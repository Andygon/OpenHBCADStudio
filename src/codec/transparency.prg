/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/transparency.prg
   Origen Rust: opencadcodec/src/types/transparency.rs (194 lineas, 2 tests; el 3o es serde, no aplica)
   Transparency = { nKind, nAlpha } con TK_* (ocx.ch). Orden derivado de Rust: ByLayer < ByBlock < Explicit(alpha).
   Los valores empaquetados i32/u32 se manejan como enteros de 64 bits de Harbour.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Tp_ByLayer() ; RETURN { TK_BYLAYER, 0 }
FUNCTION Tp_ByBlock() ; RETURN { TK_BYBLOCK, 0 }
FUNCTION Tp_New( nAlpha ) ; RETURN { TK_EXPLICIT, nAlpha }
FUNCTION Tp_Opaque() ; RETURN Tp_New( 0 )
FUNCTION Tp_Transparent() ; RETURN Tp_New( 255 )
FUNCTION Tp_Default() ; RETURN Tp_ByLayer()
FUNCTION Tp_T( nPct )   // T_10 .. T_90
   LOCAL aV := { 26, 51, 77, 102, 128, 153, 179, 204, 230 }
RETURN Tp_New( aV[ Int( nPct / 10 ) ] )
FUNCTION Tp_Eq( a, b ) ; RETURN a[1] == b[1] .AND. a[2] == b[2]
// Ord derivado
FUNCTION Tp_Cmp( a, b )
   IF a[1] != b[1] ; RETURN IIf( a[1] < b[1], -1, 1 ) ; ENDIF
   IF a[2] != b[2] ; RETURN IIf( a[2] < b[2], -1, 1 ) ; ENDIF
RETURN 0

FUNCTION Tp_FromPercent( nPct )
RETURN Tp_New( Int( OCX_CEIL( Max( 0.0, Min( 1.0, nPct ) ) * 255.0 ) ) )

// from_alpha_value(u32)
FUNCTION Tp_FromAlphaValue( nValue )
   LOCAL nTop := hb_bitAnd( hb_bitShift( nValue, -24 ), 255 )
   DO CASE
   CASE nTop == 0 ; RETURN Tp_ByLayer()
   CASE nTop == 1 ; RETURN Tp_ByBlock()
   CASE nTop == 2 .OR. nTop == 3 ; RETURN Tp_New( 255 - hb_bitAnd( nValue, 255 ) )
   ENDCASE
RETURN Tp_ByLayer()

FUNCTION Tp_Alpha( t ) ; RETURN IIf( t[1] == TK_EXPLICIT, t[2], 0 )
FUNCTION Tp_ExplicitAlpha( t ) ; RETURN IIf( t[1] == TK_EXPLICIT, t[2], NIL )
FUNCTION Tp_AsPercent( t ) ; RETURN Tp_Alpha( t ) / 255.0
FUNCTION Tp_IsByLayer( t ) ; RETURN t[1] == TK_BYLAYER
FUNCTION Tp_IsByBlock( t ) ; RETURN t[1] == TK_BYBLOCK
FUNCTION Tp_IsExplicit( t ) ; RETURN t[1] == TK_EXPLICIT
FUNCTION Tp_IsOpaque( t ) ; RETURN t[1] == TK_EXPLICIT .AND. t[2] == 0
FUNCTION Tp_IsTransparent( t ) ; RETURN t[1] == TK_EXPLICIT .AND. t[2] == 255

FUNCTION Tp_ToAlphaValue( t )
   DO CASE
   CASE t[1] == TK_BYLAYER ; RETURN 0
   CASE t[1] == TK_BYBLOCK ; RETURN hb_bitShift( 1, 24 )
   ENDCASE
RETURN hb_bitOr( hb_bitShift( 3, 24 ), 255 - t[2] )

FUNCTION Tp_ToDxfValue( t )
   DO CASE
   CASE t[1] == TK_BYLAYER ; RETURN 0
   CASE t[1] == TK_BYBLOCK ; RETURN hb_bitShift( 1, 24 )
   ENDCASE
RETURN hb_bitOr( hb_bitShift( 2, 24 ), 255 - t[2] )

FUNCTION Tp_Display( t )
   DO CASE
   CASE t[1] == TK_BYLAYER ; RETURN "ByLayer"
   CASE t[1] == TK_BYBLOCK ; RETURN "ByBlock"
   ENDCASE
RETURN LTrim( Str( Tp_AsPercent( t ) * 100.0, 10, 1 ) ) + "%"
