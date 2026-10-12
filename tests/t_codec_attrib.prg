/* Port de tests: attribute_entity.rs (12) + [extra] */
#include "ocx.ch"
STATIC FUNCTION Nr( a, b ) ; RETURN Abs( a - b ) < 0.0000000001
PROCEDURE T_CodecAttrib()
   LOCAL a, a2, d, lVis
   a := Eat_New( "TAG", "value" ) ; Chk( a[ "tag" ] == "TAG" .AND. a[ "value" ] == "value", "attrib: test_attrib_creation" )
   a := Eat_Simple( "PART_NO", "12345" ) ; Chk( a[ "tag" ] == "PART_NO" .AND. a[ "value" ] == "12345", "attrib: test_attrib_simple" )
   d := Ead_New( "TAG", "Enter:", "default" ) ; a := Eat_FromDefinition( d, "custom" ) ; a2 := Eat_FromDefinition( d, NIL )
   Chk( a[ "tag" ] == "TAG" .AND. a[ "value" ] == "custom" .AND. a2[ "value" ] == "default", "attrib: test_attrib_from_definition" )
   a := Eat_Simple( "TAG", "old" ) ; Eat_SetValue( a, "new" ) ; Chk( Eat_GetValue( a ) == "new", "attrib: test_attrib_set_value" )
   a := Eat_Default() ; Eat_SetRotationDegrees( a, 90.0 ) ; Chk( Nr( Eat_RotationDegrees( a ), 90.0 ), "attrib: test_attrib_rotation" )
   a := Eat_Default() ; a[ "insertion_point" ] := Vc3_New( 10.0, 20.0, 0.0 ) ; a[ "alignment_point" ] := Vc3_New( 10.0, 20.0, 0.0 ) ; Ent_Translate( a, Vc3_New( 5.0, 5.0, 0.0 ) )
   Chk( Vc3_Eq( a[ "insertion_point" ], Vc3_New( 15.0, 25.0, 0.0 ) ) .AND. Vc3_Eq( a[ "alignment_point" ], Vc3_New( 15.0, 25.0, 0.0 ) ), "attrib: test_attrib_translate" )
   a := Eat_Simple( "TAG", "value" ) ; a[ "insertion_point" ] := Vc3_New( 10.0, 0.0, 0.0 ) ; a[ "alignment_point" ] := Vc3_New( 10.0, 0.0, 0.0 ) ; a[ "height" ] := 2.5
   Eat_ApplyInsertTransform( a, Vc3_New( 100.0, 100.0, 0.0 ), Vc3_New( 2.0, 2.0, 1.0 ), 0.0 )
   Chk( Nr( a[ "insertion_point" ][ 1 ], 120.0 ) .AND. Nr( a[ "insertion_point" ][ 2 ], 100.0 ) .AND. Nr( a[ "height" ], 5.0 ), "attrib: test_attrib_insert_transform" )
   a := Eat_Simple( "TAG", "value" ) ; a[ "insertion_point" ] := Vc3_New( 10.0, 0.0, 0.0 ) ; a[ "alignment_point" ] := Vc3_New( 10.0, 0.0, 0.0 )
   Eat_ApplyInsertTransform( a, Vc3_Zero(), Vc3_New( 1.0, 1.0, 1.0 ), OCX_PI / 2.0 )
   Chk( Abs( a[ "insertion_point" ][ 1 ] ) < 0.0000000001 .AND. Nr( a[ "insertion_point" ][ 2 ], 10.0 ), "attrib: test_attrib_insert_transform_with_rotation" )
   a := Eat_Default() ; lVis := Eat_IsVisible( a ) ; a[ "flags" ][ "invisible" ] := .T. ; Chk( lVis .AND. ! Eat_IsVisible( a ), "attrib: test_attrib_visibility" )
   a := Eat_Simple( "TAG", "" ) ; Eat_SetValue( a, "test_value" ) ; Eat_SetPosition( a, Vc3_New( 10.0, 10.0, 0.0 ) ) ; Eat_SetHeight( a, 5.0 ) ; Eat_SetRotationDegrees( a, 45.0 ) ; a[ "common" ][ "layer" ] := "ATTRIBUTES"
   Chk( a[ "value" ] == "test_value" .AND. Vc3_Eq( a[ "insertion_point" ], Vc3_New( 10.0, 10.0, 0.0 ) ) .AND. a[ "height" ] == 5.0 .AND. a[ "common" ][ "layer" ] == "ATTRIBUTES", "attrib: test_attrib_builder (via setters)" )
   Chk( Nr( Eat_EstimatedWidth( Eat_Simple( "TAG", "Hello" ) ), 7.5 ), "attrib: test_attrib_estimated_width" )
   // [extra]
   a := Eat_Simple( "T", "abc" ) ; Chk( Ent_EntityType( a ) == "ATTRIB" .AND. Nr( Ent_BoundingBox( a )[ 2 ][ 1 ], 4.5 ), "[extra] attrib: entity_type y bbox" )
   a2 := Ent_Clone( a ) ; a2[ "flags" ][ "invisible" ] := .T. ; a2[ "insertion_point" ][ 1 ] := 9.0
   Chk( ! a[ "flags" ][ "invisible" ] .AND. a[ "insertion_point" ][ 1 ] == 0.0, "[extra] Ent_Clone: copia profunda" )
   d := Ead_Simple( "Q" ) ; d[ "flags" ][ "constant" ] := .T. ; d[ "common" ][ "layer" ] := "L1" ; a := Eat_FromDefinition( d, NIL ) ; d[ "flags" ][ "constant" ] := .F.
   Chk( a[ "flags" ][ "constant" ] .AND. a[ "common" ][ "layer" ] == "L1", "[extra] attrib: from_definition copia flags y capa" )
   Ent_ApplyScaling( a, 2.0 ) ; Chk( Nr( a[ "height" ], 5.0 ), "[extra] attrib: escala" )
RETURN
