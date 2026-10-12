/* Port 1:1 de tests de opencadcodec types/transparency.rs (2, sin el de serde) y line_weight.rs (8) */
#include "ocx.ch"
PROCEDURE T_CodecTypes2()
   LOCAL t, v, lOk, a
   t := Tp_New( 128 )
   Chk( Tp_ExplicitAlpha( t ) == 128 .AND. Tp_Alpha( Tp_FromPercent( 0.13 ) ) == 34 .AND. Tp_Alpha( Tp_FromPercent( 0.30 ) ) == 77 .AND. Tp_Alpha( Tp_FromPercent( 0.33 ) ) == 85 .AND. Tp_Alpha( Tp_FromPercent( 0.5 ) ) == 128 .AND. Tp_IsOpaque( Tp_Opaque() ) .AND. Tp_IsTransparent( Tp_Transparent() ), "transparency: explicit_amounts" )
   lOk := .T.
   FOR EACH v IN { Tp_ByLayer(), Tp_ByBlock(), Tp_Opaque(), Tp_New( 217 ), Tp_Transparent() }
      IF ! Tp_Eq( Tp_FromAlphaValue( Tp_ToDxfValue( v ) ), v ) .OR. ! Tp_Eq( Tp_FromAlphaValue( Tp_ToAlphaValue( v ) ), v ) ; lOk := .F. ; ENDIF
   NEXT
   Chk( lOk, "transparency: packed_methods_roundtrip" )
   // [extra]
   Chk( Tp_Display( Tp_New( 128 ) ) == "50.2%" .AND. Tp_Display( Tp_ByBlock() ) == "ByBlock" .AND. Tp_Cmp( Tp_ByLayer(), Tp_ByBlock() ) < 0 .AND. Tp_Cmp( Tp_ByBlock(), Tp_New( 0 ) ) < 0 .AND. Tp_Alpha( Tp_T( 50 ) ) == 128, "[extra] transparency: display, orden, T_50" )
   // line weight
   Chk( Lw_Eq( Lw_FromValue( -1 ), Lw_ByLayer() ) .AND. Lw_Eq( Lw_FromValue( -2 ), Lw_ByBlock() ) .AND. Lw_Eq( Lw_FromValue( -3 ), Lw_Default() ) .AND. Lw_Eq( Lw_FromValue( 25 ), Lw_Value( 25 ) ), "line_weight: test_line_weight_from_value" )
   Chk( Lw_GetValue( Lw_ByLayer() ) == -1 .AND. Lw_GetValue( Lw_Value( 50 ) ) == 50, "line_weight: test_line_weight_value" )
   Chk( Lw_Millimeters( Lw_Value( 25 ) ) == 0.25 .AND. Lw_Millimeters( Lw_Value( 100 ) ) == 1.0 .AND. Lw_Millimeters( Lw_ByLayer() ) == NIL, "line_weight: test_line_weight_millimeters" )
   Chk( Lw_Millimeters( Lw_Value( 25 ) ) == 0.25 .AND. Lw_Millimeters( Lw_Value( 100 ) ) == 1.0, "line_weight: test_line_weight_constants" )
   Chk( Lw_Display( Lw_ByLayer() ) == "ByLayer" .AND. Lw_Display( Lw_Value( 25 ) ) == "0.25mm", "line_weight: test_line_weight_display" )
   a := Lw_ByLayer()
   Chk( Lw_Eq( a, Lw_ByLayer() ), "line_weight: test_default_line_weight" )
   Chk( Lw_ToDwgIndex( Lw_Default() ) == 31 .AND. Lw_ToDwgIndex( Lw_ByBlock() ) == 30 .AND. Lw_ToDwgIndex( Lw_ByLayer() ) == 29 .AND. Lw_Eq( Lw_FromDwgIndex( 31 ), Lw_Default() ) .AND. Lw_Eq( Lw_FromDwgIndex( 30 ), Lw_ByBlock() ) .AND. Lw_Eq( Lw_FromDwgIndex( 29 ), Lw_ByLayer() ) .AND. Lw_Eq( Lw_FromDwgIndex( 28 ), Lw_ByLayer() ), "line_weight: test_dwg_index_roundtrip_special" )
   Chk( Lw_ToDwgIndex( Lw_Value( 0 ) ) == 0 .AND. Lw_ToDwgIndex( Lw_Value( 25 ) ) == 7 .AND. Lw_ToDwgIndex( Lw_Value( 211 ) ) == 23 .AND. Lw_Eq( Lw_FromDwgIndex( 0 ), Lw_Value( 0 ) ) .AND. Lw_Eq( Lw_FromDwgIndex( 7 ), Lw_Value( 25 ) ) .AND. Lw_Eq( Lw_FromDwgIndex( 23 ), Lw_Value( 211 ) ), "line_weight: test_dwg_index_roundtrip_standard" )
   Chk( Lw_ToDwgIndex( Lw_Value( 999 ) ) == 31 .AND. Lw_Eq( Lw_FromDwgIndex( 24 ), Lw_Default() ), "[extra] line_weight: valor desconocido -> Default" )
RETURN
