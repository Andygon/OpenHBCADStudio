/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/band.prg
   Origen Rust: opencadkernel/src/geom2d/band.rs (502 lineas; el original NO tiene tests)
   BandBoundaryEdge/BandStationPiece = { aPoints{p0,p1}, nSourceSegment, aSourceDist{a,b}, aSegDist{a,b} }
   PolylineBandBoundary = { aEdges, aStationPieces, nSourceLength }
   SourceEdge igual que BandStationPiece. Rail = { aPoints, aTags, nSourceSegment }.
   Tags base 0 como en Rust (+1 solo al indexar). Ancho: aWidths = array de {w0,w1}.
----------------------------------------------------------------------------*/
#include "ocx.ch"
#define BE_POINTS 1
#define BE_SEG    2
#define BE_SRCD   3
#define BE_SEGD   4
#define RL_POINTS 1
#define RL_TAGS   2
#define RL_SEG    3

FUNCTION Bd_PolylineBandBoundary( pl, aWidths, nMaxAngle )
   LOCAL nCount := Len( pl[ PL_VERTS ] ), nSegCount, w, aW, aSampled, aSrcEdges, aPieces, nSrcLen, aRails, aLeft, aRight
   LOCAL aRaw, aCleaned, aEdges := {}, aStation := {}, e, be, lOk := .F.
   nSegCount := IIf( pl[ PL_CLOSED ], nCount, Max( nCount - 1, 0 ) )
   IF nCount < 2 .OR. Len( aWidths ) != nSegCount ; RETURN { {}, {}, 0.0 } ; ENDIF
   FOR EACH aW IN aWidths
      FOR EACH w IN aW
         IF ! OCX_ISFINITE( w ) .OR. w < 0.0 ; RETURN { {}, {}, 0.0 } ; ENDIF
         IF w > 0.000000000001 ; lOk := .T. ; ENDIF
      NEXT
   NEXT
   IF ! lOk ; RETURN { {}, {}, 0.0 } ; ENDIF

   aSampled := Bd_SampledSource( pl, nMaxAngle )
   aSrcEdges := aSampled[1] ; aPieces := aSampled[2] ; nSrcLen := aSampled[3]
   aRails := Bd_Rails( pl, aWidths, aSrcEdges, aPieces )
   aLeft := aRails[1] ; aRight := aRails[2]
   IF Len( aLeft ) == 0 ; RETURN { {}, {}, 0.0 } ; ENDIF
   Bd_JoinRails( pl, aLeft, aWidths, nSegCount, 1.0 )
   Bd_JoinRails( pl, aRight, aWidths, nSegCount, -1.0 )

   aRaw := Bd_RailChain( aLeft, pl[ PL_CLOSED ], .F. )
   FOR EACH e IN Bd_RailChain( aRight, pl[ PL_CLOSED ], .T. ) ; AAdd( aRaw, e ) ; NEXT
   IF ! pl[ PL_CLOSED ]
      IF Len( ATail( aLeft )[ RL_POINTS ] ) > 0 .AND. Len( ATail( aRight )[ RL_POINTS ] ) > 0 .AND. Len( ATail( aLeft )[ RL_TAGS ] ) > 0
         AAdd( aRaw, Bd_Tagged( ATail( ATail( aLeft )[ RL_POINTS ] ), ATail( ATail( aRight )[ RL_POINTS ] ), ATail( ATail( aLeft )[ RL_TAGS ] ) ) )
      ENDIF
      IF Len( aLeft[1][ RL_POINTS ] ) > 0 .AND. Len( aRight[1][ RL_POINTS ] ) > 0 .AND. Len( aLeft[1][ RL_TAGS ] ) > 0
         AAdd( aRaw, Bd_Tagged( aRight[1][ RL_POINTS ][1], aLeft[1][ RL_POINTS ][1], aLeft[1][ RL_TAGS ][1] ) )
      ENDIF
   ENDIF
   w := 0.0
   FOR EACH aW IN aWidths
      FOR EACH e IN aW ; w := Max( w, e ) ; NEXT
   NEXT
   aCleaned := Bd_CleanBoundary( aRaw, pl[ PL_VERTS ][1][ PV_POS ], w )
   FOR EACH e IN aCleaned
      be := Bd_BoundaryEdge( e, aSrcEdges )
      IF be != NIL ; AAdd( aEdges, be ) ; ENDIF
   NEXT
   FOR EACH e IN aSrcEdges ; AAdd( aStation, e ) ; NEXT
RETURN { aEdges, aStation, nSrcLen }

STATIC FUNCTION Bd_SampledSource( pl, nMaxAngle )
   LOCAL nCount := Len( pl[ PL_VERTS ] ), nSegCount := IIf( pl[ PL_CLOSED ], nCount, Max( nCount - 1, 0 ) )
   LOCAL aEdges := {}, aPieces := Array( nSegCount ), nDist := 0.0, i, aStart, aEnd, arc, aSamples, nLen, nPc, p, nLs, nLe, nTag
   FOR i := 1 TO nSegCount ; aPieces[i] := {} ; NEXT
   FOR i := 0 TO nSegCount - 1
      aStart := pl[ PL_VERTS ][ i + 1 ][ PV_POS ]
      aEnd := pl[ PL_VERTS ][ ( ( i + 1 ) % nCount ) + 1 ][ PV_POS ]
      arc := PL_SegmentArc( pl, i )
      IF arc != NIL
         aSamples := BA_TessellateAngle( arc, nMaxAngle )
         nLen := arc[ BA_RADIUS ] * Abs( arc[ BA_SWEEP ] )
      ELSE
         aSamples := { aStart, aEnd }
         nLen := OCX_HYPOT( aEnd[1] - aStart[1], aEnd[2] - aStart[2] )
      ENDIF
      nPc := Max( Len( aSamples ) - 1, 0 )
      FOR p := 0 TO nPc - 1
         nLs := nLen * p / nPc
         nLe := nLen * ( p + 1 ) / nPc
         nTag := Len( aEdges )
         AAdd( aEdges, { { aSamples[ p + 1 ], aSamples[ p + 2 ] }, i, { nDist + nLs, nDist + nLe }, { nLs, nLe } } )
         AAdd( aPieces[ i + 1 ], nTag )
      NEXT
      nDist += nLen
   NEXT
RETURN { aEdges, aPieces, nDist }

STATIC FUNCTION Bd_Rails( pl, aWidths, aSrcEdges, aPieces )
   LOCAL aLeft := {}, aRight := {}, i, aTags, nLast, nLen, aLP, aRP, p, nTag, edge
   FOR i := 0 TO Len( aPieces ) - 1
      aTags := aPieces[ i + 1 ]
      IF Len( aTags ) == 0 ; LOOP ; ENDIF
      nLast := ATail( aTags )
      nLen := aSrcEdges[ nLast + 1 ][ BE_SEGD ][2]
      aLP := {} ; aRP := {}
      FOR p := 0 TO Len( aTags ) - 1
         nTag := aTags[ p + 1 ]
         edge := aSrcEdges[ nTag + 1 ]
         IF p == 0
            Bd_PushRailPoint( pl, i, aWidths[ i + 1 ], nLen, edge[ BE_POINTS ][1], edge[ BE_SEGD ][1], aLP, aRP )
         ENDIF
         Bd_PushRailPoint( pl, i, aWidths[ i + 1 ], nLen, edge[ BE_POINTS ][2], edge[ BE_SEGD ][2], aLP, aRP )
      NEXT
      IF Len( aLP ) >= 2
         AAdd( aLeft, { aLP, AClone( aTags ), i } )
         AAdd( aRight, { aRP, AClone( aTags ), i } )
      ENDIF
   NEXT
RETURN { aLeft, aRight }

STATIC FUNCTION Bd_PushRailPoint( pl, nSeg, aW, nSegLen, aPt, nStation, aLeft, aRight )
   LOCAL nCount := Len( pl[ PL_VERTS ] ), aStart := pl[ PL_VERTS ][ nSeg + 1 ][ PV_POS ]
   LOCAL aEnd := pl[ PL_VERTS ][ ( ( nSeg + 1 ) % nCount ) + 1 ][ PV_POS ], aTan, nLen, t, nHalf, aNorm
   aTan := Bd_SegmentTangent( PL_SegmentArc( pl, nSeg ), aStart, aEnd, aPt )
   nLen := OCX_HYPOT( aTan[1], aTan[2] )
   IF nLen <= 0.000000000001 ; RETURN NIL ; ENDIF
   t := IIf( nSegLen > 0.000000000001, nStation / nSegLen, 0.0 )
   nHalf := ( aW[1] + ( aW[2] - aW[1] ) * t ) * 0.5
   aNorm := { -aTan[2] / nLen, aTan[1] / nLen }
   AAdd( aLeft, { aPt[1] + aNorm[1] * nHalf, aPt[2] + aNorm[2] * nHalf } )
   AAdd( aRight, { aPt[1] - aNorm[1] * nHalf, aPt[2] - aNorm[2] * nHalf } )
RETURN NIL

STATIC FUNCTION Bd_JoinRails( pl, aRails, aWidths, nSegCount, nSide )
   LOCAL nJoin := IIf( pl[ PL_CLOSED ], Len( aRails ), Max( Len( aRails ) - 1, 0 ) ), i, nNext, nSeg, nNextSeg, nW, nNW, aCorner
   FOR i := 0 TO nJoin - 1
      nNext := ( i + 1 ) % Len( aRails )
      nSeg := aRails[ i + 1 ][ RL_SEG ] ; nNextSeg := aRails[ nNext + 1 ][ RL_SEG ]
      IF nNextSeg != ( nSeg + 1 ) % nSegCount ; LOOP ; ENDIF
      nW := aWidths[ nSeg + 1 ][2] ; nNW := aWidths[ nNextSeg + 1 ][1]
      IF Abs( nW - nNW ) > 0.000000001 * Max( Max( nW, nNW ), 1.0 ) ; LOOP ; ENDIF
      aCorner := Bd_RailIntersection( pl, aWidths, aRails[ i + 1 ], aRails[ nNext + 1 ], nSide )
      IF aCorner == NIL ; LOOP ; ENDIF
      aRails[ i + 1 ][ RL_POINTS ][ Len( aRails[ i + 1 ][ RL_POINTS ] ) ] := aCorner
      aRails[ nNext + 1 ][ RL_POINTS ][1] := aCorner
   NEXT
RETURN NIL

STATIC FUNCTION Bd_RailIntersection( pl, aWidths, prev, next, nSide )
   LOCAL d, e, p0, q0, r
   d := Bd_RailTangent( pl, aWidths[ prev[ RL_SEG ] + 1 ], prev[ RL_SEG ], .T., nSide )
   IF d == NIL ; RETURN NIL ; ENDIF
   e := Bd_RailTangent( pl, aWidths[ next[ RL_SEG ] + 1 ], next[ RL_SEG ], .F., nSide )
   IF e == NIL ; RETURN NIL ; ENDIF
   p0 := ATail( prev[ RL_POINTS ] ) ; q0 := next[ RL_POINTS ][1]
   r := Ix_LineLine( p0, d, q0, e )
   IF r == NIL ; RETURN NIL ; ENDIF
RETURN { p0[1] + r[1] * d[1], p0[2] + r[1] * d[2] }

STATIC FUNCTION Bd_RailTangent( pl, aW, nSeg, lAtEnd, nSide )
   LOCAL nCount := Len( pl[ PL_VERTS ] ), aStart := pl[ PL_VERTS ][ nSeg + 1 ][ PV_POS ]
   LOCAL aEnd := pl[ PL_VERTS ][ ( ( nSeg + 1 ) % nCount ) + 1 ][ PV_POS ], aPt := IIf( lAtEnd, aEnd, aStart )
   LOCAL arc := PL_SegmentArc( pl, nSeg ), aTan, nTL, aUnit, aNorm, nLen, nHalf, nGrad, nCurv, nAlong
   aTan := Bd_SegmentTangent( arc, aStart, aEnd, aPt )
   nTL := OCX_HYPOT( aTan[1], aTan[2] )
   IF nTL <= 0.000000000001 ; RETURN NIL ; ENDIF
   aUnit := { aTan[1] / nTL, aTan[2] / nTL }
   aNorm := { -aUnit[2], aUnit[1] }
   IF arc == NIL
      nLen := OCX_HYPOT( aEnd[1] - aStart[1], aEnd[2] - aStart[2] )
   ELSE
      nLen := arc[ BA_RADIUS ] * Abs( arc[ BA_SWEEP ] )
   ENDIF
   IF nLen <= 0.000000000001 ; RETURN NIL ; ENDIF
   nHalf := aW[ IIf( lAtEnd, 2, 1 ) ] * 0.5
   nGrad := ( aW[2] - aW[1] ) * 0.5 / nLen
   nCurv := IIf( arc == NIL, 0.0, OCX_SIGNUM( arc[ BA_SWEEP ] ) / arc[ BA_RADIUS ] )
   nAlong := 1.0 - nSide * nHalf * nCurv
RETURN { nAlong * aUnit[1] + nSide * nGrad * aNorm[1], nAlong * aUnit[2] + nSide * nGrad * aNorm[2] }

STATIC FUNCTION Bd_RailChain( aRails, lClosed, lReverse )
   LOCAL aOrder := {}, i, aEdges := {}, pos, rail, ed, lHasNext, next, s, e, nTag
   IF lReverse
      FOR i := Len( aRails ) TO 1 STEP -1 ; AAdd( aOrder, i ) ; NEXT
   ELSE
      FOR i := 1 TO Len( aRails ) ; AAdd( aOrder, i ) ; NEXT
   ENDIF
   FOR pos := 1 TO Len( aOrder )
      rail := aRails[ aOrder[ pos ] ]
      IF lReverse
         FOR ed := Len( rail[ RL_TAGS ] ) - 1 TO 0 STEP -1
            AAdd( aEdges, Bd_Tagged( rail[ RL_POINTS ][ ed + 2 ], rail[ RL_POINTS ][ ed + 1 ], rail[ RL_TAGS ][ ed + 1 ] ) )
         NEXT
      ELSE
         FOR ed := 0 TO Len( rail[ RL_TAGS ] ) - 1
            AAdd( aEdges, Bd_Tagged( rail[ RL_POINTS ][ ed + 1 ], rail[ RL_POINTS ][ ed + 2 ], rail[ RL_TAGS ][ ed + 1 ] ) )
         NEXT
      ENDIF
      lHasNext := pos < Len( aOrder ) .OR. lClosed
      IF lHasNext
         next := aRails[ aOrder[ ( pos % Len( aOrder ) ) + 1 ] ]
         IF lReverse
            s := rail[ RL_POINTS ][1] ; e := ATail( next[ RL_POINTS ] ) ; nTag := rail[ RL_TAGS ][1]
         ELSE
            s := ATail( rail[ RL_POINTS ] ) ; e := next[ RL_POINTS ][1] ; nTag := ATail( rail[ RL_TAGS ] )
         ENDIF
         AAdd( aEdges, Bd_Tagged( s, e, nTag ) )
      ENDIF
   NEXT
RETURN aEdges

STATIC FUNCTION Bd_Tagged( aStart, aEnd, nTag )
RETURN { { aStart, aEnd }, nTag }

STATIC FUNCTION Bd_Num( v )
   IF v == 0.0 ; v := 0.0 ; ENDIF
RETURN LTrim( Str( v, 40, 17 ) )

STATIC FUNCTION Bd_EdgeKey( l )
   LOCAL a := Bd_Num( l[1][1] ) + "," + Bd_Num( l[1][2] ), b := Bd_Num( l[2][1] ) + "," + Bd_Num( l[2][2] )
RETURN IIf( a < b, a + "|" + b, b + "|" + a )

STATIC FUNCTION Bd_CleanBoundary( aEdges, aOrigin, nScale )
   LOCAL aLocal := {}, e, aFaces, hCounts := { => }, cK, aOutside := {}, aRes := {}, ed, ring, aV
   FOR EACH e IN aEdges
      AAdd( aLocal, Bd_Tagged( { ( e[1][1][1] - aOrigin[1] ) / nScale, ( e[1][1][2] - aOrigin[2] ) / nScale }, ;
                                 { ( e[1][2][1] - aOrigin[1] ) / nScale, ( e[1][2][2] - aOrigin[2] ) / nScale }, e[2] ) )
   NEXT
   aFaces := Ar_BoundedFaceEdges( aLocal, 0.00000001 )
   FOR EACH ring IN aFaces
      FOR EACH ed IN ring
         cK := Bd_EdgeKey( ed[1] )
         IF hb_HHasKey( hCounts, cK )
            hCounts[ cK ][2]++
         ELSE
            hCounts[ cK ] := { ed, 1 }
         ENDIF
      NEXT
   NEXT
   FOR EACH aV IN hb_HValues( hCounts )
      IF aV[2] == 1 ; AAdd( aOutside, aV[1] ) ; ENDIF
   NEXT
   FOR EACH ring IN Ar_BoundedFaceEdges( aOutside, 0.00000001 )
      FOR EACH ed IN ring
         AAdd( aRes, Bd_Tagged( { aOrigin[1] + ed[1][1][1] * nScale, aOrigin[2] + ed[1][1][2] * nScale }, ;
                                { aOrigin[1] + ed[1][2][1] * nScale, aOrigin[2] + ed[1][2][2] * nScale }, ed[2] ) )
      NEXT
   NEXT
RETURN aRes

STATIC FUNCTION Bd_BoundaryEdge( edge, aSrcEdges )
   LOCAL src, t, a, b
   IF edge[2] >= Len( aSrcEdges ) ; RETURN NIL ; ENDIF
   src := aSrcEdges[ edge[2] + 1 ]
   t := Bd_PointSegParam( edge[1][1], src[ BE_POINTS ] )
   a := { Bd_Lerp( src[ BE_SRCD ], t ), Bd_Lerp( src[ BE_SEGD ], t ) }
   t := Bd_PointSegParam( edge[1][2], src[ BE_POINTS ] )
   b := { Bd_Lerp( src[ BE_SRCD ], t ), Bd_Lerp( src[ BE_SEGD ], t ) }
RETURN { { edge[1][1], edge[1][2] }, src[ BE_SEG ], { a[1], b[1] }, { a[2], b[2] } }

STATIC FUNCTION Bd_PointSegParam( p, seg )
   LOCAL along := { seg[2][1] - seg[1][1], seg[2][2] - seg[1][2] }, nLsq := along[1] * along[1] + along[2] * along[2]
   IF nLsq <= OCX_EPSILON() ; RETURN 0.0 ; ENDIF
RETURN Max( 0.0, Min( 1.0, ( ( p[1] - seg[1][1] ) * along[1] + ( p[2] - seg[1][2] ) * along[2] ) / nLsq ) )

STATIC FUNCTION Bd_Lerp( r, t )
RETURN r[1] + ( r[2] - r[1] ) * t

STATIC FUNCTION Bd_SegmentTangent( arc, aStart, aEnd, aPt )
   LOCAL nSign
   IF arc != NIL
      nSign := OCX_SIGNUM( arc[ BA_SWEEP ] )
      RETURN { -( aPt[2] - arc[ BA_CENTER ][2] ) * nSign, ( aPt[1] - arc[ BA_CENTER ][1] ) * nSign }
   ENDIF
RETURN { aEnd[1] - aStart[1], aEnd[2] - aStart[2] }
