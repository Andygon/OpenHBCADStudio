/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/obj_classobj.prg
   Origen Rust: opencadcodec/src/objects/class_object.rs (el fichero Rust no tiene #[test]; los tests son [extra]).
   Licencia del original: MPL-2.0.
   Prefijo: Cob_ (Cob_New<Struct>() = Default de cada struct, generado mecanicamente del Rust: 66 structs).
   ClassObject = hash { handle, owner, reactors, xdictionary_handle, data }. data = hash { "_kind": nombre de variante, "value": struct o NIL }.
   Option -> NIL. [T;N] -> array de N. Vector2/3 -> Vc2/Vc3. ViewRepSketchGeometry = hash { "_kind": "None"|"Line"|"Circle"|"Nurb", ... }.
   VbaProject.storage (StructuredStoragePayload) queda NIL: depende de compound_file (aplazado).
   visit_handles_mut: el bloque recibe un handle y DEVUELVE el nuevo (los enteros no son referencias).
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Cob_NewViewRepSourceManager()
RETURN hb_Hash( ;
      "has_source", .F., ;
      "source", 0, ;
      "status", 0 )

FUNCTION Cob_NewViewRepStandard()
RETURN hb_Hash( ;
      "values", { 0, 0, 0, 0, 0, 0 } )

FUNCTION Cob_NewViewRepOrientation()
RETURN hb_Hash( ;
      "camera", Vc3_Zero(), ;
      "target", Vc3_Zero(), ;
      "normal", Vc3_Zero() )

FUNCTION Cob_NewViewRepSectionDefinition()
RETURN hb_Hash( ;
      "version", 0, ;
      "section_depth", 0.0, ;
      "flags", { 0, 0 } )

FUNCTION Cob_NewViewRepModelSpaceViewSelectionSet()
RETURN hb_Hash( ;
      "version", 0, ;
      "entities", {} )

FUNCTION Cob_NewViewRepGuid()
RETURN hb_Hash( ;
      "data1", 0, ;
      "data2", 0, ;
      "data3", 0, ;
      "data4", { 0, 0, 0, 0, 0, 0, 0, 0 } )

FUNCTION Cob_NewViewRepModelSpaceSource()
RETURN hb_Hash( ;
      "enabled", .F., ;
      "header_values", { 0, 0, 0, 0, 0, 0 }, ;
      "transform", { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 }, ;
      "source_version", 0, ;
      "source_status", 0, ;
      "model", 0, ;
      "guid", Cob_NewViewRepGuid(), ;
      "references", { 0, 0 }, ;
      "tail_values", { 0, 0 }, ;
      "orientation", 0 )

FUNCTION Cob_NewViewRepSketchReference()
RETURN hb_Hash( ;
      "object", 0, ;
      "flag", .F. )

FUNCTION Cob_NewViewRepSketch()
RETURN hb_Hash( ;
      "id", 0, ;
      "version", 0, ;
      "references", {}, ;
      "reserved", 0, ;
      "enabled", .F., ;
      "geometry", hb_Hash( "_kind", "None" ), ;
      "final_flag", .F. )

FUNCTION Cob_NewViewRepObjectPath()
RETURN hb_Hash( ;
      "class_name", "", ;
      "objects", {} )

FUNCTION Cob_NewViewRepBlockPathEntry()
RETURN hb_Hash( ;
      "flag", 0, ;
      "kind", 0, ;
      "object", 0 )

FUNCTION Cob_NewViewRepBlockPath()
RETURN hb_Hash( ;
      "class_name", "", ;
      "version", 0, ;
      "entries", {} )

FUNCTION Cob_NewViewRep()
RETURN hb_Hash( ;
      "header_values", { 0, 0, 0, 0, 0 }, ;
      "name", "", ;
      "scale", 0, ;
      "header_status", 0, ;
      "description", "", ;
      "source_id", 0, ;
      "source_enabled", .F., ;
      "source_version", 0, ;
      "model_id", 0, ;
      "guid", Cob_NewViewRepGuid(), ;
      "marker", 0, ;
      "transform", { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 }, ;
      "transform_version", 0, ;
      "database_id", 0, ;
      "geometry_version", 0, ;
      "geometry_marker", 0, ;
      "sketches", {}, ;
      "related_objects", { 0, 0 }, ;
      "source_manager", 0, ;
      "owned_objects", { 0, 0 }, ;
      "optional_objects", { 0, 0 }, ;
      "position", Vc2_Zero(), ;
      "rotation", 0.0, ;
      "orientation", 0, ;
      "is_active", .F., ;
      "projection", 0, ;
      "linked_views", { 0, 0 }, ;
      "section_sketches", {}, ;
      "action_mode", 0, ;
      "action", NIL, ;
      "has_parent", .F., ;
      "parent", 0, ;
      "tail_version", 0, ;
      "tail_state", 0, ;
      "tail_id", 0, ;
      "path_count", 0, ;
      "path_version", 0, ;
      "path_id", 0, ;
      "has_block_path", .F., ;
      "block_path", NIL, ;
      "style", 0 )

FUNCTION Cob_NewAcMeCommandHistory()
RETURN hb_Hash( ;
      "class_version", 0 )

FUNCTION Cob_NewAcMeScope()
RETURN hb_Hash( ;
      "class_version", 0 )

FUNCTION Cob_NewAcMeStateManager()
RETURN hb_Hash( ;
      "class_version", 0 )

FUNCTION Cob_NewCsacDocumentOptions()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "raw_dwg_data", NIL, ;
      "raw_dwg_handle_bits", 0, ;
      "raw_dwg_version", NIL )

FUNCTION Cob_NewSpatialIndex()
RETURN hb_Hash( ;
      "last_updated_julian_day", 0, ;
      "last_updated_milliseconds", 0, ;
      "min_corner", Vc3_Zero(), ;
      "max_corner", Vc3_Zero(), ;
      "indexed_objects", {} )

FUNCTION Cob_NewLayerFilter()
RETURN hb_Hash( ;
      "names", {} )

FUNCTION Cob_NewPartialViewingIndexEntry()
RETURN hb_Hash( ;
      "extents_min", Vc3_Zero(), ;
      "extents_max", Vc3_Zero(), ;
      "object", 0 )

FUNCTION Cob_NewPartialViewingIndex()
RETURN hb_Hash( ;
      "has_entries", .F., ;
      "entries", {} )

FUNCTION Cob_NewVbaProject()
RETURN hb_Hash( ;
      "storage", NIL )

FUNCTION Cob_NewSectionManager()
RETURN hb_Hash( ;
      "is_live", .F., ;
      "sections", {} )

FUNCTION Cob_NewSectionGeometrySettings()
RETURN hb_Hash( ;
      "geometry_count", 0, ;
      "index", 0, ;
      "flags", 0, ;
      "color", Cl_Default(), ;
      "layer", "", ;
      "linetype", "", ;
      "linetype_scale", 0.0, ;
      "plot_style", "", ;
      "lineweight", 0, ;
      "face_transparency", 0, ;
      "edge_transparency", 0, ;
      "hatch_type", 0, ;
      "hatch_pattern", "", ;
      "hatch_angle", 0.0, ;
      "hatch_spacing", 0.0, ;
      "hatch_scale", 0.0 )

FUNCTION Cob_NewSectionTypeSettings()
RETURN hb_Hash( ;
      "section_type", 0, ;
      "generation", 0, ;
      "sources", {}, ;
      "destination_block", 0, ;
      "destination_file", "", ;
      "geometry", {} )

FUNCTION Cob_NewSectionSettings()
RETURN hb_Hash( ;
      "current_type", 0, ;
      "types", {} )

FUNCTION Cob_NewLightListEntry()
RETURN hb_Hash( ;
      "handle", 0, ;
      "name", "" )

FUNCTION Cob_NewLightList()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "lights", {} )

FUNCTION Cob_NewSun()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "is_on", .F., ;
      "color", Cl_Default(), ;
      "intensity", 0.0, ;
      "has_shadow", .F., ;
      "julian_day", 0, ;
      "milliseconds", 0, ;
      "is_daylight_savings_on", .F., ;
      "shadow_type", 0, ;
      "shadow_map_size", 0, ;
      "shadow_softness", 0 )

FUNCTION Cob_NewRenderSettings()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "name", "", ;
      "fog_enabled", .F., ;
      "fog_background_enabled", .F., ;
      "backfaces_enabled", .F., ;
      "environment_image_enabled", .F., ;
      "environment_image_filename", "", ;
      "description", "", ;
      "display_index", 0, ;
      "has_predefined", .F. )

FUNCTION Cob_NewMentalRayRenderSettings()
RETURN hb_Hash( ;
      "base", Cob_NewRenderSettings(), ;
      "version", 0, ;
      "sampling_min", 0, ;
      "sampling_max", 0, ;
      "sampling_filter", 0, ;
      "sampling_filter_width", 0.0, ;
      "sampling_filter_height", 0.0, ;
      "sampling_contrast", { 0.0, 0.0, 0.0, 0.0 }, ;
      "shadow_mode", 0, ;
      "shadow_maps_enabled", .F., ;
      "ray_tracing_enabled", .F., ;
      "ray_trace_depth", { 0, 0, 0 }, ;
      "global_illumination_enabled", .F., ;
      "global_illumination_sample_count", 0, ;
      "global_illumination_sample_radius_enabled", .F., ;
      "global_illumination_sample_radius", 0.0, ;
      "photons_per_light", 0, ;
      "photon_trace_depth", { 0, 0, 0 }, ;
      "final_gathering_enabled", .F., ;
      "final_gathering_ray_count", 0, ;
      "final_gathering_sample_radius_state", { .F., .F., .F. }, ;
      "final_gathering_sample_radius", { 0.0, 0.0 }, ;
      "light_luminance_scale", 0.0, ;
      "diagnostics_mode", 0, ;
      "diagnostics_grid_mode", 0, ;
      "diagnostics_grid_size", 0.0, ;
      "diagnostics_photon_mode", 0, ;
      "diagnostics_bsp_mode", 0, ;
      "export_mi_enabled", .F., ;
      "description", "", ;
      "tile_size", 0, ;
      "tile_order", 0, ;
      "memory_limit", 0, ;
      "diagnostics_samples_mode", .F., ;
      "energy_multiplier", 0.0 )

FUNCTION Cob_NewRapidRtRenderSettings()
RETURN hb_Hash( ;
      "base", Cob_NewRenderSettings(), ;
      "version", 0, ;
      "render_target", 0, ;
      "render_level", 0, ;
      "render_time", 0, ;
      "lighting_model", 0, ;
      "filter_type", 0, ;
      "filter_width", 0.0, ;
      "filter_height", 0.0 )

FUNCTION Cob_NewGradientBackground()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "color_top", 0, ;
      "color_middle", 0, ;
      "color_bottom", 0, ;
      "horizon", 0.0, ;
      "height", 0.0, ;
      "rotation", 0.0 )

FUNCTION Cob_NewGroundPlaneBackground()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "color_sky_zenith", 0, ;
      "color_sky_horizon", 0, ;
      "color_underground_horizon", 0, ;
      "color_underground_azimuth", 0, ;
      "color_near", 0, ;
      "color_far", 0 )

FUNCTION Cob_NewIblBackground()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "enabled", .F., ;
      "name", "", ;
      "rotation", 0.0, ;
      "display_image", .F., ;
      "secondary_background", 0 )

FUNCTION Cob_NewImageBackground()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "filename", "", ;
      "fit_to_screen", .F., ;
      "maintain_aspect_ratio", .F., ;
      "use_tiling", .F., ;
      "offset", Vc2_Zero(), ;
      "scale", Vc2_Zero() )

FUNCTION Cob_NewSkyLightBackground()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "sun", 0 )

FUNCTION Cob_NewSolidBackground()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "color", 0 )

FUNCTION Cob_NewRenderEntry()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "image_filename", "", ;
      "preset_name", "", ;
      "view_name", "", ;
      "width", 0, ;
      "height", 0, ;
      "start_year", 0, ;
      "start_month", 0, ;
      "start_day", 0, ;
      "start_hour", 0, ;
      "start_minute", 0, ;
      "start_second", 0, ;
      "start_millisecond", 0, ;
      "end_year", 0, ;
      "end_month", 0, ;
      "end_day", 0, ;
      "end_hour", 0, ;
      "end_minute", 0, ;
      "end_second", 0, ;
      "end_millisecond", 0, ;
      "render_time", 0.0, ;
      "memory_amount", 0, ;
      "material_count", 0, ;
      "light_count", 0, ;
      "triangle_count", 0, ;
      "display_index", 0 )

FUNCTION Cob_NewRenderEnvironment()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "fog_enabled", .F., ;
      "fog_background_enabled", .F., ;
      "fog_color", { 0, 0, 0 }, ;
      "fog_density_near", 0.0, ;
      "fog_density_far", 0.0, ;
      "fog_distance_near", 0.0, ;
      "fog_distance_far", 0.0, ;
      "environment_image_enabled", .F., ;
      "environment_image_filename", "" )

FUNCTION Cob_NewRenderGlobal()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "procedure", 0, ;
      "destination", 0, ;
      "save_enabled", .F., ;
      "save_filename", "", ;
      "image_width", 0, ;
      "image_height", 0, ;
      "predefined_presets_first", .F., ;
      "high_level_info", .F. )

FUNCTION Cob_NewMotionPath()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "camera_path", 0, ;
      "target_path", 0, ;
      "view", 0, ;
      "frames", 0, ;
      "frame_rate", 0, ;
      "corner_deceleration", .F. )

FUNCTION Cob_NewCurvePath()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "entity", 0 )

FUNCTION Cob_NewPointPath()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "point", Vc3_Zero() )

FUNCTION Cob_NewTvDeviceProperties()
RETURN hb_Hash( ;
      "flags", 0, ;
      "max_regen_threads", 0, ;
      "use_lut_palette", 0, ;
      "alternate_highlight", 0, ;
      "alternate_highlight_color", 0, ;
      "geometry_shader_usage", 0, ;
      "blending_mode", 0, ;
      "antialiasing_level", 0.0, ;
      "reserved_double", 0.0 )

FUNCTION Cob_NewPointCloudDefinition()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "source_filename", "", ;
      "is_loaded", .F., ;
      "point_count", 0, ;
      "extents_min", Vc3_Zero(), ;
      "extents_max", Vc3_Zero() )

FUNCTION Cob_NewPointCloudDefinitionReactor()
RETURN hb_Hash( ;
      "class_version", 0 )

FUNCTION Cob_NewPointCloudColorRamp()
RETURN hb_Hash( ;
      "id", "", ;
      "class_version", 0, ;
      "colors", {}, ;
      "name", "" )

FUNCTION Cob_NewPointCloudRampColor()
RETURN hb_Hash( ;
      "color", 0, ;
      "visible", .F. )

FUNCTION Cob_NewPointCloudColorMap()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "default_intensity_scheme", "", ;
      "default_elevation_scheme", "", ;
      "default_classification_scheme", "", ;
      "color_ramps", {}, ;
      "classification_color_ramps", {} )

FUNCTION Cob_NewNavisworksModelDefinition()
RETURN hb_Hash( ;
      "flags", 0, ;
      "path", "", ;
      "status", .F., ;
      "extents_min", Vc3_Zero(), ;
      "extents_max", Vc3_Zero(), ;
      "host_drawing_visibility", .F. )

FUNCTION Cob_NewContextDataEntry()
RETURN hb_Hash( ;
      "item", 0, ;
      "name", "" )

FUNCTION Cob_NewContextDataSubManager()
RETURN hb_Hash( ;
      "handle", 0, ;
      "entries", {} )

FUNCTION Cob_NewContextDataManager()
RETURN hb_Hash( ;
      "object_context", 0, ;
      "sub_managers", {} )

FUNCTION Cob_NewSunStudyDate()
RETURN hb_Hash( ;
      "julian_day", 0, ;
      "milliseconds", 0 )

FUNCTION Cob_NewSunStudy()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "setup_name", "", ;
      "description", "", ;
      "output_type", 0, ;
      "use_subset", .F., ;
      "sheet_set_name", "", ;
      "sheet_subset_name", "", ;
      "select_dates_from_calendar", .F., ;
      "dates", {}, ;
      "select_range_of_dates", .F., ;
      "start_time", 0, ;
      "end_time", 0, ;
      "interval", 0, ;
      "hours", {}, ;
      "shade_plot_type", 0, ;
      "viewport_count", 0, ;
      "rows", 0, ;
      "columns", 0, ;
      "spacing", 0.0, ;
      "lock_viewports", .F., ;
      "label_viewports", .F., ;
      "page_setup_wizard", 0, ;
      "view", 0, ;
      "visual_style", 0, ;
      "text_style", 0 )

FUNCTION Cob_NewDataTableValue()
RETURN hb_Hash( ;
      "integer", 0, ;
      "real", 0.0, ;
      "text", "", ;
      "point", Vc3_Zero(), ;
      "handle", 0 )

FUNCTION Cob_NewDataTableColumn()
RETURN hb_Hash( ;
      "value_type", 0, ;
      "name", "", ;
      "rows", {} )

FUNCTION Cob_NewDataTable()
RETURN hb_Hash( ;
      "flags", 0, ;
      "name", "", ;
      "row_count", 0, ;
      "columns", {} )

FUNCTION Cob_NewDataLinkCustomData()
RETURN hb_Hash( ;
      "target", 0, ;
      "value", "" )

FUNCTION Cob_NewDataLink()
RETURN hb_Hash( ;
      "data_adapter", "", ;
      "description", "", ;
      "tooltip", "", ;
      "connection_string", "", ;
      "option", 0, ;
      "update_option", 0, ;
      "flags", 0, ;
      "year", 0, ;
      "month", 0, ;
      "day", 0, ;
      "hour", 0, ;
      "minute", 0, ;
      "second", 0, ;
      "millisecond", 0, ;
      "path_option", 0, ;
      "status_flags", 0, ;
      "update_status", "", ;
      "custom_data", {}, ;
      "hard_owner", 0 )

FUNCTION Cob_NewPersistentSubentityManager()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "reserved_zero", 0, ;
      "reserved_two", 0, ;
      "associated_step_count", 0, ;
      "associated_subentity_count", 0, ;
      "steps", {}, ;
      "subentities", {} )

FUNCTION Cob_NewGeoMapImage()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "origin", Vc3_Zero(), ;
      "image_size", Vc2_Zero(), ;
      "display_properties", 0, ;
      "clipping_enabled", .F., ;
      "brightness", 0, ;
      "contrast", 0, ;
      "fade", 0 )

FUNCTION Cob_NewModelDocViewStyle()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "description", "", ;
      "modified_for_recompute", .F., ;
      "display_name", "", ;
      "flags", 0 )

FUNCTION Cob_NewDetailViewStyle()
RETURN hb_Hash( ;
      "base", Cob_NewModelDocViewStyle(), ;
      "class_version", 0, ;
      "flags", 0, ;
      "identifier_style", 0, ;
      "identifier_color", Cl_Default(), ;
      "identifier_height", 0.0, ;
      "identifier_excluded_characters", "", ;
      "identifier_offset", 0.0, ;
      "identifier_placement", 0, ;
      "arrow_symbol", 0, ;
      "arrow_symbol_color", Cl_Default(), ;
      "arrow_symbol_size", 0.0, ;
      "boundary_linetype", 0, ;
      "boundary_lineweight", 0, ;
      "boundary_color", Cl_Default(), ;
      "view_label_text_style", 0, ;
      "view_label_text_color", Cl_Default(), ;
      "view_label_text_height", 0.0, ;
      "view_label_attachment", 0, ;
      "view_label_offset", 0.0, ;
      "view_label_alignment", 0, ;
      "view_label_pattern", "", ;
      "connection_linetype", 0, ;
      "connection_lineweight", 0, ;
      "connection_color", Cl_Default(), ;
      "border_linetype", 0, ;
      "border_lineweight", 0, ;
      "border_color", Cl_Default(), ;
      "model_edge", 0 )

FUNCTION Cob_NewSectionViewStyle()
RETURN hb_Hash( ;
      "base", Cob_NewModelDocViewStyle(), ;
      "class_version", 0, ;
      "flags", 0, ;
      "identifier_style", 0, ;
      "identifier_color", Cl_Default(), ;
      "identifier_height", 0.0, ;
      "arrow_start_symbol", 0, ;
      "arrow_end_symbol", 0, ;
      "arrow_symbol_color", Cl_Default(), ;
      "arrow_symbol_size", 0.0, ;
      "identifier_excluded_characters", "", ;
      "arrow_symbol_extension_length", 0.0, ;
      "plane_linetype", 0, ;
      "plane_lineweight", 0, ;
      "plane_color", Cl_Default(), ;
      "bend_linetype", 0, ;
      "bend_lineweight", 0, ;
      "bend_color", Cl_Default(), ;
      "bend_line_length", 0.0, ;
      "end_line_length", 0.0, ;
      "view_label_text_style", 0, ;
      "view_label_text_color", Cl_Default(), ;
      "view_label_text_height", 0.0, ;
      "view_label_attachment", 0, ;
      "view_label_offset", 0.0, ;
      "view_label_alignment", 0, ;
      "view_label_pattern", "", ;
      "hatch_color", Cl_Default(), ;
      "hatch_background_color", Cl_Default(), ;
      "hatch_pattern", "", ;
      "hatch_scale", 0.0, ;
      "hatch_transparency", 0, ;
      "reserved_flags", { .F., .F. }, ;
      "identifier_position", 0, ;
      "identifier_offset", 0.0, ;
      "arrow_position", 0, ;
      "end_line_overshoot", 0.0, ;
      "hatch_angles", {} )

FUNCTION Cob_Variants()
RETURN { ;
   { "Empty", "", "" }, ;
   { "SpatialIndex", "SPATIAL_INDEX", "SpatialIndex" }, ;
   { "LayerFilter", "LAYERFILTER", "LayerFilter" }, ;
   { "PartialViewingIndex", "PARTIAL_VIEWING_INDEX", "PartialViewingIndex" }, ;
   { "VbaProject", "VBA_PROJECT", "VbaProject" }, ;
   { "SectionManager", "SECTION_MANAGER", "SectionManager" }, ;
   { "SectionSettings", "SECTION_SETTINGS", "SectionSettings" }, ;
   { "LightList", "LIGHTLIST", "LightList" }, ;
   { "Sun", "SUN", "Sun" }, ;
   { "RenderSettings", "RENDERSETTINGS", "RenderSettings" }, ;
   { "MentalRayRenderSettings", "MENTALRAYRENDERSETTINGS", "MentalRayRenderSettings" }, ;
   { "RapidRtRenderSettings", "RAPIDRTRENDERSETTINGS", "RapidRtRenderSettings" }, ;
   { "GradientBackground", "GRADIENT_BACKGROUND", "GradientBackground" }, ;
   { "GroundPlaneBackground", "GROUND_PLANE_BACKGROUND", "GroundPlaneBackground" }, ;
   { "IblBackground", "RAPIDRTRENDERENVIRONMENT", "IblBackground" }, ;
   { "ImageBackground", "IMAGE_BACKGROUND", "ImageBackground" }, ;
   { "SkyLightBackground", "SKYLIGHT_BACKGROUND", "SkyLightBackground" }, ;
   { "SolidBackground", "SOLID_BACKGROUND", "SolidBackground" }, ;
   { "RenderEntry", "RENDERENTRY", "RenderEntry" }, ;
   { "RenderEnvironment", "RENDERENVIRONMENT", "RenderEnvironment" }, ;
   { "RenderGlobal", "RENDERGLOBAL", "RenderGlobal" }, ;
   { "MotionPath", "ACDBMOTIONPATH", "MotionPath" }, ;
   { "CurvePath", "ACDBCURVEPATH", "CurvePath" }, ;
   { "PointPath", "ACDBPOINTPATH", "PointPath" }, ;
   { "TvDeviceProperties", "TVDEVICEPROPERTIES", "TvDeviceProperties" }, ;
   { "PointCloudDefinition", "ACDBPOINTCLOUDDEF", "PointCloudDefinition" }, ;
   { "PointCloudDefinitionEx", "ACDBPOINTCLOUDDEF_EX", "PointCloudDefinition" }, ;
   { "PointCloudDefinitionReactor", "ACDBPOINTCLOUDDEF_REACTOR", "PointCloudDefinitionReactor" }, ;
   { "PointCloudDefinitionReactorEx", "ACDBPOINTCLOUDDEF_REACTOR_EX", "PointCloudDefinitionReactor" }, ;
   { "PointCloudColorMap", "ACDBPOINTCLOUDCOLORMAP", "PointCloudColorMap" }, ;
   { "NavisworksModelDefinition", "NAVISWORKSMODELDEF", "NavisworksModelDefinition" }, ;
   { "ContextDataManager", "CONTEXTDATAMANAGER", "ContextDataManager" }, ;
   { "SunStudy", "SUNSTUDY", "SunStudy" }, ;
   { "DataTable", "DATATABLE", "DataTable" }, ;
   { "DataLink", "DATALINK", "DataLink" }, ;
   { "PersistentSubentityManager", "ACDBPERSSUBENTMANAGER", "PersistentSubentityManager" }, ;
   { "GeoMapImage", "GEOMAPIMAGE", "GeoMapImage" }, ;
   { "DetailViewStyle", "ACDBDETAILVIEWSTYLE", "DetailViewStyle" }, ;
   { "SectionViewStyle", "ACDBSECTIONVIEWSTYLE", "SectionViewStyle" }, ;
   { "AcMeCommandHistory", "ACMECOMMANDHISTORY", "AcMeCommandHistory" }, ;
   { "AcMeScope", "ACMESCOPE", "AcMeScope" }, ;
   { "AcMeStateManager", "ACMESTATEMGR", "AcMeStateManager" }, ;
   { "CsacDocumentOptions", "CSACDOCUMENTOPTIONS", "CsacDocumentOptions" }, ;
   { "ViewRepSourceManager", "ACDBVIEWREPSOURCEMGR", "ViewRepSourceManager" }, ;
   { "ViewRepStandard", "ACDBVIEWREPSTANDARD", "ViewRepStandard" }, ;
   { "ViewRepOrientationDefinition", "ACDBVIEWREPORIENTATIONDEF", "" }, ;
   { "ViewRepOrientation", "ACDBVIEWREPORIENTATION", "ViewRepOrientation" }, ;
   { "ViewRepSectionDefinition", "ACDBVIEWREPSECTIONDEFINITION", "ViewRepSectionDefinition" }, ;
   { "ViewRepModelSpaceViewSelectionSet", "ACDBSYMODELSPACEVIEWSELSET", "ViewRepModelSpaceViewSelectionSet" }, ;
   { "ViewRep", "ACDBVIEWREP", "ViewRep" }, ;
   { "ViewRepModelSpaceSource", "ACDBVIEWREPMODELSPACESOURCE", "ViewRepModelSpaceSource" } }
FUNCTION Cob_NewByName( c )
   SWITCH c
   CASE "AcMeCommandHistory" ; RETURN Cob_NewAcMeCommandHistory()
   CASE "AcMeScope" ; RETURN Cob_NewAcMeScope()
   CASE "AcMeStateManager" ; RETURN Cob_NewAcMeStateManager()
   CASE "ContextDataManager" ; RETURN Cob_NewContextDataManager()
   CASE "CsacDocumentOptions" ; RETURN Cob_NewCsacDocumentOptions()
   CASE "CurvePath" ; RETURN Cob_NewCurvePath()
   CASE "DataLink" ; RETURN Cob_NewDataLink()
   CASE "DataTable" ; RETURN Cob_NewDataTable()
   CASE "DetailViewStyle" ; RETURN Cob_NewDetailViewStyle()
   CASE "GeoMapImage" ; RETURN Cob_NewGeoMapImage()
   CASE "GradientBackground" ; RETURN Cob_NewGradientBackground()
   CASE "GroundPlaneBackground" ; RETURN Cob_NewGroundPlaneBackground()
   CASE "IblBackground" ; RETURN Cob_NewIblBackground()
   CASE "ImageBackground" ; RETURN Cob_NewImageBackground()
   CASE "LayerFilter" ; RETURN Cob_NewLayerFilter()
   CASE "LightList" ; RETURN Cob_NewLightList()
   CASE "MentalRayRenderSettings" ; RETURN Cob_NewMentalRayRenderSettings()
   CASE "MotionPath" ; RETURN Cob_NewMotionPath()
   CASE "NavisworksModelDefinition" ; RETURN Cob_NewNavisworksModelDefinition()
   CASE "PartialViewingIndex" ; RETURN Cob_NewPartialViewingIndex()
   CASE "PersistentSubentityManager" ; RETURN Cob_NewPersistentSubentityManager()
   CASE "PointCloudColorMap" ; RETURN Cob_NewPointCloudColorMap()
   CASE "PointCloudDefinition" ; RETURN Cob_NewPointCloudDefinition()
   CASE "PointCloudDefinitionReactor" ; RETURN Cob_NewPointCloudDefinitionReactor()
   CASE "PointPath" ; RETURN Cob_NewPointPath()
   CASE "RapidRtRenderSettings" ; RETURN Cob_NewRapidRtRenderSettings()
   CASE "RenderEntry" ; RETURN Cob_NewRenderEntry()
   CASE "RenderEnvironment" ; RETURN Cob_NewRenderEnvironment()
   CASE "RenderGlobal" ; RETURN Cob_NewRenderGlobal()
   CASE "RenderSettings" ; RETURN Cob_NewRenderSettings()
   CASE "SectionManager" ; RETURN Cob_NewSectionManager()
   CASE "SectionSettings" ; RETURN Cob_NewSectionSettings()
   CASE "SectionViewStyle" ; RETURN Cob_NewSectionViewStyle()
   CASE "SkyLightBackground" ; RETURN Cob_NewSkyLightBackground()
   CASE "SolidBackground" ; RETURN Cob_NewSolidBackground()
   CASE "SpatialIndex" ; RETURN Cob_NewSpatialIndex()
   CASE "Sun" ; RETURN Cob_NewSun()
   CASE "SunStudy" ; RETURN Cob_NewSunStudy()
   CASE "TvDeviceProperties" ; RETURN Cob_NewTvDeviceProperties()
   CASE "VbaProject" ; RETURN Cob_NewVbaProject()
   CASE "ViewRep" ; RETURN Cob_NewViewRep()
   CASE "ViewRepModelSpaceSource" ; RETURN Cob_NewViewRepModelSpaceSource()
   CASE "ViewRepModelSpaceViewSelectionSet" ; RETURN Cob_NewViewRepModelSpaceViewSelectionSet()
   CASE "ViewRepOrientation" ; RETURN Cob_NewViewRepOrientation()
   CASE "ViewRepSectionDefinition" ; RETURN Cob_NewViewRepSectionDefinition()
   CASE "ViewRepSourceManager" ; RETURN Cob_NewViewRepSourceManager()
   CASE "ViewRepStandard" ; RETURN Cob_NewViewRepStandard()
   ENDSWITCH
RETURN NIL

FUNCTION Cob_VarRow( cKind )
   LOCAL r
   FOR EACH r IN Cob_Variants()
      IF r[ 1 ] == cKind ; RETURN r ; ENDIF
   NEXT
RETURN NIL

FUNCTION Cob_NewData( cKind )
   LOCAL r := Cob_VarRow( cKind )
   IF r == NIL .OR. Empty( r[ 3 ] )
      RETURN hb_Hash( "_kind", cKind, "value", NIL )
   ENDIF
RETURN hb_Hash( "_kind", cKind, "value", Cob_NewByName( r[ 3 ] ) )

FUNCTION Cob_DataDxfName( d )
   LOCAL r := Cob_VarRow( d[ "_kind" ] )
RETURN iif( r == NIL, "", r[ 2 ] )

FUNCTION Cob_New( data )
RETURN hb_Hash( "_type", "ClassObject", "handle", 0, "owner", 0, "reactors", {}, "xdictionary_handle", NIL, "data", iif( data == NIL, Cob_NewData( "Empty" ), data ) )

FUNCTION Cob_DxfName( o ) ; RETURN Cob_DataDxfName( o[ "data" ] )

STATIC PROCEDURE Cob_VL( a, b )
   LOCAL i
   FOR i := 1 TO Len( a )
      a[ i ] := Eval( b, a[ i ] )
   NEXT
RETURN

PROCEDURE Cob_VisitHandlesMut( o, b )
   o[ "owner" ] := Eval( b, o[ "owner" ] )
   Cob_VL( o[ "reactors" ], b )
   IF o[ "xdictionary_handle" ] != NIL ; o[ "xdictionary_handle" ] := Eval( b, o[ "xdictionary_handle" ] ) ; ENDIF
   Cob_VisitData( o[ "data" ], b )
RETURN

PROCEDURE Cob_VisitData( d, b )
   LOCAL v := d[ "value" ], c, row, s, m, e, sk, rf, p
   SWITCH d[ "_kind" ]
   CASE "DataTable"
      FOR EACH c IN v[ "columns" ]
         IF Dtc_IsObjectId( c[ "value_type" ] )
            FOR EACH row IN c[ "rows" ] ; row[ "handle" ] := Eval( b, row[ "handle" ] ) ; NEXT
         ENDIF
      NEXT
      EXIT
   CASE "SpatialIndex" ; Cob_VL( v[ "indexed_objects" ], b ) ; EXIT
   CASE "PartialViewingIndex"
      FOR EACH e IN v[ "entries" ] ; e[ "object" ] := Eval( b, e[ "object" ] ) ; NEXT
      EXIT
   CASE "SectionManager" ; Cob_VL( v[ "sections" ], b ) ; EXIT
   CASE "SectionSettings"
      FOR EACH s IN v[ "types" ]
         Cob_VL( s[ "sources" ], b )
         s[ "destination_block" ] := Eval( b, s[ "destination_block" ] )
      NEXT
      EXIT
   CASE "LightList"
      FOR EACH e IN v[ "lights" ] ; e[ "handle" ] := Eval( b, e[ "handle" ] ) ; NEXT
      EXIT
   CASE "IblBackground" ; v[ "secondary_background" ] := Eval( b, v[ "secondary_background" ] ) ; EXIT
   CASE "SkyLightBackground" ; v[ "sun" ] := Eval( b, v[ "sun" ] ) ; EXIT
   CASE "MotionPath"
      v[ "camera_path" ] := Eval( b, v[ "camera_path" ] )
      v[ "target_path" ] := Eval( b, v[ "target_path" ] )
      v[ "view" ] := Eval( b, v[ "view" ] )
      EXIT
   CASE "CurvePath" ; v[ "entity" ] := Eval( b, v[ "entity" ] ) ; EXIT
   CASE "ContextDataManager"
      v[ "object_context" ] := Eval( b, v[ "object_context" ] )
      FOR EACH m IN v[ "sub_managers" ]
         m[ "handle" ] := Eval( b, m[ "handle" ] )
         FOR EACH e IN m[ "entries" ] ; e[ "item" ] := Eval( b, e[ "item" ] ) ; NEXT
      NEXT
      EXIT
   CASE "SunStudy"
      v[ "page_setup_wizard" ] := Eval( b, v[ "page_setup_wizard" ] )
      v[ "view" ] := Eval( b, v[ "view" ] )
      v[ "visual_style" ] := Eval( b, v[ "visual_style" ] )
      v[ "text_style" ] := Eval( b, v[ "text_style" ] )
      EXIT
   CASE "DataLink"
      FOR EACH e IN v[ "custom_data" ] ; e[ "target" ] := Eval( b, e[ "target" ] ) ; NEXT
      v[ "hard_owner" ] := Eval( b, v[ "hard_owner" ] )
      EXIT
   CASE "DetailViewStyle"
      FOR EACH e IN { "identifier_style", "arrow_symbol", "boundary_linetype", "view_label_text_style", "connection_linetype", "border_linetype" }
         v[ e ] := Eval( b, v[ e ] )
      NEXT
      EXIT
   CASE "SectionViewStyle"
      FOR EACH e IN { "identifier_style", "arrow_start_symbol", "arrow_end_symbol", "plane_linetype", "bend_linetype", "view_label_text_style" }
         v[ e ] := Eval( b, v[ e ] )
      NEXT
      EXIT
   CASE "ViewRepSourceManager" ; v[ "source" ] := Eval( b, v[ "source" ] ) ; EXIT
   CASE "ViewRepModelSpaceViewSelectionSet" ; Cob_VL( v[ "entities" ], b ) ; EXIT
   CASE "ViewRep"
      FOR EACH sk IN v[ "sketches" ]
         FOR EACH rf IN sk[ "references" ] ; rf[ "object" ] := Eval( b, rf[ "object" ] ) ; NEXT
      NEXT
      Cob_VL( v[ "related_objects" ], b )
      v[ "source_manager" ] := Eval( b, v[ "source_manager" ] )
      Cob_VL( v[ "owned_objects" ], b )
      Cob_VL( v[ "optional_objects" ], b )
      v[ "orientation" ] := Eval( b, v[ "orientation" ] )
      Cob_VL( v[ "linked_views" ], b )
      FOR EACH p IN v[ "section_sketches" ] ; Cob_VL( p[ "objects" ], b ) ; NEXT
      IF v[ "action" ] != NIL ; v[ "action" ] := Eval( b, v[ "action" ] ) ; ENDIF
      v[ "parent" ] := Eval( b, v[ "parent" ] )
      IF v[ "block_path" ] != NIL
         FOR EACH e IN v[ "block_path" ][ "entries" ] ; e[ "object" ] := Eval( b, e[ "object" ] ) ; NEXT
      ENDIF
      v[ "style" ] := Eval( b, v[ "style" ] )
      EXIT
   CASE "ViewRepModelSpaceSource"
      v[ "model" ] := Eval( b, v[ "model" ] )
      Cob_VL( v[ "references" ], b )
      v[ "orientation" ] := Eval( b, v[ "orientation" ] )
      EXIT
   ENDSWITCH
RETURN

/* DataTableCellType (repr i32) */
FUNCTION Dtc_FromCode( n ) ; RETURN iif( n >= 1 .AND. n <= 11, n, NIL )
FUNCTION Dtc_IsObjectId( n ) ; RETURN n >= 5 .AND. n <= 9
FUNCTION Dtc_HasNativeCodec( n ) ; RETURN n >= 1 .AND. n <= 5

/* DataTableColumn::cell_type */
FUNCTION Dtcol_CellType( c ) ; RETURN Dtc_FromCode( c[ "value_type" ] )

/* DataTable::validate: NIL = Ok; si no, texto "InvalidFormat: ..." / "NotImplemented: ..." */
FUNCTION Dtb_Validate( t )
   LOCAL c
   IF t[ "row_count" ] < 0 ; RETURN "InvalidFormat: negative DATATABLE row count" ; ENDIF
   FOR EACH c IN t[ "columns" ]
      IF Dtcol_CellType( c ) == NIL .OR. ! Dtc_HasNativeCodec( c[ "value_type" ] )
         RETURN "NotImplemented: DATATABLE cell type " + hb_ntos( c[ "value_type" ] )
      ENDIF
      IF Len( c[ "rows" ] ) != t[ "row_count" ]
         RETURN "InvalidFormat: DATATABLE column " + c[ "name" ] + " has " + hb_ntos( Len( c[ "rows" ] ) ) + " rows, expected " + hb_ntos( t[ "row_count" ] )
      ENDIF
   NEXT
RETURN NIL

FUNCTION Mdv_DisplayNameOrDescription( m ) ; RETURN iif( Empty( m[ "display_name" ] ), m[ "description" ], m[ "display_name" ] )
