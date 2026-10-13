/* [extra] Fase 2 / B12: camara 3D (orbita, vistas) y z en la escena. Sin equivalente #[test] en Rust. */
#include "ocx.ch"

STATIC FUNCTION V3_Pairs( ... )
   LOCAL a := hb_AParams(), s := "", i
   FOR i := 1 TO Len( a ) STEP 2
      s += PadL( hb_ntos( a[ i ] ), 3 ) + Chr( 10 ) + hb_CStr( a[ i + 1 ] ) + Chr( 10 )
   NEXT
RETURN s

STATIC FUNCTION V3_Sess( cEnts )
   LOCAL c := "  0" + Chr( 10 ) + "SECTION" + Chr( 10 ) + "  2" + Chr( 10 ) + "ENTITIES" + Chr( 10 ) + cEnts + ;
              "  0" + Chr( 10 ) + "ENDSEC" + Chr( 10 ) + "  0" + Chr( 10 ) + "EOF" + Chr( 10 )
   LOCAL d := Dxr_ReadString( c )
   IF ! ( ValType( d ) == "H" ) ; RETURN NIL ; ENDIF
RETURN VwS_New( d )

STATIC FUNCTION V3_Near( a, b ) ; RETURN Abs( a - b ) < 0.000001

PROCEDURE T_View3D()
   LOCAL c, a, b, s, o, w
   c := VwC_SetSize( VwC_New(), 800, 600 )
   c[ "cx" ] := 10.0 ; c[ "cy" ] := 20.0 ; c[ "scale" ] := 2.0
   Chk( ! VwC_Is3D( c ), "[extra] 3D: la camara nueva es la planta" )
   a := VwC_Proj( c, 15.0, 25.0, 7.0 ) ; b := VwC_W2S( c, 15.0, 25.0 )
   Chk( V3_Near( a[ 1 ], b[ 1 ] ) .AND. V3_Near( a[ 2 ], b[ 2 ] ), "[extra] 3D: en planta la proyeccion coincide con W2S y z no cuenta" )
   VwC_View( c, "FRONTAL" )
   Chk( VwC_Is3D( c ), "[extra] 3D: la vista frontal es 3D" )
   a := VwC_Proj( c, 10.0, 20.0, 5.0 )
   Chk( V3_Near( a[ 1 ], 400.0 ) .AND. V3_Near( a[ 2 ], 300.0 - 10.0 ), "[extra] 3D: frontal, z sube en pantalla (5 * escala 2)" )
   a := VwC_Proj( c, 13.0, 99.0, 0.0 )
   Chk( V3_Near( a[ 1 ], 406.0 ) .AND. V3_Near( a[ 2 ], 300.0 ), "[extra] 3D: frontal, x a la derecha y la profundidad Y no mueve la imagen" )
   VwC_View( c, "DERECHA" )
   a := VwC_Proj( c, 99.0, 21.0, 0.0 )
   Chk( V3_Near( a[ 1 ], 402.0 ) .AND. V3_Near( a[ 2 ], 300.0 ), "[extra] 3D: derecha, Y a la derecha de la pantalla" )
   Chk( VwC_View( c, "iso" ) .AND. ! VwC_View( c, "nada" ), "[extra] 3D: nombres de vista" )
   a := VwC_Proj( c, 10.0, 20.0, 0.0 )
   Chk( V3_Near( a[ 1 ], 400.0 ) .AND. V3_Near( a[ 2 ], 300.0 ), "[extra] 3D: el objetivo proyecta al centro" )
   a := VwC_Proj( c, 11.0, 20.0, 0.0 ) ; b := VwC_Proj( c, 10.0, 20.0, 1.0 )
   Chk( a[ 1 ] > 400.0 .AND. a[ 2 ] < 300.0 .AND. b[ 2 ] < 300.0, "[extra] 3D: iso SO, +X va a la derecha y al fondo, +Z sube" )
   VwC_View( c, "SUP" )
   Chk( ! VwC_Is3D( c ), "[extra] 3D: SUP vuelve a la planta" )
   VwC_Orbit( c, 0.1, - 0.2 )
   Chk( V3_Near( c[ "yaw" ], 0.1 ) .AND. V3_Near( c[ "pitch" ], OCX_PI / 2.0 - 0.2 ), "[extra] 3D: orbita" )
   VwC_Orbit( c, 0.0, 10.0 )
   Chk( V3_Near( c[ "pitch" ], OCX_PI / 2.0 ), "[extra] 3D: el pitch se limita a 90 grados" )
   VwC_Orbit( c, 0.0, - 10.0 )
   Chk( V3_Near( c[ "pitch" ], - OCX_PI / 2.0 ), "[extra] 3D: y a -90 grados" )
   // pan y zoom en 3D
   VwC_View( c, "FRONTAL" ) ; c[ "cx" ] := 0.0 ; c[ "cy" ] := 0.0 ; c[ "cz" ] := 0.0 ; c[ "scale" ] := 2.0
   VwC_PanPx( c, 20.0, 0.0 )
   Chk( V3_Near( c[ "cx" ], - 10.0 ) .AND. V3_Near( c[ "cz" ], 0.0 ), "[extra] 3D: pan horizontal en frontal mueve X" )
   VwC_PanPx( c, 0.0, 20.0 )
   Chk( V3_Near( c[ "cz" ], 10.0 ), "[extra] 3D: pan vertical en frontal mueve Z" )
   VwC_ZoomAt( c, 2.0, 10, 10 )
   Chk( V3_Near( c[ "scale" ], 4.0 ), "[extra] 3D: zoom escala" )
   // encuadre 3D
   VwC_View( c, "FRONTAL" )
   VwC_Fit3( c, { 0.0, 0.0, 0.0, 100.0, 50.0, 30.0 }, 1.0 )
   Chk( V3_Near( c[ "cx" ], 50.0 ) .AND. V3_Near( c[ "cz" ], 15.0 ) .AND. V3_Near( c[ "scale" ], 8.0 ), "[extra] 3D: Fit3 frontal 100 de ancho en 800 px" )
   VwC_View( c, "SUP" )
   VwC_Fit3( c, { 0.0, 0.0, 0.0, 100.0, 50.0, 30.0 }, 1.0 )
   Chk( V3_Near( c[ "scale" ], 8.0 ), "[extra] 3D: Fit3 en planta" )
   // z en la escena
   s := V3_Sess( V3_Pairs( 0, "LINE", 8, "0", 10, 0.0, 20, 0.0, 30, 1.0, 11, 10.0, 21, 0.0, 31, 5.0 ) + ;
                 V3_Pairs( 0, "CIRCLE", 8, "0", 10, 0.0, 20, 0.0, 30, 7.0, 40, 2.0 ) )
   o := s[ "scene" ]
   w := o[ "wires" ][ 1 ]
   Chk( V3_Near( w[ 3 ][ 1 ][ 3 ], 1.0 ) .AND. V3_Near( w[ 3 ][ 2 ][ 3 ], 5.0 ), "[extra] 3D: LINE conserva z" )
   w := o[ "wires" ][ 2 ]
   Chk( V3_Near( w[ 3 ][ 1 ][ 3 ], 7.0 ) .AND. V3_Near( w[ 3 ][ 10 ][ 3 ], 7.0 ), "[extra] 3D: CIRCLE a su elevacion" )
   Chk( o[ "ext3" ] != NIL .AND. V3_Near( o[ "ext3" ][ 3 ], 1.0 ) .AND. V3_Near( o[ "ext3" ][ 6 ], 7.0 ) .AND. V3_Near( o[ "ext3" ][ 4 ], 10.0 ), "[extra] 3D: caja 3D de la escena" )
   s := V3_Sess( V3_Pairs( 0, "3DFACE", 8, "0", 10, 0.0, 20, 0.0, 30, 0.0, 11, 4.0, 21, 0.0, 31, 0.0, 12, 4.0, 22, 4.0, 32, 3.0, 13, 0.0, 23, 4.0, 33, 3.0 ) )
   w := s[ "scene" ][ "wires" ][ 1 ]
   Chk( Len( w[ 3 ] ) == 5 .AND. V3_Near( s[ "scene" ][ "ext3" ][ 6 ], 3.0 ), "[extra] 3D: 3DFACE con z" )
   s := V3_Sess( V3_Pairs( 0, "LWPOLYLINE", 8, "0", 90, 2, 70, 0, 38, 2.5, 10, 0.0, 20, 0.0, 10, 3.0, 20, 0.0 ) )
   w := s[ "scene" ][ "wires" ][ 1 ]
   Chk( V3_Near( w[ 3 ][ 1 ][ 3 ], 2.5 ) .AND. V3_Near( w[ 3 ][ 2 ][ 3 ], 2.5 ), "[extra] 3D: LWPOLYLINE a su elevacion" )
   // comandos y seleccion 3D
   s := V3_Sess( V3_Pairs( 0, "LINE", 5, "A1", 8, "0", 10, 0.0, 20, 0.0, 30, 0.0, 11, 10.0, 21, 0.0, 31, 10.0 ) + ;
                 V3_Pairs( 0, "LINE", 5, "A2", 8, "0", 10, 0.0, 20, 5.0, 30, 0.0, 11, 10.0, 21, 5.0, 31, 0.0 ) )
   Chk( "FRONTAL" $ VwK_Exec( s, "VISTA FRONTAL" )[ 1 ] .AND. VwC_Is3D( s[ "cam" ] ), "[extra] 3D: VISTA FRONTAL" )
   Chk( "Vistas" $ VwK_Exec( s, "VISTA zzz" )[ 1 ], "[extra] 3D: vista desconocida avisa" )
   Chk( VwK_Exec( s, "3D" )[ 3 ] .AND. VwC_Is3D( s[ "cam" ] ), "[extra] 3D: el comando 3D pasa a iso" )
   Chk( "Vuelva" $ VwK_Exec( s, "LINEA 0,0 1,1" )[ 1 ] .AND. s[ "pend" ] == NIL, "[extra] 3D: dibujar en 3D se rechaza" )
   Chk( "Vuelva" $ VwK_Exec( s, "ARCO 0,0 1 0 90" )[ 1 ], "[extra] 3D: ARCO en 3D se rechaza" )
   VwK_Exec( s, "VISTA FRONTAL" )
   VwC_SetSize( s[ "cam" ], 800, 600 ) ; VwK_Exec( s, "ZOOM E" )
   a := VwC_Proj( s[ "cam" ], 10.0, 0.0, 10.0 )
   Chk( a[ 1 ] > 0 .AND. a[ 1 ] < 800 .AND. a[ 2 ] > 0 .AND. a[ 2 ] < 600, "[extra] 3D: ZOOM E deja la caja 3D dentro de la pantalla" )
   a := VwC_Proj( s[ "cam" ], 5.0, 0.0, 5.0 )
   o := Vwp_Pick3( s[ "scene" ], s[ "cam" ], a[ 1 ], a[ 2 ], 3.0 )
   Chk( ! ( o == NIL ) .AND. s[ "scene" ][ "ents" ][ o ][ "_type" ] == "LINE", "[extra] 3D: pick en pantalla sobre la diagonal" )
   Chk( Vwp_Pick3( s[ "scene" ], s[ "cam" ], 5.0, 5.0, 3.0 ) == NIL, "[extra] 3D: pick lejos no selecciona" )
   a := Vwp_Box3( s[ "scene" ], s[ "cam" ], 0.0, 0.0, 800.0, 600.0 )
   Chk( Len( a ) == 2, "[extra] 3D: ventana grande toma las dos" )
   a := Vwp_Box3( s[ "scene" ], s[ "cam" ], 800.0, 600.0, 0.0, 0.0 )
   Chk( Len( a ) == 2, "[extra] 3D: captura grande toma las dos" )
   VwK_Exec( s, "ORBITA 30 45" )
   Chk( V3_Near( s[ "cam" ][ "yaw" ], 30.0 * OCX_PI / 180.0 ) .AND. V3_Near( s[ "cam" ][ "pitch" ], 45.0 * OCX_PI / 180.0 ), "[extra] 3D: ORBITA fija azimut y elevacion" )
   VwK_Exec( s, "VISTA SUP" )
   Chk( ! VwC_Is3D( s[ "cam" ] ) .AND. ! ( "Vuelva" $ VwK_Exec( s, "LINEA 0,0 1,1" )[ 1 ] ), "[extra] 3D: de vuelta en planta se puede dibujar" )
RETURN
