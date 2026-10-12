/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/obj_imagedef.prg
   Origen Rust: opencadcodec/src/objects/image_definition.rs (431 lineas, 14 tests). Licencia del original: MPL-2.0.
   Prefijos: Rsu_ (ResolutionUnit, constantes RSU_* en ocx.ch), Imr_ (ImageDefinitionReactor), Imd_ (ImageDefinition).
   Tuplas -> arrays { a, b }. Los metodos builder (loaded/with_*) mutan y devuelven el mismo hash.
   Rust trabaja en bytes: is_absolute_path usa Len/SubStr sobre bytes (igual en Harbour sin CDP).
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Rsu_FromCode( n )
   IF n == 2 ; RETURN RSU_CENTIMETERS ; ENDIF
   IF n == 5 ; RETURN RSU_INCHES ; ENDIF
RETURN RSU_NONE
FUNCTION Rsu_ToCode( n ) ; RETURN n
FUNCTION Rsu_HasUnits( n ) ; RETURN n != RSU_NONE

FUNCTION Imr_ObjectType() ; RETURN "IMAGEDEF_REACTOR"
FUNCTION Imr_New( nImage ) ; RETURN hb_Hash( "_type", "ImageDefinitionReactor", "handle", Hd_Null(), "owner", Hd_Null(), "image_handle", nImage )

FUNCTION Imd_ObjectType() ; RETURN "IMAGEDEF"
FUNCTION Imd_DefaultClassVersion() ; RETURN 0

FUNCTION Imd_New( cFile )
RETURN hb_Hash( "_type", "ImageDefinition", "handle", Hd_Null(), "owner", Hd_Null(), "file_name", cFile, "is_loaded", .F., ;
   "size_in_pixels", { 0, 0 }, "pixel_size", { 0.0, 0.0 }, "resolution_unit", RSU_NONE, "class_version", Imd_DefaultClassVersion() )

FUNCTION Imd_Default() ; RETURN Imd_New( "" )

FUNCTION Imd_WithDimensions( cFile, nW, nH )
   LOCAL d := Imd_New( cFile )
   d[ "size_in_pixels" ] := { nW, nH }
   d[ "pixel_size" ] := { 1.0, 1.0 }
RETURN d

FUNCTION Imd_WidthPixels( d ) ; RETURN d[ "size_in_pixels" ][ 1 ]
FUNCTION Imd_HeightPixels( d ) ; RETURN d[ "size_in_pixels" ][ 2 ]
PROCEDURE Imd_SetSizePixels( d, nW, nH ) ; d[ "size_in_pixels" ] := { nW, nH } ; RETURN
FUNCTION Imd_PixelWidth( d ) ; RETURN d[ "pixel_size" ][ 1 ]
FUNCTION Imd_PixelHeight( d ) ; RETURN d[ "pixel_size" ][ 2 ]
PROCEDURE Imd_SetPixelSize( d, nW, nH ) ; d[ "pixel_size" ] := { nW, nH } ; RETURN
FUNCTION Imd_WidthUnits( d ) ; RETURN d[ "size_in_pixels" ][ 1 ] * d[ "pixel_size" ][ 1 ]
FUNCTION Imd_HeightUnits( d ) ; RETURN d[ "size_in_pixels" ][ 2 ] * d[ "pixel_size" ][ 2 ]

FUNCTION Imd_AspectRatio( d )
   IF d[ "size_in_pixels" ][ 2 ] == 0 ; RETURN NIL ; ENDIF
RETURN d[ "size_in_pixels" ][ 1 ] / d[ "size_in_pixels" ][ 2 ]

PROCEDURE Imd_SetResolutionDpi( d, nDpi )
   LOCAL n := 1.0 / nDpi
   d[ "pixel_size" ] := { n, n }
   d[ "resolution_unit" ] := RSU_INCHES
RETURN

PROCEDURE Imd_SetResolutionPpcm( d, nPpcm )
   LOCAL n := 1.0 / nPpcm
   d[ "pixel_size" ] := { n, n }
   d[ "resolution_unit" ] := RSU_CENTIMETERS
RETURN

FUNCTION Imd_ResolutionDpi( d )
   IF d[ "resolution_unit" ] == RSU_INCHES .AND. d[ "pixel_size" ][ 1 ] > 0.0
      RETURN 1.0 / d[ "pixel_size" ][ 1 ]
   ENDIF
RETURN NIL

FUNCTION Imd_IsRelativePath( d ) ; RETURN ! Imd_IsAbsolutePath( d )

FUNCTION Imd_IsAbsolutePath( d )
   LOCAL c := d[ "file_name" ], a, b
   IF Len( c ) >= 2
      a := SubStr( c, 1, 1 ) ; b := SubStr( c, 2, 1 )
      IF b == ":" .AND. ( ( a >= "A" .AND. a <= "Z" ) .OR. ( a >= "a" .AND. a <= "z" ) )
         RETURN .T.
      ENDIF
      IF a == "\" .AND. b == "\"
         RETURN .T.
      ENDIF
   ENDIF
RETURN Left( c, 1 ) == "/"

FUNCTION Imd_FileNameOnly( d )
   LOCAL c := d[ "file_name" ], i
   FOR i := Len( c ) TO 1 STEP -1
      IF SubStr( c, i, 1 ) == "/" .OR. SubStr( c, i, 1 ) == "\"
         RETURN SubStr( c, i + 1 )
      ENDIF
   NEXT
RETURN c

FUNCTION Imd_FileExtension( d )
   LOCAL c := Imd_FileNameOnly( d ), i
   FOR i := Len( c ) TO 1 STEP -1
      IF SubStr( c, i, 1 ) == "."
         RETURN SubStr( c, i + 1 )
      ENDIF
   NEXT
RETURN NIL

FUNCTION Imd_IsSupportedFormat( d )
   LOCAL e := Imd_FileExtension( d )
   IF e == NIL ; RETURN .F. ; ENDIF
RETURN hb_AScan( { "bmp", "jpg", "jpeg", "png", "tif", "tiff", "gif", "pcx", "tga" }, Lower( e ),, , .T. ) > 0

PROCEDURE Imd_SetLoaded( d, l ) ; d[ "is_loaded" ] := l ; RETURN
FUNCTION Imd_Loaded( d ) ; d[ "is_loaded" ] := .T. ; RETURN d
FUNCTION Imd_WithPixelSize( d, nW, nH ) ; d[ "pixel_size" ] := { nW, nH } ; RETURN d
FUNCTION Imd_WithSizePixels( d, nW, nH ) ; d[ "size_in_pixels" ] := { nW, nH } ; RETURN d
FUNCTION Imd_WithResolutionUnit( d, nUnit ) ; d[ "resolution_unit" ] := nUnit ; RETURN d
