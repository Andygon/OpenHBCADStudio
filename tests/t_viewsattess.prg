/* [extra] Fase 2 / B13b: teselado de caras planas de un SAT (cubo sintetico). Sin equivalente #[test] en Rust. */
#include "ocx.ch"

STATIC FUNCTION Vt_Cube()
   LOCAL aF := { { 0, 2, 3, 1, 0, 0, -1 }, { 4, 5, 7, 6, 0, 0, 1 }, { 0, 1, 5, 4, 0, -1, 0 }, { 2, 6, 7, 3, 0, 1, 0 }, { 0, 4, 6, 2, -1, 0, 0 }, { 1, 3, 7, 5, 1, 0, 0 } }
   LOCAL aEdges := {}, i, j, f, a, b, nE, nIdx, cS
   // indices: 0 body, 1 lump, 2 shell, 3..8 faces, 9..14 loops, 15..38 coedges, 39..50 aristas, 51..58 vertices, 59..66 puntos, 67..72 planos, 73..84 rectas
   LOCAL nF0 := 3, nL0 := 9, nC0 := 15, nE0 := 39, nV0 := 51, nP0 := 59, nS0 := 67, nR0 := 73
   FOR EACH f IN aF
      FOR i := 1 TO 4
         a := f[ i ] ; b := f[ i % 4 + 1 ]
         nE := AScan( aEdges, {| e | ( e[ 1 ] == Min( a, b ) .AND. e[ 2 ] == Max( a, b ) ) } )
         IF nE == 0 ; AAdd( aEdges, { Min( a, b ), Max( a, b ) } ) ; ENDIF
      NEXT
   NEXT
   cS := "700 0 1 0" + Chr( 10 ) + "@8 ACIS 7.0 @3 Foo @24 Mon Jan 01 00:00:00 2024" + Chr( 10 ) + "1 1 1" + Chr( 10 )
   cS += "-0 body $-1 -1 $-1 $-1 $1 $-1 #" + Chr( 10 )
   cS += "-1 lump $-1 -1 $-1 $-1 $2 $0 #" + Chr( 10 )
   cS += "-2 shell $-1 -1 $-1 $-1 $-1 $3 $-1 $1 #" + Chr( 10 )
   FOR i := 1 TO 6
      cS += "-" + hb_ntos( nF0 + i - 1 ) + " face $-1 -1 $-1 $" + IIf( i < 6, hb_ntos( nF0 + i ), "-1" ) + " $" + hb_ntos( nL0 + i - 1 ) + " $2 $-1 $" + hb_ntos( nS0 + i - 1 ) + " forward single #" + Chr( 10 )
   NEXT
   FOR i := 1 TO 6
      cS += "-" + hb_ntos( nL0 + i - 1 ) + " loop $-1 -1 $-1 $-1 $" + hb_ntos( nC0 + ( i - 1 ) * 4 ) + " $" + hb_ntos( nF0 + i - 1 ) + " #" + Chr( 10 )
   NEXT
   FOR i := 1 TO 6
      f := aF[ i ]
      FOR j := 1 TO 4
         a := f[ j ] ; b := f[ j % 4 + 1 ]
         nE := AScan( aEdges, {| e | ( e[ 1 ] == Min( a, b ) .AND. e[ 2 ] == Max( a, b ) ) } )
         nIdx := nC0 + ( i - 1 ) * 4 + j - 1
         cS += "-" + hb_ntos( nIdx ) + " coedge $-1 -1 $-1 $" + hb_ntos( nC0 + ( i - 1 ) * 4 + j % 4 ) + " $" + hb_ntos( nC0 + ( i - 1 ) * 4 + ( j + 2 ) % 4 ) + ;
               " $-1 $" + hb_ntos( nE0 + nE - 1 ) + " " + IIf( a < b, "forward", "reversed" ) + " $" + hb_ntos( nL0 + i - 1 ) + " #" + Chr( 10 )
      NEXT
   NEXT
   FOR i := 1 TO 12
      cS += "-" + hb_ntos( nE0 + i - 1 ) + " edge $-1 -1 $-1 $" + hb_ntos( nV0 + aEdges[ i ][ 1 ] ) + " 0 $" + hb_ntos( nV0 + aEdges[ i ][ 2 ] ) + " 1 $-1 $" + hb_ntos( nR0 + i - 1 ) + " forward @7 unknown #" + Chr( 10 )
   NEXT
   FOR i := 0 TO 7
      cS += "-" + hb_ntos( nV0 + i ) + " vertex $-1 -1 $-1 $-1 $" + hb_ntos( nP0 + i ) + " #" + Chr( 10 )
   NEXT
   FOR i := 0 TO 7
      cS += "-" + hb_ntos( nP0 + i ) + " point $-1 -1 $-1 " + hb_ntos( i % 2 ) + " " + hb_ntos( Int( i / 2 ) % 2 ) + " " + hb_ntos( Int( i / 4 ) ) + " #" + Chr( 10 )
   NEXT
   FOR i := 1 TO 6
      f := aF[ i ]
      cS += "-" + hb_ntos( nS0 + i - 1 ) + " plane-surface $-1 -1 $-1 " + hb_ntos( Max( f[ 5 ], 0 ) ) + " " + hb_ntos( Max( f[ 6 ], 0 ) ) + " " + hb_ntos( Max( f[ 7 ], 0 ) ) + " " + hb_ntos( f[ 5 ] ) + " " + hb_ntos( f[ 6 ] ) + " " + hb_ntos( f[ 7 ] ) + " 1 0 0 forward_v I I I I #" + Chr( 10 )
   NEXT
   FOR i := 1 TO 12
      cS += "-" + hb_ntos( nR0 + i - 1 ) + " straight-curve $-1 -1 $-1 0 0 0 1 0 0 I I #" + Chr( 10 )
   NEXT
   cS += "End-of-ACIS-data" + Chr( 10 )
RETURN cS

PROCEDURE T_ViewSatTess()
   LOCAL sat := Sat_Parse( Vt_Cube() ), r, t, nA := 0.0, ok := .T., p, v1, v2, cr
   Chk( sat != NIL .AND. Len( sat[ "records" ] ) == 85, "[extra] sattess: el cubo sintetico se parsea (85 registros)" )
   r := Sat_Tess( sat )
   Chk( r[ "faces" ] == 6 .AND. r[ "skipped" ] == 0, "[extra] sattess: 6 caras planas, ninguna saltada" )
   Chk( Len( r[ "tris" ] ) == 12, "[extra] sattess: 12 triangulos (2 por cara)" )
   FOR EACH t IN r[ "tris" ]
      v1 := { t[ 2 ][ 1 ] - t[ 1 ][ 1 ], t[ 2 ][ 2 ] - t[ 1 ][ 2 ], t[ 2 ][ 3 ] - t[ 1 ][ 3 ] }
      v2 := { t[ 3 ][ 1 ] - t[ 1 ][ 1 ], t[ 3 ][ 2 ] - t[ 1 ][ 2 ], t[ 3 ][ 3 ] - t[ 1 ][ 3 ] }
      cr := { v1[ 2 ] * v2[ 3 ] - v1[ 3 ] * v2[ 2 ], v1[ 3 ] * v2[ 1 ] - v1[ 1 ] * v2[ 3 ], v1[ 1 ] * v2[ 2 ] - v1[ 2 ] * v2[ 1 ] }
      nA += Sqrt( cr[ 1 ] ^ 2 + cr[ 2 ] ^ 2 + cr[ 3 ] ^ 2 ) / 2.0
      p := cr[ 1 ] * t[ 4 ][ 1 ] + cr[ 2 ] * t[ 4 ][ 2 ] + cr[ 3 ] * t[ 4 ][ 3 ]
      IF p <= 0.0 ; ok := .F. ; ENDIF
   NEXT
   Chk( Abs( nA - 6.0 ) < 0.000001, "[extra] sattess: area total 6 (cubo unidad)" )
   Chk( ok, "[extra] sattess: todos los triangulos miran hacia la normal saliente" )
RETURN
