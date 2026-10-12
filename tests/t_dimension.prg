/* Port de #[cfg(test)] de dimension.rs (2 tests). UTF-8. */
#include "ocx.ch"
STATIC FUNCTION AtP( aO, aAx, aNo, x, y ) ; RETURN V2_Add( V2_Add( aO, V2_Mul( aAx, x ) ), V2_Mul( aNo, y ) )

PROCEDURE T_Dimension()
   LOCAL aO, nAng, aAx, aNo, lRev, aM, aCase, aRes, ok, x, rot, ex, under, aES, aEE, line
   ok := .T.
   FOR EACH aO IN { { 0.0, 0.0 }, { 500000.0, 4500000.0 } }
      FOR EACH nAng IN { 0.0, 0.6, OCX_PI / 2.0 }
         aAx := { OCX_COS( nAng ), OCX_SIN( nAng ) }
         aNo := V2_Perpendicular( aAx )
         FOR EACH lRev IN { .F., .T. }
            IF lRev
               aM := { AtP( aO, aAx, aNo, 20.0, 0.0 ), AtP( aO, aAx, aNo, 0.0, 0.0 ) }
            ELSE
               aM := { AtP( aO, aAx, aNo, 0.0, 0.0 ), AtP( aO, aAx, aNo, 20.0, 0.0 ) }
            ENDIF
            FOR EACH aCase IN { { 30.0, nAng, 33.0, .T. }, { -12.0, nAng, -15.0, .T. }, { 10.0, nAng, 10.0, .F. }, { 30.0, nAng + OCX_PI / 2.0, 31.0, .T. } }
               x := aCase[1] ; rot := aCase[2] ; ex := aCase[3] ; under := aCase[4]
               aRes := Dm_LinearLeader( aM, AtP( aO, aAx, aNo, 0.0, -5.0 ), aAx, AtP( aO, aAx, aNo, x, -3.0 ), { 3.0, 1.0 }, rot )
               IF aRes == NIL ; ok := .F. ; LOOP ; ENDIF
               line := aRes[1]
               ok := ok .AND. ( aRes[2] == under )
               aES := AtP( aO, aAx, aNo, Max( 0.0, Min( 20.0, x ) ), -5.0 )
               aEE := AtP( aO, aAx, aNo, ex, IIf( under, -5.0, -3.0 ) )
               ok := ok .AND. V2_Distance( line[1], aES ) < 0.00000001 .AND. V2_Distance( line[2], aEE ) < 0.00000001
            NEXT
         NEXT
      NEXT
   NEXT
   Chk( ok, "dimension: leader sigue colocacion, rotacion y origenes grandes" )
   aM := { { 0.0, 0.0 }, { 20.0, 0.0 } }
   Chk( Dm_LinearLeader( aM, { 0.0, -5.0 }, { 0.0, 0.0 }, { 30.0, -3.0 }, { 3.0, 1.0 }, 0.0 ) == NIL, "dimension: eje cero rechazado" )
   Chk( Dm_LinearLeader( aM, { 0.0, -5.0 }, { 1.0, 0.0 }, { OCX_NAN(), -3.0 }, { 3.0, 1.0 }, 0.0 ) == NIL, "dimension: NaN rechazado" )
   Chk( Dm_LinearLeader( aM, { 0.0, -5.0 }, { 1.0, 0.0 }, { 30.0, -3.0 }, { -3.0, 1.0 }, 0.0 ) == NIL, "dimension: semiextension negativa rechazada" )
RETURN
