/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/nurbs.prg
   Origen Rust: opencadkernel/src/geom2d/nurbs.rs (1619 lineas)
   Estado: PARCIAL - traducido: new, new_strict, accesores, is_rational, domain,
   point_at_knot, derivative_at_knot, derivative_at, point_at, parameter_at,
   tessellate, is_closed.
   Pendiente: insert_knot, reversed, elevated, bezier_segments, split_at, trimmed,
   fit_polyline, interpolate, interpolate_periodic y los tests correspondientes.
   NurbsCurve = { nDegree, aKnots, aCtrl, aWeights } (indices NC_*). Option -> NIL.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION NC_New( nDegree, aCtrl, aKnots, aWeights )
   LOCAL nExpected, i, lOk
   IF nDegree == 0 .OR. Len( aCtrl ) <= nDegree
      RETURN NIL
   ENDIF
   nExpected := Len( aCtrl ) + nDegree + 1
   IF Len( aKnots ) != nExpected
      aKnots := Spl_ClampedUniformKnots( nDegree, Len( aCtrl ) )
   ENDIF
   lOk := ValType( aWeights ) == "A" .AND. Len( aWeights ) == Len( aCtrl )
   IF lOk
      FOR i := 1 TO Len( aWeights )
         IF ! ( aWeights[ i ] > 0.0 ) ; lOk := .F. ; EXIT ; ENDIF
      NEXT
   ENDIF
   IF ! lOk
      aWeights := Array( Len( aCtrl ) )
      AFill( aWeights, 1.0 )
   ENDIF
RETURN { nDegree, aKnots, aCtrl, aWeights }

FUNCTION NC_NewStrict( nDegree, aCtrl, aKnots, aWeights )
   LOCAL i
   IF nDegree == 0 .OR. Len( aCtrl ) <= nDegree .OR. Len( aKnots ) != Len( aCtrl ) + nDegree + 1 .OR. Len( aWeights ) != Len( aCtrl )
      RETURN NIL
   ENDIF
   FOR i := 1 TO Len( aKnots )
      IF ! OCX_ISFINITE( aKnots[ i ] ) ; RETURN NIL ; ENDIF
      IF i > 1 .AND. aKnots[ i - 1 ] > aKnots[ i ] ; RETURN NIL ; ENDIF
   NEXT
   IF aKnots[ 1 ] >= aKnots[ Len( aKnots ) ] ; RETURN NIL ; ENDIF
   FOR i := 1 TO Len( aCtrl )
      IF ! OCX_ISFINITE( aCtrl[ i ][ 1 ] ) .OR. ! OCX_ISFINITE( aCtrl[ i ][ 2 ] ) ; RETURN NIL ; ENDIF
   NEXT
   FOR i := 1 TO Len( aWeights )
      IF ! OCX_ISFINITE( aWeights[ i ] ) .OR. ! ( aWeights[ i ] > 0.0 ) ; RETURN NIL ; ENDIF
   NEXT
RETURN { nDegree, aKnots, aCtrl, aWeights }

FUNCTION NC_Degree( c )        ; RETURN c[ NC_DEGREE ]
FUNCTION NC_ControlPoints( c ) ; RETURN c[ NC_CTRL ]
FUNCTION NC_Knots( c )         ; RETURN c[ NC_KNOTS ]
FUNCTION NC_Weights( c )       ; RETURN c[ NC_WEIGHTS ]

FUNCTION NC_IsRational( c )
   LOCAL nFirst := c[ NC_WEIGHTS ][ 1 ], i
   FOR i := 1 TO Len( c[ NC_WEIGHTS ] )
      IF Abs( c[ NC_WEIGHTS ][ i ] - nFirst ) > 0.000000000001 ; RETURN .T. ; ENDIF
   NEXT
RETURN .F.

// (start, end) como array { start, end }
FUNCTION NC_Domain( c )
RETURN { c[ NC_KNOTS ][ c[ NC_DEGREE ] + 1 ], c[ NC_KNOTS ][ Len( c[ NC_CTRL ] ) + 1 ] }

STATIC FUNCTION NC_Homog( c, nIndex0 )
   LOCAL p := c[ NC_CTRL ][ nIndex0 + 1 ], w := c[ NC_WEIGHTS ][ nIndex0 + 1 ]
RETURN { p[ 1 ] * w, p[ 2 ] * w, w }

FUNCTION NC_PointAtKnot( c, u )
   LOCAL aD := NC_Domain( c ), r
   LOCAL bPt := {| i | NC_Homog( c, i ) }
   r := Spl_DeBoorBy( c[ NC_DEGREE ], c[ NC_KNOTS ], Len( c[ NC_CTRL ] ), Max( aD[ 1 ], Min( aD[ 2 ], u ) ), bPt, 3 )
   IF Abs( r[ 3 ] ) < 0.000000000000001
      RETURN { r[ 1 ], r[ 2 ] }
   ENDIF
RETURN { r[ 1 ] / r[ 3 ], r[ 2 ] / r[ 3 ] }

STATIC FUNCTION ArrSlice( a, nFrom0, nToExcl0 )   // &a[from..to]
   LOCAL r := {}, i
   FOR i := nFrom0 TO nToExcl0 - 1 ; AAdd( r, a[ i + 1 ] ) ; NEXT
RETURN r

STATIC FUNCTION NC_SlopePoint( c, i )
   LOCAL nDeg := c[ NC_DEGREE ], aKn := c[ NC_KNOTS ], nSpan, nScale, aB, aA
   nSpan := aKn[ i + nDeg + 1 + 1 ] - aKn[ i + 1 + 1 ]
   nScale := IIF( Abs( nSpan ) < 0.000000000000001, 0.0, nDeg / nSpan )
   aB := NC_Homog( c, i ) ; aA := NC_Homog( c, i + 1 )
RETURN { ( aA[ 1 ] - aB[ 1 ] ) * nScale, ( aA[ 2 ] - aB[ 2 ] ) * nScale, ( aA[ 3 ] - aB[ 3 ] ) * nScale }

FUNCTION NC_DerivativeAtKnot( c, u )
   LOCAL aD, nDeg := c[ NC_DEGREE ], aValue, aSlope, aKn := c[ NC_KNOTS ], aPt
   IF nDeg == 0
      RETURN { 0.0, 0.0 }
   ENDIF
   aD := NC_Domain( c )
   u := Max( aD[ 1 ], Min( aD[ 2 ], u ) )
   aValue := Spl_DeBoorBy( nDeg, aKn, Len( c[ NC_CTRL ] ), u, {| i | NC_Homog( c, i ) }, 3 )
   aSlope := Spl_DeBoorBy( nDeg - 1, ArrSlice( aKn, 1, Len( aKn ) - 1 ), Len( c[ NC_CTRL ] ) - 1, u, {| i | NC_SlopePoint( c, i ) }, 3 )
   IF Abs( aValue[ 3 ] ) < 0.000000000000001
      RETURN { aSlope[ 1 ], aSlope[ 2 ] }
   ENDIF
   aPt := { aValue[ 1 ] / aValue[ 3 ], aValue[ 2 ] / aValue[ 3 ] }
RETURN { ( aSlope[ 1 ] - aPt[ 1 ] * aSlope[ 3 ] ) / aValue[ 3 ], ( aSlope[ 2 ] - aPt[ 2 ] * aSlope[ 3 ] ) / aValue[ 3 ] }

FUNCTION NC_DerivativeAt( c, t )
   LOCAL aD := NC_Domain( c ), nW := aD[ 2 ] - aD[ 1 ], aS
   aS := NC_DerivativeAtKnot( c, aD[ 1 ] + Max( 0.0, Min( 1.0, t ) ) * nW )
RETURN { aS[ 1 ] * nW, aS[ 2 ] * nW }

FUNCTION NC_PointAt( c, t )
   LOCAL aD := NC_Domain( c )
RETURN NC_PointAtKnot( c, aD[ 1 ] + Max( 0.0, Min( 1.0, t ) ) * ( aD[ 2 ] - aD[ 1 ] ) )

FUNCTION NC_IsClosed( c )
RETURN V2_Distance( NC_PointAt( c, 0.0 ), NC_PointAt( c, 1.0 ) ) < 0.000000001

STATIC FUNCTION NC_DistAt( c, aPoint, t )
RETURN V2_DistanceSquared( NC_PointAt( c, t ), aPoint )

STATIC FUNCTION NC_Narrow( c, aPoint, nLow, nHigh )
   LOCAL nBest := ( nLow + nHigh ) * 0.5, i, nThird, nLeft, nRight
   FOR i := 1 TO 60
      IF nHigh - nLow < 0.000000000000001 ; EXIT ; ENDIF
      nThird := ( nHigh - nLow ) / 3.0
      nLeft := nLow + nThird ; nRight := nHigh - nThird
      IF NC_DistAt( c, aPoint, nLeft ) < NC_DistAt( c, aPoint, nRight )
         nHigh := nRight
      ELSE
         nLow := nLeft
      ENDIF
      nBest := ( nLow + nHigh ) * 0.5
   NEXT
RETURN Max( 0.0, Min( 1.0, nBest ) )

STATIC FUNCTION NC_Around( aS, nCoarse, lClosed, i, lBack )
   // i en base 0; aS base 1
   IF lBack
      IF i == 0
         RETURN IIF( lClosed, aS[ nCoarse - 1 + 1 ], OCX_INF() )
      ENDIF
      RETURN aS[ i - 1 + 1 ]
   ENDIF
   IF i == nCoarse
      RETURN IIF( lClosed, aS[ 1 + 1 ], OCX_INF() )
   ENDIF
RETURN aS[ i + 1 + 1 ]

FUNCTION NC_ParameterAt( c, aPoint )
   LOCAL nCoarse := Max( Len( c[ NC_CTRL ] ) * 8, 64 ), aS := {}, i, nStep, lClosed
   LOCAL aMin := {}, aBr := {}, t, nBestT, nBestD, nCand, nD, k
   FOR i := 0 TO nCoarse
      AAdd( aS, NC_DistAt( c, aPoint, i / nCoarse ) )
   NEXT
   nStep := 1.0 / nCoarse
   lClosed := NC_IsClosed( c )
   FOR i := 0 TO nCoarse
      IF aS[ i + 1 ] <= NC_Around( aS, nCoarse, lClosed, i, .T. ) .AND. aS[ i + 1 ] <= NC_Around( aS, nCoarse, lClosed, i, .F. )
         AAdd( aMin, { i, aS[ i + 1 ] } )
      ENDIF
   NEXT
   // sort estable por distancia (sort_by + total_cmp)
   ASort( aMin,,, {| a, b | a[ 2 ] < b[ 2 ] .OR. ( a[ 2 ] == b[ 2 ] .AND. a[ 1 ] < b[ 1 ] ) } )
   IF Len( aMin ) > 4 ; ASize( aMin, 4 ) ; ENDIF
   FOR k := 1 TO Len( aMin )
      i := aMin[ k ][ 1 ]
      t := i * nStep
      AAdd( aBr, { Max( t - nStep, 0.0 ), Min( t + nStep, 1.0 ) } )
      IF lClosed .AND. i == 0
         AAdd( aBr, { 1.0 - nStep, 1.0 } )
      ELSEIF lClosed .AND. i == nCoarse
         AAdd( aBr, { 0.0, nStep } )
      ENDIF
   NEXT
   nBestT := 0.0 ; nBestD := NIL
   FOR k := 1 TO Len( aBr )
      nCand := NC_Narrow( c, aPoint, aBr[ k ][ 1 ], aBr[ k ][ 2 ] )
      nD := NC_DistAt( c, aPoint, nCand )
      IF nBestD == NIL .OR. nD < nBestD       // min_by: gana el primero en empate
         nBestD := nD ; nBestT := nCand
      ENDIF
   NEXT
RETURN nBestT

FUNCTION NC_Tessellate( c, nPerSpan )
   LOCAL aD := NC_Domain( c ), aVals := {}, i, aOut := {}, f, nStep, aKn := c[ NC_KNOTS ], u
   nPerSpan := Max( nPerSpan, 1 )
   FOR i := c[ NC_DEGREE ] TO Len( c[ NC_CTRL ] )
      u := aKn[ i + 1 ]
      IF u >= aD[ 1 ] .AND. u <= aD[ 2 ]
         IF Len( aVals ) == 0 .OR. Abs( ATail( aVals ) - u ) >= 0.000000000001   // dedup_by
            AAdd( aVals, u )
         ENDIF
      ENDIF
   NEXT
   IF Len( aVals ) < 2
      aVals := { aD[ 1 ], aD[ 2 ] }
   ENDIF
   FOR i := 1 TO Len( aVals ) - 1
      FOR nStep := 0 TO nPerSpan - 1
         f := nStep / nPerSpan
         AAdd( aOut, NC_PointAtKnot( c, aVals[ i ] + f * ( aVals[ i + 1 ] - aVals[ i ] ) ) )
      NEXT
   NEXT
   AAdd( aOut, NC_PointAtKnot( c, aD[ 2 ] ) )
RETURN aOut
