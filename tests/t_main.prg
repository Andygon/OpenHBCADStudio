/* Runner de tests de paridad (los #[test] de Rust portados 1:1). UTF-8. */
#include "ocx.ch"
STATIC s_nOk := 0, s_nFail := 0

PROCEDURE Main()
   T_Vec()
   T_Angle()
   T_Frame()
   T_Mod()
   T_Polyline()
   T_Curve()
   T_Nurbs()
   T_Transform()
   T_Bounds()
   T_Intersect()
   T_Arclength()
   T_Deviation()
   T_Cross()
   T_Fillet()
   T_PolylineEdit()
   T_Area()
   T_Construct()
   T_Containment()
   T_Snap()
   T_NurbsEdit()
   ? "RESULTADO:", LTrim( Str( s_nOk ) ), "ok,", LTrim( Str( s_nFail ) ), "fallos"
   IF s_nFail == 0 ; ? "OCX-ALL-OK" ; ENDIF
   ErrorLevel( IIF( s_nFail == 0, 0, 1 ) )
RETURN

FUNCTION Chk( lCond, cName )
   IF lCond ; s_nOk++ ; ELSE ; s_nFail++ ; ? "FALLO:", cName ; ENDIF
RETURN lCond
FUNCTION Near( a, b, e )
RETURN Abs( a - b ) < e
