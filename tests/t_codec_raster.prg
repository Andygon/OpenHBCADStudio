/* Port de tests: raster_image.rs (27) + [extra] */
#include "ocx.ch"
STATIC FUNCTION V( x, y, z ) ; RETURN Vc3_New( x, y, z )
STATIC FUNCTION Nr( a, b ) ; RETURN Abs( a - b ) < 0.0000000001
PROCEDURE T_CodecRaster()
   LOCAL im, a, asp, c, b, r, d, f
   im := Eri_New( "test.jpg", Vc3_Zero(), 1920.0, 1080.0 ) ; Chk( im[ "file_path" ] == "test.jpg" .AND. im[ "size" ][ 1 ] == 1920.0 .AND. im[ "size" ][ 2 ] == 1080.0 .AND. Eri_IsVisible( im ), "raster_image: test_raster_image_creation" )
   im := Eri_New( "test.jpg", Vc3_Zero(), 100.0, 50.0 ) ; a := Nr( Eri_Width( im ), 100.0 ) .AND. Nr( Eri_Height( im ), 50.0 ) ; Eri_SetWidth( im, 10.0 ) ; Chk( a .AND. Nr( Eri_Width( im ), 10.0 ), "raster_image: test_raster_image_size" )
   im := Eri_New( "test.jpg", Vc3_Zero(), 1920.0, 1080.0 ) ; asp := Eri_AspectRatio( im ) ; Eri_SetWidthKeepAspect( im, 19.2 )
   Chk( Nr( Eri_Width( im ), 19.2 ) .AND. Abs( Eri_Height( im ) - 10.8 ) < 0.01 .AND. Nr( Eri_AspectRatio( im ), asp ), "raster_image: test_raster_image_aspect_ratio" )
   im := Eri_New( "test.jpg", V( 10.0, 20.0, 0.0 ), 100.0, 50.0 ) ; Eri_SetSize( im, 10.0, 5.0 ) ; c := Eri_Corners( im )
   Chk( Vc3_Eq( c[ 1 ], V( 10.0, 20.0, 0.0 ) ) .AND. Vc3_Eq( c[ 2 ], V( 20.0, 20.0, 0.0 ) ) .AND. Vc3_Eq( c[ 3 ], V( 20.0, 25.0, 0.0 ) ) .AND. Vc3_Eq( c[ 4 ], V( 10.0, 25.0, 0.0 ) ), "raster_image: test_raster_image_corners" )
   im := Eri_New( "test.jpg", Vc3_Zero(), 100.0, 100.0 ) ; Eri_SetSize( im, 10.0, 10.0 ) ; Chk( Vc3_Eq( Eri_Center( im ), V( 5.0, 5.0, 0.0 ) ), "raster_image: test_raster_image_center" )
   im := Eri_New( "test.jpg", Vc3_Zero(), 100.0, 100.0 ) ; Ent_Translate( im, V( 5.0, 10.0, 0.0 ) ) ; Chk( Vc3_Eq( im[ "insertion_point" ], V( 5.0, 10.0, 0.0 ) ), "raster_image: test_raster_image_translate" )
   im := Eri_New( "test.jpg", Vc3_Zero(), 100.0, 100.0 ) ; Eri_Rotate( im, OCX_PI / 2.0 ) ; Chk( Abs( im[ "u_vector" ][ 1 ] ) < 0.0000000001 .AND. Nr( im[ "u_vector" ][ 2 ], 1.0 ), "raster_image: test_raster_image_rotate" )
   im := Eri_New( "test.jpg", Vc3_Zero(), 100.0, 100.0 ) ; a := Eri_IsVisible( im ) ; Eri_SetVisible( im, .F. ) ; a := a .AND. ! Eri_IsVisible( im ) ; Eri_SetVisible( im, .T. ) ; Chk( a .AND. Eri_IsVisible( im ), "raster_image: test_raster_image_visibility" )
   im := Eri_New( "test.jpg", Vc3_Zero(), 100.0, 100.0 ) ; a := ! Eri_IsTransparent( im ) ; Eri_SetTransparent( im, .T. ) ; Chk( a .AND. Eri_IsTransparent( im ), "raster_image: test_raster_image_transparency" )
   im := Eri_New( "test.jpg", Vc3_Zero(), 100.0, 100.0 ) ; Eri_SetClipRect( im, Vc2_New( 10.0, 10.0 ), Vc2_New( 90.0, 90.0 ) ) ; a := im[ "clipping_enabled" ] .AND. Cbd_IsRectangular( im[ "clip_boundary" ] )
   Eri_SetClipPolygon( im, { Vc2_New( 50.0, 0.0 ), Vc2_New( 100.0, 50.0 ), Vc2_New( 50.0, 100.0 ), Vc2_New( 0.0, 50.0 ) } ) ; a := a .AND. Cbd_IsPolygonal( im[ "clip_boundary" ] ) .AND. Cbd_VertexCount( im[ "clip_boundary" ] ) == 4
   Eri_ClearClip( im ) ; Chk( a .AND. ! im[ "clipping_enabled" ], "raster_image: test_raster_image_clipping" )
   b := Cbd_Rectangular( Vc2_New( 0.0, 0.0 ), Vc2_New( 100.0, 50.0 ) ) ; r := Cbd_BoundingRect( b )
   Chk( Cbd_IsRectangular( b ) .AND. ! Cbd_IsPolygonal( b ) .AND. Cbd_VertexCount( b ) == 2 .AND. r[ 1 ][ 1 ] == 0.0 .AND. r[ 1 ][ 2 ] == 0.0 .AND. r[ 2 ][ 1 ] == 100.0 .AND. r[ 2 ][ 2 ] == 50.0, "raster_image: test_clip_boundary_rectangular" )
   b := Cbd_FullImage( 100.0, 50.0 ) ; Chk( b[ "vertices" ][ 1 ][ 1 ] == -0.5 .AND. b[ "vertices" ][ 1 ][ 2 ] == -0.5 .AND. b[ "vertices" ][ 2 ][ 1 ] == 99.5 .AND. b[ "vertices" ][ 2 ][ 2 ] == 49.5, "raster_image: test_clip_boundary_full_image" )
   im := Eri_New( "C:/images/photo.jpg", Vc3_Zero(), 100.0, 100.0 ) ; Chk( Eri_FileName( im ) == "photo.jpg" .AND. Eri_FileExtension( im ) == "jpg", "raster_image: test_raster_image_file_name" )
   d := Idf_New( "photo.png", 1920.0, 1080.0 ) ; a := Idf_FileName( d ) == "photo.png" .AND. Idf_Width( d ) == 1920.0 .AND. Idf_Height( d ) == 1080.0 .AND. Abs( Idf_AspectRatio( d ) - 1.7777777 ) < 0.0001
   Idf_SetDpi( d, 300.0 ) ; Chk( a .AND. d[ "resolution_unit" ] == RU_INCHES .AND. Nr( Idf_Dpi( d ), 300.0 ), "raster_image: test_image_definition" )
   b := Rib_Build( Rib_Transparent( Rib_Contrast( Rib_Brightness( Rib_Width( Rib_At( Rib_New( "photo.jpg", 1920.0, 1080.0 ), V( 10.0, 20.0, 0.0 ) ), 19.2 ), 70 ), 60 ) ) )
   Chk( Vc3_Eq( b[ "insertion_point" ], V( 10.0, 20.0, 0.0 ) ) .AND. Abs( Eri_Width( b ) - 19.2 ) < 0.01 .AND. b[ "brightness" ] == 70 .AND. b[ "contrast" ] == 60 .AND. Eri_IsTransparent( b ), "raster_image: test_raster_image_builder" )
   f := hb_bitOr( IDF_SHOW_IMAGE, IDF_TRANSPARENCY_ON ) ; Chk( hb_bitAnd( f, IDF_SHOW_IMAGE ) != 0 .AND. hb_bitAnd( f, IDF_TRANSPARENCY_ON ) != 0 .AND. hb_bitAnd( f, IDF_USE_CLIPPING_BOUNDARY ) == 0, "raster_image: test_display_flags" )
   Chk( Clm_From( 0 ) == CLM_OUTSIDE .AND. Clm_From( 1 ) == CLM_INSIDE, "raster_image: test_clip_mode" )
   Chk( Wct_From( 1 ) == WCT_RECTANGULAR .AND. Wct_From( 2 ) == WCT_POLYGONAL, "raster_image: test_clip_type" )
   Chk( Ru_From( 0 ) == RU_NONE .AND. Ru_From( 2 ) == RU_CENTIMETERS .AND. Ru_From( 5 ) == RU_INCHES, "raster_image: test_resolution_unit" )
   // [extra]
   im := Eri_New( "test.jpg", Vc3_Zero(), 100.0, 50.0 ) ; Ent_ApplyTransform( im, Tf_FromScale( 2.0 ) ) ; Chk( Nr( Eri_Width( im ), 200.0 ) .AND. Ent_EntityType( im ) == "IMAGE", "[extra] raster_image: transform escala una vez; entity_type IMAGE" )
   Chk( Eri_FileExtension( Eri_New( "noext", Vc3_Zero(), 1.0, 1.0 ) ) == "noext" .AND. Idq_From( 0 ) == IDQ_DRAFT .AND. Idq_From( 9 ) == IDQ_HIGH .AND. Idf_Dpi( Idf_New( "a", 1.0, 1.0 ) ) == NIL, "[extra] raster_image: file_extension sin punto, calidad, dpi None" )
   im := Eri_New( "t", V( 1.0, 1.0, 0.0 ), 10.0, 10.0 ) ; r := Eri_BoundingBoxPair( im ) ; Chk( r[ 1 ][ 1 ] == 1.0 .AND. r[ 2 ][ 1 ] == 11.0 .AND. Ent_BoundingBox( im )[ 2 ][ 2 ] == 11.0, "[extra] raster_image: bounding_box inherente y del trait" )
RETURN
