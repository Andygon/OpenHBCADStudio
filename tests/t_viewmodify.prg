/* [extra] Fase 2 / modules/draw/modify: OFFSET, TRIM, EXTEND, FILLET, CHAMFER, EXPLODE. Sin equivalente #[test] en Rust. */
#include "ocx.ch"

STATIC FUNCTION Vy_Pairs( ... )
   LOCAL a := hb_AParams(), s := "", i
   FOR i := 1 TO Len( a ) STEP 2
      s += PadL( hb_ntos( a[ i ] ), 3 ) + Chr( 10 ) + hb_CStr( a[ i + 1 ] ) + Chr( 10 )
   NEXT
RETURN s

STATIC FUNCTION Vy_Ln( x1, y1, x2, y2 ) ; RETURN Vy_Pairs( 0, "LINE", 8, "0", 10, x1, 20, y1, 11, x2, 21, y2 )

STATIC FUNCTION Vy_Sess( cEnts )
   LOCAL c := "  0" + Chr( 10 ) + "SECTION" + Chr( 10 ) + "  2" + Chr( 10 ) + "ENTITIES" + Chr( 10 ) + cEnts + ;
              "  0" + Chr( 10 ) + "ENDSEC" + Chr( 10 ) + "  0" + Chr( 10 ) + "EOF" + Chr( 10 )
   LOCAL d := Dxr_ReadString( c )
   IF ! ( ValType( d ) == "H" ) ; RETURN NIL ; ENDIF
RETURN VwS_New( d )

STATIC FUNCTION Vy_Near( a, b ) ; RETURN Abs( a - b ) < 0.000001

STATIC FUNCTION Vy_All( s, cT )
   LOCAL k, a := {}
   FOR EACH k IN hb_HKeys( s[ "scene" ][ "ents" ] )
      IF s[ "scene" ][ "ents" ][ k ][ "_type" ] == cT ; AAdd( a, s[ "scene" ][ "ents" ][ k ] ) ; ENDIF
   NEXT
RETURN a

PROCEDURE T_ViewModify()
   LOCAL s, a, e
   s := Vy_Sess( Vy_Ln( 0.0, 0.0, 10.0, 0.0 ) )
   VwK_Exec( s, "OFFSET 2 5,0 5,5" )
   a := Vy_All( s, "LINE" )
   Chk( Len( a ) == 2 .AND. ( Vy_Near( a[ 1 ][ "start" ][ 2 ], 2.0 ) .OR. Vy_Near( a[ 2 ][ "start" ][ 2 ], 2.0 ) ), "[extra] modify: OFFSET de una recta a +2" )
   s := Vy_Sess( Vy_Pairs( 0, "CIRCLE", 8, "0", 10, 0.0, 20, 0.0, 40, 5.0 ) )
   VwK_Exec( s, "OFFSET 1 5,0 10,0" )
   a := Vy_All( s, "CIRCLE" )
   Chk( Len( a ) == 2 .AND. ( Vy_Near( a[ 1 ][ "radius" ], 6.0 ) .OR. Vy_Near( a[ 2 ][ "radius" ], 6.0 ) ), "[extra] modify: OFFSET exterior de un circulo (r 6)" )
   VwK_Exec( s, "OFFSET 9 5,0 1,0" )
   Chk( Len( Vy_All( s, "CIRCLE" ) ) == 2, "[extra] modify: OFFSET que colapsa el radio no crea nada" )
   s := Vy_Sess( Vy_Ln( 0.0, 0.0, 10.0, 0.0 ) + Vy_Ln( 5.0, -5.0, 5.0, 5.0 ) )
   VwK_Exec( s, "TRIM 8,0" )
   a := Vy_All( s, "LINE" )
   Chk( Len( a ) == 2 .AND. ( Vy_Near( a[ 1 ][ "end" ][ 1 ], 5.0 ) .OR. Vy_Near( a[ 2 ][ "end" ][ 1 ], 5.0 ) ), "[extra] modify: TRIM recorta el lado clicado hasta la arista" )
   VwK_Exec( s, "DESHACER" )
   a := Vy_All( s, "LINE" )
   Chk( Vy_Near( a[ 1 ][ "end" ][ 1 ], 10.0 ) .OR. Vy_Near( a[ 2 ][ "end" ][ 1 ], 10.0 ), "[extra] modify: DESHACER restaura la recta recortada" )
   s := Vy_Sess( Vy_Ln( 0.0, 0.0, 10.0, 0.0 ) + Vy_Ln( 5.0, -5.0, 5.0, 5.0 ) )
   VwK_Exec( s, "TRIM 2,0" )
   Chk( Len( Vy_All( s, "LINE" ) ) == 2, "[extra] modify: TRIM del extremo izquierdo mantiene 2 rectas" )
   s := Vy_Sess( Vy_Ln( 0.0, 0.0, 3.0, 0.0 ) + Vy_Ln( 5.0, -5.0, 5.0, 5.0 ) )
   VwK_Exec( s, "EXTEND 3,0" )
   a := Vy_All( s, "LINE" )
   Chk( Vy_Near( a[ 1 ][ "end" ][ 1 ], 5.0 ) .OR. Vy_Near( a[ 2 ][ "end" ][ 1 ], 5.0 ), "[extra] modify: EXTEND alarga hasta la arista" )
   s := Vy_Sess( Vy_Ln( 0.0, 0.0, 10.0, 0.0 ) + Vy_Ln( 0.0, 0.0, 0.0, 10.0 ) )
   VwK_Exec( s, "FILLET 2 8,0 0,8" )
   a := Vy_All( s, "ARC" )
   Chk( Len( a ) == 1 .AND. Vy_Near( a[ 1 ][ "radius" ], 2.0 ) .AND. Vy_Near( a[ 1 ][ "center" ][ 1 ], 2.0 ) .AND. Vy_Near( a[ 1 ][ "center" ][ 2 ], 2.0 ), "[extra] modify: FILLET r=2 crea el arco centrado en (2,2)" )
   e := Vy_All( s, "LINE" )
   Chk( Len( e ) == 2 .AND. ( Vy_Near( e[ 1 ][ "start" ][ 1 ], 2.0 ) .OR. Vy_Near( e[ 1 ][ "end" ][ 1 ], 2.0 ) .OR. Vy_Near( e[ 1 ][ "start" ][ 2 ], 2.0 ) .OR. Vy_Near( e[ 1 ][ "end" ][ 2 ], 2.0 ) ), "[extra] modify: FILLET recorta las rectas a los puntos de tangencia" )
   s := Vy_Sess( Vy_Ln( 0.0, 0.0, 10.0, 0.0 ) + Vy_Ln( 0.0, 0.0, 0.0, 10.0 ) )
   VwK_Exec( s, "FILLET 0 8,0 0,8" )
   Chk( Len( Vy_All( s, "ARC" ) ) == 0 .AND. Len( Vy_All( s, "LINE" ) ) == 2, "[extra] modify: FILLET 0 solo forma la esquina" )
   s := Vy_Sess( Vy_Ln( 0.0, 0.0, 10.0, 0.0 ) + Vy_Ln( 0.0, 0.0, 0.0, 10.0 ) )
   VwK_Exec( s, "CHAMFER 2 8,0 0,8" )
   Chk( Len( Vy_All( s, "LINE" ) ) == 3, "[extra] modify: CHAMFER anade la recta del chaflan" )
   s := Vy_Sess( Vy_Ln( 0.0, 0.0, 10.0, 0.0 ) + Vy_Ln( 0.0, 1.0, 10.0, 1.0 ) )
   Chk( VwK_Exec( s, "FILLET 1 5,0 5,1" )[ 1 ] == "Las rectas son paralelas", "[extra] modify: FILLET entre paralelas se rechaza" )
   s := Vy_Sess( "" )
   VwK_Exec( s, "RECTANG 0,0 4,3" )
   VwK_Exec( s, "SELTODO" )
   VwK_Exec( s, "EXPLODE" )
   Chk( Len( Vy_All( s, "LINE" ) ) == 4 .AND. Len( Vy_All( s, "LWPOLYLINE" ) ) == 0, "[extra] modify: EXPLODE de un rectangulo da 4 rectas" )
RETURN
