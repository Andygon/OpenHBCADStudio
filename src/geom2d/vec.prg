/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/vec.prg
   Origen Rust: opencadkernel/src/geom2d/vec.rs (300 lineas)
   Estado: TRADUCIDO (todas las fn; tests portados en tests/t_vec.prg)
   Vec2 se representa como array {x,y} (como las firmas [f64;2] del Rust).
   Todas las funciones son puras y devuelven array nuevo (Copy semantics).
   Option<Vec2> -> NIL = None.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION V2_New( x, y )
RETURN { x, y }

FUNCTION V2_Zero()
RETURN { 0.0, 0.0 }

FUNCTION V2_Add( a, b )
RETURN { a[1] + b[1], a[2] + b[2] }

FUNCTION V2_Sub( a, b )
RETURN { a[1] - b[1], a[2] - b[2] }

FUNCTION V2_Mul( a, f )
RETURN { a[1] * f, a[2] * f }

FUNCTION V2_Div( a, d )
RETURN { a[1] / d, a[2] / d }

FUNCTION V2_Neg( a )
RETURN { -a[1], -a[2] }

FUNCTION V2_Eq( a, b )
RETURN a[1] == b[1] .AND. a[2] == b[2]

FUNCTION V2_Dot( a, b )
RETURN a[1] * b[1] + a[2] * b[2]

// Producto vectorial plano: escalar con signo (positivo si b esta CCW de a)
FUNCTION V2_Cross( a, b )
RETURN a[1] * b[2] - a[2] * b[1]

FUNCTION V2_LengthSquared( a )
RETURN V2_Dot( a, a )

FUNCTION V2_Length( a )
RETURN Sqrt( V2_LengthSquared( a ) )

FUNCTION V2_Distance( a, b )
RETURN V2_Length( V2_Sub( b, a ) )

FUNCTION V2_DistanceSquared( a, b )
RETURN V2_LengthSquared( V2_Sub( b, a ) )

// Option<Vec2>: NIL si no hay direccion (longitud <= 1e-300)
FUNCTION V2_Normalize( a )
   LOCAL nLen := V2_Length( a )
   IF nLen > OCX_EPS300
      RETURN V2_Div( a, nLen )
   ENDIF
RETURN NIL

FUNCTION V2_Perpendicular( a )
RETURN { -a[2], a[1] }

FUNCTION V2_Angle( a )
RETURN OCX_ATAN2( a[2], a[1] )

FUNCTION V2_Lerp( a, b, t )
RETURN V2_Add( a, V2_Mul( V2_Sub( b, a ), t ) )

// Distancia de a al SEGMENTO start-end (no a la recta)
FUNCTION V2_DistanceToSegment( p, start, end )
   LOCAL along   := V2_Sub( end, start )
   LOCAL nSq     := V2_LengthSquared( along )
   LOCAL t
   IF nSq < 0.000000000000000000000001   // 1e-24
      RETURN V2_Distance( p, start )
   ENDIF
   t := V2_Dot( V2_Sub( p, start ), along ) / nSq
   t := Max( 0.0, Min( 1.0, t ) )      // clamp(0,1)
RETURN V2_Distance( p, V2_Add( start, V2_Mul( along, t ) ) )
