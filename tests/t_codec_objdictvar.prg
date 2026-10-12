/* Tests: dictionary_variable.rs (20 tests 1:1) + [extra] */
#include "ocx.ch"
PROCEDURE T_CodecObjDictVar()
   LOCAL v, c, r
   v := Dvr_New( "CTAB", "Model" ) ; Chk( v[ "name" ] == "CTAB" .AND. v[ "value" ] == "Model", "dictionaryvariable_creation" )
   v := Dvr_WithValue( "test_value" ) ; Chk( Len( v[ "name" ] ) == 0 .AND. v[ "value" ] == "test_value", "with_value" )
   v := Dvr_New( "VAR", "old" ) ; Dvr_SetValue( v, "new" ) ; Chk( v[ "value" ] == "new", "set_value" )
   Chk( Dvr_IsEmpty( Dvr_WithValue( "" ) ) .AND. ! Dvr_IsEmpty( Dvr_WithValue( "value" ) ), "is_empty" )
   Chk( Dvr_AsI64( Dvr_WithValue( "42" ) ) == 42 .AND. Dvr_AsI64( Dvr_WithValue( "not_a_number" ) ) == NIL, "as_i64" )
   r := Dvr_AsF64( Dvr_WithValue( "3.14159" ) ) ; Chk( r != NIL .AND. Abs( r - 3.14159 ) < 0.00001 .AND. Dvr_AsF64( Dvr_WithValue( "not_a_number" ) ) == NIL, "as_f64" )
   Chk( Dvr_AsBool( Dvr_WithValue( "1" ) ) == .T. .AND. Dvr_AsBool( Dvr_WithValue( "true" ) ) == .T. .AND. Dvr_AsBool( Dvr_WithValue( "YES" ) ) == .T. ;
      .AND. Dvr_AsBool( Dvr_WithValue( "0" ) ) == .F. .AND. Dvr_AsBool( Dvr_WithValue( "false" ) ) == .F. .AND. Dvr_AsBool( Dvr_WithValue( "No" ) ) == .F. .AND. Dvr_AsBool( Dvr_WithValue( "maybe" ) ) == NIL, "as_bool" )
   v := Dvr_FromI64( "COUNT", 100 ) ; Chk( v[ "name" ] == "COUNT" .AND. v[ "value" ] == "100" .AND. Dvr_AsI64( v ) == 100, "from_i64" )
   v := Dvr_FromF64( "SCALE", 2.5 ) ; Chk( v[ "name" ] == "SCALE" .AND. Dvr_AsF64( v ) == 2.5, "from_f64" )
   Chk( Dvr_FromBool( "ENABLED", .T. )[ "value" ] == "1" .AND. Dvr_FromBool( "DISABLED", .F. )[ "value" ] == "0", "from_bool" )
   v := Dvr_Ctab( "Layout1" ) ; Chk( v[ "name" ] == "CTAB" .AND. v[ "value" ] == "Layout1", "ctab" )
   v := Dvr_Clayer( "MyLayer" ) ; Chk( v[ "name" ] == "CLAYER" .AND. v[ "value" ] == "MyLayer", "clayer" )
   v := Dvr_Dimstyle( "Standard" ) ; Chk( v[ "name" ] == "DIMSTYLE" .AND. v[ "value" ] == "Standard", "dimstyle" )
   v := Dvr_Textstyle( "Arial" ) ; Chk( v[ "name" ] == "TEXTSTYLE" .AND. v[ "value" ] == "Arial", "textstyle" )
   v := Dvr_Celtscale( 1.5 ) ; Chk( v[ "name" ] == "CELTSCALE" .AND. Dvr_AsF64( v ) == 1.5, "celtscale" )
   v := Dvr_Cecolor( 256 ) ; Chk( v[ "name" ] == "CECOLOR" .AND. Dvr_AsI64( v ) == 256, "cecolor" )
   v := Dvr_Default() ; Chk( Dvr_IsEmpty( v ) .AND. Len( v[ "name" ] ) == 0, "default" )
   v := Dvr_New( "VAR", "value" ) ; Chk( v[ "schema_number" ] == 0, "schema_number inicio" ) ; v[ "schema_number" ] := 1 ; Chk( v[ "schema_number" ] == 1, "schema_number" )
   v := Dvr_New( "CTAB", "Model" ) ; c := hb_HClone( v ) ; Chk( c[ "name" ] == v[ "name" ] .AND. c[ "value" ] == v[ "value" ], "clone" )
   Chk( Dvr_ObjectName() == "DICTIONARYVAR" .AND. Dvr_SubclassMarker() == "DictionaryVariables", "constants" )
   Chk( Dvr_F64ToString( 100.0 ) == "100" .AND. Dvr_F64ToString( 0.1 ) == "0.1" .AND. Dvr_F64ToString( -2.25 ) == "-2.25" .AND. Dvr_F64ToString( 1.0 / 3.0 ) == "0.3333333333333333", "[extra] f64 to_string forma mas corta" )
RETURN
