/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/classes.prg
   Origen Rust: opencadcodec/src/classes/mod.rs (828 lineas, 6 tests). Licencia del original: MPL-2.0.
   Prefijos: Dcl_ (DxfClass), Dcc_ (DxfClassCollection), Pxf_ (ProxyFlags, enteros u16: constantes PXF_* en este fichero).
   DxfClassCollection = hash { "entries": array, "name_index": hash UPPER(dxf_name) -> indice base 0 }. Option<&T> -> NIL.
   Tablas default_classes y LEGACY generadas mecanicamente del Rust (254 y 38 entradas). Metodos iter/IntoIterator: usar Dcc_Entries.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Pxf_Contains( nSelf, nFlag ) ; RETURN hb_bitAnd( nSelf, nFlag ) == nFlag
FUNCTION Pxf_FromI32( n ) ; RETURN hb_bitAnd( n, 65535 )

FUNCTION Dcl_New( cDxf, cCpp )
RETURN hb_Hash( "dxf_name", cDxf, "cpp_class_name", cCpp, "application_name", "ObjectDBX Classes", "proxy_flags", PXF_NONE, "instance_count", 0, "was_zombie", .F., "is_an_entity", .F., ;
   "class_number", 0, "item_class_id", 499, "dwg_version", 0, "maintenance_version", 0, "unknown1", 0, "unknown2", 0 )
FUNCTION Dcl_NewEntity( cDxf, cCpp )
   LOCAL c := Dcl_New( cDxf, cCpp )
   c[ "is_an_entity" ] := .T. ; c[ "item_class_id" ] := 498
RETURN c

FUNCTION Dcc_New() ; RETURN hb_Hash( "entries", {}, "name_index", hb_Hash() )
FUNCTION Dcc_Entries( c ) ; RETURN c[ "entries" ]

PROCEDURE Dcc_AddOrUpdate( c, cl )
   LOCAL cKey := Upper( cl[ "dxf_name" ] ), nIdx
   IF hb_HHasKey( c[ "name_index" ], cKey )
      c[ "entries" ][ c[ "name_index" ][ cKey ] + 1 ][ "instance_count" ] := cl[ "instance_count" ]
   ELSE
      IF cl[ "class_number" ] < 500 ; cl[ "class_number" ] := 500 + Len( c[ "entries" ] ) ; ENDIF
      nIdx := Len( c[ "entries" ] )
      c[ "name_index" ][ cKey ] := nIdx
      AAdd( c[ "entries" ], cl )
   ENDIF
RETURN

PROCEDURE Dcc_PushPreserving( c, cl )
   c[ "name_index" ][ Upper( cl[ "dxf_name" ] ) ] := Len( c[ "entries" ] )
   AAdd( c[ "entries" ], cl )
RETURN

FUNCTION Dcc_GetByName( c, cName )
   LOCAL cKey := Upper( cName )
RETURN iif( hb_HHasKey( c[ "name_index" ], cKey ), c[ "entries" ][ c[ "name_index" ][ cKey ] + 1 ], NIL )
FUNCTION Dcc_Contains( c, cName ) ; RETURN hb_HHasKey( c[ "name_index" ], Upper( cName ) )
FUNCTION Dcc_Len( c ) ; RETURN Len( c[ "entries" ] )
FUNCTION Dcc_IsEmpty( c ) ; RETURN Len( c[ "entries" ] ) == 0
PROCEDURE Dcc_Clear( c )
   ASize( c[ "entries" ], 0 ) ; hb_HClear( c[ "name_index" ] )
RETURN

PROCEDURE Dcc_RetainLegacyDwgClasses( c )
   LOCAL aLegacy := { "ACDBDICTIONARYWDFLT", "DICTIONARYVAR", "LAYOUT", "ACDBPLACEHOLDER", "PLOTSETTINGS", "SCALE", "MESH", "ACAD_TABLE", "WIPEOUT", "IMAGE", "PDFREFERENCE", "DWFREFERENCE", "DGNREFERENCE", "MULTILEADER", "OLE2FRAME", "MLINE", "TABLESTYLE", "MATERIAL", "VISUALSTYLE", "MLEADERSTYLE", "CELLSTYLEMAP", "XRECORD", "SORTENTSTABLE", "WIPEOUTVARIABLES", "DIMASSOC", "TABLECONTENT", "TABLEGEOMETRY", "RASTERVARIABLES", "IMAGEDEF", "IMAGEDEF_REACTOR", "DBCOLOR", "GEODATA", "PDFDEFINITION", "DWFDEFINITION", "DGNDEFINITION", "SPATIAL_FILTER", "GROUP", "MLINESTYLE" }
   LOCAL aNew := {}, cl, i
   FOR EACH cl IN c[ "entries" ]
      IF AScan( aLegacy, {| x | x == Upper( cl[ "dxf_name" ] ) } ) > 0 ; AAdd( aNew, cl ) ; ENDIF
   NEXT
   c[ "entries" ] := aNew ; c[ "name_index" ] := hb_Hash()
   FOR i := 1 TO Len( aNew )
      aNew[ i ][ "class_number" ] := 500 + i - 1
      c[ "name_index" ][ Upper( aNew[ i ][ "dxf_name" ] ) ] := i - 1
   NEXT
RETURN

PROCEDURE Dcc_UpdateDefaults( c )
   LOCAL cl
   FOR EACH cl IN Dcl_DefaultClasses()
      IF ! Dcc_Contains( c, cl[ "dxf_name" ] ) ; Dcc_AddOrUpdate( c, cl ) ; ENDIF
   NEXT
RETURN

/* (dxf_name, cpp_class_name, proxy_flags, app_name, is_entity) */
FUNCTION Dcl_DefaultClasses()
   LOCAL aDefs := { ;
      { "MESH", "AcDbSubDMesh", 4095, "AcDbSubDMesh|Description: AutoCAD subD mesh", .T. }, ;
      { "ACAD_TABLE", "AcDbTable", 1025, "ObjectDBX Classes", .T. }, ;
      { "WIPEOUT", "AcDbWipeout", 127, "WipeOut|AutoCAD Express Tool|www.autodesk.com", .T. }, ;
      { "IMAGE", "AcDbRasterImage", 127, "ISM", .T. }, ;
      { "PDFREFERENCE", "AcDbPdfReference", 1, "ObjectDBX Classes", .T. }, ;
      { "DWFREFERENCE", "AcDbDwfReference", 1, "ObjectDBX Classes", .T. }, ;
      { "DGNREFERENCE", "AcDbDgnReference", 1, "ObjectDBX Classes", .T. }, ;
      { "PDFUNDERLAY", "AcDbPdfReference", 1, "ObjectDBX Classes", .T. }, ;
      { "DWFUNDERLAY", "AcDbDwfReference", 1, "ObjectDBX Classes", .T. }, ;
      { "DGNUNDERLAY", "AcDbDgnReference", 1, "ObjectDBX Classes", .T. }, ;
      { "HELIX", "AcDbHelix", 0, "ObjectDBX Classes", .T. }, ;
      { "LIGHT", "AcDbLight", 1153, "SCENEOE", .T. }, ;
      { "MULTILEADER", "AcDbMLeader", 1025, "ACDB_MLEADER_CLASS", .T. }, ;
      { "OLE2FRAME", "AcDbOle2Frame", 1, "ObjectDBX Classes", .T. }, ;
      { "MLINE", "AcDbMline", 1, "ObjectDBX Classes", .T. }, ;
      { "ARC_DIMENSION", "AcDbArcDimension", 0, "ObjectDBX Classes", .T. }, ;
      { "LARGE_RADIAL_DIMENSION", "AcDbRadialDimensionLarge", 0, "ObjectDBX Classes", .T. }, ;
      { "CAMERA", "AcDbCamera", 0, "ObjectDBX Classes", .T. }, ;
      { "SECTIONOBJECT", "AcDbSection", 0, "ObjectDBX Classes", .T. }, ;
      { "ARCALIGNEDTEXT", "AcDbArcAlignedText", 127, "AutoCAD Express Tools", .T. }, ;
      { "RTEXT", "AcDbRText", 127, "AutoCAD Express Tools", .T. }, ;
      { "POSITIONMARKER", "AcDbGeoPositionMarker", 0, "ObjectDBX Classes", .T. }, ;
      { "COORDINATION_MODEL", "AcDbNavisworksModel", 0, "ObjectDBX Classes", .T. }, ;
      { "ACDBPOINTCLOUD", "AcDbPointCloud", 0, "AcDbPointCloudObj", .T. }, ;
      { "ACDBPOINTCLOUDEX", "AcDbPointCloudEx", 0, "AcDbPointCloudObj", .T. }, ;
      { "MPOLYGON", "AcDbMPolygon", 127, "ObjectDBX Classes", .T. }, ;
      { "ALIGNMENTPARAMETERENTITY", "AcDbBlockAlignmentParameterEntity", 0, "ObjectDBX Classes", .T. }, ;
      { "BASEPOINTPARAMETERENTITY", "AcDbBlockBasepointParameterEntity", 0, "ObjectDBX Classes", .T. }, ;
      { "FLIPPARAMETERENTITY", "AcDbBlockFlipParameterEntity", 0, "ObjectDBX Classes", .T. }, ;
      { "LINEARPARAMETERENTITY", "AcDbBlockLinearParameterEntity", 0, "ObjectDBX Classes", .T. }, ;
      { "POINTPARAMETERENTITY", "AcDbBlockPointParameterEntity", 0, "ObjectDBX Classes", .T. }, ;
      { "ROTATIONPARAMETERENTITY", "AcDbBlockRotationParameterEntity", 0, "ObjectDBX Classes", .T. }, ;
      { "VISIBILITYPARAMETERENTITY", "AcDbBlockVisibilityParameterEntity", 0, "ObjectDBX Classes", .T. }, ;
      { "FLIPGRIPENTITY", "AcDbBlockFlipGripEntity", 0, "ObjectDBX Classes", .T. }, ;
      { "LINEARGRIPENTITY", "AcDbBlockLinearGripEntity", 0, "ObjectDBX Classes", .T. }, ;
      { "POLARGRIPENTITY", "AcDbBlockPolarGripEntity", 0, "ObjectDBX Classes", .T. }, ;
      { "ROTATIONGRIPENTITY", "AcDbBlockRotationGripEntity", 0, "ObjectDBX Classes", .T. }, ;
      { "VISIBILITYGRIPENTITY", "AcDbBlockVisibilityGripEntity", 0, "ObjectDBX Classes", .T. }, ;
      { "XYGRIPENTITY", "AcDbBlockXYGripEntity", 0, "ObjectDBX Classes", .T. }, ;
      { "XYPARAMETERENTITY", "AcDbBlockXYParameterEntity", 0, "ObjectDBX Classes", .T. }, ;
      { "BLOCKANGULARCONSTRAINTPARAMETERENTITY", "AcDbBlockAngularConstraintParameterEntity", 0, "ObjectDBX Classes", .T. }, ;
      { "LOFTEDSURFACE", "AcDbLoftedSurface", 0, "ObjectDBX Classes", .T. }, ;
      { "ACDBASSOCDEPENDENCY", "AcDbAssocDependency", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCVALUEDEPENDENCY", "AcDbAssocValueDependency", 1025, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCGEOMDEPENDENCY", "AcDbAssocGeomDependency", 1025, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCACTION", "AcDbAssocAction", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCNETWORK", "AcDbAssocNetwork", 1025, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOC2DCONSTRAINTGROUP", "AcDbAssoc2dConstraintGroup", 1025, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCVARIABLE", "AcDbAssocVariable", 1025, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCPERSSUBENTMANAGER", "AcDbAssocPersSubentManager", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCCOMPOUNDACTIONPARAM", "AcDbAssocCompoundActionParam", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCOSNAPPOINTREFACTIONPARAM", "AcDbAssocOsnapPointRefActionParam", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCOBJECTACTIONPARAM", "AcDbAssocObjectActionParam", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCPATHACTIONPARAM", "AcDbAssocPathActionParam", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCEDGEACTIONPARAM", "AcDbAssocEdgeActionParam", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCFACEACTIONPARAM", "AcDbAssocFaceActionParam", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCVERTEXACTIONPARAM", "AcDbAssocVertexActionParam", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCASMBODYACTIONPARAM", "AcDbAssocAsmbodyActionParam", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCDIMDEPENDENCYBODY", "AcDbAssocDimDependencyBody", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCPLANESURFACEACTIONBODY", "AcDbAssocPlaneSurfaceActionBody", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCEXTENDSURFACEACTIONBODY", "AcDbAssocExtendSurfaceActionBody", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCEXTRUDEDSURFACEACTIONBODY", "AcDbAssocExtrudedSurfaceActionBody", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCLOFTEDSURFACEACTIONBODY", "AcDbAssocLoftedSurfaceActionBody", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCNETWORKSURFACEACTIONBODY", "AcDbAssocNetworkSurfaceActionBody", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCOFFSETSURFACEACTIONBODY", "AcDbAssocOffsetSurfaceActionBody", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCREVOLVEDSURFACEACTIONBODY", "AcDbAssocRevolvedSurfaceActionBody", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCTRIMSURFACEACTIONBODY", "AcDbAssocTrimSurfaceActionBody", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCBLENDSURFACEACTIONBODY", "AcDbAssocBlendSurfaceActionBody", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCPATCHSURFACEACTIONBODY", "AcDbAssocPatchSurfaceActionBody", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCFILLETSURFACEACTIONBODY", "AcDbAssocFilletSurfaceActionBody", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCSWEPTSURFACEACTIONBODY", "AcDbAssocSweptSurfaceActionBody", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCEDGECHAMFERACTIONBODY", "AcDbAssocEdgeChamferActionBody", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCEDGEFILLETACTIONBODY", "AcDbAssocEdgeFilletActionBody", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCRESTOREENTITYSTATEACTIONBODY", "AcDbAssocRestoreEntityStateActionBody", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCMLEADERACTIONBODY", "AcDbAssocMLeaderActionBody", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCALIGNEDDIMACTIONBODY", "AcDbAssocAlignedDimActionBody", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOC3POINTANGULARDIMACTIONBODY", "AcDbAssoc3PointAngularDimActionBody", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCORDINATEDIMACTIONBODY", "AcDbAssocOrdinateDimActionBody", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCROTATEDDIMACTIONBODY", "AcDbAssocRotatedDimActionBody", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCARRAYMODIFYPARAMETERS", "AcDbAssocArrayModifyParameters", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCARRAYPATHPARAMETERS", "AcDbAssocArrayPathParameters", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCARRAYPOLARPARAMETERS", "AcDbAssocArrayPolarParameters", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCARRAYRECTANGULARPARAMETERS", "AcDbAssocArrayRectangularParameters", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCARRAYACTIONBODY", "AcDbAssocArrayActionBody", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBASSOCARRAYMODIFYACTIONBODY", "AcDbAssocArrayModifyActionBody", 0, "ObjectDBX Classes", .F. }, ;
      { "PERSUBENTMGR", "AcDbPersSubentManager", 0, "ObjectDBX Classes", .F. }, ;
      { "ACSH_BOOLEAN_CLASS", "AcDbShBoolean", 0, "ObjectDBX Classes", .F. }, ;
      { "ACSH_BOX_CLASS", "AcDbShBox", 0, "ObjectDBX Classes", .F. }, ;
      { "ACSH_BREP_CLASS", "AcDbShBrep", 0, "ObjectDBX Classes", .F. }, ;
      { "ACSH_CHAMFER_CLASS", "AcDbShChamfer", 0, "ObjectDBX Classes", .F. }, ;
      { "ACSH_CONE_CLASS", "AcDbShCone", 0, "ObjectDBX Classes", .F. }, ;
      { "ACSH_CYLINDER_CLASS", "AcDbShCylinder", 0, "ObjectDBX Classes", .F. }, ;
      { "ACSH_EXTRUSION_CLASS", "AcDbShExtrusion", 0, "ObjectDBX Classes", .F. }, ;
      { "ACSH_FILLET_CLASS", "AcDbShFillet", 0, "ObjectDBX Classes", .F. }, ;
      { "ACSH_HISTORY_CLASS", "AcDbShHistory", 0, "ObjectDBX Classes", .F. }, ;
      { "ACSH_LOFT_CLASS", "AcDbShLoft", 0, "ObjectDBX Classes", .F. }, ;
      { "ACSH_PYRAMID_CLASS", "AcDbShPyramid", 0, "ObjectDBX Classes", .F. }, ;
      { "ACSH_REVOLVE_CLASS", "AcDbShRevolve", 0, "ObjectDBX Classes", .F. }, ;
      { "ACSH_SPHERE_CLASS", "AcDbShSphere", 0, "ObjectDBX Classes", .F. }, ;
      { "ACSH_SWEEP_CLASS", "AcDbShSweep", 0, "ObjectDBX Classes", .F. }, ;
      { "ACSH_TORUS_CLASS", "AcDbShTorus", 0, "ObjectDBX Classes", .F. }, ;
      { "ACSH_WEDGE_CLASS", "AcDbShWedge", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDB_BLOCKREPRESENTATION_DATA", "AcDbBlockRepresentationData", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDB_DYNAMICBLOCKPURGEPREVENTER_VERSION", "AcDbDynamicBlockPurgePreventer", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDB_DYNAMICBLOCKPROXYNODE", "AcDbDynamicBlockProxyNode", 0, "ObjectDBX Classes", .F. }, ;
      { "ACAD_EVALUATION_GRAPH", "AcDbEvalGraph", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKGRIPLOCATIONCOMPONENT", "AcDbBlockGripExpr", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKALIGNMENTPARAMETER", "AcDbBlockAlignmentParameter", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKALIGNMENTGRIP", "AcDbBlockAlignmentGrip", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKBASEPOINTPARAMETER", "AcDbBlockBasepointParameter", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKFLIPACTION", "AcDbBlockFlipAction", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKFLIPPARAMETER", "AcDbBlockFlipParameter", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKFLIPGRIP", "AcDbBlockFlipGrip", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKLINEARGRIP", "AcDbBlockLinearGrip", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKLOOKUPGRIP", "AcDbBlockLookupGrip", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKROTATIONGRIP", "AcDbBlockRotationGrip", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKMOVEACTION", "AcDbBlockMoveAction", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKROTATEACTION", "AcDbBlockRotationAction", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKSCALEACTION", "AcDbBlockScaleAction", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKVISIBILITYGRIP", "AcDbBlockVisibilityGrip", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKLINEARPARAMETER", "AcDbBlockLinearParameter", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKROTATIONPARAMETER", "AcDbBlockRotationParameter", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKXYPARAMETER", "AcDbBlockXYParameter", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKVISIBILITYPARAMETER", "AcDbBlockVisibilityParameter", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKPOLARPARAMETER", "AcDbBlockPolarParameter", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKPOLARGRIP", "AcDbBlockPolarGrip", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBBLOCKPARAMDEPENDENCYBODY", "AcDbBlockParameterDependencyBody", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKPARAMDEPENDENCYBODY", "AcDbBlockParameterDependencyBody", 0, "ObjectDBX Classes", .F. }, ;
      { "ACMECOMMANDHISTORY", "AcMeCommandHistory", 0, "AcMeServices", .F. }, ;
      { "ACMESCOPE", "AcMeScope", 0, "AcMeServices", .F. }, ;
      { "ACMESTATEMGR", "AcMeStateMgr", 0, "AcMeServices", .F. }, ;
      { "CSACDOCUMENTOPTIONS", "CDocDataContainer", 4095, '"DERU003_CSAPP"', .F. }, ;
      { "BLOCKALIGNEDCONSTRAINTPARAMETER", "AcDbBlockAlignedConstraintParameter", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKANGULARCONSTRAINTPARAMETER", "AcDbBlockAngularConstraintParameter", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKARRAYACTION", "AcDbBlockArrayAction", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKDIAMETRICCONSTRAINTPARAMETER", "AcDbBlockDiametricConstraintParameter", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKHORIZONTALCONSTRAINTPARAMETER", "AcDbBlockHorizontalConstraintParameter", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKLINEARCONSTRAINTPARAMETER", "AcDbBlockLinearConstraintParameter", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKRADIALCONSTRAINTPARAMETER", "AcDbBlockRadialConstraintParameter", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKVERTICALCONSTRAINTPARAMETER", "AcDbBlockVerticalConstraintParameter", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKLOOKUPACTION", "AcDbBlockLookupAction", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKLOOKUPPARAMETER", "AcDbBlockLookupParameter", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKPOINTPARAMETER", "AcDbBlockPointParameter", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKPOLARSTRETCHACTION", "AcDbBlockPolarStretchAction", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKSTRETCHACTION", "AcDbBlockStretchAction", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKUSERPARAMETER", "AcDbBlockUserParameter", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKXYGRIP", "AcDbBlockXYGrip", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKPROPERTIESTABLE", "AcDbBlockPropertiesTable", 0, "ObjectDBX Classes", .F. }, ;
      { "BLOCKPROPERTIESTABLEGRIP", "AcDbBlockPropertiesTableGrip", 0, "ObjectDBX Classes", .F. }, ;
      { "SPATIAL_INDEX", "AcDbSpatialIndex", 0, "ObjectDBX Classes", .F. }, ;
      { "LAYERFILTER", "AcDbLayerFilter", 0, "ObjectDBX Classes", .F. }, ;
      { "PARTIAL_VIEWING_INDEX", "OdDbPartialViewingIndex", 0, "ObjectDBX Classes", .F. }, ;
      { "VBA_PROJECT", "AcDbVbaProject", 0, "ObjectDBX Classes", .F. }, ;
      { "SECTION_MANAGER", "AcDbSectionManager", 0, "ObjectDBX Classes", .F. }, ;
      { "SECTION_SETTINGS", "AcDbSectionSettings", 0, "ObjectDBX Classes", .F. }, ;
      { "LIGHTLIST", "AcDbLightList", 0, "SCENEOE", .F. }, ;
      { "SUN", "AcDbSun", 0, "SCENEOE", .F. }, ;
      { "SUNSTUDY", "AcDbSunStudy", 0, "SCENEOE", .F. }, ;
      { "RENDERSETTINGS", "AcDbRenderSettings", 0, "SCENEOE", .F. }, ;
      { "MENTALRAYRENDERSETTINGS", "AcDbMentalRayRenderSettings", 0, "SCENEOE", .F. }, ;
      { "RAPIDRTRENDERSETTINGS", "AcDbRapidRTRenderSettings", 0, "ObjectDBX Classes", .F. }, ;
      { "RENDERENVIRONMENT", "AcDbRenderEnvironment", 0, "SCENEOE", .F. }, ;
      { "RENDERGLOBAL", "AcDbRenderGlobal", 0, "SCENEOE", .F. }, ;
      { "RENDERENTRY", "AcDbRenderEntry", 0, "SCENEOE", .F. }, ;
      { "RAPIDRTRENDERENVIRONMENT", "AcDbIBLBackground", 0, "SCENEOE", .F. }, ;
      { "SKYLIGHT_BACKGROUND", "AcDbSkyBackground", 0, "SCENEOE", .F. }, ;
      { "IMAGE_BACKGROUND", "AcDbImageBackground", 0, "SCENEOE", .F. }, ;
      { "SOLID_BACKGROUND", "AcDbSolidBackground", 0, "SCENEOE", .F. }, ;
      { "GROUND_PLANE_BACKGROUND", "AcDbGroundPlaneBackground", 0, "SCENEOE", .F. }, ;
      { "GRADIENT_BACKGROUND", "AcDbGradientBackground", 0, "SCENEOE", .F. }, ;
      { "ACDBCURVEPATH", "AcDbCurvePath", 0, "SCENEOE", .F. }, ;
      { "ACDBMOTIONPATH", "AcDbMotionPath", 0, "SCENEOE", .F. }, ;
      { "ACDBPOINTPATH", "AcDbPointPath", 0, "SCENEOE", .F. }, ;
      { "TVDEVICEPROPERTIES", "AcDbTvDeviceProperties", 0, "SCENEOE", .F. }, ;
      { "ACDBPOINTCLOUDDEF", "AcDbPointCloudDef", 0, "AcDbPointCloudObj", .F. }, ;
      { "ACDBPOINTCLOUDDEF_EX", "AcDbPointCloudDefEx", 1024, "AcDbPointCloudObj", .F. }, ;
      { "ACDBPOINTCLOUDDEF_REACTOR", "AcDbPointCloudDefReactor", 0, "AcDbPointCloudObj", .F. }, ;
      { "ACDBPOINTCLOUDDEF_REACTOR_EX", "AcDbPointCloudDefReactorEx", 1025, "AcDbPointCloudObj", .F. }, ;
      { "ACDBPOINTCLOUDCOLORMAP", "AcDbPointCloudColorMap", 1025, "AcDbPointCloudObj", .F. }, ;
      { "NAVISWORKSMODELDEF", "AcDbNavisworksModelDef", 0, "ObjectDBX Classes", .F. }, ;
      { "CONTEXTDATAMANAGER", "AcDbContextDataManager", 0, "ObjectDBX Classes", .F. }, ;
      { "DATATABLE", "AcDbDataTable", 0, "ObjectDBX Classes", .F. }, ;
      { "DATALINK", "AcDbDataLink", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBPERSSUBENTMANAGER", "AcDbPersSubentManager", 0, "ObjectDBX Classes", .F. }, ;
      { "GEOMAPIMAGE", "AcDbGeomapImage", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBDETAILVIEWSTYLE", "AcDbDetailViewStyle", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBSECTIONVIEWSTYLE", "AcDbSectionViewStyle", 0, "ObjectDBX Classes", .F. }, ;
      { "ACAD_PROXY_ENTITY_WRAPPER", "AcDbProxyEntityWrapper", 0, "ObjectDBX Classes", .T. }, ;
      { "ACAD_PROXY_OBJECT_WRAPPER", "AcDbProxyObjectWrapper", 0, "ObjectDBX Classes", .F. }, ;
      { "AEC_REFEDIT_STATUS_TRACKER", "AecDbRefEditStatusTracker", 0, "AecArchBase", .F. }, ;
      { "EXACXREFPANELOBJECT", "ExAcXREFPanelObject", 0, "EXAC_ESW", .F. }, ;
      { "XREFPANELOBJECT", "ExAcXREFPanelObject", 0, "EXAC_ESW", .F. }, ;
      { "NPOCOLLECTION", "AcDbImpNonPersistentObjectsCollection", 0, "ObjectDBX Classes", .F. }, ;
      { "LSDEFINITION", "AcDbLSDefinition", 0, "DgnLS", .F. }, ;
      { "LSSYMBOLCOMPONENT", "AcDbLSSymbolComponent", 0, "DgnLS", .F. }, ;
      { "LSCOMPOUNDCOMPONENT", "AcDbLSCompoundComponent", 0, "DgnLS", .F. }, ;
      { "LSSTROKEPATTERNCOMPONENT", "AcDbLSStrokePatternComponent", 0, "DgnLS", .F. }, ;
      { "LSPOINTCOMPONENT", "AcDbLSPointComponent", 0, "DgnLS", .F. }, ;
      { "LSINTERNALCOMPONENT", "AcDbLSInternalComponent", 0, "DgnLS", .F. }, ;
      { "McDbContainer2", "McDbContainer2", 0, "NanoSPDS", .F. }, ;
      { "Wall", "PtDbWall", 0, "NanoSPDS", .T. }, ;
      { "mcsDbObject", "mcsDbObject", 0, "NanoSPDS", .T. }, ;
      { "NOTEPOSITION", "mcsDbObjectNotePosition", 0, "NanoSPDS", .T. }, ;
      { "spdsLevelMark", "mcsDbObjectLevelMark", 0, "NanoSPDS", .T. }, ;
      { "spdsRelationMark", "mcsDbObjectRelationMark", 0, "NanoSPDS", .T. }, ;
      { "SECTIONLINE", "AcDbSectionSymbol", 0, "ObjectDBX Classes", .T. }, ;
      { "DRAWINGVIEW", "AcDbViewBorder", 0, "ObjectDBX Classes", .T. }, ;
      { "ACDB_ANNOTSCALEOBJECTCONTEXTDATA_CLASS", "AcDbAnnotScaleObjectContextData", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDB_BLKREFOBJECTCONTEXTDATA_CLASS", "AcDbBlkrefObjectContextData", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDB_TEXTOBJECTCONTEXTDATA_CLASS", "AcDbTextObjectContextData", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDB_MTEXTOBJECTCONTEXTDATA_CLASS", "AcDbMTextObjectContextData", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDB_ALDIMOBJECTCONTEXTDATA_CLASS", "AcDbAlignedDimensionObjectContextData", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDB_ANGDIMOBJECTCONTEXTDATA_CLASS", "AcDbAngularDimensionObjectContextData", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDB_DMDIMOBJECTCONTEXTDATA_CLASS", "AcDbDiametricDimensionObjectContextData", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDB_RADIMOBJECTCONTEXTDATA_CLASS", "AcDbRadialDimensionObjectContextData", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDB_RADIMLGOBJECTCONTEXTDATA_CLASS", "AcDbRadialDimensionLargeObjectContextData", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDB_ORDDIMOBJECTCONTEXTDATA_CLASS", "AcDbOrdinateDimensionObjectContextData", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDB_MLEADEROBJECTCONTEXTDATA_CLASS", "AcDbMLeaderObjectContextData", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDB_MTEXTATTRIBUTEOBJECTCONTEXTDATA_CLASS", "AcDbMTextAttributeObjectContextData", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDB_LEADEROBJECTCONTEXTDATA_CLASS", "AcDbLeaderObjectContextData", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDB_FCFOBJECTCONTEXTDATA_CLASS", "AcDbFcfObjectContextData", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDB_HATCHSCALECONTEXTDATA_CLASS", "AcDbHatchScaleContextData", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDB_HATCHVIEWCONTEXTDATA_CLASS", "AcDbHatchViewContextData", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBDICTIONARYWDFLT", "AcDbDictionaryWithDefault", 0, "ObjectDBX Classes", .F. }, ;
      { "ACDBPLACEHOLDER", "AcDbPlaceHolder", 0, "ObjectDBX Classes", .F. }, ;
      { "LAYOUT", "AcDbLayout", 0, "ObjectDBX Classes", .F. }, ;
      { "DICTIONARYVAR", "AcDbDictionaryVar", 0, "ObjectDBX Classes", .F. }, ;
      { "TABLESTYLE", "AcDbTableStyle", 1025, "ObjectDBX Classes", .F. }, ;
      { "MATERIAL", "AcDbMaterial", 1025, "ObjectDBX Classes", .F. }, ;
      { "VISUALSTYLE", "AcDbVisualStyle", 4095, "ObjectDBX Classes", .F. }, ;
      { "SCALE", "AcDbScale", 1153, "ObjectDBX Classes", .F. }, ;
      { "MLEADERSTYLE", "AcDbMLeaderStyle", 4095, "ACDB_MLEADERSTYLE_CLASS", .F. }, ;
      { "CELLSTYLEMAP", "AcDbCellStyleMap", 1025, "ObjectDBX Classes", .F. }, ;
      { "ACDSRECORD", "AcDsRecord", 0, "AcDsData", .F. }, ;
      { "ACDSSCHEMA", "AcDsSchema", 0, "AcDsData", .F. }, ;
      { "XRECORD", "AcDbXrecord", 0, "ObjectDBX Classes", .F. }, ;
      { "SORTENTSTABLE", "AcDbSortentsTable", 0, "ObjectDBX Classes", .F. }, ;
      { "BREAKDATA", "AcDbBreakData", 0, "ObjectDBX Classes", .F. }, ;
      { "BREAKPOINTREF", "AcDbBreakPointRef", 0, "ObjectDBX Classes", .F. }, ;
      { "IDBUFFER", "AcDbIdBuffer", 0, "ObjectDBX Classes", .F. }, ;
      { "INDEX", "AcDbIndex", 0, "ObjectDBX Classes", .F. }, ;
      { "LAYER_INDEX", "AcDbLayerIndex", 0, "ObjectDBX Classes", .F. }, ;
      { "PARTIAL_VIEWING_FILTER", "OdDbPartialViewingFilter", 0, "OdDbPartialViewing|https://www.opendesign.com Teigha(R) Core Db", .F. }, ;
      { "WIPEOUTVARIABLES", "AcDbWipeoutVariables", 0, "WipeOut|AutoCAD Express Tool|www.autodesk.com", .F. }, ;
      { "DIMASSOC", "AcDbDimAssoc", 0, "AcDbDimAssoc|Product Desc:     AcDim ARX App For Dimension|Company:          Autodesk|WEB Address:      www.autodesk.com", .F. }, ;
      { "TABLECONTENT", "AcDbTableContent", 1025, "ObjectDBX Classes", .F. }, ;
      { "TABLEGEOMETRY", "AcDbTableGeometry", 1025, "ObjectDBX Classes", .F. }, ;
      { "Format", "mcsDbObjectFormat", 0, "NanoSPDS", .T. }, ;
      { "RASTERVARIABLES", "AcDbRasterVariables", 0, "ISM", .F. }, ;
      { "IMAGEDEF", "AcDbRasterImageDef", 0, "ISM", .F. }, ;
      { "IMAGEDEF_REACTOR", "AcDbRasterImageDefReactor", 1, "ISM", .F. }, ;
      { "DBCOLOR", "AcDbColor", 1025, "ObjectDBX Classes", .F. }, ;
      { "GEODATA", "AcDbGeoData", 1025, "ObjectDBX Classes", .F. }, ;
      { "PDFDEFINITION", "AcDbPdfDefinition", 1, "ObjectDBX Classes", .F. }, ;
      { "DWFDEFINITION", "AcDbDwfDefinition", 1, "ObjectDBX Classes", .F. }, ;
      { "DGNDEFINITION", "AcDbDgnDefinition", 1, "ObjectDBX Classes", .F. }, ;
      { "SPATIAL_FILTER", "AcDbSpatialFilter", 1, "ObjectDBX Classes", .F. }, ;
      { "PLOTSETTINGS", "AcDbPlotSettings", 0, "ObjectDBX Classes", .F. }, ;
      { "GROUP", "AcDbGroup", 0, "ObjectDBX Classes", .F. }, ;
      { "MLINESTYLE", "AcDbMlineStyle", 0, "ObjectDBX Classes", .F. } }
   LOCAL aOut := {}, d, cl
   FOR EACH d IN aDefs
      cl := iif( d[ 5 ], Dcl_NewEntity( d[ 1 ], d[ 2 ] ), Dcl_New( d[ 1 ], d[ 2 ] ) )
      cl[ "proxy_flags" ] := d[ 3 ] ; cl[ "application_name" ] := d[ 4 ]
      DO CASE
      CASE d[ 1 ] == "ACDBASSOCNETWORK" .OR. d[ 1 ] == "ACDBASSOC2DCONSTRAINTGROUP" .OR. d[ 1 ] == "ACDBASSOCVARIABLE"
         cl[ "dwg_version" ] := 27 ; cl[ "maintenance_version" ] := 45
      CASE d[ 1 ] == "ACDBASSOCVALUEDEPENDENCY" .OR. d[ 1 ] == "ACDBASSOCGEOMDEPENDENCY"
         cl[ "dwg_version" ] := 27 ; cl[ "maintenance_version" ] := 29
      ENDCASE
      AAdd( aOut, cl )
   NEXT
RETURN aOut
