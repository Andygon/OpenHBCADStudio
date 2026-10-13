/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/ui/vw_window.prg
   Fase 2 / bloques B3 y B4 (hito 1: visor). Origen Rust: src/app.rs +
   src/scene/pipeline (render) + src/scene/view (camara).
   Ventana FiveWin con el visor: Abrir DXF (codec portado), render GDI con
   doble buffer, zoom con rueda, pan arrastrando, zoom extents.
   La logica (escena y camara) esta en src/view/ y se prueba en consola.
   Fase 2 / B5-B7: capas y tipos de linea (plumas GDI), relleno HATCH,
   linea de comandos estilo AutoCAD (escriba y pulse Intro; AYUDA lista
   los comandos), seleccion por clic o caja y grips.
   Raton: clic = elegir (Mayus suma), arrastrar = caja (izq a der ventana,
   der a izq captura), rueda = zoom, boton central o Ctrl+arrastrar = pan.
   Teclas: Inicio = zoom extents, flechas = pan, Ctrl+O = abrir, Esc = limpiar.
----------------------------------------------------------------------------*/
#include "FiveWin.ch"

#define VWW_ROP_SRCCOPY 13369376
#define VWW_MAXTEXTS    4000
#define VWW_CYAN        16757760      /* primario del tema oscuro Rust (Oxocarbon #00B4FF) */
#define VWW_BLUE        16757760
#define VWW_BG          1447446       /* lienzo [22,22,22] (theme_canvas_background Oxocarbon) */
#define VWW_SUCCESS     5882112       /* #00C15A: captura (crossing) */
#define VWW_YELLOW      65535
#define VWW_BARH        26

CLASS TViewer
   DATA oWnd
   DATA oBrush
   DATA oCam
   DATA oScene
   DATA oSes
   DATA cCmd     INIT ""
   DATA nMode    INIT 0
   DATA aBox     INIT NIL
   DATA aGrip    INIT NIL
   DATA aRub     INIT NIL
   DATA aSnap    INIT NIL
   DATA aBtns    INIT {}
   DATA oRb
   DATA nTop     INIT 0
   DATA cFile    INIT ""
   DATA aPens    INIT {}
   DATA hPenKeys INIT {}
   DATA lDrag    INIT .F.
   DATA aDrag    INIT { 0, 0 }
   DATA aMouse   INIT { 0, 0 }
   DATA aFonts   INIT {}

   METHOD New( cFile ) CONSTRUCTOR
   METHOD Activate()
   METHOD OnInit()
   METHOD Open( cFile )
   METHOD Paint( hDC )
   METHOD Pen( nRgb, nStyle )
   METHOD FreePens()
   METHOD FontFor( nPx, nRot )
   METHOD FreeFonts()
   METHOD Size()
   METHOD Fit()
   METHOD Zoom( nF )
   METHOD OnWheel( nDelta )
   METHOD OnLDown( nRow, nCol )
   METHOD OnLUp()
   METHOD OnMDown( nRow, nCol )
   METHOD OnChar( nKey )
   METHOD RunCmd()
   METHOD Exec( cLine )
   METHOD Run( cCmd )
   METHOD SaveAs()
   METHOD Wp( nRow, nCol )
   METHOD BtnAt( nRow, nCol )
   METHOD DrawBar( hMem, c )
   METHOD InitBtns()
   METHOD Prompt()
   METHOD DrawFills( hMem, c )
   METHOD DrawGrips( hMem, c )
   METHOD OnMove( nRow, nCol, nFlags )
   METHOD OnKey( nKey )
   METHOD Status( cText )
   METHOD Title()
ENDCLASS

METHOD New( cFile ) CLASS TViewer
   ::oCam := VwC_New()
   IF cFile != NIL .AND. ! Empty( cFile )
      ::cFile := cFile
   ENDIF
RETURN Self

METHOD Activate() CLASS TViewer
   LOCAL oMenu, oSelf := Self
   MENU oMenu
      MENUITEM "&Archivo"
      MENU
         MENUITEM "&Abrir DXF...  Ctrl+O" ACTION oSelf:Open()
         MENUITEM "&Guardar  Ctrl+S" ACTION oSelf:Exec( "GUARDAR" )
         MENUITEM "Guardar &como..." ACTION oSelf:SaveAs()
         SEPARATOR
         MENUITEM "&Salir" ACTION oSelf:oWnd:End()
      ENDMENU
      MENUITEM "&Editar"
      MENU
         MENUITEM "&Deshacer  Ctrl+Z" ACTION oSelf:Exec( "DESHACER" )
         MENUITEM "&Borrar  Supr" ACTION oSelf:Exec( "BORRAR" )
         SEPARATOR
         MENUITEM "Seleccionar &todo" ACTION oSelf:Exec( "SELTODO" )
         MENUITEM "&Quitar seleccion" ACTION oSelf:Exec( "DESELECCIONAR" )
      ENDMENU
      MENUITEM "&Dibujo"
      MENU
         MENUITEM "&Linea" ACTION oSelf:Exec( "LINEA" )
         MENUITEM "&Circulo" ACTION oSelf:Exec( "CIRCULO" )
         MENUITEM "&Polilinea" ACTION oSelf:Exec( "PLINE" )
         MENUITEM "P&unto" ACTION oSelf:Exec( "PUNTO" )
      ENDMENU
      MENUITEM "&Modificar"
      MENU
         MENUITEM "&Mover" ACTION oSelf:Exec( "MOVER" )
         MENUITEM "&Copiar" ACTION oSelf:Exec( "COPIAR" )
      ENDMENU
      MENUITEM "&Vista"
      MENU
         MENUITEM "Zoom &extensiones  Inicio" ACTION oSelf:Fit()
         MENUITEM "&Acercar" ACTION oSelf:Zoom( 1.5 )
         MENUITEM "A&lejar" ACTION oSelf:Zoom( 1.0 / 1.5 )
         SEPARATOR
         MENUITEM "&Planta (SUP)" ACTION oSelf:Exec( "VISTA SUP" )
         MENUITEM "&Frontal" ACTION oSelf:Exec( "VISTA FRONTAL" )
         MENUITEM "&Derecha" ACTION oSelf:Exec( "VISTA DERECHA" )
         MENUITEM "&Isometrica (3D)" ACTION oSelf:Exec( "VISTA ISO" )
         SEPARATOR
         MENUITEM "&Capas..." ACTION oSelf:Exec( "CAPAS" )
         MENUITEM "&Regenerar" ACTION oSelf:Exec( "REGEN" )
         MENUITEM "&Snap a objetos (activar/apagar)" ACTION oSelf:Exec( "SNAP" )
      ENDMENU
      MENUITEM "A&yuda"
      MENU
         MENUITEM "&Comandos" ACTION oSelf:Exec( "AYUDA" )
      ENDMENU
   ENDMENU
   DEFINE BRUSH ::oBrush COLOR VWW_BG
   DEFINE WINDOW ::oWnd TITLE "OpenHBCADStudio - Visor" MENU oMenu BRUSH ::oBrush
   SET MESSAGE OF ::oWnd TO "Listo. Abra un DXF (Archivo, Abrir DXF) o pase la ruta como argumento."
   ::InitBtns()
   IF Empty( GetEnv( "OHB_NORIBBON" ) )
      ::oRb := Vwr_Build( ::oWnd, oSelf )
      ::nTop := Vwr_Height()
   ENDIF
   ::oWnd:bPainted    := { | hDC | oSelf:Paint( hDC ) }
   ::oWnd:bResized    := { || oSelf:oWnd:Refresh() }
   ::oWnd:bLClicked   := { | nRow, nCol | oSelf:OnLDown( nRow - oSelf:nTop, nCol ) }
   ::oWnd:bLButtonUp  := { || oSelf:OnLUp() }
   ::oWnd:bMMoved     := { | nRow, nCol, nFlags | oSelf:OnMove( nRow - oSelf:nTop, nCol, nFlags ) }
   ::oWnd:bMouseWheel := { | nKey, nDelta | oSelf:OnWheel( nDelta ) }
   ::oWnd:bKeyDown    := { | nKey | oSelf:OnKey( nKey ) }
   ::oWnd:bKeyChar    := { | nKey | oSelf:OnChar( nKey ) }
   ACTIVATE WINDOW ::oWnd MAXIMIZED ON INIT oSelf:OnInit() ;
      VALID ( oSelf:FreePens(), oSelf:FreeFonts(), .T. )
RETURN NIL

METHOD OnInit() CLASS TViewer
   BEGIN SEQUENCE WITH { | e | Break( e ) }
      ::oWnd:bMButtonDown := { | nRow, nCol | ::OnMDown( nRow - ::nTop, nCol ) }
      ::oWnd:bMButtonUp   := { || ::OnLUp() }
   END SEQUENCE
   IF ! Empty( ::cFile )
      ::Open( ::cFile )
   ENDIF
RETURN NIL

METHOD Size() CLASS TViewer
   LOCAL aR := GetClientRect( ::oWnd:hWnd )
   VwC_SetSize( ::oCam, aR[ 4 ] - aR[ 2 ], aR[ 3 ] - aR[ 1 ] - ::nTop )
RETURN ::oCam

METHOD Title() CLASS TViewer
   ::oWnd:SetText( "OpenHBCADStudio - Visor" + If( Empty( ::cFile ), "", " - " + ::cFile ) )
RETURN NIL

METHOD Status( cText ) CLASS TViewer
   BEGIN SEQUENCE WITH { | e | Break( e ) }
      ::oWnd:SetMsg( cText )
   END SEQUENCE
RETURN NIL

METHOD Open( cFile ) CLASS TViewer
   LOCAL d, cSk := "", k, nT
   IF cFile == NIL .OR. Empty( cFile )
      cFile := cGetFile( "Dibujos DXF (*.dxf)|*.dxf|Todos (*.*)|*.*|", "Abrir DXF" )
   ENDIF
   IF Empty( cFile )
      RETURN NIL
   ENDIF
   d := Vws_LoadFile( cFile )
   IF d == NIL
      MsgAlert( "No se pudo leer el DXF:" + CRLF + cFile, "OpenHBCADStudio" )
      RETURN NIL
   ENDIF
   ::oSes := VwS_New( d )
   ::oSes[ "cam" ] := ::oCam
   ::oSes[ "file" ] := cFile
   ::oScene := ::oSes[ "scene" ]
   ::cCmd := ""
   ::cFile := cFile
   FOR EACH k IN hb_HKeys( ::oScene[ "skipped" ] )
      cSk += " " + k + "(" + hb_ntos( ::oScene[ "skipped" ][ k ] ) + ")"
   NEXT
   nT := Len( ::oScene[ "wires" ] )
   ::Title()
   ::Fit()
   ::Status( hb_ntos( nT ) + " trazos, " + hb_ntos( Len( ::oScene[ "texts" ] ) ) + " textos" + ;
             If( Empty( cSk ), "", ". Sin dibujar:" + cSk ) )
RETURN NIL

METHOD Fit() CLASS TViewer
   ::Size()
   IF ::oScene != NIL
      IF VwC_Is3D( ::oCam )
         VwC_Fit3( ::oCam, ::oScene[ "ext3" ], 0.95 )
      ELSE
         VwC_FitExtents( ::oCam, Vws_Extents( ::oScene ), 0.95 )
      ENDIF
   ENDIF
   ::oWnd:Refresh()
RETURN NIL

METHOD Zoom( nF ) CLASS TViewer
   ::Size()
   VwC_ZoomAt( ::oCam, nF, ::oCam[ "w" ] / 2, ::oCam[ "h" ] / 2 )
   ::oWnd:Refresh()
RETURN NIL

METHOD OnWheel( nDelta ) CLASS TViewer
   ::Size()
   VwC_ZoomAt( ::oCam, If( nDelta > 0, 1.25, 1.0 / 1.25 ), ::aMouse[ 2 ], ::aMouse[ 1 ] )
   ::oWnd:Refresh()
RETURN NIL

METHOD InitBtns() CLASS TViewer
   LOCAL a := { { "Abrir", "@ABRIR" }, { "Guardar", "GUARDAR" }, { "|", "" }, { "Linea", "LINEA" }, { "Circulo", "CIRCULO" }, ;
                { "Pline", "PLINE" }, { "Punto", "PUNTO" }, { "|", "" }, { "Mover", "MOVER" }, { "Copiar", "COPIAR" }, ;
                { "Borrar", "BORRAR" }, { "Deshacer", "DESHACER" }, { "|", "" }, { "Zoom E", "ZOOM E" }, { "Planta", "VISTA SUP" }, { "3D", "3D" }, { "Capas", "CAPAS" }, ;
                { "Snap", "SNAP" }, { "|", "" }, { "G.como", "@GUARDARCOMO" } }, b, nX := 4
   ::aBtns := {}
   FOR EACH b IN a
      AAdd( ::aBtns, { b[ 1 ], b[ 2 ], nX, nX + Len( b[ 1 ] ) * 8 + 12 } )
      nX += Len( b[ 1 ] ) * 8 + 16
   NEXT
RETURN NIL

METHOD BtnAt( nRow, nCol ) CLASS TViewer
   LOCAL b
   IF ::nTop > 0 .OR. nRow > VWW_BARH ; RETURN NIL ; ENDIF
   FOR EACH b IN ::aBtns
      IF ! Empty( b[ 2 ] ) .AND. nCol >= b[ 3 ] .AND. nCol <= b[ 4 ]
         RETURN b
      ENDIF
   NEXT
RETURN NIL

/* punto mundo bajo (nRow,nCol), enganchado a objetos si el snap esta activo */
METHOD Wp( nRow, nCol ) CLASS TViewer
   LOCAL aW := VwC_S2W( ::oCam, nCol, nRow ), aS
   IF ::oSes != NIL
      aS := VwK_SnapAt( ::oSes, aW[ 1 ], aW[ 2 ], 10.0 / ::oCam[ "scale" ] )
      IF aS != NIL ; aW := { aS[ 1 ], aS[ 2 ] } ; ENDIF
   ENDIF
RETURN aW

METHOD OnLDown( nRow, nCol ) CLASS TViewer
   LOCAL aW, aG, r, b
   b := ::BtnAt( nRow, nCol )
   IF b != NIL
      DO CASE
      CASE b[ 2 ] == "@ABRIR" ; ::Open()
      CASE b[ 2 ] == "@GUARDARCOMO" ; ::SaveAs()
      OTHERWISE ; ::Exec( b[ 2 ] )
      ENDCASE
      RETURN NIL
   ENDIF
   ::aDrag := { nRow, nCol }
   ::aBox := NIL
   ::aGrip := NIL
   IF ::oSes != NIL
      ::Size()
      aW := VwC_S2W( ::oCam, nCol, nRow )
      IF VwC_Is3D( ::oCam )
         ::nMode := If( GetKeyState( 17 ), 1, 2 )
         SetCapture( ::oWnd:hWnd )
         RETURN NIL
      ENDIF
      IF hb_HHasKey( ::oSes, "pend" ) .AND. ::oSes[ "pend" ] != NIL
         aW := ::Wp( nRow, nCol )
         r := VwK_Point( ::oSes, aW[ 1 ], aW[ 2 ] )
         ::oScene := ::oSes[ "scene" ]
         ::Status( r[ 1 ] )
         ::aRub := IIf( ::oSes[ "pend" ] != NIL .AND. Len( ::oSes[ "pend" ][ "pts" ] ) > 0, ATail( ::oSes[ "pend" ][ "pts" ] ), NIL )
         ::oWnd:Refresh()
         RETURN NIL
      ENDIF
      IF ! GetKeyState( 17 ) .AND. Len( ::oSes[ "sel" ] ) > 0 .AND. Len( ::oSes[ "sel" ] ) <= 200
         aG := Vwp_GripAt( ::oScene, ::oSes[ "sel" ], aW[ 1 ], aW[ 2 ], 6.0 / ::oCam[ "scale" ] )
         IF aG != NIL
            ::aGrip := aG
            ::nMode := 3
            SetCapture( ::oWnd:hWnd )
            RETURN NIL
         ENDIF
      ENDIF
   ENDIF
   ::nMode := If( GetKeyState( 17 ), 1, 2 )
   SetCapture( ::oWnd:hWnd )
RETURN NIL

METHOD OnMDown( nRow, nCol ) CLASS TViewer
   ::aDrag := { nRow, nCol }
   ::nMode := If( GetKeyState( 16 ), 4, 1 )          // Mayus + boton central = orbita
   SetCapture( ::oWnd:hWnd )
RETURN NIL

METHOD OnLUp() CLASS TViewer
   LOCAL aW, aW2, aH, k, lMove, nTol, s := ::oSes, lShift := GetKeyState( 16 )
   IF ::nMode == 0
      RETURN NIL
   ENDIF
   ReleaseCapture()
   IF ::nMode == 3 .AND. s != NIL .AND. ::aGrip != NIL
      ::Size()
      aW := ::Wp( ::aMouse[ 1 ], ::aMouse[ 2 ] )
      IF Abs( ::aMouse[ 1 ] - ::aDrag[ 1 ] ) > 2 .OR. Abs( ::aMouse[ 2 ] - ::aDrag[ 2 ] ) > 2
         IF Vwe_GripMove( s, ::aGrip[ 1 ], ::aGrip[ 2 ], aW[ 1 ], aW[ 2 ] )
            ::oScene := s[ "scene" ]
            ::Status( "Grip movido (Ctrl+Z deshace)" )
         ELSE
            ::Status( "Este tipo de entidad no admite ese grip" )
         ENDIF
      ENDIF
      ::aGrip := NIL
   ENDIF
   IF ::nMode == 2 .AND. s != NIL
      lMove := Abs( ::aMouse[ 1 ] - ::aDrag[ 1 ] ) > 4 .OR. Abs( ::aMouse[ 2 ] - ::aDrag[ 2 ] ) > 4
      ::Size()
      IF lMove
         IF VwC_Is3D( ::oCam )
            aH := Vwp_Box3( ::oScene, ::oCam, ::aDrag[ 2 ], ::aDrag[ 1 ], ::aMouse[ 2 ], ::aMouse[ 1 ] )
         ELSE
            aW := VwC_S2W( ::oCam, ::aDrag[ 2 ], ::aDrag[ 1 ] )
            aW2 := VwC_S2W( ::oCam, ::aMouse[ 2 ], ::aMouse[ 1 ] )
            aH := Vwp_Box( ::oScene, aW[ 1 ], aW[ 2 ], aW2[ 1 ], aW2[ 2 ] )
         ENDIF
         IF ! lShift ; s[ "sel" ] := hb_Hash() ; ENDIF
         FOR EACH k IN aH
            s[ "sel" ][ k ] := .T.
         NEXT
      ELSE
         IF VwC_Is3D( ::oCam )
            k := Vwp_Pick3( ::oScene, ::oCam, ::aDrag[ 2 ], ::aDrag[ 1 ], 6.0 )
         ELSE
            aW := VwC_S2W( ::oCam, ::aDrag[ 2 ], ::aDrag[ 1 ] )
            nTol := 6.0 / ::oCam[ "scale" ]
            k := Vwp_Pick( ::oScene, aW[ 1 ], aW[ 2 ], nTol )
         ENDIF
         IF ! lShift ; s[ "sel" ] := hb_Hash() ; ENDIF
         IF k != NIL
            IF lShift .AND. hb_HHasKey( s[ "sel" ], k )
               hb_HDel( s[ "sel" ], k )
            ELSE
               s[ "sel" ][ k ] := .T.
            ENDIF
         ENDIF
      ENDIF
      ::Status( hb_ntos( Len( s[ "sel" ] ) ) + " seleccionado(s)" )
   ENDIF
   ::nMode := 0
   ::aBox := NIL
   ::oWnd:Refresh()
RETURN NIL

METHOD OnMove( nRow, nCol, nFlags ) CLASS TViewer
   LOCAL aW
   ::aMouse := { nRow, nCol }
   ::Size()
   ::aSnap := NIL
   IF ::oSes != NIL .AND. ( ::nMode == 3 .OR. ( hb_HHasKey( ::oSes, "pend" ) .AND. ::oSes[ "pend" ] != NIL ) )
      aW := VwC_S2W( ::oCam, nCol, nRow )
      ::aSnap := VwK_SnapAt( ::oSes, aW[ 1 ], aW[ 2 ], 10.0 / ::oCam[ "scale" ] )
      IF ::aSnap != NIL ; ::oWnd:Refresh() ; ENDIF
   ENDIF
   DO CASE
   CASE ::nMode == 1
      VwC_PanPx( ::oCam, nCol - ::aDrag[ 2 ], nRow - ::aDrag[ 1 ] )
      ::aDrag := { nRow, nCol }
      ::oWnd:Refresh()
   CASE ::nMode == 4
      VwC_Orbit( ::oCam, ( nCol - ::aDrag[ 2 ] ) * 0.01, ( nRow - ::aDrag[ 1 ] ) * 0.01 )
      ::aDrag := { nRow, nCol }
      ::oWnd:Refresh()
   CASE ::nMode == 3
      ::oWnd:Refresh()
   CASE ::nMode == 2
      IF Abs( nRow - ::aDrag[ 1 ] ) > 4 .OR. Abs( nCol - ::aDrag[ 2 ] ) > 4
         ::aBox := { ::aDrag[ 1 ], ::aDrag[ 2 ], nRow, nCol }
         ::oWnd:Refresh()
      ENDIF
   OTHERWISE
      IF ::aRub != NIL
         ::oWnd:Refresh()
      ENDIF
      aW := VwC_S2W( ::oCam, nCol, nRow )
      IF VwC_Is3D( ::oCam )
         ::Status( "Vista 3D (alambre)  azimut " + AllTrim( Str( ::oCam[ "yaw" ] * 180.0 / 3.14159265358979, 8, 1 ) ) + ;
                   "  elevacion " + AllTrim( Str( ::oCam[ "pitch" ] * 180.0 / 3.14159265358979, 8, 1 ) ) + "   Mayus+rueda pulsada = orbita" )
         RETURN NIL
      ENDIF
      ::Status( "X=" + AllTrim( Str( aW[ 1 ], 14, 4 ) ) + "  Y=" + AllTrim( Str( aW[ 2 ], 14, 4 ) ) + ;
                "   zoom " + AllTrim( Str( ::oCam[ "scale" ], 14, 4 ) ) + If( Empty( ::cCmd ), "", "   Comando: " + ::cCmd ) )
   ENDCASE
RETURN NIL

METHOD Prompt() CLASS TViewer
   ::Status( "Comando: " + ::cCmd + "_" )
RETURN NIL

METHOD OnChar( nKey ) CLASS TViewer
   DO CASE
   CASE nKey == 13
      ::RunCmd()
   CASE nKey == 8
      IF Len( ::cCmd ) > 0 ; ::cCmd := Left( ::cCmd, Len( ::cCmd ) - 1 ) ; ENDIF
      ::Prompt()
   CASE nKey == 27
      ::cCmd := ""
      ::aRub := NIL
      IF ::oSes != NIL
         ::oSes[ "pend" ] := NIL
         ::oSes[ "sel" ] := hb_Hash()
      ENDIF
      ::Status( "Cancelado" )
      ::oWnd:Refresh()
   CASE nKey >= 32 .AND. nKey < 256
      ::cCmd += Chr( nKey )
      ::Prompt()
   ENDCASE
RETURN NIL

METHOD RunCmd() CLASS TViewer
   LOCAL cLine := ::cCmd
   ::cCmd := ""
   IF Empty( cLine ) .AND. ::oSes != NIL .AND. hb_HHasKey( ::oSes, "pend" ) .AND. ::oSes[ "pend" ] != NIL
      ::Exec( "" )
      RETURN NIL
   ENDIF
   ::Exec( cLine )
RETURN NIL

METHOD SaveAs() CLASS TViewer
   LOCAL cFile
   IF ::oSes == NIL
      ::Status( "Abra un DXF primero (Archivo, Abrir DXF)" )
      RETURN NIL
   ENDIF
   cFile := cGetFile( "Dibujos DXF (*.dxf)|*.dxf|", "Guardar como", 1, , .T. )
   IF Empty( cFile )
      RETURN NIL
   ENDIF
   IF ! ( Lower( Right( cFile, 4 ) ) == ".dxf" )
      cFile += ".dxf"
   ENDIF
   IF hb_FileExists( cFile ) .AND. ! MsgYesNo( "El archivo ya existe:" + CRLF + cFile + CRLF + "Sobrescribir?", "Guardar como" )
      RETURN NIL
   ENDIF
   ::Exec( "GUARDAR " + cFile )
   IF hb_HHasKey( ::oSes, "file" ) .AND. ::oSes[ "file" ] == cFile
      ::cFile := cFile
      ::Title()
   ENDIF
RETURN NIL

/* accion de un boton de la cinta: @ = accion de la ventana, resto = linea de comandos */
METHOD Run( cCmd ) CLASS TViewer
   DO CASE
   CASE Empty( cCmd ) ; ::Status( "Aun no portado (ver hoja Fase2)" )
   CASE cCmd == "@ABRIR" ; ::Open()
   CASE cCmd == "@GUARDARCOMO" ; ::SaveAs()
   CASE cCmd == "@ZOOMIN" ; ::Zoom( 1.5 )
   CASE cCmd == "@ZOOMOUT" ; ::Zoom( 1.0 / 1.5 )
   CASE cCmd == "@SALIR" ; ::oWnd:End()
   OTHERWISE ; ::Exec( cCmd )
   ENDCASE
   ::oWnd:Refresh()
RETURN NIL

METHOD Exec( cLine ) CLASS TViewer
   LOCAL r
   IF ::oSes == NIL .OR. ( Empty( cLine ) .AND. ! ( hb_HHasKey( ::oSes, "pend" ) .AND. ::oSes[ "pend" ] != NIL ) )
      IF ::oSes == NIL .AND. ! Empty( cLine )
         ::Status( "Abra un DXF primero (Archivo, Abrir DXF)" )
      ENDIF
      RETURN NIL
   ENDIF
   ::Size()
   r := VwK_Exec( ::oSes, cLine )
   ::oScene := ::oSes[ "scene" ]
   ::aRub := IIf( hb_HHasKey( ::oSes, "pend" ) .AND. ::oSes[ "pend" ] != NIL .AND. Len( ::oSes[ "pend" ][ "pts" ] ) > 0, ATail( ::oSes[ "pend" ][ "pts" ] ), NIL )
   ::Status( StrTran( r[ 1 ], Chr( 10 ), " " ) )
   IF r[ 2 ]
      MsgInfo( r[ 1 ], "OpenHBCADStudio - " + Upper( cLine ) )
   ENDIF
   IF r[ 3 ]
      ::oWnd:Refresh()
   ENDIF
RETURN NIL


   METHOD OnKey( nKey ) CLASS TViewer
   DO CASE
   CASE nKey == 36                                     // Inicio
      ::Fit()
   CASE nKey == 37 .OR. nKey == 38 .OR. nKey == 39 .OR. nKey == 40   // flechas
      ::Size()
      VwC_PanPx( ::oCam, If( nKey == 37, 40, If( nKey == 39, -40, 0 ) ), If( nKey == 38, 40, If( nKey == 40, -40, 0 ) ) )
      ::oWnd:Refresh()
   CASE nKey == 79 .AND. GetKeyState( 17 )              // Ctrl+O
      ::Open()
   CASE nKey == 83 .AND. GetKeyState( 17 )              // Ctrl+S (Mayus = guardar como)
      IF GetKeyState( 16 ) ; ::SaveAs() ; ELSE ; ::Exec( "GUARDAR" ) ; ENDIF
   CASE nKey == 90 .AND. GetKeyState( 17 )              // Ctrl+Z
      ::Exec( "DESHACER" )
   CASE nKey == 46                                      // Supr
      ::Exec( "BORRAR" )
   ENDCASE
RETURN NIL

METHOD Pen( nRgb, nStyle ) CLASS TViewer
   LOCAL nKey := nRgb * 8 + nStyle, n := AScan( ::hPenKeys, nKey )
   IF n == 0
      AAdd( ::hPenKeys, nKey )
      AAdd( ::aPens, CreatePen( nStyle, 1, nRgb ) )
      n := Len( ::aPens )
   ENDIF
RETURN ::aPens[ n ]

METHOD FreePens() CLASS TViewer
   LOCAL h
   FOR EACH h IN ::aPens
      DeleteObject( h )
   NEXT
   ::aPens := {}
   ::hPenKeys := {}
RETURN NIL

METHOD FontFor( nPx, nRot ) CLASS TViewer
   LOCAL nEsc := Int( nRot * 180.0 / 3.14159265358979 * 10 ), cKey := hb_ntos( nPx ) + "/" + hb_ntos( nEsc ), n, oF
   n := AScan( ::aFonts, { | a | a[ 1 ] == cKey } )
   IF n == 0
      DEFINE FONT oF NAME "Arial" SIZE 0, - nPx NESCAPEMENT nEsc
      AAdd( ::aFonts, { cKey, oF } )
      n := Len( ::aFonts )
   ENDIF
RETURN ::aFonts[ n ][ 2 ]

METHOD FreeFonts() CLASS TViewer
   LOCAL a
   FOR EACH a IN ::aFonts
      a[ 2 ]:End()
   NEXT
   ::aFonts := {}
RETURN NIL

METHOD Paint( hDC ) CLASS TViewer
   LOCAL c := ::Size(), nW := c[ "w" ], nH := c[ "h" ], hMem, hBmp, hOld, hBr
   LOCAL lV3 := VwC_Is3D( c ), aVis, w, p, a, nI, nX, nY, nLX, nLY, hPen, hOldPen, aT, nPx, oF, aS, nN := 0, aB
   hMem := CreateCompatibleDC( hDC )
   hBmp := CreateCompatibleBitmap( hDC, nW, nH )
   hOld := SelectObject( hMem, hBmp )
   hBr := CreateSolidBrush( VWW_BG )
   FillRect( hMem, { 0, 0, nH, nW }, hBr )
   DeleteObject( hBr )
   IF ::oScene != NIL
      aVis := VwC_Visible( c )
      hOldPen := NIL
      IF lV3
         VwC_Setup( c )
      ELSE
         ::DrawFills( hMem, c )
      ENDIF
      FOR EACH w IN ::oScene[ "wires" ]
         aB := w[ 4 ]
         IF ! lV3 .AND. ( aB[ 3 ] < aVis[ 1 ] .OR. aB[ 1 ] > aVis[ 3 ] .OR. aB[ 4 ] < aVis[ 2 ] .OR. aB[ 2 ] > aVis[ 4 ] )
            LOOP
         ENDIF
         IF ! Empty( w[ 6 ] ) .AND. ::oSes != NIL .AND. hb_HHasKey( ::oSes[ "sel" ], w[ 6 ] )
            hPen := ::Pen( VWW_CYAN, 0 )
         ELSE
            hPen := ::Pen( w[ 1 ], w[ 5 ] )
         ENDIF
         nI := SelectObject( hMem, hPen )
         IF hOldPen == NIL ; hOldPen := nI ; ENDIF
         nLX := NIL
         FOR EACH p IN w[ 3 ]
            a := If( lV3, VwC_P3( c, p[ 1 ], p[ 2 ], If( Len( p ) >= 3, p[ 3 ], 0.0 ) ), VwC_W2S( c, p[ 1 ], p[ 2 ] ) )
            nX := Max( - 30000, Min( 30000, Int( a[ 1 ] ) ) )
            nY := Max( - 30000, Min( 30000, Int( a[ 2 ] ) ) )
            IF nLX == NIL
               MoveTo( hMem, nX, nY )
               IF Len( w[ 3 ] ) == 1          // punto: marca de 1 px
                  LineTo( hMem, nX + 1, nY )
               ENDIF
            ELSEIF nX != nLX .OR. nY != nLY
               LineTo( hMem, nX, nY )
            ENDIF
            nLX := nX ; nLY := nY
         NEXT
      NEXT
      IF hOldPen != NIL
         SelectObject( hMem, hOldPen )
      ENDIF
      IF ! lV3
         ::DrawGrips( hMem, c )
      ENDIF
      SetBkMode( hMem, 1 )
      FOR EACH aT IN If( lV3, {}, ::oScene[ "texts" ] )
         nPx := Int( aT[ 3 ] * c[ "scale" ] )
         IF nPx < 5 .OR. nPx > 2000
            LOOP
         ENDIF
         a := VwC_W2S( c, aT[ 1 ], aT[ 2 ] )
         IF a[ 1 ] < - 2000 .OR. a[ 1 ] > nW + 2000 .OR. a[ 2 ] < - 2000 .OR. a[ 2 ] > nH + 2000
            LOOP
         ENDIF
         oF := ::FontFor( nPx, aT[ 4 ] )
         aS := SelectObject( hMem, oF:hFont )
         SetTextColor( hMem, aT[ 6 ] )
         TextOut( hMem, Int( a[ 2 ] ) - nPx, Int( a[ 1 ] ), aT[ 5 ] )
         SelectObject( hMem, aS )
         IF ++nN >= VWW_MAXTEXTS ; EXIT ; ENDIF
      NEXT
   ENDIF
   IF ::aSnap != NIL
      a := VwC_W2S( c, ::aSnap[ 1 ], ::aSnap[ 2 ] )
      hPen := CreatePen( 0, 1, VWW_YELLOW )
      hOldPen := SelectObject( hMem, hPen )
      MoveTo( hMem, Int( a[ 1 ] ) - 6, Int( a[ 2 ] ) - 6 ) ; LineTo( hMem, Int( a[ 1 ] ) + 6, Int( a[ 2 ] ) - 6 )
      LineTo( hMem, Int( a[ 1 ] ) + 6, Int( a[ 2 ] ) + 6 ) ; LineTo( hMem, Int( a[ 1 ] ) - 6, Int( a[ 2 ] ) + 6 )
      LineTo( hMem, Int( a[ 1 ] ) - 6, Int( a[ 2 ] ) - 6 )
      SelectObject( hMem, hOldPen )
      DeleteObject( hPen )
      SetBkMode( hMem, 1 )
      SetTextColor( hMem, VWW_YELLOW )
      TextOut( hMem, Int( a[ 2 ] ) + 8, Int( a[ 1 ] ) + 8, ::aSnap[ 3 ] )
   ENDIF
   IF ::nTop == 0 ; ::DrawBar( hMem, c ) ; ENDIF
   IF ::aRub != NIL .OR. ( ::nMode == 3 .AND. ::aGrip != NIL )
      a := VwC_W2S( c, If( ::aRub != NIL, ::aRub[ 1 ], ::aGrip[ 3 ] ), If( ::aRub != NIL, ::aRub[ 2 ], ::aGrip[ 4 ] ) )
      hPen := CreatePen( 2, 1, 16777215 )
      hOldPen := SelectObject( hMem, hPen )
      MoveTo( hMem, Int( a[ 1 ] ), Int( a[ 2 ] ) )
      LineTo( hMem, ::aMouse[ 2 ], ::aMouse[ 1 ] )
      SelectObject( hMem, hOldPen )
      DeleteObject( hPen )
   ENDIF
   IF ::aBox != NIL
      // goma elastica: ventana (izq a der) = continua, captura = discontinua
      hPen := CreatePen( If( ::aBox[ 4 ] >= ::aBox[ 2 ], 0, 2 ), 1, If( ::aBox[ 4 ] >= ::aBox[ 2 ], VWW_CYAN, VWW_SUCCESS ) )
      hOldPen := SelectObject( hMem, hPen )
      MoveTo( hMem, ::aBox[ 2 ], ::aBox[ 1 ] ) ; LineTo( hMem, ::aBox[ 4 ], ::aBox[ 1 ] )
      LineTo( hMem, ::aBox[ 4 ], ::aBox[ 3 ] ) ; LineTo( hMem, ::aBox[ 2 ], ::aBox[ 3 ] )
      LineTo( hMem, ::aBox[ 2 ], ::aBox[ 1 ] )
      SelectObject( hMem, hOldPen )
      DeleteObject( hPen )
   ENDIF
   BitBlt( hDC, 0, ::nTop, nW, nH, hMem, 0, 0, VWW_ROP_SRCCOPY )
   SelectObject( hMem, hOld )
   DeleteObject( hBmp )
   DeleteDC( hMem )
RETURN NIL

/* relleno HATCH: par-impar por lineas de barrido; solido = todas las filas,
   con patron = una de cada 6 (indicador aproximado) */
METHOD DrawFills( hMem, c ) CLASS TViewer
   LOCAL f, aVis := VwC_Visible( c ), aL, p, a, hPen, hOld, nY, nY0, nY1, aX, i, nStep, nN, aP, aQ
   FOR EACH f IN ::oScene[ "fills" ]
      IF f[ 3 ][ 3 ] < aVis[ 1 ] .OR. f[ 3 ][ 1 ] > aVis[ 3 ] .OR. f[ 3 ][ 4 ] < aVis[ 2 ] .OR. f[ 3 ][ 2 ] > aVis[ 4 ]
         LOOP
      ENDIF
      hPen := ::Pen( If( ! Empty( f[ 5 ] ) .AND. ::oSes != NIL .AND. hb_HHasKey( ::oSes[ "sel" ], f[ 5 ] ), VWW_CYAN, f[ 1 ] ), 0 )
      hOld := SelectObject( hMem, hPen )
      aP := VwC_W2S( c, f[ 3 ][ 1 ], f[ 3 ][ 4 ] )
      aQ := VwC_W2S( c, f[ 3 ][ 3 ], f[ 3 ][ 2 ] )
      nY0 := Max( 0, Int( aP[ 2 ] ) ) ; nY1 := Min( c[ "h" ], Int( aQ[ 2 ] ) )
      nStep := If( f[ 4 ], 1, 6 )
      nY := nY0
      DO WHILE nY <= nY1
         aX := {}
         FOR EACH aL IN f[ 2 ]
            FOR i := 1 TO Len( aL )
               a := VwC_W2S( c, aL[ i ][ 1 ], aL[ i ][ 2 ] )
               p := VwC_W2S( c, aL[ If( i == Len( aL ), 1, i + 1 ) ][ 1 ], aL[ If( i == Len( aL ), 1, i + 1 ) ][ 2 ] )
               IF ( a[ 2 ] <= nY .AND. p[ 2 ] > nY ) .OR. ( p[ 2 ] <= nY .AND. a[ 2 ] > nY )
                  AAdd( aX, a[ 1 ] + ( nY - a[ 2 ] ) * ( p[ 1 ] - a[ 1 ] ) / ( p[ 2 ] - a[ 2 ] ) )
               ENDIF
            NEXT
         NEXT
         ASort( aX )
         nN := 1
         DO WHILE nN < Len( aX )
            MoveTo( hMem, Max( - 30000, Int( aX[ nN ] ) ), nY )
            LineTo( hMem, Min( 30000, Int( aX[ nN + 1 ] ) + 1 ), nY )
            nN += 2
         ENDDO
         nY += nStep
      ENDDO
      SelectObject( hMem, hOld )
   NEXT
RETURN NIL

METHOD DrawGrips( hMem, c ) CLASS TViewer
   LOCAL k, g, a, hPen, hBr, hOldP, hOldB
   IF ::oSes == NIL .OR. Len( ::oSes[ "sel" ] ) == 0 .OR. Len( ::oSes[ "sel" ] ) > 200
      RETURN NIL
   ENDIF
   hPen := CreatePen( 0, 1, VWW_BLUE )
   hBr := CreateSolidBrush( VWW_BLUE )
   hOldP := SelectObject( hMem, hPen )
   hOldB := SelectObject( hMem, hBr )
   FOR EACH k IN hb_HKeys( ::oSes[ "sel" ] )
      IF ! hb_HHasKey( ::oScene[ "ents" ], k ) ; LOOP ; ENDIF
      FOR EACH g IN Vwp_Grips( ::oScene[ "ents" ][ k ] )
         a := VwC_W2S( c, g[ 1 ], g[ 2 ] )
         IF a[ 1 ] > - 50 .AND. a[ 1 ] < c[ "w" ] + 50 .AND. a[ 2 ] > - 50 .AND. a[ 2 ] < c[ "h" ] + 50
            Rectangle( hMem, Int( a[ 2 ] ) - 3, Int( a[ 1 ] ) - 3, Int( a[ 2 ] ) + 3, Int( a[ 1 ] ) + 3 )
         ENDIF
      NEXT
   NEXT
   SelectObject( hMem, hOldP )
   SelectObject( hMem, hOldB )
   DeleteObject( hPen )
   DeleteObject( hBr )
RETURN NIL

/* barra de botones propia (GDI) en la parte alta del lienzo */
METHOD DrawBar( hMem, c ) CLASS TViewer
   LOCAL b, hBr := CreateSolidBrush( 4210752 ), hPen := CreatePen( 0, 1, 10526880 ), hOld, lOn := .T.
   FillRect( hMem, { 0, 0, VWW_BARH, c[ "w" ] }, hBr )
   DeleteObject( hBr )
   SetBkMode( hMem, 1 )
   hOld := SelectObject( hMem, hPen )
   IF ::oSes != NIL .AND. hb_HHasKey( ::oSes, "snap" ) ; lOn := ::oSes[ "snap" ][ "on" ] ; ENDIF
   FOR EACH b IN ::aBtns
      IF Empty( b[ 2 ] )
         SetTextColor( hMem, 10526880 )
         TextOut( hMem, 6, b[ 3 ], "|" )
         LOOP
      ENDIF
      MoveTo( hMem, b[ 3 ], 2 ) ; LineTo( hMem, b[ 4 ], 2 ) ; LineTo( hMem, b[ 4 ], VWW_BARH - 3 )
      LineTo( hMem, b[ 3 ], VWW_BARH - 3 ) ; LineTo( hMem, b[ 3 ], 2 )
      SetTextColor( hMem, If( b[ 2 ] == "SNAP" .AND. ! lOn, 8421504, 16777215 ) )
      TextOut( hMem, 6, b[ 3 ] + 6, b[ 1 ] )
   NEXT
   SelectObject( hMem, hOld )
   DeleteObject( hPen )
RETURN NIL
