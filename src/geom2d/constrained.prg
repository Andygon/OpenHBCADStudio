/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/constrained.prg
   Origen Rust: opencadkernel/src/geom2d/constrained.rs (171 lineas, 0 tests)
   Licencia del original: ver repositorio. Prefijo Cdt_.
   EQUIVALENTE PROPIO (decision del usuario): el Rust usa la libreria externa `spade`
   (ConstrainedDelaunayTriangulation). Aqui se implementa una CDT propia:
     - Bowyer/Lawson incremental con triangulo-soporte grande (coordenadas normalizadas a 0..1,
       soporte a +-1000), insercion de puntos con legalizacion por flips que respetan restricciones.
     - Insercion de restricciones: recorrido de aristas cruzadas, borrado de la cavidad y
       retriangulacion de ambos poligonos (Anglada); si cruza una arista restringida y se pide
       "split", se inserta el punto de cruce (add_constraint_and_split).
   Diferencias documentadas respecto a spade:
     - Predicados orient2d/incircle en doble precision, no robustos (spade usa aritmetica exacta).
     - Estructura de datos con busqueda lineal de triangulo (O(n) por insercion): suficiente para
       dominios de teselacion de caras; spade usa DCEL con walk O(sqrt n).
     - El orden de los triangulos devueltos y el vertice inicial de cada uno no coincide con spade
       (los consumidores no dependen del orden). El orden CCW y el orden de las aristas
       (arista i = vertice i -> vertice i+1) si.
     - El triangulo-soporte finito puede dejar alguna arista de casco no Delaunay en el borde
       exterior; no afecta a las caras interiores porque solo se devuelven triangulos cuyo
       centroide esta dentro de los anillos (paridad par/impar, igual que Rust).
   rings: array de anillos; anillo = array de {x,y} (parametros). Indices internos base 1.
   Tests propios [extra] (el Rust no tiene #[test] en este fichero): tests/t_constrained.prg.
----------------------------------------------------------------------------*/
#include "ocx.ch"
#define CD_V     1   // array de {x,y,px,py}
#define CD_T     2   // hash id -> {a,b,c}
#define CD_E     3   // hash "a,b" -> id (arista dirigida)
#define CD_NEXT  4
#define CD_RINGS 5
#define CD_ORIG  6
#define CD_SCALE 7
#define CD_CONS  8   // hash "min,max" -> .T.

STATIC FUNCTION EKey( a, b ) ; RETURN hb_ntos( a ) + "," + hb_ntos( b )
STATIC FUNCTION CKey( a, b ) ; RETURN iif( a < b, EKey( a, b ), EKey( b, a ) )

STATIC FUNCTION Orient( m, a, b, c )
   LOCAL va := m[ CD_V ][ a ], vb := m[ CD_V ][ b ], vc := m[ CD_V ][ c ]
RETURN ( vb[ 1 ] - va[ 1 ] ) * ( vc[ 2 ] - va[ 2 ] ) - ( vb[ 2 ] - va[ 2 ] ) * ( vc[ 1 ] - va[ 1 ] )

// > 0 si d esta dentro de la circunferencia de (a,b,c) (a,b,c en sentido antihorario)
STATIC FUNCTION InCircle( m, a, b, c, d )
   LOCAL va := m[ CD_V ][ a ], vb := m[ CD_V ][ b ], vc := m[ CD_V ][ c ], vd := m[ CD_V ][ d ]
   LOCAL adx := va[ 1 ] - vd[ 1 ], ady := va[ 2 ] - vd[ 2 ]
   LOCAL bdx := vb[ 1 ] - vd[ 1 ], bdy := vb[ 2 ] - vd[ 2 ]
   LOCAL cdx := vc[ 1 ] - vd[ 1 ], cdy := vc[ 2 ] - vd[ 2 ]
RETURN ( adx * adx + ady * ady ) * ( bdx * cdy - cdx * bdy ) - ;
       ( bdx * bdx + bdy * bdy ) * ( adx * cdy - cdx * ady ) + ;
       ( cdx * cdx + cdy * cdy ) * ( adx * bdy - bdx * ady )

STATIC FUNCTION AddTri( m, a, b, c )
   LOCAL id
   IF Orient( m, a, b, c ) < 0
      id := b ; b := c ; c := id
   ENDIF
   id := m[ CD_NEXT ]++
   m[ CD_T ][ id ] := { a, b, c }
   m[ CD_E ][ EKey( a, b ) ] := id
   m[ CD_E ][ EKey( b, c ) ] := id
   m[ CD_E ][ EKey( c, a ) ] := id
RETURN id

STATIC FUNCTION DelTri( m, id )
   LOCAL t := m[ CD_T ][ id ]
   hb_HDel( m[ CD_E ], EKey( t[ 1 ], t[ 2 ] ) )
   hb_HDel( m[ CD_E ], EKey( t[ 2 ], t[ 3 ] ) )
   hb_HDel( m[ CD_E ], EKey( t[ 3 ], t[ 1 ] ) )
   hb_HDel( m[ CD_T ], id )
RETURN NIL

// tercer vertice del triangulo que contiene la arista dirigida a->b, o 0
STATIC FUNCTION Third( m, a, b )
   LOCAL k := EKey( a, b ), t
   IF ! hb_HHasKey( m[ CD_E ], k ) ; RETURN 0 ; ENDIF
   t := m[ CD_T ][ m[ CD_E ][ k ] ]
   IF t[ 1 ] != a .AND. t[ 1 ] != b ; RETURN t[ 1 ] ; ENDIF
   IF t[ 2 ] != a .AND. t[ 2 ] != b ; RETURN t[ 2 ] ; ENDIF
RETURN t[ 3 ]

STATIC FUNCTION IsCons( m, a, b ) ; RETURN hb_HHasKey( m[ CD_CONS ], CKey( a, b ) )

STATIC FUNCTION Legalize( m, a, b )
   LOCAL c := Third( m, a, b ), d := Third( m, b, a )
   IF c == 0 .OR. d == 0 .OR. IsCons( m, a, b ) ; RETURN NIL ; ENDIF
   IF InCircle( m, a, b, c, d ) > 0 .AND. Orient( m, c, d, a ) * Orient( m, c, d, b ) < 0
      DelTri( m, m[ CD_E ][ EKey( a, b ) ] )
      DelTri( m, m[ CD_E ][ EKey( b, a ) ] )
      AddTri( m, a, d, c )
      AddTri( m, d, b, c )
      Legalize( m, a, d ) ; Legalize( m, d, b ) ; Legalize( m, b, c ) ; Legalize( m, c, a )
   ENDIF
RETURN NIL

// Crea la estructura con el triangulo-soporte (vertices 1..3)
STATIC FUNCTION Cdt_Empty( aOrigin, aScale )
   LOCAL m := { {}, { => }, { => }, 1, {}, aOrigin, aScale, { => } }
   AAdd( m[ CD_V ], { -1000.0, -1000.0, 0.0, 0.0 } )
   AAdd( m[ CD_V ], { 1000.0, -1000.0, 0.0, 0.0 } )
   AAdd( m[ CD_V ], { 0.0, 1000.0, 0.0, 0.0 } )
   AddTri( m, 1, 2, 3 )
RETURN m

// Normaliza como ConstrainedMesh::vertex: (v-origen)/escala redondeado a multiplos de f64::EPSILON
STATIC FUNCTION NormVert( m, aPar )
   LOCAL nStep := OCX_EPSILON(), aN := { 0.0, 0.0 }, i, nV
   FOR i := 1 TO 2
      nV := ( aPar[ i ] - m[ CD_ORIG ][ i ] ) / m[ CD_SCALE ][ i ]
      aN[ i ] := OCX_FLOOR( nV / nStep + 0.5 ) * nStep
   NEXT
RETURN { aN[ 1 ], aN[ 2 ], aPar[ 1 ], aPar[ 2 ] }

// Inserta un vertice: devuelve { indice, lNuevo } o NIL
STATIC FUNCTION InsertV( m, v )
   LOCAL i, id, t, k, a, b, c, o, nOn, p, q, d, lIn, nFound
   LOCAL n := Len( m[ CD_V ] )
   FOR i := 4 TO n
      IF m[ CD_V ][ i ][ 1 ] == v[ 1 ] .AND. m[ CD_V ][ i ][ 2 ] == v[ 2 ]
         RETURN { i, .F. }
      ENDIF
   NEXT
   AAdd( m[ CD_V ], v )
   p := n + 1
   nFound := 0
   nOn := 0
   FOR EACH id IN hb_HKeys( m[ CD_T ] )
      t := m[ CD_T ][ id ]
      nOn := 0
      lIn := .T.
      FOR k := 1 TO 3
         o := Orient( m, t[ k ], t[ k % 3 + 1 ], p )
         IF o < 0
            lIn := .F.
            EXIT
         ELSEIF o == 0
            nOn := k
         ENDIF
      NEXT
      IF lIn
         nFound := id
         EXIT
      ENDIF
   NEXT
   IF nFound == 0
      ASize( m[ CD_V ], n )
      RETURN NIL
   ENDIF
   IF nOn == 0
      a := t[ 1 ] ; b := t[ 2 ] ; c := t[ 3 ]
      DelTri( m, nFound )
      AddTri( m, a, b, p ) ; AddTri( m, b, c, p ) ; AddTri( m, c, a, p )
      Legalize( m, a, b ) ; Legalize( m, b, c ) ; Legalize( m, c, a )
   ELSE
      // el punto cae sobre la arista a->b del triangulo
      a := t[ nOn ] ; b := t[ nOn % 3 + 1 ] ; c := t[ ( nOn + 1 ) % 3 + 1 ]
      q := p
      d := Third( m, b, a )
      DelTri( m, nFound )
      AddTri( m, a, q, c ) ; AddTri( m, q, b, c )
      IF d != 0
         DelTri( m, m[ CD_E ][ EKey( b, a ) ] )
         AddTri( m, b, q, d ) ; AddTri( m, q, a, d )
      ENDIF
      IF IsCons( m, a, b )
         hb_HDel( m[ CD_CONS ], CKey( a, b ) )
         m[ CD_CONS ][ CKey( a, q ) ] := .T.
         m[ CD_CONS ][ CKey( q, b ) ] := .T.
      ENDIF
      Legalize( m, a, c ) ; Legalize( m, c, b )
      IF d != 0
         Legalize( m, b, d ) ; Legalize( m, d, a )
      ENDIF
   ENDIF
RETURN { p, .T. }

// Retriangula la cavidad aP[i1..i2] con base aP[i1]-aP[i2]
STATIC FUNCTION FillPoly( m, aP, i1, i2 )
   LOCAL i, c, nSg
   IF i2 - i1 < 2 ; RETURN NIL ; ENDIF
   c := i1 + 1
   FOR i := i1 + 2 TO i2 - 1
      nSg := iif( Orient( m, aP[ i1 ], aP[ c ], aP[ i2 ] ) < 0, -1, 1 )
      IF InCircle( m, aP[ i1 ], aP[ c ], aP[ i2 ], aP[ i ] ) * nSg > 0
         c := i
      ENDIF
   NEXT
   AddTri( m, aP[ i1 ], aP[ c ], aP[ i2 ] )
   FillPoly( m, aP, i1, c )
   FillPoly( m, aP, c, i2 )
RETURN NIL

STATIC FUNCTION OnRay( m, u, a, v )
   LOCAL vu := m[ CD_V ][ u ], va := m[ CD_V ][ a ], vv := m[ CD_V ][ v ]
RETURN Orient( m, u, a, v ) == 0 .AND. ;
   ( ( va[ 1 ] - vu[ 1 ] ) * ( vv[ 1 ] - vu[ 1 ] ) + ( va[ 2 ] - vu[ 2 ] ) * ( vv[ 2 ] - vu[ 2 ] ) ) > 0

// Interseccion de las rectas u-v y L-R (coordenadas normalizadas) o NIL
STATIC FUNCTION CrossPt( m, u, v, L, R )
   LOCAL pu := m[ CD_V ][ u ], pv := m[ CD_V ][ v ], pl := m[ CD_V ][ L ], pr := m[ CD_V ][ R ]
   LOCAL dx := pv[ 1 ] - pu[ 1 ], dy := pv[ 2 ] - pu[ 2 ]
   LOCAL ex := pr[ 1 ] - pl[ 1 ], ey := pr[ 2 ] - pl[ 2 ]
   LOCAL nDen := dx * ey - dy * ex, t
   IF nDen == 0 ; RETURN NIL ; ENDIF
   t := ( ( pl[ 1 ] - pu[ 1 ] ) * ey - ( pl[ 2 ] - pu[ 2 ] ) * ex ) / nDen
RETURN { pu[ 1 ] + t * dx, pu[ 2 ] + t * dy }

// Inserta la restriccion u-v. lSplit: si cruza otra restriccion se divide en el cruce.
// Devuelve el numero de aristas restringidas o 0 si falla (malla intacta en ese caso).
STATIC FUNCTION AddCons( m, u, v, lSplit )
   LOCAL id, t, k, a, b, L, R, w, s, aTris, aLeft, aRight, tid, ok, rr, aX, aV, aPl, aPr
   IF u == v ; RETURN 1 ; ENDIF
   IF hb_HHasKey( m[ CD_E ], EKey( u, v ) )
      m[ CD_CONS ][ CKey( u, v ) ] := .T.
      RETURN 1
   ENDIF
   tid := 0
   FOR EACH id IN hb_HKeys( m[ CD_T ] )
      t := m[ CD_T ][ id ]
      FOR k := 1 TO 3
         IF t[ k ] == u
            a := t[ k % 3 + 1 ] ; b := t[ ( k + 1 ) % 3 + 1 ]
            IF OnRay( m, u, a, v )
               RETURN SplitAt( m, u, a, v, lSplit )
            ENDIF
            IF OnRay( m, u, b, v )
               RETURN SplitAt( m, u, b, v, lSplit )
            ENDIF
            IF Orient( m, u, a, v ) > 0 .AND. Orient( m, u, b, v ) < 0
               tid := id ; L := b ; R := a
            ENDIF
         ENDIF
      NEXT
      IF tid != 0 ; EXIT ; ENDIF
   NEXT
   IF tid == 0 ; RETURN 0 ; ENDIF
   aTris := { tid } ; aLeft := { L } ; aRight := { R }
   DO WHILE .T.
      IF IsCons( m, L, R )
         IF ! lSplit ; RETURN 0 ; ENDIF
         aX := CrossPt( m, u, v, L, R )
         IF aX == NIL ; RETURN 0 ; ENDIF
         aPl := m[ CD_V ][ L ] ; aPr := m[ CD_V ][ R ]
         aV := { aX[ 1 ], aX[ 2 ], m[ CD_ORIG ][ 1 ] + aX[ 1 ] * m[ CD_SCALE ][ 1 ], m[ CD_ORIG ][ 2 ] + aX[ 2 ] * m[ CD_SCALE ][ 2 ] }
         rr := InsertV( m, aV )
         IF rr == NIL .OR. aPl == NIL .OR. aPr == NIL ; RETURN 0 ; ENDIF
         ok := AddCons( m, u, rr[ 1 ], lSplit )
         IF ok == 0 ; RETURN 0 ; ENDIF
         s := AddCons( m, rr[ 1 ], v, lSplit )
         RETURN iif( s == 0, 0, ok + s )
      ENDIF
      k := EKey( L, R )
      IF ! hb_HHasKey( m[ CD_E ], k ) ; RETURN 0 ; ENDIF
      tid := m[ CD_E ][ k ]
      w := Third( m, L, R )
      AAdd( aTris, tid )
      IF w == v ; EXIT ; ENDIF
      s := Orient( m, u, v, w )
      IF s == 0
         RETURN SplitAt( m, u, w, v, lSplit )
      ELSEIF s > 0
         L := w
      ELSE
         R := w
      ENDIF
      AAdd( aLeft, L ) ; AAdd( aRight, R )
   ENDDO
   a := { u }
   FOR k := 1 TO Len( aLeft )
      IF aLeft[ k ] != ATail( a ) ; AAdd( a, aLeft[ k ] ) ; ENDIF
   NEXT
   AAdd( a, v )
   b := { u }
   FOR k := 1 TO Len( aRight )
      IF aRight[ k ] != ATail( b ) ; AAdd( b, aRight[ k ] ) ; ENDIF
   NEXT
   AAdd( b, v )
   FOR EACH id IN aTris
      DelTri( m, id )
   NEXT
   FillPoly( m, a, 1, Len( a ) )
   FillPoly( m, b, 1, Len( b ) )
   m[ CD_CONS ][ CKey( u, v ) ] := .T.
RETURN 1

// El vertice w esta sobre el segmento u-v: u-w y w-v
STATIC FUNCTION SplitAt( m, u, w, v, lSplit )
   LOCAL ok, r
   IF w == v
      RETURN AddCons( m, u, v, lSplit )
   ENDIF
   ok := AddCons( m, u, w, lSplit )
   IF ok == 0 ; RETURN 0 ; ENDIF
   r := AddCons( m, w, v, lSplit )
RETURN iif( r == 0, 0, ok + r )

STATIC FUNCTION RingContains( aRing, aP )
   LOCAL lIn := .F., i, nN := Len( aRing ), f, t
   FOR i := 1 TO nN
      f := aRing[ i ] ; t := aRing[ i % nN + 1 ]
      IF ( f[ 2 ] > aP[ 2 ] ) != ( t[ 2 ] > aP[ 2 ] ) .AND. ;
         aP[ 1 ] < ( t[ 1 ] - f[ 1 ] ) * ( aP[ 2 ] - f[ 2 ] ) / ( t[ 2 ] - f[ 2 ] ) + f[ 1 ]
         lIn := ! lIn
      ENDIF
   NEXT
RETURN lIn

STATIC FUNCTION Inside( m, aP )
   LOCAL n := 0, r
   FOR EACH r IN m[ CD_RINGS ]
      IF RingContains( r, aP ) ; n++ ; ENDIF
   NEXT
RETURN n % 2 == 1

// ConstrainedMesh::new. Devuelve la malla o NIL.
FUNCTION Cdt_New( aRings )
   LOCAL aRing, aPt, nAx, aB, aOrigin, aScale, m, aHandles, aRH, r, h, i, aFrom, aTo, nLast
   IF Len( aRings ) == 0 ; RETURN NIL ; ENDIF
   FOR EACH aRing IN aRings
      IF Len( aRing ) < 3 ; RETURN NIL ; ENDIF
   NEXT
   aB := { { OCX_INF(), -OCX_INF() }, { OCX_INF(), -OCX_INF() } }
   FOR EACH aRing IN aRings
      FOR EACH aPt IN aRing
         FOR nAx := 1 TO 2
            aB[ nAx ][ 1 ] := Min( aB[ nAx ][ 1 ], aPt[ nAx ] )
            aB[ nAx ][ 2 ] := Max( aB[ nAx ][ 2 ], aPt[ nAx ] )
         NEXT
      NEXT
   NEXT
   aOrigin := { aB[ 1 ][ 1 ], aB[ 2 ][ 1 ] }
   aScale := { aB[ 1 ][ 2 ] - aB[ 1 ][ 1 ], aB[ 2 ][ 2 ] - aB[ 2 ][ 1 ] }
   FOR nAx := 1 TO 2
      IF ! OCX_ISFINITE( aScale[ nAx ] ) .OR. aScale[ nAx ] <= 0.0 ; RETURN NIL ; ENDIF
   NEXT
   m := Cdt_Empty( aOrigin, aScale )
   m[ CD_RINGS ] := aRings
   aHandles := {}
   FOR EACH aRing IN aRings
      aRH := {}
      FOR EACH aPt IN aRing
         r := InsertV( m, NormVert( m, aPt ) )
         IF r == NIL ; RETURN NIL ; ENDIF
         h := r[ 1 ]
         IF Len( aRH ) > 0 .AND. ATail( aRH ) == h ; RETURN NIL ; ENDIF
         AAdd( aRH, h )
      NEXT
      IF aRH[ 1 ] == ATail( aRH ) ; ASize( aRH, Len( aRH ) - 1 ) ; ENDIF
      IF Len( aRH ) < 3 ; RETURN NIL ; ENDIF
      AAdd( aHandles, aRH )
   NEXT
   FOR EACH aRH IN aHandles
      nLast := Len( aRH )
      FOR i := 1 TO nLast
         aFrom := aRH[ i ] ; aTo := aRH[ i % nLast + 1 ]
         IF aFrom == aTo .OR. AddCons( m, aFrom, aTo, .F. ) == 0 ; RETURN NIL ; ENDIF
      NEXT
   NEXT
RETURN m

FUNCTION Cdt_NumVertices( m ) ; RETURN Len( m[ CD_V ] ) - 3

// Triangulos interiores: { { parameters {{x,y}x3}, constraints {l,l,l} } ... }
FUNCTION Cdt_Triangles( m )
   LOCAL aOut := {}, id, t, aPar, aC, k, aV
   FOR EACH id IN hb_HKeys( m[ CD_T ] )
      t := m[ CD_T ][ id ]
      IF t[ 1 ] > 3 .AND. t[ 2 ] > 3 .AND. t[ 3 ] > 3
         aPar := {}
         FOR k := 1 TO 3
            aV := m[ CD_V ][ t[ k ] ]
            AAdd( aPar, { aV[ 3 ], aV[ 4 ] } )
         NEXT
         IF Inside( m, { ( aPar[ 1 ][ 1 ] + aPar[ 2 ][ 1 ] + aPar[ 3 ][ 1 ] ) / 3.0, ( aPar[ 1 ][ 2 ] + aPar[ 2 ][ 2 ] + aPar[ 3 ][ 2 ] ) / 3.0 } )
            aC := {}
            FOR k := 1 TO 3
               AAdd( aC, IsCons( m, t[ k ], t[ k % 3 + 1 ] ) )
            NEXT
            AAdd( aOut, { aPar, aC } )
         ENDIF
      ENDIF
   NEXT
RETURN aOut

// insert: .T. si crea un vertice nuevo, .F. si ya existia, NIL si falla
FUNCTION Cdt_Insert( m, aPar )
   LOCAL r := InsertV( m, NormVert( m, aPar ) )
   IF r == NIL ; RETURN NIL ; ENDIF
RETURN r[ 2 ]

// constrain: numero de vertices anadidos o NIL
FUNCTION Cdt_Constrain( m, aFrom, aTo )
   LOCAL nBefore := Cdt_NumVertices( m ), rf, rt
   rf := InsertV( m, NormVert( m, aFrom ) )
   IF rf == NIL ; RETURN NIL ; ENDIF
   rt := InsertV( m, NormVert( m, aTo ) )
   IF rt == NIL ; RETURN NIL ; ENDIF
   IF rf[ 1 ] != rt[ 1 ]
      IF AddCons( m, rf[ 1 ], rt[ 1 ], .T. ) == 0 ; RETURN NIL ; ENDIF
   ENDIF
RETURN Cdt_NumVertices( m ) - nBefore
