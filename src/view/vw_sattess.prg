/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/view/vw_sattess.prg
   Fase 2 / B13b: teselado de las caras de un SAT (vw_sat.prg) a triangulos 3D.
   Sat_Tess( sat ) -> { "tris" => { { p1, p2, p3, n }, ... }, "faces" => n, "skipped" => n }
   Soportado: caras de superficie plane-surface (bordes rectos y elipse/circulo,
   con huecos via Tg_Polygon). Las demas superficies (cone-surface, sphere-surface,
   torus-surface, NURBS) se cuentan en "skipped" (siguiente hito / N/A).
   Disposicion de campos (ACIS 7, tras el nombre del registro): atributo, id, historia, y
     face: sig cara, lazo, shell, subshell, superficie, sentido
     loop: sig lazo, coedge, cara | coedge: sig, ant, pareja, arista, sentido, lazo
     edge: v.ini, t.ini, v.fin, t.fin, coedge, curva, sentido | vertex: arista, punto
     point: x y z | plane-surface: origen(3) normal(3) u(3) ...
     ellipse-curve: centro(3) normal(3) eje mayor(3) razon | straight-curve: origen(3) dir(3)
----------------------------------------------------------------------------*/
#include "ocx.ch"

STATIC FUNCTION St_P( sat, nPtr, nTok )
   LOCAL r := Sat_Rec( sat, nPtr )
   IF r == NIL .OR. Len( r[ "tok" ] ) < nTok + 2 ; RETURN NIL ; ENDIF
RETURN { Val( r[ "tok" ][ nTok ] ), Val( r[ "tok" ][ nTok + 1 ] ), Val( r[ "tok" ][ nTok + 2 ] ) }

STATIC FUNCTION St_Tok( sat, nPtr, n )
   LOCAL r := Sat_Rec( sat, nPtr )
   IF r == NIL .OR. Len( r[ "tok" ] ) < n ; RETURN NIL ; ENDIF
RETURN r[ "tok" ][ n ]

STATIC FUNCTION St_VertexPt( sat, nV )
   LOCAL nP := Sat_Ptr( St_Tok( sat, nV, 5 ) )
RETURN IIf( nP == NIL, NIL, St_P( sat, nP, 4 ) )

STATIC FUNCTION St_Dist( a, b ) ; RETURN Sqrt( ( a[ 1 ] - b[ 1 ] ) ^ 2 + ( a[ 2 ] - b[ 2 ] ) ^ 2 + ( a[ 3 ] - b[ 3 ] ) ^ 2 )

/* puntos de una arista de v.ini a v.fin */
STATIC FUNCTION St_EdgePts( sat, nE )
   LOCAL r := Sat_Rec( sat, nE ), p0, p1, rc, c, n, m, t0, t1, i, t, a := {}, k, nSteps, q
   IF r == NIL .OR. Len( r[ "tok" ] ) < 10 ; RETURN NIL ; ENDIF
   p0 := St_VertexPt( sat, Sat_Ptr( r[ "tok" ][ 4 ] ) ) ; p1 := St_VertexPt( sat, Sat_Ptr( r[ "tok" ][ 6 ] ) )
   IF p0 == NIL .OR. p1 == NIL ; RETURN NIL ; ENDIF
   rc := Sat_Rec( sat, Sat_Ptr( r[ "tok" ][ 9 ] ) )
   IF rc != NIL .AND. rc[ "type" ] == "ellipse-curve" .AND. Len( rc[ "tok" ] ) >= 13
      c := { Val( rc[ "tok" ][ 4 ] ), Val( rc[ "tok" ][ 5 ] ), Val( rc[ "tok" ][ 6 ] ) }
      n := { Val( rc[ "tok" ][ 7 ] ), Val( rc[ "tok" ][ 8 ] ), Val( rc[ "tok" ][ 9 ] ) }
      m := { Val( rc[ "tok" ][ 10 ] ), Val( rc[ "tok" ][ 11 ] ), Val( rc[ "tok" ][ 12 ] ) }
      k := Val( rc[ "tok" ][ 13 ] )
      t0 := Val( r[ "tok" ][ 5 ] ) ; t1 := Val( r[ "tok" ][ 7 ] )
      IF t1 <= t0 ; t1 := t0 + OCX_TAU ; ENDIF
      nSteps := Max( 4, Int( ( t1 - t0 ) / ( OCX_TAU / 48.0 ) ) + 1 )
      FOR i := 0 TO nSteps
         t := t0 + ( t1 - t0 ) * i / nSteps
         q := { n[ 2 ] * m[ 3 ] - n[ 3 ] * m[ 2 ], n[ 3 ] * m[ 1 ] - n[ 1 ] * m[ 3 ], n[ 1 ] * m[ 2 ] - n[ 2 ] * m[ 1 ] }
         AAdd( a, { c[ 1 ] + m[ 1 ] * OCX_COS( t ) + q[ 1 ] * k * OCX_SIN( t ), c[ 2 ] + m[ 2 ] * OCX_COS( t ) + q[ 2 ] * k * OCX_SIN( t ), ;
                    c[ 3 ] + m[ 3 ] * OCX_COS( t ) + q[ 3 ] * k * OCX_SIN( t ) } )
      NEXT
      IF St_Dist( a[ 1 ], p0 ) > St_Dist( a[ Len( a ) ], p0 ) ; a := St_Rev( a ) ; ENDIF
      RETURN a
   ENDIF
RETURN { p0, p1 }

STATIC FUNCTION St_Rev( a )
   LOCAL b := {}, i
   FOR i := Len( a ) TO 1 STEP -1 ; AAdd( b, a[ i ] ) ; NEXT
RETURN b

/* anillo 3D de un lazo */
STATIC FUNCTION St_Loop( sat, nLoop )
   LOCAL nStart := Sat_Ptr( St_Tok( sat, nLoop, 5 ) ), nC := nStart, aRing := {}, aE, nSafe := 0, nEdge, cSense, p
   DO WHILE nC != NIL .AND. nC >= 0 .AND. nSafe < 100000
      nEdge := Sat_Ptr( St_Tok( sat, nC, 7 ) ) ; cSense := St_Tok( sat, nC, 8 )
      aE := St_EdgePts( sat, nEdge )
      IF aE == NIL ; RETURN NIL ; ENDIF
      IF cSense == "reversed" ; aE := St_Rev( aE ) ; ENDIF
      FOR EACH p IN aE
         IF Len( aRing ) == 0 .OR. St_Dist( p, ATail( aRing ) ) > 0.000000001 ; AAdd( aRing, p ) ; ENDIF
      NEXT
      nC := Sat_Ptr( St_Tok( sat, nC, 4 ) ) ; nSafe++
      IF nC == nStart ; EXIT ; ENDIF
   ENDDO
   IF Len( aRing ) > 1 .AND. St_Dist( aRing[ 1 ], ATail( aRing ) ) <= 0.000000001 ; ASize( aRing, Len( aRing ) - 1 ) ; ENDIF
RETURN aRing

STATIC FUNCTION St_Area2( a )
   LOCAL s := 0.0, i, n := Len( a ), p, q
   FOR i := 1 TO n
      p := a[ i ] ; q := a[ i % n + 1 ]
      s += p[ 1 ] * q[ 2 ] - q[ 1 ] * p[ 2 ]
   NEXT
RETURN s / 2.0

STATIC FUNCTION St_PlaneFace( sat, nFace, aT )
   LOCAL nS := Sat_Ptr( St_Tok( sat, nFace, 8 ) ), o := St_P( sat, nS, 4 ), n := St_P( sat, nS, 7 ), nL, aLoops := {}, aR, ex, ey, nL1
   LOCAL a2, aOuter := NIL, aHoles := {}, nBest := -1.0, p, k, r, i, j, nRev, cSn, tri, q
   IF o == NIL .OR. n == NIL ; RETURN .F. ; ENDIF
   nL1 := Sqrt( n[ 1 ] ^ 2 + n[ 2 ] ^ 2 + n[ 3 ] ^ 2 )
   IF nL1 <= 0.0 ; RETURN .F. ; ENDIF
   n := { n[ 1 ] / nL1, n[ 2 ] / nL1, n[ 3 ] / nL1 }
   ex := IIf( Abs( n[ 1 ] ) < 0.9, { 1.0, 0.0, 0.0 }, { 0.0, 1.0, 0.0 } )
   ey := { n[ 2 ] * ex[ 3 ] - n[ 3 ] * ex[ 2 ], n[ 3 ] * ex[ 1 ] - n[ 1 ] * ex[ 3 ], n[ 1 ] * ex[ 2 ] - n[ 2 ] * ex[ 1 ] }
   nL1 := Sqrt( ey[ 1 ] ^ 2 + ey[ 2 ] ^ 2 + ey[ 3 ] ^ 2 ) ; ey := { ey[ 1 ] / nL1, ey[ 2 ] / nL1, ey[ 3 ] / nL1 }
   ex := { ey[ 2 ] * n[ 3 ] - ey[ 3 ] * n[ 2 ], ey[ 3 ] * n[ 1 ] - ey[ 1 ] * n[ 3 ], ey[ 1 ] * n[ 2 ] - ey[ 2 ] * n[ 1 ] }
   nL := Sat_Ptr( St_Tok( sat, nFace, 5 ) )
   DO WHILE nL != NIL .AND. nL >= 0 .AND. Len( aLoops ) < 10000
      aR := St_Loop( sat, nL )
      IF aR == NIL .OR. Len( aR ) < 3 ; RETURN .F. ; ENDIF
      a2 := {}
      FOR EACH p IN aR
         AAdd( a2, { ( p[ 1 ] - o[ 1 ] ) * ex[ 1 ] + ( p[ 2 ] - o[ 2 ] ) * ex[ 2 ] + ( p[ 3 ] - o[ 3 ] ) * ex[ 3 ], ;
                     ( p[ 1 ] - o[ 1 ] ) * ey[ 1 ] + ( p[ 2 ] - o[ 2 ] ) * ey[ 2 ] + ( p[ 3 ] - o[ 3 ] ) * ey[ 3 ] } )
      NEXT
      AAdd( aLoops, a2 )
      nL := Sat_Ptr( St_Tok( sat, nL, 4 ) )
   ENDDO
   IF Len( aLoops ) == 0 ; RETURN .F. ; ENDIF
   FOR i := 1 TO Len( aLoops )
      IF Abs( St_Area2( aLoops[ i ] ) ) > nBest ; nBest := Abs( St_Area2( aLoops[ i ] ) ) ; j := i ; ENDIF
   NEXT
   aOuter := aLoops[ j ]
   FOR i := 1 TO Len( aLoops )
      IF i != j ; AAdd( aHoles, aLoops[ i ] ) ; ENDIF
   NEXT
   r := Tg_Polygon( aOuter, aHoles )
   cSn := St_Tok( sat, nFace, 9 )
   nRev := IIf( cSn == "reversed", -1.0, 1.0 )
   FOR EACH tri IN r[ 2 ]
      q := {}
      FOR k := 1 TO 3
         p := r[ 1 ][ tri[ k ] + 1 ]
         AAdd( q, { o[ 1 ] + ex[ 1 ] * p[ 1 ] + ey[ 1 ] * p[ 2 ], o[ 2 ] + ex[ 2 ] * p[ 1 ] + ey[ 2 ] * p[ 2 ], o[ 3 ] + ex[ 3 ] * p[ 1 ] + ey[ 3 ] * p[ 2 ] } )
      NEXT
      // el triangulo mira hacia la normal saliente (n * sentido de la cara)
      p := { ( q[ 2 ][ 2 ] - q[ 1 ][ 2 ] ) * ( q[ 3 ][ 3 ] - q[ 1 ][ 3 ] ) - ( q[ 2 ][ 3 ] - q[ 1 ][ 3 ] ) * ( q[ 3 ][ 2 ] - q[ 1 ][ 2 ] ), ;
             ( q[ 2 ][ 3 ] - q[ 1 ][ 3 ] ) * ( q[ 3 ][ 1 ] - q[ 1 ][ 1 ] ) - ( q[ 2 ][ 1 ] - q[ 1 ][ 1 ] ) * ( q[ 3 ][ 3 ] - q[ 1 ][ 3 ] ), ;
             ( q[ 2 ][ 1 ] - q[ 1 ][ 1 ] ) * ( q[ 3 ][ 2 ] - q[ 1 ][ 2 ] ) - ( q[ 2 ][ 2 ] - q[ 1 ][ 2 ] ) * ( q[ 3 ][ 1 ] - q[ 1 ][ 1 ] ) }
      IF ( p[ 1 ] * n[ 1 ] + p[ 2 ] * n[ 2 ] + p[ 3 ] * n[ 3 ] ) * nRev < 0.0
         k := q[ 2 ] ; q[ 2 ] := q[ 3 ] ; q[ 3 ] := k
      ENDIF
      AAdd( aT, { q[ 1 ], q[ 2 ], q[ 3 ], { n[ 1 ] * nRev, n[ 2 ] * nRev, n[ 3 ] * nRev } } )
   NEXT
RETURN .T.

/* ---- B13b2: superficies de revolucion (cone/cilindro, sphere, torus) ---- */
STATIC FUNCTION St_Unit( a )
   LOCAL l := Sqrt( a[ 1 ] ^ 2 + a[ 2 ] ^ 2 + a[ 3 ] ^ 2 )
   IF l <= 0.0 ; RETURN { 0.0, 0.0, 0.0 } ; ENDIF
RETURN { a[ 1 ] / l, a[ 2 ] / l, a[ 3 ] / l }
STATIC FUNCTION St_Cross( a, b ) ; RETURN { a[ 2 ] * b[ 3 ] - a[ 3 ] * b[ 2 ], a[ 3 ] * b[ 1 ] - a[ 1 ] * b[ 3 ], a[ 1 ] * b[ 2 ] - a[ 2 ] * b[ 1 ] }
STATIC FUNCTION St_Dot( a, b ) ; RETURN a[ 1 ] * b[ 1 ] + a[ 2 ] * b[ 2 ] + a[ 3 ] * b[ 3 ]
STATIC FUNCTION St_Sub( a, b ) ; RETURN { a[ 1 ] - b[ 1 ], a[ 2 ] - b[ 2 ], a[ 3 ] - b[ 3 ] }

/* emite un triangulo orientado hacia nOut (normal saliente ya con el sentido de la cara) */
STATIC FUNCTION St_Emit( aT, q1, q2, q3, nOut )
   LOCAL n := St_Cross( St_Sub( q2, q1 ), St_Sub( q3, q1 ) ), t
   IF St_Dot( n, nOut ) < 0.0 ; t := q2 ; q2 := q3 ; q3 := t ; ENDIF
   AAdd( aT, { q1, q2, q3, nOut } )
RETURN NIL

/* anillos del lazo: devuelve lista de { aPts } de los lazos de la cara */
STATIC FUNCTION St_FaceLoops( sat, nFace )
   LOCAL nL := Sat_Ptr( St_Tok( sat, nFace, 5 ) ), a := {}, aR
   DO WHILE nL != NIL .AND. nL >= 0 .AND. Len( a ) < 10000
      aR := St_Loop( sat, nL )
      IF aR == NIL .OR. Len( aR ) < 1 ; RETURN NIL ; ENDIF
      AAdd( a, aR )
      nL := Sat_Ptr( St_Tok( sat, nL, 4 ) )
   ENDDO
RETURN a

/* rango angular de un anillo respecto al eje: { lleno, umin, umax } con angulos en el marco (x,y) */
STATIC FUNCTION St_AngRange( aPts, c, x, y )
   LOCAL aA := {}, p, i, nMax := 0.0, g, nMean, sx := 0.0, sy := 0.0, nU, nMin := 1000000000000.0, nMx := -1000000000000.0, d
   FOR EACH p IN aPts
      d := St_Sub( p, c )
      AAdd( aA, OCX_ATAN2( St_Dot( d, y ), St_Dot( d, x ) ) )
   NEXT
   IF Len( aA ) < 3 ; RETURN { .F., 0.0, 0.0 } ; ENDIF
   aA := ASort( aA )
   FOR i := 1 TO Len( aA )
      g := IIf( i < Len( aA ), aA[ i + 1 ] - aA[ i ], aA[ 1 ] + OCX_TAU - aA[ i ] )
      IF g > nMax ; nMax := g ; ENDIF
   NEXT
   IF nMax < OCX_TAU / 4.0 ; RETURN { .T., 0.0, OCX_TAU } ; ENDIF
   FOR EACH nU IN aA ; sx += OCX_COS( nU ) ; sy += OCX_SIN( nU ) ; NEXT
   nMean := OCX_ATAN2( sy, sx )
   FOR EACH nU IN aA
      d := nU - nMean
      DO WHILE d > OCX_PI ; d -= OCX_TAU ; ENDDO
      DO WHILE d < -OCX_PI ; d += OCX_TAU ; ENDDO
      nMin := Min( nMin, nMean + d ) ; nMx := Max( nMx, nMean + d )
   NEXT
RETURN { .F., nMin, nMx }

/* malla parametrica (u0..u1, v0..v1) con evaluador cBlock( u, v ) -> { punto, normal } */
STATIC FUNCTION St_Grid( aT, bEval, u0, u1, v0, v1, nU, nV, nRev )
   LOCAL i, j, a, b, c, d, r
   FOR i := 0 TO nU - 1
      FOR j := 0 TO nV - 1
         a := Eval( bEval, u0 + ( u1 - u0 ) * i / nU, v0 + ( v1 - v0 ) * j / nV )
         b := Eval( bEval, u0 + ( u1 - u0 ) * ( i + 1 ) / nU, v0 + ( v1 - v0 ) * j / nV )
         c := Eval( bEval, u0 + ( u1 - u0 ) * ( i + 1 ) / nU, v0 + ( v1 - v0 ) * ( j + 1 ) / nV )
         d := Eval( bEval, u0 + ( u1 - u0 ) * i / nU, v0 + ( v1 - v0 ) * ( j + 1 ) / nV )
         r := { a[ 2 ][ 1 ] + b[ 2 ][ 1 ] + c[ 2 ][ 1 ] + d[ 2 ][ 1 ], a[ 2 ][ 2 ] + b[ 2 ][ 2 ] + c[ 2 ][ 2 ] + d[ 2 ][ 2 ], a[ 2 ][ 3 ] + b[ 2 ][ 3 ] + c[ 2 ][ 3 ] + d[ 2 ][ 3 ] }
         r := St_Unit( r ) ; r := { r[ 1 ] * nRev, r[ 2 ] * nRev, r[ 3 ] * nRev }
         IF ! ( a[ 1 ][ 1 ] == b[ 1 ][ 1 ] .AND. a[ 1 ][ 2 ] == b[ 1 ][ 2 ] .AND. a[ 1 ][ 3 ] == b[ 1 ][ 3 ] ) .AND. ;
            ! ( b[ 1 ][ 1 ] == c[ 1 ][ 1 ] .AND. b[ 1 ][ 2 ] == c[ 1 ][ 2 ] .AND. b[ 1 ][ 3 ] == c[ 1 ][ 3 ] )
            St_Emit( aT, a[ 1 ], b[ 1 ], c[ 1 ], r )
         ENDIF
         IF ! ( a[ 1 ][ 1 ] == d[ 1 ][ 1 ] .AND. a[ 1 ][ 2 ] == d[ 1 ][ 2 ] .AND. a[ 1 ][ 3 ] == d[ 1 ][ 3 ] ) .AND. ;
            ! ( c[ 1 ][ 1 ] == d[ 1 ][ 1 ] .AND. c[ 1 ][ 2 ] == d[ 1 ][ 2 ] .AND. c[ 1 ][ 3 ] == d[ 1 ][ 3 ] )
            St_Emit( aT, a[ 1 ], c[ 1 ], d[ 1 ], r )
         ENDIF
      NEXT
   NEXT
RETURN NIL

/* cone-surface / cilindro: origen, eje, vector mayor (radio), razon, sin, cos */
FUNCTION Sat_ConePt( o, ax, mu, nu, r0, nTan, ratio, u, h )
   LOCAL rr := r0 + h * nTan, cu := OCX_COS( u ), su := OCX_SIN( u ) * ratio
   LOCAL p := { o[ 1 ] + ax[ 1 ] * h + rr * ( mu[ 1 ] * cu + nu[ 1 ] * su ), o[ 2 ] + ax[ 2 ] * h + rr * ( mu[ 2 ] * cu + nu[ 2 ] * su ), o[ 3 ] + ax[ 3 ] * h + rr * ( mu[ 3 ] * cu + nu[ 3 ] * su ) }
   LOCAL rad := { mu[ 1 ] * cu + nu[ 1 ] * su, mu[ 2 ] * cu + nu[ 2 ] * su, mu[ 3 ] * cu + nu[ 3 ] * su }
   // normal: radial menos la componente axial de la pendiente
   LOCAL n := { rad[ 1 ] - ax[ 1 ] * nTan, rad[ 2 ] - ax[ 2 ] * nTan, rad[ 3 ] - ax[ 3 ] * nTan }
RETURN { p, St_Unit( n ) }

STATIC FUNCTION St_ConeFace( sat, nFace, aT )
   LOCAL nS := Sat_Ptr( St_Tok( sat, nFace, 8 ) ), o := St_P( sat, nS, 4 ), ax := St_P( sat, nS, 7 ), mj := St_P( sat, nS, 10 )
   LOCAL nSin, nCos, nTan, ratio, r0, mu, nu, aL, aLoop, h, hmin := 1000000000000.0, hmax := -1000000000000.0, nRing := 0, full := .F., u0, u1
   LOCAL p, hh, lo, hi, nRev, bE, nSu, nSv, aRng
   IF o == NIL .OR. ax == NIL .OR. mj == NIL .OR. Len( Sat_Rec( sat, nS )[ "tok" ] ) < 18 ; RETURN .F. ; ENDIF
   ratio := Val( St_Tok( sat, nS, 13 ) ) ; nSin := Val( St_Tok( sat, nS, 16 ) ) ; nCos := Val( St_Tok( sat, nS, 17 ) )
   IF ratio == 0.0 ; ratio := 1.0 ; ENDIF
   IF Abs( nCos ) < 0.000000001 ; RETURN .F. ; ENDIF
   nTan := nSin / nCos
   ax := St_Unit( ax ) ; r0 := Sqrt( St_Dot( mj, mj ) ) ; mu := St_Unit( mj ) ; nu := St_Cross( ax, mu )
   IF r0 <= 0.0 ; RETURN .F. ; ENDIF
   aL := St_FaceLoops( sat, nFace )
   IF aL == NIL .OR. Len( aL ) == 0 ; RETURN .F. ; ENDIF
   FOR EACH aLoop IN aL
      lo := 1000000000000.0 ; hi := -1000000000000.0
      FOR EACH p IN aLoop
         hh := St_Dot( St_Sub( p, o ), ax ) ; lo := Min( lo, hh ) ; hi := Max( hi, hh )
      NEXT
      hmin := Min( hmin, lo ) ; hmax := Max( hmax, hi )
      IF hi - lo < 0.000001 * Max( 1.0, r0 ) .AND. Len( aLoop ) >= 6
         nRing++
         aRng := St_AngRange( aLoop, o, mu, nu )
         IF aRng[ 1 ] ; full := .T. ; ENDIF
      ENDIF
   NEXT
   IF nRing == 1 .AND. Abs( nTan ) > 0.000000001 .AND. hmax - hmin < 0.000001 * Max( 1.0, r0 )
      // cono hasta el apice
      h := -r0 / nTan
      IF h > hmin ; hmax := h ; ELSE ; hmin := h ; ENDIF
   ENDIF
   IF hmax - hmin < 0.000001 ; RETURN .F. ; ENDIF
   IF full
      u0 := 0.0 ; u1 := OCX_TAU
   ELSE
      u0 := 1000000000000.0 ; u1 := -1000000000000.0
      FOR EACH aLoop IN aL
         aRng := St_AngRange( aLoop, o, mu, nu )
         IF aRng[ 1 ] ; RETURN .F. ; ENDIF
         u0 := Min( u0, aRng[ 2 ] ) ; u1 := Max( u1, aRng[ 3 ] )
      NEXT
      IF u1 - u0 < 0.000001 ; RETURN .F. ; ENDIF
   ENDIF
   nRev := IIf( St_Tok( sat, nFace, 9 ) == "reversed", -1.0, 1.0 )
   bE := {| u, v | Sat_ConePt( o, ax, mu, nu, r0, nTan, ratio, u, v ) }
   nSu := Max( 8, Int( ( u1 - u0 ) / ( OCX_TAU / 48.0 ) ) + 1 ) ; nSv := 1
   St_Grid( aT, bE, u0, u1, hmin, hmax, nSu, nSv, nRev )
RETURN .T.

/* sphere-surface: centro, radio, uvec, polo */
FUNCTION Sat_SpherePt( c, rad, x, y, a, th, ph )
   LOCAL cp := OCX_COS( ph ), sp := OCX_SIN( ph ), ct := OCX_COS( th ), st := OCX_SIN( th )
   LOCAL n := { cp * ( ct * x[ 1 ] + st * y[ 1 ] ) + sp * a[ 1 ], cp * ( ct * x[ 2 ] + st * y[ 2 ] ) + sp * a[ 2 ], cp * ( ct * x[ 3 ] + st * y[ 3 ] ) + sp * a[ 3 ] }
RETURN { { c[ 1 ] + rad * n[ 1 ], c[ 2 ] + rad * n[ 2 ], c[ 3 ] + rad * n[ 3 ] }, n }

STATIC FUNCTION St_SphereFace( sat, nFace, aT )
   LOCAL nS := Sat_Ptr( St_Tok( sat, nFace, 8 ) ), c := St_P( sat, nS, 4 ), x := St_P( sat, nS, 8 ), a := St_P( sat, nS, 11 ), rad
   LOCAL aL, aLoop, aLat := {}, p, lo, hi, hh, f0, f1, nRev, bE, y
   IF c == NIL .OR. x == NIL .OR. a == NIL .OR. Len( Sat_Rec( sat, nS )[ "tok" ] ) < 13 ; RETURN .F. ; ENDIF
   rad := Abs( Val( St_Tok( sat, nS, 7 ) ) ) ; IF rad <= 0.0 ; RETURN .F. ; ENDIF
   a := St_Unit( a ) ; x := St_Unit( St_Sub( x, { a[ 1 ] * St_Dot( x, a ), a[ 2 ] * St_Dot( x, a ), a[ 3 ] * St_Dot( x, a ) } ) ) ; y := St_Cross( a, x )
   aL := St_FaceLoops( sat, nFace )
   IF aL == NIL ; RETURN .F. ; ENDIF
   FOR EACH aLoop IN aL
      lo := 1000000000000.0 ; hi := -1000000000000.0
      FOR EACH p IN aLoop
         hh := St_Dot( St_Sub( p, c ), a ) / rad ; lo := Min( lo, hh ) ; hi := Max( hi, hh )
      NEXT
      IF hi - lo < 0.000001 .AND. Len( aLoop ) >= 6
         AAdd( aLat, ASin1( ( hi + lo ) / 2.0 ) )
      ELSEIF Len( aLoop ) > 1 .AND. hi - lo >= 0.000001
         // lazo no circular (costura): se ignora, solo cuentan los anillos
      ENDIF
   NEXT
   IF Len( aLat ) == 0
      f0 := -OCX_PI / 2.0 ; f1 := OCX_PI / 2.0
   ELSEIF Len( aLat ) == 1
      IF aLat[ 1 ] >= 0.0 ; f0 := aLat[ 1 ] ; f1 := OCX_PI / 2.0 ; ELSE ; f0 := -OCX_PI / 2.0 ; f1 := aLat[ 1 ] ; ENDIF
   ELSE
      f0 := Min( aLat[ 1 ], aLat[ 2 ] ) ; f1 := Max( aLat[ 1 ], aLat[ 2 ] )
   ENDIF
   IF f1 - f0 < 0.000001 ; RETURN .F. ; ENDIF
   nRev := IIf( St_Tok( sat, nFace, 9 ) == "reversed", -1.0, 1.0 )
   bE := {| u, v | Sat_SpherePt( c, rad, x, y, a, u, v ) }
   St_Grid( aT, bE, 0.0, OCX_TAU, f0, f1, 48, Max( 6, Int( ( f1 - f0 ) / ( OCX_TAU / 48.0 ) ) + 1 ), nRev )
RETURN .T.

STATIC FUNCTION ASin1( v ) ; RETURN OCX_ASIN( Max( -1.0, Min( 1.0, v ) ) )

/* torus-surface: centro, eje, radio mayor, radio menor, uvec. Solo toro completo (sin lazos circulares). */
FUNCTION Sat_TorusPt( c, ax, x, y, nBig, nSmall, th, ph )
   LOCAL ct := OCX_COS( th ), st := OCX_SIN( th ), cp := OCX_COS( ph ), sp := OCX_SIN( ph )
   LOCAL d := { ct * x[ 1 ] + st * y[ 1 ], ct * x[ 2 ] + st * y[ 2 ], ct * x[ 3 ] + st * y[ 3 ] }
   LOCAL n := { cp * d[ 1 ] + sp * ax[ 1 ], cp * d[ 2 ] + sp * ax[ 2 ], cp * d[ 3 ] + sp * ax[ 3 ] }
RETURN { { c[ 1 ] + nBig * d[ 1 ] + nSmall * n[ 1 ], c[ 2 ] + nBig * d[ 2 ] + nSmall * n[ 2 ], c[ 3 ] + nBig * d[ 3 ] + nSmall * n[ 3 ] }, n }

STATIC FUNCTION St_TorusFace( sat, nFace, aT )
   LOCAL nS := Sat_Ptr( St_Tok( sat, nFace, 8 ) ), c := St_P( sat, nS, 4 ), ax := St_P( sat, nS, 7 ), x := St_P( sat, nS, 12 ), nBig, nSmall, y, nRev, bE
   IF c == NIL .OR. ax == NIL .OR. x == NIL .OR. Len( Sat_Rec( sat, nS )[ "tok" ] ) < 14 ; RETURN .F. ; ENDIF
   nBig := Abs( Val( St_Tok( sat, nS, 10 ) ) ) ; nSmall := Abs( Val( St_Tok( sat, nS, 11 ) ) )
   IF nBig <= 0.0 .OR. nSmall <= 0.0 ; RETURN .F. ; ENDIF
   ax := St_Unit( ax ) ; x := St_Unit( St_Sub( x, { ax[ 1 ] * St_Dot( x, ax ), ax[ 2 ] * St_Dot( x, ax ), ax[ 3 ] * St_Dot( x, ax ) } ) ) ; y := St_Cross( ax, x )
   nRev := IIf( St_Tok( sat, nFace, 9 ) == "reversed", -1.0, 1.0 )
   bE := {| u, v | Sat_TorusPt( c, ax, x, y, nBig, nSmall, u, v ) }
   St_Grid( aT, bE, 0.0, OCX_TAU, 0.0, OCX_TAU, 48, 24, nRev )
RETURN .T.

FUNCTION Sat_Tess( sat )
   LOCAL aT := {}, nF := 0, nSk := 0, nFace, r, nSurf
   FOR EACH nFace IN Sat_Find( sat, "face" )
      nF++
      nSurf := Sat_Rec( sat, Sat_Ptr( St_Tok( sat, nFace, 8 ) ) )
      IF nSurf != NIL .AND. nSurf[ "type" ] == "plane-surface"
         IF ! St_PlaneFace( sat, nFace, aT ) ; nSk++ ; ENDIF
      ELSEIF nSurf != NIL .AND. nSurf[ "type" ] == "cone-surface"
         IF ! St_ConeFace( sat, nFace, aT ) ; nSk++ ; ENDIF
      ELSEIF nSurf != NIL .AND. nSurf[ "type" ] == "sphere-surface"
         IF ! St_SphereFace( sat, nFace, aT ) ; nSk++ ; ENDIF
      ELSEIF nSurf != NIL .AND. nSurf[ "type" ] == "torus-surface"
         IF ! St_TorusFace( sat, nFace, aT ) ; nSk++ ; ENDIF
      ELSE
         nSk++
      ENDIF
   NEXT
   r := hb_Hash( "tris", aT, "faces", nF, "skipped", nSk )
RETURN r
