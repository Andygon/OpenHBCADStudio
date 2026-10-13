/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/view/vw_cmd.prg
   Fase 2 / bloque B7. Origen Rust: src/app/command_driver + commands.
   Interprete de la linea de comandos estilo AutoCAD sobre una sesion de
   visor. Logica pura (sin FiveWin); la ventana solo le pasa el texto.
   Sesion = hash: doc, scene, cam, hidden (capas apagadas), sel (handles).
   VwK_Exec devuelve { cMsg, lLong, lRedraw }  (lLong = mensaje largo: caja).
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION VwS_New( d )
   LOCAL s := hb_Hash( "doc", d, "hidden", hb_Hash(), "sel", hb_Hash(), "cam", VwC_New() )
   s[ "scene" ] := Vws_Build( d, s[ "hidden" ] )
RETURN s

FUNCTION VwS_Rebuild( s )
   s[ "scene" ] := Vws_Build( s[ "doc" ], s[ "hidden" ] )
RETURN s

STATIC FUNCTION Vk_Res( cMsg, lLong, lRedraw ) ; RETURN { cMsg, IIf( lLong == NIL, .F., lLong ), IIf( lRedraw == NIL, .F., lRedraw ) }

/* "1,2" o "1 2" -> {1,2}; NIL si no es un punto */
STATIC FUNCTION Vk_Pt( aTok, i )
   LOCAL c, n
   IF i > Len( aTok ) ; RETURN NIL ; ENDIF
   c := aTok[ i ]
   n := At( ",", c )
   IF n > 0
      IF ! Vk_IsNum( Left( c, n - 1 ) ) .OR. ! Vk_IsNum( SubStr( c, n + 1 ) ) ; RETURN NIL ; ENDIF
      RETURN { Val( Left( c, n - 1 ) ), Val( SubStr( c, n + 1 ) ) }
   ENDIF
   IF i + 1 <= Len( aTok ) .AND. Vk_IsNum( c ) .AND. Vk_IsNum( aTok[ i + 1 ] )
      RETURN { Val( c ), Val( aTok[ i + 1 ] ) }
   ENDIF
RETURN NIL

STATIC FUNCTION Vk_IsNum( c )
   LOCAL i, ch, nDot := 0
   IF Empty( c ) ; RETURN .F. ; ENDIF
   FOR i := 1 TO Len( c )
      ch := SubStr( c, i, 1 )
      IF ch == "." ; nDot++ ; LOOP ; ENDIF
      IF ch == "-" .AND. i == 1 .AND. Len( c ) > 1 ; LOOP ; ENDIF
      IF ! ( ch $ "0123456789" ) ; RETURN .F. ; ENDIF
   NEXT
RETURN nDot <= 1

STATIC FUNCTION Vk_Num( n ) ; RETURN AllTrim( Str( n, 16, 4 ) )

FUNCTION VwK_Help()
RETURN "ZOOM [E | A | I | O | factor | W x1,y1 x2,y2]  (alias Z)" + Chr( 10 ) + ;
       "PAN x,y        centra la vista en el punto (alias P)" + Chr( 10 ) + ;
       "CAPAS          lista las capas   (LAYERS)" + Chr( 10 ) + ;
       "APAGAR capa    apaga una capa    (LAYOFF)" + Chr( 10 ) + ;
       "ENCENDER capa  enciende una capa (LAYON)" + Chr( 10 ) + ;
       "TODAS          enciende todas las capas (LAYALL)" + Chr( 10 ) + ;
       "SELTODO        selecciona todo   (SELECTALL)" + Chr( 10 ) + ;
       "DESELECCIONAR  quita la seleccion (UNSELECT)" + Chr( 10 ) + ;
       "LISTA          lista la seleccion o el resumen (LIST)" + Chr( 10 ) + ;
       "DIST x1,y1 x2,y2  distancia y angulo entre dos puntos" + Chr( 10 ) + ;
       "ID x,y         muestra un punto" + Chr( 10 ) + ;
       "REGEN          regenera el dibujo" + Chr( 10 ) + ;
       "AYUDA          esta ayuda (HELP)"

FUNCTION VwK_Exec( s, cLine )
   LOCAL aTok, cCmd, c := s[ "cam" ], p1, p2, cArg, n, aL, k, cOut, o, h
   LOCAL aW
   aTok := {}
   FOR EACH cArg IN hb_ATokens( AllTrim( cLine ), " " )
      IF ! Empty( cArg ) ; AAdd( aTok, cArg ) ; ENDIF
   NEXT
   IF Len( aTok ) == 0 ; RETURN Vk_Res( "" ) ; ENDIF
   cCmd := Upper( aTok[ 1 ] )
   DO CASE
   CASE cCmd == "ZOOM" .OR. cCmd == "Z"
      cArg := IIf( Len( aTok ) >= 2, Upper( aTok[ 2 ] ), "E" )
      DO CASE
      CASE cArg $ "E T A EXTENTS EXTENSION TODO ALL"
         VwC_FitExtents( c, s[ "scene" ][ "ext" ], 0.95 )
         RETURN Vk_Res( "Zoom extensiones", , .T. )
      CASE cArg $ "I IN MAS"
         VwC_ZoomAt( c, 2.0, c[ "w" ] / 2, c[ "h" ] / 2 )
         RETURN Vk_Res( "Zoom x2", , .T. )
      CASE cArg $ "O OUT MENOS"
         VwC_ZoomAt( c, 0.5, c[ "w" ] / 2, c[ "h" ] / 2 )
         RETURN Vk_Res( "Zoom x0.5", , .T. )
      CASE cArg $ "W V WINDOW VENTANA"
         p1 := Vk_Pt( aTok, 3 )
         p2 := IIf( p1 == NIL, NIL, Vk_Pt( aTok, IIf( At( ",", aTok[ 3 ] ) > 0, 4, 5 ) ) )
         IF p1 == NIL .OR. p2 == NIL ; RETURN Vk_Res( "Uso: ZOOM W x1,y1 x2,y2" ) ; ENDIF
         VwC_ZoomWindow( c, { Min( p1[ 1 ], p2[ 1 ] ), Min( p1[ 2 ], p2[ 2 ] ), Max( p1[ 1 ], p2[ 1 ] ), Max( p1[ 2 ], p2[ 2 ] ) } )
         RETURN Vk_Res( "Zoom ventana", , .T. )
      CASE Vk_IsNum( StrTran( cArg, "X", "" ) ) .AND. Val( StrTran( cArg, "X", "" ) ) > 0
         VwC_ZoomAt( c, Val( StrTran( cArg, "X", "" ) ), c[ "w" ] / 2, c[ "h" ] / 2 )
         RETURN Vk_Res( "Zoom x" + StrTran( cArg, "X", "" ), , .T. )
      ENDCASE
      RETURN Vk_Res( "Opcion de ZOOM no valida: " + cArg )
   CASE cCmd == "PAN" .OR. cCmd == "P"
      p1 := Vk_Pt( aTok, 2 )
      IF p1 == NIL ; RETURN Vk_Res( "Uso: PAN x,y" ) ; ENDIF
      c[ "cx" ] := p1[ 1 ] ; c[ "cy" ] := p1[ 2 ]
      RETURN Vk_Res( "Vista centrada en " + Vk_Num( p1[ 1 ] ) + "," + Vk_Num( p1[ 2 ] ), , .T. )
   CASE cCmd == "CAPAS" .OR. cCmd == "LAYERS"
      cOut := ""
      FOR EACH aL IN Vws_Layers( s[ "doc" ], s[ "hidden" ] )
         cOut += IIf( aL[ 3 ], "[x] ", "[ ] " ) + aL[ 1 ] + Chr( 10 )
      NEXT
      RETURN Vk_Res( IIf( Empty( cOut ), "Sin capas", cOut ), .T. )
   CASE cCmd == "APAGAR" .OR. cCmd == "LAYOFF" .OR. cCmd == "ENCENDER" .OR. cCmd == "LAYON"
      IF Len( aTok ) < 2 ; RETURN Vk_Res( "Uso: " + cCmd + " nombre-de-capa" ) ; ENDIF
      cArg := ""
      FOR n := 2 TO Len( aTok )
         cArg += IIf( n > 2, " ", "" ) + aTok[ n ]
      NEXT
      k := .F.
      FOR EACH aL IN Vws_Layers( s[ "doc" ], NIL )
         IF Upper( aL[ 1 ] ) == Upper( cArg ) ; k := .T. ; EXIT ; ENDIF
      NEXT
      IF ! k ; RETURN Vk_Res( "No existe la capa: " + cArg ) ; ENDIF
      IF cCmd == "APAGAR" .OR. cCmd == "LAYOFF"
         s[ "hidden" ][ Upper( cArg ) ] := .T.
      ELSEIF hb_HHasKey( s[ "hidden" ], Upper( cArg ) )
         hb_HDel( s[ "hidden" ], Upper( cArg ) )
      ENDIF
      VwS_Rebuild( s )
      RETURN Vk_Res( "Capa " + cArg + IIf( hb_HHasKey( s[ "hidden" ], Upper( cArg ) ), " apagada", " encendida" ), , .T. )
   CASE cCmd == "TODAS" .OR. cCmd == "LAYALL"
      s[ "hidden" ] := hb_Hash()
      VwS_Rebuild( s )
      RETURN Vk_Res( "Todas las capas encendidas", , .T. )
   CASE cCmd == "SELTODO" .OR. cCmd == "SELECTALL"
      s[ "sel" ] := hb_Hash()
      FOR EACH k IN hb_HKeys( s[ "scene" ][ "ents" ] )
         s[ "sel" ][ k ] := .T.
      NEXT
      RETURN Vk_Res( hb_ntos( Len( s[ "sel" ] ) ) + " objetos seleccionados", , .T. )
   CASE cCmd == "DESELECCIONAR" .OR. cCmd == "UNSELECT" .OR. cCmd == "DESELECT"
      s[ "sel" ] := hb_Hash()
      RETURN Vk_Res( "Seleccion vacia", , .T. )
   CASE cCmd == "LISTA" .OR. cCmd == "LIST"
      cOut := ""
      IF Len( s[ "sel" ] ) > 0
         FOR EACH k IN hb_HKeys( s[ "sel" ] )
            IF hb_HHasKey( s[ "scene" ][ "ents" ], k )
               o := s[ "scene" ][ "ents" ][ k ]
               cOut += o[ "_type" ] + "  capa " + hb_CStr( o[ "common" ][ "layer" ] ) + "  handle " + k + Chr( 10 )
            ENDIF
         NEXT
      ELSE
         h := hb_Hash()
         FOR EACH o IN hb_HValues( s[ "scene" ][ "ents" ] )
            h[ o[ "_type" ] ] := IIf( hb_HHasKey( h, o[ "_type" ] ), h[ o[ "_type" ] ] + 1, 1 )
         NEXT
         FOR EACH k IN hb_HKeys( h )
            cOut += PadR( k, 14 ) + hb_ntos( h[ k ] ) + Chr( 10 )
         NEXT
         cOut := "Entidades por tipo:" + Chr( 10 ) + cOut
      ENDIF
      RETURN Vk_Res( IIf( Empty( cOut ), "Dibujo vacio", cOut ), .T. )
   CASE cCmd == "DIST" .OR. cCmd == "DI"
      p1 := Vk_Pt( aTok, 2 )
      IF p1 == NIL ; RETURN Vk_Res( "Uso: DIST x1,y1 x2,y2" ) ; ENDIF
      p2 := Vk_Pt( aTok, IIf( At( ",", aTok[ 2 ] ) > 0, 3, 4 ) )
      IF p2 == NIL ; RETURN Vk_Res( "Uso: DIST x1,y1 x2,y2" ) ; ENDIF
      aW := Sqrt( ( p2[ 1 ] - p1[ 1 ] ) ^ 2 + ( p2[ 2 ] - p1[ 2 ] ) ^ 2 )
      RETURN Vk_Res( "Distancia=" + Vk_Num( aW ) + "  Angulo=" + Vk_Num( OCX_ATAN2( p2[ 2 ] - p1[ 2 ], p2[ 1 ] - p1[ 1 ] ) * 180.0 / OCX_PI ) + ;
                     "  dX=" + Vk_Num( p2[ 1 ] - p1[ 1 ] ) + "  dY=" + Vk_Num( p2[ 2 ] - p1[ 2 ] ) )
   CASE cCmd == "ID"
      p1 := Vk_Pt( aTok, 2 )
      IF p1 == NIL ; RETURN Vk_Res( "Uso: ID x,y" ) ; ENDIF
      RETURN Vk_Res( "X=" + Vk_Num( p1[ 1 ] ) + "  Y=" + Vk_Num( p1[ 2 ] ) )
   CASE cCmd == "REGEN" .OR. cCmd == "REGENERAR" .OR. cCmd == "REDIBUJAR"
      VwS_Rebuild( s )
      RETURN Vk_Res( "Regenerado", , .T. )
   CASE cCmd == "AYUDA" .OR. cCmd == "HELP" .OR. cCmd == "?"
      RETURN Vk_Res( VwK_Help(), .T. )
   ENDCASE
RETURN Vk_Res( "Comando desconocido: " + cCmd + ". Escriba AYUDA." )
