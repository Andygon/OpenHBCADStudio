/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_wipeout.prg
   Origen Rust: opencadcodec/src/entities/wipeout.rs (771, 22 tests) + translate_wipeout + transform_wipeout. Licencia del original: MPL-2.0.
   Prefijo Ewp_. Flags = enteros WDF_*; clip_type = WCT_* (1 rect, 2 poligono); clip_mode = WCM_* (0 fuera, 1 dentro). Vector2 = {x,y}.
   Option<Handle> = NIL. size es Vector2. SUBCLASS_MARKER "AcDbRasterImage".
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Ewp_EntityName() ; RETURN "WIPEOUT"
FUNCTION Ewp_SubclassMarker() ; RETURN "AcDbRasterImage"
FUNCTION Wct_From( n ) ; RETURN iif( n == 1 .OR. n == 2, n, 1 )
FUNCTION Wcm_From( n ) ; RETURN iif( n == 1, 1, 0 )

FUNCTION Ewp_New()
RETURN hb_Hash( "_type", "WIPEOUT", "common", Ec_New(), "class_version", 0, "insertion_point", Vc3_Zero(), "u_vector", Vc3_UnitX(), "v_vector", Vc3_UnitY(), "size", Vc2_New( 1.0, 1.0 ), ;
   "flags", WDF_DEFAULT, "clipping_enabled", .T., "brightness", 50, "contrast", 50, "fade", 0, "clip_mode", WCM_OUTSIDE, "clip_type", WCT_RECTANGULAR, ;
   "clip_boundary_vertices", { Vc2_New( -0.5, -0.5 ), Vc2_New( 0.5, 0.5 ) }, "definition_handle", NIL, "definition_reactor_handle", NIL )
FUNCTION Ewp_Rectangular( vIns, nW, nH )
   LOCAL e := Ewp_New()
   e[ "insertion_point" ] := vIns ; e[ "u_vector" ] := Vc3_New( nW, 0.0, 0.0 ) ; e[ "v_vector" ] := Vc3_New( 0.0, nH, 0.0 )
   e[ "size" ] := Vc2_New( 1.0, 1.0 ) ; e[ "clip_type" ] := WCT_RECTANGULAR ; e[ "clip_boundary_vertices" ] := { Vc2_New( -0.5, -0.5 ), Vc2_New( 0.5, 0.5 ) }
RETURN e
FUNCTION Ewp_FromCorners( c1, c2 )
   LOCAL nMinX := Min( c1[ 1 ], c2[ 1 ] ), nMinY := Min( c1[ 2 ], c2[ 2 ] ), nMaxX := Max( c1[ 1 ], c2[ 1 ] ), nMaxY := Max( c1[ 2 ], c2[ 2 ] )
RETURN Ewp_Rectangular( Vc3_New( nMinX, nMinY, c1[ 3 ] ), nMaxX - nMinX, nMaxY - nMinY )
FUNCTION Ewp_Polygonal( aVerts, nZ )
   LOCAL e, nMinX, nMinY, nMaxX, nMaxY, nW, nH, aN := {}, i, v
   IF Len( aVerts ) < 3 ; RETURN Ewp_New() ; ENDIF
   nMinX := aVerts[ 1 ][ 1 ] ; nMinY := aVerts[ 1 ][ 2 ] ; nMaxX := nMinX ; nMaxY := nMinY
   FOR i := 2 TO Len( aVerts )
      v := aVerts[ i ]
      nMinX := Min( nMinX, v[ 1 ] ) ; nMinY := Min( nMinY, v[ 2 ] ) ; nMaxX := Max( nMaxX, v[ 1 ] ) ; nMaxY := Max( nMaxY, v[ 2 ] )
   NEXT
   nW := nMaxX - nMinX ; nH := nMaxY - nMinY
   FOR EACH v IN aVerts
      AAdd( aN, Vc2_New( iif( nW > 0.0, ( v[ 1 ] - nMinX ) / nW - 0.5, 0.0 ), iif( nH > 0.0, 0.5 - ( v[ 2 ] - nMinY ) / nH, 0.0 ) ) )
   NEXT
   e := Ewp_New()
   e[ "insertion_point" ] := Vc3_New( nMinX, nMinY, nZ ) ; e[ "u_vector" ] := Vc3_New( nW, 0.0, 0.0 ) ; e[ "v_vector" ] := Vc3_New( 0.0, nH, 0.0 )
   e[ "size" ] := Vc2_New( 1.0, 1.0 ) ; e[ "clip_type" ] := WCT_POLYGONAL ; e[ "clip_boundary_vertices" ] := aN
RETURN e
FUNCTION Ewp_SetRectangular( e, vLL, vUR ) ; e[ "clip_type" ] := WCT_RECTANGULAR ; e[ "clip_boundary_vertices" ] := { vLL, vUR } ; RETURN NIL
FUNCTION Ewp_SetPolygon( e, aVerts )
   IF Len( aVerts ) >= 3
      e[ "clip_type" ] := WCT_POLYGONAL ; e[ "clip_boundary_vertices" ] := AClone( aVerts )
   ENDIF
RETURN NIL
FUNCTION Ewp_WorldBoundaryVertices( e )
   LOCAL a := {}, v, s := e[ "size" ]
   FOR EACH v IN e[ "clip_boundary_vertices" ]
      AAdd( a, Vc3_Add( Vc3_Add( e[ "insertion_point" ], Vc3_Mul( e[ "u_vector" ], v[ 1 ] + s[ 1 ] * 0.5 ) ), Vc3_Mul( e[ "v_vector" ], s[ 2 ] * 0.5 - v[ 2 ] ) ) )
   NEXT
RETURN a
FUNCTION Ewp_Width( e ) ; RETURN Vc3_Length( e[ "u_vector" ] ) * Abs( e[ "size" ][ 1 ] )
FUNCTION Ewp_Height( e ) ; RETURN Vc3_Length( e[ "v_vector" ] ) * Abs( e[ "size" ][ 2 ] )
FUNCTION Ewp_Area( e )
   IF e[ "clip_type" ] == WCT_RECTANGULAR
      RETURN Vc3_Length( Vc3_Cross( e[ "u_vector" ], e[ "v_vector" ] ) ) * Abs( e[ "size" ][ 1 ] ) * Abs( e[ "size" ][ 2 ] )
   ENDIF
RETURN Ewp_PolygonArea( e )
STATIC FUNCTION Ewp_PolygonArea( e )
   LOCAL a := e[ "clip_boundary_vertices" ], nArea := 0.0, i, j, nL := Len( a )
   IF nL < 3 ; RETURN 0.0 ; ENDIF
   FOR i := 0 TO nL - 1
      j := ( i + 1 ) % nL
      nArea += a[ i + 1 ][ 1 ] * a[ j + 1 ][ 2 ]
      nArea -= a[ j + 1 ][ 1 ] * a[ i + 1 ][ 2 ]
   NEXT
RETURN Abs( nArea / 2.0 ) * Vc3_Length( Vc3_Cross( e[ "u_vector" ], e[ "v_vector" ] ) )
FUNCTION Ewp_SetSize( e, nW, nH )
   LOCAL vU := iif( Vc3_Length( e[ "u_vector" ] ) > 0.0000000001, Vc3_Normalize( e[ "u_vector" ] ), Vc3_UnitX() )
   LOCAL vV := iif( Vc3_Length( e[ "v_vector" ] ) > 0.0000000001, Vc3_Normalize( e[ "v_vector" ] ), Vc3_UnitY() )
   LOCAL nPw := Max( Abs( e[ "size" ][ 1 ] ), OCX_EPSILON() ), nPh := Max( Abs( e[ "size" ][ 2 ] ), OCX_EPSILON() )
   e[ "u_vector" ] := Vc3_Mul( vU, nW / nPw ) ; e[ "v_vector" ] := Vc3_Mul( vV, nH / nPh )
RETURN NIL
FUNCTION Ewp_Rotate( e, nAngle )
   LOCAL nC := OCX_COS( nAngle ), nS := OCX_SIN( nAngle ), u := e[ "u_vector" ], v := e[ "v_vector" ]
   e[ "u_vector" ] := Vc3_New( u[ 1 ] * nC - u[ 2 ] * nS, u[ 1 ] * nS + u[ 2 ] * nC, u[ 3 ] )
   e[ "v_vector" ] := Vc3_New( v[ 1 ] * nC - v[ 2 ] * nS, v[ 1 ] * nS + v[ 2 ] * nC, v[ 3 ] )
RETURN NIL
FUNCTION Ewp_Scale( e, nF ) ; e[ "u_vector" ] := Vc3_Mul( e[ "u_vector" ], nF ) ; e[ "v_vector" ] := Vc3_Mul( e[ "v_vector" ], nF ) ; RETURN NIL
FUNCTION Ewp_IsRectangular( e ) ; RETURN e[ "clip_type" ] == WCT_RECTANGULAR
FUNCTION Ewp_IsPolygonal( e ) ; RETURN e[ "clip_type" ] == WCT_POLYGONAL
FUNCTION Ewp_VertexCount( e ) ; RETURN Len( e[ "clip_boundary_vertices" ] )
FUNCTION Ewp_SetFrameVisible( e, l ) ; e[ "flags" ] := iif( l, hb_bitOr( e[ "flags" ], WDF_SHOW_IMAGE ), hb_bitAnd( e[ "flags" ], hb_bitNot( WDF_SHOW_IMAGE ) ) ) ; RETURN NIL
FUNCTION Ewp_IsFrameVisible( e ) ; RETURN hb_bitAnd( e[ "flags" ], WDF_SHOW_IMAGE ) == WDF_SHOW_IMAGE
FUNCTION Ewp_Center( e )
RETURN Vc3_Add( Vc3_Add( e[ "insertion_point" ], Vc3_Mul( e[ "u_vector" ], e[ "size" ][ 1 ] * 0.5 ) ), Vc3_Mul( e[ "v_vector" ], e[ "size" ][ 2 ] * 0.5 ) )
FUNCTION Ewp_Corners( e )
   LOCAL u := Vc3_Mul( e[ "u_vector" ], e[ "size" ][ 1 ] ), v := Vc3_Mul( e[ "v_vector" ], e[ "size" ][ 2 ] ), p := e[ "insertion_point" ]
RETURN { p, Vc3_Add( p, u ), Vc3_Add( Vc3_Add( p, u ), v ), Vc3_Add( p, v ) }
FUNCTION Ewp_ContainsPoint( e, vPt )
   LOCAL vLocal := Vc3_Sub( vPt, e[ "insertion_point" ] ), u := e[ "u_vector" ], v := e[ "v_vector" ]
   LOCAL nUu := Vc3_Dot( u, u ), nUv := Vc3_Dot( u, v ), nVv := Vc3_Dot( v, v ), nDet := nUu * nVv - nUv * nUv, nLu, nLv, nU, nV, vCp, vMn, vMx, s := e[ "size" ]
   IF ! OCX_ISFINITE( nDet ) .OR. Abs( nDet ) <= OCX_EPSILON() * OCX_POW( Max( nUu, nVv ), 2.0 ) ; RETURN .F. ; ENDIF
   nLu := Vc3_Dot( vLocal, u ) ; nLv := Vc3_Dot( vLocal, v )
   nU := ( nLu * nVv - nLv * nUv ) / nDet ; nV := ( nLv * nUu - nLu * nUv ) / nDet
   vCp := Vc2_New( nU - s[ 1 ] * 0.5, s[ 2 ] * 0.5 - nV )
   IF e[ "clip_type" ] == WCT_RECTANGULAR
      vMn := e[ "clip_boundary_vertices" ][ 1 ] ; vMx := e[ "clip_boundary_vertices" ][ 2 ]
      RETURN vCp[ 1 ] >= Min( vMn[ 1 ], vMx[ 1 ] ) .AND. vCp[ 1 ] <= Max( vMn[ 1 ], vMx[ 1 ] ) .AND. vCp[ 2 ] >= Min( vMn[ 2 ], vMx[ 2 ] ) .AND. vCp[ 2 ] <= Max( vMn[ 2 ], vMx[ 2 ] )
   ENDIF
RETURN Ewp_PointInPolygon( e, vCp )
STATIC FUNCTION Ewp_PointInPolygon( e, vP )
   LOCAL a := e[ "clip_boundary_vertices" ], lIn := .F., j, i, nL := Len( a )
   IF nL < 3 ; RETURN .F. ; ENDIF
   j := nL - 1
   FOR i := 0 TO nL - 1
      IF ( a[ i + 1 ][ 2 ] > vP[ 2 ] ) != ( a[ j + 1 ][ 2 ] > vP[ 2 ] ) .AND. ;
         vP[ 1 ] < ( a[ j + 1 ][ 1 ] - a[ i + 1 ][ 1 ] ) * ( vP[ 2 ] - a[ i + 1 ][ 2 ] ) / ( a[ j + 1 ][ 2 ] - a[ i + 1 ][ 2 ] ) + a[ i + 1 ][ 1 ]
         lIn := ! lIn
      ENDIF
      j := i
   NEXT
RETURN lIn
FUNCTION Ewp_BoundingBox( e )
   LOCAL a := Ewp_Corners( e ), vMin := AClone( a[ 1 ] ), vMax := AClone( a[ 1 ] ), i, c
   FOR i := 2 TO 4
      c := a[ i ]
      vMin := { Min( vMin[ 1 ], c[ 1 ] ), Min( vMin[ 2 ], c[ 2 ] ), Min( vMin[ 3 ], c[ 3 ] ) }
      vMax := { Max( vMax[ 1 ], c[ 1 ] ), Max( vMax[ 2 ], c[ 2 ] ), Max( vMax[ 3 ], c[ 3 ] ) }
   NEXT
RETURN Bb3_New( vMin, vMax )
FUNCTION Ewp_Translate( e, vOff ) ; e[ "insertion_point" ] := Vc3_Add( e[ "insertion_point" ], vOff ) ; RETURN NIL
FUNCTION Ewp_Transform( e, t )
   e[ "insertion_point" ] := Tf_Apply( t, e[ "insertion_point" ] )
   e[ "u_vector" ] := Tf_ApplyRotation( t, e[ "u_vector" ] )
   e[ "v_vector" ] := Tf_ApplyRotation( t, e[ "v_vector" ] )
RETURN NIL
