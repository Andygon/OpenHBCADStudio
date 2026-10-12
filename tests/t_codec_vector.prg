/* Port 1:1 de los 8 tests de opencadcodec types/vector.rs */
#include "ocx.ch"
PROCEDURE T_CodecVector()
   LOCAL v, n, v1, v2
   v := Vc2_New( 3.0, 4.0 )
   Chk( v[1] == 3.0 .AND. v[2] == 4.0, "codec vector: test_vector2_creation" )
   Chk( Vc2_Length( v ) == 5.0 .AND. Vc2_LengthSquared( v ) == 25.0, "codec vector: test_vector2_length" )
   n := Vc2_Normalize( v )
   Chk( Abs( Vc2_Length( n ) - 1.0 ) < 0.0000000001, "codec vector: test_vector2_normalize" )
   v1 := Vc2_New( 1.0, 2.0 ) ; v2 := Vc2_New( 3.0, 4.0 )
   Chk( Vc2_Eq( Vc2_Add( v1, v2 ), Vc2_New( 4.0, 6.0 ) ) .AND. Vc2_Eq( Vc2_Sub( v2, v1 ), Vc2_New( 2.0, 2.0 ) ) .AND. Vc2_Eq( Vc2_Mul( v1, 2.0 ), Vc2_New( 2.0, 4.0 ) ), "codec vector: test_vector2_operations" )
   Chk( Vc2_Dot( v1, v2 ) == 11.0, "codec vector: test_vector2_dot" )
   v := Vc3_New( 1.0, 2.0, 3.0 )
   Chk( v[1] == 1.0 .AND. v[2] == 2.0 .AND. v[3] == 3.0, "codec vector: test_vector3_creation" )
   Chk( Vc3_Eq( Vc3_Cross( Vc3_UnitX(), Vc3_UnitY() ), Vc3_UnitZ() ), "codec vector: test_vector3_cross" )
   v1 := Vc3_New( 1.0, 2.0, 3.0 ) ; v2 := Vc3_New( 4.0, 5.0, 6.0 )
   Chk( Vc3_Eq( Vc3_Add( v1, v2 ), Vc3_New( 5.0, 7.0, 9.0 ) ) .AND. Vc3_Eq( Vc3_Neg( v1 ), Vc3_New( -1.0, -2.0, -3.0 ) ), "codec vector: test_vector3_operations" )
   // [extra] normalize de vector nulo devuelve el mismo
   Chk( Vc2_Eq( Vc2_Normalize( Vc2_Zero() ), Vc2_Zero() ) .AND. Vc3_Eq( Vc3_Normalize( Vc3_Zero() ), Vc3_Zero() ), "[extra] codec vector: normalize de cero" )
RETURN
