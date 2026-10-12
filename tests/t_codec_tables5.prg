/* Tests: linetype.rs (10 tests 1:1) + [extra] */
#include "ocx.ch"
PROCEDURE T_CodecTables5()
   LOCAL c, e, l
   c := Ltc_Default() ; c[ "content" ] := { 0, 42 } ; c[ "style_handle" ] := 100 ; c[ "scale" ] := 2.0 ; c[ "rotation" ] := 45.0 ; c[ "offset" ] := { 1.0, 2.0 }
   Chk( Ltc_IsShape( c ) .AND. ! Ltc_IsText( c ) .AND. ! Ltc_IsAbsoluteRotation( c ) .AND. Ltc_ShapeNumber( c ) == 42 .AND. Ltc_Text( c ) == NIL, "complex_data_shape" )
   c := Ltc_Default() ; c[ "content" ] := { 1, "X" } ; c[ "offset" ] := { 0.0, 0.5 }
   Chk( ! Ltc_IsShape( c ) .AND. Ltc_IsText( c ) .AND. Ltc_ShapeNumber( c ) == NIL .AND. Ltc_Text( c ) == "X", "complex_data_text" )
   c := Ltc_Default() ; c[ "content" ] := { 0, 1 } ; c[ "rotation" ] := 90.0 ; c[ "absolute_rotation" ] := .T.
   Chk( Ltc_IsShape( c ) .AND. Ltc_IsAbsoluteRotation( c ), "complex_data_absolute_rotation" )
   e := Lte_Dash( 1.0 ) ; Chk( ! Lte_IsComplex( e ) .AND. ! Lte_IsShape( e ) .AND. ! Lte_IsText( e ), "element_complex_methods inicio" )
   e[ "complex" ] := Ltc_Default() ; e[ "complex" ][ "content" ] := { 0, 5 } ; Chk( Lte_IsComplex( e ) .AND. Lte_IsShape( e ) .AND. ! Lte_IsText( e ), "element_complex_methods" )
   l := Lty_Continuous() ; Chk( ! Lty_IsComplex( l ), "linetype_is_complex inicio" )
   e := Lte_Dot() ; e[ "complex" ] := Ltc_Default() ; e[ "complex" ][ "content" ] := { 1, "A" } ; AAdd( l[ "elements" ], e ) ; Chk( Lty_IsComplex( l ), "linetype_is_complex" )
   c := Ltc_Default() ; Chk( Ltc_IsShape( c ) .AND. Ltc_ShapeNumber( c ) == 0 .AND. Hd_IsNull( c[ "style_handle" ] ) .AND. ! Ltc_IsText( c ) .AND. ! Ltc_IsAbsoluteRotation( c ), "complex_default" )
   c := Ltc_Default() ; Ltc_ApplyDxfFlags( c, 4 ) ; Chk( Ltc_IsShape( c ) .AND. ! Ltc_IsText( c ), "dxf_flag_helpers shape" )
   Ltc_ApplyDxfFlags( c, hb_bitOr( 2, 1 ) ) ; Chk( Ltc_IsText( c ) .AND. Ltc_IsAbsoluteRotation( c ), "dxf_flag_helpers text" )
   c := Ltc_Default() ; c[ "content" ] := { 1, "hi" } ; Ltc_EnsureShape( c ) ; Chk( Ltc_IsShape( c ), "ensure_shape_switches_content" )
   c := Ltc_Default() ; Ltc_EnsureText( c ) ; Chk( Ltc_IsText( c ) .AND. Ltc_Text( c ) == "", "ensure_text_switches_content" )
   Chk( ! Lte_IsComplex( Lte_Dash( 1.0 ) ) .AND. ! Lte_IsComplex( Lte_Space( 0.5 ) ) .AND. ! Lte_IsComplex( Lte_Dot() ), "element_constructors_no_complex" )
   Chk( Lte_IsDash( Lte_Dash( -2.0 ) ) .AND. Lte_IsSpace( Lte_Space( 2.0 ) ) .AND. Lte_IsDot( Lte_Dot() ) .AND. Lte_Space( 2.0 )[ "length" ] == -2.0, "[extra] element: dash/space usan abs" )
   l := Lty_Dashed() ; Chk( Lty_ElementCount( l ) == 2 .AND. l[ "pattern_length" ] == 0.75 .AND. ! Lty_IsContinuous( l ) .AND. ! Lty_IsStandard( l ), "[extra] linetype: dashed" )
   l := Lty_Dotted() ; Chk( Lte_IsDot( l[ "elements" ][ 1 ] ) .AND. l[ "pattern_length" ] == 0.25, "[extra] linetype: dotted" )
   Chk( Lty_IsStandard( Lty_Continuous() ) .AND. Lty_IsStandard( Lty_ByLayer() ) .AND. Lty_IsStandard( Lty_ByBlock() ) .AND. Lty_Continuous()[ "alignment" ] == "A" .AND. Lty_Continuous()[ "description" ] == "Solid line", "[extra] linetype: estandar" )
   c := Ltc_Default() ; Ltc_SetText( c, "T" ) ; Chk( Ltc_Text( c ) == "T", "[extra] set_text" ) ; Ltc_SetShapeNumber( c, 7 ) ; Chk( Ltc_ShapeNumber( c ) == 7, "[extra] set_shape_number" )
   e := Lte_Dash( 1.0 ) ; Lte_ComplexMut( e )[ "scale" ] := 3.0 ; Chk( e[ "complex" ][ "scale" ] == 3.0 .AND. Ltc_IsShape( e[ "complex" ] ), "[extra] complex_mut crea por defecto" )
RETURN
