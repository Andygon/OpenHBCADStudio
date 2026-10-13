/* [extra] Fase 2 / B5-B7: seleccion, grips, capas y linea de comandos. Sin equivalente #[test] en Rust. */
#include "ocx.ch"

STATIC FUNCTION Vc_Pairs( ... )
   LOCAL a := hb_AParams(), s := "", i
   FOR i := 1 TO Len( a ) STEP 2
      s += PadL( hb_ntos( a[ i ] ), 3 ) + Chr( 10 ) + hb_CStr( a[ i + 1 ] ) + Chr( 10 )
   NEXT
RETURN s

STATIC FUNCTION Vc_Sess( cEnts )
   LOCAL c := "  0" + Chr( 10 ) + "SECTION" + Chr( 10 ) + "  2" + Chr( 10 ) + "ENTITIES" + Chr( 10 ) + cEnts + ;
              "  0" + Chr( 10 ) + "ENDSEC" + Chr( 10 ) + "  0" + Chr( 10 ) + "EOF" + Chr( 10 )
   LOCAL d := Dxr_ReadString( c )
   IF ! ( ValType( d ) == "H" ) ; RETURN NIL ; ENDIF
RETURN VwS_New( d )

STATIC FUNCTION Vc_H( s, cType )
   LOCAL k
   FOR EACH k IN hb_HKeys( s[ "scene" ][ "ents" ] )
      IF s[ "scene" ][ "ents" ][ k ][ "_type" ] == cType ; RETURN k ; ENDIF
   NEXT
RETURN ""

PROCEDURE T_ViewCmd()
   LOCAL s, r, cE, a, h, hL, hC
   cE := Vc_Pairs( 0, "LINE", 5, "A1", 8, "0", 10, 0.0, 20, 0.0, 11, 10.0, 21, 0.0 ) + ;
         Vc_Pairs( 0, "CIRCLE", 5, "A2", 8, "0", 10, 20.0, 20, 20.0, 40, 5.0 )
   s := Vc_Sess( cE )
   Chk( s != NIL .AND. Len( s[ "scene" ][ "ents" ] ) == 2, "[extra] visor: la escena indexa entidades por handle" )
   hL := Vc_H( s, "LINE" ) ; hC := Vc_H( s, "CIRCLE" )
   Chk( Vwp_Pick( s[ "scene" ], 5.0, 0.2, 0.5 ) == hL, "[extra] visor: pick sobre la LINE" )
   Chk( Vwp_Pick( s[ "scene" ], 5.0, 3.0, 0.5 ) == NIL, "[extra] visor: pick lejos no selecciona" )
   Chk( Vwp_Pick( s[ "scene" ], 25.0, 20.0, 0.5 ) == hC, "[extra] visor: pick sobre la CIRCLE" )
   Chk( Vwp_Pick( s[ "scene" ], 20.0, 20.0, 0.5 ) == NIL, "[extra] visor: el centro de la CIRCLE no es borde" )
   a := Vwp_Box( s[ "scene" ], -1.0, -1.0, 11.0, 1.0 )
   Chk( Len( a ) == 1 .AND. a[ 1 ] == hL, "[extra] visor: caja ventana (izq a der) toma lo que queda dentro" )
   a := Vwp_Box( s[ "scene" ], 5.0, -1.0, 12.0, 1.0 )
   Chk( Len( a ) == 0, "[extra] visor: caja ventana no toma lo parcial" )
   a := Vwp_Box( s[ "scene" ], 12.0, 1.0, 5.0, -1.0 )
   Chk( Len( a ) == 1 .AND. a[ 1 ] == hL, "[extra] visor: caja captura (der a izq) toma lo que toca" )
   a := Vwp_Box( s[ "scene" ], 30.0, 30.0, 0.0, 0.0 )
   Chk( Len( a ) == 2, "[extra] visor: captura grande toma las dos" )
   a := Vwp_Grips( s[ "scene" ][ "ents" ][ hL ] )
   Chk( Len( a ) == 3 .AND. Abs( a[ 2 ][ 1 ] - 5.0 ) < 0.000001, "[extra] visor: LINE tiene 3 grips (extremos y medio)" )
   a := Vwp_Grips( s[ "scene" ][ "ents" ][ hC ] )
   Chk( Len( a ) == 5, "[extra] visor: CIRCLE tiene 5 grips (centro y cuadrantes)" )
   h := hb_Hash( hL, .T. )
   a := Vwp_GripAt( s[ "scene" ], h, 9.9, 0.1, 0.5 )
   Chk( a != NIL .AND. a[ 2 ] == 3, "[extra] visor: grip mas cercano es el extremo final" )
   Chk( Vwp_GripAt( s[ "scene" ], h, 3.0, 3.0, 0.5 ) == NIL, "[extra] visor: sin grip cerca" )
   // linea de comandos
   r := VwK_Exec( s, "ZOOM E" )
   Chk( r[ 3 ] .AND. s[ "cam" ][ "scale" ] > 0, "[extra] visor: ZOOM E pide redibujar" )
   r := VwK_Exec( s, "zoom 2x" )
   Chk( r[ 3 ] .AND. ! ( VwK_Exec( s, "ZOOM zzz" )[ 3 ] ), "[extra] visor: ZOOM factor valido y opcion invalida" )
   VwK_Exec( s, "PAN 7,8" )
   Chk( s[ "cam" ][ "cx" ] == 7.0 .AND. s[ "cam" ][ "cy" ] == 8.0, "[extra] visor: PAN centra la vista" )
   r := VwK_Exec( s, "ZOOM W 0,0 10,10" )
   Chk( r[ 3 ] .AND. Abs( s[ "cam" ][ "cx" ] - 5.0 ) < 0.000001, "[extra] visor: ZOOM W centra la ventana" )
   r := VwK_Exec( s, "DIST 0,0 3,4" )
   Chk( "5.0000" $ r[ 1 ], "[extra] visor: DIST 3-4-5" )
   r := VwK_Exec( s, "ID 1 2" )
   Chk( "X=1.0000" $ r[ 1 ] .AND. "Y=2.0000" $ r[ 1 ], "[extra] visor: ID con dos tokens" )
   r := VwK_Exec( s, "CAPAS" )
   Chk( r[ 2 ] .AND. "[x] 0" $ r[ 1 ], "[extra] visor: CAPAS lista la capa 0 encendida" )
   r := VwK_Exec( s, "APAGAR 0" )
   Chk( r[ 3 ] .AND. Len( s[ "scene" ][ "ents" ] ) == 0 .AND. Vws_WireCount( s[ "scene" ] ) == 0, "[extra] visor: APAGAR oculta las entidades de la capa" )
   VwK_Exec( s, "ENCENDER 0" )
   Chk( Vws_WireCount( s[ "scene" ] ) >= 2, "[extra] visor: ENCENDER las devuelve" )
   r := VwK_Exec( s, "APAGAR noexiste" )
   Chk( "No existe" $ r[ 1 ], "[extra] visor: capa inexistente se avisa" )
   VwK_Exec( s, "LAYOFF 0" ) ; VwK_Exec( s, "LAYALL" )
   Chk( Vws_WireCount( s[ "scene" ] ) >= 2, "[extra] visor: LAYALL enciende todo" )
   VwK_Exec( s, "SELTODO" )
   Chk( Len( s[ "sel" ] ) == 2, "[extra] visor: SELTODO" )
   r := VwK_Exec( s, "LISTA" )
   Chk( r[ 2 ] .AND. "LINE" $ r[ 1 ], "[extra] visor: LISTA de la seleccion" )
   VwK_Exec( s, "DESELECCIONAR" )
   Chk( Len( s[ "sel" ] ) == 0, "[extra] visor: DESELECCIONAR" )
   r := VwK_Exec( s, "LISTA" )
   Chk( "Entidades por tipo" $ r[ 1 ], "[extra] visor: LISTA sin seleccion da resumen" )
   r := VwK_Exec( s, "blabla" )
   Chk( "desconocido" $ r[ 1 ], "[extra] visor: comando desconocido" )
   Chk( "ZOOM" $ VwK_Exec( s, "AYUDA" )[ 1 ], "[extra] visor: AYUDA" )
   Chk( Empty( VwK_Exec( s, "   " )[ 1 ] ), "[extra] visor: linea vacia" )
   // snap
   a := Vwp_SnapPts( s[ "scene" ][ "ents" ][ hL ] )
   Chk( Len( a ) == 3 .AND. a[ 2 ][ 3 ] == "MID", "[extra] snap: LINE END MID END" )
   a := Vwp_Snap( s[ "scene" ], "END MID CEN", 9.8, 0.3, 1.0 )
   Chk( a != NIL .AND. a[ 3 ] == "END" .AND. Abs( a[ 1 ] - 10.0 ) < 0.000001, "[extra] snap: engancha el extremo" )
   a := Vwp_Snap( s[ "scene" ], "END MID CEN", 5.2, 0.2, 1.0 )
   Chk( a != NIL .AND. a[ 3 ] == "MID" .AND. Abs( a[ 1 ] - 5.0 ) < 0.000001, "[extra] snap: engancha el punto medio" )
   a := Vwp_Snap( s[ "scene" ], "END MID CEN", 20.3, 19.8, 1.0 )
   Chk( a != NIL .AND. a[ 3 ] == "CEN", "[extra] snap: engancha el centro del circulo" )
   Chk( Vwp_Snap( s[ "scene" ], "END", 5.2, 0.2, 1.0 ) == NIL, "[extra] snap: modo MID desactivado no engancha" )
   Chk( Vwp_Snap( s[ "scene" ], "END MID CEN", 50.0, 50.0, 1.0 ) == NIL, "[extra] snap: lejos no engancha" )
   a := Vwp_Snap( s[ "scene" ], "QUA", 25.0, 20.0, 0.5 )
   Chk( a != NIL .AND. a[ 3 ] == "QUA", "[extra] snap: cuadrante del circulo" )
   VwK_Exec( s, "SNAP OFF" )
   Chk( VwK_SnapAt( s, 10.0, 0.0, 1.0 ) == NIL, "[extra] snap: SNAP OFF" )
   VwK_Exec( s, "SNAP ON" )
   Chk( VwK_SnapAt( s, 10.0, 0.0, 1.0 ) != NIL, "[extra] snap: SNAP ON" )
   VwK_Exec( s, "SNAP MID" )
   Chk( ! ( "MID" $ s[ "snap" ][ "modes" ] ), "[extra] snap: SNAP MID alterna el modo" )
   VwK_Exec( s, "SNAP TODO" )
   Chk( "QUA" $ s[ "snap" ][ "modes" ], "[extra] snap: SNAP TODO" )
   // HATCH
   cE := Vc_Pairs( 0, "HATCH", 5, "H1", 8, "0", 2, "SOLID", 70, 1, 71, 0, 91, 1, 92, 1, 93, 4 ) + ;
         Vc_Pairs( 72, 1, 10, 0.0, 20, 0.0, 11, 4.0, 21, 0.0, 72, 1, 10, 4.0, 20, 0.0, 11, 4.0, 21, 4.0 ) + ;
         Vc_Pairs( 72, 1, 10, 4.0, 20, 4.0, 11, 0.0, 21, 4.0, 72, 1, 10, 0.0, 20, 4.0, 11, 0.0, 21, 0.0, 97, 0, 75, 0, 76, 1, 98, 0 )
   s := Vc_Sess( cE )
   Chk( s != NIL .AND. Len( s[ "scene" ][ "fills" ] ) == 1, "[extra] visor: HATCH -> 1 relleno" )
   IF s != NIL .AND. Len( s[ "scene" ][ "fills" ] ) == 1
      Chk( s[ "scene" ][ "fills" ][ 1 ][ 4 ] .AND. Len( s[ "scene" ][ "fills" ][ 1 ][ 2 ][ 1 ] ) >= 4, "[extra] visor: relleno solido con lazo de 4 aristas" )
   ELSE
      Chk( .F., "[extra] visor: relleno solido con lazo de 4 aristas" )
   ENDIF
RETURN
