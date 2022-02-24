(* Copyright (C) 2019-2021-2020 Inria, contributors: Denis Merigoux
   <denis.merigoux@inria.fr> Raphaël Monat <raphael.monat@lip6.fr>

   This program is free software: you can redistribute it and/or modify it under
   the terms of the GNU General Public License as published by the Free Software
   Foundation, either version 3 of the License, or (at your option) any later
   version.

   This program is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
   FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
   details.

   You should have received a copy of the GNU General Public License along with
   this program. If not, see <https://www.gnu.org/licenses/>. *)

type rule_id = Mir.rule_id

module RuleMap = Mir.RuleMap

type variable

type variable_id

module VariableMap : Map.S with type key = variable

module VariableDict : sig
  type t

  val bindings : t -> (variable_id * variable) list

  val add : variable -> t -> t

  val empty : t

  val find : variable_id -> t -> variable

  val mem : variable -> t -> bool

  val union : t -> t -> t

  val inter : t -> t -> t

  val fold : (variable -> 'b -> 'b) -> t -> 'b -> 'b

  val singleton : variable -> t

  val filter : (variable_id -> variable -> bool) -> t -> t

  val for_all : (variable -> bool) -> t -> bool
end

type function_name = string

type rule = { rule_id : rule_id; rule_name : string; rule_stmts : stmt list }

and stmt = stmt_kind Pos.marked

and stmt_kind =
  | SAssign of variable * Mir.variable_data
  | SConditional of Mir.expression * stmt list * stmt list
  | SVerif of Mir.condition_data
  | SRuleCall of rule_id
  | SFunctionCall of function_name * Mir.Variable.t list

type mpp_function = stmt list

module FunctionMap : Map.S with type key = function_name

type program = {
  mpp_functions : mpp_function FunctionMap.t;
  rules : rule RuleMap.t;
  main_function : function_name;
  idmap : Mir.idmap;
  mir_program : Mir.program;
  outputs : unit Mir.VariableMap.t;
}

val var_from_mir : Mir.Variable.t -> variable

val var_to_mir : variable -> Mir.Variable.t

val map_from_mir_map : 'a Mir.VariableMap.t -> 'a VariableMap.t

val dict_from_mir_dict : Mir.VariableDict.t -> VariableDict.t

val main_statements : program -> stmt list

val get_all_statements : program -> stmt list

val squish_statements : program -> int -> string -> program
(** In order to handle backends with limited function / method capacity, such as
    Java's 64kB of bytecode per method, class, etc, this funciton allows a
    [program] to be split into chunks of an arbitrary size using the string
    argument as a suffix to the new function / method name. We piggyback on the
    existing rules semantics, with these chunks being rule definitions and
    inserting rule calls in their place*)

val get_assigned_variables : program -> Mir.VariableDict.t

val get_local_variables : program -> unit Mir.LocalVariableMap.t

val get_locals_size : program -> int

val remove_empty_conditionals : stmt list -> stmt list
