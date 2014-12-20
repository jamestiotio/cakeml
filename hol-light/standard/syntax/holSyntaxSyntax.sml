structure holSyntaxSyntax = struct
local
  open HolKernel holSyntaxTheory
  fun syntax_fns n m d = HolKernel.syntax_fns "holSyntax" n m d
in

  local
    val s = syntax_fns 1 dest_monop mk_monop
  in
    val (Tyvar_tm,mk_Tyvar,dest_Tyvar,is_Tyvar) = s "Tyvar"
    val (welltyped_tm,mk_welltyped,dest_welltyped,is_welltyped) = s "welltyped"
    val (typeof_tm,mk_typeof,dest_typeof,is_typeof) = s "typeof"
  end

  local
    val s = syntax_fns 2 dest_binop mk_binop
  in
    val (Tyapp_tm,mk_Tyapp,dest_Tyapp,is_Tyapp) = s "Tyapp"
    val (Var_tm,mk_Var,dest_Var,is_Var) = s "Var"
    val (Const_tm,mk_Const,dest_Const,is_Const) = s "Const"
    val (Comb_tm,mk_Comb,dest_Comb,is_Comb) = s "Comb"
    val (Abs_tm,mk_Abs,dest_Abs,is_Abs) = s "Abs"
    val (VFREE_IN_tm,mk_VFREE_IN,dest_VFREE_IN,is_VFREE_IN) = s "VFREE_IN"
    val (proves_tm,mk_proves,dest_proves,is_proves) = s "|-"
  end

  val type_ty = mk_thy_type{Thy="holSyntax",Tyop="type",Args=[]}
  val term_ty = mk_thy_type{Thy="holSyntax",Tyop="term",Args=[]}

end
end
