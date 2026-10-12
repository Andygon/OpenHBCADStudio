/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/obj_dynblock.prg
   Origen Rust: opencadcodec/src/objects/dynamic_block.rs, lineas 1-868 (el fichero Rust no tiene #[test]; los tests son [extra]).
   Licencia del original: MPL-2.0.
   APLAZADO (cluster ACIS/EmbeddedEntity): SolidHistory, SolidHistoryNodeBase, SolidHistoryOperation y sus structs (L869-1411), y las variantes
   SolidHistory / SolidHistoryNode de DynamicBlockData. Se portaran junto a entities/acis y embedded_entity.
   Prefijo: Dbo_ (Dbo_New<Struct>() = Default; generado mecanicamente del Rust: 45 structs menos los de SolidHistory).
   DynamicBlockObject = hash { handle, owner, reactors, xdictionary_handle, dxf_name, cpp_class_name, data }.
   data = hash { "_kind": nombre de variante, "value": struct o NIL }. BlockEvalValue = { BEV_*, x } (obj_group.prg).
   BlockEvalExpression::NO_PARENT = -1 (DBO_NO_PARENT). [T;N] -> array de N. Option -> NIL.
   visit_handles_mut: el bloque recibe un handle y DEVUELVE el nuevo.
----------------------------------------------------------------------------*/
#include "ocx.ch"

#define DBO_NO_PARENT  -1

FUNCTION Dbo_NewBlockEvalExpression()
RETURN hb_Hash( "parent_id", DBO_NO_PARENT, "major", 0, "minor", 0, "value_code", 0, "value", Bev_None(), "node_id", 0 )

FUNCTION Dbo_NewBlockElement()
RETURN hb_Hash( ;
      "eval", Dbo_NewBlockEvalExpression(), ;
      "name", "", ;
      "major", 0, ;
      "minor", 0, ;
      "eed_1071", 0 )

FUNCTION Dbo_NewBlockConnection()
RETURN hb_Hash( ;
      "code", 0, ;
      "name", "" )

FUNCTION Dbo_NewBlockParameterProperty()
RETURN hb_Hash( ;
      "connections", {} )

FUNCTION Dbo_NewBlockParameterValueSet()
RETURN hb_Hash( ;
      "description", "", ;
      "flags", 0, ;
      "minimum", 0.0, ;
      "maximum", 0.0, ;
      "increment", 0.0, ;
      "values", {} )

FUNCTION Dbo_NewBlockParameter()
RETURN hb_Hash( ;
      "element", Dbo_NewBlockElement(), ;
      "show_properties", .F., ;
      "chain_actions", .F. )

FUNCTION Dbo_NewBlockOnePointParameter()
RETURN hb_Hash( ;
      "parameter", Dbo_NewBlockParameter(), ;
      "definition_point", Vc3_Zero(), ;
      "properties", { Dbo_NewBlockParameterProperty(), Dbo_NewBlockParameterProperty() }, ;
      "property_count", 0 )

FUNCTION Dbo_NewBlockTwoPointParameter()
RETURN hb_Hash( ;
      "parameter", Dbo_NewBlockParameter(), ;
      "definition_base_point", Vc3_Zero(), ;
      "definition_end_point", Vc3_Zero(), ;
      "properties", { Dbo_NewBlockParameterProperty(), Dbo_NewBlockParameterProperty(), Dbo_NewBlockParameterProperty(), Dbo_NewBlockParameterProperty() }, ;
      "property_states", { 0, 0, 0, 0 }, ;
      "parameter_base_location", 0, ;
      "updated_base_point", NIL, ;
      "base_point", NIL, ;
      "updated_end_point", NIL, ;
      "end_point", NIL )

FUNCTION Dbo_NewBlockGrip()
RETURN hb_Hash( ;
      "element", Dbo_NewBlockElement(), ;
      "flags_91", 0, ;
      "flags_92", 0, ;
      "location", Vc3_Zero(), ;
      "insert_cycling", .F., ;
      "insert_cycling_weight", 0 )

FUNCTION Dbo_NewBlockGripExpression()
RETURN hb_Hash( ;
      "eval", Dbo_NewBlockEvalExpression(), ;
      "grip_type", 0, ;
      "expression", "" )

FUNCTION Dbo_NewBlockOrientedGrip()
RETURN hb_Hash( ;
      "grip", Dbo_NewBlockGrip(), ;
      "orientation", Vc3_Zero() )

FUNCTION Dbo_NewBlockFlipGrip()
RETURN hb_Hash( ;
      "grip", Dbo_NewBlockGrip(), ;
      "combined_state", 0, ;
      "orientation", Vc3_Zero() )

FUNCTION Dbo_NewBlockAction()
RETURN hb_Hash( ;
      "element", Dbo_NewBlockElement(), ;
      "display_location", Vc3_Zero(), ;
      "dependencies", {}, ;
      "parameter_ids", {} )

FUNCTION Dbo_NewBlockActionOffsets()
RETURN hb_Hash( ;
      "distance_multiplier", 0.0, ;
      "angle_offset", 0.0, ;
      "flags", 0 )

FUNCTION Dbo_NewBlockActionWithBasePoint()
RETURN hb_Hash( ;
      "action", Dbo_NewBlockAction(), ;
      "offset", Vc3_Zero(), ;
      "connections", {}, ;
      "dependent", .F., ;
      "base_point", Vc3_Zero() )

FUNCTION Dbo_NewBlockConstraintParameter()
RETURN hb_Hash( ;
      "parameter", Dbo_NewBlockTwoPointParameter(), ;
      "dependency", 0 )

FUNCTION Dbo_NewBlockLinearConstraintParameter()
RETURN hb_Hash( ;
      "constraint", Dbo_NewBlockConstraintParameter(), ;
      "expression_name", "", ;
      "expression_description", "", ;
      "value", 0.0, ;
      "value_set", Dbo_NewBlockParameterValueSet() )

FUNCTION Dbo_NewBlockRepresentationData()
RETURN hb_Hash( ;
      "flags", 0, ;
      "block", 0 )

FUNCTION Dbo_NewBlockAlignmentParameter()
RETURN hb_Hash( ;
      "parameter", Dbo_NewBlockTwoPointParameter(), ;
      "align_perpendicular", .F. )

FUNCTION Dbo_NewBlockLinearParameter()
RETURN hb_Hash( ;
      "parameter", Dbo_NewBlockTwoPointParameter(), ;
      "distance_name", "", ;
      "distance_description", "", ;
      "distance", 0.0, ;
      "value_set", Dbo_NewBlockParameterValueSet() )

FUNCTION Dbo_NewBlockBasePointParameter()
RETURN hb_Hash( ;
      "parameter", Dbo_NewBlockOnePointParameter(), ;
      "point", Vc3_Zero(), ;
      "base_point", Vc3_Zero() )

FUNCTION Dbo_NewBlockFlipParameter()
RETURN hb_Hash( ;
      "parameter", Dbo_NewBlockTwoPointParameter(), ;
      "flip_label", "", ;
      "flip_label_description", "", ;
      "base_state_label", "", ;
      "flipped_state_label", "", ;
      "definition_label_point", Vc3_Zero(), ;
      "flags_96", 0, ;
      "tooltip", "" )

FUNCTION Dbo_NewBlockXYParameter()
RETURN hb_Hash( ;
      "parameter", Dbo_NewBlockTwoPointParameter(), ;
      "x_label", "", ;
      "x_label_description", "", ;
      "y_label", "", ;
      "y_label_description", "", ;
      "x_value", 0.0, ;
      "y_value", 0.0, ;
      "x_value_set", Dbo_NewBlockParameterValueSet(), ;
      "y_value_set", Dbo_NewBlockParameterValueSet() )

FUNCTION Dbo_NewBlockRotationParameter()
RETURN hb_Hash( ;
      "parameter", Dbo_NewBlockTwoPointParameter(), ;
      "definition_base_angle_point", Vc3_Zero(), ;
      "angle_name", "", ;
      "angle_description", "", ;
      "angle", 0.0, ;
      "value_set", Dbo_NewBlockParameterValueSet() )

FUNCTION Dbo_NewBlockPolarParameter()
RETURN hb_Hash( ;
      "parameter", Dbo_NewBlockTwoPointParameter(), ;
      "angle_name", "", ;
      "angle_description", "", ;
      "distance_name", "", ;
      "distance_description", "", ;
      "offset", 0.0, ;
      "angle_value_set", Dbo_NewBlockParameterValueSet(), ;
      "distance_value_set", Dbo_NewBlockParameterValueSet() )

FUNCTION Dbo_NewBlockLookupParameter()
RETURN hb_Hash( ;
      "parameter", Dbo_NewBlockOnePointParameter(), ;
      "index", 0, ;
      "lookup_name", "", ;
      "lookup_description", "" )

FUNCTION Dbo_NewBlockPointParameter()
RETURN hb_Hash( ;
      "parameter", Dbo_NewBlockOnePointParameter(), ;
      "position_name", "", ;
      "position_description", "", ;
      "definition_label_point", Vc3_Zero() )

FUNCTION Dbo_NewBlockUserParameter()
RETURN hb_Hash( ;
      "parameter", Dbo_NewBlockOnePointParameter(), ;
      "flags", 0, ;
      "associated_variable", 0, ;
      "expression", "", ;
      "value_code", 0, ;
      "value", Bev_None(), ;
      "value_type", 0 )

FUNCTION Dbo_NewBlockAngularConstraintParameter()
RETURN hb_Hash( ;
      "constraint", Dbo_NewBlockConstraintParameter(), ;
      "center_point", Vc3_Zero(), ;
      "end_point", Vc3_Zero(), ;
      "expression_name", "", ;
      "expression_description", "", ;
      "angle", 0.0, ;
      "orientation_on_both_grips", .F., ;
      "value_set", Dbo_NewBlockParameterValueSet() )

FUNCTION Dbo_NewBlockAngularConstraintParameterEntity()
RETURN hb_Hash( ;
      "constraint", Dbo_NewBlockConstraintParameter(), ;
      "center_point", Vc3_Zero(), ;
      "label_point", Vc3_Zero(), ;
      "expression_name", "", ;
      "expression_description", "", ;
      "angle", 0.0, ;
      "orientation_on_both_grips", .F., ;
      "value_set", Dbo_NewBlockParameterValueSet() )

FUNCTION Dbo_NewBlockDistanceConstraintParameter()
RETURN hb_Hash( ;
      "constraint", Dbo_NewBlockConstraintParameter(), ;
      "expression_name", "", ;
      "expression_description", "", ;
      "distance", 0.0, ;
      "value_set", Dbo_NewBlockParameterValueSet() )

FUNCTION Dbo_NewBlockParameterDependencyBody()
RETURN hb_Hash( ;
      "dependency_body_version", 0, ;
      "dimension_base_version", 0, ;
      "name", "", ;
      "class_version", 0 )

FUNCTION Dbo_NewBlockMoveAction()
RETURN hb_Hash( ;
      "action", Dbo_NewBlockAction(), ;
      "connections", { Dbo_NewBlockConnection(), Dbo_NewBlockConnection() }, ;
      "offsets", Dbo_NewBlockActionOffsets() )

FUNCTION Dbo_NewBlockFlipAction()
RETURN hb_Hash( ;
      "action", Dbo_NewBlockAction(), ;
      "connections", { Dbo_NewBlockConnection(), Dbo_NewBlockConnection(), Dbo_NewBlockConnection(), Dbo_NewBlockConnection() } )

FUNCTION Dbo_NewBlockBasePointAction()
RETURN hb_Hash( ;
      "action", Dbo_NewBlockActionWithBasePoint(), ;
      "connections", {} )

FUNCTION Dbo_NewBlockArrayAction()
RETURN hb_Hash( ;
      "action", Dbo_NewBlockAction(), ;
      "connections", { Dbo_NewBlockConnection(), Dbo_NewBlockConnection(), Dbo_NewBlockConnection(), Dbo_NewBlockConnection() }, ;
      "column_offset", 0.0, ;
      "row_offset", 0.0 )

FUNCTION Dbo_NewBlockLookupColumn()
RETURN hb_Hash( ;
      "node_id", 0, ;
      "value_type", 0, ;
      "property_type", 0, ;
      "lookup_property", .F., ;
      "unmatched_name", "", ;
      "writable", .F., ;
      "connection_name", "" )

FUNCTION Dbo_NewBlockLookupAction()
RETURN hb_Hash( ;
      "action", Dbo_NewBlockAction(), ;
      "row_count", 0, ;
      "column_count", 0, ;
      "expressions", {}, ;
      "columns", {}, ;
      "flag_280", .F. )

FUNCTION Dbo_NewBlockStretchHandle()
RETURN hb_Hash( ;
      "handle", 0, ;
      "indexes", {} )

FUNCTION Dbo_NewBlockStretchCode()
RETURN hb_Hash( ;
      "code", 0, ;
      "indexes", {} )

FUNCTION Dbo_NewBlockStretchAction()
RETURN hb_Hash( ;
      "action", Dbo_NewBlockAction(), ;
      "connections", { Dbo_NewBlockConnection(), Dbo_NewBlockConnection() }, ;
      "points", {}, ;
      "handles", {}, ;
      "codes", {}, ;
      "offsets", Dbo_NewBlockActionOffsets() )

FUNCTION Dbo_NewBlockPolarStretchAction()
RETURN hb_Hash( ;
      "action", Dbo_NewBlockAction(), ;
      "connections", { Dbo_NewBlockConnection(), Dbo_NewBlockConnection(), Dbo_NewBlockConnection(), Dbo_NewBlockConnection(), Dbo_NewBlockConnection(), Dbo_NewBlockConnection() }, ;
      "points", {}, ;
      "handles", {}, ;
      "bindings", {}, ;
      "codes", {}, ;
      "distance_multiplier", 0.0, ;
      "angle_offset", 0.0, ;
      "extra", {} )

FUNCTION Dbo_NewBlockEvaluationNode()
RETURN hb_Hash( ;
      "id", 0, ;
      "edge_flags", 0, ;
      "next_id", 0, ;
      "expression", 0, ;
      "node_data", { 0, 0, 0, 0 }, ;
      "active_cycles", NIL )

FUNCTION Dbo_NewBlockEvaluationEdge()
RETURN hb_Hash( ;
      "id", 0, ;
      "next_id", 0, ;
      "incoming_edge", 0, ;
      "source_node", 0, ;
      "destination_node", 0, ;
      "outgoing_edges", { 0, 0, 0, 0, 0 } )

FUNCTION Dbo_NewBlockEvaluationGraph()
RETURN hb_Hash( ;
      "first_node_id", 0, ;
      "first_node_id_copy", 0, ;
      "nodes", {}, ;
      "edges", {} )

FUNCTION Dbo_Variants()
RETURN { ;
   { "Unknown", "", "", "" }, ;
   { "Representation", "BlockRepresentationData", "", "" }, ;
   { "ProxyNode", "BlockEvalExpression", "", "" }, ;
   { "GripLocationComponent", "BlockGripExpression", "", "" }, ;
   { "AlignmentGrip", "BlockOrientedGrip", "", "" }, ;
   { "FlipGrip", "BlockFlipGrip", "", "" }, ;
   { "LinearGrip", "BlockOrientedGrip", "", "" }, ;
   { "LookupGrip", "BlockGrip", "", "" }, ;
   { "PolarGrip", "BlockGrip", "", "" }, ;
   { "RotationGrip", "BlockGrip", "", "" }, ;
   { "VisibilityGrip", "BlockGrip", "", "" }, ;
   { "XYGrip", "BlockGrip", "", "" }, ;
   { "PropertiesTableGrip", "BlockGrip", "", "" }, ;
   { "AlignmentParameter", "BlockAlignmentParameter", "", "" }, ;
   { "BasePointParameter", "BlockBasePointParameter", "", "" }, ;
   { "FlipParameter", "BlockFlipParameter", "", "" }, ;
   { "LinearParameter", "BlockLinearParameter", "", "" }, ;
   { "LookupParameter", "BlockLookupParameter", "", "" }, ;
   { "PointParameter", "BlockPointParameter", "", "" }, ;
   { "PolarParameter", "BlockPolarParameter", "", "" }, ;
   { "RotationParameter", "BlockRotationParameter", "", "" }, ;
   { "UserParameter", "BlockUserParameter", "", "" }, ;
   { "VisibilityParameter", "BlockVisibilityParameter", "", "" }, ;
   { "XYParameter", "BlockXYParameter", "", "" }, ;
   { "AngularConstraintParameter", "BlockAngularConstraintParameter", "", "" }, ;
   { "DiametricConstraintParameter", "BlockDistanceConstraintParameter", "", "" }, ;
   { "RadialConstraintParameter", "BlockDistanceConstraintParameter", "", "" }, ;
   { "AlignedConstraintParameter", "BlockLinearConstraintParameter", "", "" }, ;
   { "LinearConstraintParameter", "BlockLinearConstraintParameter", "", "" }, ;
   { "HorizontalConstraintParameter", "BlockLinearConstraintParameter", "", "" }, ;
   { "VerticalConstraintParameter", "BlockLinearConstraintParameter", "", "" }, ;
   { "ParameterDependencyBody", "BlockParameterDependencyBody", "", "" }, ;
   { "MoveAction", "BlockMoveAction", "", "" }, ;
   { "FlipAction", "BlockFlipAction", "", "" }, ;
   { "RotateAction", "BlockBasePointAction", "", "" }, ;
   { "ScaleAction", "BlockBasePointAction", "", "" }, ;
   { "ArrayAction", "BlockArrayAction", "", "" }, ;
   { "LookupAction", "BlockLookupAction", "", "" }, ;
   { "StretchAction", "BlockStretchAction", "", "" }, ;
   { "PolarStretchAction", "BlockPolarStretchAction", "", "" }, ;
   { "AlignmentParameterEntity", "", "ALIGNMENTPARAMETERENTITY", "AcDbBlockAlignmentParameterEntity" }, ;
   { "BasePointParameterEntity", "", "BASEPOINTPARAMETERENTITY", "AcDbBlockBasepointParameterEntity" }, ;
   { "FlipParameterEntity", "", "FLIPPARAMETERENTITY", "AcDbBlockFlipParameterEntity" }, ;
   { "LinearParameterEntity", "", "LINEARPARAMETERENTITY", "AcDbBlockLinearParameterEntity" }, ;
   { "PointParameterEntity", "", "POINTPARAMETERENTITY", "AcDbBlockPointParameterEntity" }, ;
   { "RotationParameterEntity", "", "ROTATIONPARAMETERENTITY", "AcDbBlockRotationParameterEntity" }, ;
   { "VisibilityParameterEntity", "", "VISIBILITYPARAMETERENTITY", "AcDbBlockVisibilityParameterEntity" }, ;
   { "XYParameterEntity", "", "XYPARAMETERENTITY", "AcDbBlockXYParameterEntity" }, ;
   { "AngularConstraintParameterEntity", "BlockAngularConstraintParameterEntity", "BLOCKANGULARCONSTRAINTPARAMETERENTITY", "AcDbBlockAngularConstraintParameterEntity" }, ;
   { "FlipGripEntity", "", "FLIPGRIPENTITY", "AcDbBlockFlipGripEntity" }, ;
   { "LinearGripEntity", "", "LINEARGRIPENTITY", "AcDbBlockLinearGripEntity" }, ;
   { "PolarGripEntity", "", "POLARGRIPENTITY", "AcDbBlockPolarGripEntity" }, ;
   { "RotationGripEntity", "", "ROTATIONGRIPENTITY", "AcDbBlockRotationGripEntity" }, ;
   { "VisibilityGripEntity", "", "VISIBILITYGRIPENTITY", "AcDbBlockVisibilityGripEntity" }, ;
   { "XYGripEntity", "", "XYGRIPENTITY", "AcDbBlockXYGripEntity" }, ;
   { "EvaluationGraph", "BlockEvaluationGraph", "", "" } }

FUNCTION Dbo_NewByName( c )
   SWITCH c
   CASE "BlockAlignmentParameter" ; RETURN Dbo_NewBlockAlignmentParameter()
   CASE "BlockAngularConstraintParameter" ; RETURN Dbo_NewBlockAngularConstraintParameter()
   CASE "BlockAngularConstraintParameterEntity" ; RETURN Dbo_NewBlockAngularConstraintParameterEntity()
   CASE "BlockArrayAction" ; RETURN Dbo_NewBlockArrayAction()
   CASE "BlockBasePointAction" ; RETURN Dbo_NewBlockBasePointAction()
   CASE "BlockBasePointParameter" ; RETURN Dbo_NewBlockBasePointParameter()
   CASE "BlockDistanceConstraintParameter" ; RETURN Dbo_NewBlockDistanceConstraintParameter()
   CASE "BlockEvalExpression" ; RETURN Dbo_NewBlockEvalExpression()
   CASE "BlockEvaluationGraph" ; RETURN Dbo_NewBlockEvaluationGraph()
   CASE "BlockFlipAction" ; RETURN Dbo_NewBlockFlipAction()
   CASE "BlockFlipGrip" ; RETURN Dbo_NewBlockFlipGrip()
   CASE "BlockFlipParameter" ; RETURN Dbo_NewBlockFlipParameter()
   CASE "BlockGrip" ; RETURN Dbo_NewBlockGrip()
   CASE "BlockGripExpression" ; RETURN Dbo_NewBlockGripExpression()
   CASE "BlockLinearConstraintParameter" ; RETURN Dbo_NewBlockLinearConstraintParameter()
   CASE "BlockLinearParameter" ; RETURN Dbo_NewBlockLinearParameter()
   CASE "BlockLookupAction" ; RETURN Dbo_NewBlockLookupAction()
   CASE "BlockLookupParameter" ; RETURN Dbo_NewBlockLookupParameter()
   CASE "BlockMoveAction" ; RETURN Dbo_NewBlockMoveAction()
   CASE "BlockOrientedGrip" ; RETURN Dbo_NewBlockOrientedGrip()
   CASE "BlockParameterDependencyBody" ; RETURN Dbo_NewBlockParameterDependencyBody()
   CASE "BlockPointParameter" ; RETURN Dbo_NewBlockPointParameter()
   CASE "BlockPolarParameter" ; RETURN Dbo_NewBlockPolarParameter()
   CASE "BlockPolarStretchAction" ; RETURN Dbo_NewBlockPolarStretchAction()
   CASE "BlockRepresentationData" ; RETURN Dbo_NewBlockRepresentationData()
   CASE "BlockRotationParameter" ; RETURN Dbo_NewBlockRotationParameter()
   CASE "BlockStretchAction" ; RETURN Dbo_NewBlockStretchAction()
   CASE "BlockUserParameter" ; RETURN Dbo_NewBlockUserParameter()
   CASE "BlockVisibilityParameter" ; RETURN Bvp_New()
   CASE "BlockXYParameter" ; RETURN Dbo_NewBlockXYParameter()
   ENDSWITCH
RETURN NIL

FUNCTION Dbo_VarRow( cKind )
   LOCAL r
   FOR EACH r IN Dbo_Variants()
      IF r[ 1 ] == cKind ; RETURN r ; ENDIF
   NEXT
RETURN NIL

FUNCTION Dbo_NewData( cKind )
   LOCAL r := Dbo_VarRow( cKind )
   IF r == NIL .OR. Empty( r[ 2 ] ) ; RETURN hb_Hash( "_kind", cKind, "value", NIL ) ; ENDIF
RETURN hb_Hash( "_kind", cKind, "value", Dbo_NewByName( r[ 2 ] ) )

/* DynamicBlockObject::new( dxf_name, cpp_class_name ) */
FUNCTION Dbo_New( cDxfName, cCppName )
RETURN hb_Hash( "_type", "DynamicBlockObject", "handle", 0, "owner", 0, "reactors", {}, "xdictionary_handle", NIL, "dxf_name", iif( cDxfName == NIL, "", cDxfName ), "cpp_class_name", iif( cCppName == NIL, "", cCppName ), "data", Dbo_NewData( "Unknown" ) )

/* DynamicBlockData::empty_entity_from_dxf_name: NIL = None */
FUNCTION Dbo_EmptyEntityFromDxfName( cName )
   LOCAL r, u := Upper( cName )
   FOR EACH r IN Dbo_Variants()
      IF ! Empty( r[ 3 ] ) .AND. r[ 3 ] == u ; RETURN Dbo_NewData( r[ 1 ] ) ; ENDIF
   NEXT
RETURN NIL

FUNCTION Dbo_EntityDxfName( d )
   LOCAL r := Dbo_VarRow( d[ "_kind" ] )
RETURN iif( r == NIL .OR. Empty( r[ 3 ] ), NIL, r[ 3 ] )

FUNCTION Dbo_EntityCppName( d )
   LOCAL r := Dbo_VarRow( d[ "_kind" ] )
RETURN iif( r == NIL .OR. Empty( r[ 4 ] ), NIL, r[ 4 ] )

STATIC PROCEDURE Dbo_VL( a, b )
   LOCAL i
   FOR i := 1 TO Len( a )
      a[ i ] := Eval( b, a[ i ] )
   NEXT
RETURN

PROCEDURE Dbo_VisitHandlesMut( o, b )
   o[ "owner" ] := Eval( b, o[ "owner" ] )
   Dbo_VL( o[ "reactors" ], b )
   IF o[ "xdictionary_handle" ] != NIL ; o[ "xdictionary_handle" ] := Eval( b, o[ "xdictionary_handle" ] ) ; ENDIF
   Dbo_VisitData( o[ "data" ], b )
RETURN

STATIC PROCEDURE Dbo_VBlockValue( v, b )
   IF v[ 1 ] == BEV_HANDLE ; v[ 2 ] := Eval( b, v[ 2 ] ) ; ENDIF
RETURN
STATIC PROCEDURE Dbo_VEval( e, b ) ; Dbo_VBlockValue( e[ "value" ], b ) ; RETURN
STATIC PROCEDURE Dbo_VElement( e, b ) ; Dbo_VEval( e[ "eval" ], b ) ; RETURN
STATIC PROCEDURE Dbo_VParam( p, b ) ; Dbo_VElement( p[ "parameter" ][ "element" ], b ) ; RETURN   /* one/two point */
STATIC PROCEDURE Dbo_VGrip( g, b ) ; Dbo_VElement( g[ "element" ], b ) ; RETURN
STATIC PROCEDURE Dbo_VAction( a, b )
   Dbo_VElement( a[ "element" ], b )
   Dbo_VL( a[ "dependencies" ], b )
RETURN
STATIC PROCEDURE Dbo_VConstraint( c, b )
   Dbo_VParam( c[ "parameter" ], b )
   c[ "dependency" ] := Eval( b, c[ "dependency" ] )
RETURN

PROCEDURE Dbo_VisitData( d, b )
   LOCAL v := d[ "value" ], e
   SWITCH d[ "_kind" ]
   CASE "Representation" ; v[ "block" ] := Eval( b, v[ "block" ] ) ; EXIT
   CASE "ProxyNode" ; Dbo_VEval( v, b ) ; EXIT
   CASE "GripLocationComponent" ; Dbo_VEval( v[ "eval" ], b ) ; EXIT
   CASE "AlignmentGrip" ; CASE "LinearGrip" ; CASE "FlipGrip"
      Dbo_VGrip( v[ "grip" ], b ) ; EXIT
   CASE "LookupGrip" ; CASE "PolarGrip" ; CASE "RotationGrip" ; CASE "VisibilityGrip" ; CASE "XYGrip" ; CASE "PropertiesTableGrip"
      Dbo_VGrip( v, b ) ; EXIT
   CASE "AlignmentParameter" ; CASE "FlipParameter" ; CASE "LinearParameter" ; CASE "PolarParameter" ; CASE "RotationParameter" ; CASE "XYParameter"
   CASE "BasePointParameter" ; CASE "LookupParameter" ; CASE "PointParameter"
      Dbo_VParam( v[ "parameter" ], b ) ; EXIT
   CASE "UserParameter"
      Dbo_VParam( v[ "parameter" ], b )
      v[ "associated_variable" ] := Eval( b, v[ "associated_variable" ] )
      Dbo_VBlockValue( v[ "value" ], b )
      EXIT
   CASE "VisibilityParameter" ; Bvp_VisitHandlesMut( v, b ) ; EXIT
   CASE "AngularConstraintParameter" ; CASE "DiametricConstraintParameter" ; CASE "RadialConstraintParameter" ; CASE "AlignedConstraintParameter"
   CASE "LinearConstraintParameter" ; CASE "HorizontalConstraintParameter" ; CASE "VerticalConstraintParameter" ; CASE "AngularConstraintParameterEntity"
      Dbo_VConstraint( v[ "constraint" ], b ) ; EXIT
   CASE "MoveAction" ; CASE "FlipAction" ; CASE "ArrayAction" ; CASE "LookupAction"
      Dbo_VAction( v[ "action" ], b ) ; EXIT
   CASE "RotateAction" ; CASE "ScaleAction"
      Dbo_VAction( v[ "action" ][ "action" ], b ) ; EXIT
   CASE "StretchAction"
      Dbo_VAction( v[ "action" ], b )
      FOR EACH e IN v[ "handles" ] ; e[ "handle" ] := Eval( b, e[ "handle" ] ) ; NEXT
      EXIT
   CASE "PolarStretchAction"
      Dbo_VAction( v[ "action" ], b )
      Dbo_VL( v[ "handles" ], b )
      FOR EACH e IN v[ "bindings" ] ; e[ "handle" ] := Eval( b, e[ "handle" ] ) ; NEXT
      EXIT
   CASE "EvaluationGraph"
      FOR EACH e IN v[ "nodes" ] ; e[ "expression" ] := Eval( b, e[ "expression" ] ) ; NEXT
      EXIT
   ENDSWITCH
RETURN
