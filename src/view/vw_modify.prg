/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/view/vw_modify.prg
   Fase 2 / modules/draw/modify: OFFSET, TRIM, EXTEND, FILLET, CHAMFER, EXPLODE
   sobre la sesion del visor (planta, entidades LINE / ARC / CIRCLE / LWPOLYLINE).
   Comandos: OFFSET d [ex,ey sx,sy] | TRIM [x,y] | EXTEND [x,y] | FILLET r [x1,y1 x2,y2]
             | CHAMFER d1 [d2] [x1,y1 x2,y2] | EXPLODE (sobre la seleccion).
   Sin puntos en linea, los comandos piden clics junto al objeto (se toma el mas
   cercano). TRIM / EXTEND repiten hasta Intro; sin seleccion las aristas son todo
   el dibujo.
   No portado (N/A aqui): trim/extend de polilineas y splines, fillet entre
   arcos o polilineas, offset de splines.
----------------------------------------------------------------------------*/
#include "ocx.ch"

#define VM_EPS 0.000000001

STATIC FUNCTION Vm_Atan( dy, dx ) ; RETURN OCX_ATAN2( dy, dx )

STATIC FUNCTION Vm_Norm( a )
   DO WHILE a < 0.0 ; a += OCX_TAU ; ENDDO
   DO WHILE a >= OCX_TAU ; a -= OCX_TAU ; ENDDO
RETURN a

/* angulo ang dentro del arco a0..a1 antihorario */
STATIC FUNCTION Vm_InArc( a0, a1, ang )
   LOCAL n := Vm_Norm( a1 - a0 )
   IF n <= VM_EPS ; n := OCX_TAU ; ENDIF
RETURN Vm_Norm( ang - a0 ) <= n + VM_EPS

/* entidades soportadas { { h, e }, ... }; LWPOLYLINE sin expandir */
STATIC FUNCTION Vm_Ents( s )
   LOCAL a := {}, k, e
   FOR EACH k IN hb_HKeys( s[ "scene" ][ "ents" ] )
      e := Doc_GetEntity( s[ "doc" ], Val( k ) )
      IF e == NIL ; LOOP ; ENDIF
      IF e[ "_type" ] == "LINE" .OR. e[ "_type" ] == "ARC" .OR. e[ "_type" ] == "CIRCLE" .OR. e[ "_type" ] == "LWPOLYLINE"
         AAdd( a, { Val( k ), e } )
      ENDIF
   NEXT
RETURN a

STATIC FUNCTION Vm_PlSegs( e )
   LOCAL a := {}, v := e[ "vertices" ], i, n := Len( v ), l
   FOR i := 1 TO n - 1
      l := Eln_New()
      l[ "start" ] := { v[ i ][ "location" ][ 1 ], v[ i ][ "location" ][ 2 ], 0.0 }
      l[ "end" ] := { v[ i + 1 ][ "location" ][ 1 ], v[ i + 1 ][ "location" ][ 2 ], 0.0 }
      AAdd( a, l )
   NEXT
   IF n > 2 .AND. e[ "is_closed" ]
      l := Eln_New()
      l[ "start" ] := { v[ n ][ "location" ][ 1 ], v[ n ][ "location" ][ 2 ], 0.0 }
      l[ "end" ] := { v[ 1 ][ "location" ][ 1 ], v[ 1 ][ "location" ][ 2 ], 0.0 }
      AAdd( a, l )
   ENDIF
RETURN a

STATIC FUNCTION Vm_DistTo( e, x, y )
   LOCAL c, r, d, m := 1000000000.0, l
   DO CASE
   CASE e[ "_type" ] == "LINE"
      RETURN Vwp_DistSeg( x, y, e[ "start" ][ 1 ], e[ "start" ][ 2 ], e[ "end" ][ 1 ], e[ "end" ][ 2 ] )
   CASE e[ "_type" ] == "CIRCLE"
      RETURN Abs( Sqrt( ( x - e[ "center" ][ 1 ] ) ^ 2 + ( y - e[ "center" ][ 2 ] ) ^ 2 ) - e[ "radius" ] )
   CASE e[ "_type" ] == "ARC"
      c := e[ "center" ] ; r := e[ "radius" ]
      d := Sqrt( ( x - c[ 1 ] ) ^ 2 + ( y - c[ 2 ] ) ^ 2 )
      IF Vm_InArc( e[ "start_angle" ], e[ "end_angle" ], Vm_Atan( y - c[ 2 ], x - c[ 1 ] ) )
         RETURN Abs( d - r )
      ENDIF
      RETURN Min( Sqrt( ( x - c[ 1 ] - r * OCX_COS( e[ "start_angle" ] ) ) ^ 2 + ( y - c[ 2 ] - r * OCX_SIN( e[ "start_angle" ] ) ) ^ 2 ), ;
                  Sqrt( ( x - c[ 1 ] - r * OCX_COS( e[ "end_angle" ] ) ) ^ 2 + ( y - c[ 2 ] - r * OCX_SIN( e[ "end_angle" ] ) ) ^ 2 ) )
   ENDCASE
   FOR EACH l IN Vm_PlSegs( e )
      m := Min( m, Vwp_DistSeg( x, y, l[ "start" ][ 1 ], l[ "start" ][ 2 ], l[ "end" ][ 1 ], l[ "end" ][ 2 ] ) )
   NEXT
RETURN m

/* entidad mas cercana al punto: { h, e } o NIL. cTipos: tipos admitidos */
STATIC FUNCTION Vm_Pick( s, x, y, cTipos )
   LOCAL he, best := NIL, nB := 1000000000.0, d
   FOR EACH he IN Vm_Ents( s )
      IF ! ( he[ 2 ][ "_type" ] $ cTipos ) ; LOOP ; ENDIF
      d := Vm_DistTo( he[ 2 ], x, y )
      IF d < nB ; nB := d ; best := he ; ENDIF
   NEXT
RETURN best

/* aristas de corte: seleccion (o todo) sin la entidad hT; LWPOLYLINE expandida a rectas */
STATIC FUNCTION Vm_Edges( s, hT )
   LOCAL a := {}, he, l, lSel := Len( s[ "sel" ] ) > 0
   FOR EACH he IN Vm_Ents( s )
      IF he[ 1 ] == hT ; LOOP ; ENDIF
      IF lSel .AND. ! hb_HHasKey( s[ "sel" ], hb_ntos( he[ 1 ] ) ) ; LOOP ; ENDIF
      IF he[ 2 ][ "_type" ] == "LWPOLYLINE"
         FOR EACH l IN Vm_PlSegs( he[ 2 ] )
            AAdd( a, l )
         NEXT
      ELSE
         AAdd( a, he[ 2 ] )
      ENDIF
   NEXT
RETURN a

/* parametros t (sobre p + t d) donde la recta corta la arista ed (acotada) */
STATIC FUNCTION Vm_LineHits( p, d, ed )
   LOCAL a := {}, q, w, den, t, u, c, nA, nB, nC, nDisc, nSq, tt, x, y
   IF ed[ "_type" ] == "LINE"
      q := ed[ "start" ] ; w := { ed[ "end" ][ 1 ] - q[ 1 ], ed[ "end" ][ 2 ] - q[ 2 ] }
      den := d[ 1 ] * w[ 2 ] - d[ 2 ] * w[ 1 ]
      IF Abs( den ) > 0.000000000001
         t := ( ( q[ 1 ] - p[ 1 ] ) * w[ 2 ] - ( q[ 2 ] - p[ 2 ] ) * w[ 1 ] ) / den
         u := ( ( q[ 1 ] - p[ 1 ] ) * d[ 2 ] - ( q[ 2 ] - p[ 2 ] ) * d[ 1 ] ) / den
         IF u >= - 0.000000001 .AND. u <= 1.000000001 ; AAdd( a, t ) ; ENDIF
      ENDIF
      RETURN a
   ENDIF
   c := ed[ "center" ]
   nA := d[ 1 ] ^ 2 + d[ 2 ] ^ 2
   nB := 2.0 * ( d[ 1 ] * ( p[ 1 ] - c[ 1 ] ) + d[ 2 ] * ( p[ 2 ] - c[ 2 ] ) )
   nC := ( p[ 1 ] - c[ 1 ] ) ^ 2 + ( p[ 2 ] - c[ 2 ] ) ^ 2 - ed[ "radius" ] ^ 2
   nDisc := nB * nB - 4.0 * nA * nC
   IF nDisc < 0.0 .OR. nA <= 0.0 ; RETURN a ; ENDIF
   nSq := Sqrt( nDisc )
   FOR EACH tt IN { ( - nB - nSq ) / ( 2.0 * nA ), ( - nB + nSq ) / ( 2.0 * nA ) }
      x := p[ 1 ] + tt * d[ 1 ] ; y := p[ 2 ] + tt * d[ 2 ]
      IF ed[ "_type" ] == "ARC" .AND. ! Vm_InArc( ed[ "start_angle" ], ed[ "end_angle" ], Vm_Atan( y - c[ 2 ], x - c[ 1 ] ) )
         LOOP
      ENDIF
      AAdd( a, tt )
   NEXT
RETURN a

/* angulos sobre la circunferencia (c, r) donde corta la arista ed */
STATIC FUNCTION Vm_CircleHits( c, r, ed )
   LOCAL a := {}, t, p, d, x, y, c2, r2, nD, nA, nH, mx, my
   IF ed[ "_type" ] == "LINE"
      p := ed[ "start" ] ; d := { ed[ "end" ][ 1 ] - p[ 1 ], ed[ "end" ][ 2 ] - p[ 2 ] }
      FOR EACH t IN Vm_LineHits( p, d, { "_type" => "CIRCLE", "center" => c, "radius" => r } )
         IF t >= - 0.000000001 .AND. t <= 1.000000001
            AAdd( a, Vm_Atan( p[ 2 ] + t * d[ 2 ] - c[ 2 ], p[ 1 ] + t * d[ 1 ] - c[ 1 ] ) )
         ENDIF
      NEXT
      RETURN a
   ENDIF
   c2 := ed[ "center" ] ; r2 := ed[ "radius" ]
   nD := Sqrt( ( c2[ 1 ] - c[ 1 ] ) ^ 2 + ( c2[ 2 ] - c[ 2 ] ) ^ 2 )
   IF nD <= VM_EPS .OR. nD > r + r2 + VM_EPS .OR. nD < Abs( r - r2 ) - VM_EPS ; RETURN a ; ENDIF
   nA := ( r * r - r2 * r2 + nD * nD ) / ( 2.0 * nD )
   nH := Sqrt( Max( 0.0, r * r - nA * nA ) )
   mx := c[ 1 ] + nA * ( c2[ 1 ] - c[ 1 ] ) / nD ; my := c[ 2 ] + nA * ( c2[ 2 ] - c[ 2 ] ) / nD
   FOR EACH t IN { 1.0, -1.0 }
      x := mx - t * nH * ( c2[ 2 ] - c[ 2 ] ) / nD ; y := my + t * nH * ( c2[ 1 ] - c[ 1 ] ) / nD
      IF ed[ "_type" ] == "ARC" .AND. ! Vm_InArc( ed[ "start_angle" ], ed[ "end_angle" ], Vm_Atan( y - c2[ 2 ], x - c2[ 1 ] ) )
         LOOP
      ENDIF
      AAdd( a, Vm_Atan( y - c[ 2 ], x - c[ 1 ] ) )
      IF nH <= VM_EPS ; EXIT ; ENDIF
   NEXT
RETURN a

STATIC FUNCTION Vm_NewH( e )
   e[ "common" ][ "handle" ] := Hd_Null()
RETURN e

/* ---- OFFSET --------------------------------------------------------------------- */
STATIC FUNCTION Vm_PlFrom( e )
   LOCAL a := {}, v
   FOR EACH v IN e[ "vertices" ]
      AAdd( a, PV_Curved( { v[ "location" ][ 1 ], v[ "location" ][ 2 ] }, v[ "bulge" ] ) )
   NEXT
RETURN PL_New( a, e[ "is_closed" ] )

FUNCTION Vwe_Offset( s, h, e, nD, x, y )
   LOCAL c, n, nL, nSg, aOut, pl, i, w, nR, aNew := {}, aOps := {}, hN
   IF h == NIL ; RETURN "" ; ENDIF
   DO CASE
   CASE e[ "_type" ] == "LINE"
      nL := Sqrt( ( e[ "end" ][ 1 ] - e[ "start" ][ 1 ] ) ^ 2 + ( e[ "end" ][ 2 ] - e[ "start" ][ 2 ] ) ^ 2 )
      IF nL <= 0.0 ; RETURN "Linea de longitud nula" ; ENDIF
      n := { - ( e[ "end" ][ 2 ] - e[ "start" ][ 2 ] ) / nL, ( e[ "end" ][ 1 ] - e[ "start" ][ 1 ] ) / nL }
      nSg := IIf( ( x - e[ "start" ][ 1 ] ) * n[ 1 ] + ( y - e[ "start" ][ 2 ] ) * n[ 2 ] >= 0.0, 1.0, -1.0 )
      c := Vm_NewH( Ent_Clone( e ) )
      c[ "start" ][ 1 ] += nSg * nD * n[ 1 ] ; c[ "start" ][ 2 ] += nSg * nD * n[ 2 ]
      c[ "end" ][ 1 ] += nSg * nD * n[ 1 ] ; c[ "end" ][ 2 ] += nSg * nD * n[ 2 ]
      AAdd( aNew, c )
   CASE e[ "_type" ] == "CIRCLE" .OR. e[ "_type" ] == "ARC"
      nR := e[ "radius" ] + IIf( Sqrt( ( x - e[ "center" ][ 1 ] ) ^ 2 + ( y - e[ "center" ][ 2 ] ) ^ 2 ) > e[ "radius" ], nD, - nD )
      IF nR <= 0.0 ; RETURN "El desfase colapsa el radio" ; ENDIF
      c := Vm_NewH( Ent_Clone( e ) )
      c[ "radius" ] := nR
      AAdd( aNew, c )
   OTHERWISE
      pl := Vm_PlFrom( e )
      aOut := Ofs_OffsetPolyline( pl, nD, { x, y } )
      IF Len( aOut ) == 0 ; RETURN "No se pudo desfasar la polilinea" ; ENDIF
      FOR EACH w IN aOut
         c := Vm_NewH( Ent_Clone( e ) )
         c[ "vertices" ] := {}
         FOR i := 1 TO Len( w[ PL_VERTS ] )
            Elw_AddPointWithBulge( c, { w[ PL_VERTS ][ i ][ PV_POS ][ 1 ], w[ PL_VERTS ][ i ][ PV_POS ][ 2 ] }, w[ PL_VERTS ][ i ][ PV_BULGE ] )
         NEXT
         c[ "is_closed" ] := w[ PL_CLOSED ]
         AAdd( aNew, c )
      NEXT
   ENDCASE
   FOR EACH c IN aNew
      hN := Doc_AddEntity( s[ "doc" ], c )
      AAdd( aOps, { "add", hN } )
   NEXT
   Vwe_Push( s, aOps )
   VwS_Rebuild( s )
RETURN ""

/* ---- TRIM / EXTEND --------------------------------------------------------------- */
STATIC FUNCTION Vm_TrimLine( s, h, e, x, y )
   LOCAL p := e[ "start" ], d := { e[ "end" ][ 1 ] - e[ "start" ][ 1 ], e[ "end" ][ 2 ] - e[ "start" ][ 2 ] }
   LOCAL nL2 := d[ 1 ] ^ 2 + d[ 2 ] ^ 2, tc, tl := NIL, tu := NIL, t, ed, aOps, eM, c
   IF nL2 <= 0.0 ; RETURN "Linea de longitud nula" ; ENDIF
   tc := ( ( x - p[ 1 ] ) * d[ 1 ] + ( y - p[ 2 ] ) * d[ 2 ] ) / nL2
   FOR EACH ed IN Vm_Edges( s, h )
      FOR EACH t IN Vm_LineHits( p, d, ed )
         IF t <= VM_EPS .OR. t >= 1.0 - VM_EPS ; LOOP ; ENDIF
         IF t < tc .AND. ( tl == NIL .OR. t > tl ) ; tl := t ; ENDIF
         IF t > tc .AND. ( tu == NIL .OR. t < tu ) ; tu := t ; ENDIF
      NEXT
   NEXT
   IF tl == NIL .AND. tu == NIL ; RETURN "TRIM: no hay interseccion con las aristas" ; ENDIF
   aOps := { { "mod", h, Ent_Clone( e ) } }
   eM := Doc_GetEntityMut( s[ "doc" ], h )
   IF tl != NIL .AND. tu != NIL
      c := Vm_NewH( Ent_Clone( eM ) )
      c[ "start" ] := { p[ 1 ] + tu * d[ 1 ], p[ 2 ] + tu * d[ 2 ], 0.0 }
      AAdd( aOps, { "add", Doc_AddEntity( s[ "doc" ], c ) } )
   ENDIF
   IF tl != NIL
      eM[ "end" ] := { p[ 1 ] + tl * d[ 1 ], p[ 2 ] + tl * d[ 2 ], 0.0 }
   ELSE
      eM[ "start" ] := { p[ 1 ] + tu * d[ 1 ], p[ 2 ] + tu * d[ 2 ], 0.0 }
   ENDIF
   Vwe_Push( s, aOps )
RETURN ""

STATIC FUNCTION Vm_TrimArc( s, h, e, x, y )
   LOCAL c := e[ "center" ], r := e[ "radius" ], lCirc := e[ "_type" ] == "CIRCLE", a0, nN, ac, ed, a, m, ml := NIL, mu := NIL
   LOCAL aOps, eM, cl, nPrev, nNext, nBest, nBestP, ea
   ac := Vm_Atan( y - c[ 2 ], x - c[ 1 ] )
   IF lCirc
      nNext := NIL ; nPrev := NIL ; nBest := 1000.0 ; nBestP := 1000.0
      FOR EACH ed IN Vm_Edges( s, h )
         FOR EACH a IN Vm_CircleHits( c, r, ed )
            m := Vm_Norm( a - ac )
            IF m < nBest ; nBest := m ; nNext := a ; ENDIF
            IF OCX_TAU - m < nBestP ; nBestP := OCX_TAU - m ; nPrev := a ; ENDIF
         NEXT
      NEXT
      IF nNext == NIL .OR. Abs( Vm_Norm( nNext - nPrev ) ) <= VM_EPS .OR. Vm_Norm( nNext - nPrev ) >= OCX_TAU - VM_EPS
         RETURN "TRIM: el circulo necesita al menos dos intersecciones"
      ENDIF
      aOps := { { "del", Ent_Clone( e ) } }
      ea := Ear_New()
      ea[ "common" ] := hb_HClone( e[ "common" ] ) ; ea[ "common" ][ "handle" ] := Hd_Null()
      ea[ "center" ] := { c[ 1 ], c[ 2 ], c[ 3 ] } ; ea[ "radius" ] := r ; ea[ "normal" ] := e[ "normal" ]
      ea[ "start_angle" ] := nNext ; ea[ "end_angle" ] := nPrev
      Doc_RemoveEntity( s[ "doc" ], h )
      AAdd( aOps, { "add", Doc_AddEntity( s[ "doc" ], ea ) } )
      Vwe_Push( s, aOps )
      RETURN ""
   ENDIF
   a0 := e[ "start_angle" ] ; nN := Vm_Norm( e[ "end_angle" ] - a0 )
   IF nN <= VM_EPS ; nN := OCX_TAU ; ENDIF
   ac := Vm_Norm( ac - a0 )
   FOR EACH ed IN Vm_Edges( s, h )
      FOR EACH a IN Vm_CircleHits( c, r, ed )
         m := Vm_Norm( a - a0 )
         IF m <= VM_EPS .OR. m >= nN - VM_EPS ; LOOP ; ENDIF
         IF m < ac .AND. ( ml == NIL .OR. m > ml ) ; ml := m ; ENDIF
         IF m > ac .AND. ( mu == NIL .OR. m < mu ) ; mu := m ; ENDIF
      NEXT
   NEXT
   IF ml == NIL .AND. mu == NIL ; RETURN "TRIM: no hay interseccion con las aristas" ; ENDIF
   aOps := { { "mod", h, Ent_Clone( e ) } }
   eM := Doc_GetEntityMut( s[ "doc" ], h )
   IF ml != NIL .AND. mu != NIL
      cl := Vm_NewH( Ent_Clone( eM ) )
      cl[ "start_angle" ] := a0 + mu
      AAdd( aOps, { "add", Doc_AddEntity( s[ "doc" ], cl ) } )
   ENDIF
   IF ml != NIL
      eM[ "end_angle" ] := a0 + ml
   ELSE
      eM[ "start_angle" ] := a0 + mu
   ENDIF
   Vwe_Push( s, aOps )
RETURN ""

STATIC FUNCTION Vm_ExtendLine( s, h, e, x, y )
   LOCAL p := e[ "start" ], d := { e[ "end" ][ 1 ] - e[ "start" ][ 1 ], e[ "end" ][ 2 ] - e[ "start" ][ 2 ] }
   LOCAL nL2 := d[ 1 ] ^ 2 + d[ 2 ] ^ 2, tc, lEnd, tb := NIL, t, ed, aOps, eM
   IF nL2 <= 0.0 ; RETURN "Linea de longitud nula" ; ENDIF
   tc := ( ( x - p[ 1 ] ) * d[ 1 ] + ( y - p[ 2 ] ) * d[ 2 ] ) / nL2
   lEnd := tc >= 0.5
   FOR EACH ed IN Vm_Edges( s, h )
      FOR EACH t IN Vm_LineHits( p, d, ed )
         IF lEnd .AND. t > 1.0 + VM_EPS .AND. ( tb == NIL .OR. t < tb ) ; tb := t ; ENDIF
         IF ! lEnd .AND. t < - VM_EPS .AND. ( tb == NIL .OR. t > tb ) ; tb := t ; ENDIF
      NEXT
   NEXT
   IF tb == NIL ; RETURN "EXTEND: ninguna arista alcanza ese extremo" ; ENDIF
   aOps := { { "mod", h, Ent_Clone( e ) } }
   eM := Doc_GetEntityMut( s[ "doc" ], h )
   IF lEnd
      eM[ "end" ] := { p[ 1 ] + tb * d[ 1 ], p[ 2 ] + tb * d[ 2 ], 0.0 }
   ELSE
      eM[ "start" ] := { p[ 1 ] + tb * d[ 1 ], p[ 2 ] + tb * d[ 2 ], 0.0 }
   ENDIF
   Vwe_Push( s, aOps )
RETURN ""

/* ---- FILLET / CHAMFER (entre dos rectas) ---------------------------------------- */
STATIC FUNCTION Vm_Corner( s, h1, h2, p1, p2, nR, lChamfer, nD2 )
   LOCAL e1 := Doc_GetEntity( s[ "doc" ], h1 ), e2 := Doc_GetEntity( s[ "doc" ], h2 ), d1, d2, den, t, aP, u1, u2, nL
   LOCAL nCos, nTh, nT1, nT2, aT1, aT2, b, nB, aC, a1, a2, aOps, eM, ea, lKeep
   IF h1 == h2 ; RETURN "Elija dos rectas distintas" ; ENDIF
   d1 := { e1[ "end" ][ 1 ] - e1[ "start" ][ 1 ], e1[ "end" ][ 2 ] - e1[ "start" ][ 2 ] }
   d2 := { e2[ "end" ][ 1 ] - e2[ "start" ][ 1 ], e2[ "end" ][ 2 ] - e2[ "start" ][ 2 ] }
   den := d1[ 1 ] * d2[ 2 ] - d1[ 2 ] * d2[ 1 ]
   IF Abs( den ) <= 0.000000000001 ; RETURN "Las rectas son paralelas" ; ENDIF
   t := ( ( e2[ "start" ][ 1 ] - e1[ "start" ][ 1 ] ) * d2[ 2 ] - ( e2[ "start" ][ 2 ] - e1[ "start" ][ 2 ] ) * d2[ 1 ] ) / den
   aP := { e1[ "start" ][ 1 ] + t * d1[ 1 ], e1[ "start" ][ 2 ] + t * d1[ 2 ] }
   nL := Sqrt( d1[ 1 ] ^ 2 + d1[ 2 ] ^ 2 )
   u1 := { d1[ 1 ] / nL, d1[ 2 ] / nL }
   IF ( p1[ 1 ] - aP[ 1 ] ) * u1[ 1 ] + ( p1[ 2 ] - aP[ 2 ] ) * u1[ 2 ] < 0.0 ; u1 := { - u1[ 1 ], - u1[ 2 ] } ; ENDIF
   nL := Sqrt( d2[ 1 ] ^ 2 + d2[ 2 ] ^ 2 )
   u2 := { d2[ 1 ] / nL, d2[ 2 ] / nL }
   IF ( p2[ 1 ] - aP[ 1 ] ) * u2[ 1 ] + ( p2[ 2 ] - aP[ 2 ] ) * u2[ 2 ] < 0.0 ; u2 := { - u2[ 1 ], - u2[ 2 ] } ; ENDIF
   nCos := u1[ 1 ] * u2[ 1 ] + u1[ 2 ] * u2[ 2 ]
   nTh := OCX_ATAN2( Abs( u1[ 1 ] * u2[ 2 ] - u1[ 2 ] * u2[ 1 ] ), nCos )
   IF lChamfer
      nT1 := nR ; nT2 := nD2
   ELSEIF nR <= 0.0
      nT1 := 0.0 ; nT2 := 0.0
   ELSE
      nT1 := nR / OCX_TAN( nTh / 2.0 ) ; nT2 := nT1
   ENDIF
   aT1 := { aP[ 1 ] + u1[ 1 ] * nT1, aP[ 2 ] + u1[ 2 ] * nT1 }
   aT2 := { aP[ 1 ] + u2[ 1 ] * nT2, aP[ 2 ] + u2[ 2 ] * nT2 }
   lKeep := .T.
   FOR EACH b IN { { e1, u1, aT1 }, { e2, u2, aT2 } }
      IF Max( ( b[ 1 ][ "start" ][ 1 ] - b[ 3 ][ 1 ] ) * b[ 2 ][ 1 ] + ( b[ 1 ][ "start" ][ 2 ] - b[ 3 ][ 2 ] ) * b[ 2 ][ 2 ], ;
              ( b[ 1 ][ "end" ][ 1 ] - b[ 3 ][ 1 ] ) * b[ 2 ][ 1 ] + ( b[ 1 ][ "end" ][ 2 ] - b[ 3 ][ 2 ] ) * b[ 2 ][ 2 ] ) <= VM_EPS
         lKeep := .F.
      ENDIF
   NEXT
   IF ! lKeep ; RETURN "El radio / distancia es demasiado grande para las rectas" ; ENDIF
   aOps := { { "mod", h1, Ent_Clone( e1 ) }, { "mod", h2, Ent_Clone( e2 ) } }
   FOR EACH b IN { { h1, u1, aT1 }, { h2, u2, aT2 } }
      eM := Doc_GetEntityMut( s[ "doc" ], b[ 1 ] )
      nB := ( eM[ "start" ][ 1 ] - aP[ 1 ] ) * b[ 2 ][ 1 ] + ( eM[ "start" ][ 2 ] - aP[ 2 ] ) * b[ 2 ][ 2 ]
      IF nB < ( eM[ "end" ][ 1 ] - aP[ 1 ] ) * b[ 2 ][ 1 ] + ( eM[ "end" ][ 2 ] - aP[ 2 ] ) * b[ 2 ][ 2 ]
         eM[ "start" ] := { b[ 3 ][ 1 ], b[ 3 ][ 2 ], 0.0 }
      ELSE
         eM[ "end" ] := { b[ 3 ][ 1 ], b[ 3 ][ 2 ], 0.0 }
      ENDIF
   NEXT
   IF lChamfer .AND. ( nT1 > 0.0 .OR. nT2 > 0.0 )
      ea := Eln_New()
      ea[ "common" ] := hb_HClone( e1[ "common" ] ) ; ea[ "common" ][ "handle" ] := Hd_Null()
      ea[ "start" ] := { aT1[ 1 ], aT1[ 2 ], 0.0 } ; ea[ "end" ] := { aT2[ 1 ], aT2[ 2 ], 0.0 }
      AAdd( aOps, { "add", Doc_AddEntity( s[ "doc" ], ea ) } )
   ELSEIF ! lChamfer .AND. nR > 0.0
      nB := nR / OCX_SIN( nTh / 2.0 )
      b := { u1[ 1 ] + u2[ 1 ], u1[ 2 ] + u2[ 2 ] }
      nL := Sqrt( b[ 1 ] ^ 2 + b[ 2 ] ^ 2 )
      aC := { aP[ 1 ] + b[ 1 ] / nL * nB, aP[ 2 ] + b[ 2 ] / nL * nB }
      a1 := OCX_ATAN2( aT1[ 2 ] - aC[ 2 ], aT1[ 1 ] - aC[ 1 ] )
      a2 := OCX_ATAN2( aT2[ 2 ] - aC[ 2 ], aT2[ 1 ] - aC[ 1 ] )
      ea := Ear_New()
      ea[ "common" ] := hb_HClone( e1[ "common" ] ) ; ea[ "common" ][ "handle" ] := Hd_Null()
      ea[ "center" ] := { aC[ 1 ], aC[ 2 ], 0.0 } ; ea[ "radius" ] := nR
      IF ( aT1[ 1 ] - aC[ 1 ] ) * ( aT2[ 2 ] - aC[ 2 ] ) - ( aT1[ 2 ] - aC[ 2 ] ) * ( aT2[ 1 ] - aC[ 1 ] ) > 0.0
         ea[ "start_angle" ] := a1 ; ea[ "end_angle" ] := a2
      ELSE
         ea[ "start_angle" ] := a2 ; ea[ "end_angle" ] := a1
      ENDIF
      AAdd( aOps, { "add", Doc_AddEntity( s[ "doc" ], ea ) } )
   ENDIF
   Vwe_Push( s, aOps )
RETURN ""

/* ---- EXPLODE ---------------------------------------------------------------------- */
FUNCTION Vwe_Explode( s )
   LOCAL aOps := {}, h, e, v, i, n, nB, p0, p1, nCh, nTh, nHc, nDc, aC, c, nSeg := 0, aSegs, lN := 0
   FOR EACH h IN hb_HKeys( s[ "sel" ] )
      e := Doc_GetEntity( s[ "doc" ], Val( h ) )
      IF e == NIL .OR. ! ( e[ "_type" ] == "LWPOLYLINE" ) ; LOOP ; ENDIF
      v := e[ "vertices" ] ; n := Len( v )
      aSegs := IIf( n > 2 .AND. e[ "is_closed" ], n, n - 1 )
      FOR i := 1 TO aSegs
         p0 := v[ i ][ "location" ] ; p1 := v[ i % n + 1 ][ "location" ] ; nB := v[ i ][ "bulge" ]
         IF Abs( nB ) <= VM_EPS
            c := Eln_New()
            c[ "start" ] := { p0[ 1 ], p0[ 2 ], 0.0 } ; c[ "end" ] := { p1[ 1 ], p1[ 2 ], 0.0 }
         ELSE
            nCh := Sqrt( ( p1[ 1 ] - p0[ 1 ] ) ^ 2 + ( p1[ 2 ] - p0[ 2 ] ) ^ 2 )
            IF nCh <= 0.0 ; LOOP ; ENDIF
            nTh := 4.0 * OCX_ATAN2( nB, 1.0 )
            nHc := nCh / 2.0
            nDc := nHc / OCX_TAN( nTh / 2.0 )
            aC := { ( p0[ 1 ] + p1[ 1 ] ) / 2.0 - ( p1[ 2 ] - p0[ 2 ] ) / nCh * nDc, ( p0[ 2 ] + p1[ 2 ] ) / 2.0 + ( p1[ 1 ] - p0[ 1 ] ) / nCh * nDc }
            c := Ear_New()
            c[ "center" ] := { aC[ 1 ], aC[ 2 ], 0.0 } ; c[ "radius" ] := Abs( nHc / OCX_SIN( nTh / 2.0 ) )
            IF nB > 0.0
               c[ "start_angle" ] := OCX_ATAN2( p0[ 2 ] - aC[ 2 ], p0[ 1 ] - aC[ 1 ] ) ; c[ "end_angle" ] := OCX_ATAN2( p1[ 2 ] - aC[ 2 ], p1[ 1 ] - aC[ 1 ] )
            ELSE
               c[ "start_angle" ] := OCX_ATAN2( p1[ 2 ] - aC[ 2 ], p1[ 1 ] - aC[ 1 ] ) ; c[ "end_angle" ] := OCX_ATAN2( p0[ 2 ] - aC[ 2 ], p0[ 1 ] - aC[ 1 ] )
            ENDIF
         ENDIF
         c[ "common" ] := hb_HClone( e[ "common" ] ) ; c[ "common" ][ "handle" ] := Hd_Null()
         AAdd( aOps, { "add", Doc_AddEntity( s[ "doc" ], c ) } )
         nSeg++
      NEXT
      AAdd( aOps, { "del", Ent_Clone( e ) } )
      Doc_RemoveEntity( s[ "doc" ], Val( h ) )
      lN++
   NEXT
   IF lN == 0 ; RETURN 0 ; ENDIF
   Vwe_Push( s, aOps )
   VwS_Rebuild( s )
   s[ "sel" ] := hb_Hash()
RETURN nSeg

/* ---- comandos --------------------------------------------------------------------- */
FUNCTION VwM_Cmd( s, cK, aTok )
   LOCAL i := 2, p, r := NIL, n1, n2, k
   IF VwC_Is3D( s[ "cam" ] )
      RETURN Vk_Res( "Vuelva a la planta (VISTA SUP) para dibujar o editar" )
   ENDIF
   IF cK == "EXPLODE"
      IF Len( s[ "sel" ] ) == 0 ; RETURN Vk_Res( "Primero seleccione objetos (clic, caja o SELTODO)" ) ; ENDIF
      k := Vwe_Explode( s )
      RETURN Vk_Res( hb_ntos( k ) + " segmento(s) generado(s)", , .T. )
   ENDIF
   s[ "pend" ] := hb_Hash( "cmd", cK, "pts", {}, "d", 0.0, "d2", 0.0 )
   IF cK == "OFFSET" .OR. cK == "FILLET" .OR. cK == "CHAMFER"
      IF Len( aTok ) < 2 .OR. ! Vk_IsNum( aTok[ 2 ] ) .OR. At( ",", aTok[ 2 ] ) > 0
         s[ "pend" ] := NIL
         RETURN Vk_Res( "Uso: " + IIf( cK == "OFFSET", "OFFSET distancia [ex,ey sx,sy]", IIf( cK == "FILLET", "FILLET radio [x1,y1 x2,y2]", "CHAMFER d1 [d2] [x1,y1 x2,y2]" ) ) )
      ENDIF
      n1 := Val( aTok[ 2 ] ) ; n2 := n1 ; i := 3
      IF cK == "CHAMFER" .AND. Len( aTok ) >= 3 .AND. Vk_IsNum( aTok[ 3 ] ) .AND. At( ",", aTok[ 3 ] ) == 0
         n2 := Val( aTok[ 3 ] ) ; i := 4
      ENDIF
      IF n1 < 0.0 .OR. n2 < 0.0 .OR. ( ! ( cK == "FILLET" ) .AND. n1 <= 0.0 )
         s[ "pend" ] := NIL
         RETURN Vk_Res( cK + ": valor no valido" )
      ENDIF
      s[ "pend" ][ "d" ] := n1 ; s[ "pend" ][ "d2" ] := n2
   ENDIF
   DO WHILE Len( aTok ) >= i
      p := Vk_Pt( aTok, i )
      IF p == NIL
         s[ "pend" ] := NIL
         RETURN Vk_Res( "Argumento no valido: " + aTok[ i ] )
      ENDIF
      i += IIf( At( ",", aTok[ i ] ) > 0, 1, 2 )
      r := VwK_Point( s, p[ 1 ], p[ 2 ] )
      IF s[ "pend" ] == NIL ; EXIT ; ENDIF
   ENDDO
   IF r != NIL ; RETURN r ; ENDIF
RETURN Vk_Res( VwM_Prompt( s[ "pend" ] ) )

FUNCTION VwM_Prompt( pe )
   LOCAL n := Len( pe[ "pts" ] )
   DO CASE
   CASE pe[ "cmd" ] == "OFFSET" ; RETURN IIf( n == 0, "OFFSET: clic en el objeto (Intro termina)", "OFFSET: clic en el lado del desfase" )
   CASE pe[ "cmd" ] == "TRIM" ; RETURN "TRIM: clic en la parte a recortar (Intro termina)"
   CASE pe[ "cmd" ] == "EXTEND" ; RETURN "EXTEND: clic junto al extremo a alargar (Intro termina)"
   ENDCASE
RETURN pe[ "cmd" ] + IIf( n == 0, ": clic en la primera recta", ": clic en la segunda recta" )

/* punto recibido; NIL si el comando no es de este fichero */
FUNCTION VwM_Point( s, pe, x, y )
   LOCAL cK := pe[ "cmd" ], n := Len( pe[ "pts" ] ), he, cMsg
   IF ! ( cK == "OFFSET" .OR. cK == "TRIM" .OR. cK == "EXTEND" .OR. cK == "FILLET" .OR. cK == "CHAMFER" ) ; RETURN NIL ; ENDIF
   DO CASE
   CASE cK == "OFFSET" .AND. n == 1
      he := Vm_Pick( s, x, y, "LINE ARC CIRCLE LWPOLYLINE" )
      IF he == NIL ; pe[ "pts" ] := {} ; RETURN Vk_Res( "OFFSET: no hay objetos" ) ; ENDIF
      pe[ "h" ] := he[ 1 ]
      RETURN Vk_Res( VwM_Prompt( pe ) )
   CASE cK == "OFFSET"
      he := Doc_GetEntity( s[ "doc" ], pe[ "h" ] )
      pe[ "pts" ] := {}
      IF he == NIL ; RETURN Vk_Res( "OFFSET: objeto no encontrado" ) ; ENDIF
      cMsg := Vwe_Offset( s, pe[ "h" ], he, pe[ "d" ], x, y )
      RETURN Vk_Res( IIf( Empty( cMsg ), "Desfase creado - " + VwM_Prompt( pe ), cMsg ), , Empty( cMsg ) )
   CASE cK == "TRIM" .OR. cK == "EXTEND"
      pe[ "pts" ] := {}
      he := Vm_Pick( s, x, y, IIf( cK == "TRIM", "LINE ARC CIRCLE", "LINE" ) )
      IF he == NIL ; RETURN Vk_Res( cK + ": no hay objetos validos" ) ; ENDIF
      IF cK == "EXTEND"
         cMsg := Vm_ExtendLine( s, he[ 1 ], he[ 2 ], x, y )
      ELSEIF he[ 2 ][ "_type" ] == "LINE"
         cMsg := Vm_TrimLine( s, he[ 1 ], he[ 2 ], x, y )
      ELSE
         cMsg := Vm_TrimArc( s, he[ 1 ], he[ 2 ], x, y )
      ENDIF
      IF ! Empty( cMsg ) ; RETURN Vk_Res( cMsg ) ; ENDIF
      VwS_Rebuild( s )
      RETURN Vk_Res( cK + " hecho - " + VwM_Prompt( pe ), , .T. )
   CASE n == 1
      he := Vm_Pick( s, x, y, "LINE" )
      IF he == NIL ; pe[ "pts" ] := {} ; RETURN Vk_Res( cK + ": no hay rectas" ) ; ENDIF
      pe[ "h" ] := he[ 1 ]
      RETURN Vk_Res( VwM_Prompt( pe ) )
   ENDCASE
   // FILLET / CHAMFER, segundo clic
   s[ "pend" ] := NIL
   he := Vm_Pick( s, x, y, "LINE" )
   IF he == NIL ; RETURN Vk_Res( cK + ": no hay rectas" ) ; ENDIF
   cMsg := Vm_Corner( s, pe[ "h" ], he[ 1 ], pe[ "pts" ][ 1 ], pe[ "pts" ][ 2 ], pe[ "d" ], cK == "CHAMFER", pe[ "d2" ] )
   IF ! Empty( cMsg ) ; RETURN Vk_Res( cMsg ) ; ENDIF
   VwS_Rebuild( s )
RETURN Vk_Res( IIf( cK == "FILLET", "Empalme creado", "Chaflan creado" ), , .T. )
