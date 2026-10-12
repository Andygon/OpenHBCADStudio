/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/nurbs.prg
   Origen Rust: opencadkernel/src/geom2d/nurbs.rs (1619 lineas)
   Estado: COMPLETO (tests de parameter_at ya portados en t_nurbs). Traducido: new, new_strict, accesores, is_rational, domain,
   point_at_knot, derivative_at_knot, derivative_at, point_at, parameter_at,
   tessellate, is_closed.
   + insert_knot, reversed, elevated, bezier_segments, split_at, trimmed, span_containing
   + interpolate, interpolate_periodic, fit_polyline (simplify_polyline, rounded_polyline).
   (tests en tests/t_nurbs_edit.prg).
   Pendiente: fit_polyline, interpolate, interpolate_periodic y sus tests.
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

// ---- edicion: insert_knot / reversed / elevated / split / trim ----------------
// Index of the knot span holding u (base 0, como Rust)
STATIC FUNCTION NC_SpanContaining( c, u )
   LOCAL nLast := Len( c[ NC_CTRL ] ) - 1, nLow := c[ NC_DEGREE ], nHigh := nLast + 1, nMid
   IF u >= c[ NC_KNOTS ][ nLast + 1 + 1 ] ; RETURN nLast ; ENDIF
   DO WHILE nHigh - nLow > 1
      nMid := Int( ( nLow + nHigh ) / 2 )
      IF u < c[ NC_KNOTS ][ nMid + 1 ]
         nHigh := nMid
      ELSE
         nLow := nMid
      ENDIF
   ENDDO
RETURN nLow

// Modifica c en sitio (como &mut self)
FUNCTION NC_InsertKnot( c, u )
   LOCAL aD := NC_Domain( c ), nSpan, nDeg := c[ NC_DEGREE ], aH := {}, i, aUpd := {}, nLower, nUpper, nAlpha, aKn, aNewKn, hp, hi
   IF u <= aD[ 1 ] .OR. u >= aD[ 2 ] ; RETURN NIL ; ENDIF
   nSpan := NC_SpanContaining( c, u )
   FOR i := 0 TO Len( c[ NC_CTRL ] ) - 1 ; AAdd( aH, NC_Homog( c, i ) ) ; NEXT
   FOR i := 0 TO nSpan - nDeg ; AAdd( aUpd, aH[ i + 1 ] ) ; NEXT
   aKn := c[ NC_KNOTS ]
   FOR i := nSpan - nDeg + 1 TO nSpan
      nLower := aKn[ i + 1 ] ; nUpper := aKn[ i + nDeg + 1 ]
      nAlpha := IIF( Abs( nUpper - nLower ) < 0.000000000000001, 0.0, ( u - nLower ) / ( nUpper - nLower ) )
      hp := aH[ i ] ; hi := aH[ i + 1 ]
      AAdd( aUpd, { ( 1.0 - nAlpha ) * hp[1] + nAlpha * hi[1], ( 1.0 - nAlpha ) * hp[2] + nAlpha * hi[2], ( 1.0 - nAlpha ) * hp[3] + nAlpha * hi[3] } )
   NEXT
   FOR i := nSpan TO Len( aH ) - 1 ; AAdd( aUpd, aH[ i + 1 ] ) ; NEXT
   aNewKn := {}
   FOR i := 1 TO Len( aKn )
      IF i == nSpan + 2 ; AAdd( aNewKn, u ) ; ENDIF
      AAdd( aNewKn, aKn[ i ] )
   NEXT
   IF nSpan + 2 > Len( aKn ) ; AAdd( aNewKn, u ) ; ENDIF
   c[ NC_KNOTS ] := aNewKn
   c[ NC_CTRL ] := {}
   c[ NC_WEIGHTS ] := {}
   FOR EACH hi IN aUpd
      IF Abs( hi[3] ) < 0.000000000000001
         AAdd( c[ NC_CTRL ], { hi[1], hi[2] } )
      ELSE
         AAdd( c[ NC_CTRL ], { hi[1] / hi[3], hi[2] / hi[3] } )
      ENDIF
      AAdd( c[ NC_WEIGHTS ], hi[3] )
   NEXT
RETURN NIL

STATIC FUNCTION NC_Clone( c )
RETURN { c[ NC_DEGREE ], AClone( c[ NC_KNOTS ] ), AClone( c[ NC_CTRL ] ), AClone( c[ NC_WEIGHTS ] ) }

FUNCTION NC_Reversed( c )
   LOCAL aKn := c[ NC_KNOTS ], nTotal := aKn[ 1 ] + aKn[ Len( aKn ) ], aK := {}, aP := {}, aW := {}, i
   FOR i := Len( aKn ) TO 1 STEP -1 ; AAdd( aK, nTotal - aKn[ i ] ) ; NEXT
   FOR i := Len( c[ NC_CTRL ] ) TO 1 STEP -1
      AAdd( aP, c[ NC_CTRL ][ i ] ) ; AAdd( aW, c[ NC_WEIGHTS ][ i ] )
   NEXT
RETURN { c[ NC_DEGREE ], aK, aP, aW }

FUNCTION NC_Elevated( c, nBy )
   LOCAL cur, i
   IF nBy == 0 ; RETURN NIL ; ENDIF
   cur := NC_ElevatedOnce( c )
   IF cur == NIL ; RETURN NIL ; ENDIF
   FOR i := 2 TO nBy
      cur := NC_ElevatedOnce( cur )
      IF cur == NIL ; RETURN NIL ; ENDIF
   NEXT
RETURN cur

STATIC FUNCTION NC_ElevatedOnce( c )
   LOCAL nDeg := c[ NC_DEGREE ], nRaised := nDeg + 1, aBz, aSegs, aBreaks, aCtrl := {}, aW := {}, aSeg, aEl, i, nAlpha, aBefore, aAfter
   LOCAL nSkip, w, aD, aKn, nAt, k, aPt
   aBz := NC_BezierSegments( c )
   aSegs := aBz[ 1 ] ; aBreaks := aBz[ 2 ]
   IF Len( aSegs ) == 0 ; RETURN NIL ; ENDIF
   FOR EACH aSeg IN aSegs
      aEl := {}
      FOR i := 0 TO nRaised
         nAlpha := i / nRaised
         aBefore := IIF( i == 0, { 0.0, 0.0, 0.0 }, aSeg[ i ] )
         aAfter := IIF( i > nDeg, { 0.0, 0.0, 0.0 }, aSeg[ i + 1 ] )
         AAdd( aEl, { aBefore[1] * nAlpha + aAfter[1] * ( 1.0 - nAlpha ), aBefore[2] * nAlpha + aAfter[2] * ( 1.0 - nAlpha ), aBefore[3] * nAlpha + aAfter[3] * ( 1.0 - nAlpha ) } )
      NEXT
      nSkip := IIF( Len( aCtrl ) > 0, 1, 0 )
      FOR i := nSkip TO Len( aEl ) - 1
         aPt := aEl[ i + 1 ]
         w := IIF( Abs( aPt[3] ) < 0.000000000000001, 1.0, aPt[3] )
         AAdd( aCtrl, { aPt[1] / w, aPt[2] / w } ) ; AAdd( aW, w )
      NEXT
   NEXT
   aD := NC_Domain( c )
   aKn := {}
   FOR i := 1 TO nRaised + 1 ; AAdd( aKn, aD[ 1 ] ) ; NEXT
   FOR EACH nAt IN aBreaks
      FOR k := 1 TO nRaised ; AAdd( aKn, nAt ) ; NEXT
   NEXT
   FOR i := 1 TO nRaised + 1 ; AAdd( aKn, aD[ 2 ] ) ; NEXT
RETURN { nRaised, aKn, aCtrl, aW }

// { aSegments(cada una array de {x,y,w}), aBreaks }
STATIC FUNCTION NC_BezierSegments( c )
   LOCAL aD := NC_Domain( c ), aWork := NC_Clone( c ), aBreaks, aSeen, nKnot, lFound, e, nCount, aSegs := {}, aH := {}, nFrom, i, nDeg
   LOCAL aSeg, j
   DO WHILE .T.
      aSeen := {}
      FOR EACH nKnot IN aWork[ NC_KNOTS ]
         IF nKnot <= aD[1] + 0.000000000001 .OR. nKnot >= aD[2] - 0.000000000001 ; LOOP ; ENDIF
         lFound := .F.
         FOR EACH e IN aSeen
            IF Abs( e[1] - nKnot ) < 0.000000000001 ; e[2]++ ; lFound := .T. ; EXIT ; ENDIF
         NEXT
         IF ! lFound ; AAdd( aSeen, { nKnot, 1 } ) ; ENDIF
      NEXT
      aBreaks := {}
      FOR EACH e IN aSeen
         IF e[2] < aWork[ NC_DEGREE ] ; AAdd( aBreaks, e[1] ) ; ENDIF
      NEXT
      IF Len( aBreaks ) == 0 ; EXIT ; ENDIF
      FOR EACH nKnot IN aBreaks
         NC_InsertKnot( aWork, nKnot )
      NEXT
   ENDDO
   aBreaks := {}
   FOR EACH nKnot IN aWork[ NC_KNOTS ]
      IF nKnot <= aD[1] + 0.000000000001 .OR. nKnot >= aD[2] - 0.000000000001 ; LOOP ; ENDIF
      IF Len( aBreaks ) == 0 .OR. Abs( ATail( aBreaks ) - nKnot ) > 0.000000000001
         AAdd( aBreaks, nKnot )
      ENDIF
   NEXT
   nDeg := aWork[ NC_DEGREE ]
   FOR i := 0 TO Len( aWork[ NC_CTRL ] ) - 1 ; AAdd( aH, NC_Homog( aWork, i ) ) ; NEXT
   nCount := Len( aH )
   nFrom := 0
   DO WHILE nFrom < nCount .AND. nFrom + nDeg < nCount + nDeg
      IF nFrom + nDeg <= nCount - 1
         aSeg := {}
         FOR j := nFrom TO nFrom + nDeg ; AAdd( aSeg, aH[ j + 1 ] ) ; NEXT
         AAdd( aSegs, aSeg )
      ENDIF
      nFrom += nDeg
   ENDDO
RETURN { aSegs, aBreaks }

FUNCTION NC_SplitAt( c, t )
   LOCAL aD := NC_Domain( c ), u, aWork, nExisting := 0, k, i, nCut := NIL, nDeg := c[ NC_DEGREE ], nLeft, aLK := {}, aRK := {}, aL, aR
   u := aD[1] + Max( 0.0, Min( 1.0, t ) ) * ( aD[2] - aD[1] )
   IF u <= aD[1] + 0.000000000001 .OR. u >= aD[2] - 0.000000000001 ; RETURN NIL ; ENDIF
   aWork := NC_Clone( c )
   FOR EACH k IN aWork[ NC_KNOTS ]
      IF Abs( k - u ) < 0.000000000001 ; nExisting++ ; ENDIF
   NEXT
   FOR i := nExisting TO nDeg - 1
      NC_InsertKnot( aWork, u )
   NEXT
   FOR i := Len( aWork[ NC_KNOTS ] ) TO 1 STEP -1
      IF Abs( aWork[ NC_KNOTS ][ i ] - u ) < 0.000000000001 ; nCut := i - 1 ; EXIT ; ENDIF
   NEXT
   IF nCut == NIL ; RETURN NIL ; ENDIF
   nLeft := nCut - nDeg + 1
   FOR i := 0 TO nCut ; AAdd( aLK, aWork[ NC_KNOTS ][ i + 1 ] ) ; NEXT
   AAdd( aLK, u )
   AAdd( aRK, u )
   FOR i := nCut - nDeg + 1 TO Len( aWork[ NC_KNOTS ] ) - 1 ; AAdd( aRK, aWork[ NC_KNOTS ][ i + 1 ] ) ; NEXT
   aL := { nDeg, aLK, ArrSlice( aWork[ NC_CTRL ], 0, nLeft ), ArrSlice( aWork[ NC_WEIGHTS ], 0, nLeft ) }
   aR := { nDeg, aRK, ArrSlice( aWork[ NC_CTRL ], nLeft - 1, Len( aWork[ NC_CTRL ] ) ), ArrSlice( aWork[ NC_WEIGHTS ], nLeft - 1, Len( aWork[ NC_WEIGHTS ] ) ) }
   IF Len( aL[ NC_CTRL ] ) > nDeg .AND. Len( aR[ NC_CTRL ] ) > nDeg
      RETURN { aL, aR }
   ENDIF
RETURN NIL

FUNCTION NC_Trimmed( c, nFrom, nTo )
   LOCAL aSp, aLeft, nLocal, r
   IF ! OCX_ISFINITE( nFrom ) .OR. ! OCX_ISFINITE( nTo ) ; RETURN NIL ; ENDIF
   nFrom := Max( 0.0, Min( 1.0, nFrom ) ) ; nTo := Max( 0.0, Min( 1.0, nTo ) )
   IF Abs( nFrom - nTo ) <= 0.000000000001 ; RETURN NIL ; ENDIF
   IF nFrom > nTo
      r := NC_Trimmed( c, nTo, nFrom )
      IF r == NIL ; RETURN NIL ; ENDIF
      RETURN NC_Reversed( r )
   ENDIF
   IF nFrom <= 0.000000000001 .AND. nTo >= 1.0 - 0.000000000001 ; RETURN NC_Clone( c ) ; ENDIF
   IF nTo < 1.0 - 0.000000000001
      aSp := NC_SplitAt( c, nTo )
      IF aSp == NIL ; RETURN NIL ; ENDIF
      aLeft := aSp[ 1 ]
   ELSE
      aLeft := NC_Clone( c )
   ENDIF
   IF nFrom <= 0.000000000001 ; RETURN aLeft ; ENDIF
   IF ! ( nTo > 0.000000000001 ) ; RETURN NIL ; ENDIF
   nLocal := nFrom / nTo
   aSp := NC_SplitAt( aLeft, nLocal )
   IF aSp == NIL ; RETURN NIL ; ENDIF
RETURN aSp[ 2 ]

// ---- interpolate (nurbs.rs ~684): spline cubico por puntos de ajuste ----
// nParam: PZ_UNIFORM / PZ_CENTRIPETAL / PZ_CHORD. aT0/aT1: tangentes o NIL.
STATIC FUNCTION NC_SolveTri( aSub, aMain, aSup, aD )   // modifica aD en sitio
   LOCAL n := Len( aD ), aS := Array( n ), i, m
   aS[1] := aSup[1] / aMain[1]
   aD[1] := aD[1] / aMain[1]
   FOR i := 2 TO n
      m := aMain[i] - aSub[i] * aS[i-1]
      aS[i] := aSup[i] / m
      aD[i] := ( aD[i] - aSub[i] * aD[i-1] ) / m
   NEXT
   FOR i := n - 1 TO 1 STEP -1
      aD[i] := aD[i] - aS[i] * aD[i+1]
   NEXT
RETURN NIL

STATIC FUNCTION NC_UsableTan( t )
   IF t == NIL ; RETURN NIL ; ENDIF
   IF t[1]*t[1] + t[2]*t[2] > 0.000000000000000001 ; RETURN t ; ENDIF
RETURN NIL

FUNCTION NC_Interpolate( aPts, aT0, aT1, nParam )
   LOCAL n := Len( aPts ), aK, aSp, i, nChord, nStep
   LOCAL aSl := { Array( n ), Array( n ) }, ax, aSub, aMain, aSup, aRhs, aCtrl, aKn, h, m0, m1, aFrom, aTo, aW
   IF n < 2 ; RETURN NIL ; ENDIF
   aK := Array( n ) ; aSp := Array( n - 1 )
   aK[1] := 0.0
   FOR i := 2 TO n
      nChord := Max( V2_Distance( aPts[i-1], aPts[i] ), 0.000000001 )
      DO CASE
      CASE nParam == PZ_UNIFORM    ; nStep := 1.0
      CASE nParam == PZ_CENTRIPETAL ; nStep := Sqrt( nChord )
      OTHERWISE                    ; nStep := nChord
      ENDCASE
      aK[i] := aK[i-1] + nStep
   NEXT
   FOR i := 1 TO n - 1
      aSp[i] := Max( aK[i+1] - aK[i], 0.000000001 )
   NEXT
   aT0 := NC_UsableTan( aT0 )
   aT1 := NC_UsableTan( aT1 )
   FOR ax := 1 TO 2
      aSub := Array( n ) ; aMain := Array( n ) ; aSup := Array( n ) ; aRhs := Array( n )
      AFill( aSub, 0.0 ) ; AFill( aMain, 0.0 ) ; AFill( aSup, 0.0 ) ; AFill( aRhs, 0.0 )
      IF aT0 != NIL
         aMain[1] := 1.0 ; aRhs[1] := aT0[ax]
      ELSE
         aMain[1] := 2.0 ; aSup[1] := 1.0
         aRhs[1] := 3.0 * ( aPts[2][ax] - aPts[1][ax] ) / aSp[1]
      ENDIF
      FOR i := 2 TO n - 1
         aSub[i] := aSp[i]
         aMain[i] := 2.0 * ( aSp[i-1] + aSp[i] )
         aSup[i] := aSp[i-1]
         aRhs[i] := 3.0 * ( aSp[i] * ( aPts[i][ax] - aPts[i-1][ax] ) / aSp[i-1] + aSp[i-1] * ( aPts[i+1][ax] - aPts[i][ax] ) / aSp[i] )
      NEXT
      IF aT1 != NIL
         aMain[n] := 1.0 ; aRhs[n] := aT1[ax]
      ELSE
         aSub[n] := 1.0 ; aMain[n] := 2.0
         aRhs[n] := 3.0 * ( aPts[n][ax] - aPts[n-1][ax] ) / aSp[n-1]
      ENDIF
      NC_SolveTri( aSub, aMain, aSup, aRhs )
      aSl[ax] := aRhs
   NEXT
   aCtrl := { aPts[1] }
   FOR i := 1 TO n - 1
      h := aSp[i] ; aFrom := aPts[i] ; aTo := aPts[i+1]
      m0 := { aSl[1][i] * h, aSl[2][i] * h }
      m1 := { aSl[1][i+1] * h, aSl[2][i+1] * h }
      AAdd( aCtrl, { aFrom[1] + m0[1] / 3.0, aFrom[2] + m0[2] / 3.0 } )
      AAdd( aCtrl, { aTo[1] - m1[1] / 3.0, aTo[2] - m1[2] / 3.0 } )
      AAdd( aCtrl, aTo )
   NEXT
   aKn := { aK[1], aK[1], aK[1], aK[1] }
   FOR i := 2 TO n - 1
      AAdd( aKn, aK[i] ) ; AAdd( aKn, aK[i] ) ; AAdd( aKn, aK[i] )
   NEXT
   AAdd( aKn, aK[n] ) ; AAdd( aKn, aK[n] ) ; AAdd( aKn, aK[n] ) ; AAdd( aKn, aK[n] )
   aW := Array( Len( aCtrl ) ) ; AFill( aW, 1.0 )
RETURN { 3, aKn, aCtrl, aW }

// ---- interpolate_periodic (nurbs.rs 801) ----
FUNCTION NC_InterpolatePeriodic( aPts, nParam )
   LOCAL r := Spl_InterpolatePeriodic( aPts, nParam ), aW
   IF r == NIL ; RETURN NIL ; ENDIF
   aW := AFill( Array( Len( r[1] ) ), 1.0 )
RETURN { 3, r[2], r[1], aW }

// ---- fit_polyline (nurbs.rs 652) ----
FUNCTION NC_FitPolyline( aPtsIn, nTol )
   LOCAL aPts := {}, p, nAllow
   IF ! OCX_ISFINITE( nTol ) .OR. nTol < 0.0 ; RETURN NIL ; ENDIF
   FOR EACH p IN aPtsIn
      IF ! OCX_ISFINITE( p[1] ) .OR. ! OCX_ISFINITE( p[2] ) ; RETURN NIL ; ENDIF
   NEXT
   FOR EACH p IN aPtsIn
      IF Len( aPts ) == 0 .OR. ! ( ATail( aPts )[1] == p[1] .AND. ATail( aPts )[2] == p[2] ) ; AAdd( aPts, p ) ; ENDIF
   NEXT
   IF Len( aPts ) < 2 ; RETURN NIL ; ENDIF
   IF nTol == 0.0 ; RETURN NC_New( 1, aPts, {}, NIL ) ; ENDIF
   nAllow := nTol * 0.5
   aPts := NC_SimplifyPolyline( aPts, nAllow )
   IF Len( aPts ) == 2 ; RETURN NC_New( 1, aPts, {}, NIL ) ; ENDIF
RETURN NC_RoundedPolyline( aPts, nAllow )

STATIC FUNCTION NC_SimplifyPolyline( aPts, nTol )
   LOCAL aKeep, aRanges, aR, nStart, nEnd, nFar, nDist, aFrom, aAlong, nSq, nPrevPar, nRev, i, nPar, nHere, aOut := {}, nIdx
   IF Len( aPts ) <= 2 .OR. nTol == 0.0 ; RETURN AClone( aPts ) ; ENDIF
   aKeep := AFill( Array( Len( aPts ) ), .F. )
   aKeep[1] := .T. ; aKeep[ Len( aPts ) ] := .T.
   aRanges := { { 0, Len( aPts ) - 1 } }
   DO WHILE Len( aRanges ) > 0
      aR := ATail( aRanges ) ; ASize( aRanges, Len( aRanges ) - 1 )
      nStart := aR[1] ; nEnd := aR[2]
      nFar := NIL ; nDist := nTol
      aFrom := aPts[ nStart + 1 ]
      aAlong := V2_Sub( aPts[ nEnd + 1 ], aFrom )
      nSq := V2_LengthSquared( aAlong )
      nPrevPar := 0.0 ; nRev := NIL
      FOR i := nStart + 1 TO nEnd - 1
         nPar := IIf( nSq > 0.0, V2_Dot( V2_Sub( aPts[ i + 1 ], aFrom ), aAlong ) / nSq, 0.0 )
         IF nPar + 0.000000000001 < nPrevPar
            nRev := i ; EXIT
         ENDIF
         nPrevPar := nPar
         nHere := V2_DistanceToSegment( aPts[ i + 1 ], aFrom, aPts[ nEnd + 1 ] )
         IF nHere > nDist
            nDist := nHere ; nFar := i
         ENDIF
      NEXT
      IF nRev == NIL .AND. nPrevPar > 1.0 + 0.000000000001
         nRev := nEnd - 1
      ENDIF
      nIdx := IIf( nRev != NIL, nRev, nFar )
      IF nIdx != NIL
         aKeep[ nIdx + 1 ] := .T.
         AAdd( aRanges, { nStart, nIdx } )
         AAdd( aRanges, { nIdx, nEnd } )
      ENDIF
   ENDDO
   FOR i := 1 TO Len( aPts )
      IF aKeep[i] ; AAdd( aOut, aPts[i] ) ; ENDIF
   NEXT
RETURN aOut

STATIC FUNCTION NC_PushLineSeg( aSegs, aFrom, aTo )
   LOCAL nLen := V2_Distance( aFrom, aTo )
   IF nLen == 0.0 ; RETURN NIL ; ENDIF
   AAdd( aSegs, { { aFrom, V2_Lerp( aFrom, aTo, 1.0 / 3.0 ), V2_Lerp( aFrom, aTo, 2.0 / 3.0 ), aTo }, nLen } )
RETURN NIL

STATIC FUNCTION NC_RoundedPolyline( aPts, nAllow )
   LOCAL aSegs := {}, aCur := aPts[1], i, aPrev, aCorner, aNext, aIn, aOut, nTrim, aEntry, aExit, aCtrl, aKnots := { 0.0, 0.0, 0.0, 0.0 }, nPar, k, aW
   FOR i := 1 TO Len( aPts ) - 2
      aPrev := aPts[i] ; aCorner := aPts[i+1] ; aNext := aPts[i+2]
      aIn := V2_Normalize( V2_Sub( aCorner, aPrev ) )
      IF aIn == NIL ; RETURN NIL ; ENDIF
      aOut := V2_Normalize( V2_Sub( aNext, aCorner ) )
      IF aOut == NIL ; RETURN NIL ; ENDIF
      nTrim := Min( Min( nAllow, V2_Distance( aPrev, aCorner ) * 0.5 ), V2_Distance( aCorner, aNext ) * 0.5 )
      aEntry := V2_Sub( aCorner, V2_Mul( aIn, nTrim ) )
      aExit := V2_Add( aCorner, V2_Mul( aOut, nTrim ) )
      NC_PushLineSeg( aSegs, aCur, aEntry )
      IF V2_Distance( aEntry, aExit ) > 0.0
         AAdd( aSegs, { { aEntry, aCorner, aCorner, aExit }, V2_Distance( aEntry, aCorner ) + V2_Distance( aCorner, aExit ) } )
      ENDIF
      aCur := aExit
   NEXT
   NC_PushLineSeg( aSegs, aCur, ATail( aPts ) )
   IF Len( aSegs ) == 0 ; RETURN NIL ; ENDIF
   aCtrl := AClone( aSegs[1][1] )
   nPar := aSegs[1][2]
   FOR i := 2 TO Len( aSegs )
      AAdd( aKnots, nPar ) ; AAdd( aKnots, nPar ) ; AAdd( aKnots, nPar )
      FOR k := 2 TO 4 ; AAdd( aCtrl, aSegs[i][1][k] ) ; NEXT
      nPar += aSegs[i][2]
   NEXT
   FOR k := 1 TO 4 ; AAdd( aKnots, nPar ) ; NEXT
   aW := AFill( Array( Len( aCtrl ) ), 1.0 )
RETURN NC_NewStrict( 3, aCtrl, aKnots, aW )
