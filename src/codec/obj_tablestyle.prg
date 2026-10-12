/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/obj_tablestyle.prg
   Origen Rust: opencadcodec/src/objects/table_style.rs (1124 lineas, 29 tests). Licencia del original: MPL-2.0.
   Prefijo: Tbsy_ (Tst_ lo usa tb_style.prg) ; constantes TST_* en ocx.ch (generadas del Rust): TST_FD_ TableFlowDirection, TST_CA_ CellAlignment, TST_BT_ TableBorderType,
   TST_CP_ TableCellStylePropertyFlags, TST_BP_ TableBorderPropertyFlags, TST_SF_ TableStyleFlags (flags = enteros; contains = hb_bitAnd).
   Structs como hashes con los nombres Rust: TableCellBorder (Tbsy_Border*), RowCellStyle (Tbsy_Row*), TableContentFormat, TableGridFormat,
   TableCellStyleData, NamedTableCellStyle (los tres con constructor Default), TableStyle (Tbsy_New / Tbsy_Standard / Tbsy_Default).
   Option -> NIL; tuplas (i32, NamedTableCellStyle) de modern_overrides -> { id, cell }.
   NO portadas todavia (dependen de CadDocument, que aun no esta portado): restore_table_style_roundtrip y store_table_style_roundtrip
   (junto con las constantes CELL_STYLE_MAP_KEY, ROUNDTRIP_RECORD_KEY, PRE2007_MARKER). Se portan con CadDocument.
   Color -> arrays Cl_*; LineWeight -> Lw_*.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Tbsy_FlowDirectionFrom( n ) ; RETURN iif( n == 1, TST_FD_UP, TST_FD_DOWN )
FUNCTION Tbsy_CellAlignmentFrom( n ) ; RETURN iif( n >= 1 .AND. n <= 9, n, TST_CA_MIDDLE_CENTER )
FUNCTION Tbsy_BorderTypeFrom( n ) ; RETURN iif( n == 2, TST_BT_DOUBLE, TST_BT_SINGLE )

FUNCTION Tbsy_CaIsTop( n ) ; RETURN n >= 1 .AND. n <= 3
FUNCTION Tbsy_CaIsMiddle( n ) ; RETURN n >= 4 .AND. n <= 6
FUNCTION Tbsy_CaIsBottom( n ) ; RETURN n >= 7 .AND. n <= 9
FUNCTION Tbsy_CaIsLeft( n ) ; RETURN n == TST_CA_TOP_LEFT .OR. n == TST_CA_MIDDLE_LEFT .OR. n == TST_CA_BOTTOM_LEFT
FUNCTION Tbsy_CaIsCenter( n ) ; RETURN n == TST_CA_TOP_CENTER .OR. n == TST_CA_MIDDLE_CENTER .OR. n == TST_CA_BOTTOM_CENTER
FUNCTION Tbsy_CaIsRight( n ) ; RETURN n == TST_CA_TOP_RIGHT .OR. n == TST_CA_MIDDLE_RIGHT .OR. n == TST_CA_BOTTOM_RIGHT

FUNCTION Tbsy_FlagsContain( nFlags, nFlag ) ; RETURN hb_bitAnd( nFlags, nFlag ) == nFlag

/* ---- TableCellBorder ---- */
FUNCTION Tbsy_BorderNew()
RETURN hb_Hash( "property_flags", TST_BP_NONE, "border_type", TST_BT_SINGLE, "line_weight", Lw_ByBlock(), "color", Cl_ByBlock(), "is_invisible", .F., "double_line_spacing", 0.0 )
FUNCTION Tbsy_BorderDefault() ; RETURN Tbsy_BorderNew()
FUNCTION Tbsy_BorderInvisible()
   LOCAL b := Tbsy_BorderNew()
   b[ "is_invisible" ] := .T.
RETURN b
FUNCTION Tbsy_BorderWithStyle( aColor, aLineWeight )
   LOCAL b := Tbsy_BorderNew()
   b[ "color" ] := aColor
   b[ "line_weight" ] := aLineWeight
RETURN b

/* ---- RowCellStyle ---- */
FUNCTION Tbsy_RowNew()
RETURN hb_Hash( "text_style_name", "Standard", "text_style_handle", NIL, "text_height", 0.18, "alignment", TST_CA_MIDDLE_CENTER, "text_color", Cl_ByBlock(), ;
   "fill_color", Cl_Index( 7 ), "fill_enabled", .F., "data_type", 512, "unit_type", 0, "format_string", "", ;
   "left_border", Tbsy_BorderNew(), "right_border", Tbsy_BorderNew(), "top_border", Tbsy_BorderNew(), "bottom_border", Tbsy_BorderNew(), ;
   "horizontal_inside_border", Tbsy_BorderNew(), "vertical_inside_border", Tbsy_BorderNew() )
FUNCTION Tbsy_RowDefault() ; RETURN Tbsy_RowNew()
FUNCTION Tbsy_DataRow()
   LOCAL r := Tbsy_RowNew()
   r[ "text_height" ] := 0.18 ; r[ "alignment" ] := TST_CA_MIDDLE_CENTER
RETURN r
FUNCTION Tbsy_HeaderRow()
   LOCAL r := Tbsy_RowNew()
   r[ "text_height" ] := 0.25 ; r[ "alignment" ] := TST_CA_TOP_CENTER
RETURN r
FUNCTION Tbsy_TitleRow()
   LOCAL r := Tbsy_RowNew()
   r[ "text_height" ] := 0.25 ; r[ "alignment" ] := TST_CA_TOP_CENTER
RETURN r

PROCEDURE Tbsy_RowSetAllBorders( r, b )
   r[ "left_border" ] := Ent_Clone( b )
   r[ "right_border" ] := Ent_Clone( b )
   r[ "top_border" ] := Ent_Clone( b )
   r[ "bottom_border" ] := Ent_Clone( b )
   r[ "horizontal_inside_border" ] := Ent_Clone( b )
   r[ "vertical_inside_border" ] := b
RETURN
PROCEDURE Tbsy_RowSetAllBordersInvisible( r ) ; Tbsy_RowSetAllBorders( r, Tbsy_BorderInvisible() ) ; RETURN

/* ---- TableContentFormat / TableGridFormat / TableCellStyleData / NamedTableCellStyle (Default) ---- */
FUNCTION Tbsy_ContentFormatDefault()
RETURN hb_Hash( "property_override_flags", 0, "property_flags", 0, "value_data_type", 512, "value_unit_type", 0, "value_format_string", "", "rotation", 0.0, "block_scale", 1.0, ;
   "cell_alignment", 5, "content_color", Cl_ByBlock(), "text_style", Hd_Null(), "text_height", 0.18 )
FUNCTION Tbsy_GridFormatDefault() ; RETURN hb_Hash( "index_mask", 0, "border", Tbsy_BorderDefault(), "line_type", Hd_Null() )
FUNCTION Tbsy_CellStyleDataDefault()
RETURN hb_Hash( "style_type", 0, "data_flags", 0, "property_override_flags", 0, "merge_flags", 0, "background_color", Cl_Default(), "content_layout", 0, ;
   "content_format", Tbsy_ContentFormatDefault(), "margin_override_flags", 0, "vertical_margin", 0.0, "horizontal_margin", 0.0, "bottom_margin", 0.0, "right_margin", 0.0, ;
   "horizontal_spacing", 0.0, "vertical_spacing", 0.0, "borders", {} )
FUNCTION Tbsy_NamedCellStyleDefault() ; RETURN hb_Hash( "cell_style", Tbsy_CellStyleDataDefault(), "id", 0, "style_type", 0, "name", "" )

/* ---- TableStyle ---- */
FUNCTION Tbsy_ObjectName() ; RETURN "TABLESTYLE"
FUNCTION Tbsy_SubclassMarker() ; RETURN "AcDbTableStyle"
FUNCTION Tbsy_StandardName() ; RETURN "Standard"

FUNCTION Tbsy_New( cName )
RETURN hb_Hash( "_type", "TableStyle", "handle", Hd_Null(), "owner_handle", Hd_Null(), "name", cName, "description", "", "version", 0, "flow_direction", TST_FD_DOWN, ;
   "flags", TST_SF_NONE, "horizontal_margin", 0.06, "vertical_margin", 0.06, "title_suppressed", .F., "header_suppressed", .F., ;
   "data_row_style", Tbsy_DataRow(), "header_row_style", Tbsy_HeaderRow(), "title_row_style", Tbsy_TitleRow(), ;
   "modern_unknown_byte", 0, "modern_unknown_long1", 8, "modern_unknown_long2", 101, "modern_cell_style_handle", Hd_Null(), "modern_style", NIL, "modern_overrides", {}, ;
   "annotative", .F., "raw_dxf_codes", NIL )
FUNCTION Tbsy_Standard() ; RETURN Tbsy_New( Tbsy_StandardName() )
FUNCTION Tbsy_Default() ; RETURN Tbsy_Standard()

PROCEDURE Tbsy_SetMargins( s, n ) ; s[ "horizontal_margin" ] := n ; s[ "vertical_margin" ] := n ; RETURN
PROCEDURE Tbsy_SetAllTextHeights( s, n )
   s[ "data_row_style" ][ "text_height" ] := n ; s[ "header_row_style" ][ "text_height" ] := n ; s[ "title_row_style" ][ "text_height" ] := n
RETURN
PROCEDURE Tbsy_SetAllTextStyles( s, cName, nHandle )
   LOCAL k
   FOR EACH k IN { "data_row_style", "header_row_style", "title_row_style" }
      s[ k ][ "text_style_name" ] := cName
      s[ k ][ "text_style_handle" ] := nHandle
   NEXT
RETURN
PROCEDURE Tbsy_SetAllTextColors( s, aColor )
   s[ "data_row_style" ][ "text_color" ] := aColor ; s[ "header_row_style" ][ "text_color" ] := aColor ; s[ "title_row_style" ][ "text_color" ] := aColor
RETURN
PROCEDURE Tbsy_SetAllFillColors( s, aColor )
   s[ "data_row_style" ][ "fill_color" ] := aColor ; s[ "header_row_style" ][ "fill_color" ] := aColor ; s[ "title_row_style" ][ "fill_color" ] := aColor
RETURN
PROCEDURE Tbsy_SetAllFillEnabled( s, l )
   s[ "data_row_style" ][ "fill_enabled" ] := l ; s[ "header_row_style" ][ "fill_enabled" ] := l ; s[ "title_row_style" ][ "fill_enabled" ] := l
RETURN
FUNCTION Tbsy_HasTitleRow( s ) ; RETURN ! s[ "title_suppressed" ]
FUNCTION Tbsy_HasHeaderRow( s ) ; RETURN ! s[ "header_suppressed" ]
PROCEDURE Tbsy_SetTitleVisible( s, l ) ; s[ "title_suppressed" ] := ! l ; RETURN
PROCEDURE Tbsy_SetHeaderVisible( s, l ) ; s[ "header_suppressed" ] := ! l ; RETURN
