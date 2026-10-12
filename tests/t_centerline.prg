/* centerline.rs no tiene tests en Rust: todos [extra]. UTF-8. */
#include "ocx.ch"
PROCEDURE T_Centerline()
   LOCAL r
   r := CL_CenterlineBetween( { {0.0,0.0}, {10.0,0.0} }, { {0.0,4.0}, {10.0,4.0} }, { 2.0,0.0 }, { 2.0,4.0 }, 0.0, 0.0 )
   Chk( r != NIL .AND. Abs( r[1][1] ) < 0.000000001 .AND. Abs( r[1][2] - 2.0 ) < 0.000000001 .AND. Abs( r[2][1] - 10.0 ) < 0.000000001 .AND. Abs( r[2][2] - 2.0 ) < 0.000000001, "[extra] centerline paralelas: linea media" )
   r := CL_CenterlineBetween( { {0.0,0.0}, {10.0,0.0} }, { {0.0,4.0}, {10.0,4.0} }, { 2.0,0.0 }, { 2.0,4.0 }, 1.0, 2.0 )
   Chk( r != NIL .AND. Abs( r[1][1] + 1.0 ) < 0.000000001 .AND. Abs( r[2][1] - 12.0 ) < 0.000000001 .AND. Abs( r[3][1] ) < 0.000000001, "[extra] centerline extensiones" )
   r := CL_CenterlineBetween( { {0.0,0.0}, {10.0,0.0} }, { {0.0,0.0}, {0.0,10.0} }, { 5.0,0.0 }, { 0.0,5.0 }, 0.0, 0.0 )
   Chk( r != NIL .AND. Abs( r[2][1] - r[2][2] ) < 0.000000001 .AND. Abs( r[1][1] ) < 0.000000001, "[extra] centerline bisectriz 45 grados" )
   Chk( CL_CenterlineBetween( { {0.0,0.0}, {0.0,0.0} }, { {0.0,4.0}, {10.0,4.0} }, { 0.0,0.0 }, { 0.0,0.0 }, 0.0, 0.0 ) == NIL, "[extra] centerline degenerada" )
RETURN
