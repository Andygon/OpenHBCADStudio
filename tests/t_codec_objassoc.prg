/* Tests: associative.rs no tiene #[test]; todos [extra] */
#include "ocx.ch"
PROCEDURE T_CodecObjAssoc()
   LOCAL o, d, n
   o := Aso_New( "A", "B" ) ; Chk( o[ "data" ][ "_kind" ] == "Unknown" .AND. o[ "source_version" ] == NIL .AND. Len( Aso_Variants() ) == 33, "[extra] AssociativeObject::new" )
   Chk( Aso_ClassNameForCode( 1 ) == "AcDbAssocSingleEdgePersSubentId" .AND. Aso_ClassNameForCode( 2 ) == NIL .AND. Aso_CodeForClassName( "acdbassocasmbasedentitypersSubentid" ) == 5 .AND. Aso_CodeForClassName( "x" ) == NIL, "[extra] pers subent class codes" )
   d := Aso_NewData( "ConstraintGroup" )[ "value" ] ; Chk( Len( d[ "work_plane" ] ) == 3 .AND. Aso_NewNodeData( "None" )[ "_kind" ] == "None" .AND. Aso_NewNodeData( "Spline" )[ "knots" ] != NIL .AND. Aso_NewNodeData( "Distance" )[ "distance" ] == NIL, "[extra] defaults constraint group/node" )
   d := Aso_NewAssocDimensionAssociation() ; Chk( Len( d[ "references" ] ) == 4 .AND. Len( d[ "references" ][ 4 ] ) == 0, "[extra] DimensionAssociation default" )
   Chk( Aso_NewAssocArrayItem()[ "relative_transform" ] == NIL .AND. Len( Aso_NewAssocArrayItem()[ "transform" ] ) == 16 .AND. Aso_NewAssocEvalVariant()[ "value" ][ 1 ] == AEV_NONE, "[extra] array item / eval default" )
   /* references + visit: Dependency */
   o := Aso_New( "A", "B" ) ; o[ "data" ] := Aso_NewData( "Dependency" ) ; o[ "data" ][ "value" ][ "node" ] := 7 ; o[ "reactors" ] := { 3 } ; o[ "owner" ] := 1
   Chk( Aso_ReferencesHandle( o, 7 ) .AND. Aso_ReferencesHandle( o, 3 ) .AND. Aso_ReferencesHandle( o, 1 ) .AND. ! Aso_ReferencesHandle( o, 99 ), "[extra] references Dependency" )
   n := 0 ; Aso_VisitHandlesMut( o, {| h | n++, h + 1 } ) ; Chk( n == 6 .AND. o[ "data" ][ "value" ][ "node" ] == 8 .AND. o[ "reactors" ][ 1 ] == 4, "[extra] visit Dependency" )
   /* AsmBodyActionParam: history se visita y referencia */
   o := Aso_New( "A", "B" ) ; o[ "data" ] := Aso_NewData( "AsmBodyActionParam" ) ; o[ "data" ][ "value" ][ "history" ] := 5 ; o[ "data" ][ "value" ][ "single_dependency" ][ "dependency" ] := 6
   Chk( Aso_ReferencesHandle( o, 5 ) .AND. Aso_ReferencesHandle( o, 6 ), "[extra] references AsmBody" )
   d := {} ; Aso_VisitHandlesMut( o, {| h | AAdd( d, h ), h } ) ; Chk( d[ Len( d ) ] == 5 .AND. d[ Len( d ) - 1 ] == 6, "[extra] visit AsmBody: history al final" )
   /* ConstraintGroup node */
   o := Aso_New( "A", "B" ) ; o[ "data" ] := Aso_NewData( "ConstraintGroup" ) ; AAdd( o[ "data" ][ "value" ][ "nodes" ], Aso_NewAssocConstraintNode() )
   o[ "data" ][ "value" ][ "nodes" ][ 1 ][ "data" ] := Aso_NewNodeData( "Angle" ) ; o[ "data" ][ "value" ][ "nodes" ][ 1 ][ "data" ][ "dimension_dependency" ] := 9
   Chk( Aso_ReferencesHandle( o, 9 ), "[extra] references node Angle" )
   Aso_VisitHandlesMut( o, {| h | iif( h == 9, 10, h ) } ) ; Chk( o[ "data" ][ "value" ][ "nodes" ][ 1 ][ "data" ][ "dimension_dependency" ] == 10, "[extra] visit node Angle" )
   /* ArrayParameters: Option<Handle> */
   o := Aso_New( "A", "B" ) ; o[ "data" ] := Aso_NewData( "ArrayParameters" ) ; AAdd( o[ "data" ][ "value" ][ "items" ], Aso_NewAssocArrayItem() ) ; o[ "data" ][ "value" ][ "items" ][ 1 ][ "second_handle" ] := 11
   Chk( Aso_ReferencesHandle( o, 11 ) .AND. ! Aso_ReferencesHandle( o, 99 ), "[extra] references array item opcional" )
   Aso_VisitHandlesMut( o, {| h | h + 1 } ) ; Chk( o[ "data" ][ "value" ][ "items" ][ 1 ][ "second_handle" ] == 12 .AND. o[ "data" ][ "value" ][ "items" ][ 1 ][ "first_handle" ] == NIL, "[extra] visit array item opcional" )
   /* Variable: eval handle */
   o := Aso_New( "A", "B" ) ; o[ "data" ] := Aso_NewData( "Variable" ) ; o[ "data" ][ "value" ][ "value" ][ "value" ] := { AEV_HANDLE, 13 }
   Chk( Aso_ReferencesHandle( o, 13 ), "[extra] references Variable eval" )
   /* DimensionAssociation */
   o := Aso_New( "A", "B" ) ; o[ "data" ] := Aso_NewData( "DimensionAssociation" ) ; AAdd( o[ "data" ][ "value" ][ "references" ][ 2 ], Aso_NewAssocDimensionReference() ) ; AAdd( o[ "data" ][ "value" ][ "references" ][ 2 ][ 1 ][ "xrefs" ], 14 )
   Chk( Aso_ReferencesHandle( o, 14 ), "[extra] references dimension xrefs" )
   Aso_VisitHandlesMut( o, {| h | h + 1 } ) ; Chk( o[ "data" ][ "value" ][ "references" ][ 2 ][ 1 ][ "xrefs" ][ 1 ] == 15, "[extra] visit dimension xrefs" )
RETURN
