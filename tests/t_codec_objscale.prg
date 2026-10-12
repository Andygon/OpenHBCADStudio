/* Tests: scale.rs (23 tests 1:1) */
#include "ocx.ch"
STATIC FUNCTION Ap( a, b ) ; RETURN Abs( a - b ) < 0.0000000001
STATIC FUNCTION HasName( a, c )
   LOCAL s
   FOR EACH s IN a
      IF s[ "name" ] == c ; RETURN .T. ; ENDIF
   NEXT
RETURN .F.
PROCEDURE T_CodecObjScale()
   LOCAL s, c, a
   s := Scl_New( "1:50", 1.0, 50.0 ) ; Chk( s[ "name" ] == "1:50" .AND. s[ "paper_units" ] == 1.0 .AND. s[ "drawing_units" ] == 50.0 .AND. ! s[ "is_unit_scale" ], "scale_creation" )
   s := Scl_UnitScale() ; Chk( s[ "name" ] == "1:1" .AND. s[ "is_unit_scale" ] .AND. Ap( Scl_Factor( s ), 1.0 ), "unit_scale" )
   s := Scl_FromRatio( "1:25", 1, 25 ) ; Chk( s[ "paper_units" ] == 1.0 .AND. s[ "drawing_units" ] == 25.0, "from_ratio" )
   Chk( Ap( Scl_Factor( Scl_New( "1:50", 1.0, 50.0 ) ), 0.02 ) .AND. Ap( Scl_Factor( Scl_New( "2:1", 2.0, 1.0 ) ), 2.0 ) .AND. Ap( Scl_Factor( Scl_UnitScale() ), 1.0 ), "factor" )
   Chk( Ap( Scl_InverseFactor( Scl_New( "1:50", 1.0, 50.0 ) ), 50.0 ) .AND. Ap( Scl_InverseFactor( Scl_New( "2:1", 2.0, 1.0 ) ), 0.5 ), "inverse_factor" )
   s := Scl_New( "1:50", 1.0, 50.0 ) ; Chk( Scl_IsReduction( s ) .AND. ! Scl_IsEnlargement( s ), "is_reduction" )
   s := Scl_New( "5:1", 5.0, 1.0 ) ; Chk( Scl_IsEnlargement( s ) .AND. ! Scl_IsReduction( s ), "is_enlargement" )
   s := Scl_UnitScale() ; Chk( ! Scl_IsReduction( s ) .AND. ! Scl_IsEnlargement( s ), "unit_is_neither" )
   Chk( Scl_RatioString( Scl_New( "1:50", 1.0, 50.0 ) ) == "1:50" .AND. Scl_RatioString( Scl_New( "2:1", 2.0, 1.0 ) ) == "2:1" .AND. Scl_RatioString( Scl_UnitScale() ) == "1:1", "ratio_string" )
   Chk( Ap( Scl_Factor( Scl_New( "Invalid", 1.0, 0.0 ) ), 1.0 ), "zero_drawing_units_factor" )
   Chk( Ap( Scl_InverseFactor( Scl_New( "Invalid", 0.0, 1.0 ) ), 1.0 ), "zero_paper_units_inverse" )
   a := Scl_StandardMetricScales() ; Chk( Len( a ) >= 15 .AND. HasName( a, "1:1" ) .AND. HasName( a, "1:50" ), "standard_metric_scales" )
   a := Scl_StandardImperialScales() ; Chk( Len( a ) >= 10 .AND. HasName( a, [1/4" = 1'] ), "standard_imperial_scales" )
   s := Scl_Scale_1_1() ; Chk( s[ "is_unit_scale" ] .OR. Ap( Scl_Factor( s ), 1.0 ), "scale_1_1" )
   Chk( Ap( Scl_Factor( Scl_Scale_1_50() ), 0.02 ), "scale_1_50" )
   Chk( Ap( Scl_Factor( Scl_Scale_1_100() ), 0.01 ), "scale_1_100" )
   Chk( Ap( Scl_Factor( Scl_Scale_2_1() ), 2.0 ), "scale_2_1" )
   Chk( Ap( Scl_Factor( Scl_Scale_1in_1ft() ), 1.0 / 12.0 ), "imperial_scale_1in_1ft" )
   Chk( Ap( Scl_Factor( Scl_Scale_Quarter_In_1ft() ), 0.25 / 12.0 ), "imperial_scale_quarter_in" )
   s := Scl_Default() ; Chk( s[ "name" ] == "1:1" .AND. s[ "is_unit_scale" ], "default" )
   s := Scl_New( "Temp", 1.0, 5.0 ) ; Chk( ! s[ "is_temporary" ], "temporary_flag inicio" ) ; s[ "is_temporary" ] := .T. ; Chk( s[ "is_temporary" ], "temporary_flag" )
   s := Scl_New( "1:25", 1.0, 25.0 ) ; c := hb_HClone( s ) ; Chk( s[ "name" ] == c[ "name" ] .AND. s[ "paper_units" ] == c[ "paper_units" ] .AND. s[ "drawing_units" ] == c[ "drawing_units" ], "clone" )
   Chk( Scl_ObjectName() == "SCALE" .AND. Scl_SubclassMarker() == "AcDbScale", "[extra] constantes" )
RETURN
