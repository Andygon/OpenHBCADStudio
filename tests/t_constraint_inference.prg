/* Port de #[cfg(test)] de constraint_inference.rs (3 tests). UTF-8. */
#include "ocx.ch"
PROCEDURE T_ConstraintInference()
   LOCAL curves, found, nH := 0, it, lCol := .F., strict, loose, lT, aSet, f
   curves := { Cv_Line( {0.0,0.0}, {2.0,0.0} ), Cv_Line( {2.0,0.0}, {4.0,0.0} ) }
   found := Ci_Infer( curves, 0.000001, 0.000001 )
   FOR EACH it IN found
      IF it[ IC_KIND ] == IK_COLLINEAR ; lCol := .T. ; ENDIF
      IF it[ IC_KIND ] == IK_HORIZONTAL ; nH++ ; ENDIF
   NEXT
   Chk( Len( found ) > 0 .AND. found[1][ IC_KIND ] == IK_COINCIDENT .AND. ! lCol .AND. nH == 2, "inference: orden de prioridad sin colinealidad redundante" )
   curves := { Cv_Circle( {0.0,0.0}, 2.0 ), Cv_Line( {10.0,2.0}, {12.0,2.0} ) }
   strict := Ci_InferWithSettings( curves, Ci_DefaultSettings() )
   lT := .F.
   FOR EACH it IN strict
      IF it[ IC_KIND ] == IK_TANGENT ; lT := .T. ; ENDIF
   NEXT
   aSet := Ci_DefaultSettings() ; aSet[4] := .F.
   loose := Ci_InferWithSettings( curves, aSet )
   f := .F.
   FOR EACH it IN loose
      IF it[ IC_KIND ] == IK_TANGENT ; f := .T. ; ENDIF
   NEXT
   Chk( ! lT .AND. f, "inference: tangencia acotada respeta tangent_must_share_point" )
   curves := { Cv_Line( {0.0,0.0}, {2.0,0.0} ), Cv_Line( {3.0,0.0}, {5.0,0.0} ) }
   aSet := Ci_DefaultSettings() ; aSet[1] := { IK_COLLINEAR }
   found := Ci_InferWithSettings( curves, aSet )
   Chk( Len( found ) == 1 .AND. found[1][ IC_KIND ] == IK_COLLINEAR .AND. found[1][ IC_FIRST ] == 0 .AND. found[1][ IC_SECOND ] == 1, "inference: ejes deshabilitados no suprimen relaciones de pares habilitadas" )
RETURN
