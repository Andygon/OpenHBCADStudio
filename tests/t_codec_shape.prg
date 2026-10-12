/* Port de tests: shape.rs (22) + [extra] */
#include "ocx.ch"
STATIC FUNCTION V( x, y, z ) ; RETURN Vc3_New( x, y, z )
STATIC FUNCTION Nr( a, b ) ; RETURN Abs( a - b ) < 0.0000000001
PROCEDURE T_CodecShape()
   LOCAL s, d, a, m
   s := Esh_New() ; Chk( Vc3_Eq( s[ "insertion_point" ], Vc3_Zero() ) .AND. s[ "size" ] == 1.0 .AND. s[ "rotation" ] == 0.0 .AND. s[ "relative_x_scale" ] == 1.0 .AND. s[ "oblique_angle" ] == 0.0 .AND. Empty( s[ "shape_name" ] ), "shape: test_shape_creation" )
   s := Esh_WithName( V( 10.0, 20.0, 0.0 ), "ARROW", 5.0 ) ; Chk( s[ "insertion_point" ][ 1 ] == 10.0 .AND. s[ "shape_name" ] == "ARROW" .AND. s[ "size" ] == 5.0, "shape: test_with_name" )
   s := Esh_WithNumber( V( 10.0, 20.0, 0.0 ), 132, 5.0 ) ; Chk( s[ "shape_number" ] == 132 .AND. s[ "size" ] == 5.0, "shape: test_with_number" )
   s := Esh_WithStyle( V( 0.0, 0.0, 0.0 ), "ARROW", "MYSHAPES", 3.0, OCX_PI / 2.0 )
   Chk( s[ "shape_name" ] == "ARROW" .AND. s[ "style_name" ] == "MYSHAPES" .AND. s[ "size" ] == 3.0 .AND. Nr( s[ "rotation" ], OCX_PI / 2.0 ), "shape: test_with_style" )
   s := Esh_New() ; Esh_SetRotationDegrees( s, 45.0 ) ; Chk( Nr( Esh_RotationDegrees( s ), 45.0 ), "shape: test_rotation_degrees" )
   s := Esh_New() ; Esh_SetObliqueDegrees( s, 15.0 ) ; Chk( Nr( Esh_ObliqueDegrees( s ), 15.0 ), "shape: test_oblique_degrees" )
   s := Esh_New() ; s[ "size" ] := 10.0 ; s[ "relative_x_scale" ] := 0.5 ; Chk( Esh_Height( s ) == 10.0 .AND. Esh_Width( s ) == 5.0, "shape: test_width_height" )
   s := Esh_New() ; s[ "rotation" ] := 0.0 ; d := Esh_Direction( s ) ; a := Nr( d[ 1 ], 1.0 ) .AND. Abs( d[ 2 ] ) < 0.0000000001
   s[ "rotation" ] := OCX_PI / 2.0 ; d := Esh_Direction( s ) ; Chk( a .AND. Abs( d[ 1 ] ) < 0.0000000001 .AND. Nr( d[ 2 ], 1.0 ), "shape: test_direction" )
   s := Esh_New() ; Esh_Rotate( s, OCX_PI ) ; Chk( Nr( s[ "rotation" ], OCX_PI ), "shape: test_rotate" )
   s := Esh_New() ; s[ "size" ] := 10.0 ; Esh_Scale( s, 2.0 ) ; Chk( s[ "size" ] == 20.0, "shape: test_scale" )
   s := Esh_New() ; s[ "size" ] := 10.0 ; s[ "relative_x_scale" ] := 1.0 ; Esh_ScaleXy( s, 2.0, 0.5 ) ; Chk( s[ "size" ] == 5.0 .AND. s[ "relative_x_scale" ] == 4.0, "shape: test_scale_xy" )
   s := Esh_New() ; a := ! Esh_HasThickness( s ) ; s[ "thickness" ] := 5.0 ; Chk( a .AND. Esh_HasThickness( s ), "shape: test_has_thickness" )
   s := Esh_New() ; a := ! Esh_HasCustomNormal( s ) ; s[ "normal" ] := V( 1.0, 0.0, 0.0 ) ; Chk( a .AND. Esh_HasCustomNormal( s ), "shape: test_has_custom_normal" )
   s := Esh_New() ; a := ! Esh_IsOblique( s ) ; s[ "oblique_angle" ] := 0.25 ; Chk( a .AND. Esh_IsOblique( s ), "shape: test_is_oblique" )
   s := Esh_New() ; a := ! Esh_IsScaled( s ) ; s[ "relative_x_scale" ] := 1.5 ; Chk( a .AND. Esh_IsScaled( s ), "shape: test_is_scaled" )
   s := Esh_New() ; Ent_Translate( s, V( 10.0, 20.0, 30.0 ) ) ; Chk( Vc3_Eq( s[ "insertion_point" ], V( 10.0, 20.0, 30.0 ) ), "shape: test_translate" )
   Chk( Ent_EntityType( Esh_New() ) == "SHAPE", "shape: test_entity_type" )
   s := Esh_New() ; s[ "insertion_point" ] := V( 10.0, 10.0, 0.0 ) ; s[ "size" ] := 10.0 ; a := Esh_ApproximateBounds( s )
   Chk( a[ 1 ][ 1 ] == 5.0 .AND. a[ 1 ][ 2 ] == 5.0 .AND. a[ 2 ][ 1 ] == 15.0 .AND. a[ 2 ][ 2 ] == 15.0, "shape: test_approximate_bounds" )
   s := Esh_New() ; s[ "insertion_point" ] := V( 10.0, 20.0, 0.0 ) ; s[ "size" ] := 2.0 ; m := Esh_TransformMatrix( s ) ; Chk( m[ 10 ] == 10.0 .AND. m[ 11 ] == 20.0, "shape: test_transform_matrix" )
   Chk( SHP_ARROW == "ARROW" .AND. SHP_BOX == "BOX", "shape: test_standard_shapes" )
   Chk( GDS_POSITION == 114 .AND. GDS_PERPENDICULARITY == 118, "shape: test_gdt_shapes" )
   Chk( Esh_New()[ "size" ] == 1.0, "shape: test_default" )
   // [extra]
   s := Esh_New() ; s[ "rotation" ] := 0.5 ; Esh_Rotate( s, -1.0 ) ; Chk( Nr( s[ "rotation" ], OCX_TAU - 0.5 ), "[extra] shape: rotate normaliza a 0..TAU" )
   s := Esh_New() ; s[ "size" ] := 2.0 ; Ent_ApplyTransform( s, Tf_FromScale( 3.0 ) ) ; Chk( Nr( s[ "size" ], 6.0 ), "[extra] shape: transform escala size" )
   s := Esh_New() ; s[ "oblique_angle" ] := 0.2 ; Ent_MirrorX( s ) ; Chk( s[ "relative_x_scale" ] == -1.0 .AND. Nr( s[ "oblique_angle" ], -0.2 ), "[extra] shape: mirror niega escala x y oblicuo" )
RETURN
