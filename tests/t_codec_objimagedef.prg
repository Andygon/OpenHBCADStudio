/* Tests: image_definition.rs (14 tests 1:1) */
#include "ocx.ch"
PROCEDURE T_CodecObjImageDef()
   LOCAL d, r
   d := Imd_New( "C:\Images\test.jpg" ) ; Chk( d[ "file_name" ] == "C:\Images\test.jpg" .AND. ! d[ "is_loaded" ] .AND. d[ "size_in_pixels" ][ 1 ] == 0 .AND. d[ "size_in_pixels" ][ 2 ] == 0, "creation" )
   d := Imd_WithDimensions( "photo.png", 1920, 1080 ) ; Chk( Imd_WidthPixels( d ) == 1920 .AND. Imd_HeightPixels( d ) == 1080, "with_dimensions" )
   d := Imd_WithDimensions( "test.jpg", 100, 50 ) ; Imd_SetPixelSize( d, 0.1, 0.1 )
   Chk( Abs( Imd_WidthUnits( d ) - 10.0 ) < 0.0000000001 .AND. Abs( Imd_HeightUnits( d ) - 5.0 ) < 0.0000000001, "units" )
   d := Imd_WithDimensions( "test.jpg", 1600, 900 ) ; r := Imd_AspectRatio( d ) ; Chk( Abs( r - 16.0 / 9.0 ) < 0.0000000001, "aspect_ratio" )
   d := Imd_New( "test.jpg" ) ; Imd_SetResolutionDpi( d, 72.0 ) ; r := Imd_ResolutionDpi( d )
   Chk( d[ "resolution_unit" ] == RSU_INCHES .AND. r != NIL .AND. Abs( r - 72.0 ) < 0.0000000001, "dpi" )
   d := Imd_New( "test.jpg" ) ; Imd_SetResolutionPpcm( d, 100.0 ) ; Chk( d[ "resolution_unit" ] == RSU_CENTIMETERS .AND. Abs( d[ "pixel_size" ][ 1 ] - 0.01 ) < 0.0000000001, "ppcm" )
   Chk( Rsu_FromCode( 0 ) == RSU_NONE .AND. Rsu_FromCode( 2 ) == RSU_CENTIMETERS .AND. Rsu_FromCode( 5 ) == RSU_INCHES .AND. ! Rsu_HasUnits( RSU_NONE ) .AND. Rsu_HasUnits( RSU_INCHES ), "resolution_unit" )
   d := Imd_New( "C:\Images\photo.jpg" )
   Chk( Imd_IsAbsolutePath( d ) .AND. ! Imd_IsRelativePath( d ) .AND. Imd_FileNameOnly( d ) == "photo.jpg" .AND. Imd_FileExtension( d ) == "jpg" .AND. Imd_IsSupportedFormat( d ), "file_path_analysis" )
   d := Imd_New( "images/photo.png" ) ; Chk( ! Imd_IsAbsolutePath( d ) .AND. Imd_IsRelativePath( d ) .AND. Imd_FileNameOnly( d ) == "photo.png", "relative_path" )
   d := Imd_New( "/home/user/images/photo.tiff" ) ; Chk( Imd_IsAbsolutePath( d ) .AND. Imd_FileNameOnly( d ) == "photo.tiff" .AND. Imd_FileExtension( d ) == "tiff", "unix_path" )
   d := Imd_New( "\\server\share\photo.bmp" ) ; Chk( Imd_IsAbsolutePath( d ) .AND. Imd_FileNameOnly( d ) == "photo.bmp", "unc_path" )
   Chk( Imd_IsSupportedFormat( Imd_New( "test.jpg" ) ) .AND. Imd_IsSupportedFormat( Imd_New( "test.jpeg" ) ) .AND. Imd_IsSupportedFormat( Imd_New( "test.png" ) ) ;
      .AND. Imd_IsSupportedFormat( Imd_New( "test.bmp" ) ) .AND. Imd_IsSupportedFormat( Imd_New( "test.tif" ) ) .AND. Imd_IsSupportedFormat( Imd_New( "test.tiff" ) ) ;
      .AND. Imd_IsSupportedFormat( Imd_New( "test.gif" ) ) .AND. ! Imd_IsSupportedFormat( Imd_New( "test.pdf" ) ) .AND. ! Imd_IsSupportedFormat( Imd_New( "test.doc" ) ), "supported_formats" )
   d := Imd_Loaded( Imd_WithResolutionUnit( Imd_WithPixelSize( Imd_WithSizePixels( Imd_New( "test.jpg" ), 800, 600 ), 0.05, 0.05 ), RSU_CENTIMETERS ) )
   Chk( d[ "size_in_pixels" ][ 1 ] == 800 .AND. d[ "size_in_pixels" ][ 2 ] == 600 .AND. d[ "pixel_size" ][ 1 ] == 0.05 .AND. d[ "pixel_size" ][ 2 ] == 0.05 .AND. d[ "resolution_unit" ] == RSU_CENTIMETERS .AND. d[ "is_loaded" ], "builder_pattern" )
   r := Imr_New( 0xABC ) ; Chk( r[ "image_handle" ] == 0xABC .AND. Imr_ObjectType() == "IMAGEDEF_REACTOR", "reactor" )
RETURN
