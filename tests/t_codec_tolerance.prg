/* Port de tests: tolerance.rs (16) + [extra] */
#include "ocx.ch"
STATIC FUNCTION V( x, y, z ) ; RETURN Vc3_New( x, y, z )
STATIC FUNCTION Has( c, s ) ; RETURN s $ c
PROCEDURE T_CodecTolerance()
   LOCAL t, c, l, bb
   t := Etl_New() ; Chk( Vc3_Eq( t[ "insertion_point" ], Vc3_Zero() ) .AND. Vc3_Eq( t[ "direction" ], Vc3_UnitX() ) .AND. Vc3_Eq( t[ "normal" ], Vc3_UnitZ() ) .AND. Len( t[ "text" ] ) == 0 .AND. t[ "dimension_style_name" ] == "Standard", "tolerance: test_tolerance_creation" )
   t := Etl_WithText( V( 10.0, 20.0, 0.0 ), "test" ) ; Chk( t[ "insertion_point" ][ 1 ] == 10.0 .AND. t[ "insertion_point" ][ 2 ] == 20.0 .AND. t[ "text" ] == "test", "tolerance: test_tolerance_with_text" )
   t := Etl_NewFull( V( 5.0, 5.0, 0.0 ), "tolerance text", Vc3_UnitY(), "DIMSTYLE1" )
   Chk( t[ "insertion_point" ][ 1 ] == 5.0 .AND. t[ "text" ] == "tolerance text" .AND. Abs( t[ "direction" ][ 2 ] - 1.0 ) < 0.0000000001 .AND. t[ "dimension_style_name" ] == "DIMSTYLE1", "tolerance: test_tolerance_full" )
   t := Etl_WithText( V( 0.0, 0.0, 0.0 ), "test" ) ; Ent_Translate( t, V( 5.0, 10.0, 0.0 ) ) ; Chk( t[ "insertion_point" ][ 1 ] == 5.0 .AND. t[ "insertion_point" ][ 2 ] == 10.0, "tolerance: test_tolerance_translate" )
   Chk( Ent_EntityType( Etl_New() ) == "TOLERANCE" .AND. Etl_EntityName() == "TOLERANCE", "tolerance: test_tolerance_entity_type" )
   c := Etl_PositionTolerance( 0.5, "A", "B", NIL ) ; Chk( Has( c, "p" ) .AND. Has( c, "0.5" ) .AND. Has( c, "A" ) .AND. Has( c, "B" ), "tolerance: test_position_tolerance" )
   c := Etl_FlatnessTolerance( 0.1 ) ; Chk( Has( c, "c" ) .AND. Has( c, "0.1" ), "tolerance: test_flatness_tolerance" )
   c := Etl_PerpendicularityTolerance( 0.05, "A" ) ; Chk( Has( c, "j" ) .AND. Has( c, "0.05" ) .AND. Has( c, "A" ), "tolerance: test_perpendicularity_tolerance" )
   Chk( Etl_MultiLine( { "line1", "line2", "line3" } ) == "line1^Jline2^Jline3", "tolerance: test_multi_line" )
   t := Etl_New() ; t[ "text" ] := "line1^Jline2^Jline3" ; l := Etl_TextLines( t )
   Chk( Len( l ) == 3 .AND. l[ 1 ] == "line1" .AND. l[ 2 ] == "line2" .AND. l[ 3 ] == "line3", "tolerance: test_text_lines" )
   t := Etl_New() ; t[ "text" ] := "line1" ; c := Etl_LineCount( t ) == 1 ; t[ "text" ] := "line1^Jline2" ; c := c .AND. Etl_LineCount( t ) == 2 ; t[ "text" ] := "line1^Jline2^Jline3"
   Chk( c .AND. Etl_LineCount( t ) == 3, "tolerance: test_line_count" )
   t := Etl_New() ; Etl_PointToward( t, V( 0.0, 10.0, 0.0 ) ) ; Chk( Abs( t[ "direction" ][ 2 ] - 1.0 ) < 0.0000000001 .AND. Abs( t[ "direction" ][ 1 ] ) < 0.0000000001, "tolerance: test_point_toward" )
   t := Etl_WithText( V( 10.0, 10.0, 0.0 ), "test text" ) ; bb := Ent_BoundingBox( t ) ; Chk( bb[ 1 ][ 1 ] <= 10.0 .AND. bb[ 2 ][ 1 ] >= 10.0, "tolerance: test_bounding_box" )
   c := Etl_CylindricityTolerance( 0.02 ) ; Chk( Has( c, "e" ) .AND. Has( c, "0.02" ), "tolerance: test_cylindricity_tolerance" )
   Chk( Has( Etl_RunoutTolerance( 0.1, "A", .F. ), "r" ) .AND. Has( Etl_RunoutTolerance( 0.1, "A", .T. ), "t" ), "tolerance: test_runout_tolerance" )
   // [extra]
   Chk( Etl_FlatnessTolerance( 1.0 ) == "{\Fgdt;c}%%v1%%v%%v%%v%%v" .AND. Etl_PositionTolerance( 0.25, NIL, NIL, NIL ) == "{\Fgdt;p}%%v0.25%%v%%v%%v%%v", "[extra] tolerance: formato exacto Rust ({} de f64)" )
   t := Etl_New() ; Etl_Rotate( t, OCX_PI / 2.0 ) ; Chk( Abs( t[ "direction" ][ 2 ] - 1.0 ) < 0.000000001 .AND. Abs( Etl_RotationAngle( t ) - OCX_PI / 2.0 ) < 0.000000001, "[extra] tolerance: rotate y rotation_angle" )
   t := Etl_New() ; Ent_ApplyTransform( t, Tf_FromScale( 2.0 ) ) ; Chk( Abs( t[ "text_height" ] - 0.36 ) < 0.000000001 .AND. Abs( t[ "dimension_gap" ] - 0.18 ) < 0.000000001, "[extra] tolerance: transform escala alturas" )
RETURN
