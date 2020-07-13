(*
 * Properties of RenamingTheory for our syntax
 *)
open preamble totoTheory comparisonTheory ternaryComparisonsTheory mlstringTheory
     holSyntaxLibTheory holSyntaxTheory holSyntaxExtraTheory
     holSyntaxRenamingTheory

val _ = temp_delsimps ["lift_disj_eq", "lift_imp_disj"]

val _ = new_theory"holSyntaxRenamingTyvar"

val _ = temp_delsimps ["NORMEQ_CONV"]
val _ = diminish_srw_ss ["ABBREV"]
val _ = set_trace "BasicProvers.var_eq_old" 1

(* TODO replace with REWRITE_RULE[Once MONO_NOT_EQ] *)
fun ccontr_equiv(x) =
  let val (a,b) = EQ_IMP_RULE (SPEC_ALL x)
  in GEN_ALL (IMP_ANTISYM_RULE (CONTRAPOS b) (CONTRAPOS a)) end;

(* overloads for set operations on lists *)

val _ = Parse.add_infix("∩", 401, Parse.NONASSOC)
Overload "∩" = ``λs t. list_inter s t``
val _ = Parse.add_infix("\\", 401, Parse.NONASSOC)
Overload "\\" = ``λs t. list_complement s t``
val _ = Parse.add_infix("∪", 401, Parse.NONASSOC)
Overload "∪" = ``λs t. LIST_UNION s t``
val _ = Parse.add_infix("⊆", 401, Parse.NONASSOC)
Overload "⊆" = ``λs t. list_subset s t``

(* general properties of pairs *)

Theorem FST_SND_PAIR_MAP:
  !f g. FST o (f ## g) = f o FST
  /\ !f g. SND o (f ## g) = g o SND
Proof
  rw[SND_PAIR_MAP,FST_PAIR_MAP,FUN_EQ_THM,o_DEF]
QED

Theorem MEM_MAP_SWAP':
  !x s. MEM x (MAP SWAP s) = MEM (SWAP x) s
Proof
  rw[MEM_MAP,EQ_IMP_THM]
  >- fs[SWAP_def]
  >> goal_assum (first_assum o mp_then Any mp_tac)
  >> fs[SWAP_def]
QED

Theorem MEM_MAP_SWAP:
  !x s. MEM (SWAP x) (MAP SWAP s) = MEM x s
Proof
  Cases >> rename1`(x,y)`
  >> qspec_then `(y,x)` assume_tac MEM_MAP_SWAP'
  >> fs[SWAP_def]
QED

Triviality EVERY_MEM_SWAP_eq:
  !s. EVERY (λx. MEM (SWAP x) s) s ⇔  set (MAP SWAP s) = set s
Proof
  rw[EQ_IMP_THM,EVERY_MEM,pred_setTheory.EXTENSION,FORALL_AND_THM]
  >- fs[MEM_MAP]
  >- fs[MEM_MAP_SWAP']
  >> fs[MEM_MAP_SWAP']
QED

Theorem SWAP_EQ_FST_SND:
  !x. SWAP x = x ⇔  FST x = SND x
Proof
  Cases >> rw[EQ_IMP_THM]
  >> fs[SWAP_def]
QED

Theorem SWAP_eq:
  SWAP = λ(x,y). (y,x)
Proof
  fs[FUN_EQ_THM,SWAP_def,ELIM_UNCURRY]
QED

Theorem FST_SND_SWAP:
  FST o SWAP = SND
  /\ SND o SWAP = FST
Proof
  rw[FUN_EQ_THM,SWAP_def]
QED

Theorem MAP_INVOL:
  !f xs ys. INVOL f ==> (MAP f xs = ys) = (xs = MAP f ys)
Proof
  rw[INVOL_DEF,EQ_IMP_THM]
  >> TRY (qpat_x_assum `MAP _ = _` (assume_tac o GSYM))
  >> fs[MAP_MAP_o]
QED

Theorem SWAP_SWAP_INVOL:
  SWAP o SWAP = I
Proof
  rw[FUN_EQ_THM,SWAP_def]
QED

val MAP_SWAP = REWRITE_RULE[INVOL_DEF,SWAP_SWAP_INVOL]
  (SPEC ``SWAP:'a#'a->'a#'a`` (INST_TYPE [alpha |-> ``:'a#'a``] MAP_INVOL))

Theorem MEM_APPEND_SND_lemma:
  !a b c d x y.
    a ++ [x] ++ b = c ++ [y] ++ d
    ∧ ¬MEM (SND x) (MAP SND a) ∧ ¬MEM (SND y) (MAP SND c)
    ∧ SND x = SND y
    ==> a = c
Proof
  rw[]
  >> imp_res_tac (CONTRAPOS (SPEC_ALL (Q.ISPEC `SND` MEM_MAP_f)))
  >> qspecl_then [`a`,`[x]++b`,`c`,`[y]++d`]
      assume_tac (INST_TYPE [alpha |-> ``:'a#'b``] (REWRITE_RULE[IS_PREFIX_APPEND] APPEND_EQ_APPEND_IS_PREFIX))
  >> rfs[] >> rveq >> fs[]
  >> Cases_on `l`
  >> rfs[] >> rveq >> fs[]
QED

Theorem MEM_APPEND_FST_lemma:
  !a b c d x y.
    a ++ [x] ++ b = c ++ [y] ++ d
    ∧ ¬MEM (FST x) (MAP FST a) ∧ ¬MEM (FST y) (MAP FST c)
    ∧ FST x = FST y
    ==> a = c
Proof
  rw[]
  >> imp_res_tac (CONTRAPOS (SPEC_ALL (Q.ISPEC `FST` MEM_MAP_f)))
  >> qspecl_then [`a`,`[x]++b`,`c`,`[y]++d`]
      assume_tac (INST_TYPE [alpha |-> ``:'a#'b``] (REWRITE_RULE[IS_PREFIX_APPEND] APPEND_EQ_APPEND_IS_PREFIX))
  >> rfs[] >> rveq >> fs[]
  >> Cases_on `l`
  >> rfs[] >> rveq >> fs[]
QED

Theorem ALOOKUP_MEM_eq:
  !s x y. (ALOOKUP s x = SOME y)
  = ?pfx sfx. s = pfx ++ [(x,y)] ++ sfx /\ ~MEM x (MAP FST pfx)
Proof
  Induct >- fs[ALOOKUP_def]
  >> rw[EQ_IMP_THM]
  >> rename1`h::s`
  >> Cases_on `h`
  >> fs[ALOOKUP_def]
  >> FULL_CASE_TAC
  >> fs[]
  >- (
    qexists_tac `[]`
    >> fs[]
  )
  >- (
    res_tac
    >> qexists_tac `(q,r)::pfx`
    >> fs[]
  )
  >- (
    qmatch_asmsub_rename_tac `pfx ++ [_] ++ sfx`
    >> Cases_on `pfx`
    >> fs[MEM_MAP]
    >> qmatch_assum_rename_tac`(_,_)=h`
    >> first_x_assum (qspec_then `h` assume_tac)
    >> rveq
    >> fs[]
  )
  >- (
    qmatch_asmsub_rename_tac `pfx ++ [_] ++ sfx`
    >> Cases_on `pfx` >> fs[]
    >> ONCE_REWRITE_TAC[CONJ_COMM]
    >> asm_exists_tac
    >> fs[]
  )
QED

Theorem MEM_ALOOKUP_INJ:
   !f g xs x v. (!x y. f x = f y ==> x = y) /\ (!x y. g x = g y ==> x = y)
   ==> (ALOOKUP (MAP (f ## g) xs) (f x) = SOME (g v))
     = (ALOOKUP xs x = SOME v)
Proof
  NTAC 2 strip_tac
  >> Induct
  >> rw[PAIR_MAP]
  >- (
    Cases_on `h`
    >> fs[EQ_IMP_THM,ALOOKUP_def]
  )
  >> Cases_on `h`
  >> fs[ALOOKUP_def]
  >> FULL_CASE_TAC
  >> rw[]
QED

Theorem MEM_SPLIT_APPEND_FST_first:
  !s x. MEM x (MAP FST s) ==>
  ?pfx sfx q. s = pfx ++ [(x,q)] ++ sfx /\ ~MEM x (MAP FST pfx)
Proof
  rpt strip_tac
  >> pop_assum (assume_tac o PURE_ONCE_REWRITE_RULE [MEM_SPLIT_APPEND_first])
  >> fs[]
  >> rename1 `pfx ++ [x] ++ sfx`
  >> qexists_tac `TAKE (LENGTH pfx) s`
  >> qexists_tac `DROP (SUC (LENGTH pfx)) s`
  >> qexists_tac `EL (LENGTH pfx) (MAP SND s)`
  >> ONCE_REWRITE_TAC[GSYM ZIP_MAP_FST_SND_EQ]
  >> fs[MAP_APPEND,MAP_ZIP,MAP_TAKE]
  >> NTAC 2 (ONCE_REWRITE_TAC[GSYM APPEND_ASSOC])
  >> REWRITE_TAC[TAKE_LENGTH_APPEND,GEN_ALL MAP_DROP]
  >> qspec_then `LENGTH pfx` assume_tac LESS_EQ_SUC_REFL
  >> fs[DROP_APPEND2,ADD1]
  >> `LENGTH pfx < LENGTH (MAP SND s)` by (
    fs[LENGTH_MAP]
    >> ONCE_REWRITE_TAC[Q.ISPEC `FST` (CONV_RULE SWAP_FORALL_CONV (GSYM LENGTH_MAP))]
    >> ASM_REWRITE_TAC[]
    >> fs[]
  )
  >> imp_res_tac (GSYM TAKE1_DROP)
  >> ASM_REWRITE_TAC[GSYM TAKE_SUM]
  >> fs[TAKE_DROP]
QED

Theorem MEM_Tyvar_MAP_Tyvar:
  !l x. MEM (Tyvar x) (MAP Tyvar l) = MEM x l
Proof
  match_mp_tac MEM_f_MAP_f_INJ
  >> fs[]
QED

Theorem ALL_DISTINCT_FST_MEMs:
  !x v w s. ALL_DISTINCT (MAP FST s)
  /\ MEM (x,v) s /\ MEM (x,w) s
  ==> v = w
Proof
  rw[]
  >> qpat_x_assum `MEM _ s` (assume_tac o REWRITE_RULE[MEM_SPLIT])
  >> fs[]
  >> `~MEM x (MAP FST l1) /\ ~MEM x (MAP FST l2)` by (
    imp_res_tac (Q.ISPEC `FST` MEM_MAP_f)
    >> fs[ALL_DISTINCT_APPEND]
  )
  >> `~MEM (x,v) l1 /\ ~MEM (x,v) l2` by (
    CCONTR_TAC
    >> fs[]
    >> imp_res_tac (Q.ISPEC `FST` MEM_MAP_f)
    >> fs[]
  )
  >> fs[]
QED

Theorem ALL_DISTINCT_SND_MEMs:
  !x v w s. ALL_DISTINCT (MAP SND s)
  /\ MEM (v,x) s /\ MEM (w,x) s
  ==> v = w
Proof
  ONCE_REWRITE_TAC[GSYM FST_SND_SWAP]
  >> rw[GSYM MAP_MAP_o]
  >> imp_res_tac (Q.ISPEC `SWAP` MEM_MAP_f)
  >> fs[SWAP_def]
  >> match_mp_tac ALL_DISTINCT_FST_MEMs
  >> goal_assum (first_assum o mp_then Any mp_tac)
  >> fs[]
QED

(* properties of set functions for lists (e.g. list_inter, LIST_UNION) *)

Theorem NULL_list_inter_INJ:
  !f l1 l2.  (!x y. f x = f y ==> x = y) ==>
  NULL (list_inter (MAP f l1) (MAP f l2)) = NULL (list_inter l1 l2)
Proof
  rw[NULL_FILTER,list_inter_def,EQ_IMP_THM]
  >- (
    dxrule MEM_MAP_f
    >> CCONTR_TAC
    >> fs[]
    >> imp_res_tac MEM_MAP_f
    >> imp_res_tac MEM_f_MAP_f_INJ
    >> rpt (first_x_assum (qspec_then `f` assume_tac))
    >> res_tac
  )
  >> CCONTR_TAC
  >> fs[MEM_MAP]
  >> rveq
  >> res_tac
  >> fs[]
QED

Theorem NULL_list_inter_MAP_Tyvar:
  !l1 l2. NULL (list_inter (MAP Tyvar l1) (MAP Tyvar l2)) = NULL (list_inter l1 l2)
Proof
  rw[NULL_list_inter_INJ]
QED

Theorem list_subset_id:
  !l. list_subset l l
Proof
  fs[list_subset_def,EVERY_MEM]
QED

Theorem list_complement_MAP_Tyvar:
  !a b. MAP Tyvar (list_complement a b) = (list_complement (MAP Tyvar a) (MAP Tyvar b))
Proof
  rw[]
  >> match_mp_tac list_complement_MAP_INJ
  >> fs[]
QED

Theorem LIST_INSERT_MAP_Tyvar:
  !a b. MAP Tyvar (LIST_INSERT a b) = (LIST_INSERT (Tyvar a) (MAP Tyvar b))
Proof
  CONV_TAC SWAP_FORALL_CONV
  >> Induct
  >> rw[LIST_INSERT_def]
  >> assume_tac (Q.ISPEC `Tyvar` MEM_f_MAP_f_INJ)
  >> fs[]
QED

Theorem LIST_UNION_MAP_Tyvar:
  !a b. MAP Tyvar (LIST_UNION a b) = LIST_UNION (MAP Tyvar a) (MAP Tyvar b)
Proof
  Induct
  >> rw[LIST_UNION_def]
  >> fs[LIST_INSERT_MAP_Tyvar,GSYM LIST_UNION_def]
QED

Theorem list_inter_LIST_UNION_NULL:
  !a b c. NULL (list_inter a (LIST_UNION b c))
  = (NULL (list_inter a b) /\ NULL (list_inter a c))
Proof
  rw[NULL_FILTER,list_inter_def]
  >> rw[EQ_IMP_THM]
  >> fs[]
QED

Theorem MEM_LIST_UNION:
  !x a b. MEM x (LIST_UNION a b) = (MEM x a \/ MEM x b)
Proof
  fs[set_LIST_UNION]
QED


(*
(* bijective renamings *)

Definition rename_bij_def:
  rename_bij s = (
    EVERY (λx. MEM (SWAP x) s) s
    ∧ EVERY (UNCURRY $≠) s
    ∧ ALL_DISTINCT (MAP SND s)
    ∧ ALL_DISTINCT (MAP FST s)
  )
End

Theorem rename_bij_SWAP_IMP:
  !s. rename_bij s ⇒ rename_bij (MAP SWAP s)
Proof
  rw[rename_bij_def]
  >> fs[FST_SND_SWAP,MAP_MAP_o]
  >- (
    fs[EVERY_MEM,ELIM_UNCURRY]
    >> fs[MEM_MAP_SWAP]
    >> rw[MEM_MAP_SWAP']
    >> res_tac
    >> fs[SWAP_def]
  )
  >> fs[EVERY_MEM,ELIM_UNCURRY]
  >> rw[MEM_MAP_SWAP']
  >> res_tac
  >> fs[SWAP_def]
QED

Theorem rename_bij_MEM_MAP_eq:
  !s. rename_bij s ⇒
  !x. MEM x (MAP FST s) ⇔ MEM x (MAP SND s)
Proof
  rw[rename_bij_def,EVERY_MEM,EQ_IMP_THM]
  >- (
    qpat_x_assum `MEM _ (MAP FST _)` (strip_assume_tac o REWRITE_RULE[MEM_MAP])
    >> last_x_assum (drule_then strip_assume_tac)
    >> drule_then assume_tac (Q.ISPEC `SND:'a # 'b -> 'b` MEM_MAP_f)
    >> fs[SWAP_def]
  )
  >> qpat_x_assum `MEM _ (MAP SND _)` (strip_assume_tac o REWRITE_RULE[MEM_MAP])
  >> last_x_assum (drule_then strip_assume_tac)
  >> drule_then assume_tac (Q.ISPEC `FST:'a # 'b -> 'a` MEM_MAP_f)
  >> fs[SWAP_def]
QED

(* lift rename_bij to type variables *)

Definition var_renaming_def:
  var_renaming s =
    (rename_bij s ∧ EVERY (λ(x,y). ∃a. x = Tyvar a) s)
End

Theorem var_renaming_eq:
  !s. var_renaming s =
    (rename_bij s ∧ EVERY (λx. ∃a b. x = (Tyvar a,Tyvar b)) s)
Proof
  fs[EQ_IMP_THM,var_renaming_def,FORALL_AND_THM,GSYM AND_IMP_INTRO]
  >> conj_tac
  >- (
    rw[EVERY_MEM,rename_bij_def,ELIM_UNCURRY]
    >> qpat_x_assum `!x. MEM _ _ ⇒ MEM (SWAP _) _` (drule_then strip_assume_tac)
    >> qpat_assum `!x. MEM _ _ ⇒ ?x. _` (dxrule_then strip_assume_tac)
    >> qpat_x_assum `!x. MEM _ _ ⇒ ?x. _` (dxrule_then strip_assume_tac)
    >> Cases_on `x`
    >> fs[SWAP_def]
  )
  >> ntac 2 strip_tac
  >> match_mp_tac (Ho_Rewrite.REWRITE_RULE[PULL_FORALL] EVERY_MONOTONIC)
  >> rw[ELIM_UNCURRY]
  >> fs[]
QED

Theorem var_renaming_SWAP_IMP:
  var_renaming s ⇒ var_renaming (MAP SWAP s)
Proof
 rw[var_renaming_eq,rename_bij_SWAP_IMP]
 >> fs[EVERY_MEM,MEM_MAP_SWAP']
 >> rw[]
 >> res_tac
 >> Cases_on `x`
 >> fs[SWAP_def]
QED

Theorem var_renaming_idem:
  !s t. var_renaming s ⇒ TYPE_SUBST s (TYPE_SUBST s t) = t
Proof
  rw[TYPE_SUBST_compose]
  >> CONV_TAC (RHS_CONV(PURE_ONCE_REWRITE_CONV [GSYM TYPE_SUBST_NIL]))
  >> rw[TYPE_SUBST_tyvars,REV_ASSOCD_def]
  >> Cases_on `MEM (Tyvar x) (MAP SND s)`
  >- (
    dxrule_then strip_assume_tac MEM_SPLIT_APPEND_SND_first
    >> `?y. q = Tyvar y` by (
      fs[var_renaming_eq]
    )
    >> VAR_EQ_TAC
    >> `TYPE_SUBST (MAP (TYPE_SUBST s ## I) s ++ s) (Tyvar x) = TYPE_SUBST s (Tyvar y)` by (
      `¬MEM (Tyvar x) (MAP SND ((MAP (TYPE_SUBST s ## I) pfx)))` by (
        REWRITE_TAC[MEM_MAP,PAIR_MAP,DISJ_EQ_IMP]
        >> CCONTR_TAC
        >> fs[]
        >> imp_res_tac (Q.ISPEC `SND` MEM_MAP_f)
        >> fs[]
      )
      >> dxrule TYPE_SUBST_drop_prefix
      >> fs[]
      >> qmatch_goalsub_abbrev_tac `REV_ASSOCD _ (mpfx ++ a ++ msfx ++ pfx ++ b ++ sfx)`
      >> PURE_REWRITE_TAC[GSYM APPEND_ASSOC]
      >> disch_then (ONCE_REWRITE_TAC o single)
      >> qunabbrev_tac`a`
      >> fs[REV_ASSOCD_def]
    )
    >> pop_assum (fn x => PURE_REWRITE_TAC [REWRITE_RULE[TYPE_SUBST_def] x])
    >> `MEM (Tyvar x,Tyvar y) s` by (
      fs[var_renaming_eq,rename_bij_def]
      >> fs[SWAP_def]
    )
    >> qpat_x_assum `¬MEM _ _` kall_tac
    >> qpat_x_assum `_ = _` kall_tac
    >> fs[REV_ASSOCD_ALOOKUP,var_renaming_eq,rename_bij_def]
    >> qpat_x_assum `ALL_DISTINCT (MAP FST _)` kall_tac
    >> fs[Once (GSYM FST_SND_SWAP),GSYM MAP_MAP_o]
    >> dxrule_then strip_assume_tac (Ho_Rewrite.REWRITE_RULE[EQ_IMP_THM,FORALL_AND_THM] MEM_MAP_SWAP |> CONJUNCT2)
    >> fs[SWAP_def]
    >> drule_all ALOOKUP_ALL_DISTINCT_MEM
    >> fs[SWAP_eq]
  )
  >> `¬MEM (Tyvar x) (MAP SND ((MAP (TYPE_SUBST s ## I) s) ++ s))` by (
    fs[MEM_MAP,PAIR_MAP,DISJ_EQ_IMP]
  )
  >> dxrule_then strip_assume_tac TYPE_SUBST_drop_all
  >> fs[]
QED

Theorem var_renaming_MEM_TYPE_SUBST:
  !s x y. MEM (x,Tyvar y) s ∧ var_renaming s
  ⇒ TYPE_SUBST s (Tyvar y) = x
Proof
  rw[]
  >> imp_res_tac (Q.ISPEC `SND` MEM_MAP_f)
  >> fs[]
  >> dxrule_then strip_assume_tac TYPE_SUBST_MEM_MAP_SND
  >> `x = b` by (
    fs[var_renaming_eq,rename_bij_def]
    >> dxrule_then drule ALL_DISTINCT_SND_MEMs
    >> fs[]
  )
  >> fs[]
QED

Theorem var_renaming_MEM_REV_ASSOCD =
  REWRITE_RULE[TYPE_SUBST_def]var_renaming_MEM_TYPE_SUBST

Theorem var_renaming_NOT_MEM_TYPE_SUBST:
  !s. var_renaming s ⇒
  !x y. ¬MEM (Tyvar y) (MAP SND s) ⇔ TYPE_SUBST s (Tyvar y) = Tyvar y
Proof
  rw[EQ_IMP_THM]
  >- (dxrule TYPE_SUBST_drop_all >> fs[])
  >> CCONTR_TAC >> fs[MEM_MAP]
  >> rename1`MEM xx _`
  >> PairCases_on `xx`
  >> fs[] >> rveq
  >> drule_all_then assume_tac var_renaming_MEM_REV_ASSOCD
  >> fs[var_renaming_eq,rename_bij_def,EVERY_MEM]
  >> res_tac >> fs[]
QED

Theorem var_renaming_SWAP_inv:
  !s. var_renaming s ⇒
  !t. TYPE_SUBST (MAP SWAP s) t = TYPE_SUBST s t
Proof
  rw[TYPE_SUBST_tyvars]
  >> Cases_on `MEM (Tyvar x) (MAP SND s)`
  >- (
    fs[MEM_MAP]
    >> Cases_on `y`
    >> fs[] >> rveq
    >> drule_all var_renaming_MEM_REV_ASSOCD
    >> disch_then (fs o single)
    >> `MEM (q, Tyvar x) (MAP SWAP s)` by (
      fs[var_renaming_eq,rename_bij_def]
      >> last_x_assum ((dxrule_then strip_assume_tac) o REWRITE_RULE[EVERY_MEM])
      >> fs[GSYM MEM_MAP_SWAP']
    )
    >> dxrule_then assume_tac var_renaming_SWAP_IMP
    >> fs[var_renaming_MEM_REV_ASSOCD]
  )
  >> drule TYPE_SUBST_drop_all
  >> `~MEM (Tyvar x) (MAP SND (MAP SWAP s))` by (
    fs[var_renaming_eq,rename_bij_def,EVERY_MEM,MAP_MAP_o,FST_SND_SWAP]
    >> goal_assum (strip_assume_tac o REWRITE_RULE[MEM_MAP])
    >> qpat_x_assum `~MEM _ _` mp_tac
    >> fs[MEM_MAP]
    >> last_x_assum (dxrule_then strip_assume_tac)
    >> goal_assum (first_assum o mp_then Any mp_tac)
    >> fs[SWAP_def]
  )
  >> drule TYPE_SUBST_drop_all
  >> fs[]
QED

(* var_renaming may be invalidated by composition *)

Triviality var_renaming_non_compose:
  ?r s. var_renaming s ∧ var_renaming r
  ∧ ~var_renaming (MAP (TYPE_SUBST s ## I) r ++ s)
Proof
  (* r = (a x)(b c), s = (b x), s o r = (a b c x) *)
  map_every qexists_tac [`(Tyvar «a»,Tyvar «x»)::(Tyvar «x»,Tyvar «a»)::(Tyvar «b»,Tyvar «c»)::(Tyvar «c»,Tyvar «b»)::[]`,
`(Tyvar «b»,Tyvar «x»)::(Tyvar «x»,Tyvar «b»)::[]`]
  >> fs[var_renaming_def,rename_bij_def,SWAP_def]
  >> rw[pred_setTheory.EXTENSION,EQ_IMP_THM]
QED
*)

(* new start *)
(* new start *)
(* new start *)
(* new start *)
(* new start *)

(* TODO put somewhere else *)
Theorem UNION_DIFF_EQ:
  !s t. ((s:'a -> bool) ∪ (t DIFF s)) = (s ∪ t)
Proof
  rw[pred_setTheory.EXTENSION,EQ_IMP_THM] >> fs[]
QED

Theorem CARD_LIST_TO_SET_ALL_DISTINCT_eq =
  CONJ
    (SPEC ``ls:'a list`` CARD_LIST_TO_SET_ALL_DISTINCT)
    (SPEC ``ls:'a list`` ALL_DISTINCT_CARD_LIST_TO_SET)
  |> REWRITE_RULE[GSYM EQ_IMP_THM]
  |> GEN_ALL

Theorem ALL_DISTINCT_set_eq:
  !A B. ALL_DISTINCT A
  ∧ LENGTH A = LENGTH B
  ∧ set A = set B
  ⇒ ALL_DISTINCT B
Proof
  rpt strip_tac
  >> fs[GSYM CARD_LIST_TO_SET_ALL_DISTINCT_eq,EQ_SYM_EQ]
QED

Definition rename_bij_def:
  rename_bij s =
    (set (MAP FST s) = set (MAP SND s)
    ∧ EVERY (UNCURRY $<>) s
    ∧ ALL_DISTINCT (MAP SND s))
End

Theorem rename_bij_ALL_DISTINCT_FST:
  !s. rename_bij s⇒ ALL_DISTINCT (MAP FST s)
Proof
  rw[rename_bij_def]
  >> drule_then match_mp_tac ALL_DISTINCT_set_eq
  >> fs[]
QED

Theorem rename_bij_SWAP_IMP:
  !s. rename_bij s ⇒ rename_bij (MAP SWAP s)
Proof
  rpt strip_tac
  >> drule_then assume_tac rename_bij_ALL_DISTINCT_FST
  >> fs[FST_SND_SWAP,MAP_MAP_o,EVERY_MAP,rename_bij_def]
  >> qpat_x_assum `EVERY _ _` mp_tac
  >> match_mp_tac (Ho_Rewrite.REWRITE_RULE[PULL_FORALL] EVERY_MONOTONIC)
  >> fs[SWAP_def,ELIM_UNCURRY]
QED

Theorem rename_bij_def_imps =
  Ho_Rewrite.REWRITE_RULE[EQ_IMP_THM,FORALL_AND_THM,IMP_CONJ_THM] rename_bij_def
  |> CONJUNCT1

Theorem rename_bij_MEM_REV_ASSOCD:
  !s x. MEM x s ∧ rename_bij s
  ⇒ REV_ASSOCD (SND x) s (SND x) = FST x
Proof
  rw[]
  >> imp_res_tac (Q.ISPEC `SND` MEM_MAP_f)
  >> drule_then strip_assume_tac MEM_SPLIT_APPEND_SND_first
  >> rveq
  >> ONCE_REWRITE_TAC[GSYM APPEND_ASSOC]
  >> dxrule_then (REWRITE_TAC o single) REV_ASSOCD_drop_prefix
  >> qpat_x_assum `MEM _ (MAP _ _)` kall_tac
  >> dxrule_then assume_tac (List.nth(CONJUNCTS rename_bij_def_imps,2))
  >> rw[REV_ASSOCD_def]
  >> fs[ALL_DISTINCT_APPEND,DISJ_IMP_THM,FORALL_AND_THM]
  >> TRY (dxrule (Q.ISPEC `SND` MEM_MAP_f)) >> fs[]
  >> qmatch_goalsub_abbrev_tac `FST x` >> Cases_on `x` >> fs[]
QED

Theorem rename_bij_NOT_MEM_REV_ASSOCD:
  !s. rename_bij s ⇒
  !y. ¬MEM y (MAP SND s) ⇔ REV_ASSOCD y s y = y
Proof
  rw[EQ_IMP_THM]
  >- (dxrule REV_ASSOCD_NOT_MEM_drop >> fs[])
  >> CCONTR_TAC >> fs[MEM_MAP]
  >> drule_all_then assume_tac rename_bij_MEM_REV_ASSOCD
  >> fs[rename_bij_def,EVERY_MEM]
  >> res_tac >> fs[ELIM_UNCURRY]
QED

Theorem rename_bij_SWAP_id:
  !s t. rename_bij s ⇒
  REV_ASSOCD (REV_ASSOCD t s t) (MAP SWAP s) (REV_ASSOCD t s t) = t
Proof
  rw[]
  >> Cases_on `MEM t (MAP SND s)`
  >- (
    fs[MEM_MAP]
    >> drule_all_then strip_assume_tac rename_bij_MEM_REV_ASSOCD
    >> ASM_REWRITE_TAC[]
    >> ONCE_REWRITE_TAC[GSYM FST_SND_SWAP]
    >> fs[o_DEF]
    >> match_mp_tac rename_bij_MEM_REV_ASSOCD
    >> fs[rename_bij_SWAP_IMP,MEM_MAP_SWAP]
  )
  >> drule_then (drule_then (rw o single))
    (Ho_Rewrite.REWRITE_RULE[IMP_CONJ_THM,EQ_IMP_THM,FORALL_AND_THM,pred_setTheory.EXTENSION]
    rename_bij_NOT_MEM_REV_ASSOCD |> CONJUNCT1)
  >> `~MEM t (MAP SND (MAP SWAP s))` by fs[rename_bij_def,FST_SND_SWAP,MAP_MAP_o]
  >> dxrule_then assume_tac rename_bij_SWAP_IMP
  >> drule_then (fs o single) rename_bij_NOT_MEM_REV_ASSOCD
QED

Theorem rename_bij_SWAP_id':
  !s t. rename_bij s ⇒
  REV_ASSOCD (REV_ASSOCD t (MAP SWAP s) t) s (REV_ASSOCD t (MAP SWAP s) t) = t
Proof
  rpt strip_tac
  >> dxrule_then assume_tac rename_bij_SWAP_IMP
  >> dxrule rename_bij_SWAP_id
  >> fs[MAP_MAP_o,SWAP_SWAP_INVOL]
QED

(* TODO move *)
Theorem INSERT_DELETE':
  x ∉ A ∧ x INSERT A = B ⇒ A = B DELETE x
Proof
  rw[pred_setTheory.EXTENSION,DISJ_IMP_THM,FORALL_AND_THM,EQ_IMP_THM,DISJ_EQ_IMP]
QED

Theorem set_SWAP_EVEN:
  !s. set (MAP SWAP s) = set s ∧ EVERY (UNCURRY $<>) s
  ∧ ALL_DISTINCT s
  ⇒ EVEN (LENGTH s)
Proof
  gen_tac >> completeInduct_on `LENGTH s`
  >> Cases >> rw[]
  >> `h ≠ SWAP h` by (
    ONCE_REWRITE_TAC[GSYM PAIR]
    >> fs[SWAP_def,ELIM_UNCURRY]
  )
  >> `MEM (SWAP h) t` by (
    fs[ELIM_UNCURRY,DISJ_IMP_THM,FORALL_AND_THM,EQ_IMP_THM,pred_setTheory.EXTENSION]
  )
  >> pop_assum (strip_assume_tac o REWRITE_RULE[MEM_SPLIT])
  >> fs[ALL_DISTINCT_APPEND,FORALL_AND_THM,DISJ_IMP_THM]
  >> fs[PULL_FORALL]
  >> first_x_assum (qspec_then `l1 ++ l2` mp_tac)
  >> fs[ALL_DISTINCT_APPEND,SIMP_RULE(srw_ss())[FUN_EQ_THM] SWAP_SWAP_INVOL]
  >> impl_tac
  >- (
    `~MEM (SWAP h) (MAP SWAP l1) ∧ ~MEM (SWAP h) (MAP SWAP l2)` by (
      fs[MEM_MAP_SWAP]
    )
    >> `~MEM h (MAP SWAP l1) ∧ ~MEM h (MAP SWAP l2)` by (
      fs[MEM_MAP_SWAP']
    )
    >> dxrule (ONCE_REWRITE_RULE[CONJ_COMM] INSERT_DELETE')
    >> rw[UNION_DELETE,DELETE_INSERT,DELETE_NON_ELEMENT_RWT,Once EQ_SYM_EQ]
    >> dxrule (ONCE_REWRITE_RULE[CONJ_COMM] INSERT_DELETE')
    >> rw[UNION_DELETE,DELETE_INSERT,DELETE_NON_ELEMENT_RWT,Once EQ_SYM_EQ]
  )
  >> qmatch_goalsub_abbrev_tac `EVEN a ⇒ EVEN b`
  >> `b = SUC(SUC(a))` by (unabbrev_all_tac >> fs[])
  >> fs[Abbr`b`,EVEN]
QED

Definition var_renaming_def:
  var_renaming s =
    (rename_bij s ∧ EVERY (λ(x,y). ∃a. y = Tyvar a) s)
End

Theorem var_renaming_eq:
  !s. var_renaming s =
    (rename_bij s ∧ EVERY (λx. ∃a b. x = (Tyvar a,Tyvar b)) s)
Proof
  fs[EQ_IMP_THM,var_renaming_def,FORALL_AND_THM,GSYM AND_IMP_INTRO]
  >> conj_tac
  >- (
    rw[EVERY_MEM,rename_bij_def,ELIM_UNCURRY]
    >> imp_res_tac (Q.ISPEC `FST` MEM_MAP_f)
    >> last_x_assum ((dxrule_then assume_tac) o CONJUNCT1 o Ho_Rewrite.REWRITE_RULE[EQ_IMP_THM,FORALL_AND_THM,pred_setTheory.EXTENSION])
    >> fs[MEM_MAP]
    >> qpat_x_assum `!x. _ ⇒ ?x. _` imp_res_tac
    >> ONCE_REWRITE_TAC[GSYM PAIR]
    >> fs[Excl"PAIR"]
  )
  >> ntac 2 strip_tac
  >> match_mp_tac (Ho_Rewrite.REWRITE_RULE[PULL_FORALL] EVERY_MONOTONIC)
  >> fs[ELIM_UNCURRY,PULL_EXISTS]
QED

Theorem var_renaming_SWAP_IMP:
  !s. var_renaming s ⇒ var_renaming (MAP SWAP s)
Proof
  rw[var_renaming_eq,rename_bij_SWAP_IMP,EVERY_MAP]
  >> qpat_x_assum `EVERY _ _` mp_tac
  >> match_mp_tac (Ho_Rewrite.REWRITE_RULE[PULL_FORALL] EVERY_MONOTONIC)
  >> Cases
  >> rw[SWAP_def,ELIM_UNCURRY]
QED

Theorem var_renaming_MEM_TYPE_SUBST:
  !s x y. MEM (x,Tyvar y) s ∧ var_renaming s
  ⇒ TYPE_SUBST s (Tyvar y) = x
Proof
  rw[var_renaming_def]
  >> drule_all rename_bij_MEM_REV_ASSOCD
  >> fs[]
QED

Theorem var_renaming_MEM_REV_ASSOCD =
  REWRITE_RULE[TYPE_SUBST_def]var_renaming_MEM_TYPE_SUBST

Theorem var_renaming_NOT_MEM_TYPE_SUBST:
  !s. var_renaming s ⇒
  !y. ¬MEM (Tyvar y) (MAP SND s) ⇔ TYPE_SUBST s (Tyvar y) = Tyvar y
Proof
  fs[var_renaming_def,rename_bij_NOT_MEM_REV_ASSOCD]
QED

Theorem var_renaming_NOT_MEM_REV_ASSOCD_IMP =
  Ho_Rewrite.REWRITE_RULE
    [FORALL_AND_THM,IMP_CONJ_THM,AND_IMP_INTRO,EQ_IMP_THM,TYPE_SUBST_def]
    var_renaming_NOT_MEM_TYPE_SUBST
  |> CONJUNCT1 |> Ho_Rewrite.REWRITE_RULE[PULL_FORALL,AND_IMP_INTRO]

Theorem var_renaming_SWAP_id:
  !s t. var_renaming s ⇒
  TYPE_SUBST (MAP SWAP s) (TYPE_SUBST s t) = t
Proof
  rw[TYPE_SUBST_compose]
  >> CONV_TAC (RHS_CONV(PURE_ONCE_REWRITE_CONV [GSYM TYPE_SUBST_NIL]))
  >> rw[TYPE_SUBST_tyvars,REV_ASSOCD_def]
  >> ONCE_REWRITE_TAC[GSYM TYPE_SUBST_def]
  >> REWRITE_TAC[GSYM TYPE_SUBST_compose]
  >> Cases_on `MEM (Tyvar x) (MAP SND s)`
  >- (
    fs[MEM_MAP] >> PairCases_on `y` >> fs[] >> rveq
    >> `?y. y0 = Tyvar y` by (fs[EVERY_MEM,var_renaming_eq] >> res_tac >> fs[])
    >> VAR_EQ_TAC
    >> drule_all_then strip_assume_tac var_renaming_MEM_REV_ASSOCD
    >> ASM_REWRITE_TAC[]
    >> fs[Once (GSYM MEM_MAP_SWAP),SWAP_def]
    >> drule var_renaming_MEM_REV_ASSOCD
    >> fs[var_renaming_SWAP_IMP]
  )
  >> drule_then (fs o single) var_renaming_NOT_MEM_REV_ASSOCD_IMP
  >> `~MEM (Tyvar x) (MAP SND (MAP SWAP s))` by (
    fs[var_renaming_def,rename_bij_def]
    >> last_x_assum (mp_tac o CONJUNCT1 o Ho_Rewrite.REWRITE_RULE[EQ_IMP_THM,FORALL_AND_THM,pred_setTheory.EXTENSION])
    >> disch_then (dxrule o ONCE_REWRITE_RULE[MONO_NOT_EQ])
    >> fs[FST_SND_SWAP,MAP_MAP_o]
  )
  >> dxrule_then assume_tac var_renaming_SWAP_IMP
  >> drule_then (fs o single) var_renaming_NOT_MEM_REV_ASSOCD_IMP
QED

Theorem var_renaming_SWAP_id':
  !s t. var_renaming s ⇒
  TYPE_SUBST s (TYPE_SUBST (MAP SWAP s) t) = t
Proof
  rpt strip_tac
  >> dxrule_then assume_tac var_renaming_SWAP_IMP
  >> dxrule var_renaming_SWAP_id
  >> fs[MAP_MAP_o,SWAP_SWAP_INVOL]
QED

Theorem var_renaming_Tyvar_imp:
  (!s x. var_renaming s ∧
  MEM x (MAP FST s) ⇒ ∃a. x = Tyvar a)
  /\ (!s x. var_renaming s ∧
  MEM x (MAP SND s) ⇒ ∃a. x = Tyvar a)
  /\ (!s x. var_renaming s ∧
  MEM x s ⇒ ∃a b. x = (Tyvar a,Tyvar b))
Proof
  rw[var_renaming_eq,MEM_MAP,EVERY_MEM]
  >> first_x_assum (drule_then strip_assume_tac)
  >> fs[]
QED

Theorem var_renaming_MEM_ineq:
  !s x. var_renaming s ∧ MEM x s ⇒ FST x ≠ SND x
Proof
  rw[var_renaming_def,rename_bij_def,EVERY_MEM,ELIM_UNCURRY]
QED

Theorem var_renaming_MAP_FST_SND:
  !s. var_renaming s
  ⇒ set (MAP FST s) = set (MAP SND s)
Proof
  fs[rename_bij_def,var_renaming_def]
QED

Triviality var_renaming_compose_set:
  var_renaming r ∧ var_renaming s⇒
  set (MAP FST (MAP (TYPE_SUBST s ## I) r))
  = ({ FST x | MEM x s ∧ MEM (SND x) (MAP FST r) }
      ∪ (set (MAP FST r) DIFF set (MAP SND s)))
Proof
  rw[pred_setTheory.EXTENSION,EQ_IMP_THM,PAIR_MAP_o,o_DEF,MAP_MAP_o]
  >- (
    qpat_x_assum `MEM _ (MAP _ _)` (strip_assume_tac o REWRITE_RULE[MEM_MAP])
    >> fs[var_renaming_eq,EVERY_MEM]
    >> Cases_on `MEM (FST y) (MAP SND s)`
    >- (
      qpat_x_assum `MEM _ (MAP _ _)` (strip_assume_tac o REWRITE_RULE[MEM_MAP])
      >> res_tac
      >> rveq >> fs[] >> rveq
      >> drule var_renaming_MEM_REV_ASSOCD
      >> rw[var_renaming_eq,EVERY_MEM]
      >> disj1_tac
      >> goal_assum (first_assum o mp_then Any mp_tac)
      >> imp_res_tac (Q.ISPEC `FST` MEM_MAP_f)
      >> fs[]
    )
    >> res_tac
    >> VAR_EQ_TAC
    >> fs[]
    >> drule (ONCE_REWRITE_RULE[CONJ_COMM] var_renaming_NOT_MEM_REV_ASSOCD_IMP)
    >> rw[var_renaming_eq,EVERY_MEM]
    >> imp_res_tac (Q.ISPEC `FST` MEM_MAP_f)
    >> fs[]
  )
  >- (
    qpat_x_assum `MEM _ (MAP _ _)` (strip_assume_tac o REWRITE_RULE[MEM_MAP])
    >> drule (ONCE_REWRITE_RULE[CONJ_COMM]var_renaming_MEM_TYPE_SUBST)
    >> fs[var_renaming_eq,EVERY_MEM]
    >> res_tac
    >> rveq >> fs[] >> rveq
    >> disch_then (drule_then assume_tac)
    >> fs[MEM_MAP]
    >> goal_assum (first_assum o mp_then Any mp_tac)
    >> fs[]
  )
  >> qpat_x_assum `MEM _ (MAP _ _)` (strip_assume_tac o REWRITE_RULE[MEM_MAP])
  >> drule var_renaming_NOT_MEM_REV_ASSOCD_IMP
  >> fs[var_renaming_eq,EVERY_MEM]
  >> res_tac
  >> rveq >> fs[] >> rveq
  >> disch_then (drule_then assume_tac)
  >> fs[MEM_MAP]
  >> goal_assum (first_assum o mp_then Any mp_tac)
  >> fs[]
QED

Triviality var_renaming_compose_props:
  ∀r s. var_renaming s ∧ var_renaming r
  ⇒ let s = MAP (TYPE_SUBST s ## I) r ++ s
  in
    (set (MAP FST s) = set (MAP SND s)
    ∧ EVERY (λ(x,y). ∃a. y = Tyvar a) s)
Proof
  REWRITE_TAC[LET_THM]
  >> BETA_TAC
  >> reverse (rpt strip_tac)
  >- (
    fs[var_renaming_def,EVERY_MAP]
    >> qpat_x_assum `EVERY _ r` mp_tac
    >> match_mp_tac (Ho_Rewrite.REWRITE_RULE[PULL_FORALL] EVERY_MONOTONIC)
    >> fs[ELIM_UNCURRY]
  )
  >> drule var_renaming_compose_set
  >> disch_then (last_assum o mp_then Any mp_tac)
  >> fs[var_renaming_def,EVERY_MAP]
  >> fs[rename_bij_def,MAP_MAP_o,o_DEF,PAIR_MAP_THM,ETA_THM]
  >> rw[]
  >> qmatch_goalsub_abbrev_tac `((C ∪ _) ∪ _) = (A ∪ B)`
  >> `C ⊆ B` by (
    unabbrev_all_tac
    >> qpat_x_assum `set (MAP FST s) = _` (fs o single o GSYM)
    >> fs[SUBSET_DEF,PULL_EXISTS,MEM_MAP_f]
  )
  >> fs[UNION_DIFF_EQ,UNION_IDEMPOT,AC UNION_ASSOC UNION_COMM,SUBSET_UNION_ABSORPTION]
QED

Theorem var_renaming_clean_tysubst_eq:
  !s. var_renaming s ⇒ clean_tysubst s = s
Proof
  rw[rename_bij_def,var_renaming_def]
  >> match_mp_tac clean_tysubst_id
  >> asm_rewrite_tac[]
QED

Theorem clean_tysubst_APPEND:
  !s s'. clean_tysubst (s ++ s') = clean_tysubst s
    ++ FILTER (λx. ¬MEM (SND x) (MAP SND s)) (clean_tysubst s')
Proof
  ho_match_mp_tac clean_tysubst_ind
  >> rw[clean_tysubst_def,FILTER_APPEND,FILTER_FILTER,FILTER_EQ,ELIM_UNCURRY]
  >> imp_res_tac (REWRITE_RULE[EVERY_MEM,Once EQ_SYM_EQ]clean_tysubst_non_triv)
  >> fs[ELIM_UNCURRY]
QED

(*
Theorem :
  !s. set (MAP FST s) = set (MAP SND s)
    ⇒ set (MAP FST (clean_tysubst s)) = set (MAP SND (clean_tysubst s))
Proof
QED
*)

Theorem var_renaming_compose:
  ∀r s. var_renaming s ∧ var_renaming r
  ⇒ var_renaming (clean_tysubst (MAP (TYPE_SUBST s ## I) r ++ s))
Proof
  rpt strip_tac
  >> qmatch_goalsub_abbrev_tac `clean_tysubst sor`
  >> rw[var_renaming_def,rename_bij_def,clean_tysubst_ALL_DISTINCT_MAP_SND]
  >> TRY (
    qmatch_goalsub_abbrev_tac `EVERY _`
    >> qspec_then `sor` mp_tac clean_tysubst_non_triv
    >> match_mp_tac (Ho_Rewrite.REWRITE_RULE[PULL_FORALL] EVERY_MONOTONIC)
    >> fs[ELIM_UNCURRY,ETA_THM,PULL_EXISTS,Once EQ_SYM_EQ]
  )
  >> qpat_x_assum `var_renaming r` mp_tac
  >> drule var_renaming_compose_props
  >> disch_then (fn x => strip_tac >> drule x)
  >> qmatch_goalsub_abbrev_tac`sr ++ s`
  >> rw[Abbr`sor`,clean_tysubst_APPEND,pred_setTheory.EXTENSION,EQ_IMP_THM,FORALL_AND_THM,DISJ_IMP_THM]
  >> rw[DISJ_EQ_IMP]
  >> `MAP SND sr = MAP SND r` by  (
    fs[Abbr`sr`,MAP_MAP_o,o_DEF]
    >> SIMP_TAC(std_ss ++ ETA_ss)[]
  )
  >> TRY (
    qmatch_asmsub_abbrev_tac `MEM _ (MAP FST (FILTER _ _))`
    >> qpat_x_assum  `MEM _ (MAP FST (FILTER _ _))` (strip_assume_tac o REWRITE_RULE[MEM_MAP,MEM_FILTER])
    >> cheat
  )
  >> TRY (
    qmatch_asmsub_abbrev_tac `MEM _ (MAP FST (clean_tysubst sr))`
    >> drule_then assume_tac (REWRITE_RULE[SUBSET_DEF] (CONJUNCT1 clean_tysubst_FST_SND_SUBSET))
    >> qpat_x_assum  `MEM _ (MAP FST (clean_tysubst sr))` (strip_assume_tac o REWRITE_RULE[MEM_MAP,MEM_FILTER])
    >> first_x_assum (drule_then assume_tac)
    >> cheat
  )
  >> TRY (
    qmatch_asmsub_abbrev_tac `MEM _ (MAP SND (clean_tysubst sr))`
    >> qpat_x_assum `MEM _ (MAP SND (clean_tysubst sr))` (strip_assume_tac o REWRITE_RULE[MEM_MAP])
    >> drule_then assume_tac (REWRITE_RULE[SUBSET_DEF] clean_tysubst_SUBSET)
    >> first_x_assum (drule_then strip_assume_tac)
    >> cheat
  )
  >> cheat
  (*
  >> rpt (pop_assum mp_tac)
  >> map_every qid_spec_tac [`ss`,`s`]
  >> completeInduct_on `LENGTH r`
  >> fs[AND_IMP_INTRO,PULL_FORALL]
  >> Cases_on `v` >> rw[]
  >- (
    imp_res_tac var_renaming_clean_tysubst_eq
    >> fs[var_renaming_def,rename_bij_def]
    >> rveq >> fs[]
  )
  *)
QED

Triviality var_renaming_non_compose:
  ?r s. var_renaming s ∧ var_renaming r
  ∧ ~var_renaming (MAP (TYPE_SUBST s ## I) r ++ s)
Proof
  (* r = (a x)(b c), s = (b x), s o r = (a b c x) *)
  map_every qexists_tac [`(Tyvar «a»,Tyvar «x»)::(Tyvar «x»,Tyvar «a»)::(Tyvar «b»,Tyvar «c»)::(Tyvar «c»,Tyvar «b»)::[]`,
`(Tyvar «b»,Tyvar «x»)::(Tyvar «x»,Tyvar «b»)::[]`]
  >> fs[var_renaming_def,rename_bij_def,SWAP_def]
  >> rw[pred_setTheory.EXTENSION,EQ_IMP_THM]
QED

Theorem var_renaming_SWAP_inv:
  !s t. var_renaming s ∧ set (MAP SWAP s) = set s
    ⇒ TYPE_SUBST (MAP SWAP s) t = TYPE_SUBST s t
Proof
  rw[TYPE_SUBST_tyvars]
  >> Cases_on `MEM (Tyvar x) (MAP SND s)`
  >- (
    fs[MEM_MAP] >> rename1 `MEM y _` >> PairCases_on `y` >> fs[] >> rveq
    >> drule_all var_renaming_MEM_TYPE_SUBST
    >> dxrule_then assume_tac var_renaming_SWAP_IMP
    >> drule (ONCE_REWRITE_RULE[CONJ_COMM] var_renaming_MEM_TYPE_SUBST)
    >> fs[pred_setTheory.EXTENSION,FORALL_AND_THM,IMP_CONJ_THM,EQ_IMP_THM,MAP_MAP_o,FST_SND_SWAP]
  )
  >> `¬MEM (Tyvar x) (MAP SND (MAP SWAP s))` by (
    fs[var_renaming_eq,rename_bij_def,pred_setTheory.EXTENSION,FORALL_AND_THM,IMP_CONJ_THM,EQ_IMP_THM,MAP_MAP_o,FST_SND_SWAP]
    >> first_x_assum (match_mp_tac o ONCE_REWRITE_RULE[MONO_NOT_EQ])
    >> asm_rewrite_tac[]
  )
  >> imp_res_tac REV_ASSOCD_NOT_MEM_drop >> fs[]
QED

Theorem var_renaming_SWAP_idem:
  !s x y. var_renaming s ∧ set (MAP SWAP s) = set s
    ∧ TYPE_SUBST s (Tyvar x) = (Tyvar y)
    ==> TYPE_SUBST s (Tyvar y) = (Tyvar x)
Proof
  rpt strip_tac
  >> qpat_x_assum `TYPE_SUBST _ _ = _` (REWRITE_TAC o single o GSYM)
  >> drule var_renaming_SWAP_id'
  >> drule_all_then (Ho_Rewrite.REWRITE_TAC o single) var_renaming_SWAP_inv
  >> fs[]
QED

Theorem var_renaming_SWAP_idem':
  !s x. var_renaming s ∧ set (MAP SWAP s) = set s
    ==> TYPE_SUBST s (TYPE_SUBST s (Tyvar x)) = (Tyvar x)
Proof
  rpt strip_tac
  >> drule var_renaming_SWAP_id'
  >> drule_all_then (Ho_Rewrite.REWRITE_TAC o single) var_renaming_SWAP_inv
  >> fs[]
QED

(* less strict renaming *)

Definition renaming_compute_def:
  renaming_compute s = EVERY (λ(y,x). case x of
    | Tyvar a => (
      case (ALOOKUP (MAP SWAP s) (Tyvar a)) of
      | SOME (Tyvar b) => T
      | NONE => T
      | _ => F
    ) | _ => T) s
End

(* TODO: renaming_def in holSyntaxExtraScript.sml is too strong. Use this instead *)
Definition renaming_def:
  renaming s = !x pfx sfx.
    MAP SND s = pfx ++ [Tyvar x] ++ sfx /\ ~MEM (Tyvar x) pfx
    ==> ?a. ALOOKUP (MAP SWAP s) (Tyvar x) = SOME (Tyvar a)
End

Theorem renaming_imp:
  !s x. renaming s /\ MEM (Tyvar x) (MAP SND s)
  ==> ?pfx sfx q. s = pfx ++ [Tyvar q,Tyvar x] ++ sfx /\ ~MEM (Tyvar x) (MAP SND pfx)
Proof
  rw[renaming_def]
  >> imp_res_tac MEM_SPLIT_APPEND_SND_first
  >> qmatch_assum_rename_tac `s = pfx ++ [(q,Tyvar x)] ++ sfx`
  >> first_x_assum (qspecl_then [`x`,`MAP SND pfx`,`MAP SND sfx`] assume_tac)
  >> rfs[MAP_APPEND,ALOOKUP_APPEND]
  >> ONCE_REWRITE_TAC[CONJ_COMM]
  >> asm_exists_tac
  >> `ALOOKUP (MAP SWAP pfx) (Tyvar x) = NONE` by (
    qpat_x_assum `~MEM _ _` mp_tac
    >> rpt(pop_assum kall_tac)
    >> rw[MEM_MAP,ALOOKUP_FAILS,SWAP_def]
    >> first_x_assum (qspec_then `y` assume_tac)
    >> fs[]
  )
  >> fs[SWAP_def]
QED

Theorem renaming_compute_eq:
  !s. renaming s = renaming_compute s
Proof
  rw[EQ_IMP_THM,renaming_compute_def,renaming_def,EVERY_MEM,ELIM_UNCURRY]
  >- (
    FULL_CASE_TAC
    >> imp_res_tac (Q.ISPEC `SND` MEM_MAP_f)
    >> imp_res_tac MEM_SPLIT_APPEND_SND_first
    >> rename1`Tyvar m`
    >> rename1`pfx ++ _ ++ sfx`
    >> first_x_assum (qspecl_then [`m`,`MAP SND pfx`,`MAP SND sfx`] assume_tac)
    >> rfs[MAP_APPEND]
  )
  >- (
    rename1`MAP SND s = pfx ++ _ ++ _`
    >> `LENGTH (pfx) < LENGTH s` by (
      REWRITE_TAC[Q.ISPEC `SND` (CONV_RULE SWAP_FORALL_CONV (GSYM LENGTH_MAP))]
      >> ASM_REWRITE_TAC[]
      >> fs[]
    )
    >> `MEM (EL (LENGTH pfx) s) s` by (
      fs[MEM_EL] >> asm_exists_tac >> fs[]
    )
    >> first_x_assum drule
    >> drule (INST_TYPE [alpha |-> ``:type#type``,beta|-> ``:type``] (GSYM EL_MAP))
    >> disch_then (REWRITE_TAC o single)
    >> ASM_REWRITE_TAC[]
    >> REWRITE_TAC[el_append3]
    >> FULL_CASE_TAC >> fs[]
    >> CASE_TAC
    >- (
      qpat_x_assum `_ = NONE` mp_tac
      >> fs[ALOOKUP_FAILS,MEM_MAP,SWAP_def]
      >> ONCE_REWRITE_TAC[CONJ_COMM]
      >> asm_exists_tac
      >> drule (INST_TYPE [alpha |-> ``:type#type``,beta|-> ``:type``] (GSYM EL_MAP))
      >> disch_then (REWRITE_TAC o single)
      >> ASM_REWRITE_TAC[]
      >> REWRITE_TAC[el_append3]
    )
    >> FULL_CASE_TAC
  )
QED

Theorem renaming_eq:
  !s. renaming s = !x. MEM (Tyvar x) (MAP SND s)
  ==> ?a. ALOOKUP (MAP SWAP s) (Tyvar x) = SOME (Tyvar a)
Proof
  rw[EQ_IMP_THM,renaming_compute_eq,renaming_compute_def,EVERY_MEM]
  >- (
    fs[MEM_MAP]
    >> first_x_assum drule
    >> pairarg_tac
    >> strip_tac
    >> rveq
    >> fs[]
    >> FULL_CASE_TAC >> fs[]
    >> FULL_CASE_TAC
    >- (
      fs[ALOOKUP_FAILS,MEM_MAP,SWAP_def]
      >> qmatch_assum_rename_tac `MEM (y',Tyvar m) s`
      >> first_x_assum (qspec_then `(y',Tyvar m)` assume_tac)
      >> fs[]
    )
    >> fs[]
    >> FULL_CASE_TAC
    >> fs[]
  )
  >> pairarg_tac
  >> imp_res_tac (Q.ISPEC `SND` MEM_MAP_f)
  >> fs[]
  >> FULL_CASE_TAC
  >> first_x_assum drule
  >> FULL_CASE_TAC
  >> rw[]
  >> fs[]
QED

Theorem renaming_imp':
  !e. EVERY (λ(x,y). (?m n. (x = Tyvar m) /\ (y = Tyvar n))) e
  ==> renaming e
Proof
  rw[EVERY_MEM,renaming_def,ALOOKUP_MEM_eq]
  >> `MEM (Tyvar x) (MAP SND e)` by fs[]
  >> imp_res_tac MEM_SPLIT_APPEND_SND_first
  >> `MEM (q,Tyvar x) e` by fs[]
  >> last_x_assum imp_res_tac
  >> fs[ELIM_UNCURRY,SWAP_def]
  >> qexists_tac `m`
  >> qexists_tac `MAP SWAP pfx'`
  >> fs[MAP_MAP_o,FST_SND_SWAP]
  >> fs[]
QED

(* properties of renaming and clean_tysubst *)

Theorem list_subset_clean_tysubst:
  !r. list_subset (clean_tysubst r) r
Proof
  Induct
  >> fs[list_subset_set,clean_tysubst_def,SUBSET_DEF]
  >> rpt strip_tac
  >> qmatch_asmsub_rename_tac `h::r`
  >> Cases_on `h`
  >> qmatch_asmsub_rename_tac `(_,z)`
  >> Cases_on `z`
  >> fs[clean_tysubst_def,list_subset_set,SUBSET_DEF]
  >> FULL_CASE_TAC
  >> fs[MEM_FILTER]
QED

Theorem clean_tysubst_ALOOKUP:
  !r x. MEM x (clean_tysubst r)
  = (ALOOKUP (MAP SWAP r) (SND x) = SOME (FST x) /\ SND x <> FST x /\ !a b. (SND x <> Tyapp a b ))
Proof
  Induct
  >- fs[clean_tysubst_def,ALOOKUP_def]
  >> rw[EQ_IMP_THM]
  >- (
    Cases_on `h` >> Cases_on `r'`
    >> fs[SWAP_def,ALOOKUP_def,clean_tysubst_def]
    >> TRY (FULL_CASE_TAC)
    >> fs[MEM_FILTER]
    >- (
      FULL_CASE_TAC >> fs[MEM_FILTER,ELIM_UNCURRY]
      >> qpat_x_assum `_ = (_,_)` (assume_tac o CONV_RULE(LHS_CONV(PURE_ONCE_REWRITE_CONV[GSYM PAIR])))
      >> fs[]
    )
    >- (
      FULL_CASE_TAC >> fs[MEM_FILTER,ELIM_UNCURRY]
      >- ( first_x_assum (qspec_then `x` assume_tac) >> fs[])
      >- (
        qpat_x_assum `_ = (_,_)` (assume_tac o CONV_RULE(LHS_CONV(PURE_ONCE_REWRITE_CONV[GSYM PAIR])))
        >> fs[]
      )
      >- ( first_x_assum (qspec_then `x` assume_tac) >> fs[])
    )
    >- ( first_x_assum (qspec_then `x` assume_tac) >> rfs[] >> fs[])
    >- ( first_x_assum (qspec_then `x` assume_tac) >> fs[])
  )
  >- (
    Cases_on `h` >> Cases_on `r'`
    >> fs[SWAP_def,ALOOKUP_def,clean_tysubst_def]
    >> TRY (FULL_CASE_TAC)
    >> fs[MEM_FILTER]
    >> first_x_assum (qspec_then `x` assume_tac)
    >> fs[]
  )
  >- (
    Cases_on `h` >> Cases_on `r'`
    >> fs[SWAP_def,ALOOKUP_def,clean_tysubst_def]
    >> TRY (FULL_CASE_TAC)
    >> fs[MEM_FILTER]
    >> first_x_assum (qspec_then `x` assume_tac)
    >> fs[]
  )
  >- (
    Cases_on `h` >> Cases_on `r'`
    >> fs[SWAP_def,ALOOKUP_def,clean_tysubst_def]
    >> TRY (FULL_CASE_TAC)
    >> fs[MEM_FILTER]
    >> FULL_CASE_TAC
    >> CONV_TAC(LAND_CONV(PURE_ONCE_REWRITE_CONV[GSYM PAIR]))
    >> fs[ELIM_UNCURRY]
  )
QED

Theorem clean_tysubst_MEM:
  !pfx q q' x sfx. ~MEM (Tyvar x) (MAP SND pfx) /\ Tyvar x <> q
  /\ MEM (q,Tyvar x) (clean_tysubst (pfx ++ [(q',Tyvar x)] ++ sfx))
  ==> q=q'
Proof
  Induct
  >> rw[clean_tysubst_def,MEM_FILTER]
  >> Cases_on `h`
  >> Cases_on `r`
  >> fs[clean_tysubst_def,MEM_FILTER]
  >> TRY (FULL_CASE_TAC)
  >> fs[MEM_FILTER]
  >> last_x_assum match_mp_tac
  >> asm_exists_tac
  >> fs[]
  >> asm_exists_tac
  >> fs[]
QED

Theorem clean_tysubst_NOT_MEM:
   !pfx a sfx q. ¬MEM (Tyvar a) (MAP SND pfx)
   ==> ~MEM (q,Tyvar a) (clean_tysubst (pfx ++ [(Tyvar a,Tyvar a)] ++ sfx))
Proof
  Induct
  >> fs[clean_tysubst_def,MEM_FILTER]
  >> Cases
  >> Cases_on `r`
  >> fs[clean_tysubst_def]
  >> FULL_CASE_TAC
  >> rw[MEM_FILTER]
QED

(*
Theorem renaming_clean_tysubst_imp:
  !r. renaming r ==> renaming (clean_tysubst r)
Proof
  Cases
  >- fs[renaming_def,clean_tysubst_def]
  >> rename1 `h::_`
  >> Cases_on `h`
  >> rename1 `(_,r)::t`
  >> Cases_on `r`
  >> CONV_TAC (LAND_CONV (REWR_CONV renaming_eq))
  >> rw[renaming_def,clean_tysubst_def,DISJ_IMP_THM,FORALL_AND_THM]
  >- (

ALOOKUP_MEM_eq

  )

  >- rw[renaming_def,clean_tysubst_def,ALOOKUP_MEM_eq]
  >> rw[renaming_def,clean_tysubst_def,ALOOKUP_MEM_eq]



  Cases
  >- fs[renaming_def,clean_tysubst_def]
  >> rename1 `h::_`
  >> Cases_on `h`
  >> rename1 `(_,r)::t`
  >> Cases_on `r`
  >> rw[renaming_def,clean_tysubst_def,ALOOKUP_MEM_eq]
  >> TRY (FULL_CASE_TAC >> fs[])
  (* (Tyvar m, Tyvar m) is head *)
  >- (
    qmatch_asmsub_abbrev_tac `FILTER f`
    >> `MEM (Tyvar x) (MAP SND (FILTER f (clean_tysubst t)))` by fs[]
    >> pop_assum (strip_assume_tac o REWRITE_RULE[MAP_SND_FILTER_NEQ,MEM_FILTER,MEM_MAP,BETA_THM])
    >> qmatch_assum_rename_tac `MEM y (clean_tysubst _)` >> Cases_on `y`
    >> imp_res_tac (REWRITE_RULE[list_subset_set,SUBSET_DEF] list_subset_clean_tysubst)
    >> dxrule (Q.ISPEC `SND` MEM_MAP_f)
    >> rw[Abbr`f`]
    >> dxrule_then strip_assume_tac MEM_SPLIT_APPEND_SND_first
    >> first_x_assum (qspecl_then [`x`,`Tyvar m::MAP SND pfx'`,`MAP SND sfx'`] assume_tac)
    >> rfs[SWAP_def]
    >> rveq >> rfs[]
    >> Q.ISPECL_THEN
      [`(Tyvar m,Tyvar m)::MAP SWAP pfx'`,`MAP SWAP sfx'`,`pfx''`,`sfx''`,`(Tyvar x,q')`,`(Tyvar x,Tyvar a)`]
      mp_tac (GSYM MEM_APPEND_FST_lemma)
    >> rw[FST_SND_SWAP,MAP_MAP_o,SWAP_def]
    >> fs[]
    >> qmatch_asmsub_abbrev_tac `MAP SND (FILTER f (clean_tysubst s))`
    >> Q.ISPECL_THEN [`f`,`clean_tysubst s`] mp_tac MEM_FILTER
    >> qunabbrev_tac `f`
    >> disch_then imp_res_tac
    >> pop_assum (assume_tac o REWRITE_RULE[MEM_SPLIT,ELIM_UNCURRY])
    >> rfs[]
    (*>> qpat_x_assum `_ = _ ++ _` (assume_tac o ONCE_REWRITE_RULE[GSYM
     * markerTheory.Abbrev_def]) *)
    >> map_every qexists_tac [`a`,`MAP SWAP l1`,`MAP SWAP l2`]
    >> fs[SWAP_SWAP_INVOL,FST_SND_SWAP,MAP_MAP_o,PAIR,SWAP_def]
    >> qmatch_asmsub_abbrev_tac `FILTER f (clean_tysubst s)`
    >> qspec_then `s` assume_tac (CONJUNCT1 clean_tysubst_prop)
    >> dxrule FILTER_ALL_DISTINCT
    >> disch_then (qspec_then `λx. x <> (Tyvar m)` mp_tac)
    >> fs[FILTER_MAP,LAMBDA_PROD,o_DEF]
    >> qpat_x_assum `(MAP SND _) ++ _ ++ _ = _` (assume_tac o GSYM)
    >> fs[]
    >> rw[ALL_DISTINCT_APPEND,FORALL_AND_THM,DISJ_IMP_THM,SWAP_eq]
    >> qpat_x_assum `_ ++ _ = _` kall_tac
    >> qpat_x_assum `MEM _ (clean_tysubst _)` kall_tac
    >> fs[Abbr`s`,clean_tysubst_APPEND,FILTER_FILTER,FILTER_APPEND]
    >> qpat_x_assum `_ = _` (assume_tac o GSYM)
    >> fs[clean_tysubst_def]
    >> `~MEM (Tyvar x) (MAP SND (FILTER f (clean_tysubst pfx')))` by (
      `f = (λx. Tyvar m ≠ x) o SND` by fs[Abbr`f`,o_DEF,LAMBDA_PROD,FUN_EQ_THM,EQ_IMP_THM]
      >> rw[GSYM FILTER_MAP,MEM_FILTER,clean_tysubst_NOT_MEM_MAP_SND]
    )
    >> FULL_CASE_TAC
    >- (

    )
    >> fs[APPEND_EQ_APPEND_MID] >> rveq >> fs[MAP_APPEND,ALL_DISTINCT_APPEND]
    >> rfs[FORALL_AND_THM,DISJ_IMP_THM]

    >> `Tyvar x ≠ Tyvar m` by (
      `kk
    )

    >> qmatch_asmsub_abbrev_tac `lhs:(type#type) list = rhs`

    >> rw[FILTER_MAP,o_DEF,ALL_DISTINCT_APPEND,DISJ_IMP_THM,FORALL_AND_THM]
    (* 3 subgoals *)

    >> rfs[FILTER_FILTER,FILTER_APPEND,clean_tysubst_def]

    >> FULL_CASE_TAC >> fs[]
    >> qmatch_asmsub_abbrev_tac `lhs:(type#type) list = rhs`
    >> qmatch_asmsub_abbrev_tac (FILTER f1 l1 ++ FILTER f2 l2

    >> `MEM (Tyvar x) (MAP SND rhs) ∧ ¬MEM (Tyvar x) (MAP SND lhs)` by (
      fs[MEM_FILTER,Abbr`lhs`,Abbr`rhs`]
    )
    >- (
      unabbrev_all_tac
      >> drule clean_tysubst_MEM
      >> ONCE_REWRITE_TAC[CONJ_COMM]
      >> disch_then drule
      >> imp_res_tac (REWRITE_RULE[EVERY_MEM] (CONJUNCT2 clean_tysubst_prop))
      >> fs[ELIM_UNCURRY]
    )
    >> qspec_then `s` assume_tac (CONJUNCT1 clean_tysubst_prop)
    (*>> dxrule FILTER_ALL_DISTINCT
    >> disch_then (qspec_then `λx. x <> (Tyvar m)` mp_tac)*)
    >> fs[markerTheory.Abbrev_def]
    >> rveq
    >> rfs[LAMBDA_PROD]
    >> qpat_x_assum `_ ++ _ = _ ++ _` (fs o single o GSYM)
    >> fs[ALL_DISTINCT_APPEND]
  )
  >- (
    qmatch_asmsub_abbrev_tac `FILTER f`
    >> `MEM (Tyvar x) (Tyvar m::MAP SND (FILTER f (clean_tysubst t)))` by (ASM_REWRITE_TAC[] >> fs[])
    >> Cases_on `m = x` >> fs[]
    >- (
      first_x_assum (qspecl_then [`x`,`[]`,`MAP SND t`] mp_tac)
      >> Q.ISPECL_THEN [`[(Tyvar m,q)]`] mp_tac APPEND_EQ_APPEND_IS_PREFIX
      >> rw[SWAP_def]
      >> qpat_x_assum `!x. _` imp_res_tac
      >> TRY (FULL_CASE_TAC) >> fs[]
      >- (
        qpat_x_assum `(_,_) = _` (assume_tac o GSYM)
        >> rveq
        >> qexists_tac `a`
        >> qexists_tac `[]`
        >> Cases_on `t`
        >> rfs[]
        >> rveq
        >> fs[]
        >> Cases_on `pfx'`
        >> fs[]
      )
      >> fs[IS_PREFIX_APPEND]
      >> qexists_tac `a`
      >> qexists_tac `[]`
      >> Cases_on `pfx'`
      >> fs[]
    )
    >> `MEM (Tyvar x) (MAP SND t)` by  (
        fs[MEM_MAP,MEM_FILTER]
        >> imp_res_tac (REWRITE_RULE[list_subset_set,SUBSET_DEF] list_subset_clean_tysubst)
        >> fs[AC CONJ_ASSOC CONJ_COMM]
        >> asm_exists_tac
        >> fs[]
      )
    >> qpat_x_assum `MEM _ (MAP SND (FILTER _ _))` (assume_tac o ONCE_REWRITE_RULE[GSYM markerTheory.Abbrev_def])
    >> dxrule MEM_SPLIT_APPEND_SND_first
    >> rw[]
    >> first_x_assum (qspecl_then [`x`,`Tyvar m::MAP SND pfx'`,`MAP SND sfx'`] assume_tac)
    >> rfs[SWAP_def]
    >> Q.ISPECL_THEN [`(Tyvar m,q)::MAP SWAP pfx'`,`MAP SWAP sfx'`,`pfx''`,`sfx''`,`(Tyvar x,q')`,`(Tyvar x,Tyvar a)`] assume_tac (GSYM MEM_APPEND_FST_lemma)
    >> rfs[MAP_MAP_o,FST_SND_SWAP]
    >> rveq
    >> fs[]
    >> unabbrev_all_tac
    >> pop_assum (assume_tac o REWRITE_RULE[MEM_MAP,MEM_FILTER,ELIM_UNCURRY])
    >> fs[]
    >> Cases_on `y`
    >> rveq
    >> imp_res_tac (REWRITE_RULE[EVERY_MEM] (CONJUNCT2 clean_tysubst_prop))
    >> fs[ELIM_UNCURRY]
    >> rveq
    >> fs[]
    >> rveq
    >> qmatch_asmsub_abbrev_tac `clean_tysubst s`
    >> qpat_x_assum `MEM _ (clean_tysubst s)` (assume_tac o REWRITE_RULE[MEM_SPLIT])
    >> qspec_then `s` assume_tac (CONJUNCT1 clean_tysubst_prop)
    >> fs[]
    >> rfs[ALL_DISTINCT_APPEND]
    >> qmatch_asmsub_abbrev_tac `FILTER f`
    >> qexists_tac `a`
    >> qexists_tac `(Tyvar m,q)::MAP SWAP (FILTER f l1)`
    >> Q.ISPECL_THEN [`Tyvar a'`,`λx. x <> Tyvar m`,`MAP SND l1`] assume_tac (ccontr_equiv(MEM_FILTER))
    >> qunabbrev_tac `f`
    >> rfs[FILTER_APPEND,SWAP_def,MAP_MAP_o,FST_SND_SWAP,FILTER_MAP,o_DEF,LAMBDA_PROD,markerTheory.Abbrev_def]
    >> match_mp_tac clean_tysubst_MEM
    >> qexists_tac `pfx'`
    >> qexists_tac `a'`
    >> qexists_tac `sfx'`
    >> ASM_REWRITE_TAC[]
    >> fs[]
  )
  (* third top level subgoal *)
  >- (
    `MEM (Tyvar x) (MAP SND (clean_tysubst t))` by fs[]
    >> pop_assum (assume_tac o REWRITE_RULE[MEM_MAP])
    >> fs[]
    >> imp_res_tac (REWRITE_RULE[SUBSET_DEF,list_subset_set] list_subset_clean_tysubst)
    >> rename1 `SND y`
    >> Cases_on `y`
    >> fs[]
    >> rveq
    >> qpat_x_assum `MEM _ (clean_tysubst _)` (assume_tac o ONCE_REWRITE_RULE[GSYM markerTheory.Abbrev_def])
    >> dxrule (Q.ISPEC `SND` MEM_MAP_f)
    >> rw[]
    >> dxrule MEM_SPLIT_APPEND_SND_first
    >> rw[]
    >> first_x_assum (qspecl_then [`x`,`Tyapp m l::MAP SND pfx'`,`MAP SND sfx'`] assume_tac)
    >> rfs[SWAP_def]
    >> Q.ISPECL_THEN [`(Tyapp m l,q)::MAP SWAP pfx'`,`MAP SWAP sfx'`,`pfx''`,`sfx''`,`(Tyvar x,q'')`,`(Tyvar x,Tyvar a)`] assume_tac (GSYM MEM_APPEND_FST_lemma)
    >> rfs[MAP_MAP_o,FST_SND_SWAP]
    >> rveq >> fs[MAP_MAP_o,FST_SND_SWAP,markerTheory.Abbrev_def]
    >> imp_res_tac (REWRITE_RULE[EVERY_MEM] (CONJUNCT2 clean_tysubst_prop))
    >> qmatch_asmsub_abbrev_tac `clean_tysubst s`
    >> qspec_then `s` assume_tac (CONJUNCT1 clean_tysubst_prop)
    >> unabbrev_all_tac
    >> fs[ELIM_UNCURRY]
    >> imp_res_tac clean_tysubst_MEM
    >> fs[ELIM_UNCURRY]
    >> qpat_x_assum `MEM (_,_) _` (assume_tac o REWRITE_RULE[MEM_SPLIT])
    >> qpat_x_assum `MAP SND (clean_tysubst _) = _` kall_tac
    >> rfs[ALL_DISTINCT_APPEND]
    >> qexists_tac `a`
    >> qexists_tac `MAP SWAP l1`
    >> fs[SWAP_def,MAP_MAP_o,FST_SND_SWAP,ALL_DISTINCT_APPEND]
  )
QED
*)

(* rename apart two two argument lists *)

Definition ren_def:
  ren rs cs =
    MAP (Tyvar ## Tyvar) (rename_apart_by #"A" rs cs)
End

Theorem ren_ALL_DISTINCT:
  !r c. ALL_DISTINCT (MAP SND (ren r c))
  /\ ALL_DISTINCT (MAP FST (ren r c))
Proof
  fs[ren_def,MAP_MAP_o,FST_SND_PAIR_MAP]
  >> fs[GSYM MAP_MAP_o]
  >> rpt gen_tac
  >> qmatch_goalsub_abbrev_tac `MAP FST rab`
  >> Q.ISPECL_THEN [`MAP FST rab`,`Tyvar`] assume_tac (GSYM ALL_DISTINCT_MAP_inj)
  >> Q.ISPECL_THEN [`MAP SND rab`,`Tyvar`] assume_tac (GSYM ALL_DISTINCT_MAP_inj)
  >> unabbrev_all_tac
  >> fs[rename_apart_by_ALL_DISTINCT]
QED

Theorem ren_MEM:
  !x y r c. MEM (Tyvar y,Tyvar x) (ren r c) ==> (~MEM y c /\ MEM x (list_inter c r))
Proof
  rw[ren_def,MAP_MAP_o,FST_SND_PAIR_MAP,MEM_MAP,PAIR_MAP]
  >> Cases_on `y'`
  >> imp_res_tac rename_apart_by_MEM
  >> fs[]
QED

Theorem ren_Tyvars:
  !r c. EVERY (λx. ?y1 y2. x = (Tyvar y1,Tyvar y2)) (ren r c)
Proof
  rw[EVERY_MEM,ren_def,MEM_MAP,PAIR_MAP]
QED

Theorem ren_strlen_FST:
  !r c. EVERY (λa. ?x. a = Tyvar x /\ list_max (MAP strlen (r++c)) < strlen x) (MAP FST (ren r c))
Proof
  rw[EVERY_MEM,MEM_MAP]
  >> imp_res_tac (REWRITE_RULE[EVERY_MEM] ren_Tyvars)
  >> fs[ren_def,PAIR_MAP,MEM_MAP]
  >> imp_res_tac (Q.ISPEC `FST` MEM_MAP_f)
  >> imp_res_tac (REWRITE_RULE[EVERY_MEM] rename_apart_by_strlen_FST)
  >> fs[]
QED

Theorem ren_MEM_SND:
  !r c x. MEM x (list_inter r c) = MEM (Tyvar x) (MAP SND (ren r c))
Proof
  fs[ren_def,MAP_MAP_o,FST_SND_PAIR_MAP]
  >> fs[GSYM MAP_MAP_o,MEM_Tyvar_MAP_Tyvar,rename_apart_by_MEM_SND]
QED

Theorem ren_MEM_SND1 = ONCE_REWRITE_RULE[list_inter_set_comm] ren_MEM_SND

Theorem ren_disj_dom_img:
  !r c. NULL (list_inter (MAP FST (ren r c)) (MAP SND (ren r c)))
Proof
  fs[ren_def,MAP_MAP_o,FST_SND_PAIR_MAP]
  >> rw[GSYM MAP_MAP_o,NULL_list_inter_MAP_Tyvar,rename_apart_by_disj_dom_img]
QED

Theorem ren_diff:
  !r c. EVERY (UNCURRY $<>) (ren r c)
Proof
  rw[ren_def,rename_apart_by_diff,EVERY_MAP,ELIM_UNCURRY,EVERY_MEM,MEM_MAP]
  >> imp_res_tac (REWRITE_RULE[EVERY_MEM] rename_apart_by_diff)
  >> fs[ELIM_UNCURRY]
QED

Theorem ren_disj_img_c:
  !r c. NULL (list_inter (MAP FST (ren r c)) (MAP Tyvar c))
Proof
  fs[ren_def,MAP_MAP_o,FST_SND_PAIR_MAP]
  >> rw[GSYM MAP_MAP_o,NULL_list_inter_MAP_Tyvar,rename_apart_by_disj_img_c]
QED

Theorem ren_disj_dom_img2:
  !r c. NULL (list_inter (MAP ((TYPE_SUBST (ren r c)) o $Tyvar) r) (MAP Tyvar c))
Proof
  rw[NULL_FILTER,list_inter_def]
  >> rw[MEM_MAP]
  >> Cases_on `MEM y' r`
  >> fs[MEM_MAP]
  >> rveq
  >> Cases_on `MEM (Tyvar y') (MAP SND (ren r c))`
  >- (
    qspecl_then [`r`,`c`] assume_tac ren_disj_dom_img
    >> fs[list_inter_def,NULL_FILTER]
    >> imp_res_tac MEM_SPLIT_APPEND_SND_first
    >> imp_res_tac TYPE_SUBST_drop_prefix
    >> first_x_assum (qspec_then `[(q,Tyvar y')]++sfx` assume_tac)
    >> `MEM q (MAP FST (ren r c))` by fs[]
    >> res_tac
    >> fs[REV_ASSOCD_def]
    >> qspecl_then [`r`,`c`] (assume_tac o REWRITE_RULE[list_inter_def,NULL_FILTER,Q.ISPECL [`c:mlstring list`,`Tyvar`] MEM_MAP]) ren_disj_img_c
    >> pop_assum imp_res_tac
    >> CCONTR_TAC
    >> fs[]
  )
  >> imp_res_tac TYPE_SUBST_drop_all
  >> fs[GSYM ren_MEM_SND1]
  >> fs[list_inter_def,MEM_FILTER]
  >> fs[]
  >> CCONTR_TAC
  >> fs[]
QED

Theorem ren_disj_img_r:
  !r c. NULL (list_inter (MAP FST (ren r c)) (MAP Tyvar r))
Proof
  fs[ren_def,MAP_MAP_o,FST_SND_PAIR_MAP]
  >> rw[GSYM MAP_MAP_o,NULL_list_inter_MAP_Tyvar,rename_apart_by_disj_img_r]
QED

Theorem SWAP_PAIR_MAP_COMM:
  !f. SWAP o (f ## f) = (f ## f) o SWAP
Proof
  rw[FUN_EQ_THM,SWAP_def,PAIR_MAP]
QED

Theorem ren_ALOOKUP:
  !v x r c. MEM (v,x) (ren r c)
    = (ALOOKUP (MAP SWAP (ren r c)) x = SOME v)
Proof
  rw[ren_def,MAP_MAP_o,SWAP_PAIR_MAP_COMM,EQ_IMP_THM]
  >> fs[GSYM MAP_MAP_o]
  >- (
    Q.ISPECL_THEN [`Tyvar`,`Tyvar`] assume_tac MEM_ALOOKUP_INJ
    >> fs[MEM_MAP]
    >> Cases_on `y`
    >> fs[PAIR_MAP,rename_apart_by_ALOOKUP]
  )
  >> qmatch_asmsub_abbrev_tac `MAP SWAP rab`
  >> fs[ALOOKUP_MEM_eq,PAIR_MAP]
  >> imp_res_tac (GSYM (PURE_REWRITE_RULE[APPEND_ASSOC] (ONCE_REWRITE_RULE[CONS_APPEND] MEM_SPLIT)))
  >> fs[MAP_MAP_o,GSYM SWAP_PAIR_MAP_COMM]
  >> fs[GSYM MAP_MAP_o]
  >> qpat_x_assum `MEM _ (MAP _ _)` (assume_tac o ONCE_REWRITE_RULE[MEM_MAP])
  >> fs[SWAP_def]
QED

Theorem ren_ALOOKUP_NONE:
  !x r c. (!v. ~MEM (v,x) (ren r c))
    = (ALOOKUP (MAP SWAP (ren r c)) x = NONE)
Proof
  fs[EQ_IMP_THM]
  >> rpt strip_tac
  >> CCONTR_TAC
  >> fs[ren_ALOOKUP]
  >> qmatch_asmsub_abbrev_tac `ALOOKUP s x`
  >> Cases_on `ALOOKUP s x`
  >> fs[]
QED

Theorem ren_INJ1:
  !r c x k.
  TYPE_SUBST (ren r c) (Tyvar x) = k
  <=> MEM (k,Tyvar x) (ren r c) \/
  (~MEM (Tyvar x) (MAP SND (ren r c))  /\ k = Tyvar x)
Proof
  rw[TYPE_SUBST_def,REV_ASSOCD_ALOOKUP]
  >> FULL_CASE_TAC
  >> fs[GSYM ELIM_UNCURRY]
  >> fs[REWRITE_RULE[SWAP_eq] (GSYM ren_ALOOKUP),REWRITE_RULE[SWAP_eq] (GSYM ren_ALOOKUP_NONE)]
  >> rw[EQ_IMP_THM]
  >- (
    rw[MEM_MAP]
    >> CCONTR_TAC
    >> Cases_on `y`
    >> fs[]
    >> rveq
    >> first_x_assum (qspec_then `q` assume_tac)
    >> fs[]
  )
  >> fs[]
  >> fs[EQ_IMP_THM]
  >- (
    fs[MEM_SPLIT]
    >> rfs[APPEND_EQ_APPEND_MID]
    >> rveq
    >- (qspecl_then [`r`,`c`] assume_tac ren_ALL_DISTINCT >> rfs[ALL_DISTINCT_APPEND])
    >- fs[APPEND_EQ_SING]
    >- (qspecl_then [`r`,`c`] assume_tac ren_ALL_DISTINCT >> rfs[ALL_DISTINCT_APPEND])
  )
  >> imp_res_tac (Q.ISPEC `SND` MEM_MAP_f)
  >> fs[]
QED

Theorem ren_INJ = GSYM (CONV_RULE (DEPTH_CONV BETA_CONV)
  (REWRITE_RULE[GSYM ren_MEM_SND,MEM_FILTER,list_inter_def] ren_INJ1))

Theorem ren_ID:
  !r c x. MEM x (list_complement c r) \/ MEM x (list_complement r c) ==>
  TYPE_SUBST (ren r c) (Tyvar x) = (Tyvar x)
Proof
  rw[MEM_FILTER,list_complement_def]
  >> `~MEM (Tyvar x) (MAP SND (ren r c))` by (
    fs[GSYM ren_MEM_SND,list_inter_def,MEM_FILTER]
  )
  >> imp_res_tac TYPE_SUBST_drop_prefix
  >> first_x_assum (qspec_then `[]` assume_tac)
  >> fs[REV_ASSOCD_def]
QED

Theorem ren_renaming:
  !r c. renaming (ren r c)
Proof
  rw[renaming_eq,MEM_MAP,GSYM ren_ALOOKUP]
  >> Cases_on `y`
  >> fs[ren_def,MEM_MAP,PAIR_MAP]
  >> goal_assum (first_assum o mp_then Any mp_tac)
  >> fs[]
QED

Theorem ren_list_complement:
   !r rc c. NULL (list_inter (MAP SND (ren (list_complement r rc) c)) (MAP Tyvar rc))
Proof
  fs[ren_def,MAP_MAP_o,FST_SND_PAIR_MAP]
  >> rw[GSYM MAP_MAP_o,NULL_list_inter_MAP_Tyvar,rename_apart_by_list_complement]
QED

Theorem ren_LIST_UNION:
   (!r c1 c2. NULL (list_inter (MAP FST (ren r (LIST_UNION c1 c2))) (MAP Tyvar c1)))
   /\ !r c1 c2. NULL (list_inter (MAP FST (ren r (LIST_UNION c1 c2))) (MAP Tyvar c2))
Proof
  fs[ren_def,MAP_MAP_o,FST_SND_PAIR_MAP]
  >> rw[GSYM MAP_MAP_o,NULL_list_inter_MAP_Tyvar,rename_apart_by_LIST_UNION]
QED

Theorem LR_TYPE_SUBST_FILTER_tyvars:
  !p s. is_const_or_type p ==>
  LR_TYPE_SUBST (FILTER (λx. MEM (SND x) (MAP Tyvar (FV p))) s) p
  = LR_TYPE_SUBST s p
Proof
  rw[is_const_or_type_eq,LAMBDA_PROD,sum_case_def,LR_TYPE_SUBST_cases,tvars_def,FV_def]
  >> fs[MEM_MAP,LR_TYPE_SUBST_cases]
  >> qspecl_then [`ty`,`s`] assume_tac TYPE_SUBST_FILTER_tyvars
  >> fs[tvars_def]
  >> qmatch_goalsub_abbrev_tac `TYPE_SUBST (FILTER f1 s) _ = TYPE_SUBST (FILTER f2 s) _`
  >> `f1 = f2` by (
    unabbrev_all_tac
    >> rw[FUN_EQ_THM,EQ_IMP_THM]
  )
  >> fs[]
QED

Theorem FV_renaming_comm:
  !x y r c. is_const_or_type x ==>
    MEM y (MAP (TYPE_SUBST (ren r c) o Tyvar) (FV x)) = MEM y (MAP Tyvar (FV (LR_TYPE_SUBST (ren r c) x)))
Proof
  rw[FV_def,is_const_or_type_eq,sum_case_def,MEM_MAP,LR_TYPE_SUBST_cases,tvars_def,tyvars_TYPE_SUBST,EQ_IMP_THM]
  >> qspecl_then [`r`,`c`] assume_tac ren_Tyvars
  >> fs[sum_case_def,tvars_def,EVERY_MEM]
  >> qmatch_goalsub_abbrev_tac `REV_ASSOCD _ s _`
  >> fs[sum_case_def,LR_TYPE_SUBST_cases,tyvars_def,tvars_def,tyvars_TYPE_SUBST]
  >> qmatch_asmsub_abbrev_tac `MEM z (tyvars ty)`
    ORELSE qmatch_goalsub_abbrev_tac `REV_ASSOCD (Tyvar z) s _`
  >> Cases_on `MEM (Tyvar z) (MAP SND s)`
  >> TRY (imp_res_tac MEM_SPLIT_APPEND_SND_first)
  >> imp_res_tac TYPE_SUBST_drop_prefix
  >> first_assum (qspec_then `[(q,Tyvar z)]++sfx` assume_tac)
  >> first_x_assum (qspec_then `[]` assume_tac)
  >> first_x_assum (qspec_then `(q,Tyvar z)` assume_tac)
  >> rveq
  >> fs[REV_ASSOCD_def]
  >> rveq
  >> goal_assum (first_assum o mp_then Any mp_tac)
  >> fs[tyvars_def]
QED

Theorem TYPE_SUBST_FILTER_MEM1:
  !x tv l1 l2. MEM x tv ==>
  TYPE_SUBST (FILTER (λx. MEM (SND x) (MAP Tyvar (tv))) l1 ++ FILTER (λx. ~MEM (SND x) (MAP Tyvar (tv))) l2) (Tyvar x)
  = TYPE_SUBST l1 (Tyvar x)
Proof
  rw[]
  >> imp_res_tac (Q.ISPEC `Tyvar` MEM_MAP_f)
  >> qmatch_goalsub_abbrev_tac `REV_ASSOCD _ (fl1 ++ fl2) _`
  >> Cases_on `MEM (Tyvar x) (MAP SND l1)`
  >> TRY (imp_res_tac MEM_SPLIT_APPEND_SND_first)
  >> imp_res_tac TYPE_SUBST_drop_prefix
  >> first_assum (qspec_then `[]` assume_tac)
  >> first_x_assum (qspec_then `[(q,Tyvar x)]++sfx` assume_tac)
  >> fs[REV_ASSOCD_def]
  >- (
    qunabbrev_tac `fl1`
    >> qmatch_goalsub_abbrev_tac `FILTER f1 _`
    >> `~MEM (Tyvar x) (MAP SND (FILTER f1 pfx))` by (
      qunabbrev_tac `f1`
      >> fs[MAP_SND_FILTER,MEM_FILTER,MAP_APPEND]
    )
    >> dxrule TYPE_SUBST_drop_prefix
    >> disch_then (qspec_then `[(q,Tyvar x)]++FILTER f1 sfx ++ fl2` assume_tac)
    >> qunabbrev_tac `f1`
    >> fs[FILTER_APPEND,REV_ASSOCD_def]
  )
  >> `~MEM (Tyvar x) (MAP SND (fl1 ++ fl2))` by (
    qunabbrev_tac `fl1`
    >> qunabbrev_tac `fl2`
    >> fs[MAP_SND_FILTER,MEM_FILTER,MAP_APPEND]
  )
  >> drule TYPE_SUBST_drop_prefix
  >> disch_then (qspec_then `[]` assume_tac)
  >> fs[]
QED

Theorem TYPE_SUBST_FILTER_MEM2:
  !x tv l1 l2. ~MEM x tv ==>
  TYPE_SUBST (FILTER (λx. MEM (SND x) (MAP Tyvar tv)) l1
    ++ FILTER (λx. ~MEM (SND x) (MAP Tyvar tv)) l2) (Tyvar x)
  = TYPE_SUBST l2 (Tyvar x)
Proof
  rw[]
  >> imp_res_tac (Q.ISPEC `Tyvar` MEM_MAP_f)
  >> qmatch_goalsub_abbrev_tac `REV_ASSOCD _ (FILTER f1 l1 ++ FILTER f2 l2) _`
  >> `~MEM (Tyvar x) (MAP SND (FILTER f1 l1))` by (
    qunabbrev_tac `f1`
    >> fs[MAP_SND_FILTER,MEM_FILTER]
    >> fs[MEM_MAP]
  )
  >> dxrule TYPE_SUBST_drop_prefix
  >> disch_then (qspec_then `FILTER f2 l2` assume_tac)
  >> fs[]
  >> Cases_on `MEM (Tyvar x) (MAP SND l2)`
  >> TRY (imp_res_tac MEM_SPLIT_APPEND_SND_first)
  >> imp_res_tac TYPE_SUBST_drop_prefix
  >> first_assum (qspec_then `[]` assume_tac)
  >> first_x_assum (qspec_then `[(q,Tyvar x)]++sfx` assume_tac)
  >> fs[REV_ASSOCD_def]
  >- (
    `~MEM (Tyvar x) (MAP SND (FILTER f2 pfx))` by (
      qunabbrev_tac `f2`
      >> qunabbrev_tac `f1`
      >> fs[MAP_SND_FILTER,MEM_FILTER,MAP_APPEND]
    )
    >> dxrule TYPE_SUBST_drop_prefix
    >> disch_then (qspec_then `[(q,Tyvar x)]++FILTER f2 sfx` assume_tac)
    >> qunabbrev_tac `f2`
    >> qunabbrev_tac `f1`
    >> fs[FILTER_APPEND,REV_ASSOCD_def,MEM_MAP]
  )
  >> `~MEM (Tyvar x) (MAP SND (FILTER f2 l2))` by (
    qunabbrev_tac `f2`
    >> qunabbrev_tac `f1`
    >> fs[MAP_SND_FILTER,MEM_FILTER,MAP_APPEND]
  )
  >> drule TYPE_SUBST_drop_prefix
  >> disch_then (qspec_then `[]` assume_tac)
  >> fs[]
QED

Theorem ren_MEM_SND_compl_union =
      GEN_ALL (Q.SPECL [`list_complement (r:mlstring list) (s:mlstring list)`,`LIST_UNION (s:mlstring list) c`] ren_MEM_SND)

Theorem ren_ID_compl_union =
      GEN_ALL (Q.SPECL [`list_complement (r:mlstring list) (s:mlstring list)`,`LIST_UNION (s:mlstring list) c`] ren_ID)

Theorem ren_TYPE_SUBST_INJ1:
  !r c x y.
    MEM x (LIST_UNION r c) /\ MEM y (LIST_UNION r c)
    /\ ~MEM x (list_inter r c) /\ ~MEM y (list_inter r c)
    /\ TYPE_SUBST (ren r c) (Tyvar x) = TYPE_SUBST (ren r c) (Tyvar y)
    ==> x = y
Proof
  rw[]
  >> imp_res_tac (ONCE_REWRITE_RULE[MONO_NOT_EQ] (Ho_Rewrite.REWRITE_RULE[FORALL_AND_THM,EQ_IMP_THM] ren_MEM_SND))
  >> imp_res_tac TYPE_SUBST_drop_all
  >> fs[REV_ASSOCD_def]
QED

Theorem ren_TYPE_SUBST_INJ2:
  !r c x y. MEM x (list_inter r c) /\ MEM y (list_inter r c)
    /\ TYPE_SUBST (ren r c) (Tyvar x) = TYPE_SUBST (ren r c) (Tyvar y)
    ==> x = y
Proof
  rw[]
  >> imp_res_tac ren_MEM_SND
  >> imp_res_tac MEM_SPLIT_APPEND_SND_first
  >> imp_res_tac TYPE_SUBST_drop_prefix
  >> first_x_assum (qspec_then `[(q,Tyvar x)]++sfx` assume_tac)
  >> first_x_assum (qspec_then `[(q',Tyvar y)]++sfx'` assume_tac)
  >> `MEM (q,Tyvar x) (ren r c)` by fs[]
  >> `MEM (q',Tyvar y) (ren r c)` by rfs[]
  >> qspecl_then [`r`,`c`] assume_tac ren_Tyvars
  >> rpt (qpat_x_assum `ren r c = _` (assume_tac o ONCE_REWRITE_RULE[GSYM markerTheory.Abbrev_def]))
  >> fs[REV_ASSOCD_def,EVERY_MEM]
  >> qpat_x_assum `!x. MEM _ _ ==> _` imp_res_tac
  >> qspecl_then [`r`,`c`] assume_tac ren_ALL_DISTINCT
  >> Q.ISPECL_THEN [`q`,`Tyvar x`,`Tyvar y`,`ren r c`] mp_tac ALL_DISTINCT_FST_MEMs
  >> fs[]
  >> disch_then match_mp_tac
  >> rveq
  >> ASM_REWRITE_TAC[]
QED

Theorem ren_TYPE_SUBST_INJ3:
  !r c x y.
    MEM x (list_inter r c)
    /\ ~MEM y (list_inter r c) /\ MEM y (LIST_UNION r c)
    /\ TYPE_SUBST (ren r c) (Tyvar x) = TYPE_SUBST (ren r c) (Tyvar y)
    ==> x = y
Proof
  rw[]
  >> qspecl_then [`r`,`c`,`y`] assume_tac ren_ID
  >> imp_res_tac ren_MEM_SND
  >> imp_res_tac MEM_SPLIT_APPEND_SND_first
  >> imp_res_tac TYPE_SUBST_drop_prefix
  >> first_x_assum (qspec_then `[(q,Tyvar x)]++sfx` assume_tac)
  >> fs[REV_ASSOCD_def,DISJ_IMP_THM]
  >> qpat_x_assum `ren r c = _` mp_tac
  >> qspecl_then [`r`,`c`] (assume_tac o REWRITE_RULE[list_inter_def,NULL_FILTER]) ren_disj_img_c
  >> qspecl_then [`r`,`c`] (assume_tac o REWRITE_RULE[list_inter_def,NULL_FILTER]) ren_disj_img_r
  >> rpt (first_x_assum (qspec_then `Tyvar y` assume_tac))
  >> fs[MEM_Tyvar_MAP_Tyvar]
  >> fs[MEM_FILTER,list_inter_def,list_complement_def,MEM_LIST_UNION]
  >> rfs[]
  >> strip_tac
  >> fs[]
QED

Theorem ren_TYPE_SUBST_INJ:
  !r c x y.
    MEM x (LIST_UNION r c) /\ MEM y (LIST_UNION r c)
    /\ TYPE_SUBST (ren r c) (Tyvar x) = TYPE_SUBST (ren r c) (Tyvar y)
    ==> x = y
Proof
  rpt strip_tac
  >> qspecl_then [`r`,`c`,`x`,`y`] mp_tac ren_TYPE_SUBST_INJ1
  >> qspecl_then [`r`,`c`,`x`,`y`] mp_tac ren_TYPE_SUBST_INJ2
  >> qspecl_then [`r`,`c`,`x`,`y`] mp_tac ren_TYPE_SUBST_INJ3
  >> qspecl_then [`r`,`c`,`y`,`x`] mp_tac ren_TYPE_SUBST_INJ3
  >> ASM_REWRITE_TAC[]
  >> Cases_on `MEM x (list_inter r c)`
  >> Cases_on `MEM y (list_inter r c)`
  >> ASM_REWRITE_TAC[]
  >> fs[]
QED

Theorem ren_MEM_list_complement:
  !r s c x. let sigma = ren (list_complement r s) (LIST_UNION s c) in
  MEM (Tyvar x) (MAP (TYPE_SUBST sigma o Tyvar) (list_complement r s))
  = MEM (Tyvar x) (list_complement (MAP (TYPE_SUBST sigma o Tyvar) r) (MAP (TYPE_SUBST sigma o Tyvar) s))
Proof
  rw[]
  >> match_mp_tac list_complement_MAP_INJ1
  >> rw[o_DEF]
  >> qspecl_then [`list_complement r s`,`LIST_UNION s c`] mp_tac ren_TYPE_SUBST_INJ
  >> disch_then match_mp_tac
  >> ASM_REWRITE_TAC[TYPE_SUBST_def]
  >> fs[MEM_FILTER,list_inter_def,list_complement_def,MEM_LIST_UNION]
  >> Cases_on `MEM x s`
  >> ASM_REWRITE_TAC[]
  >> Cases_on `MEM y s`
  >> ASM_REWRITE_TAC[]
QED

(* bijective version of ren *)

Definition renn_def:
  renn r c =
    ren r c ++ MAP SWAP (ren r c)
End

Theorem renn_ALL_DISTINCT:
  !r c. ALL_DISTINCT (MAP SND (renn r c))
  /\ ALL_DISTINCT (MAP FST (renn r c))
Proof
  rw[ALL_DISTINCT_APPEND,renn_def,ren_ALL_DISTINCT,MAP_MAP_o,FST_SND_SWAP]
  >> imp_res_tac (REWRITE_RULE[list_inter_def,NULL_FILTER] ren_disj_dom_img)
  >> imp_res_tac ((REWRITE_RULE[list_inter_def,NULL_FILTER] o ONCE_REWRITE_RULE[NULL_list_inter_COMM]) ren_disj_dom_img)
  >> fs[]
QED

Theorem renn_Tyvars:
  !r c. EVERY (λx. ?y1 y2. x = (Tyvar y1,Tyvar y2)) (renn r c)
Proof
  rw[SWAP_def,EVERY_MEM,ren_def,renn_def,MEM_MAP,PAIR_MAP]
QED

Theorem renn_diff:
  !r c. EVERY (UNCURRY $<>) (renn r c)
Proof
  rw[EVERY_MEM,MEM_APPEND,renn_def,MEM_MAP,SWAP_def]
  >> imp_res_tac (REWRITE_RULE[EVERY_MEM] ren_diff)
  >> fs[ELIM_UNCURRY]
QED

Theorem renn_set_MAP_SWAP:
  !r c. set (MAP SWAP (renn r c)) = set (renn r c)
Proof
  rw[renn_def,SWAP_SWAP_INVOL,MAP_MAP_o,UNION_COMM]
QED

Theorem renn_MEM_MAP_SWAP:
  !r c x. MEM x (MAP SWAP (renn r c)) <=> MEM x (renn r c)
Proof
  fs[renn_set_MAP_SWAP]
QED

(* renn is a var_renaming *)
Theorem renn_var_renaming:
  var_renaming (renn r c)
Proof
  fs[var_renaming_eq,rename_bij_def,renn_ALL_DISTINCT,renn_diff,renn_Tyvars]
  >> fs[MEM_MAP_SWAP,EVERY_MEM,GSYM renn_MEM_MAP_SWAP]
  >> fs[renn_def,MAP_MAP_o,FST_SND_SWAP,UNION_COMM]
QED

Theorem renn_MEM:
  !r c x y. MEM (x,y) (renn r c) <=> MEM (y,x) (renn r c)
Proof
  rw[]
  >> qspecl_then [`SWAP`,`renn r c`] assume_tac
    (INST_TYPE [alpha |-> ``:type#type``,beta|-> ``:type#type``] MEM_f_MAP_f_INJ)
  >> fs[SWAP_eq,LAMBDA_PROD]
  >> fs[ELIM_UNCURRY,GSYM SWAP_eq]
  >> pop_assum (fn x => CONV_TAC (RHS_CONV (ONCE_REWRITE_CONV[GSYM x])))
  >> fs[renn_set_MAP_SWAP]
QED

Theorem renn_MAP_FST_SND:
  !r c x. MEM x (MAP FST (renn r c)) <=> MEM x (MAP SND (renn r c))
Proof
  ONCE_REWRITE_TAC[CONJUNCT1 (GSYM FST_SND_SWAP)]
  >> fs[GSYM MAP_MAP_o]
  >> CONV_TAC(ONCE_DEPTH_CONV(RHS_CONV(PURE_ONCE_REWRITE_CONV [MEM_MAP])))
  >> fs[renn_set_MAP_SWAP]
  >> fs[MEM_MAP]
QED

Theorem renn_bij:
  !r c x y. TYPE_SUBST (renn r c) (Tyvar x) = (Tyvar y)
  ==> TYPE_SUBST (renn r c) (Tyvar y) = (Tyvar x)
Proof
  rpt gen_tac
  >> rename1`renn r c`
  >> qspecl_then [`r`,`c`] assume_tac (GEN_ALL renn_var_renaming)
  >> drule var_renaming_SWAP_idem
  >> ONCE_REWRITE_TAC[GSYM AND_IMP_INTRO]
  >> disch_then match_mp_tac
  >> fs[renn_set_MAP_SWAP]
QED

Theorem renn_bij2:
  !r c x y z.
  TYPE_SUBST (renn r c) (Tyvar x) = (Tyvar z)
  /\ TYPE_SUBST (renn r c) (Tyvar y) = (Tyvar z)
  ==> x = y
Proof
  rpt strip_tac
  >> imp_res_tac renn_bij
  >> fs[]
QED

Theorem renn_Tyvars_TYPE_SUBST:
  !r c x. ?a. TYPE_SUBST (renn r c) (Tyvar x) = Tyvar a
Proof
  rw[]
  >> Cases_on `MEM (Tyvar x) (MAP SND (renn r c))`
  >- (
    imp_res_tac TYPE_SUBST_MEM_MAP_SND
    >> imp_res_tac (REWRITE_RULE[EVERY_MEM] renn_Tyvars)
    >> fs[]
  )
  >> imp_res_tac TYPE_SUBST_drop_all
  >> fs[]
QED

Theorem renn_bij3:
  !r c x y.
  TYPE_SUBST (renn r c) (Tyvar x)
  = TYPE_SUBST (renn r c) (Tyvar y)
  ==> x = y
Proof
  rpt strip_tac
  >> match_mp_tac renn_bij2
  >> qspecl_then [`r`,`c`,`x`] strip_assume_tac renn_Tyvars_TYPE_SUBST
  >> goal_assum (first_assum o mp_then Any mp_tac)
  >> fs[]
QED

Theorem renn_TYPE_SUBST_idem:
  !r c x. TYPE_SUBST (renn r c) (TYPE_SUBST (renn r c) (Tyvar x)) = Tyvar x
Proof
  rpt gen_tac
  >> match_mp_tac var_renaming_SWAP_idem'
  >> fs[renn_var_renaming,renn_set_MAP_SWAP]
QED

Theorem renn_LR_TYPE_SUBST_idem:
  !r c x. is_const_or_type x ==> LR_TYPE_SUBST (renn r c) (LR_TYPE_SUBST (renn r c) x) = x
Proof
  rw[is_const_or_type_eq]
  >> fs[LR_TYPE_SUBST_cases,TYPE_SUBST_compose]
  >> CONV_TAC(RHS_CONV(PURE_ONCE_REWRITE_CONV [GSYM TYPE_SUBST_NIL]))
  >> rw[TYPE_SUBST_tyvars]
  >> ONCE_REWRITE_TAC[GSYM TYPE_SUBST_def]
  >> fs[GSYM TYPE_SUBST_compose,renn_TYPE_SUBST_idem]
QED

Theorem ren_Tyvars_TYPE_SUBST:
  !r c x. ?a. TYPE_SUBST (ren r c) (Tyvar x) = Tyvar a
Proof
  rw[]
  >> Cases_on `MEM (Tyvar x) (MAP SND (ren r c))`
  >- (
    imp_res_tac TYPE_SUBST_MEM_MAP_SND
    >> imp_res_tac (REWRITE_RULE[EVERY_MEM] ren_Tyvars)
    >> fs[]
    >> rveq
  )
  >> dxrule TYPE_SUBST_drop_all
  >> fs[]
QED

Theorem MEM_FV_LR_TYPE_SUBST_ren_imp:
  !x t.
  MEM x (FV (LR_TYPE_SUBST (ren r c) t)) /\ is_const_or_type t
  ==> ?y. MEM y (FV t) /\ TYPE_SUBST (ren r c) (Tyvar y) = Tyvar x
Proof
  rw[is_const_or_type_eq]
  >> fs[LR_TYPE_SUBST_cases,FV_def,sum_case_def,tyvars_def,tvars_def,tyvars_TYPE_SUBST]
  >> qspecl_then [`r`,`c`,`x'`] assume_tac ren_Tyvars_TYPE_SUBST
  >> fs[tyvars_def]
  >> goal_assum (first_assum o mp_then Any mp_tac)
  >> fs[tyvars_def]
QED

Theorem MEM_FV_LR_TYPE_SUBST_renn_imp:
  !x t r c. MEM x (FV (LR_TYPE_SUBST (renn r c) t)) /\ is_const_or_type t
  ==> ?y. MEM y (FV t) /\ TYPE_SUBST (renn r c) (Tyvar y) = Tyvar x
Proof
  rw[is_const_or_type_eq]
  >> fs[LR_TYPE_SUBST_cases,FV_def,sum_case_def,tyvars_def,tvars_def,tyvars_TYPE_SUBST]
  >> qspecl_then [`r`,`c`,`x'`] assume_tac renn_Tyvars_TYPE_SUBST
  >> fs[tyvars_def]
  >> goal_assum (first_assum o mp_then Any mp_tac)
  >> fs[tyvars_def]
QED

Theorem renn_MEM_SND:
  !r c x. MEM x (LIST_UNION r c) ==>
  MEM x (list_inter r c) = MEM (Tyvar x) (MAP SND (renn r c))
Proof
  fs[renn_def,ren_MEM_SND,MAP_MAP_o,FST_SND_SWAP]
  >> rw[EQ_IMP_THM]
  >> qspecl_then [`r`,`c`,`Tyvar x`] assume_tac (REWRITE_RULE[NULL_FILTER,list_inter_def] ren_disj_img_r)
  >> qspecl_then [`r`,`c`,`Tyvar x`] assume_tac (REWRITE_RULE[NULL_FILTER,list_inter_def] ren_disj_img_c)
  >> rfs[MEM_Tyvar_MAP_Tyvar]
QED

Theorem renn_MEM_SND_compl_union =
      GEN_ALL (Q.SPECL [`list_complement (r:mlstring list) (s:mlstring list)`,`LIST_UNION (s:mlstring list) c`] renn_MEM_SND)

Theorem renn_ID:
  !r c x. MEM x (list_complement r c) \/ MEM x (list_complement c r)
  ==> TYPE_SUBST (renn r c) (Tyvar x) = Tyvar x
Proof
  rw[MEM_FILTER,list_complement_def]
  >> `~MEM (Tyvar x) (MAP SND (renn r c))` by (
    fs[GSYM renn_MEM_SND,list_inter_def,MEM_FILTER]
  )
  >> imp_res_tac TYPE_SUBST_drop_all
  >> fs[]
QED

Theorem renn_ID_LR_TYPE_SUBST:
  !r s c t. is_const_or_type t
  /\ list_subset (FV t) s
  ==> LR_TYPE_SUBST (renn (list_complement r s) (LIST_UNION s c)) t = t
Proof
  rw[is_const_or_type_eq,FV_def]
  >> fs[sum_case_def,tyvars_def,tvars_def,LR_TYPE_SUBST_cases,list_subset_def,EVERY_MEM]
  >> CONV_TAC(RHS_CONV(PURE_ONCE_REWRITE_CONV [GSYM TYPE_SUBST_NIL]))
  >> rw[TYPE_SUBST_tyvars,REV_ASSOCD_def]
  >> ONCE_REWRITE_TAC[EQ_SYM_EQ]
  >> ONCE_REWRITE_TAC[GSYM TYPE_SUBST_def]
  >> match_mp_tac renn_ID
  >> fs[MEM_FILTER,list_inter_def,MEM_LIST_UNION,list_complement_def]
QED

Theorem renn_disj_dom_s:
  !r s c. NULL (list_inter (MAP SND (renn (list_complement r s) (LIST_UNION s c))) (MAP Tyvar s))
Proof
  rw[NULL_FILTER,list_inter_def]
  >> pop_assum (assume_tac o REWRITE_RULE[MEM_MAP])
  >> fs[]
  >> rveq
  >> qspecl_then [`list_complement r s`,`LIST_UNION s c`,`y'`] mp_tac renn_MEM_SND
  >> fs[MEM_LIST_UNION,list_inter_def,MEM_FILTER,list_complement_def]
QED

Theorem renn_disj_dom_img2:
  !r s c. NULL (list_inter (MAP ((TYPE_SUBST (renn (list_complement r s) (LIST_UNION s c))) o $Tyvar) (list_complement r s)) (MAP Tyvar s))
Proof
  rw[NULL_FILTER,list_inter_def,GSYM MAP_MAP_o]
  >> rw[MEM_MAP]
  >> drule (REWRITE_RULE[NULL_FILTER,list_inter_def] renn_disj_dom_s)
  >> disch_then (qspecl_then [`r`,`c`] assume_tac)
  >> CCONTR_TAC
  >> fs[]
  >> imp_res_tac (ONCE_REWRITE_RULE[MONO_NOT_EQ] (Ho_Rewrite.REWRITE_RULE[FORALL_AND_THM,EQ_IMP_THM] renn_MAP_FST_SND))
  >> qmatch_asmsub_abbrev_tac `TYPE_SUBST sigma`
  >> Cases_on `MEM (Tyvar y'') (MAP SND sigma)`
  >- (
    qunabbrev_tac `sigma`
    >> imp_res_tac TYPE_SUBST_MEM_MAP_SND
    >> imp_res_tac (Q.ISPEC `FST` MEM_MAP_f)
    >> imp_res_tac renn_MAP_FST_SND
    >> imp_res_tac (REWRITE_RULE[NULL_FILTER,list_inter_def] renn_disj_dom_s)
    >> rfs[]
    >> fs[]
  )
  >> imp_res_tac TYPE_SUBST_drop_all
  >> rveq
  >> fs[MEM_Tyvar_MAP_Tyvar,list_complement_def,MEM_FILTER]
QED

Theorem renn_disj_dom_img3:
  !r c. NULL (list_inter (MAP ((TYPE_SUBST (renn r c)) o $Tyvar) (list_inter r c)) (MAP Tyvar c))
Proof
  rw[NULL_FILTER,list_inter_def,GSYM MAP_MAP_o,MEM_MAP]
  >> CCONTR_TAC
  >> fs[MEM_FILTER,renn_def]
  >> qspecl_then [`r`,`c`,`y''`] assume_tac ren_MEM_SND
  >> rfs[MEM_LIST_UNION,list_inter_def,MEM_FILTER]
  >> fs[REWRITE_RULE[TYPE_SUBST_def] TYPE_SUBST_drop_suffix]
  >> fs[GSYM MEM_Tyvar_MAP_Tyvar]
  >> qspecl_then [`r`,`c`,`Tyvar y'`] assume_tac (REWRITE_RULE[NULL_FILTER,list_inter_def] ren_disj_dom_img2)
  >> rfs[MEM_Tyvar_MAP_Tyvar,MEM_MAP]
  >> qpat_x_assum `_ = REV_ASSOCD _ _ _` (assume_tac o GSYM)
  >> fs[]
  >> rfs[]
  >> first_x_assum (qspec_then `y''` (assume_tac o GSYM))
  >> Cases_on `y`
  >> fs[]
  >> rveq
  >> fs[]
QED

Theorem renn_disj_dom_img4:
  !r c. NULL (list_inter (MAP ((TYPE_SUBST (renn r c)) o $Tyvar) r) (MAP Tyvar c))
Proof
  ONCE_REWRITE_TAC[NULL_list_inter_COMM]
  >> rw[NULL_FILTER,list_inter_def]
  >> pop_assum (assume_tac o REWRITE_RULE[MEM_MAP])
  >> mp_tac ((REWRITE_RULE[NULL_FILTER,list_inter_def] o ONCE_REWRITE_RULE[NULL_list_inter_COMM]) renn_disj_dom_img3)
  >> fs[Once EQ_SYM_EQ]
  >> Cases_on `MEM y' c`
  >- (
    disch_then match_mp_tac
    >> rw[MEM_MAP,MEM_FILTER]
    >> qexists_tac `r`
    >> goal_assum (first_assum o mp_then Any mp_tac)
    >> fs[]
  )
  >> disch_then kall_tac
  >> qspecl_then [`r`,`c`,`y'`] assume_tac renn_MEM_SND
  >> rfs[MEM_FILTER,list_inter_def]
  >> imp_res_tac TYPE_SUBST_drop_all
  >> rfs[MEM_Tyvar_MAP_Tyvar]
QED

Theorem renn_compl_union_TYPE_SUBST_s:
  !r s c y x. let sigma = renn (list_complement r s) (LIST_UNION s c) in
  MEM y r /\ TYPE_SUBST sigma (Tyvar y) = Tyvar x
  /\ ~MEM x s
  ==> ~MEM (Tyvar x) (MAP ((TYPE_SUBST sigma) o Tyvar) s)
Proof
  rw[MEM_MAP]
  >> Cases_on `MEM y s`
  >- (
     qspecl_then [`s`,`r`,`c`,`y`] mp_tac renn_MEM_SND_compl_union
    >> rw[MEM_FILTER,MEM_LIST_UNION,list_inter_def,list_complement_def]
    >> fs[GSYM list_complement_def]
    >> imp_res_tac TYPE_SUBST_drop_all
    >> fs[]
    >> rveq
    >> fs[]
  )
  >> qmatch_goalsub_abbrev_tac `a \/ _`
  >> Cases_on `a`
  >> mp_tac renn_bij3
  >> fs[markerTheory.Abbrev_def]
  >> disch_then drule
  >> rw[]
  >> fs[]
QED

val _ = export_theory();
