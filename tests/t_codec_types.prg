/* Port 1:1 de tests de opencadcodec types/{handle,color,aci_table}.rs (6 + 11 + 6) */
#include "ocx.ch"
STATIC FUNCTION RgbEq( a, b ) ; RETURN a != NIL .AND. b != NIL .AND. a[1] == b[1] .AND. a[2] == b[2] .AND. a[3] == b[3]
PROCEDURE T_CodecTypes()
   LOCAL h, nu, c, i, idx, h1, h2
   // handle
   h := Hd_New( 4660 )
   Chk( Hd_Value( h ) == 4660, "handle: test_handle_creation" )
   nu := Hd_Null()
   Chk( Hd_IsNull( nu ) .AND. ! Hd_IsValid( nu ) .AND. Hd_Value( nu ) == 0, "handle: test_null_handle" )
   h := Hd_New( 42 )
   Chk( ! Hd_IsNull( h ) .AND. Hd_IsValid( h ), "handle: test_valid_handle" )
   h := Hd_New( 43981 )
   Chk( Hd_Display( h ) == "0xABCD" .AND. Hd_LowerHex( h ) == "abcd" .AND. Hd_UpperHex( h ) == "ABCD", "handle: test_handle_display" )
   Chk( Hd_Value( Hd_New( 12345 ) ) == 12345, "handle: test_handle_conversion" )
   h1 := Hd_New( 100 ) ; h2 := Hd_New( 200 )
   Chk( h1 < h2 .AND. h2 > h1, "handle: test_handle_ordering" )
   // color
   Chk( Cl_Eq( Cl_FromIndex( 0 ), Cl_ByBlock() ) .AND. Cl_Eq( Cl_FromIndex( 256 ), Cl_ByLayer() ) .AND. Cl_Eq( Cl_FromIndex( 1 ), Cl_Index( 1 ) ), "color: test_color_from_index" )
   Chk( Cl_Eq( Cl_FromIndex( -5 ), Cl_Index( 5 ) ) .AND. Cl_Eq( Cl_FromIndex( -300 ), Cl_Index( 255 ) ) .AND. Cl_Eq( Cl_FromIndex( -32768 ), Cl_Index( 255 ) ), "color: test_color_from_negative_index" )
   c := Cl_FromRgb( 255, 128, 64 )
   Chk( RgbEq( Cl_Rgb( c ), { 255, 128, 64 } ) .AND. RgbEq( Cl_TrueColorRgb( c ), { 255, 128, 64 } ) .AND. Cl_IndexOf( c ) == NIL, "color: test_color_rgb" )
   c := Cl_Index( 5 )
   Chk( Cl_IndexOf( c ) == 5 .AND. RgbEq( Cl_Rgb( c ), { 0, 0, 255 } ) .AND. Cl_TrueColorRgb( c ) == NIL, "color: test_color_index" )
   Chk( Cl_Eq( Cl_Red(), Cl_Index( 1 ) ) .AND. Cl_Eq( Cl_Blue(), Cl_Index( 5 ) ), "color: test_color_constants" )
   Chk( Cl_Display( Cl_ByLayer() ) == "ByLayer" .AND. Cl_Display( Cl_FromRgb( 255, 0, 0 ) ) == "RGB(255, 0, 0)", "color: test_color_display" )
   Chk( Cl_Eq( Cl_Default(), Cl_ByLayer() ), "color: test_default_color" )
   Chk( Cl_Eq( Cl_FromTrueColorValue( 16744512 ), Cl_FromRgb( 255, 128, 64 ) ), "color: test_from_true_color_value" )
   Chk( Cl_ToTrueColorValue( Cl_FromRgb( 255, 128, 64 ) ) == 16744512 .AND. Cl_ToTrueColorValue( Cl_Index( 1 ) ) == NIL, "color: test_to_true_color_value" )
   i := Cl_ApproximateIndex( Cl_FromRgb( 255, 0, 0 ) )
   idx := Cl_ApproximateIndex( Cl_FromRgb( 0, 0, 255 ) )
   Chk( i == 1 .AND. ( idx == 5 .OR. idx == 170 ), "color: test_approximate_index_nearest_neighbor" )
   Chk( Cl_IsTrueColor( Cl_FromRgb( 10, 20, 30 ) ) .AND. ! Cl_IsTrueColor( Cl_Index( 1 ) ) .AND. ! Cl_IsTrueColor( Cl_ByLayer() ), "color: test_is_true_color" )
   // aci_table
   Chk( RgbEq( Aci_ToRgb( 1 ), {255,0,0} ) .AND. RgbEq( Aci_ToRgb( 2 ), {255,255,0} ) .AND. RgbEq( Aci_ToRgb( 3 ), {0,255,0} ) .AND. RgbEq( Aci_ToRgb( 4 ), {0,255,255} ) .AND. RgbEq( Aci_ToRgb( 5 ), {0,0,255} ) .AND. RgbEq( Aci_ToRgb( 6 ), {255,0,255} ) .AND. RgbEq( Aci_ToRgb( 7 ), {255,255,255} ), "aci: aci_standard_colors" )
   Chk( Aci_ToRgb( 0 ) == NIL, "aci: aci_byblock_returns_none" )
   Chk( Aci_Nearest( 255, 0, 0 ) == 1 .AND. Aci_Nearest( 0, 255, 0 ) == 3 .AND. Aci_Nearest( 0, 0, 255 ) == 5 .AND. Aci_Nearest( 255, 255, 0 ) == 2, "aci: nearest_aci_exact_match" )
   Chk( Aci_Nearest( 250, 5, 5 ) == 1, "aci: nearest_aci_approximate" )
   Chk( Aci_Len() == 256, "aci: table_length" )
   Chk( RgbEq( Aci_ToRgb( 8 ), {128,128,128} ) .AND. RgbEq( Aci_ToRgb( 9 ), {192,192,192} ) .AND. RgbEq( Aci_ToRgb( 250 ), {51,51,51} ) .AND. RgbEq( Aci_ToRgb( 255 ), {255,255,255} ), "aci: grays_are_correct" )
RETURN
