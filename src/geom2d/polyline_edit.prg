/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/polyline_edit.prg
   Origen Rust: opencadkernel/src/geom2d/polyline_edit.rs (456 lineas)
   Estado: TRADUCIDO (tests en tests/t_polyline_edit.prg).
   Los arrays de Harbour son referencias: las funciones "&mut Polyline" de Rust
   modifican pl en sitio. Indices de segmento base 0 (+1 al acceder).
----------------------------------------------------------------------------*/
#include "ocx.ch"

#define PE_BULGE_EPS 0.000000001

STATIC FUNCTION PE_NearestLineCircle( aLP, aLD, aCC, nCR, aNear )
   LOCAL nAA := V2_Dot( aLD, aLD ), aRel, nBB, nCC, nDisc, nRoot, aFirst, aSecond
   IF nAA <= Tol_Default() ^ 2 ; RETURN NIL ; ENDIF
   aRel := V2_Sub( aLP, aCC )
   nBB := 2.0 * V2_Dot( aRel, aLD )
   nCC := V2_Dot( aRel, aRel ) - nCR * nCR
   nDisc := nBB * nBB - 4.0 * nAA * nCC
   IF nDisc < -Tol_Default() ; RETURN NIL ; ENDIF
   nRoot := Sqrt( Max( nDisc, 0.0 ) )
   aFirst := V2_Add( aLP, V2_Mul( aLD, ( -nBB - nRoot ) / ( 2.0 * nAA ) ) )
   aSecond := V2_Add( aLP, V2_Mul( aLD, ( -nBB + nRoot ) / ( 2.0 * nAA ) ) )
RETURN IIF( V2_Distance( aFirst, aNear ) <= V2_Distance( aSecond, aNear ), aFirst, aSecond )

STATIC FUNCTION PE_NearestCircleCircle( aC1, nR1, aC2, nR2, aNear )
   LOCAL aBest := NIL, p
   FOR EACH p IN Ix_CircleCirclePoints( aC1, nR1, aC2, nR2 )
      // min_by: el primero si hay empate
      IF aBest == NIL .OR. V2_Distance( p, aNear ) < V2_Distance( aBest, aNear )
         aBest := p
      ENDIF
   NEXT
RETURN aBest

STATIC FUNCTION PE_BulgeForCircleArc( aCentre, aStart, aEnd, nDirection )
   LOCAL nSA := OCX_ATAN2( aStart[2] - aCentre[2], aStart[1] - aCentre[1] )
   LOCAL nEA := OCX_ATAN2( aEnd[2] - aCentre[2], aEnd[1] - aCentre[1] ), nSweep, nBulge
   IF nDirection >= 0.0
      nSweep := OCX_REMEUCLID( nEA - nSA, OCX_TAU )
   ELSE
      nSweep := -OCX_REMEUCLID( nSA - nEA, OCX_TAU )
   ENDIF
   nBulge := OCX_TAN( nSweep * 0.25 )
   IF ! OCX_ISFINITE( nBulge ) ; RETURN NIL ; ENDIF
RETURN Max( -1000000.0, Min( 1000000.0, nBulge ) )

STATIC FUNCTION PE_Count( pl )
   IF pl[ PL_CLOSED ] ; RETURN Len( pl[ PL_VERTS ] ) ; ENDIF
RETURN Max( Len( pl[ PL_VERTS ] ) - 1, 0 )

STATIC FUNCTION PE_Pos( pl, n ) ; RETURN pl[ PL_VERTS ][ n + 1 ][ PV_POS ]
STATIC FUNCTION PE_Bulge( pl, n ) ; RETURN pl[ PL_VERTS ][ n + 1 ][ PV_BULGE ]

STATIC FUNCTION PE_SetPos( pl, n, aP ) ; pl[ PL_VERTS ][ n + 1 ][ PV_POS ] := { aP[1], aP[2] }
RETURN NIL

STATIC FUNCTION PE_SetBulge( pl, n, nB ) ; pl[ PL_VERTS ][ n + 1 ][ PV_BULGE ] := nB
RETURN NIL

FUNCTION PE_MoveSegmentParallel( pl, nSeg, nOffset )
   LOCAL nCount := PE_Count( pl ), nVC := Len( pl[ PL_VERTS ] ), nNext, aStart, aEnd, aSel, nLen, aShifted
   LOCAL aPrevB := NIL, aNewStart, nPrev, aOuter, aNb, aCen, aPt, nBulge, aNextB := NIL, aNewEnd, nOuterIdx
   IF nSeg >= nCount .OR. ! OCX_ISFINITE( nOffset ) ; RETURN .F. ; ENDIF
   nNext := ( nSeg + 1 ) % nVC
   IF Abs( PE_Bulge( pl, nSeg ) ) >= PE_BULGE_EPS ; RETURN .F. ; ENDIF
   aStart := PE_Pos( pl, nSeg ) ; aEnd := PE_Pos( pl, nNext )
   aSel := V2_Sub( aEnd, aStart ) ; nLen := V2_Length( aSel )
   IF nLen <= Tol_Default() ; RETURN .F. ; ENDIF
   aShifted := V2_Add( aStart, V2_Mul( V2_Perpendicular( aSel ), nOffset / nLen ) )

   IF pl[ PL_CLOSED ] .OR. nSeg > 0
      nPrev := ( nSeg + nVC - 1 ) % nVC
      aOuter := PE_Pos( pl, nPrev )
      aNb := PL_SegmentArc( pl, nPrev )
      IF aNb != NIL
         aCen := aNb[ BA_CENTER ]
         aPt := PE_NearestLineCircle( aShifted, aSel, aCen, aNb[ BA_RADIUS ], aStart )
         IF aPt == NIL ; RETURN .F. ; ENDIF
         nBulge := PE_BulgeForCircleArc( aCen, aOuter, aPt, OCX_SIGNUM( aNb[ BA_SWEEP ] ) )
         IF nBulge == NIL ; RETURN .F. ; ENDIF
         aPrevB := { nPrev, nBulge }
         aNewStart := aPt
      ELSE
         aPt := PE_LineInt( aShifted, aSel, nLen, aOuter, V2_Sub( aStart, aOuter ) )
         IF aPt == NIL ; RETURN .F. ; ENDIF
         aNewStart := aPt
      ENDIF
   ELSE
      aNewStart := aShifted
   ENDIF

   IF pl[ PL_CLOSED ] .OR. nSeg + 1 < nCount
      nOuterIdx := ( nNext + 1 ) % nVC
      aOuter := PE_Pos( pl, nOuterIdx )
      aNb := PL_SegmentArc( pl, nNext )
      IF aNb != NIL
         aCen := aNb[ BA_CENTER ]
         aPt := PE_NearestLineCircle( aShifted, aSel, aCen, aNb[ BA_RADIUS ], aEnd )
         IF aPt == NIL ; RETURN .F. ; ENDIF
         nBulge := PE_BulgeForCircleArc( aCen, aPt, aOuter, OCX_SIGNUM( aNb[ BA_SWEEP ] ) )
         IF nBulge == NIL ; RETURN .F. ; ENDIF
         aNextB := { nNext, nBulge }
         aNewEnd := aPt
      ELSE
         aPt := PE_LineInt( aShifted, aSel, nLen, aEnd, V2_Sub( aOuter, aEnd ) )
         IF aPt == NIL ; RETURN .F. ; ENDIF
         aNewEnd := aPt
      ENDIF
   ELSE
      aNewEnd := V2_Add( aEnd, V2_Mul( V2_Perpendicular( aSel ), nOffset / nLen ) )
   ENDIF

   PE_SetPos( pl, nSeg, aNewStart ) ; PE_SetPos( pl, nNext, aNewEnd )
   IF aPrevB != NIL ; PE_SetBulge( pl, aPrevB[1], aPrevB[2] ) ; ENDIF
   IF aNextB != NIL ; PE_SetBulge( pl, aNextB[1], aNextB[2] ) ; ENDIF
RETURN .T.

// closure line_intersection de Rust: point + direction * ((shifted - point) x selected / cross)
STATIC FUNCTION PE_LineInt( aShifted, aSel, nLen, aPoint, aDir )
   LOCAL nCross := V2_Cross( aDir, aSel )
   IF Abs( nCross ) < PE_BULGE_EPS * Max( V2_Length( aDir ), 1.0 ) * Max( nLen, 1.0 ) ; RETURN NIL ; ENDIF
RETURN V2_Add( aPoint, V2_Mul( aDir, V2_Cross( V2_Sub( aShifted, aPoint ), aSel ) / nCross ) )

STATIC FUNCTION PE_ResizeConcentric( pl, nSeg, nRadius )
   LOCAL nCount := PE_Count( pl ), nVC := Len( pl[ PL_VERTS ] ), nNext, aStart, aEnd, aArc, aCen, nLinSq
   LOCAL nSyncPrev := NIL, aPrevB := NIL, aNewStart, nPrev, aOuter, aNb, aNbC, aPt, nBulge
   LOCAL nSyncNext := NIL, aNextB := NIL, aNewEnd, nOuterIdx, nNewBulge
   IF nSeg >= nCount .OR. ! OCX_ISFINITE( nRadius ) .OR. nRadius <= Tol_Default() ; RETURN .F. ; ENDIF
   nNext := ( nSeg + 1 ) % nVC
   aStart := PE_Pos( pl, nSeg ) ; aEnd := PE_Pos( pl, nNext )
   aArc := PL_SegmentArc( pl, nSeg )
   IF aArc == NIL ; RETURN .F. ; ENDIF
   aCen := aArc[ BA_CENTER ]
   nLinSq := Tol_Default() ^ 2

   IF pl[ PL_CLOSED ] .OR. nSeg > 0
      nPrev := ( nSeg + nVC - 1 ) % nVC
      aOuter := PE_Pos( pl, nPrev )
      aNb := PL_SegmentArc( pl, nPrev )
      IF aNb != NIL
         aNbC := aNb[ BA_CENTER ]
         aPt := PE_NearestCircleCircle( aCen, nRadius, aNbC, aNb[ BA_RADIUS ], aStart )
         IF aPt == NIL ; RETURN .F. ; ENDIF
         nBulge := PE_BulgeForCircleArc( aNbC, aOuter, aPt, OCX_SIGNUM( aNb[ BA_SWEEP ] ) )
         IF nBulge == NIL ; RETURN .F. ; ENDIF
         aPrevB := { nPrev, nBulge }
         aNewStart := aPt
      ELSEIF V2_LengthSquared( V2_Sub( aStart, aOuter ) ) <= nLinSq
         nSyncPrev := nPrev
         aNewStart := V2_Add( aCen, V2_Mul( V2_Sub( aStart, aCen ), nRadius / aArc[ BA_RADIUS ] ) )
      ELSE
         aPt := PE_NearestLineCircle( aOuter, V2_Sub( aStart, aOuter ), aCen, nRadius, aStart )
         IF aPt == NIL ; RETURN .F. ; ENDIF
         aNewStart := aPt
      ENDIF
   ELSE
      aNewStart := V2_Add( aCen, V2_Mul( V2_Sub( aStart, aCen ), nRadius / aArc[ BA_RADIUS ] ) )
   ENDIF

   IF pl[ PL_CLOSED ] .OR. nSeg + 1 < nCount
      nOuterIdx := ( nNext + 1 ) % nVC
      aOuter := PE_Pos( pl, nOuterIdx )
      aNb := PL_SegmentArc( pl, nNext )
      IF aNb != NIL
         aNbC := aNb[ BA_CENTER ]
         aPt := PE_NearestCircleCircle( aCen, nRadius, aNbC, aNb[ BA_RADIUS ], aEnd )
         IF aPt == NIL ; RETURN .F. ; ENDIF
         nBulge := PE_BulgeForCircleArc( aNbC, aPt, aOuter, OCX_SIGNUM( aNb[ BA_SWEEP ] ) )
         IF nBulge == NIL ; RETURN .F. ; ENDIF
         aNextB := { nNext, nBulge }
         aNewEnd := aPt
      ELSEIF V2_LengthSquared( V2_Sub( aOuter, aEnd ) ) <= nLinSq
         nSyncNext := nOuterIdx
         aNewEnd := V2_Add( aCen, V2_Mul( V2_Sub( aEnd, aCen ), nRadius / aArc[ BA_RADIUS ] ) )
      ELSE
         aPt := PE_NearestLineCircle( aEnd, V2_Sub( aOuter, aEnd ), aCen, nRadius, aEnd )
         IF aPt == NIL ; RETURN .F. ; ENDIF
         aNewEnd := aPt
      ENDIF
   ELSE
      aNewEnd := V2_Add( aCen, V2_Mul( V2_Sub( aEnd, aCen ), nRadius / aArc[ BA_RADIUS ] ) )
   ENDIF

   nNewBulge := PE_BulgeForCircleArc( aCen, aNewStart, aNewEnd, OCX_SIGNUM( aArc[ BA_SWEEP ] ) )
   IF nNewBulge == NIL ; RETURN .F. ; ENDIF
   PE_SetPos( pl, nSeg, aNewStart ) ; PE_SetPos( pl, nNext, aNewEnd )
   IF nSyncPrev != NIL ; PE_SetPos( pl, nSyncPrev, aNewStart ) ; ENDIF
   IF nSyncNext != NIL ; PE_SetPos( pl, nSyncNext, aNewEnd ) ; ENDIF
   IF aPrevB != NIL ; PE_SetBulge( pl, aPrevB[1], aPrevB[2] ) ; ENDIF
   IF aNextB != NIL ; PE_SetBulge( pl, aNextB[1], aNextB[2] ) ; ENDIF
   PE_SetBulge( pl, nSeg, nNewBulge )
RETURN .T.

// Option<(apex, keep_start, keep_end)>
STATIC FUNCTION PE_ArcFilletFrame( pl, nSeg )
   LOCAL nCount, nVC, nNext, nPrev, nOuterIdx, aOS, aTS, aTE, aOE, aIn, aOut, aArc, aCen, nTT, nCross, aApex, a1, a2
   IF ! pl[ PL_CLOSED ] .AND. Len( pl[ PL_VERTS ] ) == 0 ; RETURN NIL ; ENDIF
   nCount := PE_Count( pl )
   IF nSeg >= nCount .OR. ( ! pl[ PL_CLOSED ] .AND. ( nSeg == 0 .OR. nSeg + 1 == nCount ) ) ; RETURN NIL ; ENDIF
   nVC := Len( pl[ PL_VERTS ] )
   nNext := ( nSeg + 1 ) % nVC
   nPrev := ( nSeg + nVC - 1 ) % nVC
   nOuterIdx := ( nNext + 1 ) % nVC
   IF Abs( PE_Bulge( pl, nPrev ) ) >= PE_BULGE_EPS .OR. Abs( PE_Bulge( pl, nNext ) ) >= PE_BULGE_EPS ; RETURN NIL ; ENDIF
   aOS := PE_Pos( pl, nPrev ) ; aTS := PE_Pos( pl, nSeg ) ; aTE := PE_Pos( pl, nNext ) ; aOE := PE_Pos( pl, nOuterIdx )
   aIn := V2_Normalize( V2_Sub( aTS, aOS ) )
   IF aIn == NIL ; RETURN NIL ; ENDIF
   aOut := V2_Normalize( V2_Sub( aOE, aTE ) )
   IF aOut == NIL ; RETURN NIL ; ENDIF
   aArc := PL_SegmentArc( pl, nSeg )
   IF aArc == NIL ; RETURN NIL ; ENDIF
   aCen := aArc[ BA_CENTER ]
   nTT := Max( aArc[ BA_RADIUS ] * 0.000001, Tol_Default() )
   IF Abs( V2_Dot( V2_Sub( aTS, aCen ), aIn ) ) > nTT .OR. Abs( V2_Dot( V2_Sub( aTE, aCen ), aOut ) ) > nTT ; RETURN NIL ; ENDIF
   nCross := V2_Cross( aIn, aOut )
   IF Abs( nCross ) <= PE_BULGE_EPS ; RETURN NIL ; ENDIF
   aApex := V2_Add( aOS, V2_Mul( aIn, V2_Cross( V2_Sub( aTE, aOS ), aOut ) / nCross ) )
   a1 := V2_Normalize( V2_Sub( aOS, aApex ) )
   IF a1 == NIL ; RETURN NIL ; ENDIF
   a2 := V2_Normalize( V2_Sub( aOE, aApex ) )
   IF a2 == NIL ; RETURN NIL ; ENDIF
RETURN { aApex, a1, a2 }

FUNCTION PE_ArcRadiusFromPoint( pl, nSeg, aPoint )
   LOCAL aArc := PL_SegmentArc( pl, nSeg ), aFr, aMid, aRay, nRadius
   IF aArc == NIL ; RETURN NIL ; ENDIF
   aFr := PE_ArcFilletFrame( pl, nSeg )
   IF aFr != NIL
      aMid := BA_Sample( aArc, 0.5 )
      aRay := V2_Sub( aMid, aFr[1] )
      nRadius := aArc[ BA_RADIUS ] * V2_Dot( V2_Sub( aPoint, aFr[1] ), aRay ) / V2_Dot( aRay, aRay )
   ELSE
      nRadius := V2_Distance( aPoint, aArc[ BA_CENTER ] )
   ENDIF
   IF nRadius > Tol_Default() ; RETURN nRadius ; ENDIF
RETURN NIL

FUNCTION PE_SegmentParallelOffset( pl, nSeg, aPoint )
   LOCAL nCount := PE_Count( pl ), aStart, aEnd, aDir, nLen
   IF nSeg >= nCount .OR. Abs( PE_Bulge( pl, nSeg ) ) >= PE_BULGE_EPS ; RETURN NIL ; ENDIF
   aStart := PE_Pos( pl, nSeg )
   aEnd := PE_Pos( pl, ( nSeg + 1 ) % Len( pl[ PL_VERTS ] ) )
   aDir := V2_Sub( aEnd, aStart ) ; nLen := V2_Length( aDir )
   IF nLen <= Tol_Default() ; RETURN NIL ; ENDIF
RETURN V2_Dot( V2_Sub( aPoint, aStart ), V2_Mul( V2_Perpendicular( aDir ), 1.0 / nLen ) )

FUNCTION PE_ResizeArc( pl, nSeg, nRadius )
   LOCAL aFr, aF, aNS, aNE, aC, aRS, aRE, nSweep, nBulge, nNext
   IF nRadius <= Tol_Default() .OR. ! OCX_ISFINITE( nRadius ) ; RETURN .F. ; ENDIF
   IF PL_SegmentArc( pl, nSeg ) == NIL ; RETURN .F. ; ENDIF
   aFr := PE_ArcFilletFrame( pl, nSeg )
   IF aFr != NIL
      aF := Fl_BetweenRays( aFr[1], aFr[2], aFr[3], nRadius )
      IF aF == NIL ; RETURN .F. ; ENDIF
      aNS := aF[ FL_T1 ] ; aNE := aF[ FL_T2 ] ; aC := aF[ FL_C ]
      aRS := V2_Normalize( V2_Sub( aNS, aC ) ) ; aRE := V2_Normalize( V2_Sub( aNE, aC ) )
      IF aRS == NIL .OR. aRE == NIL ; RETURN .F. ; ENDIF
      nSweep := OCX_ACOS( Max( -1.0, Min( 1.0, V2_Dot( aRS, aRE ) ) ) )
      nBulge := OCX_SIGNUM( PE_Bulge( pl, nSeg ) ) * OCX_TAN( nSweep * 0.25 )
      IF ! OCX_ISFINITE( nBulge ) ; RETURN .F. ; ENDIF
      nNext := ( nSeg + 1 ) % Len( pl[ PL_VERTS ] )
      PE_SetPos( pl, nSeg, aNS ) ; PE_SetPos( pl, nNext, aNE ) ; PE_SetBulge( pl, nSeg, nBulge )
      RETURN .T.
   ENDIF
RETURN PE_ResizeConcentric( pl, nSeg, nRadius )
