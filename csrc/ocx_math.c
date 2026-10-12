/* OpenHBCADStudio - csrc/ocx_math.c
   Primitivas f64 de Rust sin equivalente exacto en Harbour. UTF-8. */
#include "hbapi.h"
#include "hbapiitm.h"
#include <math.h>
/* f64 % (fmod: el signo sigue al dividendo, NO como MOD de Clipper) */
HB_FUNC( OCX_FMOD )   { hb_retnd( fmod( hb_parnd(1), hb_parnd(2) ) ); }
HB_FUNC( OCX_ATAN2 )  { hb_retnd( atan2( hb_parnd(1), hb_parnd(2) ) ); }   /* y.atan2(x) */
HB_FUNC( OCX_HYPOT )  { hb_retnd( hypot( hb_parnd(1), hb_parnd(2) ) ); }
HB_FUNC( OCX_ISFINITE ) { hb_retl( isfinite( hb_parnd(1) ) ? HB_TRUE : HB_FALSE ); }
/* f64::rem_euclid */
HB_FUNC( OCX_REMEUCLID )
{
   double a = hb_parnd(1), b = hb_parnd(2), r = fmod( a, b );
   if( r < 0.0 ) r += fabs( b );
   hb_retnd( r );
}
/* spacing: f64::from_bits(x.to_bits()+1) - x  (x > 0) */
HB_FUNC( OCX_SPACING ) { double x = hb_parnd(1); hb_retnd( nextafter( x, INFINITY ) - x ); }
/* Harbour core no trae trigonometria: f64::sin/cos/tan/asin/acos/atan, powf */
HB_FUNC( OCX_SIN )  { hb_retnd( sin( hb_parnd(1) ) ); }
HB_FUNC( OCX_COS )  { hb_retnd( cos( hb_parnd(1) ) ); }
HB_FUNC( OCX_TAN )  { hb_retnd( tan( hb_parnd(1) ) ); }
HB_FUNC( OCX_ASIN ) { hb_retnd( asin( hb_parnd(1) ) ); }
HB_FUNC( OCX_ACOS ) { hb_retnd( acos( hb_parnd(1) ) ); }
HB_FUNC( OCX_ATAN ) { hb_retnd( atan( hb_parnd(1) ) ); }
HB_FUNC( OCX_POW )  { hb_retnd( pow( hb_parnd(1), hb_parnd(2) ) ); }
HB_FUNC( OCX_FLOOR )  { hb_retnd( floor( hb_parnd(1) ) ); }
HB_FUNC( OCX_CEIL )   { hb_retnd( ceil( hb_parnd(1) ) ); }
HB_FUNC( OCX_SIGNUM ) { double x = hb_parnd(1); hb_retnd( isnan( x ) ? x : copysign( 1.0, x ) ); }  /* f64::signum */
HB_FUNC( OCX_ISNAN )  { hb_retl( isnan( hb_parnd(1) ) ? HB_TRUE : HB_FALSE ); }
#include <float.h>
HB_FUNC( OCX_MINPOS ) { hb_retnd( DBL_MIN ); }
HB_FUNC( OCX_EPSILON ) { hb_retnd( DBL_EPSILON ); }
HB_FUNC( OCX_NAN ) { hb_retnd( NAN ); }
HB_FUNC( OCX_INF ) { hb_retnd( INFINITY ); }

/* --- Fase DXF: bytes LE -> f64, y digitos decimales mas cortos que van y vuelven (equivale a ryu) --- */
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
HB_FUNC( OCX_BIN2D )   /* 8 bytes little-endian -> f64 */
{
   double d = 0.0;
   if( hb_parclen( 1 ) >= 8 ) { memcpy( &d, hb_parc( 1 ), 8 ); }
   hb_retnd( d );
}
HB_FUNC( OCX_D2BIN )   /* f64 -> 8 bytes little-endian */
{
   double d = hb_parnd( 1 );
   hb_retclen( ( const char * ) &d, 8 );
}
/* { cDigits, nK }: valor = digits * 10^k, digitos mas cortos que hacen round-trip. Solo finitos y != 0. */
HB_FUNC( OCX_F64DIGITS )
{
   double d = fabs( hb_parnd( 1 ) );
   char buf[ 64 ], dig[ 32 ];
   int p, e = 0, n = 0, i;
   for( p = 1; p <= 17; p++ )
   {
      snprintf( buf, sizeof( buf ), "%.*e", p - 1, d );
      if( strtod( buf, NULL ) == d ) break;
   }
   if( p > 17 ) p = 17;
   for( i = 0; buf[ i ] && buf[ i ] != 'e'; i++ ) if( buf[ i ] >= '0' && buf[ i ] <= '9' ) dig[ n++ ] = buf[ i ];
   dig[ n ] = 0;
   if( buf[ i ] == 'e' ) e = atoi( buf + i + 1 );
   e -= ( p - 1 ); while( n > 1 && dig[ n - 1 ] == '0' ) { dig[ --n ] = 0; e++; }
   {
      PHB_ITEM pArr = hb_itemArrayNew( 2 );
      hb_arraySetC( pArr, 1, dig );
      hb_arraySetNI( pArr, 2, e );
      hb_itemReturnRelease( pArr );
   }
}
HB_FUNC( OCX_COPYSIGN1 ) { hb_retnd( copysign( 1.0, hb_parnd( 1 ) ) ); }
/* Rust format!("{:.16e}", v): mantisa con 16 decimales y exponente sin signo + ni ceros a la izquierda */
HB_FUNC( OCX_EXP16 )
{
   char buf[ 64 ], out[ 64 ];
   char * pe;
   int e;
   snprintf( buf, sizeof( buf ), "%.16e", hb_parnd( 1 ) );
   pe = strchr( buf, 'e' );
   if( pe ) { e = atoi( pe + 1 ); *pe = 0; snprintf( out, sizeof( out ), "%.40se%d", buf, e ); }
   else snprintf( out, sizeof( out ), "%s", buf );
   hb_retc( out );
}
HB_FUNC( OCX_I64BIN )   /* i64 -> 8 bytes little-endian */
{
   long long v = ( long long ) hb_parnint( 1 );
   hb_retclen( ( const char * ) &v, 8 );
}
HB_FUNC( OCX_BIN2I64 )   /* 8 bytes little-endian -> i64 (u64 > i64::MAX se devuelve como double, ver obj_semantic.prg) */
{
   long long v = 0;
   if( hb_parclen( 1 ) >= 8 ) { memcpy( &v, hb_parc( 1 ), 8 ); }
   hb_retnint( v );
}
HB_FUNC( OCX_BIN2U64 )   /* 8 bytes little-endian -> u64 */
{
   unsigned long long v = 0;
   if( hb_parclen( 1 ) >= 8 ) { memcpy( &v, hb_parc( 1 ), 8 ); }
   if( v <= 9223372036854775807ULL ) hb_retnint( ( HB_MAXINT ) v ); else hb_retnd( ( double ) v );
}
