/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/dxf_version.prg
   Origen Rust: opencadcodec/src/types/mod.rs (enum DxfVersion; 3 tests en t_codec_dxf.prg)
   DxfVersion = numero (version_code: 0 = Unknown, 1009 ... 1032). El orden derivado de Rust
   (Unknown < AC1009 < ... < AC1032) coincide con la comparacion numerica.
----------------------------------------------------------------------------*/
#include "ocx.ch"

STATIC FUNCTION Dxv_Codes() ; RETURN { 1009, 1012, 1014, 1015, 1018, 1021, 1024, 1027, 1032 }

FUNCTION Dxv_Unknown() ; RETURN 0
FUNCTION Dxv_AsStr( v ) ; RETURN IIf( v == 0, "UNKNOWN", "AC" + hb_ntos( v ) )
FUNCTION Dxv_ToDxfString( v ) ; RETURN Dxv_AsStr( v )
FUNCTION Dxv_Parse( c )
   LOCAL n
   IF Len( c ) == 6 .AND. ( Left( c, 2 ) == "AC" .OR. Left( c, 2 ) == "AD" )
      n := AScan( Dxv_Codes(), {| x | hb_ntos( x ) == Right( c, 4 ) } )
      IF n > 0 ; RETURN Dxv_Codes()[ n ] ; ENDIF
   ENDIF
RETURN NIL
FUNCTION Dxv_FromVersionString( c )
   LOCAL v := Dxv_Parse( c )
RETURN IIf( v == NIL, 0, v )
FUNCTION Dxv_VersionCode( v ) ; RETURN v
FUNCTION Dxv_FromVersionCode( n ) ; RETURN IIf( AScan( Dxv_Codes(), {| x | x == n } ) > 0, n, 0 )
