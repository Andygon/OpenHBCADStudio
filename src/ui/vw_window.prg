/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/ui/vw_window.prg
   Fase 2 / bloques B3 y B4 (hito 1: visor). Origen Rust: src/app.rs +
   src/scene/pipeline (render) + src/scene/view (camara).
   Ventana FiveWin con el visor: Abrir DXF (codec portado), render GDI con
   doble buffer, zoom con rueda, pan arrastrando, zoom extents.
   La logica (escena y camara) esta en src/view/ y se prueba en consola.
   Teclas: Inicio o E = zoom extents, + / - = acercar/alejar, Ctrl+O = abrir.
----------------------------------------------------------------------------*/
#include "FiveWin.ch"

#define VWW_ROP_SRCCOPY 13369376
#define VWW_MAXTEXTS    4000

CLASS TViewer
   DATA oWnd
   DATA oBrush
   DATA oCam
   DATA oScene
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
   METHOD Pen( nRgb )
   METHOD FreePens()
   METHOD FontFor( nPx, nRot )
   METHOD FreeFonts()
   METHOD Size()
   METHOD Fit()
   METHOD Zoom( nF )
   METHOD OnWheel( nDelta )
   METHOD OnLDown( nRow, nCol )
   METHOD OnLUp()
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
   ACTIVATE WINDOW ::oWnd MAXIMIZED ON INIT oSelf:OnInit() ;
      VALID ( oSelf:FreePens(), oSelf:FreeFonts(), .T. )
RETURN NIL

METHOD OnInit() CLASS TViewer
   BEGIN SEQUENCE WITH { | e | Break( e ) }
      ::oWnd:bMButtonDown := { | nRow, nCol | ::OnLDown( nRow, nCol ) }
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
   ::oScene := Vws_Build( d )
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
   ::lDrag := .T.
   ::aDrag := { nRow, nCol }
   SetCapture( ::oWnd:hWnd )
RETURN NIL

METHOD OnLUp() CLASS TViewer
   IF ::lDrag
      ::lDrag := .F.
      ReleaseCapture()
   ENDIF
RETURN NIL

METHOD OnMove( nRow, nCol, nFlags ) CLASS TViewer
   LOCAL aW
   ::aMouse := { nRow, nCol }
   IF ::lDrag
      ::Size()
      VwC_PanPx( ::oCam, nCol - ::aDrag[ 2 ], nRow - ::aDrag[ 1 ] )
      ::aDrag := { nRow, nCol }
      ::oWnd:Refresh()
   ELSE
      ::Size()
      aW := VwC_S2W( ::oCam, nCol, nRow )
      ::Status( "X=" + AllTrim( Str( aW[ 1 ], 14, 4 ) ) + "  Y=" + AllTrim( Str( aW[ 2 ], 14, 4 ) ) + ;
                "   zoom " + AllTrim( Str( ::oCam[ "scale" ], 14, 4 ) ) )
   ENDIF
RETURN NIL

METHOD OnKey( nKey ) CLASS TViewer
   DO CASE
   CASE nKey == 36 .OR. nKey == 69 .OR. nKey == 101    // Inicio, E
      ::Fit()
   CASE nKey == 107 .OR. nKey == 187 .OR. nKey == 43   // +
      ::Zoom( 1.5 )
   CASE nKey == 109 .OR. nKey == 189 .OR. nKey == 45   // -
      ::Zoom( 1.0 / 1.5 )
   CASE nKey == 79 .AND. GetKeyState( 17 )              // Ctrl+O
      ::Open()
   ENDCASE
RETURN NIL

METHOD Pen( nRgb ) CLASS TViewer
   LOCAL n := AScan( ::hPenKeys, nRgb )
   IF n == 0
      AAdd( ::hPenKeys, nRgb )
      AAdd( ::aPens, CreatePen( 0, 1, nRgb ) )
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
      FOR EACH w IN ::oScene[ "wires" ]
         aB := w[ 4 ]
         IF aB[ 3 ] < aVis[ 1 ] .OR. aB[ 1 ] > aVis[ 3 ] .OR. aB[ 4 ] < aVis[ 2 ] .OR. aB[ 2 ] > aVis[ 4 ]
            LOOP
         ENDIF
         hPen := ::Pen( w[ 1 ] )
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
   BitBlt( hDC, 0, 0, nW, nH, hMem, 0, 0, VWW_ROP_SRCCOPY )
   SelectObject( hMem, hOld )
   DeleteObject( hBmp )
   DeleteDC( hMem )
RETURN NIL
