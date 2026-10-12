/* Port de tests: mline.rs (28) + [extra] */
#include "ocx.ch"
STATIC FUNCTION V( x, y, z ) ; RETURN Vc3_New( x, y, z )
STATIC FUNCTION Nr( a, b ) ; RETURN Abs( a - b ) < 0.0000000001
PROCEDURE T_CodecMline()
   LOCAL m, e, p, a, v, g, b, st
   m := Eml_New() ; Chk( m[ "justification" ] == 1 .AND. m[ "scale_factor" ] == 1.0 .AND. Eml_VertexCount( m ) == 0 .AND. ! Eml_IsClosed( m ), "mline: test_mline_creation" )
   m := Eml_New() ; m[ "flags" ] := hb_bitOr( MLF_CLOSED, MLF_NO_START_CAPS ) ; a := Eml_SerializedFlags( m ) == 6
   m := Eml_FromPoints( { Vc3_Zero(), V( 1.0, 0.0, 0.0 ) } ) ; m[ "flags" ] := hb_bitAnd( m[ "flags" ], hb_bitNot( MLF_HAS_VERTICES ) )
   Chk( a .AND. Eml_SerializedFlags( m ) == 1, "mline: serialized_flags_derive_vertex_presence" )
   p := { V( 0.0, 0.0, 0.0 ), V( 10.0, 0.0, 0.0 ), V( 10.0, 10.0, 0.0 ) }
   m := Eml_FromPoints( p ) ; Chk( Eml_VertexCount( m ) == 3 .AND. Vc3_Eq( m[ "start_point" ], V( 0.0, 0.0, 0.0 ) ), "mline: test_mline_from_points" )
   m := Eml_FromPoints( { V( 0.0, 0.0, 0.0 ), V( 10.0, 0.0, 0.0 ), V( 10.0, 10.0, 0.0 ), V( 0.0, 10.0, 0.0 ) } ) ; a := ! Eml_IsClosed( m ) ; Eml_Close( m ) ; a := a .AND. Eml_IsClosed( m ) ; Eml_Open( m )
   Chk( a .AND. ! Eml_IsClosed( m ), "mline: test_mline_closed" )
   Chk( Nr( Eml_Length( Eml_FromPoints( p ) ), 20.0 ), "mline: test_mline_length" )
   Chk( Nr( Eml_Length( Eml_ClosedFromPoints( { V( 0.0, 0.0, 0.0 ), V( 10.0, 0.0, 0.0 ), V( 10.0, 10.0, 0.0 ), V( 0.0, 10.0, 0.0 ) } ) ), 40.0 ), "mline: test_mline_length_closed" )
   m := Eml_FromPoints( { V( 0.0, 0.0, 0.0 ), V( 10.0, 0.0, 0.0 ) } ) ; Ent_Translate( m, V( 5.0, 5.0, 0.0 ) )
   Chk( Vc3_Eq( m[ "start_point" ], V( 5.0, 5.0, 0.0 ) ) .AND. Vc3_Eq( m[ "vertices" ][ 1 ][ "position" ], V( 5.0, 5.0, 0.0 ) ) .AND. Vc3_Eq( m[ "vertices" ][ 2 ][ "position" ], V( 15.0, 5.0, 0.0 ) ), "mline: test_mline_translate" )
   m := Eml_FromPoints( { V( 0.0, 0.0, 0.0 ), V( 10.0, 5.0, 0.0 ), V( 5.0, 10.0, 0.0 ) } ) ; b := Eml_BoundingBoxOpt( m )
   Chk( Vc3_Eq( b[ 1 ], V( 0.0, 0.0, 0.0 ) ) .AND. Vc3_Eq( b[ 2 ], V( 10.0, 10.0, 0.0 ) ), "mline: test_mline_bounding_box" )
   Chk( Mlj_From( 0 ) == 0 .AND. Mlj_From( 1 ) == 1 .AND. Mlj_From( 2 ) == 2, "mline: test_mline_justification" )
   m := Eml_New() ; a := hb_bitAnd( m[ "flags" ], MLF_CLOSED ) == 0 ; Eml_Close( m ) ; a := a .AND. hb_bitAnd( m[ "flags" ], MLF_CLOSED ) != 0
   Eml_SuppressStartCaps( m ) ; a := a .AND. hb_bitAnd( m[ "flags" ], MLF_NO_START_CAPS ) != 0 ; Eml_SuppressEndCaps( m )
   Chk( a .AND. hb_bitAnd( m[ "flags" ], MLF_NO_END_CAPS ) != 0, "mline: test_mline_flags" )
   st := Mls_New( "Custom" ) ; Chk( st[ "name" ] == "Custom" .AND. Mls_ElementCount( st ) == 0 .AND. Nr( st[ "start_angle" ], OCX_PI / 2.0 ) .AND. Nr( st[ "end_angle" ], OCX_PI / 2.0 ), "mline: test_mlinestyle_creation" )
   st := Mls_Standard() ; Chk( st[ "name" ] == "Standard" .AND. Mls_ElementCount( st ) == 2 .AND. st[ "elements" ][ 1 ][ "offset" ] == 0.5 .AND. st[ "elements" ][ 2 ][ "offset" ] == -0.5, "mline: test_mlinestyle_standard" )
   st := Mls_New( "Wide" ) ; Mls_AddElement( st, Mle_New( 2.0 ) ) ; Mls_AddElement( st, Mle_New( 0.0 ) ) ; Mls_AddElement( st, Mle_New( -2.0 ) ) ; Chk( Nr( Mls_TotalWidth( st ), 4.0 ), "mline: test_mlinestyle_total_width" )
   st := Mls_New( "Filled" ) ; a := ! Mls_IsFillOn( st ) ; Mls_SetFillOn( st, .T. ) ; a := a .AND. Mls_IsFillOn( st ) ; Mls_SetFillOn( st, .F. ) ; Chk( a .AND. ! Mls_IsFillOn( st ), "mline: test_mlinestyle_fill" )
   st := Mls_New( "Joints" ) ; a := ! Mls_DisplaysJoints( st ) ; Mls_SetDisplayJoints( st, .T. ) ; Chk( a .AND. Mls_DisplaysJoints( st ), "mline: test_mlinestyle_joints" )
   st := Mls_New( "Unsorted" ) ; Mls_AddElement( st, Mle_New( 1.0 ) ) ; Mls_AddElement( st, Mle_New( -1.0 ) ) ; Mls_AddElement( st, Mle_New( 0.0 ) ) ; Mls_SortElements( st )
   Chk( st[ "elements" ][ 1 ][ "offset" ] == -1.0 .AND. st[ "elements" ][ 2 ][ "offset" ] == 0.0 .AND. st[ "elements" ][ 3 ][ "offset" ] == 1.0, "mline: test_mlinestyle_sort_elements" )
   v := Mlv_New( V( 5.0, 5.0, 0.0 ) ) ; a := Vc3_Eq( v[ "position" ], V( 5.0, 5.0, 0.0 ) ) .AND. Len( v[ "segments" ] ) == 0 ; Mlv_InitSegments( v, 3 ) ; Chk( a .AND. Len( v[ "segments" ] ) == 3, "mline: test_mline_vertex" )
   g := Mlg_New() ; a := Empty( g[ "parameters" ] ) .AND. Empty( g[ "area_fill_parameters" ] ) ; Mlg_AddParameter( g, 1.0 ) ; Mlg_AddParameter( g, 2.0 ) ; Mlg_AddAreaFillParameter( g, 0.5 )
   Chk( a .AND. Len( g[ "parameters" ] ) == 2 .AND. Len( g[ "area_fill_parameters" ] ) == 1, "mline: test_mline_segment" )
   b := Mlb_New() ; b := Mlb_Vertex( b, V( 0.0, 0.0, 0.0 ) ) ; b := Mlb_Vertex( b, V( 10.0, 0.0, 0.0 ) ) ; b := Mlb_Vertex( b, V( 10.0, 10.0, 0.0 ) ) ; b := Mlb_Scale( b, 2.0 ) ; b := Mlb_Justification( b, 0 ) ; b := Mlb_StyleName( b, "Custom" ) ; b := Mlb_Closed( b )
   m := Mlb_Build( b ) ; Chk( Eml_VertexCount( m ) == 3 .AND. m[ "scale_factor" ] == 2.0 .AND. m[ "justification" ] == 0 .AND. m[ "style_name" ] == "Custom" .AND. Eml_IsClosed( m ), "mline: test_mline_builder" )
   m := Eml_FromPoints( p ) ; Eml_Reverse( m )
   Chk( Vc3_Eq( m[ "start_point" ], V( 10.0, 10.0, 0.0 ) ) .AND. Vc3_Eq( m[ "vertices" ][ 1 ][ "position" ], V( 10.0, 10.0, 0.0 ) ) .AND. Vc3_Eq( m[ "vertices" ][ 2 ][ "position" ], V( 10.0, 0.0, 0.0 ) ) .AND. Vc3_Eq( m[ "vertices" ][ 3 ][ "position" ], V( 0.0, 0.0, 0.0 ) ), "mline: test_mline_reverse" )
   e := Mle_WithColor( 0.5, Cl_Index( 1 ) ) ; Chk( e[ "offset" ] == 0.5 .AND. hb_ValToExp( e[ "color" ] ) == hb_ValToExp( Cl_Index( 1 ) ), "mline: test_mlinestyle_element" )
   // [extra]
   m := Eml_FromPoints( p ) ; Chk( Nr( m[ "vertices" ][ 1 ][ "direction" ][ 1 ], 1.0 ) .AND. Nr( m[ "vertices" ][ 1 ][ "miter" ][ 2 ], 1.0 ) .AND. Nr( m[ "vertices" ][ 3 ][ "direction" ][ 2 ], 1.0 ), "[extra] mline: rebuild_geometry direccion y miter" )
   m := Eml_FromPoints( p ) ; Chk( ! Eml_AddVertex( m, V( 10.0, 10.0, 0.0 ) ) == NIL .AND. Eml_VertexCount( m ) == 3 .AND. ! Eml_RemoveVertex( Eml_FromPoints( { V( 0.0, 0.0, 0.0 ), V( 1.0, 0.0, 0.0 ) } ), 0 ), "[extra] mline: add_vertex duplicado y remove_vertex minimo 2" )
   m := Eml_FromPoints( p ) ; Eml_InsertVertex( m, 1, V( 5.0, 0.0, 0.0 ) ) ; a := Eml_VertexCount( m ) == 4 .AND. m[ "vertices" ][ 2 ][ "position" ][ 1 ] == 5.0 ; Eml_RemoveVertex( m, 1 ) ; Chk( a .AND. Eml_VertexCount( m ) == 3 .AND. m[ "vertices" ][ 2 ][ "position" ][ 1 ] == 10.0, "[extra] mline: insert/remove vertex" )
   m := Eml_FromPoints( p ) ; Ent_ApplyTransform( m, Tf_FromScale( 2.0 ) ) ; Chk( m[ "vertices" ][ 2 ][ "position" ][ 1 ] == 20.0 .AND. Nr( m[ "vertices" ][ 2 ][ "direction" ][ 2 ], 1.0 ), "[extra] mline: transform" )
RETURN
