/* Port de tests: polyline3d.rs (10) + [extra] */
#include "ocx.ch"
STATIC FUNCTION Nr( a, b ) ; RETURN Abs( a - b ) < 0.0000000001
PROCEDURE T_CodecPoly3d()
   LOCAL p, f, c
   p := P3d_New() ; Chk( P3d_VertexCount( p ) == 0 .AND. ! P3d_IsClosed( p ) .AND. p[ "flags" ][ "is_3d" ], "polyline3d: test_polyline3d_creation" )
   p := P3d_FromPoints( { Vc3_Zero(), Vc3_New( 10.0, 0.0, 5.0 ), Vc3_New( 10.0, 10.0, 10.0 ) } ) ; Chk( P3d_VertexCount( p ) == 3, "polyline3d: test_polyline3d_from_points" )
   p := P3d_New() ; P3d_AddVertex( p, Vc3_Zero() ) ; P3d_AddVertex( p, Vc3_New( 10.0, 0.0, 5.0 ) ) ; Chk( P3d_VertexCount( p ) == 2, "polyline3d: test_polyline3d_add_vertex" )
   p := P3d_New() ; c := ! P3d_IsClosed( p ) ; P3d_Close( p ) ; c := c .AND. P3d_IsClosed( p ) ; P3d_Open( p ) ; Chk( c .AND. ! P3d_IsClosed( p ), "polyline3d: test_polyline3d_close" )
   p := P3d_FromPoints( { Vc3_Zero(), Vc3_New( 10.0, 0.0, 0.0 ), Vc3_New( 10.0, 10.0, 0.0 ) } ) ; c := Nr( P3d_Length( p ), 20.0 )
   P3d_Close( p ) ; Chk( c .AND. Nr( P3d_Length( p ), 20.0 + Sqrt( 200.0 ) ), "polyline3d: test_polyline3d_length" )
   p := P3d_FromPoints( { Vc3_Zero(), Vc3_New( 10.0, 0.0, 0.0 ), Vc3_New( 10.0, 10.0, 0.0 ), Vc3_New( 0.0, 10.0, 0.0 ) } ) ; c := P3d_Centroid( p )
   Chk( Nr( c[ 1 ], 5.0 ) .AND. Nr( c[ 2 ], 5.0 ), "polyline3d: test_polyline3d_centroid" )
   p := P3d_FromPoints( { Vc3_Zero(), Vc3_New( 10.0, 0.0, 0.0 ), Vc3_New( 20.0, 0.0, 0.0 ) } ) ; P3d_Reverse( p )
   Chk( p[ "vertices" ][ 1 ][ "position" ][ 1 ] == 20.0 .AND. p[ "vertices" ][ 3 ][ "position" ][ 1 ] == 0.0, "polyline3d: test_polyline3d_reverse" )
   p := P3d_FromPoints( { Vc3_Zero(), Vc3_New( 10.0, 0.0, 0.0 ) } ) ; Ent_Translate( p, Vc3_New( 5.0, 5.0, 5.0 ) )
   Chk( Vc3_Eq( p[ "vertices" ][ 1 ][ "position" ], Vc3_New( 5.0, 5.0, 5.0 ) ) .AND. Vc3_Eq( p[ "vertices" ][ 2 ][ "position" ], Vc3_New( 15.0, 5.0, 5.0 ) ), "polyline3d: test_polyline3d_translate" )
   f := P3f_FromBits( 9 ) ; Chk( f[ "closed" ] .AND. f[ "is_3d" ] .AND. ! f[ "spline_fit" ] .AND. P3f_ToBits( f ) == 9, "polyline3d: test_polyline3d_flags" )
   p := P3d_New() ; c := P3d_StartPoint( p ) == NIL .AND. P3d_EndPoint( p ) == NIL
   P3d_AddVertex( p, Vc3_Zero() ) ; P3d_AddVertex( p, Vc3_New( 10.0, 0.0, 0.0 ) )
   Chk( c .AND. Vc3_Eq( P3d_StartPoint( p ), Vc3_Zero() ) .AND. Vc3_Eq( P3d_EndPoint( p ), Vc3_New( 10.0, 0.0, 0.0 ) ), "polyline3d: test_polyline3d_start_end_points" )
   // [extra]
   P3d_InsertVertex( p, 1, Vc3_New( 5.0, 0.0, 0.0 ) ) ; c := P3d_VertexCount( p ) == 3 .AND. P3d_GetVertex( p, 1 )[ "position" ][ 1 ] == 5.0 .AND. P3d_GetVertex( p, 3 ) == NIL
   Chk( c .AND. P3d_RemoveVertex( p, 1 )[ "position" ][ 1 ] == 5.0 .AND. P3d_VertexCount( p ) == 2 .AND. P3d_RemoveVertex( p, 9 ) == NIL, "[extra] polyline3d: insert/remove/get" )
   Chk( Ent_EntityType( p ) == "POLYLINE" .AND. Vc3_Eq( Ent_BoundingBox( P3d_New() )[ 2 ], Vc3_Zero() ) .AND. Vc3_Eq( Ent_BoundingBox( p )[ 2 ], Vc3_New( 10.0, 0.0, 0.0 ) ), "[extra] polyline3d: entity_type y bbox" )
   Chk( Ssd_FromDwgCode( 2 ) == SST_CUBIC_BSPLINE .AND. Ssd_ToDwgCode( SST_BEZIER ) == 0 .AND. Ssd_ToDwgCode( SST_QUADRATIC_BSPLINE ) == 1, "[extra] polyline3d: SmoothSurfaceType dwg" )
   Ent_ApplyRotation( p, Vc3_UnitZ(), OCX_PI / 2.0 ) ; Chk( Nr( p[ "vertices" ][ 2 ][ "position" ][ 2 ], 10.0 ), "[extra] polyline3d: rotacion" )
RETURN
