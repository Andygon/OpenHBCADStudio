/* gradient.rs no tiene tests en Rust: todos [extra]. UTF-8. */
#include "ocx.ch"
PROCEDURE T_Gradient()
   LOCAL sq := { {0.0,0.0}, {4.0,0.0}, {4.0,2.0}, {0.0,2.0} }, f
   f := Gr_Frame( sq, 0.0, 0.0, 0.000001 )
   Chk( f[1][1] == 2.0 .AND. f[1][2] == 1.0 .AND. f[2] == 0.0 .AND. f[3] == 4.0, "[extra] gradient sin shift" )
   Chk( Abs( f[4] - Sqrt( 5.0 ) ) < 0.000000001, "[extra] gradient radio" )
   f := Gr_Frame( sq, 0.0, 1.0, 0.000001 )
   Chk( f[1][1] == 1.0 .AND. f[1][2] == 1.5 .AND. Abs( f[2] + 1.0 ) < 0.000000001, "[extra] gradient shift 1" )
   Chk( Gr_Frame( sq, OCX_NAN(), 0.0, 0.000001 ) == NIL .AND. Gr_Frame( {}, 0.0, 0.0, 0.000001 ) == NIL, "[extra] gradient invalido" )
RETURN
