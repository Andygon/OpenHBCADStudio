/* dimension.rs no tiene tests. Port de los 2 tests de transform.rs sobre dimensiones + test de hatch mirror (transform.rs) + [extra] */
#include "ocx.ch"
STATIC FUNCTION Near( a, b ) ; RETURN Vc3_Distance( a, b ) < 0.000000001
STATIC FUNCTION V( x, y, z ) ; RETURN Vc3_New( x, y, z )
STATIC FUNCTION Ap( a, b ) ; RETURN Abs( a - b ) < 0.000000001
PROCEDURE T_CodecDimension()
   LOCAL d, t, plane, h, p, ed, arc, l1, l2, nA, sx, sy, ex, ey, c, lp, o
   // test_transform_linear_dimension_rotates_out_of_world_plane
   d := Dli_Horizontal( Vc3_Zero(), V( 10.0, 0.0, 0.0 ) ) ; d[ "definition_point" ] := V( 0.0, 5.0, 0.0 ) ; d[ "base" ][ "definition_point" ] := d[ "definition_point" ]
   Ent_ApplyTransform( d, Tf_FromRotation( Vc3_UnitY(), OCX_PI / 2.0 ) )
   Chk( Near( d[ "second_point" ], V( 0.0, 0.0, -10.0 ) ) .AND. Near( d[ "base" ][ "normal" ], Vc3_UnitX() ) .AND. Ap( Dli_Measurement( d ), 10.0 ) .AND. Ap( d[ "base" ][ "actual_measurement" ], 10.0 ), "dimension: test_transform_linear_dimension_rotates_out_of_world_plane" )
   // test_transform_linear_dimension_mirrors_about_offset_plane
   d := Dli_Horizontal( Vc3_Zero(), V( 10.0, 0.0, 0.0 ) ) ; d[ "definition_point" ] := V( 0.0, 5.0, 0.0 ) ; d[ "base" ][ "definition_point" ] := d[ "definition_point" ]
   plane := V( 0.0, 2.0, 0.0 )
   t := Tf_Then( Tf_Then( Tf_FromTranslation( Vc3_Neg( plane ) ), Tf_FromScaling( V( 1.0, -1.0, 1.0 ) ) ), Tf_FromTranslation( plane ) )
   Ent_ApplyTransform( d, t )
   Chk( Near( d[ "definition_point" ], V( 0.0, -1.0, 0.0 ) ) .AND. Ap( Dli_Measurement( d ), 10.0 ) .AND. Ap( d[ "base" ][ "actual_measurement" ], 10.0 ), "dimension: test_transform_linear_dimension_mirrors_about_offset_plane" )
   // test_mirror_hatch_arc_edge_stays_continuous (transform.rs)
   p := Bpa_New()
   Bpa_AddEdge( p, Bed_Line( Vc2_New( 0.0, -1.0 ), Vc2_New( 2.0, 0.0 ) ) )
   Bpa_AddEdge( p, Bed_CircularArc( Vc2_New( 1.0, 0.0 ), 1.0, 0.0, OCX_PI, .T. ) )
   Bpa_AddEdge( p, Bed_Line( Vc2_New( 0.0, 0.0 ), Vc2_New( 0.0, -1.0 ) ) )
   h := Ehh_New() ; Ehh_AddPath( h, p )
   Ent_ApplyTransform( h, Tf_FromScaling( V( -1.0, 1.0, 1.0 ) ) )
   l1 := h[ "paths" ][ 1 ][ "edges" ][ 1 ] ; arc := h[ "paths" ][ 1 ][ "edges" ][ 2 ] ; l2 := h[ "paths" ][ 1 ][ "edges" ][ 3 ]
   nA := iif( arc[ "counter_clockwise" ], arc[ "start_angle" ], -arc[ "start_angle" ] )
   sx := arc[ "center" ][ 1 ] + arc[ "radius" ] * OCX_COS( nA ) ; sy := arc[ "center" ][ 2 ] + arc[ "radius" ] * OCX_SIN( nA )
   nA := iif( arc[ "counter_clockwise" ], arc[ "end_angle" ], -arc[ "end_angle" ] )
   ex := arc[ "center" ][ 1 ] + arc[ "radius" ] * OCX_COS( nA ) ; ey := arc[ "center" ][ 2 ] + arc[ "radius" ] * OCX_SIN( nA )
   Chk( ! arc[ "counter_clockwise" ] .AND. Abs( sx - l1[ "end" ][ 1 ] ) < 0.000000001 .AND. Abs( sy - l1[ "end" ][ 2 ] ) < 0.000000001 .AND. Abs( ex - l2[ "start" ][ 1 ] ) < 0.000000001 .AND. Abs( ey - l2[ "start" ][ 2 ] ) < 0.000000001, "hatch: test_mirror_hatch_arc_edge_stays_continuous (continuidad y flag; falta el chequeo del punto medio)" )
   // [extra]
   d := Dal_New( Vc3_Zero(), V( 3.0, 4.0, 0.0 ) ) ; Dal_SetOffset( d, 2.0 )
   Chk( Ap( Dal_Measurement( d ), 5.0 ) .AND. Ap( Dal_Offset( d ), 2.0 ) .AND. Ent_EntityType( d ) == "DIMENSION_ALIGNED", "[extra] dimension: aligned measurement y offset" )
   d := Dli_Vertical( Vc3_Zero(), V( 3.0, 4.0, 0.0 ) ) ; Dli_SetOffset( d, 1.0 )
   Chk( Ap( Dli_Measurement( d ), 4.0 ) .AND. Near( d[ "definition_point" ], V( 2.0, 4.0, 0.0 ) ), "[extra] dimension: linear vertical" )
   Chk( Ap( Dra_Measurement( Dra_New( Vc3_Zero(), V( 0.0, 2.0, 0.0 ) ) ), 2.0 ) .AND. Near( Ddi_Center( Ddi_New( V( -1.0, 0.0, 0.0 ), V( 1.0, 0.0, 0.0 ) ) ), Vc3_Zero() ), "[extra] dimension: radius y diameter" )
   d := Da3_New( Vc3_Zero(), V( 1.0, 0.0, 0.0 ), V( 0.0, 1.0, 0.0 ) ) ; d[ "definition_point" ] := V( 1.0, 1.0, 0.0 )
   Chk( Ap( Da3_MeasurementDegrees( d ), 90.0 ) .AND. Ap( d[ "base" ][ "actual_measurement" ], 90.0 ), "[extra] dimension: angular 3 puntos" )
   d := Da3_New( Vc3_Zero(), V( 1.0, 0.0, 0.0 ), V( 0.0, 1.0, 0.0 ) ) ; d[ "definition_point" ] := V( -1.0, -1.0, 0.0 )
   Chk( Ap( Da3_MeasurementDegrees( d ), 90.0 ), "[extra] dimension: angular 3 puntos sector opuesto" )
   d := Da2_New( Vc3_Zero(), V( 1.0, 0.0, 0.0 ), V( 0.0, 1.0, 0.0 ) ) ; d[ "dimension_arc" ] := V( 1.0, 1.0, 0.0 )
   Chk( Ap( Da2_MeasurementDegrees( d ), 90.0 ), "[extra] dimension: angular 2 lineas" )
   o := Dor_XOrdinate( V( 3.0, 4.0, 0.0 ), V( 3.0, 8.0, 0.0 ) )
   Chk( Ap( Dor_Measurement( o ), 3.0 ) .AND. Ap( o[ "base" ][ "actual_measurement" ], 3.0 ), "[extra] dimension: ordinate x" )
   lp := Dor_LeaderPolyline( o, 0.5, 0.25, NIL )
   Chk( Len( lp ) == 4 .AND. Near( lp[ 4 ], V( 3.0, 8.0, 0.0 ) ) .AND. Near( lp[ 1 ], V( 3.0, 4.25, 0.0 ) ), "[extra] dimension: ordinate leader_polyline" )
   arc := Dar_Default() ; arc[ "center_point" ] := Vc3_Zero() ; arc[ "first_extension_point" ] := V( 2.0, 0.0, 0.0 ) ; arc[ "second_extension_point" ] := V( 0.0, 2.0, 0.0 )
   Chk( Ap( Dar_Measurement( arc ), OCX_PI ), "[extra] dimension: arc length desde puntos" )
   c := Dlr_Default() ; c[ "chord_point" ] := V( 3.0, 4.0, 0.0 ) ; Ent_Translate( c, V( 1.0, 1.0, 0.0 ) )
   Chk( Near( c[ "chord_point" ], V( 4.0, 5.0, 0.0 ) ) .AND. Near( c[ "base" ][ "definition_point" ], V( 1.0, 1.0, 0.0 ) ), "[extra] dimension: translate large radial" )
   d := Dli_Horizontal( Vc3_Zero(), V( 10.0, 0.0, 0.0 ) ) ; ed := Ent_Clone( d ) ; ed[ "common" ][ "layer" ] := "X"
   Chk( ed[ "base" ][ "common" ][ "layer" ] == "X" .AND. d[ "common" ][ "layer" ] == "0", "[extra] Ent_Clone: dimension mantiene common == base.common" )
   d := Dal_New( Vc3_Zero(), V( 1.0, 0.0, 0.0 ) ) ; Dmb_SetTextOverride( d[ "base" ], "<>mm" )
   Chk( Dmb_TextOverride( d[ "base" ] ) == "<>mm" .AND. Dmb_TextOverride( Dmb_New( DMT_LINEAR ) ) == NIL, "[extra] dimension: text_override" )
RETURN
