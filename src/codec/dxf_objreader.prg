/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/dxf_objreader.prg
   Origen Rust: opencadcodec/src/io/dxf/reader/section_reader.rs (read_objects, read_dictionary, read_layout).
   Licencia del original: MPL-2.0. Prefijo Dxo_.
   PENDIENTE: el resto de tipos de objeto (XRECORD, GROUP, MLINESTYLE, IMAGEDEF, MLEADERSTYLE, PLOTSETTINGS, TABLESTYLE, SCALE,
   SORTENTSTABLE, DICTIONARYVAR, VISUALSTYLE, MATERIAL, ...) se saltan; xdata de objetos tampoco.
   El original no tiene #[test] para estas funciones; los tests [extra] estan en t_dxf_rw.prg.
----------------------------------------------------------------------------*/
#include "ocx.ch"
#define DP_CODE 1
#define DP_VALUE 3

STATIC FUNCTION Dxo_LayoutDblMap()
   STATIC hM
   IF hM == NIL
      hM := { ;
         10 => { "min_limits", 1 }, ;
         20 => { "min_limits", 2 }, ;
         11 => { "max_limits", 1 }, ;
         21 => { "max_limits", 2 }, ;
         12 => { "insertion_base", 1 }, ;
         22 => { "insertion_base", 2 }, ;
         32 => { "insertion_base", 3 }, ;
         14 => { "min_extents", 1 }, ;
         24 => { "min_extents", 2 }, ;
         34 => { "min_extents", 3 }, ;
         15 => { "max_extents", 1 }, ;
         25 => { "max_extents", 2 }, ;
         35 => { "max_extents", 3 }, ;
         13 => { "ucs_origin", 1 }, ;
         23 => { "ucs_origin", 2 }, ;
         33 => { "ucs_origin", 3 }, ;
         16 => { "ucs_x_axis", 1 }, ;
         26 => { "ucs_x_axis", 2 }, ;
         36 => { "ucs_x_axis", 3 }, ;
         17 => { "ucs_y_axis", 1 }, ;
         27 => { "ucs_y_axis", 2 }, ;
         37 => { "ucs_y_axis", 3 }, ;
         146 => { "elevation", 0 } }
   ENDIF
RETURN hM

STATIC FUNCTION Dxo_PlotMap()
   STATIC hM
   IF hM == NIL
      hM := { ;
         1 => { "plot_page_name", "S" }, ;
         2 => { "plot_printer_name", "S" }, ;
         4 => { "paper_size", "S" }, ;
         6 => { "plot_view_name", "S" }, ;
         7 => { "plot_style_sheet", "S" }, ;
         40 => { "plot_margin_left", "D" }, ;
         41 => { "plot_margin_bottom", "D" }, ;
         42 => { "plot_margin_right", "D" }, ;
         43 => { "plot_margin_top", "D" }, ;
         44 => { "paper_width", "D" }, ;
         45 => { "paper_height", "D" }, ;
         46 => { "plot_origin_x", "D" }, ;
         47 => { "plot_origin_y", "D" }, ;
         48 => { "plot_window_min_x", "D" }, ;
         49 => { "plot_window_min_y", "D" }, ;
         140 => { "plot_window_max_x", "D" }, ;
         141 => { "plot_window_max_y", "D" }, ;
         142 => { "plot_scale_numerator", "D" }, ;
         143 => { "plot_scale_denominator", "D" }, ;
         147 => { "plot_scale_factor", "D" }, ;
         148 => { "paper_image_origin_x", "D" }, ;
         149 => { "paper_image_origin_y", "D" }, ;
         72 => { "plot_paper_units", "I" }, ;
         73 => { "plot_rotation", "I" }, ;
         74 => { "plot_type", "I" }, ;
         75 => { "plot_scale_type", "I" }, ;
         76 => { "shade_plot_mode", "I" }, ;
         77 => { "shade_plot_resolution", "I" }, ;
         78 => { "shade_plot_dpi", "I" } }
   ENDIF
RETURN hM

STATIC FUNCTION Dxo_Num( c )
   LOCAL t := AllTrim( c )
   IF Len( t ) == 0 ; RETURN NIL ; ENDIF
   IF ! ( Left( t, 1 ) $ "0123456789.+-" ) ; RETURN NIL ; ENDIF
RETURN Val( t )

STATIC FUNCTION Dxo_Hex( c )
   LOCAL t := AllTrim( c ), i
   IF Len( t ) == 0 ; RETURN NIL ; ENDIF
   FOR i := 1 TO Len( t )
      IF ! ( SubStr( t, i, 1 ) $ "0123456789abcdefABCDEF" ) ; RETURN NIL ; ENDIF
   NEXT
RETURN hb_HexToNum( t )

STATIC FUNCTION Dxo_ReadDictionary( s )
   LOCAL d := Dic_New(), p, cKey := NIL, v
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      DO CASE
      CASE p[ DP_CODE ] == 5
         v := Sr_HexVal( p ) ; IF v != NIL ; d[ "handle" ] := v ; ENDIF
      CASE p[ DP_CODE ] == 102
         DO CASE
         CASE AllTrim( p[ DP_VALUE ] ) == "{ACAD_REACTORS" ; d[ "reactors" ] := Sr_ReadReactorHandles( s )
         CASE AllTrim( p[ DP_VALUE ] ) == "{ACAD_XDICTIONARY" ; d[ "xdictionary_handle" ] := Sr_ReadXDictHandle( s )
         CASE Left( AllTrim( p[ DP_VALUE ] ), 1 ) == "{" ; Sr_SkipDefinedGroup( s )
         ENDCASE
      CASE p[ DP_CODE ] == 330
         v := Sr_HexVal( p ) ; IF v != NIL ; d[ "owner" ] := v ; ENDIF
      CASE p[ DP_CODE ] == 281
         v := Dp_AsI16( p ) ; IF v != NIL ; d[ "duplicate_cloning" ] := v ; ENDIF
      CASE p[ DP_CODE ] == 280
         v := Dp_AsI16( p ) ; IF v != NIL ; d[ "hard_owner" ] := v != 0 ; ENDIF
      CASE p[ DP_CODE ] == 3
         cKey := p[ DP_VALUE ]
      CASE p[ DP_CODE ] == 350 .OR. p[ DP_CODE ] == 360
         IF cKey != NIL
            v := Sr_HexVal( p )
            IF v != NIL
               IF p[ DP_CODE ] == 360 .OR. d[ "hard_owner" ] .OR. Dic_IsCanonicalHardOwnerKey( cKey )
                  Dic_SetEntryHardOwner( d, cKey, .T. )
               ENDIF
               Dic_AddEntry( d, cKey, v )
            ENDIF
            cKey := NIL
         ENDIF
      ENDCASE
   ENDDO
RETURN d

STATIC FUNCTION Dxo_ReadLayout( s )
   LOCAL l := Lyo_New( "" ), p, v, m, nSec := 0, aPs := {}, lOwner := .F., x, q, n, t
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      IF p[ DP_CODE ] == 100
         IF p[ DP_VALUE ] == "AcDbPlotSettings" ; nSec := 1 ; ELSEIF p[ DP_VALUE ] == "AcDbLayout" ; nSec := 2 ; ENDIF
         LOOP
      ENDIF
      IF p[ DP_CODE ] == 102
         IF p[ DP_VALUE ] == "{ACAD_XDICTIONARY"
            DO WHILE ( q := Sr_Next( s ) ) != NIL
               IF q[ DP_CODE ] == 360
                  v := Sr_HexVal( q ) ; IF v != NIL ; l[ "xdictionary_handle" ] := v ; ENDIF
               ENDIF
               IF q[ DP_CODE ] == 102 ; EXIT ; ENDIF
            ENDDO
         ELSEIF p[ DP_VALUE ] == "{ACAD_REACTORS"
            DO WHILE ( q := Sr_Next( s ) ) != NIL
               IF q[ DP_CODE ] == 102 ; EXIT ; ENDIF
               IF q[ DP_CODE ] == 330
                  v := Sr_HexVal( q ) ; IF v != NIL ; AAdd( l[ "reactors" ], v ) ; ENDIF
               ENDIF
            ENDDO
         ENDIF
         LOOP
      ENDIF
      DO CASE
      CASE nSec == 0
         IF p[ DP_CODE ] == 5
            v := Sr_HexVal( p ) ; IF v != NIL ; l[ "handle" ] := v ; ENDIF
         ELSEIF p[ DP_CODE ] == 330 .AND. ! lOwner
            v := Sr_HexVal( p ) ; IF v != NIL ; l[ "owner" ] := v ; ENDIF
            lOwner := .T.
         ENDIF
      CASE nSec == 1
         AAdd( aPs, { p[ DP_CODE ], p[ DP_VALUE ] } )
      CASE nSec == 2
         n := p[ DP_CODE ]
         m := hb_HGetDef( Dxo_LayoutDblMap(), n, NIL )
         IF m != NIL
            v := Dp_AsDouble( p )
            IF v != NIL
               IF m[ 2 ] == 0 ; l[ m[ 1 ] ] := v ; ELSE ; l[ m[ 1 ] ][ m[ 2 ] ] := v ; ENDIF
            ENDIF
         ELSE
            DO CASE
            CASE n == 1 ; l[ "name" ] := p[ DP_VALUE ]
            CASE n == 70
               v := Dp_AsI16( p ) ; IF v != NIL ; l[ "flags" ] := v ; ENDIF
            CASE n == 71
               v := Dp_AsI16( p ) ; IF v != NIL ; l[ "tab_order" ] := v ; ENDIF
            CASE n == 76
               v := Dp_AsI16( p ) ; IF v != NIL ; l[ "ucs_ortho_type" ] := v ; ENDIF
            CASE n == 330
               v := Sr_HexVal( p ) ; IF v != NIL ; l[ "block_record" ] := v ; ENDIF
            CASE n == 331
               v := Sr_HexVal( p ) ; IF v != NIL ; l[ "viewport" ] := v ; ENDIF
            CASE n == 345
               v := Sr_HexVal( p ) ; IF v != NIL ; l[ "named_ucs" ] := v ; ENDIF
            CASE n == 346
               v := Sr_HexVal( p ) ; IF v != NIL ; l[ "base_ucs" ] := v ; ENDIF
            ENDCASE
         ENDIF
      ENDCASE
   ENDDO
   IF Len( aPs ) > 0
      FOR EACH x IN aPs
         t := x[ 2 ]
         m := hb_HGetDef( Dxo_PlotMap(), x[ 1 ], NIL )
         IF m != NIL
            IF m[ 2 ] == "S"
               l[ m[ 1 ] ] := t
            ELSE
               v := Dxo_Num( t )
               IF v != NIL
                  IF m[ 2 ] == "I" ; v := Int( v ) ; ENDIF
                  l[ m[ 1 ] ] := v
               ENDIF
            ENDIF
         ELSEIF x[ 1 ] == 70
            v := Dxo_Num( t ) ; IF v != NIL ; l[ "plot_flags" ] := Pfl_FromBits( Int( v ) ) ; ENDIF
         ELSEIF x[ 1 ] == 333
            v := Dxo_Hex( t ) ; IF v != NIL ; l[ "visual_style_handle" ] := v ; ENDIF
         ENDIF
      NEXT
      l[ "raw_plot_settings_codes" ] := aPs
   ENDIF
RETURN l

/* read_objects: parcial (ver cabecera) */
PROCEDURE Dxo_ReadObjects( s, d )
   LOCAL p, o
   d[ "objects" ] := hb_Hash()
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 .AND. p[ DP_VALUE ] == "ENDSEC" ; EXIT ; ENDIF
      IF p[ DP_CODE ] == 0
         DO CASE
         CASE p[ DP_VALUE ] == "DICTIONARY"
            o := Dxo_ReadDictionary( s ) ; d[ "objects" ][ o[ "handle" ] ] := o
         CASE p[ DP_VALUE ] == "LAYOUT"
            o := Dxo_ReadLayout( s ) ; d[ "objects" ][ o[ "handle" ] ] := o
         OTHERWISE
            Sr_SkipEntity( s )
         ENDCASE
      ENDIF
   ENDDO
RETURN
