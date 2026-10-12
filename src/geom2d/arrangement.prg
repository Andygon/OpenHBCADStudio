/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/arrangement.prg
   Origen Rust: opencadkernel/src/geom2d/arrangement.rs (897 lineas, 18 tests en t_arrangement.prg)
   Line = { aStart, aEnd }; TaggedLine = { Line, nTag }.
   SegmentCrossing = { SX_NONE } | { SX_POINT, a, b } | { SX_OVERLAP, { a0, a1 }, { b0, b1 } }
   Hashes de Rust -> hashes de Harbour con claves de texto "i,j". Orden de caras: determinista
   (vertices por indice, vecinos por angulo), igual que Rust.
----------------------------------------------------------------------------*/
#include "ocx.ch"
#define PARALLEL_EPS 0.000000000001
#define AREA_EPS     0.0000000001

FUNCTION SignedArea( aRing )
   LOCAL aOrigin, nTotal := 0.0, i, a, b
   IF Len( aRing ) < 3 ; RETURN 0.0 ; ENDIF
   aOrigin := { aRing[1][1], aRing[1][2] }
   FOR i := 2 TO Len( aRing ) - 1
      a := V2_Sub( { aRing[i][1], aRing[i][2] }, aOrigin )
      b := V2_Sub( { aRing[i+1][1], aRing[i+1][2] }, aOrigin )
      nTotal += V2_Cross( a, b )
   NEXT
RETURN nTotal * 0.5

FUNCTION Ar_SegmentCrossing( a, b, nTol )
   LOCAL aS := a[1], aE := a[2], bS := b[1], bE := b[2], alongA := V2_Sub( aE, aS ), alongB := V2_Sub( bE, bS )
   LOCAL aSq := V2_LengthSquared( alongA ), bSq := V2_LengthSquared( alongB ), aLen, bLen, nTurn, aOff, nFrom, nTo, nLow, nHigh
   LOCAL nBLow, nBHigh, t, u, tSl, uSl
   IF aSq <= OCX_EPSILON() .OR. bSq <= OCX_EPSILON() ; RETURN { SX_NONE } ; ENDIF
   aLen := Sqrt( aSq ) ; bLen := Sqrt( bSq )
   nTurn := V2_Cross( alongA, alongB )
   aOff := V2_Sub( bS, aS )
   IF Abs( nTurn ) <= PARALLEL_EPS * aLen * bLen
      IF Abs( V2_Cross( aOff, alongA ) ) > nTol * aLen ; RETURN { SX_NONE } ; ENDIF
      nFrom := V2_Dot( aOff, alongA ) / aSq
      nTo := nFrom + V2_Dot( alongB, alongA ) / aSq
      nLow := Max( Min( nFrom, nTo ), 0.0 )
      nHigh := Min( Max( nFrom, nTo ), 1.0 )
      IF nHigh < nLow - nTol / aLen ; RETURN { SX_NONE } ; ENDIF
      nLow := Max( 0.0, Min( 1.0, nLow ) ) ; nHigh := Max( 0.0, Min( 1.0, nHigh ) )
      nBLow := V2_Dot( V2_Sub( V2_Lerp( aS, aE, nLow ), bS ), alongB ) / bSq
      nBHigh := V2_Dot( V2_Sub( V2_Lerp( aS, aE, nHigh ), bS ), alongB ) / bSq
      IF ( nHigh - nLow ) * aLen <= nTol
         RETURN { SX_POINT, ( nLow + nHigh ) * 0.5, ( nBLow + nBHigh ) * 0.5 }
      ENDIF
      RETURN { SX_OVERLAP, { nLow, nHigh }, { nBLow, nBHigh } }
   ENDIF
   t := V2_Cross( aOff, alongB ) / nTurn
   u := V2_Cross( aOff, alongA ) / nTurn
   tSl := nTol / aLen ; uSl := nTol / bLen
   IF t >= -tSl .AND. t <= 1.0 + tSl .AND. u >= -uSl .AND. u <= 1.0 + uSl
      RETURN { SX_POINT, t, u }
   ENDIF
RETURN { SX_NONE }

// ---- bounds: { minx, miny, maxx, maxy } ----
STATIC FUNCTION Ar_BoundsOf( l )
RETURN { Min( l[1][1], l[2][1] ), Min( l[1][2], l[2][2] ), Max( l[1][1], l[2][1] ), Max( l[1][2], l[2][2] ) }

STATIC FUNCTION Ar_Overlaps( a, b, nSlack )
RETURN a[3] + nSlack >= b[1] .AND. b[3] + nSlack >= a[1] .AND. a[4] + nSlack >= b[2] .AND. b[4] + nSlack >= a[2]

STATIC FUNCTION Ar_SweepOnY( aBounds, nTol )
RETURN Ar_Congestion( aBounds, nTol, .F. ) > Ar_Congestion( aBounds, nTol, .T. )

STATIC FUNCTION Ar_Congestion( aBounds, nTol, lVert )
   LOCAL nLow := OCX_INF(), nHigh := -OCX_INF(), b, nMin, nMax, nExtent, nTotal := 0.0
   FOR EACH b IN aBounds
      IF lVert ; nMin := b[2] ; nMax := b[4] ; ELSE ; nMin := b[1] ; nMax := b[3] ; ENDIF
      nLow := Min( nLow, nMin ) ; nHigh := Max( nHigh, nMax )
   NEXT
   nExtent := nHigh - nLow
   IF ! OCX_ISFINITE( nExtent ) .OR. nExtent <= nTol ; RETURN OCX_INF() ; ENDIF
   FOR EACH b IN aBounds
      IF lVert ; nTotal += ( b[4] - b[2] ) + nTol ; ELSE ; nTotal += ( b[3] - b[1] ) + nTol ; ENDIF
   NEXT
RETURN nTotal / nExtent

// -> array de { Line, nTag }; lTagged distingue las dos variantes de Rust
STATIC FUNCTION Ar_Split( aLines, aTags, nTol, lTagged )
   LOCAL aBounds := {}, l, lVert, aOrder := {}, i, aCuts := {}, aActive, aNew, idx, nFront, o, aCr, aPieces := {}
   LOCAL nIdx, aPar, aS, aE, nLen, nMerge, aP, k, a, b, x
   FOR EACH l IN aLines ; AAdd( aBounds, Ar_BoundsOf( l ) ) ; NEXT
   lVert := Ar_SweepOnY( aBounds, nTol )
   FOR i := 1 TO Len( aLines )
      AAdd( aOrder, { IIf( lVert, aBounds[i][2], aBounds[i][1] ), i } )
      AAdd( aCuts, { 0.0, 1.0 } )
   NEXT
   ASort( aOrder,,, {| p, q | p[1] < q[1] .OR. ( p[1] == q[1] .AND. p[2] < q[2] ) } )
   aActive := {}
   FOR EACH x IN aOrder
      idx := x[2] ; nFront := x[1]
      aNew := {}
      FOR EACH o IN aActive
         IF IIf( lVert, aBounds[o][4], aBounds[o][3] ) + nTol >= nFront ; AAdd( aNew, o ) ; ENDIF
      NEXT
      aActive := aNew
      FOR EACH o IN aActive
         IF ! Ar_Overlaps( aBounds[idx], aBounds[o], nTol ) ; LOOP ; ENDIF
         aCr := Ar_SegmentCrossing( aLines[idx], aLines[o], nTol )
         DO CASE
         CASE aCr[1] == SX_POINT
            AAdd( aCuts[idx], Max( 0.0, Min( 1.0, aCr[2] ) ) )
            AAdd( aCuts[o], Max( 0.0, Min( 1.0, aCr[3] ) ) )
         CASE aCr[1] == SX_OVERLAP
            FOR EACH k IN aCr[2] ; AAdd( aCuts[idx], Max( 0.0, Min( 1.0, k ) ) ) ; NEXT
            FOR EACH k IN aCr[3] ; AAdd( aCuts[o], Max( 0.0, Min( 1.0, k ) ) ) ; NEXT
         ENDCASE
      NEXT
      AAdd( aActive, idx )
   NEXT
   FOR nIdx := 1 TO Len( aLines )
      aS := aLines[nIdx][1] ; aE := aLines[nIdx][2]
      nLen := V2_Distance( aS, aE )
      IF nLen <= nTol ; LOOP ; ENDIF
      nMerge := Min( nTol / nLen, 1.0 )
      aPar := ASort( aCuts[nIdx] )
      aP := {}
      FOR EACH k IN aPar
         IF Len( aP ) == 0 .OR. ! ( Abs( k - ATail( aP ) ) <= nMerge ) ; AAdd( aP, k ) ; ENDIF
      NEXT
      FOR i := 1 TO Len( aP ) - 1
         IF ! lTagged .AND. ( aP[ i + 1 ] - aP[ i ] ) * nLen <= nTol ; LOOP ; ENDIF
         a := V2_Lerp( aS, aE, aP[i] ) ; b := V2_Lerp( aS, aE, aP[ i + 1 ] )
         IF V2_Distance( a, b ) > nTol
            AAdd( aPieces, { { a, b }, IIf( lTagged, aTags[ nIdx ], NIL ) } )
         ENDIF
      NEXT
   NEXT
RETURN aPieces

// ---- weld ----
STATIC FUNCTION Ar_Key2( a, b ) ; RETURN hb_ntos( a ) + "," + hb_ntos( b )

STATIC FUNCTION Ar_WeldPoint( p, aVerts, hBuckets, nTol )
   LOCAL nCx := OCX_FLOOR( p[1] / nTol ), nCy := OCX_FLOOR( p[2] / nTol ), dx, dy, aIdx, i, cKey, nIndex
   FOR dx := -1 TO 1
      FOR dy := -1 TO 1
         cKey := Ar_Key2( nCx + dx, nCy + dy )
         IF hb_HHasKey( hBuckets, cKey )
            aIdx := hBuckets[ cKey ]
            FOR EACH i IN aIdx
               IF V2_Distance( aVerts[ i ], p ) <= nTol ; RETURN i ; ENDIF
            NEXT
         ENDIF
      NEXT
   NEXT
   AAdd( aVerts, p )
   nIndex := Len( aVerts )
   cKey := Ar_Key2( nCx, nCy )
   IF ! hb_HHasKey( hBuckets, cKey ) ; hBuckets[ cKey ] := {} ; ENDIF
   AAdd( hBuckets[ cKey ], nIndex )
RETURN nIndex

// grafo = { aVerts, aNeighbours, aEdgeKeys(array {a,b}), hEdgeTag }; indices de vertice base 1 dentro
STATIC FUNCTION Ar_Weld( aPieces, nTol, lTagged )
   LOCAL aVerts := {}, hB := { => }, hE := { => }, aEdges := {}, pc, a, b, cK, aNb, i, e, lst, o, j, tmp, aSorted, nOrd
   FOR EACH pc IN aPieces
      a := Ar_WeldPoint( pc[1][1], aVerts, hB, nTol )
      b := Ar_WeldPoint( pc[1][2], aVerts, hB, nTol )
      IF a != b
         cK := Ar_Key2( Min( a, b ), Max( a, b ) )
         IF ! hb_HHasKey( hE, cK )
            hE[ cK ] := pc[2]
            AAdd( aEdges, { Min( a, b ), Max( a, b ) } )
         ENDIF
      ENDIF
   NEXT
   aNb := Array( Len( aVerts ) )
   FOR i := 1 TO Len( aVerts ) ; aNb[i] := {} ; NEXT
   FOR EACH e IN aEdges
      AAdd( aNb[ e[1] ], e[2] ) ; AAdd( aNb[ e[2] ], e[1] )
   NEXT
   FOR i := 1 TO Len( aNb )
      o := aVerts[ i ] ; lst := aNb[ i ]
      // insercion estable por angulo
      FOR j := 2 TO Len( lst )
         tmp := lst[j] ; nOrd := j - 1
         DO WHILE nOrd >= 1 .AND. V2_Angle( V2_Sub( aVerts[ lst[ nOrd ] ], o ) ) > V2_Angle( V2_Sub( aVerts[ tmp ], o ) )
            lst[ nOrd + 1 ] := lst[ nOrd ] ; nOrd--
         ENDDO
         lst[ nOrd + 1 ] := tmp
      NEXT
      aSorted := {}
      FOR EACH j IN lst
         IF Len( aSorted ) == 0 .OR. ATail( aSorted ) != j ; AAdd( aSorted, j ) ; ENDIF
      NEXT
      aNb[ i ] := aSorted
   NEXT
   HB_SYMBOL_UNUSED( lTagged )
RETURN { aVerts, aNb, aEdges, hE }

// -> array de anillos; cada anillo es array de vertices (si lEdges: array de TaggedLine)
STATIC FUNCTION Ar_Trace( g, lEdges )
   LOCAL aVerts := g[1], aNb := g[2], nEdgeCount := Len( g[3] ), hE := g[4], hW := { => }, aFaces := {}
   LOCAL nLimit, from, to, aStart, aCur, aRing, lClosed, k, tail, head, aAround, nInc, nNext, aPts, r, nTag
   IF nEdgeCount == 0 .AND. ! lEdges ; RETURN {} ; ENDIF
   nLimit := nEdgeCount * 2 + 1
   FOR from := 1 TO Len( aVerts )
      FOR EACH to IN aNb[ from ]
         IF hb_HHasKey( hW, Ar_Key2( from, to ) ) ; LOOP ; ENDIF
         aStart := { from, to } ; aCur := { from, to } ; aRing := {} ; lClosed := .F.
         FOR k := 1 TO nLimit
            IF hb_HHasKey( hW, Ar_Key2( aCur[1], aCur[2] ) ) ; EXIT ; ENDIF
            hW[ Ar_Key2( aCur[1], aCur[2] ) ] := .T.
            tail := aCur[1] ; head := aCur[2]
            IF lEdges
               nTag := hE[ Ar_Key2( Min( tail, head ), Max( tail, head ) ) ]
               AAdd( aRing, { { aVerts[ tail ], aVerts[ head ] }, nTag } )
            ELSE
               AAdd( aRing, aVerts[ tail ] )
            ENDIF
            aAround := aNb[ head ]
            nInc := AScan( aAround, {| n | n == tail } )
            IF nInc == 0 ; EXIT ; ENDIF
            nNext := aAround[ IIf( nInc == 1, Len( aAround ), nInc - 1 ) ]
            aCur := { head, nNext }
            IF aCur[1] == aStart[1] .AND. aCur[2] == aStart[2]
               lClosed := .T. ; EXIT
            ENDIF
         NEXT
         IF lEdges
            aPts := {}
            FOR EACH r IN aRing ; AAdd( aPts, r[1][1] ) ; NEXT
         ELSE
            aPts := aRing
         ENDIF
         IF lClosed .AND. Len( aPts ) >= 3 .AND. SignedArea( aPts ) > AREA_EPS
            AAdd( aFaces, aRing )
         ENDIF
      NEXT
   NEXT
RETURN aFaces

FUNCTION Ar_BoundedFaces( aSegments, nTol )
   LOCAL aPieces, g
   IF Len( aSegments ) == 0 ; RETURN {} ; ENDIF
   aPieces := Ar_Split( aSegments, NIL, nTol, .F. )
   g := Ar_Weld( aPieces, nTol, .F. )
RETURN Ar_Trace( g, .F. )

// aTagged = array de { Line, nTag }
FUNCTION Ar_BoundedFaceEdges( aTagged, nTol )
   LOCAL aLines := {}, aTags := {}, t, aPieces, g
   IF Len( aTagged ) == 0 ; RETURN {} ; ENDIF
   FOR EACH t IN aTagged
      AAdd( aLines, t[1] ) ; AAdd( aTags, t[2] )
   NEXT
   aPieces := Ar_Split( aLines, aTags, nTol, .T. )
   g := Ar_Weld( aPieces, nTol, .T. )
RETURN Ar_Trace( g, .T. )
