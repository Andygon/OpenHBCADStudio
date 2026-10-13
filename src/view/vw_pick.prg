/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/view/vw_pick.prg
   Fase 2 / bloque B9. Origen Rust: src/scene/pick/*.rs (hit_test, caja de
   seleccion) + src/scene/selection.rs + grips. Logica pura sobre la escena
   de vw_scene.prg (hilos con handle). Sin FiveWin: se prueba en consola.
----------------------------------------------------------------------------*/
#include "ocx.ch"

/* distancia de (px,py) al segmento a-b */
FUNCTION Vwp_DistSeg( px, py, ax, ay, bx, by )
   LOCAL dx := bx - ax, dy := by - ay, l2 := dx * dx + dy * dy, t
   IF l2 < 0.000000000001
      RETURN Sqrt( ( px - ax ) ^ 2 + ( py - ay ) ^ 2 )
   ENDIF
   t := Max( 0.0, Min( 1.0, ( ( px - ax ) * dx + ( py - ay ) * dy ) / l2 ) )
RETURN Sqrt( ( px - ( ax + t * dx ) ) ^ 2 + ( py - ( ay + t * dy ) ) ^ 2 )

/* entidad de primer nivel bajo el punto mundo (x,y) con tolerancia nTol; NIL si ninguna */
FUNCTION Vwp_Pick( oS, x, y, nTol )
   LOCAL i, w, aP, j, aB
   FOR i := Len( oS[ "wires" ] ) TO 1 STEP -1
      w := oS[ "wires" ][ i ]
      IF Empty( w[ 6 ] ) ; LOOP ; ENDIF
      aB := w[ 4 ]
      IF x < aB[ 1 ] - nTol .OR. x > aB[ 3 ] + nTol .OR. y < aB[ 2 ] - nTol .OR. y > aB[ 4 ] + nTol
         LOOP
      ENDIF
      aP := w[ 3 ]
      IF Len( aP ) == 1
         IF Sqrt( ( x - aP[ 1 ][ 1 ] ) ^ 2 + ( y - aP[ 1 ][ 2 ] ) ^ 2 ) <= nTol ; RETURN w[ 6 ] ; ENDIF
         LOOP
      ENDIF
      FOR j := 1 TO Len( aP ) - 1
         IF Vwp_DistSeg( x, y, aP[ j ][ 1 ], aP[ j ][ 2 ], aP[ j + 1 ][ 1 ], aP[ j + 1 ][ 2 ] ) <= nTol
            RETURN w[ 6 ]
         ENDIF
      NEXT
   NEXT
RETURN NIL

STATIC FUNCTION Vwp_In( x, y, r ) ; RETURN x >= r[ 1 ] .AND. x <= r[ 3 ] .AND. y >= r[ 2 ] .AND. y <= r[ 4 ]

/* segmento a-b corta el rectangulo r (Liang-Barsky) */
STATIC FUNCTION Vwp_SegHitsRect( ax, ay, bx, by, r )
   LOCAL t0 := 0.0, t1 := 1.0, dx := bx - ax, dy := by - ay, p, q, i, t
   p := { - dx, dx, - dy, dy }
   q := { ax - r[ 1 ], r[ 3 ] - ax, ay - r[ 2 ], r[ 4 ] - ay }
   FOR i := 1 TO 4
      IF Abs( p[ i ] ) < 0.000000000001
         IF q[ i ] < 0 ; RETURN .F. ; ENDIF
      ELSE
         t := q[ i ] / p[ i ]
         IF p[ i ] < 0
            IF t > t1 ; RETURN .F. ; ENDIF
            IF t > t0 ; t0 := t ; ENDIF
         ELSE
            IF t < t0 ; RETURN .F. ; ENDIF
            IF t < t1 ; t1 := t ; ENDIF
         ENDIF
      ENDIF
   NEXT
RETURN .T.

/* seleccion por caja (x1,y1)-(x2,y2): de izquierda a derecha = ventana (todo dentro),
   de derecha a izquierda = captura (toca). Devuelve array de handles unicos. */
FUNCTION Vwp_Box( oS, x1, y1, x2, y2 )
   LOCAL r := { Min( x1, x2 ), Min( y1, y2 ), Max( x1, x2 ), Max( y1, y2 ) }, lWin := ( x2 >= x1 )
   LOCAL h := hb_Hash(), a := {}, w, aB, lOk, j, aP, k, lAll
   // por handle: ventana exige TODOS sus hilos dentro; captura basta con uno
   FOR EACH w IN oS[ "wires" ]
      IF Empty( w[ 6 ] ) ; LOOP ; ENDIF
      aB := w[ 4 ]
      IF lWin
         lOk := aB[ 1 ] >= r[ 1 ] .AND. aB[ 3 ] <= r[ 3 ] .AND. aB[ 2 ] >= r[ 2 ] .AND. aB[ 4 ] <= r[ 4 ]
         IF ! lOk
            h[ w[ 6 ] ] := .F.
         ELSEIF ! hb_HHasKey( h, w[ 6 ] )
            h[ w[ 6 ] ] := .T.
         ENDIF
      ELSE
         IF aB[ 3 ] < r[ 1 ] .OR. aB[ 1 ] > r[ 3 ] .OR. aB[ 4 ] < r[ 2 ] .OR. aB[ 2 ] > r[ 4 ]
            LOOP
         ENDIF
         aP := w[ 3 ]
         lOk := .F.
         FOR j := 1 TO Len( aP )
            IF Vwp_In( aP[ j ][ 1 ], aP[ j ][ 2 ], r ) ; lOk := .T. ; EXIT ; ENDIF
            IF j < Len( aP ) .AND. Vwp_SegHitsRect( aP[ j ][ 1 ], aP[ j ][ 2 ], aP[ j + 1 ][ 1 ], aP[ j + 1 ][ 2 ], r ) ; lOk := .T. ; EXIT ; ENDIF
         NEXT
         IF lOk ; h[ w[ 6 ] ] := .T. ; ENDIF
      ENDIF
   NEXT
   lAll := NIL
   FOR EACH k IN hb_HKeys( h )
      IF h[ k ] ; AAdd( a, k ) ; ENDIF
   NEXT
RETURN a

/* puntos de agarre (grips) en mundo { {x,y}, ... } de una entidad de primer nivel */
FUNCTION Vwp_Grips( e )
   LOCAL cT := e[ "_type" ], a := {}, p, q, c, r, k, nA, nB, ax, ay, bx, by
   DO CASE
   CASE cT == "LINE"
      AAdd( a, { e[ "start" ][ 1 ], e[ "start" ][ 2 ] } )
      AAdd( a, { ( e[ "start" ][ 1 ] + e[ "end" ][ 1 ] ) / 2, ( e[ "start" ][ 2 ] + e[ "end" ][ 2 ] ) / 2 } )
      AAdd( a, { e[ "end" ][ 1 ], e[ "end" ][ 2 ] } )
   CASE cT == "CIRCLE"
      c := e[ "center" ] ; r := e[ "radius" ]
      FOR EACH k IN { { 0, 0 }, { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 } }
         q := Vws_Ocs( e[ "normal" ], c[ 1 ] + k[ 1 ] * r, c[ 2 ] + k[ 2 ] * r, c[ 3 ] )
         AAdd( a, { q[ 1 ], q[ 2 ] } )
      NEXT
   CASE cT == "ARC"
      c := e[ "center" ] ; r := e[ "radius" ] ; nA := e[ "start_angle" ] ; nB := e[ "end_angle" ]
      DO WHILE nB <= nA
         nB += OCX_TAU
      ENDDO
      FOR EACH k IN { nA, ( nA + nB ) / 2, nB }
         q := Vws_Ocs( e[ "normal" ], c[ 1 ] + r * OCX_COS( k ), c[ 2 ] + r * OCX_SIN( k ), c[ 3 ] )
         AAdd( a, { q[ 1 ], q[ 2 ] } )
      NEXT
      q := Vws_Ocs( e[ "normal" ], c[ 1 ], c[ 2 ], c[ 3 ] )
      AAdd( a, { q[ 1 ], q[ 2 ] } )
   CASE cT == "LWPOLYLINE"
      FOR EACH p IN e[ "vertices" ]
         q := Vws_Ocs( e[ "normal" ], p[ "location" ][ 1 ], p[ "location" ][ 2 ], IIf( hb_HHasKey( e, "elevation" ), e[ "elevation" ], 0.0 ) )
         AAdd( a, { q[ 1 ], q[ 2 ] } )
      NEXT
   CASE cT == "POLYLINE2D"
      FOR EACH p IN e[ "vertices" ]
         AAdd( a, { p[ "location" ][ 1 ], p[ "location" ][ 2 ] } )
      NEXT
   CASE cT == "POLYLINE3D" .OR. cT == "POLYLINE"
      FOR EACH p IN e[ "vertices" ]
         IF hb_HHasKey( p, "position" ) ; AAdd( a, { p[ "position" ][ 1 ], p[ "position" ][ 2 ] } ) ; ENDIF
      NEXT
   CASE cT == "ELLIPSE"
      c := e[ "center" ] ; ax := e[ "major_axis" ][ 1 ] ; ay := e[ "major_axis" ][ 2 ]
      bx := - ay * e[ "minor_axis_ratio" ] ; by := ax * e[ "minor_axis_ratio" ]
      AAdd( a, { c[ 1 ], c[ 2 ] } )
      AAdd( a, { c[ 1 ] + ax, c[ 2 ] + ay } ) ; AAdd( a, { c[ 1 ] - ax, c[ 2 ] - ay } )
      AAdd( a, { c[ 1 ] + bx, c[ 2 ] + by } ) ; AAdd( a, { c[ 1 ] - bx, c[ 2 ] - by } )
   CASE cT == "POINT"
      AAdd( a, { e[ "location" ][ 1 ], e[ "location" ][ 2 ] } )
   CASE cT == "TEXT" .OR. cT == "MTEXT"
      AAdd( a, { e[ "insertion_point" ][ 1 ], e[ "insertion_point" ][ 2 ] } )
   CASE cT == "INSERT" .OR. cT == "MINSERT"
      AAdd( a, { e[ "insert_point" ][ 1 ], e[ "insert_point" ][ 2 ] } )
   CASE cT == "SOLID" .OR. cT == "3DFACE"
      FOR EACH k IN { "first_corner", "second_corner", "third_corner", "fourth_corner" }
         AAdd( a, { e[ k ][ 1 ], e[ k ][ 2 ] } )
      NEXT
   CASE cT == "SPLINE"
      FOR EACH p IN IIf( Len( e[ "fit_points" ] ) >= 2, e[ "fit_points" ], e[ "control_points" ] )
         AAdd( a, { p[ 1 ], p[ 2 ] } )
      NEXT
   ENDCASE
RETURN a

/* grip mas cercano a (x,y) dentro de nTol entre las entidades seleccionadas; { cHandle, nIdx, x, y } o NIL */
FUNCTION Vwp_GripAt( oS, hSel, x, y, nTol )
   LOCAL k, aG, i, d, nBest := nTol, r := NIL
   FOR EACH k IN hb_HKeys( hSel )
      IF ! hb_HHasKey( oS[ "ents" ], k ) ; LOOP ; ENDIF
      aG := Vwp_Grips( oS[ "ents" ][ k ] )
      FOR i := 1 TO Len( aG )
         d := Sqrt( ( x - aG[ i ][ 1 ] ) ^ 2 + ( y - aG[ i ][ 2 ] ) ^ 2 )
         IF d <= nBest
            nBest := d ; r := { k, i, aG[ i ][ 1 ], aG[ i ][ 2 ] }
         ENDIF
      NEXT
   NEXT
RETURN r

/* --- snap a objetos (END, MID, CEN, QUA, NOD, INS) --- */

/* puntos de enganche de una entidad: { {x,y,cModo}, ... } */
FUNCTION Vwp_SnapPts( e )
   LOCAL cT := e[ "_type" ], g := Vwp_Grips( e ), a := {}, i, n := Len( g ), v, lClosed, p, q, nB
   DO CASE
   CASE cT == "LINE" .AND. n == 3
      a := { { g[ 1 ][ 1 ], g[ 1 ][ 2 ], "END" }, { g[ 2 ][ 1 ], g[ 2 ][ 2 ], "MID" }, { g[ 3 ][ 1 ], g[ 3 ][ 2 ], "END" } }
   CASE cT == "CIRCLE" .AND. n == 5
      AAdd( a, { g[ 1 ][ 1 ], g[ 1 ][ 2 ], "CEN" } )
      FOR i := 2 TO 5
         AAdd( a, { g[ i ][ 1 ], g[ i ][ 2 ], "QUA" } )
      NEXT
   CASE cT == "ARC" .AND. n == 4
      a := { { g[ 1 ][ 1 ], g[ 1 ][ 2 ], "END" }, { g[ 2 ][ 1 ], g[ 2 ][ 2 ], "MID" }, { g[ 3 ][ 1 ], g[ 3 ][ 2 ], "END" }, { g[ 4 ][ 1 ], g[ 4 ][ 2 ], "CEN" } }
   CASE cT == "LWPOLYLINE" .OR. cT == "POLYLINE2D" .OR. cT == "POLYLINE3D" .OR. cT == "POLYLINE"
      lClosed := hb_HHasKey( e, "is_closed" ) .AND. ValType( e[ "is_closed" ] ) == "L" .AND. e[ "is_closed" ]
      FOR i := 1 TO n
         AAdd( a, { g[ i ][ 1 ], g[ i ][ 2 ], "END" } )
      NEXT
      FOR i := 1 TO IIf( lClosed, n, n - 1 )
         p := g[ i ] ; q := g[ IIf( i == n, 1, i + 1 ) ]
         nB := 0.0
         IF cT == "LWPOLYLINE" .AND. i <= Len( e[ "vertices" ] ) .AND. hb_HHasKey( e[ "vertices" ][ i ], "bulge" )
            nB := e[ "vertices" ][ i ][ "bulge" ]
         ENDIF
         IF Abs( nB ) < 0.000000001
            AAdd( a, { ( p[ 1 ] + q[ 1 ] ) / 2, ( p[ 2 ] + q[ 2 ] ) / 2, "MID" } )
         ENDIF
      NEXT
   CASE cT == "ELLIPSE" .AND. n == 5
      AAdd( a, { g[ 1 ][ 1 ], g[ 1 ][ 2 ], "CEN" } )
      FOR i := 2 TO 5
         AAdd( a, { g[ i ][ 1 ], g[ i ][ 2 ], "QUA" } )
      NEXT
   CASE cT == "POINT" .AND. n == 1
      a := { { g[ 1 ][ 1 ], g[ 1 ][ 2 ], "NOD" } }
   CASE cT == "TEXT" .OR. cT == "MTEXT" .OR. cT == "INSERT" .OR. cT == "MINSERT"
      FOR EACH v IN g
         AAdd( a, { v[ 1 ], v[ 2 ], "INS" } )
      NEXT
   CASE cT == "SOLID" .OR. cT == "3DFACE"
      FOR EACH v IN g
         AAdd( a, { v[ 1 ], v[ 2 ], "END" } )
      NEXT
   CASE cT == "SPLINE" .AND. n >= 2
      a := { { g[ 1 ][ 1 ], g[ 1 ][ 2 ], "END" }, { g[ n ][ 1 ], g[ n ][ 2 ], "END" } }
   ENDCASE
RETURN a

/* interseccion de segmentos a-b y c-d; { x, y } o NIL */
STATIC FUNCTION Vwp_SegInt( ax, ay, bx, by, cx, cy, dx, dy )
   LOCAL r1 := bx - ax, r2 := by - ay, s1 := dx - cx, s2 := dy - cy, nDen := r1 * s2 - r2 * s1, t, u
   IF Abs( nDen ) < 0.000000000001 ; RETURN NIL ; ENDIF
   t := ( ( cx - ax ) * s2 - ( cy - ay ) * s1 ) / nDen
   u := ( ( cx - ax ) * r2 - ( cy - ay ) * r1 ) / nDen
   IF t < 0.0 .OR. t > 1.0 .OR. u < 0.0 .OR. u > 1.0 ; RETURN NIL ; ENDIF
RETURN { ax + t * r1, ay + t * r2 }

/* punto de enganche mas cercano a (x,y) dentro de nTol (unidades mundo), solo para los
   modos activos en cModes (ej. "END MID CEN"); { x, y, cModo } o NIL.
   INT = interseccion de dos trazos; PER = pie de la perpendicular desde aFrom ({x,y}, opcional). */
FUNCTION Vwp_Snap( oS, cModes, x, y, nTol, aFrom )
   LOCAL w, aB, hSeen := hb_Hash(), e, p, nBest := nTol, r := NIL, d
   LOCAL aNear := {}, i, j, k, l, aP, aQ, q, nL2, t, fx, fy, lInt := ( "INT" $ cModes ), lPer := ( "PER" $ cModes .AND. aFrom != NIL )
   IF Empty( cModes ) ; RETURN NIL ; ENDIF
   FOR EACH w IN oS[ "wires" ]
      IF Empty( w[ 6 ] ) ; LOOP ; ENDIF
      aB := w[ 4 ]
      IF x < aB[ 1 ] - nTol .OR. x > aB[ 3 ] + nTol .OR. y < aB[ 2 ] - nTol .OR. y > aB[ 4 ] + nTol
         LOOP
      ENDIF
      IF ( lInt .OR. lPer ) .AND. Len( aNear ) < 60 ; AAdd( aNear, w ) ; ENDIF
      IF hb_HHasKey( hSeen, w[ 6 ] ) ; LOOP ; ENDIF
      hSeen[ w[ 6 ] ] := .T.
      IF ! hb_HHasKey( oS[ "ents" ], w[ 6 ] ) ; LOOP ; ENDIF
      e := oS[ "ents" ][ w[ 6 ] ]
      FOR EACH p IN Vwp_SnapPts( e )
         IF ! ( p[ 3 ] $ cModes ) ; LOOP ; ENDIF
         d := Sqrt( ( x - p[ 1 ] ) ^ 2 + ( y - p[ 2 ] ) ^ 2 )
         IF d <= nBest
            nBest := d ; r := p
         ENDIF
      NEXT
   NEXT
   IF lPer
      FOR EACH w IN aNear
         aP := w[ 3 ]
         FOR j := 1 TO Len( aP ) - 1
            nL2 := ( aP[ j + 1 ][ 1 ] - aP[ j ][ 1 ] ) ^ 2 + ( aP[ j + 1 ][ 2 ] - aP[ j ][ 2 ] ) ^ 2
            IF nL2 < 0.000000000001 ; LOOP ; ENDIF
            t := ( ( aFrom[ 1 ] - aP[ j ][ 1 ] ) * ( aP[ j + 1 ][ 1 ] - aP[ j ][ 1 ] ) + ( aFrom[ 2 ] - aP[ j ][ 2 ] ) * ( aP[ j + 1 ][ 2 ] - aP[ j ][ 2 ] ) ) / nL2
            IF t < 0.0 .OR. t > 1.0 ; LOOP ; ENDIF
            fx := aP[ j ][ 1 ] + t * ( aP[ j + 1 ][ 1 ] - aP[ j ][ 1 ] ) ; fy := aP[ j ][ 2 ] + t * ( aP[ j + 1 ][ 2 ] - aP[ j ][ 2 ] )
            d := Sqrt( ( x - fx ) ^ 2 + ( y - fy ) ^ 2 )
            IF d <= nBest
               nBest := d ; r := { fx, fy, "PER" }
            ENDIF
         NEXT
      NEXT
   ENDIF
   IF lInt
      FOR i := 1 TO Len( aNear ) - 1
         FOR k := i + 1 TO Len( aNear )
            IF aNear[ i ][ 6 ] == aNear[ k ][ 6 ] ; LOOP ; ENDIF
            aP := aNear[ i ][ 3 ] ; aQ := aNear[ k ][ 3 ]
            FOR j := 1 TO Len( aP ) - 1
               IF Max( aP[ j ][ 1 ], aP[ j + 1 ][ 1 ] ) < x - nTol .OR. Min( aP[ j ][ 1 ], aP[ j + 1 ][ 1 ] ) > x + nTol .OR. ;
                  Max( aP[ j ][ 2 ], aP[ j + 1 ][ 2 ] ) < y - nTol .OR. Min( aP[ j ][ 2 ], aP[ j + 1 ][ 2 ] ) > y + nTol
                  LOOP
               ENDIF
               FOR l := 1 TO Len( aQ ) - 1
                  q := Vwp_SegInt( aP[ j ][ 1 ], aP[ j ][ 2 ], aP[ j + 1 ][ 1 ], aP[ j + 1 ][ 2 ], aQ[ l ][ 1 ], aQ[ l ][ 2 ], aQ[ l + 1 ][ 1 ], aQ[ l + 1 ][ 2 ] )
                  IF q != NIL
                     d := Sqrt( ( x - q[ 1 ] ) ^ 2 + ( y - q[ 2 ] ) ^ 2 )
                     IF d <= nBest
                        nBest := d ; r := { q[ 1 ], q[ 2 ], "INT" }
                     ENDIF
                  ENDIF
               NEXT
            NEXT
         NEXT
      NEXT
   ENDIF
RETURN r
