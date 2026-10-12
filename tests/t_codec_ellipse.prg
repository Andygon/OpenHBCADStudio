/* Port de tests: ellipse.rs (2) + [extra] */
#include "ocx.ch"
STATIC FUNCTION Nr( a, b, nTol ) ; RETURN Abs( a - b ) < nTol
PROCEDURE T_CodecEllipse()
   LOCAL e, bb
   e := Eel_New() ; Chk( Vc3_Eq( e[ "center" ], Vc3_Zero() ) .AND. Ent_EntityType( e ) == "ELLIPSE", "ellipse: test_ellipse_creation" )
   e := Eel_FromCenterAxes( Vc3_Zero(), Vc3_New( 10.0, 0.0, 0.0 ), 0.5 )
   Chk( Eel_MajorAxisLength( e ) == 10.0 .AND. Eel_MinorAxisLength( e ) == 5.0, "ellipse: test_ellipse_axis_lengths" )
   // [extra]
   bb := Ent_BoundingBox( e )
   Chk( Nr( bb[ 1 ][ 1 ], -10.0, 0.0000000001 ) .AND. Nr( bb[ 2 ][ 2 ], 10.0, 0.0000000001 ), "[extra] ellipse: bounding box" )
   Chk( Eel_IsFull( e ), "[extra] ellipse: is_full" )
   Ent_ApplyRotation( e, Vc3_UnitZ(), OCX_PI / 2.0 )
   Chk( Nr( e[ "major_axis" ][ 1 ], 0.0, 0.000000001 ) .AND. Nr( e[ "major_axis" ][ 2 ], 10.0, 0.000000001 ) .AND. Nr( e[ "minor_axis_ratio" ], 0.5, 0.000000001 ), "[extra] ellipse: rotacion 90" )
   e := Eel_FromCenterAxes( Vc3_Zero(), Vc3_New( 10.0, 0.0, 0.0 ), 0.5 ) ; Ent_ApplyScaling( e, 2.0 )
   Chk( Nr( e[ "major_axis" ][ 1 ], 20.0, 0.000000001 ) .AND. Nr( e[ "minor_axis_ratio" ], 0.5, 0.000000001 ), "[extra] ellipse: escala uniforme" )
   e := Eel_FromCenterAxes( Vc3_Zero(), Vc3_New( 10.0, 0.0, 0.0 ), 0.5 ) ; e[ "end_parameter" ] := OCX_PI ; Ent_MirrorX( e )
   Chk( ! Eel_IsFull( e ) .AND. Nr( e[ "end_parameter" ] - e[ "start_parameter" ], OCX_PI, 0.000000001 ), "[extra] ellipse: espejo conserva barrido" )
RETURN
