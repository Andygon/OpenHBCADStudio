/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/dxf_secwriter.prg
   Origen Rust: opencadcodec/src/io/dxf/writer/section_writer.rs (parcial) y writer/mod.rs (write_dxf).
   Licencia del original: MPL-2.0. Sin tests propios en el original (se prueba por roundtrip: tests/t_dxf_rw.prg).
   Portado: write_header (generado del original, con puertas de version), summary_info, write_classes,
   tablas LTYPE/LAYER/STYLE/APPID/BLOCK_RECORD, write_blocks, write_entities (POINT/LINE/CIRCLE/ARC/LWPOLYLINE/TEXT/INSERT),
   xdata, EOF.
   PENDIENTE: VPORT/VIEW/UCS/DIMSTYLE, OBJECTS (se escribe vacia), ACDSDATA, resto de entidades,
   $TDUCREATE/$TDUUPDATE (universal_*_or_local no portado), valid_handles/safe_entity_owner (no filtra),
   normal_plotstyle_handle, preview_data de BLOCK_RECORD, prepare_database_references/table_keys.
   Nota (quirk fiel al original): TEXT escribe oblique_angle (51) en radianes sin convertir.
   st = { w, nVer, lPaper }. Prefijo Swr_ / Dxw_.
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
   Swr_Var( w, "$TDUPDATE", {|| Sw_WriteDouble( w, 40, hdr[ "update_date_julian" ] ) } )
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

STATIC PROCEDURE Swr_CommonTable( w, d, h, hOwner )
   LOCAL aR := hb_HGetDef( d[ "reactors_by_handle" ], h, NIL ), r, aOk := {}, hX := hb_HGetDef( d[ "xdic_by_handle" ], h, NIL )
   Sw_WriteHandle( w, 5, h )
   IF aR != NIL
      FOR EACH r IN aR
         IF ! Hd_IsNull( r ) ; AAdd( aOk, r ) ; ENDIF
      NEXT
   ENDIF
   IF Len( aOk ) > 0
      Sw_WriteString( w, 102, "{ACAD_REACTORS" )
      FOR EACH r IN aOk ; Sw_WriteHandle( w, 330, r ) ; NEXT
      Sw_WriteString( w, 102, "}" )
   ENDIF
   IF hX != NIL .AND. ! Hd_IsNull( hX )
      Sw_WriteString( w, 102, "{ACAD_XDICTIONARY" ) ; Sw_WriteHandle( w, 360, hX ) ; Sw_WriteString( w, 102, "}" )
   ENDIF
   Sw_WriteHandle( w, 330, hOwner )
RETURN

STATIC PROCEDURE Swr_LayerEntry( st, d, l, hOwner, h )
   LOCAL w := st[ 1 ], nFl := 0, nCi, c := l[ "color" ], tc, cB
   Sw_WriteString( w, 0, "LAYER" )
   Swr_CommonTable( w, d, h, hOwner )
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
   IF st[ 2 ] >= Dxv_FromVersionString( "AC1015" ) .AND. ! Hd_IsNull( l[ "plotstyle_handle" ] )
      Sw_WriteHandle( w, 390, l[ "plotstyle_handle" ] )
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
   Swr_CommonTable( w, d, lt[ "handle" ], hOwner )
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
         Sw_WriteDouble( w, 50, c[ "rotation" ] * 180.0 / OCX_PI )
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
   Swr_CommonTable( w, d, s[ "handle" ], hOwner )
   Sw_WriteSubclass( w, "AcDbSymbolTableRecord" ) ; Sw_WriteSubclass( w, "AcDbTextStyleTableRecord" )
   Sw_WriteString( w, 2, IIf( s[ "is_shape_file" ], "", s[ "name" ] ) )
   IF s[ "is_shape_file" ] ; nFl := hb_bitOr( nFl, 1 ) ; ENDIF
   IF s[ "is_vertical" ] ; nFl := hb_bitOr( nFl, 4 ) ; ENDIF
   IF s[ "xref_dependent" ] ; nFl := hb_bitOr( nFl, 16 ) ; ENDIF
   Sw_WriteI16( w, 70, nFl )
   Sw_WriteDouble( w, 40, s[ "height" ] ) ; Sw_WriteDouble( w, 41, s[ "width_factor" ] )
   Sw_WriteDouble( w, 50, s[ "oblique_angle" ] * 180.0 / OCX_PI )
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
   Swr_CommonTable( w, d, a[ "handle" ], hOwner )
   Sw_WriteSubclass( w, "AcDbSymbolTableRecord" ) ; Sw_WriteSubclass( w, "AcDbRegAppTableRecord" )
   Sw_WriteString( w, 2, a[ "name" ] ) ; Sw_WriteI16( w, 70, 0 )
RETURN

STATIC PROCEDURE Swr_BlockRecordEntry( st, d, br, hOwner )
   LOCAL w := st[ 1 ], h
   Sw_WriteString( w, 0, "BLOCK_RECORD" )
   Swr_CommonTable( w, d, br[ "handle" ], hOwner )
   Sw_WriteSubclass( w, "AcDbSymbolTableRecord" ) ; Sw_WriteSubclass( w, "AcDbBlockTableRecord" )
   Sw_WriteString( w, 2, br[ "name" ] )
   Sw_WriteHandle( w, 340, br[ "layout" ] )
   IF Len( br[ "insert_handles" ] ) > 0
      Sw_WriteString( w, 102, "{BLKREFS" )
      FOR EACH h IN br[ "insert_handles" ] ; Sw_WriteHandle( w, 331, h ) ; NEXT
      Sw_WriteString( w, 102, "}" )
   ENDIF
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
   t := d[ "app_ids" ]
   Swr_TableHeader( w, d, "APPID", Tb_Len( t ), Tb_Handle( t ) )
   FOR EACH e IN Tb_Values( t )
      IF Upper( e[ "name" ] ) == "ACAD" ; Swr_AppIdEntry( st, d, e, Tb_Handle( t ) ) ; EXIT ; ENDIF
   NEXT
   FOR EACH e IN Tb_Values( t )
      IF Upper( e[ "name" ] ) != "ACAD" ; Swr_AppIdEntry( st, d, e, Tb_Handle( t ) ) ; ENDIF
   NEXT
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
   LOCAL w := st[ 1 ], h, tc
   Sw_WriteHandle( w, 5, c[ "handle" ] ) ; Sw_WriteHandle( w, 330, hOwner )
   IF c[ "xdictionary_handle" ] != NIL .AND. ! Hd_IsNull( c[ "xdictionary_handle" ] )
      Sw_WriteString( w, 102, "{ACAD_XDICTIONARY" ) ; Sw_WriteHandle( w, 360, c[ "xdictionary_handle" ] ) ; Sw_WriteString( w, 102, "}" )
   ENDIF
   IF Len( c[ "reactors" ] ) > 0
      Sw_WriteString( w, 102, "{ACAD_REACTORS" )
      FOR EACH h IN c[ "reactors" ] ; Sw_WriteHandle( w, 330, h ) ; NEXT
      Sw_WriteString( w, 102, "}" )
   ENDIF
   Sw_WriteSubclass( w, "AcDbEntity" )
   IF st[ 4 ] ; Sw_WriteI16( w, 67, 1 ) ; ENDIF
   Sw_WriteString( w, 8, c[ "layer" ] )
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
         IF h != NIL .AND. ! Hd_IsNull( h ) ; Sw_WriteHandle( w, 348, h ) ; ENDIF
      NEXT
   ENDIF
RETURN

STATIC FUNCTION Swr_Deg( n ) ; RETURN n * 180.0 / OCX_PI

/* write_attribute_text_value: DXF es por lineas, un salto dentro del valor se escribe como \P */
STATIC FUNCTION Swr_AttrText( c )
   c := StrTran( c, Chr( 13 ) + Chr( 10 ), "\P" )
   c := StrTran( c, Chr( 13 ), "\P" )
RETURN StrTran( c, Chr( 10 ), "\P" )

/* write_attdef / write_attrib. PENDIENTE: la cola multilinea (R2018+, AC1032: write_attribute_mtext, 101 Embedded Object) */
STATIC PROCEDURE Swr_AttdefAttrib( st, e, hOwner, lDef )
   LOCAL w := st[ 1 ], c := e[ "common" ]
   Sw_WriteEntityType( w, IIf( lDef, "ATTDEF", "ATTRIB" ) ) ; Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, "AcDbText" )
   Sw_WritePoint3d( w, 10, e[ "insertion_point" ] ) ; Sw_WriteDouble( w, 40, e[ "height" ] )
   Sw_WriteString( w, 1, Swr_AttrText( IIf( lDef, e[ "default_value" ], e[ "value" ] ) ) )
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

STATIC PROCEDURE Swr_WriteEntity( st, e, hOwner )
   LOCAL w := st[ 1 ], c := e[ "common" ], t := e[ "_type" ], v, hSeq, att, nI
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
   CASE t == "SPLINE"
      Sw_WriteEntityType( w, "SPLINE" ) ; Swr_CommonEntity( st, c, hOwner ) ; Sw_WriteSubclass( w, "AcDbSpline" )
      Swr_Normal( w, e[ "normal" ] ) ; Sw_WriteI16( w, 70, Spf_Write( e ) ) ; Sw_WriteI16( w, 71, e[ "degree" ] )
      Sw_WriteI16( w, 72, Len( e[ "knots" ] ) ) ; Sw_WriteI16( w, 73, Len( e[ "control_points" ] ) ) ; Sw_WriteI16( w, 74, Len( e[ "fit_points" ] ) )
      Sw_WriteDouble( w, 42, e[ "knot_tolerance" ] ) ; Sw_WriteDouble( w, 43, e[ "control_tolerance" ] ) ; Sw_WriteDouble( w, 44, e[ "fit_tolerance" ] )
      IF ! Vc3_Eq( e[ "begin_tangent" ], Vc3_Zero() ) ; Sw_WritePoint3d( w, 12, e[ "begin_tangent" ] ) ; ENDIF
      IF ! Vc3_Eq( e[ "end_tangent" ], Vc3_Zero() ) ; Sw_WritePoint3d( w, 13, e[ "end_tangent" ] ) ; ENDIF
      FOR EACH v IN e[ "knots" ] ; Sw_WriteDouble( w, 40, v ) ; NEXT
      FOR nI := 1 TO Len( e[ "control_points" ] )
         Sw_WritePoint3d( w, 10, e[ "control_points" ][ nI ] )
         IF e[ "flags" ][ "rational" ] ; Sw_WriteDouble( w, 41, IIf( nI <= Len( e[ "weights" ] ), e[ "weights" ][ nI ], 1.0 ) ) ; ENDIF
      NEXT
      FOR EACH v IN e[ "fit_points" ] ; Sw_WritePoint3d( w, 11, v ) ; NEXT
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
   LOCAL w := st[ 1 ], br
   Sw_WriteSectionStart( w, "ENTITIES" )
   st[ 4 ] := .F.
   br := Tb_Get( d[ "block_records" ], "*Model_Space" )
   IF br != NIL ; Swr_EntitiesOf( st, d, br ) ; ENDIF
   st[ 4 ] := .T.
   br := Tb_Get( d[ "block_records" ], "*Paper_Space" )
   IF br != NIL ; Swr_EntitiesOf( st, d, br ) ; ENDIF
   st[ 4 ] := .F.
   Sw_WriteSectionEnd( w )
RETURN

/* DxfWriter::write_dxf (texto). Devuelve el texto DXF. */
FUNCTION Dxw_WriteString( d )
   LOCAL w := TxW_New( NIL ), st
   Doc_SynchronizeHandleAllocator( d )
   st := { w, d[ "version" ], d[ "next_handle" ] + 1, .F., d }
   Swr_Header( st, d )
   Swr_Classes( st, d )
   Swr_Tables( st, d )
   Swr_Blocks( st, d )
   Swr_Entities( st, d )
   Sw_WriteSectionStart( w, "OBJECTS" ) ; Sw_WriteSectionEnd( w ) /* PENDIENTE: write_objects */
   Sw_WriteString( w, 0, "EOF" )
RETURN Sw_Output( w )
