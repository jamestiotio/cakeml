(*
  Define the compiler configuration for ARMv8
*)
open preamble backendTheory arm8_targetTheory arm8_targetLib

val _ = new_theory"arm8_config";

val arm8_names_def = Define `
  arm8_names =
    (* source can use 29 regs (0-28),
       target's r18 should be avoided (platform reserved),
       target's r26 must be avoided (extra encoding register),
       target's r31 must be avoided (stack pointer),
       source 0 must represent r30 (link register),
       source 1-4 must be r0-r3 (1st 4 args),
       top three (26-28) must be callee-saved (in r19-r28) *)
    (insert 0 30 o
     insert 1 0 o
     insert 2 1 o
     insert 3 2 o
     insert 4 3 o
     insert 18 4 o
     insert 25 29 o
     insert 26 25 o
     (* Next ones are for well-formedness only *)
     insert 29 18 o
     insert 30 26) LN:num num_map`

val arm8_names_def = save_thm("arm8_names_def[compute]",
  CONV_RULE (RAND_CONV EVAL) arm8_names_def);

val clos_conf = rconc (EVAL ``clos_to_bvl$default_config``)
val bvl_conf = rconc (EVAL``bvl_to_bvi$default_config``)
val word_to_word_conf = ``<| reg_alg:=2; col_oracle := [] |>``
(* TODO: this config may need to change *)
val arm8_data_conf = ``<| tag_bits:=4; len_bits:=4; pad_bits:=2; len_size:=32; has_div:=T; has_longdiv:=F; has_fp_ops:=F; has_fp_tern:=F; be:=F; call_empty_ffi:=F; gc_kind:=Simple|>``
val arm8_word_conf = ``<| bitmaps_length := 0; stack_frame_size := LN |>``
val arm8_stack_conf = ``<|jump:=T;reg_names:=arm8_names|>``
val arm8_lab_conf = ``<|pos:=0;ffi_names:=NONE;labels:=LN;sec_pos_len:=[];asm_conf:=arm8_config;init_clock:=5;hash_size:=104729n|>``

val arm8_backend_config_def = Define`
  arm8_backend_config =
             <|source_conf:=prim_src_config;
               clos_conf:=^(clos_conf);
               bvl_conf:=^(bvl_conf);
               data_conf:=^(arm8_data_conf);
               word_to_word_conf:=^(word_to_word_conf);
               word_conf:=^(arm8_word_conf);
               stack_conf:=^(arm8_stack_conf);
               lab_conf:=^(arm8_lab_conf);
               symbols:=[];
               tap_conf:=default_tap_config
               |>`;

val _ = export_theory();
