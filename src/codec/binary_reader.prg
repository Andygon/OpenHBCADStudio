/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/binary_reader.prg
   Origen Rust: opencadcodec/src/io/dxf/reader/binary_reader.rs (266 lineas; el original NO tiene
   tests, los de t_codec_binary.prg son todos [extra]). Licencia del original: MPL-2.0.
   Lector DXF binario sobre cadena en memoria. Reader = { cData, nPos(base 1), pPeek, lSingle, aCtx, cErr }.
   Cadenas no UTF-8: Rust usa from_utf8_lossy; aqui cada byte >127 de una cadena invalida pasa a U+FFFD
   (aproximacion: Rust conserva las secuencias validas dentro de la cadena).
   Errores: ReadPair devuelve NIL y deja BnR_Error(r) (NIL en EOF limpio).
----------------------------------------------------------------------------*/
#include "ocx.ch"

#define BN_DATA 1
#define BN_POS 2
#define BN_PEEK 3
#define BN_SINGLE 4
#define BN_CTX 5
#define BN_ERR 6

STATIC FUNCTION BnR_Sentinel() ; RETURN "AutoCAD Binary DXF" + Chr( 13 ) + Chr( 10 ) + Chr( 26 ) + Chr( 0 )

FUNCTION BnR_Error( r ) ; RETURN r[ BN_ERR ]
FUNCTION BnR_PushBack( r, p ) ; r[ BN_PEEK ] := p ; RETURN NIL
FUNCTION BnR_DiagnosticContext( r ) ; RETURN AClone( r[ BN_CTX ] )

/* new: NIL y cErr si el sentinel no es valido o faltan bytes */
FUNCTION BnR_New( cData, /*@*/ cErr )
   LOCAL nS := hb_BLen( BnR_Sentinel() ), b0, b1
   cErr := NIL
   IF hb_BLen( cData ) < nS ; cErr := "failed to fill whole buffer" ; RETURN NIL ; ENDIF
   IF hb_BLeft( cData, nS ) != BnR_Sentinel() ; cErr := "Parse error: Invalid binary DXF sentinel" ; RETURN NIL ; ENDIF
   IF hb_BLen( cData ) < nS + 2 ; cErr := "failed to fill whole buffer" ; RETURN NIL ; ENDIF
   b0 := hb_BCode( hb_BSubStr( cData, nS + 1, 1 ) ) ; b1 := hb_BCode( hb_BSubStr( cData, nS + 2, 1 ) )
RETURN { cData, nS + 1, NIL, b0 == 0 .AND. b1 >= 0x20 .AND. b1 < 0x7F, { NIL, NIL, NIL, NIL }, NIL }

FUNCTION BnR_Reset( r )
   LOCAL cErr
   LOCAL r2 := BnR_New( r[ BN_DATA ], @cErr )
   IF r2 == NIL ; r[ BN_ERR ] := cErr ; RETURN .F. ; ENDIF
   r[ BN_POS ] := r2[ BN_POS ] ; r[ BN_PEEK ] := NIL ; r[ BN_CTX ] := { NIL, NIL, NIL, NIL } ; r[ BN_ERR ] := NIL
RETURN .T.

/* read_exact(n): cadena de n bytes o NIL (avanza solo si hay n) */
STATIC FUNCTION BnR_Take( r, n )
   LOCAL c
   IF r[ BN_POS ] + n - 1 > hb_BLen( r[ BN_DATA ] ) ; RETURN NIL ; ENDIF
   c := hb_BSubStr( r[ BN_DATA ], r[ BN_POS ], n ) ; r[ BN_POS ] += n
RETURN c

STATIC FUNCTION BnR_Lossy( c )
   LOCAL i, cOut := ""
   IF hb_StrIsUTF8( c ) ; RETURN c ; ENDIF
   FOR i := 1 TO hb_BLen( c )
      IF hb_BCode( hb_BSubStr( c, i, 1 ) ) > 127 ; cOut += hb_UTF8Chr( 0xFFFD ) ; ELSE ; cOut += hb_BSubStr( c, i, 1 ) ; ENDIF
   NEXT
RETURN cOut

STATIC FUNCTION BnR_ReadZString( r )
   LOCAL nE := hb_BAt( Chr( 0 ), r[ BN_DATA ], r[ BN_POS ] ), c
   IF nE == 0
      c := hb_BSubStr( r[ BN_DATA ], r[ BN_POS ] ) ; r[ BN_POS ] := hb_BLen( r[ BN_DATA ] ) + 1
   ELSE
      c := hb_BSubStr( r[ BN_DATA ], r[ BN_POS ], nE - r[ BN_POS ] ) ; r[ BN_POS ] := nE + 1
   ENDIF
RETURN BnR_Lossy( c )

STATIC FUNCTION BnR_I64( c )
   LOCAL nLo := Bin2L( hb_BLeft( c, 4 ) ), nHi := Bin2L( hb_BSubStr( c, 5, 4 ) )
   IF nLo < 0 ; nLo += 4294967296 ; ENDIF
RETURN nHi * 4294967296 + nLo

STATIC FUNCTION BnR_ForCode( r, nCode )
   LOCAL nVt := Gv_FromRawCode( nCode ), c, v, i, cHex := ""
   DO CASE
   CASE nVt == GVT_DOUBLE
      c := BnR_Take( r, 8 ) ; IF c == NIL ; RETURN .F. ; ENDIF
      v := OCX_BIN2D( c ) ; RETURN Dp_NewTyped( nCode, F64_Ryu( v ), 2, v )
   CASE nVt == GVT_INT16 .OR. nVt == GVT_BYTE
      c := BnR_Take( r, 2 ) ; IF c == NIL ; RETURN .F. ; ENDIF
      v := Bin2I( c ) ; RETURN Dp_NewTyped( nCode, hb_ntos( v ), 1, v )
   CASE nVt == GVT_INT32
      c := BnR_Take( r, 4 ) ; IF c == NIL ; RETURN .F. ; ENDIF
      v := Bin2L( c ) ; RETURN Dp_NewTyped( nCode, hb_ntos( v ), 1, v )
   CASE nVt == GVT_INT64
      c := BnR_Take( r, 8 ) ; IF c == NIL ; RETURN .F. ; ENDIF
      v := BnR_I64( c ) ; RETURN Dp_NewTyped( nCode, hb_ntos( v ), 1, v )
   CASE nVt == GVT_BOOL
      c := BnR_Take( r, 1 ) ; IF c == NIL ; RETURN .F. ; ENDIF
      v := hb_BCode( c ) != 0 ; RETURN Dp_NewTyped( nCode, IIf( v, "1", "0" ), 3, v )
   CASE nVt == GVT_BINARYDATA
      c := BnR_Take( r, 1 ) ; IF c == NIL ; RETURN .F. ; ENDIF
      v := hb_BCode( c )
      IF v > 0
         c := BnR_Take( r, v ) ; IF c == NIL ; RETURN .F. ; ENDIF
         FOR i := 1 TO v
            cHex += hb_NumToHex( hb_BCode( hb_BSubStr( c, i, 1 ) ), 2 )
         NEXT
      ENDIF
      RETURN Dp_New( nCode, cHex )
   ENDCASE
RETURN Dp_New( nCode, BnR_ReadZString( r ) )   // String, Handle y resto

STATIC FUNCTION BnR_Observe( r, p, nOff )
   LOCAL x := r[ BN_CTX ]
   x[ 1 ] := nOff
   IF p[ 1 ] == 0
      x[ 3 ] := p[ 3 ] ; x[ 4 ] := NIL
   ELSEIF p[ 1 ] == 105 .OR. ( p[ 1 ] == 5 .AND. ! ( x[ 3 ] == "DIMSTYLE" ) )
      x[ 4 ] := Dp_AsHandle( p )
   ENDIF
RETURN NIL

STATIC FUNCTION BnR_ReadInternal( r )
   LOCAL nOff := r[ BN_POS ] - 1, x := r[ BN_CTX ], nCode, c, p
   x[ 1 ] := nOff ; x[ 2 ] := NIL
   IF r[ BN_SINGLE ]
      c := BnR_Take( r, 1 ) ; IF c == NIL ; RETURN NIL ; ENDIF
      nCode := hb_BCode( c )
      IF nCode == 255
         c := BnR_Take( r, 2 ) ; IF c == NIL ; r[ BN_ERR ] := "failed to fill whole buffer" ; RETURN NIL ; ENDIF
         nCode := Bin2I( c )
      ENDIF
   ELSE
      c := BnR_Take( r, 2 ) ; IF c == NIL ; RETURN NIL ; ENDIF
      nCode := Bin2I( c )
   ENDIF
   p := BnR_ForCode( r, nCode )
   IF ValType( p ) == "L" ; r[ BN_ERR ] := "failed to fill whole buffer" ; RETURN NIL ; ENDIF
   BnR_Observe( r, p, nOff )
RETURN p

FUNCTION BnR_ReadPair( r )
   LOCAL p
   r[ BN_ERR ] := NIL
   IF r[ BN_PEEK ] != NIL ; p := r[ BN_PEEK ] ; r[ BN_PEEK ] := NIL ; RETURN p ; ENDIF
RETURN BnR_ReadInternal( r )

FUNCTION BnR_PeekCode( r )
   LOCAL p
   r[ BN_ERR ] := NIL
   IF r[ BN_PEEK ] != NIL ; RETURN r[ BN_PEEK ][ 1 ] ; ENDIF
   p := BnR_ReadInternal( r )
   IF p == NIL ; RETURN NIL ; ENDIF
   r[ BN_PEEK ] := p
RETURN p[ 1 ]
