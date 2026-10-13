/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/view/vw_scene.prg
   Fase 2 / bloque B1. Origen Rust: src/scene/convert/*.rs (entidad -> hilos)
   + scene/view/render.rs. Convierte el documento del codec portado (hash)
   en una lista de dibujo 2D lista para pintar con GDI. Logica pura (sin
   FiveWin): se prueba en consola (tests/t_viewer.prg).
   Escena = hash:
     "wires"  array de { nRgb, cLayer, aPts, aBox, nEstilo, cHandle }  aPts = { {x,y}, ... }
              nEstilo = estilo de pluma GDI (0 continua, 1 guiones, 2 puntos, 3 raya-punto)
     "fills"  array de { nRgb, aLoops, aBox, lSolid, cHandle }  (HATCH; aLoops = poligonos mundo)
     "ents"   hash handle -> entidad del codec (entidades de primer nivel)
     "texts"  array de { x, y, nAlto, nRot, cTexto, nRgb }
     "ext"    { minx, miny, maxx, maxy } o NIL
     "skipped" hash tipo -> cantidad (entidades aun no dibujadas)
   Transformacion afin 2D de INSERT: { a, b, c, d, tx, ty }
     x' = a*x + c*y + tx ;  y' = b*x + d*y + ty
----------------------------------------------------------------------------*/
#include "ocx.ch"

#define VWS_MAXDEPTH 8
#define VWS_WHITE    16777215

STATIC FUNCTION Vws_N( h, cKey, xDef )
   IF hb_HHasKey( h, cKey ) .AND. h[ cKey ] != NIL
      RETURN h[ cKey ]
   ENDIF
RETURN xDef

STATIC FUNCTION Vws_Pack( r, g, b ) ; RETURN r + g * 256 + b * 65536

/* Color de entidad -> COLORREF; -1 = no dibujar */
STATIC FUNCTION Vws_Color( c, nLayerRgb, nBlockRgb )
   LOCAL t
   DO CASE
   CASE c[ 1 ] == CK_BYLAYER ; RETURN nLayerRgb
   CASE c[ 1 ] == CK_BYBLOCK ; RETURN nBlockRgb
   CASE c[ 1 ] == CK_NONE    ; RETURN -1
   CASE c[ 1 ] == CK_RGB     ; RETURN Vws_Pack( c[ 2 ], c[ 3 ], c[ 4 ] )
   CASE c[ 1 ] == CK_INDEX
      IF c[ 2 ] == 256 ; RETURN nLayerRgb ; ENDIF
      IF c[ 2 ] == 0 ; RETURN nBlockRgb ; ENDIF
      IF c[ 2 ] > 0 .AND. c[ 2 ] < 256
         t := Aci_ToRgb( c[ 2 ] )
         IF t != NIL ; RETURN Vws_Pack( t[ 1 ], t[ 2 ], t[ 3 ] ) ; ENDIF
      ENDIF
   ENDCASE
RETURN nLayerRgb

//--- afin 2D ------------------------------------------------------------------

STATIC FUNCTION Vws_Apply( aT, x, y )
   IF aT == NIL ; RETURN { x, y } ; ENDIF
RETURN { aT[ 1 ] * x + aT[ 3 ] * y + aT[ 5 ], aT[ 2 ] * x + aT[ 4 ] * y + aT[ 6 ] }

/* P o I : primero I, luego P */
STATIC FUNCTION Vws_Compose( P, I )
   IF P == NIL ; RETURN I ; ENDIF
RETURN { P[ 1 ] * I[ 1 ] + P[ 3 ] * I[ 2 ], P[ 2 ] * I[ 1 ] + P[ 4 ] * I[ 2 ], ;
         P[ 1 ] * I[ 3 ] + P[ 3 ] * I[ 4 ], P[ 2 ] * I[ 3 ] + P[ 4 ] * I[ 4 ], ;
         P[ 1 ] * I[ 5 ] + P[ 3 ] * I[ 6 ] + P[ 5 ], P[ 2 ] * I[ 5 ] + P[ 4 ] * I[ 6 ] + P[ 6 ] }

//--- OCS -> WCS (algoritmo de eje arbitrario de AutoCAD) ------------------------
FUNCTION Vws_Ocs( vN, x, y, z )
   LOCAL nx, ny, nz, ax, ay, az, bx, by, bz, l
   IF vN == NIL ; RETURN { x, y, z } ; ENDIF
   nx := vN[ 1 ] ; ny := vN[ 2 ] ; nz := vN[ 3 ]
   IF Abs( nx ) < 0.000000001 .AND. Abs( ny ) < 0.000000001 .AND. nz > 0
      RETURN { x, y, z }
   ENDIF
   IF Abs( nx ) < 1.0 / 64.0 .AND. Abs( ny ) < 1.0 / 64.0
      ax := nz ; ay := 0.0 ; az := - nx                                            // Y x N
   ELSE
      ax := - ny ; ay := nx ; az := 0.0                                            // Z x N
   ENDIF
   l := Sqrt( ax * ax + ay * ay + az * az )
   IF l < 0.000000001 ; RETURN { x, y, z } ; ENDIF
   ax /= l ; ay /= l ; az /= l
   bx := ny * az - nz * ay ; by := nz * ax - nx * az ; bz := nx * ay - ny * ax    // N x Ax
RETURN { x * ax + y * bx + z * nx, x * ay + y * by + z * ny, x * az + y * bz + z * nz }

//--- salida -------------------------------------------------------------------
STATIC PROCEDURE Vws_Ext( oS, x, y )
   LOCAL e := oS[ "ext" ]
   IF e == NIL
      oS[ "ext" ] := { x, y, x, y }
   ELSE
      IF x < e[ 1 ] ; e[ 1 ] := x ; ENDIF
      IF y < e[ 2 ] ; e[ 2 ] := y ; ENDIF
      IF x > e[ 3 ] ; e[ 3 ] := x ; ENDIF
      IF y > e[ 4 ] ; e[ 4 ] := y ; ENDIF
   ENDIF
RETURN

/* aPts: puntos { x, y } en coordenadas de bloque; se transforman con aT */
STATIC PROCEDURE Vws_Wire( oS, aPts, nRgb, cLayer, aT )
   LOCAL a := {}, p, q, aB := NIL
   IF nRgb < 0 .OR. Len( aPts ) < 1
      RETURN
   ENDIF
   FOR EACH p IN aPts
      q := Vws_Apply( aT, p[ 1 ], p[ 2 ] )
      AAdd( a, q )
      IF aB == NIL
         aB := { q[ 1 ], q[ 2 ], q[ 1 ], q[ 2 ] }
      ELSE
         IF q[ 1 ] < aB[ 1 ] ; aB[ 1 ] := q[ 1 ] ; ENDIF
         IF q[ 2 ] < aB[ 2 ] ; aB[ 2 ] := q[ 2 ] ; ENDIF
         IF q[ 1 ] > aB[ 3 ] ; aB[ 3 ] := q[ 1 ] ; ENDIF
         IF q[ 2 ] > aB[ 4 ] ; aB[ 4 ] := q[ 2 ] ; ENDIF
      ENDIF
      Vws_Ext( oS, q[ 1 ], q[ 2 ] )
   NEXT
   AAdd( oS[ "wires" ], { nRgb, cLayer, a, aB, oS[ "_style" ], oS[ "_h" ] } )
RETURN

//--- geometria ----------------------------------------------------------------
/* arco ccw de a0 a a1 (radianes); si a1 <= a0 se suma una vuelta */
STATIC FUNCTION Vws_ArcPts( cx, cy, r, a0, a1 )
   LOCAL aP := {}, nSw := a1 - a0, nSeg, i, a
   DO WHILE nSw <= 0.0
      nSw += OCX_TAU
   ENDDO
   nSeg := Max( 6, Int( nSw / ( OCX_TAU / 96.0 ) + 0.999999 ) )
   FOR i := 0 TO nSeg
      a := a0 + nSw * i / nSeg
      AAdd( aP, { cx + r * OCX_COS( a ), cy + r * OCX_SIN( a ) } )
   NEXT
RETURN aP

/* tramo con bulge entre p1 y p2 (sin repetir p1) */
STATIC FUNCTION Vws_BulgePts( p1, p2, nB )
   LOCAL dx := p2[ 1 ] - p1[ 1 ], dy := p2[ 2 ] - p1[ 2 ], d := Sqrt( dx * dx + dy * dy )
   LOCAL h, cx, cy, r, a0, nSw, nSeg, i, aP := {}
   IF d < 0.000000000001 .OR. Abs( nB ) < 0.000000000001
      RETURN { p2 }
   ENDIF
   h := ( d / 2.0 ) * ( 1.0 - nB * nB ) / ( 2.0 * nB )
   cx := ( p1[ 1 ] + p2[ 1 ] ) / 2.0 + ( - dy / d ) * h
   cy := ( p1[ 2 ] + p2[ 2 ] ) / 2.0 + ( dx / d ) * h
   r := Sqrt( ( p1[ 1 ] - cx ) ^ 2 + ( p1[ 2 ] - cy ) ^ 2 )
   a0 := OCX_ATAN2( p1[ 2 ] - cy, p1[ 1 ] - cx )
   nSw := 4.0 * OCX_ATAN( nB )
   nSeg := Max( 2, Int( Abs( nSw ) / ( OCX_TAU / 96.0 ) + 0.999999 ) )
   IF nSeg % 2 == 1 ; nSeg++ ; ENDIF
   FOR i := 1 TO nSeg - 1
      AAdd( aP, { cx + r * OCX_COS( a0 + nSw * i / nSeg ), cy + r * OCX_SIN( a0 + nSw * i / nSeg ) } )
   NEXT
   AAdd( aP, p2 )
RETURN aP

/* aV: { {x,y,bulge}, ... } */
STATIC FUNCTION Vws_PolyPts( aV, lClosed )
   LOCAL aP := {}, i, n := Len( aV ), j, q
   IF n == 0 ; RETURN aP ; ENDIF
   AAdd( aP, { aV[ 1 ][ 1 ], aV[ 1 ][ 2 ] } )
   FOR i := 1 TO IIf( lClosed, n, n - 1 )
      j := IIf( i == n, 1, i + 1 )
      FOR EACH q IN Vws_BulgePts( aV[ i ], aV[ j ], aV[ i ][ 3 ] )
         AAdd( aP, q )
      NEXT
   NEXT
RETURN aP

//--- NURBS (Cox-de Boor racional) ----------------------------------------------
STATIC FUNCTION Vws_Basis( aK, i, p, u, nLast )
   LOCAL a, b, nA := 0.0, nB := 0.0
   IF p == 0
      IF ( u >= aK[ i + 1 ] .AND. u < aK[ i + 2 ] ) .OR. ( u == nLast .AND. aK[ i + 1 ] < aK[ i + 2 ] .AND. u == aK[ i + 2 ] )
         RETURN 1.0
      ENDIF
      RETURN 0.0
   ENDIF
   a := aK[ i + p + 1 ] - aK[ i + 1 ]
   b := aK[ i + p + 2 ] - aK[ i + 2 ]
   IF a > 0.000000000001
      nA := ( u - aK[ i + 1 ] ) / a * Vws_Basis( aK, i, p - 1, u, nLast )
   ENDIF
   IF b > 0.000000000001
      nB := ( aK[ i + p + 2 ] - u ) / b * Vws_Basis( aK, i + 1, p - 1, u, nLast )
   ENDIF
RETURN nA + nB

STATIC FUNCTION Vws_SplinePts( e )
   LOCAL aCp := e[ "control_points" ], aFp := Vws_N( e, "fit_points", {} ), aK := Vws_N( e, "knots", {} )
   LOCAL aW := Vws_N( e, "weights", {} ), nDeg := Vws_N( e, "degree", 3 ), nN := Len( aCp )
   LOCAL aP := {}, p, i, nSeg, u, u0, u1, nx, ny, nd, nBs, nWt
   IF nN >= 2 .AND. Len( aK ) == nN + nDeg + 1 .AND. nDeg >= 1
      u0 := aK[ nDeg + 1 ] ; u1 := aK[ nN + 1 ]
      IF u1 > u0
         nSeg := Max( 24, nN * 12 )
         FOR i := 0 TO nSeg
            u := u0 + ( u1 - u0 ) * i / nSeg
            nx := 0.0 ; ny := 0.0 ; nd := 0.0
            FOR p := 0 TO nN - 1
               nBs := Vws_Basis( aK, p, nDeg, u, u1 )
               IF nBs != 0.0
                  nWt := IIf( Len( aW ) == nN, aW[ p + 1 ], 1.0 )
                  nx += nBs * nWt * aCp[ p + 1 ][ 1 ]
                  ny += nBs * nWt * aCp[ p + 1 ][ 2 ]
                  nd += nBs * nWt
               ENDIF
            NEXT
            IF nd > 0.000000000001
               AAdd( aP, { nx / nd, ny / nd } )
            ENDIF
         NEXT
         IF Len( aP ) >= 2 ; RETURN aP ; ENDIF
      ENDIF
   ENDIF
   aP := {}
   FOR EACH p IN IIf( Len( aFp ) >= 2, aFp, aCp )
      AAdd( aP, { p[ 1 ], p[ 2 ] } )
   NEXT
RETURN aP

//--- texto MTEXT -> plano ---------------------------------------------------------
STATIC FUNCTION Vws_Plain( c )
   LOCAL n
   c := StrTran( c, "\P", " " )
   c := StrTran( c, "\p", " " )
   c := StrTran( c, "{", "" )
   c := StrTran( c, "}", "" )
   DO WHILE ( n := At( "\", c ) ) > 0
      IF n < Len( c ) .AND. SubStr( c, n + 1, 1 ) $ "fFcCtTqQwWaAhHlLoOkK"
         IF At( ";", SubStr( c, n ) ) > 0
            c := Left( c, n - 1 ) + SubStr( c, n + At( ";", SubStr( c, n ) ) )
            LOOP
         ENDIF
      ENDIF
      c := Left( c, n - 1 ) + SubStr( c, n + 2 )
   ENDDO
RETURN c

//--- entidades --------------------------------------------------------------------
STATIC FUNCTION Vws_LtStyle( cName )
   LOCAL c := Upper( cName )
   DO CASE
   CASE "DASHDOT" $ c .OR. "CENTER" $ c .OR. "DIVIDE" $ c .OR. "PHANTOM" $ c ; RETURN 3
   CASE "DOT" $ c ; RETURN 2
   CASE "DASH" $ c .OR. "HIDDEN" $ c .OR. "BORDER" $ c ; RETURN 1
   ENDCASE
RETURN 0

STATIC FUNCTION Vws_EntStyle( d, com, cLayer )
   LOCAL cLt := Vws_N( com, "linetype", "" ), l
   IF Upper( cLt ) == "BYBLOCK" ; RETURN 0 ; ENDIF
   IF Empty( cLt ) .OR. Upper( cLt ) == "BYLAYER"
      l := IIf( hb_HHasKey( d, "layers" ), Tb_Get( d[ "layers" ], cLayer ), NIL )
      IF l == NIL ; RETURN 0 ; ENDIF
      cLt := Vws_N( l, "line_type", "" )
   ENDIF
RETURN Vws_LtStyle( cLt )

STATIC FUNCTION Vws_LayerInfo( d, oS, cLayer )
   LOCAL l := NIL, c
   IF hb_HHasKey( d, "layers" )
      l := Tb_Get( d[ "layers" ], cLayer )
   ENDIF
   IF hb_HHasKey( oS[ "hidden" ], Upper( cLayer ) )
      RETURN { .F., VWS_WHITE }
   ENDIF
   IF l == NIL ; RETURN { .T., VWS_WHITE } ; ENDIF
   c := Vws_Color( l[ "color" ], VWS_WHITE, VWS_WHITE )
RETURN { Lyr_IsVisible( l ), IIf( c < 0, VWS_WHITE, c ) }

STATIC PROCEDURE Vws_Skip( oS, cType )
   oS[ "skipped" ][ cType ] := Vws_N( oS[ "skipped" ], cType, 0 ) + 1
RETURN

STATIC PROCEDURE Vws_Entity( d, oS, e, aT, nBlockRgb, nDepth )
   LOCAL cT := e[ "_type" ], com := e[ "common" ], aLI, nRgb, cLayer, n, i, j, p, q, aV, aP, vN
   LOCAL ax, ay, bx, by, nR, nA, nB, nC, cName, aEnts, aI, nRot, nSx, nSy, ca, sa, aBase, k
   IF Vws_N( com, "invisible", .F. )
      RETURN
   ENDIF
   cLayer := Vws_N( com, "layer", "0" )
   aLI := Vws_LayerInfo( d, oS, cLayer )
   IF ! aLI[ 1 ]
      RETURN
   ENDIF
   nRgb := Vws_Color( com[ "color" ], aLI[ 2 ], nBlockRgb )
   IF nRgb < 0
      RETURN
   ENDIF
   IF nDepth == 0
      oS[ "_h" ] := hb_ntos( Vws_N( com, "handle", 0 ) )
      oS[ "ents" ][ oS[ "_h" ] ] := e
      oS[ "_style" ] := Vws_EntStyle( d, com, cLayer )
   ENDIF
   DO CASE
   CASE cT == "LINE"
      Vws_Wire( oS, { { e[ "start" ][ 1 ], e[ "start" ][ 2 ] }, { e[ "end" ][ 1 ], e[ "end" ][ 2 ] } }, nRgb, cLayer, aT )
   CASE cT == "CIRCLE" .OR. cT == "ARC"
      vN := e[ "normal" ]
      IF cT == "CIRCLE"
         aP := Vws_ArcPts( 0.0, 0.0, e[ "radius" ], 0.0, OCX_TAU )
      ELSE
         aP := Vws_ArcPts( 0.0, 0.0, e[ "radius" ], e[ "start_angle" ], e[ "end_angle" ] )
      ENDIF
      aV := {}
      FOR EACH p IN aP
         q := Vws_Ocs( vN, e[ "center" ][ 1 ] + p[ 1 ], e[ "center" ][ 2 ] + p[ 2 ], e[ "center" ][ 3 ] )
         AAdd( aV, { q[ 1 ], q[ 2 ] } )
      NEXT
      Vws_Wire( oS, aV, nRgb, cLayer, aT )
   CASE cT == "LWPOLYLINE"
      aV := {}
      FOR EACH p IN e[ "vertices" ]
         q := Vws_Ocs( e[ "normal" ], p[ "location" ][ 1 ], p[ "location" ][ 2 ], Vws_N( e, "elevation", 0.0 ) )
         AAdd( aV, { q[ 1 ], q[ 2 ], Vws_N( p, "bulge", 0.0 ) } )
      NEXT
      Vws_Wire( oS, Vws_PolyPts( aV, e[ "is_closed" ] ), nRgb, cLayer, aT )
   CASE cT == "POLYLINE2D"
      aV := {}
      FOR EACH p IN e[ "vertices" ]
         q := Vws_Ocs( e[ "normal" ], p[ "location" ][ 1 ], p[ "location" ][ 2 ], Vws_N( e, "elevation", 0.0 ) )
         AAdd( aV, { q[ 1 ], q[ 2 ], Vws_N( p, "bulge", 0.0 ) } )
      NEXT
      Vws_Wire( oS, Vws_PolyPts( aV, hb_bitAnd( e[ "flags" ], 1 ) != 0 ), nRgb, cLayer, aT )
   CASE cT == "POLYLINE3D" .OR. cT == "POLYLINE"
      aV := {}
      FOR EACH p IN e[ "vertices" ]
         IF hb_HHasKey( p, "position" )
            AAdd( aV, { p[ "position" ][ 1 ], p[ "position" ][ 2 ], 0.0 } )
         ENDIF
      NEXT
      n := ( ValType( e[ "flags" ] ) == "H" .AND. e[ "flags" ][ "closed" ] )
      Vws_Wire( oS, Vws_PolyPts( aV, n ), nRgb, cLayer, aT )
   CASE cT == "ELLIPSE"
      ax := e[ "major_axis" ][ 1 ] ; ay := e[ "major_axis" ][ 2 ]
      vN := e[ "normal" ]
      // eje menor = normal x mayor * ratio (en WCS, solo X,Y para la proyeccion 2D)
      bx := ( vN[ 2 ] * e[ "major_axis" ][ 3 ] - vN[ 3 ] * ay ) * e[ "minor_axis_ratio" ]
      by := ( vN[ 3 ] * ax - vN[ 1 ] * e[ "major_axis" ][ 3 ] ) * e[ "minor_axis_ratio" ]
      nA := e[ "start_parameter" ] ; nB := e[ "end_parameter" ]
      DO WHILE nB <= nA
         nB += OCX_TAU
      ENDDO
      n := Max( 12, Int( ( nB - nA ) / ( OCX_TAU / 96.0 ) ) + 1 )
      aP := {}
      FOR i := 0 TO n
         nC := nA + ( nB - nA ) * i / n
         AAdd( aP, { e[ "center" ][ 1 ] + ax * OCX_COS( nC ) + bx * OCX_SIN( nC ), ;
                     e[ "center" ][ 2 ] + ay * OCX_COS( nC ) + by * OCX_SIN( nC ) } )
      NEXT
      Vws_Wire( oS, aP, nRgb, cLayer, aT )
   CASE cT == "SPLINE"
      Vws_Wire( oS, Vws_SplinePts( e ), nRgb, cLayer, aT )
   CASE cT == "POINT"
      p := e[ "location" ]
      Vws_Wire( oS, { { p[ 1 ], p[ 2 ] } }, nRgb, cLayer, aT )
   CASE cT == "SOLID" .OR. cT == "3DFACE"
      aP := {}
      FOR EACH k IN { "first_corner", "second_corner", "fourth_corner", "third_corner" }
         AAdd( aP, { e[ k ][ 1 ], e[ k ][ 2 ] } )
      NEXT
      AAdd( aP, { aP[ 1 ][ 1 ], aP[ 1 ][ 2 ] } )
      Vws_Wire( oS, aP, nRgb, cLayer, aT )
   CASE cT == "HATCH"
      Vws_Hatch( oS, e, nRgb, aT )
   CASE cT == "TEXT" .OR. cT == "MTEXT"
      p := Vws_Apply( aT, e[ "insertion_point" ][ 1 ], e[ "insertion_point" ][ 2 ] )
      nR := Vws_N( e, "rotation", 0.0 )
      IF ! ( ValType( nR ) == "N" ) ; nR := 0.0 ; ENDIF
      nA := Vws_N( e, "height", 1.0 )
      IF aT != NIL
         nA *= Sqrt( Abs( aT[ 1 ] * aT[ 4 ] - aT[ 2 ] * aT[ 3 ] ) )
         nR += OCX_ATAN2( aT[ 2 ], aT[ 1 ] )
      ENDIF
      IF ValType( Vws_N( e, "value", "" ) ) == "C"
         AAdd( oS[ "texts" ], { p[ 1 ], p[ 2 ], nA, nR, IIf( cT == "MTEXT", Vws_Plain( e[ "value" ] ), e[ "value" ] ), nRgb } )
         Vws_Ext( oS, p[ 1 ], p[ 2 ] )
      ENDIF
   CASE cT == "INSERT" .OR. cT == "MINSERT"
      IF nDepth >= VWS_MAXDEPTH ; RETURN ; ENDIF
      cName := e[ "block_name" ]
      aEnts := Doc_EntitiesInBlock( d, cName )
      IF Empty( aEnts ) ; RETURN ; ENDIF
      aBase := Vws_N( Tb_Get( d[ "block_records" ], cName ), "base_point", { 0.0, 0.0, 0.0 } )
      nRot := e[ "rotation" ] ; nSx := e[ "x_scale" ] ; nSy := e[ "y_scale" ]
      ca := OCX_COS( nRot ) ; sa := OCX_SIN( nRot )
      FOR i := 0 TO Max( 1, e[ "row_count" ] ) - 1
         FOR j := 0 TO Max( 1, e[ "column_count" ] ) - 1
            // p' = R * S * ( p - base ) + ins + R * ( j*colsp, i*rowsp )
            nA := e[ "insert_point" ][ 1 ] + ca * j * e[ "column_spacing" ] - sa * i * e[ "row_spacing" ]
            nB := e[ "insert_point" ][ 2 ] + sa * j * e[ "column_spacing" ] + ca * i * e[ "row_spacing" ]
            aI := { ca * nSx, sa * nSx, - sa * nSy, ca * nSy, 0.0, 0.0 }
            aI[ 5 ] := nA - ( aI[ 1 ] * aBase[ 1 ] + aI[ 3 ] * aBase[ 2 ] )
            aI[ 6 ] := nB - ( aI[ 2 ] * aBase[ 1 ] + aI[ 4 ] * aBase[ 2 ] )
            Vws_Block( d, oS, aEnts, Vws_Compose( aT, aI ), nRgb, nDepth + 1 )
         NEXT
      NEXT
   OTHERWISE
      IF hb_HHasKey( e, "block_name" ) .AND. ValType( e[ "block_name" ] ) == "C" .AND. ! Empty( e[ "block_name" ] ) .AND. nDepth < VWS_MAXDEPTH
         aEnts := Doc_EntitiesInBlock( d, e[ "block_name" ] )
         IF ! Empty( aEnts )
            Vws_Block( d, oS, aEnts, aT, nRgb, nDepth + 1 )
            RETURN
         ENDIF
      ENDIF
      Vws_Skip( oS, cT )
   ENDCASE
RETURN

/* puntos de un borde de HATCH */
STATIC FUNCTION Vws_EdgePts( g )
   LOCAL k := g[ "kind" ], aP := {}, v, aV, q, nA, nB, n, i, nC, ax, ay, bx, by
   DO CASE
   CASE k == "Line"
      aP := { { g[ "start" ][ 1 ], g[ "start" ][ 2 ] }, { g[ "end" ][ 1 ], g[ "end" ][ 2 ] } }
   CASE k == "CircularArc"
      nA := g[ "start_angle" ] ; nB := g[ "end_angle" ]
      IF ! g[ "counter_clockwise" ]
         aP := Vws_Rev( Vws_ArcPts( g[ "center" ][ 1 ], g[ "center" ][ 2 ], g[ "radius" ], nB, nA ) )
      ELSE
         aP := Vws_ArcPts( g[ "center" ][ 1 ], g[ "center" ][ 2 ], g[ "radius" ], nA, nB )
      ENDIF
   CASE k == "EllipticArc"
      ax := g[ "major_axis_endpoint" ][ 1 ] ; ay := g[ "major_axis_endpoint" ][ 2 ]
      bx := - ay * g[ "minor_axis_ratio" ] ; by := ax * g[ "minor_axis_ratio" ]
      nA := g[ "start_angle" ] * OCX_PI / 180.0 ; nB := g[ "end_angle" ] * OCX_PI / 180.0
      DO WHILE nB <= nA
         nB += OCX_TAU
      ENDDO
      n := Max( 12, Int( ( nB - nA ) / ( OCX_TAU / 96.0 ) + 0.999999 ) )
      FOR i := 0 TO n
         nC := nA + ( nB - nA ) * i / n
         AAdd( aP, { g[ "center" ][ 1 ] + ax * OCX_COS( nC ) + bx * OCX_SIN( nC ), g[ "center" ][ 2 ] + ay * OCX_COS( nC ) + by * OCX_SIN( nC ) } )
      NEXT
      IF ! g[ "counter_clockwise" ] ; aP := Vws_Rev( aP ) ; ENDIF
   CASE k == "Polyline"
      aV := {}
      FOR EACH v IN g[ "vertices" ]
         AAdd( aV, { v[ 1 ], v[ 2 ], v[ 3 ] } )
      NEXT
      aP := Vws_PolyPts( aV, g[ "is_closed" ] )
   CASE k == "Spline"
      FOR EACH q IN IIf( Len( g[ "fit_points" ] ) >= 2, g[ "fit_points" ], g[ "control_points" ] )
         AAdd( aP, { q[ 1 ], q[ 2 ] } )
      NEXT
   ENDCASE
RETURN aP

STATIC FUNCTION Vws_Rev( a )
   LOCAL r := {}, i
   FOR i := Len( a ) TO 1 STEP -1
      AAdd( r, a[ i ] )
   NEXT
RETURN r

STATIC PROCEDURE Vws_Hatch( oS, e, nRgb, aT )
   LOCAL pa, g, aLoops := {}, aL, aPts, p, q, aB := NIL, lSolid := e[ "is_solid" ]
   FOR EACH pa IN e[ "paths" ]
      aPts := {}
      FOR EACH g IN pa[ "edges" ]
         FOR EACH p IN Vws_EdgePts( g )
            AAdd( aPts, p )
         NEXT
      NEXT
      IF Len( aPts ) >= 3
         aL := {}
         FOR EACH p IN aPts
            q := Vws_Apply( aT, p[ 1 ], p[ 2 ] )
            AAdd( aL, q )
            Vws_Ext( oS, q[ 1 ], q[ 2 ] )
            IF aB == NIL
               aB := { q[ 1 ], q[ 2 ], q[ 1 ], q[ 2 ] }
            ELSE
               IF q[ 1 ] < aB[ 1 ] ; aB[ 1 ] := q[ 1 ] ; ENDIF
               IF q[ 2 ] < aB[ 2 ] ; aB[ 2 ] := q[ 2 ] ; ENDIF
               IF q[ 1 ] > aB[ 3 ] ; aB[ 3 ] := q[ 1 ] ; ENDIF
               IF q[ 2 ] > aB[ 4 ] ; aB[ 4 ] := q[ 2 ] ; ENDIF
            ENDIF
         NEXT
         AAdd( aLoops, aL )
      ENDIF
   NEXT
   IF Len( aLoops ) > 0
      AAdd( oS[ "fills" ], { nRgb, aLoops, aB, lSolid, oS[ "_h" ] } )
      FOR EACH aL IN aLoops
         AAdd( oS[ "wires" ], { nRgb, "", aL, aB, 0, oS[ "_h" ] } )
      NEXT
   ENDIF
RETURN

STATIC PROCEDURE Vws_Block( d, oS, aEnts, aT, nBlockRgb, nDepth )
   LOCAL e
   FOR EACH e IN aEnts
      Vws_Entity( d, oS, e, aT, nBlockRgb, nDepth )
   NEXT
RETURN

/* Entrada: d = documento del codec (Dxr_ReadString) */
/* hHidden: capas apagadas por el usuario (clave = nombre en mayusculas), opcional */
FUNCTION Vws_Build( d, hHidden )
   LOCAL oS := hb_Hash( "wires", {}, "texts", {}, "fills", {}, "ents", hb_Hash(), "ext", NIL, "skipped", hb_Hash(), ;
                        "hidden", IIf( hHidden == NIL, hb_Hash(), hHidden ), "_style", 0, "_h", "" )
   Vws_Block( d, oS, Doc_ModelSpaceEntities( d ), NIL, VWS_WHITE, 0 )
RETURN oS

FUNCTION Vws_LoadFile( cFile )
   LOCAL c := hb_MemoRead( cFile ), d
   IF Empty( c ) ; RETURN NIL ; ENDIF
   d := Dxr_ReadString( c )
   IF ! ( ValType( d ) == "H" ) ; RETURN NIL ; ENDIF
RETURN d

FUNCTION Vws_Extents( oS ) ; RETURN oS[ "ext" ]
FUNCTION Vws_WireCount( oS ) ; RETURN Len( oS[ "wires" ] )

/* capas del documento: { { cNombre, nRgb, lVisible } ... } ordenadas por nombre */
FUNCTION Vws_Layers( d, hHidden )
   LOCAL a := {}, l, c, lHid
   IF ! hb_HHasKey( d, "layers" ) ; RETURN a ; ENDIF
   FOR EACH l IN Tb_Values( d[ "layers" ] )
      c := Vws_Color( l[ "color" ], VWS_WHITE, VWS_WHITE )
      lHid := ( hHidden != NIL .AND. hb_HHasKey( hHidden, Upper( l[ "name" ] ) ) )
      AAdd( a, { l[ "name" ], IIf( c < 0, VWS_WHITE, c ), Lyr_IsVisible( l ) .AND. ! lHid } )
   NEXT
   ASort( a,,, { | x, y | Upper( x[ 1 ] ) < Upper( y[ 1 ] ) } )
RETURN a
