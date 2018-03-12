Set Warnings "-notation-overridden".

Require Export Coq.FSets.FMapPositive.

Module Export MP := FMapPositive.
Module M := MP.PositiveMap.

Require Export Solver.Lib.
Require Export Solver.IList.

Unset Equations WithK.

Require Export Category.Theory.Category.
Require Export Category.Theory.EndoFunctor.
Require Export Category.Theory.Natural.Transformation.
Require Export Category.Theory.Adjunction.
Require Import Category.Instance.Coq.

Require Import Solver.IList.

Generalizable All Variables.

Definition obj_idx : Type := positive.
Definition arr_idx (n : nat) : Type := Fin.t n.

Definition obj_pair := obj_idx * obj_idx.
Definition dep_arr {C: Category}
           (objs : obj_idx -> C) (p : obj_pair) :=
  match p with (dom, cod) => objs dom ~> objs cod end.
Arguments dep_arr {C} objs p /.

Class Env := {
  cat : Category;
  objs : obj_idx -> cat;
  num_arrs : nat;
  tys : Vector.t (obj_idx * obj_idx) num_arrs;
  arrs : ilist (B:=dep_arr objs) tys
}.

Instance obj_idx_Equality : Equality obj_idx := {
  Eq_eqb         := Pos.eqb;
  Eq_eqb_refl    := Pos_eqb_refl;

  Eq_eqb_eq x y  := proj1 (Pos.eqb_eq x y);

  Eq_eq_dec      := Pos.eq_dec;
  Eq_eq_dec_refl := Pos_eq_dec_refl
}.

Program Instance arr_idx_Equality (n : nat) : Equality (arr_idx n) := {
  Eq_eqb         := Fin.eqb;
  Eq_eqb_refl    := Fin_eqb_refl n;

  Eq_eqb_eq x y  := proj1 (Fin_eqb_eq n x y);

  Eq_eq_dec      := Fin_eq_dec;
  Eq_eq_dec_refl := Fin_eq_dec_refl n
}.

Instance arr_idx_Setoid {a} : Setoid (arr_idx a) := {
  equiv := Eq_eq;
  setoid_equiv := eq_equivalence
}.

(** Every monoid defines a category where composition is mappend. *)

Import EqNotations.

Program Definition list_cat A B `{H : Setoid B} : Category := {|
  obj := A;
  hom := fun _ _ => list B;
  homset := fun x y => {| equiv := @list_equiv B H |};
  id := fun _ => [];
  compose := fun _ _ _ f g => f ++ g;
  id_left := fun _ _ => reflexivity (R:=list_equiv);
  id_right := fun _ _ l =>
    rew <- [fun l => list_equiv l _] (app_nil_r l)
      in reflexivity (R:=list_equiv) l;
  comp_assoc := fun _ _ _ _ x y z =>
    rew [fun l => list_equiv _ l] (app_assoc x y z)
      in reflexivity (R:=list_equiv) (x ++ y ++ z);
  comp_assoc_sym := fun _ _ _ _ x y z =>
    rew [fun l => list_equiv l _] (app_assoc x y z)
      in reflexivity (R:=list_equiv) (x ++ y ++ z)
|}.

Section Env.

Context `{Env}.

Definition opt_arrs_equiv {dom cod} (f g : option (objs dom ~> objs cod)) :=
  match f, g with
  | Some f, Some g => f ≈ g
  | None, None => True
  | _, _ => False
  end.
Arguments opt_arrs_equiv {dom cod} f g /.

Global Program Instance opt_arrs_Equivalence dom cod :
  Equivalence (@opt_arrs_equiv dom cod).
Next Obligation. destruct x; simpl; cat. Qed.
Next Obligation. destruct x, y; simpl; cat. Qed.
Next Obligation. destruct x, y, z; simpl; cat; contradiction. Qed.

Global Program Instance opt_arrs_Setoid dom cod :
  Setoid (option (objs dom ~{ cat }~> objs cod)) := {
  equiv := opt_arrs_equiv
}.

Definition opt_arrs_compose {dom mid cod}
           (f : option (objs mid ~> objs cod))
           (g : option (objs dom ~> objs mid)) :
  option (objs dom ~> objs cod) :=
  match f, g with
  | Some f, Some g => Some (f ∘ g)
  | _, _ => None
  end.

Global Program Instance opt_arrs_compose_Proper {dom mid cod} :
  Proper (equiv ==> equiv ==> equiv) (@opt_arrs_compose dom mid cod).
Next Obligation.
  repeat intro.
  destruct x, x0, y, y0; simpl in *; auto.
  now rewrite X, X0.
Qed.

(** opt_arrs is a category that combines thin and thick morphisms. *)

Global Program Instance opt_arrs : Category := {|
  obj := obj_idx;
  hom := fun dom cod => option (objs dom ~> objs cod);
  homset := opt_arrs_Setoid;
  id := fun _ => Some id;
  compose := @opt_arrs_compose
|}.
Next Obligation. destruct f; cat. Qed.
Next Obligation. destruct f; simpl; cat. Qed.
Next Obligation. destruct f, g, h; simpl; cat. Qed.
Next Obligation. destruct f, g, h; simpl; cat. Qed.

End Env.
