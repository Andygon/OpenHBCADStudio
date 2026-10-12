/* Tests: class_object.rs no tiene #[test]; todos [extra] */
#include "ocx.ch"
PROCEDURE T_CodecObjClassObj()
   LOCAL o, d, tb, sum, n
   o := Cob_New() ; Chk( Cob_DxfName( o ) == "" .AND. o[ "data" ][ "_kind" ] == "Empty" .AND. Len( Cob_Variants() ) == 51, "[extra] ClassObject default" )
   o := Cob_New( Cob_NewData( "SunStudy" ) ) ; Chk( Cob_DxfName( o ) == "SUNSTUDY" .AND. o[ "data" ][ "value" ][ "view" ] == 0, "[extra] SunStudy dxf_name y default" )
   Chk( Cob_DxfName( Cob_New( Cob_NewData( "IblBackground" ) ) ) == "RAPIDRTRENDERENVIRONMENT" .AND. Cob_DxfName( Cob_New( Cob_NewData( "ViewRepOrientationDefinition" ) ) ) == "ACDBVIEWREPORIENTATIONDEF", "[extra] dxf_name especiales" )
   Chk( Cob_NewData( "PointCloudDefinitionEx" )[ "value" ] != NIL .AND. Cob_DxfName( Cob_New( Cob_NewData( "PointCloudDefinitionReactorEx" ) ) ) == "ACDBPOINTCLOUDDEF_REACTOR_EX", "[extra] variantes Ex" )
   d := Cob_NewViewRep() ; Chk( Len( d[ "transform" ] ) == 16 .AND. Len( d[ "guid" ][ "data4" ] ) == 8 .AND. d[ "action" ] == NIL .AND. d[ "block_path" ] == NIL .AND. Len( d[ "position" ] ) == 2, "[extra] ViewRep default" )
   Chk( Len( Cob_NewDetailViewStyle()[ "base" ] ) == 5 .AND. Cl_Eq( Cob_NewSectionViewStyle()[ "hatch_color" ], Cl_Default() ), "[extra] view styles default" )
   /* visit_handles_mut: SpatialIndex + owner + reactors */
   o := Cob_New( Cob_NewData( "SpatialIndex" ) ) ; o[ "owner" ] := 1 ; o[ "reactors" ] := { 2, 3 } ; o[ "xdictionary_handle" ] := 4 ; o[ "data" ][ "value" ][ "indexed_objects" ] := { 5, 6 }
   sum := {}
   Cob_VisitHandlesMut( o, {| h | AAdd( sum, h ), h + 100 } )
   Chk( Len( sum ) == 6 .AND. o[ "owner" ] == 101 .AND. o[ "reactors" ][ 2 ] == 103 .AND. o[ "xdictionary_handle" ] == 104 .AND. o[ "data" ][ "value" ][ "indexed_objects" ][ 2 ] == 106, "[extra] visit SpatialIndex" )
   /* DataTable: solo columnas ObjectId visitan */
   tb := Cob_New( Cob_NewData( "DataTable" ) ) ; d := tb[ "data" ][ "value" ]
   AAdd( d[ "columns" ], hb_Hash( "value_type", 5, "name", "a", "rows", { Cob_NewDataTableValue() } ) )
   AAdd( d[ "columns" ], hb_Hash( "value_type", 1, "name", "b", "rows", { Cob_NewDataTableValue() } ) )
   d[ "columns" ][ 1 ][ "rows" ][ 1 ][ "handle" ] := 7 ; d[ "columns" ][ 2 ][ "rows" ][ 1 ][ "handle" ] := 8
   Cob_VisitHandlesMut( tb, {| h | iif( h == 0, 0, h + 1 ) } )
   Chk( d[ "columns" ][ 1 ][ "rows" ][ 1 ][ "handle" ] == 8 .AND. d[ "columns" ][ 2 ][ "rows" ][ 1 ][ "handle" ] == 8, "[extra] visit DataTable" )
   d[ "row_count" ] := 1 ; Chk( Dtb_Validate( d ) == NIL, "[extra] validate ok" )
   d[ "row_count" ] := 2 ; Chk( "expected 2" $ Dtb_Validate( d ), "[extra] validate filas" )
   d[ "row_count" ] := -1 ; Chk( "negative" $ Dtb_Validate( d ), "[extra] validate negativo" )
   d[ "row_count" ] := 1 ; d[ "columns" ][ 2 ][ "value_type" ] := 10 ; Chk( "cell type 10" $ Dtb_Validate( d ), "[extra] validate tipo sin codec" )
   Chk( Dtc_IsObjectId( 9 ) .AND. ! Dtc_IsObjectId( 4 ) .AND. Dtc_FromCode( 12 ) == NIL .AND. ! Dtc_HasNativeCodec( 6 ), "[extra] DataTableCellType" )
   d := Cob_NewModelDocViewStyle() ; d[ "description" ] := "D" ; n := Mdv_DisplayNameOrDescription( d ) ; d[ "display_name" ] := "N"
   Chk( n == "D" .AND. Mdv_DisplayNameOrDescription( d ) == "N", "[extra] display_name_or_description" )
RETURN
