/* Port de #[cfg(test)] de mod.rs + comprobaciones AÑADIDAS de Ellipse (no existen en Rust; se marcan [extra]). */
#include "ocx.ch"
PROCEDURE T_Mod()
   LOCAL tol, lPanic, e, p, t, i, nA, nErr
   tol := Tol_New( 0.001 )
   Chk( Tol_AreEqual( tol, 1.0, 1.0005 ), "tol eq" ); Chk( ! Tol_AreEqual( tol, 1.0, 1.002 ), "tol ne" )
   lPanic := .F.
   BEGIN SEQUENCE WITH {|o| Break( o ) }
      Tol_New( 0.0 )
   RECOVER USING e
      lPanic := ( "finite and positive" $ e:description )
   END SEQUENCE
   Chk( lPanic, "zero tolerance refused" )
   Chk( Tol_Default() == 0.0000001, "tol default" )
   // [extra] ellipse: el parametro mas cercano a un punto de la elipse devuelve ese parametro
   e := Ell_New( { 1.0, 2.0 }, 5.0, 3.0, { 1.0, 0.0 } )
   nErr := 0
   FOR i := 0 TO 23
      t := -3.0 + i * 0.25
      p := Ell_PointAt( e, t )
      nA := Ell_ClosestParameter( e, p )
      nErr := Max( nErr, Abs( ATan2n( OCX_SIN( nA - t ), OCX_COS( nA - t ) ) ) )
   NEXT
   Chk( nErr < 0.000001, "[extra] closest_parameter sobre la elipse, err=" + hb_ntos( nErr ) )
   Chk( Abs( V2_Distance( Ell_PointAt( e, 0.0 ), { 6.0, 2.0 } ) ) < 0.000000000001, "[extra] point_at(0)" )
   Chk( Abs( V2_Distance( Ell_PointAt( e, OCX_FRAC_PI_2 ), { 1.0, 5.0 } ) ) < 0.000000000001, "[extra] point_at(pi/2)" )
   Chk( Ell_IsDegenerate( Ell_New( { 0, 0 }, 0.0, 1.0, { 1, 0 } ) ), "[extra] degenerate" )
RETURN
STATIC FUNCTION ATan2n( y, x )
RETURN OCX_ATAN2( y, x )
