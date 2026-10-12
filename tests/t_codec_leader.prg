/* Port de tests: leader.rs (14) + [extra] */
#include "ocx.ch"
STATIC FUNCTION V( x, y, z ) ; RETURN Vc3_New( x, y, z )
PROCEDURE T_CodecLeader()
   LOCAL e, d, r, bb
   e := Eld_New() ; Chk( e[ "arrow_enabled" ] .AND. e[ "path_type" ] == LPT_STRAIGHT .AND. Eld_VertexCount( e ) == 0, "leader: test_leader_creation" )
   e := Eld_FromVertices( { V( 0.0, 0.0, 0.0 ), V( 10.0, 10.0, 0.0 ), V( 20.0, 10.0, 0.0 ) } ) ; Chk( Eld_VertexCount( e ) == 3, "leader: test_leader_from_vertices" )
   e := Eld_TwoPoint( V( 0.0, 0.0, 0.0 ), V( 10.0, 10.0, 0.0 ) )
   Chk( Eld_VertexCount( e ) == 2 .AND. Vc3_Eq( Eld_ArrowPoint( e ), V( 0.0, 0.0, 0.0 ) ) .AND. Vc3_Eq( Eld_EndPoint( e ), V( 10.0, 10.0, 0.0 ) ), "leader: test_leader_two_point" )
   e := Eld_WithLanding( V( 0.0, 0.0, 0.0 ), V( 10.0, 10.0, 0.0 ), 5.0 )
   Chk( Eld_VertexCount( e ) == 3 .AND. e[ "hookline_enabled" ] .AND. Vc3_Eq( Eld_EndPoint( e ), V( 15.0, 10.0, 0.0 ) ), "leader: test_leader_with_landing" )
   e := Eld_New() ; Eld_AddVertex( e, V( 0.0, 0.0, 0.0 ) ) ; Eld_AddVertex( e, V( 10.0, 10.0, 0.0 ) ) ; Chk( Eld_VertexCount( e ) == 2, "leader: test_leader_add_vertex" )
   e := Eld_FromVertices( { V( 0.0, 0.0, 0.0 ), V( 20.0, 0.0, 0.0 ) } ) ; Eld_InsertVertex( e, 1, V( 10.0, 10.0, 0.0 ) ) ; d := Eld_VertexCount( e ) == 3
   r := Eld_RemoveVertex( e, 1 ) ; Chk( d .AND. Vc3_Eq( r, V( 10.0, 10.0, 0.0 ) ) .AND. Eld_VertexCount( e ) == 2, "leader: test_leader_insert_remove_vertex" )
   e := Eld_FromVertices( { V( 0.0, 0.0, 0.0 ), V( 10.0, 0.0, 0.0 ), V( 10.0, 10.0, 0.0 ) } ) ; Chk( Abs( Eld_Length( e ) - 20.0 ) < 0.0000000001, "leader: test_leader_length" )
   e := Eld_FromVertices( { V( 0.0, 0.0, 0.0 ), V( 10.0, 0.0, 0.0 ) } ) ; d := Eld_ArrowDirection( e ) ; Chk( Abs( d[ 1 ] - 1.0 ) < 0.0000000001 .AND. Abs( d[ 2 ] ) < 0.0000000001, "leader: test_leader_arrow_direction" )
   e := Eld_FromVertices( { V( 0.0, 0.0, 0.0 ), V( 10.0, 10.0, 0.0 ) } ) ; Eld_Reverse( e )
   Chk( Vc3_Eq( Eld_ArrowPoint( e ), V( 10.0, 10.0, 0.0 ) ) .AND. Vc3_Eq( Eld_EndPoint( e ), V( 0.0, 0.0, 0.0 ) ), "leader: test_leader_reverse" )
   e := Eld_FromVertices( { V( 0.0, 0.0, 0.0 ), V( 10.0, 10.0, 0.0 ) } ) ; Ent_Translate( e, V( 5.0, 5.0, 0.0 ) )
   Chk( Vc3_Eq( Eld_ArrowPoint( e ), V( 5.0, 5.0, 0.0 ) ) .AND. Vc3_Eq( Eld_EndPoint( e ), V( 15.0, 15.0, 0.0 ) ), "leader: test_leader_translate" )
   Chk( Lpt_FromValue( 0 ) == LPT_STRAIGHT .AND. Lpt_FromValue( 1 ) == LPT_SPLINE .AND. LPT_SPLINE == 1, "leader: test_leader_path_type" )
   Chk( Lct_FromValue( 0 ) == LCT_WITHTEXT .AND. Lct_FromValue( 2 ) == LCT_WITHBLOCK .AND. LCT_WITHBLOCK == 2, "leader: test_leader_creation_type" )
   e := Eld_WithLayer( Eld_WithDimensionStyle( Eld_WithSplinePath( Eld_WithHookline( Eld_WithVertex( Eld_WithVertex( Eld_New(), V( 0.0, 0.0, 0.0 ) ), V( 10.0, 10.0, 0.0 ) ) ) ), "ISO-25" ), "LEADERS" )
   Chk( Eld_VertexCount( e ) == 2 .AND. e[ "hookline_enabled" ] .AND. e[ "path_type" ] == LPT_SPLINE .AND. e[ "dimension_style" ] == "ISO-25" .AND. e[ "common" ][ "layer" ] == "LEADERS", "leader: test_leader_builder" )
   e := Eld_FromVertices( { V( 0.0, 0.0, 0.0 ), V( 10.0, 10.0, 0.0 ), V( 20.0, 5.0, 0.0 ) } ) ; bb := Ent_BoundingBox( e )
   Chk( bb[ 1 ][ 1 ] == 0.0 .AND. bb[ 1 ][ 2 ] == 0.0 .AND. bb[ 2 ][ 1 ] == 20.0 .AND. bb[ 2 ][ 2 ] == 10.0, "leader: test_leader_bounding_box" )
   // [extra]
   e := Eld_TwoPoint( V( 0.0, 0.0, 0.0 ), V( 0.0, 5.0, 0.0 ) ) ; Ent_ApplyTransform( e, Tf_FromRotation( Vc3_UnitZ(), OCX_PI / 2.0 ) )
   Chk( Abs( e[ "vertices" ][ 2 ][ 1 ] + 5.0 ) < 0.000000001 .AND. Abs( e[ "horizontal_direction" ][ 2 ] - 1.0 ) < 0.000000001 .AND. Ent_EntityType( e ) == "LEADER", "[extra] leader: transform rota vertices y direccion" )
   e := Eld_New() ; Chk( Eld_ArrowPoint( e ) == NIL .AND. Eld_EndPoint( e ) == NIL .AND. Eld_ArrowDirection( e ) == NIL .AND. Eld_RemoveVertex( e, 0 ) == NIL .AND. Eld_Length( e ) == 0.0, "[extra] leader: vacio" )
   Eld_SetArrowPoint( e, V( 1.0, 1.0, 0.0 ) ) ; Chk( Eld_VertexCount( e ) == 1 .AND. Ent_BoundingBox( e )[ 1 ][ 1 ] == 1.0, "[extra] leader: set_arrow_point" )
RETURN
