/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/modules/draw/inquiry_cmds.prg
   Rust origen: src/modules/draw/inquiry/dist.rs + area.rs + id.rs +
                measuregeom.rs + divide.rs +
                src/modules/view/zoom_*.rs + pan.rs + limits.rs +
                src/modules/draw/layers/*.rs + src/ui/window/layers.rs +
                src/io/recovery.rs (nuevo/abre/guarda: ver también dxf_io)
----------------------------------------------------------------------------*/
#include "ohbcad.ch"
#include "FiveWin.ch"

//=========================== DIST =====================================================
CLASS TCmdDist FROM TCmdBase
   METHOD New() CONSTRUCTOR
   METHOD OnPick( aPt, nFlags )
ENDCLASS

METHOD New() CLASS TCmdDist
   ::super:New( "DIST" )
RETURN Self

METHOD OnPick( aPt, nFlags ) CLASS TCmdDist
   IF aPt == NIL
      RETURN ::Cancel()
   ENDIF
   AAdd( ::aPts, aPt )
   IF Len( ::aPts ) == 1
      OHB_CmdPrompt( "Precise segundo punto:" )
      RETURN OHB_CMD_NEED_POINT
   ENDIF
   OHB_CmdPrompt( "Distancia = " + LTrim( Str( OC_Dist2D( ::aPts[ 1 ], ;
      ::aPts[ 2 ] ), 0, 4 ) ) + "  Ángulo = " + ;
      LTrim( Str( OC_Rad2Deg( OC_Ang2D( ::aPts[ 1 ], ::aPts[ 2 ] ) ), 0, 2 ) ) + "°" )
RETURN ::Finish()

//=========================== AREA ======================================================
CLASS TCmdArea FROM TCmdBase
   DATA aHover INIT NIL
   METHOD New() CONSTRUCTOR
   METHOD OnPick( aPt, nFlags )
   METHOD OnHover( aPtW, oView )
   METHOD Preview( hDC, oView )
ENDCLASS

METHOD New() CLASS TCmdArea
   ::super:New( "AREA" )
RETURN Self

METHOD OnPick( aPt, nFlags ) CLASS TCmdArea
   LOCAL o
   IF aPt == NIL
      IF Len( ::aPts ) >= 3
         OHB_CmdPrompt( "Área = " + LTrim( Str( Abs( OC_PolyArea( ::aPts ) ), ;
            0, 4 ) ) + "  Perímetro = " + ;
            LTrim( Str( OC_PolyLen( ::aPts, .T. ), 0, 4 ) ) )
         RETURN ::Finish()
      ENDIF
      RETURN ::Cancel()
   ENDIF
   // si designa entidad cerrada, mide directamente
   o := ::oView:PickEnt( aPt )
   IF o != NIL .AND. ( o:nType == OHB_ENT_CIRCLE .OR. ;
        o:nType == OHB_ENT_LWPOLYLINE )
      IF o:nType == OHB_ENT_CIRCLE
         OHB_CmdPrompt( "Área = " + LTrim( Str( 4 * ATan( 1 ) * o:nRad ^ 2, ;
            0, 4 ) ) )
      ELSE
         OHB_CmdPrompt( "Área = " + LTrim( Str( Abs( OC_PolyArea( o:aVerts ) ), ;
            0, 4 ) ) )
      ENDIF
      RETURN ::Finish()
   ENDIF
   AAdd( ::aPts, aPt )
   OHB_CmdPrompt( "Punto " + LTrim( Str( Len( ::aPts ) + 1, 0 ) ) + ;
      " (Intro cierra):" )
RETURN OHB_CMD_NEED_POINT

METHOD OnHover( aPtW, oView ) CLASS TCmdArea
   ::aHover := AClone( aPtW )
   oView:Refresh()
RETURN NIL

METHOD Preview( hDC, oView ) CLASS TCmdArea
   LOCAL i
   FOR i := 2 TO Len( ::aPts )
      MoveTo( hDC, oView:W2SX( ::aPts[ i - 1 ][ 1 ] ), ;
                   oView:W2SY( ::aPts[ i - 1 ][ 2 ] ) )
      LineTo( hDC, oView:W2SX( ::aPts[ i ][ 1 ] ), ;
                   oView:W2SY( ::aPts[ i ][ 2 ] ) )
   NEXT
RETURN NIL

//=========================== ID =========================================================
CLASS TCmdId FROM TCmdBase
   METHOD New() CONSTRUCTOR
   METHOD OnPick( aPt, nFlags )
ENDCLASS

METHOD New() CLASS TCmdId
   ::super:New( "ID" )
RETURN Self

METHOD OnPick( aPt, nFlags ) CLASS TCmdId
   IF aPt == NIL
      RETURN ::Cancel()
   ENDIF
   OHB_CmdPrompt( "X = " + LTrim( Str( aPt[ 1 ], 0, 4 ) ) + "  Y = " + ;
      LTrim( Str( aPt[ 2 ], 0, 4 ) ) )
RETURN ::Finish()

//=========================== ZOOM ========================================================
CLASS TCmdZoom FROM TCmdBase
   DATA oMain INIT NIL
   METHOD New() CONSTRUCTOR
   METHOD Start( oView )
   METHOD OnPick( aPt, nFlags )
ENDCLASS

METHOD New() CLASS TCmdZoom
   ::super:New( "ZOOM" )
RETURN Self

METHOD Start( oView ) CLASS TCmdZoom
   LOCAL cOp
   ::oView := oView
   ::oDoc := oView:oDoc
   cOp := Upper( OC_AskText( "Zoom: E(xtensión) V(entana) +/-/factor", "E" ) )
   DO CASE
   CASE cOp == "E" .OR. Empty( cOp )
      oView:ZoomExt()
   CASE cOp == "+" .OR. cOp == "++"
      oView:Zoom( 2.0, NIL )
   CASE cOp == "-" .OR. cOp == "_"
      oView:Zoom( 0.5, NIL )
   CASE Val( cOp ) > 0
      oView:Zoom( Val( cOp ), NIL )
   OTHERWISE
      // ventana: dos puntos
      ::super:Start( oView )
      OHB_CmdPrompt( "Precise primera esquina:" )
      RETURN Self
   ENDCASE
RETURN ::Finish()

METHOD OnPick( aPt, nFlags ) CLASS TCmdZoom
   LOCAL aE, w, aC := ::oView:ClientCen()
   IF aPt == NIL
      RETURN ::Cancel()
   ENDIF
   AAdd( ::aPts, aPt )
   IF Len( ::aPts ) == 2
      aE := { Min( ::aPts[ 1 ][ 1 ], ::aPts[ 2 ][ 1 ] ), ;
              Min( ::aPts[ 1 ][ 2 ], ::aPts[ 2 ][ 2 ] ), ;
              Max( ::aPts[ 1 ][ 1 ], ::aPts[ 2 ][ 1 ] ), ;
              Max( ::aPts[ 1 ][ 2 ], ::aPts[ 2 ][ 2 ] ) }
      w := Max( aE[ 3 ] - aE[ 1 ], 0.001 )
      ::oView:nScale := ( aC[ 1 ] * 2 * 0.9 ) / w
      ::oView:aCenW := { ( aE[ 1 ] + aE[ 3 ] ) / 2, ( aE[ 2 ] + aE[ 4 ] ) / 2 }
      ::oView:Refresh()
      RETURN ::Finish()
   ENDIF
   OHB_CmdPrompt( "Precise esquina opuesta:" )
RETURN OHB_CMD_NEED_POINT

//=========================== ENCUADRE =======================================================
CLASS TCmdPan FROM TCmdBase
   METHOD New() CONSTRUCTOR
   METHOD OnPick( aPt, nFlags )
ENDCLASS

METHOD New() CLASS TCmdPan
   ::super:New( "ENCUADRE" )
RETURN Self

METHOD OnPick( aPt, nFlags ) CLASS TCmdPan
   IF aPt == NIL
      RETURN ::Cancel()
   ENDIF
   AAdd( ::aPts, aPt )
   IF Len( ::aPts ) == 1
      OHB_CmdPrompt( "Precise punto destino:" )
      RETURN OHB_CMD_NEED_POINT
   ENDIF
   ::oView:aCenW[ 1 ] -= ( ::aPts[ 2 ][ 1 ] - ::aPts[ 1 ][ 1 ] )
   ::oView:aCenW[ 2 ] -= ( ::aPts[ 2 ][ 2 ] - ::aPts[ 1 ][ 2 ] )
   ::oView:Refresh()
RETURN ::Finish()

//=========================== CAPA ============================================================
CLASS TCmdLayer FROM TCmdBase
   DATA oMain INIT NIL
   METHOD New() CONSTRUCTOR
   METHOD Start( oView )
   METHOD OnPick( aPt, nFlags )
ENDCLASS

METHOD New() CLASS TCmdLayer
   ::super:New( "CAPA" )
RETURN Self

METHOD Start( oView ) CLASS TCmdLayer
   ::oView := oView
   ::oDoc := oView:oDoc
   OHB_LayerDlg( oView, ::oDoc )
RETURN ::Finish()

METHOD OnPick( aPt, nFlags ) CLASS TCmdLayer
RETURN ::Finish()

//=========================== ABRE / GUARDA / NUEVO =============================================
CLASS TCmdOpen FROM TCmdBase
   DATA oMain INIT NIL
   METHOD New() CONSTRUCTOR
   METHOD Start( oView )
   METHOD OnPick( aPt, nFlags )
ENDCLASS

METHOD New() CLASS TCmdOpen
   ::super:New( "ABRE" )
RETURN Self

METHOD Start( oView ) CLASS TCmdOpen
   LOCAL cFile, oDoc
   ::oView := oView
   cFile := cGetFile( "Dibujo DXF (*.dxf)|*.dxf|", "Abrir dibujo" )
   IF ! Empty( cFile )
      CursorWait()
      oDoc := OC_DxfLoad( cFile )
      CursorArrow()
      IF oDoc == NIL
         MsgStop( "No se pudo leer: " + cFile )
      ELSE
         oView:oDoc := oDoc
         oView:ZoomExt()
         OHB_CmdPrompt( "Abierto: " + cFile + " (" + ;
            LTrim( Str( oDoc:Count(), 0 ) ) + " entidades)" )
         OHB_PropRefresh()
      ENDIF
   ENDIF
RETURN ::Finish()

METHOD OnPick( aPt, nFlags ) CLASS TCmdOpen
RETURN ::Finish()

CLASS TCmdSave FROM TCmdBase
   DATA oMain INIT NIL
   METHOD New() CONSTRUCTOR
   METHOD Start( oView )
   METHOD OnPick( aPt, nFlags )
ENDCLASS

METHOD New() CLASS TCmdSave
   ::super:New( "GUARDA" )
RETURN Self

METHOD Start( oView ) CLASS TCmdSave
   LOCAL cFile := oView:oDoc:cFile
   ::oView := oView
   ::oDoc := oView:oDoc
   IF Empty( cFile )
      cFile := cGetFile( "Dibujo DXF (*.dxf)|*.dxf|", "Guardar dibujo", , .T. )
      IF Empty( cFile )
         RETURN ::Finish()
      ENDIF
      IF Upper( Right( cFile, 4 ) ) != ".DXF"
         cFile += ".dxf"
      ENDIF
   ENDIF
   CursorWait()
   IF OC_DxfSave( ::oDoc, cFile )
      OHB_CmdPrompt( "Guardado: " + cFile )
   ELSE
      MsgStop( "No se pudo guardar: " + cFile )
   ENDIF
   CursorArrow()
RETURN ::Finish()

METHOD OnPick( aPt, nFlags ) CLASS TCmdSave
RETURN ::Finish()

CLASS TCmdNew FROM TCmdSave
   METHOD New() CONSTRUCTOR
   METHOD Start( oView )
ENDCLASS

METHOD New() CLASS TCmdNew
   ::super:New( "GUARDA" )
   ::cName := "NUEVO"
RETURN Self

METHOD Start( oView ) CLASS TCmdNew
   IF oView:oDoc:lDirty
      IF ! MsgYesNo( "El dibujo tiene cambios. ¿Descartar?", "Nuevo" )
         RETURN ::Finish()
      ENDIF
   ENDIF
   oView:oDoc := TDocDrawing():New()
   oView:ZoomExt()
   OHB_CmdPrompt( "Dibujo nuevo." )
   OHB_PropRefresh()
RETURN ::Finish()

//=========================== DESHACER =============================================================
CLASS TCmdUndo FROM TCmdBase
   METHOD New() CONSTRUCTOR
   METHOD Start( oView )
   METHOD OnPick( aPt, nFlags )
ENDCLASS

METHOD New() CLASS TCmdUndo
   ::super:New( "DESHACER" )
RETURN Self

METHOD Start( oView ) CLASS TCmdUndo
   ::oView := oView
   ::oDoc := oView:oDoc
   IF ::oDoc:Undo()
      oView:Refresh()
      OHB_CmdPrompt( "Deshecho." )
      OHB_PropRefresh()
   ELSE
      OHB_CmdPrompt( "Nada que deshacer." )
   ENDIF
RETURN ::Finish()

METHOD OnPick( aPt, nFlags ) CLASS TCmdUndo
RETURN ::Finish()
