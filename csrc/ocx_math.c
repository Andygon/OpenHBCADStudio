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
