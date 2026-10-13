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

FUNCTION Sat_Tess( sat )
   LOCAL aT := {}, nF := 0, nSk := 0, nFace, r, nSurf
   FOR EACH nFace IN Sat_Find( sat, "face" )
      nF++
      nSurf := Sat_Rec( sat, Sat_Ptr( St_Tok( sat, nFace, 8 ) ) )
      IF nSurf != NIL .AND. nSurf[ "type" ] == "plane-surface"
         IF ! St_PlaneFace( sat, nFace, aT ) ; nSk++ ; ENDIF
      ELSE
         nSk++
      ENDIF
   NEXT
   r := hb_Hash( "tris", aT, "faces", nF, "skipped", nSk )
RETURN r
