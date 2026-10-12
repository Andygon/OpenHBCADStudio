/* Port de tests de code_page.rs. Sin portar (necesitan encoding_rs): test_decode_mif_escapes, test_encode_legacy_string_cif_escapes.
   Los asserts de encoding comparan nombres de encoding (cadenas). */
#include "ocx.ch"
PROCEDURE T_CodecCodePage()
   LOCAL c
   Chk( CP_EncodingFromCodePage( "ANSI_1252" ) == "WINDOWS_1252", "codepage: test_ansi_1252" )
   Chk( CP_EncodingFromCodePage( "ansi_1251" ) == CP_EncodingFromCodePage( "ANSI_1251" ), "codepage: test_case_insensitive" )
   Chk( CP_EncodingFromCodePage( "ASCII" ) == NIL, "codepage: test_ascii_returns_none" )
   Chk( CP_EncodingFromCodePage( "UTF-8" ) == NIL, "codepage: test_utf8_returns_none" )
   Chk( CP_EncodingFromCodePage( "SOMETHING_UNKNOWN" ) == "WINDOWS_1252", "codepage: test_unknown_returns_windows1252" )
   Chk( CP_EncodingFromCodePage( "GB2312" ) == "GBK" .AND. CP_EncodingFromCodePage( "BIG5" ) == "BIG5" .AND. CP_EncodingFromCodePage( "ANSI_932" ) == "SHIFT_JIS" .AND. CP_EncodingFromCodePage( "KOREAN" ) == "EUC_KR", "codepage: test_asian_encodings" )
   FOR EACH c IN { "KOI8-R", "KOI8-U", "ISO8859-10", "ISO8859-13", "ISO8859-14", "ISO8859-15" }
      Chk( CP_DwgCodePageIndex( c ) == 30 .AND. CP_EncodingFromDwgCodePage( CP_DwgCodePageIndex( c ) ) == "WINDOWS_1252", "codepage: unsupported_dwg_pages " + c )
   NEXT
   Chk( CP_DecodeCifEscapes( "ab\U+4E2Dcd" ) == "ab" + hb_UTF8Chr( 0x4E2D ) + "cd" .AND. CP_DecodeCifEscapes( "\U+0041\U+0042" ) == "AB" .AND. CP_DecodeCifEscapes( "\U+00412" ) == "A2" .AND. CP_DecodeCifEscapes( "\U+GGGG" ) == "\U+GGGG" .AND. CP_DecodeCifEscapes( "\U+4E" ) == "\U+4E" .AND. CP_DecodeCifEscapes( "no escapes here" ) == "no escapes here" .AND. CP_DecodeCifEscapes( "\U+D800" ) == "" .AND. CP_DecodeCifEscapes( "\U+D83D\U+DE00" ) == hb_UTF8Chr( 0x1F600 ), "codepage: test_decode_cif_escapes" )
   // [extra]
   Chk( CP_DwgCodePageName( 43 ) == "UTF-8" .AND. CP_DwgCodePageName( 99 ) == "ANSI_1252" .AND. CP_DwgCodePageName( 38 ) == "ANSI_932" .AND. CP_DwgCodePageIndex( "ansi_950" ) == 24 .AND. CP_DwgCodePageIndex( "x" ) == 30, "[extra] codepage: nombre/indice DWG" )
   Chk( CP_HasLegacyEscape( "a\M+1" ) .AND. CP_HasLegacyEscape( "\U+" ) .AND. ! CP_HasLegacyEscape( "abc" ), "[extra] codepage: has_legacy_escape" )
   // test_encode_legacy_string_cif_escapes (sin la asercion GBK: encoding diferido)
   Chk( CP_EncodeLegacyString( "AB", "WINDOWS_1252" ) == "AB", "codepage: encode directo" )
   Chk( CP_EncodeLegacyString( "中", "WINDOWS_1252" ) == "\U+4E2D", "codepage: encode CIF" )
   Chk( CP_EncodeLegacyString( "😀", "WINDOWS_1252" ) == "\U+D83D\U+DE00", "codepage: encode astral" )
   Chk( CP_DecodeCifEscapes( CP_EncodeLegacyString( "a中b😀c", "WINDOWS_1252" ) ) == "a中b😀c", "codepage: encode round-trip" )
   Chk( CP_EncodeLegacyString( "中", "GBK" ) == NIL, "codepage [extra]: encoding no soportado -> NIL (diferido)" )
   Chk( hb_BCode( CP_EncodeLegacyString( "é", "WINDOWS_1252" ) ) == 0xE9 .AND. hb_BCode( CP_EncodeLegacyString( "€", "WINDOWS_1252" ) ) == 0x80 .AND. hb_BCode( CP_EncodeLegacyString( "Ÿ", "WINDOWS_1252" ) ) == 0x9F, "codepage [extra]: bytes 1252" )
   // test_decode_mif_escapes (aserciones que no necesitan tablas multibyte)
   Chk( CP_DecodeMifEscapes( "\M+9BCFE" ) == "\M+9BCFE" .AND. CP_DecodeMifEscapes( "\M+5GGGG" ) == "\M+5GGGG" .AND. CP_DecodeMifEscapes( "\M+4ABCD" ) == "\M+4ABCD", "codepage: decode_mif literales" )
   Chk( CP_DecodeLegacyEscapes( "ab\U+0021" ) == "ab!", "codepage [extra]: decode_legacy_escapes" )
RETURN
