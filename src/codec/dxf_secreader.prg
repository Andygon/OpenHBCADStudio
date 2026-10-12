/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/dxf_secreader.prg
   Origen Rust: opencadcodec/src/io/dxf/reader/section_reader.rs (parcial: read_header,
   read_classes, read_tables [LAYER/LTYPE/STYLE/BLOCK_RECORD/APPID], read_blocks, read_entities
   con POINT/LINE/CIRCLE/ARC/LWPOLYLINE/TEXT/INSERT; el resto de entidades/tablas/objetos: PENDIENTE)
   y io/dxf/reader.rs (bucle de secciones). Licencia del original: MPL-2.0.
   El original tiene tests en L21305+ (roundtrip); su port esta en tests/t_dxf_rw.prg.
   Flujo: s := { reader, lBinary }. Pair/NIL como en stream_reader.prg.
   Prefijo Sr_ / Dxr_.
----------------------------------------------------------------------------*/
#include "ocx.ch"

#define DP_CODE 1
#define DP_VALUE 3

FUNCTION Sr_NewText( cData ) ; RETURN { TxR_New( cData ), .F. }

FUNCTION Sr_Next( s ) ; RETURN IIf( s[ 2 ], BnR_ReadPair( s[ 1 ] ), TxR_ReadPair( s[ 1 ] ) )
FUNCTION Sr_PushBack( s, p )
   IF s[ 2 ] ; BnR_PushBack( s[ 1 ], p ) ; ELSE ; TxR_PushBack( s[ 1 ], p ) ; ENDIF
RETURN NIL
FUNCTION Sr_Error( s ) ; RETURN IIf( s[ 2 ], BnR_Error( s[ 1 ] ), TxR_Error( s[ 1 ] ) )
FUNCTION Sr_SetEncoding( s, c )
   IF ! s[ 2 ] ; TxR_SetEncoding( s[ 1 ], c ) ; ENDIF
RETURN NIL

FUNCTION Sr_HexVal( p )
   LOCAL c := AllTrim( p[ DP_VALUE ] ), n := 0, i, k
   IF Len( c ) == 0 .OR. Len( c ) > 16 ; RETURN NIL ; ENDIF
   FOR i := 1 TO Len( c )
      k := At( Upper( SubStr( c, i, 1 ) ), "0123456789ABCDEF" )
      IF k == 0 ; RETURN NIL ; ENDIF
      n := n * 16 + k - 1
   NEXT
RETURN n

PROCEDURE Sr_HeaderPoint( s, a, nDim )
   LOCAL i, p, nBase, v
   IF nDim == 2
      FOR i := 1 TO 2
         p := Sr_Next( s )
         IF p != NIL
            v := Dp_AsDouble( p )
            IF v != NIL
               IF p[ DP_CODE ] % 100 < 20 ; a[ 1 ] := v ; ELSE ; a[ 2 ] := v ; ENDIF
            ENDIF
         ENDIF
      NEXT
      RETURN
   ENDIF
   FOR i := 1 TO 3
      p := Sr_Next( s )
      IF p != NIL
         nBase := p[ DP_CODE ] % 100
         IF nBase >= 10 .AND. nBase < 40
            v := Dp_AsDouble( p )
            IF v != NIL
               DO CASE
               CASE nBase < 20 ; a[ 1 ] := v
               CASE nBase < 30 ; a[ 2 ] := v
               OTHERWISE ; a[ 3 ] := v
               ENDCASE
            ENDIF
         ELSE
            Sr_PushBack( s, p )
            EXIT
         ENDIF
      ENDIF
   NEXT
RETURN

STATIC PROCEDURE Sr_SkipHeaderVariable( s )
   LOCAL p
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 9 .OR. p[ DP_CODE ] == 0
         Sr_PushBack( s, p )
         EXIT
      ENDIF
   ENDDO
RETURN

/* read_header */
PROCEDURE Sr_ReadHeader( s, d )
   LOCAL hdr := d[ "header" ], pair, p, v, cName, lCustomPending := .F., h, aProps, info, cEnc
   DO WHILE ( pair := Sr_Next( s ) ) != NIL
      IF pair[ DP_CODE ] == 0 .AND. pair[ DP_VALUE ] == "ENDSEC" ; EXIT ; ENDIF
      IF pair[ DP_CODE ] != 9 ; LOOP ; ENDIF
      cName := pair[ DP_VALUE ]
      info := d[ "summary_info" ]
      SWITCH cName
      CASE "$ACADVER"
         p := Sr_Next( s )
         IF p != NIL ; d[ "version" ] := Dxv_FromVersionString( p[ DP_VALUE ] ) ; ENDIF
         EXIT
      CASE "$ACADMAINTVER"
         Sr_Next( s )
         EXIT
      CASE "$REQUIREDVERSIONS"
         p := Sr_Next( s )
         IF p != NIL
            v := Dp_AsInt( p )
            IF v != NIL ; hdr[ "required_versions" ] := v ; ENDIF
         ENDIF
         EXIT
      CASE "$DWGCODEPAGE"
         p := Sr_Next( s )
         IF p != NIL
            hdr[ "code_page" ] := p[ DP_VALUE ]
            IF d[ "version" ] < Dxv_FromVersionString( "AC1021" )
               cEnc := CP_EncodingFromCodePage( hdr[ "code_page" ] )
               IF cEnc != NIL ; Sr_SetEncoding( s, cEnc ) ; ENDIF
            ENDIF
         ENDIF
         EXIT
      CASE "$HANDSEED"
         p := Sr_Next( s )
         IF p != NIL
            h := Sr_HexVal( p )
            IF h != NIL ; hdr[ "handle_seed" ] := h ; ENDIF
         ENDIF
         EXIT
      CASE "$LASTSAVEDBY"
         p := Sr_Next( s )
         IF p != NIL ; hdr[ "last_saved_by" ] := p[ DP_VALUE ] ; info[ "last_saved_by" ] := p[ DP_VALUE ] ; ENDIF
         EXIT
      CASE "$FINGERPRINTGUID"
         p := Sr_Next( s )
         IF p != NIL ; hdr[ "fingerprint_guid" ] := p[ DP_VALUE ] ; ENDIF
         EXIT
      CASE "$VERSIONGUID"
         p := Sr_Next( s )
         IF p != NIL ; hdr[ "version_guid" ] := p[ DP_VALUE ] ; ENDIF
         EXIT
      CASE "$MENU"
         p := Sr_Next( s )
         IF p != NIL ; hdr[ "menu_name" ] := p[ DP_VALUE ] ; ENDIF
         EXIT
      CASE "$PROJECTNAME"
         p := Sr_Next( s )
         IF p != NIL ; hdr[ "project_name" ] := p[ DP_VALUE ] ; ENDIF
         EXIT
      CASE "$HYPERLINKBASE"
         p := Sr_Next( s )
         IF p != NIL ; hdr[ "hyperlink_base" ] := p[ DP_VALUE ] ; info[ "hyperlink_base" ] := p[ DP_VALUE ] ; ENDIF
         EXIT
      CASE "$TITLE"
      CASE "$SUBJECT"
      CASE "$AUTHOR"
      CASE "$KEYWORDS"
      CASE "$COMMENTS"
      CASE "$REVISIONNUMBER"
         p := Sr_Next( s )
         IF p != NIL
            DO CASE
            CASE cName == "$TITLE" ; info[ "title" ] := p[ DP_VALUE ]
            CASE cName == "$SUBJECT" ; info[ "subject" ] := p[ DP_VALUE ]
            CASE cName == "$AUTHOR" ; info[ "author" ] := p[ DP_VALUE ]
            CASE cName == "$KEYWORDS" ; info[ "keywords" ] := p[ DP_VALUE ]
            CASE cName == "$COMMENTS" ; info[ "comments" ] := p[ DP_VALUE ]
            OTHERWISE ; info[ "revision_number" ] := p[ DP_VALUE ]
            ENDCASE
         ENDIF
         EXIT
      CASE "$CUSTOMPROPERTYTAG"
         p := Sr_Next( s )
         IF p != NIL
            AAdd( info[ "custom_properties" ], { p[ DP_VALUE ], "" } )
            lCustomPending := .T.
         ENDIF
         EXIT
      CASE "$CUSTOMPROPERTY"
         p := Sr_Next( s )
         IF p != NIL
            aProps := info[ "custom_properties" ]
            IF Len( aProps ) > 0 .AND. lCustomPending
               ATail( aProps )[ 2 ] := p[ DP_VALUE ]
            ELSE
               AAdd( aProps, { "", p[ DP_VALUE ] } )
            ENDIF
            lCustomPending := .F.
         ENDIF
         EXIT
      CASE "$STYLESHEET"
         p := Sr_Next( s )
         IF p != NIL ; hdr[ "stylesheet" ] := p[ DP_VALUE ] ; ENDIF
         EXIT
   CASE "$DIMASO"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "associate_dimensions" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$DIMSHO"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "update_dimensions_while_dragging" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$ORTHOMODE"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "ortho_mode" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$FILLMODE"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "fill_mode" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$QTEXTMODE"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "quick_text_mode" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$MIRRTEXT"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "mirror_text" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$REGENMODE"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "regen_mode" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$LIMCHECK"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "limit_check" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$PLIMCHECK"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "paper_space_limit_check" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$PLINEGEN"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "polyline_linetype_generation" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$PSLTSCALE"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "paper_space_linetype_scaling" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$TILEMODE"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "show_model_space" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$USRTIMER"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "user_timer" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$WORLDVIEW"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "world_view" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$VISRETAIN"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "retain_xref_visibility" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$DISPSILH"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "display_silhouette" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$SPLFRAME"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "spline_frame" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$DELOBJ"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "delete_objects" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$SOLIDHIST"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "record_solid_history" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$SHOWHIST"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "show_solid_history" ] := Max( 0, Min( 2, v ) )
         ENDIF
      ENDIF
      EXIT
   CASE "$BLIPMODE"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "blip_mode" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$ATTREQ"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "attribute_request" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$ATTDIA"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "attribute_dialog" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$DRAGMODE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "drag_mode" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$LUNITS"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "linear_unit_format" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$LUPREC"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "linear_unit_precision" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$AUNITS"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "angular_unit_format" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$AUPREC"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "angular_unit_precision" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$INSUNITS"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "insertion_units" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$ATTMODE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "attribute_visibility" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$PDMODE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "point_display_mode" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$USERI1"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "user_int1" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$USERI2"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "user_int2" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$USERI3"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "user_int3" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$USERI4"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "user_int4" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$USERI5"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "user_int5" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$COORDS"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "coords_mode" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$OSMODE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI32( p )
         IF v != NIL
            hdr[ "object_snap_mode" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$PICKSTYLE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "pick_style" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$SPLINETYPE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "spline_type" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$SPLINESEGS"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "spline_segments" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$SURFU"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "surface_u_density" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$SURFV"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "surface_v_density" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$SURFTYPE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "surface_type" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$SURFTAB1"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "surface_tab1" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$SURFTAB2"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "surface_tab2" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$SHADEDGE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "shade_edge" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$SHADEDIF"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "shade_diffuse" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$MAXACTVP"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "max_active_viewports" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$ISOLINES"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "isolines" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$CMLJUST"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "multiline_justification" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$TEXTQLTY"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "text_quality" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$SORTENTS"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "sort_entities" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$INDEXCTL"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "index_control" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$HIDETEXT"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "hide_text" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$XCLIPFRAME"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "xclip_frame" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DWFFRAME"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dwf_frame" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DGNFRAME"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dgn_frame" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$HALOGAP"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "halo_gap" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$OBSCOLOR"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "obscured_color" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$OBSLTYPE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "obscured_linetype" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$INTERSECTIONDISPLAY"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "intersection_display" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMFXL"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "dim_fixed_ext_line_length" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMJOGANG"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "dim_jog_angle" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMTFILL"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_text_fill" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMTFILLCLR"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_text_fill_color" ] := Cl_FromIndex( v )
         ENDIF
      ENDIF
      EXIT
   CASE "$3DDWFPREC"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "dwf_3d_precision" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$PSOLWIDTH"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "polysolid_width" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$PSOLHEIGHT"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "polysolid_height" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$LIGHTGLYPHDISPLAY"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "light_glyph_display" ] := Max( 0, Min( 1, v ) )
         ENDIF
      ENDIF
      EXIT
   CASE "$TILEMODELIGHTSYNCH"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "tile_model_light_synch" ] := Max( 0, Min( 1, v ) )
         ENDIF
      ENDIF
      EXIT
   CASE "$INTERFERECOLOR"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "interference_color" ] := Cl_FromIndex( v )
         ENDIF
      ENDIF
      EXIT
   CASE "$REALWORLDSCALE"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "real_world_scale" ] := ( Dp_AsBool( p ) == NIL .OR. Dp_AsBool( p ) )
      ENDIF
      EXIT
   CASE "$INTERSECTIONCOLOR"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "intersection_color" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMASSOC"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dimension_associativity" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$MEASUREMENT"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "measurement" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$PROXYGRAPHICS"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "proxy_graphics" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$TREEDEPTH"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "tree_depth" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$LTSCALE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "linetype_scale" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$TEXTSIZE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "text_height" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$TRACEWID"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "trace_width" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$SKETCHINC"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "sketch_increment" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$SKPOLY"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "sketch_type" ] := Max( 0, Min( 2, v ) )
         ENDIF
      ENDIF
      EXIT
   CASE "$SKTOLERANCE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "sketch_tolerance" ] := IIf( OCX_ISFINITE( v ), Max( 0.0, Min( 1.0, v ) ), 0.5 )
         ENDIF
      ENDIF
      EXIT
   CASE "$THICKNESS"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "thickness" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$PDSIZE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "point_display_size" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$PLINEWID"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "polyline_width" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$CELTSCALE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "current_entity_linetype_scale" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$VIEWTWIST"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "view_twist" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$FILLETRAD"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "fillet_radius" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$CHAMFERA"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "chamfer_distance_a" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$CHAMFERB"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "chamfer_distance_b" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$CHAMFERC"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "chamfer_length" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$CHAMFERD"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "chamfer_angle" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$ANGBASE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "angle_base" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$ANGDIR"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "angle_direction" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$ELEVATION"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "elevation" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$PELEVATION"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "paper_elevation" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$FACETRES"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "facet_resolution" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$CMLSCALE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "multiline_scale" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$USERR1"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "user_real1" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$USERR2"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "user_real2" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$USERR3"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "user_real3" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$USERR4"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "user_real4" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$USERR5"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "user_real5" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$PSVPSCALE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "viewport_scale_factor" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$CANNOSCALE"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "current_annotation_scale" ] := Dp_AsString( p )
      ENDIF
      EXIT
   CASE "$CANNOSCALEVALUE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "annotation_scale_value" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$SHADOWPLANELOCATION"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "shadow_plane_location" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$LOFTANG1"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "loft_angle1" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$LOFTANG2"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "loft_angle2" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$LOFTMAG1"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "loft_magnitude1" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$LOFTMAG2"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "loft_magnitude2" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$LOFTPARAM"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "loft_param" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$LOFTNORMALS"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "loft_normals" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$LATITUDE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "latitude" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$LONGITUDE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "longitude" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$NORTHDIRECTION"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "north_direction" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$TIMEZONE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI32( p )
         IF v != NIL
            hdr[ "timezone" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$STEPSPERSEC"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "steps_per_second" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$STEPSIZE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "step_size" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$LENSLENGTH"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "lens_length" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$CAMERAHEIGHT"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "camera_height" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$CAMERADISPLAY"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "camera_display" ] := ( Dp_AsBool( p ) != NIL .AND. Dp_AsBool( p ) == .T. )
      ENDIF
      EXIT
   CASE "$CECOLOR"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "current_entity_color" ] := Cl_FromIndex( v )
         ENDIF
      ENDIF
      EXIT
   CASE "$CELWEIGHT"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "current_line_weight" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$CEPSNTYPE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "current_plotstyle_type" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$ENDCAPS"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "end_caps" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$JOINSTYLE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "join_style" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$LWDISPLAY"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "lineweight_display" ] := ( Dp_AsBool( p ) != NIL .AND. Dp_AsBool( p ) == .T. )
      ENDIF
      EXIT
   CASE "$XEDIT"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "xedit" ] := ( Dp_AsBool( p ) != NIL .AND. Dp_AsBool( p ) == .T. )
      ENDIF
      EXIT
   CASE "$EXTNAMES"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "extended_names" ] := ( Dp_AsBool( p ) != NIL .AND. Dp_AsBool( p ) == .T. )
      ENDIF
      EXIT
   CASE "$PSTYLEMODE"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "plotstyle_mode" ] := ( Dp_AsBool( p ) != NIL .AND. Dp_AsBool( p ) == .T. )
      ENDIF
      EXIT
   CASE "$OLESTARTUP"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "ole_startup" ] := ( Dp_AsBool( p ) != NIL .AND. Dp_AsBool( p ) == .T. )
      ENDIF
      EXIT
   CASE "$DIMSCALE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "dim_scale" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMASZ"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "dim_arrow_size" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMEXO"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "dim_ext_line_offset" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMDLI"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "dim_line_increment" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMEXE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "dim_ext_line_extension" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMRND"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "dim_rounding" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMDLE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "dim_line_extension" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMTP"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "dim_tolerance_plus" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMTM"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "dim_tolerance_minus" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMTXT"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "dim_text_height" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMCEN"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "dim_center_mark" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMTSZ"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "dim_tick_size" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMALTF"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "dim_alt_scale" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMLFAC"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "dim_linear_scale" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMTVP"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "dim_text_vertical_pos" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMTFAC"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "dim_tolerance_scale" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMGAP"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "dim_line_gap" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMALTRND"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "dim_alt_rounding" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMTOL"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "dim_tolerance" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$DIMLIM"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "dim_limits" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$DIMTIH"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "dim_text_inside_horizontal" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$DIMTOH"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "dim_text_outside_horizontal" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$DIMSE1"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "dim_suppress_ext1" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$DIMSE2"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "dim_suppress_ext2" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$DIMTAD"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_text_above" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMZIN"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_zero_suppression" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMAZIN"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_alt_zero_suppression" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMALT"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "dim_alternate_units" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$DIMALTD"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_alt_decimal_places" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMTOFL"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "dim_force_line_inside" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$DIMSAH"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "dim_separate_arrows" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$DIMTIX"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "dim_force_text_inside" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$DIMSOXD"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "dim_suppress_outside_ext" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$DIMCLRD"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_line_color" ] := Cl_FromIndex( v )
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMCLRE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_ext_line_color" ] := Cl_FromIndex( v )
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMCLRT"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_text_color" ] := Cl_FromIndex( v )
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMADEC"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_angular_decimal_places" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMDEC"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_decimal_places" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMTDEC"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_tolerance_decimal_places" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMALTU"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_alt_units_format" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMALTTD"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_alt_tolerance_decimal_places" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMAUNIT"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_angular_units" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMFRAC"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_fraction_format" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMLUNIT"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_linear_unit_format" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMDSEP"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_decimal_separator" ] := Chr( v % 256 )
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMTMOVE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_text_movement" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMJUST"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_horizontal_justification" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMSD1"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "dim_suppress_line1" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$DIMSD2"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "dim_suppress_line2" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$DIMTOLJ"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_tolerance_justification" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMTZIN"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_tolerance_zero_suppression" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMALTZ"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_alt_tolerance_zero_suppression" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMALTTZ"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_alt_tolerance_zero_tight" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMATFIT"
   CASE "$DIMFIT"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_fit" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMUPT"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "dim_user_positioned_text" ] := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      ENDIF
      EXIT
   CASE "$DIMPOST"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "dim_post" ] := Dp_AsString( p )
      ENDIF
      EXIT
   CASE "$DIMAPOST"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "dim_alt_post" ] := Dp_AsString( p )
      ENDIF
      EXIT
   CASE "$DIMBLK"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "dim_arrow_block" ] := Dp_AsString( p )
      ENDIF
      EXIT
   CASE "$DIMBLK1"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "dim_arrow_block1" ] := Dp_AsString( p )
      ENDIF
      EXIT
   CASE "$DIMBLK2"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "dim_arrow_block2" ] := Dp_AsString( p )
      ENDIF
      EXIT
   CASE "$DIMLDRBLK"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "dim_leader_arrow_block" ] := Dp_AsString( p )
      ENDIF
      EXIT
   CASE "$DIMLWD"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_line_weight" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$DIMLWE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "dim_ext_line_weight" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$CLAYER"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "current_layer_name" ] := Dp_AsString( p )
      ENDIF
      EXIT
   CASE "$CELTYPE"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "current_linetype_name" ] := Dp_AsString( p )
      ENDIF
      EXIT
   CASE "$TEXTSTYLE"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "current_text_style_name" ] := Dp_AsString( p )
      ENDIF
      EXIT
   CASE "$DIMSTYLE"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "current_dimstyle_name" ] := Dp_AsString( p )
      ENDIF
      EXIT
   CASE "$CMLSTYLE"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "multiline_style" ] := Dp_AsString( p )
      ENDIF
      EXIT
   CASE "$CTABLESTYLE"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "current_table_style_name" ] := Dp_AsString( p )
      ENDIF
      EXIT
   CASE "$CMLEADERSTYLE"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "current_mleader_style_name" ] := Dp_AsString( p )
      ENDIF
      EXIT
   CASE "$INSBASE"
      Sr_HeaderPoint( s, hdr[ "model_space_insertion_base" ], 3 )
      EXIT
   CASE "$EXTMIN"
      Sr_HeaderPoint( s, hdr[ "model_space_extents_min" ], 3 )
      EXIT
   CASE "$EXTMAX"
      Sr_HeaderPoint( s, hdr[ "model_space_extents_max" ], 3 )
      EXIT
   CASE "$LIMMIN"
      Sr_HeaderPoint( s, hdr[ "model_space_limits_min" ], 2 )
      EXIT
   CASE "$LIMMAX"
      Sr_HeaderPoint( s, hdr[ "model_space_limits_max" ], 2 )
      EXIT
   CASE "$PINSBASE"
      Sr_HeaderPoint( s, hdr[ "paper_space_insertion_base" ], 3 )
      EXIT
   CASE "$PEXTMIN"
      Sr_HeaderPoint( s, hdr[ "paper_space_extents_min" ], 3 )
      EXIT
   CASE "$PEXTMAX"
      Sr_HeaderPoint( s, hdr[ "paper_space_extents_max" ], 3 )
      EXIT
   CASE "$PLIMMIN"
      Sr_HeaderPoint( s, hdr[ "paper_space_limits_min" ], 2 )
      EXIT
   CASE "$PLIMMAX"
      Sr_HeaderPoint( s, hdr[ "paper_space_limits_max" ], 2 )
      EXIT
   CASE "$UCSBASE"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "ucs_base" ] := Dp_AsString( p )
      ENDIF
      EXIT
   CASE "$UCSNAME"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "model_space_ucs_name" ] := Dp_AsString( p )
      ENDIF
      EXIT
   CASE "$PUCSNAME"
      p := Sr_Next( s )
      IF p != NIL
         hdr[ "paper_space_ucs_name" ] := Dp_AsString( p )
      ENDIF
      EXIT
   CASE "$UCSORG"
      Sr_HeaderPoint( s, hdr[ "model_space_ucs_origin" ], 3 )
      EXIT
   CASE "$UCSXDIR"
      Sr_HeaderPoint( s, hdr[ "model_space_ucs_x_axis" ], 3 )
      EXIT
   CASE "$UCSYDIR"
      Sr_HeaderPoint( s, hdr[ "model_space_ucs_y_axis" ], 3 )
      EXIT
   CASE "$PUCSORG"
      Sr_HeaderPoint( s, hdr[ "paper_space_ucs_origin" ], 3 )
      EXIT
   CASE "$PUCSXDIR"
      Sr_HeaderPoint( s, hdr[ "paper_space_ucs_x_axis" ], 3 )
      EXIT
   CASE "$PUCSYDIR"
      Sr_HeaderPoint( s, hdr[ "paper_space_ucs_y_axis" ], 3 )
      EXIT
   CASE "$UCSORTHOVIEW"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "ucs_ortho_view" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$PUCSORTHOVIEW"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsI16( p )
         IF v != NIL
            hdr[ "paper_ucs_ortho_view" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$TDCREATE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "create_date_julian" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$TDUCREATE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "universal_create_date_julian" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$TDUPDATE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "update_date_julian" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$TDUUPDATE"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "universal_update_date_julian" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$TDINDWG"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "total_editing_time" ] := v
         ENDIF
      ENDIF
      EXIT
   CASE "$TDUSRTIMER"
      p := Sr_Next( s )
      IF p != NIL
         v := Dp_AsDouble( p )
         IF v != NIL
            hdr[ "user_elapsed_time" ] := v
         ENDIF
      ENDIF
      EXIT

      OTHERWISE
         Sr_SkipHeaderVariable( s )
      ENDSWITCH
   ENDDO
RETURN
