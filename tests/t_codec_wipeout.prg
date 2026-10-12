/* Port de tests: wipeout.rs (22) + [extra] */
#include "ocx.ch"
STATIC FUNCTION V( x, y, z ) ; RETURN Vc3_New( x, y, z )
STATIC FUNCTION Nr( a, b ) ; RETURN Abs( a - b ) < 0.0000000001
PROCEDURE T_CodecWipeout()
   LOCAL w, a, vs, c, bb
   w := Ewp_New() ; Chk( Vc3_Eq( w[ "insertion_point" ], Vc3_Zero() ) .AND. w[ "clipping_enabled" ] .AND. w[ "brightness" ] == 50 .AND. w[ "contrast" ] == 50 .AND. w[ "fade" ] == 0, "wipeout: test_wipeout_creation" )
   w := Ewp_Rectangular( V( 10.0, 20.0, 0.0 ), 100.0, 50.0 ) ; Chk( w[ "insertion_point" ][ 1 ] == 10.0 .AND. w[ "insertion_point" ][ 2 ] == 20.0 .AND. Nr( Ewp_Width( w ), 100.0 ) .AND. Nr( Ewp_Height( w ), 50.0 ) .AND. Ewp_IsRectangular( w ), "wipeout: test_rectangular_wipeout" )
   w := Ewp_FromCorners( V( 10.0, 20.0, 0.0 ), V( 60.0, 70.0, 0.0 ) ) ; Chk( Nr( Ewp_Width( w ), 50.0 ) .AND. Nr( Ewp_Height( w ), 50.0 ), "wipeout: test_from_corners" )
   w := Ewp_Polygonal( { Vc2_New( 0.0, 0.0 ), Vc2_New( 100.0, 0.0 ), Vc2_New( 100.0, 100.0 ), Vc2_New( 0.0, 100.0 ) }, 0.0 ) ; Chk( Ewp_IsPolygonal( w ) .AND. Ewp_VertexCount( w ) == 4, "wipeout: test_polygonal_wipeout" )
   w := Ewp_Rectangular( V( 10.0, 10.0, 0.0 ), 50.0, 30.0 ) ; vs := Ewp_WorldBoundaryVertices( w ) ; Chk( Len( vs ) == 2 .AND. Nr( vs[ 1 ][ 1 ], 10.0 ) .AND. Nr( vs[ 2 ][ 1 ], 60.0 ), "wipeout: test_world_boundary_vertices" )
   Chk( Nr( Ewp_Area( Ewp_Rectangular( Vc3_Zero(), 10.0, 5.0 ) ), 50.0 ), "wipeout: test_area_rectangular" )
   c := Ewp_Center( Ewp_Rectangular( V( 0.0, 0.0, 0.0 ), 10.0, 10.0 ) ) ; Chk( Nr( c[ 1 ], 5.0 ) .AND. Nr( c[ 2 ], 5.0 ), "wipeout: test_center" )
   c := Ewp_Corners( Ewp_Rectangular( V( 0.0, 0.0, 0.0 ), 10.0, 20.0 ) ) ; Chk( Vc3_Eq( c[ 1 ], V( 0.0, 0.0, 0.0 ) ) .AND. Vc3_Eq( c[ 2 ], V( 10.0, 0.0, 0.0 ) ) .AND. Vc3_Eq( c[ 3 ], V( 10.0, 20.0, 0.0 ) ) .AND. Vc3_Eq( c[ 4 ], V( 0.0, 20.0, 0.0 ) ), "wipeout: test_corners" )
   w := Ewp_Rectangular( Vc3_Zero(), 10.0, 0.0 ) ; w[ "u_vector" ] := V( 10.0, 0.0, 0.0 ) ; w[ "v_vector" ] := V( 0.0, 10.0, 0.0 ) ; Ewp_Rotate( w, OCX_PI / 2.0 ) ; Chk( Nr( w[ "u_vector" ][ 2 ], 10.0 ) .AND. Nr( w[ "v_vector" ][ 1 ] + 10.0, 0.0 ), "wipeout: test_rotate" )
   w := Ewp_Rectangular( Vc3_Zero(), 10.0, 5.0 ) ; Ewp_Scale( w, 2.0 ) ; Chk( Nr( Ewp_Width( w ), 20.0 ) .AND. Nr( Ewp_Height( w ), 10.0 ), "wipeout: test_scale" )
   w := Ewp_Rectangular( Vc3_Zero(), 10.0, 10.0 ) ; Ent_Translate( w, V( 5.0, 5.0, 0.0 ) ) ; Chk( w[ "insertion_point" ][ 1 ] == 5.0 .AND. w[ "insertion_point" ][ 2 ] == 5.0, "wipeout: test_translate" )
   w := Ewp_Rectangular( V( 10.0, 20.0, 0.0 ), 30.0, 40.0 ) ; bb := Ent_BoundingBox( w ) ; Chk( Nr( bb[ 1 ][ 1 ], 10.0 ) .AND. Nr( bb[ 1 ][ 2 ], 20.0 ) .AND. Nr( bb[ 2 ][ 1 ], 40.0 ) .AND. Nr( bb[ 2 ][ 2 ], 60.0 ), "wipeout: test_bounding_box" )
   Chk( Ent_EntityType( Ewp_New() ) == "WIPEOUT", "wipeout: test_entity_type" )
   w := Ewp_Rectangular( Vc3_Zero(), 10.0, 10.0 ) ; Ewp_SetSize( w, 50.0, 25.0 ) ; Chk( Nr( Ewp_Width( w ), 50.0 ) .AND. Nr( Ewp_Height( w ), 25.0 ), "wipeout: test_set_size" )
   w := Ewp_New() ; a := Ewp_IsFrameVisible( w ) ; Ewp_SetFrameVisible( w, .F. ) ; a := a .AND. ! Ewp_IsFrameVisible( w ) ; Ewp_SetFrameVisible( w, .T. ) ; Chk( a .AND. Ewp_IsFrameVisible( w ), "wipeout: test_frame_visibility" )
   w := Ewp_New() ; Chk( hb_bitAnd( w[ "flags" ], WDF_SHOW_IMAGE ) != 0 .AND. hb_bitAnd( w[ "flags" ], WDF_SHOW_NOT_ALIGNED ) != 0 .AND. hb_bitAnd( w[ "flags" ], WDF_USE_CLIPPING_BOUNDARY ) != 0, "wipeout: test_display_flags" )
   w := Ewp_New() ; a := Ewp_IsRectangular( w ) .AND. ! Ewp_IsPolygonal( w ) ; Ewp_SetPolygon( w, { Vc2_New( 0.0, 0.0 ), Vc2_New( 1.0, 0.0 ), Vc2_New( 0.5, 1.0 ) } ) ; Chk( a .AND. ! Ewp_IsRectangular( w ) .AND. Ewp_IsPolygonal( w ), "wipeout: test_clip_type" )
   w := Ewp_Rectangular( V( 10.0, 10.0, 0.0 ), 20.0, 20.0 ) ; Chk( Ewp_ContainsPoint( w, V( 20.0, 20.0, 0.0 ) ) .AND. ! Ewp_ContainsPoint( w, V( 0.0, 0.0, 0.0 ) ) .AND. ! Ewp_ContainsPoint( w, V( 50.0, 50.0, 0.0 ) ), "wipeout: test_contains_point_rectangular" )
   // [extra]
   Chk( Wct_From( 2 ) == 2 .AND. Wct_From( 7 ) == 1 .AND. Wcm_From( 1 ) == 1 .AND. Wcm_From( 5 ) == 0, "[extra] wipeout: conversiones clip_type/clip_mode" )
   w := Ewp_Polygonal( { Vc2_New( 0.0, 0.0 ), Vc2_New( 10.0, 0.0 ), Vc2_New( 10.0, 10.0 ), Vc2_New( 0.0, 10.0 ) }, 0.0 ) ; Chk( Nr( Ewp_Area( w ), 100.0 ) .AND. Ewp_ContainsPoint( w, V( 5.0, 5.0, 0.0 ) ), "[extra] wipeout: area y contains_point poligono" )
   w := Ewp_Rectangular( Vc3_Zero(), 10.0, 5.0 ) ; Ent_ApplyTransform( w, Tf_FromScale( 2.0 ) ) ; Chk( Nr( Ewp_Width( w ), 20.0 ) .AND. Nr( Ewp_Height( w ), 10.0 ), "[extra] wipeout: transform escala una sola vez" )
RETURN
