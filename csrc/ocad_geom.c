/*----------------------------------------------------------------------------
   OpenHBCADStudio - csrc/ocad_geom.c
   N??cleo geom??trico acelerado en C (MSVC22 x64).
   Port de la matem??tica usada en Rust por:
     src/scene/convert/tess*.rs, src/scene/pick/hit_test.rs,
     src/scene/parametric_solve.rs, src/modules/draw/modify/*.rs
     (offset.rs, fillet.rs, trim.rs, array.rs, ...),
     crates opencadkernel (glam::DVec3).
   Se expone a Harbour v??a hbapi.h (HB_FUNC OC_*).
   Compilar: cl -TC -W3 -O2 -I%HBDIR%\include -D_WIN64
----------------------------------------------------------------------------*/
#include <math.h>
#include "hbapi.h"
#include "hbapiitm.h"

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

/* --- utilidades internas --- */
static double s_norm2( double x, double y ) { return sqrt( x * x + y * y ); }

/* OC_VECLEN( x, y ) -> cDouble : m??dulo del vector 2D */
HB_FUNC( OCX_VECLEN )
{
   double x = hb_parnd( 1 );
   double y = hb_parnd( 2 );
   hb_retnd( s_norm2( x, y ) );
}

/* OC_DIST( x1, y1, x2, y2 ) -> cDouble */
HB_FUNC( OCX_DIST )
{
   double dx = hb_parnd( 3 ) - hb_parnd( 1 );
   double dy = hb_parnd( 4 ) - hb_parnd( 2 );
   hb_retnd( s_norm2( dx, dy ) );
}

/* OC_ANGLE( x1, y1, x2, y2 ) -> cDouble : ??ngulo en radianes [0, 2pi) */
HB_FUNC( OCX_ANGLE )
{
   double a = atan2( hb_parnd( 4 ) - hb_parnd( 2 ),
                     hb_parnd( 3 ) - hb_parnd( 1 ) );
   if( a < 0.0 )
      a += 2.0 * M_PI;
   hb_retnd( a );
}

/* OC_POLAR( x, y, ang, dist ) -> aArray { x, y } */
HB_FUNC( OCX_POLAR )
{
   double x = hb_parnd( 1 );
   double y = hb_parnd( 2 );
   double a = hb_parnd( 3 );
   double d = hb_parnd( 4 );
   PHB_ITEM pArr = hb_itemArrayNew( 2 );
   hb_itemPutND( hb_arrayGetItemPtr( pArr, 1 ), x + d * cos( a ) );
   hb_itemPutND( hb_arrayGetItemPtr( pArr, 2 ), y + d * sin( a ) );
   hb_itemReturnRelease( pArr );
}

/* OC_INTERS( x1,y1,x2,y2, x3,y3,x4,y4, [lSeg] ) -> aArray {x,y,t,u} o NIL
   Intersecci??n de dos rectas (segmentos si lSeg=.T.). */
HB_FUNC( OCX_INTERS )
{
   double x1 = hb_parnd( 1 ), y1 = hb_parnd( 2 );
   double x2 = hb_parnd( 3 ), y2 = hb_parnd( 4 );
   double x3 = hb_parnd( 5 ), y3 = hb_parnd( 6 );
   double x4 = hb_parnd( 7 ), y4 = hb_parnd( 8 );
   int    bSeg = hb_parl( 9 );
   double dx1 = x2 - x1, dy1 = y2 - y1;
   double dx2 = x4 - x3, dy2 = y4 - y3;
   double den = dx1 * dy2 - dy1 * dx2;
   double t, u, ix, iy;
   PHB_ITEM pArr;

   if( fabs( den ) < 1e-12 )
   {
      hb_ret();  /* paralelas: NIL */
      return;
   }
   t = ( ( x3 - x1 ) * dy2 - ( y3 - y1 ) * dx2 ) / den;
   u = ( ( x3 - x1 ) * dy1 - ( y3 - y1 ) * dx1 ) / den;
   if( bSeg && ( t < 0.0 || t > 1.0 || u < 0.0 || u > 1.0 ) )
   {
      hb_ret();
      return;
   }
   ix = x1 + t * dx1;
   iy = y1 + t * dy1;
   pArr = hb_itemArrayNew( 4 );
   hb_itemPutND( hb_arrayGetItemPtr( pArr, 1 ), ix );
   hb_itemPutND( hb_arrayGetItemPtr( pArr, 2 ), iy );
   hb_itemPutND( hb_arrayGetItemPtr( pArr, 3 ), t );
   hb_itemPutND( hb_arrayGetItemPtr( pArr, 4 ), u );
   hb_itemReturnRelease( pArr );
}

/* OC_PTSEG( px,py, x1,y1,x2,y2 ) -> aArray { dist, qx, qy, t } */
HB_FUNC( OCX_PTSEG )
{
   double px = hb_parnd( 1 ), py = hb_parnd( 2 );
   double x1 = hb_parnd( 3 ), y1 = hb_parnd( 4 );
   double x2 = hb_parnd( 5 ), y2 = hb_parnd( 6 );
   double dx = x2 - x1, dy = y2 - y1;
   double L2 = dx * dx + dy * dy;
   double t = 0.0, qx, qy;
   PHB_ITEM pArr;

   if( L2 > 1e-18 )
   {
      t = ( ( px - x1 ) * dx + ( py - y1 ) * dy ) / L2;
      if( t < 0.0 ) t = 0.0;
      if( t > 1.0 ) t = 1.0;
   }
   qx = x1 + t * dx;
   qy = y1 + t * dy;
   pArr = hb_itemArrayNew( 4 );
   hb_itemPutND( hb_arrayGetItemPtr( pArr, 1 ), s_norm2( px - qx, py - qy ) );
   hb_itemPutND( hb_arrayGetItemPtr( pArr, 2 ), qx );
   hb_itemPutND( hb_arrayGetItemPtr( pArr, 3 ), qy );
   hb_itemPutND( hb_arrayGetItemPtr( pArr, 4 ), t );
   hb_itemReturnRelease( pArr );
}

/* OC_XFPT( x, y, m11,m12,m21,m22,dx,dy ) -> aArray {x,y} : transf. af??n 2D */
HB_FUNC( OCX_XFPT )
{
   double x = hb_parnd( 1 ), y = hb_parnd( 2 );
   double m11 = hb_parnd( 3 ), m12 = hb_parnd( 4 );
   double m21 = hb_parnd( 5 ), m22 = hb_parnd( 6 );
   double dx = hb_parnd( 7 ), dy = hb_parnd( 8 );
   PHB_ITEM pArr = hb_itemArrayNew( 2 );
   hb_itemPutND( hb_arrayGetItemPtr( pArr, 1 ), m11 * x + m12 * y + dx );
   hb_itemPutND( hb_arrayGetItemPtr( pArr, 2 ), m21 * x + m22 * y + dy );
   hb_itemReturnRelease( pArr );
}

/* OC_POLYLEN( aVerts ) -> cDouble ; aVerts = array de {x,y} */
HB_FUNC( OCX_POLYLEN )
{
   PHB_ITEM pV = hb_param( 1, HB_IT_ARRAY );
   double L = 0.0;
   if( pV != NULL )
   {
      HB_SIZE n = hb_arrayLen( pV ), i;
      for( i = 2; i <= n; i++ )
      {
         PHB_ITEM a = hb_arrayGetItemPtr( pV, i - 1 );
         PHB_ITEM b = hb_arrayGetItemPtr( pV, i );
         if( a && b && HB_IS_ARRAY( a ) && HB_IS_ARRAY( b ) )
         {
            double dx = hb_arrayGetND( b, 1 ) - hb_arrayGetND( a, 1 );
            double dy = hb_arrayGetND( b, 2 ) - hb_arrayGetND( a, 2 );
            L += s_norm2( dx, dy );
         }
      }
   }
   hb_retnd( L );
}

/* OC_POLYAREA( aVerts ) -> cDouble : ??rea con signo (shoelace) */
HB_FUNC( OCX_POLYAREA )
{
   PHB_ITEM pV = hb_param( 1, HB_IT_ARRAY );
   double A = 0.0;
   if( pV != NULL )
   {
      HB_SIZE n = hb_arrayLen( pV ), i;
      for( i = 1; i <= n; i++ )
      {
         PHB_ITEM a = hb_arrayGetItemPtr( pV, i );
         PHB_ITEM b = hb_arrayGetItemPtr( pV, ( i % n ) + 1 );
         if( a && b && HB_IS_ARRAY( a ) && HB_IS_ARRAY( b ) )
            A += hb_arrayGetND( a, 1 ) * hb_arrayGetND( b, 2 )
               - hb_arrayGetND( b, 1 ) * hb_arrayGetND( a, 2 );
      }
      A *= 0.5;
   }
   hb_retnd( A );
}

/* OC_ARCN( cx,cy,r, a0,a1, sag ) -> n : n?? segmentos para teselar arco */
HB_FUNC( OCX_ARCN )
{
   double r = hb_parnd( 3 );
   double a0 = hb_parnd( 4 ), a1 = hb_parnd( 5 );
   double sag = hb_parnd( 6 );
   double span, n;
   if( r <= 0.0 || sag <= 0.0 )
   {
      hb_retni( 16 );
      return;
   }
   span = fabs( a1 - a0 );
   if( span < 1e-9 )
   {
      hb_retni( 1 );
      return;
   }
   /* n = span / (2*acos(1-sag/r)) */
   {
      double c = 1.0 - sag / r;
      double step;
      if( c < -1.0 ) c = -1.0;
      if( c > 1.0 ) c = 1.0;
      step = 2.0 * acos( c );
      if( step < 1e-6 ) step = 1e-6;
      n = ceil( span / step );
   }
   if( n < 4 ) n = 4;
   if( n > 4096 ) n = 4096;
   hb_retni( (int) n );
}

/* OC_TESSARC( cx,cy,r, a0,a1, n ) -> aArray de {x,y} (n+1 puntos) */
HB_FUNC( OCX_TESSARC )
{
   double cx = hb_parnd( 1 ), cy = hb_parnd( 2 ), r = hb_parnd( 3 );
   double a0 = hb_parnd( 4 ), a1 = hb_parnd( 5 );
   long n = hb_parnl( 6 );
   PHB_ITEM pArr;
   long i;
   if( n < 1 ) n = 1;
   if( n > 8192 ) n = 8192;
   pArr = hb_itemArrayNew( (HB_SIZE) n + 1 );
   for( i = 0; i <= n; i++ )
   {
      double a = a0 + ( a1 - a0 ) * ( (double) i / (double) n );
      PHB_ITEM pt = hb_itemArrayNew( 2 );
      hb_arraySetND( pt, 1, cx + r * cos( a ) );
      hb_arraySetND( pt, 2, cy + r * sin( a ) );
      hb_arraySet( pArr, (HB_SIZE) i + 1, pt );
      hb_itemRelease( pt );
   }
   hb_itemReturnRelease( pArr );
}

/* OC_BBOXPTS( aVerts ) -> aArray {xmin,ymin,xmax,ymax} */
HB_FUNC( OCX_BBOXPTS )
{
   PHB_ITEM pV = hb_param( 1, HB_IT_ARRAY );
   PHB_ITEM pBox = hb_itemArrayNew( 4 );
   if( pV != NULL && hb_arrayLen( pV ) > 0 )
   {
      HB_SIZE n = hb_arrayLen( pV ), i;
      double xmin, ymin, xmax, ymax;
      PHB_ITEM f = hb_arrayGetItemPtr( pV, 1 );
      xmin = xmax = hb_arrayGetND( f, 1 );
      ymin = ymax = hb_arrayGetND( f, 2 );
      for( i = 2; i <= n; i++ )
      {
         PHB_ITEM p = hb_arrayGetItemPtr( pV, i );
         if( p && HB_IS_ARRAY( p ) )
         {
            double x = hb_arrayGetND( p, 1 );
            double y = hb_arrayGetND( p, 2 );
            if( x < xmin ) xmin = x;
            if( x > xmax ) xmax = x;
            if( y < ymin ) ymin = y;
            if( y > ymax ) ymax = y;
         }
      }
      hb_itemPutND( hb_arrayGetItemPtr( pBox, 1 ), xmin );
      hb_itemPutND( hb_arrayGetItemPtr( pBox, 2 ), ymin );
      hb_itemPutND( hb_arrayGetItemPtr( pBox, 3 ), xmax );
      hb_itemPutND( hb_arrayGetItemPtr( pBox, 4 ), ymax );
   }
   else
   {
      hb_itemPutND( hb_arrayGetItemPtr( pBox, 1 ), 0.0 );
      hb_itemPutND( hb_arrayGetItemPtr( pBox, 2 ), 0.0 );
      hb_itemPutND( hb_arrayGetItemPtr( pBox, 3 ), 0.0 );
      hb_itemPutND( hb_arrayGetItemPtr( pBox, 4 ), 0.0 );
   }
   hb_itemReturnRelease( pBox );
}

/* OC_OFFSEG( x1,y1,x2,y2, d ) -> aArray {ax,ay,bx,by} : paralela a distancia d
   (normal izquierda del segmento). */
HB_FUNC( OCX_OFFSEG )
{
   double x1 = hb_parnd( 1 ), y1 = hb_parnd( 2 );
   double x2 = hb_parnd( 3 ), y2 = hb_parnd( 4 );
   double d = hb_parnd( 5 );
   double dx = x2 - x1, dy = y2 - y1;
   double L = s_norm2( dx, dy );
   double nx = 0.0, ny = 0.0;
   PHB_ITEM pArr = hb_itemArrayNew( 4 );
   if( L > 1e-12 )
   {
      nx = -dy / L * d;
      ny = dx / L * d;
   }
   hb_itemPutND( hb_arrayGetItemPtr( pArr, 1 ), x1 + nx );
   hb_itemPutND( hb_arrayGetItemPtr( pArr, 2 ), y1 + ny );
   hb_itemPutND( hb_arrayGetItemPtr( pArr, 3 ), x2 + nx );
   hb_itemPutND( hb_arrayGetItemPtr( pArr, 4 ), y2 + ny );
   hb_itemReturnRelease( pArr );
}
