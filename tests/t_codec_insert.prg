/* Port de tests: insert.rs (34 tests; se omite explode_from_document, que va con document) + [extra] */
#include "ocx.ch"
STATIC FUNCTION Ap( a, b ) ; RETURN Abs( a - b ) < 0.000001
STATIC FUNCTION Av( a, b ) ; RETURN Ap( a[1], b[1] ) .AND. Ap( a[2], b[2] ) .AND. Ap( a[3], b[3] )
STATIC FUNCTION Ins( n, v ) ; RETURN Ein_New( n, v )
STATIC FUNCTION Ln( a, b ) ; RETURN Eln_FromPoints( a, b )
STATIC FUNCTION V( x, y, z ) ; RETURN Vc3_New( x, y, z )
STATIC FUNCTION ArcPts( a )
   LOCAL mB := Mx3_ArbitraryAxis( a[ "normal" ] ), vC := Mx3_TransformPoint( mB, a[ "center" ] ), nE, nM, r := a[ "radius" ]
   nE := iif( a[ "end_angle" ] >= a[ "start_angle" ], a[ "end_angle" ], a[ "end_angle" ] + OCX_TAU )
   nM := a[ "start_angle" ] + ( nE - a[ "start_angle" ] ) * 0.5
RETURN { ;
  Vc3_Add( vC, Mx3_TransformPoint( mB, V( r * OCX_COS( a[ "start_angle" ] ), r * OCX_SIN( a[ "start_angle" ] ), 0.0 ) ) ), ;
  Vc3_Add( vC, Mx3_TransformPoint( mB, V( r * OCX_COS( nM ), r * OCX_SIN( nM ), 0.0 ) ) ), ;
  Vc3_Add( vC, Mx3_TransformPoint( mB, V( r * OCX_COS( a[ "end_angle" ] ), r * OCX_SIN( a[ "end_angle" ] ), 0.0 ) ) ) }
STATIC FUNCTION ElPts( e )
   LOCAL ml := Vc3_Length( e[ "major_axis" ] ), u := Vc3_Mul( e[ "major_axis" ], 1.0 / Max( ml, 0.000000000001 ) ), vv := Vc3_Cross( e[ "normal" ], u )
   LOCAL nm := ml * e[ "minor_axis_ratio" ], t1 := e[ "end_parameter" ], t0 := e[ "start_parameter" ], tm
   IF t1 <= t0 ; t1 += OCX_TAU ; ENDIF
   tm := t0 + ( t1 - t0 ) * 0.5
RETURN { ElP( e, u, vv, ml, nm, t0 ), ElP( e, u, vv, ml, nm, tm ), ElP( e, u, vv, ml, nm, t1 ) }
STATIC FUNCTION ElP( e, u, vv, ml, nm, t )
RETURN Vc3_Add( Vc3_Add( e[ "center" ], Vc3_Mul( u, ml * OCX_COS( t ) ) ), Vc3_Mul( vv, nm * OCX_SIN( t ) ) )
PROCEDURE T_CodecInsert()
   LOCAL i, r, l, a, e, c, p, q := OCX_PI / 2.0, s2 := 1.0 / Sqrt( 2.0 ), aB, pp, lOk
   i := Ins( "B", Vc3_Zero() ) ; i[ "row_count" ] := 65535 ; i[ "column_count" ] := 65535
   Chk( Ein_InstanceCount( i ) == 65535 * 65535 .AND. Ein_ArrayCapacityHint( i ) <= 4096, "insert: huge_minsert_does_not_prereserve_full_array" )
   r := Ein_Explode( Ins( "TestBlock", Vc3_Zero() ), {} ) ; Chk( Len( r ) == 0, "insert: explode_empty_block_returns_empty" )
   r := Ein_Explode( Ins( "TestBlock", Vc3_Zero() ), { Ebk_New( "TestBlock", Vc3_Zero() ), Ln( Vc3_Zero(), V( 1.0, 0.0, 0.0 ) ), Ead_New( "TAG", "prompt", "default" ), Ebe_New() } )
   Chk( Len( r ) == 1 .AND. r[ 1 ][ "_type" ] == "LINE", "insert: explode_skips_block_markers_and_attdefs" )
   r := Ein_Explode( Ins( "B", Vc3_Zero() ), { Ln( V( 0.0, 0.0, 0.0 ), V( 10.0, 0.0, 0.0 ) ) } )
   Chk( Len( r ) == 1 .AND. r[ 1 ][ "_type" ] == "LINE" .AND. Av( r[ 1 ][ "start" ], V( 0.0, 0.0, 0.0 ) ) .AND. Av( r[ 1 ][ "end" ], V( 10.0, 0.0, 0.0 ) ), "insert: explode_identity_insert_preserves_line" )
   r := Ein_Explode( Ins( "B", V( 10.0, 20.0, 0.0 ) ), { Ln( Vc3_Zero(), V( 5.0, 0.0, 0.0 ) ) } )
   Chk( Av( r[ 1 ][ "start" ], V( 10.0, 20.0, 0.0 ) ) .AND. Av( r[ 1 ][ "end" ], V( 15.0, 20.0, 0.0 ) ), "insert: explode_with_translation" )
   r := Ein_Explode( Ein_WithUniformScale( Ins( "B", Vc3_Zero() ), 3.0 ), { Ln( Vc3_Zero(), V( 1.0, 0.0, 0.0 ) ) } )
   Chk( Av( r[ 1 ][ "end" ], V( 3.0, 0.0, 0.0 ) ), "insert: explode_with_uniform_scale" )
   r := Ein_Explode( Ein_WithRotation( Ins( "B", Vc3_Zero() ), q ), { Ln( Vc3_Zero(), V( 1.0, 0.0, 0.0 ) ) } )
   Chk( Av( r[ 1 ][ "end" ], V( 0.0, 1.0, 0.0 ) ), "insert: explode_with_90_degree_rotation" )
   r := Ein_Explode( Ein_WithScale( Ins( "B", V( 5.0, 5.0, 0.0 ) ), 2.0, 3.0, 1.0 ), { Ln( Vc3_Zero(), V( 1.0, 1.0, 0.0 ) ) } )
   Chk( Av( r[ 1 ][ "start" ], V( 5.0, 5.0, 0.0 ) ) .AND. Av( r[ 1 ][ "end" ], V( 7.0, 8.0, 0.0 ) ), "insert: explode_with_scale_and_translation" )
   r := Ein_Explode( Ins( "B", Vc3_Zero() ), { Eci_FromCenterRadius( Vc3_Zero(), 5.0 ) } )
   Chk( Len( r ) == 1 .AND. r[ 1 ][ "_type" ] == "ELLIPSE" .AND. Ap( r[ 1 ][ "start_parameter" ], 0.0 ) .AND. Ap( r[ 1 ][ "end_parameter" ], OCX_TAU ), "insert: explode_circle_becomes_ellipse" )
   r := Ein_Explode( Ein_WithScale( Ins( "B", Vc3_Zero() ), 2.0, 1.0, 1.0 ), { Eci_FromCenterRadius( Vc3_Zero(), 1.0 ) } ) ; e := r[ 1 ]
   Chk( e[ "_type" ] == "ELLIPSE" .AND. Ap( Vc3_Length( e[ "major_axis" ] ), 2.0 ) .AND. Ap( Vc3_Length( e[ "major_axis" ] ) * e[ "minor_axis_ratio" ], 1.0 ) .AND. Ap( e[ "minor_axis_ratio" ], 0.5 ), "insert: explode_circle_with_non_uniform_scale" )
   r := Ein_Explode( Ein_WithScale( Ins( "B", Vc3_Zero() ), 1.0, 3.0, 1.0 ), { Eci_FromCenterRadius( Vc3_Zero(), 1.0 ) } ) ; e := r[ 1 ]
   Chk( e[ "_type" ] == "ELLIPSE" .AND. Ap( Vc3_Length( e[ "major_axis" ] ), 3.0 ) .AND. Ap( Vc3_Length( e[ "major_axis" ] ) * e[ "minor_axis_ratio" ], 1.0 ), "insert: explode_circle_non_uniform_scale_minor_becomes_major" )
   r := Ein_Explode( Ins( "B", Vc3_Zero() ), { Ear_FromCenterRadiusAngles( Vc3_Zero(), 5.0, 0.0, q ) } ) ; a := r[ 1 ]
   Chk( Len( r ) == 1 .AND. a[ "_type" ] == "ARC" .AND. Ap( a[ "radius" ], 5.0 ) .AND. Ap( a[ "start_angle" ], 0.0 ) .AND. Ap( a[ "end_angle" ], q ) .AND. Av( a[ "center" ], Vc3_Zero() ), "insert: explode_arc_identity" )
   r := Ein_Explode( Ins( "B", V( 100.0, 200.0, 0.0 ) ), { Ear_FromCenterRadiusAngles( Vc3_Zero(), 10.0, 0.0, OCX_PI ) } ) ; a := r[ 1 ]
   Chk( a[ "_type" ] == "ARC" .AND. Av( a[ "center" ], V( 100.0, 200.0, 0.0 ) ) .AND. Ap( a[ "radius" ], 10.0 ), "insert: explode_arc_with_translation" )
   r := Ein_Explode( Ein_WithUniformScale( Ins( "B", Vc3_Zero() ), 3.0 ), { Ear_FromCenterRadiusAngles( V( 1.0, 1.0, 0.0 ), 2.0, 0.0, q ) } ) ; a := r[ 1 ]
   Chk( a[ "_type" ] == "ARC" .AND. Ap( a[ "radius" ], 6.0 ) .AND. Av( a[ "center" ], V( 3.0, 3.0, 0.0 ) ), "insert: explode_arc_with_uniform_scale" )
   r := Ein_Explode( Ein_WithScale( Ins( "B", Vc3_Zero() ), 2.0, 1.0, 1.0 ), { Ear_FromCenterRadiusAngles( Vc3_Zero(), 5.0, 0.0, q ) } ) ; e := r[ 1 ]
   Chk( Len( r ) == 1 .AND. e[ "_type" ] == "ELLIPSE" .AND. Ap( Vc3_Length( e[ "major_axis" ] ), 10.0 ) .AND. Ap( Vc3_Length( e[ "major_axis" ] ) * e[ "minor_axis_ratio" ], 5.0 ) .AND. ! Eel_IsFull( e ), "insert: explode_arc_non_uniform_becomes_ellipse" )
   r := Ein_Explode( Ins( "B", V( 10.0, 0.0, 0.0 ) ), { Ln( Vc3_Zero(), V( 1.0, 0.0, 0.0 ) ), Eci_FromCenterRadius( Vc3_Zero(), 1.0 ), Ear_FromCenterRadiusAngles( Vc3_Zero(), 1.0, 0.0, OCX_PI ) } )
   Chk( Len( r ) == 3 .AND. r[ 1 ][ "_type" ] == "LINE" .AND. r[ 2 ][ "_type" ] == "ELLIPSE" .AND. r[ 3 ][ "_type" ] == "ARC", "insert: explode_multiple_entities" )
   l := Ln( Vc3_Zero(), V( 1.0, 0.0, 0.0 ) ) ; l[ "common" ][ "layer" ] := "0" ; i := Ins( "B", Vc3_Zero() ) ; i[ "common" ][ "layer" ] := "Walls"
   r := Ein_Explode( i, { l } ) ; Chk( r[ 1 ][ "common" ][ "layer" ] == "Walls", "insert: explode_layer_zero_inherits_insert_layer" )
   l := Ln( Vc3_Zero(), V( 1.0, 0.0, 0.0 ) ) ; l[ "common" ][ "layer" ] := "Hidden"
   r := Ein_Explode( i, { l } ) ; Chk( r[ 1 ][ "common" ][ "layer" ] == "Hidden", "insert: explode_named_layer_preserved" )
   l := Ln( Vc3_Zero(), V( 1.0, 0.0, 0.0 ) ) ; l[ "common" ][ "color" ] := Cl_ByBlock() ; i := Ins( "B", Vc3_Zero() ) ; i[ "common" ][ "color" ] := Cl_FromIndex( 1 )
   r := Ein_Explode( i, { l } ) ; Chk( Cl_Eq( r[ 1 ][ "common" ][ "color" ], Cl_FromIndex( 1 ) ), "insert: explode_byblock_color_inherits_insert_color" )
   l := Ln( Vc3_Zero(), V( 1.0, 0.0, 0.0 ) ) ; l[ "common" ][ "line_weight" ] := Lw_ByBlock() ; i := Ins( "B", Vc3_Zero() ) ; i[ "common" ][ "line_weight" ] := Lw_FromValue( 50 )
   r := Ein_Explode( i, { l } ) ; Chk( Lw_Eq( r[ 1 ][ "common" ][ "line_weight" ], Lw_FromValue( 50 ) ), "insert: explode_byblock_lineweight_inherits_insert_lineweight" )
   l := Ln( Vc3_Zero(), V( 1.0, 0.0, 0.0 ) ) ; l[ "common" ][ "color" ] := Cl_FromIndex( 3 ) ; i := Ins( "B", Vc3_Zero() ) ; i[ "common" ][ "color" ] := Cl_FromIndex( 1 )
   r := Ein_Explode( i, { l } ) ; Chk( Cl_Eq( r[ 1 ][ "common" ][ "color" ], Cl_FromIndex( 3 ) ), "insert: explode_non_byblock_color_preserved" )
   r := Ein_Explode( Ein_WithArray( Ins( "B", V( 0.0, 0.0, 0.0 ) ), 2, 3, 10.0, 20.0 ), { Ln( Vc3_Zero(), V( 1.0, 0.0, 0.0 ) ) } ) ; lOk := Len( r ) == 6
   FOR EACH e IN r ; lOk := lOk .AND. e[ "_type" ] == "LINE" ; NEXT
   Chk( lOk, "insert: explode_minsert_produces_array_copies" )
   r := Ein_Explode( Ein_WithArray( Ins( "B", V( 5.0, 0.0, 0.0 ) ), 2, 1, 10.0, 0.0 ), { Ln( Vc3_Zero(), Vc3_Zero() ) } )
   Chk( Len( r ) == 2 .AND. Av( r[ 1 ][ "start" ], V( 5.0, 0.0, 0.0 ) ) .AND. Av( r[ 2 ][ "start" ], V( 15.0, 0.0, 0.0 ) ), "insert: explode_minsert_positions_correct" )
   a := Ear_FromCenterRadiusAngles( Vc3_Zero(), 1.0, 0.0, OCX_PI ) ; a[ "common" ][ "layer" ] := "0" ; i := Ins( "B", Vc3_Zero() ) ; i[ "common" ][ "layer" ] := "Pipes"
   r := Ein_Explode( i, { a } ) ; Chk( r[ 1 ][ "common" ][ "layer" ] == "Pipes", "insert: explode_arc_layer_zero_inherits" )
   c := Eci_FromCenterRadius( Vc3_Zero(), 1.0 ) ; c[ "common" ][ "color" ] := Cl_ByBlock() ; i := Ins( "B", Vc3_Zero() ) ; i[ "common" ][ "color" ] := Cl_FromIndex( 5 )
   r := Ein_Explode( i, { c } ) ; Chk( r[ 1 ][ "_type" ] == "ELLIPSE" .AND. Cl_Eq( r[ 1 ][ "common" ][ "color" ], Cl_FromIndex( 5 ) ), "insert: explode_circle_byblock_color_inherits" )
   l := Ln( Vc3_Zero(), V( 1.0, 0.0, 0.0 ) ) ; l[ "common" ][ "layer" ] := "MyLayer"
   r := Ein_Explode( Ins( "B", Vc3_Zero() ), { l } ) ; Chk( r[ 1 ][ "common" ][ "layer" ] == "MyLayer", "insert: explode_preserves_entity_layer" )
   a := Ear_FromCenterRadiusAngles( Vc3_Zero(), 1.0, 0.0, OCX_PI ) ; a[ "common" ][ "layer" ] := "ArcLayer"
   r := Ein_Explode( Ins( "B", Vc3_Zero() ), { a } ) ; Chk( r[ 1 ][ "_type" ] == "ARC" .AND. r[ 1 ][ "common" ][ "layer" ] == "ArcLayer", "insert: explode_arc_preserves_layer" )
   a := Ear_FromCenterRadiusAngles( Vc3_Zero(), 1.0, 0.0, q )
   r := Ein_Explode( Ein_WithScale( Ins( "B", Vc3_Zero() ), -1.0, 1.0, 1.0 ), { a } ) ; pp := ArcPts( r[ 1 ] )
   Chk( r[ 1 ][ "_type" ] == "ARC" .AND. Av( pp[1], V( -1.0, 0.0, 0.0 ) ) .AND. Av( pp[3], V( 0.0, 1.0, 0.0 ) ) .AND. Av( pp[2], V( -s2, s2, 0.0 ) ), "insert: explode_arc_mirror_x_preserves_sweep_direction" )
   r := Ein_Explode( Ein_WithScale( Ins( "B", Vc3_Zero() ), 1.0, -1.0, 1.0 ), { a } ) ; pp := ArcPts( r[ 1 ] )
   Chk( Av( pp[1], V( 1.0, 0.0, 0.0 ) ) .AND. Av( pp[3], V( 0.0, -1.0, 0.0 ) ) .AND. Av( pp[2], V( s2, -s2, 0.0 ) ), "insert: explode_arc_mirror_y_preserves_sweep_direction" )
   r := Ein_Explode( Ein_WithScale( Ins( "B", Vc3_Zero() ), -1.0, -1.0, 1.0 ), { a } ) ; pp := ArcPts( r[ 1 ] )
   Chk( Av( r[ 1 ][ "normal" ], V( 0.0, 0.0, 1.0 ) ) .AND. Av( pp[1], V( -1.0, 0.0, 0.0 ) ) .AND. Av( pp[3], V( 0.0, -1.0, 0.0 ) ) .AND. Av( pp[2], V( -s2, -s2, 0.0 ) ), "insert: explode_arc_double_mirror_is_rotation" )
   aB := Ear_FromCenterRadiusAngles( V( 5.0, 3.0, 0.0 ), 1.0, 0.0, q )
   r := Ein_Explode( Ein_WithScale( Ins( "B", Vc3_Zero() ), -1.0, 1.0, 1.0 ), { aB } ) ; pp := ArcPts( r[ 1 ] )
   Chk( Av( r[ 1 ][ "normal" ], V( 0.0, 0.0, -1.0 ) ) .AND. Av( pp[1], V( -6.0, 3.0, 0.0 ) ) .AND. Av( pp[3], V( -5.0, 4.0, 0.0 ) ) .AND. Av( pp[2], V( -5.0 - s2, 3.0 + s2, 0.0 ) ), "insert: explode_arc_mirror_x_offset_center_position_preserved" )
   aB := Ear_FromCenterRadiusAngles( V( 2.0, 0.0, 0.0 ), 1.0, 0.0, q )
   r := Ein_Explode( Ein_WithScale( Ins( "B", V( 10.0, 20.0, 0.0 ) ), -1.0, 1.0, 1.0 ), { aB } ) ; pp := ArcPts( r[ 1 ] )
   Chk( Av( pp[1], V( 7.0, 20.0, 0.0 ) ) .AND. Av( pp[3], V( 8.0, 21.0, 0.0 ) ) .AND. Av( pp[2], V( 8.0 - s2, 20.0 + s2, 0.0 ) ), "insert: explode_arc_mirror_x_with_translation_position_preserved" )
   r := Ein_Explode( Ein_WithScale( Ins( "B", Vc3_Zero() ), -1.0, 1.0, 1.0 ), { a } )
   Chk( Av( r[ 1 ][ "normal" ], V( 0.0, 0.0, -1.0 ) ), "insert: explode_arc_mirror_flips_normal" )
   r := Ein_Explode( Ein_WithScale( Ins( "B", Vc3_Zero() ), -2.0, 1.0, 1.0 ), { a } ) ; e := r[ 1 ] ; pp := ElPts( e )
   Chk( e[ "_type" ] == "ELLIPSE" .AND. Av( pp[1], V( -2.0, 0.0, 0.0 ) ) .AND. Av( pp[2], V( -2.0 * s2, s2, 0.0 ) ) .AND. Av( pp[3], V( 0.0, 1.0, 0.0 ) ), "insert: explode_arc_mirror_x_nonuniform_to_ellipse" )
   // [extra]
   i := Ins( "B", V( 1.0, 2.0, 0.0 ) ) ; Ein_SetXScale( i, 0.0 ) ; Chk( Ein_XScale( i ) == 0.000000000001, "[extra] insert: guardia de escala cero" )
   i := Ein_WithArray( Ins( "B", V( 1.0, 2.0, 0.0 ) ), 2, 2, 3.0, 4.0 ) ; p := Ein_ArrayPoints( i )
   Chk( Len( p ) == 4 .AND. Av( p[ 4 ], V( 4.0, 6.0, 0.0 ) ) .AND. Ein_EntityType( i ) == "MINSERT" .AND. Ein_SubclassMarker( i ) == "AcDbMInsertBlock", "[extra] insert: array_points, entity_type, marker" )
   i := Ins( "B", V( 1.0, 2.0, 0.0 ) ) ; Ent_Translate( i, V( 5.0, 5.0, 0.0 ) )
   Chk( Av( i[ "insert_point" ], V( 6.0, 7.0, 0.0 ) ) .AND. Ein_UniformScale( i ) == 1.0 .AND. Ein_SubclassMarker( i ) == "AcDbBlockReference", "[extra] insert: translate, uniform_scale" )
   i := Ins( "B", V( 1.0, 0.0, 0.0 ) ) ; Ent_ApplyTransform( i, Tf_FromRotation( V( 0.0, 0.0, 1.0 ), q ) )
   Chk( Av( i[ "insert_point" ], V( 0.0, 1.0, 0.0 ) ) .AND. Ap( i[ "rotation" ], q ), "[extra] insert: transform rotacion" )
RETURN
