/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_underlay.prg
   Origen Rust: opencadcodec/src/entities/underlay.rs (882 lineas, 32 tests en t_codec_underlay.prg) + translate_underlay + transform_underlay. Licencia del original: MPL-2.0.
   Prefijos: Udf_ (UnderlayDefinition), Eul_ (Underlay, _type "UNDERLAY"; Ent_EntityType devuelve PDFUNDERLAY/DWFUNDERLAY/DGNUNDERLAY segun underlay_type).
   UnderlayType = enteros UTY_PDF 0 / UTY_DWF 1 / UTY_DGN 2. Flags = UDF_* (u8). Vector2 = {x,y}. file_exists usa File(); file_extension devuelve NIL si no hay extension.
   Los alias pdf/dwf/dgn (type aliases) no necesitan codigo. La rotacion en grados usa OCX_PI como to_radians/to_degrees.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Uty_EntityName( n ) ; RETURN { "PDFUNDERLAY", "DWFUNDERLAY", "DGNUNDERLAY" }[ n + 1 ]
FUNCTION Uty_DefinitionName( n ) ; RETURN { "PDFDEFINITION", "DWFDEFINITION", "DGNDEFINITION" }[ n + 1 ]
FUNCTION Uty_SubclassMarker() ; RETURN "AcDbUnderlayReference"
FUNCTION Uty_DefinitionSubclassMarker( n ) ; RETURN { "AcDbPdfDefinition", "AcDbDwfDefinition", "AcDbDgnDefinition" }[ n + 1 ]

FUNCTION Udf_New( nType ) ; RETURN hb_Hash( "handle", Hd_Null(), "owner_handle", Hd_Null(), "underlay_type", nType, "file_path", "", "page_name", "", "name", "", "reactors", {}, "unloaded", .F. )
STATIC FUNCTION Udf_Make( nType, cPath, cPage ) ; LOCAL d := Udf_New( nType ) ; d[ "file_path" ] := cPath ; d[ "page_name" ] := cPage ; RETURN d
FUNCTION Udf_Pdf( cPath, cPage ) ; RETURN Udf_Make( UTY_PDF, cPath, cPage )
FUNCTION Udf_Dwf( cPath, cSheet ) ; RETURN Udf_Make( UTY_DWF, cPath, cSheet )
FUNCTION Udf_Dgn( cPath, cModel ) ; RETURN Udf_Make( UTY_DGN, cPath, cModel )
FUNCTION Udf_EntityName( d ) ; RETURN Uty_DefinitionName( d[ "underlay_type" ] )
FUNCTION Udf_SubclassMarker( d ) ; RETURN Uty_DefinitionSubclassMarker( d[ "underlay_type" ] )
FUNCTION Udf_FileExists( d ) ; RETURN hb_FileExists( d[ "file_path" ] ) .OR. hb_DirExists( d[ "file_path" ] )
FUNCTION Udf_FileExtension( d )
   LOCAL cName := d[ "file_path" ], n := RAt( ".", cName ), nSep := Max( RAt( "/", cName ), RAt( "\", cName ) )
   IF n == 0 .OR. n < nSep .OR. n == 1 .OR. n == nSep + 1 ; RETURN NIL ; ENDIF
RETURN SubStr( cName, n + 1 )

FUNCTION Eul_Entity( nType )
RETURN hb_Hash( "_type", "UNDERLAY", "common", Ec_New(), "underlay_type", nType, "definition_handle", Hd_Null(), "insertion_point", Vc3_Zero(), "x_scale", 1.0, "y_scale", 1.0, "z_scale", 1.0, ;
   "rotation", 0.0, "normal", Vc3_UnitZ(), "flags", UDF_DEFAULT, "contrast", 100, "fade", 0, "clip_boundary_vertices", {}, "clip_inverted", .F. )
FUNCTION Eul_New( nType ) ; RETURN Eul_Entity( nType )
FUNCTION Eul_Pdf() ; RETURN Eul_Entity( UTY_PDF )
FUNCTION Eul_Dwf() ; RETURN Eul_Entity( UTY_DWF )
FUNCTION Eul_Dgn() ; RETURN Eul_Entity( UTY_DGN )
FUNCTION Eul_AtPoint( nType, v ) ; LOCAL e := Eul_Entity( nType ) ; e[ "insertion_point" ] := v ; RETURN e
FUNCTION Eul_PdfAt( v ) ; RETURN Eul_AtPoint( UTY_PDF, v )
FUNCTION Eul_DwfAt( v ) ; RETURN Eul_AtPoint( UTY_DWF, v )
FUNCTION Eul_DgnAt( v ) ; RETURN Eul_AtPoint( UTY_DGN, v )
FUNCTION Eul_WithScale( nType, v, n ) ; LOCAL e := Eul_AtPoint( nType, v ) ; Eul_SetScale( e, n ) ; RETURN e
FUNCTION Eul_EntityName( e ) ; RETURN Uty_EntityName( e[ "underlay_type" ] )
FUNCTION Eul_SubclassMarker() ; RETURN "AcDbUnderlayReference"
FUNCTION Eul_SetScale( e, n ) ; e[ "x_scale" ] := n ; e[ "y_scale" ] := n ; e[ "z_scale" ] := n ; RETURN NIL
FUNCTION Eul_SetScaleXyz( e, x, y, z ) ; e[ "x_scale" ] := x ; e[ "y_scale" ] := y ; e[ "z_scale" ] := z ; RETURN NIL
/* uniform_scale: devuelve NIL si no es uniforme */
FUNCTION Eul_UniformScale( e )
   IF Abs( e[ "x_scale" ] - e[ "y_scale" ] ) < 0.0000000001 .AND. Abs( e[ "y_scale" ] - e[ "z_scale" ] ) < 0.0000000001 ; RETURN e[ "x_scale" ] ; ENDIF
RETURN NIL
FUNCTION Eul_SetRotationDegrees( e, n ) ; e[ "rotation" ] := n * ( OCX_PI / 180.0 ) ; RETURN NIL
FUNCTION Eul_RotationDegrees( e ) ; RETURN e[ "rotation" ] * ( 180.0 / OCX_PI )
FUNCTION Eul_SetRectangularClip( e, vMin, vMax )
   e[ "clip_boundary_vertices" ] := { { vMin[ 1 ], vMin[ 2 ] }, { vMax[ 1 ], vMin[ 2 ] }, { vMax[ 1 ], vMax[ 2 ] }, { vMin[ 1 ], vMax[ 2 ] } }
   e[ "flags" ] := hb_bitOr( e[ "flags" ], UDF_CLIPPING )
RETURN NIL
FUNCTION Eul_SetPolygonClip( e, aV )
   LOCAL v
   IF Len( aV ) >= 3
      e[ "clip_boundary_vertices" ] := {}
      FOR EACH v IN aV
         AAdd( e[ "clip_boundary_vertices" ], AClone( v ) )
      NEXT
      e[ "flags" ] := hb_bitOr( e[ "flags" ], UDF_CLIPPING )
   ENDIF
RETURN NIL
FUNCTION Eul_ClearClip( e ) ; e[ "clip_boundary_vertices" ] := {} ; e[ "flags" ] := hb_bitAnd( e[ "flags" ], hb_bitNot( UDF_CLIPPING ) ) ; RETURN NIL
FUNCTION Eul_IsClipping( e ) ; RETURN hb_bitAnd( e[ "flags" ], UDF_CLIPPING ) != 0
FUNCTION Eul_IsOn( e ) ; RETURN hb_bitAnd( e[ "flags" ], UDF_ON ) != 0
FUNCTION Eul_SetOn( e, l ) ; e[ "flags" ] := iif( l, hb_bitOr( e[ "flags" ], UDF_ON ), hb_bitAnd( e[ "flags" ], hb_bitNot( UDF_ON ) ) ) ; RETURN NIL
FUNCTION Eul_IsMonochrome( e ) ; RETURN hb_bitAnd( e[ "flags" ], UDF_MONOCHROME ) != 0
FUNCTION Eul_SetMonochrome( e, l ) ; e[ "flags" ] := iif( l, hb_bitOr( e[ "flags" ], UDF_MONOCHROME ), hb_bitAnd( e[ "flags" ], hb_bitNot( UDF_MONOCHROME ) ) ) ; RETURN NIL
FUNCTION Eul_SetContrast( e, n ) ; e[ "contrast" ] := Min( n, 100 ) ; RETURN NIL
FUNCTION Eul_SetFade( e, n ) ; e[ "fade" ] := Min( n, 100 ) ; RETURN NIL
FUNCTION Eul_DisplayFlags( e ) ; RETURN iif( e[ "clip_inverted" ], hb_bitOr( e[ "flags" ], UDF_CLIP_INSIDE ), hb_bitAnd( e[ "flags" ], hb_bitNot( UDF_CLIP_INSIDE ) ) )
FUNCTION Eul_WorldClipBoundary( e )
   LOCAL c := OCX_COS( e[ "rotation" ] ), s := OCX_SIN( e[ "rotation" ] ), a := {}, v, x, y
   FOR EACH v IN e[ "clip_boundary_vertices" ]
      x := v[ 1 ] * e[ "x_scale" ] ; y := v[ 2 ] * e[ "y_scale" ]
      AAdd( a, Vc3_Add( e[ "insertion_point" ], Vc3_New( x * c - y * s, x * s + y * c, 0.0 ) ) )
   NEXT
RETURN a
FUNCTION Eul_ClipVertexCount( e ) ; RETURN Len( e[ "clip_boundary_vertices" ] )
FUNCTION Eul_BoundingBox( e )
   LOCAL w, mn, mx, i
   IF Len( e[ "clip_boundary_vertices" ] ) == 0 ; RETURN Bb3_New( e[ "insertion_point" ], e[ "insertion_point" ] ) ; ENDIF
   w := Eul_WorldClipBoundary( e ) ; mn := AClone( w[ 1 ] ) ; mx := AClone( w[ 1 ] )
   FOR i := 2 TO Len( w )
      mn[ 1 ] := Min( mn[ 1 ], w[ i ][ 1 ] ) ; mn[ 2 ] := Min( mn[ 2 ], w[ i ][ 2 ] ) ; mn[ 3 ] := Min( mn[ 3 ], w[ i ][ 3 ] )
      mx[ 1 ] := Max( mx[ 1 ], w[ i ][ 1 ] ) ; mx[ 2 ] := Max( mx[ 2 ], w[ i ][ 2 ] ) ; mx[ 3 ] := Max( mx[ 3 ], w[ i ][ 3 ] )
   NEXT
RETURN Bb3_New( mn, mx )
FUNCTION Eul_Translate( e, vOff ) ; e[ "insertion_point" ] := Vc3_Add( e[ "insertion_point" ], vOff ) ; RETURN NIL
FUNCTION Eul_Transform( e, t )
   LOCAL nS := Vc3_Length( Tf_ApplyRotation( t, Vc3_New( 1.0, 0.0, 0.0 ) ) )
   e[ "insertion_point" ] := Tf_Apply( t, e[ "insertion_point" ] )
   e[ "normal" ] := Vc3_Normalize( Tf_ApplyRotation( t, e[ "normal" ] ) )
   e[ "x_scale" ] *= nS ; e[ "y_scale" ] *= nS ; e[ "z_scale" ] *= nS
RETURN NIL
