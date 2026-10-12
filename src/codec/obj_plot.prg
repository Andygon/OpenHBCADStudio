/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/obj_plot.prg
   Origen Rust: opencadcodec/src/objects/plot_settings.rs (776 lineas; sin #[test] en Rust, tests [extra] en t_codec_objplot.prg). Licencia del original: MPL-2.0.
   Prefijos: Ppu_ PlotPaperUnits, Prt_ PlotRotation, Plt_ PlotType, Sct_ ScaledType, Spm_ ShadePlotMode, Spr_ ShadePlotResolutionLevel, Pfl_ PlotFlags,
   Pmg_ PaperMargin, Pwn_ PlotWindow, Pls_ PlotSettings. Los enums son enteros (constantes PPU_/PRT_/PLT_/SCT_/SPM_/SPR_ en ocx.ch); from_code normaliza como en Rust,
   to_code es identidad. Option<f64> cached_scale -> NIL. Los builders with_* mutan y devuelven el mismo hash (como el self movido de Rust).
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Ppu_FromCode( n ) ; RETURN iif( n == 1 .OR. n == 2, n, PPU_INCHES )
FUNCTION Ppu_ToCode( n ) ; RETURN n

FUNCTION Prt_FromCode( n ) ; RETURN iif( n >= 1 .AND. n <= 3, n, PRT_NONE )
FUNCTION Prt_ToCode( n ) ; RETURN n
FUNCTION Prt_ToDegrees( n ) ; RETURN n * 90.0
FUNCTION Prt_ToRadians( n ) ; RETURN Prt_ToDegrees( n ) * ( OCX_PI / 180.0 )

FUNCTION Plt_FromCode( n ) ; RETURN iif( n == 0 .OR. n == 1 .OR. n == 2 .OR. n == 3 .OR. n == 5, n, PLT_WINDOW )
FUNCTION Plt_ToCode( n ) ; RETURN n

FUNCTION Sct_FromCode( n ) ; RETURN iif( n == 0 .OR. n == 1 .OR. ( n >= 16 .AND. n <= 31 ), n, SCT_CUSTOM_SCALE )
FUNCTION Sct_ToCode( n ) ; RETURN n
FUNCTION Sct_ScaleFactor( n )
   DO CASE
   CASE n == SCT_SCALE_TO_FIT ; RETURN 0.0
   CASE n == SCT_CUSTOM_SCALE .OR. n == SCT_ONE_TO_ONE ; RETURN 1.0
   CASE n == SCT_ONE_TO_TWO ; RETURN 0.5
   CASE n == SCT_ONE_TO_FOUR ; RETURN 0.25
   CASE n == SCT_ONE_TO_EIGHT ; RETURN 0.125
   CASE n == SCT_ONE_TO_TEN ; RETURN 0.1
   CASE n == SCT_ONE_TO_SIXTEEN ; RETURN 0.0625
   CASE n == SCT_ONE_TO_TWENTY ; RETURN 0.05
   CASE n == SCT_ONE_TO_THIRTY ; RETURN 1.0 / 30.0
   CASE n == SCT_ONE_TO_FORTY ; RETURN 0.025
   CASE n == SCT_ONE_TO_FIFTY ; RETURN 0.02
   CASE n == SCT_ONE_TO_HUNDRED ; RETURN 0.01
   CASE n == SCT_TWO_TO_ONE ; RETURN 2.0
   CASE n == SCT_FOUR_TO_ONE ; RETURN 4.0
   CASE n == SCT_EIGHT_TO_ONE ; RETURN 8.0
   CASE n == SCT_TEN_TO_ONE ; RETURN 10.0
   ENDCASE
RETURN 100.0

FUNCTION Spm_FromCode( n ) ; RETURN iif( n >= 1 .AND. n <= 3, n, SPM_AS_DISPLAYED )
FUNCTION Spm_ToCode( n ) ; RETURN n
FUNCTION Spr_FromCode( n ) ; RETURN iif( n == 0 .OR. n == 1 .OR. n == 3 .OR. n == 4 .OR. n == 5, n, SPR_NORMAL )
FUNCTION Spr_ToCode( n ) ; RETURN n

FUNCTION Pfl_New()
RETURN hb_Hash( "unknown_bits", 0, "plot_viewport_borders", .F., "show_plot_styles", .F., "plot_centered", .F., "plot_hidden", .F., "use_standard_scale", .F., "plot_plot_styles", .F., ;
   "scale_lineweights", .F., "print_lineweights", .F., "draw_viewports_first", .F., "model_type", .F., "update_paper", .F., "zoom_to_paper_on_update", .F., "initializing", .F., "prev_plot_init", .F. )

FUNCTION Pfl_FromBits( nBits )
   LOCAL f := Pfl_New()
   nBits := hb_bitAnd( nBits, 65535 )
   f[ "unknown_bits" ] := hb_bitAnd( nBits, hb_bitNot( 32511 ) )
   f[ "plot_viewport_borders" ] := hb_bitAnd( nBits, 1 ) != 0
   f[ "show_plot_styles" ] := hb_bitAnd( nBits, 2 ) != 0
   f[ "plot_centered" ] := hb_bitAnd( nBits, 4 ) != 0
   f[ "plot_hidden" ] := hb_bitAnd( nBits, 8 ) != 0
   f[ "use_standard_scale" ] := hb_bitAnd( nBits, 16 ) != 0
   f[ "plot_plot_styles" ] := hb_bitAnd( nBits, 32 ) != 0
   f[ "scale_lineweights" ] := hb_bitAnd( nBits, 64 ) != 0
   f[ "print_lineweights" ] := hb_bitAnd( nBits, 128 ) != 0
   f[ "draw_viewports_first" ] := hb_bitAnd( nBits, 512 ) != 0
   f[ "model_type" ] := hb_bitAnd( nBits, 1024 ) != 0
   f[ "update_paper" ] := hb_bitAnd( nBits, 2048 ) != 0
   f[ "zoom_to_paper_on_update" ] := hb_bitAnd( nBits, 4096 ) != 0
   f[ "initializing" ] := hb_bitAnd( nBits, 8192 ) != 0
   f[ "prev_plot_init" ] := hb_bitAnd( nBits, 16384 ) != 0
RETURN f

FUNCTION Pfl_ToBits( f )
   LOCAL n := hb_bitAnd( f[ "unknown_bits" ], hb_bitNot( 32511 ) ), a, i
   a := { { "plot_viewport_borders", 1 }, { "show_plot_styles", 2 }, { "plot_centered", 4 }, { "plot_hidden", 8 }, { "use_standard_scale", 16 }, { "plot_plot_styles", 32 }, ;
      { "scale_lineweights", 64 }, { "print_lineweights", 128 }, { "draw_viewports_first", 512 }, { "model_type", 1024 }, { "update_paper", 2048 }, ;
      { "zoom_to_paper_on_update", 4096 }, { "initializing", 8192 }, { "prev_plot_init", 16384 } }
   FOR EACH i IN a
      IF f[ i[ 1 ] ] ; n := hb_bitOr( n, i[ 2 ] ) ; ENDIF
   NEXT
RETURN n

FUNCTION Pmg_New( nL, nB, nR, nT ) ; RETURN hb_Hash( "left", nL, "bottom", nB, "right", nR, "top", nT )
FUNCTION Pmg_Default() ; RETURN Pmg_New( 0.0, 0.0, 0.0, 0.0 )
FUNCTION Pmg_Uniform( n ) ; RETURN Pmg_New( n, n, n, n )
FUNCTION Pmg_IsZero( m ) ; RETURN m[ "left" ] == 0.0 .AND. m[ "bottom" ] == 0.0 .AND. m[ "right" ] == 0.0 .AND. m[ "top" ] == 0.0
FUNCTION Pmg_HorizontalTotal( m ) ; RETURN m[ "left" ] + m[ "right" ]
FUNCTION Pmg_VerticalTotal( m ) ; RETURN m[ "top" ] + m[ "bottom" ]

FUNCTION Pwn_Default() ; RETURN hb_Hash( "lower_left_x", 0.0, "lower_left_y", 0.0, "upper_right_x", 0.0, "upper_right_y", 0.0 )
FUNCTION Pwn_New( x1, y1, x2, y2 ) ; RETURN hb_Hash( "lower_left_x", Min( x1, x2 ), "lower_left_y", Min( y1, y2 ), "upper_right_x", Max( x1, x2 ), "upper_right_y", Max( y1, y2 ) )
FUNCTION Pwn_Width( w ) ; RETURN w[ "upper_right_x" ] - w[ "lower_left_x" ]
FUNCTION Pwn_Height( w ) ; RETURN w[ "upper_right_y" ] - w[ "lower_left_y" ]
FUNCTION Pwn_IsEmpty( w ) ; RETURN Pwn_Width( w ) <= 0.0 .OR. Pwn_Height( w ) <= 0.0

FUNCTION Pls_New( cPage )
RETURN hb_Hash( "handle", Hd_Null(), "owner", Hd_Null(), "reactors", {}, "xdictionary_handle", NIL, "page_name", cPage, "printer_name", "", "paper_size", "", "plot_view_name", "", ;
   "current_style_sheet", "", "paper_width", 0.0, "paper_height", 0.0, "margins", Pmg_Default(), "origin_x", 0.0, "origin_y", 0.0, "plot_window", Pwn_Default(), ;
   "scale_numerator", 1.0, "scale_denominator", 1.0, "paper_units", PPU_INCHES, "rotation", PRT_NONE, "plot_type", PLT_WINDOW, "scale_type", SCT_SCALE_TO_FIT, ;
   "shade_plot_mode", SPM_AS_DISPLAYED, "shade_plot_resolution", SPR_NORMAL, "shade_plot_dpi", 300, "flags", Pfl_New(), "standard_scale_factor", 1.0, ;
   "paper_image_origin_x", 0.0, "paper_image_origin_y", 0.0, "plot_view_handle", Hd_Null(), "visual_style_handle", Hd_Null(), "cached_scale", NIL )
FUNCTION Pls_Default() ; RETURN Pls_New( "" )
FUNCTION Pls_ObjectType() ; RETURN "PLOTSETTINGS"
FUNCTION Pls_WithPaper( cPage, cSize ) ; LOCAL s := Pls_New( cPage ) ; s[ "paper_size" ] := cSize ; RETURN s

FUNCTION Pls_ScaleFactor( s )
   IF s[ "cached_scale" ] != NIL ; RETURN s[ "cached_scale" ] ; ENDIF
RETURN iif( s[ "scale_denominator" ] == 0.0, 1.0, s[ "scale_numerator" ] / s[ "scale_denominator" ] )

PROCEDURE Pls_SetCustomScale( s, nNum, nDen )
   s[ "scale_numerator" ] := nNum ; s[ "scale_denominator" ] := nDen ; s[ "scale_type" ] := SCT_CUSTOM_SCALE ; s[ "cached_scale" ] := NIL
RETURN
PROCEDURE Pls_SetScaleToFit( s )
   s[ "scale_type" ] := SCT_SCALE_TO_FIT ; s[ "flags" ][ "use_standard_scale" ] := .F.
RETURN
PROCEDURE Pls_SetStandardScale( s, nScale )
   s[ "scale_type" ] := nScale ; s[ "flags" ][ "use_standard_scale" ] := .T.
   DO CASE
   CASE nScale == SCT_ONE_TO_ONE ; s[ "scale_numerator" ] := 1.0 ; s[ "scale_denominator" ] := 1.0
   CASE nScale == SCT_ONE_TO_TWO ; s[ "scale_numerator" ] := 1.0 ; s[ "scale_denominator" ] := 2.0
   CASE nScale == SCT_TWO_TO_ONE ; s[ "scale_numerator" ] := 2.0 ; s[ "scale_denominator" ] := 1.0
   CASE nScale == SCT_ONE_TO_TEN ; s[ "scale_numerator" ] := 1.0 ; s[ "scale_denominator" ] := 10.0
   CASE nScale == SCT_TEN_TO_ONE ; s[ "scale_numerator" ] := 10.0 ; s[ "scale_denominator" ] := 1.0
   ENDCASE
   s[ "cached_scale" ] := NIL
RETURN

FUNCTION Pls_PrintableWidth( s ) ; RETURN s[ "paper_width" ] - Pmg_HorizontalTotal( s[ "margins" ] )
FUNCTION Pls_PrintableHeight( s ) ; RETURN s[ "paper_height" ] - Pmg_VerticalTotal( s[ "margins" ] )
PROCEDURE Pls_SetPaperSize( s, w, h )
   s[ "paper_width" ] := w ; s[ "paper_height" ] := h
RETURN
PROCEDURE Pls_SetPaperWithMargins( s, w, h, m )
   s[ "paper_width" ] := w ; s[ "paper_height" ] := h ; s[ "margins" ] := m
RETURN
PROCEDURE Pls_SetPlotWindow( s, x1, y1, x2, y2 )
   s[ "plot_window" ] := Pwn_New( x1, y1, x2, y2 ) ; s[ "plot_type" ] := PLT_WINDOW
RETURN
PROCEDURE Pls_SetOrigin( s, x, y )
   s[ "origin_x" ] := x ; s[ "origin_y" ] := y
RETURN
PROCEDURE Pls_CenterPlot( s ) ; s[ "flags" ][ "plot_centered" ] := .T. ; RETURN
FUNCTION Pls_IsScaleToFit( s ) ; RETURN s[ "scale_type" ] == SCT_SCALE_TO_FIT
FUNCTION Pls_IsCustomScale( s ) ; RETURN s[ "scale_type" ] == SCT_CUSTOM_SCALE
PROCEDURE Pls_SetPrinter( s, c ) ; s[ "printer_name" ] := c ; RETURN
PROCEDURE Pls_SetStyleSheet( s, c ) ; s[ "current_style_sheet" ] := c ; RETURN
FUNCTION Pls_WithPaperSize( s, c ) ; s[ "paper_size" ] := c ; RETURN s
FUNCTION Pls_WithPrinter( s, c ) ; s[ "printer_name" ] := c ; RETURN s
FUNCTION Pls_WithRotation( s, n ) ; s[ "rotation" ] := n ; RETURN s
FUNCTION Pls_WithUnits( s, n ) ; s[ "paper_units" ] := n ; RETURN s
FUNCTION Pls_WithScale( s, nNum, nDen ) ; Pls_SetCustomScale( s, nNum, nDen ) ; RETURN s
