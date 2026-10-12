/* Tests: textstyle.rs (3 tests 1:1); view y vport sin #[test] en Rust ([extra]) */
#include "ocx.ch"
PROCEDURE T_CodecTables3()
   LOCAL s, v, p
   s := Tst_New( "MyStyle" ) ; Chk( s[ "name" ] == "MyStyle" .AND. s[ "width_factor" ] == 1.0 .AND. ! Tst_HasFixedHeight( s ), "textstyle_creation" )
   s := Tst_Standard() ; Chk( s[ "name" ] == "Standard" .AND. Tst_IsStandard( s ), "textstyle_standard" )
   s := Tst_New( "Test" ) ; Chk( ! Tst_IsBackward( s ) .AND. ! Tst_IsUpsideDown( s ), "textstyle_flags inicio" )
   Tst_SetBackward( s, .T. ) ; Chk( Tst_IsBackward( s ), "textstyle_flags backward" )
   Tst_SetUpsideDown( s, .T. ) ; Chk( Tst_IsUpsideDown( s ), "textstyle_flags upside_down" )
   s := Tst_WithTruetype( "T", "Arial" ) ; Chk( s[ "true_type_font" ] == "Arial" .AND. s[ "font_file" ] == "txt", "[extra] textstyle: with_truetype" )
   s[ "last_height" ] := 0.0 ; Chk( Tst_EffectiveLastHeight( s ) == 2.5, "[extra] textstyle: effective_last_height" )
   v := Viw_New( "V1" ) ; Chk( v[ "name" ] == "V1" .AND. v[ "lens_length" ] == 50.0 .AND. v[ "use_default_lights" ] .AND. v[ "default_lighting_type" ] == 1 .AND. Vc3_Eq( v[ "direction" ], Vc3_UnitZ() ), "[extra] view: valores por defecto" )
   p := Vpt_Active() ; Chk( Vpt_IsStandard( p ) .AND. p[ "circle_zoom" ] == 100 .AND. p[ "grid_major" ] == 5 .AND. p[ "grid_flags" ][ "adaptive" ] .AND. ! p[ "grid_flags" ][ "beyond_limits" ], "[extra] vport: active y grid_flags 2" )
RETURN
