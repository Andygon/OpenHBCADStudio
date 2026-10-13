/*----------------------------------------------------------------------------
   OpenHBCADStudio - ohbcad.prg
   Rust origen: src/main.rs + src/cli.rs
   Punto de entrada GUI (FiveWin64).
   Uso: OpenHBCADStudio.exe [dibujo.dxf]        visor (Fase 2, hito 1)
        OpenHBCADStudio.exe /legacy [dibujo.dxf] esqueleto MDI de la primera version
----------------------------------------------------------------------------*/
#include "ohbcad.ch"
#include "FiveWin.ch"

FUNCTION Main()
   LOCAL cFile := "", i, cArg, lLegacy := .F.
   FOR i := 1 TO hb_argc()
      cArg := hb_argv( i )
      IF Lower( cArg ) == "/legacy" .OR. Lower( cArg ) == "-legacy"
         lLegacy := .T.
      ELSEIF ! ( Left( cArg, 1 ) == "/" ) .AND. ! ( Left( cArg, 1 ) == "-" )
         cFile := cArg
      ENDIF
   NEXT
   IF lLegacy
      OHB_Startup()
      TMainWin():New( cFile ):Activate()
   ELSE
      TViewer():New( cFile ):Activate()
   ENDIF
RETURN NIL
