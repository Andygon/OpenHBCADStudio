/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/text_reader.prg
   Origen Rust: opencadcodec/src/io/dxf/reader/text_reader.rs (301 lineas, 5 tests en t_codec_text.prg)
   Licencia del original: MPL-2.0.
   Lector DXF ASCII sobre cadena en memoria (el Cursor de los tests de Rust tambien es en memoria).
   Reader = { cData, nPos, nLine, nOffset, pPeeked, cEncoding, aCtx, cErr }.
   Errores: TxR_ReadPair devuelve NIL y deja el mensaje en TxR_Error(r) (NIL si fue EOF limpio).
   Lineas que no son UTF-8 valido: con encoding "WINDOWS_1252" se usa su tabla; en otro caso Latin-1
   (como Rust sin encoding). Los demas encodings quedan pendientes (decision code_page).
   Contexto (DxfStreamContext) = { nSourceOffset, nSourceLine, cRecordType, nRecordHandle }.
----------------------------------------------------------------------------*/
#include "ocx.ch"

#define TX_DATA 1
#define TX_POS 2
#define TX_LINE 3
#define TX_OFFSET 4
#define TX_PEEK 5
#define TX_ENC 6
#define TX_CTX 7
#define TX_ERR 8

FUNCTION TxR_New( cData ) ; RETURN { cData, 1, 0, 0, NIL, NIL, { NIL, NIL, NIL, NIL }, NIL }
FUNCTION TxR_Error( r ) ; RETURN r[ TX_ERR ]
FUNCTION TxR_SetEncoding( r, cEnc ) ; r[ TX_ENC ] := cEnc ; RETURN NIL
FUNCTION TxR_DiagnosticContext( r ) ; RETURN AClone( r[ TX_CTX ] )
FUNCTION TxR_PushBack( r, p ) ; r[ TX_PEEK ] := p ; RETURN NIL
FUNCTION TxR_Reset( r )
   r[ TX_POS ] := 1 ; r[ TX_LINE ] := 0 ; r[ TX_OFFSET ] := 0 ; r[ TX_PEEK ] := NIL
   r[ TX_CTX ] := { NIL, NIL, NIL, NIL } ; r[ TX_ERR ] := NIL
RETURN NIL

/* read_until(b'\n'): devuelve linea cruda sin \n ni \r final, o NIL en EOF */
STATIC FUNCTION TxR_RawLine( r )
   LOCAL nEnd, cL, cD := r[ TX_DATA ], nP := r[ TX_POS ]
   IF nP > Len( cD ) ; RETURN NIL ; ENDIF
   nEnd := hb_At( e"\n", cD, nP )
   IF nEnd == 0
      cL := SubStr( cD, nP ) ; r[ TX_POS ] := Len( cD ) + 1 ; r[ TX_OFFSET ] += Len( cL )
   ELSE
      cL := SubStr( cD, nP, nEnd - nP ) ; r[ TX_POS ] := nEnd + 1 ; r[ TX_OFFSET ] += nEnd - nP + 1
   ENDIF
   r[ TX_LINE ]++
   IF Right( cL, 1 ) == Chr( 13 ) ; cL := hb_StrShrink( cL, 1 ) ; ENDIF
RETURN cL

/* hb_StrIsUTF8() devuelve .F. para ASCII puro: ASCII tambien es UTF-8 valido */
STATIC FUNCTION TxR_IsUtf8( c )
   LOCAL i
   FOR i := 1 TO hb_BLen( c )
      IF hb_BCode( hb_BSubStr( c, i, 1 ) ) > 127 ; RETURN hb_StrIsUTF8( c ) ; ENDIF
   NEXT
RETURN .T.

STATIC FUNCTION TxR_Cp1252( n )
   STATIC s_a := { 0x20AC, 0x81, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, 0x02C6, 0x2030, 0x0160, 0x2039, 0x0152, 0x8D, 0x017D, 0x8F, ;
                   0x90, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014, 0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0x9D, 0x017E, 0x0178 }
RETURN IIf( n >= 0x80 .AND. n <= 0x9F, s_a[ n - 0x7F ], n )

STATIC FUNCTION TxR_Decode( r, cRaw )
   LOCAL cOut := "", i, n
   IF TxR_IsUtf8( cRaw ) ; RETURN cRaw ; ENDIF
   FOR i := 1 TO Len( cRaw )
      n := Asc( SubStr( cRaw, i, 1 ) )
      IF n < 0x80
         cOut += Chr( n )
      ELSE
         cOut += hb_UTF8Chr( IIf( r[ TX_ENC ] == "WINDOWS_1252", TxR_Cp1252( n ), n ) )
      ENDIF
   NEXT
RETURN cOut

STATIC FUNCTION TxR_ReadLine( r )
   LOCAL c := TxR_RawLine( r )
   IF c == NIL ; RETURN NIL ; ENDIF
   c := TxR_Decode( r, c )
   IF CP_HasLegacyEscape( c ) ; c := CP_DecodeCifEscapes( c ) ; ENDIF   // MIF pendiente (ver code_page.prg)
RETURN c

STATIC FUNCTION TxR_ProcessString( c )
   IF ! ( "^" $ c ) ; RETURN c ; ENDIF
   c := StrTran( c, "^J", e"\n" ) ; c := StrTran( c, "^M", Chr( 13 ) )
   c := StrTran( c, "^I", Chr( 9 ) ) ; c := StrTran( c, "^ ", "^" )
RETURN c

STATIC FUNCTION TxR_Observe( r, p, nOff )
   LOCAL x := r[ TX_CTX ]
   x[ 1 ] := nOff ; x[ 2 ] := Max( r[ TX_LINE ] - 1, 0 )
   IF p[ 1 ] == 0
      x[ 3 ] := p[ 3 ] ; x[ 4 ] := NIL
   ELSEIF p[ 1 ] == 105 .OR. ( p[ 1 ] == 5 .AND. ! ( x[ 3 ] == "DIMSTYLE" ) )
      x[ 4 ] := Dp_AsHandle( p )
   ENDIF
RETURN NIL

STATIC FUNCTION TxR_ReadInternal( r )
   LOCAL nOff := r[ TX_OFFSET ], cCode, nCode, cVal, p, x := r[ TX_CTX ]
   x[ 1 ] := nOff ; x[ 2 ] := r[ TX_LINE ] + 1
   cCode := TxR_RawLine( r )
   IF cCode == NIL ; RETURN NIL ; ENDIF
   IF ! TxR_IsUtf8( cCode )
      r[ TX_ERR ] := "Parse error: Invalid UTF-8 in code at line " + hb_ntos( r[ TX_LINE ] ) ; RETURN NIL
   ENDIF
   nCode := Dp_ParseI64( AllTrim( cCode ) )   // parse::<i32>
   IF nCode == NIL .OR. nCode < -2147483648 .OR. nCode > 2147483647
      r[ TX_ERR ] := "Parse error: Invalid DXF code at line " + hb_ntos( r[ TX_LINE ] ) + ": '" + cCode + "'" ; RETURN NIL
   ENDIF
   cVal := TxR_ReadLine( r )
   IF cVal == NIL
      r[ TX_ERR ] := "Parse error: Unexpected EOF after code " + hb_ntos( nCode ) + " at line " + hb_ntos( r[ TX_LINE ] ) ; RETURN NIL
   ENDIF
   p := Dp_New( nCode, TxR_ProcessString( cVal ) )
   TxR_Observe( r, p, nOff )
RETURN p

FUNCTION TxR_ReadPair( r )
   LOCAL p
   r[ TX_ERR ] := NIL
   IF r[ TX_PEEK ] != NIL ; p := r[ TX_PEEK ] ; r[ TX_PEEK ] := NIL ; RETURN p ; ENDIF
RETURN TxR_ReadInternal( r )

FUNCTION TxR_PeekCode( r )
   LOCAL p
   r[ TX_ERR ] := NIL
   IF r[ TX_PEEK ] != NIL ; RETURN r[ TX_PEEK ][ 1 ] ; ENDIF
   p := TxR_ReadInternal( r )
   IF p == NIL ; RETURN NIL ; ENDIF
   r[ TX_PEEK ] := p
RETURN p[ 1 ]
