/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/tb_ltype.prg
   Origen Rust: opencadcodec/src/tables/linetype.rs (492 lineas, 10 tests). Licencia del original: MPL-2.0.
   Prefijos: Lte_ (LineTypeElement), Ltc_ (LineTypeComplexData), Lty_ (LineType).
   LineTypeComplexContent = { nKind, xValue }: { LTC_SHAPE, nShapeNumber } o { LTC_TEXT, cText }. Option<Complex> -> NIL. char alignment -> cadena de 1 caracter.
   offset: [f64;2] -> array { x, y }. Los metodos pub(crate) (ensure_*, set_*, apply_dxf_flags) se portan con el mismo nombre.
----------------------------------------------------------------------------*/
#include "ocx.ch"

#define LTC_SHAPE 0
#define LTC_TEXT  1

FUNCTION Lte_Dash( n ) ; RETURN hb_Hash( "length", Abs( n ), "complex", NIL )
FUNCTION Lte_Space( n ) ; RETURN hb_Hash( "length", - Abs( n ), "complex", NIL )
FUNCTION Lte_Dot() ; RETURN hb_Hash( "length", 0.0, "complex", NIL )
FUNCTION Lte_IsDash( e ) ; RETURN e[ "length" ] > 0.0
FUNCTION Lte_IsSpace( e ) ; RETURN e[ "length" ] < 0.0
FUNCTION Lte_IsDot( e ) ; RETURN e[ "length" ] == 0.0

FUNCTION Ltc_Default()
RETURN hb_Hash( "content", { LTC_SHAPE, 0 }, "style_handle", Hd_Null(), "scale", 1.0, "rotation", 0.0, "absolute_rotation", .F., "offset", { 0.0, 0.0 } )
FUNCTION Ltc_IsShape( c ) ; RETURN c[ "content" ][ 1 ] == LTC_SHAPE
FUNCTION Ltc_IsText( c ) ; RETURN c[ "content" ][ 1 ] == LTC_TEXT
FUNCTION Ltc_IsAbsoluteRotation( c ) ; RETURN c[ "absolute_rotation" ]
FUNCTION Ltc_ShapeNumber( c ) ; RETURN iif( Ltc_IsShape( c ), c[ "content" ][ 2 ], NIL )
FUNCTION Ltc_Text( c ) ; RETURN iif( Ltc_IsText( c ), c[ "content" ][ 2 ], NIL )
FUNCTION Ltc_EnsureShape( c )
   IF ! Ltc_IsShape( c ) ; c[ "content" ] := { LTC_SHAPE, 0 } ; ENDIF
RETURN NIL
FUNCTION Ltc_EnsureText( c )
   IF ! Ltc_IsText( c ) ; c[ "content" ] := { LTC_TEXT, "" } ; ENDIF
RETURN NIL
FUNCTION Ltc_SetShapeNumber( c, n ) ; Ltc_EnsureShape( c ) ; c[ "content" ][ 2 ] := n ; RETURN NIL
FUNCTION Ltc_SetText( c, cText ) ; Ltc_EnsureText( c ) ; c[ "content" ][ 2 ] := cText ; RETURN NIL
FUNCTION Ltc_ApplyDxfFlags( c, nFlags )
   c[ "absolute_rotation" ] := hb_bitAnd( nFlags, 1 ) != 0
   IF hb_bitAnd( nFlags, 4 ) != 0
      Ltc_EnsureShape( c )
   ELSEIF hb_bitAnd( nFlags, 2 ) != 0
      Ltc_EnsureText( c )
   ENDIF
RETURN NIL

FUNCTION Lte_ComplexMut( e )
   IF e[ "complex" ] == NIL ; e[ "complex" ] := Ltc_Default() ; ENDIF
RETURN e[ "complex" ]
FUNCTION Lte_IsShape( e ) ; RETURN e[ "complex" ] != NIL .AND. Ltc_IsShape( e[ "complex" ] )
FUNCTION Lte_IsText( e ) ; RETURN e[ "complex" ] != NIL .AND. Ltc_IsText( e[ "complex" ] )
FUNCTION Lte_IsAbsoluteRotation( e ) ; RETURN e[ "complex" ] != NIL .AND. Ltc_IsAbsoluteRotation( e[ "complex" ] )
FUNCTION Lte_IsComplex( e ) ; RETURN e[ "complex" ] != NIL

FUNCTION Lty_New( cName )
RETURN hb_Hash( "handle", Hd_Null(), "name", cName, "description", "", "elements", {}, "pattern_length", 0.0, "alignment", "A", "xref_dependent", .F., "xref_block_record_handle", Hd_Null() )
FUNCTION Lty_Continuous() ; LOCAL l := Lty_New( "Continuous" ) ; l[ "description" ] := "Solid line" ; RETURN l
FUNCTION Lty_ByLayer() ; RETURN Lty_New( "ByLayer" )
FUNCTION Lty_ByBlock() ; RETURN Lty_New( "ByBlock" )
FUNCTION Lty_AddElement( l, e ) ; AAdd( l[ "elements" ], e ) ; RETURN NIL
FUNCTION Lty_Dashed()
   LOCAL l := Lty_New( "Dashed" )
   l[ "description" ] := "__ __ __ __ __ __" ; Lty_AddElement( l, Lte_Dash( 0.5 ) ) ; Lty_AddElement( l, Lte_Space( 0.25 ) ) ; l[ "pattern_length" ] := 0.75
RETURN l
FUNCTION Lty_Dotted()
   LOCAL l := Lty_New( "Dotted" )
   l[ "description" ] := ". . . . . . . ." ; Lty_AddElement( l, Lte_Dot() ) ; Lty_AddElement( l, Lte_Space( 0.25 ) ) ; l[ "pattern_length" ] := 0.25
RETURN l
FUNCTION Lty_ElementCount( l ) ; RETURN Len( l[ "elements" ] )
FUNCTION Lty_IsContinuous( l ) ; RETURN Len( l[ "elements" ] ) == 0
FUNCTION Lty_IsComplex( l )
   LOCAL e
   FOR EACH e IN l[ "elements" ]
      IF e[ "complex" ] != NIL ; RETURN .T. ; ENDIF
   NEXT
RETURN .F.
FUNCTION Lty_IsStandard( l ) ; RETURN l[ "name" ] == "Continuous" .OR. l[ "name" ] == "ByLayer" .OR. l[ "name" ] == "ByBlock"
