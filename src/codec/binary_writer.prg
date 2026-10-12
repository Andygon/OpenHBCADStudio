/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/binary_writer.prg
   Origen Rust: opencadcodec/src/io/dxf/writer/binary_writer.rs (300 lineas, 5 tests en t_codec_writer.prg)
   Licencia del original: MPL-2.0. Escritor DXF binario. Ver stream_writer.prg para el modelo.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION BnW_New( nFH )
   LOCAL w := { 2, "", nFH }
   Sw_Put( w, "AutoCAD Binary DXF" + Chr( 13 ) + Chr( 10 ) + Chr( 26 ) + Chr( 0 ) )
RETURN w

STATIC FUNCTION BnW_Code( w, nCode ) ; Sw_Put( w, I2Bin( nCode ) ) ; RETURN NIL   // code as i16
STATIC FUNCTION BnW_NullString( w, c ) ; Sw_Put( w, c + Chr( 0 ) ) ; RETURN NIL

STATIC FUNCTION BnW_Invalid( nCode ) ; RETURN "Parse error: Invalid text value for binary DXF group " + hb_ntos( nCode )

/* NIL = escrito; .F. = se queda con el formato de cadena nula; cadena = error */
STATIC FUNCTION BnW_TypedText( w, nCode, cValue )
   LOCAL cText := AllTrim( cValue ), nVt := Gv_FromRawCode( nCode ), n, i, cBin := "", nH, nL
   DO CASE
   CASE nVt == GVT_STRING .OR. nVt == GVT_HANDLE ; RETURN .F.
   CASE nVt == GVT_BOOL
      n := Dp_ParseI64( cText ) ; IF n == NIL ; RETURN BnW_Invalid( nCode ) ; ENDIF
      BnW_Bool( w, nCode, n != 0 )
   CASE nVt == GVT_BYTE .OR. nVt == GVT_INT16
      n := Dp_ParseI64( cText ) ; IF n == NIL .OR. n < -32768 .OR. n > 32767 ; RETURN BnW_Invalid( nCode ) ; ENDIF
      BnW_I16( w, nCode, n )
   CASE nVt == GVT_INT32
      n := Dp_ParseI64( cText ) ; IF n == NIL .OR. n < -2147483648 .OR. n > 2147483647 ; RETURN BnW_Invalid( nCode ) ; ENDIF
      BnW_I32( w, nCode, n )
   CASE nVt == GVT_INT64
      n := Dp_ParseI64( cText ) ; IF n == NIL ; RETURN BnW_Invalid( nCode ) ; ENDIF
      BnW_I64( w, nCode, n )
   CASE nVt == GVT_DOUBLE .OR. nVt == GVT_POINT3D
      n := Dp_ParseF64( cText ) ; IF n == NIL ; RETURN BnW_Invalid( nCode ) ; ENDIF
      BnW_Double( w, nCode, n )
   CASE nVt == GVT_BINARYDATA
      IF hb_BLen( cText ) % 2 != 0 ; RETURN BnW_Invalid( nCode ) ; ENDIF
      FOR i := 1 TO hb_BLen( cText ) STEP 2
         IF ! ( hb_BSubStr( cText, i, 1 ) $ "0123456789abcdefABCDEF" ) .OR. ! ( hb_BSubStr( cText, i + 1, 1 ) $ "0123456789abcdefABCDEF" ) ; RETURN BnW_Invalid( nCode ) ; ENDIF
         nH := hb_HexToNum( hb_BSubStr( cText, i, 1 ) ) ; nL := hb_HexToNum( hb_BSubStr( cText, i + 1, 1 ) )
         cBin += Chr( nH * 16 + nL )
      NEXT
      BnW_Binary( w, nCode, cBin )
   OTHERWISE
      RETURN "Invalid DXF code: " + hb_ntos( nCode )
   ENDCASE
RETURN NIL

FUNCTION BnW_String( w, nCode, c )
   LOCAL r := BnW_TypedText( w, nCode, c )
   IF ValType( r ) == "C" ; RETURN r ; ENDIF
   IF ValType( r ) == "U" ; RETURN NIL ; ENDIF
   BnW_Code( w, nCode )
   IF e"\n" $ c .OR. Chr( 13 ) $ c
      c := StrTran( c, Chr( 13 ) + e"\n", "\P" ) ; c := StrTran( c, Chr( 13 ), "\P" ) ; c := StrTran( c, e"\n", "\P" )
   ENDIF
RETURN BnW_NullString( w, c )

FUNCTION BnW_XRecordString( w, nCode, c )
   LOCAL r := BnW_TypedText( w, nCode, c )
   IF ValType( r ) == "C" ; RETURN r ; ENDIF
   IF ValType( r ) == "U" ; RETURN NIL ; ENDIF
   BnW_Code( w, nCode )
RETURN BnW_NullString( w, c )

FUNCTION BnW_Byte( w, nCode, n ) ; BnW_Code( w, nCode ) ; Sw_Put( w, I2Bin( n ) ) ; RETURN NIL   // 280-289 se escriben como i16
FUNCTION BnW_I16( w, nCode, n ) ; BnW_Code( w, nCode ) ; Sw_Put( w, I2Bin( n ) ) ; RETURN NIL
FUNCTION BnW_I32( w, nCode, n ) ; BnW_Code( w, nCode ) ; Sw_Put( w, L2Bin( n ) ) ; RETURN NIL
FUNCTION BnW_I64( w, nCode, n ) ; BnW_Code( w, nCode ) ; Sw_Put( w, OCX_I64BIN( n ) ) ; RETURN NIL
FUNCTION BnW_Double( w, nCode, n ) ; BnW_Code( w, nCode ) ; Sw_Put( w, OCX_D2BIN( n ) ) ; RETURN NIL

FUNCTION BnW_Bool( w, nCode, l )
   LOCAL n := IIf( l, 1, 0 ), nVt := Gv_FromRawCode( nCode )
   DO CASE
   CASE nVt == GVT_BOOL ; BnW_Code( w, nCode ) ; Sw_Put( w, Chr( n ) ) ; RETURN NIL
   CASE nVt == GVT_BYTE .OR. nVt == GVT_INT16 ; RETURN BnW_I16( w, nCode, n )
   CASE nVt == GVT_INT32 ; RETURN BnW_I32( w, nCode, n )
   CASE nVt == GVT_INT64 ; RETURN BnW_I64( w, nCode, n )
   CASE nVt == GVT_DOUBLE ; RETURN BnW_Double( w, nCode, n )
   ENDCASE
RETURN "Invalid DXF code: " + hb_ntos( nCode )

FUNCTION BnW_Handle( w, nCode, h )
   BnW_Code( w, nCode )
   Sw_Put( w, IIf( Hd_Value( h ) == 0, "0", Hd_UpperHex( h ) ) + Chr( 0 ) )
RETURN NIL

FUNCTION BnW_Binary( w, nCode, cData )
   LOCAL i, n := hb_BLen( cData ), nLen
   IF n == 0 ; BnW_Code( w, nCode ) ; Sw_Put( w, Chr( 0 ) ) ; ENDIF
   FOR i := 1 TO n STEP 255
      nLen := Min( 255, n - i + 1 )
      BnW_Code( w, nCode ) ; Sw_Put( w, Chr( nLen ) + hb_BSubStr( cData, i, nLen ) )
   NEXT
RETURN NIL
