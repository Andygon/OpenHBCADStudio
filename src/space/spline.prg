/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/space/spline.prg
   Origen Rust: opencadkernel/src/space/spline.rs (460 lineas)
   Estado: PARCIAL - traducido: de_boor_by, blend, span_of, clamped_uniform_knots.
   Pendiente: interpolate_open, interpolate_periodic, Parameterization (+ tests).
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
