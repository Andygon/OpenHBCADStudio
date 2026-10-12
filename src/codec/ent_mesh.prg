/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_mesh.prg
   Origen Rust: opencadcodec/src/entities/mesh.rs (1053 lineas, 21 tests en t_codec_mesh.prg) + translate_mesh + transform_mesh + mirror_mesh. Licencia del original: MPL-2.0.
   Prefijos: Mge_ (MeshEdge hash start/end/crease, crease NIL = None), Mfc_ (MeshFace hash "vertices"), Emh_ (Mesh, _type "MESH"), Mbd_ (MeshBuilder: hash {"mesh"}, encadenable).
   Indices base 0 como en Rust (los arrays de Harbour se acceden con +1). Option<usize>/Option<Vector3> = NIL.
   Rust compute_edges usa un HashSet (orden de iteracion no determinista); aqui el orden es el de primera aparicion (cualquier orden es valido en Rust).
   Rust bounding_box (Option) = Emh_BoundingBoxOpt (NIL si vacio); el del trait = Emh_BoundingBox (Bb3_Default si vacio).
   Rust create_cylinder usa angle.cos()/sin(): OCX_COS/OCX_SIN. Mirror = transformar y invertir las caras.
----------------------------------------------------------------------------*/
#include "ocx.ch"

/* ---- MeshEdge ---- */
FUNCTION Mge_New( nS, nE ) ; RETURN hb_Hash( "start", nS, "end", nE, "crease", NIL )
FUNCTION Mge_WithCrease( nS, nE, nC ) ; RETURN hb_Hash( "start", nS, "end", nE, "crease", nC )
FUNCTION Mge_Default() ; RETURN Mge_New( 0, 0 )
FUNCTION Mge_HasCrease( g ) ; RETURN g[ "crease" ] != NIL
FUNCTION Mge_CreaseValue( g ) ; RETURN iif( g[ "crease" ] == NIL, 0.0, g[ "crease" ] )
FUNCTION Mge_SetCrease( g, n ) ; g[ "crease" ] := n ; RETURN NIL
FUNCTION Mge_ClearCrease( g ) ; g[ "crease" ] := NIL ; RETURN NIL
FUNCTION Mge_Connects( g, v1, v2 ) ; RETURN ( g[ "start" ] == v1 .AND. g[ "end" ] == v2 ) .OR. ( g[ "start" ] == v2 .AND. g[ "end" ] == v1 )
FUNCTION Mge_OtherVertex( g, v )
   IF g[ "start" ] == v ; RETURN g[ "end" ] ; ENDIF
   IF g[ "end" ] == v ; RETURN g[ "start" ] ; ENDIF
RETURN NIL

/* ---- MeshFace ---- */
FUNCTION Mfc_New( aV ) ; RETURN hb_Hash( "vertices", aV )
FUNCTION Mfc_Triangle( v0, v1, v2 ) ; RETURN Mfc_New( { v0, v1, v2 } )
FUNCTION Mfc_Quad( v0, v1, v2, v3 ) ; RETURN Mfc_New( { v0, v1, v2, v3 } )
FUNCTION Mfc_VertexCount( f ) ; RETURN Len( f[ "vertices" ] )
FUNCTION Mfc_IsTriangle( f ) ; RETURN Len( f[ "vertices" ] ) == 3
FUNCTION Mfc_IsQuad( f ) ; RETURN Len( f[ "vertices" ] ) == 4
FUNCTION Mfc_Indices( f ) ; RETURN f[ "vertices" ]
/* edges(): array de { a, b } */
FUNCTION Mfc_Edges( f )
   LOCAL a := {}, n := Len( f[ "vertices" ] ), i
   FOR i := 1 TO n
      AAdd( a, { f[ "vertices" ][ i ], f[ "vertices" ][ iif( i == n, 1, i + 1 ) ] } )
   NEXT
RETURN a
FUNCTION Mfc_Reverse( f ) ; f[ "vertices" ] := ARev( f[ "vertices" ] ) ; RETURN NIL
FUNCTION Mfc_Reversed( f ) ; RETURN Mfc_New( ARev( AClone( f[ "vertices" ] ) ) )

STATIC FUNCTION ARev( a )
   LOCAL r := {}, i
   FOR i := Len( a ) TO 1 STEP -1 ; AAdd( r, a[ i ] ) ; NEXT
RETURN r

/* ---- Mesh ---- */
FUNCTION Emh_New()
RETURN hb_Hash( "_type", "MESH", "common", Ec_New(), "version", 2, "blend_crease", .T., "subdivision_level", 0, "vertices", {}, "faces", {}, "edges", {}, "override_option", 0 )
FUNCTION Emh_EntityName() ; RETURN "MESH"
FUNCTION Emh_FromTriangles( aVerts, aTris )
   LOCAL m := Emh_New(), t
   m[ "vertices" ] := aVerts
   FOR EACH t IN aTris ; AAdd( m[ "faces" ], Mfc_Triangle( t[ 1 ], t[ 2 ], t[ 3 ] ) ) ; NEXT
   Emh_ComputeEdges( m )
RETURN m
FUNCTION Emh_FromQuads( aVerts, aQuads )
   LOCAL m := Emh_New(), t
   m[ "vertices" ] := aVerts
   FOR EACH t IN aQuads ; AAdd( m[ "faces" ], Mfc_Quad( t[ 1 ], t[ 2 ], t[ 3 ], t[ 4 ] ) ) ; NEXT
   Emh_ComputeEdges( m )
RETURN m
FUNCTION Emh_AddVertex( m, v ) ; AAdd( m[ "vertices" ], v ) ; RETURN Len( m[ "vertices" ] ) - 1
FUNCTION Emh_AddVertices( m, aV )
   LOCAL n := Len( m[ "vertices" ] ), v
   FOR EACH v IN aV ; AAdd( m[ "vertices" ], v ) ; NEXT
RETURN n
FUNCTION Emh_AddFace( m, f ) ; AAdd( m[ "faces" ], f ) ; RETURN NIL
FUNCTION Emh_AddTriangle( m, v0, v1, v2 ) ; AAdd( m[ "faces" ], Mfc_Triangle( v0, v1, v2 ) ) ; RETURN NIL
FUNCTION Emh_AddQuad( m, v0, v1, v2, v3 ) ; AAdd( m[ "faces" ], Mfc_Quad( v0, v1, v2, v3 ) ) ; RETURN NIL
FUNCTION Emh_AddEdge( m, g ) ; AAdd( m[ "edges" ], g ) ; RETURN NIL
FUNCTION Emh_AddEdgeBetween( m, nS, nE ) ; AAdd( m[ "edges" ], Mge_New( nS, nE ) ) ; RETURN Len( m[ "edges" ] ) - 1
FUNCTION Emh_AddCreasedEdge( m, nS, nE, nC ) ; AAdd( m[ "edges" ], Mge_WithCrease( nS, nE, nC ) ) ; RETURN Len( m[ "edges" ] ) - 1
FUNCTION Emh_ComputeEdges( m )
   LOCAL h := hb_Hash(), f, p, a, b, k
   m[ "edges" ] := {}
   FOR EACH f IN m[ "faces" ]
      FOR EACH p IN Mfc_Edges( f )
         a := Min( p[ 1 ], p[ 2 ] ) ; b := Max( p[ 1 ], p[ 2 ] ) ; k := hb_NToS( a ) + "," + hb_NToS( b )
         IF ! k $ h ; h[ k ] := .T. ; AAdd( m[ "edges" ], Mge_New( a, b ) ) ; ENDIF
      NEXT
   NEXT
RETURN NIL
FUNCTION Emh_VertexCount( m ) ; RETURN Len( m[ "vertices" ] )
FUNCTION Emh_FaceCount( m ) ; RETURN Len( m[ "faces" ] )
FUNCTION Emh_EdgeCount( m ) ; RETURN Len( m[ "edges" ] )
FUNCTION Emh_TriangleCount( m )
   LOCAL n := 0, f
   FOR EACH f IN m[ "faces" ] ; n += iif( Mfc_VertexCount( f ) < 3, 0, Mfc_VertexCount( f ) - 2 ) ; NEXT
RETURN n
FUNCTION Emh_IsAllTriangles( m )
   LOCAL f
   FOR EACH f IN m[ "faces" ]
      IF ! Mfc_IsTriangle( f )
         RETURN .F.
      ENDIF
   NEXT
RETURN .T.
FUNCTION Emh_IsAllQuads( m )
   LOCAL f
   FOR EACH f IN m[ "faces" ]
      IF ! Mfc_IsQuad( f )
         RETURN .F.
      ENDIF
   NEXT
RETURN .T.
/* find_edge: indice (base 0) o NIL */
FUNCTION Emh_FindEdge( m, v1, v2 )
   LOCAL i
   FOR i := 1 TO Len( m[ "edges" ] )
      IF Mge_Connects( m[ "edges" ][ i ], v1, v2 ) ; RETURN i - 1 ; ENDIF
   NEXT
RETURN NIL
FUNCTION Emh_Vertex( m, n ) ; RETURN iif( n >= 0 .AND. n < Len( m[ "vertices" ] ), m[ "vertices" ][ n + 1 ], NIL )
FUNCTION Emh_Face( m, n ) ; RETURN iif( n >= 0 .AND. n < Len( m[ "faces" ] ), m[ "faces" ][ n + 1 ], NIL )
FUNCTION Emh_Edge( m, n ) ; RETURN iif( n >= 0 .AND. n < Len( m[ "edges" ] ), m[ "edges" ][ n + 1 ], NIL )
FUNCTION Emh_SetEdgeCrease( m, n, nC )
   IF n >= 0 .AND. n < Len( m[ "edges" ] ) ; Mge_SetCrease( m[ "edges" ][ n + 1 ], nC ) ; RETURN .T. ; ENDIF
RETURN .F.
FUNCTION Emh_ClearCreases( m )
   LOCAL g
   FOR EACH g IN m[ "edges" ] ; Mge_ClearCrease( g ) ; NEXT
RETURN NIL
FUNCTION Emh_HasCreases( m )
   LOCAL g
   FOR EACH g IN m[ "edges" ]
      IF Mge_HasCrease( g )
         RETURN .T.
      ENDIF
   NEXT
RETURN .F.
FUNCTION Emh_Translate( m, vOff )
   LOCAL i
   FOR i := 1 TO Len( m[ "vertices" ] ) ; m[ "vertices" ][ i ] := Vc3_Add( m[ "vertices" ][ i ], vOff ) ; NEXT
RETURN NIL
FUNCTION Emh_Scale( m, vC, nS )
   LOCAL i
   FOR i := 1 TO Len( m[ "vertices" ] ) ; m[ "vertices" ][ i ] := Vc3_Add( vC, Vc3_Mul( Vc3_Sub( m[ "vertices" ][ i ], vC ), nS ) ) ; NEXT
RETURN NIL
FUNCTION Emh_ScaleUniform( m, nS )
   LOCAL i
   FOR i := 1 TO Len( m[ "vertices" ] ) ; m[ "vertices" ][ i ] := Vc3_Mul( m[ "vertices" ][ i ], nS ) ; NEXT
RETURN NIL
/* bounding_box inherente: { min, max } o NIL */
FUNCTION Emh_BoundingBoxOpt( m )
   LOCAL vMin, vMax, i, v
   IF Len( m[ "vertices" ] ) == 0 ; RETURN NIL ; ENDIF
   vMin := AClone( m[ "vertices" ][ 1 ] ) ; vMax := AClone( m[ "vertices" ][ 1 ] )
   FOR i := 2 TO Len( m[ "vertices" ] )
      v := m[ "vertices" ][ i ]
      vMin := { Min( vMin[ 1 ], v[ 1 ] ), Min( vMin[ 2 ], v[ 2 ] ), Min( vMin[ 3 ], v[ 3 ] ) }
      vMax := { Max( vMax[ 1 ], v[ 1 ] ), Max( vMax[ 2 ], v[ 2 ] ), Max( vMax[ 3 ], v[ 3 ] ) }
   NEXT
RETURN { vMin, vMax }
FUNCTION Emh_BoundingBox( m )
   LOCAL b := Emh_BoundingBoxOpt( m )
RETURN iif( b == NIL, Bb3_Default(), Bb3_New( b[ 1 ], b[ 2 ] ) )
FUNCTION Emh_Center( m )
   LOCAL b := Emh_BoundingBoxOpt( m )
RETURN iif( b == NIL, NIL, Vc3_Mul( Vc3_Add( b[ 1 ], b[ 2 ] ), 0.5 ) )
FUNCTION Emh_FlipNormals( m )
   LOCAL f
   FOR EACH f IN m[ "faces" ] ; Mfc_Reverse( f ) ; NEXT
RETURN NIL
FUNCTION Emh_CreateBox( vMin, vMax )
   LOCAL aV := { { vMin[ 1 ], vMin[ 2 ], vMin[ 3 ] }, { vMax[ 1 ], vMin[ 2 ], vMin[ 3 ] }, { vMax[ 1 ], vMax[ 2 ], vMin[ 3 ] }, { vMin[ 1 ], vMax[ 2 ], vMin[ 3 ] }, ;
      { vMin[ 1 ], vMin[ 2 ], vMax[ 3 ] }, { vMax[ 1 ], vMin[ 2 ], vMax[ 3 ] }, { vMax[ 1 ], vMax[ 2 ], vMax[ 3 ] }, { vMin[ 1 ], vMax[ 2 ], vMax[ 3 ] } }
RETURN Emh_FromQuads( aV, { { 0, 3, 2, 1 }, { 4, 5, 6, 7 }, { 0, 1, 5, 4 }, { 2, 3, 7, 6 }, { 0, 4, 7, 3 }, { 1, 2, 6, 5 } } )
FUNCTION Emh_CreateUnitCube() ; RETURN Emh_CreateBox( { -0.5, -0.5, -0.5 }, { 0.5, 0.5, 0.5 } )
FUNCTION Emh_CreatePlane( vOrigin, vU, vV, nUs, nVs )
   LOCAL m := Emh_New(), u, v, nUr, nVr, nCols, v0
   FOR v := 0 TO nVs
      FOR u := 0 TO nUs
         nUr := u / nUs ; nVr := v / nVs
         Emh_AddVertex( m, Vc3_Add( Vc3_Add( vOrigin, Vc3_Mul( vU, nUr ) ), Vc3_Mul( vV, nVr ) ) )
      NEXT
   NEXT
   nCols := nUs + 1
   FOR v := 0 TO nVs - 1
      FOR u := 0 TO nUs - 1
         v0 := v * nCols + u
         Emh_AddQuad( m, v0, v0 + 1, v0 + nCols + 1, v0 + nCols )
      NEXT
   NEXT
   Emh_ComputeEdges( m )
RETURN m
FUNCTION Emh_CreateCylinder( vBase, nRadius, nHeight, nRs, nHs, lTop, lBottom )
   LOCAL m := Emh_New(), h, r, y, nAng, nNext, v0, v1, v2, v3, nC, nTopStart
   FOR h := 0 TO nHs
      y := ( h / nHs ) * nHeight
      FOR r := 0 TO nRs - 1
         nAng := ( r / nRs ) * 2.0 * OCX_PI
         Emh_AddVertex( m, Vc3_Add( vBase, { nRadius * OCX_COS( nAng ), y, nRadius * OCX_SIN( nAng ) } ) )
      NEXT
   NEXT
   FOR h := 0 TO nHs - 1
      FOR r := 0 TO nRs - 1
         nNext := ( r + 1 ) % nRs
         v0 := h * nRs + r ; v1 := h * nRs + nNext ; v2 := ( h + 1 ) * nRs + nNext ; v3 := ( h + 1 ) * nRs + r
         Emh_AddQuad( m, v0, v1, v2, v3 )
      NEXT
   NEXT
   IF lBottom
      nC := Emh_AddVertex( m, vBase )
      FOR r := 0 TO nRs - 1
         nNext := ( r + 1 ) % nRs
         Emh_AddTriangle( m, nC, nNext, r )
      NEXT
   ENDIF
   IF lTop
      nC := Emh_AddVertex( m, Vc3_Add( vBase, { 0.0, nHeight, 0.0 } ) )
      nTopStart := nHs * nRs
      FOR r := 0 TO nRs - 1
         nNext := ( r + 1 ) % nRs
         Emh_AddTriangle( m, nC, nTopStart + r, nTopStart + nNext )
      NEXT
   ENDIF
   Emh_ComputeEdges( m )
RETURN m
FUNCTION Emh_Merge( m, o )
   LOCAL nOff := Len( m[ "vertices" ] ), v, f, g, a
   FOR EACH v IN o[ "vertices" ] ; AAdd( m[ "vertices" ], v ) ; NEXT
   FOR EACH f IN o[ "faces" ]
      a := {} ; FOR EACH v IN f[ "vertices" ] ; AAdd( a, v + nOff ) ; NEXT
      AAdd( m[ "faces" ], Mfc_New( a ) )
   NEXT
   FOR EACH g IN o[ "edges" ] ; AAdd( m[ "edges" ], hb_Hash( "start", g[ "start" ] + nOff, "end", g[ "end" ] + nOff, "crease", g[ "crease" ] ) ) ; NEXT
RETURN NIL
/* translate_mesh / transform_mesh / mirror_mesh */
FUNCTION Emh_Transform( m, t )
   LOCAL i
   FOR i := 1 TO Len( m[ "vertices" ] ) ; m[ "vertices" ][ i ] := Tf_Apply( t, m[ "vertices" ][ i ] ) ; NEXT
RETURN NIL
FUNCTION Emh_Mirror( m, t ) ; Emh_Transform( m, t ) ; Emh_FlipNormals( m ) ; RETURN NIL

/* ---- MeshBuilder ---- */
FUNCTION Mbd_New() ; RETURN hb_Hash( "mesh", Emh_New() )
FUNCTION Mbd_Vertex( b, v ) ; Emh_AddVertex( b[ "mesh" ], v ) ; RETURN b
FUNCTION Mbd_Vertices( b, aV ) ; Emh_AddVertices( b[ "mesh" ], aV ) ; RETURN b
FUNCTION Mbd_Triangle( b, v0, v1, v2 ) ; Emh_AddTriangle( b[ "mesh" ], v0, v1, v2 ) ; RETURN b
FUNCTION Mbd_Quad( b, v0, v1, v2, v3 ) ; Emh_AddQuad( b[ "mesh" ], v0, v1, v2, v3 ) ; RETURN b
FUNCTION Mbd_Face( b, aV ) ; Emh_AddFace( b[ "mesh" ], Mfc_New( aV ) ) ; RETURN b
FUNCTION Mbd_SubdivisionLevel( b, n ) ; b[ "mesh" ][ "subdivision_level" ] := n ; RETURN b
FUNCTION Mbd_BlendCrease( b, l ) ; b[ "mesh" ][ "blend_crease" ] := l ; RETURN b
FUNCTION Mbd_ComputeEdges( b ) ; Emh_ComputeEdges( b[ "mesh" ] ) ; RETURN b
FUNCTION Mbd_Build( b ) ; RETURN b[ "mesh" ]
