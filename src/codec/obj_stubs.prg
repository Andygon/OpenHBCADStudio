/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/obj_stubs.prg
   Origen Rust: opencadcodec/src/objects/stub_objects.rs, lineas 597-1195 (el fichero Rust no tiene #[test]; VisualStyle esta en obj_visualstyle.prg).
   Licencia del original: MPL-2.0.
   Prefijos: Mcl_ MaterialColor, Mtx_ MaterialTexture, Mmp_ MaterialMap, Mat_ Material, Gdt_ GeoData, Spf_ SpatialFilter, Rvr_ RasterVariables,
             Bkc_ BookColor, Plhd_ PlaceHolder, Ddf_ DictionaryWithDefault, Wov_ WipeoutVariables, Stb_ (trait StubObject: new_stub/set_handle/set_owner/handle).
   Structs = hashes con los nombres de campo Rust. [f64;16] -> array de 16. Vector2/3 -> { x, y [, z] }. Matrix4 -> Mx4_Identity(). Option -> NIL.
   MaterialProceduralValue = hash { "_kind": "Bool"|"Integer"|"Real"|"Color"|"Text"|"Table", "value": x } (Table = array de { nombre, MaterialTexture }).
   La comparacion `normal_map != MaterialMap::default()` de has_advanced_data se porta como NOT Mmp_IsDefault.
   Trait StubObject: impl solo para GeoData y PlaceHolder (impl_stub_object!), igual aqui.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Mcl_Default() ; RETURN hb_Hash( "flag", 0, "factor", 1.0, "rgb", NIL )
FUNCTION Mcl_Eq( a, b ) ; RETURN a[ "flag" ] == b[ "flag" ] .AND. a[ "factor" ] == b[ "factor" ] .AND. a[ "rgb" ] == b[ "rgb" ]

FUNCTION Mpv_New( cKind, xVal ) ; RETURN hb_Hash( "_kind", cKind, "value", xVal )

FUNCTION Mtx_Default() ; RETURN hb_Hash( "mode", 0, "color1", Mcl_Default(), "color2", Mcl_Default(), "procedural", NIL, "table_end", .F. )

FUNCTION Mmp_Default()
   LOCAL t := Array( 16 )
   AFill( t, 0.0 )
   t[ 1 ] := 1.0 ; t[ 6 ] := 1.0 ; t[ 11 ] := 1.0 ; t[ 16 ] := 1.0
RETURN hb_Hash( "blend_factor", 1.0, "projection", 2, "tiling", 1, "auto_transform", 1, "transform", t, "source", 0, "file_name", "", "texture", NIL )

FUNCTION Mmp_IsDefault( m )
   LOCAL d := Mmp_Default(), i
   IF m[ "blend_factor" ] != d[ "blend_factor" ] .OR. m[ "projection" ] != d[ "projection" ] .OR. m[ "tiling" ] != d[ "tiling" ] .OR. m[ "auto_transform" ] != d[ "auto_transform" ] ;
      .OR. m[ "source" ] != d[ "source" ] .OR. ! m[ "file_name" ] == d[ "file_name" ] .OR. m[ "texture" ] != NIL
      RETURN .F.
   ENDIF
   FOR i := 1 TO 16
      IF m[ "transform" ][ i ] != d[ "transform" ][ i ] ; RETURN .F. ; ENDIF
   NEXT
RETURN .T.

FUNCTION Mat_New()
RETURN hb_Hash( "_type", "Material", "handle", Hd_Null(), "owner", Hd_Null(), "reactors", {}, "xdictionary_handle", NIL, "name", "", "description", "", ;
   "ambient_color", Mcl_Default(), "diffuse_color", Mcl_Default(), "diffuse_map", Mmp_Default(), "specular_color", Mcl_Default(), "specular_map", Mmp_Default(), ;
   "specular_gloss_factor", 0.5, "reflection_map", Mmp_Default(), "opacity_percent", 1.0, "opacity_map", Mmp_Default(), "bump_map", Mmp_Default(), ;
   "refraction_index", 1.0, "refraction_map", Mmp_Default(), "translucence", 0.0, "self_illumination", 0.0, "reflectivity", 0.0, "illumination_model", 0, ;
   "channel_flags", 127, "mode", 0, "indirect_bump_scale", 1.0, "reflectance_scale", 1.0, "transmittance_scale", 1.0, "two_sided_material", .F., ;
   "luminance", 0.0, "luminance_mode", 0, "normal_map_method", 0, "normal_map_strength", 1.0, "normal_map", Mmp_Default(), "is_anonymous", .F., ;
   "global_illumination", 0, "final_gather", 0, "color_bleed_scale", 1.0, "advanced_data_present", .F. )
FUNCTION Mat_Default() ; RETURN Mat_New()

FUNCTION Mat_HasAdvancedData( m )
RETURN m[ "advanced_data_present" ] .OR. m[ "indirect_bump_scale" ] != 1.0 .OR. m[ "reflectance_scale" ] != 1.0 .OR. m[ "transmittance_scale" ] != 1.0 ;
   .OR. m[ "two_sided_material" ] .OR. m[ "luminance" ] != 0.0 .OR. m[ "luminance_mode" ] != 0 .OR. m[ "normal_map_method" ] != 0 .OR. m[ "normal_map_strength" ] != 1.0 ;
   .OR. ! Mmp_IsDefault( m[ "normal_map" ] ) .OR. m[ "is_anonymous" ] .OR. m[ "global_illumination" ] != 0 .OR. m[ "final_gather" ] != 0 .OR. m[ "color_bleed_scale" ] != 1.0

FUNCTION Gdm_Point( aSrc, aDst ) ; RETURN hb_Hash( "source", aSrc, "destination", aDst )
FUNCTION Gdm_Face( a, b, c ) ; RETURN hb_Hash( "first", a, "second", b, "third", c )

FUNCTION Gdt_New()
RETURN hb_Hash( "_type", "GeoData", "handle", Hd_Null(), "owner", Hd_Null(), "reactors", {}, "xdictionary_handle", NIL, "version", 2, "host_block", Hd_Null(), "coordinate_type", 0, ;
   "design_point", { 0.0, 0.0, 0.0 }, "reference_point", { 0.0, 0.0, 0.0 }, "obsolete_observation_point", { 0.0, 0.0, 0.0 }, "obsolete_scale_vector", { 1.0, 1.0, 1.0 }, ;
   "north_direction", { 0.0, 0.0 }, "up_direction", { 0.0, 0.0, 0.0 }, "horizontal_unit_scale", 1.0, "vertical_unit_scale", 1.0, "horizontal_units", 0, "vertical_units", 0, ;
   "scale_estimation_method", 0, "user_scale_factor", 1.0, "sea_level_correction", .F., "sea_level_elevation", 0.0, "coordinate_projection_radius", 0.0, ;
   "coordinate_system_definition", "", "coordinate_system_datum", "", "coordinate_system_wkt", "", "geo_rss_tag", "", "observation_from_tag", "", "observation_to_tag", "", ;
   "observation_coverage_tag", "", "mesh_points", {}, "mesh_faces", {}, "civil_data_present", .F., "civil_obsolete_flag", .F., "civil_reference_point1", { 0.0, 0.0 }, ;
   "civil_reference_point2", { 0.0, 0.0 }, "civil_unknown1", 0, "civil_unknown2", 0, "civil_unknown_flag1", .F., "civil_zero_point1", { 0.0, 0.0 }, "civil_zero_point2", { 0.0, 0.0 }, ;
   "civil_unknown_flag2", .F., "civil_north_angle_degrees", 0.0, "civil_north_angle_radians", 0.0 )
FUNCTION Gdt_Default() ; RETURN Gdt_New()

FUNCTION Spf_New()
RETURN hb_Hash( "_type", "SpatialFilter", "handle", Hd_Null(), "owner", Hd_Null(), "boundary_points", {}, "normal", { 0.0, 0.0, 1.0 }, "origin", { 0.0, 0.0, 0.0 }, ;
   "display_enabled", .T., "front_clip", NIL, "back_clip", NIL, "inverse_block_transform", Mx4_Identity(), "clip_bound_transform", Mx4_Identity() )
FUNCTION Spf_Default() ; RETURN Spf_New()

FUNCTION Rvr_New() ; RETURN hb_Hash( "_type", "RasterVariables", "handle", Hd_Null(), "owner", Hd_Null(), "class_version", 0, "display_image_frame", 1, "image_quality", 1, "units", 0 )
FUNCTION Rvr_Default() ; RETURN Rvr_New()

FUNCTION Bkc_New() ; RETURN hb_Hash( "_type", "BookColor", "handle", Hd_Null(), "owner", Hd_Null(), "color", Cl_Default(), "color_name", "", "book_name", "" )
FUNCTION Bkc_Default() ; RETURN Bkc_New()

FUNCTION Plhd_New() ; RETURN hb_Hash( "_type", "PlaceHolder", "handle", Hd_Null(), "owner", Hd_Null() )
FUNCTION Plhd_Default() ; RETURN Plhd_New()

FUNCTION Ddf_New() ; RETURN hb_Hash( "_type", "DictionaryWithDefault", "handle", Hd_Null(), "owner", Hd_Null(), "entries", {}, "default_handle", Hd_Null(), "duplicate_cloning", 1, "hard_owner", .F. )
FUNCTION Ddf_Default() ; RETURN Ddf_New()

FUNCTION Wov_New() ; RETURN hb_Hash( "_type", "WipeoutVariables", "handle", Hd_Null(), "owner", Hd_Null(), "display_frame", 1 )
FUNCTION Wov_Default() ; RETURN Wov_New()

/* trait StubObject (solo GeoData y PlaceHolder lo implementan) */
FUNCTION Stb_NewStub( cType )
   IF cType == "GeoData" ; RETURN Gdt_New() ; ENDIF
   IF cType == "PlaceHolder" ; RETURN Plhd_New() ; ENDIF
RETURN NIL
PROCEDURE Stb_SetHandle( o, n ) ; o[ "handle" ] := n ; RETURN
PROCEDURE Stb_SetOwner( o, n ) ; o[ "owner" ] := n ; RETURN
FUNCTION Stb_Handle( o ) ; RETURN o[ "handle" ]
