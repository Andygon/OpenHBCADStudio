/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/obj_dictvar.prg
   Origen Rust: opencadcodec/src/objects/dictionary_variable.rs (345 lineas, 20 tests). Licencia del original: MPL-2.0.
   Prefijo: Dvr_ . as_i64 / as_f64 reutilizan Dp_ParseI64 / Dp_ParseF64 (str::parse, ya portados en stream_reader.prg). Option -> NIL.
   f64::to_string (formato Display de Rust, forma mas corta que ida y vuelta, sin notacion exponencial) se aproxima con Dvr_F64ToString:
   se prueba de 0 a 17 decimales hasta que Val(texto) == valor; vale para los rangos usados (escalas, indices). Divergencia documentada para magnitudes >= 1e21.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Dvr_ObjectName() ; RETURN "DICTIONARYVAR"
FUNCTION Dvr_SubclassMarker() ; RETURN "DictionaryVariables"

FUNCTION Dvr_New( cName, cValue )
RETURN hb_Hash( "_type", "DictionaryVariable", "handle", Hd_Null(), "owner_handle", Hd_Null(), "schema_number", 0, "value", cValue, "name", cName )
FUNCTION Dvr_WithValue( cValue ) ; RETURN Dvr_New( "", cValue )
FUNCTION Dvr_Default() ; RETURN Dvr_WithValue( "" )
PROCEDURE Dvr_SetValue( v, c ) ; v[ "value" ] := c ; RETURN
FUNCTION Dvr_IsEmpty( v ) ; RETURN Len( v[ "value" ] ) == 0
FUNCTION Dvr_AsI64( v ) ; RETURN Dp_ParseI64( v[ "value" ] )
FUNCTION Dvr_AsF64( v ) ; RETURN Dp_ParseF64( v[ "value" ] )
FUNCTION Dvr_AsBool( v )
   LOCAL c := Lower( v[ "value" ] )
   IF c == "1" .OR. c == "true" .OR. c == "yes" ; RETURN .T. ; ENDIF
   IF c == "0" .OR. c == "false" .OR. c == "no" ; RETURN .F. ; ENDIF
RETURN NIL

FUNCTION Dvr_F64ToString( n )
   LOCAL d, c
   IF n == Int( n ) .AND. Abs( n ) < 1000000000000000000000.0
      c := AllTrim( Str( n, 30, 0 ) )
      RETURN iif( c == "-0", "-0", c )
   ENDIF
   FOR d := 1 TO 17
      c := AllTrim( Str( n, 40, d ) )
      IF Val( c ) == n ; RETURN c ; ENDIF
   NEXT
RETURN AllTrim( Str( n, 40, 17 ) )

FUNCTION Dvr_FromI64( cName, n ) ; RETURN Dvr_New( cName, AllTrim( Str( n, 30, 0 ) ) )
FUNCTION Dvr_FromF64( cName, n ) ; RETURN Dvr_New( cName, Dvr_F64ToString( n ) )
FUNCTION Dvr_FromBool( cName, l ) ; RETURN Dvr_New( cName, iif( l, "1", "0" ) )
FUNCTION Dvr_Ctab( c ) ; RETURN Dvr_New( "CTAB", c )
FUNCTION Dvr_Clayer( c ) ; RETURN Dvr_New( "CLAYER", c )
FUNCTION Dvr_Dimstyle( c ) ; RETURN Dvr_New( "DIMSTYLE", c )
FUNCTION Dvr_Textstyle( c ) ; RETURN Dvr_New( "TEXTSTYLE", c )
FUNCTION Dvr_Celtscale( n ) ; RETURN Dvr_FromF64( "CELTSCALE", n )
FUNCTION Dvr_Cecolor( n ) ; RETURN Dvr_FromI64( "CECOLOR", n )
