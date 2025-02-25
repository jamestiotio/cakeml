(**
 * Pancake concrete syntax examples
 * 9th May 2023: Updated with function declarations
 *)
open HolKernel Parse boolLib bossLib stringLib numLib intLib;
open preamble panPtreeConversionTheory;
open helperLib;

val _ = new_theory "panConcreteExamples";

local
  val f =
    List.mapPartial
       (fn s => case remove_whitespace s of "" => NONE | x => SOME x) o
    String.tokens (fn c => c = #"\n")
in
  fun quote_to_strings q =
    f (Portable.quote_to_string (fn _ => raise General.Bind) q)
end

fun lex_pancake q =
  let
    val code = quote_to_strings q |> String.concatWith "\n" |> fromMLstring
  in
    EVAL “pancake_lex ^code”
end

fun parse_tree_pancake q =
  let
    val code = quote_to_strings q |> String.concatWith "\n" |> fromMLstring
  in
    EVAL “parse (pancake_lex ^code)”
end

(** Copied from panPtreeConversion *)
fun parse_pancake q =
  let
    val code = quote_to_strings q |> String.concatWith "\n" |> fromMLstring
  in
    EVAL “parse_funs_to_ast ^code”
  end

val check_success = assert $ optionSyntax.is_some o rhs o concl

(** Examples can be written using quoted strings and passed to the ML
    function parse_pancake. *)

(** Pancake programs consist of a sequence of function declarations. *)

(** The body of each function consists of a sequence of blocks. *)

(** Blocks: Declarations, Conditionals (If-Then-Else), Loops (While) *)

(** Conditionals: An if-block without an alternative. The bodies of the
    conditional are Pancake programs (in this case a single assignment
    statement). NB: Statements end with a semi-colon, blocks do not. *)
val ex1 = ‘
  fun cond() {
    if 2 >= 1 { x = 2; }
  }’;

val treeEx1 = check_success $ parse_pancake ex1;

(** We also have a selection of boolean operators and we can call
    functions. A struct value encloses expressions within chevrons
    (‘<>’). *)
val ex2 = ‘
  fun main() {
    if b & (a ^ c) & d {
      foo(1, <2, 3>);
    } else {
      goo(4, 5, 6);
    }
  }’;

val treeEx2 = check_success $ parse_pancake ex2;

(** We also have a selection of boolean operators and
    a ‘return’ statement. *)
val ex3 = ‘
  fun boolfun() {
    if b & (a ^ c) & d { return true; }
    else { return false; }
  }’;

val treeEx3 = check_success $ parse_pancake ex3;

(** Loops: standard looping construct. *)

val ex4 = ‘
  fun loopy() {
    while b | c {
      if x >= 5 {
        break;
      } else {
        strb y, 8; // store byte
        #foo(x,y,k,z); // ffi function call with pointer args
        x = x + 1;
        y = x + 1;
      }
    }
  }’;

val treeEx4 = check_success $ parse_pancake ex4;

(** Declarations: intended semantics is the variable scope extends as
    far left as possible. *)

val ex5 = ‘
  fun foo () {
    var b = 5;
    b = b + 1;
    if b >= 5 {
      raise Err 5;
    }
  }’;

val treeEx5 = check_success $ parse_pancake ex5;

(** Scope can be indicated with curly brackets *)

val ex6 = ‘
  fun foo () {
    {var b = 5;
     b = b + 1;};
     if b >= 5 {
       raise Err 5;
     }
  }’;

val treeEx6 = check_success $ parse_pancake ex6;

(* Load data of a fixed shape. The below example loads a triple where
   the first two components are single words, and the third is a tuple
   of words.
 *)
val ex7 = ‘
  fun loader() {
    x = lds {1,1,2} y;
  }’;

val treeEx7 = check_success $ parse_pancake ex7;

(* These can be nested arbitrarily deep *)
val ex7_and_a_half = ‘
  fun loader() {
    x = lds {3,1,{1,{2,1}}} y;
  }’;

val treeEx7_and_a_half = check_success $ parse_pancake ex7_and_a_half;

(* Note that {1} and 1 are distinct shapes *)
val ex7_and_three_quarters = ‘
  fun loader() {
    x = lds {1,{1}} y;
  }’;

val treeEx7_and_three_quarters = check_success $ parse_pancake ex7_and_three_quarters;

(* Comparison operators. Only two of these exist in the concrete syntax,
   so the parser may rotate them. This shouldn't matter since expressions
   are pure.
 *)
val ex8 = ‘
  fun cmps () {
    x = a < b;
    x = b > a;
    x =  b >= a;
    x = a <= b;
  }’;

val treeEx8 = check_success $ parse_pancake ex8;

(* Multiplication
 *)

val ex8_and_a_half = ‘x = a * b;
                      x = a * b * c;
                      x =  (a + b) * c;
                      x = a + b * c;
                      x = a * b + c;’;

val treeEx8_and_a_half = check_success $ parse_pancake ex8_and_a_half;

(** Statments. *)

(** Small test modelled after the minimal working example. *)
val ex10 = ‘
 fun testfun() {
   var a = @base;
   var b = 8;
   var c = @base + 16;
   var d = 1;
   #out_morefun(a,b,c,d);
   str @base, ic;
   return 0;
 }’;

val treeEx10 = check_success $ parse_pancake ex10;

(** Multiple functions. *)

val ex_much_fun = ‘
  fun loader() {
    x = lds {1,{1}} y;
  }

  fun loader() {
    x = lds {1,{1}} y;
  }

  fun cmps () {
    x = a < b;
    x = b > a;
    x =  b >= a;
    x = a <= b;
  }’;

val treeExMuchFun = check_success $ parse_pancake ex_much_fun;

(** We can assign boolean expressions to variables. *)
val exN = ‘fun blah() { x = b & a ^ c & d; }’;

val treeExN = check_success $ parse_pancake exN;

val _ = export_theory();
