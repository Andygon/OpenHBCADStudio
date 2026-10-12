/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/offset.prg
   Origen Rust: opencadkernel/src/geom2d/offset.rs (424 lineas, 10 tests: tests/t_offset.prg)
   Prefijo Ofs_.
   EQUIVALENTE PROPIO (decision del usuario): el Rust delega en la libreria externa
   `cavalier_contours` (create_raw_offset_polyline, slices_from_dual_raw_offsets,
   stitch_slices_together). Aqui el nucleo es propio y mas simple:
     1) normalise(): traslada al primer vertice, escala para que la distancia sea 1, parte
        arcos mayores de media vuelta por su punto medio y elimina posiciones repetidas (igual que Rust).
     2) Lado: punto mas cercano de la polilinea al "side" y signo del producto vectorial
        tangente x (pick - punto), igual que Rust (>= 0 -> +1 izquierda).
     3) Desplazado crudo de cada segmento (recta: normal; arco: radio -/+ d) y union de segmentos:
        esquina convexa recta-recta -> esquina viva (sharpen_joins del Rust); convexa con arco ->
        arco de union de radio 1 centrado en el vertice; concava -> recorte en la interseccion
        de los dos desplazados, o conector recto si no se cortan.
     4) Autointersecciones: se parte el desplazado crudo en todos los cruces y se descartan los
        trozos cuya distancia a la polilinea original es < 1 (criterio estandar de offsets); los
        trozos validos contiguos se unen y se cosen por extremos (tolerancia 1e-4 = JOIN_EPSILON).
   Diferencias documentadas respecto a cavalier_contours:
     - Sin indice espacial (O(n^2) en el numero de segmentos).
     - Segmentos colineales solapados en el desplazado no se tratan de forma especial.
     - Dos lazos validos que se cruzan en un punto salen como una sola polilinea que se toca a si
       misma (cavalier tambien cose por extremos, pero el orden de cosido puede diferir).
     - Si un arco colapsa (radio <= 0) se omite su desplazado y se conecta con una recta.
   Indices base 0 en la API publica como Rust; internamente arrays base 1.
----------------------------------------------------------------------------*/
#include "ocx.ch"
#define OF_POS_EPS  0.00001
#define OF_JOIN_EPS 0.0001
#define OF_KIND 1   // 1 recta, 2 arco
#define OF_P0   2
#define OF_P1   3
#define OF_C    4
#define OF_R    5
#define OF_CCW  6

STATIC FUNCTION SgLine( p0, p1 ) ; RETURN { 1, p0, p1, NIL, 0.0, .F. }
STATIC FUNCTION SgArc( p0, p1, c, r, lCcw ) ; RETURN { 2, p0, p1, c, r, lCcw }
STATIC FUNCTION Dist2( a, b ) ; RETURN Sqrt( ( a[ 1 ] - b[ 1 ] ) ^ 2 + ( a[ 2 ] - b[ 2 ] ) ^ 2 )
STATIC FUNCTION Cross2( ax, ay, bx, by ) ; RETURN ax * by - ay * bx

STATIC FUNCTION SgFromBulge( p0, p1, nBulge )
   LOCAL arc := BA_FromBulge( p0, p1, nBulge )
   IF arc == NIL ; RETURN SgLine( p0, p1 ) ; ENDIF
RETURN SgArc( p0, p1, arc[ BA_CENTER ], arc[ BA_RADIUS ], nBulge > 0.0 )

// barrido con signo de un arco desde p0 hasta p1 (p0/p1 sobre la circunferencia)
STATIC FUNCTION ArcSweepTo( c, lCcw, p0, p1 )
   LOCAL a0 := OCX_ATAN2( p0[ 2 ] - c[ 2 ], p0[ 1 ] - c[ 1 ] )
   LOCAL a1 := OCX_ATAN2( p1[ 2 ] - c[ 2 ], p1[ 1 ] - c[ 1 ] )
   LOCAL s := a1 - a0
   IF lCcw
      IF s < 0.0 ; s += OCX_TAU ; ENDIF
   ELSEIF s > 0.0
      s -= OCX_TAU
   ENDIF
RETURN s

STATIC FUNCTION SgSweep( sg ) ; RETURN ArcSweepTo( sg[ OF_C ], sg[ OF_CCW ], sg[ OF_P0 ], sg[ OF_P1 ] )

STATIC FUNCTION SgLength( sg )
   IF sg[ OF_KIND ] == 1 ; RETURN Dist2( sg[ OF_P0 ], sg[ OF_P1 ] ) ; ENDIF
RETURN Abs( SgSweep( sg ) ) * sg[ OF_R ]

// tangente unitaria en el punto p del segmento
STATIC FUNCTION SgTangent( sg, p )
   LOCAL ux, uy, n, rx, ry
   IF sg[ OF_KIND ] == 1
      ux := sg[ OF_P1 ][ 1 ] - sg[ OF_P0 ][ 1 ] ; uy := sg[ OF_P1 ][ 2 ] - sg[ OF_P0 ][ 2 ]
      n := Sqrt( ux * ux + uy * uy )
      IF n == 0.0 ; RETURN { 0.0, 0.0 } ; ENDIF
      RETURN { ux / n, uy / n }
   ENDIF
   rx := p[ 1 ] - sg[ OF_C ][ 1 ] ; ry := p[ 2 ] - sg[ OF_C ][ 2 ]
   n := Sqrt( rx * rx + ry * ry )
   IF n == 0.0 ; RETURN { 0.0, 0.0 } ; ENDIF
   rx /= n ; ry /= n
RETURN iif( sg[ OF_CCW ], { -ry, rx }, { ry, -rx } )

// fraccion 0..1 de p a lo largo del segmento (puede salir de rango)
STATIC FUNCTION SgParam( sg, p )
   LOCAL dx, dy, l2, sw
   IF sg[ OF_KIND ] == 1
      dx := sg[ OF_P1 ][ 1 ] - sg[ OF_P0 ][ 1 ] ; dy := sg[ OF_P1 ][ 2 ] - sg[ OF_P0 ][ 2 ]
      l2 := dx * dx + dy * dy
      IF l2 == 0.0 ; RETURN 0.0 ; ENDIF
      RETURN ( ( p[ 1 ] - sg[ OF_P0 ][ 1 ] ) * dx + ( p[ 2 ] - sg[ OF_P0 ][ 2 ] ) * dy ) / l2
   ENDIF
   sw := SgSweep( sg )
   IF sw == 0.0 ; RETURN 0.0 ; ENDIF
RETURN ArcSweepTo( sg[ OF_C ], sg[ OF_CCW ], sg[ OF_P0 ], p ) / sw

STATIC FUNCTION SgPointAt( sg, t )
   LOCAL a0, sw
   IF sg[ OF_KIND ] == 1
      RETURN { sg[ OF_P0 ][ 1 ] + t * ( sg[ OF_P1 ][ 1 ] - sg[ OF_P0 ][ 1 ] ), sg[ OF_P0 ][ 2 ] + t * ( sg[ OF_P1 ][ 2 ] - sg[ OF_P0 ][ 2 ] ) }
   ENDIF
   a0 := OCX_ATAN2( sg[ OF_P0 ][ 2 ] - sg[ OF_C ][ 2 ], sg[ OF_P0 ][ 1 ] - sg[ OF_C ][ 1 ] )
   sw := SgSweep( sg )
RETURN { sg[ OF_C ][ 1 ] + sg[ OF_R ] * OCX_COS( a0 + sw * t ), sg[ OF_C ][ 2 ] + sg[ OF_R ] * OCX_SIN( a0 + sw * t ) }

// punto del segmento mas cercano a p: { punto, distancia }
STATIC FUNCTION SgClosest( sg, p )
   LOCAL dx, dy, l2, t, q, rx, ry, n, aq, d0, d1
   IF sg[ OF_KIND ] == 1
      dx := sg[ OF_P1 ][ 1 ] - sg[ OF_P0 ][ 1 ] ; dy := sg[ OF_P1 ][ 2 ] - sg[ OF_P0 ][ 2 ]
      l2 := dx * dx + dy * dy
      t := iif( l2 == 0.0, 0.0, ( ( p[ 1 ] - sg[ OF_P0 ][ 1 ] ) * dx + ( p[ 2 ] - sg[ OF_P0 ][ 2 ] ) * dy ) / l2 )
      t := Max( 0.0, Min( 1.0, t ) )
      q := { sg[ OF_P0 ][ 1 ] + t * dx, sg[ OF_P0 ][ 2 ] + t * dy }
      RETURN { q, Dist2( p, q ) }
   ENDIF
   rx := p[ 1 ] - sg[ OF_C ][ 1 ] ; ry := p[ 2 ] - sg[ OF_C ][ 2 ]
   n := Sqrt( rx * rx + ry * ry )
   IF n > 0.0
      q := { sg[ OF_C ][ 1 ] + sg[ OF_R ] * rx / n, sg[ OF_C ][ 2 ] + sg[ OF_R ] * ry / n }
      aq := SgParam( sg, q )
      IF aq >= 0.0 .AND. aq <= 1.0
         RETURN { q, Dist2( p, q ) }
      ENDIF
   ENDIF
   d0 := Dist2( p, sg[ OF_P0 ] ) ; d1 := Dist2( p, sg[ OF_P1 ] )
RETURN iif( d0 <= d1, { sg[ OF_P0 ], d0 }, { sg[ OF_P1 ], d1 } )

STATIC FUNCTION OnSg( sg, p )
   LOCAL t := SgParam( sg, p ), nTol := 0.000000001
   IF sg[ OF_KIND ] == 2
      // un arco con p fuera del barrido da un angulo > 1 (o ~0 al otro lado): se acepta solo en rango
      RETURN t >= -nTol .AND. t <= 1.0 + nTol
   ENDIF
RETURN t >= -nTol .AND. t <= 1.0 + nTol

// puntos de interseccion de dos segmentos (sobre ambos)
STATIC FUNCTION SgIntersect( a, b )
   LOCAL aOut := {}, aC, p, d, e, den, t, u, qx, qy
   IF a[ OF_KIND ] == 1 .AND. b[ OF_KIND ] == 1
      d := { a[ OF_P1 ][ 1 ] - a[ OF_P0 ][ 1 ], a[ OF_P1 ][ 2 ] - a[ OF_P0 ][ 2 ] }
      e := { b[ OF_P1 ][ 1 ] - b[ OF_P0 ][ 1 ], b[ OF_P1 ][ 2 ] - b[ OF_P0 ][ 2 ] }
      den := Cross2( d[ 1 ], d[ 2 ], e[ 1 ], e[ 2 ] )
      IF Abs( den ) < 0.000000000001 ; RETURN aOut ; ENDIF
      qx := b[ OF_P0 ][ 1 ] - a[ OF_P0 ][ 1 ] ; qy := b[ OF_P0 ][ 2 ] - a[ OF_P0 ][ 2 ]
      t := Cross2( qx, qy, e[ 1 ], e[ 2 ] ) / den
      u := Cross2( qx, qy, d[ 1 ], d[ 2 ] ) / den
      IF t >= -0.000000001 .AND. t <= 1.000000001 .AND. u >= -0.000000001 .AND. u <= 1.000000001
         AAdd( aOut, { a[ OF_P0 ][ 1 ] + t * d[ 1 ], a[ OF_P0 ][ 2 ] + t * d[ 2 ] } )
      ENDIF
      RETURN aOut
   ENDIF
   IF a[ OF_KIND ] == 1 .OR. b[ OF_KIND ] == 1
      IF a[ OF_KIND ] == 1
         aC := LineCircle( a[ OF_P0 ], a[ OF_P1 ], b[ OF_C ], b[ OF_R ] )
      ELSE
         aC := LineCircle( b[ OF_P0 ], b[ OF_P1 ], a[ OF_C ], a[ OF_R ] )
      ENDIF
   ELSE
      aC := CircleCircle( a[ OF_C ], a[ OF_R ], b[ OF_C ], b[ OF_R ] )
   ENDIF
   FOR EACH p IN aC
      IF OnSg( a, p ) .AND. OnSg( b, p )
         AAdd( aOut, p )
      ENDIF
   NEXT
RETURN aOut

// puntos de la RECTA p0-p1 sobre el circulo (el filtro de extension lo hace el llamador via OnSg)
STATIC FUNCTION LineCircle( p0, p1, c, r )
   LOCAL dx := p1[ 1 ] - p0[ 1 ], dy := p1[ 2 ] - p0[ 2 ], fx := p0[ 1 ] - c[ 1 ], fy := p0[ 2 ] - c[ 2 ]
   LOCAL qa := dx * dx + dy * dy, qb := 2.0 * ( fx * dx + fy * dy ), qc := fx * fx + fy * fy - r * r
   LOCAL disc, s, aR := {}, t1, t2
   IF qa == 0.0 ; RETURN aR ; ENDIF
   disc := qb * qb - 4.0 * qa * qc
   IF disc < -0.000000000001 ; RETURN aR ; ENDIF
   s := Sqrt( Max( 0.0, disc ) )
   t1 := ( -qb - s ) / ( 2.0 * qa ) ; t2 := ( -qb + s ) / ( 2.0 * qa )
   IF t1 >= -0.000000001 .AND. t1 <= 1.000000001
      AAdd( aR, { p0[ 1 ] + t1 * dx, p0[ 2 ] + t1 * dy } )
   ENDIF
   IF s > 0.0 .AND. t2 >= -0.000000001 .AND. t2 <= 1.000000001
      AAdd( aR, { p0[ 1 ] + t2 * dx, p0[ 2 ] + t2 * dy } )
   ENDIF
RETURN aR

STATIC FUNCTION CircleCircle( c1, r1, c2, r2 )
   LOCAL dx := c2[ 1 ] - c1[ 1 ], dy := c2[ 2 ] - c1[ 2 ], d := Sqrt( dx * dx + dy * dy ), a, h2, h, mx, my, aR := {}
   IF d == 0.0 .OR. d > r1 + r2 + 0.000000001 .OR. d < Abs( r1 - r2 ) - 0.000000001 ; RETURN aR ; ENDIF
   a := ( r1 * r1 - r2 * r2 + d * d ) / ( 2.0 * d )
   h2 := r1 * r1 - a * a
   h := Sqrt( Max( 0.0, h2 ) )
   mx := c1[ 1 ] + a * dx / d ; my := c1[ 2 ] + a * dy / d
   AAdd( aR, { mx + h * dy / d, my - h * dx / d } )
   IF h > 0.0
      AAdd( aR, { mx - h * dy / d, my + h * dx / d } )
   ENDIF
RETURN aR

// ---- normalise ---------------------------------------------------------------------------
// Devuelve { aVerts {x,y,bulge}, lClosed, aOrigin } o NIL
STATIC FUNCTION Normalise( pl, nDist )
   LOCAL aV := pl[ PL_VERTS ], nCount := Len( aV ), aOrigin, aOut := {}, i, nSeg, st, en, nBulge, aLocal, arc, nHalf, aMid
   LOCAL aClean, v
   IF nCount < 2 ; RETURN NIL ; ENDIF
   aOrigin := aV[ 1 ][ PV_POS ]
   nSeg := iif( pl[ PL_CLOSED ], nCount, nCount - 1 )
   FOR i := 0 TO nSeg - 1
      st := aV[ i + 1 ] ; en := aV[ ( i + 1 ) % nCount + 1 ]
      nBulge := iif( OCX_ISFINITE( st[ PV_BULGE ] ), st[ PV_BULGE ], 0.0 )
      aLocal := { ( st[ PV_POS ][ 1 ] - aOrigin[ 1 ] ) / nDist, ( st[ PV_POS ][ 2 ] - aOrigin[ 2 ] ) / nDist }
      IF Abs( nBulge ) > 1.0
         arc := BA_FromBulge( st[ PV_POS ], en[ PV_POS ], nBulge )
         IF arc != NIL
            nHalf := OCX_TAN( arc[ BA_SWEEP ] / 8.0 )
            aMid := BA_Sample( arc, 0.5 )
            AAdd( aOut, { aLocal[ 1 ], aLocal[ 2 ], nHalf } )
            AAdd( aOut, { ( aMid[ 1 ] - aOrigin[ 1 ] ) / nDist, ( aMid[ 2 ] - aOrigin[ 2 ] ) / nDist, nHalf } )
            LOOP
         ENDIF
      ENDIF
      AAdd( aOut, { aLocal[ 1 ], aLocal[ 2 ], nBulge } )
   NEXT
   IF ! pl[ PL_CLOSED ]
      v := aV[ nCount ][ PV_POS ]
      AAdd( aOut, { ( v[ 1 ] - aOrigin[ 1 ] ) / nDist, ( v[ 2 ] - aOrigin[ 2 ] ) / nDist, 0.0 } )
   ENDIF
   // remove_repeat_pos: se queda el bulge del ultimo de los repetidos
   aClean := {}
   FOR EACH v IN aOut
      IF Len( aClean ) > 0 .AND. Abs( v[ 1 ] - ATail( aClean )[ 1 ] ) < OF_POS_EPS .AND. Abs( v[ 2 ] - ATail( aClean )[ 2 ] ) < OF_POS_EPS
         ATail( aClean )[ 3 ] := v[ 3 ]
      ELSE
         AAdd( aClean, v )
      ENDIF
   NEXT
   IF pl[ PL_CLOSED ] .AND. Len( aClean ) > 1
      IF Abs( aClean[ 1 ][ 1 ] - ATail( aClean )[ 1 ] ) < OF_POS_EPS .AND. Abs( aClean[ 1 ][ 2 ] - ATail( aClean )[ 2 ] ) < OF_POS_EPS
         aClean[ 1 ][ 3 ] := ATail( aClean )[ 3 ]
         ASize( aClean, Len( aClean ) - 1 )
      ENDIF
   ENDIF
   IF Len( aClean ) < 2 ; RETURN NIL ; ENDIF
RETURN { aClean, pl[ PL_CLOSED ], aOrigin }

// segmentos de la polilinea normalizada
STATIC FUNCTION SourceSegs( aVerts, lClosed )
   LOCAL aS := {}, n := Len( aVerts ), i, nEnd := iif( lClosed, n, n - 1 ), a, b
   FOR i := 1 TO nEnd
      a := aVerts[ i ] ; b := aVerts[ i % n + 1 ]
      AAdd( aS, SgFromBulge( { a[ 1 ], a[ 2 ] }, { b[ 1 ], b[ 2 ] }, a[ 3 ] ) )
   NEXT
RETURN aS

// ---- desplazado crudo ------------------------------------------------------------------------
// Devuelve el segmento desplazado d (signo: + izquierda) o NIL si colapsa
STATIC FUNCTION OffsetSeg( sg, d )
   LOCAL u, nr, rn, p0, p1
   IF sg[ OF_KIND ] == 1
      u := SgTangent( sg, sg[ OF_P0 ] ) ; nr := { -u[ 2 ], u[ 1 ] }
      RETURN SgLine( { sg[ OF_P0 ][ 1 ] + nr[ 1 ] * d, sg[ OF_P0 ][ 2 ] + nr[ 2 ] * d }, { sg[ OF_P1 ][ 1 ] + nr[ 1 ] * d, sg[ OF_P1 ][ 2 ] + nr[ 2 ] * d } )
   ENDIF
   rn := iif( sg[ OF_CCW ], sg[ OF_R ] - d, sg[ OF_R ] + d )
   IF rn <= OF_POS_EPS ; RETURN NIL ; ENDIF
   p0 := { sg[ OF_C ][ 1 ] + ( sg[ OF_P0 ][ 1 ] - sg[ OF_C ][ 1 ] ) * rn / sg[ OF_R ], sg[ OF_C ][ 2 ] + ( sg[ OF_P0 ][ 2 ] - sg[ OF_C ][ 2 ] ) * rn / sg[ OF_R ] }
   p1 := { sg[ OF_C ][ 1 ] + ( sg[ OF_P1 ][ 1 ] - sg[ OF_C ][ 1 ] ) * rn / sg[ OF_R ], sg[ OF_C ][ 2 ] + ( sg[ OF_P1 ][ 2 ] - sg[ OF_C ][ 2 ] ) * rn / sg[ OF_R ] }
RETURN SgArc( p0, p1, sg[ OF_C ], rn, sg[ OF_CCW ] )

// Une los dos segmentos desplazados s1 (anterior) y s2 (siguiente) que parten del vertice v.
// Modifica s1/s2 (recortes) y devuelve un array con los segmentos de union a intercalar.
STATIC FUNCTION JoinSegs( s1, s2, v, nD, o1, o2 )
   LOCAL t1 := SgTangent( o1, o1[ OF_P1 ] ), t2 := SgTangent( o2, o2[ OF_P0 ] )
   LOCAL ta := SgTangent( s1, s1[ OF_P1 ] ), tb := SgTangent( s2, s2[ OF_P0 ] )
   LOCAL nCross := Cross2( ta[ 1 ], ta[ 2 ], tb[ 1 ], tb[ 2 ] ), nDot := ta[ 1 ] * tb[ 1 ] + ta[ 2 ] * tb[ 2 ]
   LOCAL aPts, p, best, nBest, nDs, nTheta, aCorner, den, tt, nBulge, aArc
   // o1.P1 y o2.P0 son los extremos desplazados
   IF Dist2( o1[ OF_P1 ], o2[ OF_P0 ] ) < OF_POS_EPS * 0.01
      RETURN {}
   ENDIF
   IF t1[ 1 ] == 0.0 .AND. t1[ 2 ] == 0.0 ; RETURN { SgLine( o1[ OF_P1 ], o2[ OF_P0 ] ) } ; ENDIF
   IF nCross * OCX_SIGNUM( nD ) < 0.0
      // esquina convexa: hay hueco
      IF o1[ OF_KIND ] == 1 .AND. o2[ OF_KIND ] == 1 .AND. nDot > -0.999999
         den := Cross2( t1[ 1 ], t1[ 2 ], t2[ 1 ], t2[ 2 ] )
         IF Abs( den ) > 0.000000000001
            tt := Cross2( o2[ OF_P0 ][ 1 ] - o1[ OF_P1 ][ 1 ], o2[ OF_P0 ][ 2 ] - o1[ OF_P1 ][ 2 ], t2[ 1 ], t2[ 2 ] ) / den
            aCorner := { o1[ OF_P1 ][ 1 ] + tt * t1[ 1 ], o1[ OF_P1 ][ 2 ] + tt * t1[ 2 ] }
            o1[ OF_P1 ] := aCorner ; o2[ OF_P0 ] := aCorner
            RETURN {}
         ENDIF
      ENDIF
      nTheta := OCX_ATAN2( Abs( nCross ), nDot )
      nBulge := OCX_SIGNUM( nCross ) * OCX_TAN( nTheta / 4.0 )
      aArc := SgFromBulge( o1[ OF_P1 ], o2[ OF_P0 ], nBulge )
      IF aArc[ OF_KIND ] == 2
         aArc[ OF_C ] := v ; aArc[ OF_R ] := Abs( nD ) ; aArc[ OF_CCW ] := nCross > 0.0
      ENDIF
      RETURN { aArc }
   ENDIF
   // concava: recorte en la interseccion mas cercana al vertice
   aPts := SgIntersect( o1, o2 )
   best := NIL ; nBest := 0.0
   FOR EACH p IN aPts
      nDs := Dist2( p, v )
      IF best == NIL .OR. nDs < nBest
         best := p ; nBest := nDs
      ENDIF
   NEXT
   IF best != NIL
      o1[ OF_P1 ] := best ; o2[ OF_P0 ] := best
      RETURN {}
   ENDIF
RETURN { SgLine( o1[ OF_P1 ], o2[ OF_P0 ] ) }

// camino crudo: array de segmentos consecutivos
STATIC FUNCTION RawOffset( aSegs, lClosed, nD )
   LOCAL aOff := {}, aIdx := {}, i, n := Len( aSegs ), o, aPath := {}, k, nj, aJ, a, b, v, aV
   FOR i := 1 TO n
      o := OffsetSeg( aSegs[ i ], nD )
      IF o != NIL
         AAdd( aOff, o ) ; AAdd( aIdx, i )
      ENDIF
   NEXT
   IF Len( aOff ) == 0 ; RETURN {} ; ENDIF
   nj := Len( aOff )
   FOR k := 1 TO nj
      AAdd( aPath, aOff[ k ] )
      IF k < nj .OR. lClosed
         a := aOff[ k ] ; b := aOff[ k % nj + 1 ]
         IF k == nj .AND. nj == 1 .AND. lClosed
            LOOP
         ENDIF
         // vertice compartido solo si los indices originales son consecutivos
         IF aIdx[ k % nj + 1 ] == aIdx[ k ] % n + 1 .OR. ( k == nj .AND. lClosed .AND. aIdx[ 1 ] == aIdx[ nj ] % n + 1 )
            v := aSegs[ aIdx[ k ] ][ OF_P1 ]
            aJ := JoinSegs( aSegs[ aIdx[ k ] ], aSegs[ aIdx[ k % nj + 1 ] ], v, nD, a, b )
         ELSE
            aJ := { SgLine( a[ OF_P1 ], b[ OF_P0 ] ) }
            IF Dist2( a[ OF_P1 ], b[ OF_P0 ] ) < OF_POS_EPS * 0.01 ; aJ := {} ; ENDIF
         ENDIF
         FOR EACH aV IN aJ
            AAdd( aPath, aV )
         NEXT
      ENDIF
   NEXT
RETURN aPath

// ---- autointersecciones ------------------------------------------------------------------------
STATIC FUNCTION DistToSource( aSrc, p )
   LOCAL nMin := 1000000000.0, sg, r
   FOR EACH sg IN aSrc
      r := SgClosest( sg, p )
      nMin := Min( nMin, r[ 2 ] )
   NEXT
RETURN nMin

// Trocea el camino en todos los cruces; devuelve segmentos troceados en orden
STATIC FUNCTION SplitPath( aPath, lClosed )
   LOCAL n := Len( aPath ), i, j, aPts, p, aT, aOut := {}, aSplit, nT, k, aPrev, aCut, nLen
   LOCAL aSplits := Array( n )
   FOR i := 1 TO n ; aSplits[ i ] := {} ; NEXT
   FOR i := 1 TO n
      FOR j := i + 1 TO n
         aPts := SgIntersect( aPath[ i ], aPath[ j ] )
         FOR EACH p IN aPts
            // omitir la union entre segmentos consecutivos
            IF j == i + 1 .AND. Dist2( p, aPath[ i ][ OF_P1 ] ) < 0.000001
               LOOP
            ENDIF
            IF lClosed .AND. i == 1 .AND. j == n .AND. Dist2( p, aPath[ j ][ OF_P1 ] ) < 0.000001
               LOOP
            ENDIF
            AAdd( aSplits[ i ], SgParam( aPath[ i ], p ) )
            AAdd( aSplits[ j ], SgParam( aPath[ j ], p ) )
         NEXT
      NEXT
   NEXT
   FOR i := 1 TO n
      aT := ASort( aSplits[ i ] )
      aCut := { 0.0 }
      FOR EACH nT IN aT
         IF nT > 0.000000001 .AND. nT < 1.0 - 0.000000001 .AND. nT - ATail( aCut ) > 0.000000001
            AAdd( aCut, nT )
         ENDIF
      NEXT
      AAdd( aCut, 1.0 )
      FOR k := 1 TO Len( aCut ) - 1
         aPrev := aPath[ i ]
         nLen := Len( aCut )
         IF nLen == 2
            AAdd( aOut, aPrev )
         ELSE
            AAdd( aOut, SubSeg( aPrev, aCut[ k ], aCut[ k + 1 ] ) )
         ENDIF
      NEXT
   NEXT
   aSplit := NIL
RETURN aOut

STATIC FUNCTION SubSeg( sg, t0, t1 )
   LOCAL p0 := iif( t0 <= 0.0, sg[ OF_P0 ], SgPointAt( sg, t0 ) ), p1 := iif( t1 >= 1.0, sg[ OF_P1 ], SgPointAt( sg, t1 ) )
   IF sg[ OF_KIND ] == 1 ; RETURN SgLine( p0, p1 ) ; ENDIF
RETURN SgArc( p0, p1, sg[ OF_C ], sg[ OF_R ], sg[ OF_CCW ] )

STATIC FUNCTION KeepPiece( aSrc, sg )
   LOCAL t
   IF SgLength( sg ) < 0.000000001 ; RETURN .F. ; ENDIF
   FOR EACH t IN { 0.25, 0.5, 0.75 }
      IF DistToSource( aSrc, SgPointAt( sg, t ) ) < 1.0 - OF_JOIN_EPS
         RETURN .F.
      ENDIF
   NEXT
RETURN .T.

// vertices { x, y, bulge } de una cadena de segmentos
STATIC FUNCTION ChainToVerts( aChain, lClosed )
   LOCAL aV := {}, sg, nB, aLast
   FOR EACH sg IN aChain
      IF sg[ OF_KIND ] == 1
         nB := 0.0
      ELSE
         nB := OCX_TAN( SgSweep( sg ) / 4.0 )
      ENDIF
      IF Len( aV ) > 0 .AND. Dist2( ATail( aV ), sg[ OF_P0 ] ) < 0.000000001
         ATail( aV )[ 3 ] := nB
      ELSE
         AAdd( aV, { sg[ OF_P0 ][ 1 ], sg[ OF_P0 ][ 2 ], nB } )
      ENDIF
   NEXT
   IF ! lClosed
      aLast := ATail( aChain )[ OF_P1 ]
      AAdd( aV, { aLast[ 1 ], aLast[ 2 ], 0.0 } )
   ENDIF
RETURN aV

// ---- API publica ---------------------------------------------------------------------------------
// offset_polyline( source, distance, side ) -> array de Polyline
FUNCTION Ofs_OffsetPolyline( pl, nDistance, aSide )
   LOCAL nDist := Abs( nDistance ), aNorm, aSrc, aOrigin, aSideN, best, sg, r, nBest, nSigned, aT, aToward, nCross
   LOCAL aPieces, aKeep, aRuns, aRun, i, n, nFirstDrop, k, aChain, aUsed, aResult := {}, aRaw, lClosed
   LOCAL aChains, lFound, aNext, j, aVerts, aOutV, v, lAll
   IF nDist < 0.000000000001 ; RETURN {} ; ENDIF
   aNorm := Normalise( pl, nDist )
   IF aNorm == NIL ; RETURN {} ; ENDIF
   aOrigin := aNorm[ 3 ] ; lClosed := aNorm[ 2 ]
   aSrc := SourceSegs( aNorm[ 1 ], lClosed )
   aSideN := { ( aSide[ 1 ] - aOrigin[ 1 ] ) / nDist, ( aSide[ 2 ] - aOrigin[ 2 ] ) / nDist }
   best := NIL ; nBest := 0.0
   FOR EACH sg IN aSrc
      r := SgClosest( sg, aSideN )
      IF best == NIL .OR. r[ 2 ] < nBest - OF_POS_EPS
         best := { sg, r[ 1 ] } ; nBest := r[ 2 ]
      ENDIF
   NEXT
   IF best == NIL ; RETURN {} ; ENDIF
   aT := SgTangent( best[ 1 ], best[ 2 ] )
   aToward := { aSideN[ 1 ] - best[ 2 ][ 1 ], aSideN[ 2 ] - best[ 2 ][ 2 ] }
   nCross := aT[ 1 ] * aToward[ 2 ] - aT[ 2 ] * aToward[ 1 ]
   nSigned := iif( nCross >= 0.0, 1.0, -1.0 )
   aRaw := RawOffset( aSrc, lClosed, nSigned )
   IF Len( aRaw ) == 0 ; RETURN {} ; ENDIF
   aPieces := SplitPath( aRaw, lClosed )
   n := Len( aPieces )
   aKeep := Array( n )
   lAll := .T.
   FOR i := 1 TO n
      aKeep[ i ] := KeepPiece( aSrc, aPieces[ i ] )
      IF ! aKeep[ i ] ; lAll := .F. ; ENDIF
   NEXT
   aRuns := {}
   IF lAll .AND. lClosed
      AAdd( aRuns, { aPieces, .T. } )
   ELSE
      nFirstDrop := 0
      IF lClosed
         FOR i := 1 TO n
            IF ! aKeep[ i ] ; nFirstDrop := i ; EXIT ; ENDIF
         NEXT
      ENDIF
      aRun := {}
      FOR k := 1 TO n
         i := iif( lClosed, ( nFirstDrop + k - 1 ) % n + 1, k )
         IF aKeep[ i ]
            AAdd( aRun, aPieces[ i ] )
         ELSEIF Len( aRun ) > 0
            AAdd( aRuns, { aRun, .F. } ) ; aRun := {}
         ENDIF
      NEXT
      IF Len( aRun ) > 0 ; AAdd( aRuns, { aRun, .F. } ) ; ENDIF
   ENDIF
   // coser por extremos
   aUsed := Array( Len( aRuns ) ) ; AFill( aUsed, .F. )
   aChains := {}
   FOR i := 1 TO Len( aRuns )
      IF aUsed[ i ] ; LOOP ; ENDIF
      aUsed[ i ] := .T.
      aChain := AClone( aRuns[ i ][ 1 ] )
      IF aRuns[ i ][ 2 ]
         AAdd( aChains, { aChain, .T. } )
         LOOP
      ENDIF
      DO WHILE Dist2( ATail( aChain )[ OF_P1 ], aChain[ 1 ][ OF_P0 ] ) >= OF_JOIN_EPS
         lFound := .F.
         FOR j := 1 TO Len( aRuns )
            IF ! aUsed[ j ] .AND. Dist2( ATail( aChain )[ OF_P1 ], aRuns[ j ][ 1 ][ 1 ][ OF_P0 ] ) < OF_JOIN_EPS
               aUsed[ j ] := .T.
               FOR EACH aNext IN aRuns[ j ][ 1 ]
                  AAdd( aChain, aNext )
               NEXT
               lFound := .T.
               EXIT
            ENDIF
         NEXT
         IF ! lFound ; EXIT ; ENDIF
      ENDDO
      AAdd( aChains, { aChain, Dist2( ATail( aChain )[ OF_P1 ], aChain[ 1 ][ OF_P0 ] ) < OF_JOIN_EPS .AND. lClosed } )
   NEXT
   FOR EACH aChain IN aChains
      aVerts := ChainToVerts( aChain[ 1 ], aChain[ 2 ] )
      IF Len( aVerts ) >= 2
         aOutV := {}
         FOR EACH v IN aVerts
            AAdd( aOutV, PV_Curved( { aOrigin[ 1 ] + v[ 1 ] * nDist, aOrigin[ 2 ] + v[ 2 ] * nDist }, v[ 3 ] ) )
         NEXT
         AAdd( aResult, PL_New( aOutV, aChain[ 2 ] ) )
      ENDIF
   NEXT
RETURN aResult
