/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_leader.prg
   Origen Rust: opencadcodec/src/entities/leader.rs (620, 14 tests) + translate_leader + transform_leader. Licencia del original: MPL-2.0.
   Enums (LeaderPathType, LeaderCreationType, HooklineDirection) = enteros con from_value/to_value (valores como en Rust).
   Option<Vector3> -> vector o NIL. Prefijo: Eld_. Builders with_*: mutan y devuelven el mismo hash.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Lpt_FromValue( n ) ; RETURN iif( n == 1, 1, 0 )
FUNCTION Lct_FromValue( n ) ; RETURN iif( n >= 1 .AND. n <= 3, n, 0 )
FUNCTION Lhd_FromValue( n ) ; RETURN iif( n == 1, 1, 0 )

FUNCTION Eld_New()
RETURN hb_Hash( "_type", "LEADER", "common", Ec_New(), "dimension_style", "Standard", "arrow_enabled", .T., "path_type", LPT_STRAIGHT, "creation_type", LCT_WITHTEXT, ;
   "hookline_direction", 0, "hookline_enabled", .F., "text_height", 2.5, "text_width", 0.0, "vertices", {}, "override_color", Cl_ByLayer(), "annotation_handle", Hd_Null(), ;
   "normal", Vc3_UnitZ(), "horizontal_direction", Vc3_UnitX(), "block_offset", Vc3_Zero(), "annotation_offset", Vc3_Zero(), "origin", Vc3_Zero(), "dimension_gap", 0.0, ;
   "arrowhead_type", 0, "arrow_size", 0.0, "byblock_color", 0, "dwg_unknown_bit1", .F., "dwg_unknown_bit2", .F., "dwg_unknown_bit3", .F., "dwg_unknown_bit4", .F., ;
   "dwg_unknown_bit5", .F., "dwg_unknown_short1", 0 )
FUNCTION Eld_FromVertices( aV ) ; LOCAL e := Eld_New() ; e[ "vertices" ] := aV ; RETURN e
FUNCTION Eld_TwoPoint( vArrow, vEnd ) ; LOCAL e := Eld_New() ; AAdd( e[ "vertices" ], vArrow ) ; AAdd( e[ "vertices" ], vEnd ) ; RETURN e
FUNCTION Eld_WithLanding( vArrow, vBend, nLen )
   LOCAL e := Eld_New()
   AAdd( e[ "vertices" ], vArrow ) ; AAdd( e[ "vertices" ], vBend )
   AAdd( e[ "vertices" ], Vc3_New( vBend[ 1 ] + nLen, vBend[ 2 ], vBend[ 3 ] ) )
   e[ "hookline_enabled" ] := .T.
RETURN e
FUNCTION Eld_AddVertex( e, v ) ; AAdd( e[ "vertices" ], v ) ; RETURN NIL
/* nIndex base 0 como en Rust */
FUNCTION Eld_InsertVertex( e, nIndex, v )
   IF nIndex <= Len( e[ "vertices" ] ) ; hb_AIns( e[ "vertices" ], nIndex + 1, v, .T. ) ; ENDIF
RETURN NIL
FUNCTION Eld_RemoveVertex( e, nIndex )
   LOCAL v
   IF nIndex < Len( e[ "vertices" ] )
      v := e[ "vertices" ][ nIndex + 1 ] ; hb_ADel( e[ "vertices" ], nIndex + 1, .T. )
      RETURN v
   ENDIF
RETURN NIL
FUNCTION Eld_VertexCount( e ) ; RETURN Len( e[ "vertices" ] )
FUNCTION Eld_ArrowPoint( e ) ; RETURN iif( Len( e[ "vertices" ] ) > 0, e[ "vertices" ][ 1 ], NIL )
FUNCTION Eld_EndPoint( e ) ; RETURN iif( Len( e[ "vertices" ] ) > 0, ATail( e[ "vertices" ] ), NIL )
FUNCTION Eld_SetArrowPoint( e, v )
   IF Len( e[ "vertices" ] ) == 0 ; AAdd( e[ "vertices" ], v ) ; ELSE ; e[ "vertices" ][ 1 ] := v ; ENDIF
RETURN NIL
FUNCTION Eld_Length( e )
   LOCAL n := 0.0, i, a := e[ "vertices" ]
   IF Len( a ) < 2 ; RETURN 0.0 ; ENDIF
   FOR i := 1 TO Len( a ) - 1 ; n += Vc3_Distance( a[ i ], a[ i + 1 ] ) ; NEXT
RETURN n
FUNCTION Eld_ArrowDirection( e )
   LOCAL vD
   IF Len( e[ "vertices" ] ) < 2 ; RETURN NIL ; ENDIF
   vD := Vc3_Sub( e[ "vertices" ][ 2 ], e[ "vertices" ][ 1 ] )
RETURN iif( Vc3_LengthSquared( vD ) > 0.0, Vc3_Normalize( vD ), NIL )
FUNCTION Eld_SetPathType( e, n ) ; e[ "path_type" ] := n ; RETURN NIL
FUNCTION Eld_SetArrowEnabled( e, l ) ; e[ "arrow_enabled" ] := l ; RETURN NIL
FUNCTION Eld_SetHooklineEnabled( e, l ) ; e[ "hookline_enabled" ] := l ; RETURN NIL
FUNCTION Eld_SetDimensionStyle( e, c ) ; e[ "dimension_style" ] := c ; RETURN NIL
FUNCTION Eld_Reverse( e )
   LOCAL a := e[ "vertices" ], i, n := Len( a ), t
   FOR i := 1 TO Int( n / 2 ) ; t := a[ i ] ; a[ i ] := a[ n - i + 1 ] ; a[ n - i + 1 ] := t ; NEXT
RETURN NIL
FUNCTION Eld_Clear( e ) ; ASize( e[ "vertices" ], 0 ) ; RETURN NIL
FUNCTION Eld_WithVertex( e, v ) ; AAdd( e[ "vertices" ], v ) ; RETURN e
FUNCTION Eld_WithArrow( e, l ) ; e[ "arrow_enabled" ] := l ; RETURN e
FUNCTION Eld_WithSplinePath( e ) ; e[ "path_type" ] := LPT_SPLINE ; RETURN e
FUNCTION Eld_WithHookline( e ) ; e[ "hookline_enabled" ] := .T. ; RETURN e
FUNCTION Eld_WithDimensionStyle( e, c ) ; e[ "dimension_style" ] := c ; RETURN e
FUNCTION Eld_WithLayer( e, c ) ; e[ "common" ][ "layer" ] := c ; RETURN e
FUNCTION Eld_WithColor( e, c ) ; e[ "common" ][ "color" ] := c ; RETURN e
FUNCTION Eld_WithCreationType( e, n ) ; e[ "creation_type" ] := n ; RETURN e
FUNCTION Eld_WithAnnotation( e, h ) ; e[ "annotation_handle" ] := h ; RETURN e
FUNCTION Eld_BoundingBox( e )
   IF Len( e[ "vertices" ] ) == 0 ; RETURN Bb3_Default() ; ENDIF
RETURN Bb3_FromPoints( e[ "vertices" ] )
FUNCTION Eld_Translate( e, vOff )
   LOCAL i
   FOR i := 1 TO Len( e[ "vertices" ] ) ; e[ "vertices" ][ i ] := Vc3_Add( e[ "vertices" ][ i ], vOff ) ; NEXT
   e[ "block_offset" ] := Vc3_Add( e[ "block_offset" ], vOff )
   e[ "annotation_offset" ] := Vc3_Add( e[ "annotation_offset" ], vOff )
RETURN NIL
FUNCTION Eld_Transform( e, t )
   LOCAL i
   FOR i := 1 TO Len( e[ "vertices" ] ) ; e[ "vertices" ][ i ] := Tf_Apply( t, e[ "vertices" ][ i ] ) ; NEXT
   e[ "block_offset" ] := Tf_Apply( t, e[ "block_offset" ] )
   e[ "annotation_offset" ] := Tf_Apply( t, e[ "annotation_offset" ] )
   e[ "horizontal_direction" ] := Vc3_Normalize( Tf_ApplyRotation( t, e[ "horizontal_direction" ] ) )
   e[ "normal" ] := Vc3_Normalize( Tf_ApplyRotation( t, e[ "normal" ] ) )
RETURN NIL
