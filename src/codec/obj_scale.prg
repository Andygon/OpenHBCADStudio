/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/obj_scale.prg
   Origen Rust: opencadcodec/src/objects/scale.rs (535 lineas, 23 tests). Licencia del original: MPL-2.0.
   Prefijo: Scl_ . Los 29 presets (scale_1_1 ... scale_6in_1ft) estan generados mecanicamente del Rust; Scl_Scale_1_1 corresponde a scale_1_1.
   Option/Vec: standard_*_scales devuelve un array de hashes.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Scl_ObjectName() ; RETURN "SCALE"
FUNCTION Scl_SubclassMarker() ; RETURN "AcDbScale"

FUNCTION Scl_New( cName, nPaper, nDrawing )
RETURN hb_Hash( "_type", "Scale", "handle", Hd_Null(), "owner_handle", Hd_Null(), "name", cName, "paper_units", nPaper, "drawing_units", nDrawing, ;
   "is_unit_scale", Abs( nPaper - nDrawing ) < 0.0000000001, "is_temporary", .F. )
FUNCTION Scl_UnitScale() ; RETURN hb_Hash( "_type", "Scale", "handle", Hd_Null(), "owner_handle", Hd_Null(), "name", "1:1", "paper_units", 1.0, "drawing_units", 1.0, "is_unit_scale", .T., "is_temporary", .F. )
FUNCTION Scl_Default() ; RETURN Scl_UnitScale()
FUNCTION Scl_FromRatio( cName, nPaper, nDrawing ) ; RETURN Scl_New( cName, nPaper + 0.0, nDrawing + 0.0 )
FUNCTION Scl_Factor( s ) ; RETURN iif( Abs( s[ "drawing_units" ] ) < 0.0000000001, 1.0, s[ "paper_units" ] / s[ "drawing_units" ] )
FUNCTION Scl_InverseFactor( s ) ; RETURN iif( Abs( s[ "paper_units" ] ) < 0.0000000001, 1.0, s[ "drawing_units" ] / s[ "paper_units" ] )
FUNCTION Scl_IsReduction( s ) ; RETURN Scl_Factor( s ) < 1.0 - 0.0000000001
FUNCTION Scl_IsEnlargement( s ) ; RETURN Scl_Factor( s ) > 1.0 + 0.0000000001
FUNCTION Scl_RatioString( s )
   IF s[ "paper_units" ] >= s[ "drawing_units" ]
      RETURN hb_ntos( Round( s[ "paper_units" ] / s[ "drawing_units" ], 0 ) ) + ":1"
   ENDIF
RETURN "1:" + hb_ntos( Round( s[ "drawing_units" ] / s[ "paper_units" ], 0 ) )

FUNCTION Scl_Scale_1_1() ; RETURN Scl_New( "1:1", 1.0, 1.0 )
FUNCTION Scl_Scale_1_2() ; RETURN Scl_New( "1:2", 1.0, 2.0 )
FUNCTION Scl_Scale_1_4() ; RETURN Scl_New( "1:4", 1.0, 4.0 )
FUNCTION Scl_Scale_1_5() ; RETURN Scl_New( "1:5", 1.0, 5.0 )
FUNCTION Scl_Scale_1_8() ; RETURN Scl_New( "1:8", 1.0, 8.0 )
FUNCTION Scl_Scale_1_10() ; RETURN Scl_New( "1:10", 1.0, 10.0 )
FUNCTION Scl_Scale_1_16() ; RETURN Scl_New( "1:16", 1.0, 16.0 )
FUNCTION Scl_Scale_1_20() ; RETURN Scl_New( "1:20", 1.0, 20.0 )
FUNCTION Scl_Scale_1_30() ; RETURN Scl_New( "1:30", 1.0, 30.0 )
FUNCTION Scl_Scale_1_40() ; RETURN Scl_New( "1:40", 1.0, 40.0 )
FUNCTION Scl_Scale_1_50() ; RETURN Scl_New( "1:50", 1.0, 50.0 )
FUNCTION Scl_Scale_1_100() ; RETURN Scl_New( "1:100", 1.0, 100.0 )
FUNCTION Scl_Scale_1_128() ; RETURN Scl_New( "1:128", 1.0, 128.0 )
FUNCTION Scl_Scale_2_1() ; RETURN Scl_New( "2:1", 2.0, 1.0 )
FUNCTION Scl_Scale_4_1() ; RETURN Scl_New( "4:1", 4.0, 1.0 )
FUNCTION Scl_Scale_8_1() ; RETURN Scl_New( "8:1", 8.0, 1.0 )
FUNCTION Scl_Scale_10_1() ; RETURN Scl_New( "10:1", 10.0, 1.0 )
FUNCTION Scl_Scale_100_1() ; RETURN Scl_New( "100:1", 100.0, 1.0 )
FUNCTION Scl_Scale_1in_1ft() ; RETURN Scl_New( [1" = 1'], 1.0, 12.0 )
FUNCTION Scl_Scale_Half_In_1ft() ; RETURN Scl_New( [1/2" = 1'], 0.5, 12.0 )
FUNCTION Scl_Scale_Quarter_In_1ft() ; RETURN Scl_New( [1/4" = 1'], 0.25, 12.0 )
FUNCTION Scl_Scale_Eighth_In_1ft() ; RETURN Scl_New( [1/8" = 1'], 0.125, 12.0 )
FUNCTION Scl_Scale_3_4in_1ft() ; RETURN Scl_New( [3/4" = 1'], 0.75, 12.0 )
FUNCTION Scl_Scale_3_8in_1ft() ; RETURN Scl_New( [3/8" = 1'], 0.375, 12.0 )
FUNCTION Scl_Scale_3_16in_1ft() ; RETURN Scl_New( [3/16" = 1'], 0.1875, 12.0 )
FUNCTION Scl_Scale_3_32in_1ft() ; RETURN Scl_New( [3/32" = 1'], 0.09375, 12.0 )
FUNCTION Scl_Scale_1_5in_1ft() ; RETURN Scl_New( [1 1/2" = 1'], 1.5, 12.0 )
FUNCTION Scl_Scale_3in_1ft() ; RETURN Scl_New( [3" = 1'], 3.0, 12.0 )
FUNCTION Scl_Scale_6in_1ft() ; RETURN Scl_New( [6" = 1'], 6.0, 12.0 )

FUNCTION Scl_StandardMetricScales()
RETURN { ;
      Scl_Scale_1_1(), ;
      Scl_Scale_1_2(), ;
      Scl_Scale_1_4(), ;
      Scl_Scale_1_5(), ;
      Scl_Scale_1_8(), ;
      Scl_Scale_1_10(), ;
      Scl_Scale_1_16(), ;
      Scl_Scale_1_20(), ;
      Scl_Scale_1_30(), ;
      Scl_Scale_1_40(), ;
      Scl_Scale_1_50(), ;
      Scl_Scale_1_100(), ;
      Scl_Scale_1_128(), ;
      Scl_Scale_2_1(), ;
      Scl_Scale_4_1(), ;
      Scl_Scale_8_1(), ;
      Scl_Scale_10_1(), ;
      Scl_Scale_100_1() }

FUNCTION Scl_StandardImperialScales()
RETURN { ;
      Scl_Scale_1_1(), ;
      Scl_Scale_6in_1ft(), ;
      Scl_Scale_3in_1ft(), ;
      Scl_Scale_1_5in_1ft(), ;
      Scl_Scale_1in_1ft(), ;
      Scl_Scale_3_4in_1ft(), ;
      Scl_Scale_Half_In_1ft(), ;
      Scl_Scale_3_8in_1ft(), ;
      Scl_Scale_Quarter_In_1ft(), ;
      Scl_Scale_3_16in_1ft(), ;
      Scl_Scale_Eighth_In_1ft(), ;
      Scl_Scale_3_32in_1ft() }
