/* Port de tests: point.rs (5), circle.rs (5), arc.rs (7) */
#include "ocx.ch"
STATIC FUNCTION Nr( a, b, nTol ) ; RETURN Abs( a - b ) < nTol
PROCEDURE T_CodecCurves()
   LOCAL p, c, a, oS, oE, nS, nE, bb
   // point
   p := Ept_New() ; Chk( Vc3_Eq( p[ "location" ], Vc3_Zero() ) .AND. Ent_EntityType( p ) == "POINT", "point: test_point_creation" )
   p := Ept_At( Vc3_New( 10.0, 20.0, 30.0 ) ) ; Chk( p[ "location" ][ 1 ] == 10.0 .AND. p[ "location" ][ 2 ] == 20.0 .AND. p[ "location" ][ 3 ] == 30.0, "point: test_point_at_location" )
   Chk( Vc3_Eq( Ept_FromCoords( 5.0, 10.0, 15.0 )[ "location" ], Vc3_New( 5.0, 10.0, 15.0 ) ), "point: test_point_from_coords" )
   p := Ept_At( Vc3_New( 1.0, 2.0, 3.0 ) ) ; Ent_Translate( p, Vc3_New( 10.0, 20.0, 30.0 ) )
   Chk( Vc3_Eq( p[ "location" ], Vc3_New( 11.0, 22.0, 33.0 ) ), "point: test_point_translate" )
   bb := Ent_BoundingBox( Ept_At( Vc3_New( 5.0, 10.0, 15.0 ) ) )
   Chk( Vc3_Eq( bb[ 1 ], Vc3_New( 5.0, 10.0, 15.0 ) ) .AND. Vc3_Eq( bb[ 2 ], Vc3_New( 5.0, 10.0, 15.0 ) ), "point: test_point_bounding_box" )
   // circle
   c := Eci_New() ; Chk( Vc3_Eq( c[ "center" ], Vc3_Zero() ) .AND. c[ "radius" ] == 1.0 .AND. Ent_EntityType( c ) == "CIRCLE", "circle: test_circle_creation" )
   c := Eci_FromCenterRadius( Vc3_New( 5.0, 5.0, 0.0 ), 10.0 ) ; Chk( Vc3_Eq( c[ "center" ], Vc3_New( 5.0, 5.0, 0.0 ) ) .AND. c[ "radius" ] == 10.0 .AND. Eci_Diameter( c ) == 20.0, "circle: test_circle_from_center_radius" )
   Chk( Nr( Eci_Area( Eci_FromCoords( 0.0, 0.0, 0.0, 5.0 ) ), 78.53981633974483, 0.0000000001 ), "circle: test_circle_area" )
   Chk( Nr( Eci_Circumference( Eci_FromCoords( 0.0, 0.0, 0.0, 5.0 ) ), 31.41592653589793, 0.0000000001 ), "circle: test_circle_circumference" )
   c := Eci_FromCoords( 0.0, 0.0, 0.0, 5.0 ) ; Ent_Translate( c, Vc3_New( 10.0, 20.0, 30.0 ) )
   Chk( Vc3_Eq( c[ "center" ], Vc3_New( 10.0, 20.0, 30.0 ) ) .AND. c[ "radius" ] == 5.0, "circle: test_circle_translate" )
   // arc
   a := Ear_New() ; Chk( Vc3_Eq( a[ "center" ], Vc3_Zero() ) .AND. a[ "radius" ] == 1.0 .AND. Ent_EntityType( a ) == "ARC", "arc: test_arc_creation" )
   a := Ear_FromCoords( 0.0, 0.0, 0.0, 5.0, 0.0, OCX_PI ) ; Chk( Nr( Ear_SweepAngle( a ), OCX_PI, 0.0000000001 ), "arc: test_arc_sweep_angle" )
   Chk( Nr( Ear_ArcLength( a ), 5.0 * OCX_PI, 0.0000000001 ), "arc: test_arc_length" )
   a := Ear_FromCoords( 0.0, 0.0, 0.0, 5.0, 0.0, OCX_PI / 2.0 ) ; nS := Ear_StartPoint( a ) ; nE := Ear_EndPoint( a )
   Chk( Nr( nS[ 1 ], 5.0, 0.0000000001 ) .AND. Nr( nS[ 2 ], 0.0, 0.0000000001 ) .AND. Nr( nE[ 1 ], 0.0, 0.0000000001 ) .AND. Nr( nE[ 2 ], 5.0, 0.0000000001 ), "arc: test_arc_endpoints" )
   a := Ear_FromCoords( 0.0, 0.0, 0.0, 5.0, 0.0, OCX_PI ) ; Ent_Translate( a, Vc3_New( 10.0, 20.0, 30.0 ) )
   Chk( Vc3_Eq( a[ "center" ], Vc3_New( 10.0, 20.0, 30.0 ) ) .AND. a[ "radius" ] == 5.0, "arc: test_arc_translate" )
   a := Ear_FromCoords( 0.0, 0.0, 0.0, 5.0, 0.0, OCX_PI / 2.0 ) ; oS := Ear_StartPoint( a ) ; oE := Ear_EndPoint( a ) ; Ent_MirrorX( a )
   nS := Ear_StartPoint( a ) ; nE := Ear_EndPoint( a )
   Chk( Nr( a[ "center" ][ 1 ], 0.0, 0.0000000001 ) .AND. Nr( nS[ 1 ], -oE[ 1 ], 0.00000001 ) .AND. Nr( nS[ 2 ], oE[ 2 ], 0.00000001 ) .AND. Nr( nE[ 1 ], -oS[ 1 ], 0.00000001 ) .AND. Nr( nE[ 2 ], oS[ 2 ], 0.00000001 ), "arc: test_arc_mirror_x" )
   a := Ear_FromCoords( 0.0, 0.0, 0.0, 5.0, 0.0, OCX_PI / 2.0 ) ; oS := Ear_StartPoint( a ) ; oE := Ear_EndPoint( a ) ; Ent_MirrorY( a )
   nS := Ear_StartPoint( a ) ; nE := Ear_EndPoint( a )
   Chk( Nr( nS[ 1 ], oE[ 1 ], 0.00000001 ) .AND. Nr( nS[ 2 ], -oE[ 2 ], 0.00000001 ) .AND. Nr( nE[ 1 ], oS[ 1 ], 0.00000001 ) .AND. Nr( nE[ 2 ], -oS[ 2 ], 0.00000001 ), "arc: test_arc_mirror_y" )
   // [extra]
   c := Eci_FromCoords( 1.0, 2.0, 0.0, 3.0 ) ; bb := Ent_BoundingBox( c )
   Chk( Nr( bb[ 1 ][ 1 ], -2.0, 0.0000000001 ) .AND. Nr( bb[ 2 ][ 2 ], 5.0, 0.0000000001 ), "[extra] circle: bounding box" )
   c := Eci_FromCoords( 1.0, 0.0, 0.0, 2.0 ) ; Ent_ApplyScaling( c, 3.0 )
   Chk( Nr( c[ "radius" ], 6.0, 0.0000000001 ) .AND. Nr( c[ "center" ][ 1 ], 3.0, 0.0000000001 ), "[extra] circle: escala" )
   a := Ear_FromCoords( 0.0, 0.0, 0.0, 5.0, 0.0, OCX_PI ) ; bb := Ent_BoundingBox( a )
   Chk( Nr( bb[ 1 ][ 1 ], -5.0, 0.00000001 ) .AND. Nr( bb[ 2 ][ 1 ], 5.0, 0.00000001 ) .AND. Nr( bb[ 1 ][ 2 ], 0.0, 0.00000001 ) .AND. Nr( bb[ 2 ][ 2 ], 5.0, 0.00000001 ), "[extra] arc: bounding box semicirculo" )
   a := Ear_FromCoords( 0.0, 0.0, 0.0, 5.0, 0.0, OCX_PI / 2.0 ) ; Ent_ApplyRotation( a, Vc3_UnitZ(), OCX_PI / 2.0 )
   Chk( Nr( a[ "start_angle" ], OCX_PI / 2.0, 0.000000001 ) .AND. Nr( Abs( a[ "end_angle" ] ), OCX_PI, 0.000000001 ), "[extra] arc: rotacion 90 grados" )
   Chk( Tf_IsReflecting( Tf_FromMirrorX() ) .AND. ! Tf_IsReflecting( Tf_FromScale( 2.0 ) ), "[extra] transform: is_reflecting" )
RETURN
