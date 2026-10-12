/* nurbs.rs: fit_polyline (2 tests 1:1) + interpolate_periodic y spline interpolate_* ([extra]). */
#include "ocx.ch"
PROCEDURE T_NurbsFit()
   LOCAL aSrc, nTol, c, p, nBest, i, lOk, aOn, r, aPts, t, nCnt, aT
   aSrc := { {0.0,0.0}, {1.0,0.8}, {2.0,-0.6}, {3.0,0.0} }
   nTol := 0.4
   c := NC_FitPolyline( aSrc, nTol )
   lOk := c != NIL
   IF lOk
      FOR EACH p IN NC_Tessellate( c, 32 )
         nBest := OCX_INF()
         FOR i := 1 TO Len( aSrc ) - 1
            nBest := Min( nBest, V2_DistanceToSegment( p, aSrc[i], aSrc[i+1] ) )
         NEXT
         IF nBest > nTol + 0.000000001 ; lOk := .F. ; ENDIF
      NEXT
      FOR EACH p IN aSrc
         aOn := NC_PointAt( c, NC_ParameterAt( c, p ) )
         IF V2_Distance( p, aOn ) > nTol + 0.000000001 ; lOk := .F. ; ENDIF
      NEXT
   ENDIF
   Chk( lOk, "nurbs: freehand_fit_stays_within_tolerance" )
   aSrc := { {0.0,0.0}, {1.0,2.0}, {3.0,1.0} }
   c := NC_FitPolyline( aSrc, 0.0 )
   Chk( c != NIL .AND. NC_Degree( c ) == 1 .AND. Len( NC_ControlPoints( c ) ) == 3 .AND. NC_ControlPoints( c )[2][1] == 1.0 .AND. NC_ControlPoints( c )[3][2] == 1.0, "nurbs: zero_freehand_tolerance_keeps_the_polyline" )
   // [extra]
   Chk( NC_FitPolyline( { {0.0,0.0} }, 0.1 ) == NIL .AND. NC_FitPolyline( aSrc, -1.0 ) == NIL, "[extra] fit_polyline: un punto o tolerancia negativa -> NIL" )
   c := NC_FitPolyline( { {0.0,0.0}, {5.0,0.0001}, {10.0,0.0} }, 0.5 )
   Chk( c != NIL .AND. NC_Degree( c ) == 1 .AND. Len( NC_ControlPoints( c ) ) == 2, "[extra] fit_polyline: puntos casi colineales se reducen a una recta" )
   // periodic
   aPts := { {0.0,0.0}, {4.0,0.0}, {4.0,3.0}, {0.0,3.0} }
   c := NC_InterpolatePeriodic( aPts, PZ_CHORD )
   lOk := c != NIL .AND. NC_Degree( c ) == 3 .AND. Len( NC_ControlPoints( c ) ) == 13
   IF lOk
      FOR EACH p IN aPts
         t := NC_ParameterAt( c, p )
         IF V2_Distance( NC_PointAt( c, t ), p ) > 0.000001 ; lOk := .F. ; ENDIF
      NEXT
      IF V2_Distance( NC_PointAt( c, 0.0 ), NC_PointAt( c, 1.0 ) ) > 0.000001 ; lOk := .F. ; ENDIF
   ENDIF
   Chk( lOk, "[extra] interpolate_periodic: pasa por los puntos y cierra" )
   Chk( NC_InterpolatePeriodic( { {0.0,0.0}, {1.0,1.0} }, PZ_CHORD ) == NIL, "[extra] interpolate_periodic: menos de 3 puntos -> NIL" )
   r := NC_InterpolatePeriodic( { {0.0,0.0}, {4.0,0.0}, {4.0,3.0}, {0.0,3.0}, {0.0,0.0} }, PZ_UNIFORM )
   Chk( r != NIL .AND. Len( NC_ControlPoints( r ) ) == 13, "[extra] interpolate_periodic: el punto final repetido se descarta" )
   // spline interpolate_open con 3 coordenadas
   aPts := { {0.0,0.0,0.0}, {1.0,2.0,1.0}, {3.0,2.0,2.0}, {4.0,0.0,3.0} }
   r := Spl_InterpolateOpen( aPts, NIL, NIL, PZ_CENTRIPETAL )
   Chk( r != NIL .AND. Len( r[1] ) == 10 .AND. Len( r[2] ) == 14, "[extra] spline interpolate_open: tamanos 3n-2 y 3n+2" )
   nCnt := 0
   FOR i := 0 TO 3
      t := r[1][ 3 * i + 1 ]
      IF Abs( t[1] - aPts[i+1][1] ) < 0.000000001 .AND. Abs( t[3] - aPts[i+1][3] ) < 0.000000001 ; nCnt++ ; ENDIF
   NEXT
   Chk( nCnt == 4, "[extra] spline interpolate_open: los puntos de ajuste son puntos de control" )
   aT := { 0.0, 0.0, 0.0 }
   Chk( Spl_InterpolateOpen( aPts, aT, aT, PZ_CHORD ) != NIL .AND. Spl_InterpolateOpen( { {1.0,1.0,1.0} }, NIL, NIL, PZ_CHORD ) == NIL, "[extra] spline interpolate_open: tangente cero = natural; 1 punto -> NIL" )
RETURN
