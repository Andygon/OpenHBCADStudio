/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/polyline.prg
   Origen Rust: opencadkernel/src/geom2d/polyline.rs (544 lineas)
   Estado: TRADUCIDO (BulgeArc, PolylineVertex, Polyline: segment_arc,
   rectangle_frame, ranged; tests portados en tests/t_polyline.prg).
   Representacion: ver include/ocx.ch (BA_*, PV_*, PL_*). Option -> NIL.
   Indices de API publica en BASE 0 (como Rust).
----------------------------------------------------------------------------*/
#include "ocx.ch"

// ---- BulgeArc --------------------------------------------------------------
// Option<BulgeArc>
FUNCTION BA_FromBulge( p0, p1, nBulge )
   LOCAL cx := p1[1] - p0[1], cy := p1[2] - p0[2]   // chord_x/chord_y
   LOCAL nChordLen := Sqrt( cx * cx + cy * cy )
   LOCAL nSq, nRadius, nToCentre, nMidX, nMidY, nPerpX, nPerpY, nSign, aCenter
   LOCAL nStart, nEnd, nSweep
   IF nChordLen < 0.000000000001 .OR. Abs( nBulge ) < 0.000000000001
      RETURN NIL
   ENDIF
   nSq       := nBulge * nBulge
   nRadius   := nChordLen * ( 1.0 + nSq ) / ( 4.0 * Abs( nBulge ) )
   nToCentre := nRadius * ( 1.0 - nSq ) / ( 1.0 + nSq )
   nMidX := ( p0[1] + p1[1] ) * 0.5
   nMidY := ( p0[2] + p1[2] ) * 0.5
   nPerpX := -cy / nChordLen
   nPerpY := cx / nChordLen
   nSign := OCX_SIGNUM( nBulge )
   aCenter := { nMidX + nSign * nToCentre * nPerpX, nMidY + nSign * nToCentre * nPerpY }
   nStart := OCX_ATAN2( p0[2] - aCenter[2], p0[1] - aCenter[1] )
   nEnd   := OCX_ATAN2( p1[2] - aCenter[2], p1[1] - aCenter[1] )
   nSweep := nEnd - nStart
   IF nBulge > 0.0
      IF nSweep <= 0.0
         nSweep += OCX_TAU
      ENDIF
   ELSEIF nSweep >= 0.0
      nSweep -= OCX_TAU
   ENDIF
   IF Abs( nSweep ) < 0.000000001
      nSweep := IIF( nBulge > 0.0, OCX_TAU, -OCX_TAU )
   ENDIF
RETURN { aCenter, nRadius, nStart, nEnd, nSweep }

FUNCTION BA_Sample( ba, t )
   LOCAL nAngle := ba[ BA_START ] + ba[ BA_SWEEP ] * t
RETURN { ba[ BA_CENTER ][ 1 ] + ba[ BA_RADIUS ] * OCX_COS( nAngle ), ;
         ba[ BA_CENTER ][ 2 ] + ba[ BA_RADIUS ] * OCX_SIN( nAngle ) }

FUNCTION BA_TessellateAngle( ba, nMaxAngle )
   LOCAL nSegs, i, aOut := {}
   nMaxAngle := Tess_Angle( nMaxAngle )
   nSegs := Int( Max( OCX_CEIL( Abs( ba[ BA_SWEEP ] ) / nMaxAngle ), 1.0 ) )
   FOR i := 0 TO nSegs
      AAdd( aOut, BA_Sample( ba, i / nSegs ) )
   NEXT
RETURN aOut

// ---- PolylineVertex / Polyline ---------------------------------------------
FUNCTION PV_Straight( aPos )
RETURN { aPos, 0.0 }

FUNCTION PV_Curved( aPos, nBulge )
RETURN { aPos, nBulge }

FUNCTION PL_New( aVerts, lClosed )
   hb_default( @aVerts, {} ); hb_default( @lClosed, .F. )
RETURN { aVerts, lClosed }

// Option<BulgeArc>; nIndex base 0
FUNCTION PL_SegmentArc( pl, nIndex )
   LOCAL nCount := Len( pl[ PL_VERTS ] ), nNext
   IF nIndex >= nCount
      RETURN NIL
   ENDIF
   IF nIndex + 1 < nCount
      nNext := nIndex + 1
   ELSEIF pl[ PL_CLOSED ]
      nNext := 0
   ELSE
      RETURN NIL
   ENDIF
RETURN BA_FromBulge( pl[ PL_VERTS ][ nIndex + 1 ][ PV_POS ], pl[ PL_VERTS ][ nNext + 1 ][ PV_POS ], pl[ PL_VERTS ][ nIndex + 1 ][ PV_BULGE ] )

// Option<RectangleFrame> = {origin, width_axis, height_axis, width, height}
FUNCTION PL_RectangleFrame( pl, nTol )
   LOCAL aV := pl[ PL_VERTS ], aWorld := {}, aCo := {}, i, aFrame
   LOCAL wv, se, nWidth, aWAxis, aPerp, nSignedH, nHeight, aHAxis, aExp2, aExp3
   IF ! pl[ PL_CLOSED ] .OR. Len( aV ) != 4
      RETURN NIL
   ENDIF
   FOR i := 1 TO 4
      IF aV[ i ][ PV_BULGE ] != 0.0 .OR. ! OCX_ISFINITE( aV[ i ][ PV_POS ][ 1 ] ) .OR. ! OCX_ISFINITE( aV[ i ][ PV_POS ][ 2 ] )
         RETURN NIL
      ENDIF
   NEXT
   FOR i := 1 TO 4
      AAdd( aWorld, { aV[ i ][ PV_POS ][ 1 ], aV[ i ][ PV_POS ][ 2 ], 0.0 } )
   NEXT
   aFrame := Frame_Around( aWorld )
   FOR i := 1 TO 4
      AAdd( aCo, Frame_Lift2D( aFrame, { aWorld[ i ][ 1 ], aWorld[ i ][ 2 ] } ) )
   NEXT
   wv := V2_Sub( aCo[ 2 ], aCo[ 1 ] )
   se := V2_Sub( aCo[ 3 ], aCo[ 2 ] )
   nWidth := V2_Length( wv )
   IF nWidth <= nTol
      RETURN NIL
   ENDIF
   aWAxis := V2_Div( wv, nWidth )
   aPerp := V2_Perpendicular( aWAxis )
   nSignedH := V2_Dot( se, aPerp )
   nHeight := Abs( nSignedH )
   IF nHeight <= nTol
      RETURN NIL
   ENDIF
   aHAxis := V2_Mul( aPerp, OCX_SIGNUM( nSignedH ) )
   aExp2 := V2_Add( aCo[ 2 ], V2_Mul( aHAxis, nHeight ) )
   aExp3 := V2_Add( aCo[ 1 ], V2_Mul( aHAxis, nHeight ) )
   IF V2_Distance( aCo[ 3 ], aExp2 ) > nTol .OR. V2_Distance( aCo[ 4 ], aExp3 ) > nTol
      RETURN NIL
   ENDIF
RETURN { aV[ 1 ][ PV_POS ], aWAxis, aHAxis, nWidth, nHeight }

// ---- ranged ------------------------------------------------------------------
// PolylineRangeSegment = {source_index(base0), from, to}
FUNCTION PRS_Interpolate( seg, nStart, nEnd )
RETURN { ( 1.0 - seg[ 2 ] ) * nStart + seg[ 2 ] * nEnd, ( 1.0 - seg[ 3 ] ) * nStart + seg[ 3 ] * nEnd }

STATIC FUNCTION AllFinite2( a )
RETURN OCX_ISFINITE( a[ 1 ] ) .AND. OCX_ISFINITE( a[ 2 ] )

// Option<PolylineRange> = {polyline, aSegments}
FUNCTION PL_Ranged( pl, nFrom, nTo )
   LOCAL aV := pl[ PL_VERTS ], n := Len( aV ), i, nCount, nStart, nEnd, nFirst, nLast
   LOCAL aVerts := {}, aSegs := {}, aEnd := NIL, nIdx, nSrc, a, b, v, nxt, arc
   LOCAL nBulge, aPos, aFin
   IF n < 2 .OR. ! OCX_ISFINITE( nFrom ) .OR. ! OCX_ISFINITE( nTo ) .OR. nFrom < 0.0 ;
      .OR. nFrom > 1.0 .OR. nTo <= nFrom .OR. nTo > nFrom + 1.0 ;
      .OR. ( ! pl[ PL_CLOSED ] .AND. nTo > 1.0 )
      RETURN NIL
   ENDIF
   FOR i := 1 TO n
      IF ! OCX_ISFINITE( aV[ i ][ PV_BULGE ] ) .OR. ! AllFinite2( aV[ i ][ PV_POS ] )
         RETURN NIL
      ENDIF
   NEXT
   nCount := IIF( pl[ PL_CLOSED ], n, n - 1 )
   nStart := nFrom * nCount
   nEnd   := nTo * nCount
   nFirst := Int( OCX_FLOOR( nStart ) )
   nLast  := Int( OCX_CEIL( nEnd ) )
   FOR nIdx := nFirst TO nLast - 1
      nSrc := nIdx % nCount
      a := Max( nStart - nIdx, 0.0 )
      b := Min( nEnd - nIdx, 1.0 )
      IF b <= a
         LOOP
      ENDIF
      v   := aV[ nSrc + 1 ]
      nxt := aV[ ( nSrc + 1 ) % n + 1 ]
      arc := NIL
      IF Abs( v[ PV_BULGE ] ) >= 0.000000000001
         arc := BA_FromBulge( v[ PV_POS ], nxt[ PV_POS ], v[ PV_BULGE ] )
         IF ValType( arc ) == "U"
            RETURN NIL     // `?` en Rust
         ENDIF
      ENDIF
      IF a == 0.0 .AND. b == 1.0
         nBulge := v[ PV_BULGE ]
      ELSEIF ValType( arc ) == "A"
         nBulge := OCX_TAN( OCX_ATAN( v[ PV_BULGE ] ) * ( b - a ) )
      ELSE
         nBulge := 0.0
      ENDIF
      aPos := PL_RangeSample( v, nxt, arc, a )
      aFin := PL_RangeSample( v, nxt, arc, b )
      IF ! OCX_ISFINITE( nBulge ) .OR. ! AllFinite2( aPos ) .OR. ! AllFinite2( aFin )
         RETURN NIL
      ENDIF
      AAdd( aVerts, { aPos, nBulge } )
      aEnd := aFin
      AAdd( aSegs, { nSrc, a, b } )
   NEXT
   IF ValType( aEnd ) == "U"
      RETURN NIL
   ENDIF
   AAdd( aVerts, PV_Straight( aEnd ) )
RETURN { PL_New( aVerts, .F. ), aSegs }

STATIC FUNCTION PL_RangeSample( v, nxt, arc, t )
   IF t == 0.0
      RETURN v[ PV_POS ]
   ELSEIF t == 1.0
      RETURN nxt[ PV_POS ]
   ELSEIF ValType( arc ) == "A"
      RETURN BA_Sample( arc, t )
   ENDIF
RETURN { ( 1.0 - t ) * v[ PV_POS ][ 1 ] + t * nxt[ PV_POS ][ 1 ], ( 1.0 - t ) * v[ PV_POS ][ 2 ] + t * nxt[ PV_POS ][ 2 ] }
