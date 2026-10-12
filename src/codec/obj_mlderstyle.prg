/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/obj_mlderstyle.prg
   Origen Rust: opencadcodec/src/objects/multileader_style.rs (925 lineas, 20 tests). Licencia del original: MPL-2.0.
   Prefijo: Mst_ (MultiLeaderStyle) y constantes MST_* en ocx.ch (enums i16 y flags i32 generados del Rust, 70 constantes):
     MST_CT_ LeaderContentType, MST_PT_ MultiLeaderPathType, MST_TA_ TextAttachmentType, MST_TD_ TextAttachmentDirectionType,
     MST_TL_ TextAlignmentType, MST_TG_ TextAngleType, MST_BC_ BlockContentConnectionType, MST_LD_ LeaderDrawOrderType,
     MST_MD_ MultiLeaderDrawOrderType, MST_PO_ MultiLeaderPropertyOverrideFlags, MST_LL_ LeaderLinePropertyOverrideFlags.
   Los From<i16> de cada enum son Mst_*From. Los flags son enteros; contains(f) = hb_bitAnd(flags, f) == f.
   Estos enums son los de objects/ y NO son los homonimos de entities/multileader (ent_multileader.prg, Mlc_*): valores distintos.
   Color -> Cl_ByBlock(), LineWeight -> Lw_ByBlock(). to_radians/to_degrees con OCX_PI.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Mst_ContentTypeFrom( n ) ; RETURN iif( n >= 0 .AND. n <= 3, n, MST_CT_MTEXT )
FUNCTION Mst_PathTypeFrom( n ) ; RETURN iif( n >= 0 .AND. n <= 2, n, MST_PT_STRAIGHT_LINE_SEGMENTS )
FUNCTION Mst_TextAttachmentFrom( n ) ; RETURN iif( n >= 0 .AND. n <= 10, n, MST_TA_MIDDLE_OF_TOP_LINE )
FUNCTION Mst_AttachmentDirectionFrom( n ) ; RETURN iif( n == 1, MST_TD_VERTICAL, MST_TD_HORIZONTAL )
FUNCTION Mst_TextAlignmentFrom( n ) ; RETURN iif( n >= 0 .AND. n <= 2, n, MST_TL_LEFT )
FUNCTION Mst_TextAngleFrom( n ) ; RETURN iif( n >= 0 .AND. n <= 2, n, MST_TG_HORIZONTAL )
FUNCTION Mst_BlockConnectionFrom( n ) ; RETURN iif( n == 1, MST_BC_BASE_POINT, MST_BC_BLOCK_EXTENTS )
FUNCTION Mst_LeaderDrawOrderFrom( n ) ; RETURN iif( n == 1, MST_LD_LEADER_TAIL_FIRST, MST_LD_LEADER_HEAD_FIRST )
FUNCTION Mst_MultiLeaderDrawOrderFrom( n ) ; RETURN iif( n == 1, MST_MD_LEADER_FIRST, MST_MD_CONTENT_FIRST )

FUNCTION Mst_ObjectName() ; RETURN "MLEADERSTYLE"
FUNCTION Mst_SubclassMarker() ; RETURN "AcDbMLeaderStyle"
FUNCTION Mst_StandardName() ; RETURN "Standard"

FUNCTION Mst_New( cName )
RETURN hb_Hash( "_type", "MultiLeaderStyle", "handle", Hd_Null(), "owner_handle", Hd_Null(), "name", cName, "description", "", ;
   "path_type", MST_PT_STRAIGHT_LINE_SEGMENTS, "line_color", Cl_ByBlock(), "line_type_handle", NIL, "line_weight", Lw_ByBlock(), ;
   "enable_landing", .T., "enable_dogleg", .T., "landing_distance", 0.36, "landing_gap", 0.09, ;
   "arrowhead_handle", NIL, "arrowhead_size", 0.18, "content_type", MST_CT_MTEXT, "text_style_handle", NIL, ;
   "text_left_attachment", MST_TA_MIDDLE_OF_TOP_LINE, "text_right_attachment", MST_TA_MIDDLE_OF_TOP_LINE, ;
   "text_top_attachment", MST_TA_TOP_OF_TOP_LINE, "text_bottom_attachment", MST_TA_BOTTOM_OF_BOTTOM_LINE, ;
   "text_attachment_direction", MST_TD_HORIZONTAL, "text_angle_type", MST_TG_HORIZONTAL, "text_alignment", MST_TL_LEFT, ;
   "text_color", Cl_ByBlock(), "text_height", 0.18, "text_frame", .F., "text_always_left", .F., "default_text", "", ;
   "block_content_handle", NIL, "block_content_color", Cl_ByBlock(), "block_content_connection", MST_BC_BLOCK_EXTENTS, "block_content_rotation", 0.0, ;
   "block_content_scale_x", 1.0, "block_content_scale_y", 1.0, "block_content_scale_z", 1.0, "enable_block_scale", .F., "enable_block_rotation", .F., ;
   "scale_factor", 1.0, "align_space", 0.0, "break_gap_size", 0.125, "max_leader_points", 2, "first_segment_angle", 0.0, "second_segment_angle", 0.0, ;
   "leader_draw_order", MST_LD_LEADER_HEAD_FIRST, "multileader_draw_order", MST_MD_CONTENT_FIRST, ;
   "is_annotative", .F., "property_changed", .F., "unknown_flag_298", .F. )

FUNCTION Mst_Standard() ; RETURN Mst_New( Mst_StandardName() )
FUNCTION Mst_Default() ; RETURN Mst_Standard()

PROCEDURE Mst_SetBlockScale( s, n )
   s[ "block_content_scale_x" ] := n
   s[ "block_content_scale_y" ] := n
   s[ "block_content_scale_z" ] := n
RETURN

FUNCTION Mst_UniformBlockScale( s )
   IF Abs( s[ "block_content_scale_x" ] - s[ "block_content_scale_y" ] ) < 0.0000000001 .AND. Abs( s[ "block_content_scale_y" ] - s[ "block_content_scale_z" ] ) < 0.0000000001
      RETURN s[ "block_content_scale_x" ]
   ENDIF
RETURN NIL

PROCEDURE Mst_SetBlockRotationDegrees( s, n ) ; s[ "block_content_rotation" ] := n * OCX_PI / 180.0 ; RETURN
FUNCTION Mst_BlockRotationDegrees( s ) ; RETURN s[ "block_content_rotation" ] * 180.0 / OCX_PI
FUNCTION Mst_HasTextContent( s ) ; RETURN s[ "content_type" ] == MST_CT_MTEXT
FUNCTION Mst_HasBlockContent( s ) ; RETURN s[ "content_type" ] == MST_CT_BLOCK
FUNCTION Mst_HasToleranceContent( s ) ; RETURN s[ "content_type" ] == MST_CT_TOLERANCE
FUNCTION Mst_HasVisibleLeaders( s ) ; RETURN s[ "path_type" ] != MST_PT_INVISIBLE
FUNCTION Mst_HasSplineLeaders( s ) ; RETURN s[ "path_type" ] == MST_PT_SPLINE
FUNCTION Mst_FlagsContain( nFlags, nFlag ) ; RETURN hb_bitAnd( nFlags, nFlag ) == nFlag
