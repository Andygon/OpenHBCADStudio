/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_raster.prg
   Origen Rust: opencadcodec/src/entities/raster_image.rs (998, 27 tests) + translate_raster_image + transform_raster_image. Licencia del original: MPL-2.0.
   Prefijos: Cbd_ (ClipBoundary), Eri_ (RasterImage, _type "IMAGE"), Idf_ (ImageDefinition), Rib_ (RasterImageBuilder). Enums = enteros: CLM_*, WCT_* (ClipType), RU_*, IDQ_*; flags IDF_*.
   Rust: RasterImage tiene un bounding_box inherente (tupla) y el del trait (BoundingBox3D): aqui Eri_BoundingBoxPair y Eri_BoundingBox.
   Option<(min,max)> / Option<f64> = NIL cuando es None. file_extension: rsplit('.').next() devuelve siempre Some (si no hay punto, la cadena entera).
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Clm_From( n ) ; RETURN iif( n == 1, 1, 0 )
FUNCTION Ru_From( n ) ; RETURN iif( n == 2 .OR. n == 5, n, 0 )
FUNCTION Idq_From( n ) ; RETURN iif( n == 0, 0, 1 )

STATIC FUNCTION LastSeg( c, cSeps )
   LOCAL i
   FOR i := Len( c ) TO 1 STEP -1
      IF SubStr( c, i, 1 ) $ cSeps
         RETURN SubStr( c, i + 1 )
      ENDIF
   NEXT
RETURN c

/* ---- ClipBoundary ---- */
FUNCTION Cbd_Rectangular( v1, v2 ) ; RETURN hb_Hash( "clip_type", WCT_RECTANGULAR, "clip_mode", CLM_OUTSIDE, "vertices", { v1, v2 } )
FUNCTION Cbd_Polygonal( aV ) ; RETURN hb_Hash( "clip_type", WCT_POLYGONAL, "clip_mode", CLM_OUTSIDE, "vertices", aV )
FUNCTION Cbd_FullImage( nW, nH ) ; RETURN Cbd_Rectangular( Vc2_New( -0.5, -0.5 ), Vc2_New( nW - 0.5, nH - 0.5 ) )
FUNCTION Cbd_Default() ; RETURN hb_Hash( "clip_type", WCT_RECTANGULAR, "clip_mode", CLM_OUTSIDE, "vertices", {} )
FUNCTION Cbd_VertexCount( b ) ; RETURN Len( b[ "vertices" ] )
FUNCTION Cbd_IsRectangular( b ) ; RETURN b[ "clip_type" ] == WCT_RECTANGULAR
FUNCTION Cbd_IsPolygonal( b ) ; RETURN b[ "clip_type" ] == WCT_POLYGONAL
FUNCTION Cbd_BoundingRect( b )
   LOCAL a := b[ "vertices" ], i, vMin, vMax
   IF Len( a ) == 0 ; RETURN NIL ; ENDIF
   vMin := AClone( a[ 1 ] ) ; vMax := AClone( a[ 1 ] )
   FOR i := 2 TO Len( a )
      vMin := { Min( vMin[ 1 ], a[ i ][ 1 ] ), Min( vMin[ 2 ], a[ i ][ 2 ] ) }
      vMax := { Max( vMax[ 1 ], a[ i ][ 1 ] ), Max( vMax[ 2 ], a[ i ][ 2 ] ) }
   NEXT
RETURN { vMin, vMax }

/* ---- RasterImage ---- */
FUNCTION Eri_EntityName() ; RETURN "IMAGE"
FUNCTION Eri_New( cPath, vIns, nWpx, nHpx )
RETURN hb_Hash( "_type", "IMAGE", "common", Ec_New(), "class_version", 0, "insertion_point", vIns, "u_vector", Vc3_New( 1.0, 0.0, 0.0 ), "v_vector", Vc3_New( 0.0, 1.0, 0.0 ), ;
   "size", Vc2_New( nWpx, nHpx ), "flags", hb_bitOr( IDF_SHOW_IMAGE, IDF_USE_CLIPPING_BOUNDARY ), "clipping_enabled", .F., "brightness", 50, "contrast", 50, "fade", 0, ;
   "clip_boundary", Cbd_FullImage( nWpx, nHpx ), "definition_handle", NIL, "definition_reactor_handle", NIL, "file_path", cPath )
FUNCTION Eri_Default() ; RETURN Eri_New( "", Vc3_Zero(), 1.0, 1.0 )
FUNCTION Eri_WithSize( cPath, vIns, nWpx, nHpx, nWw, nHw ) ; LOCAL e := Eri_New( cPath, vIns, nWpx, nHpx ) ; Eri_SetSize( e, nWw, nHw ) ; RETURN e
FUNCTION Eri_Width( e ) ; RETURN Vc3_Length( e[ "u_vector" ] ) * e[ "size" ][ 1 ]
FUNCTION Eri_Height( e ) ; RETURN Vc3_Length( e[ "v_vector" ] ) * e[ "size" ][ 2 ]
FUNCTION Eri_AspectRatio( e ) ; RETURN iif( e[ "size" ][ 2 ] == 0.0, 1.0, e[ "size" ][ 1 ] / e[ "size" ][ 2 ] )
FUNCTION Eri_SetWidth( e, nW ) ; e[ "u_vector" ] := Vc3_Mul( Vc3_Normalize( e[ "u_vector" ] ), nW / e[ "size" ][ 1 ] ) ; RETURN NIL
FUNCTION Eri_SetHeight( e, nH ) ; e[ "v_vector" ] := Vc3_Mul( Vc3_Normalize( e[ "v_vector" ] ), nH / e[ "size" ][ 2 ] ) ; RETURN NIL
FUNCTION Eri_SetSize( e, nW, nH ) ; Eri_SetWidth( e, nW ) ; Eri_SetHeight( e, nH ) ; RETURN NIL
FUNCTION Eri_SetWidthKeepAspect( e, nW ) ; LOCAL nR := Eri_AspectRatio( e ) ; Eri_SetWidth( e, nW ) ; Eri_SetHeight( e, nW / nR ) ; RETURN NIL
FUNCTION Eri_SetHeightKeepAspect( e, nH ) ; LOCAL nR := Eri_AspectRatio( e ) ; Eri_SetHeight( e, nH ) ; Eri_SetWidth( e, nH * nR ) ; RETURN NIL
FUNCTION Eri_PixelSize( e ) ; RETURN { Vc3_Length( e[ "u_vector" ] ), Vc3_Length( e[ "v_vector" ] ) }
FUNCTION Eri_SetPixelSize( e, n ) ; e[ "u_vector" ] := Vc3_Mul( Vc3_Normalize( e[ "u_vector" ] ), n ) ; e[ "v_vector" ] := Vc3_Mul( Vc3_Normalize( e[ "v_vector" ] ), n ) ; RETURN NIL
FUNCTION Eri_IsVisible( e ) ; RETURN hb_bitAnd( e[ "flags" ], IDF_SHOW_IMAGE ) == IDF_SHOW_IMAGE
FUNCTION Eri_SetVisible( e, l ) ; e[ "flags" ] := iif( l, hb_bitOr( e[ "flags" ], IDF_SHOW_IMAGE ), hb_bitAnd( e[ "flags" ], hb_bitNot( IDF_SHOW_IMAGE ) ) ) ; RETURN NIL
FUNCTION Eri_IsTransparent( e ) ; RETURN hb_bitAnd( e[ "flags" ], IDF_TRANSPARENCY_ON ) == IDF_TRANSPARENCY_ON
FUNCTION Eri_SetTransparent( e, l ) ; e[ "flags" ] := iif( l, hb_bitOr( e[ "flags" ], IDF_TRANSPARENCY_ON ), hb_bitAnd( e[ "flags" ], hb_bitNot( IDF_TRANSPARENCY_ON ) ) ) ; RETURN NIL
FUNCTION Eri_Corners( e )
   LOCAL o := e[ "insertion_point" ], u := Vc3_Mul( e[ "u_vector" ], e[ "size" ][ 1 ] ), v := Vc3_Mul( e[ "v_vector" ], e[ "size" ][ 2 ] )
RETURN { o, Vc3_Add( o, u ), Vc3_Add( Vc3_Add( o, u ), v ), Vc3_Add( o, v ) }
FUNCTION Eri_Center( e )
   LOCAL u := Vc3_Mul( e[ "u_vector" ], e[ "size" ][ 1 ] ), v := Vc3_Mul( e[ "v_vector" ], e[ "size" ][ 2 ] )
RETURN Vc3_Add( e[ "insertion_point" ], Vc3_Mul( Vc3_Add( u, v ), 0.5 ) )
/* bounding_box inherente: { vMin, vMax } */
FUNCTION Eri_BoundingBoxPair( e )
   LOCAL a := Eri_Corners( e ), vMin := AClone( a[ 1 ] ), vMax := AClone( a[ 1 ] ), i, c
   FOR i := 2 TO 4
      c := a[ i ]
      vMin := { Min( vMin[ 1 ], c[ 1 ] ), Min( vMin[ 2 ], c[ 2 ] ), Min( vMin[ 3 ], c[ 3 ] ) }
      vMax := { Max( vMax[ 1 ], c[ 1 ] ), Max( vMax[ 2 ], c[ 2 ] ), Max( vMax[ 3 ], c[ 3 ] ) }
   NEXT
RETURN { vMin, vMax }
FUNCTION Eri_BoundingBox( e ) ; LOCAL p := Eri_BoundingBoxPair( e ) ; RETURN Bb3_New( p[ 1 ], p[ 2 ] )
FUNCTION Eri_Translate( e, vOff ) ; e[ "insertion_point" ] := Vc3_Add( e[ "insertion_point" ], vOff ) ; RETURN NIL
FUNCTION Eri_Rotate( e, nA )
   LOCAL nC := OCX_COS( nA ), nS := OCX_SIN( nA ), u := e[ "u_vector" ], v
   e[ "u_vector" ] := Vc3_New( u[ 1 ] * nC - u[ 2 ] * nS, u[ 1 ] * nS + u[ 2 ] * nC, u[ 3 ] )
   v := e[ "v_vector" ]
   e[ "v_vector" ] := Vc3_New( v[ 1 ] * nC - v[ 2 ] * nS, v[ 1 ] * nS + v[ 2 ] * nC, v[ 3 ] )
RETURN NIL
FUNCTION Eri_SetClipRect( e, v1, v2 ) ; e[ "clip_boundary" ] := Cbd_Rectangular( v1, v2 ) ; e[ "clipping_enabled" ] := .T. ; RETURN NIL
FUNCTION Eri_SetClipPolygon( e, aV ) ; e[ "clip_boundary" ] := Cbd_Polygonal( aV ) ; e[ "clipping_enabled" ] := .T. ; RETURN NIL
FUNCTION Eri_ClearClip( e ) ; e[ "clip_boundary" ] := Cbd_FullImage( e[ "size" ][ 1 ], e[ "size" ][ 2 ] ) ; e[ "clipping_enabled" ] := .F. ; RETURN NIL
FUNCTION Eri_FileName( e ) ; RETURN LastSeg( e[ "file_path" ], "/\" )
FUNCTION Eri_FileExtension( e ) ; RETURN LastSeg( e[ "file_path" ], "." )
FUNCTION Eri_Transform( e, t )
   e[ "insertion_point" ] := Tf_Apply( t, e[ "insertion_point" ] )
   e[ "u_vector" ] := Tf_ApplyRotation( t, e[ "u_vector" ] )
   e[ "v_vector" ] := Tf_ApplyRotation( t, e[ "v_vector" ] )
RETURN NIL

/* ---- ImageDefinition ---- */
FUNCTION Idf_New( cPath, nW, nH )
RETURN hb_Hash( "handle", Hd_Null(), "class_version", 0, "file_path", cPath, "size", Vc2_New( nW, nH ), "pixel_size", Vc2_New( 1.0, 1.0 ), "is_loaded", .T., "resolution_unit", RU_NONE )
FUNCTION Idf_Default() ; RETURN Idf_New( "", 1.0, 1.0 )
FUNCTION Idf_AspectRatio( d ) ; RETURN iif( d[ "size" ][ 2 ] == 0.0, 1.0, d[ "size" ][ 1 ] / d[ "size" ][ 2 ] )
FUNCTION Idf_Width( d ) ; RETURN d[ "size" ][ 1 ]
FUNCTION Idf_Height( d ) ; RETURN d[ "size" ][ 2 ]
FUNCTION Idf_FileName( d ) ; RETURN LastSeg( d[ "file_path" ], "/\" )
FUNCTION Idf_SetDpi( d, nDpi ) ; d[ "resolution_unit" ] := RU_INCHES ; d[ "pixel_size" ] := Vc2_New( 1.0 / nDpi, 1.0 / nDpi ) ; RETURN NIL
FUNCTION Idf_Dpi( d )
   IF d[ "resolution_unit" ] == RU_INCHES .AND. d[ "pixel_size" ][ 1 ] > 0.0
      RETURN 1.0 / d[ "pixel_size" ][ 1 ]
   ENDIF
RETURN NIL

/* ---- RasterImageBuilder ---- */
FUNCTION Rib_New( cPath, nW, nH ) ; RETURN hb_Hash( "image", Eri_New( cPath, Vc3_Zero(), nW, nH ) )
FUNCTION Rib_At( b, v ) ; b[ "image" ][ "insertion_point" ] := v ; RETURN b
FUNCTION Rib_Size( b, nW, nH ) ; Eri_SetSize( b[ "image" ], nW, nH ) ; RETURN b
FUNCTION Rib_Width( b, nW ) ; Eri_SetWidthKeepAspect( b[ "image" ], nW ) ; RETURN b
FUNCTION Rib_Height( b, nH ) ; Eri_SetHeightKeepAspect( b[ "image" ], nH ) ; RETURN b
FUNCTION Rib_Rotation( b, nA ) ; Eri_Rotate( b[ "image" ], nA ) ; RETURN b
FUNCTION Rib_Brightness( b, n ) ; b[ "image" ][ "brightness" ] := Min( n, 100 ) ; RETURN b
FUNCTION Rib_Contrast( b, n ) ; b[ "image" ][ "contrast" ] := Min( n, 100 ) ; RETURN b
FUNCTION Rib_Fade( b, n ) ; b[ "image" ][ "fade" ] := Min( n, 100 ) ; RETURN b
FUNCTION Rib_Transparent( b ) ; Eri_SetTransparent( b[ "image" ], .T. ) ; RETURN b
FUNCTION Rib_ClipRect( b, v1, v2 ) ; Eri_SetClipRect( b[ "image" ], v1, v2 ) ; RETURN b
FUNCTION Rib_Build( b ) ; RETURN b[ "image" ]
