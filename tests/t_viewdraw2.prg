/* [extra] Fase 2 / modules/draw: ELLIPSE, SPLINE, ARRAYRECT, ARRAYPOLAR, STRETCH, AREA. Sin equivalente #[test] en Rust. */
#include "ocx.ch"

STATIC FUNCTION Vz_Pairs( ... )
   LOCAL a := hb_AParams(), s := "", i
   FOR i := 1 TO Len( a ) STEP 2
      s += PadL( hb_ntos( a[ i ] ), 3 ) + Chr( 10 ) + hb_CStr( a[ i + 1 ] ) + Chr( 10 )
   NEXT
RETURN s

STATIC FUNCTION Vz_Ln( x1, y1, x2, y2 ) ; RETURN Vz_Pairs( 0, "LINE", 8, "0", 10, x1, 20, y1, 11, x2, 21, y2 )

STATIC FUNCTION Vz_Sess( cEnts )
   LOCAL c := "  0" + Chr( 10 ) + "SECTION" + Chr( 10 ) + "  2" + Chr( 10 ) + "ENTITIES" + Chr( 10 ) + cEnts + ;
              "  0" + Chr( 10 ) + "ENDSEC" + Chr( 10 ) + "  0" + Chr( 10 ) + "EOF" + Chr( 10 )
   LOCAL d := Dxr_ReadString( c )
   IF ! ( ValType( d ) == "H" ) ; RETURN NIL ; ENDIF
RETURN VwS_New( d )

STATIC FUNCTION Vz_Near( a, b ) ; RETURN Abs( a - b ) < 0.000001

STATIC FUNCTION Vz_All( s, cT )
   LOCAL k, a := {}
   FOR EACH k IN hb_HKeys( s[ "scene" ][ "ents" ] )
      IF s[ "scene" ][ "ents" ][ k ][ "_type" ] == cT ; AAdd( a, s[ "scene" ][ "ents" ][ k ] ) ; ENDIF
   NEXT
RETURN a

PROCEDURE T_ViewDraw2()
   LOCAL s, a, r
   s := Vz_Sess( "" )
   VwK_Exec( s, "ELLIPSE 0,0 10,0 0,4" )
   a := Vz_All( s, "ELLIPSE" )
   Chk( Len( a ) == 1 .AND. Vz_Near( a[ 1 ][ "minor_axis_ratio" ], 0.4 ) .AND. Vz_Near( a[ 1 ][ "major_axis" ][ 1 ], 10.0 ), "[extra] draw2: ELLIPSE centro, eje mayor y punto menor (ratio 0.4)" )
   VwK_Exec( s, "SPLINE 0,0 2,3 5,1 8,4" )
   a := Vz_All( s, "SPLINE" )
   Chk( Len( a ) == 1 .AND. Len( a[ 1 ][ "fit_points" ] ) == 4 .AND. Len( a[ 1 ][ "control_points" ] ) >= 4, "[extra] draw2: SPLINE por 4 puntos de ajuste" )
   Chk( Vz_Near( a[ 1 ][ "fit_points" ][ 3 ][ 1 ], 5.0 ), "[extra] draw2: SPLINE conserva los puntos de ajuste" )
   s := Vz_Sess( Vz_Ln( 0.0, 0.0, 1.0, 0.0 ) )
   VwK_Exec( s, "SELTODO" )
   VwK_Exec( s, "ARRAYRECT 2 3 5 10" )
   Chk( Len( Vz_All( s, "LINE" ) ) == 6, "[extra] draw2: ARRAYRECT 2x3 deja 6 rectas" )
   s := Vz_Sess( Vz_Ln( 1.0, 0.0, 2.0, 0.0 ) )
   VwK_Exec( s, "SELTODO" )
   VwK_Exec( s, "ARRAYPOLAR 0,0 4" )
   a := Vz_All( s, "LINE" )
   Chk( Len( a ) == 4, "[extra] draw2: ARRAYPOLAR 4 deja 4 rectas" )
   r := .F.
   FOR EACH s IN a
      IF Vz_Near( s[ "start" ][ 1 ], 0.0 ) .AND. Vz_Near( s[ "start" ][ 2 ], 1.0 ) ; r := .T. ; ENDIF
   NEXT
   Chk( r, "[extra] draw2: ARRAYPOLAR 4 incluye la copia girada 90 grados" )
   s := Vz_Sess( Vz_Ln( 0.0, 0.0, 10.0, 0.0 ) )
   VwK_Exec( s, "STRETCH 8,-1 12,1 8,0 8,3" )
   a := Vz_All( s, "LINE" )
   Chk( Vz_Near( a[ 1 ][ "start" ][ 2 ], 0.0 ) .AND. Vz_Near( a[ 1 ][ "end" ][ 2 ], 3.0 ) .AND. Vz_Near( a[ 1 ][ "end" ][ 1 ], 10.0 ), "[extra] draw2: STRETCH mueve solo el extremo dentro de la ventana" )
   VwK_Exec( s, "DESHACER" )
   a := Vz_All( s, "LINE" )
   Chk( Vz_Near( a[ 1 ][ "end" ][ 2 ], 0.0 ), "[extra] draw2: DESHACER restaura el STRETCH" )
   Chk( "Area=12.0000" $ VwK_Exec( s, "AREA 0,0 4,0 4,3 0,3" )[ 1 ] .AND. "Perimetro=14.0000" $ VwK_Exec( s, "AREA 0,0 4,0 4,3 0,3" )[ 1 ], "[extra] draw2: AREA de un rectangulo 4x3" )
   s := Vz_Sess( "" )
   VwK_Exec( s, "RECTANG 0,0 4,3" )
   VwK_Exec( s, "SELTODO" )
   Chk( "Area=12.0000" $ VwK_Exec( s, "AREA" )[ 1 ], "[extra] draw2: AREA de la polilinea seleccionada" )
RETURN
