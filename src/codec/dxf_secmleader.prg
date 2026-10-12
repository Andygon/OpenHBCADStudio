/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/dxf_secmleader.prg
   Origen Rust: opencadcodec/src/io/dxf/reader/section_reader.rs: read_multileader, read_mleader_context, read_mleader_leader_root, read_mleader_leader_line, color_from_i32, append_hex_bytes.
   Fichero aparte (el editor web de GitHub no soporta bien dxf_secsections.prg por tamano). Licencia del original: MPL-2.0.
----------------------------------------------------------------------------*/
#include "ocx.ch"
#define DP_CODE 1
#define DP_VALUE 3

/* color_from_i32 (lector MLEADER): byte alto = metodo (C0 ByLayer, C1 ByBlock, C2 RGB, C3 indice, C8 None) */
FUNCTION Sr_McColor( v )
   LOCAL u := IIf( v < 0, v + 4294967296, v ), nM := hb_bitAnd( Int( u / 16777216 ), 255 )
   DO CASE
   CASE nM == 192 ; RETURN Cl_ByLayer()
   CASE nM == 193 ; RETURN Cl_ByBlock()
   CASE nM == 194 ; RETURN Cl_FromRgb( hb_bitAnd( Int( u / 65536 ), 255 ), hb_bitAnd( Int( u / 256 ), 255 ), hb_bitAnd( u, 255 ) )
   CASE nM == 195 ; RETURN Cl_FromIndex( hb_bitAnd( u, 255 ) )
   CASE nM == 200 ; RETURN Cl_None()
   ENDCASE
   DO CASE
   CASE v == 0 ; RETURN Cl_ByBlock()
   CASE v == 256 ; RETURN Cl_ByLayer()
   CASE v >= 1 .AND. v <= 255 ; RETURN Cl_FromIndex( v )
   ENDCASE
RETURN Cl_FromRgb( hb_bitAnd( hb_bitShift( v, -16 ), 255 ), hb_bitAnd( hb_bitShift( v, -8 ), 255 ), hb_bitAnd( v, 255 ) )

/* append_hex_bytes: bytes como cadena */
FUNCTION Sr_AppendHex( cTarget, cVal )
   LOCAL c := AllTrim( cVal ), i := 1, a, b
   DO WHILE i + 1 <= Len( c )
      a := At( Upper( SubStr( c, i, 1 ) ), "0123456789ABCDEF" ) ; b := At( Upper( SubStr( c, i + 1, 1 ) ), "0123456789ABCDEF" )
      IF a > 0 .AND. b > 0 ; cTarget += Chr( ( a - 1 ) * 16 + ( b - 1 ) ) ; ENDIF
      i += 2
   ENDDO
RETURN cTarget

FUNCTION Sr_McHandleNZ( p )
   LOCAL h := Sr_HexVal( p )
RETURN IIf( h != NIL .AND. h != 0, h, NIL )

/* read_mleader_leader_line */
FUNCTION Sr_ReadMlLine( s, nIdx )
   LOCAL l := Lln_FromPoints( nIdx, {} ), p, n, v, rBs := PR_New(), rBe := PR_New(), nSeg := NIL, aCur := {}, a, b, nL, bi
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      n := p[ DP_CODE ]
      IF n == 305 ; EXIT ; ENDIF
      DO CASE
      CASE n == 10
         v := Dp_AsDouble( p ) ; IF v != NIL ; AAdd( l[ "points" ], Vc3_New( v, 0.0, 0.0 ) ) ; ENDIF
      CASE n == 20
         v := Dp_AsDouble( p ) ; nL := Len( l[ "points" ] ) ; IF v != NIL .AND. nL > 0 ; l[ "points" ][ nL ][ 2 ] := v ; ENDIF
      CASE n == 30
         v := Dp_AsDouble( p ) ; nL := Len( l[ "points" ] ) ; IF v != NIL .AND. nL > 0 ; l[ "points" ][ nL ][ 3 ] := v ; ENDIF
      CASE n == 90
         v := Dp_AsI32( p )
         IF v != NIL
            a := PR_GetPoint( rBs ) ; b := PR_GetPoint( rBe )
            IF a != NIL .AND. b != NIL ; AAdd( aCur, Sep_New( a, b ) ) ; ENDIF
            PR_Reset( rBs ) ; PR_Reset( rBe )
            IF nSeg != NIL
               bi := Llb_New() ; bi[ "segment_index" ] := nSeg ; bi[ "break_points" ] := aCur ; AAdd( l[ "break_infos" ], bi ) ; aCur := {}
            ENDIF
            nSeg := v
         ENDIF
      CASE n == 11
         IF nSeg == NIL ; nSeg := 0 ; ENDIF
         a := PR_GetPoint( rBs ) ; b := PR_GetPoint( rBe )
         IF a != NIL .AND. b != NIL ; AAdd( aCur, Sep_New( a, b ) ) ; PR_Reset( rBs ) ; PR_Reset( rBe ) ; ENDIF
         PR_AddCoordinate( rBs, p )
      CASE n == 21 .OR. n == 31 ; PR_AddCoordinate( rBs, p )
      CASE n == 12 .OR. n == 22 .OR. n == 32 ; PR_AddCoordinate( rBe, p )
      CASE n == 91
         v := Dp_AsI32( p ) ; IF v != NIL ; l[ "index" ] := v ; ENDIF
      CASE n == 170
         v := Dp_AsI16( p ) ; IF v != NIL ; l[ "path_type" ] := Mpt_From( v ) ; ENDIF
      CASE n == 92
         v := Dp_AsI32Bits( p ) ; IF v != NIL ; l[ "line_color" ] := Sr_McColor( v ) ; ENDIF
      CASE n == 340 ; l[ "line_type_handle" ] := Sr_McHandleNZ( p )
      CASE n == 171
         v := Dp_AsI16( p ) ; IF v != NIL ; l[ "line_weight" ] := Lw_FromValue( v ) ; ENDIF
      CASE n == 40
         v := Dp_AsDouble( p ) ; IF v != NIL ; l[ "arrowhead_size" ] := v ; ENDIF
      CASE n == 341 ; l[ "arrowhead_handle" ] := Sr_McHandleNZ( p )
      CASE n == 93
         v := Dp_AsI32( p ) ; IF v != NIL ; l[ "override_flags" ] := IIf( v < 0, v + 4294967296, v ) ; ENDIF
      ENDCASE
   ENDDO
   a := PR_GetPoint( rBs ) ; b := PR_GetPoint( rBe )
   IF a != NIL .AND. b != NIL ; AAdd( aCur, Sep_New( a, b ) ) ; ENDIF
   IF nSeg != NIL
      bi := Llb_New() ; bi[ "segment_index" ] := nSeg ; bi[ "break_points" ] := aCur ; AAdd( l[ "break_infos" ], bi )
   ENDIF
   l[ "break_info_count" ] := Len( l[ "break_infos" ] )
   IF Len( l[ "break_infos" ] ) > 0
      l[ "segment_index" ] := l[ "break_infos" ][ 1 ][ "segment_index" ]
      l[ "break_points" ] := AClone( l[ "break_infos" ][ 1 ][ "break_points" ] )
   ENDIF
RETURN l

/* read_mleader_leader_root */
FUNCTION Sr_ReadMlRoot( s )
   LOCAL r := Lrt_New( 0 ), p, n, v, rC := PR_New(), rD := PR_New(), rBs := PR_New(), rBe := PR_New(), a, b
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      n := p[ DP_CODE ]
      IF n == 303 ; EXIT ; ENDIF
      DO CASE
      CASE n == 304 .AND. Left( p[ DP_VALUE ], 11 ) == "LEADER_LINE"
         AAdd( r[ "lines" ], Sr_ReadMlLine( s, Len( r[ "lines" ] ) ) )
      CASE n == 290
         v := Dp_AsBool( p ) ; IF v != NIL ; r[ "content_valid" ] := v ; ENDIF
      CASE n == 291
         v := Dp_AsBool( p ) ; IF v != NIL ; r[ "unknown" ] := v ; ENDIF
      CASE n == 10 .OR. n == 20 .OR. n == 30 ; PR_AddCoordinate( rC, p )
      CASE n == 11 .OR. n == 21 .OR. n == 31 ; PR_AddCoordinate( rD, p )
      CASE n == 90
         v := Dp_AsI32( p ) ; IF v != NIL ; r[ "leader_index" ] := v ; ENDIF
      CASE n == 40
         v := Dp_AsDouble( p ) ; IF v != NIL ; r[ "landing_distance" ] := v ; ENDIF
      CASE n == 12
         a := PR_GetPoint( rBs ) ; b := PR_GetPoint( rBe )
         IF a != NIL .AND. b != NIL ; AAdd( r[ "break_points" ], Sep_New( a, b ) ) ; PR_Reset( rBs ) ; PR_Reset( rBe ) ; ENDIF
         PR_AddCoordinate( rBs, p )
      CASE n == 22 .OR. n == 32 ; PR_AddCoordinate( rBs, p )
      CASE n == 13 .OR. n == 23 .OR. n == 33 ; PR_AddCoordinate( rBe, p )
      CASE n == 271
         v := Dp_AsI16( p ) ; IF v != NIL ; r[ "text_attachment_direction" ] := Tad_From( v ) ; ENDIF
      ENDCASE
   ENDDO
   a := PR_GetPoint( rC ) ; IF a != NIL ; r[ "connection_point" ] := a ; ENDIF
   a := PR_GetPoint( rD ) ; IF a != NIL ; r[ "direction" ] := a ; ENDIF
   a := PR_GetPoint( rBs ) ; b := PR_GetPoint( rBe )
   IF a != NIL .AND. b != NIL ; AAdd( r[ "break_points" ], Sep_New( a, b ) ) ; ENDIF
RETURN r

/* read_mleader_context */
PROCEDURE Sr_ReadMlContext( s, c )
   LOCAL p, n, v, i := 0, a, rCb := PR_New(), rTn := PR_New(), rTl := PR_New(), rTd := PR_New(), rBn := PR_New(), rBl := PR_New(), rBs := PR_New(), rBp := PR_New(), rBd := PR_New(), rBv := PR_New()
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      n := p[ DP_CODE ]
      IF n == 301 ; EXIT ; ENDIF
      DO CASE
      CASE n == 302 .AND. Left( p[ DP_VALUE ], 6 ) == "LEADER" ; AAdd( c[ "leader_roots" ], Sr_ReadMlRoot( s ) )
      CASE n == 40 ; v := Dp_AsDouble( p ) ; IF v != NIL ; c[ "scale_factor" ] := v ; ENDIF
      CASE n == 10 .OR. n == 20 .OR. n == 30 ; PR_AddCoordinate( rCb, p )
      CASE n == 41 ; v := Dp_AsDouble( p ) ; IF v != NIL ; c[ "text_height" ] := v ; ENDIF
      CASE n == 140 ; v := Dp_AsDouble( p ) ; IF v != NIL ; c[ "arrowhead_size" ] := v ; ENDIF
      CASE n == 145 ; v := Dp_AsDouble( p ) ; IF v != NIL ; c[ "landing_gap" ] := v ; ENDIF
      CASE n == 174 ; v := Dp_AsI16( p ) ; IF v != NIL ; c[ "text_left_attachment" ] := Tat_From( v ) ; ENDIF
      CASE n == 175 ; v := Dp_AsI16( p ) ; IF v != NIL ; c[ "text_right_attachment" ] := Tat_From( v ) ; ENDIF
      CASE n == 176 ; v := Dp_AsI16( p ) ; IF v != NIL ; c[ "text_alignment" ] := Tal_From( v ) ; ENDIF
      CASE n == 177 ; v := Dp_AsI16( p ) ; IF v != NIL ; c[ "block_connection_type" ] := Bcc_From( v ) ; ENDIF
      CASE n == 290 ; v := Dp_AsBool( p ) ; IF v != NIL ; c[ "has_text_contents" ] := v ; ENDIF
      CASE n == 304 ; c[ "text_string" ] := p[ DP_VALUE ]
      CASE n == 11 .OR. n == 21 .OR. n == 31 ; PR_AddCoordinate( rTn, p )
      CASE n == 340 ; v := Sr_HexVal( p ) ; IF v != NIL ; c[ "text_style_handle" ] := v ; ENDIF
      CASE n == 12 .OR. n == 22 .OR. n == 32 ; PR_AddCoordinate( rTl, p )
      CASE n == 13 .OR. n == 23 .OR. n == 33 ; PR_AddCoordinate( rTd, p )
      CASE n == 42 ; v := Dp_AsDouble( p ) ; IF v != NIL ; c[ "text_rotation" ] := v ; ENDIF
      CASE n == 43 ; v := Dp_AsDouble( p ) ; IF v != NIL ; c[ "text_width" ] := v ; ENDIF
      CASE n == 44 ; v := Dp_AsDouble( p ) ; IF v != NIL ; c[ "text_boundary_height" ] := v ; ENDIF
      CASE n == 45 ; v := Dp_AsDouble( p ) ; IF v != NIL ; c[ "line_spacing_factor" ] := v ; ENDIF
      CASE n == 170 ; v := Dp_AsI16( p ) ; IF v != NIL ; c[ "line_spacing_style" ] := Lss_From( v ) ; ENDIF
      CASE n == 90 ; v := Dp_AsI32Bits( p ) ; IF v != NIL ; c[ "text_color" ] := Sr_McColor( v ) ; ENDIF
      CASE n == 171 ; v := Dp_AsI16( p ) ; IF v != NIL ; c[ "text_attachment_point" ] := Tap_From( v ) ; ENDIF
      CASE n == 172 ; v := Dp_AsI16( p ) ; IF v != NIL ; c[ "text_flow_direction" ] := Fdt_From( v ) ; ENDIF
      CASE n == 91 ; v := Dp_AsI32Bits( p ) ; IF v != NIL ; c[ "background_fill_color" ] := Sr_McColor( v ) ; ENDIF
      CASE n == 141 ; v := Dp_AsDouble( p ) ; IF v != NIL ; c[ "background_scale_factor" ] := v ; ENDIF
      CASE n == 92 ; v := Dp_AsI32( p ) ; IF v != NIL ; c[ "background_transparency" ] := v ; ENDIF
      CASE n == 291 ; v := Dp_AsBool( p ) ; IF v != NIL ; c[ "background_fill_enabled" ] := v ; ENDIF
      CASE n == 292 ; v := Dp_AsBool( p ) ; IF v != NIL ; c[ "background_mask_fill_on" ] := v ; ENDIF
      CASE n == 173 ; v := Dp_AsI16( p ) ; IF v != NIL ; c[ "column_type" ] := v ; ENDIF
      CASE n == 293 ; v := Dp_AsBool( p ) ; IF v != NIL ; c[ "text_height_automatic" ] := v ; ENDIF
      CASE n == 142 ; v := Dp_AsDouble( p ) ; IF v != NIL ; c[ "column_width" ] := v ; ENDIF
      CASE n == 143 ; v := Dp_AsDouble( p ) ; IF v != NIL ; c[ "column_gutter" ] := v ; ENDIF
      CASE n == 144 ; v := Dp_AsDouble( p ) ; IF v != NIL ; AAdd( c[ "column_sizes" ], v ) ; ENDIF
      CASE n == 294 ; v := Dp_AsBool( p ) ; IF v != NIL ; c[ "column_flow_reversed" ] := v ; ENDIF
      CASE n == 295 ; v := Dp_AsBool( p ) ; IF v != NIL ; c[ "word_break" ] := v ; ENDIF
      CASE n == 296 ; v := Dp_AsBool( p ) ; IF v != NIL ; c[ "has_block_contents" ] := v ; ENDIF
      CASE n == 341 ; v := Sr_HexVal( p ) ; IF v != NIL ; c[ "block_content_handle" ] := v ; ENDIF
      CASE n == 14 .OR. n == 24 .OR. n == 34 ; PR_AddCoordinate( rBn, p )
      CASE n == 15 .OR. n == 25 .OR. n == 35 ; PR_AddCoordinate( rBl, p )
      CASE n == 16 .OR. n == 26 .OR. n == 36 ; PR_AddCoordinate( rBs, p )
      CASE n == 46 ; v := Dp_AsDouble( p ) ; IF v != NIL ; c[ "block_rotation" ] := v ; ENDIF
      CASE n == 93 ; v := Dp_AsI32Bits( p ) ; IF v != NIL ; c[ "block_content_color" ] := Sr_McColor( v ) ; ENDIF
      CASE n == 47
         v := Dp_AsDouble( p )
         IF v != NIL .AND. i < Len( c[ "transform_matrix" ] ) ; c[ "transform_matrix" ][ i + 1 ] := v ; i++ ; ENDIF
      CASE n == 110 .OR. n == 120 .OR. n == 130 ; PR_AddCoordinate( rBp, p )
      CASE n == 111 .OR. n == 121 .OR. n == 131 ; PR_AddCoordinate( rBd, p )
      CASE n == 112 .OR. n == 122 .OR. n == 132 ; PR_AddCoordinate( rBv, p )
      CASE n == 297 ; v := Dp_AsBool( p ) ; IF v != NIL ; c[ "normal_reversed" ] := v ; ENDIF
      CASE n == 273 ; v := Dp_AsI16( p ) ; IF v != NIL ; c[ "text_top_attachment" ] := Tat_From( v ) ; ENDIF
      CASE n == 272 ; v := Dp_AsI16( p ) ; IF v != NIL ; c[ "text_bottom_attachment" ] := Tat_From( v ) ; ENDIF
      ENDCASE
   ENDDO
   a := PR_GetPoint( rCb ) ; IF a != NIL ; c[ "content_base_point" ] := a ; ENDIF
   a := PR_GetPoint( rTn ) ; IF a != NIL ; c[ "text_normal" ] := a ; ENDIF
   a := PR_GetPoint( rTl ) ; IF a != NIL ; c[ "text_location" ] := a ; ENDIF
   a := PR_GetPoint( rTd ) ; IF a != NIL ; c[ "text_direction" ] := a ; ENDIF
   a := PR_GetPoint( rBn ) ; IF a != NIL ; c[ "block_content_normal" ] := a ; ENDIF
   a := PR_GetPoint( rBl ) ; IF a != NIL ; c[ "block_content_location" ] := a ; ENDIF
   a := PR_GetPoint( rBs ) ; IF a != NIL ; c[ "block_content_scale" ] := a ; ENDIF
   a := PR_GetPoint( rBp ) ; IF a != NIL ; c[ "base_point" ] := a ; ENDIF
   a := PR_GetPoint( rBd ) ; IF a != NIL ; c[ "base_direction" ] := a ; ENDIF
   a := PR_GetPoint( rBv ) ; IF a != NIL ; c[ "base_vertical" ] := a ; ENDIF
RETURN

/* read_multileader */
FUNCTION Sr_ReadMultileader( s )
   LOCAL e := Emu_New(), p, n, v, rBs := PR_New(), cSec := "", cAtt := NIL, nPg := 0, cPg := "", a, nL
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      n := p[ DP_CODE ]
      DO CASE
      CASE n == 100 ; cSec := p[ DP_VALUE ]
      CASE n == 8 ; e[ "common" ][ "layer" ] := p[ DP_VALUE ]
      CASE n == 62
         v := Dp_AsI16( p ) ; IF v != NIL ; e[ "common" ][ "color" ] := Cl_FromIndex( v ) ; ENDIF
      CASE n == 370
         v := Dp_AsI16( p ) ; IF v != NIL ; e[ "common" ][ "line_weight" ] := Lw_FromValue( v ) ; ENDIF
      CASE ( n == 92 .OR. n == 160 ) .AND. cSec == "AcDbEntity"
         v := Dp_AsInt( p ) ; nPg := Max( 0, IIf( v == NIL, 0, v ) )
      CASE n == 310 .AND. cSec == "AcDbEntity" ; cPg := Sr_AppendHex( cPg, p[ DP_VALUE ] )
      CASE n == 102 ; Sr_EntBaseP( s, p, e )
      CASE n == 270 ; v := Dp_AsI16( p ) ; IF v != NIL ; e[ "dwg_version" ] := v ; ENDIF
      CASE n == 300 .AND. Left( p[ DP_VALUE ], 12 ) == "CONTEXT_DATA" ; Sr_ReadMlContext( s, e[ "context" ] )
      CASE n == 340 ; v := Sr_HexVal( p ) ; IF v != NIL ; e[ "style_handle" ] := v ; ENDIF
      CASE n == 90 ; v := Dp_AsI32( p ) ; IF v != NIL ; e[ "property_override_flags" ] := IIf( v < 0, v + 4294967296, v ) ; ENDIF
      CASE n == 170 ; v := Dp_AsI16( p ) ; IF v != NIL ; e[ "path_type" ] := Mpt_From( v ) ; ENDIF
      CASE n == 91 ; v := Dp_AsI32Bits( p ) ; IF v != NIL ; e[ "line_color" ] := Sr_McColor( v ) ; ENDIF
      CASE n == 341 ; v := Sr_HexVal( p ) ; IF v != NIL ; e[ "line_type_handle" ] := v ; ENDIF
      CASE n == 171 ; v := Dp_AsI16( p ) ; IF v != NIL ; e[ "line_weight" ] := Lw_FromValue( v ) ; ENDIF
      CASE n == 290 ; v := Dp_AsBool( p ) ; IF v != NIL ; e[ "enable_landing" ] := v ; ENDIF
      CASE n == 291 ; v := Dp_AsBool( p ) ; IF v != NIL ; e[ "enable_dogleg" ] := v ; ENDIF
      CASE n == 41 ; v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "dogleg_length" ] := v ; ENDIF
      CASE n == 342 ; e[ "arrowhead_handle" ] := Sr_McHandleNZ( p )
      CASE n == 42 ; v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "arrowhead_size" ] := v ; ENDIF
      CASE n == 172 ; v := Dp_AsI16( p ) ; IF v != NIL ; e[ "content_type" ] := IIf( v == 1 .OR. v == 2, v, MLC_NONE ) ; ENDIF
      CASE n == 343 ; v := Sr_HexVal( p ) ; IF v != NIL ; e[ "text_style_handle" ] := v ; ENDIF
      CASE n == 173 ; v := Dp_AsI16( p ) ; IF v != NIL ; e[ "text_left_attachment" ] := Tat_From( v ) ; ENDIF
      CASE n == 95 ; v := Dp_AsI32( p ) ; IF v != NIL ; e[ "text_right_attachment" ] := Tat_From( v ) ; ENDIF
      CASE n == 174 ; v := Dp_AsI16( p ) ; IF v != NIL ; e[ "text_angle_type" ] := Tan_From( v ) ; ENDIF
      CASE n == 175 ; v := Dp_AsI16( p ) ; IF v != NIL ; e[ "text_alignment" ] := Tal_From( v ) ; ENDIF
      CASE n == 92 ; v := Dp_AsI32Bits( p ) ; IF v != NIL ; e[ "text_color" ] := Sr_McColor( v ) ; ENDIF
      CASE n == 292 ; v := Dp_AsBool( p ) ; IF v != NIL ; e[ "text_frame" ] := v ; ENDIF
      CASE n == 344 ; v := Sr_HexVal( p ) ; IF v != NIL ; e[ "block_content_handle" ] := v ; ENDIF
      CASE n == 93 ; v := Dp_AsI32Bits( p ) ; IF v != NIL ; e[ "block_content_color" ] := Sr_McColor( v ) ; ENDIF
      CASE n == 10 .OR. n == 20 .OR. n == 30 ; PR_AddCoordinate( rBs, p )
      CASE n == 43 ; v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "block_rotation" ] := v ; ENDIF
      CASE n == 45 ; v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "scale_factor" ] := v ; ENDIF
      CASE n == 176 ; v := Dp_AsI16( p ) ; IF v != NIL ; e[ "block_connection_type" ] := Bcc_From( v ) ; ENDIF
      CASE n == 293 ; v := Dp_AsBool( p ) ; IF v != NIL ; e[ "enable_annotation_scale" ] := v ; ENDIF
      CASE n == 94
         v := Dp_AsI32( p )
         IF v != NIL ; a := Mao_New() ; a[ "index" ] := v ; a[ "is_default" ] := ( v == 0 ) ; AAdd( e[ "arrowhead_overrides" ], a ) ; ENDIF
      CASE n == 345
         v := Sr_HexVal( p ) ; nL := Len( e[ "arrowhead_overrides" ] )
         IF v != NIL .AND. nL > 0 ; e[ "arrowhead_overrides" ][ nL ][ "arrowhead_handle" ] := IIf( v != 0, v, NIL ) ; ENDIF
      CASE n == 330 .AND. cSec == "AcDbMLeader"
         IF cAtt != NIL ; AAdd( e[ "block_attributes" ], cAtt ) ; ENDIF
         cAtt := Bat_New( "" )
         v := Sr_HexVal( p ) ; IF v != NIL ; cAtt[ "attribute_definition_handle" ] := IIf( v != 0, v, NIL ) ; ENDIF
      CASE n == 177 .AND. cAtt != NIL
         v := Dp_AsI16( p ) ; IF v != NIL ; cAtt[ "index" ] := v ; ENDIF
      CASE n == 44 .AND. cAtt != NIL
         v := Dp_AsDouble( p ) ; IF v != NIL ; cAtt[ "width" ] := v ; ENDIF
      CASE n == 302 .AND. cAtt != NIL
         cAtt[ "text" ] := p[ DP_VALUE ] ; AAdd( e[ "block_attributes" ], cAtt ) ; cAtt := NIL
      CASE n == 294 ; v := Dp_AsBool( p ) ; IF v != NIL ; e[ "text_direction_negative" ] := v ; ENDIF
      CASE n == 178 ; v := Dp_AsI16( p ) ; IF v != NIL ; e[ "text_align_in_ipe" ] := v ; ENDIF
      CASE n == 179 ; v := Dp_AsI16( p ) ; IF v != NIL ; e[ "text_attachment_point" ] := Tap_From( v ) ; ENDIF
      CASE n == 271 ; v := Dp_AsI16( p ) ; IF v != NIL ; e[ "text_attachment_direction" ] := Tad_From( v ) ; ENDIF
      CASE n == 272 ; v := Dp_AsI16( p ) ; IF v != NIL ; e[ "text_bottom_attachment" ] := Tat_From( v ) ; ENDIF
      CASE n == 273 ; v := Dp_AsI16( p ) ; IF v != NIL ; e[ "text_top_attachment" ] := Tat_From( v ) ; ENDIF
      CASE n == 295 ; v := Dp_AsBool( p ) ; IF v != NIL ; e[ "extend_leader_to_text" ] := v ; ENDIF
      CASE n == 44 ; v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "text_height" ] := v ; ENDIF
      OTHERWISE ; Sr_EntBaseP( s, p, e )
      ENDCASE
   ENDDO
   a := PR_GetPoint( rBs ) ; IF a != NIL ; e[ "block_scale" ] := a ; ENDIF
   IF cAtt != NIL ; AAdd( e[ "block_attributes" ], cAtt ) ; ENDIF
   IF nPg != 0 .OR. Len( cPg ) > 0 ; e[ "common" ][ "graphic_data" ] := Left( cPg, nPg ) ; ENDIF
RETURN e

/* read_mesh (mismo fichero por el limite del editor web). Estados: 0 Properties, 1 Vertices, 2 Faces, 3 Edges, 4 Creases */
FUNCTION Sr_ReadMesh( s )
   LOCAL e := Emh_New(), p, n, v, nSt := 0, rV := PR_New(), aFi := {}, nSub := NIL, aEb := {}, aCr := {}, pt, i
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      n := p[ DP_CODE ]
      DO CASE
      CASE n == 8 ; e[ "common" ][ "layer" ] := p[ DP_VALUE ]
      CASE n == 62
         v := Dp_AsI16( p ) ; IF v != NIL ; e[ "common" ][ "color" ] := Cl_FromIndex( v ) ; ENDIF
      CASE n == 370
         v := Dp_AsI16( p ) ; IF v != NIL ; e[ "common" ][ "line_weight" ] := Lw_FromValue( v ) ; ENDIF
      CASE n == 71
         v := Dp_AsI16( p ) ; IF v != NIL ; e[ "version" ] := v ; ENDIF
      CASE n == 72
         v := Dp_AsI16( p ) ; IF v != NIL ; e[ "blend_crease" ] := ( v != 0 ) ; ENDIF
      CASE n == 91 .AND. nSt == 0
         v := Dp_AsI32( p ) ; IF v != NIL ; e[ "subdivision_level" ] := v ; ENDIF
      CASE n == 91
         /* otros estados: se ignora (Rust: _ => {}) */
      CASE n == 92
         v := Dp_AsI32( p ) ; IF v != NIL ; nSt := 1 ; ENDIF
      CASE n == 93
         v := Dp_AsI32( p ) ; IF v != NIL ; nSt := 2 ; ENDIF
      CASE n == 94
         v := Dp_AsI32( p ) ; IF v != NIL ; nSt := 3 ; ENDIF
      CASE n == 95
         v := Dp_AsI32( p ) ; IF v != NIL ; nSt := 4 ; ENDIF
      CASE n == 10 .OR. n == 20 .OR. n == 30
         IF nSt == 1
            PR_AddCoordinate( rV, p )
            IF n == 30
               pt := PR_GetPoint( rV )
               IF pt != NIL ; AAdd( e[ "vertices" ], pt ) ; rV := PR_New() ; ENDIF
            ENDIF
         ENDIF
      CASE n == 90
         v := Dp_AsI32( p )
         IF v != NIL
            IF nSt == 2
               IF nSub == NIL
                  nSub := v
               ELSE
                  AAdd( aFi, v )
                  IF Len( aFi ) == nSub
                     AAdd( e[ "faces" ], Mfc_New( aFi ) ) ; aFi := {} ; nSub := NIL
                  ENDIF
               ENDIF
            ELSEIF nSt == 3
               AAdd( aEb, v )
               IF Len( aEb ) == 2
                  AAdd( e[ "edges" ], Mge_New( aEb[ 1 ], aEb[ 2 ] ) ) ; aEb := {}
               ENDIF
            ENDIF
         ENDIF
      CASE n == 140 .AND. nSt == 4
         v := Dp_AsDouble( p ) ; IF v != NIL ; AAdd( aCr, v ) ; ENDIF
      OTHERWISE ; Sr_EntBaseP( s, p, e )
      ENDCASE
   ENDDO
   FOR i := 1 TO Len( aCr )
      IF aCr[ i ] != 0.0 .AND. i <= Len( e[ "edges" ] ) ; e[ "edges" ][ i ][ "crease" ] := aCr[ i ] ; ENDIF
   NEXT
RETURN e
