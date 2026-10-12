/* Tests: object_context_data.rs no tiene #[test]; estos son [extra] sobre class_name / subclass_marker */
#include "ocx.ch"
PROCEDURE T_CodecObjCtxData()
   LOCAL a, k, i, aSub, aCls, aMrk
   aSub := { "Aligned", "Angular", "Diametric", "Radial", "RadialLarge", "Ordinate" }
   aCls := { "ACDB_ALDIMOBJECTCONTEXTDATA_CLASS", "ACDB_ANGDIMOBJECTCONTEXTDATA_CLASS", "ACDB_DMDIMOBJECTCONTEXTDATA_CLASS", "ACDB_RADIMOBJECTCONTEXTDATA_CLASS", "ACDB_RADIMLGOBJECTCONTEXTDATA_CLASS", "ACDB_ORDDIMOBJECTCONTEXTDATA_CLASS" }
   aMrk := { "AcDbAlignedDimensionObjectContextData", "AcDbAngularDimensionObjectContextData", "AcDbDiametricDimensionObjectContextData", "AcDbRadialDimensionObjectContextData", "AcDbRadialDimensionLargeObjectContextData", "AcDbOrdinateDimensionObjectContextData" }
   FOR i := 1 TO 6
      k := hb_Hash( "_kind", aSub[ i ] )
      Chk( Ocd_DimSubtypeClassName( k ) == aCls[ i ] .AND. Ocd_DimSubtypeSubclassMarker( k ) == aMrk[ i ], "[extra] dim subtype " + aSub[ i ] )
   NEXT
   a := Ocd_New( hb_Hash( "_kind", "AnnotScale" ) ) ; Chk( Ocd_ClassName( a ) == "ACDB_ANNOTSCALEOBJECTCONTEXTDATA_CLASS" .AND. a[ "scale" ] == Hd_Null(), "[extra] annotscale" )
   a := Ocd_New( hb_Hash( "_kind", "Opaque" ) ) ; Chk( Ocd_ClassName( a ) == "ACDB_OBJECTCONTEXTDATA_CLASS", "[extra] opaque" )
   a := Ocd_New( hb_Hash( "_kind", "Dim", "value", hb_Hash( "subtype", hb_Hash( "_kind", "Radial" ) ) ) ) ; Chk( Ocd_ClassName( a ) == "ACDB_RADIMOBJECTCONTEXTDATA_CLASS", "[extra] dim class" )
   a := Ocd_New( hb_Hash( "_kind", "HatchView" ) ) ; Chk( Ocd_ClassName( a ) == "ACDB_HATCHVIEWCONTEXTDATA_CLASS", "[extra] hatchview" )
RETURN
