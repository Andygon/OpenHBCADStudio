/* Port de #[cfg(test)] de curve_offset.rs (3 tests). UTF-8. */
#include "ocx.ch"
STATIC FUNCTION AssertParallel( src, res, nDist, nTol )
   LOCAL i, p, d
   FOR i := 0 TO 200
      p := Cv_PointAt( res, i / 200.0 )
      d := Co_ClosestPoint( src, p )[ CL_D ]
      IF Abs( d - Abs( nDist ) ) > nTol * 2.0 ; RETURN .F. ; ENDIF
   NEXT
RETURN .T.

PROCEDURE T_CurveOffset()
   LOCAL src, nDist, res, ok, aOrigin, spl, arc, inner, aCtl, p
   src := Cv_Ellipse( EA_Full( Ell_New( { 0.0, 0.0 }, 7.0, 3.0, { 1.0, 0.0 } ) ) )
   ok := .T.
   FOR EACH nDist IN { 1.0, -1.0 }
      res := CO2_OffsetCurve( src, nDist, 0.000001 )
      ok := ok .AND. res != NIL .AND. res[ CV_KIND ] == CV_NURBS
      IF res != NIL ; ok := ok .AND. AssertParallel( src, res, nDist, 0.000001 ) ; ENDIF
   NEXT
   Chk( ok, "curve_offset: elipse -> paralela real (NURBS)" )

   aOrigin := { 1234567.0, 4567890.0 }
   aCtl := {}
   FOR EACH p IN { { -9.0, -5.0 }, { -4.0, 7.0 }, { 0.0, -7.0 }, { 4.0, 8.0 }, { 9.0, -4.0 } }
      AAdd( aCtl, { aOrigin[1] + p[1], aOrigin[2] + p[2] } )
   NEXT
   spl := Cv_Nurbs( NC_New( 3, aCtl, { 0.0, 0.0, 0.0, 0.0, 0.5, 1.0, 1.0, 1.0, 1.0 }, NIL ) )
   res := CO2_OffsetCurve( spl, 0.5, 0.00001 )
   Chk( res != NIL .AND. AssertParallel( spl, res, 0.5, 0.00001 ), "curve_offset: spline en coordenadas topograficas" )

   arc := Cv_Arc( { 0.0, 0.0 }, 5.0, 0.0, 1.0 )
   inner := CO2_OffsetCurve( arc, 1.0, 0.000001 )
   Chk( inner != NIL .AND. inner[ CV_KIND ] == CV_ARC .AND. Abs( inner[ CV_DATA ][ AR_RADIUS ] - 4.0 ) < 0.000000000001 .AND. CO2_OffsetCurve( arc, 6.0, 0.000001 ) == NIL, "curve_offset: arcos mantienen su tipo" )
RETURN
