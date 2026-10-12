/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/obj_ctxdata.prg
   Origen Rust: opencadcodec/src/objects/object_context_data.rs (359 lineas, sin tests en Rust). Licencia del original: MPL-2.0.
   Prefijo: Ocd_. El fichero Rust es casi todo datos (structs/enums sin constructor); en Harbour:
     ObjectContextData = hash { _type "ObjectContextData", handle, owner_handle, reactors, xdictionary_handle, class_version, is_default, scale, kind }
     kind (ObjectContextKind) = hash con "_kind" = nombre de la variante ("AnnotScale", "BlkRef", "Text", "MText", "Dim", "MLeader",
       "MTextAttribute", "Leader", "Fcf", "HatchScale", "HatchView", "Opaque") mas los campos de la variante con los nombres de Rust.
       Las variantes con payload (MText, Dim, MLeader, ...) guardan el hash del struct en "value" (campos con los nombres Rust).
     DimSubtype = hash con "_kind" = "Aligned"|"Angular"|"Diametric"|"Radial"|"RadialLarge"|"Ordinate" mas campos.
   Se portan los dos metodos con logica: DimSubtype::class_name/subclass_marker y ObjectContextData::class_name.
   Pendiente: MultiLeaderAnnotContext (entities/multileader), HatchPatternLine/BoundaryPath (entities/hatch ya portado, se referencian por hash).
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Ocd_DimSubtypeClassName( s )
   SWITCH s[ "_kind" ]
   CASE "Aligned"     ; RETURN "ACDB_ALDIMOBJECTCONTEXTDATA_CLASS"
   CASE "Angular"     ; RETURN "ACDB_ANGDIMOBJECTCONTEXTDATA_CLASS"
   CASE "Diametric"   ; RETURN "ACDB_DMDIMOBJECTCONTEXTDATA_CLASS"
   CASE "Radial"      ; RETURN "ACDB_RADIMOBJECTCONTEXTDATA_CLASS"
   CASE "RadialLarge" ; RETURN "ACDB_RADIMLGOBJECTCONTEXTDATA_CLASS"
   CASE "Ordinate"    ; RETURN "ACDB_ORDDIMOBJECTCONTEXTDATA_CLASS"
   ENDSWITCH
RETURN NIL

FUNCTION Ocd_DimSubtypeSubclassMarker( s )
   SWITCH s[ "_kind" ]
   CASE "Aligned"     ; RETURN "AcDbAlignedDimensionObjectContextData"
   CASE "Angular"     ; RETURN "AcDbAngularDimensionObjectContextData"
   CASE "Diametric"   ; RETURN "AcDbDiametricDimensionObjectContextData"
   CASE "Radial"      ; RETURN "AcDbRadialDimensionObjectContextData"
   CASE "RadialLarge" ; RETURN "AcDbRadialDimensionLargeObjectContextData"
   CASE "Ordinate"    ; RETURN "AcDbOrdinateDimensionObjectContextData"
   ENDSWITCH
RETURN NIL

FUNCTION Ocd_ClassName( o )
   LOCAL k := o[ "kind" ]
   SWITCH k[ "_kind" ]
   CASE "AnnotScale"     ; RETURN "ACDB_ANNOTSCALEOBJECTCONTEXTDATA_CLASS"
   CASE "BlkRef"         ; RETURN "ACDB_BLKREFOBJECTCONTEXTDATA_CLASS"
   CASE "Text"           ; RETURN "ACDB_TEXTOBJECTCONTEXTDATA_CLASS"
   CASE "MText"          ; RETURN "ACDB_MTEXTOBJECTCONTEXTDATA_CLASS"
   CASE "Dim"            ; RETURN Ocd_DimSubtypeClassName( k[ "value" ][ "subtype" ] )
   CASE "MLeader"        ; RETURN "ACDB_MLEADEROBJECTCONTEXTDATA_CLASS"
   CASE "MTextAttribute" ; RETURN "ACDB_MTEXTATTRIBUTEOBJECTCONTEXTDATA_CLASS"
   CASE "Leader"         ; RETURN "ACDB_LEADEROBJECTCONTEXTDATA_CLASS"
   CASE "Fcf"            ; RETURN "ACDB_FCFOBJECTCONTEXTDATA_CLASS"
   CASE "HatchScale"     ; RETURN "ACDB_HATCHSCALECONTEXTDATA_CLASS"
   CASE "HatchView"      ; RETURN "ACDB_HATCHVIEWCONTEXTDATA_CLASS"
   CASE "Opaque"         ; RETURN "ACDB_OBJECTCONTEXTDATA_CLASS"
   ENDSWITCH
RETURN NIL

FUNCTION Ocd_New( hKind )
RETURN hb_Hash( "_type", "ObjectContextData", "handle", Hd_Null(), "owner_handle", Hd_Null(), "reactors", {}, "xdictionary_handle", NIL, ;
   "class_version", 0, "is_default", .F., "scale", Hd_Null(), "kind", hKind )
