/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/space/spline.prg
   Origen Rust: opencadkernel/src/space/spline.rs (460 lineas)
   Estado: COMPLETO (salvo que spline.rs solo tiene 5 tests, ya portados; interpolate_* se prueban via nurbs.rs y tests [extra])
   Indices de la API en BASE 0 (como Rust); los arrays de Harbour se acceden con +1.
   Los puntos "N-dimensionales" son arrays de N numeros.
----------------------------------------------------------------------------*/
#include "ocx.ch"

// de_boor_by: bPointAt( nIndex0 ) -> array de N numeros
FUNCTION Spl_DeBoorBy( nDegree, aKnots, nPointCount, u, bPointAt, nN )
   LOCAL nLast, nSpan, aWork, nStep, i, nIdx, aZero := {}
   IF nPointCount == 0
      FOR i := 1 TO nN ; AAdd( aZero, 0.0 ) ; NEXT
      RETURN aZero
   ENDIF
   IF nDegree == 0
      nIdx := 0
      FOR i := Len( aKnots ) TO 1 STEP -1          // rposition(|k| k <= u)
         IF aKnots[ i ] <= u ; nIdx := i - 1 ; EXIT ; ENDIF
      NEXT
      RETURN Eval( bPointAt, Min( nIdx, nPointCount - 1 ) )
   ENDIF
   nLast := nPointCount - 1
   nSpan := Spl_SpanOf( nDegree, aKnots, nLast, u )
   aWork := {}
   FOR nStep := 0 TO nDegree
      AAdd( aWork, AClone( Eval( bPointAt, nSpan + nStep - nDegree ) ) )
   NEXT
RETURN Spl_Blend( nDegree, aKnots, nSpan, u, aWork, nN )

STATIC FUNCTION Spl_Blend( nDegree, aKnots, nSpan, u, aW, nN )
   LOCAL nRound, nStep, nIndex, nLower, nUpper, nAlpha, aPrev, aCur, k
   FOR nRound := 1 TO nDegree
      FOR nStep := nDegree TO nRound STEP -1
         nIndex := nSpan + nStep - nDegree
         nLower := aKnots[ nIndex + 1 ]
         nUpper := aKnots[ nIndex + nDegree + 1 - nRound + 1 ]
         IF Abs( nUpper - nLower ) < 0.000000000000001
            nAlpha := 0.0
         ELSE
            nAlpha := ( u - nLower ) / ( nUpper - nLower )
         ENDIF
         aPrev := aW[ nStep ]          // working[step-1]
         aCur  := aW[ nStep + 1 ]      // working[step]
         FOR k := 1 TO nN
            aCur[ k ] := ( 1.0 - nAlpha ) * aPrev[ k ] + nAlpha * aCur[ k ]
         NEXT
      NEXT
   NEXT
RETURN aW[ nDegree + 1 ]

FUNCTION Spl_SpanOf( nDegree, aKnots, nLast, u )
   LOCAL nLow, nHigh, nMid
   IF u >= aKnots[ nLast + 1 + 1 ]
      RETURN nLast
   ENDIF
   nLow := nDegree ; nHigh := nLast + 1
   DO WHILE nHigh - nLow > 1
      nMid := Int( ( nLow + nHigh ) / 2 )
      IF u < aKnots[ nMid + 1 ]
         nHigh := nMid
      ELSE
         nLow := nMid
      ENDIF
   ENDDO
RETURN nLow

FUNCTION Spl_ClampedUniformKnots( nDegree, nCount )
   LOCAL nSpans := Max( nCount - nDegree, 0 ), aK := {}, i
   FOR i := 1 TO nDegree + 1 ; AAdd( aK, 0.0 ) ; NEXT
   FOR i := 1 TO nSpans - 1
      AAdd( aK, i / Max( nSpans, 1 ) )
   NEXT
   FOR i := 1 TO nDegree + 1 ; AAdd( aK, 1.0 ) ; NEXT
RETURN aK

// ---- Parameterization: PZ_UNIFORM / PZ_CENTRIPETAL / PZ_CHORD (ocx.ch) ----
STATIC FUNCTION Spl_Dist( a, b, nN )
   LOCAL s := 0.0, ax
   FOR ax := 1 TO nN ; s += ( a[ax] - b[ax] ) ^ 2 ; NEXT
RETURN Sqrt( s )

STATIC FUNCTION Spl_Span( nDist, nParam )
   DO CASE
   CASE nParam == PZ_UNIFORM ; RETURN 1.0
   CASE nParam == PZ_CENTRIPETAL ; RETURN Sqrt( nDist )
   ENDCASE
RETURN nDist

// solve_tridiagonal_system: aRight = array de vectores (N), se modifica en sitio. -> .T./.F. (Option<()>)
STATIC FUNCTION Spl_SolveTri( aLower, aDiag, aUpper, aRight )
   LOCAL nCount := Len( aRight ), aMU := Array( nCount ), nFirst := aDiag[1], nN := Len( aRight[1] ), ax, row, nPivot
   IF Abs( nFirst ) < 0.00000000000001 ; RETURN .F. ; ENDIF
   aMU[1] := aUpper[1] / nFirst
   FOR ax := 1 TO nN ; aRight[1][ax] := aRight[1][ax] / nFirst ; NEXT
   FOR row := 2 TO nCount
      nPivot := aDiag[row] - aLower[row] * aMU[row-1]
      IF Abs( nPivot ) < 0.00000000000001 ; RETURN .F. ; ENDIF
      aMU[row] := aUpper[row] / nPivot
      FOR ax := 1 TO nN
         aRight[row][ax] := ( aRight[row][ax] - aLower[row] * aRight[row-1][ax] ) / nPivot
      NEXT
   NEXT
   FOR row := nCount - 1 TO 1 STEP -1
      FOR ax := 1 TO nN
         aRight[row][ax] := aRight[row][ax] - aMU[row] * aRight[row+1][ax]
      NEXT
   NEXT
RETURN .T.

STATIC FUNCTION Spl_AllFinite( aVecs )
   LOCAL v, x
   FOR EACH v IN aVecs
      FOR EACH x IN v
         IF ! OCX_ISFINITE( x ) ; RETURN .F. ; ENDIF
      NEXT
   NEXT
RETURN .T.

STATIC FUNCTION Spl_Zero( nCount, nN )
   LOCAL a := Array( nCount ), i
   FOR i := 1 TO nCount ; a[i] := AFill( Array( nN ), 0.0 ) ; NEXT
RETURN a

// -> { aControls, aKnots } o NIL.  aT0/aT1: tangente o NIL
FUNCTION Spl_InterpolateOpen( aPts, aT0, aT1, nParam )
   LOCAL nCount := Len( aPts ), nN, ax, i, aSpans := {}, aLo, aDi, aUp, aSl, aCtrl := {}, aKnots := { 0.0, 0.0, 0.0, 0.0 }
   LOCAL nBefore, nAfter, nParameter := 0.0, aAfter, aBefore, s
   IF nCount < 2 ; RETURN NIL ; ENDIF
   nN := Len( aPts[1] )
   IF ! Spl_AllFinite( aPts ) ; RETURN NIL ; ENDIF
   IF aT0 != NIL .AND. ! Spl_AllFinite( { aT0 } ) ; RETURN NIL ; ENDIF
   IF aT1 != NIL .AND. ! Spl_AllFinite( { aT1 } ) ; RETURN NIL ; ENDIF
   IF aT0 != NIL
      s := 0.0 ; FOR ax := 1 TO nN ; s += aT0[ax] * aT0[ax] ; NEXT
      IF ! ( s > 0.000000000000000001 ) ; aT0 := NIL ; ENDIF
   ENDIF
   IF aT1 != NIL
      s := 0.0 ; FOR ax := 1 TO nN ; s += aT1[ax] * aT1[ax] ; NEXT
      IF ! ( s > 0.000000000000000001 ) ; aT1 := NIL ; ENDIF
   ENDIF
   FOR i := 1 TO nCount - 1
      AAdd( aSpans, Spl_Span( Max( Spl_Dist( aPts[i], aPts[i+1], nN ), 0.000000001 ), nParam ) )
   NEXT
   FOR i := 1 TO Len( aSpans )
      IF ! OCX_ISFINITE( aSpans[i] ) ; RETURN NIL ; ENDIF
   NEXT
   aLo := AFill( Array( nCount ), 0.0 ) ; aDi := AFill( Array( nCount ), 0.0 ) ; aUp := AFill( Array( nCount ), 0.0 )
   aSl := Spl_Zero( nCount, nN )
   IF aT0 != NIL
      aDi[1] := 1.0
      FOR ax := 1 TO nN ; aSl[1][ax] := aT0[ax] ; NEXT
   ELSE
      aDi[1] := 2.0 ; aUp[1] := 1.0
      FOR ax := 1 TO nN ; aSl[1][ax] := 3.0 * ( aPts[2][ax] - aPts[1][ax] ) / aSpans[1] ; NEXT
   ENDIF
   FOR i := 2 TO nCount - 1
      nBefore := aSpans[i-1] ; nAfter := aSpans[i]
      aLo[i] := nAfter ; aDi[i] := 2.0 * ( nBefore + nAfter ) ; aUp[i] := nBefore
      FOR ax := 1 TO nN
         aSl[i][ax] := 3.0 * ( nAfter * ( aPts[i][ax] - aPts[i-1][ax] ) / nBefore + nBefore * ( aPts[i+1][ax] - aPts[i][ax] ) / nAfter )
      NEXT
   NEXT
   IF aT1 != NIL
      aDi[nCount] := 1.0
      FOR ax := 1 TO nN ; aSl[nCount][ax] := aT1[ax] ; NEXT
   ELSE
      aLo[nCount] := 1.0 ; aDi[nCount] := 2.0
      FOR ax := 1 TO nN ; aSl[nCount][ax] := 3.0 * ( aPts[nCount][ax] - aPts[nCount-1][ax] ) / aSpans[nCount-1] ; NEXT
   ENDIF
   IF ! Spl_SolveTri( aLo, aDi, aUp, aSl ) ; RETURN NIL ; ENDIF
   AAdd( aCtrl, AClone( aPts[1] ) )
   FOR i := 1 TO nCount - 1
      aAfter := AClone( aPts[i] ) ; aBefore := AClone( aPts[i+1] )
      FOR ax := 1 TO nN
         aAfter[ax] += aSl[i][ax] * aSpans[i] / 3.0
         aBefore[ax] -= aSl[i+1][ax] * aSpans[i] / 3.0
      NEXT
      AAdd( aCtrl, aAfter ) ; AAdd( aCtrl, aBefore ) ; AAdd( aCtrl, AClone( aPts[i+1] ) )
      nParameter += aSpans[i]
      IF i < nCount - 1
         AAdd( aKnots, nParameter ) ; AAdd( aKnots, nParameter ) ; AAdd( aKnots, nParameter )
      ENDIF
   NEXT
   FOR i := 1 TO 4 ; AAdd( aKnots, nParameter ) ; NEXT
   IF ! Spl_AllFinite( aCtrl ) .OR. ! OCX_ISFINITE( nParameter ) ; RETURN NIL ; ENDIF
RETURN { aCtrl, aKnots }

STATIC FUNCTION Spl_SolveCyclic( aLo, aDi, aUp, nAlpha, nBeta, aRight )
   LOCAL nCount := Len( aRight ), nN := Len( aRight[1] ), nGamma := -aDi[1], aAdj := AClone( aDi ), aCor, ax, row, nDen, nFactor
   IF Abs( nGamma ) < 0.00000000000001 ; RETURN NIL ; ENDIF
   aAdj[1] -= nGamma
   aAdj[nCount] -= nAlpha * nBeta / nGamma
   IF ! Spl_SolveTri( aLo, aAdj, aUp, aRight ) ; RETURN NIL ; ENDIF
   aCor := Spl_Zero( nCount, nN )
   FOR ax := 1 TO nN ; aCor[1][ax] := nGamma ; aCor[nCount][ax] := nAlpha ; NEXT
   IF ! Spl_SolveTri( aLo, aAdj, aUp, aCor ) ; RETURN NIL ; ENDIF
   FOR ax := 1 TO nN
      nDen := 1.0 + aCor[1][ax] + nBeta * aCor[nCount][ax] / nGamma
      IF Abs( nDen ) < 0.00000000000001 ; RETURN NIL ; ENDIF
      nFactor := ( aRight[1][ax] + nBeta * aRight[nCount][ax] / nGamma ) / nDen
      FOR row := 1 TO nCount
         aRight[row][ax] := aRight[row][ax] - nFactor * aCor[row][ax]
      NEXT
   NEXT
   IF ! Spl_AllFinite( aRight ) ; RETURN NIL ; ENDIF
RETURN aRight

// -> { aControls, aKnots } o NIL
FUNCTION Spl_InterpolatePeriodic( aPtsIn, nParam )
   LOCAL aPts := AClone( aPtsIn ), nN, nCount, i, ax, aSpans := {}, aLo, aDi, aUp, aRt, nPrev, nNext, nBefore, nAfter, nAlpha, nBeta
   LOCAL aSl, aCtrl := {}, nParameter := 0.0, aBound := { 0.0 }, aAfter, aBefore, aKnots := { 0.0, 0.0, 0.0, 0.0 }, nSpan, s
   IF Len( aPts ) > 1
      nN := Len( aPts[1] ) ; s := 0.0
      FOR ax := 1 TO nN ; s += ( aPts[Len(aPts)][ax] - aPts[1][ax] ) ^ 2 ; NEXT
      IF s <= 0.000000000000000001 ; ASize( aPts, Len( aPts ) - 1 ) ; ENDIF
   ENDIF
   nCount := Len( aPts )
   IF nCount < 3 ; RETURN NIL ; ENDIF
   nN := Len( aPts[1] )
   FOR i := 1 TO nCount
      nNext := IIf( i == nCount, 1, i + 1 )
      AAdd( aSpans, Spl_Span( Max( Spl_Dist( aPts[nNext], aPts[i], nN ), 0.000000001 ), nParam ) )
   NEXT
   aLo := AFill( Array( nCount ), 0.0 ) ; aDi := AFill( Array( nCount ), 0.0 ) ; aUp := AFill( Array( nCount ), 0.0 )
   aRt := Spl_Zero( nCount, nN )
   FOR i := 1 TO nCount
      nPrev := IIf( i == 1, nCount, i - 1 ) ; nNext := IIf( i == nCount, 1, i + 1 )
      nBefore := aSpans[nPrev] ; nAfter := aSpans[i]
      aLo[i] := nAfter ; aDi[i] := 2.0 * ( nBefore + nAfter ) ; aUp[i] := nBefore
      FOR ax := 1 TO nN
         aRt[i][ax] := 3.0 * ( nAfter * ( aPts[i][ax] - aPts[nPrev][ax] ) / nBefore + nBefore * ( aPts[nNext][ax] - aPts[i][ax] ) / nAfter )
      NEXT
   NEXT
   nAlpha := aLo[1] ; nBeta := aUp[nCount]
   aLo[1] := 0.0 ; aUp[nCount] := 0.0
   aSl := Spl_SolveCyclic( aLo, aDi, aUp, nAlpha, nBeta, aRt )
   IF aSl == NIL ; RETURN NIL ; ENDIF
   AAdd( aCtrl, AClone( aPts[1] ) )
   FOR i := 1 TO nCount
      nNext := IIf( i == nCount, 1, i + 1 )
      nSpan := aSpans[i]
      aAfter := AClone( aPts[i] ) ; aBefore := AClone( aPts[nNext] )
      FOR ax := 1 TO nN
         aAfter[ax] += aSl[i][ax] * nSpan / 3.0
         aBefore[ax] -= aSl[nNext][ax] * nSpan / 3.0
      NEXT
      AAdd( aCtrl, aAfter ) ; AAdd( aCtrl, aBefore ) ; AAdd( aCtrl, AClone( aPts[nNext] ) )
      nParameter += nSpan
      AAdd( aBound, nParameter )
   NEXT
   FOR i := 2 TO nCount
      AAdd( aKnots, aBound[i] ) ; AAdd( aKnots, aBound[i] ) ; AAdd( aKnots, aBound[i] )
   NEXT
   FOR i := 1 TO 4 ; AAdd( aKnots, nParameter ) ; NEXT
RETURN { aCtrl, aKnots }
