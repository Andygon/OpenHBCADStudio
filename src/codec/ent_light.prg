/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_light.prg
   Origen Rust: opencadcodec/src/entities/light.rs (198, SIN tests en Rust). Licencia del original: MPL-2.0.
   Prefijos: Lpd_ (LightPhotometricData), Elt_ (Light, _type "LIGHT"). photometric_data: Option -> NIL. web_angles = array de 5 (base 1). Tests [extra] en t_codec_misc1.prg.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Elt_EntityName() ; RETURN "LIGHT"
FUNCTION Lpd_New()
RETURN hb_Hash( "has_web_file", .F., "web_file", "", "physical_intensity_method", 0, "physical_intensity", 0.0, "illuminance_distance", 0.0, "lamp_color_type", 0, "lamp_color_temperature", 0.0, ;
   "lamp_color_preset", 0, "web_rotation", Vc3_New( 1.0, 1.0, 1.0 ), "extended_light_shape", 0, "extended_light_length", 0.0, "extended_light_width", 0.0, "extended_light_radius", 0.0, ;
   "web_file_type", 0, "web_symmetry", 0, "has_target_grip", 0, "web_flux", 0.0, "web_angles", { 0.0, 0.0, 0.0, 0.0, 0.0 }, "glyph_display_type", 0 )
FUNCTION Elt_New()
RETURN hb_Hash( "_type", "LIGHT", "common", Ec_New(), "name", "", "class_version", 1, "light_type", 2, "position", Vc3_Zero(), "target", Vc3_Zero(), "status", .T., "light_color", Cl_White(), ;
   "plot_glyph", .F., "intensity", 1.0, "attenuation_type", 0, "use_attenuation_limits", .F., "attenuation_start_limit", 0.0, "attenuation_end_limit", 0.0, "hotspot_angle", 0.0, "falloff_angle", 0.0, ;
   "cast_shadows", .F., "shadow_type", 0, "shadow_map_size", 0, "shadow_map_softness", 0, "photometric_mode", .F., "photometric_data", NIL )
FUNCTION Elt_IsSpot( e ) ; RETURN e[ "light_type" ] == 3
FUNCTION Elt_IsDistant( e ) ; RETURN e[ "light_type" ] == 1
FUNCTION Elt_BoundingBox( e ) ; RETURN Bb3_FromPoint( e[ "position" ] )
FUNCTION Elt_Translate( e, vOff ) ; e[ "position" ] := Vc3_Add( e[ "position" ], vOff ) ; e[ "target" ] := Vc3_Add( e[ "target" ], vOff ) ; RETURN NIL
FUNCTION Elt_Transform( e, t ) ; e[ "position" ] := Tf_Apply( t, e[ "position" ] ) ; e[ "target" ] := Tf_Apply( t, e[ "target" ] ) ; RETURN NIL
