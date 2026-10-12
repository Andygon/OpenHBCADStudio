/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/obj_mlstyle.prg
   Origen Rust: opencadcodec/src/objects/mlinestyle.rs (538 lineas, 13 tests). Licencia del original: MPL-2.0.
   Prefijos: Mlsf_ (MLineStyleFlags), Mlse_ (MLineStyleElement), Mlsy_ (MLineStyle). Option -> NIL. Los builders with_* mutan y devuelven el mismo hash.
   width(): f64::MAX/MIN como valores iniciales se sustituyen por el primer elemento (mismo resultado con elementos finitos). sort_elements: insercion estable (sort_by de Rust es estable).
   to_radians / to_degrees usan x * (PI/180) y x * (180/PI) igual que f64.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Mlsf_New() ; RETURN hb_Hash( "fill_on", .F., "display_joints", .F., "start_square_cap", .F., "start_inner_arcs_cap", .F., "start_round_cap", .F., "end_square_cap", .F., "end_inner_arcs_cap", .F., "end_round_cap", .F. )
FUNCTION Mlsf_FromBits( n )
RETURN hb_Hash( "fill_on", hb_bitAnd( n, 1 ) != 0, "display_joints", hb_bitAnd( n, 2 ) != 0, "start_square_cap", hb_bitAnd( n, 16 ) != 0, "start_inner_arcs_cap", hb_bitAnd( n, 32 ) != 0, ;
   "start_round_cap", hb_bitAnd( n, 64 ) != 0, "end_square_cap", hb_bitAnd( n, 256 ) != 0, "end_inner_arcs_cap", hb_bitAnd( n, 512 ) != 0, "end_round_cap", hb_bitAnd( n, 1024 ) != 0 )
FUNCTION Mlsf_ToBits( f )
   LOCAL n := 0
   IF f[ "fill_on" ] ; n := hb_bitOr( n, 1 ) ; ENDIF
   IF f[ "display_joints" ] ; n := hb_bitOr( n, 2 ) ; ENDIF
   IF f[ "start_square_cap" ] ; n := hb_bitOr( n, 16 ) ; ENDIF
   IF f[ "start_inner_arcs_cap" ] ; n := hb_bitOr( n, 32 ) ; ENDIF
   IF f[ "start_round_cap" ] ; n := hb_bitOr( n, 64 ) ; ENDIF
   IF f[ "end_square_cap" ] ; n := hb_bitOr( n, 256 ) ; ENDIF
   IF f[ "end_inner_arcs_cap" ] ; n := hb_bitOr( n, 512 ) ; ENDIF
   IF f[ "end_round_cap" ] ; n := hb_bitOr( n, 1024 ) ; ENDIF
RETURN n
FUNCTION Mlsf_Simple() ; LOCAL f := Mlsf_New() ; f[ "start_square_cap" ] := .T. ; f[ "end_square_cap" ] := .T. ; RETURN f
FUNCTION Mlsf_RoundCaps() ; LOCAL f := Mlsf_New() ; f[ "start_round_cap" ] := .T. ; f[ "end_round_cap" ] := .T. ; RETURN f

FUNCTION Mlse_New( nOffset ) ; RETURN hb_Hash( "offset", nOffset, "color", Cl_ByLayer(), "linetype", "BYLAYER" )
FUNCTION Mlse_Default() ; RETURN Mlse_New( 0.0 )
FUNCTION Mlse_WithColor( nOffset, c ) ; LOCAL e := Mlse_New( nOffset ) ; e[ "color" ] := c ; RETURN e
FUNCTION Mlse_Full( nOffset, c, cLt ) ; RETURN hb_Hash( "offset", nOffset, "color", c, "linetype", cLt )
PROCEDURE Mlse_SetColor( e, c ) ; e[ "color" ] := c ; RETURN
PROCEDURE Mlse_SetLinetype( e, c ) ; e[ "linetype" ] := c ; RETURN
FUNCTION Mlse_Duplicate( e ) ; RETURN hb_HClone( e )

FUNCTION Mlsy_ObjectType() ; RETURN "MLINESTYLE"
FUNCTION Mlsy_DefaultName() ; RETURN "Standard"
FUNCTION Mlsy_New( cName )
RETURN hb_Hash( "_type", "MLineStyle", "handle", Hd_Null(), "owner", Hd_Null(), "name", cName, "description", "", "elements", {}, "start_angle", OCX_PI / 2.0, "end_angle", OCX_PI / 2.0, "fill_color", Cl_ByLayer(), "flags", Mlsf_New() )
FUNCTION Mlsy_Standard()
   LOCAL s := Mlsy_New( Mlsy_DefaultName() )
   Mlsy_AddElement( s, Mlse_New( 0.5 ) ) ; Mlsy_AddElement( s, Mlse_New( -0.5 ) )
RETURN s
FUNCTION Mlsy_Default() ; RETURN Mlsy_Standard()
PROCEDURE Mlsy_AddElement( s, e ) ; AAdd( s[ "elements" ], e ) ; RETURN
PROCEDURE Mlsy_AddElementAtOffset( s, n ) ; AAdd( s[ "elements" ], Mlse_New( n ) ) ; RETURN
PROCEDURE Mlsy_InsertElement( s, nIdx, e )
   IF nIdx <= Len( s[ "elements" ] ) ; hb_AIns( s[ "elements" ], nIdx + 1, e, .T. ) ; ENDIF
RETURN
FUNCTION Mlsy_RemoveElement( s, nIdx )
   LOCAL e
   IF nIdx >= 0 .AND. nIdx < Len( s[ "elements" ] )
      e := s[ "elements" ][ nIdx + 1 ] ; hb_ADel( s[ "elements" ], nIdx + 1, .T. )
      RETURN e
   ENDIF
RETURN NIL
FUNCTION Mlsy_ElementCount( s ) ; RETURN Len( s[ "elements" ] )
FUNCTION Mlsy_IsEmpty( s ) ; RETURN Len( s[ "elements" ] ) == 0
FUNCTION Mlsy_GetElement( s, nIdx ) ; RETURN iif( nIdx >= 0 .AND. nIdx < Len( s[ "elements" ] ), s[ "elements" ][ nIdx + 1 ], NIL )
FUNCTION Mlsy_Width( s )
   LOCAL e, nMin, nMax, l := .T.
   IF Len( s[ "elements" ] ) == 0 ; RETURN 0.0 ; ENDIF
   FOR EACH e IN s[ "elements" ]
      IF l ; nMin := e[ "offset" ] ; nMax := e[ "offset" ] ; l := .F. ; ENDIF
      IF e[ "offset" ] < nMin ; nMin := e[ "offset" ] ; ENDIF
      IF e[ "offset" ] > nMax ; nMax := e[ "offset" ] ; ENDIF
   NEXT
RETURN nMax - nMin
PROCEDURE Mlsy_SortElements( s )
   LOCAL a := s[ "elements" ], i, j, x
   FOR i := 2 TO Len( a )
      x := a[ i ] ; j := i - 1
      DO WHILE j >= 1 .AND. a[ j ][ "offset" ] > x[ "offset" ]
         a[ j + 1 ] := a[ j ] ; j--
      ENDDO
      a[ j + 1 ] := x
   NEXT
RETURN
PROCEDURE Mlsy_SetStartAngleDegrees( s, n ) ; s[ "start_angle" ] := n * ( OCX_PI / 180.0 ) ; RETURN
PROCEDURE Mlsy_SetEndAngleDegrees( s, n ) ; s[ "end_angle" ] := n * ( OCX_PI / 180.0 ) ; RETURN
FUNCTION Mlsy_StartAngleDegrees( s ) ; RETURN s[ "start_angle" ] * ( 180.0 / OCX_PI )
FUNCTION Mlsy_EndAngleDegrees( s ) ; RETURN s[ "end_angle" ] * ( 180.0 / OCX_PI )
PROCEDURE Mlsy_EnableFill( s, c ) ; s[ "flags" ][ "fill_on" ] := .T. ; s[ "fill_color" ] := c ; RETURN
PROCEDURE Mlsy_DisableFill( s ) ; s[ "flags" ][ "fill_on" ] := .F. ; RETURN
PROCEDURE Mlsy_SetRoundCaps( s )
   s[ "flags" ][ "start_round_cap" ] := .T. ; s[ "flags" ][ "end_round_cap" ] := .T. ; s[ "flags" ][ "start_square_cap" ] := .F. ; s[ "flags" ][ "end_square_cap" ] := .F.
RETURN
PROCEDURE Mlsy_SetSquareCaps( s )
   s[ "flags" ][ "start_square_cap" ] := .T. ; s[ "flags" ][ "end_square_cap" ] := .T. ; s[ "flags" ][ "start_round_cap" ] := .F. ; s[ "flags" ][ "end_round_cap" ] := .F.
RETURN
FUNCTION Mlsy_WithDescription( s, c ) ; s[ "description" ] := c ; RETURN s
FUNCTION Mlsy_WithElement( s, e ) ; Mlsy_AddElement( s, e ) ; RETURN s
FUNCTION Mlsy_WithFill( s, c ) ; Mlsy_EnableFill( s, c ) ; RETURN s
FUNCTION Mlsy_WithFlags( s, f ) ; s[ "flags" ] := f ; RETURN s
