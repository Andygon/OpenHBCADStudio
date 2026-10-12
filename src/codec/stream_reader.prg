/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/stream_reader.prg
   Origen Rust: opencadcodec/src/io/dxf/reader/stream_reader.rs (DxfCodePair, PointReader;
   3 tests en t_codec_stream.prg). Licencia del original: MPL-2.0.
   DxfCodePair = { nCode, nDxfCode, cValue, nKind, xTyped }; nKind: 0 None, 1 Int, 2 Double, 3 Bool.
   Option -> NIL. PENDIENTE de este fichero: trait DxfStreamReader, XDataRecorder y
   DxfStreamContext (dependen del diseno de lectores; van con text/binary reader).
   Nota: Val() de Harbour puede diferir en 1 ulp del parse::<f64> de Rust en decimales largos.
----------------------------------------------------------------------------*/
#include "ocx.ch"

#define DP_CODE    1
#define DP_DXFCODE 2
#define DP_VALUE   3
#define DP_KIND    4
#define DP_TYPED   5
#define DPK_NONE   0
#define DPK_INT    1
#define DPK_DOUBLE 2
#define DPK_BOOL   3

/* str::parse::<i64>() sobre texto ya recortado: NIL si no valido o fuera de rango */
FUNCTION Dp_ParseI64( c )
   LOCAL cDig := c, lNeg := .F., i
   IF Len( c ) == 0 ; RETURN NIL ; ENDIF
   IF Left( c, 1 ) $ "+-"
      lNeg := ( Left( c, 1 ) == "-" ) ; cDig := SubStr( c, 2 )
   ENDIF
   IF Len( cDig ) == 0 ; RETURN NIL ; ENDIF
   FOR i := 1 TO Len( cDig )
      IF ! ( SubStr( cDig, i, 1 ) $ "0123456789" ) ; RETURN NIL ; ENDIF
   NEXT
   DO WHILE Len( cDig ) > 1 .AND. Left( cDig, 1 ) == "0" ; cDig := SubStr( cDig, 2 ) ; ENDDO
   IF Len( cDig ) > 19 ; RETURN NIL ; ENDIF
   IF Len( cDig ) == 19 .AND. cDig > IIf( lNeg, "9223372036854775808", "9223372036854775807" ) ; RETURN NIL ; ENDIF
RETURN IIf( lNeg, -Val( cDig ), Val( cDig ) )

/* str::parse::<f64>(): NIL si no valido */
FUNCTION Dp_ParseF64( c )
   LOCAL cL := Lower( c ), lNeg := .F., cM, cE, nE := 0, nP
   IF Len( cL ) == 0 ; RETURN NIL ; ENDIF
   IF Left( cL, 1 ) $ "+-"
      lNeg := ( Left( cL, 1 ) == "-" ) ; cL := SubStr( cL, 2 )
   ENDIF
   IF cL == "inf" .OR. cL == "infinity" ; RETURN IIf( lNeg, -OCX_INF(), OCX_INF() ) ; ENDIF
   IF cL == "nan" ; RETURN OCX_NAN() ; ENDIF
   IF ! hb_RegExLike( "^([0-9]+\.?[0-9]*|\.[0-9]+)(e[+-]?[0-9]+)?$", cL ) ; RETURN NIL ; ENDIF
   nP := At( "e", cL )
   IF nP > 0
      cM := Left( cL, nP - 1 ) ; cE := SubStr( cL, nP + 1 )
      nE := IIf( Left( cE, 1 ) == "+", Val( SubStr( cE, 2 ) ), Val( cE ) )
   ELSE
      cM := cL
   ENDIF
   cM := IIf( Right( cM, 1 ) == ".", cM + "0", cM )
   cM := IIf( Left( cM, 1 ) == ".", "0" + cM, cM )
RETURN IIf( lNeg, -1, 1 ) * IIf( nE == 0, Val( cM ), Val( cM ) * OCX_POW( 10.0, nE ) )

STATIC FUNCTION Dp_Mk( nCode, cValue, nKind, xTyped )
RETURN { nCode, Dxc_FromI32( nCode ), cValue, nKind, xTyped }

FUNCTION Dp_New( nCode, cValue )
   LOCAL nVt := Gv_FromRawCode( nCode ), xV, c := AllTrim( cValue )
   DO CASE
   CASE nVt == GVT_INT16 .OR. nVt == GVT_INT32 .OR. nVt == GVT_INT64 .OR. nVt == GVT_BYTE
      xV := Dp_ParseI64( c )
      RETURN IIf( xV == NIL, Dp_Mk( nCode, cValue, DPK_NONE, NIL ), Dp_Mk( nCode, cValue, DPK_INT, xV ) )
   CASE nVt == GVT_DOUBLE
      xV := Dp_ParseF64( c )
      RETURN IIf( xV == NIL, Dp_Mk( nCode, cValue, DPK_NONE, NIL ), Dp_Mk( nCode, cValue, DPK_DOUBLE, xV ) )
   CASE nVt == GVT_BOOL
      xV := Dp_ParseI64( c )  // parse::<i32>: fuera de rango i32 -> None
      IF xV != NIL .AND. ( xV < -2147483648 .OR. xV > 2147483647 ) ; xV := NIL ; ENDIF
      RETURN IIf( xV == NIL, Dp_Mk( nCode, cValue, DPK_NONE, NIL ), Dp_Mk( nCode, cValue, DPK_BOOL, xV != 0 ) )
   ENDCASE
RETURN Dp_Mk( nCode, cValue, DPK_NONE, NIL )

/* new_typed: valor ya calculado (lector binario) */
FUNCTION Dp_NewTyped( nCode, cValue, nKind, xTyped ) ; RETURN Dp_Mk( nCode, cValue, nKind, xTyped )

FUNCTION Dp_AsString( p ) ; RETURN p[ DP_VALUE ]
FUNCTION Dp_AsInt( p ) ; RETURN IIf( p[ DP_KIND ] == DPK_INT, p[ DP_TYPED ], NIL )
FUNCTION Dp_AsI16( p )
   IF p[ DP_KIND ] == DPK_INT ; RETURN IIf( p[ DP_TYPED ] >= -32768 .AND. p[ DP_TYPED ] <= 32767, p[ DP_TYPED ], NIL ) ; ENDIF
   IF p[ DP_KIND ] == DPK_BOOL ; RETURN IIf( p[ DP_TYPED ], 1, 0 ) ; ENDIF
RETURN NIL
FUNCTION Dp_AsI32( p )
   IF p[ DP_KIND ] == DPK_INT ; RETURN IIf( p[ DP_TYPED ] >= -2147483648 .AND. p[ DP_TYPED ] <= 2147483647, p[ DP_TYPED ], NIL ) ; ENDIF
   IF p[ DP_KIND ] == DPK_BOOL ; RETURN IIf( p[ DP_TYPED ], 1, 0 ) ; ENDIF
RETURN NIL
FUNCTION Dp_AsI32Bits( p )
   LOCAL v
   IF p[ DP_KIND ] != DPK_INT ; RETURN NIL ; ENDIF
   v := p[ DP_TYPED ]
   IF v >= -2147483648 .AND. v <= 2147483647 ; RETURN v ; ENDIF
   IF v >= 0 .AND. v <= 4294967295 ; RETURN v - 4294967296 ; ENDIF
RETURN NIL
FUNCTION Dp_AsDouble( p ) ; RETURN IIf( p[ DP_KIND ] == DPK_DOUBLE, p[ DP_TYPED ], NIL )
FUNCTION Dp_AsBool( p ) ; RETURN IIf( p[ DP_KIND ] == DPK_BOOL, p[ DP_TYPED ], NIL )
/* u64::from_str_radix(trim, 16) */
FUNCTION Dp_AsHandle( p )
   LOCAL c := AllTrim( p[ DP_VALUE ] ), i, nV := 0
   IF Left( c, 1 ) == "+" ; c := SubStr( c, 2 ) ; ENDIF
   IF Len( c ) == 0 .OR. Len( c ) > 16 ; RETURN NIL ; ENDIF
   FOR i := 1 TO Len( c )
      IF ! ( SubStr( c, i, 1 ) $ "0123456789abcdefABCDEF" ) ; RETURN NIL ; ENDIF
      nV := nV * 16 + hb_HexToNum( SubStr( c, i, 1 ) )
   NEXT
RETURN nV

/* PointReader = { x, y, z, group } (NIL = None) */
FUNCTION PR_New() ; RETURN { NIL, NIL, NIL, NIL }
FUNCTION PR_AddCoordinate( r, p )
   LOCAL nAxis := Gv_CoordinateAxis( p[ DP_CODE ] ), nGrp, nV
   IF nAxis != NIL
      nGrp := Gv_CoordinateGroup( p[ DP_CODE ] )
      IF r[ 4 ] != NIL .AND. r[ 4 ] != nGrp ; RETURN .F. ; ENDIF
      r[ 4 ] := nGrp
      nV := Dp_AsDouble( p )
      IF nV != NIL
         IF nAxis >= 0 .AND. nAxis <= 2 ; r[ nAxis + 1 ] := nV ; RETURN .T. ; ENDIF
         RETURN .F.
      ENDIF
   ENDIF
RETURN .F.
FUNCTION PR_IsComplete( r ) ; RETURN r[ 1 ] != NIL .AND. r[ 2 ] != NIL
FUNCTION PR_GetPoint( r ) ; RETURN IIf( r[ 1 ] != NIL .AND. r[ 2 ] != NIL, Vc3_New( r[ 1 ], r[ 2 ], IIf( r[ 3 ] == NIL, 0.0, r[ 3 ] ) ), NIL )
FUNCTION PR_Reset( r ) ; r[ 1 ] := r[ 2 ] := r[ 3 ] := r[ 4 ] := NIL ; RETURN NIL
