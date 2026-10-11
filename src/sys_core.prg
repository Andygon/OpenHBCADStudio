/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/sys_core.prg
   Rust origen: src/main.rs + src/lib.rs + src/sys.rs + src/sysinfo.rs +
                src/config.rs + src/app/startup.rs + src/app/config.rs
   Sistema: versión, rutas, info de plataforma, registro de log.
----------------------------------------------------------------------------*/
#include "ohbcad.ch"

STATIC s_cAppData := NIL
STATIC s_cLogFile := NIL

//--- Versión ---------------------------------------------------------------
FUNCTION OHB_Version()
RETURN OHB_VERSION_STR

FUNCTION OHB_VersionNum()
RETURN { OHB_VERSION_MAJOR, OHB_VERSION_MINOR, OHB_VERSION_PATCH }

//--- Info de sistema (Rust: sysinfo.rs) ------------------------------------
FUNCTION OHB_SysInfo()
   LOCAL aInfo := {}
   AAdd( aInfo, { "app",     "OpenHBCADStudio" } )
   AAdd( aInfo, { "version", OHB_Version() } )
   AAdd( aInfo, { "lang",    "Harbour " + Version() } )
   AAdd( aInfo, { "gui",     "FiveWin64" } )
   AAdd( aInfo, { "cc",      "MSVC22 x64" } )
   AAdd( aInfo, { "os",      OS() } )
   AAdd( aInfo, { "arch",    "x86_64" } )
RETURN aInfo

//--- Rutas (Rust: sys.rs / config.rs) --------------------------------------
FUNCTION OHB_AppDataDir()
   IF s_cAppData == NIL
      s_cAppData := GetEnv( "APPDATA" ) + "\OpenHBCADStudio"
      IF ! lIsDir( s_cAppData )
         MakeDir( s_cAppData )
      ENDIF
   ENDIF
RETURN s_cAppData

FUNCTION OHB_LogFile()
   IF s_cLogFile == NIL
      s_cLogFile := OHB_AppDataDir() + "\ohbcad.log"
   ENDIF
RETURN s_cLogFile

//--- Log (Rust: env_logger / log) ------------------------------------------
PROCEDURE OHB_Log( cMsg, cLevel )
   LOCAL h
   hb_default( @cLevel, "INFO" )
   h := FOpen( OHB_LogFile(), FO_WRITE )
   IF h != -1
      FSeek( h, 0, FS_END )
      FWrite( h, DToC( Date() ) + " " + Time() + " [" + cLevel + "] " + ;
         hb_ValToStr( cMsg ) + hb_eol() )
      FClose( h )
   ENDIF
RETURN

//--- Arranque (Rust: app/startup.rs) ----------------------------------------
PROCEDURE OHB_Startup()
   OHB_Log( "OpenHBCADStudio " + OHB_Version() + " inicio. " + OS() )
RETURN
