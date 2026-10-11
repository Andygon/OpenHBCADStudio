/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/ui/cmdline.prg
   Rust origen: src/ui/command_line.rs + src/ui/modal.rs +
                src/ui/window/layers.rs (di??logo) +
                src/ui/properties.rs (panel: aqu?? 8 l??neas SAY) +
                src/app/find_replace.rs (di??logo buscar: fase 2)
   L??nea de comandos FiveWin + di??logos de petici??n + gestor de capas.
----------------------------------------------------------------------------*/
#include "ohbcad.ch"
#include "FiveWin.ch"

STATIC s_oPrompt := NIL   // SAY del prompt
STATIC s_oInput := NIL    // GET de entrada
STATIC s_cInput := ""
STATIC s_aHist := {}
STATIC s_oView := NIL     // canvas activo (TCadCanvas)
STATIC s_oMain := NIL     // ventana principal (TMainWin)
STATIC s_aProp := {}      // 8 SAYs del panel de propiedades
STATIC s_oCoord := NIL    // SAY de coordenadas

//--- Barra de comandos -----------------------------------------------------------
FUNCTION OHB_CmdBarCreate( oParent, oView, oMain )
   s_oView := oView
   s_oMain := oMain
   @ 0, 0 SAY s_oPrompt PROMPT "Comando:" SIZE 100, 20 OF oParent PIXEL
   @ 0, 0 GET s_oInput VAR s_cInput SIZE 100, 22 OF oParent PIXEL
   s_oInput:bKeyDown := { | nK, nF | OHB_CmdKey( nK, nF ) }
RETURN NIL

FUNCTION OHB_CmdBarLayout( nTop, nLeft, nW )
   s_oPrompt:Move( nTop + 4, nLeft + 4, nW - 220, 20, .T. )
   s_oInput:Move( nTop + 2, nLeft + nW - 210, 200, 24, .T. )
RETURN NIL

FUNCTION OHB_CmdKey( nKey, nFlags )
   hb_default( @nFlags, 0 )
   IF nKey == 13  // Enter
      OHB_ExecTyped( AllTrim( s_cInput ) )
      s_cInput := ""
      s_oInput:Refresh()
      s_oView:SetFocus()
   ELSEIF nKey == 27
      IF s_oView:oCmd != NIL
         s_oView:oCmd:Cancel()
      ENDIF
      s_cInput := ""
      s_oInput:Refresh()
   ENDIF
RETURN NIL

FUNCTION OHB_SetView( oView )
   s_oView := oView
RETURN NIL

FUNCTION OHB_ExecTyped( cText )
   LOCAL aR, oCmd
   IF Empty( cText )
      IF s_oView != NIL .AND. s_oView:oCmd != NIL
         s_oView:oCmd:OnPick( NIL, 0 )
      ENDIF
      RETURN NIL
   ENDIF
   AAdd( s_aHist, cText )
   IF s_oView != NIL .AND. s_oView:oCmd != NIL .AND. ;
         __objHasMethod( s_oView:oCmd, "ONNUM" ) .AND. IsNumericCmd( cText )
      s_oView:oCmd:OnNum( Val( cText ) )
      RETURN NIL
   ENDIF
   aR := OHB_CmdFind( cText )
   IF aR == NIL
      OHB_CmdPrompt( "Comando desconocido: " + cText )
      RETURN NIL
   ENDIF
   oCmd := OHB_RunCmd( cText, s_oView, s_oMain )
RETURN oCmd

STATIC FUNCTION IsNumericCmd( cT )
   LOCAL i, c
   FOR i := 1 TO Len( cT )
      c := SubStr( cT, i, 1 )
      IF !( c $ "0123456789.,+-" )
         RETURN .F.
      ENDIF
   NEXT
RETURN .T.

FUNCTION OHB_CmdPrompt( cText )
   IF s_oPrompt != NIL
      s_oPrompt:SetText( Left( cText, 220 ) )
   ENDIF
RETURN NIL

//--- Petici??n de n??mero (Rust: modal.rs) -----------------------------------------
FUNCTION OC_AskNum( cPrompt, nDef )
   LOCAL oDlg, oGet, nVal := nDef, lOk := .F.
   DEFINE DIALOG oDlg TITLE cPrompt FROM 0, 0 TO 120, 300 PIXEL
   @ 12, 12 SAY "Valor:" SIZE 50, 14 OF oDlg PIXEL
   @ 10, 70 GET oGet VAR nVal SIZE 120, 16 OF oDlg PIXEL PICTURE "99999999.99"
   @ 44, 70 BUTTON "Aceptar" SIZE 60, 16 OF oDlg PIXEL ;
      ACTION ( lOk := .T., oDlg:End() )
   @ 44, 140 BUTTON "Cancelar" SIZE 60, 16 OF oDlg PIXEL ;
      ACTION oDlg:End()
   ACTIVATE DIALOG oDlg CENTERED
   IF ! lOk
      RETURN NIL
   ENDIF
RETURN nVal

//--- Petici??n de texto --------------------------------------------------------------
FUNCTION OC_AskText( cPrompt, cDef )
   LOCAL oDlg, oGet, cVal := cDef, lOk := .F.
   DEFINE DIALOG oDlg TITLE cPrompt FROM 0, 0 TO 120, 340 PIXEL
   @ 12, 12 SAY "Texto:" SIZE 50, 14 OF oDlg PIXEL
   @ 10, 70 GET oGet VAR cVal SIZE 170, 16 OF oDlg PIXEL
   @ 44, 110 BUTTON "Aceptar" SIZE 60, 16 OF oDlg PIXEL ;
      ACTION ( lOk := .T., oDlg:End() )
   @ 44, 180 BUTTON "Cancelar" SIZE 60, 16 OF oDlg PIXEL ;
      ACTION oDlg:End()
   ACTIVATE DIALOG oDlg CENTERED
   IF ! lOk
      RETURN NIL
   ENDIF
RETURN cVal

//--- Gestor de capas (Rust: ui/window/layers.rs + layer_state_manager) ---------------
FUNCTION OHB_LayerDlg( oParent, oDoc )
   LOCAL oDlg, oLbx, aNames := {}, nSel := 1, i, cNew := ""
   FOR i := 1 TO Len( oDoc:aLayers )
      AAdd( aNames, oDoc:aLayers[ i ]:cName )
   NEXT
   DEFINE DIALOG oDlg TITLE "Capas" FROM 0, 0 TO 300, 380 PIXEL
   @ 10, 10 LISTBOX oLbx VAR nSel ITEMS aNames SIZE 200, 180 OF oDlg PIXEL
   @ 200, 10 BUTTON "Actual" SIZE 80, 18 OF oDlg PIXEL ;
      ACTION ( oDoc:cCurLayer := aNames[ nSel ], oDlg:Update(), ;
               OHB_CmdPrompt( "Capa actual: " + aNames[ nSel ] ) )
   @ 200, 100 BUTTON "Nueva..." SIZE 80, 18 OF oDlg PIXEL ;
      ACTION ( cNew := OC_AskText( "Nueva capa", "C1" ), ;
               If( ! Empty( cNew ), ;
                  ( oDoc:AddLayer( cNew, 7 ), AAdd( aNames, Upper( cNew ) ), ;
                    oLbx:Refresh() ), NIL ) )
   @ 260, 10 BUTTON "Cerrar" SIZE 80, 18 OF oDlg PIXEL ACTION oDlg:End()
   ACTIVATE DIALOG oDlg CENTERED
   OHB_PropRefresh()
RETURN NIL

//--- Panel de propiedades: 8 l??neas SAY (Rust: ui/properties.rs) -----------------------
FUNCTION OHB_PropPanelCreate( oParent )
   LOCAL i, oSay
   s_aProp := {}
   FOR i := 1 TO 8
      @ 0, 0 SAY oSay PROMPT "" SIZE 100, 18 OF oParent PIXEL
      AAdd( s_aProp, oSay )
   NEXT
RETURN NIL

FUNCTION OHB_PropPanelLayout( nTop, nLeft, nW )
   LOCAL i
   FOR i := 1 TO Len( s_aProp )
      s_aProp[ i ]:Move( nTop + ( i - 1 ) * 20 + 4, nLeft + 4, nW - 8, 18, .T. )
   NEXT
RETURN NIL

FUNCTION OHB_PropRefresh()
   LOCAL aL := { "", "", "", "", "", "", "", "" }, o, aP, i
   IF s_oView != NIL
      IF ! Empty( s_oView:oDoc:aSel )
         o := s_oView:oDoc:FindEnt( ATail( s_oView:oDoc:aSel ) )
         IF o != NIL
            aL[ 1 ] := o:TypeName() + " [" + o:cHandle + "]"
            aL[ 2 ] := "Capa: " + o:cLayer
            aL[ 3 ] := "Color: " + LTrim( Str( o:nColor, 0 ) )
            aP := o:Props()
            IF aP != NIL
               FOR i := 1 TO Min( Len( aP ), 5 )
                  aL[ 3 + i ] := Left( aP[ i ][ 1 ] + ": " + ;
                     hb_ValToStr( aP[ i ][ 2 ] ), 40 )
               NEXT
            ENDIF
         ENDIF
      ELSE
         aL[ 1 ] := "Entidades: " + LTrim( Str( s_oView:oDoc:Count(), 0 ) )
         aL[ 2 ] := "Capa: " + s_oView:oDoc:cCurLayer
      ENDIF
   ENDIF
   FOR i := 1 TO Min( Len( s_aProp ), 8 )
      s_aProp[ i ]:SetText( aL[ i ] )
   NEXT
RETURN NIL

//--- Coordenadas (Rust: ui/statusbar/mod.rs) --------------------------------------------
FUNCTION OHB_StatusCoordCreate( oParent )
   @ 0, 0 SAY s_oCoord PROMPT "0.00, 0.00" SIZE 150, 18 OF oParent PIXEL
RETURN NIL

FUNCTION OHB_StatusCoordLayout( nTop, nLeft )
   s_oCoord:Move( nTop, nLeft, 150, 18, .T. )
RETURN NIL

FUNCTION OHB_StatusCoords( nX, nY )
   IF s_oCoord != NIL
      s_oCoord:SetText( LTrim( Str( nX, 0, 2 ) ) + ", " + ;
         LTrim( Str( nY, 0, 2 ) ) )
   ENDIF
RETURN NIL
