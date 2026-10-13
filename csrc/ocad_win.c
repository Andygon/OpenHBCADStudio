/*----------------------------------------------------------------------------
   OpenHBCADStudio - csrc/ocad_win.c
   Barra de titulo oscura (modo oscuro inmersivo de Windows 10 1809+/11).
   Harbour: OCX_DARKTITLE( hWnd ) -> .T. si Windows acepto el atributo.
   dwmapi.dll se carga en tiempo de ejecucion: no hace falta enlazarla.
----------------------------------------------------------------------------*/
#include <windows.h>
#include "hbapi.h"

typedef HRESULT ( WINAPI * OCX_DWMSET )( HWND, DWORD, LPCVOID, DWORD );

HB_FUNC( OCX_DARKTITLE )
{
   HWND hWnd = ( HWND ) ( HB_PTRUINT ) hb_parnint( 1 );
   HMODULE hDll = LoadLibraryA( "dwmapi.dll" );
   HB_BOOL bOk = HB_FALSE;
   if( hDll && hWnd )
   {
      OCX_DWMSET pSet = ( OCX_DWMSET ) GetProcAddress( hDll, "DwmSetWindowAttribute" );
      if( pSet )
      {
         BOOL bOn = TRUE;
         if( pSet( hWnd, 20, &bOn, sizeof( bOn ) ) == S_OK ||    /* DWMWA_USE_IMMERSIVE_DARK_MODE */
             pSet( hWnd, 19, &bOn, sizeof( bOn ) ) == S_OK )     /* valor antiguo (1809 a 1909) */
            bOk = HB_TRUE;
      }
   }
   if( hDll )
      FreeLibrary( hDll );
   hb_retl( bOk );
}
