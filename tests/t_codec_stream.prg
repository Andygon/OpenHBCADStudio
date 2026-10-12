/* Port de los 3 tests de stream_reader.rs (as_i32_bits_*) + [extra] */
#include "ocx.ch"
PROCEDURE T_CodecStream()
   LOCAL c, lOk := .T., a, p, r
   FOR EACH c IN { "0", "16746496", "-1023440896", "-1", "2147483647", "-2147483648" }
      p := Dp_New( 420, c )
      IF Dp_AsI32Bits( p ) != Dp_AsI32( p ) .OR. Dp_AsI32Bits( p ) == NIL ; lOk := .F. ; ENDIF
   NEXT
   Chk( lOk, "stream: as_i32_bits_keeps_what_as_i32_already_kept" )
   lOk := .T.
   FOR EACH a IN { { "2147483648", -2147483648 }, { "3271526400", -1023440896 }, { "4294967295", -1 } }
      p := Dp_New( 420, a[ 1 ] )
      IF Dp_AsI32( p ) != NIL .OR. Dp_AsI32Bits( p ) != a[ 2 ] ; lOk := .F. ; ENDIF
   NEXT
   Chk( lOk, "stream: as_i32_bits_accepts_the_unsigned_half_of_the_range" )
   Chk( Dp_AsI32Bits( Dp_New( 420, "4294967296" ) ) == NIL .AND. Dp_AsI32Bits( Dp_New( 420, "-2147483649" ) ) == NIL .AND. Dp_AsI32Bits( Dp_New( 420, "not a number" ) ) == NIL .AND. Dp_AsI32Bits( Dp_New( 40, "1.5" ) ) == NIL, "stream: as_i32_bits_refuses_what_is_not_a_32_bit_pattern" )
   // [extra]
   Chk( Dp_AsDouble( Dp_New( 40, " 1.5 " ) ) == 1.5 .AND. Dp_AsDouble( Dp_New( 40, "2.5e2" ) ) == 250.0 .AND. Dp_AsDouble( Dp_New( 40, ".5" ) ) == 0.5 .AND. Dp_AsDouble( Dp_New( 40, "-3." ) ) == -3.0 .AND. Dp_AsDouble( Dp_New( 40, "abc" ) ) == NIL .AND. Dp_AsDouble( Dp_New( 40, "1e-3" ) ) == 0.001, "[extra] stream: parse f64" )
   Chk( Dp_AsI16( Dp_New( 70, "32767" ) ) == 32767 .AND. Dp_AsI16( Dp_New( 70, "32768" ) ) == NIL .AND. Dp_AsInt( Dp_New( 160, "9223372036854775808" ) ) == NIL .AND. Dp_AsInt( Dp_New( 90, "+7" ) ) == 7, "[extra] stream: parse i64 / i16" )
   Chk( Dp_AsBool( Dp_New( 290, "1" ) ) == .T. .AND. Dp_AsBool( Dp_New( 290, "0" ) ) == .F. .AND. Dp_AsI16( Dp_New( 290, "1" ) ) == 1 .AND. Dp_AsHandle( Dp_New( 5, " 1F " ) ) == 31 .AND. Dp_AsHandle( Dp_New( 5, "zz" ) ) == NIL .AND. Dp_AsString( Dp_New( 1, "txt" ) ) == "txt", "[extra] stream: bool, handle, string" )
   r := PR_New()
   Chk( PR_AddCoordinate( r, Dp_New( 10, "1" ) ) .AND. PR_AddCoordinate( r, Dp_New( 20, "2" ) ) .AND. PR_IsComplete( r ) .AND. PR_GetPoint( r )[ 3 ] == 0.0 .AND. PR_GetPoint( r )[ 1 ] == 1.0 .AND. ! PR_AddCoordinate( r, Dp_New( 11, "5" ) ) .AND. ! PR_AddCoordinate( r, Dp_New( 40, "5" ) ), "[extra] stream: PointReader" )
RETURN
