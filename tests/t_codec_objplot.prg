/* Tests [extra]: plot_settings.rs no tiene #[test] en Rust */
#include "ocx.ch"
PROCEDURE T_CodecObjPlot()
   LOCAL f, s, w
   Chk( Ppu_FromCode( 1 ) == PPU_MILLIMETERS .AND. Ppu_FromCode( 9 ) == PPU_INCHES .AND. Prt_FromCode( 3 ) == PRT_DEGREES270 .AND. Prt_FromCode( 7 ) == PRT_NONE, "[extra] from_code normaliza paper units y rotation" )
   Chk( Prt_ToDegrees( PRT_DEGREES180 ) == 180.0 .AND. Abs( Prt_ToRadians( PRT_DEGREES90 ) - OCX_PI / 2.0 ) < 0.000000000001, "[extra] rotation to_degrees/to_radians" )
   Chk( Plt_FromCode( 4 ) == PLT_WINDOW .AND. Plt_FromCode( 5 ) == PLT_LAYOUT .AND. Plt_FromCode( 99 ) == PLT_WINDOW .AND. Sct_FromCode( 20 ) == SCT_ONE_TO_TEN .AND. Sct_FromCode( 12 ) == SCT_CUSTOM_SCALE .AND. Sct_FromCode( 0 ) == SCT_SCALE_TO_FIT, "[extra] plot_type y scaled_type from_code" )
   Chk( Sct_ScaleFactor( SCT_ONE_TO_THIRTY ) == 1.0 / 30.0 .AND. Sct_ScaleFactor( SCT_HUNDRED_TO_ONE ) == 100.0 .AND. Sct_ScaleFactor( SCT_SCALE_TO_FIT ) == 0.0 .AND. Sct_ScaleFactor( SCT_ONE_TO_TWO ) == 0.5, "[extra] scaled_type scale_factor" )
   Chk( Spm_FromCode( 2 ) == SPM_HIDDEN .AND. Spm_FromCode( 8 ) == SPM_AS_DISPLAYED .AND. Spr_FromCode( 2 ) == SPR_NORMAL .AND. Spr_FromCode( 4 ) == SPR_MAXIMUM .AND. Spr_FromCode( 9 ) == SPR_NORMAL, "[extra] shade plot from_code" )
   f := Pfl_FromBits( 1 + 4 + 512 + 16384 + 256 ) ; Chk( f[ "plot_viewport_borders" ] .AND. f[ "plot_centered" ] .AND. f[ "draw_viewports_first" ] .AND. f[ "prev_plot_init" ] .AND. ! f[ "plot_hidden" ] .AND. f[ "unknown_bits" ] == 256, "[extra] plot_flags from_bits" )
   Chk( Pfl_ToBits( f ) == 1 + 4 + 512 + 16384 + 256, "[extra] plot_flags ida y vuelta con unknown_bits" )
   Chk( Pfl_ToBits( Pfl_FromBits( 65536 + 2 ) ) == 2, "[extra] plot_flags from_bits recorta a 16 bits" )
   Chk( Pmg_IsZero( Pmg_Default() ) .AND. ! Pmg_IsZero( Pmg_Uniform( 1.0 ) ) .AND. Pmg_HorizontalTotal( Pmg_New( 1.0, 2.0, 3.0, 4.0 ) ) == 4.0 .AND. Pmg_VerticalTotal( Pmg_New( 1.0, 2.0, 3.0, 4.0 ) ) == 6.0, "[extra] paper_margin" )
   w := Pwn_New( 5.0, 7.0, 1.0, 2.0 ) ; Chk( w[ "lower_left_x" ] == 1.0 .AND. w[ "upper_right_y" ] == 7.0 .AND. Pwn_Width( w ) == 4.0 .AND. Pwn_Height( w ) == 5.0 .AND. ! Pwn_IsEmpty( w ) .AND. Pwn_IsEmpty( Pwn_Default() ), "[extra] plot_window ordena y mide" )
   s := Pls_New( "P" ) ; Chk( s[ "page_name" ] == "P" .AND. s[ "shade_plot_dpi" ] == 300 .AND. Pls_ScaleFactor( s ) == 1.0 .AND. Pls_IsScaleToFit( s ) .AND. Pls_ObjectType() == "PLOTSETTINGS", "[extra] plot_settings new" )
   Pls_SetCustomScale( s, 1.0, 4.0 ) ; Chk( Pls_ScaleFactor( s ) == 0.25 .AND. Pls_IsCustomScale( s ), "[extra] set_custom_scale" )
   s[ "scale_denominator" ] := 0.0 ; Chk( Pls_ScaleFactor( s ) == 1.0, "[extra] scale_factor con denominador 0" )
   Pls_SetStandardScale( s, SCT_TEN_TO_ONE ) ; Chk( s[ "scale_numerator" ] == 10.0 .AND. s[ "scale_denominator" ] == 1.0 .AND. s[ "flags" ][ "use_standard_scale" ] .AND. ! Pls_IsScaleToFit( s ), "[extra] set_standard_scale" )
   Pls_SetScaleToFit( s ) ; Chk( ! s[ "flags" ][ "use_standard_scale" ] .AND. Pls_IsScaleToFit( s ), "[extra] set_scale_to_fit" )
   Pls_SetPaperWithMargins( s, 210.0, 297.0, Pmg_Uniform( 5.0 ) ) ; Chk( Pls_PrintableWidth( s ) == 200.0 .AND. Pls_PrintableHeight( s ) == 287.0, "[extra] printable width/height" )
   Pls_SetPlotWindow( s, 3.0, 3.0, 1.0, 1.0 ) ; Chk( s[ "plot_type" ] == PLT_WINDOW .AND. s[ "plot_window" ][ "lower_left_x" ] == 1.0, "[extra] set_plot_window" )
   s := Pls_WithScale( Pls_WithUnits( Pls_WithRotation( Pls_WithPrinter( Pls_WithPaperSize( Pls_WithPaper( "A", "A4" ), "A3" ), "HP" ), PRT_DEGREES90 ), PPU_MILLIMETERS ), 2.0, 1.0 )
   Chk( s[ "paper_size" ] == "A3" .AND. s[ "printer_name" ] == "HP" .AND. s[ "rotation" ] == PRT_DEGREES90 .AND. s[ "paper_units" ] == PPU_MILLIMETERS .AND. Pls_ScaleFactor( s ) == 2.0, "[extra] builders with_*" )
RETURN
