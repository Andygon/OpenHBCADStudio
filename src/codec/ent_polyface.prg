/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_polyface.prg
   Origen Rust: opencadcodec/src/entities/polyface_mesh.rs (1034 lineas, 17 tests en t_codec_polyface.prg) + translate/transform_polyface_mesh + mirror_polyface_mesh. Licencia del original: MPL-2.0.
   Prefijos: Pfv_ (PolyfaceVertex), Pff_ (PolyfaceFace), Epf_ (PolyfaceMesh, _type "POLYFACE_MESH", entity_type "POLYLINE").
   Flags: se reutilizan PF_* y VF_* de ocx.ch (mismos valores: PolyfaceMeshFlags=PF_*, PolyfaceVertexFlags: POLYFACE_MESH=VF_POLYFACE_FACE=128). PolyfaceSmoothType = SST_* (Sst_From).
   Indices 1-based como en Rust (Epf_Vertex(e,idx) devuelve NIL si idx<=0 o fuera de rango). Option -> NIL.
   Nota: el original calcula areas de triangulos con el producto vectorial a mano; se reproduce igual.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Pfv_New( v ) ; RETURN hb_Hash( "common", Ec_New(), "location", v, "flags", VF_POLYFACE_FACE, "bulge", 0.0, "start_width", 0.0, "end_width", 0.0, "curve_tangent", 0.0, "id", 0 )
FUNCTION Pfv_FromXyz( x, y, z ) ; RETURN Pfv_New( Vc3_New( x, y, z ) )

FUNCTION Pff_Quad( a, b, c, d ) ; RETURN hb_Hash( "common", Ec_New(), "flags", 0, "index1", a, "index2", b, "index3", c, "index4", d, "color", NIL )
FUNCTION Pff_Triangle( a, b, c ) ; RETURN Pff_Quad( a, b, c, 0 )
FUNCTION Pff_TriangleWithVisibility( a, b, c, l1, l2, l3 ) ; RETURN Pff_Quad( iif( l1, -a, a ), iif( l2, -b, b ), iif( l3, -c, c ), 0 )
FUNCTION Pff_Default() ; RETURN Pff_Triangle( 1, 2, 3 )
FUNCTION Pff_IsTriangle( f ) ; RETURN f[ "index4" ] == 0 .OR. Abs( f[ "index4" ] ) == Abs( f[ "index3" ] )
FUNCTION Pff_IsQuad( f ) ; RETURN f[ "index4" ] != 0 .AND. Abs( f[ "index4" ] ) != Abs( f[ "index3" ] )
FUNCTION Pff_VertexCount( f ) ; RETURN iif( Pff_IsTriangle( f ), 3, 4 )
FUNCTION Pff_VertexIndices( f )
   LOCAL a := { Abs( f[ "index1" ] ), Abs( f[ "index2" ] ), Abs( f[ "index3" ] ) }
   IF Pff_IsQuad( f ) ; AAdd( a, Abs( f[ "index4" ] ) ) ; ENDIF
RETURN a
FUNCTION Pff_IsEdge1Invisible( f ) ; RETURN f[ "index1" ] < 0
FUNCTION Pff_IsEdge2Invisible( f ) ; RETURN f[ "index2" ] < 0
FUNCTION Pff_IsEdge3Invisible( f ) ; RETURN f[ "index3" ] < 0
FUNCTION Pff_IsEdge4Invisible( f ) ; RETURN f[ "index4" ] < 0
FUNCTION Pff_SetEdgeVisibility( f, nEdge, lVisible )
   LOCAL c
   IF nEdge < 0 .OR. nEdge > 3 ; RETURN NIL ; ENDIF
   c := "index" + hb_ntos( nEdge + 1 )
   f[ c ] := iif( lVisible, Abs( f[ c ] ), - Abs( f[ c ] ) )
RETURN NIL
FUNCTION Pff_Reverse( f )
   LOCAL t
   IF Pff_IsTriangle( f )
      t := f[ "index1" ] ; f[ "index1" ] := f[ "index3" ] ; f[ "index3" ] := t
   ELSE
      t := f[ "index1" ] ; f[ "index1" ] := f[ "index4" ] ; f[ "index4" ] := t
      t := f[ "index2" ] ; f[ "index2" ] := f[ "index3" ] ; f[ "index3" ] := t
   ENDIF
RETURN NIL

FUNCTION Epf_New()
RETURN hb_Hash( "_type", "POLYFACE_MESH", "common", Ec_New(), "elevation", 0.0, "flags", PF_POLYFACE_MESH, "normal", Vc3_UnitZ(), "start_width", 0.0, "end_width", 0.0, ;
   "smooth_surface", SST_NONE, "thickness", 0.0, "vertices", {}, "faces", {}, "seqend_handle", NIL )
FUNCTION Epf_FromData( aVerts, aFaces ) ; LOCAL e := Epf_New() ; e[ "vertices" ] := aVerts ; e[ "faces" ] := aFaces ; RETURN e
FUNCTION Epf_AddVertex( e, v ) ; AAdd( e[ "vertices" ], v ) ; RETURN Len( e[ "vertices" ] )
FUNCTION Epf_AddVertexXyz( e, x, y, z ) ; RETURN Epf_AddVertex( e, Pfv_FromXyz( x, y, z ) )
FUNCTION Epf_AddFace( e, f ) ; AAdd( e[ "faces" ], f ) ; RETURN NIL
FUNCTION Epf_AddTriangle( e, a, b, c ) ; Epf_AddFace( e, Pff_Triangle( a, b, c ) ) ; RETURN NIL
FUNCTION Epf_AddQuad( e, a, b, c, d ) ; Epf_AddFace( e, Pff_Quad( a, b, c, d ) ) ; RETURN NIL
FUNCTION Epf_VertexCount( e ) ; RETURN Len( e[ "vertices" ] )
FUNCTION Epf_FaceCount( e ) ; RETURN Len( e[ "faces" ] )
FUNCTION Epf_Vertex( e, n ) ; RETURN iif( n > 0 .AND. n <= Len( e[ "vertices" ] ), e[ "vertices" ][ n ], NIL )
FUNCTION Epf_FaceVertices( e, f )
   LOCAL a := {}, n, v
   FOR EACH n IN Pff_VertexIndices( f )
      v := Epf_Vertex( e, n )
      IF v != NIL ; AAdd( a, v[ "location" ] ) ; ENDIF
   NEXT
RETURN a
STATIC FUNCTION Epf_TriArea( p0, p1, p2 )
   LOCAL e1 := Vc3_Sub( p1, p0 ), e2 := Vc3_Sub( p2, p0 )
   LOCAL c := Vc3_New( e1[ 2 ] * e2[ 3 ] - e1[ 3 ] * e2[ 2 ], e1[ 3 ] * e2[ 1 ] - e1[ 1 ] * e2[ 3 ], e1[ 1 ] * e2[ 2 ] - e1[ 2 ] * e2[ 1 ] )
RETURN Vc3_Length( c ) / 2.0
FUNCTION Epf_FaceNormal( e, f )
   LOCAL v := Epf_FaceVertices( e, f ), e1, e2, n, nLen
   IF Len( v ) < 3 ; RETURN NIL ; ENDIF
   e1 := Vc3_Sub( v[ 2 ], v[ 1 ] ) ; e2 := Vc3_Sub( v[ 3 ], v[ 1 ] )
   n := Vc3_New( e1[ 2 ] * e2[ 3 ] - e1[ 3 ] * e2[ 2 ], e1[ 3 ] * e2[ 1 ] - e1[ 1 ] * e2[ 3 ], e1[ 1 ] * e2[ 2 ] - e1[ 2 ] * e2[ 1 ] )
   nLen := Vc3_Length( n )
RETURN iif( nLen > 0.0000000001, Vc3_Div( n, nLen ), NIL )
FUNCTION Epf_FaceArea( e, f )
   LOCAL v := Epf_FaceVertices( e, f )
   IF Len( v ) < 3 ; RETURN 0.0 ; ENDIF
   IF Pff_IsTriangle( f ) ; RETURN Epf_TriArea( v[ 1 ], v[ 2 ], v[ 3 ] ) ; ENDIF
   /* un cuadrilatero con menos de 4 vertices validos haria panic en Rust (indice); aqui se asume validez */
RETURN Epf_TriArea( v[ 1 ], v[ 2 ], v[ 3 ] ) + Epf_TriArea( v[ 1 ], v[ 3 ], v[ 4 ] )
FUNCTION Epf_TotalArea( e )
   LOCAL n := 0.0, f
   FOR EACH f IN e[ "faces" ] ; n += Epf_FaceArea( e, f ) ; NEXT
RETURN n
FUNCTION Epf_FlipNormals( e )
   LOCAL f
   FOR EACH f IN e[ "faces" ] ; Pff_Reverse( f ) ; NEXT
RETURN NIL
FUNCTION Epf_Validate( e )
   LOCAL nMax := Len( e[ "vertices" ] ), f, i
   FOR EACH f IN e[ "faces" ]
      FOR EACH i IN Pff_VertexIndices( f )
         IF i < 1 .OR. i > nMax ; RETURN .F. ; ENDIF
      NEXT
   NEXT
RETURN .T.
FUNCTION Epf_CreateBox( a, b )
   LOCAL m := Epf_New()
   Epf_AddVertexXyz( m, a[ 1 ], a[ 2 ], a[ 3 ] ) ; Epf_AddVertexXyz( m, b[ 1 ], a[ 2 ], a[ 3 ] ) ; Epf_AddVertexXyz( m, b[ 1 ], b[ 2 ], a[ 3 ] ) ; Epf_AddVertexXyz( m, a[ 1 ], b[ 2 ], a[ 3 ] )
   Epf_AddVertexXyz( m, a[ 1 ], a[ 2 ], b[ 3 ] ) ; Epf_AddVertexXyz( m, b[ 1 ], a[ 2 ], b[ 3 ] ) ; Epf_AddVertexXyz( m, b[ 1 ], b[ 2 ], b[ 3 ] ) ; Epf_AddVertexXyz( m, a[ 1 ], b[ 2 ], b[ 3 ] )
   Epf_AddQuad( m, 4, 3, 2, 1 ) ; Epf_AddQuad( m, 5, 6, 7, 8 ) ; Epf_AddQuad( m, 1, 2, 6, 5 ) ; Epf_AddQuad( m, 3, 4, 8, 7 ) ; Epf_AddQuad( m, 2, 3, 7, 6 ) ; Epf_AddQuad( m, 4, 1, 5, 8 )
RETURN m
FUNCTION Epf_CreatePyramid( c, nSize, nHeight )
   LOCAL m := Epf_New(), h := nSize / 2.0
   Epf_AddVertexXyz( m, c[ 1 ] - h, c[ 2 ] - h, c[ 3 ] ) ; Epf_AddVertexXyz( m, c[ 1 ] + h, c[ 2 ] - h, c[ 3 ] ) ; Epf_AddVertexXyz( m, c[ 1 ] + h, c[ 2 ] + h, c[ 3 ] ) ; Epf_AddVertexXyz( m, c[ 1 ] - h, c[ 2 ] + h, c[ 3 ] )
   Epf_AddVertexXyz( m, c[ 1 ], c[ 2 ], c[ 3 ] + nHeight )
   Epf_AddQuad( m, 1, 2, 3, 4 ) ; Epf_AddTriangle( m, 1, 2, 5 ) ; Epf_AddTriangle( m, 2, 3, 5 ) ; Epf_AddTriangle( m, 3, 4, 5 ) ; Epf_AddTriangle( m, 4, 1, 5 )
RETURN m
FUNCTION Epf_Triangulate( e )
   LOCAL aN := {}, f
   FOR EACH f IN e[ "faces" ]
      IF Pff_IsQuad( f )
         AAdd( aN, Pff_Triangle( f[ "index1" ], f[ "index2" ], f[ "index3" ] ) )
         AAdd( aN, Pff_Triangle( f[ "index1" ], f[ "index3" ], f[ "index4" ] ) )
      ELSE
         AAdd( aN, hb_HClone( f ) )
      ENDIF
   NEXT
   e[ "faces" ] := aN
RETURN NIL
FUNCTION Epf_TriangleCount( e )
   LOCAL n := 0, f
   FOR EACH f IN e[ "faces" ]
      IF Pff_IsTriangle( f )
         n++
      ENDIF
   NEXT
RETURN n
FUNCTION Epf_QuadCount( e )
   LOCAL n := 0, f
   FOR EACH f IN e[ "faces" ]
      IF Pff_IsQuad( f )
         n++
      ENDIF
   NEXT
RETURN n
FUNCTION Epf_BoundingBox( e )
   LOCAL a := {}, v
   IF Len( e[ "vertices" ] ) == 0 ; RETURN Bb3_Default() ; ENDIF
   FOR EACH v IN e[ "vertices" ] ; AAdd( a, v[ "location" ] ) ; NEXT
RETURN Bb3_FromPoints( a )
FUNCTION Epf_Translate( e, vOff )
   LOCAL v
   FOR EACH v IN e[ "vertices" ] ; v[ "location" ] := Vc3_Add( v[ "location" ], vOff ) ; NEXT
RETURN NIL
FUNCTION Epf_Transform( e, t )
   LOCAL v
   FOR EACH v IN e[ "vertices" ] ; v[ "location" ] := Tf_Apply( t, v[ "location" ] ) ; NEXT
   e[ "normal" ] := Vc3_Normalize( Tf_ApplyRotation( t, e[ "normal" ] ) )
RETURN NIL
FUNCTION Epf_Mirror( e, t )
   Epf_Transform( e, t ) ; Epf_FlipNormals( e )
RETURN NIL
