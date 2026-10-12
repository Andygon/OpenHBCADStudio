/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/dxf_secwriter.prg
   Origen Rust: opencadcodec/src/io/dxf/writer/section_writer.rs (parcial) y writer/mod.rs (write_dxf).
   Licencia del original: MPL-2.0. Sin tests propios en el original (se prueba por roundtrip: tests/t_dxf_rw.prg).
   Portado: cabecera (con $TDUCREATE/$TDUUPDATE), summary_info, classes, tablas, blocks, entities (la mayoria de tipos incl. MULTILEADER/MESH),
   graphic_data comun, normal_plotstyle_handle, active_viewport_ids, xdata, DXF binario (Dxw_WriteBinaryString), EOF.
   valid_handles (Dxw_BuildValidHandles, sin Unknown/Associative/loft) y safe_entity_owner portados; preview_data 310 portado.
   prepare_table_keys y prepare_database_references (sin las reparaciones de TABLE) portados.
   PENDIENTE: ACDSDATA (depende de ACIS),
   3DSOLID/REGION/BODY (ACIS).
   Nota (quirk fiel al original): TEXT escribe oblique_angle (51) en radianes sin convertir.
   st = { w, nVer, nextHandle, lPaper, d, hViewportIds, nNormalPlotstyle }. Prefijo Swr_ / Dxw_.
----------------------------------------------------------------------------*/
#include "ocx.ch"

STATIC PROCEDURE Swr_Var( w, cName, bBody )
   Sw_WriteString( w, 9, cName )
   Eval( bBody )
RETURN

STATIC FUNCTION Swr_CelWeight( v )
   LOCAL a := { 0, 5, 9, 13, 14, 15, 16, 18, 20, 23, 25, 30, 35, 40, 45, 50, 53, 55, 60, 65, 70, 75, 78, 80, 85, 90, 95, 100, 103, 105, 109, 112, 118, 120, 125, 130, 135, 140, 145, 150, 155, 158, 160, 165, 170, 175, 180, 185, 190, 195, 200, 205, 209, 211 }
   IF ( v >= -3 .AND. v <= -1 ) .OR. AScan( a, {| x | x == v } ) > 0 ; RETURN v ; ENDIF
RETURN -1

STATIC PROCEDURE Swr_SummaryInfo( w, d )
   LOCAL info := d[ "summary_info" ], a, p, aCustom := {}, cLsb
   FOR EACH a IN { { "$TITLE", "title" }, { "$SUBJECT", "subject" }, { "$AUTHOR", "author" }, { "$KEYWORDS", "keywords" }, { "$COMMENTS", "comments" } }
      IF Len( info[ a[ 2 ] ] ) > 0 ; Swr_Var( w, a[ 1 ], {|| Sw_WriteString( w, 1, info[ a[ 2 ] ] ) } ) ; ENDIF
   NEXT
   FOR EACH p IN info[ "custom_properties" ]
      IF Len( p[ 1 ] ) > 0 ; AAdd( aCustom, p ) ; ENDIF
   NEXT
   cLsb := IIf( Len( info[ "last_saved_by" ] ) == 0, d[ "header" ][ "last_saved_by" ], info[ "last_saved_by" ] )
   IF Len( cLsb ) > 0 .OR. Len( aCustom ) > 0
      Swr_Var( w, "$LASTSAVEDBY", {|| Sw_WriteString( w, 1, cLsb ) } )
   ENDIF
   IF Len( info[ "revision_number" ] ) > 0
      Swr_Var( w, "$REVISIONNUMBER", {|| Sw_WriteString( w, 1, info[ "revision_number" ] ) } )
   ENDIF
   FOR EACH p IN aCustom
      Swr_Var( w, "$CUSTOMPROPERTYTAG", {|| Sw_WriteString( w, 1, p[ 1 ] ) } )
      Swr_Var( w, "$CUSTOMPROPERTY", {|| Sw_WriteString( w, 1, p[ 2 ] ) } )
   NEXT
RETURN

PROCEDURE Swr_Header( st, d )
   LOCAL w := st[ 1 ], nVer := st[ 2 ], hdr := d[ "header" ], cBase := ""
   Sw_WriteSectionStart( w, "HEADER" )
   Swr_Var( w, "$ACADVER", {|| Sw_WriteString( w, 1, Dxv_ToDxfString( nVer ) ) } )
   IF nVer >= Dxv_FromVersionString( "AC1032" )
      Swr_Var( w, "$ACADMAINTVER", {|| Sw_WriteI32( w, 90, 377 ) } )
   ELSEIF nVer >= Dxv_FromVersionString( "AC1015" )
      Swr_Var( w, "$ACADMAINTVER", {|| Sw_WriteI16( w, 70, 0 ) } )
   ENDIF
   Swr_Var( w, "$DWGCODEPAGE", {|| Sw_WriteString( w, 3, hdr[ "code_page" ] ) } )
   IF nVer >= Dxv_FromVersionString( "AC1018" ) ; Swr_SummaryInfo( w, d ) ; ENDIF
   Swr_Var( w, "$HANDSEED", {|| Sw_WriteHandle( w, 5, st[ 3 ] ) } )
   Swr_Var( w, "$INSBASE", {|| Sw_WritePoint3d( w, 10, hdr[ "model_space_insertion_base" ] ) } )
   Swr_Var( w, "$EXTMIN", {|| Sw_WritePoint3d( w, 10, hdr[ "model_space_extents_min" ] ) } )
   Swr_Var( w, "$EXTMAX", {|| Sw_WritePoint3d( w, 10, hdr[ "model_space_extents_max" ] ) } )
   Swr_Var( w, "$LIMMIN", {|| Sw_WritePoint2d( w, 10, hdr[ "model_space_limits_min" ] ) } )
   Swr_Var( w, "$LIMMAX", {|| Sw_WritePoint2d( w, 10, hdr[ "model_space_limits_max" ] ) } )
   Swr_Var( w, "$ORTHOMODE", {|| Sw_WriteI16( w, 70, IIf( hdr[ "ortho_mode" ], 1, 0 ) ) } )
   Swr_Var( w, "$OSMODE", {|| Sw_WriteI16( w, 70, hdr[ "object_snap_mode" ] ) } )
   Swr_Var( w, "$REGENMODE", {|| Sw_WriteI16( w, 70, IIf( hdr[ "regen_mode" ], 1, 0 ) ) } )
   Swr_Var( w, "$FILLMODE", {|| Sw_WriteI16( w, 70, IIf( hdr[ "fill_mode" ], 1, 0 ) ) } )
   Swr_Var( w, "$QTEXTMODE", {|| Sw_WriteI16( w, 70, IIf( hdr[ "quick_text_mode" ], 1, 0 ) ) } )
   Swr_Var( w, "$MIRRTEXT", {|| Sw_WriteI16( w, 70, IIf( hdr[ "mirror_text" ], 1, 0 ) ) } )
   Swr_Var( w, "$LTSCALE", {|| Sw_WriteDouble( w, 40, hdr[ "linetype_scale" ] ) } )
   Swr_Var( w, "$ATTMODE", {|| Sw_WriteI16( w, 70, hdr[ "attribute_visibility" ] ) } )
   Swr_Var( w, "$TEXTSIZE", {|| Sw_WriteDouble( w, 40, hdr[ "text_height" ] ) } )
   Swr_Var( w, "$TRACEWID", {|| Sw_WriteDouble( w, 40, hdr[ "trace_width" ] ) } )
   Swr_Var( w, "$SKETCHINC", {|| Sw_WriteDouble( w, 40, hdr[ "sketch_increment" ] ) } )
   Swr_Var( w, "$SKPOLY", {|| Sw_WriteI16( w, 70, Max( 0, Min( 2, hdr[ "sketch_type" ] ) ) ) } )
   Swr_Var( w, "$TEXTSTYLE", {|| Sw_WriteString( w, 7, hdr[ "current_text_style_name" ] ) } )
   Swr_Var( w, "$CMLSTYLE", {|| Sw_WriteString( w, 2, hdr[ "multiline_style" ] ) } )
   IF Len( hdr[ "current_table_style_name" ] ) > 0 .AND. ! ( Upper( hdr[ "current_table_style_name" ] ) == "STANDARD" )
     Swr_Var( w, "$CTABLESTYLE", {|| Sw_WriteString( w, 2, hdr[ "current_table_style_name" ] ) } )
   ENDIF
   IF Len( hdr[ "current_mleader_style_name" ] ) > 0 .AND. ! ( Upper( hdr[ "current_mleader_style_name" ] ) == "STANDARD" )
     Swr_Var( w, "$CMLEADERSTYLE", {|| Sw_WriteString( w, 2, hdr[ "current_mleader_style_name" ] ) } )
   ENDIF
   Swr_Var( w, "$CLAYER", {|| Sw_WriteString( w, 8, hdr[ "current_layer_name" ] ) } )
   Swr_Var( w, "$CELTYPE", {|| Sw_WriteString( w, 6, hdr[ "current_linetype_name" ] ) } )
   Swr_Var( w, "$CECOLOR", {|| Sw_WriteI16( w, 62, Cl_ApproximateIndex( hdr[ "current_entity_color" ] ) ) } )
   Swr_Var( w, "$CELWEIGHT", {|| Sw_WriteI16( w, 370, Swr_CelWeight( hdr[ "current_line_weight" ] ) ) } )
   Swr_Var( w, "$CELTSCALE", {|| Sw_WriteDouble( w, 40, hdr[ "current_entity_linetype_scale" ] ) } )
   Swr_Var( w, "$DISPSILH", {|| Sw_WriteI16( w, 70, IIf( hdr[ "display_silhouette" ], 1, 0 ) ) } )
   Swr_Var( w, "$LWDISPLAY", {|| Sw_WriteBool( w, 290, hdr[ "lineweight_display" ] ) } )
   Swr_Var( w, "$LUNITS", {|| Sw_WriteI16( w, 70, hdr[ "linear_unit_format" ] ) } )
   Swr_Var( w, "$LUPREC", {|| Sw_WriteI16( w, 70, hdr[ "linear_unit_precision" ] ) } )
   Swr_Var( w, "$AUNITS", {|| Sw_WriteI16( w, 70, hdr[ "angular_unit_format" ] ) } )
   Swr_Var( w, "$AUPREC", {|| Sw_WriteI16( w, 70, hdr[ "angular_unit_precision" ] ) } )
   Swr_Var( w, "$MEASUREMENT", {|| Sw_WriteI16( w, 70, hdr[ "measurement" ] ) } )
   Swr_Var( w, "$INSUNITS", {|| Sw_WriteI16( w, 70, hdr[ "insertion_units" ] ) } )
   cBase := IIf( Len( d[ "summary_info" ][ "hyperlink_base" ] ) == 0, hdr[ "hyperlink_base" ], d[ "summary_info" ][ "hyperlink_base" ] )
   IF nVer >= Dxv_FromVersionString( "AC1015" ) .AND. Len( cBase ) > 0
     Swr_Var( w, "$HYPERLINKBASE", {|| Sw_WriteString( w, 1, cBase ) } )
   ENDIF
   Swr_Var( w, "$PDMODE", {|| Sw_WriteI16( w, 70, hdr[ "point_display_mode" ] ) } )
   Swr_Var( w, "$PDSIZE", {|| Sw_WriteDouble( w, 40, hdr[ "point_display_size" ] ) } )
   Swr_Var( w, "$PLINEGEN", {|| Sw_WriteI16( w, 70, IIf( hdr[ "polyline_linetype_generation" ], 1, 0 ) ) } )
   Swr_Var( w, "$PSLTSCALE", {|| Sw_WriteI16( w, 70, IIf( hdr[ "paper_space_linetype_scaling" ], 1, 0 ) ) } )
   Swr_Var( w, "$DIMSCALE", {|| Sw_WriteDouble( w, 40, hdr[ "dim_scale" ] ) } )
   Swr_Var( w, "$DIMASZ", {|| Sw_WriteDouble( w, 40, hdr[ "dim_arrow_size" ] ) } )
   Swr_Var( w, "$DIMEXO", {|| Sw_WriteDouble( w, 40, hdr[ "dim_ext_line_offset" ] ) } )
   Swr_Var( w, "$DIMDLI", {|| Sw_WriteDouble( w, 40, hdr[ "dim_line_increment" ] ) } )
   Swr_Var( w, "$DIMRND", {|| Sw_WriteDouble( w, 40, hdr[ "dim_rounding" ] ) } )
   Swr_Var( w, "$DIMDLE", {|| Sw_WriteDouble( w, 40, hdr[ "dim_line_extension" ] ) } )
   Swr_Var( w, "$DIMEXE", {|| Sw_WriteDouble( w, 40, hdr[ "dim_ext_line_extension" ] ) } )
   Swr_Var( w, "$DIMTP", {|| Sw_WriteDouble( w, 40, hdr[ "dim_tolerance_plus" ] ) } )
   Swr_Var( w, "$DIMTM", {|| Sw_WriteDouble( w, 40, hdr[ "dim_tolerance_minus" ] ) } )
   Swr_Var( w, "$DIMTXT", {|| Sw_WriteDouble( w, 40, hdr[ "dim_text_height" ] ) } )
   Swr_Var( w, "$DIMCEN", {|| Sw_WriteDouble( w, 40, hdr[ "dim_center_mark" ] ) } )
   Swr_Var( w, "$DIMTSZ", {|| Sw_WriteDouble( w, 40, hdr[ "dim_tick_size" ] ) } )
   Swr_Var( w, "$DIMTOL", {|| Sw_WriteI16( w, 70, IIf( hdr[ "dim_tolerance" ], 1, 0 ) ) } )
   Swr_Var( w, "$DIMLIM", {|| Sw_WriteI16( w, 70, IIf( hdr[ "dim_limits" ], 1, 0 ) ) } )
   Swr_Var( w, "$DIMTIH", {|| Sw_WriteI16( w, 70, IIf( hdr[ "dim_text_inside_horizontal" ], 1, 0 ) ) } )
   Swr_Var( w, "$DIMTOH", {|| Sw_WriteI16( w, 70, IIf( hdr[ "dim_text_outside_horizontal" ], 1, 0 ) ) } )
   Swr_Var( w, "$DIMSE1", {|| Sw_WriteI16( w, 70, IIf( hdr[ "dim_suppress_ext1" ], 1, 0 ) ) } )
   Swr_Var( w, "$DIMSE2", {|| Sw_WriteI16( w, 70, IIf( hdr[ "dim_suppress_ext2" ], 1, 0 ) ) } )
   Swr_Var( w, "$DIMTAD", {|| Sw_WriteI16( w, 70, hdr[ "dim_text_above" ] ) } )
   Swr_Var( w, "$DIMZIN", {|| Sw_WriteI16( w, 70, hdr[ "dim_zero_suppression" ] ) } )
   Swr_Var( w, "$DIMCLRD", {|| Sw_WriteI16( w, 70, Cl_ApproximateIndex( hdr[ "dim_line_color" ] ) ) } )
   Swr_Var( w, "$DIMCLRE", {|| Sw_WriteI16( w, 70, Cl_ApproximateIndex( hdr[ "dim_ext_line_color" ] ) ) } )
   Swr_Var( w, "$DIMCLRT", {|| Sw_WriteI16( w, 70, Cl_ApproximateIndex( hdr[ "dim_text_color" ] ) ) } )
   Swr_Var( w, "$DIMGAP", {|| Sw_WriteDouble( w, 40, hdr[ "dim_line_gap" ] ) } )
   Swr_Var( w, "$DIMALT", {|| Sw_WriteI16( w, 70, IIf( hdr[ "dim_alternate_units" ], 1, 0 ) ) } )
   Swr_Var( w, "$DIMALTD", {|| Sw_WriteI16( w, 70, hdr[ "dim_alt_decimal_places" ] ) } )
   Swr_Var( w, "$DIMALTF", {|| Sw_WriteDouble( w, 40, hdr[ "dim_alt_scale" ] ) } )
   Swr_Var( w, "$DIMLFAC", {|| Sw_WriteDouble( w, 40, hdr[ "dim_linear_scale" ] ) } )
   Swr_Var( w, "$DIMTOFL", {|| Sw_WriteI16( w, 70, IIf( hdr[ "dim_force_line_inside" ], 1, 0 ) ) } )
   Swr_Var( w, "$DIMTVP", {|| Sw_WriteDouble( w, 40, hdr[ "dim_text_vertical_pos" ] ) } )
   Swr_Var( w, "$DIMTIX", {|| Sw_WriteI16( w, 70, IIf( hdr[ "dim_force_text_inside" ], 1, 0 ) ) } )
   Swr_Var( w, "$DIMSOXD", {|| Sw_WriteI16( w, 70, IIf( hdr[ "dim_suppress_outside_ext" ], 1, 0 ) ) } )
   Swr_Var( w, "$DIMSAH", {|| Sw_WriteI16( w, 70, IIf( hdr[ "dim_separate_arrows" ], 1, 0 ) ) } )
   Swr_Var( w, "$DIMPOST", {|| Sw_WriteString( w, 1, hdr[ "dim_post" ] ) } )
   Swr_Var( w, "$DIMAPOST", {|| Sw_WriteString( w, 1, hdr[ "dim_alt_post" ] ) } )
   Swr_Var( w, "$DIMSTYLE", {|| Sw_WriteString( w, 2, hdr[ "current_dimstyle_name" ] ) } )
   Swr_Var( w, "$DIMLUNIT", {|| Sw_WriteI16( w, 70, hdr[ "dim_linear_unit_format" ] ) } )
   Swr_Var( w, "$DIMDEC", {|| Sw_WriteI16( w, 70, hdr[ "dim_decimal_places" ] ) } )
   Swr_Var( w, "$DIMTDEC", {|| Sw_WriteI16( w, 70, hdr[ "dim_tolerance_decimal_places" ] ) } )
   Swr_Var( w, "$DIMALTU", {|| Sw_WriteI16( w, 70, hdr[ "dim_alt_units_format" ] ) } )
   Swr_Var( w, "$DIMALTTD", {|| Sw_WriteI16( w, 70, hdr[ "dim_alt_tolerance_decimal_places" ] ) } )
   Swr_Var( w, "$DIMAUNIT", {|| Sw_WriteI16( w, 70, hdr[ "dim_angular_units" ] ) } )
   Swr_Var( w, "$DIMADEC", {|| Sw_WriteI16( w, 70, hdr[ "dim_angular_decimal_places" ] ) } )
   Swr_Var( w, "$DIMJUST", {|| Sw_WriteI16( w, 70, hdr[ "dim_horizontal_justification" ] ) } )
   Swr_Var( w, "$DIMSD1", {|| Sw_WriteI16( w, 70, IIf( hdr[ "dim_suppress_line1" ], 1, 0 ) ) } )
   Swr_Var( w, "$DIMSD2", {|| Sw_WriteI16( w, 70, IIf( hdr[ "dim_suppress_line2" ], 1, 0 ) ) } )
   Swr_Var( w, "$DIMTOLJ", {|| Sw_WriteI16( w, 70, hdr[ "dim_tolerance_justification" ] ) } )
   Swr_Var( w, "$DIMTZIN", {|| Sw_WriteI16( w, 70, hdr[ "dim_tolerance_zero_suppression" ] ) } )
   Swr_Var( w, "$DIMALTZ", {|| Sw_WriteI16( w, 70, hdr[ "dim_alt_tolerance_zero_suppression" ] ) } )
   Swr_Var( w, "$DIMALTTZ", {|| Sw_WriteI16( w, 70, hdr[ "dim_alt_tolerance_zero_tight" ] ) } )
   Swr_Var( w, "$DIMATFIT", {|| Sw_WriteI16( w, 70, hdr[ "dim_fit" ] ) } )
   Swr_Var( w, "$DIMDSEP", {|| Sw_WriteI16( w, 70, Asc( hdr[ "dim_decimal_separator" ] ) ) } )
   Swr_Var( w, "$DIMTMOVE", {|| Sw_WriteI16( w, 70, hdr[ "dim_text_movement" ] ) } )
   Swr_Var( w, "$DIMFRAC", {|| Sw_WriteI16( w, 70, hdr[ "dim_fraction_format" ] ) } )
   Swr_Var( w, "$DIMLWD", {|| Sw_WriteI16( w, 70, hdr[ "dim_line_weight" ] ) } )
   Swr_Var( w, "$DIMLWE", {|| Sw_WriteI16( w, 70, hdr[ "dim_ext_line_weight" ] ) } )
   Swr_Var( w, "$DIMTFAC", {|| Sw_WriteDouble( w, 40, hdr[ "dim_tolerance_scale" ] ) } )
   IF nVer >= Dxv_FromVersionString( "AC1021" )
     Swr_Var( w, "$DIMFXL", {|| Sw_WriteDouble( w, 40, hdr[ "dim_fixed_ext_line_length" ] ) } )
   ENDIF
   IF nVer >= Dxv_FromVersionString( "AC1021" )
     Swr_Var( w, "$DIMJOGANG", {|| Sw_WriteDouble( w, 40, Max( 0.0872665, Min( OCX_PI / 2.0, hdr[ "dim_jog_angle" ] ) ) ) } )
   ENDIF
   IF nVer >= Dxv_FromVersionString( "AC1021" )
     Swr_Var( w, "$DIMTFILL", {|| Sw_WriteI16( w, 70, hdr[ "dim_text_fill" ] ) } )
   ENDIF
   IF nVer >= Dxv_FromVersionString( "AC1021" )
     Swr_Var( w, "$DIMTFILLCLR", {|| Sw_WriteI16( w, 70, Cl_ApproximateIndex( hdr[ "dim_text_fill_color" ] ) ) } )
   ENDIF
   Swr_Var( w, "$SPLFRAME", {|| Sw_WriteI16( w, 70, IIf( hdr[ "spline_frame" ], 1, 0 ) ) } )
   IF nVer >= Dxv_FromVersionString( "AC1015" )
     Swr_Var( w, "$XCLIPFRAME", {|| Sw_WriteByte( w, 280, Max( 0, Min( 2, hdr[ "xclip_frame" ] ) ) ) } )
   ENDIF
   IF nVer >= Dxv_FromVersionString( "AC1021" )
     Swr_Var( w, "$DWFFRAME", {|| Sw_WriteByte( w, 280, Max( 0, Min( 2, hdr[ "dwf_frame" ] ) ) ) } )
   ENDIF
   IF nVer >= Dxv_FromVersionString( "AC1021" )
     Swr_Var( w, "$DGNFRAME", {|| Sw_WriteByte( w, 280, Max( 0, Min( 2, hdr[ "dgn_frame" ] ) ) ) } )
   ENDIF
   IF nVer >= Dxv_FromVersionString( "AC1021" )
     Swr_Var( w, "$SOLIDHIST", {|| Sw_WriteByte( w, 280, IIf( hdr[ "record_solid_history" ], 1, 0 ) ) } )
   ENDIF
   IF nVer >= Dxv_FromVersionString( "AC1021" )
     Swr_Var( w, "$SHOWHIST", {|| Sw_WriteByte( w, 280, Max( 0, Min( 2, hdr[ "show_solid_history" ] ) ) ) } )
   ENDIF
   IF nVer >= Dxv_FromVersionString( "AC1021" )
     Swr_Var( w, "$3DDWFPREC", {|| Sw_WriteDouble( w, 40, Max( 1.0, Min( 6.0, hdr[ "dwf_3d_precision" ] ) ) ) } )
   ENDIF
   IF nVer >= Dxv_FromVersionString( "AC1021" )
     Swr_Var( w, "$PSOLWIDTH", {|| Sw_WriteDouble( w, 40, IIf( hdr[ "polysolid_width" ] > 0.0, hdr[ "polysolid_width" ], 0.25 ) ) } )
   ENDIF
   IF nVer >= Dxv_FromVersionString( "AC1021" )
     Swr_Var( w, "$PSOLHEIGHT", {|| Sw_WriteDouble( w, 40, IIf( hdr[ "polysolid_height" ] > 0.0, hdr[ "polysolid_height" ], 4.0 ) ) } )
   ENDIF
   IF nVer >= Dxv_FromVersionString( "AC1021" )
     Swr_Var( w, "$LIGHTGLYPHDISPLAY", {|| Sw_WriteByte( w, 280, Min( 1, hdr[ "light_glyph_display" ] ) ) } )
   ENDIF
   IF nVer >= Dxv_FromVersionString( "AC1021" )
     Swr_Var( w, "$TILEMODELIGHTSYNCH", {|| Sw_WriteByte( w, 280, Min( 1, hdr[ "tile_model_light_synch" ] ) ) } )
   ENDIF
   IF nVer >= Dxv_FromVersionString( "AC1021" )
     Swr_Var( w, "$REALWORLDSCALE", {|| Sw_WriteBool( w, 290, hdr[ "real_world_scale" ] ) } )
   ENDIF
   IF nVer >= Dxv_FromVersionString( "AC1021" )
     Swr_Var( w, "$INTERFERECOLOR", {|| Sw_WriteI16( w, 62, Cl_ApproximateIndex( hdr[ "interference_color" ] ) ) } )
   ENDIF
   Swr_Var( w, "$SPLINETYPE", {|| Sw_WriteI16( w, 70, hdr[ "spline_type" ] ) } )
   Swr_Var( w, "$SPLINESEGS", {|| Sw_WriteI16( w, 70, hdr[ "spline_segments" ] ) } )
   Swr_Var( w, "$SURFTAB1", {|| Sw_WriteI16( w, 70, hdr[ "surface_tab1" ] ) } )
   Swr_Var( w, "$SURFTAB2", {|| Sw_WriteI16( w, 70, hdr[ "surface_tab2" ] ) } )
   Swr_Var( w, "$SURFTYPE", {|| Sw_WriteI16( w, 70, hdr[ "surface_type" ] ) } )
   Swr_Var( w, "$SURFU", {|| Sw_WriteI16( w, 70, hdr[ "surface_u_density" ] ) } )
   Swr_Var( w, "$SURFV", {|| Sw_WriteI16( w, 70, hdr[ "surface_v_density" ] ) } )
   Swr_Var( w, "$WORLDVIEW", {|| Sw_WriteI16( w, 70, IIf( hdr[ "world_view" ], 1, 0 ) ) } )
   Swr_Var( w, "$PELEVATION", {|| Sw_WriteDouble( w, 40, hdr[ "paper_elevation" ] ) } )
   Swr_Var( w, "$PLINEWID", {|| Sw_WriteDouble( w, 40, hdr[ "polyline_width" ] ) } )
   Swr_Var( w, "$MAXACTVP", {|| Sw_WriteI16( w, 70, hdr[ "max_active_viewports" ] ) } )
   Swr_Var( w, "$TILEMODE", {|| Sw_WriteI16( w, 70, IIf( hdr[ "show_model_space" ], 1, 0 ) ) } )
   Swr_Var( w, "$PLIMCHECK", {|| Sw_WriteI16( w, 70, IIf( hdr[ "paper_space_limit_check" ], 1, 0 ) ) } )
   Swr_Var( w, "$VISRETAIN", {|| Sw_WriteI16( w, 70, IIf( hdr[ "retain_xref_visibility" ], 1, 0 ) ) } )
   Swr_Var( w, "$PSTYLEMODE", {|| Sw_WriteBool( w, 290, hdr[ "plotstyle_mode" ] ) } )
   Swr_Var( w, "$TDCREATE", {|| Sw_WriteDouble( w, 40, hdr[ "create_date_julian" ] ) } )
   IF nVer >= Dxv_FromVersionString( "AC1015" ) ; Swr_Var( w, "$TDUCREATE", {|| Sw_WriteDouble( w, 40, Hdr_UniversalCreateOrLocal( hdr ) ) } ) ; ENDIF
   Swr_Var( w, "$TDUPDATE", {|| Sw_WriteDouble( w, 40, hdr[ "update_date_julian" ] ) } )
   IF nVer >= Dxv_FromVersionString( "AC1015" ) ; Swr_Var( w, "$TDUUPDATE", {|| Sw_WriteDouble( w, 40, Hdr_UniversalUpdateOrLocal( hdr ) ) } ) ; ENDIF
   Swr_Var( w, "$TDINDWG", {|| Sw_WriteDouble( w, 40, hdr[ "total_editing_time" ] ) } )
   IF nVer >= Dxv_FromVersionString( "AC1015" ) .AND. Len( hdr[ "fingerprint_guid" ] ) > 0
     Swr_Var( w, "$FINGERPRINTGUID", {|| Sw_WriteString( w, 2, hdr[ "fingerprint_guid" ] ) } )
   ENDIF
   IF nVer >= Dxv_FromVersionString( "AC1015" ) .AND. Len( hdr[ "version_guid" ] ) > 0
     Swr_Var( w, "$VERSIONGUID", {|| Sw_WriteString( w, 2, hdr[ "version_guid" ] ) } )
   ENDIF
   Swr_Var( w, "$UCSORG", {|| Sw_WritePoint3d( w, 10, hdr[ "model_space_ucs_origin" ] ) } )
   Swr_Var( w, "$UCSXDIR", {|| Sw_WritePoint3d( w, 10, hdr[ "model_space_ucs_x_axis" ] ) } )
   Swr_Var( w, "$UCSYDIR", {|| Sw_WritePoint3d( w, 10, hdr[ "model_space_ucs_y_axis" ] ) } )

   Sw_WriteSectionEnd( w )
RETURN

PROCEDURE Swr_Classes( st, d )
   LOCAL w := st[ 1 ], c
   Sw_WriteSectionStart( w, "CLASSES" )
   FOR EACH c IN d[ "classes" ][ "entries" ]
      Sw_WriteString( w, 0, "CLASS" )
      Sw_WriteString( w, 1, c[ "dxf_name" ] )
      Sw_WriteString( w, 2, c[ "cpp_class_name" ] )
      Sw_WriteString( w, 3, c[ "application_name" ] )
      Sw_WriteI32( w, 90, c[ "proxy_flags" ] )
      IF st[ 2 ] >= Dxv_FromVersionString( "AC1018" ) ; Sw_WriteI32( w, 91, c[ "instance_count" ] ) ; ENDIF
      Sw_WriteByte( w, 280, IIf( c[ "was_zombie" ], 1, 0 ) )
      Sw_WriteByte( w, 281, IIf( c[ "is_an_entity" ], 1, 0 ) )
   NEXT
   Sw_WriteSectionEnd( w )
RETURN

STATIC PROCEDURE Swr_XData( w, xd )
   LOCAL r, v, p, k
   IF Xd_IsEmpty( xd ) ; RETURN ; ENDIF
   FOR EACH r IN Xd_Records( xd )
      Sw_WriteString( w, 1001, Xr_ApplicationName( r ) )
      FOR EACH v IN Xr_Values( r )
         p := v[ 2 ]
         DO CASE
         CASE v[ 1 ] == XV_STRING ; Sw_WriteString( w, 1000, p )
         CASE v[ 1 ] == XV_CONTROLSTRING ; Sw_WriteString( w, 1002, p )
         CASE v[ 1 ] == XV_LAYERNAME ; Sw_WriteString( w, 1003, p )
         CASE v[ 1 ] == XV_BINARYDATA ; Sw_WriteBinary( w, 1004, p )
         CASE v[ 1 ] == XV_HANDLE ; Sw_WriteHandle( w, 1005, p )
         CASE v[ 1 ] >= XV_POINT3D .AND. v[ 1 ] <= XV_DIRECTION3D
            k := 1010 + ( v[ 1 ] - XV_POINT3D )
            Sw_WriteDouble( w, k, p[ 1 ] ) ; Sw_WriteDouble( w, k + 10, p[ 2 ] ) ; Sw_WriteDouble( w, k + 20, p[ 3 ] )
         CASE v[ 1 ] == XV_REAL ; Sw_WriteDouble( w, 1040, p )
         CASE v[ 1 ] == XV_DISTANCE ; Sw_WriteDouble( w, 1041, p )
         CASE v[ 1 ] == XV_SCALEFACTOR ; Sw_WriteDouble( w, 1042, p )
         CASE v[ 1 ] == XV_INTEGER16 ; Sw_WriteI16( w, 1070, p )
         CASE v[ 1 ] == XV_INTEGER32 ; Sw_WriteI32( w, 1071, p )
         ENDCASE
      NEXT
   NEXT
RETURN

STATIC PROCEDURE Swr_TableHeader( w, d, cName, nCount, hTable )
   LOCAL hX := hb_HGetDef( d[ "xdic_by_handle" ], hTable, NIL )
   Sw_WriteString( w, 0, "TABLE" ) ; Sw_WriteString( w, 2, cName ) ; Sw_WriteHandle( w, 5, hTable )
   IF hX != NIL
      Sw_WriteString( w, 102, "{ACAD_XDICTIONARY" ) ; Sw_WriteHandle( w, 360, hX ) ; Sw_WriteString( w, 102, "}" )
   ENDIF
   Sw_WriteHandle( w, 330, 0 )
   Sw_WriteSubclass( w, "AcDbSymbolTable" )
   Sw_WriteI16( w, 70, nCount )
RETURN

STATIC PROCEDURE Swr_CommonTable( st, d, h, hOwner )
   LOCAL w := st[ 1 ], aR := hb_HGetDef( d[ "reactors_by_handle" ], h, NIL ), r, aOk := {}, hX := hb_HGetDef( d[ "xdic_by_handle" ], h, NIL )
   Sw_WriteHandle( w, 5, h )
   IF aR != NIL
      FOR EACH r IN aR
         IF ! Hd_IsNull( r ) .AND. Swr_Valid( st, r ) ; AAdd( aOk, r ) ; ENDIF
      NEXT
   ENDIF
   IF Len( aOk ) > 0
      Sw_WriteString( w, 102, "{ACAD_REACTORS" )
      FOR EACH r IN aOk ; Sw_WriteHandle( w, 330, r ) ; NEXT
      Sw_WriteString( w, 102, "}" )
   ENDIF
   IF hX != NIL .AND. ! Hd_IsNull( hX ) .AND. Swr_Valid( st, hX )
      Sw_WriteString( w, 102, "{ACAD_XDICTIONARY" ) ; Sw_WriteHandle( w, 360, hX ) ; Sw_WriteString( w, 102, "}" )
   ENDIF
   Sw_WriteHandle( w, 330, hOwner )
RETURN

STATIC PROCEDURE Swr_LayerEntry( st, d, l, hOwner, h )
   LOCAL w := st[ 1 ], nFl := 0, nCi, c := l[ "color" ], tc, cB, nPs
   Sw_WriteString( w, 0, "LAYER" )
   Swr_CommonTable( st, d, h, hOwner )
   Sw_WriteSubclass( w, "AcDbSymbolTableRecord" ) ; Sw_WriteSubclass( w, "AcDbLayerTableRecord" )
   Sw_WriteString( w, 2, l[ "name" ] )
   IF l[ "flags" ][ "frozen" ] ; nFl := hb_bitOr( nFl, 1 ) ; ENDIF
   IF l[ "flags" ][ "frozen_in_new_viewport" ] ; nFl := hb_bitOr( nFl, 2 ) ; ENDIF
   IF l[ "flags" ][ "locked" ] ; nFl := hb_bitOr( nFl, 4 ) ; ENDIF
   IF l[ "flags" ][ "xref_dependent" ] ; nFl := hb_bitOr( nFl, 16 ) ; ENDIF
   Sw_WriteI16( w, 70, nFl )
   DO CASE
   CASE c[ 1 ] == CK_INDEX ; nCi := c[ 2 ]
   CASE c[ 1 ] == CK_BYBLOCK ; nCi := 0
   OTHERWISE ; nCi := 7
   ENDCASE
   Sw_WriteI16( w, 62, IIf( ! l[ "flags" ][ "off" ], nCi, - nCi ) )
   tc := Cl_ToTrueColorValue( c )
   IF tc != NIL ; Sw_WriteI32( w, 420, tc ) ; ENDIF
   IF st[ 2 ] >= Dxv_FromVersionString( "AC1018" )
      cB := Dxm_JoinColorBookName( l[ "book_name" ], l[ "color_name" ] )
      IF cB != NIL ; Sw_WriteString( w, 430, cB ) ; ENDIF
   ENDIF
   Sw_WriteString( w, 6, l[ "line_type" ] )
   Sw_WriteI16( w, 370, Lw_GetValue( l[ "line_weight" ] ) )
   IF st[ 2 ] >= Dxv_FromVersionString( "AC1015" )
      nPs := IIf( Hd_IsNull( l[ "plotstyle_handle" ] ), st[ 7 ], l[ "plotstyle_handle" ] )
      IF ! Hd_IsNull( nPs ) ; Sw_WriteHandle( w, 390, nPs ) ; ENDIF
   ENDIF
   Sw_WriteBool( w, 290, l[ "is_plottable" ] )
   IF ! Tp_IsOpaque( l[ "transparency" ] )
      Sw_WriteString( w, 1001, "AcCmTransparency" )
      Sw_WriteI32( w, 1071, Tp_ToDxfValue( l[ "transparency" ] ) )
   ENDIF
   IF Len( l[ "description" ] ) > 0
      Sw_WriteString( w, 1001, "AcAecLayerStandard" ) ; Sw_WriteString( w, 1000, "" ) ; Sw_WriteString( w, 1000, l[ "description" ] )
   ENDIF
RETURN

STATIC PROCEDURE Swr_LtypeEntry( st, d, lt, hOwner )
   LOCAL w := st[ 1 ], e, c, nFl, hS, s
   Sw_WriteString( w, 0, "LTYPE" )
   Swr_CommonTable( st, d, lt[ "handle" ], hOwner )
   Sw_WriteSubclass( w, "AcDbSymbolTableRecord" ) ; Sw_WriteSubclass( w, "AcDbLinetypeTableRecord" )
   Sw_WriteString( w, 2, lt[ "name" ] )
   Sw_WriteI16( w, 70, IIf( lt[ "xref_dependent" ], 16, 0 ) )
   Sw_WriteString( w, 3, lt[ "description" ] )
   Sw_WriteI16( w, 72, 65 ) ; Sw_WriteI16( w, 73, Len( lt[ "elements" ] ) ) ; Sw_WriteDouble( w, 40, lt[ "pattern_length" ] )
   FOR EACH e IN lt[ "elements" ]
      Sw_WriteDouble( w, 49, e[ "length" ] )
      c := e[ "complex" ]
      IF c != NIL
         nFl := 0
         IF c[ "absolute_rotation" ] ; nFl := hb_bitOr( nFl, 1 ) ; ENDIF
         IF Ltc_IsShape( c ) ; nFl := hb_bitOr( nFl, 4 ) ; ELSEIF Ltc_IsText( c ) ; nFl := hb_bitOr( nFl, 2 ) ; ENDIF
         Sw_WriteI16( w, 74, nFl )
         Sw_WriteI16( w, 75, IIf( Ltc_ShapeNumber( c ) == NIL, 0, Ltc_ShapeNumber( c ) ) )
         hS := c[ "style_handle" ]
         IF Hd_IsNull( hS )
            hS := Hd_Null()
            s := Tb_Get( d[ "text_styles" ], "Standard" )
            IF s != NIL .AND. ! Hd_IsNull( s[ "handle" ] )
               hS := s[ "handle" ]
            ELSE
               FOR EACH s IN Tb_Values( d[ "text_styles" ] )
                  IF ! Hd_IsNull( s[ "handle" ] ) ; hS := s[ "handle" ] ; EXIT ; ENDIF
               NEXT
            ENDIF
         ENDIF
         Sw_WriteHandle( w, 340, hS )
         Sw_WriteDouble( w, 46, c[ "scale" ] )
         Sw_WriteDouble( w, 50, c[ "rotation" ] * ( 180.0 / OCX_PI ) )
         Sw_WriteDouble( w, 44, c[ "offset" ][ 1 ] ) ; Sw_WriteDouble( w, 45, c[ "offset" ][ 2 ] )
         IF Ltc_Text( c ) != NIL .AND. Len( Ltc_Text( c ) ) > 0 ; Sw_WriteString( w, 9, Ltc_Text( c ) ) ; ENDIF
      ELSE
         Sw_WriteI16( w, 74, 0 )
      ENDIF
   NEXT
RETURN

STATIC PROCEDURE Swr_StyleEntry( st, d, s, hOwner )
   LOCAL w := st[ 1 ], nFl := 0, nGen := 0, cTt
   Sw_WriteString( w, 0, "STYLE" )
   Swr_CommonTable( st, d, s[ "handle" ], hOwner )
   Sw_WriteSubclass( w, "AcDbSymbolTableRecord" ) ; Sw_WriteSubclass( w, "AcDbTextStyleTableRecord" )
   Sw_WriteString( w, 2, IIf( s[ "is_shape_file" ], "", s[ "name" ] ) )
   IF s[ "is_shape_file" ] ; nFl := hb_bitOr( nFl, 1 ) ; ENDIF
   IF s[ "is_vertical" ] ; nFl := hb_bitOr( nFl, 4 ) ; ENDIF
   IF s[ "xref_dependent" ] ; nFl := hb_bitOr( nFl, 16 ) ; ENDIF
   Sw_WriteI16( w, 70, nFl )
   Sw_WriteDouble( w, 40, s[ "height" ] ) ; Sw_WriteDouble( w, 41, s[ "width_factor" ] )
   Sw_WriteDouble( w, 50, s[ "oblique_angle" ] * ( 180.0 / OCX_PI ) )
   IF s[ "flags" ][ "backward" ] ; nGen := hb_bitOr( nGen, 2 ) ; ENDIF
   IF s[ "flags" ][ "upside_down" ] ; nGen := hb_bitOr( nGen, 4 ) ; ENDIF
   Sw_WriteI16( w, 71, nGen )
   Sw_WriteDouble( w, 42, Tst_EffectiveLastHeight( s ) )
   Sw_WriteString( w, 3, s[ "font_file" ] ) ; Sw_WriteString( w, 4, s[ "big_font_file" ] )
   cTt := AllTrim( s[ "true_type_font" ] )
   IF Len( cTt ) > 0
      Sw_WriteString( w, 1001, "ACAD" ) ; Sw_WriteString( w, 1000, cTt )
      Sw_WriteI32( w, 1071, 0 ) /* DEFAULT_FONT_FLAGS (dwg::typeface_eed): PENDIENTE valor real */
   ENDIF
   IF s[ "annotative" ]
      Sw_WriteString( w, 1001, "AcadAnnotative" ) ; Sw_WriteString( w, 1000, "AnnotativeData" ) ; Sw_WriteString( w, 1002, "{" )
      Sw_WriteI16( w, 1070, 1 ) ; Sw_WriteI16( w, 1070, 1 ) ; Sw_WriteString( w, 1002, "}" )
   ENDIF
RETURN

STATIC PROCEDURE Swr_AppIdEntry( st, d, a, hOwner )
   LOCAL w := st[ 1 ]
   IF Len( a[ "name" ] ) == 0 ; RETURN ; ENDIF
   Sw_WriteString( w, 0, "APPID" )
   Swr_CommonTable( st, d, a[ "handle" ], hOwner )
   Sw_WriteSubclass( w, "AcDbSymbolTableRecord" ) ; Sw_WriteSubclass( w, "AcDbRegAppTableRecord" )
   Sw_WriteString( w, 2, a[ "name" ] ) ; Sw_WriteI16( w, 70, 0 )
RETURN

STATIC PROCEDURE Swr_DimStyleEntry( st, d, ds, hOwner )
   LOCAL w := st[ 1 ], nF := 0, hX := hb_HGetDef( d[ "xdic_by_handle" ], ds[ "handle" ], NIL )
   Sw_WriteString( w, 0, "DIMSTYLE" ) ; Sw_WriteHandle( w, 105, ds[ "handle" ] )
   IF hX != NIL .AND. ! Hd_IsNull( hX )
      Sw_WriteString( w, 102, "{ACAD_XDICTIONARY" ) ; Sw_WriteHandle( w, 360, hX ) ; Sw_WriteString( w, 102, "}" )
   ENDIF
   Sw_WriteHandle( w, 330, hOwner )
   Sw_WriteSubclass( w, "AcDbSymbolTableRecord" ) ; Sw_WriteSubclass( w, "AcDbDimStyleTableRecord" )
   Sw_WriteString( w, 2, ds[ "name" ] )
   IF ds[ "xref_dependent" ] ; nF := hb_bitOr( nF, 16 ) ; ENDIF
   IF ds[ "xref_resolved" ] ; nF := hb_bitOr( nF, 32 ) ; ENDIF
   IF ds[ "xref_reference" ] ; nF := hb_bitOr( nF, 64 ) ; ENDIF
   Sw_WriteI16( w, 70, nF )
   IF Len( ds[ "dimpost" ] ) > 0 .AND. ! ( ds[ "dimpost" ] == "<>" ) ; Sw_WriteString( w, 3, ds[ "dimpost" ] ) ; ENDIF
   IF Len( ds[ "dimapost" ] ) > 0 ; Sw_WriteString( w, 4, ds[ "dimapost" ] ) ; ENDIF
   IF st[ 2 ] <= Dxv_FromVersionString( "AC1014" )
      IF Len( ds[ "dimblk_name" ] ) > 0 ; Sw_WriteString( w, 5, ds[ "dimblk_name" ] ) ; ENDIF
      IF Len( ds[ "dimblk1_name" ] ) > 0 ; Sw_WriteString( w, 6, ds[ "dimblk1_name" ] ) ; ENDIF
      IF Len( ds[ "dimblk2_name" ] ) > 0 ; Sw_WriteString( w, 7, ds[ "dimblk2_name" ] ) ; ENDIF
   ENDIF
   Sw_WriteDouble( w, 40, ds[ "dimscale" ] )
   Sw_WriteDouble( w, 41, ds[ "dimasz" ] )
   Sw_WriteDouble( w, 42, ds[ "dimexo" ] )
   Sw_WriteDouble( w, 43, ds[ "dimdli" ] )
   Sw_WriteDouble( w, 44, ds[ "dimexe" ] )
   Sw_WriteDouble( w, 45, ds[ "dimrnd" ] )
   Sw_WriteDouble( w, 46, ds[ "dimdle" ] )
   Sw_WriteDouble( w, 47, ds[ "dimtp" ] )
   Sw_WriteDouble( w, 48, ds[ "dimtm" ] )
   IF ds[ "dimfxl" ] != 1.0 ; Sw_WriteDouble( w, 49, ds[ "dimfxl" ] ) ; ENDIF
   IF ds[ "dimjogang" ] != OCX_PI / 4.0 ; Sw_WriteDouble( w, 50, Max( 0.0872665, Min( 1.5708, ds[ "dimjogang" ] ) ) ) ; ENDIF
   Sw_WriteDouble( w, 140, ds[ "dimtxt" ] )
   Sw_WriteDouble( w, 141, ds[ "dimcen" ] )
   Sw_WriteDouble( w, 142, ds[ "dimtsz" ] )
   Sw_WriteDouble( w, 143, ds[ "dimaltf" ] )
   Sw_WriteDouble( w, 144, ds[ "dimlfac" ] )
   Sw_WriteDouble( w, 145, ds[ "dimtvp" ] )
   Sw_WriteDouble( w, 146, ds[ "dimtfac" ] )
   Sw_WriteDouble( w, 147, ds[ "dimgap" ] )
   IF ds[ "dimaltrnd" ] != 0.0 ; Sw_WriteDouble( w, 148, ds[ "dimaltrnd" ] ) ; ENDIF
   IF st[ 2 ] >= Dxv_FromVersionString( "AC1021" ) .AND. ds[ "dimtfill" ] != 0
      Sw_WriteI16( w, 69, ds[ "dimtfill" ] ) ; Sw_WriteI16( w, 70, ds[ "dimtfillclr" ] )
   ENDIF
   Sw_WriteI16( w, 71, IIf( ds[ "dimtol" ], 1, 0 ) )
   Sw_WriteI16( w, 72, IIf( ds[ "dimlim" ], 1, 0 ) )
   Sw_WriteI16( w, 73, IIf( ds[ "dimtih" ], 1, 0 ) )
   Sw_WriteI16( w, 74, IIf( ds[ "dimtoh" ], 1, 0 ) )
   Sw_WriteI16( w, 75, IIf( ds[ "dimse1" ], 1, 0 ) )
   Sw_WriteI16( w, 76, IIf( ds[ "dimse2" ], 1, 0 ) )
   Sw_WriteI16( w, 77, ds[ "dimtad" ] )
   Sw_WriteI16( w, 78, ds[ "dimzin" ] )
   Sw_WriteI16( w, 79, ds[ "dimazin" ] )
   IF ds[ "dimarcsym" ] != 0 ; Sw_WriteI32( w, 90, ds[ "dimarcsym" ] ) ; ENDIF
   Sw_WriteI16( w, 170, IIf( ds[ "dimalt" ], 1, 0 ) )
   Sw_WriteI16( w, 171, ds[ "dimaltd" ] )
   Sw_WriteI16( w, 172, IIf( ds[ "dimtofl" ], 1, 0 ) )
   Sw_WriteI16( w, 173, IIf( ds[ "dimsah" ], 1, 0 ) )
   Sw_WriteI16( w, 174, IIf( ds[ "dimtix" ], 1, 0 ) )
   Sw_WriteI16( w, 175, IIf( ds[ "dimsoxd" ], 1, 0 ) )
   Sw_WriteI16( w, 176, ds[ "dimclrd" ] )
   Sw_WriteI16( w, 177, ds[ "dimclre" ] )
   Sw_WriteI16( w, 178, ds[ "dimclrt" ] )
   Sw_WriteI16( w, 179, ds[ "dimadec" ] )
   IF st[ 2 ] <= Dxv_FromVersionString( "AC1014" ) ; Sw_WriteI16( w, 270, ds[ "dimunit" ] ) ; ENDIF
   Sw_WriteI16( w, 271, ds[ "dimdec" ] )
   Sw_WriteI16( w, 272, ds[ "dimtdec" ] )
   Sw_WriteI16( w, 273, ds[ "dimaltu" ] )
   Sw_WriteI16( w, 274, ds[ "dimalttd" ] )
   Sw_WriteI16( w, 275, ds[ "dimaunit" ] )
   Sw_WriteI16( w, 276, ds[ "dimfrac" ] )
   Sw_WriteI16( w, 277, ds[ "dimlunit" ] )
   Sw_WriteI16( w, 278, ds[ "dimdsep" ] )
   Sw_WriteI16( w, 279, ds[ "dimtmove" ] )
   Sw_WriteI16( w, 280, ds[ "dimjust" ] )
   Sw_WriteI16( w, 281, IIf( ds[ "dimsd1" ], 1, 0 ) )
   Sw_WriteI16( w, 282, IIf( ds[ "dimsd2" ], 1, 0 ) )
   Sw_WriteI16( w, 283, ds[ "dimtolj" ] )
   Sw_WriteI16( w, 284, ds[ "dimtzin" ] )
   Sw_WriteI16( w, 285, ds[ "dimaltz" ] )
   Sw_WriteI16( w, 286, ds[ "dimalttz" ] )
   Sw_WriteI16( w, 288, IIf( ds[ "dimupt" ], 1, 0 ) )
   IF st[ 2 ] <= Dxv_FromVersionString( "AC1014" )
      Sw_WriteI16( w, 287, ds[ "dimfit" ] )
   ELSE
      Sw_WriteI16( w, 289, ds[ "dimatfit" ] )
   ENDIF
   IF st[ 2 ] >= Dxv_FromVersionString( "AC1021" ) .AND. ds[ "dimfxlon" ] ; Sw_WriteBool( w, 290, .T. ) ; ENDIF
   IF st[ 2 ] >= Dxv_FromVersionString( "AC1024" ) .AND. ds[ "dimtxtdirection" ] ; Sw_WriteBool( w, 295, .T. ) ; ENDIF
   IF ! Hd_IsNull( ds[ "dimtxsty_handle" ] ) ; Sw_WriteHandle( w, 340, ds[ "dimtxsty_handle" ] ) ; ENDIF
   IF st[ 2 ] >= Dxv_FromVersionString( "AC1015" )
      IF ! Hd_IsNull( ds[ "dimldrblk" ] ) ; Sw_WriteHandle( w, 341, ds[ "dimldrblk" ] ) ; ENDIF
      IF ! Hd_IsNull( ds[ "dimblk" ] ) ; Sw_WriteHandle( w, 342, ds[ "dimblk" ] ) ; ENDIF
      IF ! Hd_IsNull( ds[ "dimblk1" ] ) ; Sw_WriteHandle( w, 343, ds[ "dimblk1" ] ) ; ENDIF
      IF ! Hd_IsNull( ds[ "dimblk2" ] ) ; Sw_WriteHandle( w, 344, ds[ "dimblk2" ] ) ; ENDIF
   ENDIF
   IF st[ 2 ] >= Dxv_FromVersionString( "AC1021" )
      IF ! Hd_IsNull( ds[ "dimltex_handle" ] ) ; Sw_WriteHandle( w, 345, ds[ "dimltex_handle" ] ) ; ENDIF
      IF ! Hd_IsNull( ds[ "dimltex1_handle" ] ) ; Sw_WriteHandle( w, 346, ds[ "dimltex1_handle" ] ) ; ENDIF
      IF ! Hd_IsNull( ds[ "dimltex2_handle" ] ) ; Sw_WriteHandle( w, 347, ds[ "dimltex2_handle" ] ) ; ENDIF
   ENDIF
   IF st[ 2 ] >= Dxv_FromVersionString( "AC1015" )
      Sw_WriteI16( w, 371, ds[ "dimlwd" ] ) ; Sw_WriteI16( w, 372, ds[ "dimlwe" ] )
   ENDIF
   IF ds[ "annotative" ]
      Sw_WriteString( w, 1001, "AcadAnnotative" ) ; Sw_WriteString( w, 1000, "AnnotativeData" ) ; Sw_WriteString( w, 1002, "{" )
      Sw_WriteI16( w, 1070, 1 ) ; Sw_WriteI16( w, 1070, 1 ) ; Sw_WriteString( w, 1002, "}" )
   ENDIF
RETURN

STATIC PROCEDURE Swr_VportEntry( st, d, vp, hOwner )
   LOCAL w := st[ 1 ], nF := 0, nM := 0, nI := 0, rgb
   Sw_WriteString( w, 0, "VPORT" )
   Swr_CommonTable( st, d, vp[ "handle" ], hOwner )
   Sw_WriteSubclass( w, "AcDbSymbolTableRecord" ) ; Sw_WriteSubclass( w, "AcDbViewportTableRecord" )
   Sw_WriteString( w, 2, vp[ "name" ] )
   IF vp[ "xref_dependent" ] ; nF := hb_bitOr( nF, 16 ) ; ENDIF
   IF vp[ "xref_resolved" ] ; nF := hb_bitOr( nF, 32 ) ; ENDIF
   IF vp[ "xref_reference" ] ; nF := hb_bitOr( nF, 64 ) ; ENDIF
   Sw_WriteI16( w, 70, nF )
   Sw_WriteDouble( w, 10, vp[ "lower_left" ][ 1 ] ) ; Sw_WriteDouble( w, 20, vp[ "lower_left" ][ 2 ] )
   Sw_WriteDouble( w, 11, vp[ "upper_right" ][ 1 ] ) ; Sw_WriteDouble( w, 21, vp[ "upper_right" ][ 2 ] )
   Sw_WriteDouble( w, 12, vp[ "view_center" ][ 1 ] ) ; Sw_WriteDouble( w, 22, vp[ "view_center" ][ 2 ] )
   Sw_WriteDouble( w, 13, vp[ "snap_base" ][ 1 ] ) ; Sw_WriteDouble( w, 23, vp[ "snap_base" ][ 2 ] )
   Sw_WriteDouble( w, 14, vp[ "snap_spacing" ][ 1 ] ) ; Sw_WriteDouble( w, 24, vp[ "snap_spacing" ][ 2 ] )
   Sw_WriteDouble( w, 15, vp[ "grid_spacing" ][ 1 ] ) ; Sw_WriteDouble( w, 25, vp[ "grid_spacing" ][ 2 ] )
   Sw_WriteDouble( w, 16, vp[ "view_direction" ][ 1 ] ) ; Sw_WriteDouble( w, 26, vp[ "view_direction" ][ 2 ] ) ; Sw_WriteDouble( w, 36, vp[ "view_direction" ][ 3 ] )
   Sw_WriteDouble( w, 17, vp[ "view_target" ][ 1 ] ) ; Sw_WriteDouble( w, 27, vp[ "view_target" ][ 2 ] ) ; Sw_WriteDouble( w, 37, vp[ "view_target" ][ 3 ] )
   Sw_WriteDouble( w, 40, vp[ "view_height" ] ) ; Sw_WriteDouble( w, 41, vp[ "aspect_ratio" ] ) ; Sw_WriteDouble( w, 42, vp[ "lens_length" ] )
   Sw_WriteDouble( w, 43, vp[ "front_clip" ] ) ; Sw_WriteDouble( w, 44, vp[ "back_clip" ] )
   Sw_WriteDouble( w, 50, vp[ "snap_rotation" ] * ( 180.0 / OCX_PI ) ) ; Sw_WriteDouble( w, 51, vp[ "view_twist" ] * ( 180.0 / OCX_PI ) )
   IF vp[ "perspective" ] ; nM := hb_bitOr( nM, 1 ) ; ENDIF
   IF vp[ "front_clipping" ] ; nM := hb_bitOr( nM, 2 ) ; ENDIF
   IF vp[ "back_clipping" ] ; nM := hb_bitOr( nM, 4 ) ; ENDIF
   IF vp[ "ucsfollow" ] ; nM := hb_bitOr( nM, 8 ) ; ENDIF
   IF vp[ "front_clip_at_eye" ] ; nM := hb_bitOr( nM, 16 ) ; ENDIF
   Sw_WriteI16( w, 71, nM ) ; Sw_WriteI16( w, 72, vp[ "circle_zoom" ] ) ; Sw_WriteI16( w, 73, IIf( vp[ "fast_zoom" ], 1, 0 ) )
   IF vp[ "ucsicon_lower" ] ; nI := hb_bitOr( nI, 1 ) ; ENDIF
   IF vp[ "ucsicon_origin" ] ; nI := hb_bitOr( nI, 2 ) ; ENDIF
   Sw_WriteI16( w, 74, nI ) ; Sw_WriteI16( w, 75, IIf( vp[ "snap_on" ], 1, 0 ) ) ; Sw_WriteI16( w, 76, IIf( vp[ "grid_on" ], 1, 0 ) )
   Sw_WriteI16( w, 77, IIf( vp[ "snap_style" ], 1, 0 ) ) ; Sw_WriteI16( w, 78, vp[ "snap_isopair" ] )
   IF st[ 2 ] >= Dxv_FromVersionString( "AC1015" )
      Sw_WriteI16( w, 281, Vrm_ToValue( vp[ "render_mode" ] ) ) ; Sw_WriteI16( w, 65, IIf( vp[ "ucs_per_viewport" ], 1, 0 ) )
      Sw_WritePoint3d( w, 110, vp[ "ucs_origin" ] ) ; Sw_WritePoint3d( w, 111, vp[ "ucs_x_axis" ] ) ; Sw_WritePoint3d( w, 112, vp[ "ucs_y_axis" ] )
      Sw_WriteI16( w, 79, vp[ "ucs_ortho_type" ] ) ; Sw_WriteDouble( w, 146, vp[ "ucs_elevation" ] )
      IF ! Hd_IsNull( vp[ "named_ucs_handle" ] ) ; Sw_WriteHandle( w, 345, vp[ "named_ucs_handle" ] ) ; ENDIF
      IF ! Hd_IsNull( vp[ "base_ucs_handle" ] ) ; Sw_WriteHandle( w, 346, vp[ "base_ucs_handle" ] ) ; ENDIF
   ENDIF
   IF st[ 2 ] >= Dxv_FromVersionString( "AC1021" )
      Sw_WriteI16( w, 60, Vgf_ToBits( vp[ "grid_flags" ] ) ) ; Sw_WriteI16( w, 61, vp[ "grid_major" ] )
      IF ! Hd_IsNull( vp[ "background_handle" ] ) ; Sw_WriteHandle( w, 332, vp[ "background_handle" ] ) ; ENDIF
      IF ! Hd_IsNull( vp[ "visual_style_handle" ] ) ; Sw_WriteHandle( w, 348, vp[ "visual_style_handle" ] ) ; ENDIF
      IF ! Hd_IsNull( vp[ "sun_handle" ] ) ; Sw_WriteHandle( w, 361, vp[ "sun_handle" ] ) ; ENDIF
      Sw_WriteBool( w, 292, vp[ "use_default_lights" ] ) ; Sw_WriteI16( w, 282, vp[ "default_lighting_type" ] )
      Sw_WriteDouble( w, 141, vp[ "brightness" ] ) ; Sw_WriteDouble( w, 142, vp[ "contrast" ] )
      Sw_WriteColor( w, 63, vp[ "ambient_color" ] )
      rgb := Cl_ToTrueColorValue( vp[ "ambient_color" ] )
      IF rgb != NIL ; Sw_WriteI32( w, 421, rgb ) ; ENDIF
   ENDIF
RETURN

STATIC PROCEDURE Swr_ViewEntry( st, d, vw, hOwner )
   LOCAL w := st[ 1 ], nF := 0, nM := 0, rgb
   Sw_WriteString( w, 0, "VIEW" )
   Swr_CommonTable( st, d, vw[ "handle" ], hOwner )
   Sw_WriteSubclass( w, "AcDbSymbolTableRecord" ) ; Sw_WriteSubclass( w, "AcDbViewTableRecord" )
   Sw_WriteString( w, 2, vw[ "name" ] )
   IF vw[ "paper_space" ] ; nF := hb_bitOr( nF, 1 ) ; ENDIF
   IF vw[ "xref_dependent" ] ; nF := hb_bitOr( nF, 16 ) ; ENDIF
   IF vw[ "xref_resolved" ] ; nF := hb_bitOr( nF, 32 ) ; ENDIF
   IF vw[ "xref_reference" ] ; nF := hb_bitOr( nF, 64 ) ; ENDIF
   Sw_WriteI16( w, 70, nF )
   Sw_WriteDouble( w, 40, vw[ "height" ] ) ; Sw_WriteDouble( w, 10, vw[ "center" ][ 1 ] ) ; Sw_WriteDouble( w, 20, vw[ "center" ][ 2 ] )
   Sw_WriteDouble( w, 41, vw[ "width" ] ) ; Sw_WritePoint3d( w, 11, vw[ "direction" ] ) ; Sw_WritePoint3d( w, 12, vw[ "target" ] )
   Sw_WriteDouble( w, 42, vw[ "lens_length" ] ) ; Sw_WriteDouble( w, 43, vw[ "front_clip" ] ) ; Sw_WriteDouble( w, 44, vw[ "back_clip" ] )
   Sw_WriteDouble( w, 50, vw[ "twist_angle" ] * ( 180.0 / OCX_PI ) )
   IF vw[ "perspective" ] ; nM := hb_bitOr( nM, 1 ) ; ENDIF
   IF vw[ "front_clipping" ] ; nM := hb_bitOr( nM, 2 ) ; ENDIF
   IF vw[ "back_clipping" ] ; nM := hb_bitOr( nM, 4 ) ; ENDIF
   IF vw[ "front_clip_at_eye" ] ; nM := hb_bitOr( nM, 16 ) ; ENDIF
   Sw_WriteI16( w, 71, nM )
   IF st[ 2 ] >= Dxv_FromVersionString( "AC1015" )
      Sw_WriteI16( w, 72, IIf( vw[ "ucs_associated" ], 1, 0 ) ) ; Sw_WriteI16( w, 281, Vrm_ToValue( vw[ "render_mode" ] ) )
      IF vw[ "ucs_associated" ]
         Sw_WritePoint3d( w, 110, vw[ "ucs_origin" ] ) ; Sw_WritePoint3d( w, 111, vw[ "ucs_x_axis" ] ) ; Sw_WritePoint3d( w, 112, vw[ "ucs_y_axis" ] )
         Sw_WriteDouble( w, 146, vw[ "ucs_elevation" ] ) ; Sw_WriteI16( w, 79, vw[ "ucs_ortho_type" ] )
         IF ! Hd_IsNull( vw[ "named_ucs_handle" ] ) ; Sw_WriteHandle( w, 345, vw[ "named_ucs_handle" ] ) ; ENDIF
         IF ! Hd_IsNull( vw[ "base_ucs_handle" ] ) ; Sw_WriteHandle( w, 346, vw[ "base_ucs_handle" ] ) ; ENDIF
      ENDIF
   ENDIF
   IF st[ 2 ] >= Dxv_FromVersionString( "AC1021" )
      Sw_WriteI16( w, 73, IIf( vw[ "camera_plottable" ], 1, 0 ) )
      IF ! Hd_IsNull( vw[ "background_handle" ] ) ; Sw_WriteHandle( w, 332, vw[ "background_handle" ] ) ; ENDIF
      IF ! Hd_IsNull( vw[ "live_section_handle" ] ) ; Sw_WriteHandle( w, 334, vw[ "live_section_handle" ] ) ; ENDIF
      IF ! Hd_IsNull( vw[ "visual_style_handle" ] ) ; Sw_WriteHandle( w, 348, vw[ "visual_style_handle" ] ) ; ENDIF
      IF ! Hd_IsNull( vw[ "sun_handle" ] ) ; Sw_WriteHandle( w, 361, vw[ "sun_handle" ] ) ; ENDIF
      Sw_WriteBool( w, 292, vw[ "use_default_lights" ] ) ; Sw_WriteI16( w, 282, vw[ "default_lighting_type" ] )
      Sw_WriteDouble( w, 141, vw[ "brightness" ] ) ; Sw_WriteDouble( w, 142, vw[ "contrast" ] )
      Sw_WriteColor( w, 63, vw[ "ambient_color" ] )
      rgb := Cl_ToTrueColorValue( vw[ "ambient_color" ] )
      IF rgb != NIL ; Sw_WriteI32( w, 421, rgb ) ; ENDIF
   ENDIF
RETURN

STATIC PROCEDURE Swr_UcsEntry( st, d, u, hOwner )
   LOCAL w := st[ 1 ], nF := 0
   Sw_WriteString( w, 0, "UCS" )
   Swr_CommonTable( st, d, u[ "handle" ], hOwner )
   Sw_WriteSubclass( w, "AcDbSymbolTableRecord" ) ; Sw_WriteSubclass( w, "AcDbUCSTableRecord" )
   Sw_WriteString( w, 2, u[ "name" ] )
   IF u[ "xref_dependent" ] ; nF := hb_bitOr( nF, 16 ) ; ENDIF
   IF u[ "xref_resolved" ] ; nF := hb_bitOr( nF, 32 ) ; ENDIF
   IF u[ "xref_reference" ] ; nF := hb_bitOr( nF, 64 ) ; ENDIF
   Sw_WriteI16( w, 70, nF )
   Sw_WritePoint3d( w, 10, u[ "origin" ] ) ; Sw_WritePoint3d( w, 11, u[ "x_axis" ] ) ; Sw_WritePoint3d( w, 12, u[ "y_axis" ] )
   IF st[ 2 ] >= Dxv_FromVersionString( "AC1015" )
      Sw_WriteI16( w, 71, u[ "ortho_type" ] ) ; Sw_WriteI16( w, 79, u[ "ortho_view_type" ] ) ; Sw_WriteDouble( w, 146, u[ "elevation" ] )
      IF ! Hd_IsNull( u[ "base_ucs_handle" ] ) ; Sw_WriteHandle( w, 346, u[ "base_ucs_handle" ] ) ; ENDIF
   ENDIF
RETURN

STATIC PROCEDURE Swr_BlockRecordEntry( st, d, br, hOwner )
   LOCAL w := st[ 1 ], h, aRef
   Sw_WriteString( w, 0, "BLOCK_RECORD" )
   Swr_CommonTable( st, d, br[ "handle" ], hOwner )
   Sw_WriteSubclass( w, "AcDbSymbolTableRecord" ) ; Sw_WriteSubclass( w, "AcDbBlockTableRecord" )
   Sw_WriteString( w, 2, br[ "name" ] )
   Sw_WriteHandle( w, 340, br[ "layout" ] )
   aRef := {}
   FOR EACH h IN br[ "insert_handles" ]
      IF Swr_Valid( st, h ) ; AAdd( aRef, h ) ; ENDIF
   NEXT
   IF Len( aRef ) > 0
      Sw_WriteString( w, 102, "{BLKREFS" )
      FOR EACH h IN aRef ; Sw_WriteHandle( w, 331, h ) ; NEXT
      Sw_WriteString( w, 102, "}" )
   ENDIF
   FOR h := 1 TO hb_BLen( br[ "preview_data" ] ) STEP 127
      Sw_WriteBinary( w, 310, hb_BSubStr( br[ "preview_data" ], h, 127 ) )
   NEXT
   IF st[ 2 ] >= Dxv_FromVersionString( "AC1021" )
      Sw_WriteI16( w, 70, br[ "units" ] ) ; Sw_WriteByte( w, 280, IIf( br[ "explodable" ], 1, 0 ) ) ; Sw_WriteI16( w, 281, IIf( br[ "scale_uniformly" ], 1, 0 ) )
   ENDIF
   IF st[ 2 ] < Dxv_FromVersionString( "AC1021" ) .AND. br[ "units" ] != 0
      Swr_XData( w, Swr_DesignCenterXData( br[ "units" ] ) )
   ENDIF
RETURN

STATIC FUNCTION Swr_DesignCenterXData( nUnits )
   LOCAL xd := Xd_New(), r := Xr_New( "ACAD" ), v
   FOR EACH v IN Blk_DesignCenterUnitsValues( nUnits )
      Xr_AddValue( r, v )
   NEXT
   Xd_AddRecord( xd, r )
RETURN xd

PROCEDURE Swr_Tables( st, d )
   LOCAL w := st[ 1 ], t, e, h
   Sw_WriteSectionStart( w, "TABLES" )
   t := d[ "vports" ]
   Swr_TableHeader( w, d, "VPORT", Tb_Len( t ), Tb_Handle( t ) )
   FOR EACH e IN Tb_Values( t ) ; Swr_VportEntry( st, d, e, Tb_Handle( t ) ) ; NEXT
   Sw_WriteString( w, 0, "ENDTAB" )
   t := d[ "line_types" ]
   Swr_TableHeader( w, d, "LTYPE", Tb_Len( t ), Tb_Handle( t ) )
   FOR EACH e IN Tb_Values( t ) ; Swr_LtypeEntry( st, d, e, Tb_Handle( t ) ) ; NEXT
   Sw_WriteString( w, 0, "ENDTAB" )
   t := d[ "layers" ]
   Swr_TableHeader( w, d, "LAYER", Tb_Len( t ), Tb_Handle( t ) )
   FOR EACH e IN Tb_Values( t )
      h := IIf( Hd_IsNull( e[ "handle" ] ), Doc_AllocateHandle( d ), e[ "handle" ] )
      Swr_LayerEntry( st, d, e, Tb_Handle( t ), h )
   NEXT
   Sw_WriteString( w, 0, "ENDTAB" )
   t := d[ "text_styles" ]
   Swr_TableHeader( w, d, "STYLE", Tb_Len( t ), Tb_Handle( t ) )
   FOR EACH e IN Tb_Values( t ) ; Swr_StyleEntry( st, d, e, Tb_Handle( t ) ) ; NEXT
   Sw_WriteString( w, 0, "ENDTAB" )
   t := d[ "views" ]
   Swr_TableHeader( w, d, "VIEW", Tb_Len( t ), Tb_Handle( t ) )
   FOR EACH e IN Tb_Values( t ) ; Swr_ViewEntry( st, d, e, Tb_Handle( t ) ) ; NEXT
   Sw_WriteString( w, 0, "ENDTAB" )
   t := d[ "ucss" ]
   Swr_TableHeader( w, d, "UCS", Tb_Len( t ), Tb_Handle( t ) )
   FOR EACH e IN Tb_Values( t ) ; Swr_UcsEntry( st, d, e, Tb_Handle( t ) ) ; NEXT
   Sw_WriteString( w, 0, "ENDTAB" )
   t := d[ "app_ids" ]
   Swr_TableHeader( w, d, "APPID", Tb_Len( t ), Tb_Handle( t ) )
   FOR EACH e IN Tb_Values( t )
      IF Upper( e[ "name" ] ) == "ACAD" ; Swr_AppIdEntry( st, d, e, Tb_Handle( t ) ) ; EXIT ; ENDIF
   NEXT
   FOR EACH e IN Tb_Values( t )
      IF ! ( Upper( e[ "name" ] ) == "ACAD" ) ; Swr_AppIdEntry( st, d, e, Tb_Handle( t ) ) ; ENDIF
   NEXT
   Sw_WriteString( w, 0, "ENDTAB" )
   t := d[ "dim_styles" ]
   Swr_TableHeader( w, d, "DIMSTYLE", Tb_Len( t ), Tb_Handle( t ) )
   IF st[ 2 ] >= Dxv_FromVersionString( "AC1015" ) ; Sw_WriteSubclass( w, "AcDbDimStyleTable" ) ; Sw_WriteI16( w, 71, Tb_Len( t ) ) ; ENDIF
   FOR EACH e IN Tb_Values( t ) ; Swr_DimStyleEntry( st, d, e, Tb_Handle( t ) ) ; NEXT
   Sw_WriteString( w, 0, "ENDTAB" )
   t := d[ "block_records" ]
   Swr_TableHeader( w, d, "BLOCK_RECORD", Tb_Len( t ), Tb_Handle( t ) )
   FOR EACH e IN Tb_Values( t ) ; Swr_BlockRecordEntry( st, d, e, Tb_Handle( t ) ) ; NEXT
   Sw_WriteString( w, 0, "ENDTAB" )
   Sw_WriteSectionEnd( w )
RETURN

/* ---- entidades ---- */
STATIC PROCEDURE Swr_Normal( w, v )
   IF ! ( v[ 1 ] == 0.0 .AND. v[ 2 ] == 0.0 .AND. v[ 3 ] == 1.0 )
      Sw_WriteDouble( w, 210, v[ 1 ] ) ; Sw_WriteDouble( w, 220, v[ 2 ] ) ; Sw_WriteDouble( w, 230, v[ 3 ] )
   ENDIF
RETURN

STATIC PROCEDURE Swr_CommonEntity( st, c, hOwner )
   LOCAL w := st[ 1 ], h, tc, aR := {}
   Sw_WriteHandle( w, 5, c[ "handle" ] ) ; Sw_WriteHandle( w, 330, Swr_SafeOwner( st, hOwner ) )
   IF c[ "xdictionary_handle" ] != NIL .AND. ! Hd_IsNull( c[ "xdictionary_handle" ] ) .AND. Swr_Valid( st, c[ "xdictionary_handle" ] )
      Sw_WriteString( w, 102, "{ACAD_XDICTIONARY" ) ; Sw_WriteHandle( w, 360, c[ "xdictionary_handle" ] ) ; Sw_WriteString( w, 102, "}" )
   ENDIF
   FOR EACH h IN c[ "reactors" ]
      IF Len( st[ 8 ] ) == 0 .OR. hb_HHasKey( st[ 8 ], h ) ; AAdd( aR, h ) ; ENDIF
   NEXT
   IF Len( aR ) > 0
      Sw_WriteString( w, 102, "{ACAD_REACTORS" )
      FOR EACH h IN aR ; Sw_WriteHandle( w, 330, h ) ; NEXT
      Sw_WriteString( w, 102, "}" )
   ENDIF
   Sw_WriteSubclass( w, "AcDbEntity" )
   IF st[ 4 ] ; Sw_WriteI16( w, 67, 1 ) ; ENDIF
   Sw_WriteString( w, 8, c[ "layer" ] )
   IF c[ "graphic_data" ] != NIL
      IF st[ 2 ] >= Dxv_FromVersionString( "AC1024" ) ; Sw_WriteI64( w, 160, hb_BLen( c[ "graphic_data" ] ) ) ; ELSE ; Sw_WriteI32( w, 92, hb_BLen( c[ "graphic_data" ] ) ) ; ENDIF
      FOR h := 1 TO hb_BLen( c[ "graphic_data" ] ) STEP 127
         Sw_WriteBinary( w, 310, hb_BSubStr( c[ "graphic_data" ], h, 127 ) )
      NEXT
   ENDIF
   IF Ec_HasLinetype( c ) ; Sw_WriteString( w, 6, c[ "linetype" ] ) ; ENDIF
   IF ! Cl_Eq( c[ "color" ], Cl_ByLayer() ) ; Sw_WriteColor( w, 62, c[ "color" ] ) ; ENDIF
   IF st[ 2 ] >= Dxv_FromVersionString( "AC1018" )
      tc := Cl_ToTrueColorValue( c[ "color" ] )
      IF tc != NIL ; Sw_WriteI32( w, 420, tc ) ; ENDIF
      IF c[ "color_name" ] != NIL ; Sw_WriteString( w, 430, c[ "color_name" ] ) ; ENDIF
   ENDIF
   IF Abs( c[ "linetype_scale" ] - 1.0 ) > 0.000000000001 ; Sw_WriteDouble( w, 48, c[ "linetype_scale" ] ) ; ENDIF
   IF ! Lw_Eq( c[ "line_weight" ], Lw_ByLayer() ) ; Sw_WriteI16( w, 370, Lw_GetValue( c[ "line_weight" ] ) ) ; ENDIF
   IF c[ "invisible" ] ; Sw_WriteI16( w, 60, 1 ) ; ENDIF
   IF st[ 2 ] >= Dxv_FromVersionString( "AC1018" ) .AND. ! Tp_IsByLayer( c[ "transparency" ] )
      Sw_WriteI32( w, 440, Tp_ToDxfValue( c[ "transparency" ] ) )
   ENDIF
   IF st[ 2 ] >= Dxv_FromVersionString( "AC1024" )
      FOR EACH h IN { c[ "full_visual_style_handle" ], c[ "face_visual_style_handle" ], c[ "edge_visual_style_handle" ] }
         IF h != NIL .AND. ! Hd_IsNull( h ) .AND. Swr_Valid( st, h ) ; Sw_WriteHandle( w, 348, h ) ; ENDIF
      NEXT
   ENDIF
RETURN

/* write_dimension_base (sin safe_entity_owner, como el original) */
STATIC PROCEDURE Swr_DimBase( st, b, vDef, nFlags, hOwner )
   LOCAL w := st[ 1 ], c := b[ "common" ], h, tc, n, cTxt, aR := {}
   Sw_WriteHandle( w, 5, c[ "handle" ] ) ; Sw_WriteHandle( w, 330, hOwner )
   IF c[ "xdictionary_handle" ] != NIL .AND. ! Hd_IsNull( c[ "xdictionary_handle" ] ) .AND. Swr_Valid( st, c[ "xdictionary_handle" ] )
      Sw_WriteString( w, 102, "{ACAD_XDICTIONARY" ) ; Sw_WriteHandle( w, 360, c[ "xdictionary_handle" ] ) ; Sw_WriteString( w, 102, "}" )
   ENDIF
   FOR EACH h IN c[ "reactors" ]
      IF Swr_Valid( st, h ) ; AAdd( aR, h ) ; ENDIF
   NEXT
   IF Len( aR ) > 0
      Sw_WriteString( w, 102, "{ACAD_REACTORS" )
      FOR EACH h IN aR ; Sw_WriteHandle( w, 330, h ) ; NEXT
      Sw_WriteString( w, 102, "}" )
   ENDIF
   Sw_WriteSubclass( w, "AcDbEntity" ) ; Sw_WriteString( w, 8, c[ "layer" ] )
   IF ! Cl_Eq( c[ "color" ], Cl_ByLayer() ) ; Sw_WriteColor( w, 62, c[ "color" ] ) ; ENDIF
   IF st[ 2 ] >= Dxv_FromVersionString( "AC1018" )
      tc := Cl_ToTrueColorValue( c[ "color" ] )
      IF tc != NIL ; Sw_WriteI32( w, 420, tc ) ; ENDIF
      IF c[ "color_name" ] != NIL ; Sw_WriteString( w, 430, c[ "color_name" ] ) ; ENDIF
      IF ! Tp_IsByLayer( c[ "transparency" ] ) ; Sw_WriteI32( w, 440, Tp_ToDxfValue( c[ "transparency" ] ) ) ; ENDIF
   ENDIF
   Sw_WriteSubclass( w, "AcDbDimension" )
   IF Len( b[ "block_name" ] ) > 0 ; Sw_WriteString( w, 2, b[ "block_name" ] ) ; ENDIF
   Sw_WritePoint3d( w, 10, vDef ) ; Sw_WritePoint3d( w, 11, b[ "text_middle_point" ] )
   IF b[ "text_user_positioned" ] ; nFlags := hb_bitOr( nFlags, 128 ) ; ENDIF
   Sw_WriteI16( w, 70, nFlags ) ; Sw_WriteDouble( w, 42, b[ "actual_measurement" ] )
   Sw_WriteDouble( w, 53, b[ "text_rotation" ] * ( 180.0 / OCX_PI ) )
   IF Abs( b[ "horizontal_direction" ] ) > 0.000000000001 ; Sw_WriteDouble( w, 51, b[ "horizontal_direction" ] * ( 180.0 / OCX_PI ) ) ; ENDIF
   Sw_WriteI16( w, 71, b[ "attachment_point" ] ) ; Sw_WriteI16( w, 72, b[ "line_spacing_style" ] ) ; Sw_WriteString( w, 3, b[ "style_name" ] )
   cTxt := Dmb_TextOverride( b )
   IF cTxt != NIL ; Sw_WriteString( w, 1, cTxt ) ; ENDIF
   IF Abs( b[ "line_spacing_factor" ] - 1.0 ) > 0.0000000001 ; Sw_WriteDouble( w, 41, b[ "line_spacing_factor" ] ) ; ENDIF
   n := b[ "normal" ]
   IF Abs( n[ 1 ] ) > 0.000000000001 .OR. Abs( n[ 2 ] ) > 0.000000000001 .OR. Abs( n[ 3 ] - 1.0 ) > 0.000000000001
      Sw_WriteDouble( w, 210, n[ 1 ] ) ; Sw_WriteDouble( w, 220, n[ 2 ] ) ; Sw_WriteDouble( w, 230, n[ 3 ] )
   ENDIF
RETURN

/* write_dimension (Aligned/Linear/Radius/Diameter/Angular2Ln/Angular3Pt/Ordinate). Arc/LargeRadial incluidos */
STATIC PROCEDURE Swr_Dimension( st, e, hOwner )
   LOCAL w := st[ 1 ], t := e[ "_type" ], b := e[ "base" ], bb
   DO CASE
   CASE t == "DIMENSION_ALIGNED"
      Sw_WriteEntityType( w, "DIMENSION" ) ; Swr_DimBase( st, b, e[ "definition_point" ], 1, hOwner ) ; Sw_WriteSubclass( w, "AcDbAlignedDimension" )
      Sw_WritePoint3d( w, 13, e[ "first_point" ] ) ; Sw_WritePoint3d( w, 14, e[ "second_point" ] )
      IF Abs( e[ "ext_line_rotation" ] ) > 0.000000000001 ; Sw_WriteDouble( w, 52, e[ "ext_line_rotation" ] * ( 180.0 / OCX_PI ) ) ; ENDIF
   CASE t == "DIMENSION_LINEAR"
      Sw_WriteEntityType( w, "DIMENSION" ) ; Swr_DimBase( st, b, e[ "definition_point" ], 0, hOwner ) ; Sw_WriteSubclass( w, "AcDbAlignedDimension" )
      Sw_WritePoint3d( w, 13, e[ "first_point" ] ) ; Sw_WritePoint3d( w, 14, e[ "second_point" ] ) ; Sw_WriteDouble( w, 50, e[ "rotation" ] * ( 180.0 / OCX_PI ) )
      IF Abs( e[ "ext_line_rotation" ] ) > 0.000000000001 ; Sw_WriteDouble( w, 52, e[ "ext_line_rotation" ] * ( 180.0 / OCX_PI ) ) ; ENDIF
      Sw_WriteSubclass( w, "AcDbRotatedDimension" )
   CASE t == "DIMENSION_RADIUS"
      Sw_WriteEntityType( w, "DIMENSION" ) ; Swr_DimBase( st, b, e[ "angle_vertex" ], 4, hOwner ) ; Sw_WriteSubclass( w, "AcDbRadialDimension" )
      Sw_WritePoint3d( w, 15, e[ "definition_point" ] ) ; Sw_WriteDouble( w, 40, e[ "leader_length" ] )
   CASE t == "DIMENSION_DIAMETER"
      Sw_WriteEntityType( w, "DIMENSION" ) ; Swr_DimBase( st, b, e[ "definition_point" ], 3, hOwner ) ; Sw_WriteSubclass( w, "AcDbDiametricDimension" )
      Sw_WritePoint3d( w, 15, e[ "angle_vertex" ] ) ; Sw_WriteDouble( w, 40, e[ "leader_length" ] )
   CASE t == "DIMENSION_ANGULAR_2LINE"
      Sw_WriteEntityType( w, "DIMENSION" ) ; Swr_DimBase( st, b, e[ "definition_point" ], 2, hOwner ) ; Sw_WriteSubclass( w, "AcDb2LineAngularDimension" )
      Sw_WritePoint3d( w, 13, e[ "first_point" ] ) ; Sw_WritePoint3d( w, 14, e[ "second_point" ] ) ; Sw_WritePoint3d( w, 15, e[ "angle_vertex" ] ) ; Sw_WritePoint3d( w, 16, e[ "dimension_arc" ] )
   CASE t == "DIMENSION_ANGULAR_3POINT"
      Sw_WriteEntityType( w, "DIMENSION" ) ; Swr_DimBase( st, b, e[ "definition_point" ], 5, hOwner ) ; Sw_WriteSubclass( w, "AcDb3PointAngularDimension" )
      Sw_WritePoint3d( w, 13, e[ "first_point" ] ) ; Sw_WritePoint3d( w, 14, e[ "second_point" ] ) ; Sw_WritePoint3d( w, 15, e[ "angle_vertex" ] )
   CASE t == "DIMENSION_ORDINATE"
      bb := Ent_Clone( b ) ; bb[ "actual_measurement" ] := Dor_Measurement( e )
      Sw_WriteEntityType( w, "DIMENSION" ) ; Swr_DimBase( st, bb, e[ "definition_point" ], hb_bitOr( 6, IIf( e[ "is_ordinate_type_x" ], 64, 0 ) ), hOwner )
      Sw_WriteSubclass( w, "AcDbOrdinateDimension" ) ; Sw_WritePoint3d( w, 13, e[ "feature_location" ] ) ; Sw_WritePoint3d( w, 14, e[ "leader_endpoint" ] )
   CASE t == "ARC_DIMENSION"
      Sw_WriteEntityType( w, "ARC_DIMENSION" ) ; Swr_DimBase( st, b, e[ "definition_point" ], 8, hOwner ) ; Sw_WriteSubclass( w, "AcDbArcDimension" )
      Sw_WritePoint3d( w, 13, e[ "first_extension_point" ] ) ; Sw_WritePoint3d( w, 14, e[ "second_extension_point" ] ) ; Sw_WritePoint3d( w, 15, e[ "center_point" ] )
      Sw_WriteBool( w, 70, e[ "is_partial" ] ) ; Sw_WriteDouble( w, 40, e[ "arc_start_parameter" ] ) ; Sw_WriteDouble( w, 41, e[ "arc_end_parameter" ] )
      Sw_WriteBool( w, 71, e[ "has_leader" ] ) ; Sw_WritePoint3d( w, 16, e[ "first_leader_point" ] ) ; Sw_WritePoint3d( w, 17, e[ "second_leader_point" ] )
   CASE t == "LARGE_RADIAL_DIMENSION"
      Sw_WriteEntityType( w, "LARGE_RADIAL_DIMENSION" ) ; Swr_DimBase( st, b, e[ "definition_point" ], 4, hOwner ) ; Sw_WriteSubclass( w, "AcDbRadialDimensionLarge" )
      Sw_WritePoint3d( w, 13, e[ "jog_point" ] ) ; Sw_WritePoint3d( w, 14, e[ "override_center" ] ) ; Sw_WritePoint3d( w, 15, e[ "chord_point" ] ) ; Sw_WriteDouble( w, 40, e[ "jog_angle" ] )
   ENDCASE
RETURN

STATIC FUNCTION Swr_Deg( n ) ; RETURN n * ( 180.0 / OCX_PI )

/* write_attribute_text_value: DXF es por lineas, un salto dentro del valor se escribe como \P */
STATIC FUNCTION Swr_AttrText( c )
   c := StrTran( c, Chr( 13 ) + Chr( 10 ), "\P" )
   c := StrTran( c, Chr( 13 ), "\P" )
RETURN StrTran( c, Chr( 10 ), "\P" )

/* write_attribute_mtext: cola multilinea R2018+ (MTEXT flag, 72 0, punto 11 y el objeto embebido 101) */
STATIC PROCEDURE Swr_AttribMtext( w, nFlag, e, cValue )
   LOCAL m := e[ "embedded_mtext" ], xd
   IF m == NIL
      m := Emt_WithValue( cValue, e[ "insertion_point" ] )
      m[ "normal" ] := e[ "normal" ] ; m[ "rotation" ] := e[ "rotation" ] ; m[ "height" ] := e[ "height" ] ; m[ "style" ] := e[ "text_style" ]
   ENDIF
   Sw_WriteI16( w, 71, nFlag ) ; Sw_WriteI16( w, 72, 0 ) ; Sw_WritePoint3d( w, 11, e[ "alignment_point" ] )
   Sw_WriteString( w, 101, "Embedded Object" )
   Sw_WritePoint3d( w, 10, m[ "insertion_point" ] ) ; Sw_WriteDouble( w, 40, m[ "height" ] ) ; Sw_WriteDouble( w, 41, m[ "rectangle_width" ] )
   Sw_WriteDouble( w, 46, IIf( m[ "rectangle_height" ] == NIL, 0.0, m[ "rectangle_height" ] ) )
   Sw_WriteI16( w, 71, m[ "attachment_point" ] ) ; Sw_WriteI16( w, 72, m[ "drawing_direction" ] )
   Swr_MTextValue( w, m[ "value" ] ) ; Sw_WriteString( w, 7, m[ "style" ] )
   IF ! ( m[ "normal" ][ 1 ] == 0.0 .AND. m[ "normal" ][ 2 ] == 0.0 .AND. m[ "normal" ][ 3 ] == 1.0 )
      Sw_WritePoint3d( w, 210, m[ "normal" ] )
   ENDIF
   IF m[ "rotation" ] != 0.0
      xd := m[ "dwg_x_direction" ]
      IF xd == NIL .OR. ! ( OCX_ATAN2( xd[ 2 ], xd[ 1 ] ) == m[ "rotation" ] )
         xd := Vc3_New( OCX_COS( m[ "rotation" ] ), OCX_SIN( m[ "rotation" ] ), 0.0 )
      ENDIF
      Sw_WritePoint3d( w, 11, xd )
   ENDIF
   IF m[ "extents_width" ] > 0.0 ; Sw_WriteDouble( w, 42, m[ "extents_width" ] ) ; ENDIF
   IF m[ "extents_height" ] > 0.0 ; Sw_WriteDouble( w, 43, m[ "extents_height" ] ) ; ENDIF
   IF m[ "rotation" ] != 0.0 ; Sw_WriteDouble( w, 50, Swr_Deg( m[ "rotation" ] ) ) ; ENDIF
   Sw_WriteI16( w, 73, m[ "line_spacing_style" ] ) ; Sw_WriteDouble( w, 44, m[ "line_spacing_factor" ] )
RETURN

/* write_attdef / write_attrib */
STATIC PROCEDURE Swr_AttdefAttrib( st, e, hOwner, lDef )
   LOCAL w := st[ 1 ], c := e[ "common" ], lMl, cVal
   lMl := st[ 2 ] >= Dxv_FromVersionString( "AC1032" ) .AND. ( e[ "is_multiline" ] .OR. e[ "embedded_mtext" ] != NIL )
   cVal := IIf( lDef, e[ "default_value" ], e[ "value" ] )
   IF lMl .AND. e[ "embedded_mtext" ] != NIL ; cVal := e[ "embedded_mtext" ][ "value" ] ; ENDIF
   Sw_WriteEntityType( w, IIf( lDef, "ATTDEF", "ATTRIB" ) ) ; Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, "AcDbText" )
   Sw_WritePoint3d( w, 10, e[ "insertion_point" ] ) ; Sw_WriteDouble( w, 40, e[ "height" ] )
   Sw_WriteString( w, 1, Swr_AttrText( cVal ) )
   Sw_WriteDouble( w, 50, Swr_Deg( e[ "rotation" ] ) ) ; Sw_WriteDouble( w, 41, e[ "width_factor" ] )
   Sw_WriteDouble( w, 51, Swr_Deg( e[ "oblique_angle" ] ) ) ; Sw_WriteString( w, 7, e[ "text_style" ] )
   Sw_WriteI16( w, 71, e[ "text_generation_flags" ] ) ; Sw_WriteI16( w, 72, e[ "horizontal_alignment" ] )
   Sw_WritePoint3d( w, 11, e[ "alignment_point" ] ) ; Sw_WritePoint3d( w, 210, e[ "normal" ] )
   Sw_WriteSubclass( w, IIf( lDef, "AcDbAttributeDefinition", "AcDbAttribute" ) )
   IF st[ 2 ] >= Dxv_FromVersionString( "AC1024" ) ; Sw_WriteByte( w, 280, 0 ) ; ENDIF
   IF lDef ; Sw_WriteString( w, 3, e[ "prompt" ] ) ; ENDIF
   Sw_WriteString( w, 2, e[ "tag" ] ) ; Sw_WriteI16( w, 70, Taf_ToBits( e[ "flags" ] ) )
   Sw_WriteI16( w, 73, e[ "field_length" ] ) ; Sw_WriteI16( w, 74, e[ "vertical_alignment" ] )
   IF st[ 2 ] >= Dxv_FromVersionString( "AC1021" ) ; Sw_WriteByte( w, 280, IIf( e[ "lock_position" ], 1, 0 ) ) ; ENDIF
   IF lMl ; Swr_AttribMtext( w, IIf( lDef, 4, 2 ), e, IIf( lDef, e[ "default_value" ], e[ "value" ] ) ) ; ENDIF
   IF ! lDef ; Swr_XData( w, c[ "extended_data" ] ) ; ENDIF
RETURN

/* write_mtext_value: \n y \r se sustituyen por \P; trozos de 250 bytes por codigo 3 y el resto por el 1 */
STATIC PROCEDURE Swr_MTextValue( w, c )
   c := Swr_AttrText( c )
   DO WHILE Len( c ) > 250
      Sw_WriteString( w, 3, Left( c, 250 ) ) ; c := SubStr( c, 251 )
   ENDDO
   Sw_WriteString( w, 1, c )
RETURN

STATIC PROCEDURE Swr_MTextBody( st, e, hOwner )
   LOCAL w := st[ 1 ], c := e[ "common" ], cd := e[ "column_data" ], lMan, nCnt, h, nI, tc
   Sw_WriteEntityType( w, "MTEXT" ) ; Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, "AcDbMText" )
   Sw_WritePoint3d( w, 10, e[ "insertion_point" ] ) ; Sw_WriteDouble( w, 40, e[ "height" ] ) ; Sw_WriteDouble( w, 41, e[ "rectangle_width" ] )
   Sw_WriteI16( w, 71, e[ "attachment_point" ] ) ; Sw_WriteI16( w, 72, e[ "drawing_direction" ] )
   Swr_MTextValue( w, e[ "value" ] ) ; Sw_WriteString( w, 7, e[ "style" ] )
   IF e[ "rotation" ] != 0.0 ; Sw_WriteDouble( w, 50, Swr_Deg( e[ "rotation" ] ) ) ; ENDIF
   IF e[ "extents_width" ] > 0.0 ; Sw_WriteDouble( w, 42, e[ "extents_width" ] ) ; ENDIF
   IF e[ "extents_height" ] > 0.0 ; Sw_WriteDouble( w, 43, e[ "extents_height" ] ) ; ENDIF
   Sw_WriteI16( w, 73, e[ "line_spacing_style" ] ) ; Sw_WriteDouble( w, 44, e[ "line_spacing_factor" ] )
   IF e[ "rectangle_height" ] != NIL ; Sw_WriteDouble( w, 46, e[ "rectangle_height" ] ) ; ENDIF
   IF e[ "background_fill_flags" ] != 0
      Sw_WriteI32( w, 90, e[ "background_fill_flags" ] ) ; Sw_WriteDouble( w, 45, e[ "background_scale" ] )
      tc := Cl_ToTrueColorValue( e[ "background_color" ] )
      IF tc != NIL
         Sw_WriteI32( w, 421, tc )
      ELSEIF Cl_IndexOf( e[ "background_color" ] ) != NIL
         Sw_WriteI16( w, 63, Cl_IndexOf( e[ "background_color" ] ) )
      ENDIF
      IF e[ "background_transparency" ] != 0 ; Sw_WriteI32( w, 441, e[ "background_transparency" ] ) ; ENDIF
   ENDIF
   lMan := ( cd[ "column_type" ] == 2 .AND. ! cd[ "auto_height" ] )
   IF cd[ "column_type" ] != 0 .AND. st[ 2 ] >= Dxv_FromVersionString( "AC1032" )
      Swr_Normal( w, e[ "normal" ] )
      nCnt := IIf( lMan, Len( cd[ "heights" ] ), cd[ "column_count" ] )
      Sw_WriteString( w, 101, "Embedded Object" ) ; Sw_WriteI16( w, 70, e[ "attachment_point" ] )
      Sw_WritePoint3d( w, 10, Vc3_New( OCX_COS( e[ "rotation" ] ), OCX_SIN( e[ "rotation" ] ), 0.0 ) ) ; Sw_WritePoint3d( w, 11, e[ "insertion_point" ] )
      Sw_WriteDouble( w, 40, e[ "rectangle_width" ] ) ; Sw_WriteDouble( w, 41, IIf( e[ "rectangle_height" ] == NIL, 0.0, e[ "rectangle_height" ] ) )
      Sw_WriteDouble( w, 42, e[ "extents_width" ] ) ; Sw_WriteDouble( w, 43, e[ "extents_height" ] )
      Sw_WriteI16( w, 71, cd[ "column_type" ] ) ; Sw_WriteI16( w, 72, Max( 0, Min( nCnt, 32767 ) ) )
      Sw_WriteDouble( w, 44, cd[ "width" ] ) ; Sw_WriteDouble( w, 45, cd[ "gutter" ] )
      Sw_WriteI16( w, 73, IIf( cd[ "auto_height" ], 1, 0 ) ) ; Sw_WriteI16( w, 74, IIf( cd[ "flow_reversed" ], 1, 0 ) )
      IF lMan
         FOR EACH h IN cd[ "heights" ] ; Sw_WriteDouble( w, 46, h ) ; NEXT
      ENDIF
      RETURN
   ENDIF
   IF cd[ "column_type" ] != 0
      nCnt := IIf( lMan, Min( Len( cd[ "heights" ] ), 32767 ), Max( 0, Min( cd[ "column_count" ], 32767 ) ) )
      Sw_WriteI16( w, 75, cd[ "column_type" ] ) ; Sw_WriteI16( w, 76, nCnt )
      Sw_WriteI16( w, 78, IIf( cd[ "flow_reversed" ], 1, 0 ) ) ; Sw_WriteI16( w, 79, IIf( cd[ "auto_height" ], 1, 0 ) )
      Sw_WriteDouble( w, 48, cd[ "width" ] ) ; Sw_WriteDouble( w, 49, cd[ "gutter" ] )
      IF lMan
         FOR nI := 1 TO Min( nCnt, Len( cd[ "heights" ] ) ) ; Sw_WriteDouble( w, 50, cd[ "heights" ][ nI ] ) ; NEXT
      ENDIF
   ENDIF
   Swr_Normal( w, e[ "normal" ] )
RETURN

STATIC PROCEDURE Swr_SeqEnd( st, hSeq, hOwner, cLayer )
   LOCAL w := st[ 1 ]
   Sw_WriteEntityType( w, "SEQEND" ) ; Sw_WriteHandle( w, 5, hSeq ) ; Sw_WriteHandle( w, 330, hOwner )
   Sw_WriteSubclass( w, "AcDbEntity" )
   IF st[ 4 ] ; Sw_WriteI16( w, 67, 1 ) ; ENDIF
   Sw_WriteString( w, 8, cLayer )
RETURN

/* Cabecera de VERTEX comun */
STATIC PROCEDURE Swr_VertexHead( st, hV, hOwner, cLayer, xColor )
   LOCAL w := st[ 1 ]
   Sw_WriteEntityType( w, "VERTEX" ) ; Sw_WriteHandle( w, 5, hV ) ; Sw_WriteHandle( w, 330, hOwner )
   Sw_WriteSubclass( w, "AcDbEntity" ) ; Sw_WriteString( w, 8, cLayer )
   IF xColor != NIL .AND. ! Cl_Eq( xColor, Cl_ByLayer() ) ; Sw_WriteColor( w, 62, xColor ) ; ENDIF
   Sw_WriteSubclass( w, "AcDbVertex" )
RETURN

/* write_polyline (generica), write_polyline2d (+ bajada a LWPOLYLINE), write_polyline3d, write_polyface_mesh, write_polygon_mesh */
STATIC PROCEDURE Swr_PolyEntity( st, e, hOwner )
   LOCAL w := st[ 1 ], c := e[ "common" ], t := e[ "_type" ], hP := c[ "handle" ], v, hV, nFl, nS, nE, lDown
   IF t == "POLYLINE2D"
      lDown := st[ 2 ] >= Dxv_FromVersionString( "AC1015" ) .AND. hb_bitAnd( e[ "flags" ], 65406 ) == 0 .AND. e[ "smooth_surface" ] == SST_NONE
      IF lDown
         FOR EACH v IN e[ "vertices" ]
            IF v[ "flags" ] != 0 ; lDown := .F. ; EXIT ; ENDIF
         NEXT
      ENDIF
      IF lDown
         Sw_WriteEntityType( w, "LWPOLYLINE" ) ; Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, "AcDbPolyline" )
         Sw_WriteI32( w, 90, Len( e[ "vertices" ] ) )
         nFl := 0
         IF hb_bitAnd( e[ "flags" ], 1 ) != 0 ; nFl := 1 ; ENDIF
         IF hb_bitAnd( e[ "flags" ], 128 ) != 0 ; nFl := hb_bitOr( nFl, 128 ) ; ENDIF
         Sw_WriteI16( w, 70, nFl ) ; Sw_WriteDouble( w, 38, e[ "elevation" ] )
         IF e[ "thickness" ] != 0.0 ; Sw_WriteDouble( w, 39, e[ "thickness" ] ) ; ENDIF
         FOR EACH v IN e[ "vertices" ]
            Sw_WriteDouble( w, 10, v[ "location" ][ 1 ] ) ; Sw_WriteDouble( w, 20, v[ "location" ][ 2 ] )
            nS := IIf( v[ "start_width" ] != 0.0, v[ "start_width" ], e[ "start_width" ] )
            nE := IIf( v[ "end_width" ] != 0.0, v[ "end_width" ], e[ "end_width" ] )
            Sw_WriteDouble( w, 40, nS ) ; Sw_WriteDouble( w, 41, nE ) ; Sw_WriteDouble( w, 42, v[ "bulge" ] )
            IF v[ "id" ] != 0 ; Sw_WriteI32( w, 91, v[ "id" ] ) ; ENDIF
         NEXT
         Swr_Normal( w, e[ "normal" ] )
         Swr_XData( w, c[ "extended_data" ] )
         RETURN
      ENDIF
   ENDIF
   Sw_WriteEntityType( w, "POLYLINE" ) ; Swr_CommonEntity( st, c, hOwner )
   DO CASE
   CASE t == "POLYLINE"
      Sw_WriteSubclass( w, "AcDb3dPolyline" ) ; Sw_WriteI16( w, 66, 1 )
      Sw_WriteDouble( w, 10, 0.0 ) ; Sw_WriteDouble( w, 20, 0.0 ) ; Sw_WriteDouble( w, 30, 0.0 )
      Sw_WriteI16( w, 70, IIf( Pfl_IsClosed( e[ "flags" ] ), 9, 8 ) )
      Swr_XData( w, c[ "extended_data" ] )
      FOR EACH v IN e[ "vertices" ]
         Swr_VertexHead( st, Doc_AllocateHandle( st[ 5 ] ), hP, c[ "layer" ], c[ "color" ] )
         Sw_WriteSubclass( w, "AcDb3dPolylineVertex" ) ; Sw_WritePoint3d( w, 10, v[ "location" ] ) ; Sw_WriteI16( w, 70, 32 )
      NEXT
   CASE t == "POLYLINE2D"
      Sw_WriteSubclass( w, "AcDb2dPolyline" ) ; Sw_WriteI16( w, 66, 1 )
      Sw_WriteDouble( w, 10, 0.0 ) ; Sw_WriteDouble( w, 20, 0.0 ) ; Sw_WriteDouble( w, 30, e[ "elevation" ] )
      Sw_WriteI16( w, 70, e[ "flags" ] )
      IF e[ "thickness" ] != 0.0 ; Sw_WriteDouble( w, 39, e[ "thickness" ] ) ; ENDIF
      IF e[ "start_width" ] != 0.0 ; Sw_WriteDouble( w, 40, e[ "start_width" ] ) ; ENDIF
      IF e[ "end_width" ] != 0.0 ; Sw_WriteDouble( w, 41, e[ "end_width" ] ) ; ENDIF
      Swr_XData( w, c[ "extended_data" ] )
      FOR EACH v IN e[ "vertices" ]
         Swr_VertexHead( st, Doc_AllocateHandle( st[ 5 ] ), hP, c[ "layer" ], c[ "color" ] )
         Sw_WriteSubclass( w, "AcDb2dVertex" ) ; Sw_WritePoint3d( w, 10, v[ "location" ] )
         IF v[ "start_width" ] != 0.0 ; Sw_WriteDouble( w, 40, v[ "start_width" ] ) ; ENDIF
         IF v[ "end_width" ] != 0.0 ; Sw_WriteDouble( w, 41, v[ "end_width" ] ) ; ENDIF
         IF v[ "bulge" ] != 0.0 ; Sw_WriteDouble( w, 42, v[ "bulge" ] ) ; ENDIF
         Sw_WriteI16( w, 70, v[ "flags" ] ) ; Sw_WriteDouble( w, 50, Swr_Deg( v[ "curve_tangent" ] ) )
      NEXT
   CASE t == "POLYLINE3D"
      Sw_WriteSubclass( w, "AcDb3dPolyline" ) ; Sw_WriteI16( w, 66, 1 )
      Sw_WriteDouble( w, 10, 0.0 ) ; Sw_WriteDouble( w, 20, 0.0 ) ; Sw_WriteDouble( w, 30, e[ "elevation" ] )
      Sw_WriteI16( w, 70, P3f_ToBits( e[ "flags" ] ) )
      IF e[ "smooth_type" ] != SST_NONE ; Sw_WriteI16( w, 75, e[ "smooth_type" ] ) ; ENDIF
      Swr_XData( w, c[ "extended_data" ] )
      FOR EACH v IN e[ "vertices" ]
         hV := IIf( Hd_IsNull( v[ "handle" ] ), Doc_AllocateHandle( st[ 5 ] ), v[ "handle" ] )
         Swr_VertexHead( st, hV, hP, v[ "layer" ], c[ "color" ] )
         Sw_WriteSubclass( w, "AcDb3dPolylineVertex" ) ; Sw_WritePoint3d( w, 10, v[ "position" ] ) ; Sw_WriteI16( w, 70, v[ "flags" ] )
      NEXT
   CASE t == "POLYFACE_MESH"
      Sw_WriteSubclass( w, "AcDbPolyFaceMesh" ) ; Sw_WriteI16( w, 66, 1 )
      Sw_WriteDouble( w, 10, 0.0 ) ; Sw_WriteDouble( w, 20, 0.0 ) ; Sw_WriteDouble( w, 30, e[ "elevation" ] )
      Sw_WriteI16( w, 70, e[ "flags" ] ) ; Sw_WriteI16( w, 71, Len( e[ "vertices" ] ) ) ; Sw_WriteI16( w, 72, Len( e[ "faces" ] ) )
      Swr_XData( w, c[ "extended_data" ] )
      FOR EACH v IN e[ "vertices" ]
         hV := IIf( Hd_IsNull( v[ "common" ][ "handle" ] ), Doc_AllocateHandle( st[ 5 ] ), v[ "common" ][ "handle" ] )
         Swr_VertexHead( st, hV, hP, v[ "common" ][ "layer" ], NIL )
         Sw_WriteSubclass( w, "AcDbPolyFaceMeshVertex" ) ; Sw_WritePoint3d( w, 10, v[ "location" ] )
         Sw_WriteI16( w, 70, hb_bitOr( hb_bitOr( v[ "flags" ], 64 ), 128 ) )
      NEXT
      FOR EACH v IN e[ "faces" ]
         hV := IIf( Hd_IsNull( v[ "common" ][ "handle" ] ), Doc_AllocateHandle( st[ 5 ] ), v[ "common" ][ "handle" ] )
         Sw_WriteEntityType( w, "VERTEX" ) ; Sw_WriteHandle( w, 5, hV ) ; Sw_WriteHandle( w, 330, hP )
         Sw_WriteSubclass( w, "AcDbEntity" ) ; Sw_WriteString( w, 8, v[ "common" ][ "layer" ] )
         IF v[ "color" ] != NIL
            nS := Cl_ToTrueColorValue( v[ "color" ] )
            IF nS != NIL
               Sw_WriteI32( w, 420, nS )
            ELSEIF Cl_IndexOf( v[ "color" ] ) != NIL
               Sw_WriteI16( w, 62, Cl_IndexOf( v[ "color" ] ) )
            ENDIF
         ENDIF
         Sw_WriteSubclass( w, "AcDbFaceRecord" )
         Sw_WriteDouble( w, 10, 0.0 ) ; Sw_WriteDouble( w, 20, 0.0 ) ; Sw_WriteDouble( w, 30, 0.0 )
         Sw_WriteI16( w, 70, hb_bitOr( v[ "flags" ], 128 ) )
         Sw_WriteI16( w, 71, v[ "index1" ] ) ; Sw_WriteI16( w, 72, v[ "index2" ] ) ; Sw_WriteI16( w, 73, v[ "index3" ] )
         IF v[ "index4" ] != 0 ; Sw_WriteI16( w, 74, v[ "index4" ] ) ; ENDIF
      NEXT
      hV := IIf( e[ "seqend_handle" ] != NIL, e[ "seqend_handle" ], Doc_AllocateHandle( st[ 5 ] ) )
      Swr_SeqEnd( st, hV, hP, c[ "layer" ] )
      RETURN
   CASE t == "POLYGON_MESH"
      Sw_WriteSubclass( w, "AcDbPolygonMesh" ) ; Sw_WriteI16( w, 66, 1 )
      Sw_WriteDouble( w, 10, 0.0 ) ; Sw_WriteDouble( w, 20, 0.0 ) ; Sw_WriteDouble( w, 30, 0.0 )
      Sw_WriteI16( w, 70, hb_bitOr( e[ "flags" ], 16 ) )
      Sw_WriteI16( w, 71, e[ "m_vertex_count" ] ) ; Sw_WriteI16( w, 72, e[ "n_vertex_count" ] )
      Sw_WriteI16( w, 73, e[ "m_smooth_density" ] ) ; Sw_WriteI16( w, 74, e[ "n_smooth_density" ] ) ; Sw_WriteI16( w, 75, e[ "smooth_type" ] )
      Swr_Normal( w, e[ "normal" ] )
      Swr_XData( w, c[ "extended_data" ] )
      FOR EACH v IN e[ "vertices" ]
         hV := IIf( Hd_IsNull( v[ "common" ][ "handle" ] ), Doc_AllocateHandle( st[ 5 ] ), v[ "common" ][ "handle" ] )
         Swr_VertexHead( st, hV, hP, v[ "common" ][ "layer" ], c[ "color" ] )
         Sw_WriteSubclass( w, "AcDbPolygonMeshVertex" ) ; Sw_WritePoint3d( w, 10, v[ "location" ] )
         IF v[ "flags" ] != 0 ; Sw_WriteI16( w, 70, v[ "flags" ] ) ; ENDIF
      NEXT
   ENDCASE
   Swr_SeqEnd( st, Doc_AllocateHandle( st[ 5 ] ), hP, c[ "layer" ] )
RETURN

STATIC PROCEDURE Swr_SplineBody( w, sp )
   LOCAL v, nI
   Sw_WriteSubclass( w, "AcDbSpline" )
      Swr_Normal( w, sp[ "normal" ] ) ; Sw_WriteI16( w, 70, Spf_Write( sp ) ) ; Sw_WriteI16( w, 71, sp[ "degree" ] )
      Sw_WriteI16( w, 72, Len( sp[ "knots" ] ) ) ; Sw_WriteI16( w, 73, Len( sp[ "control_points" ] ) ) ; Sw_WriteI16( w, 74, Len( sp[ "fit_points" ] ) )
      Sw_WriteDouble( w, 42, sp[ "knot_tolerance" ] ) ; Sw_WriteDouble( w, 43, sp[ "control_tolerance" ] ) ; Sw_WriteDouble( w, 44, sp[ "fit_tolerance" ] )
      IF ! Vc3_Eq( sp[ "begin_tangent" ], Vc3_Zero() ) ; Sw_WritePoint3d( w, 12, sp[ "begin_tangent" ] ) ; ENDIF
      IF ! Vc3_Eq( sp[ "end_tangent" ], Vc3_Zero() ) ; Sw_WritePoint3d( w, 13, sp[ "end_tangent" ] ) ; ENDIF
      FOR EACH v IN sp[ "knots" ] ; Sw_WriteDouble( w, 40, v ) ; NEXT
      FOR nI := 1 TO Len( sp[ "control_points" ] )
         Sw_WritePoint3d( w, 10, sp[ "control_points" ][ nI ] )
         IF sp[ "flags" ][ "rational" ] ; Sw_WriteDouble( w, 41, IIf( nI <= Len( sp[ "weights" ] ), sp[ "weights" ][ nI ], 1.0 ) ) ; ENDIF
      NEXT
      FOR EACH v IN sp[ "fit_points" ] ; Sw_WritePoint3d( w, 11, v ) ; NEXT
RETURN

STATIC PROCEDURE Swr_HatchEdge( w, nVer, g )
   LOCAL v, lB, k := g[ "kind" ]
   DO CASE
   CASE k == "Line"
      Sw_WriteI16( w, 72, 1 ) ; Sw_WriteDouble( w, 10, g[ "start" ][ 1 ] ) ; Sw_WriteDouble( w, 20, g[ "start" ][ 2 ] )
      Sw_WriteDouble( w, 11, g[ "end" ][ 1 ] ) ; Sw_WriteDouble( w, 21, g[ "end" ][ 2 ] )
   CASE k == "CircularArc"
      Sw_WriteI16( w, 72, 2 ) ; Sw_WriteDouble( w, 10, g[ "center" ][ 1 ] ) ; Sw_WriteDouble( w, 20, g[ "center" ][ 2 ] ) ; Sw_WriteDouble( w, 40, g[ "radius" ] )
      Sw_WriteDouble( w, 50, Swr_Deg( g[ "start_angle" ] ) ) ; Sw_WriteDouble( w, 51, Swr_Deg( g[ "end_angle" ] ) ) ; Sw_WriteI16( w, 73, IIf( g[ "counter_clockwise" ], 1, 0 ) )
   CASE k == "EllipticArc"
      Sw_WriteI16( w, 72, 3 ) ; Sw_WriteDouble( w, 10, g[ "center" ][ 1 ] ) ; Sw_WriteDouble( w, 20, g[ "center" ][ 2 ] )
      Sw_WriteDouble( w, 11, g[ "major_axis_endpoint" ][ 1 ] ) ; Sw_WriteDouble( w, 21, g[ "major_axis_endpoint" ][ 2 ] ) ; Sw_WriteDouble( w, 40, g[ "minor_axis_ratio" ] )
      Sw_WriteDouble( w, 50, g[ "start_angle" ] ) ; Sw_WriteDouble( w, 51, g[ "end_angle" ] ) ; Sw_WriteI16( w, 73, IIf( g[ "counter_clockwise" ], 1, 0 ) )
   CASE k == "Spline"
      Sw_WriteI16( w, 72, 4 ) ; Sw_WriteI32( w, 94, g[ "degree" ] ) ; Sw_WriteI16( w, 73, IIf( g[ "rational" ], 1, 0 ) ) ; Sw_WriteI16( w, 74, IIf( g[ "periodic" ], 1, 0 ) )
      Sw_WriteI32( w, 95, Len( g[ "knots" ] ) ) ; Sw_WriteI32( w, 96, Len( g[ "control_points" ] ) )
      FOR EACH v IN g[ "knots" ] ; Sw_WriteDouble( w, 40, v ) ; NEXT
      FOR EACH v IN g[ "control_points" ]
         Sw_WriteDouble( w, 10, v[ 1 ] ) ; Sw_WriteDouble( w, 20, v[ 2 ] )
         IF g[ "rational" ] ; Sw_WriteDouble( w, 42, v[ 3 ] ) ; ENDIF
      NEXT
      IF nVer >= Dxv_FromVersionString( "AC1024" )
         Sw_WriteI32( w, 97, Len( g[ "fit_points" ] ) )
         FOR EACH v IN g[ "fit_points" ] ; Sw_WriteDouble( w, 11, v[ 1 ] ) ; Sw_WriteDouble( w, 21, v[ 2 ] ) ; NEXT
         IF Len( g[ "fit_points" ] ) > 0
            Sw_WriteDouble( w, 12, g[ "start_tangent" ][ 1 ] ) ; Sw_WriteDouble( w, 22, g[ "start_tangent" ][ 2 ] )
            Sw_WriteDouble( w, 13, g[ "end_tangent" ][ 1 ] ) ; Sw_WriteDouble( w, 23, g[ "end_tangent" ][ 2 ] )
         ENDIF
      ENDIF
   CASE k == "Polyline"
      lB := Bed_HasBulge( g )
      Sw_WriteI16( w, 72, IIf( lB, 1, 0 ) ) ; Sw_WriteI16( w, 73, IIf( g[ "is_closed" ], 1, 0 ) ) ; Sw_WriteI32( w, 93, Len( g[ "vertices" ] ) )
      FOR EACH v IN g[ "vertices" ]
         Sw_WriteDouble( w, 10, v[ 1 ] ) ; Sw_WriteDouble( w, 20, v[ 2 ] )
         IF lB ; Sw_WriteDouble( w, 42, v[ 3 ] ) ; ENDIF
      NEXT
   ENDCASE
RETURN

STATIC PROCEDURE Swr_HatchPath( st, nVer, pa )
   LOCAL g, h, w := st[ 1 ], aB := {}
   Sw_WriteI32( w, 92, pa[ "flags" ] )
   IF ! Bpf_IsPolyline( pa[ "flags" ] ) ; Sw_WriteI32( w, 93, Len( pa[ "edges" ] ) ) ; ENDIF
   FOR EACH g IN pa[ "edges" ] ; Swr_HatchEdge( w, nVer, g ) ; NEXT
   /* asociados: con valid_handles solo los no nulos y presentes */
   FOR EACH h IN pa[ "boundary_handles" ]
      IF Len( st[ 8 ] ) == 0 .OR. ( ! Hd_IsNull( h ) .AND. hb_HHasKey( st[ 8 ], h ) ) ; AAdd( aB, h ) ; ENDIF
   NEXT
   Sw_WriteI32( w, 97, Len( aB ) )
   FOR EACH h IN aB ; Sw_WriteHandle( w, 330, h ) ; NEXT
RETURN

STATIC PROCEDURE Swr_HatchGradient( w, e )
   LOCAL g := e[ "gradient_color" ], en, c
   IF ! g[ "enabled" ] ; RETURN ; ENDIF
   Sw_WriteI32( w, 450, 1 ) ; Sw_WriteI32( w, 451, g[ "reserved" ] ) ; Sw_WriteDouble( w, 460, g[ "angle" ] ) ; Sw_WriteDouble( w, 461, g[ "shift" ] )
   Sw_WriteI32( w, 452, IIf( g[ "is_single_color" ], 1, 0 ) ) ; Sw_WriteDouble( w, 462, g[ "color_tint" ] ) ; Sw_WriteI32( w, 453, Len( g[ "colors" ] ) )
   FOR EACH en IN g[ "colors" ]
      c := en[ "color" ]
      Sw_WriteDouble( w, 463, en[ "value" ] ) ; Sw_WriteColor( w, 63, c )
      IF c[ 1 ] == CK_RGB ; Sw_WriteI32( w, 421, hb_bitOr( hb_bitOr( hb_bitShift( c[ 2 ], 16 ), hb_bitShift( c[ 3 ], 8 ) ), c[ 4 ] ) ) ; ENDIF
   NEXT
   Sw_WriteString( w, 470, g[ "name" ] )
RETURN

STATIC PROCEDURE Swr_HatchPattern( w, e )
   LOCAL l, d
   Sw_WriteDouble( w, 52, Swr_Deg( e[ "pattern_angle" ] ) ) ; Sw_WriteDouble( w, 41, e[ "pattern_scale" ] ) ; Sw_WriteI16( w, 77, IIf( e[ "is_double" ], 1, 0 ) )
   Sw_WriteI16( w, 78, Len( e[ "pattern" ][ "lines" ] ) )
   FOR EACH l IN e[ "pattern" ][ "lines" ]
      Sw_WriteDouble( w, 53, Swr_Deg( l[ "angle" ] ) ) ; Sw_WriteDouble( w, 43, l[ "base_point" ][ 1 ] ) ; Sw_WriteDouble( w, 44, l[ "base_point" ][ 2 ] )
      Sw_WriteDouble( w, 45, l[ "offset" ][ 1 ] ) ; Sw_WriteDouble( w, 46, l[ "offset" ][ 2 ] ) ; Sw_WriteI16( w, 79, Len( l[ "dash_lengths" ] ) )
      FOR EACH d IN l[ "dash_lengths" ] ; Sw_WriteDouble( w, 49, d ) ; NEXT
   NEXT
RETURN

STATIC PROCEDURE Swr_Hatch( st, e, hOwner )
   LOCAL w := st[ 1 ], c := e[ "common" ], pa, lAs := .F., lDer := .F., sd, h
   FOR EACH pa IN e[ "paths" ]
      IF e[ "is_mpolygon" ]
         FOR EACH h IN pa[ "boundary_handles" ]
            IF ! Hd_IsNull( h ) ; lAs := .T. ; ENDIF
         NEXT
      ELSEIF Len( st[ 8 ] ) == 0
         IF Len( pa[ "boundary_handles" ] ) > 0 ; lAs := .T. ; ENDIF
      ELSE
         FOR EACH h IN pa[ "boundary_handles" ]
            IF ! Hd_IsNull( h ) .AND. hb_HHasKey( st[ 8 ], h ) ; lAs := .T. ; ENDIF
         NEXT
      ENDIF
      IF Bpf_IsDerived( pa[ "flags" ] ) ; lDer := .T. ; ENDIF
   NEXT
   lAs := lAs .AND. e[ "is_associative" ]
   IF e[ "is_mpolygon" ]
      Sw_WriteEntityType( w, "MPOLYGON" ) ; Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, "AcDbMPolygon" ) ; Sw_WriteI16( w, 75, e[ "style" ] )
   ELSE
      Sw_WriteEntityType( w, "HATCH" ) ; Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, "AcDbHatch" )
   ENDIF
   Sw_WriteDouble( w, 10, 0.0 ) ; Sw_WriteDouble( w, 20, 0.0 ) ; Sw_WriteDouble( w, 30, e[ "elevation" ] )
   Sw_WriteDouble( w, 210, e[ "normal" ][ 1 ] ) ; Sw_WriteDouble( w, 220, e[ "normal" ][ 2 ] ) ; Sw_WriteDouble( w, 230, e[ "normal" ][ 3 ] )
   Sw_WriteString( w, 2, e[ "pattern" ][ "name" ] ) ; Sw_WriteI16( w, 70, IIf( e[ "is_solid" ], 1, 0 ) ) ; Sw_WriteI16( w, 71, IIf( lAs, 1, 0 ) )
   Sw_WriteI32( w, 91, Len( e[ "paths" ] ) )
   FOR EACH pa IN e[ "paths" ] ; Swr_HatchPath( st, st[ 2 ], pa ) ; NEXT
   Sw_WriteI16( w, 75, e[ "style" ] ) ; Sw_WriteI16( w, 76, e[ "pattern_type" ] )
   IF ! e[ "is_solid" ] ; Swr_HatchPattern( w, e ) ; ENDIF
   IF e[ "is_mpolygon" ]
      Sw_WriteColor( w, 62, e[ "mpolygon_hatch_color" ] ) ; Sw_WriteDouble( w, 11, e[ "mpolygon_x_direction" ][ 1 ] ) ; Sw_WriteDouble( w, 21, e[ "mpolygon_x_direction" ][ 2 ] )
      Sw_WriteI32( w, 99, 0 )
   ELSE
      IF lDer ; Sw_WriteDouble( w, 47, e[ "pixel_size" ] ) ; ENDIF
      Sw_WriteI32( w, 98, Len( e[ "seed_points" ] ) )
      FOR EACH sd IN e[ "seed_points" ] ; Sw_WriteDouble( w, 10, sd[ 1 ] ) ; Sw_WriteDouble( w, 20, sd[ 2 ] ) ; NEXT
   ENDIF
   Swr_HatchGradient( w, e )
RETURN

/* write_color_i32 */
STATIC PROCEDURE Swr_McColor( w, nCode, c )
   LOCAL u
   DO CASE
   CASE c[ 1 ] == CK_BYLAYER ; u := 3221225472
   CASE c[ 1 ] == CK_BYBLOCK ; u := 3238002688
   CASE c[ 1 ] == CK_RGB ; u := 3254779904 + c[ 2 ] * 65536 + c[ 3 ] * 256 + c[ 4 ]
   CASE c[ 1 ] == CK_INDEX ; u := 3271557120 + c[ 2 ]
   OTHERWISE ; u := 3355443200
   ENDCASE
   Sw_WriteI32( w, nCode, IIf( u >= 2147483648, u - 4294967296, u ) )
RETURN

STATIC FUNCTION Swr_McH( h ) ; RETURN IIf( h == NIL, 0, h )

/* write_mleader_line_breaks */
STATIC PROCEDURE Swr_MlBreaks( w, l )
   LOCAL b, bi
   IF Len( l[ "break_infos" ] ) == 0
      IF Len( l[ "break_points" ] ) > 0
         Sw_WriteI32( w, 90, l[ "segment_index" ] )
         FOR EACH b IN l[ "break_points" ] ; Sw_WritePoint3d( w, 11, b[ "start_point" ] ) ; Sw_WritePoint3d( w, 12, b[ "end_point" ] ) ; NEXT
      ENDIF
   ELSE
      FOR EACH bi IN l[ "break_infos" ]
         Sw_WriteI32( w, 90, bi[ "segment_index" ] )
         FOR EACH b IN bi[ "break_points" ] ; Sw_WritePoint3d( w, 11, b[ "start_point" ] ) ; Sw_WritePoint3d( w, 12, b[ "end_point" ] ) ; NEXT
      NEXT
   ENDIF
RETURN

/* write_multileader. bylayer/byblock linetype handles: se buscan en d["line_types"] (Rust los guarda al preparar) */
STATIC PROCEDURE Swr_Multileader( st, e, hOwner )
   LOCAL w := st[ 1 ], nVer := st[ 2 ], c := e[ "context" ], r, l, b, a, h, hBl := 0, hBy := 0, lt, nV24 := Dxv_FromVersionString( "AC1024" )
   lt := Tb_Get( st[ 5 ][ "line_types" ], "ByLayer" ) ; IF lt != NIL ; hBy := lt[ "handle" ] ; ENDIF
   lt := Tb_Get( st[ 5 ][ "line_types" ], "ByBlock" ) ; IF lt != NIL ; hBl := lt[ "handle" ] ; ENDIF
   Sw_WriteEntityType( w, "MULTILEADER" ) ; Swr_CommonEntity( st, e[ "common" ], hOwner ) ; Sw_WriteSubclass( w, "AcDbMLeader" )
   IF nVer >= nV24 ; Sw_WriteI16( w, 270, e[ "dwg_version" ] ) ; ENDIF
   Sw_WriteString( w, 300, "CONTEXT_DATA{" )
   Sw_WriteDouble( w, 40, c[ "scale_factor" ] ) ; Sw_WritePoint3d( w, 10, c[ "content_base_point" ] ) ; Sw_WriteDouble( w, 41, c[ "text_height" ] )
   Sw_WriteDouble( w, 140, c[ "arrowhead_size" ] ) ; Sw_WriteDouble( w, 145, c[ "landing_gap" ] )
   Sw_WriteI16( w, 174, c[ "text_left_attachment" ] ) ; Sw_WriteI16( w, 175, c[ "text_right_attachment" ] )
   Sw_WriteI16( w, 176, c[ "text_alignment" ] ) ; Sw_WriteI16( w, 177, c[ "block_connection_type" ] )
   Sw_WriteBool( w, 290, c[ "has_text_contents" ] )
   IF c[ "has_text_contents" ]
      Sw_WriteString( w, 304, c[ "text_string" ] ) ; Sw_WritePoint3d( w, 11, c[ "text_normal" ] )
      IF c[ "text_style_handle" ] != NIL ; Sw_WriteHandle( w, 340, c[ "text_style_handle" ] ) ; ENDIF
      Sw_WritePoint3d( w, 12, c[ "text_location" ] ) ; Sw_WritePoint3d( w, 13, c[ "text_direction" ] )
      Sw_WriteDouble( w, 42, c[ "text_rotation" ] ) ; Sw_WriteDouble( w, 43, c[ "text_width" ] ) ; Sw_WriteDouble( w, 44, c[ "text_boundary_height" ] )
      Sw_WriteDouble( w, 45, c[ "line_spacing_factor" ] ) ; Sw_WriteI16( w, 170, c[ "line_spacing_style" ] ) ; Swr_McColor( w, 90, c[ "text_color" ] )
      Sw_WriteI16( w, 171, c[ "text_attachment_point" ] ) ; Sw_WriteI16( w, 172, c[ "text_flow_direction" ] ) ; Swr_McColor( w, 91, c[ "background_fill_color" ] )
      Sw_WriteDouble( w, 141, c[ "background_scale_factor" ] ) ; Sw_WriteI32( w, 92, c[ "background_transparency" ] )
      Sw_WriteBool( w, 291, c[ "background_fill_enabled" ] ) ; Sw_WriteBool( w, 292, c[ "background_mask_fill_on" ] )
      Sw_WriteI16( w, 173, c[ "column_type" ] ) ; Sw_WriteBool( w, 293, c[ "text_height_automatic" ] )
      Sw_WriteDouble( w, 142, c[ "column_width" ] ) ; Sw_WriteDouble( w, 143, c[ "column_gutter" ] ) ; Sw_WriteBool( w, 294, c[ "column_flow_reversed" ] )
      FOR EACH a IN c[ "column_sizes" ] ; Sw_WriteDouble( w, 144, a ) ; NEXT
      IF nVer >= Dxv_FromVersionString( "AC1027" ) ; Sw_WriteBool( w, 295, c[ "word_break" ] ) ; ENDIF
   ENDIF
   Sw_WriteBool( w, 296, c[ "has_block_contents" ] )
   IF c[ "has_block_contents" ]
      IF c[ "block_content_handle" ] != NIL ; Sw_WriteHandle( w, 341, c[ "block_content_handle" ] ) ; ENDIF
      Sw_WritePoint3d( w, 14, c[ "block_content_normal" ] ) ; Sw_WritePoint3d( w, 15, c[ "block_content_location" ] ) ; Sw_WritePoint3d( w, 16, c[ "block_content_scale" ] )
      Sw_WriteDouble( w, 46, c[ "block_rotation" ] ) ; Swr_McColor( w, 93, c[ "block_content_color" ] )
      FOR EACH a IN c[ "transform_matrix" ] ; Sw_WriteDouble( w, 47, a ) ; NEXT
   ENDIF
   Sw_WritePoint3d( w, 110, c[ "base_point" ] ) ; Sw_WritePoint3d( w, 111, c[ "base_direction" ] ) ; Sw_WritePoint3d( w, 112, c[ "base_vertical" ] )
   Sw_WriteBool( w, 297, c[ "normal_reversed" ] )
   FOR EACH r IN c[ "leader_roots" ]
      Sw_WriteString( w, 302, "LEADER{" ) ; Sw_WriteBool( w, 290, r[ "content_valid" ] ) ; Sw_WriteBool( w, 291, r[ "unknown" ] )
      Sw_WritePoint3d( w, 10, r[ "connection_point" ] ) ; Sw_WritePoint3d( w, 11, r[ "direction" ] ) ; Sw_WriteI32( w, 90, r[ "leader_index" ] )
      FOR EACH b IN r[ "break_points" ] ; Sw_WritePoint3d( w, 12, b[ "start_point" ] ) ; Sw_WritePoint3d( w, 13, b[ "end_point" ] ) ; NEXT
      Sw_WriteDouble( w, 40, r[ "landing_distance" ] )
      FOR EACH l IN r[ "lines" ]
         Sw_WriteString( w, 304, "LEADER_LINE{" )
         FOR EACH a IN l[ "points" ] ; Sw_WritePoint3d( w, 10, a ) ; NEXT
         Swr_MlBreaks( w, l )
         Sw_WriteI32( w, 91, l[ "index" ] ) ; Sw_WriteI16( w, 170, l[ "path_type" ] ) ; Swr_McColor( w, 92, l[ "line_color" ] )
         Sw_WriteHandle( w, 340, Swr_McH( l[ "line_type_handle" ] ) ) ; Sw_WriteI16( w, 171, Lw_GetValue( l[ "line_weight" ] ) )
         Sw_WriteDouble( w, 40, l[ "arrowhead_size" ] ) ; Sw_WriteHandle( w, 341, Swr_McH( l[ "arrowhead_handle" ] ) )
         Sw_WriteI32( w, 93, IIf( l[ "override_flags" ] >= 2147483648, l[ "override_flags" ] - 4294967296, l[ "override_flags" ] ) )
         Sw_WriteString( w, 305, "}" )
      NEXT
      IF nVer >= nV24 ; Sw_WriteI16( w, 271, r[ "text_attachment_direction" ] ) ; ENDIF
      Sw_WriteString( w, 303, "}" )
   NEXT
   IF nVer >= nV24 ; Sw_WriteI16( w, 272, c[ "text_bottom_attachment" ] ) ; Sw_WriteI16( w, 273, c[ "text_top_attachment" ] ) ; ENDIF
   Sw_WriteString( w, 301, "}" )
   IF e[ "style_handle" ] != NIL ; Sw_WriteHandle( w, 340, e[ "style_handle" ] ) ; ENDIF
   Sw_WriteI32( w, 90, IIf( e[ "property_override_flags" ] >= 2147483648, e[ "property_override_flags" ] - 4294967296, e[ "property_override_flags" ] ) )
   Sw_WriteI16( w, 170, e[ "path_type" ] ) ; Swr_McColor( w, 91, e[ "line_color" ] )
   h := e[ "line_type_handle" ]
   IF h == NIL .OR. h == 0 .OR. h == hBl ; h := hBy ; ENDIF
   IF h != 0 ; Sw_WriteHandle( w, 341, h ) ; ENDIF
   Sw_WriteI16( w, 171, Lw_GetValue( e[ "line_weight" ] ) ) ; Sw_WriteBool( w, 290, e[ "enable_landing" ] ) ; Sw_WriteBool( w, 291, e[ "enable_dogleg" ] )
   Sw_WriteDouble( w, 41, e[ "dogleg_length" ] )
   IF e[ "arrowhead_handle" ] != NIL .AND. e[ "arrowhead_handle" ] != 0 ; Sw_WriteHandle( w, 342, e[ "arrowhead_handle" ] ) ; ENDIF
   Sw_WriteDouble( w, 42, e[ "arrowhead_size" ] ) ; Sw_WriteI16( w, 172, e[ "content_type" ] )
   IF e[ "text_style_handle" ] != NIL ; Sw_WriteHandle( w, 343, e[ "text_style_handle" ] ) ; ENDIF
   Sw_WriteI16( w, 173, e[ "text_left_attachment" ] ) ; Sw_WriteI32( w, 95, e[ "text_right_attachment" ] ) ; Sw_WriteI16( w, 174, e[ "text_angle_type" ] )
   Sw_WriteI16( w, 175, e[ "text_alignment" ] ) ; Swr_McColor( w, 92, e[ "text_color" ] ) ; Sw_WriteBool( w, 292, e[ "text_frame" ] )
   IF e[ "block_content_handle" ] != NIL ; Sw_WriteHandle( w, 344, e[ "block_content_handle" ] ) ; ENDIF
   Swr_McColor( w, 93, e[ "block_content_color" ] ) ; Sw_WritePoint3d( w, 10, e[ "block_scale" ] ) ; Sw_WriteDouble( w, 43, e[ "block_rotation" ] )
   Sw_WriteDouble( w, 45, e[ "scale_factor" ] ) ; Sw_WriteI16( w, 176, e[ "block_connection_type" ] ) ; Sw_WriteBool( w, 293, e[ "enable_annotation_scale" ] )
   FOR EACH a IN e[ "arrowhead_overrides" ]
      Sw_WriteI32( w, 94, a[ "index" ] ) ; Sw_WriteHandle( w, 345, Swr_McH( a[ "arrowhead_handle" ] ) )
   NEXT
   FOR EACH a IN e[ "block_attributes" ]
      Sw_WriteHandle( w, 330, Swr_McH( a[ "attribute_definition_handle" ] ) ) ; Sw_WriteI16( w, 177, a[ "index" ] )
      Sw_WriteDouble( w, 44, a[ "width" ] ) ; Sw_WriteString( w, 302, a[ "text" ] )
   NEXT
   Sw_WriteBool( w, 294, e[ "text_direction_negative" ] ) ; Sw_WriteI16( w, 178, e[ "text_align_in_ipe" ] ) ; Sw_WriteI16( w, 179, e[ "text_attachment_point" ] )
   IF nVer >= nV24
      Sw_WriteI16( w, 271, e[ "text_attachment_direction" ] ) ; Sw_WriteI16( w, 272, e[ "text_bottom_attachment" ] ) ; Sw_WriteI16( w, 273, e[ "text_top_attachment" ] )
   ENDIF
   IF nVer >= Dxv_FromVersionString( "AC1027" ) ; Sw_WriteBool( w, 295, e[ "extend_leader_to_text" ] ) ; ENDIF
RETURN

STATIC PROCEDURE Swr_WriteEntity( st, e, hOwner )
   LOCAL w := st[ 1 ], c := e[ "common" ], t := e[ "_type" ], v, hSeq, att, nI, g, q
   DO CASE
   CASE t == "POINT"
      Sw_WriteEntityType( w, "POINT" ) ; Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, "AcDbPoint" )
      Sw_WritePoint3d( w, 10, e[ "location" ] )
      IF e[ "thickness" ] != 0.0 ; Sw_WriteDouble( w, 39, e[ "thickness" ] ) ; ENDIF
      Swr_Normal( w, e[ "normal" ] )
      IF e[ "x_axis_angle" ] != 0.0 ; Sw_WriteDouble( w, 50, e[ "x_axis_angle" ] ) ; ENDIF
   CASE t == "LINE"
      Sw_WriteEntityType( w, "LINE" ) ; Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, "AcDbLine" )
      Sw_WritePoint3d( w, 10, e[ "start" ] ) ; Sw_WritePoint3d( w, 11, e[ "end" ] )
      IF e[ "thickness" ] != 0.0 ; Sw_WriteDouble( w, 39, e[ "thickness" ] ) ; ENDIF
      Swr_Normal( w, e[ "normal" ] )
   CASE t == "CIRCLE" .OR. t == "ARC"
      Sw_WriteEntityType( w, t ) ; Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, "AcDbCircle" )
      Sw_WritePoint3d( w, 10, e[ "center" ] ) ; Sw_WriteDouble( w, 40, e[ "radius" ] )
      IF e[ "thickness" ] != 0.0 ; Sw_WriteDouble( w, 39, e[ "thickness" ] ) ; ENDIF
      Swr_Normal( w, e[ "normal" ] )
      IF t == "ARC"
         Sw_WriteSubclass( w, "AcDbArc" )
         Sw_WriteDouble( w, 50, Swr_Deg( e[ "start_angle" ] ) ) ; Sw_WriteDouble( w, 51, Swr_Deg( e[ "end_angle" ] ) )
      ENDIF
   CASE t == "LWPOLYLINE"
      Sw_WriteEntityType( w, "LWPOLYLINE" ) ; Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, "AcDbPolyline" )
      Sw_WriteI32( w, 90, Len( e[ "vertices" ] ) )
      Sw_WriteI16( w, 70, hb_bitOr( IIf( e[ "is_closed" ], 1, 0 ), IIf( e[ "plinegen" ], 128, 0 ) ) )
      Sw_WriteDouble( w, 38, e[ "elevation" ] )
      IF e[ "thickness" ] != 0.0 ; Sw_WriteDouble( w, 39, e[ "thickness" ] ) ; ENDIF
      IF e[ "constant_width" ] != 0.0 ; Sw_WriteDouble( w, 43, e[ "constant_width" ] ) ; ENDIF
      FOR EACH v IN e[ "vertices" ]
         Sw_WriteDouble( w, 10, v[ "location" ][ 1 ] ) ; Sw_WriteDouble( w, 20, v[ "location" ][ 2 ] )
         Sw_WriteDouble( w, 40, v[ "start_width" ] ) ; Sw_WriteDouble( w, 41, v[ "end_width" ] ) ; Sw_WriteDouble( w, 42, v[ "bulge" ] )
         IF v[ "vertex_id" ] != 0 ; Sw_WriteI32( w, 91, v[ "vertex_id" ] ) ; ENDIF
      NEXT
      Swr_Normal( w, e[ "normal" ] )
   CASE t == "TEXT"
      Sw_WriteEntityType( w, "TEXT" ) ; Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, "AcDbText" )
      IF e[ "thickness" ] != 0.0 ; Sw_WriteDouble( w, 39, e[ "thickness" ] ) ; ENDIF
      Sw_WritePoint3d( w, 10, e[ "insertion_point" ] ) ; Sw_WriteDouble( w, 40, e[ "height" ] ) ; Sw_WriteString( w, 1, e[ "value" ] )
      IF e[ "rotation" ] != 0.0 ; Sw_WriteDouble( w, 50, Swr_Deg( e[ "rotation" ] ) ) ; ENDIF
      IF e[ "width_factor" ] != 1.0 ; Sw_WriteDouble( w, 41, e[ "width_factor" ] ) ; ENDIF
      IF e[ "oblique_angle" ] != 0.0 ; Sw_WriteDouble( w, 51, e[ "oblique_angle" ] ) ; ENDIF
      Sw_WriteString( w, 7, e[ "style" ] )
      IF e[ "generation_flags" ] != 0 ; Sw_WriteI16( w, 71, e[ "generation_flags" ] ) ; ENDIF
      Sw_WriteI16( w, 72, e[ "horizontal_alignment" ] )
      IF e[ "alignment_point" ] != NIL ; Sw_WritePoint3d( w, 11, e[ "alignment_point" ] ) ; ENDIF
      Swr_Normal( w, e[ "normal" ] )
      Sw_WriteSubclass( w, "AcDbText" ) ; Sw_WriteI16( w, 73, e[ "vertical_alignment" ] )
   CASE t == "MTEXT"
      Swr_MTextBody( st, e, hOwner )
   CASE t == "HATCH" .OR. t == "MPOLYGON"
      Swr_Hatch( st, e, hOwner )
   CASE t == "SPLINE"
      Sw_WriteEntityType( w, "SPLINE" ) ; Swr_CommonEntity( st, c, hOwner ) ; Swr_SplineBody( w, e )
   CASE t == "HELIX"
      Sw_WriteEntityType( w, "HELIX" ) ; Swr_CommonEntity( st, c, hOwner ) ; Swr_SplineBody( w, e[ "spline" ] )
      Sw_WriteSubclass( w, "AcDbHelix" ) ; Sw_WriteI32( w, 90, e[ "major_version" ] ) ; Sw_WriteI32( w, 91, e[ "maintenance_version" ] )
      Sw_WritePoint3d( w, 10, e[ "axis_base_point" ] ) ; Sw_WritePoint3d( w, 11, e[ "start_point" ] ) ; Sw_WritePoint3d( w, 12, e[ "axis_vector" ] )
      Sw_WriteDouble( w, 40, e[ "radius" ] ) ; Sw_WriteDouble( w, 41, e[ "turns" ] ) ; Sw_WriteDouble( w, 42, e[ "turn_height" ] )
      Sw_WriteBool( w, 290, e[ "handedness" ] ) ; Sw_WriteByte( w, 280, Hxc_ToCode( e[ "constraint" ] ) )
   CASE t == "POLYLINE" .OR. t == "POLYLINE2D" .OR. t == "POLYLINE3D" .OR. t == "POLYFACE_MESH" .OR. t == "POLYGON_MESH"
      Swr_PolyEntity( st, e, hOwner )
      RETURN
   CASE t == "ATTDEF"
      Swr_AttdefAttrib( st, e, hOwner, .T. )
   CASE t == "ELLIPSE"
      Sw_WriteEntityType( w, "ELLIPSE" ) ; Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, "AcDbEllipse" )
      Sw_WritePoint3d( w, 10, e[ "center" ] ) ; Sw_WritePoint3d( w, 11, e[ "major_axis" ] ) ; Sw_WriteDouble( w, 40, e[ "minor_axis_ratio" ] )
      Swr_Normal( w, e[ "normal" ] )
      Sw_WriteDouble( w, 41, e[ "start_parameter" ] ) ; Sw_WriteDouble( w, 42, e[ "end_parameter" ] )
   CASE t == "SOLID"
      Sw_WriteEntityType( w, IIf( e[ "is_trace" ], "TRACE", "SOLID" ) ) ; Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, "AcDbTrace" )
      Sw_WritePoint3d( w, 10, e[ "first_corner" ] ) ; Sw_WritePoint3d( w, 11, e[ "second_corner" ] )
      Sw_WritePoint3d( w, 12, e[ "third_corner" ] ) ; Sw_WritePoint3d( w, 13, e[ "fourth_corner" ] )
      IF e[ "thickness" ] != 0.0 ; Sw_WriteDouble( w, 39, e[ "thickness" ] ) ; ENDIF
      Swr_Normal( w, e[ "normal" ] )
   CASE t == "3DFACE"
      Sw_WriteEntityType( w, "3DFACE" ) ; Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, "AcDbFace" )
      Sw_WritePoint3d( w, 10, e[ "first_corner" ] ) ; Sw_WritePoint3d( w, 11, e[ "second_corner" ] )
      Sw_WritePoint3d( w, 12, e[ "third_corner" ] ) ; Sw_WritePoint3d( w, 13, e[ "fourth_corner" ] )
      IF e[ "invisible_edges" ] != 0 ; Sw_WriteI16( w, 70, e[ "invisible_edges" ] ) ; ENDIF
   CASE t == "DIMENSION_ALIGNED" .OR. t == "DIMENSION_LINEAR" .OR. t == "DIMENSION_RADIUS" .OR. t == "DIMENSION_DIAMETER" .OR. t == "DIMENSION_ANGULAR_2LINE" .OR. t == "DIMENSION_ANGULAR_3POINT" .OR. t == "DIMENSION_ORDINATE" .OR. t == "ARC_DIMENSION" .OR. t == "LARGE_RADIAL_DIMENSION"
      Swr_Dimension( st, e, hOwner )
   CASE t == "TOLERANCE"
      Sw_WriteEntityType( w, "TOLERANCE" ) ; Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, "AcDbFcf" ) ; Sw_WriteString( w, 3, e[ "dimension_style_name" ] )
      Sw_WriteDouble( w, 10, e[ "insertion_point" ][ 1 ] ) ; Sw_WriteDouble( w, 20, e[ "insertion_point" ][ 2 ] ) ; Sw_WriteDouble( w, 30, e[ "insertion_point" ][ 3 ] )
      Sw_WriteDouble( w, 210, e[ "normal" ][ 1 ] ) ; Sw_WriteDouble( w, 220, e[ "normal" ][ 2 ] ) ; Sw_WriteDouble( w, 230, e[ "normal" ][ 3 ] )
      Sw_WriteDouble( w, 11, e[ "direction" ][ 1 ] ) ; Sw_WriteDouble( w, 21, e[ "direction" ][ 2 ] ) ; Sw_WriteDouble( w, 31, e[ "direction" ][ 3 ] ) ; Sw_WriteString( w, 1, e[ "text" ] )
   CASE t == "WIPEOUT"
      Sw_WriteEntityType( w, "WIPEOUT" ) ; Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, "AcDbWipeout" ) ; Sw_WriteI32( w, 90, e[ "class_version" ] )
      Sw_WriteDouble( w, 10, e[ "insertion_point" ][ 1 ] ) ; Sw_WriteDouble( w, 20, e[ "insertion_point" ][ 2 ] ) ; Sw_WriteDouble( w, 30, e[ "insertion_point" ][ 3 ] )
      Sw_WriteDouble( w, 11, e[ "u_vector" ][ 1 ] ) ; Sw_WriteDouble( w, 21, e[ "u_vector" ][ 2 ] ) ; Sw_WriteDouble( w, 31, e[ "u_vector" ][ 3 ] )
      Sw_WriteDouble( w, 12, e[ "v_vector" ][ 1 ] ) ; Sw_WriteDouble( w, 22, e[ "v_vector" ][ 2 ] ) ; Sw_WriteDouble( w, 32, e[ "v_vector" ][ 3 ] )
      Sw_WriteDouble( w, 13, e[ "size" ][ 1 ] ) ; Sw_WriteDouble( w, 23, e[ "size" ][ 2 ] )
      IF e[ "definition_handle" ] != NIL ; Sw_WriteHandle( w, 340, e[ "definition_handle" ] ) ; ENDIF
      Sw_WriteI16( w, 70, e[ "flags" ] ) ; Sw_WriteByte( w, 280, IIf( e[ "clipping_enabled" ], 1, 0 ) ) ; Sw_WriteByte( w, 281, e[ "brightness" ] )
      Sw_WriteByte( w, 282, e[ "contrast" ] ) ; Sw_WriteByte( w, 283, e[ "fade" ] )
      IF e[ "definition_reactor_handle" ] != NIL ; Sw_WriteHandle( w, 360, e[ "definition_reactor_handle" ] ) ; ENDIF
      IF st[ 2 ] >= Dxv_FromVersionString( "AC1024" ) ; Sw_WriteBool( w, 290, e[ "clip_mode" ] == WCM_INSIDE ) ; ENDIF
      Sw_WriteI16( w, 71, e[ "clip_type" ] ) ; Sw_WriteI32( w, 91, Len( e[ "clip_boundary_vertices" ] ) )
      FOR EACH v IN e[ "clip_boundary_vertices" ] ; Sw_WriteDouble( w, 14, v[ 1 ] ) ; Sw_WriteDouble( w, 24, v[ 2 ] ) ; NEXT
   CASE t == "MLINE"
      Sw_WriteEntityType( w, "MLINE" ) ; Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, "AcDbMline" ) ; Sw_WriteString( w, 2, e[ "style_name" ] )
      Sw_WriteHandle( w, 340, IIf( e[ "style_handle" ] == NIL, Hd_Null(), e[ "style_handle" ] ) ) ; Sw_WriteDouble( w, 40, e[ "scale_factor" ] ) ; Sw_WriteI16( w, 70, e[ "justification" ] )
      Sw_WriteI16( w, 71, Eml_SerializedFlags( e ) ) ; Sw_WriteI16( w, 72, Len( e[ "vertices" ] ) ) ; Sw_WriteI16( w, 73, e[ "style_element_count" ] )
      Sw_WritePoint3d( w, 10, e[ "start_point" ] ) ; Sw_WritePoint3d( w, 210, e[ "normal" ] )
      FOR EACH v IN e[ "vertices" ]
         Sw_WritePoint3d( w, 11, v[ "position" ] ) ; Sw_WritePoint3d( w, 12, v[ "direction" ] ) ; Sw_WritePoint3d( w, 13, v[ "miter" ] )
         FOR EACH g IN v[ "segments" ]
            Sw_WriteI16( w, 74, Len( g[ "parameters" ] ) )
            FOR EACH q IN g[ "parameters" ] ; Sw_WriteDouble( w, 41, q ) ; NEXT
            Sw_WriteI16( w, 75, Len( g[ "area_fill_parameters" ] ) )
            FOR EACH q IN g[ "area_fill_parameters" ] ; Sw_WriteDouble( w, 42, q ) ; NEXT
         NEXT
      NEXT
   CASE t == "LEADER"
      Sw_WriteEntityType( w, "LEADER" ) ; Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, "AcDbLeader" ) ; Sw_WriteString( w, 3, e[ "dimension_style" ] )
      Sw_WriteI16( w, 71, IIf( e[ "arrow_enabled" ], 1, 0 ) ) ; Sw_WriteI16( w, 72, e[ "path_type" ] ) ; Sw_WriteI16( w, 73, e[ "creation_type" ] )
      Sw_WriteI16( w, 74, e[ "hookline_direction" ] ) ; Sw_WriteI16( w, 75, IIf( e[ "hookline_enabled" ], 1, 0 ) )
      Sw_WriteDouble( w, 40, e[ "text_height" ] ) ; Sw_WriteDouble( w, 41, e[ "text_width" ] ) ; Sw_WriteI16( w, 76, Len( e[ "vertices" ] ) )
      FOR EACH v IN e[ "vertices" ] ; Sw_WritePoint3d( w, 10, v ) ; NEXT
      Sw_WritePoint3d( w, 210, e[ "normal" ] ) ; Sw_WritePoint3d( w, 211, e[ "horizontal_direction" ] )
      Sw_WritePoint3d( w, 212, e[ "block_offset" ] ) ; Sw_WritePoint3d( w, 213, e[ "annotation_offset" ] )
      IF ! Hd_IsNull( e[ "annotation_handle" ] ) ; Sw_WriteHandle( w, 340, e[ "annotation_handle" ] ) ; ENDIF
      IF ! ( e[ "override_color" ][ 1 ] == CK_RGB ) ; Sw_WriteI16( w, 77, Cl_IndexOf( e[ "override_color" ] ) ) ; ENDIF
   CASE t == "VIEWPORT"
      /* active_viewport_ids (estado del escritor) pendiente: id 0 si el viewport no lo trae */
      Sw_WriteEntityType( w, "VIEWPORT" ) ; Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, "AcDbViewport" ) ; Sw_WritePoint3d( w, 10, e[ "center" ] )
      Sw_WriteDouble( w, 40, e[ "width" ] ) ; Sw_WriteDouble( w, 41, e[ "height" ] )
      nI := e[ "id" ]
      IF nI == 0 ; nI := hb_HGetDef( st[ 6 ], c[ "handle" ], 0 ) ; ENDIF
      DO CASE
      CASE ! Evp_IsOn( e ) ; Sw_WriteI16( w, 68, 0 )
      CASE e[ "off_screen" ] ; Sw_WriteI16( w, 68, -1 )
      OTHERWISE ; Sw_WriteI16( w, 68, nI )
      ENDCASE
      Sw_WriteI16( w, 69, nI ) ; Sw_WriteI32( w, 90, Vsf_ToBits( e[ "status" ] ) )
      Sw_WriteDouble( w, 12, e[ "view_center" ][ 1 ] ) ; Sw_WriteDouble( w, 22, e[ "view_center" ][ 2 ] )
      Sw_WriteDouble( w, 13, e[ "snap_base" ][ 1 ] ) ; Sw_WriteDouble( w, 23, e[ "snap_base" ][ 2 ] )
      Sw_WriteDouble( w, 14, e[ "snap_spacing" ][ 1 ] ) ; Sw_WriteDouble( w, 24, e[ "snap_spacing" ][ 2 ] )
      Sw_WriteDouble( w, 15, e[ "grid_spacing" ][ 1 ] ) ; Sw_WriteDouble( w, 25, e[ "grid_spacing" ][ 2 ] )
      Sw_WriteDouble( w, 16, e[ "view_direction" ][ 1 ] ) ; Sw_WriteDouble( w, 26, e[ "view_direction" ][ 2 ] ) ; Sw_WriteDouble( w, 36, e[ "view_direction" ][ 3 ] )
      Sw_WriteDouble( w, 17, e[ "view_target" ][ 1 ] ) ; Sw_WriteDouble( w, 27, e[ "view_target" ][ 2 ] ) ; Sw_WriteDouble( w, 37, e[ "view_target" ][ 3 ] )
      Sw_WriteDouble( w, 42, e[ "lens_length" ] ) ; Sw_WriteDouble( w, 43, e[ "front_clip_z" ] ) ; Sw_WriteDouble( w, 44, e[ "back_clip_z" ] ) ; Sw_WriteDouble( w, 45, e[ "view_height" ] )
      Sw_WriteDouble( w, 50, Swr_Deg( e[ "snap_angle" ] ) ) ; Sw_WriteDouble( w, 51, Swr_Deg( e[ "twist_angle" ] ) ) ; Sw_WriteI16( w, 72, e[ "circle_sides" ] )
      FOR EACH v IN e[ "frozen_layers" ]
         IF ! Hd_IsNull( v ) ; Sw_WriteHandle( w, 331, v ) ; ENDIF
      NEXT
      IF ! Hd_IsNull( e[ "clip_boundary_handle" ] ) ; Sw_WriteHandle( w, 340, e[ "clip_boundary_handle" ] ) ; ENDIF
      Sw_WriteByte( w, 281, Vrm_ToValue( e[ "render_mode" ] ) )
      IF e[ "ucs_per_viewport" ] ; Sw_WriteI16( w, 71, 1 ) ; ENDIF
      v := e[ "ucs_origin" ]
      IF ! ( v[ 1 ] == 0.0 .AND. v[ 2 ] == 0.0 .AND. v[ 3 ] == 0.0 ) ; Sw_WriteDouble( w, 110, v[ 1 ] ) ; Sw_WriteDouble( w, 120, v[ 2 ] ) ; Sw_WriteDouble( w, 130, v[ 3 ] ) ; ENDIF
      v := e[ "ucs_x_axis" ]
      IF ! ( v[ 1 ] == 0.0 .AND. v[ 2 ] == 0.0 .AND. v[ 3 ] == 0.0 ) ; Sw_WriteDouble( w, 111, v[ 1 ] ) ; Sw_WriteDouble( w, 121, v[ 2 ] ) ; Sw_WriteDouble( w, 131, v[ 3 ] ) ; ENDIF
      v := e[ "ucs_y_axis" ]
      IF ! ( v[ 1 ] == 0.0 .AND. v[ 2 ] == 0.0 .AND. v[ 3 ] == 0.0 ) ; Sw_WriteDouble( w, 112, v[ 1 ] ) ; Sw_WriteDouble( w, 122, v[ 2 ] ) ; Sw_WriteDouble( w, 132, v[ 3 ] ) ; ENDIF
      IF e[ "elevation" ] != 0.0 ; Sw_WriteDouble( w, 146, e[ "elevation" ] ) ; ENDIF
      IF e[ "grid_major" ] != 0 ; Sw_WriteI16( w, 61, e[ "grid_major" ] ) ; ENDIF
   CASE t == "IMAGE"
      Sw_WriteEntityType( w, "IMAGE" ) ; Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, "AcDbRasterImage" ) ; Sw_WriteI32( w, 90, e[ "class_version" ] )
      Sw_WritePoint3d( w, 10, e[ "insertion_point" ] ) ; Sw_WritePoint3d( w, 11, e[ "u_vector" ] ) ; Sw_WritePoint3d( w, 12, e[ "v_vector" ] )
      Sw_WriteDouble( w, 13, e[ "size" ][ 1 ] ) ; Sw_WriteDouble( w, 23, e[ "size" ][ 2 ] )
      IF e[ "definition_handle" ] != NIL ; Sw_WriteHandle( w, 340, e[ "definition_handle" ] ) ; ENDIF
      Sw_WriteI16( w, 70, e[ "flags" ] ) ; Sw_WriteByte( w, 280, IIf( e[ "clipping_enabled" ], 1, 0 ) ) ; Sw_WriteByte( w, 281, e[ "brightness" ] )
      Sw_WriteByte( w, 282, e[ "contrast" ] ) ; Sw_WriteByte( w, 283, e[ "fade" ] )
      IF e[ "definition_reactor_handle" ] != NIL ; Sw_WriteHandle( w, 360, e[ "definition_reactor_handle" ] ) ; ENDIF
      Sw_WriteI16( w, 71, e[ "clip_boundary" ][ "clip_type" ] ) ; Sw_WriteI32( w, 91, Len( e[ "clip_boundary" ][ "vertices" ] ) )
      FOR EACH v IN e[ "clip_boundary" ][ "vertices" ] ; Sw_WriteDouble( w, 14, v[ 1 ] ) ; Sw_WriteDouble( w, 24, v[ 2 ] ) ; NEXT
   CASE t == "MULTILEADER"
      Swr_Multileader( st, e, hOwner )
   CASE t == "MESH"
      Sw_WriteEntityType( w, "MESH" ) ; Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, "AcDbSubDMesh" )
      Sw_WriteI16( w, 71, e[ "version" ] ) ; Sw_WriteI16( w, 72, IIf( e[ "blend_crease" ], 1, 0 ) ) ; Sw_WriteI32( w, 91, e[ "subdivision_level" ] )
      Sw_WriteI32( w, 92, Len( e[ "vertices" ] ) )
      FOR EACH v IN e[ "vertices" ] ; Sw_WritePoint3d( w, 10, v ) ; NEXT
      nI := 0 ; FOR EACH v IN e[ "faces" ] ; nI += 1 + Len( v[ "vertices" ] ) ; NEXT
      Sw_WriteI32( w, 93, nI )
      FOR EACH v IN e[ "faces" ]
         Sw_WriteI32( w, 90, Len( v[ "vertices" ] ) )
         FOR EACH nI IN v[ "vertices" ] ; Sw_WriteI32( w, 90, nI ) ; NEXT
      NEXT
      Sw_WriteI32( w, 94, Len( e[ "edges" ] ) )
      FOR EACH v IN e[ "edges" ] ; Sw_WriteI32( w, 90, v[ "start" ] ) ; Sw_WriteI32( w, 90, v[ "end" ] ) ; NEXT
      Sw_WriteI32( w, 95, Len( e[ "edges" ] ) )
      FOR EACH v IN e[ "edges" ] ; Sw_WriteDouble( w, 140, Mge_CreaseValue( v ) ) ; NEXT
      Sw_WriteI32( w, 90, 0 )
   CASE t == "UNDERLAY"
      Sw_WriteEntityType( w, Eul_EntityName( e ) ) ; Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, "AcDbUnderlayReference" ) ; Sw_WriteHandle( w, 340, e[ "definition_handle" ] )
      Sw_WriteDouble( w, 10, e[ "insertion_point" ][ 1 ] ) ; Sw_WriteDouble( w, 20, e[ "insertion_point" ][ 2 ] ) ; Sw_WriteDouble( w, 30, e[ "insertion_point" ][ 3 ] )
      Sw_WriteDouble( w, 41, e[ "x_scale" ] ) ; Sw_WriteDouble( w, 42, e[ "y_scale" ] ) ; Sw_WriteDouble( w, 43, e[ "z_scale" ] ) ; Sw_WriteDouble( w, 50, Swr_Deg( e[ "rotation" ] ) )
      Sw_WriteDouble( w, 210, e[ "normal" ][ 1 ] ) ; Sw_WriteDouble( w, 220, e[ "normal" ][ 2 ] ) ; Sw_WriteDouble( w, 230, e[ "normal" ][ 3 ] )
      Sw_WriteByte( w, 280, Eul_DisplayFlags( e ) ) ; Sw_WriteByte( w, 281, e[ "contrast" ] ) ; Sw_WriteByte( w, 282, e[ "fade" ] )
      FOR EACH v IN e[ "clip_boundary_vertices" ] ; Sw_WriteDouble( w, 11, v[ 1 ] ) ; Sw_WriteDouble( w, 21, v[ 2 ] ) ; NEXT
   CASE t == "SHAPE"
      Sw_WriteEntityType( w, "SHAPE" ) ; Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, "AcDbShape" )
      IF Abs( e[ "thickness" ] ) > 0.0000000001 ; Sw_WriteDouble( w, 39, e[ "thickness" ] ) ; ENDIF
      Sw_WriteDouble( w, 10, e[ "insertion_point" ][ 1 ] ) ; Sw_WriteDouble( w, 20, e[ "insertion_point" ][ 2 ] ) ; Sw_WriteDouble( w, 30, e[ "insertion_point" ][ 3 ] )
      Sw_WriteDouble( w, 40, e[ "size" ] ) ; Sw_WriteString( w, 2, e[ "shape_name" ] )
      IF Abs( e[ "rotation" ] ) > 0.0000000001 ; Sw_WriteDouble( w, 50, e[ "rotation" ] * ( 180.0 / OCX_PI ) ) ; ENDIF
      IF Abs( e[ "relative_x_scale" ] - 1.0 ) > 0.0000000001 ; Sw_WriteDouble( w, 41, e[ "relative_x_scale" ] ) ; ENDIF
      IF Abs( e[ "oblique_angle" ] ) > 0.0000000001 ; Sw_WriteDouble( w, 51, e[ "oblique_angle" ] * ( 180.0 / OCX_PI ) ) ; ENDIF
      IF Esh_HasCustomNormal( e )
         Sw_WriteDouble( w, 210, e[ "normal" ][ 1 ] ) ; Sw_WriteDouble( w, 220, e[ "normal" ][ 2 ] ) ; Sw_WriteDouble( w, 230, e[ "normal" ][ 3 ] )
      ENDIF
   CASE t == "RAY" .OR. t == "XLINE"
      Sw_WriteEntityType( w, t ) ; Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, IIf( t == "RAY", "AcDbRay", "AcDbXline" ) )
      Sw_WritePoint3d( w, 10, e[ "base_point" ] ) ; Sw_WritePoint3d( w, 11, e[ "direction" ] )
   CASE t == "INSERT"
      Sw_WriteEntityType( w, IIf( e[ "view_rep_handle" ] != NIL, "ACDBVIEWREPBLOCKREFERENCE", "INSERT" ) )
      Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, Ein_SubclassMarker( e ) )
      IF Ein_HasAttributes( e ) ; Sw_WriteI16( w, 66, 1 ) ; ENDIF
      Sw_WriteString( w, 2, e[ "block_name" ] ) ; Sw_WritePoint3d( w, 10, e[ "insert_point" ] )
      IF e[ "x_scale" ] != 1.0 ; Sw_WriteDouble( w, 41, e[ "x_scale" ] ) ; ENDIF
      IF e[ "y_scale" ] != 1.0 ; Sw_WriteDouble( w, 42, e[ "y_scale" ] ) ; ENDIF
      IF e[ "z_scale" ] != 1.0 ; Sw_WriteDouble( w, 43, e[ "z_scale" ] ) ; ENDIF
      IF e[ "rotation" ] != 0.0 ; Sw_WriteDouble( w, 50, Swr_Deg( e[ "rotation" ] ) ) ; ENDIF
      IF e[ "column_count" ] > 1 ; Sw_WriteI16( w, 70, e[ "column_count" ] ) ; ENDIF
      IF e[ "row_count" ] > 1 ; Sw_WriteI16( w, 71, e[ "row_count" ] ) ; ENDIF
      IF e[ "column_spacing" ] != 0.0 ; Sw_WriteDouble( w, 44, e[ "column_spacing" ] ) ; ENDIF
      IF e[ "row_spacing" ] != 0.0 ; Sw_WriteDouble( w, 45, e[ "row_spacing" ] ) ; ENDIF
      Swr_Normal( w, e[ "normal" ] )
      IF e[ "view_rep_handle" ] != NIL
         Sw_WriteSubclass( w, "AcDbViewRepBlockReference" ) ; Sw_WriteHandle( w, 330, e[ "view_rep_handle" ] )
      ENDIF
      Swr_XData( w, c[ "extended_data" ] )
      IF Ein_HasAttributes( e )
         FOR EACH v IN e[ "attributes" ]
            att := v
            IF Hd_IsNull( att[ "common" ][ "handle" ] )
               att := Ent_Clone( v ) ; att[ "common" ][ "handle" ] := Doc_AllocateHandle( st[ 5 ] )
            ENDIF
            Swr_AttdefAttrib( st, att, c[ "handle" ], .F. )
         NEXT
         hSeq := Doc_AllocateHandle( st[ 5 ] )
         Sw_WriteEntityType( w, "SEQEND" ) ; Sw_WriteHandle( w, 5, hSeq ) ; Sw_WriteHandle( w, 330, c[ "handle" ] )
         Sw_WriteSubclass( w, "AcDbEntity" )
         IF st[ 4 ] ; Sw_WriteI16( w, 67, 1 ) ; ENDIF
         Sw_WriteString( w, 8, c[ "layer" ] )
      ENDIF
      RETURN
   OTHERWISE
      RETURN /* PENDIENTE: resto de tipos */
   ENDCASE
   Swr_XData( w, c[ "extended_data" ] )
RETURN

STATIC PROCEDURE Swr_EntitiesOf( st, d, br )
   LOCAL h, n
   FOR EACH h IN br[ "entity_handles" ]
      n := hb_HGetDef( d[ "entity_index" ], h, NIL )
      IF n != NIL ; Swr_WriteEntity( st, d[ "entities" ][ n + 1 ], br[ "handle" ] ) ; ENDIF
   NEXT
RETURN

PROCEDURE Swr_Blocks( st, d )
   LOCAL w := st[ 1 ], br, nFl, cN, lPs, lAnon, prev
   Sw_WriteSectionStart( w, "BLOCKS" )
   FOR EACH br IN Tb_Values( d[ "block_records" ] )
      cN := br[ "name" ] ; lPs := Blk_IsPaperSpace( br ) ; nFl := 0
      lAnon := br[ "flags" ][ "anonymous" ] .OR. ( Left( cN, 1 ) == "*" .AND. ! Blk_IsModelSpace( br ) .AND. ! lPs )
      IF lAnon ; nFl := hb_bitOr( nFl, 1 ) ; ENDIF
      IF br[ "flags" ][ "has_attributes" ] ; nFl := hb_bitOr( nFl, 2 ) ; ENDIF
      IF br[ "flags" ][ "is_xref" ] ; nFl := hb_bitOr( nFl, 4 ) ; ENDIF
      IF br[ "flags" ][ "is_xref_overlay" ] ; nFl := hb_bitOr( nFl, 8 ) ; ENDIF
      IF br[ "flags" ][ "is_external" ] ; nFl := hb_bitOr( nFl, 16 ) ; ENDIF
      Sw_WriteString( w, 0, "BLOCK" ) ; Sw_WriteHandle( w, 5, br[ "block_entity_handle" ] ) ; Sw_WriteHandle( w, 330, br[ "handle" ] )
      Sw_WriteSubclass( w, "AcDbEntity" )
      IF lPs ; Sw_WriteI16( w, 67, 1 ) ; ENDIF
      Sw_WriteString( w, 8, "0" ) ; Sw_WriteSubclass( w, "AcDbBlockBegin" )
      Sw_WriteString( w, 2, cN ) ; Sw_WriteI16( w, 70, nFl ) ; Sw_WritePoint3d( w, 10, br[ "base_point" ] )
      Sw_WriteString( w, 3, cN ) ; Sw_WriteString( w, 1, br[ "xref_path" ] )
      IF Len( br[ "description" ] ) > 0 ; Sw_WriteString( w, 4, br[ "description" ] ) ; ENDIF
      IF ! Blk_IsModelSpace( br ) .AND. ! ( Upper( cN ) == "*PAPER_SPACE" )
         prev := st[ 4 ] ; IF lPs ; st[ 4 ] := .T. ; ENDIF
         Swr_EntitiesOf( st, d, br )
         st[ 4 ] := prev
      ENDIF
      Sw_WriteString( w, 0, "ENDBLK" ) ; Sw_WriteHandle( w, 5, br[ "block_end_handle" ] ) ; Sw_WriteHandle( w, 330, br[ "handle" ] )
      Sw_WriteSubclass( w, "AcDbEntity" )
      IF lPs ; Sw_WriteI16( w, 67, 1 ) ; ENDIF
      Sw_WriteString( w, 8, "0" ) ; Sw_WriteSubclass( w, "AcDbBlockEnd" )
   NEXT
   Sw_WriteSectionEnd( w )
RETURN

PROCEDURE Swr_Entities( st, d )
   LOCAL w := st[ 1 ], br, nVp, h, n
   Sw_WriteSectionStart( w, "ENTITIES" )
   st[ 4 ] := .F.
   br := Tb_Get( d[ "block_records" ], "*Model_Space" )
   IF br != NIL ; Swr_EntitiesOf( st, d, br ) ; ENDIF
   st[ 4 ] := .T.
   br := Tb_Get( d[ "block_records" ], "*Paper_Space" )
   IF br != NIL
      /* AutoCAD numera los viewports del layout activo 1, 2, ... en orden de entidad */
      nVp := 1
      FOR EACH h IN br[ "entity_handles" ]
         n := hb_HGetDef( d[ "entity_index" ], h, NIL )
         IF n != NIL .AND. d[ "entities" ][ n + 1 ][ "_type" ] == "VIEWPORT"
            st[ 6 ][ d[ "entities" ][ n + 1 ][ "common" ][ "handle" ] ] := nVp ; nVp := Min( nVp + 1, 32767 )
         ENDIF
      NEXT
      Swr_EntitiesOf( st, d, br )
   ENDIF
   st[ 4 ] := .F.
   Sw_WriteSectionEnd( w )
RETURN

/* DxfWriter::write_dxf (texto). Devuelve el texto DXF. */
FUNCTION Dxw_WriteString( d ) ; RETURN Dxw_WriteWith( d, TxW_New( NIL ) )

/* DxfWriter::new_binary + write_to_vec: devuelve los bytes del DXF binario */
FUNCTION Dxw_WriteBinaryString( d ) ; RETURN Dxw_WriteWith( d, BnW_New( NIL ) )

/* prepare_database_references (dwg_writer.rs), sobre una copia solo si hace falta. Portado: HATCH asociado (reactores de frontera / invalido),
   MLINE sin style_handle, reactores de UNDERLAY y reparacion del diccionario de layouts. PENDIENTE: reparaciones de TABLE (ACAD_TABLE/TABLESTYLE diferidos). */
STATIC FUNCTION Dxw_PrepareDbRefs( d )
   LOCAL e, pa, h, b, aBound, lBad, aMiss := {}, aInv := {}, aMl := {}, aUl := {}, o, k, hSty, hRoot, hLay, hNames := hb_Hash()
   LOCAL lFix := .F., nTg, ent, x, aL, hSeen, hdr := d[ "header" ], dic
   FOR EACH e IN Doc_Entities( d )
      DO CASE
      CASE e[ "_type" ] == "HATCH"
         IF ! e[ "is_associative" ] ; LOOP ; ENDIF
         aBound := {} ; lBad := .F.
         FOR EACH pa IN e[ "paths" ]
            FOR EACH h IN pa[ "boundary_handles" ] ; AAdd( aBound, h ) ; NEXT
         NEXT
         IF Len( aBound ) == 0 ; lBad := .T. ; ENDIF
         FOR EACH h IN aBound
            IF Doc_GetEntity( d, h ) == NIL ; lBad := .T. ; ENDIF
         NEXT
         IF lBad
            AAdd( aInv, e[ "common" ][ "handle" ] ) ; LOOP
         ENDIF
         FOR EACH h IN aBound
            b := Doc_GetEntity( d, h )
            IF AScan( b[ "common" ][ "reactors" ], {| r | r == e[ "common" ][ "handle" ] } ) == 0 ; AAdd( aMiss, { h, e[ "common" ][ "handle" ] } ) ; ENDIF
         NEXT
      CASE e[ "_type" ] == "MLINE" .AND. ( e[ "style_handle" ] == NIL .OR. Hd_IsNull( e[ "style_handle" ] ) )
         hSty := NIL
         FOR EACH k IN hb_HKeys( d[ "objects" ] )
            o := d[ "objects" ][ k ]
            IF o[ "_type" ] == "MLineStyle" .AND. Upper( o[ "name" ] ) == Upper( e[ "style_name" ] ) ; hSty := k ; EXIT ; ENDIF
         NEXT
         IF hSty == NIL ; hSty := hdr[ "current_multiline_style_handle" ] ; ENDIF
         IF ! Hd_IsNull( hSty ) ; AAdd( aMl, { e[ "common" ][ "handle" ], hSty } ) ; ENDIF
      CASE e[ "_type" ] == "UNDERLAY"
         IF hb_HHasKey( d[ "objects" ], e[ "definition_handle" ] ) .AND. d[ "objects" ][ e[ "definition_handle" ] ][ "_type" ] == "UnderlayDefinition"
            IF AScan( d[ "objects" ][ e[ "definition_handle" ] ][ "reactors" ], {| r | r == e[ "common" ][ "handle" ] } ) == 0
               AAdd( aUl, { e[ "definition_handle" ], e[ "common" ][ "handle" ] } )
            ENDIF
         ENDIF
      ENDCASE
   NEXT
   hRoot := hdr[ "named_objects_dict_handle" ] ; hLay := hdr[ "acad_layout_dict_handle" ]
   IF hb_HHasKey( d[ "objects" ], hRoot ) .AND. d[ "objects" ][ hRoot ][ "_type" ] == "Dictionary"
      x := Dic_Get( d[ "objects" ][ hRoot ], "ACAD_LAYOUT" )
      IF x != NIL ; hLay := x ; ENDIF
   ENDIF
   FOR EACH k IN hb_HKeys( d[ "objects" ] )
      IF d[ "objects" ][ k ][ "_type" ] == "Layout" ; hNames[ k ] := d[ "objects" ][ k ][ "name" ] ; ENDIF
   NEXT
   IF hb_HHasKey( d[ "objects" ], hLay ) .AND. d[ "objects" ][ hLay ][ "_type" ] == "Dictionary"
      nTg := 0 ; hSeen := hb_Hash()
      FOR EACH e IN d[ "objects" ][ hLay ][ "entries" ]
         IF hb_HHasKey( hNames, e[ 2 ] ) .AND. hNames[ e[ 2 ] ] == e[ 1 ] .AND. ! hb_HHasKey( hSeen, e[ 2 ] )
            hSeen[ e[ 2 ] ] := .T. ; nTg++
         ENDIF
      NEXT
      lFix := Len( d[ "objects" ][ hLay ][ "entries" ] ) != nTg .OR. nTg != Len( hNames )
   ENDIF
   IF Len( aMiss ) == 0 .AND. Len( aInv ) == 0 .AND. Len( aMl ) == 0 .AND. Len( aUl ) == 0 .AND. ! lFix
      RETURN d
   ENDIF
   d := Ent_Clone( d )
   FOR EACH x IN aUl
      AAdd( d[ "objects" ][ x[ 1 ] ][ "reactors" ], x[ 2 ] )
   NEXT
   FOR EACH x IN aMl
      ent := Doc_GetEntity( d, x[ 1 ] ) ; IF ent != NIL ; ent[ "style_handle" ] := x[ 2 ] ; ENDIF
   NEXT
   FOR EACH x IN aMiss
      ent := Doc_GetEntity( d, x[ 1 ] )
      IF ent != NIL .AND. AScan( ent[ "common" ][ "reactors" ], {| r | r == x[ 2 ] } ) == 0 ; AAdd( ent[ "common" ][ "reactors" ], x[ 2 ] ) ; ENDIF
   NEXT
   FOR EACH h IN aInv
      ent := Doc_GetEntity( d, h )
      IF ent != NIL
         ent[ "is_associative" ] := .F.
         FOR EACH pa IN ent[ "paths" ] ; pa[ "boundary_handles" ] := {} ; NEXT
      ENDIF
   NEXT
   IF lFix
      dic := d[ "objects" ][ hLay ] ; dic[ "entries" ] := {}
      aL := ASort( hb_HKeys( hNames ) ) ; hSeen := hb_Hash()
      FOR EACH k IN aL
         IF ! hb_HHasKey( hSeen, hNames[ k ] ) ; hSeen[ hNames[ k ] ] := .T. ; AAdd( dic[ "entries" ], { hNames[ k ], k } ) ; ENDIF
      NEXT
      FOR EACH k IN aL ; d[ "objects" ][ k ][ "owner" ] := hLay ; NEXT
   ENDIF
RETURN d

/* build_valid_handles: handles que apareceran en el DXF (objetos, block records y sus entidades, indice de entidades, atributos de INSERT,
   registros y cabeceras de tablas). Hash handle -> .T. ; vacio = sin filtro. PENDIENTE: Unknown/Associative/DynamicBlock "no restaurables" y loft_input_entities (sin modelo). */
STATIC FUNCTION Dxw_BuildValidHandles( d )
   LOCAL h := hb_Hash(), k, br, e, a, t
   FOR EACH k IN hb_HKeys( d[ "objects" ] ) ; h[ k ] := .T. ; NEXT
   FOR EACH br IN Tb_Values( d[ "block_records" ] )
      h[ br[ "handle" ] ] := .T.
      FOR EACH k IN br[ "entity_handles" ] ; h[ k ] := .T. ; NEXT
   NEXT
   FOR EACH k IN hb_HKeys( d[ "entity_index" ] ) ; h[ k ] := .T. ; NEXT
   FOR EACH e IN d[ "entities" ]
      IF e[ "_type" ] == "INSERT"
         FOR EACH a IN e[ "attributes" ] ; h[ a[ "common" ][ "handle" ] ] := .T. ; NEXT
      ENDIF
   NEXT
   FOR EACH t IN { "layers", "line_types", "text_styles", "dim_styles", "app_ids", "views", "vports", "ucss" }
      FOR EACH e IN Tb_Values( d[ t ] ) ; h[ e[ "handle" ] ] := .T. ; NEXT
      h[ Tb_Handle( d[ t ] ) ] := .T.
   NEXT
   h[ Tb_Handle( d[ "block_records" ] ) ] := .T.
RETURN h

/* valid_handles.is_empty() || contains(h) */
STATIC FUNCTION Swr_Valid( st, h ) ; RETURN Len( st[ 8 ] ) == 0 .OR. hb_HHasKey( st[ 8 ], h )

/* safe_entity_owner: si el propietario no saldra en el DXF, *Model_Space */
STATIC FUNCTION Swr_SafeOwner( st, hOwner )
   IF Hd_IsNull( hOwner ) .OR. Len( st[ 8 ] ) == 0 .OR. hb_HHasKey( st[ 8 ], hOwner ) .OR. Hd_IsNull( st[ 9 ] ) ; RETURN hOwner ; ENDIF
RETURN st[ 9 ]

STATIC FUNCTION Dxw_WriteWith( d, w )
   LOCAL st, o, nNp := Hd_Null(), e, br
   d := Dxw_PrepareDbRefs( d )
   /* prepare_table_keys: sobre una copia (el original no cambia) */
   IF Doc_HasStaleTableKeys( d )
      d := Ent_Clone( d ) ; Doc_ResyncTableKeys( d )
   ENDIF
   Doc_SynchronizeHandleAllocator( d )
   /* normal_plotstyle_handle: default_handle del DictionaryWithDefault que tiene la entrada "Normal" */
   FOR EACH o IN hb_HValues( d[ "objects" ] )
      IF o[ "_type" ] == "DictionaryWithDefault"
         FOR EACH e IN o[ "entries" ]
            IF e[ 1 ] == "Normal" ; nNp := o[ "default_handle" ] ; EXIT ; ENDIF
         NEXT
         IF ! Hd_IsNull( nNp ) ; EXIT ; ENDIF
      ENDIF
   NEXT
   br := Tb_Get( d[ "block_records" ], "*Model_Space" )
   st := { w, d[ "version" ], d[ "next_handle" ] + 1, .F., d, hb_Hash(), nNp, Dxw_BuildValidHandles( d ), IIf( br != NIL, br[ "handle" ], Hd_Null() ) }
   Swr_Header( st, d )
   Swr_Classes( st, d )
   Swr_Tables( st, d )
   Swr_Blocks( st, d )
   Swr_Entities( st, d )
   Dxo_WriteObjects( w, d, d[ "version" ], st[ 8 ] )
   Sw_WriteString( w, 0, "EOF" )
RETURN Sw_Output( w )
