/*----------------------------------------------------------------------------
   OpenHBCADStudio - ohbcad.prg
   Rust origen: src/main.rs + src/cli.rs
   Punto de entrada GUI (FiveWin64). Uso: OpenHBCADStudio.exe [dibujo.dxf]
----------------------------------------------------------------------------*/
#include "ohbcad.ch"
#include "FiveWin.ch"

FUNCTION Main()
   LOCAL cFile := "", i, cArg
   FOR i := 1 TO hb_argc()
      cArg := hb_argv( i )
      IF Left( cArg, 1 ) != "/" .AND. Left( cArg, 1 ) != "-"
         cFile := cArg
      ENDIF
   NEXT
   OHB_Startup()
   TMainWin():New( cFile ):Activate()
RETURN NIL
