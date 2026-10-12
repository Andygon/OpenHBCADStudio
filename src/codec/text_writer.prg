/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/text_writer.prg
   Origen Rust: opencadcodec/src/io/dxf/writer/text_writer.rs (388 lineas, 7 tests en t_codec_writer.prg)
   Licencia del original: MPL-2.0. Escritor DXF ASCII (CRLF). Ver stream_writer.prg para el modelo.
   Formato de doubles: Display de Rust (F64_Display) + ".0" si no hay punto; |v|>=1e15 o |v|<1e-15
   -> {:.16e} (OCX_EXP16); no finito -> "0.0".
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION TxW_New( nFH ) ; RETURN { 1, "", nFH }

STATIC FUNCTION TxW_Code( w, nCode )
   Sw_Put( w, IIf( nCode < 100, PadL( hb_ntos( nCode ), 3 ), hb_ntos( nCode ) ) + Chr( 13 ) + Chr( 10 ) ) /* {:>3}: sin truncar (codigos 1000+) */
RETURN NIL
STATIC FUNCTION TxW_Line( w, c )
   Sw_Put( w, c + Chr( 13 ) + Chr( 10 ) )
RETURN NIL

STATIC FUNCTION TxW_Sanitize( c )
   IF e"\n" $ c .OR. Chr( 13 ) $ c
      c := StrTran( c, Chr( 13 ) + e"\n", "\P" ) ; c := StrTran( c, Chr( 13 ), "\P" ) ; c := StrTran( c, e"\n", "\P" )
   ENDIF
RETURN c

STATIC FUNCTION TxW_EscapeCaret( c )
   LOCAL cOut := "", i, n := hb_BLen( c ), ch
   FOR i := 1 TO n
      ch := hb_BSubStr( c, i, 1 ) ; cOut += ch
      IF ch == "^" .AND. ! ( i < n .AND. hb_BSubStr( c, i + 1, 1 ) == " " ) ; cOut += " " ; ENDIF
   NEXT
RETURN cOut

FUNCTION TxW_String( w, nCode, c )
   TxW_Code( w, nCode )
   IF "^" $ c ; c := TxW_EscapeCaret( c ) ; ENDIF
   TxW_Line( w, TxW_Sanitize( c ) )
RETURN NIL

FUNCTION TxW_XRecordString( w, nCode, c )
   TxW_Code( w, nCode )
   c := StrTran( c, "^", "^ " ) ; c := StrTran( c, Chr( 13 ) + e"\n", "^M^J" ) ; c := StrTran( c, Chr( 13 ), "^M" )
   c := StrTran( c, e"\n", "^J" ) ; c := StrTran( c, Chr( 9 ), "^I" )
   TxW_Line( w, c )
RETURN NIL

FUNCTION TxW_Byte( w, nCode, n ) ; TxW_Code( w, nCode ) ; TxW_Line( w, hb_ntos( n ) ) ; RETURN NIL
FUNCTION TxW_I16( w, nCode, n ) ; TxW_Code( w, nCode ) ; TxW_Line( w, TxW_Pad6( n ) ) ; RETURN NIL
FUNCTION TxW_I32( w, nCode, n ) ; TxW_Code( w, nCode ) ; TxW_Line( w, TxW_Pad6( n ) ) ; RETURN NIL
FUNCTION TxW_I64( w, nCode, n ) ; TxW_Code( w, nCode ) ; TxW_Line( w, hb_ntos( n ) ) ; RETURN NIL
FUNCTION TxW_Bool( w, nCode, l ) ; TxW_Code( w, nCode ) ; TxW_Line( w, IIf( l, "     1", "     0" ) ) ; RETURN NIL

FUNCTION TxW_FormatDouble( v )
   LOCAL a, s
   IF ! OCX_ISFINITE( v ) ; RETURN "0.0" ; ENDIF
   a := Abs( v )
   IF a > 0 .AND. a < 1.0 / OCX_POW( 10.0, 15 ) ; RETURN OCX_EXP16( v ) ; ENDIF
   IF a >= OCX_POW( 10.0, 15 ) .AND. a != 0 ; RETURN OCX_EXP16( v ) ; ENDIF
   s := F64_Display( v )
   IF ! ( "." $ s ) ; s += ".0" ; ENDIF
RETURN s

FUNCTION TxW_Double( w, nCode, v ) ; TxW_Code( w, nCode ) ; TxW_Line( w, TxW_FormatDouble( v ) ) ; RETURN NIL

FUNCTION TxW_Handle( w, nCode, h )
   TxW_Code( w, nCode )
   TxW_Line( w, IIf( Hd_Value( h ) == 0, "0", Hd_UpperHex( h ) ) )
RETURN NIL

FUNCTION TxW_Binary( w, nCode, cData )
   LOCAL i, cHex := ""
   TxW_Code( w, nCode )
   FOR i := 1 TO hb_BLen( cData )
      cHex += hb_NumToHex( hb_BCode( hb_BSubStr( cData, i, 1 ) ), 2 )
   NEXT
   TxW_Line( w, cHex )
RETURN NIL

/* {:>6} de Rust: rellena a la izquierda sin truncar (PadL de Harbour trunca) */
STATIC FUNCTION TxW_Pad6( n )
   LOCAL c := hb_ntos( n )
RETURN IIf( Len( c ) >= 6, c, PadL( c, 6 ) )
