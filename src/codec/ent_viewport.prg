/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_viewport.prg
   Origen Rust: opencadcodec/src/entities/viewport.rs (834, 12 tests) + translate_viewport + transform_viewport. Licencia del original: MPL-2.0.
   Prefijos: Vsf_ (ViewportStatusFlags, hash de booleanos), Vgf_ (GridFlags), Vrm_ (ViewportRenderMode, enteros 0..6 en ocx.ch VRM_*),
   Evp_ (Viewport). StandardView = enteros SV_* en ocx.ch. Handle = entero (Hd_Null() = 0). Option/enums por defecto como en Rust.
   from_bits/to_bits: bits como i32 (hb_bitAnd/hb_bitOr).
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Evp_EntityName() ; RETURN "VIEWPORT"

FUNCTION Vsf_New()
RETURN hb_Hash( "non_rectangular_clipping", .F., "is_off", .F., "is_on", .F., "perspective", .F., "front_clipping", .F., "back_clipping", .F., "ucs_follow", .F., "front_clip_not_at_eye", .F., ;
   "ucs_icon_visible", .F., "ucs_icon_at_origin", .F., "fast_zoom", .F., "snap_on", .F., "grid_on", .F., "isometric_snap", .F., "hide_plot", .F., "iso_pair_top", .F., "iso_pair_right", .F., "locked", .F. )
FUNCTION Vsf_DefaultOn() ; LOCAL f := Vsf_New() ; f[ "is_on" ] := .T. ; RETURN f
FUNCTION Vsf_FromBits( n )
   LOCAL f := Vsf_New()
   f[ "non_rectangular_clipping" ] := hb_bitAnd( n, 65536 ) != 0
   f[ "is_off" ] := hb_bitAnd( n, 131072 ) != 0
   f[ "perspective" ] := hb_bitAnd( n, 1 ) != 0
   f[ "front_clipping" ] := hb_bitAnd( n, 2 ) != 0
   f[ "back_clipping" ] := hb_bitAnd( n, 4 ) != 0
   f[ "ucs_follow" ] := hb_bitAnd( n, 8 ) != 0
   f[ "front_clip_not_at_eye" ] := hb_bitAnd( n, 16 ) != 0
   f[ "ucs_icon_visible" ] := hb_bitAnd( n, 32 ) != 0
   f[ "ucs_icon_at_origin" ] := hb_bitAnd( n, 64 ) != 0
   f[ "fast_zoom" ] := hb_bitAnd( n, 128 ) != 0
   f[ "snap_on" ] := hb_bitAnd( n, 256 ) != 0
   f[ "grid_on" ] := hb_bitAnd( n, 512 ) != 0
   f[ "isometric_snap" ] := hb_bitAnd( n, 1024 ) != 0
   f[ "hide_plot" ] := hb_bitAnd( n, 2048 ) != 0
   f[ "iso_pair_top" ] := hb_bitAnd( n, 4096 ) != 0
   f[ "iso_pair_right" ] := hb_bitAnd( n, 8192 ) != 0
   f[ "locked" ] := hb_bitAnd( n, 16384 ) != 0
   f[ "is_on" ] := hb_bitAnd( n, 32768 ) != 0
RETURN f
FUNCTION Vsf_ToBits( f )
   LOCAL n := 0
   IF f[ "is_off" ] ; n := hb_bitOr( n, 131072 ) ; ENDIF
   IF f[ "non_rectangular_clipping" ] ; n := hb_bitOr( n, 65536 ) ; ENDIF
   IF f[ "perspective" ] ; n := hb_bitOr( n, 1 ) ; ENDIF
   IF f[ "front_clipping" ] ; n := hb_bitOr( n, 2 ) ; ENDIF
   IF f[ "back_clipping" ] ; n := hb_bitOr( n, 4 ) ; ENDIF
   IF f[ "ucs_follow" ] ; n := hb_bitOr( n, 8 ) ; ENDIF
   IF f[ "front_clip_not_at_eye" ] ; n := hb_bitOr( n, 16 ) ; ENDIF
   IF f[ "ucs_icon_visible" ] ; n := hb_bitOr( n, 32 ) ; ENDIF
   IF f[ "ucs_icon_at_origin" ] ; n := hb_bitOr( n, 64 ) ; ENDIF
   IF f[ "fast_zoom" ] ; n := hb_bitOr( n, 128 ) ; ENDIF
   IF f[ "snap_on" ] ; n := hb_bitOr( n, 256 ) ; ENDIF
   IF f[ "grid_on" ] ; n := hb_bitOr( n, 512 ) ; ENDIF
   IF f[ "isometric_snap" ] ; n := hb_bitOr( n, 1024 ) ; ENDIF
   IF f[ "hide_plot" ] ; n := hb_bitOr( n, 2048 ) ; ENDIF
   IF f[ "iso_pair_top" ] ; n := hb_bitOr( n, 4096 ) ; ENDIF
   IF f[ "iso_pair_right" ] ; n := hb_bitOr( n, 8192 ) ; ENDIF
   IF f[ "locked" ] ; n := hb_bitOr( n, 16384 ) ; ENDIF
   IF f[ "is_on" ] ; n := hb_bitOr( n, 32768 ) ; ENDIF
RETURN n

FUNCTION Vrm_FromValue( n ) ; RETURN iif( n >= 1 .AND. n <= 6, n, 0 )
FUNCTION Vrm_ToValue( n ) ; RETURN n

FUNCTION Vgf_New() ; RETURN hb_Hash( "beyond_limits", .F., "adaptive", .F., "subdivision", .F., "follow_dynamic", .F. )
FUNCTION Vgf_FromBits( n ) ; RETURN hb_Hash( "beyond_limits", hb_bitAnd( n, 1 ) != 0, "adaptive", hb_bitAnd( n, 2 ) != 0, "subdivision", hb_bitAnd( n, 4 ) != 0, "follow_dynamic", hb_bitAnd( n, 8 ) != 0 )
FUNCTION Vgf_ToBits( g )
   LOCAL n := 0
   IF g[ "beyond_limits" ] ; n := hb_bitOr( n, 1 ) ; ENDIF
   IF g[ "adaptive" ] ; n := hb_bitOr( n, 2 ) ; ENDIF
   IF g[ "subdivision" ] ; n := hb_bitOr( n, 4 ) ; ENDIF
   IF g[ "follow_dynamic" ] ; n := hb_bitOr( n, 8 ) ; ENDIF
RETURN n

FUNCTION Evp_New()
RETURN hb_Hash( "_type", "VIEWPORT", "common", Ec_New(), "center", Vc3_Zero(), "width", 297.0, "height", 210.0, "status", Vsf_DefaultOn(), "id", 0, "off_screen", .F., ;
   "view_center", Vc3_Zero(), "snap_base", Vc3_Zero(), "snap_spacing", Vc3_New( 10.0, 10.0, 0.0 ), "grid_spacing", Vc3_New( 10.0, 10.0, 0.0 ), "view_direction", Vc3_UnitZ(), "view_target", Vc3_Zero(), ;
   "lens_length", 50.0, "front_clip_z", 0.0, "back_clip_z", 0.0, "view_height", 210.0, "snap_angle", 0.0, "twist_angle", 0.0, "circle_sides", 1000, "frozen_layers", {}, ;
   "clip_boundary_handle", Hd_Null(), "render_mode", VRM_WIREFRAME2D, "style_sheet", "", "ucs_at_origin", .F., "ucs_per_viewport", .F., "ucs_icon_visible", .T., ;
   "ucs_origin", Vc3_Zero(), "ucs_x_axis", Vc3_UnitX(), "ucs_y_axis", Vc3_UnitY(), "ucs_handle", Hd_Null(), "base_ucs_handle", Hd_Null(), "ucs_ortho_type", 0, "elevation", 0.0, ;
   "shade_plot_mode", 0, "grid_flags", Vgf_New(), "grid_major", 5, "background_handle", Hd_Null(), "shade_plot_handle", Hd_Null(), "visual_style_handle", Hd_Null(), "sun_handle", Hd_Null(), ;
   "default_lighting", .T., "default_lighting_type", 1, "brightness", 0.0, "contrast", 0.0, "ambient_color", Cl_FromIndex( 0 ), "custom_scale", 1.0 )
FUNCTION Evp_WithSize( vC, nW, nH ) ; LOCAL v := Evp_New() ; v[ "center" ] := vC ; v[ "width" ] := nW ; v[ "height" ] := nH ; RETURN v
FUNCTION Evp_ModelSpace() ; LOCAL v := Evp_New() ; v[ "id" ] := 1 ; RETURN v
FUNCTION Evp_SetViewTarget( v, vT ) ; v[ "view_target" ] := vT ; RETURN NIL
FUNCTION Evp_SetViewDirection( v, vD )
   LOCAL vN := Vc3_Normalize( vD )
   v[ "view_direction" ] := iif( Vc3_LengthSquared( vN ) > 0.0, vN, Vc3_UnitZ() )
RETURN NIL
FUNCTION Evp_SetViewHeight( v, n ) ; v[ "view_height" ] := n ; RETURN NIL
FUNCTION Evp_Scale( v ) ; RETURN iif( Abs( v[ "view_height" ] ) > 0.0000000001, v[ "height" ] / v[ "view_height" ], 1.0 )
FUNCTION Evp_SetScale( v, n )
   IF Abs( n ) > 0.0000000001 ; v[ "view_height" ] := v[ "height" ] / n ; v[ "custom_scale" ] := n ; ENDIF
RETURN NIL
FUNCTION Evp_Lock( v ) ; v[ "status" ][ "locked" ] := .T. ; RETURN NIL
FUNCTION Evp_Unlock( v ) ; v[ "status" ][ "locked" ] := .F. ; RETURN NIL
FUNCTION Evp_IsLocked( v ) ; RETURN v[ "status" ][ "locked" ]
FUNCTION Evp_TurnOn( v ) ; v[ "status" ][ "is_on" ] := .T. ; v[ "status" ][ "is_off" ] := .F. ; RETURN NIL
FUNCTION Evp_TurnOff( v ) ; v[ "status" ][ "is_on" ] := .F. ; v[ "status" ][ "is_off" ] := .T. ; RETURN NIL
FUNCTION Evp_IsOn( v ) ; RETURN v[ "status" ][ "is_on" ] .AND. ! v[ "status" ][ "is_off" ]
FUNCTION Evp_FreezeLayer( v, h )
   IF AScan( v[ "frozen_layers" ], {| x | x == h } ) == 0
      AAdd( v[ "frozen_layers" ], h )
   ENDIF
RETURN NIL
FUNCTION Evp_ThawLayer( v, h )
   LOCAL a := {}, x
   FOR EACH x IN v[ "frozen_layers" ]
      IF x != h
         AAdd( a, x )
      ENDIF
   NEXT
   v[ "frozen_layers" ] := a
RETURN NIL
FUNCTION Evp_SetRenderMode( v, n ) ; v[ "render_mode" ] := n ; RETURN NIL
FUNCTION Evp_PaperBounds( v )
   LOCAL nHw := v[ "width" ] / 2.0, nHh := v[ "height" ] / 2.0, c := v[ "center" ]
RETURN Bb3_New( Vc3_New( c[ 1 ] - nHw, c[ 2 ] - nHh, 0.0 ), Vc3_New( c[ 1 ] + nHw, c[ 2 ] + nHh, 0.0 ) )
FUNCTION Evp_SetStandardView( v, nView )
   LOCAL vD
   DO CASE
   CASE nView == SV_TOP ; vD := Vc3_New( 0.0, 0.0, 1.0 )
   CASE nView == SV_BOTTOM ; vD := Vc3_New( 0.0, 0.0, -1.0 )
   CASE nView == SV_FRONT ; vD := Vc3_New( 0.0, -1.0, 0.0 )
   CASE nView == SV_BACK ; vD := Vc3_New( 0.0, 1.0, 0.0 )
   CASE nView == SV_LEFT ; vD := Vc3_New( -1.0, 0.0, 0.0 )
   CASE nView == SV_RIGHT ; vD := Vc3_New( 1.0, 0.0, 0.0 )
   CASE nView == SV_SW_ISOMETRIC ; vD := Vc3_Normalize( Vc3_New( -1.0, -1.0, 1.0 ) )
   CASE nView == SV_SE_ISOMETRIC ; vD := Vc3_Normalize( Vc3_New( 1.0, -1.0, 1.0 ) )
   CASE nView == SV_NE_ISOMETRIC ; vD := Vc3_Normalize( Vc3_New( 1.0, 1.0, 1.0 ) )
   OTHERWISE ; vD := Vc3_Normalize( Vc3_New( -1.0, 1.0, 1.0 ) )
   ENDCASE
   v[ "view_direction" ] := vD ; v[ "twist_angle" ] := 0.0
RETURN NIL
/* builder por valor en Rust (consume self); aqui muta y devuelve el mismo hash */
FUNCTION Evp_WithCenter( v, vC ) ; v[ "center" ] := vC ; RETURN v
FUNCTION Evp_WithViewTarget( v, vT ) ; v[ "view_target" ] := vT ; RETURN v
FUNCTION Evp_WithViewDirection( v, vD ) ; Evp_SetViewDirection( v, vD ) ; RETURN v
FUNCTION Evp_WithScale( v, n ) ; Evp_SetScale( v, n ) ; RETURN v
FUNCTION Evp_WithLocked( v ) ; v[ "status" ][ "locked" ] := .T. ; RETURN v
FUNCTION Evp_BoundingBox( v ) ; RETURN Evp_PaperBounds( v )
FUNCTION Evp_Translate( v, vOff ) ; v[ "center" ] := Vc3_Add( v[ "center" ], vOff ) ; RETURN NIL
FUNCTION Evp_Transform( v, t )
   LOCAL nS := Vc3_Length( Tf_ApplyRotation( t, Vc3_New( 1.0, 0.0, 0.0 ) ) )
   v[ "center" ] := Tf_Apply( t, v[ "center" ] )
   v[ "width" ] *= nS ; v[ "height" ] *= nS
   v[ "view_direction" ] := Vc3_Normalize( Tf_ApplyRotation( t, v[ "view_direction" ] ) )
   v[ "ucs_x_axis" ] := Vc3_Normalize( Tf_ApplyRotation( t, v[ "ucs_x_axis" ] ) )
   v[ "ucs_y_axis" ] := Vc3_Normalize( Tf_ApplyRotation( t, v[ "ucs_y_axis" ] ) )
   v[ "ucs_origin" ] := Tf_Apply( t, v[ "ucs_origin" ] )
   v[ "view_target" ] := Tf_Apply( t, v[ "view_target" ] )
RETURN NIL
