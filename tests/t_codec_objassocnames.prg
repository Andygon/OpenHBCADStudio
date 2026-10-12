/* Tests: associative.rs no tiene #[test]; todos [extra] */
#include "ocx.ch"
PROCEDURE T_CodecObjAssocNames()
   Chk( Asn_CanonicalName( "acdbassocnetwork" ) == "ASSOCNETWORK", "[extra] canonical prefijo" )
   Chk( Asn_CanonicalName( "ASSOCALIGNEDIMACTIONBODY" ) == "ASSOCALIGNEDDIMACTIONBODY" .AND. Asn_CanonicalName( "ACDBPERSSUBENTMANAGER" ) == "PERSUBENTMGR" .AND. Asn_CanonicalName( "acdbdimassoc" ) == "DIMASSOC", "[extra] canonical alias" )
   Chk( Asn_IsAssociativeObjectName( "AcDbAssocNetwork" ) .AND. Asn_IsAssociativeObjectName( "ACDBCENTERLINEACTIONBODY" ) .AND. ! Asn_IsAssociativeObjectName( "LAYER" ), "[extra] is_associative_object_name" )
   Chk( Asn_CppClassName( "ACDBASSOCDEPENDENCY" ) == "AcDbAssocDependency" .AND. Asn_CppClassName( "ASSOCASMBODYACTIONPARAM" ) == "AcDbAssocAsmbodyActionParam" .AND. Asn_CppClassName( "X" ) == NIL, "[extra] cpp class name" )
   Chk( Asn_CppClassName( "ACDBPERSSUBENTMANAGER" ) == "AcDbPersSubentManager" .AND. Asn_CppClassName( "ASSOCALIGNEDIMACTIONBODY" ) == "AcDbAssocAlignedDimActionBody", "[extra] cpp via alias" )
RETURN
