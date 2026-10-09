signature TacticLeafSource =
sig

datatype source = Verbatim of string | Synthesised of string

val sourceText: source -> string

val leafSource: string -> (int * int) TacticParse.tac_expr -> source option

val fragmentLeafKind:
  (int * int) TacticParse.tac_expr -> ProofStepPlan.leaf_kind

end

(* ----------------------------------------------------------------------
    Overview
   ----------------------------------------------------------------------

    Lowering a leaf of a tactic tree to SML source that compiles and
    runs: for `TacticWalker' in the LSP, and for any consumer of a
    `ProofStepPlan.plan'.  Asked for in HOL#2069.

    `TacticParse.printTacAsSML' is not enough on its own, as its own
    documentation says: the output is surface syntax, so it assumes the
    opens a script normally has.  Worse, a `By' leaf renders as
    `q by ALL_TAC', which always fails -- `by' discharges its assertion
    with `tac THEN NO_TAC' -- where the applicative
    `BasicProvers.byA' is what a plan wants.

    leafSource text e answers NONE for a leaf that is a semantic no-op,
    so a caller can substitute the identity for its kind;
    SOME (Verbatim s) when the leaf spans a whole expression and s is
    the user's own source; and SOME (Synthesised s) when s had to be
    made up, in which case its names are qualified.  The distinction
    matters: Verbatim source failing to compile is the file's own
    problem, while Synthesised source failing to compile is a bug here.

    Groups are stripped before dispatch, so either shape of the same
    leaf gets the same answer -- `ProofStepPlan' keeps a leaf's
    enclosing Group, `TacticParse.linearize' discards it.  That also
    keeps a `>>~-' selector honest, its Group spanning only the
    pattern.

    Synthesised: Subgoal, Rename, LSelectGoal and LSelectGoals, whose
    annotation covers an operand rather than a tactic, and By /
    SufficesBy with an empty body.  Everything else goes through
    topSpan and then printTacAsSML, whose remaining names all live in
    Tactical and so need no opens.  A By with a non-empty body is left
    to that path deliberately: its surface rendering is right, and
    neither consumer produces one.

    fragmentLeafKind classifies a leaf that arrived with no position to
    say which it is, as when one is pulled out of a `tac_frag' walk.
    It is enumerated rather than read off `TacticParse.isTac', which
    answers false for OOpaque -- a tactic in a tactic list -- and would
    misroute it.  A `ProofStepPlan' consumer should read its own
    `Leaf's `kind' instead, decided by the position the leaf was found
    in.
   ---------------------------------------------------------------------- *)
