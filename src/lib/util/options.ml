(******************************************************************************)
(*                                                                            *)
(*     The Alt-Ergo theorem prover                                            *)
(*     Copyright (C) 2006-2013                                                *)
(*                                                                            *)
(*     Sylvain Conchon                                                        *)
(*     Evelyne Contejean                                                      *)
(*                                                                            *)
(*     Francois Bobot                                                         *)
(*     Mohamed Iguernelala                                                    *)
(*     Stephane Lescuyer                                                      *)
(*     Alain Mebsout                                                          *)
(*                                                                            *)
(*     CNRS - INRIA - Universite Paris Sud                                    *)
(*                                                                            *)
(*     This file is distributed under the terms of the Apache Software        *)
(*     License version 2.0                                                    *)
(*                                                                            *)
(*  ------------------------------------------------------------------------  *)
(*                                                                            *)
(*     Alt-Ergo: The SMT Solver For Software Verification                     *)
(*     Copyright (C) 2013-2018 --- OCamlPro SAS                               *)
(*                                                                            *)
(*     This file is distributed under the terms of the Apache Software        *)
(*     License version 2.0                                                    *)
(*                                                                            *)
(******************************************************************************)

open Cmdliner

let fmt = Format.err_formatter

exception Exit_options of int
exception Error of bool * string

(* Declaration of all the options as refs with default values *)

type model = MNone | MDefault | MAll | MComplete

let model_parser = function
  | "none" -> Ok MNone
  | "default" -> Ok MDefault
  | "complete" -> Ok MComplete
  | "all" -> Ok MAll
  | s ->
    Error (`Msg ("Option --model does not accept the argument \"" ^ s))

let model_to_string = function
  | MNone -> "none"
  | MDefault -> "default"
  | MComplete -> "complete"
  | MAll -> "all"

let model_printer fmt model = Format.fprintf fmt "%s" (model_to_string model)

let model_conv = Arg.conv ~docv:"MDL" (model_parser, model_printer)

type input_format = Native | Smtlib2 | Why3 (* | SZS *) | Unknown of string
type output_format = input_format

let format_parser = function
  | "native" | "altergo" | "alt-ergo" -> Ok Native
  | "smtlib2" | "smt-lib2" -> Ok Smtlib2
  | "why3" -> Ok Why3
  (* | "szs" | "SZS" -> "szs" *)
  | s ->
    Error (`Msg (Format.sprintf
                   "The format %s is not accepted as input/output" s))

let format_to_string = function
  | Native -> "native"
  | Smtlib2 -> "smtlib2"
  | Why3 -> "why3"
  | Unknown s -> Format.sprintf "Unknown %s" s

let format_printer fmt format =
  Format.fprintf fmt "%s" (format_to_string format)

let format_conv = Arg.conv ~docv:"FMT" (format_parser, format_printer)

let vtimers = ref false

let vfile = ref ""
let vsession_file = ref ""
let vused_context_file = ref ""
let vrewriting = ref false
let vtype_only = ref false
let vtype_smt2 = ref false
let vparse_only = ref false
let vfrontend = ref "legacy"
let vsteps_bound = ref (-1)
let vage_bound = ref 50
let vdebug = ref false
let vdebug_warnings = ref false
let vno_user_triggers = ref false
let vdebug_triggers = ref false
let vdebug_cc = ref false
let vdebug_gc = ref false
let vdebug_use = ref false
let vdebug_arrays = ref false
let vdebug_ite = ref false
let vdebug_uf = ref false
let vdebug_sat = ref false
let vdebug_sat_simple = ref false
let vdebug_typing = ref false
let vdebug_constr = ref false
let vverbose = ref false
let vdebug_fm = ref false
let vdebug_fpa = ref 0
let vdebug_sum = ref false
let vdebug_adt = ref false
let vdebug_arith = ref false
let vdebug_combine = ref false
let vdebug_bitv = ref false
let vdebug_ac = ref false
let vdebug_split = ref false
let vgreedy = ref false
let vdisable_ites = ref false
let vdisable_adts = ref false
let venable_adts_cs = ref false
let vtriggers_var = ref false
let vnb_triggers = ref 2
let vmax_multi_triggers_size = ref 4
let venable_assertions = ref false
let vno_ematching = ref false
let varith_matching = ref true
let vno_backjumping = ref false
let vno_contracongru = ref false
let vterm_like_pp = ref true
let vdebug_types = ref false
let vmodel = ref MNone
let vinterpretation = ref 0
let vdebug_interpretation = ref false
let vunsat_core = ref false
let vdebug_unsat_core = ref false
let vrules = ref (-1)
let vmax_split = ref (Numbers.Q.from_int 1000000)
let vfm_cross_limit = ref (Numbers.Q.from_int 10_000)
let vcase_split_policy = ref Util.AfterTheoryAssume
let vrestricted = ref false
let vbottom_classes = ref false
let vtimelimit = ref 0.
let vtimelimit_per_goal = ref false
let vtimelimit_interpretation = ref (if Sys.win32 then 0. else 1.)
let vdebug_matching = ref 0
let vdebug_explanations = ref false
let vsat_plugin = ref ""
let vparsers = ref []
let vinequalities_plugin = ref ""
let vprofiling_plugin = ref ""
let vcumulative_time_profiling = ref false
let vnormalize_instances = ref false

let vsat_solver = ref Util.CDCL_Tableaux
let vcdcl_tableaux_inst = ref true
let vcdcl_tableaux_th = ref true
let vtableaux_cdcl = ref false
let vminimal_bj = ref true
let venable_restarts = ref false
let vdisable_flat_formulas_simplification = ref false

let vtighten_vars = ref false
let vno_tcp = ref false
let vno_decisions = ref false

let vno_decisions_on = ref Util.SS.empty
let vno_fm = ref false
let vno_theory = ref false
let vjs_mode = ref false
let vuse_fpa = ref false
let vpreludes : string list ref = ref []
let vno_nla = ref false
let vno_ac = ref false
let vno_backward = ref false
let vno_sat_learning = ref false
let vinstantiate_after_backjump = ref false
let vdisable_weaks = ref false
let vanswers_with_loc = ref true

(* vinfer_input_format controls whether input format
   should be inferred by alt-ergo.
   It's set to true by default and set to false when an input format is set.
   The inference is done at parsing (in parsers.ml) using the extension of the
   input file and regarding of this extension,
   the corresponding parser is choosed *)
let vinfer_input_format = ref true
let vinput_format = ref Native

(* vinfer_output_format controls whether output format
   should be inferred by alt-ergo.
   It's set to true by default and set to false when an outpu format is set.
   The inference is done at parsing (in parsers.ml) using the extension of the
   input file and regarding of this extension,
   the corresponding output_format is choosed *)
let vinfer_output_format = ref true
let voutput_format = ref Native

let vinline_lets = ref false

let vreplay = ref false
let vreplay_used_context = ref false
let vreplay_all_used_context = ref false
let vsave_used_context = ref false

let vprofiling_period = ref 0.
let vprofiling = ref false

let match_extension e =
  match e with
  | ".ae" -> Native
  | ".smt2" | ".psmt2" -> Smtlib2
  | ".why" | ".mlw" -> Why3
  (* | ".szs" -> SZS *)
  | s -> Unknown s

(* We don't want to handle functions with more than 10 arguments so
   we need to split the debug options to gather them in the end.
   Problems with this way of doing is the options in each "group" are sorted
   alphabetically before we split the corresponding group. Adding a new one may
   break the sorting which is why each group contains 7/8/9 options as of now
   to allow the adding of new ones in the right group
*)

type rules = RParsing | RTyping | RSat | RCC | RArith | RNone

let value_of_rules = function
  | RParsing -> 0
  | RTyping -> 1
  | RSat -> 2
  | RCC -> 3
  | RArith -> 4
  | RNone -> -1


let rules_parser = function
  | "parsing" -> Ok RParsing
  | "typing" -> Ok RTyping
  | "sat" -> Ok RSat
  | "cc" -> Ok RCC
  | "arith" -> Ok RArith
  | "none" -> Ok RNone
  | s ->
    Error (`Msg ("Option --rules does not accept the argument \"" ^ s))

let rules_to_string = function
  | RParsing -> "parsing"
  | RTyping -> "typing"
  | RSat -> "sat"
  | RCC -> "cc"
  | RArith -> "arith"
  | RNone -> "none"

let rules_printer fmt rules = Format.fprintf fmt "%s" (rules_to_string rules)

let rules_conv = Arg.conv ~docv:"MDL" (rules_parser, rules_printer)

type dbg_opt_spl1 = {
  debug : bool;
  debug_ac : bool;
  debug_adt : bool;
  debug_arith : bool;
  debug_arrays : bool;
  debug_bitv : bool;
  debug_cc : bool;
  debug_combine : bool;
  debug_constr : bool;
}

type dbg_opt_spl2 = {
  debug_explanations : bool;
  debug_fm : bool;
  debug_fpa : int;
  debug_gc : bool;
  debug_interpretation : bool;
  debug_ite : bool;
  debug_matching : int;
  debug_sat : bool;
  debug_sat_simple : bool;
}

type dbg_opt_spl3 = {
  debug_split : bool;
  debug_sum : bool;
  debug_triggers : bool;
  debug_types : bool;
  debug_typing : bool;
  debug_uf : bool;
  debug_unsat_core : bool;
  debug_use : bool;
  debug_warnings : bool;
  rules : int;
}

type dbg_opt = {
  dbg_opt_spl1 : dbg_opt_spl1;
  dbg_opt_spl2 : dbg_opt_spl2;
  dbg_opt_spl3 : dbg_opt_spl3
}

type case_split_opt =
  {
    case_split_policy : Util.case_split_policy;
    enable_adts_cs : bool;
    max_split : Numbers.Q.t;
  }

type context_opt =
  {
    replay : bool;
    replay_all_used_context : bool;
    replay_used_context : bool;
    save_used_context : bool;
  }

type execution_opt =
  {
    answers_with_loc : bool;
    frontend : string;
    input_format : input_format;
    parse_only : bool;
    parsers : string list;
    preludes : string list;
    type_only : bool;
    type_smt2 : bool;
  }

type internal_opt =
  {
    disable_weaks : bool;
    enable_assertions : bool;
    gc_policy : int;
  }

type limit_opt =
  {
    age_bound : int;
    fm_cross_limit : Numbers.Q.t;
    steps_bound : int;
    timelimit : float;
    timelimit_interpretation : float;
    timelimit_per_goal : bool;
  }

type output_opt =
  {
    interpretation : int;
    model : model;
    output_format : output_format;
    unsat_core : bool;
  }

type profiling_opt =
  {
    cumulative_time_profiling : bool;
    profiling : bool;
    profiling_period : float;
    profiling_plugin : string;
    verbose : bool;
  }

type quantifiers_opt =
  {
    greedy : bool;
    instantiate_after_backjump : bool;
    max_multi_triggers_size : int;
    nb_triggers : int;
    no_ematching : bool;
    no_user_triggers : bool;
    normalize_instances : bool;
    triggers_var : bool;
  }

type sat_opt =
  {
    arith_matching : bool;
    bottom_classes : bool;
    cdcl_tableaux_inst : bool;
    cdcl_tableaux_th : bool;
    disable_flat_formulas_simplification : bool;
    enable_restarts : bool;
    minimal_bj : bool;
    no_backjumping : bool;
    no_backward : bool;
    no_decisions : bool;
    no_decisions_on : Util.SS.t;
    no_sat_learning : bool;
    sat_plugin : string;
    sat_solver : Util.sat_solver;
    tableaux_cdcl : bool;
  }

type term_opt =
  {
    disable_ites : bool;
    inline_lets : bool;
    rewriting : bool;
    term_like_pp : bool;
  }

type theory_opt =
  {
    disable_adts : bool;
    inequalities_plugin : string;
    no_ac : bool;
    no_contracongru : bool;
    no_fm : bool;
    no_nla : bool;
    no_tcp : bool;
    no_theory : bool;
    restricted : bool;
    tighten_vars : bool;
    use_fpa : bool;
  }

let mk_dbg_opt_spl1 debug debug_ac debug_adt debug_arith debug_arrays
    debug_bitv debug_cc debug_combine debug_constr
  =
  `Ok {debug; debug_ac; debug_adt; debug_arith; debug_arrays; debug_bitv;
       debug_cc; debug_combine; debug_constr;}

let mk_dbg_opt_spl2 debug_explanations debug_fm debug_fpa debug_gc
    debug_interpretation debug_ite debug_matching debug_sat debug_sat_simple
  =
  `Ok {debug_explanations; debug_fm; debug_fpa; debug_gc; debug_interpretation;
       debug_ite; debug_matching; debug_sat; debug_sat_simple;
      }

let mk_dbg_opt_spl3 debug_split debug_sum debug_triggers debug_types
    debug_typing debug_uf debug_unsat_core debug_use debug_warnings rules
  =
  let rules = value_of_rules rules in
  `Ok {debug_split; debug_sum; debug_triggers; debug_types; debug_typing;
       debug_uf; debug_unsat_core; debug_use; debug_warnings; rules;
      }

let mk_dbg_opt dbg_opt_spl1 dbg_opt_spl2 dbg_opt_spl3 =
  `Ok {dbg_opt_spl1; dbg_opt_spl2; dbg_opt_spl3}

let mk_case_split_opt case_split_policy enable_adts_cs max_split
  =
  let res =
    match case_split_policy with
    | "after-theory-assume" -> `Ok(Util.AfterTheoryAssume)
    | "before-matching" -> `Ok(Util.BeforeMatching)
    | "after-matching" -> `Ok(Util.AfterMatching)
    | _ -> `Error ("Bad value '" ^ case_split_policy ^
                   "' for option --case-split-policy")
  in
  let max_split = Numbers.Q.from_string max_split in
  match res with
  | `Ok(case_split_policy) ->
    `Ok {max_split; case_split_policy; enable_adts_cs;}
  | `Error m -> `Error(false, m)

let mk_context_opt replay replay_all_used_context replay_used_context
    save_used_context
  =
  `Ok {save_used_context; replay; replay_all_used_context;
       replay_used_context;}

let mk_execution_opt frontend input_format parse_only parsers
    preludes no_locs_in_answers type_only type_smt2
  =
  let answers_with_loc = not no_locs_in_answers in

  vinfer_input_format := input_format = None;
  let input_format = match input_format with
    | None -> Native
    | Some fmt -> fmt
  in
  `Ok {answers_with_loc; input_format; parse_only; parsers; frontend;
       type_only; type_smt2; preludes;}

let mk_internal_opt disable_weaks enable_assertions gc_policy
  =
  let gc_policy = match gc_policy with
    | 0 | 1 | 2 -> gc_policy
    | _ ->
      Format.eprintf "[warning] Gc_policy value must be 0[default], 1 or 2@.";
      0
  in
  `Ok {disable_weaks; enable_assertions; gc_policy;}

let mk_limit_opt age_bound fm_cross_limit timelimit_interpretation
    steps_bound timelimit timelimit_per_goal
  =
  let set_limit t d =
    match t with
    | Some t ->
      if Sys.win32 then (
        Format.eprintf "timelimit not supported on Win32 (ignored)@.";
        d
      )
      else t
    | None -> d
  in
  if steps_bound < -1 then
    `Error (false, "--steps-bound argument should be positive")
  else
    let fm_cross_limit = Numbers.Q.from_string fm_cross_limit in
    let timelimit = set_limit timelimit !vtimelimit in
    let timelimit_interpretation = set_limit timelimit_interpretation
        !vtimelimit_interpretation in
    `Ok { age_bound; fm_cross_limit; timelimit_interpretation;
          steps_bound; timelimit; timelimit_per_goal; }

let mk_output_opt interpretation model unsat_core output_format
  =
  vinfer_output_format := output_format = None;
  let output_format = match output_format with
    | None -> Native
    | Some fmt -> fmt
  in
  `Ok { interpretation; model; unsat_core; output_format; }

let mk_profiling_opt cumulative_time_profiling profiling
    profiling_plugin verbose
  =
  let profiling, profiling_period = match profiling with
    | Some f -> true, f
    | None -> false, 0.
  in
  `Ok { profiling; profiling_period; profiling_plugin; verbose;
        cumulative_time_profiling;}

let mk_quantifiers_opt greedy instantiate_after_backjump
    max_multi_triggers_size nb_triggers
    no_ematching no_user_triggers normalize_instances triggers_var
  =
  `Ok { no_user_triggers; no_ematching; nb_triggers; normalize_instances;
        greedy; instantiate_after_backjump; max_multi_triggers_size;
        triggers_var;
      }

let mk_sat_opt bottom_classes disable_flat_formulas_simplification
    enable_restarts no_arith_matching no_backjumping
    no_backward no_decisions no_decisions_on
    no_minimal_bj no_sat_learning no_tableaux_cdcl_in_instantiation
    no_tableaux_cdcl_in_theories sat_plugin sat_solver
  =
  let arith_matching = not no_arith_matching in
  let mk_no_decisions_on ndo =
    List.fold_left
      (fun set s ->
         match s with
         | "" -> set
         | s -> Util.SS.add s set
      ) Util.SS.empty (Str.split (Str.regexp ",") ndo)
  in
  let no_decisions_on = mk_no_decisions_on no_decisions_on in
  let minimal_bj = not no_minimal_bj in

  let cdcl_tableaux_inst = not no_tableaux_cdcl_in_instantiation in
  let cdcl_tableaux_th = not no_tableaux_cdcl_in_theories in
  let tableaux_cdcl = false in
  let res = match sat_solver with
    | "CDCL" | "satML" ->
      `Ok(Util.CDCL, false, false, tableaux_cdcl)
    | "CDCL-Tableaux" | "satML-Tableaux" | "CDCL-tableaux" | "satML-tableaux" ->
      `Ok(Util.CDCL_Tableaux, true, true, tableaux_cdcl)
    | "tableaux" | "Tableaux" | "tableaux-like" | "Tableaux-like" ->
      `Ok(Util.Tableaux, false, cdcl_tableaux_th, tableaux_cdcl)
    | "tableaux-cdcl" | "Tableaux-CDCL" | "tableaux-CDCL" | "Tableaux-cdcl" ->
      `Ok(Util.Tableaux_CDCL, cdcl_tableaux_inst, cdcl_tableaux_th, true)
    | _ -> `Error ("Args parsing error: unkown SAT solver " ^ sat_solver)
  in
  match res with
  | `Ok(sat_solver, cdcl_tableaux_inst, cdcl_tableaux_th, tableaux_cdcl) ->
    `Ok { arith_matching; bottom_classes; cdcl_tableaux_inst; cdcl_tableaux_th;
          disable_flat_formulas_simplification; enable_restarts;
          minimal_bj; no_backjumping; no_backward; no_decisions;
          no_decisions_on; no_sat_learning; sat_plugin; sat_solver;
          tableaux_cdcl}
  | `Error m -> `Error (false, m)

let mk_term_opt disable_ites inline_lets rewriting term_like_pp
  =
  `Ok {rewriting; term_like_pp; disable_ites; inline_lets;}

let mk_theory_opt disable_adts inequalities_plugin no_ac no_contracongru
    no_fm no_nla no_tcp no_theory restricted tighten_vars use_fpa
  =
  `Ok { no_ac; no_fm; no_nla; no_tcp; no_theory; use_fpa; inequalities_plugin;
        restricted; disable_adts; tighten_vars; no_contracongru;
      }

let halt_opt version_info where =
  let handle_where w =
    let res = match w with
      | "lib" -> `Ok Config.libdir
      | "plugins" -> `Ok Config.pluginsdir
      | "preludes" -> `Ok Config.preludesdir
      | "data" -> `Ok Config.datadir
      | "man" -> `Ok Config.mandir
      | _ -> `Error
               ("Option --where does not accept the argument \"" ^ w ^
                "\"\nAccepted options are lib, plugins, preludes, data or man")
    in
    match res with
    | `Ok path -> Format.printf "%s@." path
    | `Error m -> raise (Error (false, m))
  in
  let handle_version_info vi =
    if vi then (
      Format.printf "Version          = %s@." Version._version;
      Format.printf "Release date     = %s@." Version._release_date;
      Format.printf "Release commit   = %s@." Version._release_commit;
    )
  in
  try
    match where with
    | Some w -> handle_where w; `Ok true
    | None -> if version_info then (handle_version_info version_info; `Ok true)
      else `Ok false
  with Failure f -> `Error (false, f)
     | Error (b, m) -> `Error (b, m)

let mk_opts file case_split_opt context_opt dbg_opt execution_opt halt_opt
    internal_opt limit_opt output_opt profiling_opt quantifiers_opt
    sat_opt term_opt theory_opt
  =

  if halt_opt then `Ok false
  else
    (* If save_used_context was invoked as an option it should
       automatically set unsat_core to true *)
    let output_opt = if context_opt.save_used_context then
        { output_opt with unsat_core = true} else output_opt in

    (match file with
     | Some f ->
       vfile := f;
       let base_file = try
           Filename.chop_extension f
         with Invalid_argument _ -> f
       in
       vsession_file := base_file^".agr";
       vused_context_file := base_file;
     | _ -> ()
    );

    Gc.set { (Gc.get()) with Gc.allocation_policy = internal_opt.gc_policy };

    vdebug := dbg_opt.dbg_opt_spl1.debug;
    vdebug_ac := dbg_opt.dbg_opt_spl1.debug_ac;
    vdebug_adt := dbg_opt.dbg_opt_spl1.debug_adt;
    vdebug_arith := dbg_opt.dbg_opt_spl1.debug_arith;
    vdebug_arrays := dbg_opt.dbg_opt_spl1.debug_arrays;
    vdebug_bitv := dbg_opt.dbg_opt_spl1.debug_bitv;
    vdebug_cc := dbg_opt.dbg_opt_spl1.debug_cc;
    vdebug_combine := dbg_opt.dbg_opt_spl1.debug_combine;
    vdebug_constr := dbg_opt.dbg_opt_spl1.debug_constr;
    vdebug_explanations := dbg_opt.dbg_opt_spl2.debug_explanations;
    vdebug_fm := dbg_opt.dbg_opt_spl2.debug_fm;
    vdebug_fpa := dbg_opt.dbg_opt_spl2.debug_fpa;
    vdebug_gc := dbg_opt.dbg_opt_spl2.debug_gc;
    vdebug_interpretation := dbg_opt.dbg_opt_spl2.debug_interpretation;
    vdebug_ite := dbg_opt.dbg_opt_spl2.debug_ite;
    vdebug_matching := dbg_opt.dbg_opt_spl2.debug_matching;
    vdebug_sat := dbg_opt.dbg_opt_spl2.debug_sat;
    vdebug_sat_simple := dbg_opt.dbg_opt_spl2.debug_sat_simple;
    vdebug_split := dbg_opt.dbg_opt_spl3.debug_split;
    vdebug_sum := dbg_opt.dbg_opt_spl3.debug_sum;
    vdebug_triggers := dbg_opt.dbg_opt_spl3.debug_triggers;
    vdebug_types := dbg_opt.dbg_opt_spl3.debug_types;
    vdebug_typing := dbg_opt.dbg_opt_spl3.debug_typing;
    vdebug_uf := dbg_opt.dbg_opt_spl3.debug_uf;
    vdebug_unsat_core := dbg_opt.dbg_opt_spl3.debug_unsat_core;
    vdebug_use := dbg_opt.dbg_opt_spl3.debug_use;
    vdebug_warnings := dbg_opt.dbg_opt_spl3.debug_warnings;
    vrules := dbg_opt.dbg_opt_spl3.rules;
    vcase_split_policy := case_split_opt.case_split_policy;
    venable_adts_cs := case_split_opt.enable_adts_cs;
    vmax_split := case_split_opt.max_split;
    vreplay := context_opt.replay;
    vreplay_all_used_context := context_opt.replay_all_used_context;
    vreplay_used_context := context_opt.replay_used_context;
    vsave_used_context := context_opt.save_used_context;
    vinput_format := execution_opt.input_format;
    vfrontend := execution_opt.frontend;
    vanswers_with_loc := execution_opt.answers_with_loc;
    vparse_only := execution_opt.parse_only;
    vparsers := execution_opt.parsers;
    vpreludes := execution_opt.preludes;
    vtype_only := execution_opt.type_only;
    vtype_smt2 := execution_opt .type_smt2;
    vdisable_weaks := internal_opt.disable_weaks;
    venable_assertions := internal_opt.enable_assertions;
    vage_bound := limit_opt.age_bound;
    vfm_cross_limit := limit_opt.fm_cross_limit;
    vtimelimit_interpretation := limit_opt.timelimit_interpretation;
    vsteps_bound := limit_opt.steps_bound;
    vtimelimit := limit_opt.timelimit;
    vtimelimit_per_goal := limit_opt.timelimit_per_goal;
    vinterpretation := output_opt.interpretation;
    vmodel := output_opt.model;
    vunsat_core := output_opt.unsat_core;
    voutput_format := output_opt.output_format;
    vcumulative_time_profiling := profiling_opt.cumulative_time_profiling;
    vprofiling := profiling_opt.profiling;
    vprofiling_period := profiling_opt.profiling_period;
    vprofiling_plugin := profiling_opt.profiling_plugin;
    vverbose := profiling_opt.verbose;
    vgreedy := quantifiers_opt.greedy;
    vinstantiate_after_backjump := quantifiers_opt.instantiate_after_backjump;
    vmax_multi_triggers_size := quantifiers_opt.max_multi_triggers_size;
    vnb_triggers := quantifiers_opt.nb_triggers;
    vno_ematching := quantifiers_opt.no_ematching;
    vno_user_triggers := quantifiers_opt.no_user_triggers;
    vnormalize_instances := quantifiers_opt.normalize_instances;
    vtriggers_var := quantifiers_opt.triggers_var;
    varith_matching := sat_opt.arith_matching;
    vbottom_classes := sat_opt.bottom_classes;
    vdisable_flat_formulas_simplification :=
      sat_opt.disable_flat_formulas_simplification;
    venable_restarts := sat_opt.enable_restarts;
    vno_backjumping := sat_opt.no_backjumping;
    vno_backward := sat_opt.no_backward;
    vno_decisions := sat_opt.no_decisions;
    vno_decisions_on := sat_opt.no_decisions_on;
    vminimal_bj := sat_opt.minimal_bj;
    vno_sat_learning := sat_opt.no_sat_learning;
    vcdcl_tableaux_inst := sat_opt.cdcl_tableaux_inst;
    vcdcl_tableaux_th := sat_opt.cdcl_tableaux_th;
    vsat_plugin := sat_opt.sat_plugin;
    vsat_solver := sat_opt.sat_solver;
    vtableaux_cdcl := sat_opt.tableaux_cdcl;
    vdisable_ites := term_opt.disable_ites;
    vinline_lets := term_opt.inline_lets;
    vrewriting := term_opt.rewriting;
    vterm_like_pp := term_opt.term_like_pp;
    vdisable_adts := theory_opt.disable_adts;
    vinequalities_plugin := theory_opt.inequalities_plugin;
    vno_ac := theory_opt.no_ac;
    vno_contracongru := theory_opt.no_contracongru;
    vno_fm := theory_opt.no_fm;
    vno_nla := theory_opt.no_nla;
    vno_tcp := theory_opt.no_tcp;
    vno_theory := theory_opt.no_theory;
    vrestricted := theory_opt.restricted;
    vtighten_vars := theory_opt.tighten_vars;
    vuse_fpa := theory_opt.use_fpa;
    `Ok true

(* Custom sections *)

let s_debug = "DEBUG OPTIONS"
let s_case_split = "CASE SPLIT OPTIONS"
let s_context = "CONTEXT OPTIONS"
let s_execution = "EXECUTION OPTIONS"
let s_internal = "INTERNAL OPTIONS"
let s_halt = "HALTING OPTIONS"
let s_limit = "LIMIT OPTIONS"
let s_output = "OUTPUT OPTIONS"
let s_profiling = "PROFILING OPTIONS"
let s_quantifiers = "QUANTIFIERS OPTIONS"
let s_sat = "SAT OPTIONS"
let s_term = "TERM OPTIONS"
let s_theory = "THEORY OPTIONS"

(* Parsers *)

let parse_dbg_opt_spl1 =

  let docs = s_debug in

  let debug =
    let doc = "Set the debugging flag." in
    Arg.(value & flag & info ["d"; "debug"] ~doc) in

  let debug_ac =
    let doc = "Set the debugging flag of ac." in
    Arg.(value & flag & info ["dac"] ~docs ~doc) in

  let debug_adt =
    let doc = "Set the debugging flag of ADTs." in
    Arg.(value & flag & info ["dadt"] ~docs ~doc) in

  let debug_arith =
    let doc = "Set the debugging flag of Arith (without fm)." in
    Arg.(value & flag & info ["darith"] ~docs ~doc) in

  let debug_arrays =
    let doc = "Set the debugging flag of arrays." in
    Arg.(value & flag & info ["darrays"] ~docs ~doc) in

  let debug_bitv =
    let doc = "Set the debugging flag of bitv." in
    Arg.(value & flag & info ["dbitv"] ~docs ~doc) in

  let debug_cc =
    let doc = "Set the debugging flag of cc." in
    Arg.(value & flag & info ["dcc"] ~docs ~doc) in

  let debug_combine =
    let doc = "Set the debugging flag of combine." in
    Arg.(value & flag & info ["dcombine"] ~docs ~doc) in

  let debug_constr =
    let doc = "Set the debugging flag of constructors." in
    Arg.(value & flag & info ["dconstr"] ~docs ~doc) in

  Term.(ret (const mk_dbg_opt_spl1 $
             debug $
             debug_ac $
             debug_adt $
             debug_arith $
             debug_arrays $
             debug_bitv $
             debug_cc $
             debug_combine $
             debug_constr
            ))

let parse_dbg_opt_spl2 =

  let docs = s_debug in

  let debug_explanations =
    let doc = "Set the debugging flag of explanations." in
    Arg.(value & flag & info ["dexplanations"] ~docs ~doc) in

  let debug_fm =
    let doc = "Set the debugging flag of inequalities." in
    Arg.(value & flag & info ["dfm"] ~docs ~doc) in

  let debug_fpa =
    let doc = "Set the debugging flag of floating-point." in
    Arg.(value & opt int !vdebug_fpa & info ["dfpa"] ~docs ~doc) in

  let debug_gc =
    let doc = "Prints some debug info about the GC's activity." in
    Arg.(value & flag & info ["dgc"] ~docs ~doc) in

  let debug_interpretation =
    let doc = "Set debug flag for interpretation generatation." in
    Arg.(value & flag & info ["debug-interpretation"] ~docs ~doc) in

  let debug_ite =
    let doc = "Set the debugging flag of ite." in
    Arg.(value & flag & info ["dite"] ~docs ~doc) in

  let debug_matching =
    let doc = "Set the debugging flag \
               of E-matching (0=disabled, 1=light, 2=full)." in
    let docv = "FLAG" in
    Arg.(value & opt int !vdebug_matching &
         info ["dmatching"] ~docv ~docs ~doc) in

  let debug_sat =
    let doc = "Set the debugging flag of sat." in
    Arg.(value & flag & info ["dsat"] ~docs ~doc) in

  let debug_sat_simple =
    let doc = "Set the debugging flag of sat (simple output)." in
    Arg.(value & flag & info ["dsats"] ~docs ~doc) in

  Term.(ret (const mk_dbg_opt_spl2 $

             debug_explanations $
             debug_fm $
             debug_fpa $
             debug_gc $
             debug_interpretation $
             debug_ite $
             debug_matching $
             debug_sat $
             debug_sat_simple
            ))

let parse_dbg_opt_spl3 =

  let docs = s_debug in

  let debug_split =
    let doc = "Set the debugging flag of case-split analysis." in
    Arg.(value & flag & info ["dsplit"] ~docs ~doc) in

  let debug_sum =
    let doc = "Set the debugging flag of Sum." in
    Arg.(value & flag & info ["dsum"] ~docs ~doc) in

  let debug_triggers =
    let doc = "Set the debugging flag of triggers." in
    Arg.(value & flag & info ["dtriggers"] ~docs ~doc) in

  let debug_types =
    let doc = "Set the debugging flag of types." in
    Arg.(value & flag & info ["dtypes"] ~docs ~doc) in

  let debug_typing =
    let doc = "Set the debugging flag of typing." in
    Arg.(value & flag & info ["dtyping"] ~docs ~doc) in

  let debug_uf =
    let doc = "Set the debugging flag of uf." in
    Arg.(value & flag & info ["duf"] ~docs ~doc) in

  let debug_unsat_core =
    let doc = "Replay unsat-cores produced by $(b,--unsat-core). \
               The option implies $(b,--unsat-core)." in
    Arg.(value & flag & info ["debug-unsat-core"] ~docs ~doc) in

  let debug_use =
    let doc = "Set the debugging flag of use." in
    Arg.(value & flag & info ["duse"] ~docs ~doc) in

  let debug_warnings =
    let doc = "Set the debugging flag of warnings." in
    Arg.(value & flag & info ["dwarnings"] ~docs ~doc) in

  let rules =
    let doc =
      "$(docv) = parsing|typing|sat|cc|arith, output rules used on stderr." in
    let docv = "TR" in
    Arg.(value & opt rules_conv RNone & info ["rules"] ~docv ~docs ~doc) in

  Term.(ret (const mk_dbg_opt_spl3 $

             debug_split $
             debug_sum $
             debug_triggers $
             debug_types $
             debug_typing $
             debug_uf $
             debug_unsat_core $
             debug_use $
             debug_warnings $
             rules
            ))

let parse_dbg_opt =
  Term.(ret (const mk_dbg_opt $
             parse_dbg_opt_spl1 $
             parse_dbg_opt_spl2 $
             parse_dbg_opt_spl3
            ))

let parse_case_split_opt =

  let docs = s_case_split in

  let case_split_policy =
    let doc = Format.sprintf
        "Case-split policy. Set the case-split policy to use. \
         Possible values are %s."
        (Arg.doc_alts
           ["after-theory-assume"; "before-matching"; "after-matching"]) in
    let docv = "PLCY" in
    Arg.(value & opt string "after-theory-assume" &
         info ["case-split-policy"] ~docv ~docs ~doc) in

  let enable_adts_cs =
    let doc = "Enable case-split for Algebraic Datatypes theory." in
    Arg.(value & flag & info ["enable-adts-cs"] ~docs ~doc) in

  let max_split =
    let dv = Numbers.Q.to_string !vmax_split in
    let doc =
      Format.sprintf "Maximum size of case-split." in
    let docv = "VAL" in
    Arg.(value & opt string dv & info ["max-split"] ~docv ~docs ~doc) in

  Term.(ret (const mk_case_split_opt $
             case_split_policy $ enable_adts_cs $ max_split))

let parse_context_opt =

  let docs = s_context in

  let replay =
    let doc = "Replay session saved in $(i,file_name.agr)." in
    Arg.(value & flag & info ["replay"] ~docs ~doc) in

  let replay_all_used_context =
    let doc =
      "Replay with all axioms and predicates saved in $(i,.used) files \
       of the current directory." in
    Arg.(value & flag & info ["replay-all-used-context"] ~docs ~doc) in

  let replay_used_context =
    let doc = "Replay with axioms and predicates saved in $(i,.used) file." in
    Arg.(value & flag & info ["r"; "replay-used-context"] ~doc) in

  let save_used_context =
    let doc = "Save used axioms and predicates in a $(i,.used) file. \
               This option implies $(b,--unsat-core)." in
    Arg.(value & flag & info ["s"; "save-used-context"] ~doc) in

  Term.(ret (const mk_context_opt $
             replay $ replay_all_used_context $ replay_used_context $
             save_used_context
            ))

let parse_execution_opt =

  let docs = s_execution in

  let frontend =
    let doc = "Select the parsing and typing frontend." in
    let docv = "FTD" in
    Arg.(value & opt string !vfrontend & info ["frontend"] ~docv ~docs ~doc) in

  let input_format =
    let doc = Format.sprintf
        "Set the default input format to $(docv) and must be %s. \
         Useful when the extension does not allow to automatically select \
         a parser (eg. JS mode, GUI mode, ...)."
        (Arg.doc_alts ["native"; "smtlib"; "why3"]) in
    let docv = "FMT" in
    Arg.(value & opt (some format_conv) None & info ["i"; "input"] ~docv ~doc)
  in

  let parse_only =
    let doc = "Stop after parsing." in
    Arg.(value & flag & info ["parse-only"] ~docs ~doc) in

  let parsers =
    let doc = "Register a new parser for Alt-Ergo." in
    Arg.(value & opt_all string !vparsers & info ["add-parser"] ~docs ~doc) in

  let preludes =
    let doc =
      "Add a file that will be loaded as a prelude. The command is \
       cumulative, and the order of successive preludes is preserved." in
    Arg.(value & opt_all string !vpreludes & info ["prelude"] ~docs ~doc) in

  let no_locs_in_answers =
    let doc =
      "Do not show the locations of goals when printing solver's answers." in
    Arg.(value & flag & info ["no-locs-in-answers"] ~docs ~doc) in

  let type_only =
    let doc = "Stop after typing." in
    Arg.(value & flag & info ["type-only"] ~docs ~doc) in

  let type_smt2 =
    let doc = "Stop after SMT2 typing." in
    Arg.(value & flag & info ["type-smt2"] ~docs ~doc) in


  Term.(ret (const mk_execution_opt $
             frontend $ input_format $ parse_only $ parsers $ preludes $
             no_locs_in_answers $ type_only $ type_smt2
            ))

let parse_halt_opt =

  let docs = s_halt in

  let version_info =
    let doc = "Print some info about this version." in
    Arg.(value & flag & info ["version-info"] ~docs ~doc) in

  let where =
    let doc = Format.sprintf
        "Print the directory of $(docv). Possible arguments are \
         %s." (Arg.doc_alts ["lib"; "plugins"; "preludes"; "data"; "man"]) in
    let docv = "DIR" in
    Arg.(value & opt (some string) None & info ["where"] ~docv ~docs ~doc) in

  Term.(ret (const halt_opt $
             version_info $ where
            ))

let parse_internal_opt =

  let docs = s_internal in

  let disable_weaks =
    let doc =
      "Prevent the GC from collecting hashconsed data structrures that are \
       not reachable (useful for more determinism)." in
    Arg.(value & flag & info ["disable-weaks"] ~docs ~doc) in

  let enable_assertions =
    let doc = "Enable verification of some heavy invariants." in
    Arg.(value & flag & info ["enable-assertions"] ~docs ~doc) in

  let gc_policy =
    let doc =
      "Set the gc policy allocation. 0 = next-fit policy, 1 = \
       first-fit policy, 2 = best-fit policy. See GC module for more \
       informations." in
    let docv = "PLCY" in
    Arg.(value & opt int 0 & info ["gc-policy"] ~docv ~docs ~doc) in

  Term.(ret (const mk_internal_opt $
             disable_weaks $ enable_assertions $ gc_policy
            ))

let parse_limit_opt =

  let docs = s_limit in

  let age_bound =
    let doc = "Set the age limit bound." in
    let docv = "AGE" in
    Arg.(value & opt int !vage_bound & info ["age-bound"] ~docv ~docs ~doc) in

  let fm_cross_limit =
    (* TODO : Link this to Alt-Ergo numbers *)
    let dv = Numbers.Q.to_string !vfm_cross_limit in
    let doc = Format.sprintf
        "Skip Fourier-Motzkin variables elimination steps that may produce \
         a number of inequalities that is greater than the given limit. \
         However, unit eliminations are always done." in
    let docv = "VAL" in
    Arg.(value & opt string dv & info ["fm-cross-limit"] ~docv ~docs ~doc) in

  let timelimit_interpretation =
    let doc = "Set the time limit to $(docv) seconds for model generation \
               (not supported on Windows)." in
    let docv = "SEC" in
    Arg.(value & opt (some float) None &
         info ["timelimit-interpretation"] ~docv ~docs ~doc) in

  let steps_bound =
    let doc = "Set the maximum number of steps." in
    let docv = "STEPS" in
    Arg.(value & opt int !vsteps_bound &
         info ["S"; "steps-bound"] ~docv ~doc) in

  let timelimit =
    let doc =
      "Set the time limit to $(docv) seconds (not supported on Windows)." in
    let docv = "VAL" in
    Arg.(value & opt (some float) None & info ["t"; "timelimit"] ~docv ~doc) in

  let timelimit_per_goal =
    let doc =
      "Set the given timelimit for each goal, in case of multiple goals per \
       file. In this case, time spent in preprocessing is separated from \
       resolution time. Not relevant for GUI-mode." in
    Arg.(value & flag & info ["timelimit-per-goal"] ~docs ~doc) in

  Term.(ret (const mk_limit_opt $
             age_bound $ fm_cross_limit $ timelimit_interpretation $
             steps_bound $ timelimit $ timelimit_per_goal
            ))

let parse_output_opt =

  let docs = s_output in

  let interpretation =
    let doc =
      "Experimental support for counter-example generation. Possible \
       values are 1, 2, or 3 to compute an interpretation before returning \
       Unknown, before instantiation, or before every decision or \
       instantiation. A negative value (-1, -2, or -3) will disable \
       interpretation display. Note that $(b, --max-split) limitation will \
       be ignored in model generation phase." in
    let docv = "VAL" in
    Arg.(value & opt int !vinterpretation &
         info ["interpretation"] ~docv ~docs ~doc) in

  let model =
    let doc = Format.sprintf
        "Experimental support for models on labeled terms. \
         $(docv) must be %s. %s shows a complete model and %s shows \
         all models."
        (Arg.doc_alts ["none"; "default"; "complete"; "all"])
        (Arg.doc_quote "complete") (Arg.doc_quote "all") in
    let docv = "VAL" in
    Arg.(value & opt model_conv MNone & info ["m"; "model"] ~docv ~doc) in

  let unsat_core =
    let doc = "Experimental support for unsat-cores." in
    Arg.(value & flag & info ["u"; "unsat-core"] ~doc) in

  let output_format =
    let doc =
      Format.sprintf
        "Answer unsat/sat/unknown instead of Valid/Invalid/I don't know. \
         $(docv) must be %s. It must be noticed that not specifying an output \
         format will let Alt-Ergo set it according to the input file's \
         extension."
        (Arg.doc_alts [ "native"; "smtlib" ])
    in
    let docv = "FMT" in
    Arg.(value & opt (some format_conv) None & info ["o"; "output"] ~docv ~doc)
  in

  Term.(ret (const mk_output_opt $
             interpretation $ model $ unsat_core $ output_format
            ))

let parse_profiling_opt =

  let docs = s_profiling in

  let cumulative_time_profiling =
    let doc =
      "Record the time spent in called functions in callers" in
    Arg.(value & flag & info ["cumulative-time-profiling"] ~docs ~doc) in

  let profiling =
    let doc =
      "Activate the profiling module with the given frequency. \
       Use Ctrl-C to switch between different views and \\\"Ctrl \
       + AltGr + \" to exit." in
    let docv = "DELAY" in
    Arg.(value & opt (some float) None & info ["profiling"] ~docv ~docs ~doc) in

  let profiling_plugin =
    let doc = "Use the given profiling plugin." in
    let docv = "PGN" in
    Arg.(value & opt string !vprofiling_plugin &
         info ["profiling-plugin"] ~docv ~docs ~doc) in

  let verbose =
    let doc = "Set the verbose mode." in
    Arg.(value & flag & info ["v"; "verbose"] ~doc) in

  Term.(ret (const mk_profiling_opt $
             cumulative_time_profiling $ profiling $
             profiling_plugin $ verbose
            ))

let parse_quantifiers_opt =

  let docs = s_quantifiers in

  let greedy =
    let doc = "Use all available ground terms in instantiation." in
    Arg.(value & flag & info ["g"; "greedy"] ~doc) in

  let instantiate_after_backjump =
    let doc =
      "Make a (normal) instantiation round after every backjump/backtrack." in
    Arg.(value & flag & info ["inst-after-bj"] ~docs ~doc) in

  let max_multi_triggers_size =
    let doc = "Max number of terms allowed in multi-triggers." in
    let docv = "VAL" in
    Arg.(value & opt int !vmax_multi_triggers_size &
         info ["max-multi-triggers-size"] ~docv ~docs ~doc) in

  let nb_triggers =
    let doc = "Number of (multi)triggers." in
    let docv = "VAL" in
    Arg.(value & opt int !vnb_triggers &
         info ["nb-triggers"] ~docv ~docs ~doc) in

  let no_ematching =
    let doc = "Disable matching modulo ground equalities." in
    Arg.(value & flag & info ["no-ematching"] ~docs ~doc) in

  let no_user_triggers =
    let doc = "Ignore user triggers, except for triggers of theories axioms"; in
    Arg.(value & flag & info ["no-user-triggers"] ~docs ~doc) in

  let normalize_instances =
    let doc =
      "Normalize generated substitutions by matching w.r.t. the state of \
       the theory. This means that only terms that \
       are greater (w.r.t. depth) than the initial terms of the problem are \
       normalized." in
    Arg.(value & flag & info ["normalize-instances"] ~docs ~doc) in

  let triggers_var =
    let doc = "Allows variables as triggers." in
    Arg.(value & flag & info ["triggers-var"] ~docs ~doc) in

  Term.(ret (const mk_quantifiers_opt $ greedy $ instantiate_after_backjump $
             max_multi_triggers_size $ nb_triggers $
             no_ematching $ no_user_triggers $ normalize_instances $
             triggers_var
            ))

let parse_sat_opt =

  let docs = s_sat in

  let bottom_classes =
    let doc = "Show equivalence classes at each bottom of the sat." in
    Arg.(value & flag & info ["bottom-classes"] ~docs ~doc) in

  let disable_flat_formulas_simplification =
    let doc = "Disable facts simplifications in satML's flat formulas." in
    Arg.(value & flag &
         info ["disable-flat-formulas-simplification"] ~docs ~doc) in

  let enable_restarts =
    let doc =
      "For satML: enable restarts or not. Default behavior is 'false'." in
    Arg.(value & flag & info ["enable-restarts"] ~docs ~doc) in

  let no_arith_matching =
    let doc = "Disable (the weak form of) matching modulo linear arithmetic." in
    Arg.(value & flag & info ["no-arith-matching"] ~docs ~doc) in

  let no_backjumping =
    let doc = "Disable backjumping mechanism in the functional SAT solver." in
    Arg.(value & flag & info ["no-backjumping"] ~docs ~doc) in

  let no_backward =
    let doc =
      "Disable backward reasoning step (starting from the goal) done in \
       the default SAT solver before deciding." in
    Arg.(value & flag & info ["no-backward"] ~docs ~doc) in


  let no_decisions =
    let doc = "Disable decisions at the SAT level." in
    Arg.(value & flag & info ["no-decisions"] ~docs ~doc) in

  let no_decisions_on =
    let doc =
      "Disable decisions at the SAT level for the instances generated \
       from the given axioms. Arguments should be separated with a comma." in
    let docv = "[INST1; INST2; ...]" in
    Arg.(value & opt string "" &
         info ["no-decisions-on"] ~docv ~docs ~doc) in

  let no_minimal_bj =
    let doc = "Disable minimal backjumping in satML CDCL solver." in
    Arg.(value & flag & info ["no-minimal-bj"] ~docs ~doc) in

  let no_sat_learning =
    let doc =
      "Disable learning/caching of unit facts in the Default SAT. These \
       facts are used to improve bcp." in
    Arg.(value & flag & info ["no-sat-learning"] ~docs ~doc) in

  let no_tableaux_cdcl_in_instantiation =
    let doc = "When satML is used, this disables the use of a tableaux-like\
               method for instantiations with the CDCL solver." in
    Arg.(value & flag &
         info ["no-tableaux-cdcl-in-instantiation"] ~docs ~doc) in

  let no_tableaux_cdcl_in_theories =
    let doc = "When satML is used, this disables the use of a tableaux-like\
               method for theories with the CDCL solver." in
    Arg.(value & flag & info ["no-tableaux-cdcl-in-theories"] ~docs ~doc) in

  let sat_plugin =
    let doc =
      "Use the given SAT-solver instead of the default DFS-based SAT solver." in
    Arg.(value & opt string !vsat_plugin & info ["sat-plugin"] ~docs ~doc) in

  let sat_solver =
    let doc = Format.sprintf
        "Choose the SAT solver to use. Default value is CDCL (i.e. satML \
         solver). Possible options are %s."
        (Arg.doc_alts ["CDCL"; "satML"; "CDCL-Tableaux";
                       "satML-Tableaux"; "Tableaux-CDCL"])
    in
    let docv = "SAT" in
    Arg.(value & opt string "CDCL-Tableaux" &
         info ["sat-solver"] ~docv ~docs ~doc) in

  Term.(ret (const mk_sat_opt $
             bottom_classes $ disable_flat_formulas_simplification $
             enable_restarts $ no_arith_matching $
             no_backjumping $ no_backward $ no_decisions $ no_decisions_on $
             no_minimal_bj $ no_sat_learning $
             no_tableaux_cdcl_in_instantiation $
             no_tableaux_cdcl_in_theories $ sat_plugin $ sat_solver
            ))

let parse_term_opt =

  let docs = s_term in

  let disable_ites =
    let doc = "Disable handling of ite(s) on terms in the backend." in
    Arg.(value & flag & info ["disable-ites"] ~docs ~doc) in

  let inline_lets =
    let doc =
      "Enable substitution of variables bounds by Let. The default \
       behavior is to only substitute variables that are bound to a \
       constant, or that appear at most once." in
    Arg.(value & flag & info ["inline-lets"] ~docs ~doc) in

  let rewriting =
    let doc = "Use rewriting instead of axiomatic approach." in
    Arg.(value & flag & info ["rwt"; "rewriting"] ~docs ~doc) in

  let term_like_pp =
    let doc = "Output semantic values as terms." in
    Arg.(value & flag & info ["term-like-pp"] ~docs ~doc) in

  Term.(ret (const mk_term_opt $
             disable_ites $ inline_lets $ rewriting $ term_like_pp
            ))

let parse_theory_opt =

  let docs = s_theory in

  let disable_adts =
    let doc = "Disable Algebraic Datatypes theory." in
    Arg.(value & flag & info ["disable-adts"] ~docs ~doc) in

  let inequalities_plugin =
    let doc =
      "Use the given module to handle inequalities of linear arithmetic." in
    Arg.(value & opt string !vinequalities_plugin &
         info ["inequalities-plugin"] ~docs ~doc) in

  let no_ac =
    let doc = "Disable the AC theory of Associative and \
               Commutative function symbols." in
    Arg.(value & flag & info ["no-ac"] ~docs ~doc) in

  let no_contracongru =
    let doc = "Disable contracongru." in
    Arg.(value & flag & info ["no-contracongru"] ~docs ~doc) in

  let no_fm =
    let doc = "Disable Fourier-Motzkin algorithm." in
    Arg.(value & flag & info ["no-fm"] ~docs ~doc) in

  let no_nla =
    let doc = "Disable non-linear arithmetic reasoning (i.e. non-linear \
               multplication, division and modulo on integers and rationals). \
               Non-linear multiplication remains AC." in
    Arg.(value & flag & info ["no-nla"] ~docs ~doc) in

  let no_tcp =
    let doc = "Deactivate BCP modulo theories." in
    Arg.(value & flag & info ["no-tcp"] ~docs ~doc) in

  let no_theory =
    let doc = "Completely deactivate theory reasoning." in
    Arg.(value & flag & info ["no-theory"] ~docs ~doc) in

  let restricted =
    let doc =
      "Restrict set of decision procedures (equality, arithmetic and AC)." in
    Arg.(value & flag & info ["restricted"] ~docs ~doc) in

  let tighten_vars =
    let doc = "Compute the best bounds for arithmetic variables." in
    Arg.(value & flag & info ["tighten-vars"] ~docs ~doc) in

  let use_fpa =
    let doc = "Enable support for floating-point arithmetic." in
    Arg.(value & flag & info ["use-fpa"] ~docs ~doc) in

  Term.(ret (const mk_theory_opt $
             disable_adts $ inequalities_plugin $ no_ac $ no_contracongru $
             no_fm $ no_nla $ no_tcp $ no_theory $ restricted $
             tighten_vars $ use_fpa
            )
       )

let main =

  let file =
    let doc =
      "Source file. Must be suffixed by $(i,.ae), \
       ($(i,.mlw) and $(i,.why) are depreciated, \
       $(i,.smt2) or $(i,.psmt2)." in
    let i = Arg.(info [] ~docv:"FILE" ~doc) in
    Arg.(value & pos ~rev:true 0 (some string) None & i) in

  let doc = "Execute Alt-Ergo on the given file." in
  let exits = Term.default_exits in
  let to_exit = Term.(exit_info ~doc:"on timeout errors" ~max:142 142) in
  let dft_errors = Term.(exit_info ~doc:"on default errors" ~max:1 1) in
  let exits = to_exit :: dft_errors :: exits in

  (* Specify the order in which the sections should appear
     Default behaviour gives an unpleasant result with
     non standard sections appearing before standard ones *)
  let man =
    [
      `S Manpage.s_options;
      `S s_execution;
      `S s_limit;
      `S s_internal;
      `S s_output;
      `S s_context;
      `S s_profiling;
      `S s_sat;
      `S s_quantifiers;
      `S s_term;
      `S s_theory;
      `S s_case_split;
      `S s_halt;
      `S s_debug;
      `S Manpage.s_bugs;
      `P "You can open an issue on: \
          https://github.com/OCamlPro/alt-ergo/issues";
      `Pre "Or you can write to: \n   alt-ergo@ocamlpro.com";
      `S Manpage.s_authors;
      `Pre "CURRENT AUTHORS\n\
           \   Albin Coquereau\n\
           \   Guillaume Bury\n\
           \   Mattias Roux";

      `Pre "ORIGINAL AUTHORS\n\
           \   Sylvain Conchon\n\
           \   Evelyne Contejean\n\
           \   Mohamed Iguernlala\n\
           \   Stephane Lescuyer\n\
           \   Alain Mebsout\n";
    ]
  in

  Term.(ret (const mk_opts $
             file $
             parse_case_split_opt $ parse_context_opt $ parse_dbg_opt $
             parse_execution_opt $ parse_halt_opt $ parse_internal_opt $
             parse_limit_opt $ parse_output_opt $ parse_profiling_opt $
             parse_quantifiers_opt $ parse_sat_opt $ parse_term_opt $
             parse_theory_opt
            )),
  Term.info "alt-ergo" ~version:Version._version ~doc ~exits ~man

let parse_cmdline_arguments () =
  let r = Cmdliner.Term.(eval main) in
  match r with
  | `Ok false -> raise (Exit_options 0)
  | `Ok true -> ()
  | e -> exit @@ Term.(exit_status_of_result e)

let set_file_for_js filename =
  vfile := filename;
  vjs_mode := true

(* Debug options references *)

(* Setters for debug options *)

let set_debug b = vdebug := b
let set_debug_ac b = vdebug_ac := b
let set_debug_adt b = vdebug_adt := b
let set_debug_arith b = vdebug_arith := b
let set_debug_arrays b = vdebug_arrays := b
let set_debug_bitv b = vdebug_bitv := b
let set_debug_cc b = vdebug_cc := b
let set_debug_combine b = vdebug_combine := b
let set_debug_constr b = vdebug_constr := b
let set_debug_explanations b = vdebug_explanations := b
let set_debug_fm b = vdebug_fm := b
let set_debug_gc b = vdebug_gc := b
let set_debug_ite b = vdebug_ite := b
let set_debug_matching i = vdebug_matching := i
let set_debug_sat b = vdebug_sat := b
let set_debug_sat_simple b = vdebug_sat_simple := b
let set_debug_split b = vdebug_split := b
let set_debug_sum b = vdebug_sum := b
let set_debug_types b = vdebug_types := b
let set_debug_typing b = vdebug_typing := b
let set_debug_uf b = vdebug_uf := b
let set_debug_unsat_core b = vdebug_unsat_core := b
let set_debug_use b = vdebug_use := b
let set_rules b = vrules := b

(* Getters for debug options *)

let debug () = !vdebug
let debug_ac () = !vdebug_ac
let debug_adt () = !vdebug_adt
let debug_arith () = !vdebug_arith
let debug_arrays () = !vdebug_arrays
let debug_bitv () = !vdebug_bitv
let debug_cc () = !vdebug_cc
let debug_combine () = !vdebug_combine
let debug_constr () = !vdebug_constr
let debug_explanations () = !vdebug_explanations
let debug_fm () = !vdebug_fm
let debug_fpa () = !vdebug_fpa
let debug_gc () = !vdebug_gc
let debug_interpretation () = !vdebug_interpretation
let debug_ite () = !vdebug_ite
let debug_matching () = !vdebug_matching
let debug_sat () = !vdebug_sat
let debug_sat_simple () = !vdebug_sat_simple
let debug_split () = !vdebug_split
let debug_sum () = !vdebug_sum
let debug_triggers () = !vdebug_triggers
let debug_types () = !vdebug_types
let debug_typing () = !vdebug_typing
let debug_uf () = !vdebug_uf
let debug_unsat_core () = !vdebug_unsat_core
let debug_use () = !vdebug_use
let debug_warnings () = !vdebug_warnings
let rules () = !vrules


let set_max_split b = vmax_split := b

let case_split_policy () = !vcase_split_policy
let enable_adts_cs () = !venable_adts_cs
let max_split () = !vmax_split


let set_save_used_context b = vsave_used_context := b


let set_type_only b = vtype_only := b
let set_type_smt2 b = vtype_smt2 := b
let set_parse_only b = vparse_only := b
let set_frontend s = vfrontend := s


let set_age_bound b = vage_bound := b
let set_fm_cross_limit b = vfm_cross_limit := b
let set_steps_bound b = vsteps_bound := b
let set_timelimit b = vtimelimit := b


let set_model m = vmodel := m
let set_interpretation b = vinterpretation := b
let set_unsat_core b = vunsat_core := b


let set_profiling f b =
  vprofiling := b;
  vprofiling_period := if b then f else 0.

let set_verbose b = vverbose := b


let set_greedy b = vgreedy := b
let set_nb_triggers b = vnb_triggers := b
let set_no_ematching b = vno_ematching := b
let set_no_user_triggers b = vno_user_triggers := b
let set_normalize_instances b = vnormalize_instances := b
let set_triggers_var b = vtriggers_var := b


let set_bottom_classes b = vbottom_classes := b

let set_inline_lets m = vinline_lets := m
let set_rewriting b = vrewriting := b
let set_term_like_pp b = vterm_like_pp := b


let set_no_ac b = vno_ac := b
let set_restricted b = vrestricted := b
let set_no_contracongru b = vno_contracongru := b
let set_no_nla b = vno_nla := b

let set_timers b = vtimers := b
let timers () = !vtimers || !vprofiling

let disable_ites () = !vdisable_ites
let disable_adts () = !vdisable_adts
let js_mode () = !vjs_mode
let type_only () = !vtype_only
let type_smt2 () = !vtype_smt2
let parse_only () = !vparse_only
let frontend () = !vfrontend
let steps_bound () = !vsteps_bound
let no_tcp () = !vno_tcp
let no_decisions () = !vno_decisions
let no_fm () = !vno_fm
let no_theory () = !vno_theory
let tighten_vars () = !vtighten_vars
let age_bound () = !vage_bound
let no_user_triggers () = !vno_user_triggers
let verbose () = !vverbose
let greedy () = !vgreedy
let triggers_var () = !vtriggers_var
let nb_triggers () = !vnb_triggers
let max_multi_triggers_size () = !vmax_multi_triggers_size
let no_ematching () = !vno_ematching
let arith_matching () = !varith_matching
let no_backjumping () = !vno_backjumping
let no_nla () = !vno_nla
let no_ac () = !vno_ac
let no_backward () = !vno_backward
let no_sat_learning () = !vno_sat_learning
let sat_learning () = not (no_sat_learning ())
let no_contracongru () = !vno_contracongru
let term_like_pp () = !vterm_like_pp
let cumulative_time_profiling () = !vcumulative_time_profiling
let model () = !vmodel = MDefault || !vmodel = MComplete
let complete_model () = !vmodel = MComplete
let all_models () = !vmodel = MAll
let interpretation () = !vinterpretation
let fm_cross_limit () = !vfm_cross_limit
let rewriting () = !vrewriting
let unsat_core () = !vunsat_core || !vsave_used_context || !vdebug_unsat_core
let restricted () = !vrestricted
let bottom_classes () = !vbottom_classes
let timelimit () = !vtimelimit
let timelimit_per_goal () = !vtimelimit_per_goal
let timelimit_interpretation () = !vtimelimit_interpretation
let enable_assertions () = !venable_assertions
let profiling () =  !vprofiling
let profiling_period () = !vprofiling_period
let instantiate_after_backjump () = !vinstantiate_after_backjump
let disable_weaks () = !vdisable_weaks
let minimal_bj () = !vminimal_bj
let cdcl_tableaux_inst () = !vcdcl_tableaux_inst
let cdcl_tableaux_th () = !vcdcl_tableaux_th
let cdcl_tableaux () = !vcdcl_tableaux_th || !vcdcl_tableaux_inst
let tableaux_cdcl () = !vtableaux_cdcl
let disable_flat_formulas_simplification () =
  !vdisable_flat_formulas_simplification

let enable_restarts () = !venable_restarts

let replay () = !vreplay
let replay_used_context () = !vreplay_used_context
let replay_all_used_context () = !vreplay_all_used_context
let save_used_context () = !vsave_used_context
let get_file () = !vfile
let get_session_file () = !vsession_file
let get_used_context_file () = !vused_context_file
let sat_plugin () = !vsat_plugin
let parsers () = !vparsers
let sat_solver () = !vsat_solver
let inequalities_plugin () = !vinequalities_plugin
let profiling_plugin () = !vprofiling_plugin
let normalize_instances () = !vnormalize_instances
let use_fpa () = !vuse_fpa
let preludes () = !vpreludes

let can_decide_on s =
  !vno_decisions_on == Util.SS.empty || not (Util.SS.mem s !vno_decisions_on)

let no_decisions_on__is_empty () = !vno_decisions_on == Util.SS.empty

let infer_input_format ()  = !vinfer_input_format
let input_format () = !vinput_format

let answers_with_locs ()  = !vanswers_with_loc
let output_format ()  = !voutput_format
let infer_output_format ()  = !vinfer_output_format
let inline_lets () = !vinline_lets

let set_input_format i = vinput_format := i
let set_output_format o = voutput_format := o

(** particular getters : functions that are immediately executed **************)

let thread_yield = ref (fun () -> ())

let set_thread_yield f = thread_yield := f

let (timeout : (unit -> unit) ref) =
  ref (fun () -> raise Util.Timeout)

let set_timeout f = timeout := f

let exec_thread_yield () = !thread_yield ()
let exec_timeout () = !timeout ()

let tool_req n msg =
  if rules () = n then Format.fprintf fmt "[rule] %s@." msg

(** Simple Timer module **)
module Time = struct

  let u = ref 0.0

  let start () =
    u := MyUnix.cur_time()

  let value () =
    MyUnix.cur_time() -. !u

  let set_timeout ~is_gui tm = MyUnix.set_timeout ~is_gui tm

  let unset_timeout ~is_gui =
    if timelimit() <> 0. then
      MyUnix.unset_timeout ~is_gui

end

(** globals **)

(** open Options in every module to hide polymorphic versions of Stdlib **)
let (<>) (a: int) (b: int) = a <> b
let (=)  (a: int) (b: int) = a = b
let (<)  (a: int) (b: int) = a < b
let (>)  (a: int) (b: int) = a > b
let (<=) (a: int) (b: int) = a <= b
let (>=) (a: int) (b: int) = a >= b

let compare  (a: int) (b: int) = Stdlib.compare a b


(* extra **)

let is_gui = ref None

let set_is_gui b =
  match !is_gui with
  | None -> is_gui := Some b
  | Some _ ->
    Format.eprintf "Error in Options.set_is_gui: is_gui is already set!@.";
    assert false

let get_is_gui () =
  match !is_gui with
  | Some b -> b
  | None ->
    Format.eprintf "Error in Options.get_is_gui: is_gui is not set!@.";
    assert false

let print_output_format fmt msg =
  match output_format () with
  | Smtlib2 -> Format.fprintf fmt "; %s" msg;
  | Native | Why3 | Unknown _ -> Format.fprintf fmt "%s" msg;
