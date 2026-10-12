/* OpenHBCADStudio - csrc/ocx_math.c
   Primitivas f64 de Rust sin equivalente exacto en Harbour. UTF-8. */
#include "hbapi.h"
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
