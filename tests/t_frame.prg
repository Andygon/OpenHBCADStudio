/* Port 1:1 de #[cfg(test)] de frame.rs. UTF-8. */
#include "ocx.ch"
PROCEDURE T_Frame()
   LOCAL aF, aP, aPts, w, l, n, lOk
   aF := Frame_At( { 512345.678, 4512345.678, 91.5 } )
   aP := { 512400.5, 4512300.25, 100.0 }
   Chk( V3Eq( Frame_Lower( aF, Frame_Lift( aF, aP ) ), aP ), "lift/lower roundtrip" )
   aPts := { { 500000.0, 4500000.0, 0.0 }, { 500100.0, 4500200.0, 10.0 } }
   aF := Frame_Around( aPts )
   Chk( V3Eq( Frame_Origin( aF ), { 500050.0, 4500100.0, 5.0 } ), "around midpoint" )
   lOk := .T.
   FOR n := 1 TO 2
      aP := Frame_Lift( aF, aPts[ n ] )
      lOk := lOk .AND. Abs( aP[1] ) <= 50 .AND. Abs( aP[2] ) <= 100 .AND. Abs( aP[3] ) <= 5
   NEXT
   Chk( lOk, "around bounds lifted magnitude" )
   w := OCX_SPACING( 4500000.0 ); l := OCX_SPACING( 100.0 )
   Chk( w > 0.0000000001, "world spacing" ); Chk( l < 0.0000000000001, "local spacing" ); Chk( w / l > 1000, "ratio" )
   Chk( V3Eq( Frame_Around( {} ), Frame_Identity() ), "empty -> identity" )
RETURN
STATIC FUNCTION V3Eq( a, b )
RETURN a[1] == b[1] .AND. a[2] == b[2] .AND. a[3] == b[3]
