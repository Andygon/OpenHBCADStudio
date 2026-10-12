/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/vector.prg
   Origen Rust: opencadcodec/src/types/vector.rs (309 lineas, licencia MPL-2.0 del original)
   Vector2 = {x,y}; Vector3 = {x,y,z}. Operadores sobrecargados de Rust -> funciones Vc2_/Vc3_.
   normalize: si la longitud es 0 devuelve el mismo vector (a diferencia de V2_Normalize de geom2d).
   NO portado: impl Display ("({}, {})") - depende del formato de f64 de Rust; se hara junto al
   escritor DXF con una funcion de formato dedicada.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Vc2_New( x, y ) ; RETURN { x, y }
FUNCTION Vc2_Zero() ; RETURN { 0.0, 0.0 }
FUNCTION Vc2_UnitX() ; RETURN { 1.0, 0.0 }
FUNCTION Vc2_UnitY() ; RETURN { 0.0, 1.0 }
FUNCTION Vc2_LengthSquared( a ) ; RETURN a[1] * a[1] + a[2] * a[2]
FUNCTION Vc2_Length( a ) ; RETURN Sqrt( Vc2_LengthSquared( a ) )
FUNCTION Vc2_Normalize( a )
   LOCAL n := Vc2_Length( a )
   IF n > 0.0 ; RETURN { a[1] / n, a[2] / n } ; ENDIF
RETURN { a[1], a[2] }
FUNCTION Vc2_Dot( a, b ) ; RETURN a[1] * b[1] + a[2] * b[2]
FUNCTION Vc2_Cross( a, b ) ; RETURN a[1] * b[2] - a[2] * b[1]
FUNCTION Vc2_Add( a, b ) ; RETURN { a[1] + b[1], a[2] + b[2] }
FUNCTION Vc2_Sub( a, b ) ; RETURN { a[1] - b[1], a[2] - b[2] }
FUNCTION Vc2_Mul( a, s ) ; RETURN { a[1] * s, a[2] * s }
FUNCTION Vc2_Div( a, s ) ; RETURN { a[1] / s, a[2] / s }
FUNCTION Vc2_Neg( a ) ; RETURN { -a[1], -a[2] }
FUNCTION Vc2_Distance( a, b ) ; RETURN Vc2_Length( Vc2_Sub( a, b ) )
FUNCTION Vc2_Eq( a, b ) ; RETURN a[1] == b[1] .AND. a[2] == b[2]

FUNCTION Vc3_New( x, y, z ) ; RETURN { x, y, z }
FUNCTION Vc3_Zero() ; RETURN { 0.0, 0.0, 0.0 }
FUNCTION Vc3_UnitX() ; RETURN { 1.0, 0.0, 0.0 }
FUNCTION Vc3_UnitY() ; RETURN { 0.0, 1.0, 0.0 }
FUNCTION Vc3_UnitZ() ; RETURN { 0.0, 0.0, 1.0 }
FUNCTION Vc3_LengthSquared( a ) ; RETURN a[1] * a[1] + a[2] * a[2] + a[3] * a[3]
FUNCTION Vc3_Length( a ) ; RETURN Sqrt( Vc3_LengthSquared( a ) )
FUNCTION Vc3_Normalize( a )
   LOCAL n := Vc3_Length( a )
   IF n > 0.0 ; RETURN { a[1] / n, a[2] / n, a[3] / n } ; ENDIF
RETURN { a[1], a[2], a[3] }
FUNCTION Vc3_Dot( a, b ) ; RETURN a[1] * b[1] + a[2] * b[2] + a[3] * b[3]
FUNCTION Vc3_Cross( a, b ) ; RETURN { a[2] * b[3] - a[3] * b[2], a[3] * b[1] - a[1] * b[3], a[1] * b[2] - a[2] * b[1] }
FUNCTION Vc3_Add( a, b ) ; RETURN { a[1] + b[1], a[2] + b[2], a[3] + b[3] }
FUNCTION Vc3_Sub( a, b ) ; RETURN { a[1] - b[1], a[2] - b[2], a[3] - b[3] }
FUNCTION Vc3_Mul( a, s ) ; RETURN { a[1] * s, a[2] * s, a[3] * s }
FUNCTION Vc3_Div( a, s ) ; RETURN { a[1] / s, a[2] / s, a[3] / s }
FUNCTION Vc3_Neg( a ) ; RETURN { -a[1], -a[2], -a[3] }
FUNCTION Vc3_Distance( a, b ) ; RETURN Vc3_Length( Vc3_Sub( a, b ) )
FUNCTION Vc3_Eq( a, b ) ; RETURN a[1] == b[1] .AND. a[2] == b[2] .AND. a[3] == b[3]
