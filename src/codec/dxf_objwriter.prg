/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/dxf_objwriter.prg
   Origen Rust: opencadcodec/src/io/dxf/writer/section_writer.rs (write_objects, write_dictionary, write_layout,
   find_root_dict_handle). Licencia del original: MPL-2.0. Prefijo Dxo_.
   PENDIENTE: solo se escriben DICTIONARY, LAYOUT, XRECORD, GROUP y MLINESTYLE (sin las entradas avanzadas de MATERIAL en XRECORD); el resto de tipos, valid_handles y xdata de objetos no estan portados.
   El original no tiene #[test] para estas funciones; los tests [extra] estan en t_dxf_rw.prg.
----------------------------------------------------------------------------*/
#include "ocx.ch"

/* valid_handles del escritor (se fija en Dxo_WriteObjects; vacio = sin filtro) y handle del diccionario raiz (find_root_dict_handle) */
STATIC s_hValid := NIL
STATIC s_nRoot := 0
STATIC FUNCTION Dxo_Valid( h ) ; RETURN s_hValid == NIL .OR. Len( s_hValid ) == 0 .OR. hb_HHasKey( s_hValid, h )

STATIC FUNCTION Dxo_FindRootDictHandle( d )
   LOCAL nBest := 0, nCount := 0, h, o
   FOR EACH h IN hb_HKeys( d[ "objects" ] )
      o := d[ "objects" ][ h ]
      IF o[ "_type" ] == "Dictionary" .AND. Hd_IsNull( o[ "owner" ] )
         IF Len( o[ "entries" ] ) > nCount .OR. ( Len( o[ "entries" ] ) == nCount .AND. h > nBest )
            nBest := h ; nCount := Len( o[ "entries" ] )
         ENDIF
      ENDIF
   NEXT
RETURN nBest

/* tipos de objeto que este escritor emite: las entradas de diccionario a otros tipos se omiten (equivale al filtro valid_handles de Rust) */
STATIC FUNCTION Dxo_IsWritten( o ) ; RETURN o[ "_type" ] == "Dictionary" .OR. o[ "_type" ] == "Layout" .OR. o[ "_type" ] == "XRecord" .OR. o[ "_type" ] == "Group" .OR. o[ "_type" ] == "MLineStyle" .OR. o[ "_type" ] == "SortEntitiesTable" .OR. o[ "_type" ] == "ImageDefinition" .OR. o[ "_type" ] == "UnderlayDefinition" .OR. o[ "_type" ] == "MultiLeaderStyle" .OR. o[ "_type" ] == "PlotSettings" .OR. o[ "_type" ] == "Scale" .OR. o[ "_type" ] == "DictionaryVariable" .OR. o[ "_type" ] == "DictionaryWithDefault" .OR. o[ "_type" ] == "PlaceHolder" .OR. o[ "_type" ] == "SpatialFilter"

STATIC PROCEDURE Dxo_WriteDictionary( w, d, dic )
   LOCAL aR := dic[ "reactors" ], hX, e, lForced, aV, hO
   IF Len( aR ) == 0 ; aR := hb_HGetDef( d[ "reactors_by_handle" ], dic[ "handle" ], {} ) ; ENDIF
   Sw_WriteString( w, 0, "DICTIONARY" ) ; Sw_WriteHandle( w, 5, dic[ "handle" ] )
   aV := {}
   FOR EACH e IN aR
      IF ! Hd_IsNull( e ) .AND. Dxo_Valid( e ) ; AAdd( aV, e ) ; ENDIF
   NEXT
   aR := aV
   IF Len( aR ) > 0
      Sw_WriteString( w, 102, "{ACAD_REACTORS" )
      FOR EACH e IN aR
         IF ! Hd_IsNull( e ) ; Sw_WriteHandle( w, 330, e ) ; ENDIF
      NEXT
      Sw_WriteString( w, 102, "}" )
   ENDIF
   hX := dic[ "xdictionary_handle" ]
   IF hX == NIL ; hX := Doc_ExtensionDictionaryHandle( d, dic[ "handle" ] ) ; ENDIF
   IF hX != NIL .AND. ! Hd_IsNull( hX ) .AND. Dxo_Valid( hX )
      Sw_WriteString( w, 102, "{ACAD_XDICTIONARY" ) ; Sw_WriteHandle( w, 360, hX ) ; Sw_WriteString( w, 102, "}" )
   ENDIF
   hO := dic[ "owner" ]
   IF ! ( Hd_IsNull( hO ) .OR. Dxo_Valid( hO ) .OR. Hd_IsNull( s_nRoot ) ) ; hO := s_nRoot ; ENDIF
   Sw_WriteHandle( w, 330, hO )
   Sw_WriteSubclass( w, "AcDbDictionary" )
   Sw_WriteByte( w, 280, IIf( dic[ "hard_owner" ], 1, 0 ) ) ; Sw_WriteByte( w, 281, dic[ "duplicate_cloning" ] )
   FOR EACH e IN dic[ "entries" ]
      IF hb_HHasKey( d[ "objects" ], e[ 2 ] ) .AND. Dxo_Valid( e[ 2 ] ) .AND. Dxo_IsWritten( d[ "objects" ][ e[ 2 ] ] )
         Sw_WriteString( w, 3, e[ 1 ] )
         lForced := Dic_IsEntryHardOwner( dic, e[ 1 ] ) .OR. Dic_IsCanonicalHardOwnerKey( e[ 1 ] )
         Sw_WriteHandle( w, IIf( dic[ "hard_owner" ] .OR. lForced, 360, 350 ), e[ 2 ] )
      ENDIF
   NEXT
RETURN

/* write_stub_handle_only("ACDBPLACEHOLDER") */
STATIC PROCEDURE Dxo_WritePlaceHolder( w, o, nVer )
   Sw_WriteString( w, 0, "ACDBPLACEHOLDER" ) ; Sw_WriteHandle( w, 5, o[ "handle" ] )
   Sw_WriteString( w, 102, "{ACAD_REACTORS" ) ; Sw_WriteHandle( w, 330, o[ "owner" ] ) ; Sw_WriteString( w, 102, "}" )
   Sw_WriteHandle( w, 330, o[ "owner" ] )
   IF nVer < Dxv_FromVersionString( "AC1015" ) ; Sw_WriteSubclass( w, "AcDbPlaceHolder" ) ; ENDIF
RETURN

/* write_spatial_filter + write_matrix_column_major */
STATIC PROCEDURE Dxo_WriteSpatialFilter( w, d, o )
   LOCAL pt, hX, nC, nR, a
   Sw_WriteString( w, 0, "SPATIAL_FILTER" ) ; Sw_WriteHandle( w, 5, o[ "handle" ] )
   hX := Doc_ExtensionDictionaryHandle( d, o[ "handle" ] )
   IF hX != NIL .AND. ! Hd_IsNull( hX ) .AND. Dxo_Valid( hX )
      Sw_WriteString( w, 102, "{ACAD_XDICTIONARY" ) ; Sw_WriteHandle( w, 360, hX ) ; Sw_WriteString( w, 102, "}" )
   ENDIF
   Sw_WriteHandle( w, 330, o[ "owner" ] )
   Sw_WriteSubclass( w, "AcDbFilter" ) ; Sw_WriteSubclass( w, "AcDbSpatialFilter" )
   Sw_WriteI16( w, 70, Len( o[ "boundary_points" ] ) )
   FOR EACH pt IN o[ "boundary_points" ] ; Sw_WritePoint2d( w, 10, pt ) ; NEXT
   Sw_WritePoint3d( w, 210, o[ "normal" ] ) ; Sw_WritePoint3d( w, 11, o[ "origin" ] )
   Sw_WriteI16( w, 71, IIf( o[ "display_enabled" ], 1, 0 ) )
   Sw_WriteI16( w, 72, IIf( o[ "front_clip" ] != NIL, 1, 0 ) )
   IF o[ "front_clip" ] != NIL ; Sw_WriteDouble( w, 40, o[ "front_clip" ] ) ; ENDIF
   Sw_WriteI16( w, 73, IIf( o[ "back_clip" ] != NIL, 1, 0 ) )
   IF o[ "back_clip" ] != NIL ; Sw_WriteDouble( w, 41, o[ "back_clip" ] ) ; ENDIF
   FOR EACH a IN { o[ "inverse_block_transform" ], o[ "clip_bound_transform" ] }
      FOR nC := 1 TO 4
         FOR nR := 1 TO 3 ; Sw_WriteDouble( w, 40, a[ nR ][ nC ] ) ; NEXT
      NEXT
   NEXT
RETURN

/* write_dict_with_default (sin 280: BricsCAD issue #51) */
STATIC PROCEDURE Dxo_WriteDictWithDefault( w, d, o )
   LOCAL e
   Sw_WriteString( w, 0, "ACDBDICTIONARYWDFLT" ) ; Sw_WriteHandle( w, 5, o[ "handle" ] )
   Sw_WriteHandle( w, 330, o[ "owner" ] )
   Sw_WriteSubclass( w, "AcDbDictionary" )
   Sw_WriteByte( w, 281, o[ "duplicate_cloning" ] )
   FOR EACH e IN o[ "entries" ]
      IF hb_HHasKey( d[ "objects" ], e[ 2 ] )
         Sw_WriteString( w, 3, e[ 1 ] ) ; Sw_WriteHandle( w, 350, e[ 2 ] )
      ENDIF
   NEXT
   Sw_WriteSubclass( w, "AcDbDictionaryWithDefault" )
   Sw_WriteHandle( w, 340, o[ "default_handle" ] )
RETURN

STATIC PROCEDURE Dxo_WriteLayout( w, l )
   LOCAL x, nF, aV
   Sw_WriteString( w, 0, "LAYOUT" ) ; Sw_WriteHandle( w, 5, l[ "handle" ] )
   IF l[ "xdictionary_handle" ] != NIL .AND. ! Hd_IsNull( l[ "xdictionary_handle" ] ) .AND. Dxo_Valid( l[ "xdictionary_handle" ] )
      Sw_WriteString( w, 102, "{ACAD_XDICTIONARY" ) ; Sw_WriteHandle( w, 360, l[ "xdictionary_handle" ] ) ; Sw_WriteString( w, 102, "}" )
   ENDIF
   aV := {}
   FOR EACH x IN l[ "reactors" ]
      IF Dxo_Valid( x ) ; AAdd( aV, x ) ; ENDIF
   NEXT
   IF Len( aV ) > 0
      Sw_WriteString( w, 102, "{ACAD_REACTORS" )
      FOR EACH x IN aV ; Sw_WriteHandle( w, 330, x ) ; NEXT
      Sw_WriteString( w, 102, "}" )
   ENDIF
   Sw_WriteHandle( w, 330, l[ "owner" ] )
   Sw_WriteSubclass( w, "AcDbPlotSettings" )
   IF l[ "raw_plot_settings_codes" ] != NIL
      FOR EACH x IN l[ "raw_plot_settings_codes" ] ; Sw_WriteString( w, x[ 1 ], x[ 2 ] ) ; NEXT
   ELSE
      Sw_WriteString( w, 1, l[ "plot_page_name" ] ) ; Sw_WriteString( w, 2, l[ "plot_printer_name" ] ) ; Sw_WriteString( w, 4, l[ "paper_size" ] )
      Sw_WriteString( w, 6, l[ "plot_view_name" ] ) ; Sw_WriteString( w, 7, l[ "plot_style_sheet" ] )
      Sw_WriteDouble( w, 40, l[ "plot_margin_left" ] )
      Sw_WriteDouble( w, 41, l[ "plot_margin_bottom" ] )
      Sw_WriteDouble( w, 42, l[ "plot_margin_right" ] )
      Sw_WriteDouble( w, 43, l[ "plot_margin_top" ] )
      Sw_WriteDouble( w, 44, l[ "paper_width" ] )
      Sw_WriteDouble( w, 45, l[ "paper_height" ] )
      Sw_WriteDouble( w, 46, l[ "plot_origin_x" ] )
      Sw_WriteDouble( w, 47, l[ "plot_origin_y" ] )
      Sw_WriteDouble( w, 48, l[ "plot_window_min_x" ] )
      Sw_WriteDouble( w, 49, l[ "plot_window_min_y" ] )
      Sw_WriteDouble( w, 140, l[ "plot_window_max_x" ] )
      Sw_WriteDouble( w, 141, l[ "plot_window_max_y" ] )
      Sw_WriteDouble( w, 142, l[ "plot_scale_numerator" ] )
      Sw_WriteDouble( w, 143, l[ "plot_scale_denominator" ] )
      Sw_WriteDouble( w, 147, l[ "plot_scale_factor" ] )
      Sw_WriteDouble( w, 148, l[ "paper_image_origin_x" ] )
      Sw_WriteDouble( w, 149, l[ "paper_image_origin_y" ] )
      nF := Pfl_ToBits( l[ "plot_flags" ] )
      IF l[ "name" ] == "Model" ; nF := hb_bitOr( nF, 1024 ) ; ENDIF
      Sw_WriteI16( w, 70, nF )
      Sw_WriteI16( w, 72, l[ "plot_paper_units" ] )
      Sw_WriteI16( w, 73, l[ "plot_rotation" ] )
      Sw_WriteI16( w, 74, l[ "plot_type" ] )
      Sw_WriteI16( w, 75, l[ "plot_scale_type" ] )
      Sw_WriteI16( w, 76, l[ "shade_plot_mode" ] )
      Sw_WriteI16( w, 77, l[ "shade_plot_resolution" ] )
      Sw_WriteI16( w, 78, l[ "shade_plot_dpi" ] )
      IF ! Hd_IsNull( l[ "visual_style_handle" ] ) ; Sw_WriteHandle( w, 333, l[ "visual_style_handle" ] ) ; ENDIF
   ENDIF
   Sw_WriteSubclass( w, "AcDbLayout" )
   Sw_WriteString( w, 1, l[ "name" ] ) ; Sw_WriteI16( w, 70, l[ "flags" ] ) ; Sw_WriteI16( w, 71, l[ "tab_order" ] )
   Sw_WriteDouble( w, 10, l[ "min_limits" ][ 1 ] )
   Sw_WriteDouble( w, 20, l[ "min_limits" ][ 2 ] )
   Sw_WriteDouble( w, 11, l[ "max_limits" ][ 1 ] )
   Sw_WriteDouble( w, 21, l[ "max_limits" ][ 2 ] )
   Sw_WriteDouble( w, 12, l[ "insertion_base" ][ 1 ] )
   Sw_WriteDouble( w, 22, l[ "insertion_base" ][ 2 ] )
   Sw_WriteDouble( w, 32, l[ "insertion_base" ][ 3 ] )
   Sw_WriteDouble( w, 14, l[ "min_extents" ][ 1 ] )
   Sw_WriteDouble( w, 24, l[ "min_extents" ][ 2 ] )
   Sw_WriteDouble( w, 34, l[ "min_extents" ][ 3 ] )
   Sw_WriteDouble( w, 15, l[ "max_extents" ][ 1 ] )
   Sw_WriteDouble( w, 25, l[ "max_extents" ][ 2 ] )
   Sw_WriteDouble( w, 35, l[ "max_extents" ][ 3 ] )
   Sw_WriteDouble( w, 146, l[ "elevation" ] )
   Sw_WriteDouble( w, 13, l[ "ucs_origin" ][ 1 ] )
   Sw_WriteDouble( w, 23, l[ "ucs_origin" ][ 2 ] )
   Sw_WriteDouble( w, 33, l[ "ucs_origin" ][ 3 ] )
   Sw_WriteDouble( w, 16, l[ "ucs_x_axis" ][ 1 ] )
   Sw_WriteDouble( w, 26, l[ "ucs_x_axis" ][ 2 ] )
   Sw_WriteDouble( w, 36, l[ "ucs_x_axis" ][ 3 ] )
   Sw_WriteDouble( w, 17, l[ "ucs_y_axis" ][ 1 ] )
   Sw_WriteDouble( w, 27, l[ "ucs_y_axis" ][ 2 ] )
   Sw_WriteDouble( w, 37, l[ "ucs_y_axis" ][ 3 ] )
   Sw_WriteI16( w, 76, l[ "ucs_ortho_type" ] )
   Sw_WriteHandle( w, 330, l[ "block_record" ] )
   IF ! Hd_IsNull( l[ "viewport" ] ) ; Sw_WriteHandle( w, 331, l[ "viewport" ] ) ; ENDIF
   IF ! Hd_IsNull( l[ "named_ucs" ] ) ; Sw_WriteHandle( w, 345, l[ "named_ucs" ] ) ; ENDIF
   IF ! Hd_IsNull( l[ "base_ucs" ] ) ; Sw_WriteHandle( w, 346, l[ "base_ucs" ] ) ; ENDIF
RETURN

STATIC PROCEDURE Dxo_WriteXRecord( w, x )
   LOCAL e, v, k, r
   Sw_WriteString( w, 0, "XRECORD" ) ; Sw_WriteHandle( w, 5, x[ "handle" ] )
   IF Len( x[ "reactors" ] ) > 0
      Sw_WriteString( w, 102, "{ACAD_REACTORS" )
      FOR EACH r IN x[ "reactors" ] ; Sw_WriteHandle( w, 330, r ) ; NEXT
      Sw_WriteString( w, 102, "}" )
   ENDIF
   IF x[ "xdictionary_handle" ] != NIL
      Sw_WriteString( w, 102, "{ACAD_XDICTIONARY" ) ; Sw_WriteHandle( w, 360, x[ "xdictionary_handle" ] ) ; Sw_WriteString( w, 102, "}" )
   ENDIF
   Sw_WriteHandle( w, 330, x[ "owner" ] )
   Sw_WriteSubclass( w, "AcDbXrecord" )
   Sw_WriteByte( w, 280, Dcf_ToCode( x[ "cloning_flags" ] ) )
   FOR EACH e IN x[ "entries" ]
      v := e[ "value" ] ; k := v[ "_kind" ]
      DO CASE
      CASE k == "String" ; Sw_WriteXRecordString( w, e[ "code" ], v[ "value" ] )
      CASE k == "Double" ; Sw_WriteDouble( w, e[ "code" ], v[ "value" ] )
      CASE k == "Int16" ; Sw_WriteI16( w, e[ "code" ], v[ "value" ] )
      CASE k == "Int32" ; Sw_WriteI32( w, e[ "code" ], v[ "value" ] )
      CASE k == "Int64" ; Sw_WriteI64( w, e[ "code" ], v[ "value" ] )
      CASE k == "Byte" ; Sw_WriteByte( w, e[ "code" ], v[ "value" ] )
      CASE k == "Bool" ; Sw_WriteBool( w, e[ "code" ], v[ "value" ] )
      CASE k == "Handle" ; Sw_WriteHandle( w, e[ "code" ], v[ "value" ] )
      CASE k == "Point3D"
         Sw_WriteDouble( w, e[ "code" ], v[ "value" ][ 1 ] ) ; Sw_WriteDouble( w, e[ "code" ] + 10, v[ "value" ][ 2 ] ) ; Sw_WriteDouble( w, e[ "code" ] + 20, v[ "value" ][ 3 ] )
      CASE k == "Chunk" ; Sw_WriteBinary( w, e[ "code" ], v[ "value" ] )
      ENDCASE
   NEXT
RETURN

STATIC FUNCTION Dxo_ColorIndex( c )
   DO CASE
   CASE c[ 1 ] == CK_BYLAYER ; RETURN 256
   CASE c[ 1 ] == CK_NONE ; RETURN 257
   CASE c[ 1 ] == CK_BYBLOCK ; RETURN 0
   CASE c[ 1 ] == CK_INDEX ; RETURN c[ 2 ]
   ENDCASE
RETURN 256

STATIC PROCEDURE Dxo_WriteMLineStyle( w, st )
   LOCAL e
   Sw_WriteString( w, 0, "MLINESTYLE" ) ; Sw_WriteHandle( w, 5, st[ "handle" ] ) ; Sw_WriteHandle( w, 330, st[ "owner" ] )
   Sw_WriteSubclass( w, "AcDbMlineStyle" )
   Sw_WriteString( w, 2, st[ "name" ] ) ; Sw_WriteI16( w, 70, Mlsf_ToBits( st[ "flags" ] ) ) ; Sw_WriteString( w, 3, st[ "description" ] )
   Sw_WriteI16( w, 62, Dxo_ColorIndex( st[ "fill_color" ] ) )
   Sw_WriteDouble( w, 51, st[ "start_angle" ] * ( 180.0 / OCX_PI ) ) ; Sw_WriteDouble( w, 52, st[ "end_angle" ] * ( 180.0 / OCX_PI ) )
   Sw_WriteI16( w, 71, Len( st[ "elements" ] ) )
   FOR EACH e IN st[ "elements" ]
      Sw_WriteDouble( w, 49, e[ "offset" ] ) ; Sw_WriteI16( w, 62, Dxo_ColorIndex( e[ "color" ] ) ) ; Sw_WriteString( w, 6, e[ "linetype" ] )
   NEXT
RETURN

STATIC PROCEDURE Dxo_WriteScale( w, sc )
   Sw_WriteString( w, 0, "SCALE" ) ; Sw_WriteHandle( w, 5, sc[ "handle" ] ) ; Sw_WriteHandle( w, 330, sc[ "owner_handle" ] )
   Sw_WriteSubclass( w, "AcDbScale" ) ; Sw_WriteI16( w, 70, 0 ) ; Sw_WriteString( w, 300, sc[ "name" ] )
   Sw_WriteDouble( w, 140, sc[ "paper_units" ] ) ; Sw_WriteDouble( w, 141, sc[ "drawing_units" ] ) ; Sw_WriteBool( w, 290, sc[ "is_unit_scale" ] )
RETURN

STATIC PROCEDURE Dxo_WriteDictVar( w, dv )
   Sw_WriteString( w, 0, "DICTIONARYVAR" ) ; Sw_WriteHandle( w, 5, dv[ "handle" ] )
   IF ! Hd_IsNull( dv[ "owner_handle" ] )
      Sw_WriteString( w, 102, "{ACAD_REACTORS" ) ; Sw_WriteHandle( w, 330, dv[ "owner_handle" ] ) ; Sw_WriteString( w, 102, "}" )
   ENDIF
   Sw_WriteHandle( w, 330, dv[ "owner_handle" ] ) ; Sw_WriteSubclass( w, "DictionaryVariables" )
   Sw_WriteByte( w, 280, dv[ "schema_number" ] ) ; Sw_WriteString( w, 1, dv[ "value" ] )
RETURN

STATIC PROCEDURE Dxo_WriteSortEnts( w, d, t, nVer )
   LOCAL c, aE := t[ "entries" ], aIdx := {}, aNew, i
   Sw_WriteString( w, 0, "SORTENTSTABLE" )
   IF t[ "raw_dxf_version" ] != NIL .AND. t[ "raw_dxf_version" ] == nVer .AND. t[ "raw_dxf_codes" ] != NIL
      FOR EACH c IN t[ "raw_dxf_codes" ] ; Sw_WriteString( w, c[ 1 ], c[ 2 ] ) ; NEXT
      RETURN
   ENDIF
   Sw_WriteHandle( w, 5, t[ "handle" ] ) ; Sw_WriteHandle( w, 330, t[ "owner_handle" ] )
   Sw_WriteSubclass( w, "AcDbSortentsTable" ) ; Sw_WriteHandle( w, 330, t[ "block_owner_handle" ] )
   FOR i := 1 TO Len( aE ) ; AAdd( aIdx, { aE[ i ][ "sort_handle" ], i } ) ; NEXT
   ASort( aIdx,,, {| x, y | x[ 1 ] < y[ 1 ] .OR. ( x[ 1 ] == y[ 1 ] .AND. x[ 2 ] < y[ 2 ] ) } )
   aNew := Array( Len( aE ) )
   FOR EACH c IN aIdx ; aNew[ c[ 2 ] ] := Doc_AllocateHandle( d ) ; NEXT
   FOR i := 1 TO Len( aE )
      Sw_WriteHandle( w, 331, aE[ i ][ "entity_handle" ] ) ; Sw_WriteHandle( w, 5, aNew[ i ] )
   NEXT
RETURN

STATIC PROCEDURE Dxo_WriteImageDef( w, df )
   Sw_WriteString( w, 0, "IMAGEDEF" ) ; Sw_WriteHandle( w, 5, df[ "handle" ] ) ; Sw_WriteHandle( w, 330, df[ "owner" ] )
   Sw_WriteSubclass( w, "AcDbRasterImageDef" ) ; Sw_WriteI32( w, 90, df[ "class_version" ] ) ; Sw_WriteString( w, 1, df[ "file_name" ] )
   Sw_WriteDouble( w, 10, df[ "size_in_pixels" ][ 1 ] + 0.0 ) ; Sw_WriteDouble( w, 20, df[ "size_in_pixels" ][ 2 ] + 0.0 )
   Sw_WriteDouble( w, 11, df[ "pixel_size" ][ 1 ] ) ; Sw_WriteDouble( w, 21, df[ "pixel_size" ][ 2 ] )
   Sw_WriteByte( w, 280, IIf( df[ "is_loaded" ], 1, 0 ) ) ; Sw_WriteByte( w, 281, Rsu_ToCode( df[ "resolution_unit" ] ) )
RETURN

STATIC PROCEDURE Dxo_WriteUnderlayDef( w, df )
   LOCAL h
   Sw_WriteString( w, 0, Udf_EntityName( df ) ) ; Sw_WriteHandle( w, 5, df[ "handle" ] )
   IF Len( df[ "reactors" ] ) > 0
      Sw_WriteString( w, 102, "{ACAD_REACTORS" )
      FOR EACH h IN df[ "reactors" ] ; Sw_WriteHandle( w, 330, h ) ; NEXT
      Sw_WriteString( w, 102, "}" )
   ENDIF
   Sw_WriteHandle( w, 330, df[ "owner_handle" ] ) ; Sw_WriteSubclass( w, Udf_SubclassMarker( df ) )
   Sw_WriteString( w, 1, df[ "file_path" ] ) ; Sw_WriteString( w, 2, df[ "page_name" ] )
   IF df[ "unloaded" ] ; Sw_WriteString( w, 1001, "ACAD" ) ; Sw_WriteString( w, 1000, "NOLOAD" ) ; ENDIF
RETURN

/* write_color_i32 */
STATIC PROCEDURE Dxo_WriteColorI32( w, nCode, c )
   LOCAL n
   DO CASE
   CASE c[ 1 ] == CK_BYLAYER ; n := 3221225472
   CASE c[ 1 ] == CK_BYBLOCK ; n := 3238002688
   CASE c[ 1 ] == CK_RGB ; n := 3254779904 + c[ 2 ] * 65536 + c[ 3 ] * 256 + c[ 4 ]
   CASE c[ 1 ] == CK_INDEX ; n := 3271557120 + c[ 2 ]
   OTHERWISE ; n := 3355443200
   ENDCASE
   IF n >= 2147483648 ; n -= 4294967296 ; ENDIF
   Sw_WriteI32( w, nCode, n )
RETURN

STATIC PROCEDURE Dxo_WriteMLeaderStyle( w, d, st )
   LOCAL h := st[ "line_type_handle" ], lt
   Sw_WriteString( w, 0, "MLEADERSTYLE" ) ; Sw_WriteHandle( w, 5, st[ "handle" ] ) ; Sw_WriteHandle( w, 330, st[ "owner_handle" ] )
   Sw_WriteSubclass( w, "AcDbMLeaderStyle" )
   Sw_WriteI16( w, 170, st[ "content_type" ] ) ; Sw_WriteI16( w, 171, st[ "multileader_draw_order" ] ) ; Sw_WriteI16( w, 172, st[ "leader_draw_order" ] )
   Sw_WriteI32( w, 90, st[ "max_leader_points" ] ) ; Sw_WriteDouble( w, 40, st[ "first_segment_angle" ] ) ; Sw_WriteDouble( w, 41, st[ "second_segment_angle" ] )
   Sw_WriteI16( w, 173, st[ "path_type" ] ) ; Dxo_WriteColorI32( w, 91, st[ "line_color" ] )
   IF h == NIL .OR. Hd_IsNull( h )
      lt := Tb_Get( d[ "line_types" ], "ByLayer" )
      h := IIf( lt != NIL, lt[ "handle" ], Hd_Null() )
   ENDIF
   IF ! Hd_IsNull( h ) ; Sw_WriteHandle( w, 340, h ) ; ENDIF
   Sw_WriteI32( w, 92, Lw_GetValue( st[ "line_weight" ] ) ) ; Sw_WriteBool( w, 290, st[ "enable_landing" ] ) ; Sw_WriteDouble( w, 42, st[ "landing_gap" ] )
   Sw_WriteBool( w, 291, st[ "enable_dogleg" ] ) ; Sw_WriteDouble( w, 43, st[ "landing_distance" ] ) ; Sw_WriteString( w, 3, st[ "name" ] )
   IF st[ "arrowhead_handle" ] != NIL ; Sw_WriteHandle( w, 341, st[ "arrowhead_handle" ] ) ; ENDIF
   Sw_WriteDouble( w, 44, st[ "arrowhead_size" ] ) ; Sw_WriteString( w, 300, st[ "default_text" ] )
   IF st[ "text_style_handle" ] != NIL ; Sw_WriteHandle( w, 342, st[ "text_style_handle" ] ) ; ENDIF
   Sw_WriteI16( w, 174, st[ "text_left_attachment" ] ) ; Sw_WriteI16( w, 175, st[ "text_angle_type" ] ) ; Sw_WriteI16( w, 176, st[ "text_alignment" ] )
   Sw_WriteI16( w, 178, st[ "text_right_attachment" ] ) ; Dxo_WriteColorI32( w, 93, st[ "text_color" ] ) ; Sw_WriteDouble( w, 45, st[ "text_height" ] )
   Sw_WriteBool( w, 292, st[ "text_frame" ] ) ; Sw_WriteBool( w, 297, st[ "text_always_left" ] ) ; Sw_WriteDouble( w, 46, st[ "align_space" ] )
   IF st[ "block_content_handle" ] != NIL ; Sw_WriteHandle( w, 343, st[ "block_content_handle" ] ) ; ENDIF
   Dxo_WriteColorI32( w, 94, st[ "block_content_color" ] ) ; Sw_WriteDouble( w, 47, st[ "block_content_scale_x" ] ) ; Sw_WriteDouble( w, 49, st[ "block_content_scale_y" ] )
   Sw_WriteDouble( w, 140, st[ "block_content_scale_z" ] ) ; Sw_WriteBool( w, 293, st[ "enable_block_scale" ] ) ; Sw_WriteDouble( w, 141, st[ "block_content_rotation" ] )
   Sw_WriteBool( w, 294, st[ "enable_block_rotation" ] ) ; Sw_WriteI16( w, 177, st[ "block_content_connection" ] ) ; Sw_WriteDouble( w, 142, st[ "scale_factor" ] )
   Sw_WriteBool( w, 295, st[ "property_changed" ] ) ; Sw_WriteBool( w, 296, st[ "is_annotative" ] ) ; Sw_WriteDouble( w, 143, st[ "break_gap_size" ] )
RETURN

STATIC PROCEDURE Dxo_WritePlotSettings( w, ps )
   LOCAL h, m := ps[ "margins" ], pw := ps[ "plot_window" ]
   Sw_WriteString( w, 0, "PLOTSETTINGS" ) ; Sw_WriteHandle( w, 5, ps[ "handle" ] )
   IF Len( ps[ "reactors" ] ) > 0
      Sw_WriteString( w, 102, "{ACAD_REACTORS" )
      FOR EACH h IN ps[ "reactors" ] ; Sw_WriteHandle( w, 330, h ) ; NEXT
      Sw_WriteString( w, 102, "}" )
   ENDIF
   IF ps[ "xdictionary_handle" ] != NIL
      Sw_WriteString( w, 102, "{ACAD_XDICTIONARY" ) ; Sw_WriteHandle( w, 360, ps[ "xdictionary_handle" ] ) ; Sw_WriteString( w, 102, "}" )
   ENDIF
   Sw_WriteHandle( w, 330, ps[ "owner" ] ) ; Sw_WriteSubclass( w, "AcDbPlotSettings" )
   Sw_WriteString( w, 1, ps[ "page_name" ] ) ; Sw_WriteString( w, 2, ps[ "printer_name" ] ) ; Sw_WriteString( w, 4, ps[ "paper_size" ] )
   Sw_WriteString( w, 6, ps[ "plot_view_name" ] ) ; Sw_WriteString( w, 7, ps[ "current_style_sheet" ] )
   Sw_WriteDouble( w, 40, m[ "left" ] ) ; Sw_WriteDouble( w, 41, m[ "bottom" ] ) ; Sw_WriteDouble( w, 42, m[ "right" ] ) ; Sw_WriteDouble( w, 43, m[ "top" ] )
   Sw_WriteDouble( w, 44, ps[ "paper_width" ] ) ; Sw_WriteDouble( w, 45, ps[ "paper_height" ] ) ; Sw_WriteDouble( w, 46, ps[ "origin_x" ] ) ; Sw_WriteDouble( w, 47, ps[ "origin_y" ] )
   Sw_WriteDouble( w, 48, pw[ "lower_left_x" ] ) ; Sw_WriteDouble( w, 49, pw[ "lower_left_y" ] ) ; Sw_WriteDouble( w, 140, pw[ "upper_right_x" ] ) ; Sw_WriteDouble( w, 141, pw[ "upper_right_y" ] )
   Sw_WriteDouble( w, 142, ps[ "scale_numerator" ] ) ; Sw_WriteDouble( w, 143, ps[ "scale_denominator" ] ) ; Sw_WriteDouble( w, 147, ps[ "standard_scale_factor" ] )
   Sw_WriteDouble( w, 148, ps[ "paper_image_origin_x" ] ) ; Sw_WriteDouble( w, 149, ps[ "paper_image_origin_y" ] )
   Sw_WriteI16( w, 70, Pfl_ToBits( ps[ "flags" ] ) ) ; Sw_WriteI16( w, 72, Ppu_ToCode( ps[ "paper_units" ] ) ) ; Sw_WriteI16( w, 73, Prt_ToCode( ps[ "rotation" ] ) )
   Sw_WriteI16( w, 74, Plt_ToCode( ps[ "plot_type" ] ) ) ; Sw_WriteI16( w, 75, Sct_ToCode( ps[ "scale_type" ] ) ) ; Sw_WriteI16( w, 76, Spm_ToCode( ps[ "shade_plot_mode" ] ) )
   Sw_WriteI16( w, 77, Spr_ToCode( ps[ "shade_plot_resolution" ] ) ) ; Sw_WriteI16( w, 78, ps[ "shade_plot_dpi" ] )
   IF ! Hd_IsNull( ps[ "visual_style_handle" ] ) ; Sw_WriteHandle( w, 333, ps[ "visual_style_handle" ] ) ; ENDIF
RETURN

STATIC PROCEDURE Dxo_WriteGroup( w, g )
   LOCAL h
   Sw_WriteString( w, 0, "GROUP" ) ; Sw_WriteHandle( w, 5, g[ "handle" ] ) ; Sw_WriteHandle( w, 330, g[ "owner" ] )
   Sw_WriteSubclass( w, "AcDbGroup" )
   Sw_WriteString( w, 300, g[ "description" ] )
   Sw_WriteI16( w, 70, IIf( Grp_IsUnnamed( g ), 1, 0 ) ) ; Sw_WriteI16( w, 71, IIf( g[ "selectable" ], 1, 0 ) )
   FOR EACH h IN g[ "entities" ] ; Sw_WriteHandle( w, 340, h ) ; NEXT
RETURN

/* write_object_xdata */
STATIC PROCEDURE Dxo_WriteObjXdata( w, d, h )
   IF Dxo_HasOwnXdata( d[ "objects" ][ h ] ) ; RETURN ; ENDIF
   IF hb_HHasKey( d[ "object_xdata" ], h ) ; Swr_XDataP( w, d[ "object_xdata" ][ h ] ) ; ENDIF
RETURN

PROCEDURE Dxo_WriteObjects( w, d, nVer, hValid )
   LOCAL nRoot := d[ "header" ][ "named_objects_dict_handle" ], aK, h, o
   s_hValid := hValid ; s_nRoot := Dxo_FindRootDictHandle( d )
   Sw_WriteSectionStart( w, "OBJECTS" )
   IF Hd_IsNull( nRoot ) .OR. ! hb_HHasKey( d[ "objects" ], nRoot ) .OR. ! d[ "objects" ][ nRoot ][ "_type" ] == "Dictionary"
      nRoot := Dxo_FindRootDictHandle( d )
   ENDIF
   IF hb_HHasKey( d[ "objects" ], nRoot ) .AND. d[ "objects" ][ nRoot ][ "_type" ] == "Dictionary"
      Dxo_WriteDictionary( w, d, d[ "objects" ][ nRoot ] )
      Dxo_WriteObjXdata( w, d, nRoot )
   ENDIF
   aK := ASort( hb_HKeys( d[ "objects" ] ) )
   FOR EACH h IN aK
      IF h != nRoot
         o := d[ "objects" ][ h ]
         DO CASE
         CASE o[ "_type" ] == "Dictionary" ; Dxo_WriteDictionary( w, d, o )
         CASE o[ "_type" ] == "Layout" ; Dxo_WriteLayout( w, o )
         CASE o[ "_type" ] == "XRecord" ; Dxo_WriteXRecord( w, o )
         CASE o[ "_type" ] == "MLineStyle" ; Dxo_WriteMLineStyle( w, o )
         CASE o[ "_type" ] == "SortEntitiesTable" ; Dxo_WriteSortEnts( w, d, o, nVer )
         CASE o[ "_type" ] == "ImageDefinition" ; Dxo_WriteImageDef( w, o )
         CASE o[ "_type" ] == "UnderlayDefinition" ; Dxo_WriteUnderlayDef( w, o )
         CASE o[ "_type" ] == "MultiLeaderStyle" ; Dxo_WriteMLeaderStyle( w, d, o )
         CASE o[ "_type" ] == "PlotSettings" ; Dxo_WritePlotSettings( w, o )
         CASE o[ "_type" ] == "Scale" ; Dxo_WriteScale( w, o )
         CASE o[ "_type" ] == "DictionaryVariable" ; Dxo_WriteDictVar( w, o )
         CASE o[ "_type" ] == "Group" ; Dxo_WriteGroup( w, o )
         CASE o[ "_type" ] == "PlaceHolder" ; Dxo_WritePlaceHolder( w, o, nVer )
         CASE o[ "_type" ] == "DictionaryWithDefault" ; Dxo_WriteDictWithDefault( w, d, o )
         CASE o[ "_type" ] == "SpatialFilter" ; Dxo_WriteSpatialFilter( w, d, o )
         ENDCASE
         IF Dxo_IsWritten( o ) ; Dxo_WriteObjXdata( w, d, h ) ; ENDIF
      ENDIF
   NEXT
   Sw_WriteSectionEnd( w )
RETURN
