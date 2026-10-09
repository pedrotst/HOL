structure TacticLeafSource :> TacticLeafSource =
struct

open TacticParse

datatype source = Verbatim of string | Synthesised of string

fun sourceText (Verbatim s) = s
  | sourceText (Synthesised s) = s

fun textAt text (s, e) = String.substring (text, s, e - s)

(* `ProofStepPlan' keeps a leaf's enclosing Group and `linearize'
   discards it, so strip before dispatching and both callers agree. *)
fun stripGroup (Group (_, _, e)) = stripGroup e
  | stripGroup (RepairGroup (_, _, e, _)) = stripGroup e
  | stripGroup e = e

fun leafSource text leaf = let
  val txt = textAt text
  fun synth s = SOME (Synthesised s)
  (* Whatever the constructor did not claim: the user's own source if
     the leaf spans a whole expression, else the inverse printer. *)
  fun printed () =
      case topSpan leaf of
          SOME span => SOME (Verbatim (txt span))
        | NONE => Option.map Synthesised (printTacAsSML text leaf)
  (* `by' proves its assertion with `tac THEN NO_TAC', so the surface
     form of an empty body cannot go through; `byA' is the applicative
     equivalent that leaves the assertion standing. *)
  fun applicative name quotation body =
      case stripGroup body of
          Then [] => synth ("BasicProvers." ^ name ^ " (" ^ txt quotation ^
                            ", Tactical.ALL_TAC)")
        | _ => printed ()
  in
    case stripGroup leaf of
        Subgoal span      => synth ("BasicProvers.subgoal " ^ txt span)
      | Rename span       => synth ("Q.RENAME_TAC " ^ txt span)
      | LSelectGoal span  => synth ("Q.SELECT_GOAL_LT " ^ txt span)
      | LSelectGoals span => synth ("Q.SELECT_GOALS_LT " ^ txt span)
      | By (quotation, _, body) => applicative "byA" quotation body
      | SufficesBy (quotation, _, body) =>
          applicative "suffices_byA" quotation body
      | _ => printed ()
  end

(* Enumerated rather than read off `isTac', which also answers false
   for OOpaque -- a tactic sitting in a tactic list -- and so would
   misroute it. *)
fun fragmentLeafKind leaf =
    case stripGroup leaf of
        LReverse => ProofStepPlan.ListTacticLeaf
      | LSelectGoal _ => ProofStepPlan.ListTacticLeaf
      | LSelectGoals _ => ProofStepPlan.ListTacticLeaf
      | LFirst [] => ProofStepPlan.ListTacticLeaf
      | LTacsToLT _ => ProofStepPlan.ListTacticLeaf
      | LOpaque _ => ProofStepPlan.ListTacticLeaf
      | _ => ProofStepPlan.TacticLeaf

end
