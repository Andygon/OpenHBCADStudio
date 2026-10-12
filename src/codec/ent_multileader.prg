/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_multileader.prg
   Origen Rust: opencadcodec/src/entities/multileader.rs (1559, 17 tests) + translate_multileader + transform_multileader. Licencia del original: MPL-2.0.
   Prefijos: Sep_ (StartEndPointPair), Llb_ (LeaderLineBreakInfo), Lln_ (LeaderLine), Lrt_ (LeaderRoot), Bat_ (BlockAttribute), Mao_ (MultiLeaderArrowheadOverride),
   Mac_ (MultiLeaderAnnotContext), Emu_ (MultiLeader, _type "MULTILEADER"), Mub_ (MultiLeaderBuilder: hash {"multileader"}, encadenable).
   Enums = enteros (MLC_*, MPT_*, TAT_*, TAN_*, BCC_*, TAD_*, TAP_*, TAL_*, FDT_*, LSS_* en ocx.ch) con funciones *_From (From<i16>). Flags = MPO_* y LLO_*.
   transform_matrix = array de 16 (base 1 en Harbour). Option<Handle> = NIL. Colors/LineWeight = Cl_ y Lw_.
   Rust: bounding_box inherente (Option<(min,max)>, nunca None porque incluye content_base_point) = Emu_BoundingBoxOpt; el del trait empieza en f64::MAX/MIN y
   siempre incluye content_base_point, asi que el resultado es el mismo empezando desde ese punto (no hay literal de f64::MAX en Harbour).
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Mlc_From( n ) ; RETURN iif( n == 0 .OR. n == 1 .OR. n == 2 .OR. n == 3, n, 0 )   /* From<i16> de LeaderContentType; por defecto 0 */
FUNCTION Mpt_From( n ) ; RETURN iif( n == 0 .OR. n == 1 .OR. n == 2, n, 1 )   /* From<i16> de MultiLeaderPathType; por defecto 1 */
FUNCTION Tat_From( n ) ; RETURN iif( n == 0 .OR. n == 1 .OR. n == 2 .OR. n == 3 .OR. n == 4 .OR. n == 5 .OR. n == 6 .OR. n == 7 .OR. n == 8 .OR. n == 9 .OR. n == 10, n, 2 )   /* From<i16> de TextAttachmentType; por defecto 2 */
FUNCTION Tan_From( n ) ; RETURN iif( n == 0 .OR. n == 1 .OR. n == 2, n, 1 )   /* From<i16> de TextAngleType; por defecto 1 */
FUNCTION Bcc_From( n ) ; RETURN iif( n == 0 .OR. n == 1, n, 0 )   /* From<i16> de BlockContentConnectionType; por defecto 0 */
FUNCTION Tad_From( n ) ; RETURN iif( n == 0 .OR. n == 1, n, 0 )   /* From<i16> de TextAttachmentDirectionType; por defecto 0 */
FUNCTION Tap_From( n ) ; RETURN iif( n == 1 .OR. n == 2 .OR. n == 3, n, 2 )   /* From<i16> de TextAttachmentPointType; por defecto 2 */
FUNCTION Tal_From( n ) ; RETURN iif( n == 0 .OR. n == 1 .OR. n == 2, n, 0 )   /* From<i16> de TextAlignmentType; por defecto 0 */
FUNCTION Fdt_From( n ) ; RETURN iif( n == 1 .OR. n == 3 .OR. n == 5, n, 1 )   /* From<i16> de FlowDirectionType; por defecto 1 */
FUNCTION Lss_From( n ) ; RETURN iif( n == 1 .OR. n == 2, n, 1 )   /* From<i16> de LineSpacingStyle; por defecto 1 */

FUNCTION Emu_EntityName() ; RETURN "MULTILEADER"

/* ---- StartEndPointPair ---- */
FUNCTION Sep_New( vS, vE ) ; RETURN hb_Hash( "start_point", vS, "end_point", vE )
FUNCTION Sep_Default() ; RETURN Sep_New( Vc3_Zero(), Vc3_Zero() )
FUNCTION Llb_New() ; RETURN hb_Hash( "segment_index", 0, "break_points", {} )

/* ---- LeaderLine ---- */
FUNCTION Lln_New( nIdx )
RETURN hb_Hash( "index", nIdx, "segment_index", 0, "points", {}, "break_points", {}, "break_info_count", 0, "break_infos", {}, "path_type", MPT_STRAIGHT_LINE_SEGMENTS, ;
   "line_color", Cl_ByBlock(), "line_type_handle", NIL, "line_weight", Lw_ByLayer(), "arrowhead_handle", NIL, "arrowhead_size", 0.18, "override_flags", LLO_NONE )
FUNCTION Lln_FromPoints( nIdx, aPts ) ; LOCAL l := Lln_New( nIdx ) ; l[ "points" ] := aPts ; RETURN l
FUNCTION Lln_AddPoint( l, v ) ; AAdd( l[ "points" ], v ) ; RETURN NIL
FUNCTION Lln_PointCount( l ) ; RETURN Len( l[ "points" ] )
FUNCTION Lln_StartPoint( l ) ; RETURN iif( Len( l[ "points" ] ) > 0, l[ "points" ][ 1 ], NIL )
FUNCTION Lln_EndPoint( l ) ; RETURN iif( Len( l[ "points" ] ) > 0, ATail( l[ "points" ] ), NIL )
FUNCTION Lln_Length( l )
   LOCAL a := l[ "points" ], n := 0.0, i
   IF Len( a ) < 2 ; RETURN 0.0 ; ENDIF
   FOR i := 1 TO Len( a ) - 1 ; n += Vc3_Length( Vc3_Sub( a[ i + 1 ], a[ i ] ) ) ; NEXT
RETURN n

/* ---- LeaderRoot ---- */
FUNCTION Lrt_New( nIdx )
RETURN hb_Hash( "leader_index", nIdx, "content_valid", .T., "unknown", .T., "connection_point", Vc3_Zero(), "direction", Vc3_New( 1.0, 0.0, 0.0 ), "break_points", {}, "lines", {}, ;
   "landing_distance", 0.36, "text_attachment_direction", TAD_HORIZONTAL )
FUNCTION Lrt_AddLine( r, l ) ; AAdd( r[ "lines" ], l ) ; RETURN NIL
FUNCTION Lrt_CreateLine( r, aPts )
   LOCAL l := Lln_FromPoints( Len( r[ "lines" ] ), aPts )
   AAdd( r[ "lines" ], l )
RETURN l
FUNCTION Lrt_LineCount( r ) ; RETURN Len( r[ "lines" ] )

/* ---- BlockAttribute ---- */
FUNCTION Bat_New( cText ) ; RETURN hb_Hash( "attribute_definition_handle", NIL, "index", 0, "width", 0.0, "text", cText )
FUNCTION Mao_New() ; RETURN hb_Hash( "index", 0, "is_default", .F., "arrowhead_handle", NIL )

/* ---- MultiLeaderAnnotContext ---- */
FUNCTION Mac_New()
   LOCAL m := { 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0 }
RETURN hb_Hash( "leader_roots", {}, "standalone_flags", 0, "standalone_uses_root_flags", .F., "scale_factor", 1.0, "content_base_point", Vc3_Zero(), "has_text_contents", .F., "text_string", "", ;
   "text_normal", Vc3_New( 0.0, 0.0, 1.0 ), "text_location", Vc3_Zero(), "text_direction", Vc3_New( 1.0, 0.0, 0.0 ), "text_rotation", 0.0, "text_height", 0.18, "text_width", 0.0, ;
   "text_boundary_height", 0.0, "line_spacing_factor", 1.0, "line_spacing_style", LSS_AT_LEAST, "text_color", Cl_ByBlock(), "text_attachment_point", TAP_CENTER, "text_flow_direction", FDT_HORIZONTAL, ;
   "text_alignment", TAL_LEFT, "text_left_attachment", TAT_MIDDLE_OF_TEXT, "text_right_attachment", TAT_MIDDLE_OF_TEXT, "text_top_attachment", TAT_CENTER_OF_TEXT, "text_bottom_attachment", TAT_CENTER_OF_TEXT, ;
   "text_height_automatic", .F., "word_break", .T., "dwg_unknown_text_bit", .F., "text_style_handle", NIL, "has_block_contents", .F., "block_content_handle", NIL, "block_content_normal", Vc3_New( 0.0, 0.0, 1.0 ), ;
   "block_content_location", Vc3_Zero(), "block_content_scale", Vc3_New( 1.0, 1.0, 1.0 ), "block_rotation", 0.0, "block_content_color", Cl_ByBlock(), "block_connection_type", BCC_BLOCK_EXTENTS, ;
   "column_type", 0, "column_width", 0.0, "column_gutter", 0.0, "column_flow_reversed", .F., "column_sizes", {}, "background_fill_enabled", .F., "background_mask_fill_on", .F., ;
   "background_fill_color", Cl_ByBlock(), "background_scale_factor", 1.5, "background_transparency", 0, "base_point", Vc3_Zero(), "base_direction", Vc3_New( 1.0, 0.0, 0.0 ), "base_vertical", Vc3_New( 0.0, 1.0, 0.0 ), ;
   "normal_reversed", .F., "arrowhead_size", 0.18, "landing_gap", 0.09, "transform_matrix", m, "scale_handle", NIL )
FUNCTION Mac_AddLeaderRoot( c )
   LOCAL r := Lrt_New( Len( c[ "leader_roots" ] ) )
   AAdd( c[ "leader_roots" ], r )
RETURN r
FUNCTION Mac_LeaderRootCount( c ) ; RETURN Len( c[ "leader_roots" ] )
FUNCTION Mac_SetTextContent( c, cText, vLoc ) ; c[ "has_text_contents" ] := .T. ; c[ "text_string" ] := cText ; c[ "text_location" ] := vLoc ; c[ "content_base_point" ] := vLoc ; RETURN NIL
FUNCTION Mac_SetBlockContent( c, h, vLoc ) ; c[ "has_block_contents" ] := .T. ; c[ "block_content_handle" ] := h ; c[ "block_content_location" ] := vLoc ; c[ "content_base_point" ] := vLoc ; RETURN NIL

/* ---- MultiLeader ---- */
FUNCTION Emu_New()
RETURN hb_Hash( "_type", "MULTILEADER", "common", Ec_New(), "dwg_version", 2, "style_handle", NIL, "content_type", MLC_MTEXT, "context", Mac_New(), "block_attributes", {}, "arrowhead_overrides", {}, ;
   "path_type", MPT_STRAIGHT_LINE_SEGMENTS, "line_color", Cl_ByBlock(), "line_type_handle", NIL, "line_weight", Lw_ByLayer(), "enable_landing", .T., "enable_dogleg", .T., "dogleg_length", 0.36, ;
   "arrowhead_handle", NIL, "arrowhead_size", 0.18, "text_style_handle", NIL, "text_color", Cl_ByBlock(), "text_frame", .F., "text_height", 0.18, "text_left_attachment", TAT_MIDDLE_OF_TEXT, ;
   "text_right_attachment", TAT_MIDDLE_OF_TEXT, "text_top_attachment", TAT_CENTER_OF_TEXT, "text_bottom_attachment", TAT_CENTER_OF_TEXT, "text_attachment_direction", TAD_HORIZONTAL, ;
   "text_attachment_point", TAP_CENTER, "text_alignment", TAL_LEFT, "text_angle_type", TAN_HORIZONTAL, "text_direction_negative", .F., "text_align_in_ipe", 0, "block_content_handle", NIL, ;
   "block_content_color", Cl_ByBlock(), "block_connection_type", BCC_BLOCK_EXTENTS, "block_rotation", 0.0, "block_scale", Vc3_New( 1.0, 1.0, 1.0 ), "scale_factor", 1.0, ;
   "property_override_flags", MPO_NONE, "enable_annotation_scale", .F., "extend_leader_to_text", .F. )
FUNCTION Emu_WithText( cText, vLoc, aLeaderPts )
   LOCAL e := Emu_New(), r
   Emu_SetTextContent( e, cText, vLoc )
   r := Emu_AddLeaderRoot( e ) ; r[ "connection_point" ] := vLoc
   IF Len( aLeaderPts ) > 0 ; Lrt_CreateLine( r, aLeaderPts ) ; ENDIF
RETURN e
FUNCTION Emu_SetTextContent( e, cText, vLoc ) ; e[ "content_type" ] := MLC_MTEXT ; Mac_SetTextContent( e[ "context" ], cText, vLoc ) ; RETURN NIL
FUNCTION Emu_SetBlockContent( e, h, vLoc ) ; e[ "content_type" ] := MLC_BLOCK ; e[ "block_content_handle" ] := h ; Mac_SetBlockContent( e[ "context" ], h, vLoc ) ; RETURN NIL
FUNCTION Emu_AddLeaderRoot( e ) ; RETURN Mac_AddLeaderRoot( e[ "context" ] )
FUNCTION Emu_LeaderRootCount( e ) ; RETURN Mac_LeaderRootCount( e[ "context" ] )
FUNCTION Emu_TotalLeaderLineCount( e )
   LOCAL n := 0, r
   FOR EACH r IN e[ "context" ][ "leader_roots" ] ; n += Lrt_LineCount( r ) ; NEXT
RETURN n
/* Option<&str>: NIL si None */
FUNCTION Emu_Text( e ) ; RETURN iif( e[ "content_type" ] == MLC_MTEXT .AND. e[ "context" ][ "has_text_contents" ], e[ "context" ][ "text_string" ], NIL )
FUNCTION Emu_SetText( e, cText )
   IF e[ "content_type" ] == MLC_MTEXT
      e[ "context" ][ "text_string" ] := cText ; e[ "context" ][ "has_text_contents" ] := .T.
   ENDIF
RETURN NIL
STATIC FUNCTION AddBp( aBp, vOff )
   LOCAL b
   FOR EACH b IN aBp
      b[ "start_point" ] := Vc3_Add( b[ "start_point" ], vOff ) ; b[ "end_point" ] := Vc3_Add( b[ "end_point" ], vOff )
   NEXT
RETURN NIL
FUNCTION Emu_Translate( e, vOff )
   LOCAL c := e[ "context" ], r, l, i
   c[ "content_base_point" ] := Vc3_Add( c[ "content_base_point" ], vOff ) ; c[ "text_location" ] := Vc3_Add( c[ "text_location" ], vOff )
   c[ "block_content_location" ] := Vc3_Add( c[ "block_content_location" ], vOff ) ; c[ "base_point" ] := Vc3_Add( c[ "base_point" ], vOff )
   FOR EACH r IN c[ "leader_roots" ]
      r[ "connection_point" ] := Vc3_Add( r[ "connection_point" ], vOff ) ; AddBp( r[ "break_points" ], vOff )
      FOR EACH l IN r[ "lines" ]
         FOR i := 1 TO Len( l[ "points" ] ) ; l[ "points" ][ i ] := Vc3_Add( l[ "points" ][ i ], vOff ) ; NEXT
         AddBp( l[ "break_points" ], vOff )
      NEXT
   NEXT
RETURN NIL
FUNCTION Emu_BoundingBoxOpt( e )
   LOCAL aP := { e[ "context" ][ "content_base_point" ] }, r, l, p, vMin, vMax, i
   FOR EACH r IN e[ "context" ][ "leader_roots" ]
      AAdd( aP, r[ "connection_point" ] )
      FOR EACH l IN r[ "lines" ]
         FOR EACH p IN l[ "points" ] ; AAdd( aP, p ) ; NEXT
      NEXT
   NEXT
   vMin := AClone( aP[ 1 ] ) ; vMax := AClone( aP[ 1 ] )
   FOR i := 2 TO Len( aP )
      vMin := { Min( vMin[ 1 ], aP[ i ][ 1 ] ), Min( vMin[ 2 ], aP[ i ][ 2 ] ), Min( vMin[ 3 ], aP[ i ][ 3 ] ) }
      vMax := { Max( vMax[ 1 ], aP[ i ][ 1 ] ), Max( vMax[ 2 ], aP[ i ][ 2 ] ), Max( vMax[ 3 ], aP[ i ][ 3 ] ) }
   NEXT
RETURN { vMin, vMax }
/* Entity::bounding_box: solo usa content_base_point y los puntos de las lineas (no connection_point) */
FUNCTION Emu_BoundingBox( e )
   LOCAL aP := { e[ "context" ][ "content_base_point" ] }, r, l, p, vMin, vMax, i
   FOR EACH r IN e[ "context" ][ "leader_roots" ]
      FOR EACH l IN r[ "lines" ]
         FOR EACH p IN l[ "points" ] ; AAdd( aP, p ) ; NEXT
      NEXT
   NEXT
   vMin := AClone( aP[ 1 ] ) ; vMax := AClone( aP[ 1 ] )
   FOR i := 2 TO Len( aP )
      vMin := { Min( vMin[ 1 ], aP[ i ][ 1 ] ), Min( vMin[ 2 ], aP[ i ][ 2 ] ), Min( vMin[ 3 ], aP[ i ][ 3 ] ) }
      vMax := { Max( vMax[ 1 ], aP[ i ][ 1 ] ), Max( vMax[ 2 ], aP[ i ][ 2 ] ), Max( vMax[ 3 ], aP[ i ][ 3 ] ) }
   NEXT
RETURN Bb3_New( vMin, vMax )
STATIC FUNCTION TfBp( aBp, t )
   LOCAL b
   FOR EACH b IN aBp
      b[ "start_point" ] := Tf_Apply( t, b[ "start_point" ] ) ; b[ "end_point" ] := Tf_Apply( t, b[ "end_point" ] )
   NEXT
RETURN NIL
FUNCTION Emu_Transform( e, t )
   LOCAL c := e[ "context" ], r, l, i, nS
   c[ "content_base_point" ] := Tf_Apply( t, c[ "content_base_point" ] ) ; c[ "text_location" ] := Tf_Apply( t, c[ "text_location" ] )
   c[ "block_content_location" ] := Tf_Apply( t, c[ "block_content_location" ] ) ; c[ "base_point" ] := Tf_Apply( t, c[ "base_point" ] )
   c[ "text_normal" ] := Vc3_Normalize( Tf_ApplyRotation( t, c[ "text_normal" ] ) ) ; c[ "text_direction" ] := Vc3_Normalize( Tf_ApplyRotation( t, c[ "text_direction" ] ) )
   c[ "base_direction" ] := Vc3_Normalize( Tf_ApplyRotation( t, c[ "base_direction" ] ) ) ; c[ "base_vertical" ] := Vc3_Normalize( Tf_ApplyRotation( t, c[ "base_vertical" ] ) )
   FOR EACH r IN c[ "leader_roots" ]
      r[ "connection_point" ] := Tf_Apply( t, r[ "connection_point" ] ) ; TfBp( r[ "break_points" ], t )
      FOR EACH l IN r[ "lines" ]
         FOR i := 1 TO Len( l[ "points" ] ) ; l[ "points" ][ i ] := Tf_Apply( t, l[ "points" ][ i ] ) ; NEXT
         TfBp( l[ "break_points" ], t )
      NEXT
   NEXT
   nS := Vc3_Length( Tf_ApplyRotation( t, Vc3_New( 1.0, 0.0, 0.0 ) ) )
   e[ "arrowhead_size" ] *= nS ; e[ "text_height" ] *= nS ; e[ "dogleg_length" ] *= nS
   c[ "arrowhead_size" ] *= nS ; c[ "text_height" ] *= nS ; c[ "landing_gap" ] *= nS
RETURN NIL

/* ---- MultiLeaderBuilder ---- */
FUNCTION Mub_New() ; RETURN hb_Hash( "multileader", Emu_New() )
FUNCTION Mub_Text( b, cText, vLoc ) ; Emu_SetTextContent( b[ "multileader" ], cText, vLoc ) ; RETURN b
FUNCTION Mub_Block( b, h, vLoc ) ; Emu_SetBlockContent( b[ "multileader" ], h, vLoc ) ; RETURN b
FUNCTION Mub_NoContent( b ) ; b[ "multileader" ][ "content_type" ] := MLC_NONE ; RETURN b
FUNCTION Mub_LeaderLine( b, aPts )
   LOCAL m := b[ "multileader" ]
   IF Len( m[ "context" ][ "leader_roots" ] ) == 0 ; Emu_AddLeaderRoot( m ) ; ENDIF
   Lrt_CreateLine( ATail( m[ "context" ][ "leader_roots" ] ), aPts )
RETURN b
FUNCTION Mub_NewRoot( b ) ; Emu_AddLeaderRoot( b[ "multileader" ] ) ; RETURN b
FUNCTION Mub_PathType( b, n ) ; b[ "multileader" ][ "path_type" ] := n ; RETURN b
FUNCTION Mub_ArrowheadSize( b, n ) ; b[ "multileader" ][ "arrowhead_size" ] := n ; b[ "multileader" ][ "context" ][ "arrowhead_size" ] := n ; RETURN b
FUNCTION Mub_TextHeight( b, n ) ; b[ "multileader" ][ "text_height" ] := n ; b[ "multileader" ][ "context" ][ "text_height" ] := n ; RETURN b
FUNCTION Mub_TextFrame( b, l ) ; b[ "multileader" ][ "text_frame" ] := l ; RETURN b
FUNCTION Mub_LineColor( b, c ) ; b[ "multileader" ][ "line_color" ] := c ; RETURN b
FUNCTION Mub_TextColor( b, c ) ; b[ "multileader" ][ "text_color" ] := c ; b[ "multileader" ][ "context" ][ "text_color" ] := c ; RETURN b
FUNCTION Mub_Landing( b, l ) ; b[ "multileader" ][ "enable_landing" ] := l ; RETURN b
FUNCTION Mub_DoglegLength( b, n ) ; b[ "multileader" ][ "dogleg_length" ] := n ; RETURN b
FUNCTION Mub_Scale( b, n ) ; b[ "multileader" ][ "scale_factor" ] := n ; b[ "multileader" ][ "context" ][ "scale_factor" ] := n ; RETURN b
FUNCTION Mub_Build( b ) ; RETURN b[ "multileader" ]
