/* Tests: classes/mod.rs (6 tests 1:1) + [extra] */
#include "ocx.ch"
PROCEDURE T_CodecClasses()
   LOCAL c, coll, c2, n, cl, ok
   c := Dcl_New( "MLEADERSTYLE", "AcDbMLeaderStyle" ) ; Chk( c[ "dxf_name" ] == "MLEADERSTYLE" .AND. c[ "cpp_class_name" ] == "AcDbMLeaderStyle" .AND. ! c[ "is_an_entity" ] .AND. c[ "item_class_id" ] == 499, "dxf_class_creation" )
   c := Dcl_NewEntity( "MESH", "AcDbSubDMesh" ) ; Chk( c[ "is_an_entity" ] .AND. c[ "item_class_id" ] == 498, "entity_class" )
   coll := Dcc_New() ; c := Dcl_New( "XRECORD", "AcDbXrecord" ) ; c[ "instance_count" ] := 5 ; Dcc_AddOrUpdate( coll, c )
   Chk( Dcc_Len( coll ) == 1 .AND. Dcc_GetByName( coll, "XRECORD" )[ "instance_count" ] == 5 .AND. Dcc_GetByName( coll, "XRECORD" )[ "class_number" ] == 500, "collection_add_or_update alta" )
   c2 := Dcl_New( "xrecord", "AcDbXrecord" ) ; c2[ "instance_count" ] := 10 ; Dcc_AddOrUpdate( coll, c2 )
   Chk( Dcc_Len( coll ) == 1 .AND. Dcc_GetByName( coll, "XRECORD" )[ "instance_count" ] == 10, "collection_add_or_update actualiza" )
   coll := Dcc_New() ; Dcc_UpdateDefaults( coll )
   ok := Dcc_Len( coll ) > 20 .AND. Dcc_Contains( coll, "MESH" ) .AND. Dcc_Contains( coll, "LAYOUT" ) .AND. Dcc_Contains( coll, "MLEADERSTYLE" ) .AND. ! Dcc_Contains( coll, "ACDBASSOCACTIONPARAM" ) ;
      .AND. ! Dcc_Contains( coll, "ACDBASSOCPOINTREFACTIONPARAM" ) .AND. Dcc_Contains( coll, "ACDBASSOCCOMPOUNDACTIONPARAM" ) .AND. Dcc_Contains( coll, "ACDBASSOCOSNAPPOINTREFACTIONPARAM" )
   FOR EACH n IN { "ACDBASSOCVALUEDEPENDENCY", "ACDBASSOCGEOMDEPENDENCY", "ACDBASSOCNETWORK", "ACDBASSOC2DCONSTRAINTGROUP", "ACDBASSOCVARIABLE" }
      cl := Dcc_GetByName( coll, n )
      ok := ok .AND. cl != NIL .AND. cl[ "proxy_flags" ] == 1025 .AND. cl[ "dwg_version" ] == 27 .AND. cl[ "maintenance_version" ] > 0
   NEXT
   Chk( ok, "collection_defaults" )
   coll := Dcc_New() ; Dcc_PushPreserving( coll, Dcl_New( "ACDBASSOCACTIONPARAM", "AcDbAssocActionParam" ) ) ; Dcc_UpdateDefaults( coll )
   Chk( Dcc_Contains( coll, "ACDBASSOCACTIONPARAM" ), "imported_abstract_class_declarations_are_not_discarded" )
   n := PXF_ALL_OPERATIONS_ALLOWED ; Chk( Pxf_Contains( n, PXF_ERASE_ALLOWED ) .AND. Pxf_Contains( n, PXF_TRANSFORM_ALLOWED ) .AND. Pxf_Contains( n, PXF_CLONING_ALLOWED ), "proxy_flags" )
   Chk( Pxf_FromI32( 65536 + 5 ) == 5 .AND. ! Pxf_Contains( PXF_NONE, PXF_ERASE_ALLOWED ), "[extra] proxy_flags: from i32 trunca a u16" )
   coll := Dcc_New() ; Dcc_UpdateDefaults( coll ) ; Dcc_RetainLegacyDwgClasses( coll )
   Chk( Dcc_Len( coll ) > 0 .AND. Dcc_Entries( coll )[ 1 ][ "class_number" ] == 500 .AND. Dcc_Contains( coll, "LAYOUT" ) .AND. ! Dcc_Contains( coll, "HELIX" ), "[extra] retain_legacy_dwg_classes renumera y filtra" )
   Chk( Dcc_Contains( Dcc_New(), "X" ) == .F. .AND. Dcc_GetByName( ( coll := Dcc_New(), Dcc_UpdateDefaults( coll ), coll ), "CSACDOCUMENTOPTIONS" )[ "application_name" ] == '"DERU003_CSAPP"', "[extra] defaults: nombre de aplicacion con comillas escapadas" )
   Dcc_Clear( coll ) ; Chk( Dcc_IsEmpty( coll ) .AND. ! Dcc_Contains( coll, "LAYOUT" ), "[extra] clear" )
RETURN
