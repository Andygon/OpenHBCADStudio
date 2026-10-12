/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/obj_semantic.prg
   Origen Rust: opencadcodec/src/objects/semantic_property.rs (377 lineas, sin tests en Rust). Licencia del original: MPL-2.0.
   Prefijos: Ppl_ (ProxyPayload), Ppr_ (ProxyPayloadRecord), Spv_ (SemanticPropertyValue / SemanticProperty),
             Rco_ (RegisteredClassObject), Pxo_ (ProxyObject), Pxe_ (envelope registered class + EnvelopeReader).
   Vec<u8> -> cadena de bytes (se usan funciones hb_B* para no depender del CDP). Option -> NIL. u32/u64 saturating_*: los valores reales
   no desbordan. Constantes en ocx.ch: PPE_BYTES/PPE_BITS (ProxyPayloadEncoding, defecto Bits) y PRK_* (ProxyReferenceKind).
   SemanticPropertyValue = hash { "_kind": "Text"|"Bool"|"Byte"|"Int16"|"Int32"|"Int64"|"Double"|"Handle"|"Binary", "value": x }.
   Los handles u64 > i64::MAX se leen como double (OCX_BIN2U64); no ocurren en handles reales.
   Los tests que hay son [extra]: el fichero Rust no tiene #[test].
----------------------------------------------------------------------------*/
#include "ocx.ch"

/* ---- SemanticProperty ---- */
FUNCTION Spv_Value( cKind, xVal ) ; RETURN hb_Hash( "_kind", cKind, "value", xVal )
FUNCTION Spv_New( cSubclass, nCode, hValue ) ; RETURN hb_Hash( "subclass", cSubclass, "code", nCode, "value", hValue )

/* ---- ProxyReference ---- */
FUNCTION Ppr_NewRef( nHandle, nKind ) ; RETURN hb_Hash( "handle", nHandle, "kind", nKind )

/* ---- ProxyPayload ---- */
FUNCTION Ppl_Default() ; RETURN hb_Hash( "encoding", PPE_BITS, "bit_count", 0, "records", {} )

FUNCTION Ppl_FromBits( cData, nBitCount ) ; RETURN Ppl_FromData( cData, nBitCount, PPE_BITS )
FUNCTION Ppl_FromBytes( cData ) ; RETURN Ppl_FromData( cData, Min( hb_BLen( cData ) * 8, 4294967295 ), PPE_BYTES )

STATIC FUNCTION Ppl_FromData( cData, nBitCount, nEnc )
   LOCAL aRec := {}, nOff := 0, nSeq := 0, nPos := 1, cChunk, nAvail, nRb
   DO WHILE nPos <= hb_BLen( cData )
      cChunk := hb_BSubStr( cData, nPos, 127 )
      nAvail := Max( nBitCount - nOff, 0 )
      nRb := Min( nAvail, hb_BLen( cChunk ) * 8 )
      AAdd( aRec, hb_Hash( "sequence", nSeq, "bit_offset", nOff, "bit_count", nRb, "data", cChunk ) )
      nOff += nRb
      nSeq++
      nPos += 127
   ENDDO
RETURN hb_Hash( "encoding", nEnc, "bit_count", nBitCount, "records", aRec )

FUNCTION Ppl_Data( p )
   LOCAL aRec := {}, i, r, nByteCount, cOut, nOff, nLen, nEnd, nRem, nLast
   FOR i := 1 TO Len( p[ "records" ] )
      AAdd( aRec, { p[ "records" ][ i ][ "sequence" ], i, p[ "records" ][ i ] } )
   NEXT
   ASort( aRec,,, {| x, y | x[ 1 ] < y[ 1 ] .OR. ( x[ 1 ] == y[ 1 ] .AND. x[ 2 ] < y[ 2 ] ) } )
   nByteCount := Int( ( p[ "bit_count" ] + 7 ) / 8 )
   cOut := Replicate( hb_BChar( 0 ), nByteCount )
   FOR i := 1 TO Len( aRec )
      r := aRec[ i ][ 3 ]
      nOff := Int( r[ "bit_offset" ] / 8 )
      nLen := Int( ( r[ "bit_count" ] + 7 ) / 8 )
      IF nOff >= hb_BLen( cOut ) ; LOOP ; ENDIF
      nEnd := Min( Min( nOff + nLen, hb_BLen( cOut ) ), nOff + hb_BLen( r[ "data" ] ) )
      cOut := hb_BLeft( cOut, nOff ) + hb_BLeft( r[ "data" ], nEnd - nOff ) + hb_BSubStr( cOut, nEnd + 1 )
   NEXT
   nRem := p[ "bit_count" ] % 8
   nByteCount := hb_BLen( cOut )
   IF nByteCount > 0 .AND. nRem != 0
      nLast := hb_bitAnd( hb_BCode( hb_BSubStr( cOut, nByteCount, 1 ) ), hb_bitAnd( hb_bitShift( 255, 8 - nRem ), 255 ) )
      cOut := hb_BLeft( cOut, nByteCount - 1 ) + hb_BChar( nLast )
   ENDIF
RETURN cOut

/* ---- RegisteredClassObject / ProxyObject (derive Default) ---- */
FUNCTION Rco_Default()
RETURN hb_Hash( "_type", "RegisteredClassObject", "handle", Hd_Null(), "owner", Hd_Null(), "reactors", {}, "xdictionary_handle", NIL, "dxf_name", "", "cpp_class_name", "", ;
   "properties", {}, "payload", Ppl_Default(), "object_ids", {}, "raw_dwg_data", NIL, "raw_dwg_handle_bits", 0, "raw_dwg_version", NIL )

FUNCTION Pxo_Default()
RETURN hb_Hash( "_type", "ProxyObject", "handle", Hd_Null(), "owner", Hd_Null(), "reactors", {}, "xdictionary_handle", NIL, "proxy_id", 0, "class_id", 0, "dxf_subclass", "", ;
   "version", 0, "dwg_version", 0, "maintenance_version", 0, "from_dxf", .F., "payload", Ppl_Default(), "text_payload", Ppl_Default(), "object_ids", {} )

/* ---- envelope de clase registrada ---- */
STATIC FUNCTION Pxe_Magic() ; RETURN "ACADRUST-REGISTERED-CLASS" + hb_BChar( 0 )

STATIC FUNCTION Pxe_U32( n ) ; RETURN L2Bin( iif( n >= 2147483648, n - 4294967296, n ) )
STATIC FUNCTION Pxe_Bytes( c ) ; RETURN Pxe_U32( hb_BLen( c ) ) + c

FUNCTION Pxe_Encode( cDxfName, cCppName, aProps, hPayload )
   LOCAL d := Pxe_Magic(), i, p, v
   d += hb_BChar( 1 )
   d += Pxe_Bytes( cDxfName ) + Pxe_Bytes( cCppName )
   d += hb_BChar( iif( hPayload[ "encoding" ] == PPE_BYTES, 0, 1 ) )
   d += Pxe_U32( hPayload[ "bit_count" ] )
   d += Pxe_Bytes( Ppl_Data( hPayload ) )
   d += Pxe_U32( Min( Len( aProps ), 4294967295 ) )
   FOR i := 1 TO Len( aProps )
      p := aProps[ i ]
      d += Pxe_Bytes( p[ "subclass" ] ) + L2Bin( p[ "code" ] )
      v := p[ "value" ]
      SWITCH v[ "_kind" ]
      CASE "Text"   ; d += hb_BChar( 0 ) + Pxe_Bytes( v[ "value" ] ) ; EXIT
      CASE "Bool"   ; d += hb_BChar( 1 ) + hb_BChar( iif( v[ "value" ], 1, 0 ) ) ; EXIT
      CASE "Byte"   ; d += hb_BChar( 2 ) + hb_BChar( v[ "value" ] ) ; EXIT
      CASE "Int16"  ; d += hb_BChar( 3 ) + I2Bin( v[ "value" ] ) ; EXIT
      CASE "Int32"  ; d += hb_BChar( 4 ) + L2Bin( v[ "value" ] ) ; EXIT
      CASE "Int64"  ; d += hb_BChar( 5 ) + OCX_I64BIN( v[ "value" ] ) ; EXIT
      CASE "Double" ; d += hb_BChar( 6 ) + OCX_D2BIN( v[ "value" ] ) ; EXIT
      CASE "Handle" ; d += hb_BChar( 7 ) + OCX_I64BIN( v[ "value" ] ) ; EXIT
      CASE "Binary" ; d += hb_BChar( 8 ) + Pxe_Bytes( v[ "value" ] ) ; EXIT
      ENDSWITCH
   NEXT
RETURN Ppl_FromBytes( d )

/* EnvelopeReader = hash { data, position (base 0), fail } ; take() devuelve NIL y marca fail si no hay bytes */
STATIC FUNCTION Pxr_New( c ) ; RETURN hb_Hash( "data", c, "position", 0, "fail", .F. )
STATIC FUNCTION Pxr_Take( r, n )
   LOCAL c
   IF r[ "fail" ] .OR. r[ "position" ] + n > hb_BLen( r[ "data" ] )
      r[ "fail" ] := .T.
      RETURN NIL
   ENDIF
   c := hb_BSubStr( r[ "data" ], r[ "position" ] + 1, n )
   r[ "position" ] += n
RETURN c
STATIC FUNCTION Pxr_Byte( r )
   LOCAL c := Pxr_Take( r, 1 )
RETURN iif( c == NIL, NIL, hb_BCode( c ) )
STATIC FUNCTION Pxr_I16( r )
   LOCAL c := Pxr_Take( r, 2 )
RETURN iif( c == NIL, NIL, Bin2I( c ) )
STATIC FUNCTION Pxr_U32( r )
   LOCAL c := Pxr_Take( r, 4 )
RETURN iif( c == NIL, NIL, Bin2L( c ) + iif( hb_BCode( hb_BSubStr( c, 4, 1 ) ) >= 128, 4294967296, 0 ) )
STATIC FUNCTION Pxr_I32( r )
   LOCAL c := Pxr_Take( r, 4 )
RETURN iif( c == NIL, NIL, Bin2L( c ) )
STATIC FUNCTION Pxr_U64( r )
   LOCAL c := Pxr_Take( r, 8 )
RETURN iif( c == NIL, NIL, OCX_BIN2U64( c ) )
STATIC FUNCTION Pxr_I64( r )
   LOCAL c := Pxr_Take( r, 8 )
RETURN iif( c == NIL, NIL, OCX_BIN2I64( c ) )
STATIC FUNCTION Pxr_F64( r )
   LOCAL c := Pxr_Take( r, 8 )
RETURN iif( c == NIL, NIL, OCX_BIN2D( c ) )
STATIC FUNCTION Pxr_Bytes( r )
   LOCAL n := Pxr_U32( r )
RETURN iif( n == NIL, NIL, Pxr_Take( r, n ) )
STATIC FUNCTION Pxr_String( r )
   LOCAL c := Pxr_Bytes( r ), i
   IF c == NIL ; RETURN NIL ; ENDIF
   FOR i := 1 TO hb_BLen( c )
      IF hb_BCode( hb_BSubStr( c, i, 1 ) ) > 127
         IF ! hb_StrIsUTF8( c )
            r[ "fail" ] := .T.
            RETURN NIL
         ENDIF
         EXIT
      ENDIF
   NEXT
RETURN c

/* devuelve hash { dxf_name, cpp_class_name, properties, payload } o NIL */
FUNCTION Pxe_Decode( hPayload )
   LOCAL cData := Ppl_Data( hPayload ), r, nEnc, nBits, cPay, oPay, nCount, aProps := {}, i, cSub, nCode, nTag, hVal, cDxf, cCpp, x, aKinds
   IF ! hb_BLeft( cData, hb_BLen( Pxe_Magic() ) ) == Pxe_Magic()
      RETURN NIL
   ENDIF
   aKinds := { "Text", "Bool", "Byte", "Int16", "Int32", "Int64", "Double", "Handle", "Binary" }
   r := Pxr_New( hb_BSubStr( cData, hb_BLen( Pxe_Magic() ) + 1 ) )
   x := Pxr_Byte( r ) ; IF x == NIL .OR. x != 1 ; RETURN NIL ; ENDIF
   cDxf := Pxr_String( r ) ; IF cDxf == NIL ; RETURN NIL ; ENDIF
   cCpp := Pxr_String( r ) ; IF cCpp == NIL ; RETURN NIL ; ENDIF
   nEnc := Pxr_Byte( r ) ; IF nEnc == NIL ; RETURN NIL ; ENDIF
   nBits := Pxr_U32( r ) ; IF nBits == NIL ; RETURN NIL ; ENDIF
   cPay := Pxr_Bytes( r ) ; IF cPay == NIL ; RETURN NIL ; ENDIF
   IF nBits > hb_BLen( cPay ) * 8 ; RETURN NIL ; ENDIF
   IF nEnc == 0 .AND. nBits == hb_BLen( cPay ) * 8
      oPay := Ppl_FromBytes( cPay )
   ELSEIF nEnc == 1
      oPay := Ppl_FromBits( cPay, nBits )
   ELSE
      RETURN NIL
   ENDIF
   nCount := Pxr_U32( r ) ; IF nCount == NIL .OR. nCount > 1000000 ; RETURN NIL ; ENDIF
   FOR i := 1 TO nCount
      cSub := Pxr_String( r ) ; IF cSub == NIL ; RETURN NIL ; ENDIF
      nCode := Pxr_I32( r ) ; IF nCode == NIL ; RETURN NIL ; ENDIF
      nTag := Pxr_Byte( r ) ; IF nTag == NIL ; RETURN NIL ; ENDIF
      DO CASE
      CASE nTag == 0 ; x := Pxr_String( r )
      CASE nTag == 1 ; x := Pxr_Byte( r ) ; IF x != NIL ; x := ( x != 0 ) ; ENDIF
      CASE nTag == 2 ; x := Pxr_Byte( r )
      CASE nTag == 3 ; x := Pxr_I16( r )
      CASE nTag == 4 ; x := Pxr_I32( r )
      CASE nTag == 5 ; x := Pxr_I64( r )
      CASE nTag == 6 ; x := Pxr_F64( r )
      CASE nTag == 7 ; x := Pxr_U64( r )
      CASE nTag == 8 ; x := Pxr_Bytes( r )
      OTHERWISE ; RETURN NIL
      ENDCASE
      IF x == NIL ; RETURN NIL ; ENDIF
      hVal := Spv_Value( aKinds[ nTag + 1 ], x )
      AAdd( aProps, Spv_New( cSub, nCode, hVal ) )
   NEXT
   IF r[ "position" ] != hb_BLen( r[ "data" ] ) ; RETURN NIL ; ENDIF
RETURN hb_Hash( "dxf_name", cDxf, "cpp_class_name", cCpp, "properties", aProps, "payload", oPay )
