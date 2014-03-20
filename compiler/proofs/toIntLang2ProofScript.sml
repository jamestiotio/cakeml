open preamble;
open alistTheory optionTheory rich_listTheory;
open miscTheory;
open astTheory;
open semanticPrimitivesTheory;
open libTheory;
open libPropsTheory;
open intLang1Theory;
open intLang2Theory;
open toIntLang1ProofTheory;
open evalPropsTheory;

val _ = new_theory "toIntLang2Proof";

val fmap_inverse_def = Define `
fmap_inverse m1 m2 =
  !k. k ∈ FDOM m1 ⇒ ?v. FLOOKUP m1 k = SOME v ∧ FLOOKUP m2 v = SOME k`;

val map_some_eq = Q.prove (
`!l1 l2. MAP SOME l1 = MAP SOME l2 ⇔ l1 = l2`,
 induct_on `l1` >>
 rw [] >>
 Cases_on `l2` >>
 rw []);

val map_some_eq_append = Q.prove (
`!l1 l2 l3. MAP SOME l1 ++ MAP SOME l2 = MAP SOME l3 ⇔ l1 ++ l2 = l3`,
metis_tac [map_some_eq, MAP_APPEND]);

val _ = augment_srw_ss [rewrites [map_some_eq,map_some_eq_append]];

val lookup_reverse = Q.prove (
`∀x l.
 ALL_DISTINCT (MAP FST l) ⇒
 lookup x (REVERSE l) = lookup x l`,
 induct_on `l` >>
 rw [] >>
 PairCases_on `h` >>
 rw [lookup_append] >>
 every_case_tac >>
 fs [] >>
 imp_res_tac lookup_in2);

val lookup_con_id_rev = Q.prove (
`!cn fenvC envC.
  ALL_DISTINCT (MAP FST fenvC) ⇒
  lookup_con_id cn (merge_envC ([],REVERSE fenvC) envC)
  =
  lookup_con_id cn (merge_envC ([],fenvC) envC)`,
 rw [] >>
 cases_on `cn` >>
 PairCases_on `envC` >>
 fs [merge_envC_def, lookup_con_id_def, merge_def, lookup_append] >>
 every_case_tac >>
 fs [] >>
 metis_tac [lookup_reverse, SOME_11, NOT_SOME_NONE]);

val same_tid_diff_ctor = Q.prove (
`!cn1 cn2 t1 t2.
  same_tid t1 t2 ∧ ~same_ctor (cn1, t1) (cn2, t2)
  ⇒
  (cn1 ≠ cn2) ∨ (cn1 = cn2 ∧ ?mn1 mn2. t1 = TypeExn mn1 ∧ t2 = TypeExn mn2 ∧ mn1 ≠ mn2)`,
rw [] >>
cases_on `t1` >>
cases_on `t2` >>
fs [same_tid_def, same_ctor_def]);

fun register name def ind =
  let val _ = save_thm (name ^ "_def", def);
      val _ = save_thm (name ^ "_ind", ind);
      val _ = computeLib.add_persistent_funs [name ^ "_def"];
  in
    ()
  end;

val (pat_to_i2_def, pat_to_i2_ind) =
  tprove_no_defn ((pat_to_i2_def, pat_to_i2_ind),
  wf_rel_tac `inv_image $< (\(x,p). pat_size p)` >>
  srw_tac [ARITH_ss] [pat_size_def] >>
  induct_on `ps` >>
  srw_tac [ARITH_ss] [pat_size_def] >>
  srw_tac [ARITH_ss] [pat_size_def] >>
  res_tac >>
  decide_tac);
val _ = register "pat_to_i2" pat_to_i2_def pat_to_i2_ind;

val (exp_to_i2_def, exp_to_i2_ind) =
  tprove_no_defn ((exp_to_i2_def, exp_to_i2_ind),
  wf_rel_tac `inv_image $< (\x. case x of INL (x,e) => exp_i1_size e
                                        | INR (INL (x,es)) => exp_i16_size es
                                        | INR (INR (INL (x,pes))) => exp_i13_size pes
                                        | INR (INR (INR (x,funs))) => exp_i11_size funs)` >>
  srw_tac [ARITH_ss] [exp_i1_size_def]);
val _ = register "exp_to_i2" exp_to_i2_def exp_to_i2_ind;

val (pmatch_i2_def, pmatch_i2_ind) =
  tprove_no_defn ((pmatch_i2_def, pmatch_i2_ind),
  wf_rel_tac `inv_image $< (\x. case x of INL (x,p,y,z) => pat_i2_size p
                                        | INR (x,ps,y,z) => pat_i21_size ps)` >>
  srw_tac [ARITH_ss] [pat_i2_size_def]);
val _ = register "pmatch_i2" pmatch_i1_def pmatch_i2_ind;

val (do_eq_i2_def, do_eq_i2_ind) =
  tprove_no_defn ((do_eq_i2_def, do_eq_i2_ind),
  wf_rel_tac `inv_image $< (\x. case x of INL (x,y) => v_i2_size x
                                        | INR (xs,ys) => v_i23_size xs)`);
val _ = register "do_eq_i2" do_eq_i2_def do_eq_i2_ind;

val build_rec_env_i2_help_lem = Q.prove (
`∀funs env funs'.
FOLDR (λ(f,x,e) env'. bind f (Recclosure_i2 env funs' f) env') env' funs =
merge (MAP (λ(fn,n,e). (fn, Recclosure_i2 env funs' fn)) funs) env'`,
Induct >>
rw [merge_def, bind_def] >>
PairCases_on `h` >>
rw []);

val build_rec_env_i2_merge = Q.store_thm ("build_rec_env_i2_merge",
`∀funs funs' env env'.
  build_rec_env_i2 funs env env' =
  merge (MAP (λ(fn,n,e). (fn, Recclosure_i2 env funs fn)) funs) env'`,
rw [build_rec_env_i2_def, build_rec_env_i2_help_lem]);

val funs_to_i2_map = Q.prove (
`!funs.
  funs_to_i2 cenv funs = MAP (\(f,x,e). (f,x,exp_to_i2 cenv e)) funs`,
 induct_on `funs` >>
 rw [exp_to_i2_def] >>
 PairCases_on `h` >>
 rw [exp_to_i2_def]);

val has_exns_def = Define `
has_exns gtagenv ⇔
  FLOOKUP gtagenv ("Bind", TypeExn (Short "Bind")) = SOME (bind_tag,0:num) ∧
  FLOOKUP gtagenv ("Div", TypeExn (Short "Div")) = SOME (div_tag,0) ∧
  FLOOKUP gtagenv ("Eq", TypeExn (Short "Eq")) = SOME (eq_tag,0)`;

val cenv_inv_def = Define `
cenv_inv envC tagenv gtagenv ⇔
  (!cn num_args t.
    lookup_con_id cn envC = SOME (num_args, t)
    ⇒
    ?tag.
      lookup_tag_env (SOME cn) tagenv = tag ∧
      FLOOKUP gtagenv (id_to_n cn, t) = SOME (tag,num_args)) ∧
  (!cn l. FLOOKUP gtagenv cn ≠ SOME (tuple_tag,l)) ∧
  has_exns gtagenv ∧
  (!t1 t2 tag l1 l2 cn cn'.
     (* Comment out same_tid because we're not using separate tag spaces per type *)
     (* same_tid t1 t2 ∧ *)
     FLOOKUP gtagenv (cn,t1) = SOME (tag,l1) ∧
     FLOOKUP gtagenv (cn',t2) = SOME (tag,l2)
     ⇒
     cn = cn' ∧ t1 = t2)`;

val (v_to_i2_rules, v_to_i2_ind, v_to_i2_cases) = Hol_reln `
(!gtagenv lit.
  v_to_i2 gtagenv (Litv_i1 lit) (Litv_i2 lit)) ∧
(!gtagenv vs vs'.
  vs_to_i2 gtagenv vs vs'
  ⇒ 
  v_to_i2 gtagenv (Conv_i1 NONE vs) (Conv_i2 tuple_tag vs')) ∧
(!gtagenv cn tn tag vs vs'.
  FLOOKUP gtagenv (cn,tn) = SOME (tag, LENGTH vs) ∧
  vs_to_i2 gtagenv vs vs'
  ⇒ 
  v_to_i2 gtagenv (Conv_i1 (SOME (cn,tn)) vs) (Conv_i2 tag vs')) ∧
(!gtagenv env x e env_i2 envC tagenv.
  env_to_i2 gtagenv env env_i2 ∧
  cenv_inv envC tagenv gtagenv
  ⇒ 
  v_to_i2 gtagenv (Closure_i1 (envC,env) x e) (Closure_i2 env_i2 x (exp_to_i2 tagenv e))) ∧ 
(!gtagenv env funs x envC env_i2 tagenv.
  env_to_i2 gtagenv env env_i2 ∧
  cenv_inv envC tagenv gtagenv
  ⇒ 
  v_to_i2 gtagenv (Recclosure_i1 (envC,env) funs x) (Recclosure_i2 env_i2 (funs_to_i2 tagenv funs) x)) ∧
(!gtagenv loc.
  v_to_i2 gtagenv (Loc_i1 loc) (Loc_i2 loc)) ∧
(!gtagenv.
  vs_to_i2 gtagenv [] []) ∧
(!gtagenv v vs v' vs'.
  v_to_i2 gtagenv v v' ∧
  vs_to_i2 gtagenv vs vs'
  ⇒
  vs_to_i2 gtagenv (v::vs) (v'::vs')) ∧
(!gtagenv.
  env_to_i2 gtagenv [] []) ∧
(!gtagenv x v env env' v'. 
  env_to_i2 gtagenv env env' ∧
  v_to_i2 gtagenv v v'
  ⇒ 
  env_to_i2 gtagenv ((x,v)::env) ((x,v')::env'))`;

val v_to_i2_eqns = Q.prove (
`(!gtagenv l v.
  v_to_i2 gtagenv (Litv_i1 l) v ⇔ 
    (v = Litv_i2 l)) ∧
 (!gtagenv cn vs v.
  v_to_i2 gtagenv (Conv_i1 cn vs) v ⇔ 
    (?vs' tag gtagenv' clengths.
       vs_to_i2 gtagenv vs vs' ∧ (v = Conv_i2 tag vs') ∧
       (cn = NONE ∧ tag = tuple_tag ∨
        ?cn' tn.
          FLOOKUP gtagenv (cn',tn) = SOME (tag,LENGTH vs) ∧
          cn = SOME (cn',tn)))) ∧
 (!gtagenv l v.
  v_to_i2 gtagenv (Loc_i1 l) v ⇔ 
    (v = Loc_i2 l)) ∧
 (!gtagenv vs.
  vs_to_i2 gtagenv [] vs ⇔ 
    (vs = [])) ∧
 (!gtagenv l v vs vs'.
  vs_to_i2 gtagenv (v::vs) vs' ⇔ 
    ?v' vs''. v_to_i2 gtagenv v v' ∧ vs_to_i2 gtagenv vs vs'' ∧ vs' = v'::vs'') ∧
 (!gtagenv env'.
  env_to_i2 gtagenv [] env' ⇔
    env' = []) ∧
 (!gtagenv x v env env'.
  env_to_i2 gtagenv ((x,v)::env) env' ⇔
    ?v' env''. v_to_i2 gtagenv v v' ∧ env_to_i2 gtagenv env env'' ∧ env' = ((x,v')::env''))`,
rw [] >>
rw [Once v_to_i2_cases] >>
metis_tac []);

val gtagenv_weak_def = Define `
gtagenv_weak gtagenv1 gtagenv2 ⇔
  gtagenv1 SUBMAP gtagenv2 ∧
  (!cn l. FLOOKUP gtagenv2 cn ≠ SOME (tuple_tag,l)) ∧
  (!t1 t2 tag cn cn' l1 l2.
     (* Comment out same_tid because we're not using separate tag spaces per type *)
     (* same_tid t1 t2 ∧ *)
     FLOOKUP gtagenv2 (cn,t1) = SOME (tag,l1) ∧
     FLOOKUP gtagenv2 (cn',t2) = SOME (tag,l2)
     ⇒
     cn = cn' ∧ t1 = t2)`;

val v_to_i2_weakening = Q.prove (
`(!gtagenv v v_i2.
  v_to_i2 gtagenv v v_i2
  ⇒
    !gtagenv'. gtagenv_weak gtagenv gtagenv'
    ⇒
    v_to_i2 gtagenv' v v_i2) ∧
 (!gtagenv vs vs_i2.
  vs_to_i2 gtagenv vs vs_i2
  ⇒
   !gtagenv'. gtagenv_weak gtagenv gtagenv'
    ⇒
    vs_to_i2 gtagenv' vs vs_i2) ∧
 (!gtagenv env env_i2.
  env_to_i2 gtagenv env env_i2
  ⇒
   !gtagenv'. gtagenv_weak gtagenv gtagenv'
    ⇒
    env_to_i2 gtagenv' env env_i2)`,
 ho_match_mp_tac v_to_i2_ind >>
 rw [v_to_i2_eqns, gtagenv_weak_def] >>
 res_tac >>
 fs [gtagenv_weak_def]
 >- metis_tac [FLOOKUP_SUBMAP]
 >- (rw [Once v_to_i2_cases] >>
     qexists_tac `tagenv` >>
     fs [cenv_inv_def] >>
     rw []
     >- metis_tac [FLOOKUP_SUBMAP]
     >- (fs [has_exns_def] >>
         metis_tac [FLOOKUP_SUBMAP])
     >- metis_tac []
     >- metis_tac [])
 >- (rw [Once v_to_i2_cases] >>
     qexists_tac `tagenv` >>
     fs [cenv_inv_def] >>
     rw []
     >- metis_tac [FLOOKUP_SUBMAP]
     >- (fs [has_exns_def] >>
         metis_tac [FLOOKUP_SUBMAP])
     >- metis_tac []
     >- metis_tac []));

val (result_to_i2_rules, result_to_i2_ind, result_to_i2_cases) = Hol_reln `
(∀gtagenv v v'. 
  f gtagenv v v'
  ⇒
  result_to_i2 f gtagenv (Rval v) (Rval v')) ∧
(∀gtagenv v v'. 
  v_to_i2 gtagenv v v'
  ⇒
  result_to_i2 f gtagenv (Rerr (Rraise v)) (Rerr (Rraise v'))) ∧
(!gtagenv.
  result_to_i2 f gtagenv (Rerr Rtimeout_error) (Rerr Rtimeout_error)) ∧
(!gtagenv.
  result_to_i2 f gtagenv (Rerr Rtype_error) (Rerr Rtype_error))`;

val result_to_i2_eqns = Q.prove (
`(!gtagenv v r.
  result_to_i2 f gtagenv (Rval v) r ⇔ 
    ?v'. f gtagenv v v' ∧ r = Rval v') ∧
 (!gtagenv v r.
  result_to_i2 f gtagenv (Rerr (Rraise v)) r ⇔ 
    ?v'. v_to_i2 gtagenv v v' ∧ r = Rerr (Rraise v')) ∧
 (!gtagenv v r.
  result_to_i2 f gtagenv (Rerr Rtimeout_error) r ⇔ 
    r = Rerr Rtimeout_error) ∧
 (!gtagenv v r.
  result_to_i2 f gtagenv (Rerr Rtype_error) r ⇔ 
    r = Rerr Rtype_error)`,
rw [result_to_i2_cases] >>
metis_tac []);

val (s_to_i2'_rules, s_to_i2'_ind, s_to_i2'_cases) = Hol_reln `
(!gtagenv s s'.
  vs_to_i2 gtagenv s s'
  ⇒
  s_to_i2' gtagenv s s')`;

val (s_to_i2_rules, s_to_i2_ind, s_to_i2_cases) = Hol_reln `
(!gtagenv c s s'.
  s_to_i2' gtagenv s s'
  ⇒
  s_to_i2 gtagenv (c,s) (c,s'))`;

val length_vs_to_i2 = Q.prove (
`!vs gtagenv vs'. 
  vs_to_i2 gtagenv vs vs'
  ⇒
  LENGTH vs = LENGTH vs'`,
 induct_on `vs` >>
 rw [v_to_i2_eqns] >>
 rw [] >>
 metis_tac []);

val length_evaluate_list_i2 = Q.prove (
`!b env s gtagenv es s' vs.
  evaluate_list_i2 b env s (exps_to_i2 gtagenv es) (s', Rval vs)
  ⇒
  LENGTH es = LENGTH vs`,
 induct_on `es` >>
 rw [exp_to_i2_def] >>
 cases_on `vs` >>
 pop_assum (mp_tac o SIMP_RULE (srw_ss()) [Once evaluate_i2_cases]) >>
 rw [] >>
 metis_tac []);

val env_to_i2_el = Q.prove (
`!gtagenv env env_i2. 
  env_to_i2 gtagenv env env_i2 ⇔ 
  LENGTH env = LENGTH env_i2 ∧ !n. n < LENGTH env ⇒ (FST (EL n env) = FST (EL n env_i2)) ∧ v_to_i2 gtagenv (SND (EL n env)) (SND (EL n env_i2))`,
 induct_on `env` >>
 rw [v_to_i2_eqns]
 >- (cases_on `env_i2` >>
     fs []) >>
 PairCases_on `h` >>
 rw [v_to_i2_eqns] >>
 eq_tac >>
 rw [] >>
 rw []
 >- (cases_on `n` >>
     fs [])
 >- (cases_on `n` >>
     fs [])
 >- (cases_on `env_i2` >>
     fs [] >>
     FIRST_ASSUM (qspecl_then [`0`] mp_tac) >>
     SIMP_TAC (srw_ss()) [] >>
     rw [] >>
     qexists_tac `SND h` >>
     rw [] >>
     FIRST_X_ASSUM (qspecl_then [`SUC n`] mp_tac) >>
     rw []));

val vs_to_i2_lupdate = Q.prove (
`!gtagenv v n s v_i2 n s_i2.
  vs_to_i2 gtagenv s s_i2 ∧
  v_to_i2 gtagenv v v_i2
  ⇒
  vs_to_i2 gtagenv (LUPDATE v n s) (LUPDATE v_i2 n s_i2)`,
 induct_on `n` >>
 rw [v_to_i2_eqns, LUPDATE_def] >>
 cases_on `s` >>
 fs [v_to_i2_eqns, LUPDATE_def]);

val match_result_to_i2_def = Define 
`(match_result_to_i2 gtagenv (Match env) (Match env_i2) ⇔ 
   env_to_i2 gtagenv env env_i2) ∧
 (match_result_to_i2 gtagenv No_match No_match = T) ∧
 (match_result_to_i2 gtagenv Match_type_error Match_type_error = T) ∧
 (match_result_to_i2 gtagenv _ _ = F)`;

val store_lookup_vs_to_i2 = Q.prove (
`!gtagenv vs vs_i2 v v_i2 n.
  vs_to_i2 gtagenv vs vs_i2 ∧
  store_lookup n vs = SOME v ∧
  store_lookup n vs_i2 = SOME v_i2
  ⇒
  v_to_i2 gtagenv v v_i2`,
 induct_on `vs` >>
 rw [v_to_i2_eqns] >>
 fs [store_lookup_def] >>
 cases_on `n` >>
 fs [] >>
 metis_tac []);

val store_lookup_vs_to_i2_2 = Q.prove (
`!gtagenv vs vs_i2 v v_i2 n.
  vs_to_i2 gtagenv vs vs_i2 ∧
  store_lookup n vs = SOME v
  ⇒
  ?v'. store_lookup n vs_i2 = SOME v'`,
 induct_on `vs` >>
 rw [v_to_i2_eqns] >>
 fs [store_lookup_def] >>
 cases_on `n` >>
 fs [] >>
 metis_tac []);

val pat_bindings_i2_accum = Q.store_thm ("pat_bindings_ai2_ccum",
`(!p acc. pat_bindings_i2 p acc = pat_bindings_i2 p [] ++ acc) ∧
 (!ps acc. pats_bindings_i2 ps acc = pats_bindings_i2 ps [] ++ acc)`,
 Induct >>
 rw []
 >- rw [pat_bindings_i2_def]
 >- rw [pat_bindings_i2_def]
 >- metis_tac [APPEND_ASSOC, pat_bindings_i2_def]
 >- metis_tac [APPEND_ASSOC, pat_bindings_i2_def]
 >- rw [pat_bindings_i2_def]
 >- metis_tac [APPEND_ASSOC, pat_bindings_i2_def]);

val pat_bindings_to_i2 = Q.prove (
`!tagenv p x. pat_bindings_i2 (pat_to_i2 tagenv p) x = pat_bindings p x`,
 ho_match_mp_tac pat_to_i2_ind >>
 rw [pat_bindings_def, pat_bindings_i2_def, pat_to_i2_def] >>
 induct_on `ps` >>
 rw [] >>
 fs [pat_bindings_def, pat_bindings_i2_def, pat_to_i2_def] >>
 metis_tac [APPEND_11, pat_bindings_accum, pat_bindings_i2_accum]);

val pmatch_to_i2_correct = Q.prove (
`(!envC s p v env r env_i2 s_i2 v_i2 tagenv gtagenv.
  r ≠ Match_type_error ∧
  cenv_inv envC tagenv gtagenv ∧
  pmatch_i1 envC s p v env = r ∧
  s_to_i2' gtagenv s s_i2 ∧
  v_to_i2 gtagenv v v_i2 ∧
  env_to_i2 gtagenv env env_i2
  ⇒
  ?r_i2.
    pmatch_i2 s_i2 (pat_to_i2 tagenv p) v_i2 env_i2 = r_i2 ∧
    match_result_to_i2 gtagenv r r_i2) ∧
 (!envC s ps vs env r env_i2 s_i2 vs_i2 tagenv gtagenv.
  r ≠ Match_type_error ∧
  cenv_inv envC tagenv gtagenv ∧
  pmatch_list_i1 envC s ps vs env = r ∧
  s_to_i2' gtagenv s s_i2 ∧
  vs_to_i2 gtagenv vs vs_i2 ∧
  env_to_i2 gtagenv env env_i2
  ⇒
  ?r_i2.
    pmatch_list_i2 s_i2 (MAP (pat_to_i2 tagenv) ps) vs_i2 env_i2 = r_i2 ∧
    match_result_to_i2 gtagenv r r_i2)`,
 ho_match_mp_tac pmatch_i1_ind >>
 rw [pmatch_i1_def, pmatch_i2_def, pat_to_i2_def, match_result_to_i2_def] >>
 fs [match_result_to_i2_def, bind_def, v_to_i2_eqns] >>
 rw [pmatch_i2_def, match_result_to_i2_def]
 >- (cases_on `lookup_con_id n envC` >>
     fs [] >>
     every_case_tac >>
     fs [] 
     >- metis_tac [] >>
     fs [cenv_inv_def] >>
     res_tac >>
     fs [] >>
     rw [] >>
     imp_res_tac same_tid_diff_ctor >>
     rw [] >>
     metis_tac [tid_or_exn_11, SOME_11, PAIR_EQ])
 >- (cases_on `lookup_con_id n envC` >>
     fs [] >>
     every_case_tac >>
     fs [] >> 
     rw []
     >- metis_tac [length_vs_to_i2, cenv_inv_def, SOME_11, same_ctor_and_same_tid, PAIR_EQ] >>
     fs [cenv_inv_def] >>
     res_tac >>
     fs [] >>
     rw [] >>
     imp_res_tac same_tid_diff_ctor >>
     rw [] >>
     metis_tac [tid_or_exn_11, SOME_11, PAIR_EQ])
 >- (cases_on `lookup_con_id n envC` >>
     fs [] >>
     every_case_tac >>
     fs [cenv_inv_def] >>
     imp_res_tac same_ctor_and_same_tid >>
     imp_res_tac same_tid_diff_ctor >>
     rw [] >>
     res_tac >>
     fs [match_result_to_i2_def])
 >- metis_tac []
 >- metis_tac [length_vs_to_i2]
 >- (PairCases_on `tagenv` >>
     fs [lookup_tag_env_def])
 >- (every_case_tac >>
     fs [s_to_i2'_cases] >>
     imp_res_tac store_lookup_vs_to_i2 >>
     fs [store_lookup_def] >>
     metis_tac [length_vs_to_i2])
 >- (every_case_tac >>
     fs [match_result_to_i2_def] >>
     rw [] >>
     pop_assum mp_tac >>
     pop_assum mp_tac >>
     res_tac >>
     rw [] >>
     CCONTR_TAC >>
     fs [match_result_to_i2_def] >>
     metis_tac [match_result_to_i2_def, match_result_distinct]));

val (env_all_to_i2_rules, env_all_to_i2_ind, env_all_to_i2_cases) = Hol_reln `
(!genv envC gtagenv env env_i2 genv_i2.
  cenv_inv envC tagenv gtagenv ∧
  vs_to_i2 gtagenv genv genv_i2 ∧
  env_to_i2 gtagenv env env_i2
  ⇒
  env_all_to_i2 tagenv (MAP SOME genv,envC,env) (MAP SOME genv_i2,env_i2) gtagenv)`;

val env_to_i2_append = Q.prove (
`!gtagenv env1 env2 env1' env2'.
  env_to_i2 gtagenv env1 env1' ∧
  env_to_i2 gtagenv env2 env2' 
  ⇒
  env_to_i2 gtagenv (env1++env2) (env1'++env2')`,
 induct_on `env1` >>
 rw [v_to_i2_eqns] >>
 PairCases_on `h` >>
 fs [v_to_i2_eqns]);

val env_to_i2_lookup = Q.prove (
`!gtagenv env x v env'.
  lookup x env = SOME v ∧
  env_to_i2 gtagenv env env'
  ⇒
  ?v'.
    v_to_i2 gtagenv v v' ∧
    lookup x env' = SOME v'`,
 induct_on `env` >>
 rw [] >>
 PairCases_on `h` >>
 fs [] >>
 cases_on `h0 = x` >>
 fs [] >>
 rw [] >>
 fs [v_to_i2_eqns]);

val genv_to_i2_lookup = Q.prove (
`!gtagenv genv n genv'.
  vs_to_i2 gtagenv genv genv' ∧
  LENGTH genv > n
  ⇒
  v_to_i2 gtagenv (EL n genv) (EL n genv')`,
 induct_on `genv` >>
 srw_tac [ARITH_ss] [v_to_i2_eqns] >>
 cases_on `n` >>
 srw_tac [ARITH_ss] [v_to_i2_eqns]);

val vs_to_i2_append1 = Q.prove (
`!gtagenv vs v vs' v'.
  vs_to_i2 gtagenv (vs++[v]) (vs'++[v'])
  ⇔
  vs_to_i2 gtagenv vs vs' ∧
  v_to_i2 gtagenv v v'`,
 induct_on `vs` >>
 rw [] >>
 cases_on `vs'` >>
 rw [v_to_i2_eqns] 
 >- (cases_on `vs` >>
     rw [v_to_i2_eqns]) >>
 metis_tac []);

val vs_to_i2_append = Q.prove (
`!gtagenv vs1 vs1' vs2 vs2'.
  (LENGTH vs2 = LENGTH vs2' ∨ LENGTH vs1 = LENGTH vs1')
  ⇒
  (vs_to_i2 gtagenv (vs1++vs2) (vs1'++vs2') ⇔
   vs_to_i2 gtagenv vs1 vs1' ∧ vs_to_i2 gtagenv vs2 vs2')`,
 induct_on `vs1` >>
 rw [v_to_i2_eqns] >>
 eq_tac >>
 rw [] >>
 imp_res_tac length_vs_to_i2 >>
 fs [] >>
 cases_on `vs1'` >>
 fs [] >>
 rw [] >>
 full_simp_tac (srw_ss()++ARITH_ss) [] >>
 metis_tac []);

val do_uapp_correct = Q.prove (
`!s uop v s' v' gtagenv s_i2 v_i2.
  do_uapp_i1 s uop v = SOME (s',v') ∧
  s_to_i2' gtagenv s s_i2 ∧
  v_to_i2 gtagenv v v_i2
  ⇒
  ∃s'_i2 v'_i2.
    s_to_i2' gtagenv s' s'_i2 ∧
    v_to_i2 gtagenv v' v'_i2 ∧
    do_uapp_i2 s_i2 (uop_to_i2 uop) v_i2 = SOME (s'_i2,v'_i2)`,
 cases_on `uop` >>
 rw [uop_to_i2_def, do_uapp_i1_def, do_uapp_i2_def, LET_THM, store_alloc_def, s_to_i2'_cases] >>
 rw [vs_to_i2_append1, v_to_i2_eqns]
 >- metis_tac [length_vs_to_i2] >>
 every_case_tac >>
 fs [v_to_i2_eqns]
 >- metis_tac [store_lookup_vs_to_i2_2, NOT_SOME_NONE] 
 >- metis_tac [store_lookup_vs_to_i2]);

val exn_env_i2_correct = Q.prove (
`!gtagenv.
  env_all_to_i2 tagenv env env_i2 gtagenv
  ⇒
  env_all_to_i2 (FST (SND init_tagenv_state)) (exn_env_i1 (all_env_i1_to_genv env))
    (exn_env_i2 (all_env_i2_to_genv env_i2)) gtagenv`,
 rw [env_all_to_i2_cases, exn_env_i1_def, exn_env_i2_def, emp_def, v_to_i2_eqns,
     all_env_i1_to_genv_def, all_env_i2_to_genv_def, init_tagenv_state_def] >>
 qexists_tac `genv` >>
 qexists_tac `genv_i2` >>
 fs [cenv_inv_def, lookup_con_id_def] >>
 rw [] >>
 every_case_tac >>
 fs [] >>
 rw [id_to_n_def] >>
 fs [has_exns_def] >>
 fs [flookup_fupdate_list, lookup_tag_env_def, lookup_tag_flat_def, all_env_i1_to_genv_def, all_env_i2_to_genv_def] >>
 metis_tac []);

val do_eq_i2 = Q.prove (
`(!v1 v2 tagenv r v1_i2 v2_i2 gtagenv.
  env_all_to_i2 tagenv env env_i2 gtagenv ∧
  do_eq_i1 v1 v2 = r ∧
  v_to_i2 gtagenv v1 v1_i2 ∧
  v_to_i2 gtagenv v2 v2_i2
  ⇒ 
  do_eq_i2 v1_i2 v2_i2 = r) ∧
 (!vs1 vs2 tagenv r vs1_i2 vs2_i2 gtagenv.
  env_all_to_i2 tagenv env env_i2 gtagenv ∧
  do_eq_list_i1 vs1 vs2 = r ∧
  vs_to_i2 gtagenv vs1 vs1_i2 ∧
  vs_to_i2 gtagenv vs2 vs2_i2
  ⇒ 
  do_eq_list_i2 vs1_i2 vs2_i2 = r)`,
 ho_match_mp_tac do_eq_i1_ind >>
 rw [do_eq_i2_def, do_eq_i1_def, v_to_i2_eqns] >>
 rw [] >>
 rw [do_eq_i2_def, do_eq_i1_def, v_to_i2_eqns] >>
 imp_res_tac length_vs_to_i2 >>
 fs [env_all_to_i2_cases] >>
 rw []
 >- metis_tac []
 >- metis_tac []
 >- metis_tac []
 >- metis_tac [cenv_inv_def, SOME_11, PAIR_EQ, pair_CASES]
 >- metis_tac [cenv_inv_def, SOME_11, PAIR_EQ, pair_CASES]
 >- metis_tac [cenv_inv_def, SOME_11, PAIR_EQ, pair_CASES]
 >- metis_tac [cenv_inv_def, SOME_11, PAIR_EQ, pair_CASES]
 >- (fs [Once v_to_i2_cases] >>
     rw [do_eq_i2_def])
 >- (fs [Once v_to_i2_cases] >>
     rw [do_eq_i2_def])
 >- (fs [Once v_to_i2_cases] >>
     rw [do_eq_i2_def])
 >- (fs [Once v_to_i2_cases] >>
     rw [do_eq_i2_def])
 >- (fs [Once v_to_i2_cases] >>
     rw [do_eq_i2_def])
 >- (fs [Once v_to_i2_cases] >>
     rw [do_eq_i2_def])
 >- (fs [Once v_to_i2_cases] >>
     rw [do_eq_i2_def])
 >- (fs [Once v_to_i2_cases] >>
     rw [do_eq_i2_def])
 >- (fs [Once v_to_i2_cases] >>
     rw [do_eq_i2_def])
 >- (fs [Once v_to_i2_cases] >>
     rw [do_eq_i2_def])
 >- (fs [Once v_to_i2_cases] >>
     rw [do_eq_i2_def])
 >- (fs [Once v_to_i2_cases] >>
     rw [do_eq_i2_def])
 >- (fs [Once v_to_i2_cases] >>
     rw [do_eq_i2_def])
 >- (fs [Once v_to_i2_cases] >>
     rw [do_eq_i2_def])
 >- (fs [Once v_to_i2_cases] >>
     rw [do_eq_i2_def])
 >- (fs [Once v_to_i2_cases] >>
     rw [do_eq_i2_def])
 >- (fs [Once v_to_i2_cases] >>
     rw [do_eq_i2_def])
 >- (fs [Once v_to_i2_cases] >>
     rw [do_eq_i2_def])
 >- (fs [Once v_to_i2_cases] >>
     rw [do_eq_i2_def])
 >- (fs [Once v_to_i2_cases] >>
     rw [do_eq_i2_def]) >>
 res_tac >>
 every_case_tac >>
 fs [] >>
 metis_tac []);

val do_app_i2_correct = Q.prove (
`!env s op v1 v2 s' e env' tagenv s_i2 v1_i2 v2_i2 env_i2 gtagenv.
  do_app_i1 env s op v1 v2 = SOME (env',s',e) ∧
  env_all_to_i2 tagenv env env_i2 gtagenv ∧
  s_to_i2' gtagenv s s_i2 ∧
  v_to_i2 gtagenv v1 v1_i2 ∧
  v_to_i2 gtagenv v2 v2_i2
  ⇒
  ∃s'_i2 env'_i2 tagenv'.
    env_all_to_i2 tagenv' env' env'_i2 gtagenv ∧
    s_to_i2' gtagenv s' s'_i2 ∧
    do_app_i2 env_i2 s_i2 op v1_i2 v2_i2 = SOME (env'_i2,s'_i2,exp_to_i2 tagenv' e)`,
 cases_on `op` >>
 rw [do_app_i1_def, do_app_i2_def]
 >- (cases_on `v2` >>
     fs [] >>
     cases_on `v1` >>
     fs [v_to_i2_eqns] >>
     rw [] >>
     every_case_tac >>
     fs [] >>
     rw [] >>
     fs [v_to_i2_eqns] >>
     rw [exp_to_i2_def]
     >- (qexists_tac `FST (SND init_tagenv_state)` >>
         rw []
         >- metis_tac [exn_env_i2_correct]
         >- rw [init_tagenv_state_def, flookup_fupdate_list, lookup_tag_env_def, lookup_tag_flat_def])
     >- (qexists_tac `FST (SND init_tagenv_state)` >>
         rw []
         >- metis_tac [exn_env_i2_correct]
         >- rw [init_tagenv_state_def, flookup_fupdate_list, lookup_tag_env_def, lookup_tag_flat_def])
     >- metis_tac []
     >- metis_tac [])
 >- (cases_on `v2` >>
     fs [] >>
     cases_on `v1` >>
     fs [v_to_i2_eqns] >>
     rw [] >>
     every_case_tac >>
     fs [] >>
     rw [] >>
     rw [exp_to_i2_def, exn_env_i2_correct] >>
     metis_tac [])
 >- (every_case_tac >>
     fs [] >>
     rw [exp_to_i2_def]
     >- metis_tac [do_eq_i2, eq_result_11, eq_result_distinct]
     >- metis_tac [do_eq_i2, eq_result_11, eq_result_distinct]
     >- metis_tac [do_eq_i2, eq_result_11, eq_result_distinct]
     >- (qexists_tac `FST (SND init_tagenv_state)` >>
         rw []
         >- metis_tac [exn_env_i2_correct]
         >- rw [init_tagenv_state_def, flookup_fupdate_list, lookup_tag_env_def, lookup_tag_flat_def])
     >- metis_tac [do_eq_i2, eq_result_11, eq_result_distinct]
     >- metis_tac [do_eq_i2, eq_result_11, eq_result_distinct])
 >- (every_case_tac >>
     fs [] >>
     pop_assum (mp_tac o SIMP_RULE (srw_ss()) [Once v_to_i2_cases]) >>
     rw []
     >- (qexists_tac `tagenv'` >>
         rw [] >>
         fs [env_all_to_i2_cases, bind_def] >>
         rw [v_to_i2_eqns, all_env_i1_to_genv_def, all_env_i2_to_genv_def, get_tagenv_def] >>
         metis_tac [])
     >- (CCONTR_TAC >>
         fs [] >>
         rw [] >>
         fs [find_recfun_lookup] >>
         induct_on `l'` >>
         rw [] >>
         PairCases_on `h` >>
         fs [exp_to_i2_def] >>
         every_case_tac >>
         fs [])
     >- (qexists_tac `tagenv'` >>
         rw [] >>
         fs [env_all_to_i2_cases, bind_def] >>
         rw [v_to_i2_eqns, all_env_i1_to_genv_def, all_env_i2_to_genv_def, 
             build_rec_env_i1_merge, build_rec_env_i2_merge, merge_def] >>
         fs [funs_to_i2_map]
         >- (match_mp_tac env_to_i2_append >>
             rw [funs_to_i2_map, MAP_MAP_o, combinTheory.o_DEF, LAMBDA_PROD, env_to_i2_el, EL_MAP] >>
             `?f x e. EL n l' = (f,x,e)` by metis_tac [pair_CASES] >>
             rw [] >>
             rw [Once v_to_i2_cases] >>
             metis_tac [funs_to_i2_map])
         >- (fs [find_recfun_lookup] >>
             induct_on `l'` >>
             rw [] >>
             PairCases_on `h` >>
             fs [exp_to_i2_def] >>
             every_case_tac >>
             fs [])
         >- (fs [find_recfun_lookup] >>
             induct_on `l'` >>
             rw [] >>
             PairCases_on `h` >>
             fs [exp_to_i2_def] >>
             every_case_tac >>
             fs [get_tagenv_def])))
 >- (every_case_tac >>
     fs [] >>
     rw [] >>
     fs [v_to_i2_eqns, store_assign_def] 
     >- metis_tac [length_vs_to_i2, s_to_i2'_cases] >>
     rw [exp_to_i2_def, s_to_i2'_cases] >>
     metis_tac [vs_to_i2_lupdate, s_to_i2'_cases]));

val lookup_tag_env_NONE = Q.prove (
`lookup_tag_env NONE tagenv = tuple_tag`,
PairCases_on `tagenv` >>
rw [lookup_tag_env_def]);

val exp_to_i2_correct = Q.prove (
`(∀b env s e res. 
   evaluate_i1 b env s e res ⇒ 
   (SND res ≠ Rerr Rtype_error) ⇒
   !tagenv s' r env_i2 s_i2 e_i2 gtagenv.
     (res = (s',r)) ∧
     env_all_to_i2 tagenv env env_i2 gtagenv ∧
     s_to_i2 gtagenv s s_i2 ∧
     (e_i2 = exp_to_i2 tagenv e)
     ⇒
     ∃s'_i2 r_i2.
       result_to_i2 v_to_i2 gtagenv r r_i2 ∧
       s_to_i2 gtagenv s' s'_i2 ∧
       evaluate_i2 b env_i2 s_i2 e_i2 (s'_i2, r_i2)) ∧
 (∀b env s es res.
   evaluate_list_i1 b env s es res ⇒ 
   (SND res ≠ Rerr Rtype_error) ⇒
   !tagenv s' r env_i2 s_i2 es_i2 gtagenv.
     (res = (s',r)) ∧
     env_all_to_i2 tagenv env env_i2 gtagenv ∧
     s_to_i2 gtagenv s s_i2 ∧
     (es_i2 = exps_to_i2 tagenv es)
     ⇒
     ?s'_i2 r_i2.
       result_to_i2 vs_to_i2 gtagenv r r_i2 ∧
       s_to_i2 gtagenv s' s'_i2 ∧
       evaluate_list_i2 b env_i2 s_i2 es_i2 (s'_i2, r_i2)) ∧
 (∀b env s v pes err_v res. 
   evaluate_match_i1 b env s v pes err_v res ⇒ 
   (SND res ≠ Rerr Rtype_error) ⇒
   !tagenv s' r env_i2 s_i2 v_i2 pes_i2 err_v_i2 gtagenv.
     (res = (s',r)) ∧
     env_all_to_i2 tagenv env env_i2 gtagenv ∧
     s_to_i2 gtagenv s s_i2 ∧
     v_to_i2 gtagenv v v_i2 ∧
     (pes_i2 = pat_exp_to_i2 tagenv pes) ∧
     v_to_i2 gtagenv err_v err_v_i2
     ⇒
     ?s'_i2 r_i2.
       result_to_i2 v_to_i2 gtagenv r r_i2 ∧
       s_to_i2 gtagenv s' s'_i2 ∧
       evaluate_match_i2 b env_i2 s_i2 v_i2 pes_i2 err_v_i2 (s'_i2, r_i2))`,
 ho_match_mp_tac evaluate_i1_ind >>
 rw [] >>
 rw [Once evaluate_i2_cases,exp_to_i2_def] >>
 TRY (Cases_on `err`) >>
 fs [result_to_i2_eqns, v_to_i2_eqns]
 >- metis_tac []
 >- metis_tac []
 >- metis_tac []
 >- metis_tac []
 >- metis_tac []
 >- (* Constructor application *)
    (res_tac >>
     rw [] >>
     fs [env_all_to_i2_cases, build_conv_i1_def] >>
     rw [] >>
     MAP_EVERY qexists_tac [`s'_i2`, `Rval (Conv_i2 (lookup_tag_env cn tagenv) v')`] >>
     rw [] >>
     Cases_on `cn` >>
     fs [] >>
     rw [v_to_i2_eqns, lookup_tag_env_NONE] >>
     fs [all_env_i1_to_cenv_def] >>
     every_case_tac >>
     fs [get_tagenv_def] >>
     rw [v_to_i2_eqns] >>
     fs [cenv_inv_def, do_con_check_def] >>
     rw [] >>
     metis_tac [length_evaluate_list_i2, length_vs_to_i2])
 >- metis_tac []
 >- (* Local variable lookup *)
    (fs [env_all_to_i2_cases, all_env_i2_to_env_def] >>
     rw [] >>
     fs [all_env_i1_to_env_def] >>
     metis_tac [env_to_i2_lookup])
 >- (* Global variable lookup *)
    (fs [env_all_to_i2_cases, all_env_i2_to_genv_def] >>
     rw [] >>
     fs [all_env_i1_to_genv_def] >>
     `n < LENGTH genv` by decide_tac >>
     `LENGTH genv_i2 = LENGTH genv` by metis_tac [length_vs_to_i2] >>
     fs [EL_MAP] >>
     metis_tac [genv_to_i2_lookup])
 >- (rw [Once v_to_i2_cases] >>
     fs [env_all_to_i2_cases] >>
     rw [all_env_i1_to_env_def, all_env_i2_to_env_def, all_env_i1_to_cenv_def] >>
     metis_tac [])
 >- (* Uapp *)
    (res_tac >>
     rw [] >>
     fs [s_to_i2_cases] >>
     rw [] >>
     `?s3_i2 v'_i2. do_uapp_i2 s''' (uop_to_i2 uop) v'' = SOME (s3_i2, v'_i2) ∧
       s_to_i2' gtagenv s3 s3_i2 ∧ v_to_i2 gtagenv v' v'_i2` by metis_tac [do_uapp_correct] >>
     metis_tac [])
 >- metis_tac []
 >- (* App *)
    (LAST_X_ASSUM (qspecl_then [`tagenv`, `env_i2`, `s_i2`, `gtagenv`] mp_tac) >>
     rw [] >>
     LAST_X_ASSUM (qspecl_then [`tagenv`, `env_i2`, `s'_i2`, `gtagenv`] mp_tac) >>
     rw [] >>
     fs [s_to_i2_cases] >>
     rw [] >>
     (qspecl_then [`env`, `s3`, `op`, `v1`, `v2`, `s4`, `e''`, `env'`,
                   `tagenv`, `s'''''''`, `v'`, `v''`, `env_i2`, `gtagenv`] mp_tac) do_app_i2_correct >>
     rw [] >>
     metis_tac [])
 >- (* App *)
    (LAST_X_ASSUM (qspecl_then [`tagenv`, `env_i2`, `s_i2`, `gtagenv`] mp_tac) >>
     rw [] >>
     LAST_X_ASSUM (qspecl_then [`tagenv`, `env_i2`, `s'_i2`, `gtagenv`] mp_tac) >>
     rw [] >>
     fs [s_to_i2_cases] >>
     rw [] >>
     (qspecl_then [`env`, `s3`, `op`, `v1`, `v2`, `s4`, `e''`, `env'`,
                   `tagenv`, `s'''''''`, `v'`, `v''`, `env_i2`, `gtagenv`] mp_tac) do_app_i2_correct >>
     rw [] >>
     metis_tac [])
 >- (* App *)
    (LAST_X_ASSUM (qspecl_then [`tagenv`, `env_i2`, `s_i2`, `gtagenv`] mp_tac) >>
     rw [] >>
     LAST_X_ASSUM (qspecl_then [`tagenv`, `env_i2`, `s'_i2`, `gtagenv`] mp_tac) >>
     rw [] >>
     fs [s_to_i2_cases] >>
     rw [] >>
     metis_tac [do_app_i2_correct])
 >- metis_tac []
 >- metis_tac []
 >- metis_tac []
 >- metis_tac []
 >- (* If *)
    (fs [do_if_i2_def, do_if_i1_def] >>
     every_case_tac >>
     rw [] >>
     res_tac >>
     rw [] >>
     res_tac >>
     rw [] >>
     MAP_EVERY qexists_tac [`s'_i2''`, `r_i2`] >>
     rw [] >>
     disj1_tac
     >- (qexists_tac `Litv_i2 (Bool F)` >>
         fs [v_to_i2_eqns, exp_to_i2_def] >>
         metis_tac [])
     >- (qexists_tac `Litv_i2 (Bool T)` >>
         fs [v_to_i2_eqns, exp_to_i2_def] >>
         metis_tac []))
 >- metis_tac []
 >- metis_tac []
 >- (* Match *)
    (pop_assum mp_tac >>
     res_tac >>
     rw [] >>
     FIRST_X_ASSUM (qspecl_then [`tagenv`, `env_i2`, `s'_i2'`, `v''`, `Conv_i2 bind_tag []`, `gtagenv` ] mp_tac) >>
     rw [] >>
     fs [env_all_to_i2_cases] >>
     rw [] >>
     fs [cenv_inv_def, has_exns_def] >>
     pop_assum (fn _ => all_tac) >>
     pop_assum mp_tac >>
     rw [] >>
     MAP_EVERY qexists_tac [`s'_i2''`, `r_i2`] >>
     rw [] >>
     metis_tac [])
 >- metis_tac []
 >- metis_tac []
 >- (* Let *)
    (`?genv' env'. env_i2 = (genv',env')` by metis_tac [pair_CASES] >>
     rw [] >>
     res_tac >>
     fs [] >>
     rw [] >>
     `env_all_to_i2 tagenv (genv,cenv,bind n v env) (genv', (n,v')::env') gtagenv`
                by (fs [env_all_to_i2_cases] >>
                    fs [bind_def, v_to_i2_eqns] >>
                    rw []) >>
     metis_tac [bind_def])
 >- metis_tac []
 >- metis_tac []
 >- (* Letrec *)
    (pop_assum mp_tac >>
     rw [] >>
     `?genv' env'. env_i2 = (genv',env')` by metis_tac [pair_CASES] >>
     rw [] >>
     `env_all_to_i2 tagenv (genv,cenv,build_rec_env_i1 funs (cenv,env) env) 
                           (genv',build_rec_env_i2 (funs_to_i2 tagenv funs) env' env') 
                           gtagenv`
         by (fs [env_all_to_i2_cases] >>
             rw [build_rec_env_i1_merge, build_rec_env_i2_merge, merge_def] >>
             rw [] >>
             match_mp_tac env_to_i2_append >>
             rw [] >>
             rw [funs_to_i2_map, MAP_MAP_o, combinTheory.o_DEF, LAMBDA_PROD, env_to_i2_el, EL_MAP] >>
             `?f x e. EL n funs = (f,x,e)` by metis_tac [pair_CASES] >>
             rw [] >>
             rw [Once v_to_i2_cases] >>
             metis_tac [funs_to_i2_map]) >>
      res_tac >>
      MAP_EVERY qexists_tac [`s'_i2'`, `r_i2'`] >>
      rw [] >>
      disj1_tac >>
      rw [funs_to_i2_map, MAP_MAP_o, combinTheory.o_DEF, LAMBDA_PROD])
 >- metis_tac []
 >- metis_tac []
 >- metis_tac []
 >- metis_tac []
 >- metis_tac []
 >- (pop_assum mp_tac >>
     rw [] >>
     fs [s_to_i2_cases, env_all_to_i2_cases] >>
     rw [] >>
     `match_result_to_i2 gtagenv (Match env') 
            (pmatch_i2 s'' (pat_to_i2 tagenv p) v_i2 env_i2')`
                   by metis_tac [pmatch_to_i2_correct, match_result_distinct] >>
     cases_on `pmatch_i2 s'' (pat_to_i2 tagenv p) v_i2 env_i2'` >>
     fs [match_result_to_i2_def] >>
     rw [] >>
     fs [METIS_PROVE [] ``(((?x. P x) ∧ R ⇒ Q) ⇔ !x. P x ∧ R ⇒ Q) ∧ ((R ∧ (?x. P x) ⇒ Q) ⇔ !x. R ∧ P x ⇒ Q) ``] >>
     FIRST_X_ASSUM (qspecl_then [`tagenv`, `gtagenv`, `a`, `genv_i2`, `s''`] mp_tac) >>
     rw [] >>
     fs [] >>
     MAP_EVERY qexists_tac [`(c, s'''')`, `r_i2`] >>
     rw [] >>
     metis_tac [pat_bindings_to_i2])
 >- (pop_assum mp_tac >>
     rw [] >>
     fs [s_to_i2_cases, env_all_to_i2_cases] >>
     rw [] >>
     `match_result_to_i2 gtagenv No_match 
            (pmatch_i2 s'' (pat_to_i2 tagenv p) v_i2 env_i2')`
                   by metis_tac [pmatch_to_i2_correct, match_result_distinct] >>
     cases_on `pmatch_i2 s'' (pat_to_i2 tagenv p) v_i2 env_i2'` >>
     fs [match_result_to_i2_def] >>
     rw [] >>
     fs [METIS_PROVE [] ``(((?x. P x) ∧ R ⇒ Q) ⇔ !x. P x ∧ R ⇒ Q) ∧ ((R ∧ (?x. P x) ⇒ Q) ⇔ !x. R ∧ P x ⇒ Q) ``] >>
     metis_tac [pat_bindings_to_i2]));

val merge_envC_empty = Q.prove (
`!envC. merge_envC (emp,emp) envC = envC ∧ merge_envC ([],[]) envC = envC`,
rw [emp_def] >>
PairCases_on `envC` >>
rw [merge_envC_def, merge_def]);

val lookup_tag_env_insert = Q.prove (
`(!cn tag tagenv. lookup_tag_env (SOME (Short cn)) (insert_tag_env cn tag tagenv) = tag) ∧
 (!cn cn' tag tagenv. 
   cn' ≠ Short cn 
   ⇒ 
   lookup_tag_env (SOME cn') (insert_tag_env cn tag tagenv) = lookup_tag_env (SOME cn') tagenv)`,
 rw [] >>
 PairCases_on `tagenv` >>
 rw [lookup_tag_env_def, insert_tag_env_def, lookup_tag_flat_def, FLOOKUP_UPDATE] >>
 every_case_tac >>
 fs []);

val alloc_tags_flat = Q.prove (
`!mn tagenv_st defs.
  alloc_tags mn tagenv_st defs =
  FOLDL (λst' (cn,l,t). alloc_tag t cn st') tagenv_st 
        (FLAT (MAP (\(tvs,tn,ctors). (MAP (\(cn,ts). (cn, LENGTH ts, TypeId (mk_id mn tn))) ctors)) defs))`,
 induct_on `defs` >>
 rw [alloc_tags_def, LET_THM] >>
 PairCases_on `h` >>
 rw [LET_THM, alloc_tags_def, FOLDL_APPEND, FOLDL_MAP, LAMBDA_PROD]);

val check_dup_ctors_flat = Q.prove (
`!defs.
  check_dup_ctors defs =
  ALL_DISTINCT (MAP FST (FLAT (MAP (λ(tvs,tn,condefs). MAP (λ(n,ts). (n, LENGTH ts, TypeId (mk_id mn tn))) condefs) defs)))`,
 rw [check_dup_ctors_thm, MAP_FLAT, MAP_MAP_o, combinTheory.o_DEF, LAMBDA_PROD]);

val gtagenv_weak_refl = Q.prove (
`!gtagenv envC tagenv. 
  cenv_inv envC tagenv gtagenv
  ⇒
  gtagenv_weak gtagenv gtagenv`,
 rw [gtagenv_weak_def] >>
 metis_tac [SUBMAP_REFL, cenv_inv_def]);

val gtagenv_weak_trans = Q.prove (
`!gtagenv1 gtagenv2 gtagenv3.
  gtagenv_weak gtagenv1 gtagenv2 ∧
  gtagenv_weak gtagenv2 gtagenv3
  ⇒
  gtagenv_weak gtagenv1 gtagenv3`,
 rw [gtagenv_weak_def] >>
 metis_tac [SUBMAP_TRANS]);

val get_next_def = Define `
get_next (a,b,c,d) = a`;

val alloc_tag_cenv_inv = Q.prove (
`!envC gtagenv tagenv_st l t cn.
  cenv_inv envC (get_tagenv tagenv_st) gtagenv ∧
  (cn,t) ∉ FDOM gtagenv ∧
  (!cn t tag l. FLOOKUP gtagenv (cn,t) = SOME (tag,l) ⇒ get_next tagenv_st > tag) ∧
  get_next tagenv_st > tuple_tag
  ⇒
  cenv_inv (merge_envC ([],bind cn (l,t) emp) envC) (get_tagenv (alloc_tag t cn tagenv_st)) (gtagenv |+ ((cn,t),(get_next tagenv_st,l))) ∧
  gtagenv_weak gtagenv (gtagenv |+ ((cn,t),(get_next tagenv_st,l))) ∧
  get_next (alloc_tag t cn tagenv_st) > tuple_tag ∧
  (!cn' t' tag l. FLOOKUP (gtagenv |+ ((cn,t),(get_next tagenv_st,l))) (cn',t') = SOME (tag,l) ⇒ get_next (alloc_tag t cn tagenv_st) > tag)`,
 rw [] >>
 `?next tagenv inv_tagenv acc. tagenv_st = (next,tagenv,inv_tagenv,acc)` 
         by metis_tac [pair_CASES] >>
 fs [get_next_def,bind_def, emp_def, cenv_inv_def, alloc_tag_def, get_tagenv_def] >>
 rw []
 >- (`(cn' = Short cn ∧ l = num_args ∧ t' = t) ∨ 
      lookup_con_id cn' envC = SOME (num_args,t') ∧ cn' ≠ Short cn`
             by (PairCases_on `envC` >>
                 fs [merge_envC_def, merge_def, lookup_con_id_def] >>
                     every_case_tac >>
                     fs []) >>
     rw [FLOOKUP_UPDATE, lookup_tag_env_insert] >>
     fs [id_to_n_def] >>
     res_tac >>
     fs [FLOOKUP_DEF])
 >- (rw [FLOOKUP_UPDATE] >>
     fs [get_next_def] >>
     decide_tac)
 >- (fs [has_exns_def, FLOOKUP_UPDATE] >>
     rw [] >>
     fs [FLOOKUP_DEF])
 >- (fs [FLOOKUP_UPDATE] >>
     every_case_tac >>
     fs [get_next_def] >>
     rw [] >>
     res_tac >>
     fs [])
 >- (fs [FLOOKUP_UPDATE] >>
     every_case_tac >>
     fs [get_next_def] >>
     rw [] >>
     res_tac >>
     fs [])
 >-  (rw [gtagenv_weak_def, FLOOKUP_UPDATE] >>
      every_case_tac >>
      fs [get_next_def] >>
      rw [] >>
      res_tac >>
      full_simp_tac (srw_ss()++ARITH_ss) [])
 >- (fs [get_next_def] >>
     decide_tac)
 >- (rw [get_next_def] >>
     fs [FLOOKUP_UPDATE] >>
     every_case_tac >>
     full_simp_tac (srw_ss()++ARITH_ss) [] >>
     res_tac >>
     full_simp_tac (srw_ss()++ARITH_ss) [get_next_def]));

val alloc_tags_cenv_inv1 = Q.prove (
`!flat_envC envC gtagenv tagenv_st flat_defs tids.
  cenv_inv (merge_envC ([],flat_envC) envC) (get_tagenv tagenv_st) gtagenv ∧
  ALL_DISTINCT (MAP FST flat_defs) ∧
  EVERY (\(cn,l,t). (cn,t) ∉ FDOM gtagenv) flat_defs ∧
  (!cn t tag l. FLOOKUP gtagenv (cn,t) = SOME (tag,l) ⇒ get_next tagenv_st > tag) ∧
  IMAGE SND (FDOM gtagenv) ⊆ tids ∧
  get_next tagenv_st > tuple_tag
  ⇒
  ?gtagenv'. 
    cenv_inv (merge_envC ([],REVERSE flat_defs++flat_envC) envC) (get_tagenv (FOLDL (λst' (cn,l,t). alloc_tag t cn st') tagenv_st flat_defs)) gtagenv' ∧
    IMAGE SND (FDOM gtagenv') ⊆ set (MAP (λ(cn,l,t). t) flat_defs) ∪ tids ∧
    get_next (FOLDL (λst' (cn,l,t). alloc_tag t cn st') tagenv_st flat_defs) > tuple_tag ∧
    (!cn t tag l. FLOOKUP gtagenv' (cn,t) = SOME (tag,l) ⇒ get_next (FOLDL (λst' (cn,l,t). alloc_tag t cn st') tagenv_st flat_defs) > tag) ∧
    gtagenv_weak gtagenv gtagenv'`,
 induct_on `flat_defs` >>
 rw [merge_envC_empty]
 >- metis_tac [gtagenv_weak_refl] >>
 `?cn l t. h = (cn,l,t)` by metis_tac [pair_CASES] >>
 `?next tagenv inv_tagenv acc. tagenv_st = (next,tagenv,inv_tagenv,acc)` by metis_tac [pair_CASES] >>
 rw [] >>
 fs [] >>
 `cenv_inv (merge_envC ([],bind cn (l,t) emp) (merge_envC ([],flat_envC) envC))
           (get_tagenv (alloc_tag t cn (next,tagenv,inv_tagenv,acc)))
           (gtagenv |+ ((cn,t),get_next (next,tagenv,inv_tagenv,acc),l)) ∧
  gtagenv_weak gtagenv (gtagenv |+ ((cn,t),get_next (next,tagenv,inv_tagenv,acc),l)) ∧
  get_next (alloc_tag t cn (next,tagenv,inv_tagenv,acc)) > tuple_tag`
             by metis_tac [alloc_tag_cenv_inv] >>
 `EVERY (λ(cn',l',t'). (cn',t') ∉ FDOM (gtagenv |+ ((cn,t),get_next (next,tagenv,inv_tagenv,acc),l))) flat_defs` 
            by (fs [EVERY_MEM, MEM_MAP] >>
                rw [] >>
                PairCases_on `e` >>
                fs [FORALL_PROD] >>
                metis_tac [FST]) >>
 `∀cn' t' tag l'.
   FLOOKUP (gtagenv |+ ((cn,t),get_next (next,tagenv,inv_tagenv,acc),l)) (cn',t') = SOME (tag,l') ⇒
   get_next (alloc_tag t cn (next,tagenv,inv_tagenv,acc)) > tag`
                 by (srw_tac [ARITH_ss] [FLOOKUP_UPDATE, alloc_tag_def, get_next_def] >>
                     res_tac >>
                     fs [get_next_def] >>
                     decide_tac) >>
 fs [merge_envC_empty_assoc, emp_def, bind_def] >>
 `IMAGE SND (FDOM (gtagenv |+ ((cn,t),get_next (next,tagenv,inv_tagenv,acc),l))) ⊆ t INSERT tids` 
          by (fs [SUBSET_DEF] >>
              rw [] >>
              metis_tac [SND]) >>
 FIRST_X_ASSUM (qspecl_then [`(cn,l,t)::flat_envC`, `envC`, `gtagenv |+ ((cn,t),get_next (next,tagenv,inv_tagenv,acc),l)`,
                             `alloc_tag t cn (next,tagenv,inv_tagenv,acc)`, `t INSERT tids`] mp_tac) >>
 rw [] >>
 res_tac >>
 qexists_tac `gtagenv'` >>
 rw []
 >- metis_tac [APPEND, APPEND_ASSOC]
 >- (fs [SUBSET_DEF] >>
     metis_tac [])
 >- res_tac
 >- metis_tac [gtagenv_weak_trans]);

val cenv_inv_rev = Q.prove (
`ALL_DISTINCT (MAP FST flat_defs) ⇒
 cenv_inv (merge_envC ([],REVERSE flat_defs) envC) tagenv_st gtagenv
 =
 cenv_inv (merge_envC ([],flat_defs) envC) tagenv_st gtagenv`,
 rw [cenv_inv_def] >>
 eq_tac >>
 rw [] >>
 metis_tac [lookup_con_id_rev]);

val alloc_tags_invariant_def = Define `
alloc_tags_invariant tids tagenv_st gtagenv ⇔
  IMAGE SND (FDOM gtagenv) ⊆ tids ∧
  get_next tagenv_st > tuple_tag ∧
  (!cn t tag l. FLOOKUP gtagenv (cn,t) = SOME (tag,l) ⇒ get_next tagenv_st > tag)`;

val alloc_tags_cenv_inv2 = Q.prove (
`!envC gtagenv tagenv_st mn type_defs tids.
  alloc_tags_invariant tids tagenv_st gtagenv ∧
  cenv_inv envC (get_tagenv tagenv_st) gtagenv ∧
  check_dup_ctors type_defs ∧
  EVERY (λ(cn,l,t). (cn,t) ∉ FDOM gtagenv) (FLAT (MAP (λ(tvs,tn,condefs). MAP (λ(n,ts). (n,LENGTH ts,TypeId (mk_id mn tn))) condefs) type_defs))
  ⇒
  ?gtagenv'. 
    cenv_inv (merge_envC ([], build_tdefs mn type_defs) envC) (get_tagenv (alloc_tags mn tagenv_st type_defs)) gtagenv' ∧
    alloc_tags_invariant (set (MAP (\(cn,l,t). t) (FLAT (MAP (λ(tvs,tn,condefs). MAP (λ(n,ts). (n,LENGTH ts,TypeId (mk_id mn tn))) condefs) type_defs))) ∪ tids) (alloc_tags mn tagenv_st type_defs) gtagenv' ∧
    gtagenv_weak gtagenv gtagenv'`,
 REWRITE_TAC [alloc_tags_invariant_def, alloc_tags_flat, build_tdefs_def, check_dup_ctors_flat, type_defs_to_new_tdecs_def] >>
 rpt GEN_TAC >>
 Q.SPEC_TAC (`FLAT (MAP (λ(tvs,tn,condefs).  MAP (λ(n,ts). (n,LENGTH ts,TypeId (mk_id mn tn))) condefs) type_defs)`,
             `flat_defs`) >>
 rw [GSYM CONJ_ASSOC] >>
 match_mp_tac (SIMP_RULE (srw_ss()) [merge_envC_empty, cenv_inv_rev] (Q.SPEC `[]` alloc_tags_cenv_inv1)) >>
 rw [] >>
 fs [] >>
 metis_tac []);

val alloc_tags_cenv_inv3_lem = Q.prove (
`!mn type_defs x.
  set (MAP (λ(cn,l,t). t) (FLAT (MAP (λ(tvs,tn,condefs).  MAP (λ(n,ts). (n,LENGTH ts,TypeId (mk_id mn tn))) condefs) type_defs))) ∪ x ⊆
  set (MAP (λ(tvs,tn,ctors). TypeId (mk_id mn tn)) type_defs) ∪ x`,
 induct_on `type_defs` >>
 fs [SUBSET_DEF] >>
 rw []
 >-(rw [MEM_MAP,MEM_FLAT] >>
    PairCases_on `h` >>
    rw [MEM_MAP,EXISTS_PROD] >>
    fs [MEM_MAP] >>
    rw [] >>
    PairCases_on`y'` >>
    rw [])
    >- metis_tac []);

val alloc_tags_cenv_inv3 = Q.prove (
`!envC gtagenv tagenv_st mn type_defs tids.
  alloc_tags_invariant tids tagenv_st gtagenv ∧
  cenv_inv envC (get_tagenv tagenv_st) gtagenv ∧
  check_dup_ctors type_defs ∧
  EVERY (λ(cn,l,t). (cn,t) ∉ FDOM gtagenv) (FLAT (MAP (λ(tvs,tn,condefs). MAP (λ(n,ts). (n,LENGTH ts,TypeId (mk_id mn tn))) condefs) type_defs))
  ⇒
  ?gtagenv'. 
    cenv_inv (merge_envC ([], build_tdefs mn type_defs) envC) (get_tagenv (alloc_tags mn tagenv_st type_defs)) gtagenv' ∧
    alloc_tags_invariant (type_defs_to_new_tdecs mn type_defs ∪ tids) (alloc_tags mn tagenv_st type_defs) gtagenv' ∧
    gtagenv_weak gtagenv gtagenv'`,
 rw [] >> 
 imp_res_tac alloc_tags_cenv_inv2 >>
 rw [type_defs_to_new_tdecs_def] >>
 fs [alloc_tags_invariant_def] >>
 qexists_tac `gtagenv'` >>
 rw [] >>
 metis_tac [alloc_tags_cenv_inv3_lem, SUBSET_TRANS]);

val recfun_helper = Q.prove (
`cenv_inv envC tagenv gtagenv
 ⇒
 vs_to_i2 gtagenv
          (MAP (\(f,x,e). Closure_i1 (envC,[]) x e) l)
          (MAP (\(f,x,e). Closure_i2 [] x (exp_to_i2 tagenv e)) l)`,
induct_on `l` >>
rw [v_to_i2_eqns] >>
PairCases_on `h` >>
rw [] >>
rw [Once v_to_i2_cases] >>
rw [v_to_i2_eqns] >>
metis_tac []);

val decs_to_i2_correct = Q.prove (
`!genv_opt envC s ds r.
  evaluate_decs_i1 genv_opt envC s ds r
  ⇒
  !genv s1 tids s1_i2 genv_i2 tagenv_st ds_i2 tagenv_st' genv' envC' s' tids' res gtagenv.
    genv_opt = MAP SOME genv ∧
    s = (s1,tids) ∧
    r = ((s',tids'), envC', genv', res) ∧
    res ≠ SOME Rtype_error ∧
    (tagenv_st', ds_i2) = decs_to_i2 tagenv_st ds ∧
    cenv_inv envC (get_tagenv tagenv_st) gtagenv ∧
    s_to_i2' gtagenv s1 s1_i2 ∧
    vs_to_i2 gtagenv genv genv_i2 ∧
    alloc_tags_invariant tids tagenv_st gtagenv
    ⇒
    ?genv'_i2 s'_i2 res_i2 gtagenv'.
      gtagenv_weak gtagenv gtagenv' ∧
      evaluate_decs_i2 (MAP SOME genv_i2) s1_i2 ds_i2 (s'_i2,genv'_i2,res_i2) ∧
      vs_to_i2 gtagenv' genv' genv'_i2 ∧
      s_to_i2' gtagenv' s' s'_i2 ∧
      alloc_tags_invariant tids' tagenv_st' gtagenv' ∧
      (res = NONE ∧ res_i2 = NONE ∧ cenv_inv (merge_envC (emp,envC') envC) (get_tagenv tagenv_st') gtagenv' ∨
       ?err err_i2. res = SOME err ∧ res_i2 = SOME err_i2 ∧ result_to_i2 (\a b c. T) gtagenv' (Rerr err) (Rerr err_i2))`,
 ho_match_mp_tac evaluate_decs_i1_ind >>
 rw [decs_to_i2_def] >>
 every_case_tac >>
 fs [LET_THM, evaluate_dec_i1_cases] >>
 rw []  
 >- (fs [emp_def, Once evaluate_decs_i2_cases, v_to_i2_eqns, s_to_i2'_cases, merge_envC_empty] >>
     metis_tac [gtagenv_weak_refl])
 >- (`?tagenv_st' ds_i2. decs_to_i2 tagenv_st ds = (tagenv_st', ds_i2)` by metis_tac [pair_CASES] >>
     fs [] >>
     rw [Once evaluate_decs_i2_cases] >>
     fs [s_to_i2'_cases] >>
     `env_all_to_i2 (get_tagenv tagenv_st) (MAP SOME genv,envC,emp) (MAP SOME genv_i2,[]) gtagenv`
                 by (fs [env_all_to_i2_cases] >>
                     rw [emp_def, v_to_i2_eqns] >>
                     every_case_tac >>
                     metis_tac []) >>
     `?s'_i2 r_i2 count' s''.
        result_to_i2 v_to_i2 gtagenv (Rerr e) r_i2 ∧
        s'_i2 = (count',s'') ∧
        vs_to_i2 gtagenv s' s'' ∧
        evaluate_i2 F (MAP SOME genv_i2,[]) (0,s1_i2) (exp_to_i2 (get_tagenv tagenv_st) e') (s'_i2,r_i2)`
           by (imp_res_tac exp_to_i2_correct >>
               fs [] >>
               pop_assum mp_tac >>
               rw [s_to_i2_cases, s_to_i2'_cases] >>
               res_tac >>
               fs [] >>
               res_tac >>
               fs [] >>
               metis_tac []) >>
     rw [evaluate_dec_i2_cases] >>
     fs [emp_def, result_to_i2_cases, v_to_i2_eqns] >>
     rw [merge_envC_empty] >>
     `alloc_tags_invariant tids tagenv_st' gtagenv` by cheat >>
     metis_tac [gtagenv_weak_refl])
 >- (`?tagenv_st' ds_i2. decs_to_i2 tagenv_st ds = (tagenv_st', ds_i2)` by metis_tac [pair_CASES] >>
     fs [] >>
     rw [Once evaluate_decs_i2_cases] >>
     fs [s_to_i2'_cases] >>
     `env_all_to_i2 (get_tagenv tagenv_st) (MAP SOME genv,envC,emp) (MAP SOME genv_i2,[]) gtagenv`
                 by (fs [env_all_to_i2_cases] >>
                     rw [emp_def, v_to_i2_eqns] >>
                     every_case_tac >>
                     metis_tac []) >>
     `?count' s' r_i2. result_to_i2 v_to_i2 gtagenv (Rval (Conv_i1 NONE new_env)) r_i2 ∧
                vs_to_i2 gtagenv s2 s' ∧
                evaluate_i2 F (MAP SOME genv_i2,[]) (0,s1_i2) (exp_to_i2 (get_tagenv tagenv_st) e) ((count',s'),r_i2)` 
                     by (imp_res_tac exp_to_i2_correct >>
                         fs [] >>
                         pop_assum mp_tac >>
                         rw [s_to_i2_cases, s_to_i2'_cases] >>
                         res_tac >>
                         fs [] >>
                         res_tac >>
                         fs [] >>
                         metis_tac []) >>
     rw [evaluate_dec_i2_cases] >>
     fs [result_to_i2_cases, v_to_i2_eqns, merge_envC_empty] >>
     rw [] >>
     `vs_to_i2 gtagenv (genv ++ new_env) (genv_i2++vs')` 
                  by metis_tac [vs_to_i2_append, length_vs_to_i2] >>
     FIRST_X_ASSUM (qspecl_then [`s'`, `genv_i2 ++ vs'`, `tagenv_st`, `ds_i2'`, `tagenv_st'`, `gtagenv`] mp_tac) >>
     rw [] >>
     fs [emp_def, merge_def] >>
     `vs_to_i2 gtagenv'' (new_env ++ new_env') (vs' ++ genv'_i2)`
                  by metis_tac [vs_to_i2_append, length_vs_to_i2, v_to_i2_weakening] >>
     metis_tac [length_vs_to_i2])
 >- (`?tagenv_st' ds_i2. decs_to_i2 tagenv_st ds = (tagenv_st', ds_i2)` by metis_tac [pair_CASES] >>
     fs [] >>
     rw [] >>
     fs [emp_def, merge_def, merge_envC_empty] >>
     `vs_to_i2 gtagenv
               (genv ++ MAP (\(f,x,e). Closure_i1 (envC,[]) x e) l)
               (genv_i2 ++ MAP (\(f,x,e). Closure_i2 [] x (exp_to_i2 (get_tagenv tagenv_st) e)) l)`
              by metis_tac [recfun_helper, length_vs_to_i2, vs_to_i2_append] >>
     FIRST_X_ASSUM (qspecl_then [`s1_i2`, `genv_i2 ++ MAP (λ(f,x,e).  Closure_i2 [] x (exp_to_i2 (get_tagenv tagenv_st) e)) l`, `tagenv_st`, `ds_i2'`, `tagenv_st'`, `gtagenv`] mp_tac) >>
     rw [] >>
     rw [Once evaluate_decs_i2_cases, evaluate_dec_i2_cases] >>
     `vs_to_i2 gtagenv'
               (MAP (\(f,x,e). Closure_i1 (envC,[]) x e) l ++ new_env') 
               (MAP (\(f,x,e). Closure_i2 [] x (exp_to_i2 (get_tagenv tagenv_st) e)) l ++ genv'_i2)`
               by metis_tac [recfun_helper, v_to_i2_weakening, vs_to_i2_append, length_vs_to_i2] >>
     fs [funs_to_i2_map, MAP_MAP_o, combinTheory.o_DEF, LAMBDA_PROD]
     >- metis_tac [] >>
     fs [result_to_i2_cases] >>
     metis_tac [])
 >- (`?gtagenv'. cenv_inv (merge_envC ([],build_tdefs o' l) envC) (get_tagenv (alloc_tags o' tagenv_st l)) gtagenv' ∧
                 alloc_tags_invariant (type_defs_to_new_tdecs o' l ∪ tids) (alloc_tags o' tagenv_st l) gtagenv' ∧
                 gtagenv_weak gtagenv gtagenv'`
             by (match_mp_tac alloc_tags_cenv_inv3 >>
                 rw [EVERY_MAP, MEM_FLAT, EVERY_MEM, MEM_MAP, EXISTS_PROD] >>
                 fs [MEM_MAP] >>
                 rw [] >>
                 PairCases_on `y` >>
                 rw [] >>
                 fs [alloc_tags_invariant_def, SUBSET_DEF, DISJOINT_DEF, type_defs_to_new_tdecs_def, EXTENSION,
                     MEM_MAP, FORALL_PROD] >>
                 metis_tac [SND]) >>
     fs [merge_envC_empty_assoc, merge_def, emp_def] >>
     `s_to_i2' gtagenv' s1 s1_i2 ∧ vs_to_i2 gtagenv' genv genv_i2` 
                 by metis_tac [v_to_i2_weakening, s_to_i2'_cases] >>
     FIRST_X_ASSUM (qspecl_then [`s1_i2`, `genv_i2`, `alloc_tags o' tagenv_st l`,
                                 `ds_i2`, `tagenv_st'`, `gtagenv'` ] mp_tac) >>
     rw [] >>
     metis_tac [gtagenv_weak_trans])
 >- (`?gtagenv'. cenv_inv (merge_envC ([],bind s (LENGTH l,TypeExn (mk_id o' s)) emp) envC) 
                          (get_tagenv (alloc_tag (TypeExn (mk_id o' s)) s tagenv_st)) gtagenv' ∧
                 alloc_tags_invariant ({TypeExn (mk_id o' s)} ∪ tids) (alloc_tag (TypeExn (mk_id o' s)) s tagenv_st) gtagenv' ∧
                 gtagenv_weak gtagenv gtagenv'`
             by (fs [alloc_tags_invariant_def] >>
                 imp_res_tac alloc_tags_cenv_inv1 >>
                 pop_assum (qspecl_then [`bind s (LENGTH l,TypeExn (mk_id o' s)) emp`] mp_tac) >>
                 `(s,TypeExn (mk_id o' s)) ∉ FDOM gtagenv`
                          by (fs [SUBSET_DEF] >>
                              metis_tac [SND]) >>
                 rw [bind_def, emp_def] >>
                 pop_assum (qspecl_then [`[]`, `envC`] mp_tac) >>
                 rw [merge_envC_empty] >>
                 metis_tac []) >>
     fs [merge_envC_empty_assoc, merge_def, emp_def] >>
     `s_to_i2' gtagenv' s1 s1_i2 ∧ vs_to_i2 gtagenv' genv genv_i2` 
                 by metis_tac [v_to_i2_weakening, s_to_i2'_cases] >>
     FIRST_X_ASSUM (qspecl_then [`s1_i2`, `genv_i2`, `alloc_tag (TypeExn (mk_id o' s)) s tagenv_st`,
                                 `ds_i2`, `tagenv_st'`, `gtagenv'` ] mp_tac) >>
     rw [] >>
     metis_tac [gtagenv_weak_trans]));

val dummy_env_to_i2 = Q.prove (
`!ds cenv cenv' ds'.
  decs_to_i2 cenv ds = (cenv',ds')
  ⇒
  decs_to_dummy_env ds = decs_to_dummy_env_i2 ds'`,
 induct_on `ds` >>
 rw [decs_to_i2_def, decs_to_dummy_env_def, decs_to_dummy_env_i2_def] >>
 rw [decs_to_i2_def, decs_to_dummy_env_def, decs_to_dummy_env_i2_def] >>
 every_case_tac >>
 fs [LET_THM, dec_to_dummy_env_def]
 >- (Cases_on `decs_to_i2 cenv ds` >>
     fs [] >>
     rw [decs_to_dummy_env_i2_def, dec_to_dummy_env_i2_def] >>
     metis_tac [])
 >- (Cases_on `decs_to_i2 cenv ds` >>
     fs [] >>
     rw [decs_to_dummy_env_i2_def, dec_to_dummy_env_i2_def,
         funs_to_i2_map] >>
     metis_tac [])
 >- metis_tac []
 >- metis_tac []);

val prompt_to_i2_correct = Q.prove (
`!genv_opt envC s_mods prompt r.
  evaluate_prompt_i1 genv_opt envC s_mods prompt r
  ⇒
  !genv s tids s1_i2 genv_i2 tagenv_st prompt_i2 genv' envC' s' tids' res gtagenv tagenv_st'.
    genv_opt = MAP SOME genv ∧
    s_mods = (s,tids) ∧
    r = ((s',tids'), envC', genv', res) ∧
    res ≠ SOME Rtype_error ∧
    (tagenv_st', prompt_i2) = prompt_to_i2 tagenv_st prompt ∧
    cenv_inv envC (FST (SND tagenv_st)) gtagenv ∧
    s_to_i2' gtagenv s s1_i2 ∧
    vs_to_i2 gtagenv genv genv_i2 ∧
    alloc_tags_invariant tids tagenv_st gtagenv
    ⇒
    ?genv'_i2 s'_i2 res_i2 gtagenv'.
      evaluate_prompt_i2 (MAP SOME genv_i2) s1_i2 prompt_i2 (s'_i2,genv'_i2,res_i2) ∧
      cenv_inv (merge_envC envC' envC) (FST (SND tagenv_st')) gtagenv' ∧
      vs_to_i2 gtagenv' genv' genv'_i2 ∧
      s_to_i2' gtagenv' s' s'_i2 ∧
      alloc_tags_invariant tids' tagenv_st' gtagenv' ∧
      (res = NONE ∧ res_i2 = NONE ∨
       ?err err_i2. res = SOME err ∧ res_i2 = SOME err_i2 ∧ result_to_i2 (\a b c. T) gtagenv' (Rerr err) (Rerr err_i2))`,
 rw [evaluate_prompt_i1_cases, evaluate_prompt_i2_cases] >>
 `?next tagenv inv_tagenv. tagenv_st = (next,tagenv,inv_tagenv)` by metis_tac [pair_CASES] >>
 fs [prompt_to_i2_def] >>
 every_case_tac >>
 fs [LET_THM] >>
 rw [] >>
 `?next' tagenv' inv_tagenv' acc ds_i2. decs_to_i2 (next,tagenv,inv_tagenv,[]) ds = ((next',tagenv',inv_tagenv',acc),ds_i2)` by metis_tac [pair_CASES] >>
 fs [] >>
 rw []


 >- metis_tac [decs_to_i2_correct, NOT_SOME_NONE, PAIR_EQ, get_tagenv_def] >>
 `?s'_i2 genv'_i2 err_i2 clengths'.
    evaluate_decs_i2 (MAP SOME genv_i2) s1_i2 prompt_i2' (s'_i2,genv'_i2,SOME err_i2) ∧
    cenv_inv (merge_envC (mod_cenv mn cenv') envC) cenv_mapping' clengths' ∧
    vs_to_i2 (cenv_mapping_to_cenv cenv_mapping' clengths') env genv'_i2 ∧
    s_to_i2' (cenv_mapping_to_cenv cenv_mapping' clengths') s' s'_i2 ∧
    result_to_i2 (λa (b:'a) (c:'b). T) (cenv_mapping_to_cenv cenv_mapping' clengths') (Rerr err) (Rerr err_i2)`
       by (imp_res_tac (SIMP_RULE (srw_ss()) [PULL_FORALL] decs_to_i2_correct) >>
           fs [] >>
           rpt (pop_assum mp_tac) >>
           rw [] >>
           metis_tac []) >>
 Q.LIST_EXISTS_TAC [`genv'_i2 ++ GENLIST (λn. Litv_i2 Unit) (decs_to_dummy_env_i2 prompt_i2' − LENGTH genv'_i2)`,
                    `s'_i2`,
                    `SOME err_i2`,
                    `clengths'`] >>
 rw []
 >- (qexists_tac `genv'_i2` >>
     rw [])
 >- (`LENGTH env = LENGTH genv'_i2` by metis_tac [length_vs_to_i2] >>
     `vs_to_i2 (cenv_mapping_to_cenv cenv_mapping' clengths') 
               (GENLIST (λn. Litv_i1 Unit) (decs_to_dummy_env ds − LENGTH env))
               (GENLIST (λn. Litv_i2 Unit) (decs_to_dummy_env_i2 prompt_i2' − LENGTH env))`
                  by (imp_res_tac dummy_env_to_i2 >>
                      rw [] >>
                      rpt (pop_assum (fn _ => all_tac)) >>
                      Q.SPEC_TAC (`decs_to_dummy_env_i2 prompt_i2' − LENGTH genv'_i2`, `nn`) >>
                      induct_on `nn` >>
                      rw [v_to_i2_eqns, GENLIST, SNOC_APPEND, vs_to_i2_append1]) >>
     metis_tac [vs_to_i2_append]))

val _ = export_theory ();
