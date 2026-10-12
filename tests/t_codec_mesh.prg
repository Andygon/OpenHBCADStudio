/* Tests 1:1 de mesh.rs (21 #[test]) + [extra] */
#include "ocx.ch"
STATIC FUNCTION Nr( a, b ) ; RETURN Abs( a - b ) < 0.0000000001
PROCEDURE T_CodecMesh()
   LOCAL m, i, f, g, e, bb, c, m2, mg, r
   m := Emh_New() ; Chk( Emh_VertexCount( m ) == 0 .AND. Emh_FaceCount( m ) == 0 .AND. Emh_EdgeCount( m ) == 0 .AND. m[ "subdivision_level" ] == 0 .AND. m[ "blend_crease" ], "mesh: test_mesh_creation" )
   m := Emh_New() ; i := Emh_AddVertex( m, { 1.0, 2.0, 3.0 } ) ; Chk( i == 0 .AND. Emh_VertexCount( m ) == 1 .AND. Vc3_Eq( Emh_Vertex( m, 0 ), { 1.0, 2.0, 3.0 } ), "mesh: test_mesh_add_vertex" )
   m := Emh_New() ; Emh_AddVertex( m, Vc3_Zero() ) ; Emh_AddVertex( m, { 1.0, 0.0, 0.0 } ) ; Emh_AddVertex( m, { 0.0, 1.0, 0.0 } ) ; Emh_AddTriangle( m, 0, 1, 2 )
   Chk( Emh_FaceCount( m ) == 1 .AND. Mfc_IsTriangle( Emh_Face( m, 0 ) ), "mesh: test_mesh_add_face" )
   f := Mfc_Quad( 0, 1, 2, 3 ) ; e := Mfc_Edges( f )
   Chk( Mfc_IsQuad( f ) .AND. ! Mfc_IsTriangle( f ) .AND. Mfc_VertexCount( f ) == 4 .AND. Len( e ) == 4 .AND. e[ 1 ][ 1 ] == 0 .AND. e[ 1 ][ 2 ] == 1 .AND. e[ 2 ][ 1 ] == 1 .AND. e[ 2 ][ 2 ] == 2 ;
      .AND. e[ 3 ][ 1 ] == 2 .AND. e[ 3 ][ 2 ] == 3 .AND. e[ 4 ][ 1 ] == 3 .AND. e[ 4 ][ 2 ] == 0, "mesh: test_mesh_face" )
   f := Mfc_Quad( 0, 1, 2, 3 ) ; Mfc_Reverse( f ) ; Chk( f[ "vertices" ][ 1 ] == 3 .AND. f[ "vertices" ][ 2 ] == 2 .AND. f[ "vertices" ][ 3 ] == 1 .AND. f[ "vertices" ][ 4 ] == 0, "mesh: test_mesh_face_reverse" )
   g := Mge_New( 0, 5 ) ; c := g[ "start" ] == 0 .AND. g[ "end" ] == 5 .AND. ! Mge_HasCrease( g ) .AND. Mge_CreaseValue( g ) == 0.0 ; Mge_SetCrease( g, 2.5 )
   Chk( c .AND. Mge_HasCrease( g ) .AND. Mge_CreaseValue( g ) == 2.5, "mesh: test_mesh_edge" )
   g := Mge_New( 0, 5 ) ; Chk( Mge_Connects( g, 0, 5 ) .AND. Mge_Connects( g, 5, 0 ) .AND. ! Mge_Connects( g, 0, 3 ), "mesh: test_mesh_edge_connects" )
   g := Mge_New( 0, 5 ) ; Chk( Mge_OtherVertex( g, 0 ) == 5 .AND. Mge_OtherVertex( g, 5 ) == 0 .AND. Mge_OtherVertex( g, 3 ) == NIL, "mesh: test_mesh_edge_other_vertex" )
   m := Emh_New() ; Emh_AddVertex( m, Vc3_Zero() ) ; Emh_AddVertex( m, { 1.0, 0.0, 0.0 } ) ; Emh_AddVertex( m, { 1.0, 1.0, 0.0 } ) ; Emh_AddVertex( m, { 0.0, 1.0, 0.0 } ) ; Emh_AddQuad( m, 0, 1, 2, 3 ) ; Emh_ComputeEdges( m )
   Chk( Emh_EdgeCount( m ) == 4, "mesh: test_mesh_compute_edges" )
   m := Emh_FromTriangles( { Vc3_Zero(), { 1.0, 0.0, 0.0 }, { 0.5, 1.0, 0.0 } }, { { 0, 1, 2 } } )
   Chk( Emh_VertexCount( m ) == 3 .AND. Emh_FaceCount( m ) == 1 .AND. Emh_EdgeCount( m ) == 3 .AND. Emh_IsAllTriangles( m ), "mesh: test_mesh_from_triangles" )
   m := Emh_CreateBox( Vc3_Zero(), { 1.0, 1.0, 1.0 } ) ; Chk( Emh_VertexCount( m ) == 8 .AND. Emh_FaceCount( m ) == 6 .AND. Emh_IsAllQuads( m ), "mesh: test_mesh_create_box" )
   m := Emh_CreateUnitCube() ; bb := Emh_BoundingBoxOpt( m ) ; Chk( Vc3_Eq( bb[ 1 ], { -0.5, -0.5, -0.5 } ) .AND. Vc3_Eq( bb[ 2 ], { 0.5, 0.5, 0.5 } ), "mesh: test_mesh_unit_cube" )
   m := Emh_CreateUnitCube() ; Ent_Translate( m, { 1.0, 2.0, 3.0 } ) ; c := Emh_Center( m ) ; Chk( Nr( c[ 1 ], 1.0 ) .AND. Nr( c[ 2 ], 2.0 ) .AND. Nr( c[ 3 ], 3.0 ), "mesh: test_mesh_translate" )
   m := Emh_CreateUnitCube() ; Emh_ScaleUniform( m, 2.0 ) ; bb := Emh_BoundingBoxOpt( m ) ; Chk( Vc3_Eq( bb[ 1 ], { -1.0, -1.0, -1.0 } ) .AND. Vc3_Eq( bb[ 2 ], { 1.0, 1.0, 1.0 } ), "mesh: test_mesh_scale" )
   m := Emh_New() ; Emh_AddFace( m, Mfc_Triangle( 0, 1, 2 ) ) ; Emh_AddFace( m, Mfc_Quad( 3, 4, 5, 6 ) ) ; Emh_AddFace( m, Mfc_New( { 7, 8, 9, 10, 11 } ) ) ; Chk( Emh_TriangleCount( m ) == 6, "mesh: test_mesh_triangle_count" )
   m := Emh_New() ; Emh_AddVertex( m, Vc3_Zero() ) ; Emh_AddVertex( m, { 1.0, 0.0, 0.0 } ) ; Emh_AddVertex( m, { 0.0, 1.0, 0.0 } ) ; Emh_AddTriangle( m, 0, 1, 2 ) ; Emh_ComputeEdges( m )
   Chk( Emh_FindEdge( m, 0, 1 ) != NIL .AND. Emh_FindEdge( m, 1, 0 ) != NIL .AND. Emh_FindEdge( m, 0, 5 ) == NIL, "mesh: test_mesh_find_edge" )
   m := Emh_CreateUnitCube() ; Emh_ComputeEdges( m ) ; c := ! Emh_HasCreases( m ) ; Emh_SetEdgeCrease( m, 0, 2.0 ) ; r := Emh_HasCreases( m ) ; Emh_ClearCreases( m ) ; Chk( c .AND. r .AND. ! Emh_HasCreases( m ), "mesh: test_mesh_creases" )
   m := Emh_New() ; Emh_AddFace( m, Mfc_Triangle( 0, 1, 2 ) ) ; Emh_FlipNormals( m ) ; f := Emh_Face( m, 0 ) ; Chk( f[ "vertices" ][ 1 ] == 2 .AND. f[ "vertices" ][ 2 ] == 1 .AND. f[ "vertices" ][ 3 ] == 0, "mesh: test_mesh_flip_normals" )
   m := Emh_CreateUnitCube() ; m2 := Emh_CreateUnitCube() ; Ent_Translate( m2, { 2.0, 0.0, 0.0 } ) ; mg := Ent_Clone( m ) ; Emh_Merge( mg, m2 ) ; Chk( Emh_VertexCount( mg ) == 16 .AND. Emh_FaceCount( mg ) == 12, "mesh: test_mesh_merge" )
   m := Emh_CreatePlane( Vc3_Zero(), { 10.0, 0.0, 0.0 }, { 0.0, 10.0, 0.0 }, 2, 2 ) ; Chk( Emh_VertexCount( m ) == 9 .AND. Emh_FaceCount( m ) == 4, "mesh: test_mesh_create_plane" )
   m := Mbd_Build( Mbd_ComputeEdges( Mbd_BlendCrease( Mbd_SubdivisionLevel( Mbd_Triangle( Mbd_Vertex( Mbd_Vertex( Mbd_Vertex( Mbd_New(), Vc3_Zero() ), { 1.0, 0.0, 0.0 } ), { 0.5, 1.0, 0.0 } ), 0, 1, 2 ), 2 ), .F. ) ) )
   Chk( Emh_VertexCount( m ) == 3 .AND. Emh_FaceCount( m ) == 1 .AND. m[ "subdivision_level" ] == 2 .AND. ! m[ "blend_crease" ], "mesh: test_mesh_builder" )
   /* [extra] */
   m := Emh_CreateCylinder( Vc3_Zero(), 1.0, 2.0, 8, 2, .T., .T. ) ; Chk( Emh_VertexCount( m ) == 3 * 8 + 2 .AND. Emh_FaceCount( m ) == 16 + 16 .AND. Nr( m[ "vertices" ][ 3 ][ 1 ], 0.0 ) .AND. Nr( m[ "vertices" ][ 3 ][ 3 ], 1.0 ), "mesh: [extra] cylinder" )
   m := Emh_CreateUnitCube() ; Chk( Emh_EdgeCount( m ) == 12 .AND. Ent_EntityType( m ) == "MESH" .AND. Emh_BoundingBox( Emh_New() )[ 1 ][ 1 ] == 0.0, "mesh: [extra] cubo 12 aristas, tipo, bbox vacia" )
   m := Emh_CreateUnitCube() ; Ent_ApplyMirror( m, Tf_FromMirrorX() ) ; Chk( Emh_Face( m, 0 )[ "vertices" ][ 1 ] == 1 .AND. Emh_Face( m, 0 )[ "vertices" ][ 4 ] == 0, "mesh: [extra] mirror invierte caras" )
RETURN
