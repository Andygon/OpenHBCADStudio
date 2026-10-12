/* polyline.rs no tiene tests en Rust: todos los checks son [extra] */
#include "ocx.ch"
STATIC FUNCTION Nr( a, b ) ; RETURN Abs( a - b ) < 0.000000001
PROCEDURE T_CodecPolyline()
   LOCAL p, h, bb
   p := Pl2_New() ; Pl2_AddVertex( p, Vx2_FromPoint( Vc2_New( 0.0, 0.0 ) ) ) ; Pl2_AddVertex( p, Vx2_WithBulge( Vx2_FromPoint( Vc2_New( 4.0, 0.0 ) ), 0.5 ) )
   Pl2_AddVertex( p, Vx2_WithWidth( Vx2_FromPoint( Vc2_New( 4.0, 3.0 ) ), 1.0, 2.0 ) )
   Chk( ! Pl2_IsClosed( p ) .AND. Ent_EntityType( p ) == "POLYLINE" .AND. p[ "vertices" ][ 3 ][ "end_width" ] == 2.0, "[extra] polyline2d: creacion" )
   Pl2_Close( p ) ; Chk( Pl2_IsClosed( p ) .AND. Pfl_IsClosed( p[ "flags" ] ) .AND. ! Pfl_Is3d( p[ "flags" ] ), "[extra] polyline2d: close" )
   bb := Ent_BoundingBox( p ) ; Chk( Vc3_Eq( bb[ 2 ], Vc3_New( 4.0, 3.0, 0.0 ) ), "[extra] polyline2d: bounding box" )
   Ent_Translate( p, Vc3_New( 1.0, 1.0, 1.0 ) ) ; Chk( Vc3_Eq( p[ "vertices" ][ 1 ][ "location" ], Vc3_New( 1.0, 1.0, 1.0 ) ), "[extra] polyline2d: translate" )
   Ent_MirrorX( p ) ; Chk( Nr( p[ "vertices" ][ 2 ][ "bulge" ], -0.5 ) .AND. Nr( p[ "vertices" ][ 1 ][ "location" ][ 1 ], -1.0 ), "[extra] polyline2d: espejo niega bulge" )
   h := Plh_FromPoints( { Vc3_Zero(), Vc3_New( 1.0, 2.0, 3.0 ) } )
   Chk( Plh_VertexCount( h ) == 2 .AND. Pfl_Is3d( h[ "flags" ] ) .AND. Ent_EntityType( h ) == "POLYLINE", "[extra] polyline3d heavy: creacion" )
   Ent_Translate( h, Vc3_New( 1.0, 1.0, 1.0 ) ) ; bb := Ent_BoundingBox( h )
   Chk( Vc3_Eq( bb[ 2 ], Vc3_New( 2.0, 3.0, 4.0 ) ), "[extra] polyline3d heavy: translate y bbox" )
   Ent_ApplyRotation( h, Vc3_UnitZ(), OCX_PI / 2.0 ) ; Chk( Nr( h[ "vertices" ][ 1 ][ "location" ][ 1 ], -1.0 ), "[extra] polyline3d heavy: rotacion" )
   Chk( Pfl_SetClosed( Pfl_Set3d( 0, .T. ), .T. ) == 9 .AND. Pfl_Set3d( 9, .F. ) == 1 .AND. Sst_From( 6 ) == SST_CUBIC_BSPLINE .AND. Sst_From( 7 ) == SST_NONE, "[extra] polyline: flags y SmoothSurfaceType" )
RETURN
