/* Port de tests: multileader.rs (17) + [extra] */
#include "ocx.ch"
STATIC FUNCTION V( x, y, z ) ; RETURN Vc3_New( x, y, z )
STATIC FUNCTION Nr( a, b ) ; RETURN Abs( a - b ) < 0.0000000001
PROCEDURE T_CodecMultileader()
   LOCAL m, r, l, bb, pts, a, f, at, ctx, b
   m := Emu_New() ; Chk( m[ "content_type" ] == MLC_MTEXT .AND. m[ "enable_landing" ] .AND. m[ "enable_dogleg" ] .AND. Emu_LeaderRootCount( m ) == 0, "multileader: test_multileader_creation" )
   pts := { V( 0.0, 0.0, 0.0 ), V( 5.0, 5.0, 0.0 ) } ; m := Emu_WithText( "Note", V( 10.0, 10.0, 0.0 ), pts )
   Chk( m[ "content_type" ] == MLC_MTEXT .AND. Emu_Text( m ) == "Note" .AND. Emu_LeaderRootCount( m ) == 1 .AND. Emu_TotalLeaderLineCount( m ) == 1, "multileader: test_multileader_with_text" )
   m := Emu_New() ; r := Emu_AddLeaderRoot( m ) ; Lrt_CreateLine( r, { Vc3_Zero(), V( 1.0, 1.0, 0.0 ) } ) ; Lrt_CreateLine( r, { V( 0.0, 1.0, 0.0 ), V( 1.0, 1.0, 0.0 ) } )
   Chk( Emu_LeaderRootCount( m ) == 1 .AND. Emu_TotalLeaderLineCount( m ) == 2, "multileader: test_multileader_add_leader_root" )
   l := Lln_New( 0 ) ; Lln_AddPoint( l, V( 0.0, 0.0, 0.0 ) ) ; Lln_AddPoint( l, V( 3.0, 4.0, 0.0 ) )
   Chk( Lln_PointCount( l ) == 2 .AND. Vc3_Eq( Lln_StartPoint( l ), V( 0.0, 0.0, 0.0 ) ) .AND. Vc3_Eq( Lln_EndPoint( l ), V( 3.0, 4.0, 0.0 ) ) .AND. Nr( Lln_Length( l ), 5.0 ), "multileader: test_leader_line" )
   m := Emu_WithText( "Note", V( 10.0, 10.0, 0.0 ), { Vc3_Zero(), V( 5.0, 5.0, 0.0 ) } ) ; Ent_Translate( m, V( 5.0, 5.0, 0.0 ) ) ; l := m[ "context" ][ "leader_roots" ][ 1 ][ "lines" ][ 1 ]
   Chk( Vc3_Eq( m[ "context" ][ "text_location" ], V( 15.0, 15.0, 0.0 ) ) .AND. Vc3_Eq( l[ "points" ][ 1 ], V( 5.0, 5.0, 0.0 ) ) .AND. Vc3_Eq( l[ "points" ][ 2 ], V( 10.0, 10.0, 0.0 ) ), "multileader: test_multileader_translate" )
   m := Emu_WithText( "Note", V( 10.0, 10.0, 0.0 ), { V( 0.0, 0.0, 0.0 ), V( 5.0, 5.0, 0.0 ) } ) ; bb := Emu_BoundingBoxOpt( m )
   Chk( Vc3_Eq( bb[ 1 ], V( 0.0, 0.0, 0.0 ) ) .AND. Vc3_Eq( bb[ 2 ], V( 10.0, 10.0, 0.0 ) ), "multileader: test_multileader_bounding_box" )
   Chk( Mlc_From( 0 ) == MLC_NONE .AND. Mlc_From( 1 ) == MLC_BLOCK .AND. Mlc_From( 2 ) == MLC_MTEXT .AND. Mlc_From( 3 ) == MLC_TOLERANCE, "multileader: test_content_types" )
   Chk( Mpt_From( 0 ) == MPT_INVISIBLE .AND. Mpt_From( 1 ) == MPT_STRAIGHT_LINE_SEGMENTS .AND. Mpt_From( 2 ) == MPT_SPLINE, "multileader: test_path_types" )
   Chk( Tat_From( 0 ) == TAT_TOP_OF_TOP_LINE .AND. Tat_From( 2 ) == TAT_MIDDLE_OF_TEXT .AND. Tat_From( 9 ) == TAT_CENTER_OF_TEXT, "multileader: test_text_attachment_types" )
   b := Mub_Build( Mub_Scale( Mub_TextFrame( Mub_TextHeight( Mub_ArrowheadSize( Mub_LeaderLine( Mub_Text( Mub_New(), "Note", V( 10.0, 10.0, 0.0 ) ), { Vc3_Zero(), V( 5.0, 5.0, 0.0 ) } ), 0.25 ), 0.2 ), .T. ), 2.0 ) )
   Chk( Emu_Text( b ) == "Note" .AND. b[ "arrowhead_size" ] == 0.25 .AND. b[ "text_height" ] == 0.2 .AND. b[ "text_frame" ] .AND. b[ "scale_factor" ] == 2.0, "multileader: test_builder" )
   f := hb_bitOr( hb_bitOr( MPO_PATH_TYPE, MPO_LINE_COLOR ), MPO_TEXT_HEIGHT ) ; Chk( hb_bitAnd( f, MPO_PATH_TYPE ) != 0 .AND. hb_bitAnd( f, MPO_LINE_COLOR ) != 0 .AND. hb_bitAnd( f, MPO_TEXT_HEIGHT ) != 0 .AND. hb_bitAnd( f, MPO_ARROWHEAD ) == 0, "multileader: test_property_override_flags" )
   f := hb_bitOr( LLO_LINE_COLOR, LLO_ARROWHEAD ) ; Chk( hb_bitAnd( f, LLO_LINE_COLOR ) != 0 .AND. hb_bitAnd( f, LLO_ARROWHEAD ) != 0 .AND. hb_bitAnd( f, LLO_PATH_TYPE ) == 0, "multileader: test_leader_line_override_flags" )
   at := Bat_New( "Value" ) ; Chk( at[ "text" ] == "Value" .AND. at[ "index" ] == 0 .AND. at[ "width" ] == 0.0, "multileader: test_block_attribute" )
   ctx := Mac_New() ; Chk( ctx[ "scale_factor" ] == 1.0 .AND. ctx[ "text_height" ] == 0.18 .AND. ! ctx[ "has_text_contents" ] .AND. ! ctx[ "has_block_contents" ] .AND. Len( ctx[ "leader_roots" ] ) == 0, "multileader: test_annot_context_defaults" )
   // [extra]
   m := Emu_WithText( "N", V( 1.0, 1.0, 0.0 ), { V( 0.0, 0.0, 0.0 ), V( 5.0, 5.0, 0.0 ) } ) ; Ent_ApplyTransform( m, Tf_FromScale( 2.0 ) )
   Chk( Nr( m[ "text_height" ], 0.36 ) .AND. Nr( m[ "context" ][ "landing_gap" ], 0.18 ) .AND. m[ "context" ][ "leader_roots" ][ 1 ][ "lines" ][ 1 ][ "points" ][ 2 ][ 1 ] == 10.0, "[extra] multileader: transform escala alturas y puntos" )
   m := Emu_New() ; Emu_SetText( m, "T" ) ; a := Emu_Text( m ) == "T" ; m[ "content_type" ] := MLC_NONE ; Emu_SetText( m, "U" ) ; Chk( a .AND. Emu_Text( m ) == NIL .AND. Ent_EntityType( m ) == "MULTILEADER", "[extra] multileader: text/set_text segun content_type" )
   m := Emu_WithText( "N", V( 7.0, 7.0, 0.0 ), { V( 0.0, 0.0, 0.0 ), V( 5.0, 5.0, 0.0 ) } ) ; bb := Ent_BoundingBox( m ) ; Chk( bb[ 1 ][ 1 ] == 0.0 .AND. bb[ 2 ][ 1 ] == 7.0, "[extra] multileader: bounding_box del trait" )
RETURN
