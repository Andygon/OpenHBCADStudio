/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/code_page.prg
   Origen Rust: opencadcodec/src/io/dxf/code_page.rs (418 lineas, 11 tests; ver t_codec_codepage.prg)
   Licencia del original: MPL-2.0.
   encoding_rs no existe en Harbour: un "encoding" se representa por su NOMBRE (cadena, p.ej.
   "WINDOWS_1252", "GBK") y NIL equivale a None (UTF-8/ASCII, sin transcodificar).
   DECISION (usuario/parent, 12-oct): interno UTF-8; al leer se respeta el $DWGCODEPAGE declarado y
   se cubre WINDOWS_1252 (ANSI_1252) y los escapes CIF \U+XXXX. Encodings exoticos (GBK, Shift-JIS,
   Big5, EUC-KR, Johab, 125x no latinos...) quedan DIFERIDOS hasta que un fichero real los pida:
     - CP_EncodeLegacyString solo codifica WINDOWS_1252 (y NIL/UTF-8 = sin cambios); otro encoding -> NIL.
     - CP_DecodeMifEscapes (\M+nXXXX) valida el formato igual que el Rust pero NO decodifica
       (deja el escape literal tambien para Shift-JIS/Big5/EUC-KR/GBK, que el Rust si decodifica).
   Tests Rust: test_encode_legacy_string_cif_escapes portado salvo la asercion GBK; test_decode_mif_escapes
   portado salvo las aserciones que decodifican (件号, 技术要求).
----------------------------------------------------------------------------*/
#include "ocx.ch"

STATIC FUNCTION CP_EncMap()
   STATIC s_a
   IF s_a == NIL
      s_a := {;
      { "gb2312", "GBK" },;
      { "ansi_936", "GBK" },;
      { "big5", "BIG5" },;
      { "ansi_950", "BIG5" },;
      { "korean", "EUC_KR" },;
      { "ansi_949", "EUC_KR" },;
      { "johab", "EUC_KR" },;
      { "ansi_932", "SHIFT_JIS" },;
      { "dos437", "IBM866" },;
      { "dos850", "WINDOWS_1252" },;
      { "dos852", "WINDOWS_1250" },;
      { "dos855", "IBM866" },;
      { "dos866", "IBM866" },;
      { "dos857", "WINDOWS_1254" },;
      { "dos860", "WINDOWS_1252" },;
      { "dos861", "WINDOWS_1252" },;
      { "dos863", "WINDOWS_1252" },;
      { "dos865", "WINDOWS_1252" },;
      { "dos869", "WINDOWS_1253" },;
      { "ansi_874", "WINDOWS_874" },;
      { "ansi_1250", "WINDOWS_1250" },;
      { "ansi_1251", "WINDOWS_1251" },;
      { "ansi_1252", "WINDOWS_1252" },;
      { "ansi_1253", "WINDOWS_1253" },;
      { "ansi_1254", "WINDOWS_1254" },;
      { "ansi_1255", "WINDOWS_1255" },;
      { "ansi_1256", "WINDOWS_1256" },;
      { "ansi_1257", "WINDOWS_1257" },;
      { "ansi_1258", "WINDOWS_1258" },;
      { "iso8859-1", "WINDOWS_1252" },;
      { "iso_8859-1", "WINDOWS_1252" },;
      { "iso8859-2", "ISO_8859_2" },;
      { "iso_8859-2", "ISO_8859_2" },;
      { "iso8859-3", "ISO_8859_3" },;
      { "iso_8859-3", "ISO_8859_3" },;
      { "iso8859-4", "ISO_8859_4" },;
      { "iso_8859-4", "ISO_8859_4" },;
      { "iso8859-5", "ISO_8859_5" },;
      { "iso_8859-5", "ISO_8859_5" },;
      { "iso8859-6", "ISO_8859_6" },;
      { "iso_8859-6", "ISO_8859_6" },;
      { "iso8859-7", "ISO_8859_7" },;
      { "iso_8859-7", "ISO_8859_7" },;
      { "iso8859-8", "ISO_8859_8" },;
      { "iso_8859-8", "ISO_8859_8" },;
      { "iso8859-9", "WINDOWS_1254" },;
      { "iso_8859-9", "WINDOWS_1254" },;
      { "iso8859-10", "ISO_8859_10" },;
      { "iso_8859-10", "ISO_8859_10" },;
      { "iso8859-13", "ISO_8859_13" },;
      { "iso_8859-13", "ISO_8859_13" },;
      { "iso8859-14", "ISO_8859_14" },;
      { "iso_8859-14", "ISO_8859_14" },;
      { "iso8859-15", "ISO_8859_15" },;
      { "iso_8859-15", "ISO_8859_15" },;
      { "koi8-r", "KOI8_R" },;
      { "koi8-u", "KOI8_U" },;
      { "ascii", NIL },;
      { "utf-8", NIL },;
      { "utf8", NIL },;
      { "unicode", NIL } }
   ENDIF
RETURN s_a

STATIC FUNCTION CP_NameMap()
   STATIC s_a
   IF s_a == NIL
      s_a := {;
      { 1, "ASCII" },;
      { 2, "ISO8859-1" },;
      { 3, "ISO8859-2" },;
      { 4, "ISO8859-3" },;
      { 5, "ISO8859-4" },;
      { 6, "ISO8859-5" },;
      { 7, "ISO8859-6" },;
      { 8, "ISO8859-7" },;
      { 9, "ISO8859-8" },;
      { 10, "ISO8859-9" },;
      { 11, "DOS437" },;
      { 12, "DOS850" },;
      { 13, "DOS852" },;
      { 14, "DOS855" },;
      { 15, "DOS857" },;
      { 16, "DOS860" },;
      { 17, "DOS861" },;
      { 18, "DOS863" },;
      { 19, "DOS864" },;
      { 20, "DOS865" },;
      { 21, "DOS869" },;
      { 22, "ANSI_932" },;
      { 38, "ANSI_932" },;
      { 23, "MAC-ROMAN" },;
      { 24, "BIG5" },;
      { 41, "BIG5" },;
      { 25, "KOREAN" },;
      { 40, "KOREAN" },;
      { 26, "JOHAB" },;
      { 42, "JOHAB" },;
      { 27, "DOS866" },;
      { 28, "ANSI_1250" },;
      { 29, "ANSI_1251" },;
      { 30, "ANSI_1252" },;
      { 31, "GB2312" },;
      { 39, "GB2312" },;
      { 32, "ANSI_1253" },;
      { 33, "ANSI_1254" },;
      { 34, "ANSI_1255" },;
      { 35, "ANSI_1256" },;
      { 36, "ANSI_1257" },;
      { 37, "ANSI_874" },;
      { 43, "UTF-8" },;
      { 44, "ANSI_1258" } }
   ENDIF
RETURN s_a

STATIC FUNCTION CP_IdxMap()
   STATIC s_a
   IF s_a == NIL
      s_a := {;
      { "ascii", 1 },;
      { "iso8859-1", 2 },;
      { "iso_8859-1", 2 },;
      { "iso8859-2", 3 },;
      { "iso_8859-2", 3 },;
      { "iso8859-3", 4 },;
      { "iso_8859-3", 4 },;
      { "iso8859-4", 5 },;
      { "iso_8859-4", 5 },;
      { "iso8859-5", 6 },;
      { "iso_8859-5", 6 },;
      { "iso8859-6", 7 },;
      { "iso_8859-6", 7 },;
      { "iso8859-7", 8 },;
      { "iso_8859-7", 8 },;
      { "iso8859-8", 9 },;
      { "iso_8859-8", 9 },;
      { "iso8859-9", 10 },;
      { "iso_8859-9", 10 },;
      { "dos437", 11 },;
      { "dos850", 12 },;
      { "dos852", 13 },;
      { "dos855", 14 },;
      { "dos857", 15 },;
      { "dos860", 16 },;
      { "dos861", 17 },;
      { "dos863", 18 },;
      { "dos864", 19 },;
      { "dos865", 20 },;
      { "dos869", 21 },;
      { "ansi_932", 22 },;
      { "dos932", 22 },;
      { "mac-roman", 23 },;
      { "big5", 24 },;
      { "ansi_950", 24 },;
      { "dos950", 24 },;
      { "korean", 25 },;
      { "ansi_949", 25 },;
      { "johab", 26 },;
      { "dos866", 27 },;
      { "ansi_1250", 28 },;
      { "ansi1250", 28 },;
      { "ansi_1251", 29 },;
      { "ansi1251", 29 },;
      { "ansi_1252", 30 },;
      { "ansi1252", 30 },;
      { "gb2312", 31 },;
      { "ansi_936", 31 },;
      { "ansi_1253", 32 },;
      { "ansi1253", 32 },;
      { "ansi_1254", 33 },;
      { "ansi1254", 33 },;
      { "ansi_1255", 34 },;
      { "ansi1255", 34 },;
      { "ansi_1256", 35 },;
      { "ansi1256", 35 },;
      { "ansi_1257", 36 },;
      { "ansi1257", 36 },;
      { "ansi_874", 37 },;
      { "utf-8", 43 },;
      { "utf8", 43 },;
      { "unicode", 43 },;
      { "ansi_1258", 44 },;
      { "ansi1258", 44 } }
   ENDIF
RETURN s_a

/* Devuelve nombre de encoding, o NIL (None). Desconocido -> "WINDOWS_1252". */
FUNCTION CP_EncodingFromCodePage( cPage )
   LOCAL k := Lower( cPage ), n := AScan( CP_EncMap(), {| a | a[ 1 ] == k } )
RETURN IIf( n > 0, CP_EncMap()[ n ][ 2 ], "WINDOWS_1252" )

FUNCTION CP_DwgCodePageName( nIdx )
   LOCAL n := AScan( CP_NameMap(), {| a | a[ 1 ] == nIdx } )
RETURN IIf( n > 0, CP_NameMap()[ n ][ 2 ], "ANSI_1252" )

FUNCTION CP_DwgCodePageIndex( cPage )
   LOCAL k := Lower( cPage ), n := AScan( CP_IdxMap(), {| a | a[ 1 ] == k } )
RETURN IIf( n > 0, CP_IdxMap()[ n ][ 2 ], 30 )

FUNCTION CP_EncodingFromDwgCodePage( nIdx )
   LOCAL e := CP_EncodingFromCodePage( CP_DwgCodePageName( nIdx ) )
RETURN IIf( e == NIL, "WINDOWS_1252", e )

FUNCTION CP_HasLegacyEscape( cText ) ; RETURN "\U+" $ cText .OR. "\M+" $ cText

/* u16::from_str_radix(s,16) sobre 4 caracteres: acepta '+' inicial como Rust. NIL si falla. */
STATIC FUNCTION CP_Hex4( aCh, nStart )
   LOCAL c, i, nV := 0, nFrom := nStart
   IF nStart + 3 > Len( aCh ) ; RETURN NIL ; ENDIF
   IF aCh[ nStart ] == "+" ; nFrom := nStart + 1 ; ENDIF
   FOR i := nFrom TO nStart + 3
      c := aCh[ i ]
      IF Len( c ) != 1 .OR. ! ( c $ "0123456789abcdefABCDEF" ) ; RETURN NIL ; ENDIF
      nV := nV * 16 + hb_HexToNum( c )
   NEXT
RETURN nV

STATIC FUNCTION CP_Chars( cText )
   LOCAL a := {}, i, n := hb_UTF8Len( cText )
   FOR i := 1 TO n
      AAdd( a, hb_UTF8Substr( cText, i, 1 ) )
   NEXT
RETURN a

/* Decodifica \U+XXXX (exactamente 4 hex); par sustituto alto+bajo se combina;
   escapes mal formados quedan literales; puntos de codigo invalidos se descartan. */
FUNCTION CP_DecodeCifEscapes( cText )
   LOCAL aCh, nLen, i := 1, cOut := "", nU, nLow, nCp
   IF ! ( "\U+" $ cText ) ; RETURN cText ; ENDIF
   aCh := CP_Chars( cText ) ; nLen := Len( aCh )
   DO WHILE i <= nLen
      IF aCh[ i ] == "\" .AND. i + 6 <= nLen .AND. aCh[ i + 1 ] == "U" .AND. aCh[ i + 2 ] == "+"
         nU := CP_Hex4( aCh, i + 3 )
         IF nU != NIL
            i += 7 ; nCp := nU
            IF nU >= 0xD800 .AND. nU < 0xDC00 .AND. i + 6 <= nLen .AND. aCh[ i ] == "\" .AND. aCh[ i + 1 ] == "U" .AND. aCh[ i + 2 ] == "+"
               nLow := CP_Hex4( aCh, i + 3 )
               IF nLow != NIL .AND. nLow >= 0xDC00 .AND. nLow < 0xE000
                  nCp := 0x10000 + ( nU - 0xD800 ) * 0x400 + ( nLow - 0xDC00 )
                  i += 7
               ENDIF
            ENDIF
            IF ! ( nCp >= 0xD800 .AND. nCp < 0xE000 )
               cOut += hb_UTF8Chr( nCp )
            ENDIF
            LOOP
         ENDIF
      ENDIF
      cOut += aCh[ i ] ; i++
   ENDDO
RETURN cOut

/* ---- Escritura legacy (solo WINDOWS_1252) --------------------------------------------------- */
STATIC FUNCTION CP_Win1252High()
   STATIC s_a
   IF s_a == NIL
      // bytes 0x80..0x9F de windows-1252 (WHATWG/encoding_rs): codepoint o -1 si no hay mapeo propio
      s_a := { 0x20AC, 0x81, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, 0x02C6, 0x2030, 0x0160, 0x2039, 0x0152, 0x8D, 0x017D, 0x8F, ;
               0x90, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014, 0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0x9D, 0x017E, 0x0178 }
   ENDIF
RETURN s_a

// byte windows-1252 para el codepoint o -1
STATIC FUNCTION CP_Cp1252Byte( nCp )
   LOCAL a, i
   IF nCp < 0x80 .OR. ( nCp >= 0xA0 .AND. nCp <= 0xFF ) ; RETURN nCp ; ENDIF
   a := CP_Win1252High()
   FOR i := 1 TO 32
      IF a[ i ] == nCp ; RETURN 0x7F + i ; ENDIF
   NEXT
RETURN -1

/* encode_legacy_string( text, encoding ): cadena binaria. Lo no mapeable sale como \U+XXXX (par sustituto
   para el plano astral). Devuelve NIL si el encoding no esta soportado (solo WINDOWS_1252). */
FUNCTION CP_EncodeLegacyString( cText, cEncoding )
   LOCAL cOut := "", i, n, c, nCp, nB
   IF cEncoding == NIL .OR. cEncoding == "UTF-8"
      RETURN cText
   ENDIF
   IF ! ( cEncoding == "WINDOWS_1252" ) ; RETURN NIL ; ENDIF
   n := hb_UTF8Len( cText )
   FOR i := 1 TO n
      c := hb_UTF8Substr( cText, i, 1 ) ; nCp := hb_UTF8Asc( c )
      nB := CP_Cp1252Byte( nCp )
      IF nB >= 0
         cOut += hb_BChar( nB )
      ELSEIF nCp >= 0x10000
         nCp -= 0x10000
         cOut += "\U+" + PadL( hb_NumToHex( 0xD800 + Int( nCp / 0x400 ), 4 ), 4, "0" ) + "\U+" + PadL( hb_NumToHex( 0xDC00 + nCp % 0x400, 4 ), 4, "0" )
      ELSE
         cOut += "\U+" + PadL( hb_NumToHex( nCp, 4 ), 4, "0" )
      ENDIF
   NEXT
RETURN cOut

/* decode_mif_escapes: solo valida el formato (no hay tablas multibyte; ver cabecera): devuelve el texto igual. */
FUNCTION CP_DecodeMifEscapes( cText )
RETURN cText

/* decode_legacy_escapes = decode_cif_escapes( decode_mif_escapes( text ) ) */
FUNCTION CP_DecodeLegacyEscapes( cText )
RETURN CP_DecodeCifEscapes( CP_DecodeMifEscapes( cText ) )
