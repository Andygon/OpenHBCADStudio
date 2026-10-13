/* [extra] Fase 2 / visor: camara 2D y escena (DXF -> hilos). Sin equivalente #[test] en Rust. */
#include "ocx.ch"

STATIC FUNCTION Vt_Dxf( cEnts, cBlocks )
   LOCAL c := "  0" + Chr( 10 ) + "SECTION" + Chr( 10 ) + "  2" + Chr( 10 ) + "BLOCKS" + Chr( 10 ) + cBlocks + ;
              "  0" + Chr( 10 ) + "ENDSEC" + Chr( 10 ) + "  0" + Chr( 10 ) + "SECTION" + Chr( 10 ) + "  2" + Chr( 10 ) + "ENTITIES" + Chr( 10 ) + cEnts + ;
              "  0" + Chr( 10 ) + "ENDSEC" + Chr( 10 ) + "  0" + Chr( 10 ) + "EOF" + Chr( 10 )
RETURN c

STATIC FUNCTION Vt_Pairs( ... )
   LOCAL a := hb_AParams(), s := "", i
   FOR i := 1 TO Len( a ) STEP 2
      s += PadL( hb_ntos( a[ i ] ), 3 ) + Chr( 10 ) + hb_CStr( a[ i + 1 ] ) + Chr( 10 )
   NEXT
RETURN s

STATIC FUNCTION Vt_Scene( cEnts, cBlocks )
   LOCAL d := Dxr_ReadString( Vt_Dxf( cEnts, IIf( cBlocks == NIL, "", cBlocks ) ) )
   IF ! ( ValType( d ) == "H" ) ; RETURN NIL ; ENDIF
RETURN Vws_Build( d )

STATIC FUNCTION Vt_Near( a, b ) ; RETURN Abs( a - b ) < 0.000001

PROCEDURE T_Viewer()
   LOCAL c, o, w, a, aE, i, lOk, d, p, cE, cB
   // --- camara ---
   c := VwC_SetSize( VwC_New(), 800, 600 )
   c[ "cx" ] := 10.0 ; c[ "cy" ] := 20.0 ; c[ "scale" ] := 2.0
   a := VwC_W2S( c, 10.0, 20.0 )
   Chk( Vt_Near( a[ 1 ], 400 ) .AND. Vt_Near( a[ 2 ], 300 ), "[extra] visor: el centro mundo cae en el centro de pantalla" )
   a := VwC_W2S( c, 15.0, 25.0 )
   Chk( Vt_Near( a[ 1 ], 410 ) .AND. Vt_Near( a[ 2 ], 290 ), "[extra] visor: Y mundo hacia arriba" )
   a := VwC_S2W( c, 410, 290 )
   Chk( Vt_Near( a[ 1 ], 15.0 ) .AND. Vt_Near( a[ 2 ], 25.0 ), "[extra] visor: S2W es la inversa de W2S" )
   VwC_ZoomAt( c, 2.0, 100, 50 )
   p := VwC_S2W( c, 100, 50 )
   a := VwC_W2S( c, VwC_S2W( c, 100, 50 )[ 1 ], VwC_S2W( c, 100, 50 )[ 2 ] )
   Chk( Vt_Near( c[ "scale" ], 4.0 ) .AND. Vt_Near( a[ 1 ], 100 ) .AND. Vt_Near( a[ 2 ], 50 ), "[extra] visor: zoom en punto mantiene el punto bajo el cursor" )
   c := VwC_SetSize( VwC_New(), 800, 600 )
   a := VwC_S2W( c, 300, 200 )
   VwC_ZoomAt( c, 0.5, 300, 200 )
   Chk( Vt_Near( VwC_S2W( c, 300, 200 )[ 1 ], a[ 1 ] ) .AND. Vt_Near( VwC_S2W( c, 300, 200 )[ 2 ], a[ 2 ] ), "[extra] visor: alejar mantiene el punto fijo" )
   a := { c[ "cx" ], c[ "cy" ] }
   VwC_PanPx( c, 50, -30 )
   Chk( Vt_Near( c[ "cx" ], a[ 1 ] - 50 / c[ "scale" ] ) .AND. Vt_Near( c[ "cy" ], a[ 2 ] - 30 / c[ "scale" ] ), "[extra] visor: pan arrastra el dibujo con el raton" )
   c := VwC_SetSize( VwC_New(), 1000, 500 )
   VwC_FitExtents( c, { 0.0, 0.0, 100.0, 100.0 }, 0.9 )
   Chk( Vt_Near( c[ "scale" ], 4.5 ) .AND. Vt_Near( c[ "cx" ], 50.0 ) .AND. Vt_Near( c[ "cy" ], 50.0 ), "[extra] visor: zoom extents (margen 10 %, limita el eje corto)" )
   VwC_FitExtents( c, NIL )
   Chk( Vt_Near( c[ "scale" ], 1.0 ), "[extra] visor: zoom extents sin entidades" )
   // --- escena ---
   cE := Vt_Pairs( 0, "LINE", 8, "0", 10, 0.0, 20, 0.0, 11, 10.0, 21, 5.0 )
   o := Vt_Scene( cE )
   Chk( o != NIL .AND. Vws_WireCount( o ) == 1 .AND. Len( o[ "wires" ][ 1 ][ 3 ] ) == 2, "[extra] visor: LINE -> 1 hilo de 2 puntos" )
   aE := Vws_Extents( o )
   Chk( aE != NIL .AND. Vt_Near( aE[ 3 ], 10.0 ) .AND. Vt_Near( aE[ 4 ], 5.0 ), "[extra] visor: extension de LINE" )
   Chk( o[ "wires" ][ 1 ][ 1 ] == 16777215, "[extra] visor: ByLayer en capa 0 = blanco" )
   cE := Vt_Pairs( 0, "CIRCLE", 8, "0", 62, 1, 10, 1.0, 20, 2.0, 30, 0.0, 40, 5.0 )
   o := Vt_Scene( cE )
   lOk := o != NIL .AND. Vws_WireCount( o ) == 1
   IF lOk
      FOR EACH p IN o[ "wires" ][ 1 ][ 3 ]
         IF ! Vt_Near( Sqrt( ( p[ 1 ] - 1.0 ) ^ 2 + ( p[ 2 ] - 2.0 ) ^ 2 ), 5.0 ) ; lOk := .F. ; ENDIF
      NEXT
   ENDIF
   Chk( lOk, "[extra] visor: CIRCLE tesela sobre el radio" )
   Chk( o != NIL .AND. o[ "wires" ][ 1 ][ 1 ] == 255, "[extra] visor: color ACI 1 = rojo (COLORREF 255)" )
   aE := Vws_Extents( o )
   Chk( aE != NIL .AND. Vt_Near( aE[ 1 ], -4.0 ) .AND. Vt_Near( aE[ 4 ], 7.0 ), "[extra] visor: extension de CIRCLE" )
   cE := Vt_Pairs( 0, "ARC", 8, "0", 10, 0.0, 20, 0.0, 30, 0.0, 40, 2.0, 50, 0.0, 51, 90.0 )
   o := Vt_Scene( cE )
   w := IIf( o == NIL, {}, o[ "wires" ][ 1 ][ 3 ] )
   Chk( Len( w ) > 3 .AND. Vt_Near( w[ 1 ][ 1 ], 2.0 ) .AND. Vt_Near( w[ 1 ][ 2 ], 0.0 ) .AND. Vt_Near( w[ Len( w ) ][ 1 ], 0.0 ) .AND. Vt_Near( w[ Len( w ) ][ 2 ], 2.0 ), "[extra] visor: ARC 0-90 va de (r,0) a (0,r)" )
   cE := Vt_Pairs( 0, "LWPOLYLINE", 8, "0", 90, 2, 70, 0, 10, 0.0, 20, 0.0, 42, 1.0, 10, 2.0, 20, 0.0 )
   o := Vt_Scene( cE )
   w := IIf( o == NIL, {}, o[ "wires" ][ 1 ][ 3 ] )
   lOk := Len( w ) > 4 .AND. Vt_Near( w[ 1 ][ 1 ], 0.0 ) .AND. Vt_Near( w[ Len( w ) ][ 1 ], 2.0 )
   IF lOk
      lOk := .F.
      FOR EACH p IN w
         IF Vt_Near( p[ 1 ], 1.0 ) .AND. Vt_Near( p[ 2 ], -1.0 ) ; lOk := .T. ; ENDIF
      NEXT
   ENDIF
   Chk( lOk, "[extra] visor: LWPOLYLINE con bulge 1 = semicirculo por debajo (convencion DXF)" )
   cE := Vt_Pairs( 0, "LWPOLYLINE", 8, "0", 90, 3, 70, 1, 10, 0.0, 20, 0.0, 10, 4.0, 20, 0.0, 10, 4.0, 20, 3.0 )
   o := Vt_Scene( cE )
   w := IIf( o == NIL, {}, o[ "wires" ][ 1 ][ 3 ] )
   Chk( Len( w ) == 4 .AND. Vt_Near( w[ 4 ][ 1 ], 0.0 ) .AND. Vt_Near( w[ 4 ][ 2 ], 0.0 ), "[extra] visor: LWPOLYLINE cerrada repite el primer punto" )
   cE := Vt_Pairs( 0, "ELLIPSE", 8, "0", 10, 0.0, 20, 0.0, 30, 0.0, 11, 4.0, 21, 0.0, 31, 0.0, 40, 0.5, 41, 0.0, 42, 6.283185307179586 )
   o := Vt_Scene( cE )
   aE := IIf( o == NIL, NIL, Vws_Extents( o ) )
   Chk( aE != NIL .AND. Abs( aE[ 3 ] - 4.0 ) < 0.001 .AND. Abs( aE[ 4 ] - 2.0 ) < 0.01, "[extra] visor: ELLIPSE semiejes 4 y 2" )
   cE := Vt_Pairs( 0, "SPLINE", 8, "0", 70, 8, 71, 1, 72, 4, 73, 3, 40, 0.0, 40, 0.0, 40, 1.0, 40, 1.0, 10, 0.0, 20, 0.0, 30, 0.0, 10, 1.0, 20, 2.0, 30, 0.0, 10, 3.0, 20, 0.0, 30, 0.0 )
   o := Vt_Scene( cE )
   Chk( o != NIL .AND. Vws_WireCount( o ) == 1 .AND. Len( o[ "wires" ][ 1 ][ 3 ] ) >= 2, "[extra] visor: SPLINE genera un hilo" )
   cB := Vt_Pairs( 0, "BLOCK", 8, "0", 2, "B", 70, 0, 10, 0.0, 20, 0.0, 30, 0.0, 3, "B" ) + Vt_Pairs( 0, "LINE", 8, "0", 10, 0.0, 20, 0.0, 11, 1.0, 21, 0.0 ) + Vt_Pairs( 0, "ENDBLK", 8, "0" )
   cE := Vt_Pairs( 0, "INSERT", 8, "0", 2, "B", 10, 10.0, 20, 10.0, 30, 0.0, 41, 2.0, 42, 2.0, 43, 1.0, 50, 90.0 )
   o := Vt_Scene( cE, cB )
   w := IIf( o == NIL .OR. Vws_WireCount( o ) < 1, {}, o[ "wires" ][ 1 ][ 3 ] )
   Chk( Len( w ) == 2 .AND. Vt_Near( w[ 1 ][ 1 ], 10.0 ) .AND. Vt_Near( w[ 1 ][ 2 ], 10.0 ) .AND. Vt_Near( w[ 2 ][ 1 ], 10.0 ) .AND. Vt_Near( w[ 2 ][ 2 ], 12.0 ), "[extra] visor: INSERT aplica escala 2 y giro 90" )
   cE := Vt_Pairs( 0, "TEXT", 8, "0", 10, 1.0, 20, 2.0, 30, 0.0, 40, 3.0, 1, "Hola" )
   o := Vt_Scene( cE )
   Chk( o != NIL .AND. Len( o[ "texts" ] ) == 1 .AND. o[ "texts" ][ 1 ][ 5 ] == "Hola" .AND. Vt_Near( o[ "texts" ][ 1 ][ 3 ], 3.0 ), "[extra] visor: TEXT -> lista de textos" )
   // --- DXF reales ---
   FOR EACH i IN { "tests/fixtures/embedded-image-print.dxf", "tests/fixtures/viewport_associations.dxf", "tests/fixtures/page-setups-metric.dxf" }
      d := Vws_LoadFile( i )
      o := IIf( d == NIL, NIL, Vws_Build( d ) )
      Chk( o != NIL, "[extra] visor: carga y construye escena de " + i )
   NEXT
RETURN
