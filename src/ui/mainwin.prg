/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/ui/mainwin.prg
   Rust origen: src/app.rs (App) + src/ui/ribbon/mod.rs + draw_panel.rs +
                modify_panel.rs + src/ui/statusbar/mod.rs +
                src/ui/window/*.rs (capas, trazar, opciones: aqu?? men??) +
                src/ui/dock.rs + src/app/shortcuts.rs
   Ventana principal MDI: men?? + barra de botones + hijo-canvas +
   l??nea de comandos + panel propiedades + coordenadas.
   (Ribbon iced -> ButtonBar+men?? FiveWin; ver docs/PORTING.md.)
----------------------------------------------------------------------------*/
#include "ohbcad.ch"
#include "FiveWin.ch"

CLASS TMainWin
   DATA oDoc
   DATA oFrame
   DATA oChild
   DATA oCanvas     // TCadCanvas
   DATA oBar
   DATA cFile    INIT ""
   METHOD New( cFile ) CONSTRUCTOR
   METHOD Activate()
   METHOD Layout()
   METHOD RunCmd( cName )
   METHOD OnKeys( nKey, nFlags )
   METHOD OnMove( nRow, nCol, nFlags )
   METHOD UpdateTitle()
ENDCLASS

METHOD New( cFile ) CLASS TMainWin
   LOCAL oDoc
   ::cFile := If( cFile == NIL, "", cFile )
   oDoc := TDocDrawing():New()
   IF ! Empty( ::cFile ) .AND. File( ::cFile )
      oDoc := OC_DxfLoad( ::cFile )
      IF oDoc == NIL
         oDoc := TDocDrawing():New()
      ENDIF
   ENDIF
   ::oDoc := oDoc
   ::oCanvas := TCadCanvas():New( oDoc )
RETURN Self

METHOD Activate() CLASS TMainWin
   LOCAL oMenu := OHB_BuildMenu( Self )
   DEFINE WINDOW ::oFrame FROM 1, 1 TO 30, 120 ;
      TITLE "OpenHBCADStudio " + OHB_Version() MDI MENU oMenu
   DEFINE BUTTONBAR ::oBar OF ::oFrame SIZE 60, 32
   DEFINE BUTTON PROMPT "L??nea" OF ::oBar ACTION ::RunCmd( "LINEA" ) ;
      TOOLTIP "L??nea (LINEA)"
   DEFINE BUTTON PROMPT "C??rculo" OF ::oBar ACTION ::RunCmd( "CIRCULO" ) ;
      TOOLTIP "C??rculo (CIRCULO)"
   DEFINE BUTTON PROMPT "Arco" OF ::oBar ACTION ::RunCmd( "ARCO" ) ;
      TOOLTIP "Arco 3 puntos (ARCO)"
   DEFINE BUTTON PROMPT "Mueve" OF ::oBar ACTION ::RunCmd( "MUEVE" ) ;
      TOOLTIP "Mueve (MUEVE)"
   DEFINE BUTTON PROMPT "Copia" OF ::oBar ACTION ::RunCmd( "COPIA" ) ;
      TOOLTIP "Copia (COPIA)"
   DEFINE BUTTON PROMPT "ZoomE" OF ::oBar ACTION ::RunCmd( "ZOOM" ) ;
      TOOLTIP "Zoom extensi??n (ZOOM)"
   DEFINE BUTTON PROMPT "Capa" OF ::oBar ACTION ::RunCmd( "CAPA" ) ;
      TOOLTIP "Capas (CAPA)"
   DEFINE BUTTON PROMPT "Guarda" OF ::oBar ACTION ::RunCmd( "GUARDA" ) ;
      TOOLTIP "Guarda DXF (GUARDA)"
   SET MESSAGE OF ::oFrame TO "Listo. Escriba un comando o pulse un bot??n."
   DEFINE WINDOW ::oChild MDICHILD OF ::oFrame ;
      TITLE "Dibujo" COLOR "W/N"
   ::oCanvas:Attach( ::oChild )
   ::oChild:bResized := { || ::Layout() }
   ::oChild:bKeyDown := { | nK, nF | ::OnKeys( nK, nF ) }
   ::oChild:bMMoved := { | nR, nC, nF | ::OnMove( nR, nC, nF ) }
   OHB_CmdBarCreate( ::oChild, ::oCanvas, Self )
   OHB_PropPanelCreate( ::oChild )
   OHB_StatusCoordCreate( ::oChild )
   ACTIVATE WINDOW ::oChild MAXIMIZED ;
      VALID If( ::oDoc:lDirty, ;
         MsgYesNo( "Hay cambios sin guardar. ??Cerrar?", "Cerrar" ), .T. )
   ACTIVATE WINDOW ::oFrame MAXIMIZED ;
      VALID If( ::oDoc:lDirty, ;
         MsgYesNo( "Hay cambios sin guardar. ??Salir?", "Salir" ), .T. )
   ::Layout()
   ::oCanvas:ZoomExt()
   OHB_PropRefresh()
   OHB_CmdPrompt( "Comando (LINEA, CIRCULO, ARCO, MUEVE, ZOOM, ...):" )
RETURN NIL

METHOD Layout() CLASS TMainWin
   LOCAL aR, nW, nH, nCmdH := 30, nPropW := 230
   IF ::oChild == NIL .OR. ::oChild:hWnd == 0
      RETURN NIL
   ENDIF
   aR := GetClientRect( ::oChild:hWnd )
   nW := aR[ 4 ] - aR[ 2 ]
   nH := aR[ 3 ] - aR[ 1 ]
   OHB_CmdBarLayout( nH - nCmdH, 0, nW - nPropW )
   OHB_PropPanelLayout( 0, nW - nPropW, nPropW )
   OHB_StatusCoordLayout( nH - nCmdH, nW - nPropW )
   ::UpdateTitle()
RETURN NIL

METHOD RunCmd( cName ) CLASS TMainWin
   OHB_RunCmd( cName, ::oCanvas, Self )
   ::oChild:SetFocus()
   ::UpdateTitle()
RETURN NIL

METHOD OnKeys( nKey, nFlags ) CLASS TMainWin
   hb_default( @nFlags, 0 )
   DO CASE
   CASE nKey == 27
      IF ::oCanvas:oCmd != NIL
         ::oCanvas:oCmd:Cancel()
      ENDIF
   CASE nKey == 46
      IF ::oCanvas:oCmd == NIL
         ::RunCmd( "BORRA" )
      ENDIF
   CASE Upper( Chr( nKey ) ) == "L" .AND. ::oCanvas:oCmd == NIL
      ::RunCmd( "LINEA" )
   CASE Upper( Chr( nKey ) ) == "C" .AND. ::oCanvas:oCmd == NIL
      ::RunCmd( "CIRCULO" )
   CASE Upper( Chr( nKey ) ) == "Z" .AND. nFlags == 4
      ::RunCmd( "DESHACER" )
   CASE Upper( Chr( nKey ) ) == "S" .AND. nFlags == 4
      ::RunCmd( "GUARDA" )
   CASE Upper( Chr( nKey ) ) == "G" .AND. nFlags == 4
      ::RunCmd( "GUARDA" )
   ENDCASE
RETURN NIL

METHOD OnMove( nRow, nCol, nFlags ) CLASS TMainWin
   OHB_StatusCoords( ::oCanvas:S2WX( nCol ), ::oCanvas:S2WY( nRow ) )
   IF ::oCanvas:oCmd != NIL .AND. ;
         __objHasMethod( ::oCanvas:oCmd, "ONHOVER" )
      ::oCanvas:oCmd:OnHover( { ::oCanvas:S2WX( nCol ), ;
         ::oCanvas:S2WY( nRow ) }, ::oCanvas )
   ENDIF
RETURN NIL

METHOD UpdateTitle() CLASS TMainWin
   IF ::oFrame != NIL .AND. ::oFrame:hWnd != 0
      ::oFrame:SetText( "OpenHBCADStudio " + OHB_Version() + " - " + ;
         If( Empty( ::oDoc:cFile ), "Sin t??tulo", ::oDoc:cFile ) + ;
         If( ::oDoc:lDirty, " *", "" ) )
   ENDIF
RETURN NIL

//--- Men?? principal (Rust: ui/ribbon + ui/wide_menu.rs) -----------------------------
FUNCTION OHB_BuildMenu( oMain )
   LOCAL oMenu
   MENU oMenu
      MENUITEM "Archivo"
      MENU
         MENUITEM "Nuevo" ACTION oMain:RunCmd( "NUEVO" )
         MENUITEM "Abrir DXF..." ACTION oMain:RunCmd( "ABRE" )
         MENUITEM "Guardar DXF" ACTION oMain:RunCmd( "GUARDA" )
         SEPARATOR
         MENUITEM "Salir" ACTION oMain:oFrame:End()
      ENDMENU
      MENUITEM "Edici??n"
      MENU
         MENUITEM "Deshacer" ACTION oMain:RunCmd( "DESHACER" )
         MENUITEM "Borrar" ACTION oMain:RunCmd( "BORRA" )
         MENUITEM "Igualar propiedades" ACTION oMain:RunCmd( "IGUALA" )
      ENDMENU
      MENUITEM "Ver"
      MENU
         MENUITEM "Zoom extensi??n" ACTION oMain:RunCmd( "ZOOM" )
         MENUITEM "Encuadre" ACTION oMain:RunCmd( "ENCUADRE" )
         SEPARATOR
         MENUITEM "Ortho" ACTION ( oMain:oCanvas:lOrtho := ;
            ! oMain:oCanvas:lOrtho, ;
            OHB_CmdPrompt( "ORTHO " + ;
               If( oMain:oCanvas:lOrtho, "ON", "OFF" ) ) )
         MENUITEM "Rejilla" ACTION ( oMain:oCanvas:lGrid := ;
            ! oMain:oCanvas:lGrid, oMain:oCanvas:Refresh() )
      ENDMENU
      MENUITEM "Dibujo"
      MENU
         MENUITEM "L??nea" ACTION oMain:RunCmd( "LINEA" )
         MENUITEM "C??rculo" ACTION oMain:RunCmd( "CIRCULO" )
         MENUITEM "Arco 3P" ACTION oMain:RunCmd( "ARCO" )
         MENUITEM "Polil??nea" ACTION oMain:RunCmd( "POL" )
         MENUITEM "Punto" ACTION oMain:RunCmd( "PUNTO" )
         MENUITEM "Texto" ACTION oMain:RunCmd( "TEXTO" )
         MENUITEM "Elipse" ACTION oMain:RunCmd( "ELIPSE" )
         MENUITEM "Sombreado" ACTION oMain:RunCmd( "SOMBREADO" )
         MENUITEM "Cota lineal" ACTION oMain:RunCmd( "COTLIN" )
      ENDMENU
      MENUITEM "Modifica"
      MENU
         MENUITEM "Mueve" ACTION oMain:RunCmd( "MUEVE" )
         MENUITEM "Copia" ACTION oMain:RunCmd( "COPIA" )
         MENUITEM "Gira" ACTION oMain:RunCmd( "GIRA" )
         MENUITEM "Escala" ACTION oMain:RunCmd( "ESCALA" )
         MENUITEM "Simetr??a" ACTION oMain:RunCmd( "SIMETRIA" )
         MENUITEM "Desfase" ACTION oMain:RunCmd( "DESFASE" )
         MENUITEM "Empalme" ACTION oMain:RunCmd( "EMPALME" )
         MENUITEM "Recorta" ACTION oMain:RunCmd( "RECORTA" )
         MENUITEM "Matriz" ACTION oMain:RunCmd( "MATRIZ" )
      ENDMENU
      MENUITEM "Consulta"
      MENU
         MENUITEM "Distancia" ACTION oMain:RunCmd( "DIST" )
         MENUITEM "??rea" ACTION oMain:RunCmd( "AREA" )
         MENUITEM "ID punto" ACTION oMain:RunCmd( "ID" )
      ENDMENU
      MENUITEM "Capas"
      MENU
         MENUITEM "Gestor de capas..." ACTION oMain:RunCmd( "CAPA" )
      ENDMENU
      MENUITEM "Ayuda"
      MENU
         MENUITEM "Acerca de..." ACTION OHB_About()
      ENDMENU
   ENDMENU
RETURN oMenu

FUNCTION OHB_About()
   MsgInfo( "OpenHBCADStudio " + OHB_Version() + hb_eol() + ;
      "Port Harbour/FiveWin64 + MSVC22 de OpenCADStudio (Rust)." + hb_eol() + ;
      "Motor 2D GDI + n??cleo C de geometr??a." )
RETURN NIL
