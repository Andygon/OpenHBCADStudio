/* Port de #[cfg(test)] de nurbs.rs: interpolate (sin periodic/fit_polyline aun). UTF-8. */
#include "ocx.ch"
STATIC FUNCTION CL( a, b, e ) ; RETURN Abs( a[1]-b[1] ) < e .AND. Abs( a[2]-b[2] ) < e

PROCEDURE T_NurbsInterp()
   LOCAL fit, c, d, tg, ok, i, t, a, b, aSp, f, m, fit3, mode, cc
   fit := { {0.0,0.0}, {1.0,2.0}, {3.0,1.0}, {5.0,4.0} }
   c := NC_Interpolate( fit, NIL, NIL, PZ_CHORD )
   d := NC_Domain( c )
   Chk( CL( NC_PointAtKnot( c, d[1] ), fit[1], 0.000000001 ) .AND. CL( NC_PointAtKnot( c, d[2] ), fit[4], 0.000000001 ), "interpolada pasa por extremos" )
   ok := .T.
   FOR EACH tg IN fit
      t := NC_ParameterAt( c, tg )
      ok := ok .AND. CL( NC_PointAt( c, t ), tg, 0.000001 )
   NEXT
   Chk( ok, "interpolada pasa por cada punto de ajuste" )

   c := NC_Interpolate( { {0.0,0.0}, {10.0,0.0} }, { 0.0, 1.0 }, { 0.0, -1.0 }, PZ_CHORD )
   Chk( NC_Degree( c ) == 3 .AND. Len( NC_ControlPoints( c ) ) == 4, "dos puntos con tangentes: un cubico" )
   Chk( CL( NC_PointAt( c, 0.0 ), { 0.0, 0.0 }, 0.000000001 ) .AND. CL( NC_PointAt( c, 1.0 ), { 10.0, 0.0 }, 0.000000001 ), "dos puntos: extremos" )
   Chk( NC_PointAt( c, 0.5 )[2] > 0.0, "dos puntos: arquea hacia arriba" )

   c := NC_Interpolate( { {0.0,0.0}, {5.0,0.0}, {10.0,0.0} }, { 1.0, 2.0 }, { 1.0, -2.0 }, PZ_CHORD )
   a := NC_PointAt( c, 0.0 ) ; b := NC_PointAt( c, 0.001 )
   Chk( Abs( ( b[2]-a[2] ) / ( b[1]-a[1] ) - 2.0 ) < 0.05, "tangente inicial seguida" )
   a := NC_PointAt( c, 0.999 ) ; b := NC_PointAt( c, 1.0 )
   Chk( Abs( ( b[2]-a[2] ) / ( b[1]-a[1] ) + 2.0 ) < 0.05, "tangente final seguida" )

   fit3 := { {0.0,0.0}, {2.0,3.0}, {4.0,-1.0} }
   ok := .T.
   FOR EACH mode IN { PZ_UNIFORM, PZ_CENTRIPETAL, PZ_CHORD }
      cc := NC_Interpolate( fit3, NIL, NIL, mode )
      FOR EACH tg IN fit3
         ok := ok .AND. CL( NC_PointAt( cc, NC_ParameterAt( cc, tg ) ), tg, 0.000001 )
      NEXT
   NEXT
   Chk( ok, "sin tangentes pasa por los puntos (3 parametrizaciones)" )

   c := NC_Interpolate( fit, NIL, NIL, PZ_CHORD )
   aSp := NC_SplitAt( c, 0.45 )
   Chk( aSp != NIL .AND. CL( NC_PointAt( aSp[1], 1.0 ), NC_PointAt( aSp[2], 0.0 ), 0.000000001 ), "interpolada se puede partir: union" )
   ok := .T.
   FOR i := 0 TO 10
      f := i / 10.0
      ok := ok .AND. CL( NC_PointAt( aSp[1], f ), NC_PointAt( c, f * 0.45 ), 0.000000001 )
   NEXT
   Chk( ok, "interpolada partida: mitad izquierda coincide" )

   Chk( NC_Interpolate( {}, NIL, NIL, PZ_CHORD ) == NIL .AND. NC_Interpolate( { {1.0,1.0} }, NIL, NIL, PZ_CHORD ) == NIL, "menos de 2 puntos no es curva" )

   m := { 512345.678, 4512345.678 }
   c := NC_New( 3, { m, { m[1]+1.0, m[2]+5.0 }, { m[1]+4.0, m[2]+5.0 }, { m[1]+5.0, m[2] } }, {}, NIL )
   Chk( CL( NC_PointAt( c, 0.0 ), m, 0.000001 ) .AND. CL( NC_PointAt( c, 1.0 ), { m[1]+5.0, m[2] }, 0.000001 ), "coordenadas topograficas sin deriva" )
RETURN
