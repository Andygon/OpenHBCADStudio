/* Tests: mlinestyle.rs (13 tests 1:1) + [extra] */
#include "ocx.ch"
PROCEDURE T_CodecObjMlStyle()
   LOCAL s, e, f, r, a
   s := Mlsy_New( "Custom" ) ; Chk( s[ "name" ] == "Custom" .AND. Mlsy_IsEmpty( s ) .AND. Abs( s[ "start_angle" ] - OCX_PI / 2.0 ) < 0.0000000001, "mlinestyle_creation" )
   s := Mlsy_Standard() ; a := { s[ "elements" ][ 1 ][ "offset" ], s[ "elements" ][ 2 ][ "offset" ] }
   Chk( s[ "name" ] == "Standard" .AND. Mlsy_ElementCount( s ) == 2 .AND. AScan( a, 0.5 ) > 0 .AND. AScan( a, -0.5 ) > 0, "mlinestyle_standard" )
   s := Mlsy_New( "Test" ) ; Mlsy_AddElement( s, Mlse_New( 0.0 ) ) ; Mlsy_AddElement( s, Mlse_New( 1.0 ) ) ; Chk( Mlsy_ElementCount( s ) == 2, "mlinestyle_add_element" )
   s := Mlsy_Standard() ; r := Mlsy_RemoveElement( s, 0 ) ; Chk( r != NIL .AND. Mlsy_ElementCount( s ) == 1, "mlinestyle_remove_element" )
   s := Mlsy_New( "Test" ) ; Mlsy_AddElement( s, Mlse_New( -1.0 ) ) ; Mlsy_AddElement( s, Mlse_New( 0.0 ) ) ; Mlsy_AddElement( s, Mlse_New( 1.5 ) ) ; Chk( Abs( Mlsy_Width( s ) - 2.5 ) < 0.0000000001, "mlinestyle_width" )
   s := Mlsy_New( "Test" ) ; Mlsy_AddElement( s, Mlse_New( 1.0 ) ) ; Mlsy_AddElement( s, Mlse_New( -1.0 ) ) ; Mlsy_AddElement( s, Mlse_New( 0.0 ) ) ; Mlsy_SortElements( s )
   Chk( s[ "elements" ][ 1 ][ "offset" ] == -1.0 .AND. s[ "elements" ][ 2 ][ "offset" ] == 0.0 .AND. s[ "elements" ][ 3 ][ "offset" ] == 1.0, "mlinestyle_sort" )
   e := Mlse_New( 0.5 ) ; Chk( e[ "offset" ] == 0.5 .AND. Cl_Eq( e[ "color" ], Cl_ByLayer() ), "mlinestyle_element inicio" )
   Mlse_SetColor( e, Cl_FromIndex( 1 ) ) ; Chk( Cl_Eq( e[ "color" ], Cl_FromIndex( 1 ) ), "mlinestyle_element color" ) ; Mlse_SetLinetype( e, "DASHED" ) ; Chk( e[ "linetype" ] == "DASHED", "mlinestyle_element linetype" )
   e := Mlse_Full( 0.25, Cl_FromIndex( 2 ), "CENTER" ) ; Chk( e[ "offset" ] == 0.25 .AND. Cl_Eq( e[ "color" ], Cl_FromIndex( 2 ) ) .AND. e[ "linetype" ] == "CENTER", "mlinestyle_element_full" )
   f := Mlsf_FromBits( hb_bitOr( 1, 16, 256 ) ) ; Chk( f[ "fill_on" ] .AND. f[ "start_square_cap" ] .AND. f[ "end_square_cap" ] .AND. ! f[ "display_joints" ] .AND. Mlsf_ToBits( f ) == hb_bitOr( 1, 16, 256 ), "mlinestyle_flags" )
   s := Mlsy_New( "Test" ) ; Mlsy_SetRoundCaps( s ) ; Chk( s[ "flags" ][ "start_round_cap" ] .AND. s[ "flags" ][ "end_round_cap" ] .AND. ! s[ "flags" ][ "start_square_cap" ], "mlinestyle_caps round" )
   Mlsy_SetSquareCaps( s ) ; Chk( s[ "flags" ][ "start_square_cap" ] .AND. s[ "flags" ][ "end_square_cap" ] .AND. ! s[ "flags" ][ "start_round_cap" ], "mlinestyle_caps square" )
   s := Mlsy_New( "Test" ) ; Mlsy_EnableFill( s, Cl_FromIndex( 5 ) ) ; Chk( s[ "flags" ][ "fill_on" ] .AND. Cl_Eq( s[ "fill_color" ], Cl_FromIndex( 5 ) ), "mlinestyle_fill on" ) ; Mlsy_DisableFill( s ) ; Chk( ! s[ "flags" ][ "fill_on" ], "mlinestyle_fill off" )
   s := Mlsy_WithFill( Mlsy_WithElement( Mlsy_WithElement( Mlsy_WithDescription( Mlsy_New( "Test" ), "A test style" ), Mlse_New( -0.5 ) ), Mlse_New( 0.5 ) ), Cl_FromIndex( 3 ) )
   Chk( s[ "description" ] == "A test style" .AND. Mlsy_ElementCount( s ) == 2 .AND. s[ "flags" ][ "fill_on" ], "mlinestyle_builder" )
   s := Mlsy_New( "Test" ) ; Mlsy_SetStartAngleDegrees( s, 45.0 ) ; Mlsy_SetEndAngleDegrees( s, 60.0 ) ; Chk( Abs( Mlsy_StartAngleDegrees( s ) - 45.0 ) < 0.0000000001 .AND. Abs( Mlsy_EndAngleDegrees( s ) - 60.0 ) < 0.0000000001, "mlinestyle_angles" )
   s := Mlsy_New( "T" ) ; Mlsy_InsertElement( s, 0, Mlse_New( 2.0 ) ) ; Mlsy_InsertElement( s, 5, Mlse_New( 9.0 ) ) ; Mlsy_InsertElement( s, 0, Mlse_New( 1.0 ) )
   Chk( Mlsy_ElementCount( s ) == 2 .AND. Mlsy_GetElement( s, 0 )[ "offset" ] == 1.0 .AND. Mlsy_GetElement( s, 2 ) == NIL .AND. Mlsy_RemoveElement( s, 9 ) == NIL, "[extra] insert_element fuera de rango se ignora; get/remove fuera de rango dan None" )
   Chk( Mlsf_ToBits( Mlsf_Simple() ) == 16 + 256 .AND. Mlsf_ToBits( Mlsf_RoundCaps() ) == 64 + 1024 .AND. Mlsy_ObjectType() == "MLINESTYLE" .AND. Mlsy_Default()[ "name" ] == "Standard", "[extra] flags simple/round_caps y constantes" )
RETURN
