/* Port 1:1 de tests de opencadcodec types/transform.rs (16) y bounds.rs (5) */
#include "ocx.ch"
#define EPS 0.0000000001
STATIC FUNCTION Near3( r, x, y, z ) ; RETURN Abs( r[1] - x ) < EPS .AND. Abs( r[2] - y ) < EPS .AND. Abs( r[3] - z ) < EPS
PROCEDURE T_CodecTransform()
   LOCAL m, v, r, t1, t2, c, t, p, b, pts, PI := OCX_TAU / 2.0, b2
   v := { 1.0, 2.0, 3.0 }
   r := Mx3_TransformPoint( Mx3_Identity(), v )
   Chk( Near3( r, 1.0, 2.0, 3.0 ), "transform: test_matrix3_identity" )
   r := Mx3_TransformPoint( Mx3_RotationZ( PI / 2.0 ), { 1.0, 0.0, 0.0 } )
   Chk( Abs( r[1] ) < EPS .AND. Abs( r[2] - 1.0 ) < EPS, "transform: test_matrix3_rotation_z" )
   r := Mx4_TransformPoint( Mx4_Translation( 1.0, 2.0, 3.0 ), { 0.0, 0.0, 0.0 } )
   Chk( Near3( r, 1.0, 2.0, 3.0 ), "transform: test_matrix4_translation" )
   r := Mx4_TransformPoint( Mx4_Rotation( { 0.0, 0.0, 1.0 }, PI / 2.0 ), { 1.0, 0.0, 0.0 } )
   Chk( Abs( r[1] ) < EPS .AND. Abs( r[2] - 1.0 ) < EPS, "transform: test_matrix4_rotation" )
   t1 := Tf_FromTranslation( { 1.0, 0.0, 0.0 } ) ; t2 := Tf_FromTranslation( { 0.0, 1.0, 0.0 } )
   c := Tf_Then( t1, t2 ) ; r := Tf_Apply( c, { 0.0, 0.0, 0.0 } )
   Chk( Abs( r[1] - 1.0 ) < EPS .AND. Abs( r[2] - 1.0 ) < EPS, "transform: test_transform_composition" )
   Chk( Abs( Mx3_Determinant( Mx3_ArbitraryAxis( { 0.0, 0.0, 1.0 } ) ) - 1.0 ) < EPS, "transform: test_arbitrary_axis" )
   p := { 3.0, 5.0, 7.0 }
   Chk( Near3( Tf_Apply( Tf_FromMirrorX(), p ), -3.0, 5.0, 7.0 ), "transform: test_mirror_x" )
   Chk( Near3( Tf_Apply( Tf_FromMirrorY(), p ), 3.0, -5.0, 7.0 ), "transform: test_mirror_y" )
   Chk( Near3( Tf_Apply( Tf_FromMirrorZ(), p ), 3.0, 5.0, -7.0 ), "transform: test_mirror_z" )
   Chk( Near3( Tf_Apply( Tf_FromMirrorPlane( Vc3_Zero(), Vc3_UnitX() ), p ), -3.0, 5.0, 7.0 ), "transform: test_mirror_plane_through_origin" )
   Chk( Near3( Tf_Apply( Tf_FromMirrorPlane( { 2.0, 0.0, 0.0 }, Vc3_UnitX() ), { 5.0, 3.0, 1.0 } ), -1.0, 3.0, 1.0 ), "transform: test_mirror_plane_offset" )
   r := Tf_Apply( Tf_FromMirrorLine( { 0.0, 0.0, 0.0 }, { 1.0, 0.0, 0.0 } ), { 3.0, 5.0, 0.0 } )
   Chk( Abs( r[1] - 3.0 ) < EPS .AND. Abs( r[2] + 5.0 ) < EPS, "transform: test_mirror_line" )
   r := Tf_Apply( Tf_FromMirrorLine( Vc3_Zero(), { 1.0, 1.0, 0.0 } ), { 3.0, 0.0, 0.0 } )
   Chk( Abs( r[1] ) < EPS .AND. Abs( r[2] - 3.0 ) < EPS, "transform: test_mirror_line_diagonal" )
   t := Tf_FromMirrorPlane( { 1.0, 2.0, 3.0 }, { 1.0, 1.0, 0.0 } ) ; p := { 7.0, -2.0, 4.0 }
   r := Tf_Apply( t, Tf_Apply( t, p ) )
   Chk( Near3( r, p[1], p[2], p[3] ), "transform: test_mirror_is_involution" )
   Chk( Abs( Cd_NormalizeAngle( 0.0 ) ) < EPS .AND. Abs( Cd_NormalizeAngle( PI ) - PI ) < EPS .AND. Abs( Cd_NormalizeAngle( -PI / 2.0 ) - 3.0 * PI / 2.0 ) < EPS .AND. Abs( Cd_NormalizeAngle( 3.0 * PI ) - PI ) < EPS, "transform: test_normalize_angle" )
   // [extra]
   m := Mx3_Mul( Mx3_RotationZ( 0.7 ), Mx3_Inverse( Mx3_RotationZ( 0.7 ) ) )
   Chk( Abs( m[1][1] - 1.0 ) < 0.000000001 .AND. Abs( m[1][2] ) < 0.000000001 .AND. Abs( m[3][3] - 1.0 ) < 0.000000001 .AND. Mx3_Inverse( Mx3_Zero() ) == NIL, "[extra] matrix3: inversa y singular" )
   Chk( Tf_IsIdentity( Tf_Identity() ) .AND. ! Tf_IsIdentity( Tf_FromScale( 2.0 ) ), "[extra] transform: is_identity" )
   Chk( Near3( Tf_Apply( Tf_FromScalingWithOrigin( { 2.0, 2.0, 2.0 }, { 1.0, 1.0, 1.0 } ), { 2.0, 2.0, 2.0 } ), 3.0, 3.0, 3.0 ), "[extra] scaling_with_origin" )
   r := Cd_RotatePoint2d( { 2.0, 1.0 }, { 1.0, 1.0 }, PI / 2.0 )
   Chk( Abs( r[1] - 1.0 ) < EPS .AND. Abs( r[2] - 2.0 ) < EPS .AND. Cd_IsZeroAngle( 0.00000000001 ), "[extra] rotate_point_2d / is_zero_angle" )
   // bounds
   pts := { { 0.0, 0.0 }, { 10.0, 5.0 }, { -5.0, 3.0 } }
   b := Bb2_FromPoints( pts )
   Chk( Vc2_Eq( b[1], { -5.0, 0.0 } ) .AND. Vc2_Eq( b[2], { 10.0, 5.0 } ), "bounds: test_bbox2d_from_points" )
   b := Bb2_New( { 0.0, 0.0 }, { 10.0, 5.0 } )
   Chk( Bb2_Width( b ) == 10.0 .AND. Bb2_Height( b ) == 5.0 .AND. Vc2_Eq( Bb2_Center( b ), { 5.0, 2.5 } ), "bounds: test_bbox2d_dimensions" )
   b := Bb2_New( { 0.0, 0.0 }, { 10.0, 10.0 } )
   Chk( Bb2_Contains( b, { 5.0, 5.0 } ) .AND. ! Bb2_Contains( b, { 15.0, 5.0 } ), "bounds: test_bbox2d_contains" )
   b := Bb3_FromPoints( { { 0.0, 0.0, 0.0 }, { 10.0, 5.0, 3.0 }, { -5.0, 3.0, -2.0 } } )
   Chk( Vc3_Eq( b[1], { -5.0, 0.0, -2.0 } ) .AND. Vc3_Eq( b[2], { 10.0, 5.0, 3.0 } ), "bounds: test_bbox3d_from_points" )
   b := Bb3_New( { 0.0, 0.0, 0.0 }, { 10.0, 5.0, 3.0 } )
   Chk( Bb3_Width( b ) == 10.0 .AND. Bb3_Height( b ) == 5.0 .AND. Bb3_Depth( b ) == 3.0 .AND. Vc3_Eq( Bb3_Center( b ), { 5.0, 2.5, 1.5 } ), "bounds: test_bbox3d_dimensions" )
   // [extra]
   b2 := Bb2_Merge( Bb2_New( { 0.0, 0.0 }, { 1.0, 1.0 } ), Bb2_New( { -1.0, 0.5 }, { 0.5, 3.0 } ) )
   Chk( Vc2_Eq( b2[1], { -1.0, 0.0 } ) .AND. Vc2_Eq( b2[2], { 1.0, 3.0 } ) .AND. Bb2_FromPoints( {} ) == NIL .AND. Bb3_FromPoints( {} ) == NIL, "[extra] bounds: merge y vacio" )
   b := Bb3_OcsToWcs( Bb3_New( { 0.0, 0.0, 0.0 }, { 1.0, 2.0, 3.0 } ), { 0.0, 0.0, 1.0 } )
   Chk( Vc3_Eq( b[2], { 1.0, 2.0, 3.0 } ), "[extra] bounds: ocs_to_wcs con normal Z es identidad" )
   b := Bb3_OcsToWcs( Bb3_New( { 0.0, 0.0, 0.0 }, { 1.0, 2.0, 3.0 } ), { 1.0, 0.0, 0.0 } )
   Chk( Abs( ( b[2][1] - b[1][1] ) - 3.0 ) < 0.000000001 .AND. Abs( ( b[2][2] - b[1][2] ) - 1.0 ) < 0.000000001 .AND. Abs( ( b[2][3] - b[1][3] ) - 2.0 ) < 0.000000001, "[extra] bounds: ocs_to_wcs con normal X reordena ejes" )
RETURN
