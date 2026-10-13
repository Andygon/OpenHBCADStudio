/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/ui/vw_iconfile.prg
   Saca al disco (carpeta temporal) el icono BMP pedido por el ribbon.
   Vwi_File( cNombre ) -> ruta del .bmp ("" si no existe ese icono).
----------------------------------------------------------------------------*/
#include "FiveWin.ch"

STATIC s_hAll := NIL

STATIC FUNCTION Vwi_All()
   IF s_hAll == NIL
      s_hAll := { => }
      hb_HMerge( s_hAll, Vwi_D1() )
      hb_HMerge( s_hAll, Vwi_D2() )
      hb_HMerge( s_hAll, Vwi_D3() )
      hb_HMerge( s_hAll, Vwi_D4() )
   ENDIF
RETURN s_hAll

FUNCTION Vwi_File( cName )
   LOCAL h := Vwi_All(), cDir := hb_DirTemp() + "ohbcad_ico", cPath
   IF Empty( cName ) .OR. ! hb_HHasKey( h, cName )
      RETURN ""
   ENDIF
   IF ! hb_DirExists( cDir )
      hb_DirCreate( cDir )
   ENDIF
   cPath := cDir + hb_ps() + cName + ".bmp"
   IF ! hb_FileExists( cPath )
      hb_MemoWrit( cPath, hb_base64Decode( h[ cName ] ) )
   ENDIF
RETURN cPath
