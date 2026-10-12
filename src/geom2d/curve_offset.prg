/* Port de opencadkernel/src/geom2d/curve_offset.rs (204 lineas, 3 tests ported 1:1). UTF-8.
   Prefijo CO2_ (Co_ ya es containment). Option -> NIL. */
#include "ocx.ch"

STATIC FUNCTION CO2_Shift( p, aAlong, nDist )
   LOCAL n := V2_Normalize( aAlong )
   IF n == NIL ; RETURN NIL ; ENDIF
RETURN V2_Add( p, V2_Mul( V2_Perpendicular( n ), nDist ) )

FUNCTION CO2_OffsetCurve( c, nDist, nTol )
   LOCAL d := c[ CV_DATA ], a, b, nR, aFit
   IF ! OCX_ISFINITE( nDist ) .OR. ! ( nTol > 0.0 ) ; RETURN NIL ; ENDIF
   DO CASE
   CASE c[ CV_KIND ] == CV_LINE
      a := CO2_Shift( d[1], V2_Sub( d[2], d[1] ), nDist )
      IF a == NIL ; RETURN NIL ; ENDIF
      b := CO2_Shift( d[2], V2_Sub( d[2], d[1] ), nDist )
      IF b == NIL ; RETURN NIL ; ENDIF
      RETURN Cv_Line( a, b )
   CASE c[ CV_KIND ] == CV_RAY
      a := CO2_Shift( d[ RY_ORIGIN ], d[ RY_DIR ], nDist )
      IF a == NIL ; RETURN NIL ; ENDIF
      RETURN Cv_Ray( a, d[ RY_DIR ] )
   CASE c[ CV_KIND ] == CV_XLINE
      a := CO2_Shift( d[ XL_BASE ], d[ XL_DIR ], nDist )
      IF a == NIL ; RETURN NIL ; ENDIF
      RETURN Cv_XLine( a, d[ XL_DIR ] )
   CASE c[ CV_KIND ] == CV_CIRCLE
      nR := d[2] - nDist
      IF nR > 0.0 ; RETURN Cv_Circle( d[1], nR ) ; ENDIF
      RETURN NIL
   CASE c[ CV_KIND ] == CV_ARC
      nR := d[ AR_RADIUS ] - nDist
      IF nR > 0.0 ; RETURN Cv_Arc( d[ AR_CENTRE ], nR, d[ AR_START ], d[ AR_END ] ) ; ENDIF
      RETURN NIL
   CASE c[ CV_KIND ] == CV_POLYLINE
      RETURN NIL
   ENDCASE
   aFit := CO2_Fitted( c, nDist, nTol )
   IF aFit == NIL ; RETURN NIL ; ENDIF
RETURN Cv_Nurbs( aFit )

STATIC FUNCTION CO2_Tangent( loc, lClosed, t )
   LOCAL h := 0.0000001, a, b
   IF lClosed
      a := Cv_PointAt( loc, OCX_REMEUCLID( t + h, 1.0 ) )
      b := Cv_PointAt( loc, OCX_REMEUCLID( t - h, 1.0 ) )
   ELSE
      a := Cv_PointAt( loc, Min( t + h, 1.0 ) )
      b := Cv_PointAt( loc, Max( t - h, 0.0 ) )
   ENDIF
RETURN V2_Normalize( V2_Sub( a, b ) )

STATIC FUNCTION CO2_At( loc, lClosed, nDist, t )
   LOCAL tg := CO2_Tangent( loc, lClosed, t )
   IF tg == NIL ; RETURN NIL ; ENDIF
RETURN V2_Add( Cv_PointAt( loc, t ), V2_Mul( V2_Perpendicular( tg ), nDist ) )

STATIC FUNCTION CO2_LocalDistance( aFit, aTarget, nLo, nHi )
   LOCAL third, i
   FOR i := 1 TO 60
      third := ( nHi - nLo ) / 3.0
      IF third <= 0.0000000000000001 ; EXIT ; ENDIF
      IF V2_Distance( NC_PointAt( aFit, nLo + third ), aTarget ) < V2_Distance( NC_PointAt( aFit, nHi - third ), aTarget )
         nHi := nHi - third
      ELSE
         nLo := nLo + third
      ENDIF
   NEXT
RETURN V2_Distance( NC_PointAt( aFit, ( nLo + nHi ) * 0.5 ), aTarget )

STATIC FUNCTION CO2_Fitted( c, nDist, nTol )
   LOCAL aAnchor := Cv_PointAt( c, 0.0 ), loc, lClosed, nSamples := 8, aParams, aPts, aRaw, i, p, aT0, aT1
   LOCAL aFit, aAlong, nTotal, nWorst, aTruth, nLo, nHi, aBack, bk
   loc := Cv_Transformed( c, Tr_Translation( { -aAnchor[1], -aAnchor[2] } ) )
   IF loc == NIL ; RETURN NIL ; ENDIF
   lClosed := Cv_IsClosed( loc )
   DO WHILE nSamples <= 8192
      aParams := Array( nSamples + 1 )
      FOR i := 0 TO nSamples ; aParams[ i + 1 ] := i / nSamples ; NEXT
      aPts := Array( nSamples + 1 )
      FOR i := 1 TO nSamples + 1
         p := CO2_At( loc, lClosed, nDist, aParams[ i ] )
         IF p == NIL ; RETURN NIL ; ENDIF
         aPts[ i ] := p
      NEXT
      aRaw := aPts
      aT0 := CO2_Tangent( loc, lClosed, 0.0 )
      IF aT0 == NIL ; RETURN NIL ; ENDIF
      aT1 := CO2_Tangent( loc, lClosed, 1.0 )
      IF aT1 == NIL ; RETURN NIL ; ENDIF
      aFit := NC_Interpolate( aRaw, aT0, aT1, PZ_CHORD )
      IF aFit == NIL ; RETURN NIL ; ENDIF
      aAlong := Array( nSamples + 1 )
      AFill( aAlong, 0.0 )
      FOR i := 2 TO nSamples + 1
         aAlong[ i ] := aAlong[ i - 1 ] + Max( V2_Distance( aPts[ i ], aPts[ i - 1 ] ), 0.000000001 )
      NEXT
      nTotal := aAlong[ nSamples + 1 ]
      nWorst := 0.0
      FOR i := 1 TO nSamples
         aTruth := CO2_At( loc, lClosed, nDist, ( aParams[ i ] + aParams[ i + 1 ] ) * 0.5 )
         IF aTruth == NIL
            nWorst := OCX_INF() ; EXIT
         ENDIF
         nLo := aAlong[ i ] / nTotal ; nHi := aAlong[ i + 1 ] / nTotal
         nWorst := Max( nWorst, CO2_LocalDistance( aFit, aTruth, nLo, nHi ) )
         IF nWorst > nTol ; EXIT ; ENDIF
      NEXT
      IF nWorst <= nTol
         aBack := Tr_Translation( aAnchor )
         bk := Cv_Transformed( Cv_Nurbs( aFit ), aBack )
         IF bk == NIL ; RETURN NIL ; ENDIF
         IF bk[ CV_KIND ] == CV_NURBS ; RETURN bk[ CV_DATA ] ; ENDIF
         RETURN NIL
      ENDIF
      nSamples *= 2
   ENDDO
RETURN NIL
