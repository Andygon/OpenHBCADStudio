/* Tests: stub_objects.rs (VisualStyle) no tiene #[test]; todos [extra] sobre core/extended/legacy/restore */
#include "ocx.ch"
PROCEDURE T_CodecObjVisualStyle()
   LOCAL s, c, e, l, x, a, ok
   s := Vsy_New() ; Chk( s[ "extended_lighting_model" ] == 2 .AND. Len( s[ "properties" ] ) == 0 .AND. s[ "description" ] == "", "[extra] new" )
   s[ "face_lighting_model" ] := 3 ; s[ "face_modifier" ] := 1 ; s[ "edge_model" ] := 2 ; s[ "edge_style" ] := 9
   c := Vsy_CoreProperties( s )
   Chk( Len( c ) == 28 .AND. c[ 1 ][ "value" ][ "value" ] == 3 .AND. c[ 4 ][ "value" ][ "value" ] == 1 .AND. c[ 8 ][ "value" ][ "value" ] == 2 .AND. c[ 9 ][ "value" ][ "value" ] == 9 ;
      .AND. c[ 5 ][ "value" ][ "value" ] == 0.6 .AND. c[ 6 ][ "value" ][ "value" ] == 30.0 .AND. c[ 7 ][ "value" ][ "_kind" ] == "Color" .AND. c[ 25 ][ "value" ][ "_kind" ] == "Bool", "[extra] core defaults" )
   e := Vsy_ExtendedProperties( s ) ; Chk( Len( e ) == 30 .AND. e[ 27 ][ "value" ][ "value" ] == "strokes_ogs.tif" .AND. e[ 24 ][ "enabled" ] == 0 .AND. e[ 25 ][ "enabled" ] == 0, "[extra] extended defaults" )
   l := Vsy_LegacyProperties( s )
   Chk( Len( l ) == 24 .AND. l[ 1 ][ "value" ][ "value" ] == 0.6 .AND. l[ 2 ][ "value" ][ "value" ] == -30.0 .AND. l[ 19 ][ "value" ][ "_kind" ] == "Short" .AND. l[ 24 ][ "value" ][ "value" ] == 0.0, "[extra] legacy desde core (signo por face_modifier)" )
   s[ "properties" ] := l
   c := Vsy_CoreProperties( s )
   Chk( Len( c ) == 28 .AND. c[ 5 ][ "value" ][ "value" ] == 0.6 .AND. c[ 6 ][ "value" ][ "value" ] == 30.0 .AND. c[ 1 ][ "value" ][ "value" ] == 3, "[extra] core desde legacy de 24" )
   Chk( Len( Vsy_LegacyProperties( s ) ) == 24, "[extra] legacy devuelve los 24" )
   x := { Xre_String( 102, "RTVSPost2010Prop0" ), Xre_Int32( 90, 1 ), Xre_String( 102, "RTVSPost2010Prop4" ), Xre_Int32( 90, 7 ), Xre_String( 102, "RTVSPost2010Op4x" ), Xre_Int16( 70, 0 ), ;
      Xre_String( 102, "RTVSPropertyOp3" ), Xre_Int16( 70, 5 ), Xre_String( 102, "RTVSPost2010PropOp29" ), Xre_Int16( 70, 0 ) }
   ok := Vsy_RestorePost2010Properties( s, x ) ; a := s[ "properties" ]
   Chk( ok .AND. Len( a ) == 58 .AND. a[ 4 ][ "enabled" ] == 5 .AND. a[ 30 ][ "enabled" ] == 0 .AND. a[ 1 ][ "value" ][ "value" ] == 1 , "[extra] restore_post_2010 actualiza" )
   s := Vsy_New() ; Chk( ! Vsy_RestorePost2010Properties( s, x ), "[extra] restore sin 24 props" )
   s := Vsy_New() ; s[ "properties" ] := Vsy_LegacyProperties( s ) ; Chk( ! Vsy_RestorePost2010Properties( s, { Xre_String( 102, "nada" ), Xre_Int16( 70, 1 ) } ) .AND. Len( s[ "properties" ] ) == 24, "[extra] restore sin coincidencias" )
   x := { Xre_String( 102, "RTVSPost2010Prop15ColorIndex" ), Xre_Int16( 70, 5 ), Xre_String( 102, "RTVSPost2010Prop15ColorRGB" ), Xre_Int32( 90, 16711935 ) }
   s := Vsy_New() ; s[ "properties" ] := Vsy_LegacyProperties( s ) ; ok := Vsy_RestorePost2010Properties( s, x )
   Chk( ok .AND. Cl_Eq( s[ "properties" ][ 16 ][ "value" ][ "value" ], Cl_FromRgb( 255, 0, 255 ) ), "[extra] colorRGB sin alfa -> true color" )
   x := { Xre_String( 102, "RTVSPost2010Prop15ColorIndex" ), Xre_Int16( 70, 5 ), Xre_String( 102, "RTVSPost2010Prop15ColorRGB" ), Xre_Int32( 90, 33488127 ) }
   s := Vsy_New() ; s[ "properties" ] := Vsy_LegacyProperties( s ) ; ok := Vsy_RestorePost2010Properties( s, x )
   Chk( ok .AND. Cl_Eq( s[ "properties" ][ 16 ][ "value" ][ "value" ], Cl_Index( 5 ) ), "[extra] colorRGB con alfa -> indice" )
   x := { Xre_String( 102, "RTVSPost2010Prop15ColorRGB" ), Xre_Int32( 90, 16711935 ) }
   s := Vsy_New() ; s[ "properties" ] := Vsy_LegacyProperties( s ) ; ok := Vsy_RestorePost2010Properties( s, x )
   Chk( ok .AND. Cl_Eq( s[ "properties" ][ 16 ][ "value" ][ "value" ], Cl_ByLayer() ), "[extra] colorRGB sin ColorIndex usa 256 -> ByLayer" )
RETURN
