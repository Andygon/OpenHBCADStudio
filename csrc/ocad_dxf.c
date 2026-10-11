/*----------------------------------------------------------------------------
   OpenHBCADStudio - csrc/ocad_dxf.c
   Esc??ner r??pido de DXF ASCII (grupos c??digo/valor) en C (MSVC22 x64).
   Port del papel de opencadcodec (Rust) en lectura: aqu?? DXF R12/R2000 ASCII.
   El DWG binario propietario se documenta en docs/PORTING.md (v??a ODA/Teigha
   o conversi??n previa a DXF); este lector cubre el intercambio nativo.
   Harbour: aPairs := OC_DXFSCAN( cFile ) -> array de { nCode, cValue }.
----------------------------------------------------------------------------*/
#define _CRT_SECURE_NO_WARNINGS
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "hbapi.h"
#include "hbapiitm.h"

/* normaliza fin de l??nea y recorta \r \n finales */
static void s_chomp( char * s )
{
   size_t n = strlen( s );
   while( n > 0 && ( s[ n - 1 ] == '\r' || s[ n - 1 ] == '\n' ) )
      s[ --n ] = '\0';
   /* recorta espacios finales en l??neas de c??digo */
   while( n > 0 && ( s[ n - 1 ] == ' ' || s[ n - 1 ] == '\t' ) )
      s[ --n ] = '\0';
}

HB_FUNC( OCX_DXFSCAN )
{
   const char * fname = hb_parc( 1 );
   FILE * fh;
   char lineCode[ 1024 ];
   char lineVal[ 4096 ];
   PHB_ITEM pArr;
   HB_SIZE cap = 4096, len = 0;

   if( fname == NULL )
   {
      hb_ret();
      return;
   }
   fh = fopen( fname, "r" );
   if( fh == NULL )
   {
      hb_ret();
      return;
   }
   pArr = hb_itemArrayNew( cap );
   while( fgets( lineCode, sizeof( lineCode ), fh ) != NULL )
   {
      int code;
      PHB_ITEM pPair;
      s_chomp( lineCode );
      if( fgets( lineVal, sizeof( lineVal ), fh ) == NULL )
         break;
      s_chomp( lineVal );
      code = atoi( lineCode );
      if( len + 1 >= cap )
      {
         cap *= 2;
         hb_arraySize( pArr, cap );
      }
      ++len;
      pPair = hb_itemArrayNew( 2 );
      hb_arraySetNI( pPair, 1, code );
      hb_arraySetC( pPair, 2, lineVal );
      hb_arraySet( pArr, len, pPair );
      hb_itemRelease( pPair );
   }
   fclose( fh );
   hb_arraySize( pArr, len );
   hb_itemReturnRelease( pArr );
}

/* OC_DXFCOUNT( cFile ) -> n : n?? de pares grupo/valor (chequeo r??pido) */
HB_FUNC( OCX_DXFCOUNT )
{
   const char * fname = hb_parc( 1 );
   FILE * fh;
   char buf[ 4096 ];
   long nLines = 0;
   if( fname == NULL )
   {
      hb_retni( -1 );
      return;
   }
   fh = fopen( fname, "r" );
   if( fh == NULL )
   {
      hb_retni( -1 );
      return;
   }
   while( fgets( buf, sizeof( buf ), fh ) != NULL )
      nLines++;
   fclose( fh );
   hb_retnl( nLines / 2 );
}
