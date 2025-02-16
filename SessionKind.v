Require Import Reals.
Require Import Psatz.
Require Import Complex.
Require Import SQIR.
Require Import VectorStates UnitaryOps Coq.btauto.Btauto Coq.NArith.Nnat Permutation. 
Require Import Dirac.
Require Import QPE.
Require Import BasicUtility.
Require Import Classical_Prop.
Require Import MathSpec.
Require Import QWhileSyntax.
Require Import SessionDef.
(**********************)
(** Session Definitions **)
(**********************)

Require Import Coq.FSets.FMapList.
Require Import Coq.FSets.FMapFacts.
Require Import Coq.Structures.OrderedTypeEx.
Local Open Scope nat_scope.

(* Kind checking rules to determine if an expression has a certain kind. *)

Definition is_class_type (t:ktype) := match t with Mo CT => True | Mo MT => True | _ => False end.

Inductive union_f : (ktype * session) -> (ktype * session) -> (ktype * session) -> Prop :=
 | union_cl_1: union_f (Mo CT,nil) (Mo CT,nil) (Mo CT, nil)
 | union_cl_2: union_f (Mo CT,nil) (Mo MT,nil) (Mo MT, nil)
 | union_cl_3: union_f (Mo MT,nil) (Mo CT,nil) (Mo MT, nil)
 |  union_sl: forall a b l1 l2, is_class_type b -> union_f (QT a,l1) (b,l2) (QT a, l1)
 | union_sr: forall a b l1 l2, is_class_type a -> union_f (a,l1) (QT b,l2) (QT b, l1)
 | union_two: forall a b l1 l2, ses_dis (l1++l2) -> union_f (QT a,l1) (QT b,l2) (QT (a+b), l1++l2). 

Inductive type_aexp : aenv -> aexp -> (ktype*session) -> Prop :=
   | ba_type : forall env b t, t = Mo MT \/ t = Mo CT -> AEnv.MapsTo b t env -> type_aexp env (BA b) (t,[])
   | ba_type_q : forall env b n, AEnv.MapsTo b (QT n) env -> type_aexp env (BA b) (QT n,[(b,BNum 0,BNum n)])
   | num_type : forall env n, type_aexp env (Num n) (Mo CT,[])
   | num_type_q : forall env r n, type_aexp env (MNum r n) (Mo MT,[])
   | plus_type : forall env e1 e2 t1 t2 t3, 
                   type_aexp env e1 t1 -> type_aexp env e2 t2 -> union_f t1 t2 t3 -> 
                     type_aexp env (APlus e1 e2) t3
   | mult_type : forall env e1 e2 t1 t2 t3, type_aexp env e1 t1 -> type_aexp env e2 t2 -> union_f t1 t2 t3 -> 
                     type_aexp env (AMult e1 e2) t3
   | mnum_type : forall env r n, type_aexp env (MNum r n) (Mo MT,[]).


Inductive type_vari : aenv -> varia -> (ktype*session) -> Prop :=
   | aexp_type : forall env a t, type_aexp env a t -> type_vari env a t
   | index_type : forall env x n v,
       AEnv.MapsTo x (QT n) env -> 0 <= v < n -> type_vari env (Index x (Num v)) (QT 1,[(x,BNum v,BNum (S v))]).


Inductive type_cbexp : aenv -> cbexp -> ktype -> Prop :=
  | ceq_type : forall env a b t1 t2 l1 l2, type_aexp env a (t1,l1) -> type_aexp env b (t2,l2) ->
                     is_class_type t1 -> is_class_type t2 -> type_cbexp env (CEq a b) (meet_ktype t1 t2)
  | clt_type : forall env a b t1 t2 l1 l2, type_aexp env a (t1,l1) -> type_aexp env b (t2,l2) ->
                     is_class_type t1 -> is_class_type t2 -> type_cbexp env (CLt a b) (meet_ktype t1 t2).

Inductive type_bexp : aenv -> bexp -> (ktype*session) -> Prop :=
   | cb_type: forall env b t, type_cbexp env b t -> type_bexp env (CB b) (t,nil)

   | beq_type_1 : forall env a b x m n v, AEnv.MapsTo a (QT m) env -> 
             AEnv.MapsTo x (QT n) env -> 0 <= v < n -> 
           type_bexp env (BEq (BA a) ((Num b)) x (Num v)) (QT (m+1),((a,BNum 0,BNum m)::[(x,BNum v,BNum (S v))]))
   | beq_type_2 : forall env a b x m n v, AEnv.MapsTo a (QT m) env -> 
             AEnv.MapsTo x (QT n) env -> 0 <= v < n -> 
           type_bexp env (BEq ((Num b)) (BA a) x (Num v)) (QT (m+1),((a,BNum 0,BNum m)::[(x,BNum v,BNum (S v))]))
   | blt_type_1 : forall env a b x m n v, AEnv.MapsTo a (QT m) env -> 
             AEnv.MapsTo x (QT n) env -> 0 <= v < n -> 
           type_bexp env (BLt (BA a) ((Num b)) x (Num v)) (QT (m+1),((a,BNum 0,BNum m)::[(x,BNum v,BNum (S v))]))
   | blt_type_2 : forall env a b x m n v, AEnv.MapsTo a (QT m) env -> 
             AEnv.MapsTo x (QT n) env -> 0 <= v < n -> 
           type_bexp env (BLt ((Num b)) (BA a) x (Num v)) (QT (m+1),((a,BNum 0,BNum m)::[(x,BNum v,BNum (S v))]))
   | btest_type : forall env x n v, AEnv.MapsTo x (QT n) env -> 0 <= v < n 
            -> type_bexp env (BTest x (Num v)) (QT 1,[((x,BNum v,BNum (S v)))])
   | bneg_type : forall env b t, type_bexp env b t -> type_bexp env (BNeg b) t.


Inductive type_exp : aenv -> exp -> (ktype*session) -> Prop :=
   | skip_fa : forall env x v n, AEnv.MapsTo x (QT n) env -> 0 <= v < n -> type_exp env (SKIP x (Num v)) (QT 1,([(x,BNum v, BNum (S v))]))
   | x_fa : forall env x v n, AEnv.MapsTo x (QT n) env -> 0 <= v < n -> type_exp env (X x (Num v)) (QT 1,([(x,BNum v, BNum (S v))]))
   | rz_fa : forall env q x v n, AEnv.MapsTo x (QT n) env -> 0 <= v < n -> type_exp env (RZ q x (Num v)) (QT 1, ([(x,BNum v, BNum (S v))]))
   | rrz_fa : forall env q x v n, AEnv.MapsTo x (QT n) env -> 0 <= v < n -> type_exp env (RRZ q x (Num v)) (QT 1, ([(x,BNum v, BNum (S v))]))
   | sr_fa : forall env q x n, AEnv.MapsTo x (QT n) env -> q < n -> type_exp env (SR q x) (QT n, ([(x,BNum 0, BNum n)]))
   | srr_fa : forall env q x n,  AEnv.MapsTo x (QT n) env -> q < n -> type_exp env (SRR q x) (QT n, ([(x,BNum 0, BNum n)]))
   | qft_fa : forall env q x n,  AEnv.MapsTo x (QT n) env -> q <= n -> 0 < n -> type_exp env (QFT x q) (QT n, ([(x,BNum 0, BNum n)]))
   | rqft_fa : forall env q x n,  AEnv.MapsTo x (QT n) env -> q <= n -> 0 < n -> type_exp env (RQFT x q) (QT n, ([(x,BNum 0, BNum n)]))
   | lft_fa : forall env x n,  AEnv.MapsTo x (QT n) env -> type_exp env (Lshift x) (QT n, ([(x,BNum 0, BNum n)]))
   | rft_fa : forall env x n,  AEnv.MapsTo x (QT n) env -> type_exp env (Rshift x) (QT n, ([(x,BNum 0, BNum n)]))
   | rev_fa : forall env x n,  AEnv.MapsTo x (QT n) env -> type_exp env (Rev x) (QT n, ([(x,BNum 0, BNum n)]))
   | cu_fa : forall env x v n e t1 t2, AEnv.MapsTo x (QT n) env -> 0 <= v < n -> 
            type_exp env e t1 -> union_f (QT 1, ([(x,BNum v, BNum (S v))])) t1 t2 -> type_exp env (CU x (Num v) e) t2
   | seq_fa : forall env e1 t1 e2 t2 t3, type_exp env e1 t1 -> type_exp env e2 t2 -> union_f t1 t2 t3 ->
                 type_exp env (Seq e1 e2) t3.

Inductive fv_su : aenv -> single_u -> session -> Prop :=
   fv_su_h : forall env a n s, type_vari env a (QT n, s) -> fv_su env (RH a) s
  | fv_su_qft : forall env x n, AEnv.MapsTo x (QT n) env -> fv_su env (SQFT x) ([(x,BNum 0,BNum n)])
  | fv_su_rqft : forall env x n, AEnv.MapsTo x (QT n) env -> fv_su env (SRQFT x) ([(x,BNum 0,BNum n)]).

Inductive fv_pexp : aenv -> pexp -> session -> Prop :=
  | pskip_fa: forall env, fv_pexp env (PSKIP) nil
  | let_fa_c : forall env x a e, fv_pexp env (Let x (AE a) e) nil
  | let_fa_m : forall env x a e n, AEnv.MapsTo x (QT n) env -> fv_pexp env (Let x (Meas a) e) ([(x,BNum 0,BNum n)])
  | appsu_fa: forall env e s,  fv_su env e s -> fv_pexp env (AppSU e) s
  | appu_fa : forall env l e, fv_pexp env (AppU l e) l
  | if_fa : forall env t l l1 b e, type_bexp env b (t,l) -> fv_pexp env e l1 -> fv_pexp env (If b e) (l++l1)
  | for_fa : forall env t l h x b e, (forall i, l <= i < h -> 
                 fv_pexp env (If (subst_bexp b x i) (subst_pexp e x i)) (subst_session t x i))
                              -> fv_pexp env (For x (Num l) (Num h) b e) (subst_session t x h)
  | pseq_fa : forall env e1 e2 l1 l2, fv_pexp env e1 l1 -> fv_pexp env e2 l2 
                              -> fv_pexp env (PSeq e1 e2) (join_ses l1 l2)
  | dis_fa : forall env x n, AEnv.MapsTo x (QT n) env -> fv_pexp env (Diffuse x) ([(x,BNum 0,BNum n)]).

Fixpoint freeVarsAExp (a:aexp) := match a with BA x => ([x]) | Num n => nil | MNum r n => nil
            | APlus e1 e2 => (freeVarsAExp e1)++(freeVarsAExp e2)
            | AMult e1 e2 => (freeVarsAExp e1)++(freeVarsAExp e2)
  end.
Definition freeVarsVari (a:varia) := match a with AExp x => freeVarsAExp x
            | Index x v => (x::freeVarsAExp v)
  end.
Definition freeVarsCBexp (a:cbexp) := match a with CEq x y => (freeVarsAExp x)++(freeVarsAExp y)
         | CLt x y => (freeVarsAExp x)++(freeVarsAExp y)
  end.
Fixpoint freeVarsBexp (a:bexp) := match a with CB b => (freeVarsCBexp b)
         | BEq x y i a => i::((freeVarsVari x)++(freeVarsVari y)++(freeVarsAExp a))
         | BLt x y i a => i::((freeVarsVari x)++(freeVarsVari y)++(freeVarsAExp a))
         | BTest i a => i::(freeVarsAExp a)
         | BNeg b => freeVarsBexp b
  end.
Definition freeVarsMAExp (m:maexp) := match m with AE n => freeVarsAExp n | Meas x => ([x]) end.

Fixpoint list_sub (s:list var) (b:var) :=
   match s with nil => nil
              | a::al => if a =? b then list_sub al b else a::list_sub al b
   end.

Lemma list_sub_not_in : forall l x xa, xa <> x -> In xa l -> In xa (list_sub l x).
Proof.
  induction l;intros;simpl in *. easy.
  bdestruct (a =? x); subst. destruct H0; subst. easy.
  apply IHl. easy. easy. destruct H0; subst. simpl. left. easy.
  simpl. right. apply IHl; try easy.
Qed.

Fixpoint freeVarsPExp (p:pexp) := 
   match p with PSKIP => nil
              | Let x n e => freeVarsMAExp n ++ list_sub (freeVarsPExp e) x
              | AppSU (RH p) => freeVarsVari p
              | AppSU (SQFT x) => ([x])
              | AppSU (SRQFT x) => ([x])
              | If b e => freeVarsBexp b ++ freeVarsPExp e
              | For x l h b e => freeVarsAExp l ++ freeVarsAExp h 
                                    ++ list_sub (freeVarsBexp b) x ++ list_sub (freeVarsPExp e) x
              | PSeq e1 e2 => freeVarsPExp e1 ++ freeVarsPExp e2
              | _ => nil
   end.

Definition freeVarsNotCAExp (env:aenv) (a:aexp) :=
   forall x t, In x (freeVarsAExp a) -> AEnv.MapsTo x (Mo t) env -> t <> CT.

Definition freeVarsNotCBExp (env:aenv) (a:bexp) :=
   forall x t, In x (freeVarsBexp a) -> AEnv.MapsTo x (Mo t) env -> t <> CT.

Definition freeVarsNotCPExp (env:aenv) (a:pexp) :=
   forall x t, In x (freeVarsPExp a) -> AEnv.MapsTo x (Mo t) env -> t <> CT.


Definition kind_env_stack (env:aenv) (s:stack) : Prop :=
  forall x, AEnv.MapsTo x (Mo MT) env <-> AEnv.In x s.

Fixpoint simp_aexp (a:aexp) :=
   match a with BA y => None
             | Num a => Some a
              | MNum r a => None
             | APlus c d => match (simp_aexp c,simp_aexp d) with (Some v1,Some v2) => Some (v1+v2)
                                | (_,_) => None
                            end
             | AMult c d => match (simp_aexp c,simp_aexp d) with (Some v1,Some v2) => Some (v1*v2)
                                | (_,_) => None
                            end
   end.

Fixpoint simp_bexp (a:bexp) :=
   match a with CB (CEq x y) => match (simp_aexp x,simp_aexp y) with (Some v1,Some v2) => Some (v1 =? v2)
                                                                   | _ => None
                                end
              | CB (CLt x y) => match (simp_aexp x,simp_aexp y) with (Some v1,Some v2) => Some (v1 <? v2)
                                                                   | _ => None
                                end
              | BNeg b => match simp_bexp b with None => None | Some b' => Some (negb b') end
              | _ => None
   end.

Inductive eval_aexp : stack -> aexp -> (R * nat) -> Prop :=
    | var_sem : forall s x r n, AEnv.MapsTo x (r,n) s -> eval_aexp s (BA x) (r,n)
    | mnum_sem: forall s r n, eval_aexp s (MNum r n) (r,n)
    | aplus_sem_1: forall s e1 e2 r n1 n2, eval_aexp s e1 (r,n1) -> simp_aexp e2 = Some n2 -> eval_aexp s (APlus e1 e2) (r,n1 + n2)
    | aplus_sem_2: forall s e1 e2 r n1 n2, eval_aexp s e2 (r,n2) -> simp_aexp e1 = Some n1 -> eval_aexp s (APlus e1 e2) (r,n1 + n2)
    | amult_sem_1: forall s e1 e2 r n1 n2, eval_aexp s e1 (r,n1) -> simp_aexp e2 = Some n2 -> eval_aexp s (AMult e1 e2) (r,n1 * n2)
    | amult_sem_2: forall s e1 e2 r n1 n2, eval_aexp s e2 (r,n2) -> simp_aexp e1 = Some n1 -> eval_aexp s (AMult e1 e2) (r,n1 * n2). 

Inductive eval_cbexp : stack -> bexp -> bool -> Prop :=
    | ceq_sem_1 : forall s x y r1 n1 n2, eval_aexp s x (r1,n1) -> simp_aexp y = Some n2 -> eval_cbexp s (CB (CEq x y)) (n1 =? n2)
    | ceq_sem_2 : forall s x y n1 r2 n2, simp_aexp x = Some n1 -> eval_aexp s y (r2,n2) -> eval_cbexp s (CB (CEq x y)) (n1 =? n2)
    | ceq_sem_3 : forall s x y r1 n1 r2 n2, eval_aexp s x (r1,n1) -> eval_aexp s y (r2,n2) -> eval_cbexp s (CB (CEq x y)) (n1 =? n2)
    | clt_sem_1 : forall s x y r1 n1 n2, eval_aexp s x (r1,n1) -> simp_aexp y = Some n2 -> eval_cbexp s (CB (CLt x y)) (n1 <? n2)
    | clt_sem_2 : forall s x y n1 r2 n2, simp_aexp x = Some n1 -> eval_aexp s y (r2,n2) -> eval_cbexp s (CB (CLt x y)) (n1 <? n2)
    | clt_sem_3 : forall s x y r1 n1 r2 n2, eval_aexp s x (r1,n1) -> eval_aexp s y (r2,n2) -> eval_cbexp s (CB (CLt x y)) (n1 <? n2)
    | bneq_sem: forall s e b, eval_cbexp s e b -> eval_cbexp s (BNeg e) (negb b).

Inductive simp_varia : aenv -> varia -> range -> Prop :=
    | aexp_sem : forall env x n, AEnv.MapsTo x (QT n) env -> simp_varia env (AExp (BA x)) (x,BNum 0, BNum n)
    | index_sem : forall env x v, simp_varia env (Index x (Num v)) (x,BNum v,BNum (v+1)).

Lemma kind_aexp_class_empty: forall env a t l, type_aexp env a (Mo t, l) -> t = CT \/ t = MT -> l = [].
Proof.
  intros. remember (Mo t, l) as e. induction H; simpl in *; try easy.
  inv Heqe. destruct H. inv H. easy. easy. inv Heqe. easy. inv Heqe. easy.
  subst. destruct H0; subst. inv H2. easy.
  inv H2. easy. easy.
  destruct H0; subst. inv H2. easy. inv H2; easy.
  inv Heqe. easy.
Qed.


Lemma simp_aexp_empty: forall a v, simp_aexp a = Some v -> freeVarsAExp a = [].
Proof.
  induction a;intros;simpl in *; try easy.
  destruct (simp_aexp a1) eqn:eq1.
  destruct (simp_aexp a2) eqn:eq2. inv H. erewrite IHa1; try easy. erewrite IHa2; try easy.
  inv H. inv H.
  destruct (simp_aexp a1) eqn:eq1.
  destruct (simp_aexp a2) eqn:eq2. inv H. erewrite IHa1; try easy. erewrite IHa2; try easy.
  inv H. inv H.
Qed.


Lemma freeVars_pexp_in : forall e env x a v, freeVarsNotCPExp env (Let x (AE a) e) -> simp_aexp a = Some v ->
             freeVarsNotCPExp env (subst_pexp e x v).
Proof.
  induction e; intros;simpl in *.
  unfold freeVarsNotCPExp in *; intros. simpl in *. easy.
Admitted.

Lemma kind_env_stack_exist_ct: forall env a, 
     freeVarsNotCAExp env a -> type_aexp env a (Mo CT, []) -> exists v, simp_aexp a = Some v.
Proof.
 intros. remember (Mo CT, []) as l.
 induction H0; simpl in *; try easy.
 inv Heql;subst. destruct H0. inv H0.
 specialize (H b CT). simpl in *. apply H in H1. easy. left. easy.
 exists n. easy. subst. inv H0.
 apply kind_aexp_class_empty in H0_ as X1.
 apply kind_aexp_class_empty in H0_0 as X2. subst.
 assert (freeVarsNotCAExp env e1).
 unfold freeVarsNotCAExp in *. intros. apply (H x). simpl in *.
 apply in_app_iff. left. easy.
 easy.
 assert (freeVarsNotCAExp env e2).
 unfold freeVarsNotCAExp in *. intros. apply (H x). simpl in *.
 apply in_app_iff. right. easy.
 easy.
 apply IHtype_aexp1 in H0; try easy.
 apply IHtype_aexp2 in H1; try easy.
 destruct H0. destruct H1.
 exists (x+x0). rewrite H0. rewrite H1. easy. left. easy. left. easy.
 subst. inv H0.
 apply kind_aexp_class_empty in H0_ as X1.
 apply kind_aexp_class_empty in H0_0 as X2. subst.
 assert (freeVarsNotCAExp env e1).
 unfold freeVarsNotCAExp in *. intros. apply (H x). simpl in *.
 apply in_app_iff. left. easy.
 easy.
 assert (freeVarsNotCAExp env e2).
 unfold freeVarsNotCAExp in *. intros. apply (H x). simpl in *.
 apply in_app_iff. right. easy.
 easy.
 apply IHtype_aexp1 in H0; try easy.
 apply IHtype_aexp2 in H1; try easy.
 destruct H0. destruct H1.
 exists (x*x0). rewrite H0. rewrite H1. easy. left. easy. left. easy. 
Qed.

(* Follow the pattern in kind_env_stack_exist_ct.
   Now, please realize that in the type of MT in aexp, you must have one side being CT and the other one being MT. *)
Lemma kind_env_stack_exist : forall env s a, kind_env_stack env s -> freeVarsNotCAExp env a ->
              type_aexp env a (Mo MT, nil) -> exists v, eval_aexp s a v.
Proof.
  intros. remember (Mo MT, nil) as t.
  induction H1; simpl in *.
  destruct H1; subst.
  apply H in H2.
  destruct H2. exists x. destruct x. constructor. easy.
  inv Heqt. inv Heqt. inv Heqt.
  exists (r,n); constructor.
  subst. inv H1.
  (* show e1 + e2 case, deal with cases, check if type e1 or e2 is CT.
     use kind_env_stack_exist_ct *)
  assert (freeVarsNotCAExp env e1).
  unfold freeVarsNotCAExp in *. intros. apply (H0 x). simpl in *.
  apply in_app_iff. left. auto. auto.
  assert (freeVarsNotCAExp env e2).
  unfold freeVarsNotCAExp in *. intros. apply (H0 x). simpl in *.
  apply in_app_iff. right. auto. auto.
  apply kind_aexp_class_empty in H1_ as X1.
  apply kind_aexp_class_empty in H1_0 as X2.
  subst.
  apply kind_env_stack_exist_ct in H1; try easy. destruct H1.
  apply IHtype_aexp2 in H2; try easy. destruct H2. destruct x0.
  exists (r,x + n). apply aplus_sem_2; try easy. right. easy. left. easy.
  assert (freeVarsNotCAExp env e1).
  unfold freeVarsNotCAExp in *. intros. apply (H0 x). simpl in *.
  apply in_app_iff. left. auto. auto.
  assert (freeVarsNotCAExp env e2).
  unfold freeVarsNotCAExp in *. intros. apply (H0 x). simpl in *.
  apply in_app_iff. right. auto. auto.
  apply kind_aexp_class_empty in H1_ as X1.
  apply kind_aexp_class_empty in H1_0 as X2.
  subst.
  apply IHtype_aexp1 in H1; try easy. destruct H1.
  apply kind_env_stack_exist_ct in H2; try auto. destruct H2.
  destruct x.
  exists (r, n+x0). apply aplus_sem_1; try auto. left. auto. right. auto.
  assert (freeVarsNotCAExp env e1).
  unfold freeVarsNotCAExp in *. intros. apply (H0 x). simpl in *.
  apply in_app_iff. left. auto. auto.
  assert (freeVarsNotCAExp env e2).
  unfold freeVarsNotCAExp in *. intros. apply (H0 x). simpl in *.
  apply in_app_iff. right. auto. auto.
  inv H1.
  apply kind_aexp_class_empty in H1_ as X1.
  apply kind_aexp_class_empty in H1_0 as X2.
  subst.
  apply IHtype_aexp1 in H2; try easy. left. auto. left. auto.
  apply kind_aexp_class_empty in H1_ as X1.
  apply kind_aexp_class_empty in H1_0 as X2.
  subst.
  apply IHtype_aexp2 in H3; try easy. destruct H3. destruct x.
  apply kind_env_stack_exist_ct in H2; try easy. destruct H2.
  exists (r, x*n). apply amult_sem_2; try easy. right. auto. left. auto.
  apply kind_aexp_class_empty in H1_ as X1.
  apply kind_aexp_class_empty in H1_0 as X2.
  subst.
  apply IHtype_aexp1 in H2; try auto. destruct H2. destruct x.
  apply kind_env_stack_exist_ct in H3; try auto. destruct H3.
  exists (r, n*x). apply amult_sem_1; try easy. left. auto. right. auto.
  inv H7. inv H7. inv H7.
  exists (r,n). apply mnum_sem; try auto.
  Qed.


Lemma kind_env_stack_exist_bexp : forall env s b, kind_env_stack env s -> freeVarsNotCBExp env b ->
              type_bexp env b (Mo MT, nil) -> exists v, eval_cbexp s b v.
Proof.
  intros. remember (Mo MT, nil) as t.
  induction H1; simpl in *.
  destruct b. inv Heqt. inv H1.
  unfold meet_ktype,meet_atype in *. destruct t1. destruct t2. destruct a. inv H4.
  (* case 1 *)
  apply kind_aexp_class_empty in H5 as X1. subst.
  apply kind_aexp_class_empty in H7 as X2; subst.
  assert (freeVarsNotCAExp env x).
  unfold freeVarsNotCBExp,freeVarsNotCAExp in *; simpl in *.
  intros. apply (H0 x0); try easy.
  apply in_app_iff. left. easy.
  assert (freeVarsNotCAExp env y).
  unfold freeVarsNotCBExp,freeVarsNotCAExp in *; simpl in *.
  intros. apply (H0 x0); try easy.
  apply in_app_iff. right. easy.
  apply kind_env_stack_exist_ct in H5 as X3; try easy. destruct X3.
  apply kind_env_stack_exist with (s := s) in H7; try easy. destruct H7. destruct x1.
  exists (x0 =? n). apply ceq_sem_2 with (r2 := r); try easy. right. easy. left. easy.
  (* case 2 *)
  apply kind_aexp_class_empty in H5 as X1. subst.
  apply kind_aexp_class_empty in H7 as X2; subst.
  assert (freeVarsNotCAExp env x).
  unfold freeVarsNotCBExp,freeVarsNotCAExp in *; simpl in *.
  intros. apply (H0 x0); try easy.
  apply in_app_iff. left. easy.
  assert (freeVarsNotCAExp env y).
  unfold freeVarsNotCBExp,freeVarsNotCAExp in *; simpl in *.
  intros. apply (H0 x0); try easy.
  apply in_app_iff. right. easy.
  apply kind_env_stack_exist with (s := s) in H5; try easy. destruct H5. destruct x0.
  destruct a0.
  apply kind_env_stack_exist_ct in H7 as X3; try easy. destruct X3.
  exists (n =? x0). apply ceq_sem_1 with (r1 := r); try easy.
  apply kind_env_stack_exist with (s := s) in H7; try easy. destruct H7. destruct x0.
  exists (n =? n0). apply ceq_sem_3 with (r1 := r) (r2 := r0); try easy.
  destruct a0. left. easy. right. easy. right. easy. inv H4.
  (* case 3 *)
  destruct t2. easy. easy. inv Heqt. inv H1.
  unfold meet_ktype,meet_atype in *. destruct t1. destruct t2. destruct a. inv H4.
  (* case 31 *)
  apply kind_aexp_class_empty in H5 as X1. subst.
  apply kind_aexp_class_empty in H7 as X2; subst.
  assert (freeVarsNotCAExp env x).
  unfold freeVarsNotCBExp,freeVarsNotCAExp in *; simpl in *.
  intros. apply (H0 x0); try easy.
  apply in_app_iff. left. easy.
  assert (freeVarsNotCAExp env y).
  unfold freeVarsNotCBExp,freeVarsNotCAExp in *; simpl in *.
  intros. apply (H0 x0); try easy.
  apply in_app_iff. right. easy.
  apply kind_env_stack_exist_ct in H5 as X3; try easy. destruct X3.
  apply kind_env_stack_exist with (s := s) in H7; try easy. destruct H7. destruct x1.
  exists (x0 <? n). apply clt_sem_2 with (r2 := r); try easy. right. easy. left. easy.
  destruct a0.
  apply kind_aexp_class_empty in H5 as X1. subst.
  apply kind_aexp_class_empty in H7 as X2; subst.
  assert (freeVarsNotCAExp env x).
  unfold freeVarsNotCBExp,freeVarsNotCAExp in *; simpl in *.
  intros. apply (H0 x0); try easy.
  apply in_app_iff. left. easy.
  assert (freeVarsNotCAExp env y).
  unfold freeVarsNotCBExp,freeVarsNotCAExp in *; simpl in *.
  intros. apply (H0 x0); try easy.
  apply in_app_iff. right. easy.
  apply kind_env_stack_exist with (s := s) in H5; try easy. destruct H5. destruct x0.
  apply kind_env_stack_exist_ct in H7 as X3; try easy. destruct X3.
  exists (n <? x0). apply clt_sem_1 with (r1 := r); try easy. left. easy. right. easy.
  apply kind_aexp_class_empty in H5 as X1. subst.
  apply kind_aexp_class_empty in H7 as X2; subst.
  assert (freeVarsNotCAExp env x).
  unfold freeVarsNotCBExp,freeVarsNotCAExp in *; simpl in *.
  intros. apply (H0 x0); try easy.
  apply in_app_iff. left. easy.
  assert (freeVarsNotCAExp env y).
  unfold freeVarsNotCBExp,freeVarsNotCAExp in *; simpl in *.
  intros. apply (H0 x0); try easy.
  apply in_app_iff. right. easy.
  apply kind_env_stack_exist with (s := s) in H5 as X3; try easy. destruct X3. destruct x0.
  apply kind_env_stack_exist with (s := s) in H7; try easy. destruct H7. destruct x0.
  exists (n <? n0). apply clt_sem_3 with (r1 := r) (r2 := r0); try easy. right. easy. right. easy.
  easy. destruct t2. easy. easy. inv Heqt. inv Heqt. inv Heqt. inv Heqt. inv Heqt. subst.
  apply IHtype_bexp in H0; try easy. destruct H0.
  exists (negb x). constructor. easy.
Qed.

Lemma subst_aexp_eq_var: forall b i v x, subst_aexp b i v = BA x -> b = BA x /\ x <> i.
Proof.
  induction b; intros;simpl in *; try easy.
  bdestruct (i =? x); subst. inv H. split. easy. intros R. subst. inv H. easy.
  destruct (subst_aexp b1 i v) eqn:eq1. inv H.
  destruct (subst_aexp b2 i v) eqn:eq2; try inv H. inv H. inv H. inv H.
  destruct (subst_aexp b1 i v) eqn:eq1; try inv H.
  destruct (subst_aexp b2 i v) eqn:eq2; try inv H1. 
Qed.

Lemma in_list_sub_if: forall l x i, In x (list_sub l i) -> In x l.
Proof.
  induction l;intros;simpl in *; try easy.
  bdestruct (a =? i). subst. apply IHl in H. right. easy.
  simpl in *. destruct H; subst. left. easy.
  apply IHl in H. right. easy.
Qed.

Lemma in_list_sub_app_iff: forall l1 l2 x i, In x (list_sub (l1++l2) i)
    <-> In x (list_sub l1 i) \/ In x (list_sub l2 i).
Proof.
Admitted.

Lemma freeVarAExp_subst: forall b i v x, In x (freeVarsAExp (subst_aexp b i v))
        -> In x (list_sub (freeVarsAExp b) i).
Proof.
  induction b;intros;simpl in *; try easy.
  bdestruct (x=?i). rewrite H0 in *. bdestruct (i=?i). simpl in *. easy. lia.
  bdestruct (i =? x). rewrite H1 in H0. easy. simpl in *. easy.
  destruct (subst_aexp b1 i v) eqn:eq1. simpl in *. destruct H; subst.
  apply subst_aexp_eq_var in eq1. destruct eq1. subst.
  apply list_sub_not_in. lia. simpl in *. left. easy.
  apply subst_aexp_eq_var in eq1. destruct eq1. subst.
  bdestruct (x =? i). subst.
  simpl in *. bdestruct (x0 =? i). lia. simpl in *. right. apply IHb2 in H. easy.
  apply list_sub_not_in. lia. simpl in *.
  apply IHb2 in H. apply in_list_sub_if in H. right. easy.
Admitted.

Lemma freeVarCBExp_subst: forall b i v x, In x (freeVarsCBexp (subst_cbexp b i v))
        -> In x (list_sub (freeVarsCBexp b) i).
Proof.
  induction b;intros;simpl in *; try easy.
  apply in_app_iff in H. destruct H. apply freeVarAExp_subst in H.
  apply in_list_sub_app_iff. left. easy.
  apply freeVarAExp_subst in H. apply in_list_sub_app_iff. right. easy.
  apply in_app_iff in H. destruct H. apply freeVarAExp_subst in H.
  apply in_list_sub_app_iff. left. easy.
  apply freeVarAExp_subst in H. apply in_list_sub_app_iff. right. easy.
Qed.

Lemma freeVarBexp_subst: forall b i v x, In x (freeVarsBexp (subst_bexp b i v))
        -> In x (list_sub (freeVarsBexp b) i).
Proof.
  induction b;intros;simpl in *; try easy.
  apply freeVarCBExp_subst in H. easy.
Admitted.

Lemma freeVarPExp_subst: forall b i v x, In x (freeVarsPExp (subst_pexp b i v))
        -> In x (list_sub (freeVarsPExp b) i).
Proof.
  induction b;intros;simpl in *; try easy.
Admitted.

