(* Copyright (C) 2019 Inria, contributor: Denis Merigoux <denis.merigoux@inria.fr>

   This program is free software: you can redistribute it and/or modify it under the terms of the
   GNU General Public License as published by the Free Software Foundation, either version 3 of the
   License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
   even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   General Public License for more details.

   You should have received a copy of the GNU General Public License along with this program. If
   not, see <https://www.gnu.org/licenses/>. *)

open Mir

let verbose_output = ref false

let java_imports : string = {|
  import java.util.Map;
  import java.util.OptionalDouble;
  import java.util.function.BiFunction;
  import java.util.HashMap;
|}

let m_operation_class: string = {|

  private static OptionalDouble mGreaterThan(OptionalDouble value1, OptionalDouble value2) {
    return unopCondition((firstValue, secondValue) -> {
      return firstValue.getAsDouble() > secondValue.getAsDouble();
    }, value1, value2);
  }

  private static OptionalDouble mGreaterThanEqual(OptionalDouble value1, OptionalDouble value2) {
    return unopCondition((firstValue, secondValue) -> {
      return firstValue.getAsDouble() >= secondValue.getAsDouble();
    }, value1, value2);
  }

  private static OptionalDouble mLessThan(OptionalDouble value1, OptionalDouble value2) {
    return unopCondition((firstValue, secondValue) -> {
      return firstValue.getAsDouble() < secondValue.getAsDouble();
    }, value1, value2);
  }

  private static OptionalDouble mLessThanEqual(OptionalDouble value1, OptionalDouble value2) {
    return unopCondition((firstValue, secondValue) -> {
      return firstValue.getAsDouble() <= secondValue.getAsDouble();
    }, value1, value2);
  }

  private static OptionalDouble mEqual(OptionalDouble value1, OptionalDouble value2) {
    return unopCondition((firstValue, secondValue) -> {
      return firstValue.getAsDouble() == secondValue.getAsDouble();
    }, value1, value2);
  }

  private static OptionalDouble mNotEqual(OptionalDouble value1, OptionalDouble value2) {
    return unopCondition((firstValue, secondValue) -> {
      return firstValue.getAsDouble() != secondValue.getAsDouble();
    }, value1, value2);
  }

  private static OptionalDouble mAnd(OptionalDouble value1, OptionalDouble value2) {
    return unopCondition((firstValue, secondValue) -> {
      return firstValue.getAsDouble() != 0d && secondValue.getAsDouble() != 0d;
    }, value1, value2);
  }

  private static OptionalDouble mOr(OptionalDouble value1, OptionalDouble value2) {
    return unopCondition((firstValue, secondValue) -> {
      return firstValue.getAsDouble() != 0d || secondValue.getAsDouble() != 0d;
    }, value1, value2);
  }

  private static OptionalDouble mAdd(OptionalDouble value1, OptionalDouble value2) {
    return binopCondition((firstValue, secondValue) -> {
      return OptionalDouble.of(firstValue.getAsDouble() + secondValue.getAsDouble());
    }, value1, value2);
  }

  private static OptionalDouble mSubstract(OptionalDouble value1, OptionalDouble value2) {
    return binopCondition((firstValue, secondValue) -> {
      return OptionalDouble.of(firstValue.getAsDouble() - secondValue.getAsDouble());
    }, value1, value2);
  }

  private static OptionalDouble mMultiply(OptionalDouble value1, OptionalDouble value2) {
    return binopCondition((firstValue, secondValue) -> {
      return OptionalDouble.of(firstValue.getAsDouble() * secondValue.getAsDouble());
    }, value1, value2);
  }

  private static OptionalDouble mDivide(OptionalDouble value1, OptionalDouble value2) {

    if (valuesNotPresent(value1, value2)) {
      return OptionalDouble.empty();
    }

    double denominateur = value2.getAsDouble();

    if (denominateur == 0) {
      return OptionalDouble.of(0);
    }

    return OptionalDouble.of(value1.getAsDouble() / denominateur);

  }

  private static OptionalDouble unopCondition(BiFunction<OptionalDouble, OptionalDouble, Boolean> condition,
      OptionalDouble value1, OptionalDouble value2) {

    if (valuesNotPresent(value1, value2)) {
      return OptionalDouble.empty();
    }

    if (condition.apply(value1, value2)) {
      return OptionalDouble.of(1);
    } else {
      return OptionalDouble.of(0);
    }
  }

  private static OptionalDouble binopCondition(BiFunction<OptionalDouble, OptionalDouble, OptionalDouble> condition,
      OptionalDouble value1, OptionalDouble value2) {

    if (valuesNotPresent(value1, value2)) {
      return OptionalDouble.empty();
    }

    return condition.apply(value1, value2);
  }

  private static boolean valuesNotPresent(OptionalDouble value1, OptionalDouble value2) {
    return value1.isEmpty() || value2.isEmpty();
  }

  private static OptionalDouble m_round(OptionalDouble value) {
    if (!value.isPresent()) {
      return value;
    }
    double valueToRound = value.getAsDouble() + value.getAsDouble() < 0 ? -0.50005 : 0.50005;
    return OptionalDouble.of(Math.round(valueToRound));
  }

    private static OptionalDouble m_floor(OptionalDouble value) {
    if (!value.isPresent()) {
      return value;
    }
    double valueToFloor = value.getAsDouble() + 0.000001;
    return OptionalDouble.of(Math.floor(valueToFloor));
  }

   private static OptionalDouble m_cond(OptionalDouble value, OptionalDouble value2, OptionalDouble value3) {
    if (!value.isPresent()) {
      return value;
    } else if (value.getAsDouble() != 0) {
      return value2;
    } else {
      return value3;
    }
  }

    private static OptionalDouble m_max(OptionalDouble value1, OptionalDouble value2) {
    if (value1.isEmpty() && value2.isPresent()) {
      return value2;
    } else if (value1.isPresent() && value2.isEmpty()) {
      return value1;
    } else if (value1.isEmpty() && value2.isEmpty()) {
      return OptionalDouble.empty();
    } else {
      return OptionalDouble.of(Math.max(value1.getAsDouble(), value2.getAsDouble()));
    }
  }

  private static OptionalDouble m_min(OptionalDouble value1, OptionalDouble value2) {
    if (value1.isEmpty() && value2.isPresent()) {
      return value2;
    } else if (value1.isPresent() && value2.isEmpty()) {
      return value1;
    } else if (value1.isEmpty() && value2.isEmpty()) {
      return OptionalDouble.empty();
    } else {
      return OptionalDouble.of(Math.min(value1.getAsDouble(), value2.getAsDouble()));
    }
  }

  private static OptionalDouble mNeg(OptionalDouble value) {
    if (value.isEmpty()) {
      return value;
    }
    return OptionalDouble.of(-value.getAsDouble());
  }

}
|}

let calculateTax_method_header : string = {|

public static Map<String, OptionalDouble> calculateTax(Map<String,OptionalDouble> input_variables) {
  OptionalDouble cond; 
  Map<String, OptionalDouble> out = new HashMap<>();
  Map<String, OptionalDouble> calculationVariables = new HashMap<>();
  Map<Integer, OptionalDouble> localVariables = new HashMap<>();
|}

let none_value = "OptionalDouble.empty()"

let generate_comp_op (op : Mast.comp_op) : string =
  match op with
  | Mast.Gt -> "mGreaterThan"
  | Mast.Gte -> "mGreaterThanEqual"
  | Mast.Lt -> "mLessThan"
  | Mast.Lte -> "mLessThanEqual"
  | Mast.Eq -> "mEqual"
  | Mast.Neq -> "mNotEqual"

let generate_binop (op : Mast.binop) : string =
  match op with
  | Mast.And -> "mAnd"
  | Mast.Or -> "mOr"
  | Mast.Add -> "mAdd"
  | Mast.Sub -> "mSubstract"
  | Mast.Mul -> "mMultiply"
  | Mast.Div -> "mDivide"

let generate_unop (op : Mast.unop) : string = match op with Mast.Not -> "mNot" | Mast.Minus -> "mNeg"

let generate_variable (var_indexes : int Mir.VariableMap.t) 
    (fmt : Format.formatter) (var : Variable.t) : unit =
  let var_index =
    match Mir.VariableMap.find_opt var var_indexes with
    | Some i -> i
    | None ->
      Errors.raise_error
        (Format.asprintf "Variable %s not found in TGV" (Pos.unmark var.Mir.Variable.name))
  in
  Format.fprintf fmt "TGV[%d]" var_index

let generate_var_name (var: Variable.t) : string = 
  let v = Pos.unmark var.Variable.name in
  String.uppercase_ascii v

let format_var_name (fmt : Format.formatter) (var : Variable.t) : unit =
  let v = generate_var_name var in
  Format.fprintf fmt "%s" v

let generate_name (v : Variable.t) : string =
  match v.alias with Some v -> v | None -> Pos.unmark v.Variable.name

let autograd_ref = ref false

let autograd () : bool = !autograd_ref

let rec generate_java_expr (e : expression Pos.marked) (var_indexes : int Mir.VariableMap.t) :
  string * (LocalVariable.t * expression Pos.marked) list =
  match Pos.unmark e with
  | Comparison (op, e1, e2) ->
    let se1, s1 = generate_java_expr e1 var_indexes in
    let se2, s2 = generate_java_expr e2 var_indexes in
    (Format.asprintf "%s(%s, %s)" (generate_comp_op (Pos.unmark op)) se1 se2, s1 @ s2)
  | Binop (op, e1, e2) ->
    let se1, s1 = generate_java_expr e1 var_indexes in
    let se2, s2 = generate_java_expr e2 var_indexes in
    (Format.asprintf "%s(%s, %s)" (generate_binop (Pos.unmark op)) se1 se2, s1 @ s2)
  | Unop (op, e) ->
    let se, s = generate_java_expr e var_indexes in
    (Format.asprintf "%s(%s)" (generate_unop op) se, s)
  | Index (_, _) ->
    assert false
  | Conditional (e1, e2, e3) ->
    let se1, s1 = generate_java_expr e1 var_indexes in
    let se2, s2 = generate_java_expr e2 var_indexes in
    let se3, s3 = generate_java_expr e3 var_indexes in
    (Format.asprintf "m_cond(%s, %s, %s)" se1 se2 se3, s1 @ s2 @ s3)
  | FunctionCall (PresentFunc, [ arg ]) ->
    let se, s = generate_java_expr arg var_indexes in
    (Format.asprintf "m_present(%s)" se, s)
  | FunctionCall (NullFunc, [ arg ]) ->
    let se, s = generate_java_expr arg var_indexes in
    (Format.asprintf "m_null(%s)" se, s)
  | FunctionCall (ArrFunc, [ arg ]) ->
    let se, s = generate_java_expr arg var_indexes in
    (Format.asprintf "m_round(%s)" se, s)
  | FunctionCall (InfFunc, [ arg ]) ->
    let se, s = generate_java_expr arg var_indexes in
    (Format.asprintf "m_floor(%s)" se, s)
  | FunctionCall (MaxFunc, [ e1; e2 ]) ->
    let se1, s1 = generate_java_expr e1 var_indexes in
    let se2, s2 = generate_java_expr e2 var_indexes in
    (Format.asprintf "m_max(%s, %s)" se1 se2, s1 @ s2)
  | FunctionCall (MinFunc, [ e1; e2 ]) ->
    let se1, s1 = generate_java_expr e1 var_indexes in
    let se2, s2 = generate_java_expr e2 var_indexes in
    (Format.asprintf "m_min(%s, %s)" se1 se2, s1 @ s2)
  | FunctionCall (Multimax, [ e1; (Var v2, _) ]) ->
    let se1, s1 = generate_java_expr e1 var_indexes in
    (Format.asprintf "m_multimax(%s, %a)" se1 format_var_name v2), s1
  | FunctionCall _ -> assert false (* should not happen *)
  | Literal (Float f) -> (Format.asprintf "OptionalDouble.of(%s)" (string_of_float f), [])
  | Literal Undefined -> (Format.asprintf "%s" none_value, [])
  | Var var -> (Format.asprintf "calculationVariables.get(\"%a\")" format_var_name  var, [])
  | LocalVar lvar -> (Format.asprintf "localVariables.get(%d)" lvar.LocalVariable.id, [])
  | GenericTableIndex -> (Format.asprintf "generic_index", [])
  | Error -> assert false (* should not happen *)
  | LocalLet (lvar, e1, e2) ->
    let _, s1 = generate_java_expr e1 var_indexes in
    let se2, s2 = generate_java_expr e2 var_indexes in
    (Format.asprintf "%s" se2, s1 @ ((lvar, e1) :: s2))

let format_local_vars_defs  (var_indexes : int Mir.VariableMap.t) (fmt : Format.formatter)
    (defs : (LocalVariable.t * expression Pos.marked) list) =
  List.iter
    (fun (lvar, e) ->
       let se, _ = generate_java_expr e var_indexes in
       Format.fprintf fmt "localVariables.put(%d,%s);@\n" lvar.LocalVariable.id se)
    defs

let generate_method (oc : Format.formatter) ((rule_number : string),(expression : string))  : unit=
  Format.fprintf oc "private static OptionalDouble generate_%s(Map<String,OptionalDouble> calculationVariables, Map<Integer, OptionalDouble> localVariables) {return %s;} @\n" rule_number expression

let generate_var_def (var_indexes : int Mir.VariableMap.t) (var : Mir.Variable.t)
    (data : Mir.variable_data) (oc : Format.formatter) (methods_to_write) =
  match data.var_definition with
  | SimpleVar e ->
    let se, defs = generate_java_expr e var_indexes in
    let method_number = Format.asprintf "%s_%d_%d" (generate_name var) var.Variable.execution_number.Mir.rule_number
        var.Variable.execution_number.Mir.seq_number in
    Format.fprintf oc "%a calculationVariables.put(\"%a\",generate_%s(calculationVariables, localVariables));@\n"
      (format_local_vars_defs var_indexes)
      defs
      format_var_name var
      method_number;
    Hashtbl.replace methods_to_write method_number se 
  | TableVar (_, IndexTable es) ->
    Format.fprintf oc "/* TableVar */ @\n List<OptionalDouble> %a = {%s}@\n" 
      format_var_name var
      (String.concat ","  
         (let array_of_variables =  ref [] in 
          IndexMap.iter
            (fun _ v ->  
               let string_genere,_  = generate_java_expr v var_indexes in 
               array_of_variables := List.append !array_of_variables [string_genere]
            ) 
            es;
          !array_of_variables))
  | TableVar (_, IndexGeneric _) -> assert false
  (*Format.fprintf oc "%a = %a;@\n@\n" generate_variable var
    (generate_java_expr) e*)
  | InputVar -> assert false

let generate_header (oc : Format.formatter) () : unit =
  Format.fprintf oc "// %s\n\n" Prelude.message;
  Format.fprintf oc "%s\n\n" java_imports;
  Format.fprintf oc "public class CalculImpot {@\n"

let generate_input_handling oc (function_spec : Bir_interface.bir_function) =
  let input_vars = List.map fst (VariableMap.bindings function_spec.func_variable_inputs) in
  Format.fprintf oc "%a@\n@\n"
    (Format.pp_print_list
       ~pp_sep:(fun fmt () -> Format.fprintf fmt "@\n")
       (fun fmt var ->
          Format.fprintf fmt "calculationVariables.put(\"%a\",input_variables.get(\"%s\") != null ? input_variables.get(\"%s\") : OptionalDouble.empty());" 
            format_var_name var
            (generate_name var) 
            (generate_name var)))
    input_vars

let sanitize_str (s, p) =
  String.map
    (fun c ->
       if c >= Char.chr 128 then
         let () =
           Cli.warning_print "Replaced char code %d by space %a" (Char.code c) Pos.format_position p
         in
         ' '
       else c)
    s

let generate_var_cond var_indexes cond oc =
  Format.fprintf oc
    "cond = %s;@\n\
     if (cond.isPresent() && (cond.getAsDouble() != 0)) { @\n\
    \   throw new RuntimeException(\"Error triggered\\n%a\");@\n\
     }@\n\
     @\n"
    (let se, _ = generate_java_expr cond.cond_expr var_indexes  in 
     se)
    (Format.pp_print_list
       ~pp_sep:(fun fmt () -> Format.fprintf fmt "@\n")
       (fun fmt err ->
          Format.fprintf fmt "%s: %s" (sanitize_str err.Error.name) (sanitize_str err.Error.descr)))
    cond.cond_errors

let rec generate_stmts (program : Bir.program) (var_indexes : int Mir.VariableMap.t) methods_to_write
    (oc : Format.formatter) (stmts : Bir.stmt list)  =
  Format.pp_print_list (generate_stmt program var_indexes methods_to_write) oc stmts

and generate_stmt (program : Bir.program) (var_indexes : int Mir.VariableMap.t) methods_to_write
    (oc : Format.formatter) (stmt : Bir.stmt)  =
  match Pos.unmark stmt with
  | Bir.SAssign (var, vdata) -> generate_var_def var_indexes var vdata oc methods_to_write
  | SConditional (cond, tt, []) ->
    let pos = Pos.get_position stmt in
    let fname =
      String.map (fun c -> if c = '.' then '_' else c) (Filename.basename (Pos.get_file pos))
    in
    let cond_name =
      Format.asprintf "cond_%s_%d_%d_%d_%d" fname (Pos.get_start_line pos)
        (Pos.get_start_column pos) (Pos.get_end_line pos) (Pos.get_end_column pos)
    in
    Format.fprintf oc
      "OptionalDouble %s = %s;@\nif (!%s.isPresent() || %s.getAsDouble() != 0){@\n@[<h 4>    %a@]}@\n" 
      cond_name
      ( let pos_expression = Pos.same_pos_as cond stmt in
        let s,_ = generate_java_expr pos_expression var_indexes in
        s)
      cond_name 
      cond_name
      (generate_stmts program var_indexes methods_to_write) tt     
  | SConditional (cond, tt, ff) ->
    let pos = Pos.get_position stmt in
    let fname =
      String.map (fun c -> if c = '.' then '_' else c) (Filename.basename (Pos.get_file pos))
    in
    let cond_name =
      Format.asprintf "cond_%s_%d_%d_%d_%d" fname (Pos.get_start_line pos)
        (Pos.get_start_column pos) (Pos.get_end_line pos) (Pos.get_end_column pos)
    in
    Format.fprintf oc
      "%s = %s@\n\
       if (!%s.isPresent() && %s != 0){@\n\
       @[<h 4>    %a@]}@\n\
       else if (!%s.isPresent()){@\n\
       @[<h 4>    %a@]}@\n"
      cond_name 
      (let s,_ = generate_java_expr (Pos.same_pos_as cond stmt) var_indexes in 
       s)
      cond_name cond_name
      (generate_stmts program var_indexes methods_to_write) tt cond_name (generate_stmts program var_indexes methods_to_write) ff
  | SVerif v -> generate_var_cond var_indexes v oc

let generate_return (oc : Format.formatter) (function_spec : Bir_interface.bir_function) =
  let returned_variables = List.map fst (VariableMap.bindings function_spec.func_outputs) in
  Format.pp_print_list
    (fun oc (var : Variable.t) ->
       Format.fprintf oc "out.put(\"%a\",calculationVariables.get(\"%a\"));@\n" format_var_name var format_var_name var)
    oc returned_variables;
  Format.fprintf oc "return out;@\n@]\n";
  Format.fprintf oc "}"

let get_variables_indexes (p : Bir.program) (function_spec : Bir_interface.bir_function) :
  int Mir.VariableMap.t * int =
  let input_vars = List.map fst (VariableMap.bindings function_spec.func_variable_inputs) in
  let assigned_variables = List.map fst (Mir.VariableMap.bindings (Bir.get_assigned_variables p)) in
  let output_vars = List.map fst (VariableMap.bindings function_spec.func_outputs) in
  let all_relevant_variables =
    List.fold_left
      (fun acc var -> Mir.VariableMap.add var () acc)
      Mir.VariableMap.empty
      (input_vars @ assigned_variables @ output_vars)
  in
  let counter = ref 0 in
  let var_indexes =
    VariableMap.mapi
      (fun var _ ->
         let id = !counter in
         let size = match var.Mir.Variable.is_table with None -> 1 | Some size -> size in
         counter := !counter + size;
         id)
      all_relevant_variables
  in
  (var_indexes, !counter)

let generate_calculation_methods (oc: Format.formatter) hashtbl: unit =
  Seq.iter (generate_method oc) (Hashtbl.to_seq hashtbl)


let generate_java_program (program : Bir.program) (function_spec : Bir_interface.bir_function)
    (filename : string) : unit =
  let _oc = open_out filename in
  let oc = Format.formatter_of_out_channel _oc in
  let methods_to_write = Hashtbl.create 500 in
  Format.fprintf oc "%a%s%a%a%a%a%s" 
    generate_header () 
    calculateTax_method_header
    generate_input_handling function_spec
    (let var_indexes,_ = get_variables_indexes program function_spec in
     generate_stmts program var_indexes methods_to_write) program.statements
    generate_return function_spec
    generate_calculation_methods methods_to_write
    m_operation_class; 
  close_out _oc
