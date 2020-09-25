(* Copyright (C) 2020 Inria, contributors: Denis Merigoux <denis.merigoux@inria.fr>

   This program is free software: you can redistribute it and/or modify it under the terms of the
   GNU General Public License as published by the Free Software Foundation, either version 3 of the
   License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
   even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   General Public License for more details.

   You should have received a copy of the GNU General Public License along with this program. If
   not, see <https://www.gnu.org/licenses/>. *)

open Oir

type ctx = {
  ctx_vars : (Mir.variable_def * int) BlockMap.t Mir.VariableMap.t;
  (* the int is the statement number inside the block *)
  ctx_doms : Dominators.dom;
  ctx_paths : Paths.path_checker;
}

let empty_ctx (g : CFG.t) (entry_block : block_id) =
  {
    ctx_vars = Mir.VariableMap.empty;
    ctx_doms = Dominators.idom_to_dom (Dominators.compute_idom g entry_block);
    ctx_paths = Paths.create g;
  }

let add_var_def_to_ctx (var : Mir.Variable.t) (def : Mir.variable_def) (current_block : block_id)
    (current_stmt_pos : int) (ctx : ctx) : ctx =
  {
    ctx with
    ctx_vars =
      Mir.VariableMap.update var
        (fun defs ->
          match defs with
          | None -> Some (BlockMap.singleton current_block (def, current_stmt_pos))
          | Some defs -> Some (BlockMap.add current_block (def, current_stmt_pos) defs))
        ctx.ctx_vars;
  }

let inline_in_expr (e : Mir.expression) (ctx : ctx) (current_block : block_id) (current_pos : int) :
    Mir.expression =
  match e with
  | Mir.Var var_x -> (
      match Mir.VariableMap.find_opt var_x ctx.ctx_vars with
      | Some previous_x_defs -> (
          let candidate =
            BlockMap.filter
              (fun previous_x_def_block_id (previous_x_def, previous_x_def_pos) ->
                (* first we pick dominating definitions *)
                ( previous_x_def_block_id = current_block
                || ctx.ctx_doms previous_x_def_block_id current_block )
                &&
                match previous_x_def with
                | Mir.SimpleVar previous_e ->
                    let vars_used_in_previous_x_def =
                      Mir_dependency_graph.get_used_variables previous_e
                    in
                    (* we're trying to replace the use of [var] with [previous_e]. This is valid
                       only if [var] and the variables used in [previous_e] have not been redefined
                       between [previous_def_block_id] and [current_block] *)
                    let exists_def_between_previous_x_def_and_here (var : Mir.Variable.t) : bool =
                      let var_defs =
                        match Mir.VariableMap.find_opt var ctx.ctx_vars with
                        | None -> BlockMap.empty
                        | Some defs -> defs
                      in
                      BlockMap.exists
                        (fun intermediate_block (_, intermediate_block_pos) ->
                          if intermediate_block = previous_x_def_block_id then
                            intermediate_block_pos > previous_x_def_pos
                          else if intermediate_block = current_block then
                            current_pos > intermediate_block_pos
                          else
                            Paths.check_path ctx.ctx_paths previous_x_def_block_id
                              intermediate_block
                            && Paths.check_path ctx.ctx_paths intermediate_block current_block)
                        var_defs
                    in
                    Mir.VariableMap.for_all
                      (fun var _ -> not (exists_def_between_previous_x_def_and_here var))
                      vars_used_in_previous_x_def
                    && not (exists_def_between_previous_x_def_and_here var_x)
                | _ -> false)
              previous_x_defs
          in
          (* at this point, [candidate] should contain at most one definition *)
          match BlockMap.choose_opt candidate with
          | Some (_, previous_def) -> (
              match fst previous_def with
              | SimpleVar previous_e -> Pos.unmark previous_e
              | _ -> assert false (* should not happen *) )
          | None -> e )
      | None -> e )
  | _ -> e

let inline_in_stmt (stmt : stmt) (ctx : ctx) (current_block : block_id) (current_stmt_pos : int) :
    stmt * ctx =
  match Pos.unmark stmt with
  | SAssign (var, data) -> (
      match data.var_definition with
      | InputVar -> (stmt, ctx)
      | SimpleVar def ->
          let new_def = inline_in_expr (Pos.unmark def) ctx current_block current_stmt_pos in
          let new_def = Mir.SimpleVar (Pos.same_pos_as new_def def) in
          let new_stmt =
            Pos.same_pos_as (SAssign (var, { data with var_definition = new_def })) stmt
          in
          let new_ctx = add_var_def_to_ctx var new_def current_block current_stmt_pos ctx in
          (new_stmt, new_ctx)
      | TableVar (size, defs) -> (
          match defs with
          | IndexGeneric def ->
              let new_def = inline_in_expr (Pos.unmark def) ctx current_block current_stmt_pos in
              let new_def = Mir.TableVar (size, IndexGeneric (Pos.same_pos_as new_def def)) in
              let new_stmt =
                Pos.same_pos_as (SAssign (var, { data with var_definition = new_def })) stmt
              in
              let new_ctx = add_var_def_to_ctx var new_def current_block current_stmt_pos ctx in
              (new_stmt, new_ctx)
          | IndexTable defs ->
              let new_defs =
                Mir.IndexMap.map
                  (fun def ->
                    Pos.same_pos_as
                      (inline_in_expr (Pos.unmark def) ctx current_block current_stmt_pos)
                      def)
                  defs
              in
              let new_defs = Mir.TableVar (size, IndexTable new_defs) in
              let new_stmt =
                Pos.same_pos_as (SAssign (var, { data with var_definition = new_defs })) stmt
              in
              let new_ctx = add_var_def_to_ctx var new_defs current_block current_stmt_pos ctx in
              (new_stmt, new_ctx) ) )
  | SVerif cond ->
      let new_e = inline_in_expr (Pos.unmark cond.cond_expr) ctx current_block current_stmt_pos in
      let new_stmt =
        Pos.same_pos_as (SVerif { cond with cond_expr = Pos.same_pos_as new_e cond.cond_expr }) stmt
      in
      (new_stmt, ctx)
  | SConditional (cond, b1, b2, join) ->
      let new_cond = inline_in_expr cond ctx current_block current_stmt_pos in
      let new_stmt = Pos.same_pos_as (SConditional (new_cond, b1, b2, join)) stmt in
      (new_stmt, ctx)
  | _ -> (stmt, ctx)

let inlining (p : program) : program =
  let g = get_cfg p in
  let p, _ =
    Topological.fold
      (fun (block_id : block_id) (p, ctx) ->
        let block = BlockMap.find block_id p.blocks in
        let new_block, ctx, _ =
          List.fold_left
            (fun (new_block, ctx, stmt_pos) stmt ->
              let new_stmt, new_ctx = inline_in_stmt stmt ctx block_id stmt_pos in
              (new_stmt :: new_block, new_ctx, stmt_pos + 1))
            ([], ctx, 0) block
        in
        ({ p with blocks = BlockMap.add block_id (List.rev new_block) p.blocks }, ctx))
      g
      (p, empty_ctx g p.entry_block)
  in
  p
