/* Port de tests: attribute_definition.rs (11) + [extra] */
#include "ocx.ch"
STATIC FUNCTION Nr( a, b ) ; RETURN Abs( a - b ) < 0.0000000001
PROCEDURE T_CodecAttdef()
   LOCAL a, f
   a := Ead_New( "TAG", "Enter value:", "default" ) ; Chk( a[ "tag" ] == "TAG" .AND. a[ "prompt" ] == "Enter value:" .AND. a[ "default_value" ] == "default", "attdef: test_attdef_creation" )
   a := Ead_Simple( "PART_NO" ) ; Chk( a[ "tag" ] == "PART_NO" .AND. a[ "prompt" ] == "Enter PART_NO:", "attdef: test_attdef_simple" )
   a := Ead_Invisible( "HIDDEN", "secret" ) ; Chk( a[ "flags" ][ "invisible" ] .AND. a[ "default_value" ] == "secret", "attdef: test_attdef_invisible" )
   a := Ead_Constant( "VERSION", "1.0" ) ; Chk( a[ "flags" ][ "constant" ] .AND. a[ "default_value" ] == "1.0", "attdef: test_attdef_constant" )
   a := Ead_Default() ; Ead_SetRotationDegrees( a, 45.0 ) ; Chk( Nr( Ead_RotationDegrees( a ), 45.0 ), "attdef: test_attdef_rotation" )
   f := Taf_FromBits( 7 ) ; Chk( f[ "invisible" ] .AND. f[ "constant" ] .AND. f[ "verify" ] .AND. ! f[ "preset" ] .AND. Taf_ToBits( f ) == 7, "attdef: test_attdef_flags" )
   a := Ead_Default() ; Ead_SetAlignment( a, TXH_CENTER, TXV_MIDDLE ) ; Chk( a[ "horizontal_alignment" ] == TXH_CENTER .AND. a[ "vertical_alignment" ] == TXV_MIDDLE, "attdef: test_attdef_alignment" )
   a := Ead_Default() ; a[ "insertion_point" ] := Vc3_New( 10.0, 20.0, 0.0 ) ; a[ "alignment_point" ] := Vc3_New( 10.0, 20.0, 0.0 ) ; Ent_Translate( a, Vc3_New( 5.0, 5.0, 0.0 ) )
   Chk( Vc3_Eq( a[ "insertion_point" ], Vc3_New( 15.0, 25.0, 0.0 ) ) .AND. Vc3_Eq( a[ "alignment_point" ], Vc3_New( 15.0, 25.0, 0.0 ) ), "attdef: test_attdef_translate" )
   a := Ead_Simple( "TEST" ) ; Ead_SetPosition( a, Vc3_New( 10.0, 10.0, 0.0 ) ) ; Ead_SetHeight( a, 5.0 ) ; Ead_SetRotationDegrees( a, 90.0 ) ; Ead_SetInvisible( a, .T. ) ; a[ "common" ][ "layer" ] := "ATTRIBUTES"
   Chk( Vc3_Eq( a[ "insertion_point" ], Vc3_New( 10.0, 10.0, 0.0 ) ) .AND. a[ "height" ] == 5.0 .AND. a[ "flags" ][ "invisible" ] .AND. a[ "common" ][ "layer" ] == "ATTRIBUTES", "attdef: test_attdef_builder (via setters)" )
   Chk( Ha_FromValue( 0 ) == TXH_LEFT .AND. Ha_FromValue( 1 ) == TXH_CENTER .AND. Ha_FromValue( 2 ) == TXH_RIGHT, "attdef: test_horizontal_alignment" )
   Chk( Va_FromValue( 0 ) == TXV_BASELINE .AND. Va_FromValue( 2 ) == TXV_MIDDLE, "attdef: test_vertical_alignment" )
   // [extra]
   Chk( Ha_FromValue( 9 ) == TXH_LEFT .AND. Va_FromValue( -1 ) == TXV_BASELINE .AND. Mtf_FromValue( 4 ) == MTF_CONSTANTMULTILINE .AND. Mtf_FromValue( 3 ) == MTF_SINGLELINE, "[extra] attdef: from_value fuera de rango" )
   a := Ead_Simple( "T" ) ; a[ "default_value" ] := "abc" ; a[ "height" ] := 2.0 ; Chk( Nr( Ead_EstimatedWidth( a ), 3.6 ) .AND. Nr( Ent_BoundingBox( a )[ 2 ][ 1 ], 3.6 ) .AND. Ent_EntityType( a ) == "ATTDEF", "[extra] attdef: ancho y bbox" )
   Ent_ApplyScaling( a, 2.0 ) ; Chk( Nr( a[ "height" ], 4.0 ), "[extra] attdef: escala" )
RETURN
