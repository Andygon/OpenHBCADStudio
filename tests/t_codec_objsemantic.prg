/* Tests: semantic_property.rs no tiene #[test]; todos [extra] (ida y vuelta del envelope, payloads, defaults) */
#include "ocx.ch"
PROCEDURE T_CodecObjSemantic()
   LOCAL p, d, props, pl, env, dec, big, i, cBad, q
   p := Ppl_FromBytes( "hello" ) ; Chk( p[ "encoding" ] == PPE_BYTES .AND. p[ "bit_count" ] == 40 .AND. Len( p[ "records" ] ) == 1 .AND. Ppl_Data( p ) == "hello", "[extra] from_bytes" )
   p := Ppl_FromBits( hb_BChar( 255 ) + hb_BChar( 255 ), 12 ) ; d := Ppl_Data( p )
   Chk( p[ "encoding" ] == PPE_BITS .AND. hb_BLen( d ) == 2 .AND. hb_BCode( hb_BSubStr( d, 1, 1 ) ) == 255 .AND. hb_BCode( hb_BSubStr( d, 2, 1 ) ) == 240, "[extra] from_bits mascara el ultimo byte" )
   big := Replicate( "a", 300 ) ; p := Ppl_FromBytes( big )
   Chk( Len( p[ "records" ] ) == 3 .AND. p[ "records" ][ 2 ][ "bit_offset" ] == 1016 .AND. p[ "records" ][ 3 ][ "bit_count" ] == 368 .AND. Ppl_Data( p ) == big, "[extra] chunks de 127 y reconstruccion" )
   p := Ppl_Default() ; Chk( p[ "encoding" ] == PPE_BITS .AND. p[ "bit_count" ] == 0 .AND. Len( p[ "records" ] ) == 0 .AND. hb_BLen( Ppl_Data( p ) ) == 0, "[extra] default payload" )
   props := { Spv_New( "AcDbA", 1, Spv_Value( "Text", "hola" ) ), Spv_New( "AcDbB", 2, Spv_Value( "Bool", .T. ) ), Spv_New( "AcDbB", 3, Spv_Value( "Bool", .F. ) ), ;
      Spv_New( "S", 4, Spv_Value( "Byte", 200 ) ), Spv_New( "S", 5, Spv_Value( "Int16", -1234 ) ), Spv_New( "S", 6, Spv_Value( "Int32", -70000 ) ), ;
      Spv_New( "S", -7, Spv_Value( "Int64", -5000000000 ) ), Spv_New( "S", 8, Spv_Value( "Double", 2.5 ) ), Spv_New( "S", 9, Spv_Value( "Handle", 0xABCDEF ) ), ;
      Spv_New( "S", 10, Spv_Value( "Binary", hb_BChar( 0 ) + hb_BChar( 255 ) + "x" ) ) }
   pl := Ppl_FromBits( hb_BChar( 1 ) + hb_BChar( 2 ) + hb_BChar( 192 ), 18 )
   env := Pxe_Encode( "MYCLASS", "CMyClass", props, pl ) ; dec := Pxe_Decode( env )
   Chk( dec != NIL .AND. dec[ "dxf_name" ] == "MYCLASS" .AND. dec[ "cpp_class_name" ] == "CMyClass" .AND. Len( dec[ "properties" ] ) == 10, "[extra] envelope ida y vuelta: cabecera" )
   IF dec != NIL
      Chk( dec[ "payload" ][ "encoding" ] == PPE_BITS .AND. dec[ "payload" ][ "bit_count" ] == 18 .AND. Ppl_Data( dec[ "payload" ] ) == Ppl_Data( pl ), "[extra] envelope payload" )
      q := dec[ "properties" ]
      Chk( q[ 1 ][ "value" ][ "value" ] == "hola" .AND. q[ 2 ][ "value" ][ "value" ] == .T. .AND. q[ 3 ][ "value" ][ "value" ] == .F. .AND. q[ 4 ][ "value" ][ "value" ] == 200 ;
         .AND. q[ 5 ][ "value" ][ "value" ] == -1234 .AND. q[ 6 ][ "value" ][ "value" ] == -70000 .AND. q[ 7 ][ "value" ][ "value" ] == -5000000000 .AND. q[ 7 ][ "code" ] == -7 ;
         .AND. q[ 8 ][ "value" ][ "value" ] == 2.5 .AND. q[ 9 ][ "value" ][ "value" ] == 0xABCDEF .AND. q[ 10 ][ "value" ][ "value" ] == hb_BChar( 0 ) + hb_BChar( 255 ) + "x" ;
         .AND. q[ 9 ][ "value" ][ "_kind" ] == "Handle" .AND. q[ 10 ][ "subclass" ] == "S", "[extra] envelope propiedades" )
   ENDIF
   pl := Ppl_FromBytes( "abc" ) ; env := Pxe_Encode( "A", "B", {}, pl ) ; dec := Pxe_Decode( env )
   Chk( dec != NIL .AND. dec[ "payload" ][ "encoding" ] == PPE_BYTES .AND. Ppl_Data( dec[ "payload" ] ) == "abc" .AND. Len( dec[ "properties" ] ) == 0, "[extra] envelope bytes" )
   Chk( Pxe_Decode( Ppl_FromBytes( "no envelope" ) ) == NIL, "[extra] sin magic -> NIL" )
   cBad := Ppl_Data( env ) + "x" ; Chk( Pxe_Decode( Ppl_FromBytes( cBad ) ) == NIL, "[extra] bytes sobrantes -> NIL" )
   cBad := hb_BLeft( Ppl_Data( env ), hb_BLen( Ppl_Data( env ) ) - 1 ) ; Chk( Pxe_Decode( Ppl_FromBytes( cBad ) ) == NIL, "[extra] truncado -> NIL" )
   i := Ppl_Data( env ) ; cBad := hb_BLeft( i, 26 ) + hb_BChar( 2 ) + hb_BSubStr( i, 28 ) ; Chk( Pxe_Decode( Ppl_FromBytes( cBad ) ) == NIL, "[extra] version distinta -> NIL" )
   d := Rco_Default() ; Chk( d[ "dxf_name" ] == "" .AND. d[ "payload" ][ "encoding" ] == PPE_BITS .AND. d[ "raw_dwg_handle_bits" ] == 0 .AND. d[ "raw_dwg_data" ] == NIL, "[extra] RegisteredClassObject default" )
   d := Pxo_Default() ; Chk( d[ "proxy_id" ] == 0 .AND. ! d[ "from_dxf" ] .AND. d[ "text_payload" ][ "encoding" ] == PPE_BITS .AND. Len( d[ "object_ids" ] ) == 0, "[extra] ProxyObject default" )
   d := Ppr_NewRef( 0x10, PRK_HARD_POINTER ) ; Chk( d[ "handle" ] == 0x10 .AND. d[ "kind" ] == PRK_HARD_POINTER, "[extra] ProxyObjectReference" )
RETURN
