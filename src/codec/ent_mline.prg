/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_mline.prg
   Origen Rust: opencadcodec/src/entities/mline.rs (1121, 28 tests) + translate_mline + transform_mline. Licencia del original: MPL-2.0.
   Prefijos: Mle_ (MLineStyleElement), Mls_ (MLineStyle), Mlg_ (MLineSegment), Mlv_ (MLineVertex), Eml_ (MLine), Mlb_ (MLineBuilder), Mlj_ (justification).
   Flags = enteros (MLF_* / MLS_* en ocx.ch). Justification = entero (0 Top, 1 Zero, 2 Bottom). Option<Handle> = NIL.
   Indices de la API en base 0 como en Rust. Mlb_ es un hash {"mline"}; cada metodo devuelve el mismo builder (encadenable).
   Rust: add_vertex devuelve &mut vertex: aqui el hash del vertice (referencia). sort_elements: insercion estable (sort_by es estable).
----------------------------------------------------------------------------*/
#include "ocx.ch"

#define EPS2  0.00000000000000000001   /* GEOMETRY_EPSILON_SQUARED = 1.0e-20 */

FUNCTION Mlj_From( n ) ; RETURN iif( n == 0 .OR. n == 1 .OR. n == 2, n, 1 )

/* ---- MLineStyleElement ---- */
FUNCTION Mle_New( nOffset ) ; RETURN hb_Hash( "offset", nOffset, "color", Cl_ByLayer(), "line_type_handle", NIL, "line_type_name", "ByLayer" )
FUNCTION Mle_WithColor( nOffset, aColor ) ; LOCAL e := Mle_New( nOffset ) ; e[ "color" ] := aColor ; RETURN e

/* ---- MLineStyle ---- */
FUNCTION Mls_New( cName )
RETURN hb_Hash( "handle", Hd_Null(), "name", cName, "description", "", "flags", MLS_NONE, "fill_color", Cl_ByLayer(), "start_angle", OCX_PI / 2.0, "end_angle", OCX_PI / 2.0, "elements", {} )
FUNCTION Mls_Standard()
   LOCAL s := Mls_New( "Standard" )
   Mls_AddElement( s, Mle_New( 0.5 ) ) ; Mls_AddElement( s, Mle_New( -0.5 ) )
RETURN s
FUNCTION Mls_AddElement( s, e ) ; AAdd( s[ "elements" ], e ) ; RETURN NIL
FUNCTION Mls_AddElementWithOffset( s, nOff )
   LOCAL e := Mle_New( nOff )
   AAdd( s[ "elements" ], e )
RETURN e
FUNCTION Mls_ElementCount( s ) ; RETURN Len( s[ "elements" ] )
FUNCTION Mls_TotalWidth( s )
   LOCAL nMin := OCX_INF(), nMax := - OCX_INF(), e
   IF Len( s[ "elements" ] ) == 0 ; RETURN 0.0 ; ENDIF
   FOR EACH e IN s[ "elements" ]
      nMin := Min( nMin, e[ "offset" ] )
      nMax := Max( nMax, e[ "offset" ] )
   NEXT
RETURN nMax - nMin
FUNCTION Mls_SetFillOn( s, l ) ; s[ "flags" ] := iif( l, hb_bitOr( s[ "flags" ], MLS_FILL_ON ), hb_bitAnd( s[ "flags" ], hb_bitNot( MLS_FILL_ON ) ) ) ; RETURN NIL
FUNCTION Mls_IsFillOn( s ) ; RETURN hb_bitAnd( s[ "flags" ], MLS_FILL_ON ) == MLS_FILL_ON
FUNCTION Mls_SetDisplayJoints( s, l ) ; s[ "flags" ] := iif( l, hb_bitOr( s[ "flags" ], MLS_DISPLAY_JOINTS ), hb_bitAnd( s[ "flags" ], hb_bitNot( MLS_DISPLAY_JOINTS ) ) ) ; RETURN NIL
FUNCTION Mls_DisplaysJoints( s ) ; RETURN hb_bitAnd( s[ "flags" ], MLS_DISPLAY_JOINTS ) == MLS_DISPLAY_JOINTS
FUNCTION Mls_SortElements( s )
   LOCAL a := s[ "elements" ], i, j, x
   FOR i := 2 TO Len( a )
      x := a[ i ] ; j := i - 1
      DO WHILE j >= 1 .AND. a[ j ][ "offset" ] > x[ "offset" ]
         a[ j + 1 ] := a[ j ] ; j--
      ENDDO
      a[ j + 1 ] := x
   NEXT
RETURN NIL

/* ---- MLineSegment ---- */
FUNCTION Mlg_New() ; RETURN hb_Hash( "parameters", {}, "area_fill_parameters", {} )
FUNCTION Mlg_AddParameter( g, n ) ; AAdd( g[ "parameters" ], n ) ; RETURN NIL
FUNCTION Mlg_AddAreaFillParameter( g, n ) ; AAdd( g[ "area_fill_parameters" ], n ) ; RETURN NIL

/* ---- MLineVertex ---- */
FUNCTION Mlv_New( vPos ) ; RETURN hb_Hash( "position", vPos, "direction", Vc3_New( 1.0, 0.0, 0.0 ), "miter", Vc3_New( 0.0, 1.0, 0.0 ), "segments", {} )
FUNCTION Mlv_WithDirection( vPos, vDir )
RETURN hb_Hash( "position", vPos, "direction", Vc3_Normalize( vDir ), "miter", Vc3_Normalize( Vc3_New( - vDir[ 2 ], vDir[ 1 ], 0.0 ) ), "segments", {} )
FUNCTION Mlv_AddSegment( v, g ) ; AAdd( v[ "segments" ], g ) ; RETURN NIL
FUNCTION Mlv_InitSegments( v, nCount )
   LOCAL i
   v[ "segments" ] := {}
   FOR i := 1 TO nCount ; AAdd( v[ "segments" ], Mlg_New() ) ; NEXT
RETURN NIL

/* ---- MLine ---- */
FUNCTION Eml_EntityName() ; RETURN "MLINE"

FUNCTION Eml_New()
RETURN hb_Hash( "_type", "MLINE", "common", Ec_New(), "flags", MLF_HAS_VERTICES, "justification", 1, "normal", Vc3_New( 0.0, 0.0, 1.0 ), "scale_factor", 1.0, ;
   "start_point", Vc3_Zero(), "style_handle", NIL, "style_name", "Standard", "style_element_count", 2, "vertices", {} )
FUNCTION Eml_FromPoints( aPts )
   LOCAL m := Eml_New(), p
   FOR EACH p IN aPts ; Eml_AddVertex( m, p ) ; NEXT
RETURN m
FUNCTION Eml_ClosedFromPoints( aPts ) ; LOCAL m := Eml_FromPoints( aPts ) ; Eml_Close( m ) ; RETURN m
FUNCTION Eml_AddVertex( m, vPos )
   LOCAL nL := Len( m[ "vertices" ] ), v
   IF nL > 0 .AND. Vc3_LengthSquared( Vc3_Sub( vPos, m[ "vertices" ][ nL ][ "position" ] ) ) <= EPS2
      RETURN m[ "vertices" ][ nL ]
   ENDIF
   v := Mlv_New( vPos ) ; Mlv_InitSegments( v, m[ "style_element_count" ] )
   AAdd( m[ "vertices" ], v )
   Eml_RebuildGeometry( m )
RETURN v

STATIC FUNCTION DirAfter( aPos, nCount, nIdx, lClosed )   // nIdx base 0; NIL = None
   LOCAL nAtt := iif( lClosed, nCount - 1, Max( nCount - ( nIdx + 1 ), 0 ) ), nStep, nNext, vD
   FOR nStep := 1 TO nAtt
      nNext := iif( lClosed, ( nIdx + nStep ) % nCount, nIdx + nStep )
      vD := Vc3_Sub( aPos[ nNext + 1 ], aPos[ nIdx + 1 ] )
      IF Vc3_LengthSquared( vD ) > EPS2 ; RETURN Vc3_Normalize( vD ) ; ENDIF
   NEXT
RETURN NIL
STATIC FUNCTION DirBefore( aPos, nCount, nIdx, lClosed )
   LOCAL nAtt := iif( lClosed, nCount - 1, nIdx ), nStep, nPrev, vD
   FOR nStep := 1 TO nAtt
      nPrev := iif( lClosed, ( nIdx + nCount - ( nStep % nCount ) ) % nCount, nIdx - nStep )
      vD := Vc3_Sub( aPos[ nIdx + 1 ], aPos[ nPrev + 1 ] )
      IF Vc3_LengthSquared( vD ) > EPS2 ; RETURN Vc3_Normalize( vD ) ; ENDIF
   NEXT
RETURN NIL

FUNCTION Eml_RebuildGeometry( m )
   LOCAL nCount := Len( m[ "vertices" ] ), aPos := {}, v, lClosed, vN, nIdx, vBef, vAft, vDir, vBn, vAn, vMit, vSum
   m[ "flags" ] := iif( nCount > 0, hb_bitOr( m[ "flags" ], MLF_HAS_VERTICES ), hb_bitAnd( m[ "flags" ], hb_bitNot( MLF_HAS_VERTICES ) ) )
   IF nCount == 0 ; m[ "start_point" ] := Vc3_Zero() ; RETURN NIL ; ENDIF
   m[ "start_point" ] := m[ "vertices" ][ 1 ][ "position" ]
   FOR EACH v IN m[ "vertices" ] ; AAdd( aPos, v[ "position" ] ) ; NEXT
   lClosed := Eml_IsClosed( m ) .AND. nCount >= 3
   vN := iif( Vc3_LengthSquared( m[ "normal" ] ) > EPS2, Vc3_Normalize( m[ "normal" ] ), Vc3_UnitZ() )
   FOR nIdx := 0 TO nCount - 1
      vBef := DirBefore( aPos, nCount, nIdx, lClosed )
      vAft := DirAfter( aPos, nCount, nIdx, lClosed )
      vDir := iif( vAft != NIL, vAft, iif( vBef != NIL, vBef, Vc3_UnitX() ) )
      vBn := iif( vBef != NIL, Vc3_Normalize( Vc3_Cross( vN, vBef ) ), NIL )
      vAn := iif( vAft != NIL, Vc3_Normalize( Vc3_Cross( vN, vAft ) ), NIL )
      DO CASE
      CASE vBn != NIL .AND. vAn != NIL
         vSum := Vc3_Add( vBn, vAn )
         vMit := iif( Vc3_LengthSquared( vSum ) > EPS2, Vc3_Normalize( vSum ), vAn )
      CASE vBn != NIL ; vMit := vBn
      CASE vAn != NIL ; vMit := vAn
      OTHERWISE ; vMit := Vc3_UnitY()
      ENDCASE
      m[ "vertices" ][ nIdx + 1 ][ "direction" ] := vDir
      m[ "vertices" ][ nIdx + 1 ][ "miter" ] := vMit
   NEXT
RETURN NIL

FUNCTION Eml_SerializedFlags( m )
RETURN hb_bitOr( hb_bitAnd( m[ "flags" ], hb_bitNot( MLF_HAS_VERTICES ) ), iif( Len( m[ "vertices" ] ) == 0, 0, MLF_HAS_VERTICES ) )
FUNCTION Eml_SetVertexPosition( m, nIdx, vPos )
   IF nIdx < 0 .OR. nIdx >= Len( m[ "vertices" ] ) ; RETURN .F. ; ENDIF
   m[ "vertices" ][ nIdx + 1 ][ "position" ] := vPos ; Eml_RebuildGeometry( m )
RETURN .T.
FUNCTION Eml_InsertVertex( m, nIdx, vPos )
   LOCAL v
   IF nIdx > Len( m[ "vertices" ] ) ; RETURN .F. ; ENDIF
   v := Mlv_New( vPos ) ; Mlv_InitSegments( v, m[ "style_element_count" ] )
   ASize( m[ "vertices" ], Len( m[ "vertices" ] ) + 1 ) ; AIns( m[ "vertices" ], nIdx + 1 ) ; m[ "vertices" ][ nIdx + 1 ] := v
   Eml_RebuildGeometry( m )
RETURN .T.
FUNCTION Eml_RemoveVertex( m, nIdx )
   IF Len( m[ "vertices" ] ) <= 2 .OR. nIdx >= Len( m[ "vertices" ] ) ; RETURN .F. ; ENDIF
   ADel( m[ "vertices" ], nIdx + 1 ) ; ASize( m[ "vertices" ], Len( m[ "vertices" ] ) - 1 )
   Eml_RebuildGeometry( m )
RETURN .T.
FUNCTION Eml_Close( m ) ; m[ "flags" ] := hb_bitOr( m[ "flags" ], MLF_CLOSED ) ; Eml_RebuildGeometry( m ) ; RETURN NIL
FUNCTION Eml_Open( m ) ; m[ "flags" ] := hb_bitAnd( m[ "flags" ], hb_bitNot( MLF_CLOSED ) ) ; Eml_RebuildGeometry( m ) ; RETURN NIL
FUNCTION Eml_IsClosed( m ) ; RETURN hb_bitAnd( m[ "flags" ], MLF_CLOSED ) == MLF_CLOSED
FUNCTION Eml_SuppressStartCaps( m ) ; m[ "flags" ] := hb_bitOr( m[ "flags" ], MLF_NO_START_CAPS ) ; RETURN NIL
FUNCTION Eml_SuppressEndCaps( m ) ; m[ "flags" ] := hb_bitOr( m[ "flags" ], MLF_NO_END_CAPS ) ; RETURN NIL
FUNCTION Eml_VertexCount( m ) ; RETURN Len( m[ "vertices" ] )
FUNCTION Eml_Positions( m )
   LOCAL a := {}, v
   FOR EACH v IN m[ "vertices" ] ; AAdd( a, v[ "position" ] ) ; NEXT
RETURN a
FUNCTION Eml_Length( m )
   LOCAL a := m[ "vertices" ], nTot := 0.0, i, nL := Len( m[ "vertices" ] )
   IF nL < 2 ; RETURN 0.0 ; ENDIF
   FOR i := 1 TO nL - 1 ; nTot += Vc3_Length( Vc3_Sub( a[ i + 1 ][ "position" ], a[ i ][ "position" ] ) ) ; NEXT
   IF Eml_IsClosed( m ) ; nTot += Vc3_Length( Vc3_Sub( a[ 1 ][ "position" ], a[ nL ][ "position" ] ) ) ; ENDIF
RETURN nTot
FUNCTION Eml_Translate( m, vOff )
   LOCAL v
   m[ "start_point" ] := Vc3_Add( m[ "start_point" ], vOff )
   FOR EACH v IN m[ "vertices" ] ; v[ "position" ] := Vc3_Add( v[ "position" ], vOff ) ; NEXT
RETURN NIL
/* Option<(min,max)>: NIL si no hay vertices */
FUNCTION Eml_BoundingBoxOpt( m )
   LOCAL i, p, vMin, vMax
   IF Len( m[ "vertices" ] ) == 0 ; RETURN NIL ; ENDIF
   vMin := AClone( m[ "vertices" ][ 1 ][ "position" ] ) ; vMax := AClone( vMin )
   FOR i := 2 TO Len( m[ "vertices" ] )
      p := m[ "vertices" ][ i ][ "position" ]
      vMin := { Min( vMin[ 1 ], p[ 1 ] ), Min( vMin[ 2 ], p[ 2 ] ), Min( vMin[ 3 ], p[ 3 ] ) }
      vMax := { Max( vMax[ 1 ], p[ 1 ] ), Max( vMax[ 2 ], p[ 2 ] ), Max( vMax[ 3 ], p[ 3 ] ) }
   NEXT
RETURN { vMin, vMax }
FUNCTION Eml_BoundingBox( m )
   LOCAL b := Eml_BoundingBoxOpt( m )
   IF b == NIL ; RETURN Bb3_Default() ; ENDIF
RETURN Bb3_New( b[ 1 ], b[ 2 ] )
FUNCTION Eml_SetStyleElementCount( m, n ) ; m[ "style_element_count" ] := n ; RETURN NIL
FUNCTION Eml_Reverse( m )
   LOCAL a := m[ "vertices" ], i, x, nL := Len( a )
   FOR i := 1 TO Int( nL / 2 )
      x := a[ i ] ; a[ i ] := a[ nL - i + 1 ] ; a[ nL - i + 1 ] := x
   NEXT
   Eml_RebuildGeometry( m )
RETURN NIL
FUNCTION Eml_Transform( m, t )
   LOCAL v
   m[ "start_point" ] := Tf_Apply( t, m[ "start_point" ] )
   FOR EACH v IN m[ "vertices" ]
      v[ "position" ] := Tf_Apply( t, v[ "position" ] )
      v[ "direction" ] := Vc3_Normalize( Tf_ApplyRotation( t, v[ "direction" ] ) )
      v[ "miter" ] := Vc3_Normalize( Tf_ApplyRotation( t, v[ "miter" ] ) )
   NEXT
   m[ "normal" ] := Vc3_Normalize( Tf_ApplyRotation( t, m[ "normal" ] ) )
RETURN NIL

/* ---- MLineBuilder ---- */
FUNCTION Mlb_New() ; RETURN hb_Hash( "mline", Eml_New() )
FUNCTION Mlb_Vertex( b, vPos ) ; Eml_AddVertex( b[ "mline" ], vPos ) ; RETURN b
FUNCTION Mlb_Vertices( b, aPos )
   LOCAL p
   FOR EACH p IN aPos ; Eml_AddVertex( b[ "mline" ], p ) ; NEXT
RETURN b
FUNCTION Mlb_Scale( b, n ) ; b[ "mline" ][ "scale_factor" ] := n ; RETURN b
FUNCTION Mlb_Justification( b, n ) ; b[ "mline" ][ "justification" ] := n ; RETURN b
FUNCTION Mlb_StyleName( b, c ) ; b[ "mline" ][ "style_name" ] := c ; RETURN b
FUNCTION Mlb_Closed( b ) ; Eml_Close( b[ "mline" ] ) ; RETURN b
FUNCTION Mlb_NoStartCaps( b ) ; Eml_SuppressStartCaps( b[ "mline" ] ) ; RETURN b
FUNCTION Mlb_NoEndCaps( b ) ; Eml_SuppressEndCaps( b[ "mline" ] ) ; RETURN b
FUNCTION Mlb_Build( b ) ; RETURN b[ "mline" ]
