/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/tb_style.prg
   Origen Rust: opencadcodec/src/tables/textstyle.rs (209, 3 tests), view.rs (155) y vport.rs (208); view y vport no tienen #[test] (tests [extra] en t_codec_tables3.prg). Licencia del original: MPL-2.0.
   Prefijos: Tgf_ (TextGenerationFlags), Tst_ (TextStyle), Viw_ (View), Vpt_ (VPort). Entradas = hash con "handle" y "name" (ver tb_table.prg).
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Tgf_New() ; RETURN hb_Hash( "backward", .F., "upside_down", .F. )

FUNCTION Tst_New( cName )
RETURN hb_Hash( "handle", Hd_Null(), "name", cName, "flags", Tgf_New(), "height", 0.0, "width_factor", 1.0, "oblique_angle", 0.0, "last_height", 2.5, "font_file", "txt", ;
   "big_font_file", "", "true_type_font", "", "xref_dependent", .F., "xref_block_record_handle", Hd_Null(), "is_shape_file", .F., "is_vertical", .F., "annotative", .F. )
FUNCTION Tst_Standard() ; RETURN Tst_New( "Standard" )
FUNCTION Tst_WithTruetype( cName, cFont ) ; LOCAL s := Tst_New( cName ) ; s[ "true_type_font" ] := cFont ; RETURN s
FUNCTION Tst_EffectiveLastHeight( s ) ; RETURN iif( s[ "last_height" ] > 0.0, s[ "last_height" ], 2.5 )
FUNCTION Tst_SetBackward( s, l ) ; s[ "flags" ][ "backward" ] := l ; RETURN NIL
FUNCTION Tst_SetUpsideDown( s, l ) ; s[ "flags" ][ "upside_down" ] := l ; RETURN NIL
FUNCTION Tst_IsBackward( s ) ; RETURN s[ "flags" ][ "backward" ]
FUNCTION Tst_IsUpsideDown( s ) ; RETURN s[ "flags" ][ "upside_down" ]
FUNCTION Tst_HasFixedHeight( s ) ; RETURN s[ "height" ] > 0.0
FUNCTION Tst_IsStandard( s ) ; RETURN s[ "name" ] == "Standard"

FUNCTION Viw_New( cName )
RETURN hb_Hash( "handle", Hd_Null(), "name", cName, "center", Vc3_Zero(), "height", 1.0, "width", 1.0, "direction", Vc3_UnitZ(), "target", Vc3_Zero(), "lens_length", 50.0, ;
   "front_clip", 0.0, "back_clip", 0.0, "twist_angle", 0.0, "perspective", .F., "front_clipping", .F., "back_clipping", .F., "front_clip_at_eye", .F., "render_mode", VRM_WIREFRAME2D, ;
   "use_default_lights", .T., "default_lighting_type", 1, "brightness", 0.0, "contrast", 0.0, "ambient_color", Cl_FromIndex( 250 ), "paper_space", .F., "ucs_associated", .F., ;
   "ucs_origin", Vc3_Zero(), "ucs_x_axis", Vc3_UnitX(), "ucs_y_axis", Vc3_UnitY(), "ucs_elevation", 0.0, "ucs_ortho_type", 0, "camera_plottable", .F., ;
   "xref_reference", .F., "xref_resolved", .F., "xref_dependent", .F., "xref_handle", Hd_Null(), "background_handle", Hd_Null(), "live_section_handle", Hd_Null(), ;
   "visual_style_handle", Hd_Null(), "sun_handle", Hd_Null(), "named_ucs_handle", Hd_Null(), "base_ucs_handle", Hd_Null() )

FUNCTION Vpt_New( cName )
RETURN hb_Hash( "handle", Hd_Null(), "name", cName, "lower_left", Vc2_Zero(), "upper_right", Vc2_New( 1.0, 1.0 ), "view_center", Vc2_Zero(), "snap_base", Vc2_Zero(), ;
   "snap_spacing", Vc2_New( 0.5, 0.5 ), "grid_spacing", Vc2_New( 10.0, 10.0 ), "view_direction", Vc3_UnitZ(), "view_target", Vc3_Zero(), "view_height", 10.0, "aspect_ratio", 1.0, ;
   "lens_length", 50.0, "view_twist", 0.0, "front_clip", 0.0, "back_clip", 0.0, "ucsfollow", .F., "circle_zoom", 100, "fast_zoom", .T., "grid_on", .F., "snap_on", .F., ;
   "snap_style", .F., "snap_isopair", 0, "snap_rotation", 0.0, "render_mode", VRM_WIREFRAME2D, "perspective", .F., "front_clipping", .F., "back_clipping", .F., ;
   "front_clip_at_eye", .F., "ucsicon_lower", .T., "ucsicon_origin", .T., "use_default_lights", .T., "default_lighting_type", 1, "brightness", 0.0, "contrast", 0.0, ;
   "ambient_color", Cl_FromIndex( 250 ), "ucs_at_origin", .F., "ucs_per_viewport", .T., "ucs_origin", Vc3_Zero(), "ucs_x_axis", Vc3_UnitX(), "ucs_y_axis", Vc3_UnitY(), ;
   "ucs_elevation", 0.0, "ucs_ortho_type", 0, "grid_flags", Vgf_FromBits( 2 ), "grid_major", 5, "xref_reference", .F., "xref_resolved", .F., "xref_dependent", .F., ;
   "xref_handle", Hd_Null(), "background_handle", Hd_Null(), "visual_style_handle", Hd_Null(), "sun_handle", Hd_Null(), "named_ucs_handle", Hd_Null(), "base_ucs_handle", Hd_Null() )
FUNCTION Vpt_Active() ; RETURN Vpt_New( "*Active" )
FUNCTION Vpt_IsStandard( v ) ; RETURN v[ "name" ] == "*Active"
