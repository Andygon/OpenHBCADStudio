/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/obj_assoc.prg
   Origen Rust: opencadcodec/src/objects/associative.rs, lineas 1-1390 (los nombres L1390-1530 estan en obj_assocnames.prg).
   El fichero Rust no tiene #[test]; los tests son [extra]. Licencia del original: MPL-2.0.
   Prefijo: Aso_ (Aso_New<Struct>() = Default de los 47 structs, generado mecanicamente del Rust).
   AssociativeObject = hash { handle, owner, reactors, xdictionary_handle, dxf_name, cpp_class_name, data, source_version }.
   data = hash { "_kind": variante, "value": struct o NIL }. AssocEvalValue = { AEV_*, x }. AssocCurveValue = { ACV_*, x }.
   AssocConstraintNodeData = hash { "_kind": "None"|"Geometrical"|... , campos }. Enums simples -> enteros (ASK_*, AAK_*, AVK_*, ASC_*).
   AssocAsmBodyActionParam.acis_data = NIL y wires/silhouettes = {}: dependen del cluster ACIS (entities/acis, aplazado).
   references_handle y visit_handles_mut se portan por separado como en Rust (incluido que AsmBodyActionParam.history se visita al final).
   visit_handles_mut: el bloque recibe un handle y DEVUELVE el nuevo.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Aso_NewAssocDependency()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "status", 0, ;
      "is_read_dependency", .F., ;
      "is_write_dependency", .F., ;
      "is_attached_to_object", .F., ;
      "is_delegating_to_owning_action", .F., ;
      "order", 0, ;
      "dependent_on", 0, ;
      "name", NIL, ;
      "read_dependency", 0, ;
      "node", 0, ;
      "dependency_body", 0, ;
      "dependency_body_id", 0 )

FUNCTION Aso_NewAssocValueDependency()
RETURN hb_Hash( ;
      "dependency", Aso_NewAssocDependency(), ;
      "class_version", 0, ;
      "name", "", ;
      "value", Aso_NewAssocEvalVariant() )

FUNCTION Aso_NewAssocPersistentSubentId()
RETURN hb_Hash( ;
      "class_name", "", ;
      "dependent_on_compound_object", .F., ;
      "class_code", 0, ;
      "values", {}, ;
      "leading_flag", .F. )

FUNCTION Aso_NewAssocGeomDependency()
RETURN hb_Hash( ;
      "dependency", Aso_NewAssocDependency(), ;
      "class_version", 0, ;
      "enabled", .F., ;
      "persistent_subent", Aso_NewAssocPersistentSubentId() )

FUNCTION Aso_NewAssocEvalVariant()
RETURN hb_Hash( ;
      "code", 0, ;
      "value", { AEV_NONE, NIL } )

FUNCTION Aso_NewAssocValueParamVariable()
RETURN hb_Hash( ;
      "value", Aso_NewAssocEvalVariant(), ;
      "handle", 0 )

FUNCTION Aso_NewAssocValueParam()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "name", "", ;
      "unit_type", 0, ;
      "variables", {}, ;
      "controlled_object_dependency", 0 )

FUNCTION Aso_NewAssocActionDependency()
RETURN hb_Hash( ;
      "is_owned", .F., ;
      "dependency", 0 )

FUNCTION Aso_NewAssocAction()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "geometry_status", 0, ;
      "owning_network", 0, ;
      "action_body", 0, ;
      "action_index", 0, ;
      "max_dependency_index", 0, ;
      "dependencies", {}, ;
      "owned_parameters", {}, ;
      "values", {} )

FUNCTION Aso_NewAssocNetwork()
RETURN hb_Hash( ;
      "action", Aso_NewAssocAction(), ;
      "network_version", 0, ;
      "network_action_index", 0, ;
      "actions", {}, ;
      "owned_actions", {} )

FUNCTION Aso_NewAssocActionParam()
RETURN hb_Hash( ;
      "is_r2013", 0, ;
      "version", 0, ;
      "name", "" )

FUNCTION Aso_NewAssocActionBody()
RETURN hb_Hash( ;
      "version", 0 )

FUNCTION Aso_NewAssocParamBasedActionBody()
RETURN hb_Hash( ;
      "version", 0, ;
      "minor", 0, ;
      "dependencies", {}, ;
      "marker", 0, ;
      "values", {}, ;
      "empty_value_marker", 0, ;
      "dependency", 0 )

FUNCTION Aso_NewAssocSurfaceBody()
RETURN hb_Hash( ;
      "version", 0, ;
      "dependency", 0, ;
      "is_semi_associative", .F., ;
      "marker", 0, ;
      "is_semi_override", .F., ;
      "grip_status", 0 )

FUNCTION Aso_NewAssocSurfaceActionBody()
RETURN hb_Hash( ;
      "kind", 0, ;
      "action_body", Aso_NewAssocActionBody(), ;
      "parameter_body", Aso_NewAssocParamBasedActionBody(), ;
      "surface_body", Aso_NewAssocSurfaceBody(), ;
      "path_status", 0, ;
      "class_version", 0, ;
      "option", 0, ;
      "flags", { .F., .F., .F., .F., .F. }, ;
      "status", 0, ;
      "secondary_status", 0, ;
      "distance", 0.0, ;
      "first_point", Vc2_Zero(), ;
      "second_point", Vc2_Zero() )

FUNCTION Aso_NewAssocAnnotationBase()
RETURN hb_Hash( ;
      "action_body", Aso_NewAssocActionBody(), ;
      "parameter_body", Aso_NewAssocParamBasedActionBody(), ;
      "version", 0, ;
      "dependency", 0 )

FUNCTION Aso_NewAssocAnnotationDependency()
RETURN hb_Hash( ;
      "dependency_id", 0, ;
      "dependency", 0 )

FUNCTION Aso_NewAssocAnnotationActionBody()
RETURN hb_Hash( ;
      "kind", 0, ;
      "annotation", Aso_NewAssocAnnotationBase(), ;
      "action_body", Aso_NewAssocActionBody(), ;
      "class_version", 0, ;
      "entity", 0, ;
      "actions", {}, ;
      "read_node", 0, ;
      "dimension_node", 0, ;
      "dependency", 0 )

FUNCTION Aso_NewAssocPersSubentManager()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "markers", { 0, 0, 0 }, ;
      "values", {}, ;
      "final_flag", .F. )

FUNCTION Aso_NewAssocSingleDependencyActionParam()
RETURN hb_Hash( ;
      "action_param", Aso_NewAssocActionParam(), ;
      "dependency_class_version", 0, ;
      "dependency", 0, ;
      "class_version", 0 )

FUNCTION Aso_NewAssocSmartCenterActionBody()
RETURN hb_Hash( ;
      "action_body", Aso_NewAssocActionBody(), ;
      "parameter_body", Aso_NewAssocParamBasedActionBody(), ;
      "version", 0 )

FUNCTION Aso_NewAssocViewRepActionBody()
RETURN hb_Hash( ;
      "action_body", Aso_NewAssocActionBody(), ;
      "class_version", 0, ;
      "view_rep", 0, ;
      "view_type", 0, ;
      "rotation", 0.0 )

FUNCTION Aso_NewAssocViewObjectActionParam()
RETURN hb_Hash( ;
      "kind", 0, ;
      "single_dependency", Aso_NewAssocSingleDependencyActionParam(), ;
      "class_version", 0 )

FUNCTION Aso_NewAssocViewRepHatchManagerItem()
RETURN hb_Hash( ;
      "first_id", 0, ;
      "second_id", 0, ;
      "status", 0, ;
      "parameter", 0 )

FUNCTION Aso_NewAssocViewRepHatchManager()
RETURN hb_Hash( ;
      "compound", Aso_NewAssocCompoundActionParam(), ;
      "class_version", 0, ;
      "items", {} )

FUNCTION Aso_NewAssocViewRepHatchActionParam()
RETURN hb_Hash( ;
      "single_dependency", Aso_NewAssocSingleDependencyActionParam(), ;
      "class_version", 0, ;
      "normal", Vc3_Zero(), ;
      "hatch_index", 0, ;
      "flags", 0 )

FUNCTION Aso_NewAssocViewLabelActionParam()
RETURN hb_Hash( ;
      "single_dependency", Aso_NewAssocSingleDependencyActionParam(), ;
      "class_version", 0, ;
      "label_version", 0, ;
      "offset", Vc2_Zero(), ;
      "flag", 0 )

FUNCTION Aso_NewAssocEdgeActionParam()
RETURN hb_Hash( ;
      "single_dependency", Aso_NewAssocSingleDependencyActionParam(), ;
      "parameter", 0, ;
      "has_action", .F., ;
      "action_type", 0, ;
      "subcurve_kind", 0, ;
      "curve", {} )

FUNCTION Aso_NewAssocConstraintNode()
RETURN hb_Hash( ;
      "node_id", 0, ;
      "status", 0, ;
      "connections", {}, ;
      "class_name", "", ;
      "registry_flag", .F., ;
      "data", Aso_NewNodeData( "None" ) )

FUNCTION Aso_NewAssoc2dConstraintGroup()
RETURN hb_Hash( ;
      "action", Aso_NewAssocAction(), ;
      "version", 0, ;
      "flag", .F., ;
      "work_plane", { Vc3_Zero(), Vc3_Zero(), Vc3_Zero() }, ;
      "dependency", 0, ;
      "actions", {}, ;
      "nodes", {} )

FUNCTION Aso_NewAssocVariable()
RETURN hb_Hash( ;
      "action", Aso_NewAssocAction(), ;
      "class_version", 0, ;
      "name", "", ;
      "expression", "", ;
      "evaluator", "", ;
      "description", "", ;
      "value", Aso_NewAssocEvalVariant(), ;
      "has_cached_value", .F., ;
      "cached_value", "", ;
      "flag", .F., ;
      "dependencies", {} )

FUNCTION Aso_NewAssocVariableDependency()
RETURN hb_Hash( ;
      "dependency", 0, ;
      "flags", 0 )

FUNCTION Aso_NewAssocCompoundActionParam()
RETURN hb_Hash( ;
      "action_param", Aso_NewAssocActionParam(), ;
      "class_version", 0, ;
      "status", 0, ;
      "parameters", {}, ;
      "child_parameter", NIL )

FUNCTION Aso_NewAssocChildParameter()
RETURN hb_Hash( ;
      "status", 0, ;
      "id", 0, ;
      "parameter", 0, ;
      "secondary_parameter", 0, ;
      "marker", 0, ;
      "tertiary_parameter", 0 )

FUNCTION Aso_NewAssocOsnapPointRefActionParam()
RETURN hb_Hash( ;
      "compound", Aso_NewAssocCompoundActionParam(), ;
      "status", 0, ;
      "osnap_mode", 0, ;
      "parameter", 0.0 )

FUNCTION Aso_NewAssocPathActionParam()
RETURN hb_Hash( ;
      "compound", Aso_NewAssocCompoundActionParam(), ;
      "version", 0 )

FUNCTION Aso_NewAssocDimDependencyBody()
RETURN hb_Hash( ;
      "dependency_body_version", 0, ;
      "base_version", 0, ;
      "name", "", ;
      "class_version", 0 )

FUNCTION Aso_NewAssocFaceActionParam()
RETURN hb_Hash( ;
      "single_dependency", Aso_NewAssocSingleDependencyActionParam(), ;
      "index", 0 )

FUNCTION Aso_NewAssocVertexActionParam()
RETURN hb_Hash( ;
      "single_dependency", Aso_NewAssocSingleDependencyActionParam(), ;
      "point", Vc3_Zero() )

FUNCTION Aso_NewAssocAsmBodyActionParam()
RETURN hb_Hash( ;
      "single_dependency", Aso_NewAssocSingleDependencyActionParam(), ;
      "acis_data", NIL, ;
      "point_of_reference", Vc3_Zero(), ;
      "wires", {}, ;
      "silhouettes", {}, ;
      "history", 0 )

FUNCTION Aso_NewAssocArrayItem()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "location", { 0, 0, 0 }, ;
      "flags", 0, ;
      "uses_default_transform", .F., ;
      "x_direction", Vc3_Zero(), ;
      "transform", { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 }, ;
      "relative_transform", NIL, ;
      "first_handle", NIL, ;
      "second_handle", NIL )

FUNCTION Aso_NewAssocArrayParameters()
RETURN hb_Hash( ;
      "version", 0, ;
      "class_name", "", ;
      "items", {}, ;
      "item_count", 0, ;
      "row_count", 0, ;
      "level_count", 0 )

FUNCTION Aso_NewAssocArrayActionBody()
RETURN hb_Hash( ;
      "action_body", Aso_NewAssocActionBody(), ;
      "parameter_body", Aso_NewAssocParamBasedActionBody(), ;
      "version", 0, ;
      "parameter_block", "", ;
      "item_list_version", 0, ;
      "item_class", "", ;
      "items", {}, ;
      "transform", { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 } )

FUNCTION Aso_NewAssocArrayModifyActionBody()
RETURN hb_Hash( ;
      "body", Aso_NewAssocArrayActionBody(), ;
      "status", 0, ;
      "item_locations", {} )

FUNCTION Aso_NewAssocDimensionReference()
RETURN hb_Hash( ;
      "class_name", "", ;
      "osnap_type", 0, ;
      "xrefs", {}, ;
      "main_subent_type", 0, ;
      "main_gs_marker", 0, ;
      "xref_paths", {}, ;
      "osnap_distance", 0.0, ;
      "osnap_point", Vc3_Zero(), ;
      "intersection_objects", {}, ;
      "intersection_subent_type", 0, ;
      "intersection_gs_marker", 0, ;
      "intersection_xref_paths", {}, ;
      "has_last_point_reference", .F. )

FUNCTION Aso_NewAssocDimensionAssociation()
RETURN hb_Hash( ;
      "associativity", 0, ;
      "trans_space", .F., ;
      "rotated_type", 0, ;
      "dimension", 0, ;
      "references", { {}, {}, {}, {} } )

FUNCTION Aso_NewPersSubentManager()
RETURN hb_Hash( ;
      "class_version", 0, ;
      "marker_zero", 0, ;
      "marker_two", 0, ;
      "associative_step_count", 0, ;
      "associative_subent_count", 0, ;
      "values", {} )

FUNCTION Aso_NewNodeData( cKind )
   SWITCH cKind
   CASE "None" ; RETURN hb_Hash( "_kind", "None" )
   CASE "Geometrical" ; RETURN hb_Hash( "_kind", "Geometrical", "owner_id", 0, "is_implied", .F., "is_active", .F. )
   CASE "Composite" ; RETURN hb_Hash( "_kind", "Composite", "owner_id", 0, "is_implied", .F., "is_active", .F., "owned_constraint_ids", {} )
   CASE "HelpParameter" ; RETURN hb_Hash( "_kind", "HelpParameter", "value", 0.0, "reserved", .F. )
   CASE "Angle" ; RETURN hb_Hash( "_kind", "Angle", "owner_id", 0, "is_implied", .F., "is_active", .F., "value_dependency", 0, "dimension_dependency", 0, "sector_type", 0 )
   CASE "Parallel" ; RETURN hb_Hash( "_kind", "Parallel", "owner_id", 0, "is_implied", .F., "is_active", .F., "datum_line_index", NIL )
   CASE "Distance" ; RETURN hb_Hash( "_kind", "Distance", "owner_id", 0, "is_implied", .F., "is_active", .F., "value_dependency", 0, "dimension_dependency", 0, "direction_type", 0, "distance", NIL )
   CASE "RadiusDiameter" ; RETURN hb_Hash( "_kind", "RadiusDiameter", "owner_id", 0, "is_implied", .F., "is_active", .F., "value_dependency", 0, "dimension_dependency", 0, "mode", 0 )
   CASE "ImplicitPoint" ; RETURN hb_Hash( "_kind", "ImplicitPoint", "geometry_dependency", 0, "geometry_node_id", 0, "point", NIL, "point_type", 0, "point_index", 0, "curve_id", 0 )
   CASE "Point" ; RETURN hb_Hash( "_kind", "Point", "geometry_dependency", 0, "geometry_node_id", 0, "point", NIL )
   CASE "RigidSet" ; RETURN hb_Hash( "_kind", "RigidSet", "geometry_dependency", 0, "geometry_node_id", 0, "reserved", .F., "transform", { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 }, "geometry_ids", {} )
   CASE "Line" ; RETURN hb_Hash( "_kind", "Line", "geometry_dependency", 0, "geometry_node_id", 0, "point", Vc3_Zero(), "direction", Vc3_Zero() )
   CASE "BoundedLine" ; RETURN hb_Hash( "_kind", "BoundedLine", "geometry_dependency", 0, "geometry_node_id", 0, "point", Vc3_Zero(), "direction", Vc3_Zero(), "is_ray", .F., "start_point", Vc3_Zero(), "end_point", Vc3_Zero() )
   CASE "Circle" ; RETURN hb_Hash( "_kind", "Circle", "geometry_dependency", 0, "geometry_node_id", 0, "center", Vc3_Zero(), "normal", Vc3_Zero(), "direction", Vc3_Zero(), "radius", 0.0, "start_parameter", 0.0, "end_parameter", 0.0, "reserved", 0.0 )
   CASE "Arc" ; RETURN hb_Hash( "_kind", "Arc", "geometry_dependency", 0, "geometry_node_id", 0, "center", Vc3_Zero(), "normal", Vc3_Zero(), "direction", Vc3_Zero(), "radius", 0.0, "start_parameter", 0.0, "end_parameter", 0.0, "reserved", 0.0, "start_point", Vc3_Zero(), "end_point", Vc3_Zero() )
   CASE "Ellipse" ; RETURN hb_Hash( "_kind", "Ellipse", "geometry_dependency", 0, "geometry_node_id", 0, "center", Vc3_Zero(), "major_axis", Vc3_Zero(), "axis_ratio", 0.0 )
   CASE "BoundedEllipse" ; RETURN hb_Hash( "_kind", "BoundedEllipse", "geometry_dependency", 0, "geometry_node_id", 0, "center", Vc3_Zero(), "major_axis", Vc3_Zero(), "axis_ratio", 0.0, "start_point", Vc3_Zero(), "end_point", Vc3_Zero() )
   CASE "Spline" ; RETURN hb_Hash( "_kind", "Spline", "geometry_dependency", 0, "geometry_node_id", 0, "rational", .F., "periodic", .F., "degree", 0, "knot_tolerance", 0.0, "knot_physical_length", 0, "knot_grow_length", 0, "knots", {}, "weight_physical_length", 0, "weight_grow_length", 0, "weights", {}, "control_point_physical_length", 0, "control_point_grow_length", 0, "control_points", {}, "implicit_point_ids", {} )
   ENDSWITCH
RETURN NIL

FUNCTION Aso_Variants()
RETURN { ;
   { "Unknown", "" }, ;
   { "Dependency", "AssocDependency" }, ;
   { "ValueDependency", "AssocValueDependency" }, ;
   { "GeomDependency", "AssocGeomDependency" }, ;
   { "SurfaceActionBody", "AssocSurfaceActionBody" }, ;
   { "Action", "AssocAction" }, ;
   { "Network", "AssocNetwork" }, ;
   { "AnnotationActionBody", "AssocAnnotationActionBody" }, ;
   { "PersSubentManager", "AssocPersSubentManager" }, ;
   { "EdgeActionParam", "AssocEdgeActionParam" }, ;
   { "ConstraintGroup", "Assoc2dConstraintGroup" }, ;
   { "Variable", "AssocVariable" }, ;
   { "ActionParam", "AssocActionParam" }, ;
   { "CompoundActionParam", "AssocCompoundActionParam" }, ;
   { "OsnapPointRefActionParam", "AssocOsnapPointRefActionParam" }, ;
   { "PointRefActionParam", "AssocCompoundActionParam" }, ;
   { "ObjectActionParam", "AssocSingleDependencyActionParam" }, ;
   { "PathActionParam", "AssocPathActionParam" }, ;
   { "DimDependencyBody", "AssocDimDependencyBody" }, ;
   { "FaceActionParam", "AssocFaceActionParam" }, ;
   { "VertexActionParam", "AssocVertexActionParam" }, ;
   { "AsmBodyActionParam", "AssocAsmBodyActionParam" }, ;
   { "ArrayParameters", "AssocArrayParameters" }, ;
   { "ArrayActionBody", "AssocArrayActionBody" }, ;
   { "ArrayModifyActionBody", "AssocArrayModifyActionBody" }, ;
   { "DimensionAssociation", "AssocDimensionAssociation" }, ;
   { "PersSubentManagerStatic", "PersSubentManager" }, ;
   { "ViewRepActionBody", "AssocViewRepActionBody" }, ;
   { "ViewObjectActionParam", "AssocViewObjectActionParam" }, ;
   { "ViewRepHatchManager", "AssocViewRepHatchManager" }, ;
   { "ViewRepHatchActionParam", "AssocViewRepHatchActionParam" }, ;
   { "ViewLabelActionParam", "AssocViewLabelActionParam" }, ;
   { "SmartCenterActionBody", "AssocSmartCenterActionBody" } }

FUNCTION Aso_NewByName( c )
   SWITCH c
   CASE "Assoc2dConstraintGroup" ; RETURN Aso_NewAssoc2dConstraintGroup()
   CASE "AssocAction" ; RETURN Aso_NewAssocAction()
   CASE "AssocActionParam" ; RETURN Aso_NewAssocActionParam()
   CASE "AssocAnnotationActionBody" ; RETURN Aso_NewAssocAnnotationActionBody()
   CASE "AssocArrayActionBody" ; RETURN Aso_NewAssocArrayActionBody()
   CASE "AssocArrayModifyActionBody" ; RETURN Aso_NewAssocArrayModifyActionBody()
   CASE "AssocArrayParameters" ; RETURN Aso_NewAssocArrayParameters()
   CASE "AssocAsmBodyActionParam" ; RETURN Aso_NewAssocAsmBodyActionParam()
   CASE "AssocCompoundActionParam" ; RETURN Aso_NewAssocCompoundActionParam()
   CASE "AssocDependency" ; RETURN Aso_NewAssocDependency()
   CASE "AssocDimDependencyBody" ; RETURN Aso_NewAssocDimDependencyBody()
   CASE "AssocDimensionAssociation" ; RETURN Aso_NewAssocDimensionAssociation()
   CASE "AssocEdgeActionParam" ; RETURN Aso_NewAssocEdgeActionParam()
   CASE "AssocFaceActionParam" ; RETURN Aso_NewAssocFaceActionParam()
   CASE "AssocGeomDependency" ; RETURN Aso_NewAssocGeomDependency()
   CASE "AssocNetwork" ; RETURN Aso_NewAssocNetwork()
   CASE "AssocOsnapPointRefActionParam" ; RETURN Aso_NewAssocOsnapPointRefActionParam()
   CASE "AssocPathActionParam" ; RETURN Aso_NewAssocPathActionParam()
   CASE "AssocPersSubentManager" ; RETURN Aso_NewAssocPersSubentManager()
   CASE "AssocSingleDependencyActionParam" ; RETURN Aso_NewAssocSingleDependencyActionParam()
   CASE "AssocSmartCenterActionBody" ; RETURN Aso_NewAssocSmartCenterActionBody()
   CASE "AssocSurfaceActionBody" ; RETURN Aso_NewAssocSurfaceActionBody()
   CASE "AssocValueDependency" ; RETURN Aso_NewAssocValueDependency()
   CASE "AssocVariable" ; RETURN Aso_NewAssocVariable()
   CASE "AssocVertexActionParam" ; RETURN Aso_NewAssocVertexActionParam()
   CASE "AssocViewLabelActionParam" ; RETURN Aso_NewAssocViewLabelActionParam()
   CASE "AssocViewObjectActionParam" ; RETURN Aso_NewAssocViewObjectActionParam()
   CASE "AssocViewRepActionBody" ; RETURN Aso_NewAssocViewRepActionBody()
   CASE "AssocViewRepHatchActionParam" ; RETURN Aso_NewAssocViewRepHatchActionParam()
   CASE "AssocViewRepHatchManager" ; RETURN Aso_NewAssocViewRepHatchManager()
   CASE "PersSubentManager" ; RETURN Aso_NewPersSubentManager()
   ENDSWITCH
RETURN NIL

FUNCTION Aso_VarRow( cKind )
   LOCAL r
   FOR EACH r IN Aso_Variants()
      IF r[ 1 ] == cKind ; RETURN r ; ENDIF
   NEXT
RETURN NIL

FUNCTION Aso_NewData( cKind )
   LOCAL r := Aso_VarRow( cKind )
   IF r == NIL .OR. Empty( r[ 2 ] ) ; RETURN hb_Hash( "_kind", cKind, "value", NIL ) ; ENDIF
RETURN hb_Hash( "_kind", cKind, "value", Aso_NewByName( r[ 2 ] ) )

FUNCTION Aso_New( cDxfName, cCppName )
RETURN hb_Hash( "_type", "AssociativeObject", "handle", 0, "owner", 0, "reactors", {}, "xdictionary_handle", NIL, ;
   "dxf_name", iif( cDxfName == NIL, "", cDxfName ), "cpp_class_name", iif( cCppName == NIL, "", cCppName ), "data", Aso_NewData( "Unknown" ), "source_version", NIL )

/* AssocPersistentSubentId::class_name_for_code / code_for_class_name (NIL = None) */
FUNCTION Aso_ClassNameForCode( n )
   IF n == 1 ; RETURN "AcDbAssocSingleEdgePersSubentId" ; ENDIF
   IF n == 5 ; RETURN "AcDbAssocAsmBasedEntityPersSubentId" ; ENDIF
RETURN NIL
FUNCTION Aso_CodeForClassName( c )
   IF Upper( c ) == Upper( "AcDbAssocSingleEdgePersSubentId" ) ; RETURN 1 ; ENDIF
   IF Upper( c ) == Upper( "AcDbAssocAsmBasedEntityPersSubentId" ) ; RETURN 5 ; ENDIF
RETURN NIL

STATIC FUNCTION Aso_In( a, h ) ; RETURN AScan( a, {| x | x == h } ) > 0

/* ---------- references ---------- */
STATIC FUNCTION Aso_RefEval( v, t ) ; RETURN v[ "value" ][ 1 ] == AEV_HANDLE .AND. v[ "value" ][ 2 ] == t
STATIC FUNCTION Aso_RefValueParam( v, t )
   LOCAL x
   IF v[ "controlled_object_dependency" ] == t ; RETURN .T. ; ENDIF
   FOR EACH x IN v[ "variables" ]
      IF x[ "handle" ] == t .OR. Aso_RefEval( x, t ) ; RETURN .T. ; ENDIF
   NEXT
RETURN .F.
STATIC FUNCTION Aso_RefValues( a, t )
   LOCAL x
   FOR EACH x IN a
      IF Aso_RefValueParam( x, t ) ; RETURN .T. ; ENDIF
   NEXT
RETURN .F.
STATIC FUNCTION Aso_RefDep( v, t ) ; RETURN v[ "dependent_on" ] == t .OR. v[ "read_dependency" ] == t .OR. v[ "node" ] == t .OR. v[ "dependency_body" ] == t
STATIC FUNCTION Aso_RefDeps( a, t, k )
   LOCAL x
   FOR EACH x IN a
      IF x[ k ] == t ; RETURN .T. ; ENDIF
   NEXT
RETURN .F.
STATIC FUNCTION Aso_RefAction( v, t )
RETURN v[ "owning_network" ] == t .OR. v[ "action_body" ] == t .OR. Aso_RefDeps( v[ "dependencies" ], t, "dependency" ) .OR. Aso_In( v[ "owned_parameters" ], t ) .OR. Aso_RefValues( v[ "values" ], t )
STATIC FUNCTION Aso_RefParamBody( v, t ) ; RETURN Aso_In( v[ "dependencies" ], t ) .OR. v[ "dependency" ] == t .OR. Aso_RefValues( v[ "values" ], t )
STATIC FUNCTION Aso_RefSingle( v, t ) ; RETURN v[ "dependency" ] == t
STATIC FUNCTION Aso_RefCompound( v, t )
   LOCAL c := v[ "child_parameter" ]
   IF Aso_In( v[ "parameters" ], t ) ; RETURN .T. ; ENDIF
RETURN c != NIL .AND. ( c[ "parameter" ] == t .OR. c[ "secondary_parameter" ] == t .OR. c[ "tertiary_parameter" ] == t )

STATIC FUNCTION Aso_NodeRef( n, t )
   SWITCH n[ "data" ][ "_kind" ]
   CASE "Angle" ; CASE "Distance" ; CASE "RadiusDiameter"
      RETURN n[ "data" ][ "value_dependency" ] == t .OR. n[ "data" ][ "dimension_dependency" ] == t
   CASE "ImplicitPoint" ; CASE "Point" ; CASE "Line" ; CASE "BoundedLine" ; CASE "Circle" ; CASE "Arc" ; CASE "Ellipse" ; CASE "BoundedEllipse" ; CASE "RigidSet" ; CASE "Spline"
      RETURN n[ "data" ][ "geometry_dependency" ] == t
   ENDSWITCH
RETURN .F.

/* AssociativeData::references_handle */
FUNCTION Aso_DataReferencesHandle( d, t )
   LOCAL v := d[ "value" ], x, r
   SWITCH d[ "_kind" ]
   CASE "Dependency" ; RETURN Aso_RefDep( v, t )
   CASE "ValueDependency" ; RETURN Aso_RefDep( v[ "dependency" ], t ) .OR. Aso_RefEval( v[ "value" ], t )
   CASE "GeomDependency" ; RETURN Aso_RefDep( v[ "dependency" ], t )
   CASE "SurfaceActionBody" ; RETURN Aso_RefParamBody( v[ "parameter_body" ], t ) .OR. v[ "surface_body" ][ "dependency" ] == t
   CASE "Action" ; RETURN Aso_RefAction( v, t )
   CASE "Network" ; RETURN Aso_RefAction( v[ "action" ], t ) .OR. Aso_RefDeps( v[ "actions" ], t, "dependency" ) .OR. Aso_In( v[ "owned_actions" ], t )
   CASE "AnnotationActionBody"
      RETURN Aso_RefParamBody( v[ "annotation" ][ "parameter_body" ], t ) .OR. v[ "annotation" ][ "dependency" ] == t .OR. v[ "entity" ] == t ;
         .OR. Aso_RefDeps( v[ "actions" ], t, "dependency" ) .OR. v[ "read_node" ] == t .OR. v[ "dimension_node" ] == t .OR. v[ "dependency" ] == t
   CASE "EdgeActionParam" ; RETURN Aso_RefSingle( v[ "single_dependency" ], t ) .OR. v[ "parameter" ] == t
   CASE "ConstraintGroup"
      IF Aso_RefAction( v[ "action" ], t ) .OR. v[ "dependency" ] == t .OR. Aso_In( v[ "actions" ], t ) ; RETURN .T. ; ENDIF
      FOR EACH x IN v[ "nodes" ]
         IF Aso_NodeRef( x, t ) ; RETURN .T. ; ENDIF
      NEXT
      RETURN .F.
   CASE "Variable" ; RETURN Aso_RefAction( v[ "action" ], t ) .OR. Aso_RefEval( v[ "value" ], t ) .OR. Aso_RefDeps( v[ "dependencies" ], t, "dependency" )
   CASE "CompoundActionParam" ; CASE "PointRefActionParam" ; RETURN Aso_RefCompound( v, t )
   CASE "PathActionParam" ; RETURN Aso_RefCompound( v[ "compound" ], t )
   CASE "OsnapPointRefActionParam" ; RETURN Aso_RefCompound( v[ "compound" ], t )
   CASE "ObjectActionParam" ; RETURN Aso_RefSingle( v, t )
   CASE "FaceActionParam" ; CASE "VertexActionParam" ; RETURN Aso_RefSingle( v[ "single_dependency" ], t )
   CASE "AsmBodyActionParam" ; RETURN Aso_RefSingle( v[ "single_dependency" ], t ) .OR. v[ "history" ] == t
   CASE "ArrayParameters"
      FOR EACH x IN v[ "items" ]
         IF ( x[ "first_handle" ] != NIL .AND. x[ "first_handle" ] == t ) .OR. ( x[ "second_handle" ] != NIL .AND. x[ "second_handle" ] == t ) ; RETURN .T. ; ENDIF
      NEXT
      RETURN .F.
   CASE "ArrayActionBody" ; RETURN Aso_RefParamBody( v[ "parameter_body" ], t )
   CASE "ArrayModifyActionBody" ; RETURN Aso_RefParamBody( v[ "body" ][ "parameter_body" ], t )
   CASE "DimensionAssociation"
      IF v[ "dimension" ] == t ; RETURN .T. ; ENDIF
      FOR EACH x IN v[ "references" ]
         FOR EACH r IN x
            IF Aso_In( r[ "xrefs" ], t ) .OR. Aso_In( r[ "intersection_objects" ], t ) ; RETURN .T. ; ENDIF
         NEXT
      NEXT
      RETURN .F.
   CASE "ViewRepActionBody" ; RETURN v[ "view_rep" ] == t
   CASE "ViewObjectActionParam" ; CASE "ViewRepHatchActionParam" ; CASE "ViewLabelActionParam" ; RETURN Aso_RefSingle( v[ "single_dependency" ], t )
   CASE "ViewRepHatchManager" ; RETURN Aso_RefCompound( v[ "compound" ], t ) .OR. Aso_RefDeps( v[ "items" ], t, "parameter" )
   CASE "SmartCenterActionBody" ; RETURN Aso_RefParamBody( v[ "parameter_body" ], t )
   ENDSWITCH
RETURN .F.

FUNCTION Aso_ReferencesHandle( o, t )
RETURN o[ "owner" ] == t .OR. Aso_In( o[ "reactors" ], t ) .OR. ( o[ "xdictionary_handle" ] != NIL .AND. o[ "xdictionary_handle" ] == t ) .OR. Aso_DataReferencesHandle( o[ "data" ], t )

/* ---------- visit ---------- */
STATIC PROCEDURE Aso_VL( a, b )
   LOCAL i
   FOR i := 1 TO Len( a )
      a[ i ] := Eval( b, a[ i ] )
   NEXT
RETURN
STATIC PROCEDURE Aso_VK( h, k, b ) ; h[ k ] := Eval( b, h[ k ] ) ; RETURN
STATIC PROCEDURE Aso_VKs( a, k, b )
   LOCAL x
   FOR EACH x IN a ; x[ k ] := Eval( b, x[ k ] ) ; NEXT
RETURN
STATIC PROCEDURE Aso_VEval( v, b )
   IF v[ "value" ][ 1 ] == AEV_HANDLE ; v[ "value" ][ 2 ] := Eval( b, v[ "value" ][ 2 ] ) ; ENDIF
RETURN
STATIC PROCEDURE Aso_VValueParam( v, b )
   LOCAL x
   FOR EACH x IN v[ "variables" ]
      Aso_VEval( x, b )
      x[ "handle" ] := Eval( b, x[ "handle" ] )
   NEXT
   Aso_VK( v, "controlled_object_dependency", b )
RETURN
STATIC PROCEDURE Aso_VDep( v, b )
   Aso_VK( v, "dependent_on", b ) ; Aso_VK( v, "read_dependency", b ) ; Aso_VK( v, "node", b ) ; Aso_VK( v, "dependency_body", b )
RETURN
STATIC PROCEDURE Aso_VAction( v, b )
   LOCAL x
   Aso_VK( v, "owning_network", b ) ; Aso_VK( v, "action_body", b )
   Aso_VKs( v[ "dependencies" ], "dependency", b )
   Aso_VL( v[ "owned_parameters" ], b )
   FOR EACH x IN v[ "values" ] ; Aso_VValueParam( x, b ) ; NEXT
RETURN
STATIC PROCEDURE Aso_VParamBody( v, b )
   LOCAL x
   Aso_VL( v[ "dependencies" ], b )
   FOR EACH x IN v[ "values" ] ; Aso_VValueParam( x, b ) ; NEXT
   Aso_VK( v, "dependency", b )
RETURN
STATIC PROCEDURE Aso_VSingle( v, b ) ; Aso_VK( v, "dependency", b ) ; RETURN
STATIC PROCEDURE Aso_VCompound( v, b )
   LOCAL c := v[ "child_parameter" ]
   Aso_VL( v[ "parameters" ], b )
   IF c != NIL
      Aso_VK( c, "parameter", b ) ; Aso_VK( c, "secondary_parameter", b ) ; Aso_VK( c, "tertiary_parameter", b )
   ENDIF
RETURN

PROCEDURE Aso_VisitData( d, b )
   LOCAL v := d[ "value" ], x, r, n
   SWITCH d[ "_kind" ]
   CASE "Dependency" ; Aso_VDep( v, b ) ; EXIT
   CASE "ValueDependency" ; Aso_VDep( v[ "dependency" ], b ) ; Aso_VEval( v[ "value" ], b ) ; EXIT
   CASE "GeomDependency" ; Aso_VDep( v[ "dependency" ], b ) ; EXIT
   CASE "SurfaceActionBody" ; Aso_VParamBody( v[ "parameter_body" ], b ) ; Aso_VK( v[ "surface_body" ], "dependency", b ) ; EXIT
   CASE "Action" ; Aso_VAction( v, b ) ; EXIT
   CASE "Network"
      Aso_VAction( v[ "action" ], b ) ; Aso_VKs( v[ "actions" ], "dependency", b ) ; Aso_VL( v[ "owned_actions" ], b ) ; EXIT
   CASE "AnnotationActionBody"
      Aso_VParamBody( v[ "annotation" ][ "parameter_body" ], b ) ; Aso_VK( v[ "annotation" ], "dependency", b ) ; Aso_VK( v, "entity", b )
      Aso_VKs( v[ "actions" ], "dependency", b )
      Aso_VK( v, "read_node", b ) ; Aso_VK( v, "dimension_node", b ) ; Aso_VK( v, "dependency", b )
      EXIT
   CASE "EdgeActionParam" ; Aso_VSingle( v[ "single_dependency" ], b ) ; Aso_VK( v, "parameter", b ) ; EXIT
   CASE "ConstraintGroup"
      Aso_VAction( v[ "action" ], b ) ; Aso_VK( v, "dependency", b ) ; Aso_VL( v[ "actions" ], b )
      FOR EACH x IN v[ "nodes" ]
         n := x[ "data" ]
         SWITCH n[ "_kind" ]
         CASE "Angle" ; CASE "Distance" ; CASE "RadiusDiameter"
            Aso_VK( n, "value_dependency", b ) ; Aso_VK( n, "dimension_dependency", b ) ; EXIT
         CASE "ImplicitPoint" ; CASE "Point" ; CASE "Line" ; CASE "BoundedLine" ; CASE "Circle" ; CASE "Arc" ; CASE "Ellipse" ; CASE "BoundedEllipse" ; CASE "RigidSet" ; CASE "Spline"
            Aso_VK( n, "geometry_dependency", b ) ; EXIT
         ENDSWITCH
      NEXT
      EXIT
   CASE "Variable" ; Aso_VAction( v[ "action" ], b ) ; Aso_VEval( v[ "value" ], b ) ; Aso_VKs( v[ "dependencies" ], "dependency", b ) ; EXIT
   CASE "CompoundActionParam" ; CASE "PointRefActionParam" ; Aso_VCompound( v, b ) ; EXIT
   CASE "PathActionParam" ; CASE "OsnapPointRefActionParam" ; Aso_VCompound( v[ "compound" ], b ) ; EXIT
   CASE "ObjectActionParam" ; Aso_VSingle( v, b ) ; EXIT
   CASE "FaceActionParam" ; CASE "VertexActionParam" ; CASE "AsmBodyActionParam" ; Aso_VSingle( v[ "single_dependency" ], b ) ; EXIT
   CASE "ArrayParameters"
      FOR EACH x IN v[ "items" ]
         IF x[ "first_handle" ] != NIL ; x[ "first_handle" ] := Eval( b, x[ "first_handle" ] ) ; ENDIF
         IF x[ "second_handle" ] != NIL ; x[ "second_handle" ] := Eval( b, x[ "second_handle" ] ) ; ENDIF
      NEXT
      EXIT
   CASE "ArrayActionBody" ; Aso_VParamBody( v[ "parameter_body" ], b ) ; EXIT
   CASE "ArrayModifyActionBody" ; Aso_VParamBody( v[ "body" ][ "parameter_body" ], b ) ; EXIT
   CASE "DimensionAssociation"
      Aso_VK( v, "dimension", b )
      FOR EACH x IN v[ "references" ]
         FOR EACH r IN x
            Aso_VL( r[ "xrefs" ], b ) ; Aso_VL( r[ "intersection_objects" ], b )
         NEXT
      NEXT
      EXIT
   CASE "ViewRepActionBody" ; Aso_VK( v, "view_rep", b ) ; EXIT
   CASE "ViewObjectActionParam" ; CASE "ViewRepHatchActionParam" ; CASE "ViewLabelActionParam" ; Aso_VSingle( v[ "single_dependency" ], b ) ; EXIT
   CASE "ViewRepHatchManager" ; Aso_VCompound( v[ "compound" ], b ) ; Aso_VKs( v[ "items" ], "parameter", b ) ; EXIT
   CASE "SmartCenterActionBody" ; Aso_VParamBody( v[ "parameter_body" ], b ) ; EXIT
   ENDSWITCH
   IF d[ "_kind" ] == "AsmBodyActionParam" ; Aso_VK( v, "history", b ) ; ENDIF
RETURN

PROCEDURE Aso_VisitHandlesMut( o, b )
   o[ "owner" ] := Eval( b, o[ "owner" ] )
   Aso_VL( o[ "reactors" ], b )
   IF o[ "xdictionary_handle" ] != NIL ; o[ "xdictionary_handle" ] := Eval( b, o[ "xdictionary_handle" ] ) ; ENDIF
   Aso_VisitData( o[ "data" ], b )
RETURN
