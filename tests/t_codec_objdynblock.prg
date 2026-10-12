/* Tests: dynamic_block.rs no tiene #[test]; todos [extra] */
#include "ocx.ch"
PROCEDURE T_CodecObjDynBlock()
   LOCAL o, d, n
   o := Dbo_New( "X", "Y" ) ; Chk( o[ "dxf_name" ] == "X" .AND. o[ "cpp_class_name" ] == "Y" .AND. o[ "data" ][ "_kind" ] == "Unknown", "[extra] DynamicBlockObject::new" )
   Chk( Dbo_NewBlockEvalExpression()[ "parent_id" ] == -1 .AND. Dbo_NewBlockEvalExpression()[ "value" ][ 1 ] == BEV_NONE, "[extra] BlockEvalExpression default (NO_PARENT)" )
   d := Dbo_EmptyEntityFromDxfName( "flipgripentity" ) ; Chk( d != NIL .AND. d[ "_kind" ] == "FlipGripEntity" .AND. Dbo_EntityDxfName( d ) == "FLIPGRIPENTITY" .AND. Dbo_EntityCppName( d ) == "AcDbBlockFlipGripEntity", "[extra] empty_entity_from_dxf_name" )
   Chk( Dbo_EmptyEntityFromDxfName( "NOPE" ) == NIL .AND. Dbo_EntityDxfName( Dbo_NewData( "MoveAction" ) ) == NIL .AND. Dbo_EntityCppName( Dbo_NewData( "AngularConstraintParameterEntity" ) ) == "AcDbBlockAngularConstraintParameterEntity", "[extra] nombres entity" )
   d := Dbo_NewData( "StretchAction" )[ "value" ] ; Chk( Len( d[ "connections" ] ) == 2 .AND. Len( Dbo_NewData( "PolarStretchAction" )[ "value" ][ "connections" ] ) == 6 .AND. Len( Dbo_NewData( "FlipAction" )[ "value" ][ "connections" ] ) == 4, "[extra] arrays de conexiones" )
   d := Dbo_NewData( "TwoPointParameter" ) ; Chk( d[ "value" ] == NIL, "[extra] variante desconocida sin payload" )
   d := Dbo_NewData( "XYParameter" )[ "value" ] ; Chk( Len( d[ "parameter" ][ "properties" ] ) == 4 .AND. d[ "parameter" ][ "updated_base_point" ] == NIL .AND. Len( d[ "parameter" ][ "parameter" ][ "element" ][ "eval" ] ) == 6, "[extra] XYParameter default" )
   /* visit: UserParameter con valor handle */
   o := Dbo_New( "A", "B" ) ; o[ "owner" ] := 1 ; o[ "reactors" ] := { 2 } ; o[ "data" ] := Dbo_NewData( "UserParameter" )
   o[ "data" ][ "value" ][ "associated_variable" ] := 3 ; o[ "data" ][ "value" ][ "value" ] := { BEV_HANDLE, 4 } ; o[ "data" ][ "value" ][ "parameter" ][ "parameter" ][ "element" ][ "eval" ][ "value" ] := { BEV_HANDLE, 5 }
   n := 0 ; Dbo_VisitHandlesMut( o, {| h | n++, h + 10 } )
   Chk( n == 5 .AND. o[ "owner" ] == 11 .AND. o[ "data" ][ "value" ][ "associated_variable" ] == 13 .AND. o[ "data" ][ "value" ][ "value" ][ 2 ] == 14 .AND. o[ "data" ][ "value" ][ "parameter" ][ "parameter" ][ "element" ][ "eval" ][ "value" ][ 2 ] == 15, "[extra] visit UserParameter" )
   /* visit: RotateAction (action.action) y StretchAction */
   o := Dbo_New( "A", "B" ) ; o[ "data" ] := Dbo_NewData( "RotateAction" ) ; AAdd( o[ "data" ][ "value" ][ "action" ][ "action" ][ "dependencies" ], 7 )
   Dbo_VisitHandlesMut( o, {| h | h + 1 } ) ; Chk( o[ "data" ][ "value" ][ "action" ][ "action" ][ "dependencies" ][ 1 ] == 8, "[extra] visit RotateAction" )
   o[ "data" ] := Dbo_NewData( "StretchAction" ) ; AAdd( o[ "data" ][ "value" ][ "handles" ], Dbo_NewBlockStretchHandle() ) ; o[ "data" ][ "value" ][ "handles" ][ 1 ][ "handle" ] := 9
   Dbo_VisitHandlesMut( o, {| h | h + 1 } ) ; Chk( o[ "data" ][ "value" ][ "handles" ][ 1 ][ "handle" ] == 10, "[extra] visit StretchAction" )
   o[ "data" ] := Dbo_NewData( "EvaluationGraph" ) ; AAdd( o[ "data" ][ "value" ][ "nodes" ], Dbo_NewBlockEvaluationNode() ) ; o[ "data" ][ "value" ][ "nodes" ][ 1 ][ "expression" ] := 20
   Dbo_VisitHandlesMut( o, {| h | h + 1 } ) ; Chk( o[ "data" ][ "value" ][ "nodes" ][ 1 ][ "expression" ] == 21, "[extra] visit EvaluationGraph" )
RETURN
