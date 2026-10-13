/* [extra] Fase 2 / modules/draw: ROTAR, ESCALA, SIMETRIA, RECTANG, POLIGONO. Sin equivalente #[test] en Rust. */
#include "ocx.ch"

STATIC FUNCTION Vx_Pairs( ... )
   LOCAL a := hb_AParams(), s := "", i
   FOR i := 1 TO Len( a ) STEP 2
      s += PadL( hb_ntos( a[ i ] ), 3 ) + Chr( 10 ) + hb_CStr( a[ i + 1 ] ) + Chr( 10 )
   NEXT
RETURN s

STATIC FUNCTION Vx_Sess()
   LOCAL c := "  0" + Chr( 10 ) + "SECTION" + Chr( 10 ) + "  2" + Chr( 10 ) + "ENTITIES" + Chr( 10 ) + ;
              Vx_Pairs( 0, "LINE", 8, "0", 10, 0.0, 20, 0.0, 11, 10.0, 21, 0.0 ) + ;
              "  0" + Chr( 10 ) + "ENDSEC" + Chr( 10 ) + "  0" + Chr( 10 ) + "EOF" + Chr( 10 )
   LOCAL d := Dxr_ReadString( c )
   IF ! ( ValType( d ) == "H" ) ; RETURN NIL ; ENDIF
RETURN VwS_New( d )

STATIC FUNCTION Vx_Near( a, b ) ; RETURN Abs( a - b ) < 0.000001

STATIC FUNCTION Vx_Line( s )
   LOCAL k
   FOR EACH k IN hb_HKeys( s[ "scene" ][ "ents" ] )
      IF s[ "scene" ][ "ents" ][ k ][ "_type" ] == "LINE" ; RETURN s[ "scene" ][ "ents" ][ k ] ; ENDIF
   NEXT
RETURN NIL

STATIC FUNCTION Vx_Count( s, cT )
   LOCAL k, n := 0
   FOR EACH k IN hb_HKeys( s[ "scene" ][ "ents" ] )
      IF s[ "scene" ][ "ents" ][ k ][ "_type" ] == cT ; n++ ; ENDIF
   NEXT
RETURN n

PROCEDURE T_ViewXform()
   LOCAL s := Vx_Sess(), e, k
   Chk( s != NIL, "[extra] xform: sesion con una LINE" )
   Chk( VwK_Exec( s, "ROTAR 0,0 90" )[ 1 ] == "Primero seleccione objetos (clic, caja o SELTODO)", "[extra] xform: ROTAR exige seleccion" )
   VwK_Exec( s, "SELTODO" )
   VwK_Exec( s, "ROTAR 0,0 90" )
   e := Vx_Line( s )
   Chk( Vx_Near( e[ "end" ][ 1 ], 0.0 ) .AND. Vx_Near( e[ "end" ][ 2 ], 10.0 ), "[extra] xform: ROTAR 90 grados gira el extremo a (0,10)" )
   VwK_Exec( s, "ESCALA 0,0 2" )
   e := Vx_Line( s )
   Chk( Vx_Near( e[ "end" ][ 2 ], 20.0 ), "[extra] xform: ESCALA x2 desde el origen" )
   VwK_Exec( s, "ROTAR 0,0" )
   Chk( s[ "pend" ] != NIL, "[extra] xform: ROTAR con solo la base queda pendiente" )
   VwK_Exec( s, "-90" )
   e := Vx_Line( s )
   Chk( s[ "pend" ] == NIL .AND. Vx_Near( e[ "end" ][ 1 ], 20.0 ) .AND. Vx_Near( e[ "end" ][ 2 ], 0.0 ), "[extra] xform: angulo escrito tras la base (-90)" )
   VwK_Exec( s, "SIMETRIA 0,1 1,1" )
   Chk( Vx_Count( s, "LINE" ) == 2, "[extra] xform: SIMETRIA conserva el original y crea el reflejo" )
   VwK_Exec( s, "RECTANG 0,0 4,3" )
   k := Vx_Count( s, "LWPOLYLINE" )
   Chk( k == 1, "[extra] xform: RECTANG crea una polilinea" )
   VwK_Exec( s, "POLIGONO 5 0,0 3,0" )
   Chk( Vx_Count( s, "LWPOLYLINE" ) == 2, "[extra] xform: POLIGONO 5 lados crea otra polilinea" )
   VwK_Exec( s, "DESHACER" )
   Chk( Vx_Count( s, "LWPOLYLINE" ) == 1, "[extra] xform: DESHACER quita el poligono" )
RETURN
