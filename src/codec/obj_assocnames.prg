/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/obj_assocnames.prg
   Origen Rust: opencadcodec/src/objects/associative.rs, lineas 1390-1530 (associative_canonical_name, is_associative_object_name,
   associative_cpp_class_name). El fichero Rust no tiene #[test]; los tests son [extra].
   Licencia del original: MPL-2.0.
   Prefijo: Asn_. El resto de associative.rs (structs y AssociativeData) se porta en obj_assoc.prg (pendiente).
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Asn_CanonicalName( cName )
   LOCAL u := Upper( cName ), c
   IF Left( u, 9 ) == "ACDBASSOC"
      c := "ASSOC" + SubStr( u, 10 )
   ELSE
      c := u
   ENDIF
   SWITCH c
   CASE "ASSOCALIGNEDIMACTIONBODY" ; RETURN "ASSOCALIGNEDDIMACTIONBODY"
   CASE "ACDBPERSSUBENTMANAGER" ; RETURN "PERSUBENTMGR"
   CASE "ACDBDIMASSOC" ; RETURN "DIMASSOC"
   ENDSWITCH
RETURN c

STATIC FUNCTION Asn_Table()
RETURN { ;
   { "ASSOCDEPENDENCY", "AcDbAssocDependency" }, ;
   { "ASSOCPLANESURFACEACTIONBODY", "AcDbAssocPlaneSurfaceActionBody" }, ;
   { "ASSOCEXTENDSURFACEACTIONBODY", "AcDbAssocExtendSurfaceActionBody" }, ;
   { "ASSOCEXTRUDEDSURFACEACTIONBODY", "AcDbAssocExtrudedSurfaceActionBody" }, ;
   { "ASSOCLOFTEDSURFACEACTIONBODY", "AcDbAssocLoftedSurfaceActionBody" }, ;
   { "ASSOCNETWORKSURFACEACTIONBODY", "AcDbAssocNetworkSurfaceActionBody" }, ;
   { "ASSOCOFFSETSURFACEACTIONBODY", "AcDbAssocOffsetSurfaceActionBody" }, ;
   { "ASSOCREVOLVEDSURFACEACTIONBODY", "AcDbAssocRevolvedSurfaceActionBody" }, ;
   { "ASSOCTRIMSURFACEACTIONBODY", "AcDbAssocTrimSurfaceActionBody" }, ;
   { "ASSOCBLENDSURFACEACTIONBODY", "AcDbAssocBlendSurfaceActionBody" }, ;
   { "ASSOCPATCHSURFACEACTIONBODY", "AcDbAssocPatchSurfaceActionBody" }, ;
   { "ASSOCFILLETSURFACEACTIONBODY", "AcDbAssocFilletSurfaceActionBody" }, ;
   { "ASSOCACTION", "AcDbAssocAction" }, ;
   { "ASSOCVALUEDEPENDENCY", "AcDbAssocValueDependency" }, ;
   { "ASSOCGEOMDEPENDENCY", "AcDbAssocGeomDependency" }, ;
   { "ASSOCNETWORK", "AcDbAssocNetwork" }, ;
   { "ASSOCSWEPTSURFACEACTIONBODY", "AcDbAssocSweptSurfaceActionBody" }, ;
   { "ASSOCEDGECHAMFERACTIONBODY", "AcDbAssocEdgeChamferActionBody" }, ;
   { "ASSOCEDGEFILLETACTIONBODY", "AcDbAssocEdgeFilletActionBody" }, ;
   { "ASSOCRESTOREENTITYSTATEACTIONBODY", "AcDbAssocRestoreEntityStateActionBody" }, ;
   { "ASSOCMLEADERACTIONBODY", "AcDbAssocMLeaderActionBody" }, ;
   { "ASSOCALIGNEDDIMACTIONBODY", "AcDbAssocAlignedDimActionBody" }, ;
   { "ASSOC3POINTANGULARDIMACTIONBODY", "AcDbAssoc3PointAngularDimActionBody" }, ;
   { "ASSOCORDINATEDIMACTIONBODY", "AcDbAssocOrdinateDimActionBody" }, ;
   { "ASSOCROTATEDDIMACTIONBODY", "AcDbAssocRotatedDimActionBody" }, ;
   { "ASSOCPERSSUBENTMANAGER", "AcDbAssocPersSubentManager" }, ;
   { "ASSOCEDGEACTIONPARAM", "AcDbAssocEdgeActionParam" }, ;
   { "ASSOC2DCONSTRAINTGROUP", "AcDbAssoc2dConstraintGroup" }, ;
   { "ASSOCVARIABLE", "AcDbAssocVariable" }, ;
   { "ASSOCACTIONPARAM", "AcDbAssocActionParam" }, ;
   { "ASSOCCOMPOUNDACTIONPARAM", "AcDbAssocCompoundActionParam" }, ;
   { "ASSOCOSNAPPOINTREFACTIONPARAM", "AcDbAssocOsnapPointRefActionParam" }, ;
   { "ASSOCPOINTREFACTIONPARAM", "AcDbAssocPointRefActionParam" }, ;
   { "ASSOCOBJECTACTIONPARAM", "AcDbAssocObjectActionParam" }, ;
   { "ASSOCPATHACTIONPARAM", "AcDbAssocPathActionParam" }, ;
   { "ASSOCDIMDEPENDENCYBODY", "AcDbAssocDimDependencyBody" }, ;
   { "ASSOCFACEACTIONPARAM", "AcDbAssocFaceActionParam" }, ;
   { "ASSOCVERTEXACTIONPARAM", "AcDbAssocVertexActionParam" }, ;
   { "ASSOCASMBODYACTIONPARAM", "AcDbAssocAsmbodyActionParam" }, ;
   { "ASSOCARRAYMODIFYPARAMETERS", "AcDbAssocArrayModifyParameters" }, ;
   { "ASSOCARRAYPATHPARAMETERS", "AcDbAssocArrayPathParameters" }, ;
   { "ASSOCARRAYPOLARPARAMETERS", "AcDbAssocArrayPolarParameters" }, ;
   { "ASSOCARRAYRECTANGULARPARAMETERS", "AcDbAssocArrayRectangularParameters" }, ;
   { "ASSOCARRAYACTIONBODY", "AcDbAssocArrayActionBody" }, ;
   { "ASSOCARRAYMODIFYACTIONBODY", "AcDbAssocArrayModifyActionBody" }, ;
   { "DIMASSOC", "AcDbDimAssoc" }, ;
   { "PERSUBENTMGR", "AcDbPersSubentManager" }, ;
   { "ASSOCVIEWREPACTIONBODY", "AcDbAssocViewRepActionBody" }, ;
   { "ASSOCVIEWBORDERACTIONPARAM", "AcDbAssocViewBorderActionParam" }, ;
   { "ASSOCVIEWREPHATCHMANAGER", "AcDbAssocViewRepHatchManager" }, ;
   { "ASSOCVIEWREPACTIONPARAM", "AcDbAssocViewRepActionParam" }, ;
   { "ASSOCVIEWREPHATCHACTIONPARAM", "AcDbAssocViewRepHatchActionParam" }, ;
   { "ASSOCVIEWSYMBOLACTIONPARAM", "AcDbAssocViewSymbolActionParam" }, ;
   { "ASSOCVIEWSTYLEACTIONPARAM", "AcDbAssocViewStyleActionParam" }, ;
   { "ASSOCVIEWLABELACTIONPARAM", "AcDbAssocViewLabelActionParam" }, ;
   { "ACDBCENTERMARKACTIONBODY", "AcDbCenterMarkActionBody" }, ;
   { "ACDBCENTERLINEACTIONBODY", "AcDbCenterLineActionBody" } }

FUNCTION Asn_IsAssociativeObjectName( cName )
   LOCAL c := Asn_CanonicalName( cName ), r
   FOR EACH r IN Asn_Table()
      IF r[ 1 ] == c ; RETURN .T. ; ENDIF
   NEXT
RETURN .F.

/* NIL = None */
FUNCTION Asn_CppClassName( cName )
   LOCAL c := Asn_CanonicalName( cName ), r
   FOR EACH r IN Asn_Table()
      IF r[ 1 ] == c ; RETURN r[ 2 ] ; ENDIF
   NEXT
RETURN NIL
