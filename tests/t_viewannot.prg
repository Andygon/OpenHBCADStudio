/* [extra] Fase 2 / annotate e insert: TEXT, MTEXT, INSERT, DIM*. Sin equivalente #[test] en Rust. */
#include "ocx.ch"

STATIC FUNCTION Vq_Sess()
   LOCAL c := "  0" + Chr( 10 ) + "SECTION" + Chr( 10 ) + "  2" + Chr( 10 ) + "ENTITIES" + Chr( 10 ) + ;
              "  0" + Chr( 10 ) + "ENDSEC" + Chr( 10 ) + "  0" + Chr( 10 ) + "EOF" + Chr( 10 )
   LOCAL d := Dxr_ReadString( c )
   IF ! ( ValType( d ) == "H" ) ; RETURN NIL ; ENDIF
RETURN VwS_New( d )

STATIC FUNCTION Vq_Near( a, b ) ; RETURN Abs( a - b ) < 0.000001

STATIC FUNCTION Vq_All( s, cT )
   LOCAL k, a := {}
   FOR EACH k IN hb_HKeys( s[ "scene" ][ "ents" ] )
      IF s[ "scene" ][ "ents" ][ k ][ "_type" ] == cT ; AAdd( a, s[ "scene" ][ "ents" ][ k ] ) ; ENDIF
   NEXT
RETURN a

PROCEDURE T_ViewAnnot()
   LOCAL s := Vq_Sess(), a, g, n0
   VwK_Exec( s, "TEXT 1,2 2.5 Hola mundo" )
   a := Vq_All( s, "TEXT" )
   Chk( Len( a ) == 1 .AND. a[ 1 ][ "value" ] == "Hola mundo" .AND. Vq_Near( a[ 1 ][ "height" ], 2.5 ), "[extra] annot: TEXT con varias palabras y altura" )
   Chk( Len( s[ "scene" ][ "texts" ] ) >= 1, "[extra] annot: el texto llega a la escena" )
   VwK_Exec( s, "MTEXT 0,0 3 Linea" )
   Chk( Len( Vq_All( s, "MTEXT" ) ) == 1, "[extra] annot: MTEXT creado" )
   Chk( VwK_Exec( s, "TEXT 1,2" )[ 1 ] == "Uso: TEXT x,y altura texto", "[extra] annot: TEXT sin altura da el uso" )
   Chk( VwK_Exec( s, "INSERT NOEXISTE 0,0" )[ 1 ] == "INSERT: no existe el bloque NOEXISTE", "[extra] annot: INSERT de bloque inexistente" )
   n0 := Len( s[ "scene" ][ "wires" ] )
   VwK_Exec( s, "DIMLINEAR 0,0 10,0 5,3 1" )
   a := Vq_All( s, "DIMENSION_LINEAR" )
   Chk( Len( a ) == 1 .AND. Vq_Near( a[ 1 ][ "base" ][ "actual_measurement" ], 10.0 ), "[extra] annot: DIMLINEAR mide 10" )
   Chk( Len( s[ "scene" ][ "wires" ] ) - n0 >= 7, "[extra] annot: la cota se dibuja (2 ref + linea + 4 flechas)" )
   g := Vwd_Geom( s[ "doc" ], a[ 1 ] )
   Chk( g != NIL .AND. g[ 2 ][ 1 ][ 5 ] == "10" .AND. Vq_Near( g[ 1 ][ 3 ][ 1 ][ 2 ], 3.0 ), "[extra] annot: texto '10' y linea de cota a y=3" )
   VwK_Exec( s, "DIMALIGNED 0,0 3,4 0,0 1" )
   g := Vwd_Geom( s[ "doc" ], Vq_All( s, "DIMENSION_ALIGNED" )[ 1 ] )
   Chk( g != NIL .AND. g[ 2 ][ 1 ][ 5 ] == "5", "[extra] annot: DIMALIGNED 3-4-5 da 5" )
   VwK_Exec( s, "DIMRADIUS 0,0 5,0 1" )
   g := Vwd_Geom( s[ "doc" ], Vq_All( s, "DIMENSION_RADIUS" )[ 1 ] )
   Chk( g != NIL .AND. g[ 2 ][ 1 ][ 5 ] == "R5", "[extra] annot: DIMRADIUS da R5" )
   VwK_Exec( s, "DESHACER" )
   Chk( Len( Vq_All( s, "DIMENSION_RADIUS" ) ) == 0, "[extra] annot: DESHACER quita la cota" )
RETURN
