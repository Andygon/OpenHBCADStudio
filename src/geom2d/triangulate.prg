/* Port de opencadkernel/src/geom2d/triangulate.rs (ear clipping con puentes para huecos). UTF-8.
   Puntos = { x, y }; indices de triangulo base 0 (como Rust), +1 solo al acceder a arrays.
   Prefijo Tg_. Tolerance = numero. Option -> NIL. */
#include "ocx.ch"

// ---- RingBounds = { minx, miny, maxx, maxy } ----
STATIC FUNCTION Tg_BoundsOf( aRing )
   LOCAL b, p
   IF Len( aRing ) == 0 ; RETURN NIL ; ENDIF
   b := { aRing[1][1], aRing[1][2], aRing[1][1], aRing[1][2] }
   FOR EACH p IN aRing
      b[1] := Min( b[1], p[1] ) ; b[2] := Min( b[2], p[2] )
      b[3] := Max( b[3], p[1] ) ; b[4] := Max( b[4], p[2] )
   NEXT
RETURN b

STATIC FUNCTION Tg_Overlaps( a, b )
RETURN a[3] >= b[1] .AND. b[3] >= a[1] .AND. a[4] >= b[2] .AND. b[4] >= a[2]

STATIC FUNCTION Tg_PtEq( a, b ) ; RETURN a[1] == b[1] .AND. a[2] == b[2]
STATIC FUNCTION Tg_Turn( p, q, r ) ; RETURN V2_Cross( V2_Sub( q, p ), V2_Sub( r, p ) )

STATIC FUNCTION Tg_SignedArea( aPts )
   LOCAL o, i, nSum := 0.0
   IF Len( aPts ) < 3 ; RETURN 0.0 ; ENDIF
   o := aPts[1]
   FOR i := 1 TO Len( aPts ) - 2
      nSum += V2_Cross( V2_Sub( aPts[ i + 1 ], o ), V2_Sub( aPts[ i + 2 ], o ) )
   NEXT
RETURN nSum * 0.5

STATIC FUNCTION Tg_AnyNonFinite( aRing )
   LOCAL p
   FOR EACH p IN aRing
      IF ! OCX_ISFINITE( p[1] ) .OR. ! OCX_ISFINITE( p[2] ) ; RETURN .T. ; ENDIF
   NEXT
RETURN .F.

STATIC FUNCTION Tg_RemoveAt( a, n0 )   // n0 base 0
   ADel( a, n0 + 1 ) ; ASize( a, Len( a ) - 1 )
RETURN NIL

// ---- polygon_frame -> { origin, size, points } o NIL ----
FUNCTION Tg_SignedAreaPub( a ) ; RETURN Tg_SignedArea( a )

FUNCTION Tg_PolygonFrame( aInput, nTol )
   LOCAL aPts := {}, p, b, aSize, nScale, nArea
   IF Tg_AnyNonFinite( aInput ) ; RETURN NIL ; ENDIF
   FOR EACH p IN aInput
      IF Len( aPts ) == 0 .OR. V2_Distance( ATail( aPts ), p ) > nTol
         AAdd( aPts, p )
      ENDIF
   NEXT
   DO WHILE Len( aPts ) > 1 .AND. V2_Distance( aPts[1], ATail( aPts ) ) <= nTol
      ASize( aPts, Len( aPts ) - 1 )
   ENDDO
   b := Tg_BoundsOf( aPts )
   IF b == NIL ; RETURN NIL ; ENDIF
   aSize := { b[3] - b[1], b[4] - b[2] }
   nScale := Max( aSize[1], aSize[2] )
   nArea := Abs( Tg_SignedArea( aPts ) )
   IF aSize[1] <= nTol .OR. aSize[2] <= nTol .OR. nArea <= nTol * Max( nScale, nTol ) .OR. ! Tg_Simple( aPts, nTol )
      RETURN NIL
   ENDIF
RETURN { { b[1], b[2] }, aSize, aPts }

// ---- sanitize ----
STATIC FUNCTION Tg_Sanitize( aRing )
   LOCAL aPts := {}, p, nIdx := 0, nCount, aBefore, aHere, aAfter, aIn, aOut, nLen, nEps, nPrev
   IF Tg_AnyNonFinite( aRing ) ; RETURN {} ; ENDIF
   FOR EACH p IN aRing
      IF Len( aPts ) == 0 .OR. ! Tg_PtEq( ATail( aPts ), p )
         AAdd( aPts, p )
      ENDIF
   NEXT
   DO WHILE Len( aPts ) > 1 .AND. Tg_PtEq( aPts[1], ATail( aPts ) )
      ASize( aPts, Len( aPts ) - 1 )
   ENDDO
   DO WHILE Len( aPts ) >= 3 .AND. nIdx < Len( aPts )
      nCount := Len( aPts )
      aBefore := aPts[ ( nIdx + nCount - 1 ) % nCount + 1 ]
      aHere := aPts[ nIdx + 1 ]
      aAfter := aPts[ ( nIdx + 1 ) % nCount + 1 ]
      aIn := V2_Sub( aBefore, aHere ) ; aOut := V2_Sub( aAfter, aHere )
      nLen := Max( Max( V2_Length( aIn ), V2_Length( aOut ) ), 1.0 )
      nEps := 64.0 * OCX_EPSILON() * nLen * nLen
      IF Abs( V2_Cross( aIn, aOut ) ) > nEps .OR. V2_Dot( aIn, aOut ) <= 0.0
         nIdx++
         LOOP
      ENDIF
      Tg_RemoveAt( aPts, nIdx )
      nCount := Len( aPts )
      nPrev := ( nIdx + nCount - 1 ) % nCount
      IF nCount > 1 .AND. Tg_PtEq( aPts[ nPrev + 1 ], aPts[ nIdx % nCount + 1 ] )
         Tg_RemoveAt( aPts, nIdx % nCount )
      ENDIF
      nIdx := Max( nIdx - 1, 0 )
   ENDDO
RETURN aPts

// ---- simple ----
STATIC FUNCTION Tg_Simple( aRing, nTol )
   LOCAL n := Len( aRing ), f, s, i, aB, aH, aA, aIn, aOut, nLen, nEps, fn, sn
   IF n < 3 ; RETURN .F. ; ENDIF
   FOR f := 0 TO n - 1
      FOR s := f + 1 TO n - 1
         IF V2_Distance( aRing[ f + 1 ], aRing[ s + 1 ] ) <= nTol ; RETURN .F. ; ENDIF
      NEXT
   NEXT
   FOR i := 0 TO n - 1
      aB := aRing[ ( i + n - 1 ) % n + 1 ] ; aH := aRing[ i + 1 ] ; aA := aRing[ ( i + 1 ) % n + 1 ]
      aIn := V2_Sub( aB, aH ) ; aOut := V2_Sub( aA, aH )
      nLen := Max( Max( V2_Length( aIn ), V2_Length( aOut ) ), 1.0 )
      nEps := Max( 64.0 * OCX_EPSILON() * nLen * nLen, nTol * nLen )
      IF Abs( V2_Cross( aIn, aOut ) ) <= nEps .AND. V2_Dot( aIn, aOut ) > 0.0 ; RETURN .F. ; ENDIF
   NEXT
   FOR f := 0 TO n - 1
      fn := ( f + 1 ) % n
      FOR s := f + 1 TO n - 1
         sn := ( s + 1 ) % n
         IF fn == s .OR. sn == f ; LOOP ; ENDIF
         IF Tg_SegsIntersectTol( aRing[ f + 1 ], aRing[ fn + 1 ], aRing[ s + 1 ], aRing[ sn + 1 ], nTol ) ; RETURN .F. ; ENDIF
      NEXT
   NEXT
RETURN .T.

STATIC FUNCTION Tg_Straddle( v1, v2 )
RETURN ( v1 > 0.0 .AND. v2 < 0.0 ) .OR. ( v1 < 0.0 .AND. v2 > 0.0 )

STATIC FUNCTION Tg_SegsProperlyCross( a, b, c, d )
   LOCAL v := { Tg_Turn( a, b, c ), Tg_Turn( a, b, d ), Tg_Turn( c, d, a ), Tg_Turn( c, d, b ) }
   LOCAL nScale := Max( Max( V2_LengthSquared( V2_Sub( b, a ) ), V2_LengthSquared( V2_Sub( d, c ) ) ), 1.0 )
   LOCAL nEps := 64.0 * OCX_EPSILON() * nScale
RETURN ( ( v[1] > nEps .AND. v[2] < -nEps ) .OR. ( v[1] < -nEps .AND. v[2] > nEps ) ) .AND. ;
       ( ( v[3] > nEps .AND. v[4] < -nEps ) .OR. ( v[3] < -nEps .AND. v[4] > nEps ) )

STATIC FUNCTION Tg_On( p, q, r, nVal, nEps, nTol )
RETURN Abs( nVal ) <= nEps .AND. r[1] >= Min( p[1], q[1] ) - nTol .AND. r[1] <= Max( p[1], q[1] ) + nTol ;
       .AND. r[2] >= Min( p[2], q[2] ) - nTol .AND. r[2] <= Max( p[2], q[2] ) + nTol

STATIC FUNCTION Tg_SegsIntersectTol( a, b, c, d, nTol )
   LOCAL v := { Tg_Turn( a, b, c ), Tg_Turn( a, b, d ), Tg_Turn( c, d, a ), Tg_Turn( c, d, b ) }
   LOCAL nLen := Max( Max( V2_Length( V2_Sub( b, a ) ), V2_Length( V2_Sub( d, c ) ) ), 1.0 )
   LOCAL nEps := Max( 64.0 * OCX_EPSILON() * nLen * nLen, nTol * nLen )
   IF Tg_Straddle( v[1], v[2] ) .AND. Tg_Straddle( v[3], v[4] ) .AND. ;
      ( ( v[1] > nEps .AND. v[2] < -nEps ) .OR. ( v[1] < -nEps .AND. v[2] > nEps ) ) .AND. ;
      ( ( v[3] > nEps .AND. v[4] < -nEps ) .OR. ( v[3] < -nEps .AND. v[4] > nEps ) )
      RETURN .T.
   ENDIF
RETURN Tg_On( a, b, c, v[1], nEps, nTol ) .OR. Tg_On( a, b, d, v[2], nEps, nTol ) .OR. ;
       Tg_On( c, d, a, v[3], nEps, nTol ) .OR. Tg_On( c, d, b, v[4], nEps, nTol )

STATIC FUNCTION Tg_BoundariesIntersect( f, s )
   LOCAL a, b
   FOR a := 0 TO Len( f ) - 1
      FOR b := 0 TO Len( s ) - 1
         IF Tg_SegsIntersectTol( f[ a + 1 ], f[ ( a + 1 ) % Len( f ) + 1 ], s[ b + 1 ], s[ ( b + 1 ) % Len( s ) + 1 ], 0.0 ) ; RETURN .T. ; ENDIF
      NEXT
   NEXT
RETURN .F.

STATIC FUNCTION Tg_BoundariesCross( f, s )
   LOCAL a, b
   FOR a := 0 TO Len( f ) - 1
      FOR b := 0 TO Len( s ) - 1
         IF Tg_SegsProperlyCross( f[ a + 1 ], f[ ( a + 1 ) % Len( f ) + 1 ], s[ b + 1 ], s[ ( b + 1 ) % Len( s ) + 1 ] ) ; RETURN .T. ; ENDIF
      NEXT
   NEXT
RETURN .F.

STATIC FUNCTION Tg_RingContains( aRing, p )
   LOCAL i, n := Len( aRing ), fr, to, lIn := .F., lX
   FOR i := 0 TO n - 1
      fr := aRing[ i + 1 ] ; to := aRing[ ( i + 1 ) % n + 1 ]
      lX := ( fr[2] > p[2] ) != ( to[2] > p[2] ) .AND. p[1] < ( to[1] - fr[1] ) * ( p[2] - fr[2] ) / ( to[2] - fr[2] ) + fr[1]
      IF lX ; lIn := ! lIn ; ENDIF
   NEXT
RETURN lIn

STATIC FUNCTION Tg_PointOnSegment( s, e, p )
   LOCAL aEdge := V2_Sub( e, s ), aOff := V2_Sub( p, s )
   LOCAL nEps := 64.0 * OCX_EPSILON() * Max( V2_LengthSquared( aEdge ), 1.0 )
RETURN Abs( V2_Cross( aEdge, aOff ) ) <= nEps .AND. p[1] >= Min( s[1], e[1] ) - nEps .AND. p[1] <= Max( s[1], e[1] ) + nEps ;
       .AND. p[2] >= Min( s[2], e[2] ) - nEps .AND. p[2] <= Max( s[2], e[2] ) + nEps

STATIC FUNCTION Tg_PointOnBoundary( aRing, p )
   LOCAL i, n := Len( aRing )
   FOR i := 0 TO n - 1
      IF Tg_PointOnSegment( aRing[ i + 1 ], aRing[ ( i + 1 ) % n + 1 ], p ) ; RETURN .T. ; ENDIF
   NEXT
RETURN .F.

STATIC FUNCTION Tg_StrictlyContains( aOuter, aInner )
   LOCAL p
   FOR EACH p IN aInner
      IF ! Tg_PointOnBoundary( aOuter, p )
         RETURN Tg_RingContains( aOuter, p )
      ENDIF
   NEXT
RETURN .F.

// ---- nesting_depths ----
FUNCTION Tg_NestingDepths( aInput )
   LOCAL aRings := {}, aAreas := {}, r, i, o, aOut := {}, n
   FOR EACH r IN aInput
      AAdd( aRings, Tg_Sanitize( r ) )
      AAdd( aAreas, Abs( Tg_SignedArea( ATail( aRings ) ) ) )
   NEXT
   FOR i := 0 TO Len( aRings ) - 1
      n := 0
      FOR o := 0 TO Len( aRings ) - 1
         IF o != i .AND. aAreas[ o + 1 ] > aAreas[ i + 1 ] .AND. Tg_StrictlyContains( aRings[ o + 1 ], aRings[ i + 1 ] )
            n++
         ENDIF
      NEXT
      AAdd( aOut, n )
   NEXT
RETURN aOut

STATIC FUNCTION Tg_Interact( a, b )
   // a,b = { points, area, bounds }
RETURN Tg_Overlaps( a[3], b[3] ) .AND. ( Tg_BoundariesIntersect( a[1], b[1] ) .OR. Tg_StrictlyContains( a[1], b[1] ) .OR. Tg_StrictlyContains( b[1], a[1] ) )

STATIC FUNCTION Tg_RootOf( n, aParent )
   DO WHILE aParent[ n + 1 ] != NIL
      n := aParent[ n + 1 ]
   ENDDO
RETURN n

STATIC FUNCTION Tg_Matches( aPts, aTris, nExpected )
   LOCAL t, a, b, c, nTwice, nArea := 0.0
   IF Len( aTris ) == 0 .OR. ! OCX_ISFINITE( nExpected ) .OR. nExpected <= 0.0 ; RETURN .F. ; ENDIF
   FOR EACH t IN aTris
      IF t[1] >= Len( aPts ) .OR. t[2] >= Len( aPts ) .OR. t[3] >= Len( aPts ) ; RETURN .F. ; ENDIF
      a := aPts[ t[1] + 1 ] ; b := aPts[ t[2] + 1 ] ; c := aPts[ t[3] + 1 ]
      nTwice := V2_Cross( V2_Sub( b, a ), V2_Sub( c, a ) )
      IF ! OCX_ISFINITE( nTwice ) .OR. nTwice <= 0.0 ; RETURN .F. ; ENDIF
      nArea += nTwice * 0.5
   NEXT
RETURN Abs( nArea - nExpected ) <= Max( nExpected, 1.0 ) * 0.000000001

// ---- rings -> { points, triangles } ----
FUNCTION Tg_Rings( aInput )
   LOCAL aRings := {}, aInvalid := {}, raw, aPts, b, nArea, aBad, f, s, i, o, lChanged, aActive, aValid, aParent, aDepth
   LOCAL nBest, nD, nxt, aOutPts := {}, aOutTris := {}, nRoot, aMembers, aCompP, aCompT, lComplete, nOuter, aHoles, nExp
   LOCAL aPoly, nBase, t, h, x
   FOR EACH raw IN aInput
      aPts := Tg_Sanitize( raw )
      b := Tg_BoundsOf( aPts )
      IF b == NIL ; LOOP ; ENDIF
      nArea := Tg_SignedArea( aPts )
      IF ! Tg_Simple( aPts, 0.0 ) .OR. ! OCX_ISFINITE( nArea ) .OR. nArea == 0.0
         AAdd( aInvalid, { aPts, Abs( nArea ), b } )
         LOOP
      ENDIF
      AAdd( aRings, { aPts, Abs( nArea ), b } )
   NEXT
   aBad := Array( Len( aRings ) ) ; AFill( aBad, .F. )
   FOR f := 1 TO Len( aRings )
      FOR s := f + 1 TO Len( aRings )
         IF Tg_Overlaps( aRings[f][3], aRings[s][3] ) .AND. Tg_BoundariesCross( aRings[f][1], aRings[s][1] )
            aBad[f] := .T. ; aBad[s] := .T.
         ENDIF
      NEXT
   NEXT
   FOR i := 1 TO Len( aRings )
      FOR EACH x IN aInvalid
         IF Tg_Interact( aRings[i], x ) ; aBad[i] := .T. ; EXIT ; ENDIF
      NEXT
   NEXT
   DO WHILE .T.
      aActive := {}
      FOR i := 1 TO Len( aBad )
         IF aBad[i] ; AAdd( aActive, i ) ; ENDIF
      NEXT
      lChanged := .F.
      FOR i := 1 TO Len( aRings )
         IF ! aBad[i]
            FOR EACH o IN aActive
               IF Tg_Interact( aRings[i], aRings[o] )
                  aBad[i] := .T. ; lChanged := .T. ; EXIT
               ENDIF
            NEXT
         ENDIF
      NEXT
      IF ! lChanged ; EXIT ; ENDIF
   ENDDO
   aValid := {}
   FOR i := 1 TO Len( aRings )
      IF ! aBad[i] ; AAdd( aValid, aRings[i] ) ; ENDIF
   NEXT
   aParent := Array( Len( aValid ) ) ; AFill( aParent, NIL )
   FOR i := 0 TO Len( aValid ) - 1
      nBest := NIL
      FOR o := 0 TO Len( aValid ) - 1
         IF o != i .AND. aValid[ o + 1 ][2] > aValid[ i + 1 ][2] .AND. Tg_StrictlyContains( aValid[ o + 1 ][1], aValid[ i + 1 ][1] )
            IF nBest == NIL .OR. aValid[ o + 1 ][2] < aValid[ nBest + 1 ][2]
               nBest := o
            ENDIF
         ENDIF
      NEXT
      aParent[ i + 1 ] := nBest
   NEXT
   aDepth := Array( Len( aValid ) )
   FOR i := 0 TO Len( aValid ) - 1
      nD := 0 ; nxt := aParent[ i + 1 ]
      DO WHILE nxt != NIL
         nD++ ; nxt := aParent[ nxt + 1 ]
      ENDDO
      aDepth[ i + 1 ] := nD
   NEXT
   FOR nRoot := 0 TO Len( aValid ) - 1
      IF aParent[ nRoot + 1 ] != NIL ; LOOP ; ENDIF
      aMembers := {}
      FOR i := 0 TO Len( aValid ) - 1
         IF Tg_RootOf( i, aParent ) == nRoot ; AAdd( aMembers, i ) ; ENDIF
      NEXT
      aCompP := {} ; aCompT := {} ; lComplete := .T.
      FOR EACH nOuter IN aMembers
         IF aDepth[ nOuter + 1 ] % 2 != 0 ; LOOP ; ENDIF
         aHoles := {} ; nExp := aValid[ nOuter + 1 ][2]
         FOR EACH i IN aMembers
            IF aParent[ i + 1 ] != NIL .AND. aParent[ i + 1 ] == nOuter .AND. aDepth[ i + 1 ] % 2 == 1
               AAdd( aHoles, aValid[ i + 1 ][1] )
            ENDIF
         NEXT
         FOR EACH h IN aHoles
            nExp -= Abs( Tg_SignedArea( h ) )
         NEXT
         aPoly := Tg_Polygon( aValid[ nOuter + 1 ][1], aHoles )
         IF ! Tg_Matches( aPoly[1], aPoly[2], nExp )
            lComplete := .F. ; EXIT
         ENDIF
         nBase := Len( aCompP )
         FOR EACH x IN aPoly[1] ; AAdd( aCompP, x ) ; NEXT
         FOR EACH t IN aPoly[2] ; AAdd( aCompT, { t[1] + nBase, t[2] + nBase, t[3] + nBase } ) ; NEXT
      NEXT
      IF lComplete
         nBase := Len( aOutPts )
         FOR EACH x IN aCompP ; AAdd( aOutPts, x ) ; NEXT
         FOR EACH t IN aCompT ; AAdd( aOutTris, { t[1] + nBase, t[2] + nBase, t[3] + nBase } ) ; NEXT
      ENDIF
   NEXT
RETURN { aOutPts, aOutTris }

// ---- polygon -> { points, triangles } ----
STATIC FUNCTION Tg_Orient( aRing, lCcw )
   LOCAL aPts := AClone( aRing ), i, n, tmp
   IF Len( aPts ) > 1 .AND. Tg_PtEq( aPts[1], ATail( aPts ) ) ; ASize( aPts, Len( aPts ) - 1 ) ; ENDIF
   IF ( Tg_SignedArea( aPts ) > 0.0 ) != lCcw
      n := Len( aPts )
      FOR i := 1 TO Int( n / 2 )
         tmp := aPts[i] ; aPts[i] := aPts[ n - i + 1 ] ; aPts[ n - i + 1 ] := tmp
      NEXT
   ENDIF
RETURN aPts

STATIC FUNCTION Tg_Rightmost( aRing )   // -> { idx0, point }
   LOCAL nBest := 0, i
   FOR i := 1 TO Len( aRing ) - 1
      IF aRing[ i + 1 ][1] > aRing[ nBest + 1 ][1] ; nBest := i ; ENDIF
   NEXT
RETURN { nBest, aRing[ nBest + 1 ] }

FUNCTION Tg_Polygon( aOuter, aHoles )
   LOCAL aPts := Tg_Orient( aOuter, .T. ), aRing := {}, i, aPending := {}, h, aTris, o
   IF Len( aPts ) < 3 ; RETURN { {}, {} } ; ENDIF
   FOR i := 0 TO Len( aPts ) - 1 ; AAdd( aRing, i ) ; NEXT
   FOR EACH h IN aHoles
      o := Tg_Orient( h, .F. )
      IF Len( o ) >= 3 ; AAdd( aPending, o ) ; ENDIF
   NEXT
   // orden estable por x del punto mas a la derecha, de mayor a menor
   aPending := Tg_StableSortDesc( aPending )
   FOR EACH h IN aPending
      aRing := Tg_Bridge( aPts, aRing, h )
   NEXT
   aTris := Tg_ClipEars( aPts, aRing )
RETURN { aPts, aTris }

STATIC FUNCTION Tg_StableSortDesc( aList )
   LOCAL i, j, tmp, n := Len( aList )
   FOR i := 2 TO n     // insercion (estable)
      tmp := aList[i] ; j := i - 1
      DO WHILE j >= 1 .AND. Tg_Rightmost( aList[j] )[2][1] < Tg_Rightmost( tmp )[2][1]
         aList[ j + 1 ] := aList[j] ; j--
      ENDDO
      aList[ j + 1 ] := tmp
   NEXT
RETURN aList

STATIC FUNCTION Tg_Bridge( aPts, aRing, aHole )
   LOCAL aR := Tg_Rightmost( aHole ), nStart := aR[1], aFrom := aR[2], nAt, nBase, aSp := {}, i, nH := Len( aHole )
   nAt := Tg_BridgeTarget( aPts, aRing, aFrom )
   IF nAt == NIL ; RETURN aRing ; ENDIF
   nBase := Len( aPts )
   FOR i := 1 TO nH ; AAdd( aPts, aHole[i] ) ; NEXT
   FOR i := 0 TO nAt ; AAdd( aSp, aRing[ i + 1 ] ) ; NEXT
   FOR i := 0 TO nH - 1 ; AAdd( aSp, nBase + ( nStart + i ) % nH ) ; NEXT
   AAdd( aSp, nBase + nStart )
   AAdd( aSp, aRing[ nAt + 1 ] )
   FOR i := nAt + 1 TO Len( aRing ) - 1 ; AAdd( aSp, aRing[ i + 1 ] ) ; NEXT
RETURN aSp

STATIC FUNCTION Tg_BridgeTarget( aPts, aRing, aFrom )
   LOCAL nCount := Len( aRing ), nNearest := OCX_INF(), aHit := NIL, i, nxt, a, b, nAlong, x, aCross, nIdx
   FOR i := 0 TO nCount - 1
      nxt := ( i + 1 ) % nCount
      a := aPts[ aRing[ i + 1 ] + 1 ] ; b := aPts[ aRing[ nxt + 1 ] + 1 ]
      IF ( a[2] > aFrom[2] ) == ( b[2] > aFrom[2] ) ; LOOP ; ENDIF
      nAlong := ( aFrom[2] - a[2] ) / ( b[2] - a[2] )
      x := a[1] + ( b[1] - a[1] ) * nAlong
      IF x >= aFrom[1] .AND. x < nNearest
         nNearest := x ; aHit := { i, nxt }
      ENDIF
   NEXT
   IF aHit == NIL ; RETURN NIL ; ENDIF
   aCross := { nNearest, aFrom[2] }
   IF Tg_PtEq( aPts[ aRing[ aHit[1] + 1 ] + 1 ], aCross ) ; RETURN aHit[1] ; ENDIF
   IF Tg_PtEq( aPts[ aRing[ aHit[2] + 1 ] + 1 ], aCross ) ; RETURN aHit[2] ; ENDIF
   nIdx := Len( aPts )
   AAdd( aPts, aCross )
   ASize( aRing, Len( aRing ) + 1 )
   AIns( aRing, aHit[1] + 2 )
   aRing[ aHit[1] + 2 ] := nIdx
RETURN aHit[1] + 1

STATIC FUNCTION Tg_EarCorners( aPts, aRing, nAt )
   LOCAL n := Len( aRing )
RETURN { aPts[ aRing[ ( nAt + n - 1 ) % n + 1 ] + 1 ], aPts[ aRing[ nAt + 1 ] + 1 ], aPts[ aRing[ ( nAt + 1 ) % n + 1 ] + 1 ] }

STATIC FUNCTION Tg_ConvexCorner( c )
RETURN V2_Cross( V2_Sub( c[2], c[1] ), V2_Sub( c[3], c[2] ) ) > 0.0

STATIC FUNCTION Tg_Inside( a, b, c, p )
RETURN V2_Cross( V2_Sub( b, a ), V2_Sub( p, a ) ) >= 0.0 .AND. V2_Cross( V2_Sub( c, b ), V2_Sub( p, b ) ) >= 0.0 .AND. V2_Cross( V2_Sub( a, c ), V2_Sub( p, c ) ) >= 0.0

STATIC FUNCTION Tg_IsEar( aPts, aRing, nAt )
   LOCAL n := Len( aRing ), c := Tg_EarCorners( aPts, aRing, nAt ), o, p
   IF ! Tg_ConvexCorner( c ) ; RETURN .F. ; ENDIF
   FOR o := 0 TO n - 1
      IF o == nAt .OR. o == ( nAt + n - 1 ) % n .OR. o == ( nAt + 1 ) % n ; LOOP ; ENDIF
      p := aPts[ aRing[ o + 1 ] + 1 ]
      IF Tg_PtEq( p, c[1] ) .OR. Tg_PtEq( p, c[2] ) .OR. Tg_PtEq( p, c[3] ) ; LOOP ; ENDIF
      IF Tg_Inside( c[1], c[2], c[3], p ) ; RETURN .F. ; ENDIF
   NEXT
RETURN .T.

STATIC FUNCTION Tg_EarScore( aPts, aRing, nAt, aScale )
   LOCAL c := Tg_EarCorners( aPts, aRing, nAt ), i, nx, dx, dy, nMax := 0.0
   FOR i := 0 TO 2
      nx := ( i + 1 ) % 3
      dx := ( c[ nx + 1 ][1] - c[ i + 1 ][1] ) / aScale[1]
      dy := ( c[ nx + 1 ][2] - c[ i + 1 ][2] ) / aScale[2]
      nMax := Max( nMax, dx * dx + dy * dy )
   NEXT
RETURN nMax

FUNCTION Tg_ClipEars( aPts, aRing )
   LOCAL aOut := {}, nFail := 0, n, i, p, nMinX, nMaxX, nMinY, nMaxY, aScale, nCut, aCand, nBestI, k, nScore, nBestS, n2
   DO WHILE Len( aRing ) > 3
      IF nFail > Len( aRing ) ; RETURN {} ; ENDIF
      n := Len( aRing )
      nMinX := OCX_INF() ; nMaxX := -OCX_INF() ; nMinY := OCX_INF() ; nMaxY := -OCX_INF()
      FOR EACH i IN aRing
         p := aPts[ i + 1 ]
         nMinX := Min( nMinX, p[1] ) ; nMaxX := Max( nMaxX, p[1] )
         nMinY := Min( nMinY, p[2] ) ; nMaxY := Max( nMaxY, p[2] )
      NEXT
      aScale := { Max( nMaxX - nMinX, OCX_MINPOS() ), Max( nMaxY - nMinY, OCX_MINPOS() ) }
      nCut := NIL
      IF n <= 4
         nBestS := NIL
         FOR k := 0 TO n - 1
            IF Tg_IsEar( aPts, aRing, k )
               nScore := Tg_EarScore( aPts, aRing, k, aScale )
               IF nBestS == NIL .OR. nScore < nBestS
                  nBestS := nScore ; nCut := k
               ENDIF
            ENDIF
         NEXT
      ELSE
         aCand := {}
         FOR k := 0 TO n - 1
            IF Tg_ConvexCorner( Tg_EarCorners( aPts, aRing, k ) )
               AAdd( aCand, { k, Tg_EarScore( aPts, aRing, k, aScale ) } )
            ENDIF
         NEXT
         DO WHILE Len( aCand ) > 0
            nBestI := 1
            FOR k := 2 TO Len( aCand )
               IF aCand[k][2] < aCand[nBestI][2] .OR. ( aCand[k][2] == aCand[nBestI][2] .AND. aCand[k][1] < aCand[nBestI][1] )
                  nBestI := k
               ENDIF
            NEXT
            n2 := aCand[ nBestI ][1]
            ADel( aCand, nBestI ) ; ASize( aCand, Len( aCand ) - 1 )
            IF Tg_IsEar( aPts, aRing, n2 )
               nCut := n2 ; EXIT
            ENDIF
         ENDDO
      ENDIF
      IF nCut != NIL
         AAdd( aOut, { aRing[ ( nCut + n - 1 ) % n + 1 ], aRing[ nCut + 1 ], aRing[ ( nCut + 1 ) % n + 1 ] } )
         Tg_RemoveAt( aRing, nCut )
         nFail := 0
      ELSE
         nFail++
      ENDIF
   ENDDO
   IF Len( aRing ) == 3
      AAdd( aOut, { aRing[1], aRing[2], aRing[3] } )
   ENDIF
RETURN aOut
