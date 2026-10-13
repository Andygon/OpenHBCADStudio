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
#define VWW_CYAN        16776960
#define VWW_BLUE        16711680

CLASS TViewer
   DATA oWnd
   DATA oBrush
   DATA oCam
   DATA oScene
   DATA oSes
   DATA cCmd     INIT ""
   DATA nMode    INIT 0
   DATA aBox     INIT NIL
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
         MENUITEM "&Abrir DXF..." ACTION oSelf:Open()
         SEPARATOR
         MENUITEM "&Salir" ACTION oSelf:oWnd:End()
      ENDMENU
      MENUITEM "&Vista"
      MENU
         MENUITEM "Zoom &extensiones" ACTION oSelf:Fit()
         MENUITEM "&Acercar" ACTION oSelf:Zoom( 1.5 )
         MENUITEM "A&lejar" ACTION oSelf:Zoom( 1.0 / 1.5 )
      ENDMENU
   ENDMENU
   DEFINE BRUSH ::oBrush COLOR 0
   DEFINE WINDOW ::oWnd TITLE "OpenHBCADStudio - Visor" MENU oMenu BRUSH ::oBrush
   SET MESSAGE OF ::oWnd TO "Listo. Abra un DXF (Archivo, Abrir DXF) o pase la ruta como argumento."
   ::oWnd:bPainted    := { | hDC | oSelf:Paint( hDC ) }
   ::oWnd:bResized    := { || oSelf:oWnd:Refresh() }
   ::oWnd:bLClicked   := { | nRow, nCol | oSelf:OnLDown( nRow, nCol ) }
   ::oWnd:bLButtonUp  := { || oSelf:OnLUp() }
   ::oWnd:bMMoved     := { | nRow, nCol, nFlags | oSelf:OnMove( nRow, nCol, nFlags ) }
   ::oWnd:bMouseWheel := { | nKey, nDelta | oSelf:OnWheel( nDelta ) }
   ::oWnd:bKeyDown    := { | nKey | oSelf:OnKey( nKey ) }
   ::oWnd:bKeyChar    := { | nKey | oSelf:OnChar( nKey ) }
   ACTIVATE WINDOW ::oWnd MAXIMIZED ON INIT oSelf:OnInit() ;
      VALID ( oSelf:FreePens(), oSelf:FreeFonts(), .T. )
RETURN NIL

METHOD OnInit() CLASS TViewer
   BEGIN SEQUENCE WITH { | e | Break( e ) }
      ::oWnd:bMButtonDown := { | nRow, nCol | ::OnMDown( nRow, nCol ) }
      ::oWnd:bMButtonUp   := { || ::OnLUp() }
   END SEQUENCE
   IF ! Empty( ::cFile )
      ::Open( ::cFile )
   ENDIF
RETURN NIL

METHOD Size() CLASS TViewer
   LOCAL aR := GetClientRect( ::oWnd:hWnd )
   VwC_SetSize( ::oCam, aR[ 4 ] - aR[ 2 ], aR[ 3 ] - aR[ 1 ] )
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
      VwC_FitExtents( ::oCam, Vws_Extents( ::oScene ), 0.95 )
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

METHOD OnLDown( nRow, nCol ) CLASS TViewer
   ::aDrag := { nRow, nCol }
   ::aBox := NIL
   ::nMode := If( GetKeyState( 17 ), 1, 2 )
   SetCapture( ::oWnd:hWnd )
RETURN NIL

METHOD OnMDown( nRow, nCol ) CLASS TViewer
   ::aDrag := { nRow, nCol }
   ::nMode := 1
   SetCapture( ::oWnd:hWnd )
RETURN NIL

METHOD OnLUp() CLASS TViewer
   LOCAL aW, aW2, aH, k, lMove, nTol, s := ::oSes, lShift := GetKeyState( 16 )
   IF ::nMode == 0
      RETURN NIL
   ENDIF
   ReleaseCapture()
   IF ::nMode == 2 .AND. s != NIL
      lMove := Abs( ::aMouse[ 1 ] - ::aDrag[ 1 ] ) > 4 .OR. Abs( ::aMouse[ 2 ] - ::aDrag[ 2 ] ) > 4
      ::Size()
      IF lMove
         aW := VwC_S2W( ::oCam, ::aDrag[ 2 ], ::aDrag[ 1 ] )
         aW2 := VwC_S2W( ::oCam, ::aMouse[ 2 ], ::aMouse[ 1 ] )
         aH := Vwp_Box( ::oScene, aW[ 1 ], aW[ 2 ], aW2[ 1 ], aW2[ 2 ] )
         IF ! lShift ; s[ "sel" ] := hb_Hash() ; ENDIF
         FOR EACH k IN aH
            s[ "sel" ][ k ] := .T.
         NEXT
      ELSE
         aW := VwC_S2W( ::oCam, ::aDrag[ 2 ], ::aDrag[ 1 ] )
         nTol := 6.0 / ::oCam[ "scale" ]
         k := Vwp_Pick( ::oScene, aW[ 1 ], aW[ 2 ], nTol )
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
   DO CASE
   CASE ::nMode == 1
      VwC_PanPx( ::oCam, nCol - ::aDrag[ 2 ], nRow - ::aDrag[ 1 ] )
      ::aDrag := { nRow, nCol }
      ::oWnd:Refresh()
   CASE ::nMode == 2
      IF Abs( nRow - ::aDrag[ 1 ] ) > 4 .OR. Abs( nCol - ::aDrag[ 2 ] ) > 4
         ::aBox := { ::aDrag[ 1 ], ::aDrag[ 2 ], nRow, nCol }
         ::oWnd:Refresh()
      ENDIF
   OTHERWISE
      aW := VwC_S2W( ::oCam, nCol, nRow )
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
      IF ::oSes != NIL ; ::oSes[ "sel" ] := hb_Hash() ; ENDIF
      ::Status( "Cancelado" )
      ::oWnd:Refresh()
   CASE nKey >= 32 .AND. nKey < 256
      ::cCmd += Chr( nKey )
      ::Prompt()
   ENDCASE
RETURN NIL

METHOD RunCmd() CLASS TViewer
   LOCAL r, cLine := ::cCmd
   ::cCmd := ""
   IF Empty( cLine ) .OR. ::oSes == NIL
      IF ::oSes == NIL .AND. ! Empty( cLine )
         ::Status( "Abra un DXF primero (Archivo, Abrir DXF)" )
      ENDIF
      RETURN NIL
   ENDIF
   ::Size()
   r := VwK_Exec( ::oSes, cLine )
   ::oScene := ::oSes[ "scene" ]
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
   LOCAL aVis, w, p, a, nI, nX, nY, nLX, nLY, hPen, hOldPen, aT, nPx, oF, aS, nN := 0, aB
   hMem := CreateCompatibleDC( hDC )
   hBmp := CreateCompatibleBitmap( hDC, nW, nH )
   hOld := SelectObject( hMem, hBmp )
   hBr := CreateSolidBrush( 0 )
   FillRect( hMem, { 0, 0, nH, nW }, hBr )
   DeleteObject( hBr )
   IF ::oScene != NIL
      aVis := VwC_Visible( c )
      hOldPen := NIL
      ::DrawFills( hMem, c )
      FOR EACH w IN ::oScene[ "wires" ]
         aB := w[ 4 ]
         IF aB[ 3 ] < aVis[ 1 ] .OR. aB[ 1 ] > aVis[ 3 ] .OR. aB[ 4 ] < aVis[ 2 ] .OR. aB[ 2 ] > aVis[ 4 ]
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
            a := VwC_W2S( c, p[ 1 ], p[ 2 ] )
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
      ::DrawGrips( hMem, c )
      SetBkMode( hMem, 1 )
      FOR EACH aT IN ::oScene[ "texts" ]
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
   IF ::aBox != NIL
      // goma elastica: ventana (izq a der) = continua, captura = discontinua
      hPen := CreatePen( If( ::aBox[ 4 ] >= ::aBox[ 2 ], 0, 2 ), 1, 16777215 )
      hOldPen := SelectObject( hMem, hPen )
      MoveTo( hMem, ::aBox[ 2 ], ::aBox[ 1 ] ) ; LineTo( hMem, ::aBox[ 4 ], ::aBox[ 1 ] )
      LineTo( hMem, ::aBox[ 4 ], ::aBox[ 3 ] ) ; LineTo( hMem, ::aBox[ 2 ], ::aBox[ 3 ] )
      LineTo( hMem, ::aBox[ 2 ], ::aBox[ 1 ] )
      SelectObject( hMem, hOldPen )
      DeleteObject( hPen )
   ENDIF
   BitBlt( hDC, 0, 0, nW, nH, hMem, 0, 0, VWW_ROP_SRCCOPY )
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
