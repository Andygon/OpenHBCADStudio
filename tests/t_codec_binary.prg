/* binary_reader.rs no tiene tests en Rust: todos [extra]. Incluye formateo f64 (ryu / Display). */
#include "ocx.ch"
STATIC FUNCTION Hdr() ; RETURN "AutoCAD Binary DXF" + Chr( 13 ) + Chr( 10 ) + Chr( 26 ) + Chr( 0 )
PROCEDURE T_CodecBinary()
   LOCAL cErr, r, p, c
   // AC1012+: codigos de 2 bytes
   c := Hdr() + Chr( 0 ) + Chr( 0 ) + "SECTION" + Chr( 0 ) + Chr( 70 ) + Chr( 0 ) + Chr( 0xFE ) + Chr( 0xFF ) + ;
        Chr( 10 ) + Chr( 0 ) + OCX_D2BIN( 1.5 ) + Chr( 90 ) + Chr( 0 ) + Chr( 0xFF ) + Chr( 0xFF ) + Chr( 0xFF ) + Chr( 0x7F ) + ;
        Chr( 0x22 ) + Chr( 1 ) + Chr( 1 ) + Chr( 0x36 ) + Chr( 1 ) + Chr( 3 ) + Chr( 0xAB ) + Chr( 0x01 ) + Chr( 0xFF )
   r := BnR_New( c, @cErr )
   Chk( r != NIL .AND. cErr == NIL, "[extra] binary: sentinel valido" )
   Chk( BnR_PeekCode( r ) == 0, "[extra] binary: peek" )
   p := BnR_ReadPair( r ) ; Chk( p[ 1 ] == 0 .AND. p[ 3 ] == "SECTION", "[extra] binary: cadena" )
   p := BnR_ReadPair( r ) ; Chk( p[ 1 ] == 70 .AND. Dp_AsInt( p ) == -2 .AND. p[ 3 ] == "-2", "[extra] binary: i16" )
   p := BnR_ReadPair( r ) ; Chk( p[ 1 ] == 10 .AND. Dp_AsDouble( p ) == 1.5 .AND. p[ 3 ] == "1.5", "[extra] binary: f64" )
   p := BnR_ReadPair( r ) ; Chk( p[ 1 ] == 90 .AND. Dp_AsInt( p ) == 2147483647, "[extra] binary: i32" )
   p := BnR_ReadPair( r ) ; Chk( p[ 1 ] == 290 .AND. Dp_AsBool( p ) == .T. .AND. p[ 3 ] == "1", "[extra] binary: bool" )
   p := BnR_ReadPair( r ) ; Chk( p[ 1 ] == 310 .AND. p[ 3 ] == "AB01FF", "[extra] binary: datos binarios a hex" )
   Chk( BnR_ReadPair( r ) == NIL .AND. BnR_Error( r ) == NIL, "[extra] binary: EOF limpio" )
   Chk( BnR_Reset( r ) .AND. BnR_ReadPair( r )[ 3 ] == "SECTION", "[extra] binary: reset" )
   // pre-AC1012: codigo de 1 byte
   r := BnR_New( Hdr() + Chr( 0 ) + "SECTION" + Chr( 0 ) + Chr( 255 ) + Chr( 0xE8 ) + Chr( 0x03 ) + "txt" + Chr( 0 ), @cErr )
   p := BnR_ReadPair( r ) ; Chk( p[ 1 ] == 0 .AND. p[ 3 ] == "SECTION", "[extra] binary: 1 byte" )
   p := BnR_ReadPair( r ) ; Chk( p[ 1 ] == 1000 .AND. p[ 3 ] == "txt", "[extra] binary: escape 255" )
   r := BnR_New( Hdr() + Chr( 0 ) + Chr( 0 ) + "A" + Chr( 0 ) + Chr( 10 ) + Chr( 0 ) + "abc", @cErr ) ; BnR_ReadPair( r )
   Chk( BnR_ReadPair( r ) == NIL .AND. BnR_Error( r ) != NIL, "[extra] binary: f64 truncado es error" )
   Chk( BnR_New( "AutoCAD Binary DXF" + Chr( 13 ) + Chr( 10 ) + Chr( 26 ) + Chr( 1 ) + "xx", @cErr ) == NIL .AND. "sentinel" $ cErr, "[extra] binary: sentinel invalido" )
   // formateo f64
   Chk( F64_Ryu( 1.0 ) == "1.0" .AND. F64_Ryu( 1.5 ) == "1.5" .AND. F64_Ryu( 0.1 ) == "0.1" .AND. F64_Ryu( -2.25 ) == "-2.25" .AND. F64_Ryu( 100.0 ) == "100.0" .AND. F64_Ryu( 0.0 ) == "0.0" .AND. F64_Ryu( 123456.789 ) == "123456.789", "[extra] f64: ryu basico" )
   Chk( F64_Ryu( OCX_POW( 10.0, 16 ) ) == "1e16" .AND. F64_Ryu( 15.0 / OCX_POW( 10.0, 8 ) ) == "1.5e-7" .AND. F64_Ryu( 0.00001 ) == "0.00001" .AND. F64_Ryu( OCX_POW( 10.0, 15 ) ) == "1000000000000000.0" .AND. F64_Ryu( 1.0 / OCX_POW( 10.0, 6 ) ) == "1e-6", "[extra] f64: ryu exponente" )
   Chk( F64_Ryu( 1.0 / 3.0 ) == "0.3333333333333333" .AND. F64_Ryu( 0.1 + 0.2 ) == "0.30000000000000004" .AND. F64_Ryu( OCX_INF() ) == "inf" .AND. F64_Ryu( -OCX_INF() ) == "-inf" .AND. F64_Ryu( OCX_NAN() ) == "NaN", "[extra] f64: ryu round-trip y no finitos" )
   Chk( F64_Display( 1.0 ) == "1" .AND. F64_Display( 1.5 ) == "1.5" .AND. F64_Display( OCX_POW( 10.0, 21 ) ) == "1000000000000000000000" .AND. F64_Display( 15.0 / OCX_POW( 10.0, 8 ) ) == "0.00000015" .AND. F64_Display( -0.0 ) == "-0" .AND. F64_Display( 100.25 ) == "100.25", "[extra] f64: Display sin exponente" )
RETURN
