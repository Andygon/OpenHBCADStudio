/* [extra] Fase 2 / B10: dibujo y edicion basica (comandos, grips, deshacer). Sin equivalente #[test] en Rust. */
#include "ocx.ch"

STATIC FUNCTION Ve_Pairs( ... )
   LOCAL a := hb_AParams(), s := "", i
   FOR i := 1 TO Len( a ) STEP 2
      s += PadL( hb_ntos( a[ i ] ), 3 ) + Chr( 10 ) + hb_CStr( a[ i + 1 ] ) + Chr( 10 )
   NEXT
RETURN s

STATIC FUNCTION Ve_Sess( cEnts )
   LOCAL c := "  0" + Chr( 10 ) + "SECTION" + Chr( 10 ) + "  2" + Chr( 10 ) + "ENTITIES" + Chr( 10 ) + cEnts + ;
              "  0" + Chr( 10 ) + "ENDSEC" + Chr( 10 ) + "  0" + Chr( 10 ) + "EOF" + Chr( 10 )
   LOCAL d := Dxr_ReadString( c )
   IF ! ( ValType( d ) == "H" ) ; RETURN NIL ; ENDIF
RETURN VwS_New( d )

STATIC FUNCTION Ve_Near( a, b ) ; RETURN Abs( a - b ) < 0.000001

STATIC FUNCTION Ve_N( s ) ; RETURN Len( s[ "scene" ][ "ents" ] )

STATIC FUNCTION Ve_First( s, cT )
   LOCAL k
   FOR EACH k IN hb_HKeys( s[ "scene" ][ "ents" ] )
      IF s[ "scene" ][ "ents" ][ k ][ "_type" ] == cT ; RETURN k ; ENDIF
   NEXT
RETURN ""

PROCEDURE T_ViewEdit()
   LOCAL s, r, e, k, c
   s := Ve_Sess( Ve_Pairs( 0, "LINE", 8, "0", 10, 0.0, 20, 0.0, 11, 10.0, 21, 0.0 ) )
   Chk( s != NIL .AND. Ve_N( s ) == 1, "[extra] edicion: sesion con una LINE" )
   // dibujo por comando
   VwK_Exec( s, "LINEA 0,5 10,5" )
   Chk( VwK_Exec( s, "" )[ 1 ] == "Comando terminado" .AND. Ve_N( s ) == 2, "[extra] edicion: LINEA con dos puntos crea una entidad e Intro termina" )
   VwK_Exec( s, "CIRCULO 5,5 2" )
   Chk( Ve_N( s ) == 3, "[extra] edicion: CIRCULO centro y radio" )
   k := Ve_First( s, "CIRCLE" )
   Chk( ! ( k == "" ) .AND. Ve_Near( s[ "scene" ][ "ents" ][ k ][ "radius" ], 2.0 ), "[extra] edicion: radio del circulo = 2" )
   VwK_Exec( s, "ARCO 0,0 3 0 90" )
   k := Ve_First( s, "ARC" )
   Chk( ! ( k == "" ) .AND. Ve_Near( s[ "scene" ][ "ents" ][ k ][ "end_angle" ], OCX_PI / 2.0 ), "[extra] edicion: ARCO en grados" )
   VwK_Exec( s, "PUNTO 1,1" )
   Chk( ! ( Ve_First( s, "POINT" ) == "" ), "[extra] edicion: PUNTO inline" )
   VwK_Exec( s, "PLINE 0,0 4,0 4,4" )
   k := Ve_First( s, "LWPOLYLINE" )
   Chk( ! ( k == "" ) .AND. Len( s[ "scene" ][ "ents" ][ k ][ "vertices" ] ) == 3 .AND. s[ "pend" ] == NIL, "[extra] edicion: PLINE inline crea polilinea de 3 vertices" )
   // modo interactivo (clics)
   VwK_Exec( s, "CIRCULO" )
   Chk( s[ "pend" ] != NIL, "[extra] edicion: CIRCULO sin argumentos queda pendiente" )
   VwK_Point( s, 20.0, 20.0 )
   r := VwK_Point( s, 23.0, 24.0 )
   Chk( s[ "pend" ] == NIL .AND. Ve_N( s ) == 7, "[extra] edicion: CIRCULO por dos clics" )
   Chk( r[ 3 ], "[extra] edicion: crear pide redibujar" )
   VwK_Exec( s, "LINEA" )
   VwK_Point( s, 0.0, 0.0 ) ; VwK_Point( s, 1.0, 1.0 ) ; VwK_Point( s, 2.0, 0.0 )
   VwK_Cancel( s )
   Chk( s[ "pend" ] == NIL .AND. Ve_N( s ) == 9, "[extra] edicion: LINEA por clics crea un segmento por punto y Esc cancela" )
   // capa actual
   VwK_Exec( s, "CAPA 0" )
   Chk( "0" $ VwK_Exec( s, "CAPA" )[ 1 ], "[extra] edicion: capa actual" )
   Chk( "No existe" $ VwK_Exec( s, "CAPA zzz" )[ 1 ], "[extra] edicion: capa inexistente" )
   // deshacer del dibujo
   c := Ve_N( s )
   VwK_Exec( s, "DESHACER" )
   Chk( Ve_N( s ) == c - 1, "[extra] edicion: DESHACER quita la ultima entidad" )
   // seleccion + mover / copiar / borrar / deshacer
   s := Ve_Sess( Ve_Pairs( 0, "LINE", 8, "0", 10, 0.0, 20, 0.0, 11, 10.0, 21, 0.0 ) )
   Chk( "Primero" $ VwK_Exec( s, "MOVER 1,1" )[ 1 ], "[extra] edicion: MOVER sin seleccion avisa" )
   VwK_Exec( s, "SELTODO" )
   VwK_Exec( s, "MOVER 5,3" )
   k := Ve_First( s, "LINE" ) ; e := s[ "scene" ][ "ents" ][ k ]
   Chk( Ve_Near( e[ "start" ][ 1 ], 5.0 ) .AND. Ve_Near( e[ "end" ][ 2 ], 3.0 ), "[extra] edicion: MOVER dx,dy desplaza la entidad" )
   VwK_Exec( s, "UNDO" )
   k := Ve_First( s, "LINE" ) ; e := s[ "scene" ][ "ents" ][ k ]
   Chk( Ve_Near( e[ "start" ][ 1 ], 0.0 ) .AND. Ve_Near( e[ "end" ][ 1 ], 10.0 ), "[extra] edicion: UNDO restaura el MOVER" )
   VwK_Exec( s, "SELTODO" )
   VwK_Exec( s, "COPIAR 0,10" )
   Chk( Ve_N( s ) == 2 .AND. Len( s[ "sel" ] ) == 1, "[extra] edicion: COPIAR crea una copia y la selecciona" )
   VwK_Exec( s, "BORRAR" )
   Chk( Ve_N( s ) == 1 .AND. Len( s[ "sel" ] ) == 0, "[extra] edicion: BORRAR quita la copia seleccionada" )
   VwK_Exec( s, "DESHACER" )
   Chk( Ve_N( s ) == 2, "[extra] edicion: DESHACER restaura lo borrado" )
   VwK_Exec( s, "DESHACER" )
   Chk( Ve_N( s ) == 1, "[extra] edicion: DESHACER quita la copia" )
   Chk( VwK_Exec( s, "DESHACER" )[ 1 ] == "Nada que deshacer", "[extra] edicion: pila vacia" )
   // mover con dos clics
   VwK_Exec( s, "SELTODO" )
   VwK_Exec( s, "MOVER" )
   VwK_Point( s, 1.0, 1.0 ) ; VwK_Point( s, 1.0, 4.0 )
   k := Ve_First( s, "LINE" ) ; e := s[ "scene" ][ "ents" ][ k ]
   Chk( Ve_Near( e[ "start" ][ 2 ], 3.0 ), "[extra] edicion: MOVER con punto base y destino" )
   // grips
   s := Ve_Sess( Ve_Pairs( 0, "LINE", 8, "0", 10, 0.0, 20, 0.0, 11, 10.0, 21, 0.0 ) + ;
                 Ve_Pairs( 0, "CIRCLE", 8, "0", 10, 20.0, 20, 20.0, 40, 5.0 ) )
   k := Ve_First( s, "LINE" )
   Chk( Vwe_GripMove( s, k, 3, 12.0, 7.0 ), "[extra] edicion: grip final de LINE" )
   e := s[ "scene" ][ "ents" ][ k ]
   Chk( Ve_Near( e[ "end" ][ 1 ], 12.0 ) .AND. Ve_Near( e[ "end" ][ 2 ], 7.0 ) .AND. Ve_Near( e[ "start" ][ 1 ], 0.0 ), "[extra] edicion: solo se mueve el extremo" )
   Chk( Vwe_GripMove( s, k, 2, 50.0, 50.0 ), "[extra] edicion: grip medio mueve toda la LINE" )
   Chk( Vwe_Undo( s ) .AND. Vwe_Undo( s ), "[extra] edicion: dos deshacer de grips" )
   e := s[ "scene" ][ "ents" ][ k ]
   Chk( Ve_Near( e[ "end" ][ 1 ], 10.0 ) .AND. Ve_Near( e[ "end" ][ 2 ], 0.0 ), "[extra] edicion: la LINE vuelve a su estado original" )
   k := Ve_First( s, "CIRCLE" )
   Vwe_GripMove( s, k, 2, 28.0, 20.0 )
   Chk( Ve_Near( s[ "scene" ][ "ents" ][ k ][ "radius" ], 8.0 ), "[extra] edicion: grip de cuadrante cambia el radio" )
   Vwe_GripMove( s, k, 1, 0.0, 0.0 )
   Chk( Ve_Near( s[ "scene" ][ "ents" ][ k ][ "center" ][ 1 ], 0.0 ) .AND. Ve_Near( s[ "scene" ][ "ents" ][ k ][ "radius" ], 8.0 ), "[extra] edicion: grip de centro traslada el circulo" )
   Chk( ! Vwe_GripMove( s, k, 9, 0.0, 0.0 ), "[extra] edicion: grip fuera de rango" )
   // guardar y releer
   r := VwK_Exec( s, "GUARDAR /tmp/ohb_t_edit.dxf" )
   Chk( "Guardado" $ r[ 1 ], "[extra] edicion: GUARDAR escribe el DXF" )
   c := Vws_LoadFile( "/tmp/ohb_t_edit.dxf" )
   Chk( c != NIL .AND. Len( Doc_ModelSpaceEntities( c ) ) == 2, "[extra] edicion: el DXF guardado se relee con 2 entidades" )
   hb_FileDelete( "/tmp/ohb_t_edit.dxf" )
RETURN
