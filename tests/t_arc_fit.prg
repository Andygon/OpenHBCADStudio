/* Port de #[cfg(test)] de arc_fit.rs (3 tests). UTF-8. */
#include "ocx.ch"
PROCEDURE T_ArcFit()
   LOCAL f, ok, v
   f := AF_FitArcChain( { {0.0,0.0}, {3.0,4.0} }, .F., { NIL, NIL } )
   Chk( f != NIL .AND. Len( f ) == 2 .AND. f[1][1][1] == 0.0 .AND. f[1][1][2] == 0.0 .AND. f[1][2] == 0.0 .AND. f[2][1][1] == 3.0 .AND. f[2][1][2] == 4.0, "arc_fit: dos puntos un tramo recto" )
   f := AF_FitArcChain( { {0.0,0.0}, {1.0,1.0}, {2.0,0.0} }, .F., { NIL, NIL, NIL } )
   ok := f != NIL
   IF ok
      ok := f[1][1][1] == 0.0 .AND. f[1][1][2] == 0.0 .AND. ATail( f )[1][1] == 2.0 .AND. ATail( f )[1][2] == 0.0
      FOR EACH v IN f
         ok := ok .AND. OCX_ISFINITE( v[1][1] ) .AND. OCX_ISFINITE( v[1][2] ) .AND. OCX_ISFINITE( v[2] ) .AND. OCX_ISFINITE( v[4] )
      NEXT
   ENDIF
   Chk( ok, "arc_fit: cadena curva conserva extremos y arcos finitos" )
   Chk( AF_FitArcChain( { {0.0,0.0}, {1.0,1.0}, {2.0,0.0} }, .F., { { 1.7976931348623157 * OCX_POW( 10.0, 308.0 ), 1.7976931348623157 * OCX_POW( 10.0, 308.0 ) }, NIL, NIL } ) == NIL, "arc_fit: direccion invalida rechaza el ajuste" )
RETURN
