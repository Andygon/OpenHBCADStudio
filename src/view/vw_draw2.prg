/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/view/vw_draw2.prg
   Fase 2 / modules/draw: ELLIPSE, SPLINE (draw), ARRAYRECT, ARRAYPOLAR, STRETCH
   (modify) y AREA (inquiry) sobre la sesion del visor.
   ELLIPSE cx,cy ax,ay bx,by (centro, extremo del eje mayor, punto del menor)
   SPLINE p1 p2 p3 ... (por puntos de ajuste; Intro termina; NC_Interpolate)
   ARRAYRECT filas columnas dx dy | ARRAYPOLAR cx,cy n [angulo]  (sobre la seleccion)
   STRETCH x1,y1 x2,y2 bx,by dx,dy (ventana de captura, base, destino)
   AREA [x1,y1 x2,y2 x3,y3 ...] (area y perimetro de la seleccion o de los puntos)
   No portado (N/A): ARRAYPATH, ARRAYCLASSIC con asociatividad, spline por vertices de control.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Vwe_Ellipse( s, pC, pA, pB )
   LOCAL e := Eel_New(), nMaj := Sqrt( ( pA[ 1 ] - pC[ 1 ] ) ^ 2 + ( pA[ 2 ] - pC[ 2 ] ) ^ 2 )
   LOCAL nX := pA[ 1 ] - pC[ 1 ], nY := pA[ 2 ] - pC[ 2 ], nMin
   IF nMaj <= 0.0 ; RETURN 0 ; ENDIF
   // distancia del punto B al eje mayor
   nMin := Abs( ( pB[ 1 ] - pC[ 1 ] ) * nY - ( pB[ 2 ] - pC[ 2 ] ) * nX ) / nMaj
   IF nMin <= 0.0 ; RETURN 0 ; ENDIF
   e[ "center" ] := { pC[ 1 ], pC[ 2 ], 0.0 } ; e[ "major_axis" ] := { nX, nY, 0.0 } ; e[ "minor_axis_ratio" ] := Min( nMin / nMaj, 1.0 )
RETURN Vwe_Add( s, e )

FUNCTION Vwe_Spline( s, aPts )
   LOCAL c := NC_Interpolate( aPts, NIL, NIL, PZ_CHORD ), e, p
   IF c == NIL ; RETURN 0 ; ENDIF
   e := Esp_New()
   e[ "degree" ] := c[ 1 ] ; e[ "knots" ] := c[ 2 ] ; e[ "weights" ] := c[ 4 ]
   FOR EACH p IN c[ 3 ]
      AAdd( e[ "control_points" ], { p[ 1 ], p[ 2 ], 0.0 } )
   NEXT
   FOR EACH p IN aPts
      AAdd( e[ "fit_points" ], { p[ 1 ], p[ 2 ], 0.0 } )
   NEXT
RETURN Vwe_Add( s, e )

STATIC FUNCTION Vd_Sel( s )
   LOCAL a := {}, k
   FOR EACH k IN hb_HKeys( s[ "sel" ] )
      IF Doc_GetEntity( s[ "doc" ], Val( k ) ) != NIL ; AAdd( a, Val( k ) ) ; ENDIF
   NEXT
RETURN a

/* matriz: cKind "R" ( nFil, nCol, dx, dy ) o "P" ( cx, cy, n, grados ); devuelve copias creadas */
FUNCTION Vwe_Array( s, cKind, a1, a2, a3, a4 )
   LOCAL aOps := {}, h, e, c, r, k, n := 0, nStep
   FOR EACH h IN Vd_Sel( s )
      e := Doc_GetEntity( s[ "doc" ], h )
      IF cKind == "R"
         FOR r := 0 TO a1 - 1
            FOR k := 0 TO a2 - 1
               IF r == 0 .AND. k == 0 ; LOOP ; ENDIF
               c := Ent_Clone( e ) ; c[ "common" ][ "handle" ] := Hd_Null()
               Ent_Translate( c, { k * a3, r * a4, 0.0 } )
               AAdd( aOps, { "add", Doc_AddEntity( s[ "doc" ], c ) } ) ; n++
            NEXT
         NEXT
      ELSE
         nStep := IIf( Abs( a4 - 360.0 ) < 0.000001, a4 / a3, a4 / Max( a3 - 1, 1 ) )
         FOR k := 1 TO a3 - 1
            c := Ent_Clone( e ) ; c[ "common" ][ "handle" ] := Hd_Null()
            Ent_Translate( c, { - a1[ 1 ], - a1[ 2 ], 0.0 } )
            Ent_ApplyRotation( c, { 0.0, 0.0, 1.0 }, k * nStep * OCX_PI / 180.0 )
            Ent_Translate( c, { a1[ 1 ], a1[ 2 ], 0.0 } )
            AAdd( aOps, { "add", Doc_AddEntity( s[ "doc" ], c ) } ) ; n++
         NEXT
      ENDIF
   NEXT
   IF n > 0
      Vwe_Push( s, aOps )
      VwS_Rebuild( s )
   ENDIF
RETURN n

STATIC FUNCTION Vd_In( p, x1, y1, x2, y2 )
RETURN p[ 1 ] >= Min( x1, x2 ) .AND. p[ 1 ] <= Max( x1, x2 ) .AND. p[ 2 ] >= Min( y1, y2 ) .AND. p[ 2 ] <= Max( y1, y2 )

/* STRETCH: mueve los vertices dentro de la ventana; devuelve entidades modificadas */
FUNCTION Vwe_Stretch( s, pA, pB, nDx, nDy )
   LOCAL aOps := {}, k, h, e, eM, n := 0, lCh, v, p, t
   FOR EACH k IN hb_HKeys( s[ "scene" ][ "ents" ] )
      h := Val( k ) ; e := Doc_GetEntity( s[ "doc" ], h )
      IF e == NIL ; LOOP ; ENDIF
      t := e[ "_type" ] ; lCh := .F.
      DO CASE
      CASE t == "LINE"
         lCh := Vd_In( e[ "start" ], pA[ 1 ], pA[ 2 ], pB[ 1 ], pB[ 2 ] ) .OR. Vd_In( e[ "end" ], pA[ 1 ], pA[ 2 ], pB[ 1 ], pB[ 2 ] )
         IF lCh
            AAdd( aOps, { "mod", h, Ent_Clone( e ) } )
            eM := Doc_GetEntityMut( s[ "doc" ], h )
            IF Vd_In( eM[ "start" ], pA[ 1 ], pA[ 2 ], pB[ 1 ], pB[ 2 ] ) ; eM[ "start" ] := { eM[ "start" ][ 1 ] + nDx, eM[ "start" ][ 2 ] + nDy, eM[ "start" ][ 3 ] } ; ENDIF
            IF Vd_In( eM[ "end" ], pA[ 1 ], pA[ 2 ], pB[ 1 ], pB[ 2 ] ) ; eM[ "end" ] := { eM[ "end" ][ 1 ] + nDx, eM[ "end" ][ 2 ] + nDy, eM[ "end" ][ 3 ] } ; ENDIF
         ENDIF
      CASE t == "LWPOLYLINE"
         FOR EACH v IN e[ "vertices" ]
            IF Vd_In( v[ "location" ], pA[ 1 ], pA[ 2 ], pB[ 1 ], pB[ 2 ] ) ; lCh := .T. ; ENDIF
         NEXT
         IF lCh
            AAdd( aOps, { "mod", h, Ent_Clone( e ) } )
            eM := Doc_GetEntityMut( s[ "doc" ], h )
            FOR EACH v IN eM[ "vertices" ]
               p := v[ "location" ]
               IF Vd_In( p, pA[ 1 ], pA[ 2 ], pB[ 1 ], pB[ 2 ] ) ; v[ "location" ] := { p[ 1 ] + nDx, p[ 2 ] + nDy } ; ENDIF
            NEXT
         ENDIF
      CASE t == "ARC" .OR. t == "CIRCLE" .OR. t == "ELLIPSE"
         IF Vd_In( e[ "center" ], pA[ 1 ], pA[ 2 ], pB[ 1 ], pB[ 2 ] )
            lCh := .T.
            AAdd( aOps, { "mod", h, Ent_Clone( e ) } )
            eM := Doc_GetEntityMut( s[ "doc" ], h )
            Ent_Translate( eM, { nDx, nDy, 0.0 } )
         ENDIF
      ENDCASE
      IF lCh ; n++ ; ENDIF
   NEXT
   IF n > 0
      Vwe_Push( s, aOps )
      VwS_Rebuild( s )
   ENDIF
RETURN n

/* area y perimetro de una lista de puntos { {x,y}, ... } (poligono) */
STATIC FUNCTION Vd_PolyAP( aPts )
   LOCAL n := Len( aPts ), i, a := 0.0, nP := 0.0, p, q
   FOR i := 1 TO n
      p := aPts[ i ] ; q := aPts[ i % n + 1 ]
      a += p[ 1 ] * q[ 2 ] - q[ 1 ] * p[ 2 ]
      nP += Sqrt( ( q[ 1 ] - p[ 1 ] ) ^ 2 + ( q[ 2 ] - p[ 2 ] ) ^ 2 )
   NEXT
RETURN { Abs( a ) / 2.0, nP }

STATIC FUNCTION Vd_Fmt( n ) ; RETURN AllTrim( Str( n, 16, 4 ) )

FUNCTION Vwe_Area( s, aPts )
   LOCAL cOut := "", h, e, ap, v, i, n, a, nSg, nB, nTh, nR, nCh, p, q, aV
   IF aPts != NIL
      IF Len( aPts ) < 3 ; RETURN "AREA: se necesitan al menos 3 puntos" ; ENDIF
      ap := Vd_PolyAP( aPts )
      RETURN "Area=" + Vd_Fmt( ap[ 1 ] ) + "  Perimetro=" + Vd_Fmt( ap[ 2 ] )
   ENDIF
   FOR EACH h IN Vd_Sel( s )
      e := Doc_GetEntity( s[ "doc" ], h )
      IF e[ "_type" ] == "CIRCLE"
         cOut += "CIRCLE: Area=" + Vd_Fmt( OCX_PI * e[ "radius" ] ^ 2 ) + "  Circunferencia=" + Vd_Fmt( OCX_TAU * e[ "radius" ] ) + Chr( 10 )
      ELSEIF e[ "_type" ] == "LWPOLYLINE" .AND. Len( e[ "vertices" ] ) >= 3
         aV := {}
         FOR EACH v IN e[ "vertices" ]
            AAdd( aV, { v[ "location" ][ 1 ], v[ "location" ][ 2 ] } )
         NEXT
         ap := Vd_PolyAP( aV )
         n := Len( aV ) ; a := 0.0
         FOR i := 1 TO n
            p := aV[ i ] ; q := aV[ i % n + 1 ]
            a += p[ 1 ] * q[ 2 ] - q[ 1 ] * p[ 2 ]
         NEXT
         nSg := IIf( a >= 0.0, 1.0, -1.0 ) ; a := Abs( a ) / 2.0
         FOR i := 1 TO n
            nB := e[ "vertices" ][ i ][ "bulge" ]
            IF Abs( nB ) > 0.000000001
               p := aV[ i ] ; q := aV[ i % n + 1 ]
               nCh := Sqrt( ( q[ 1 ] - p[ 1 ] ) ^ 2 + ( q[ 2 ] - p[ 2 ] ) ^ 2 )
               nTh := 4.0 * OCX_ATAN2( Abs( nB ), 1.0 )
               nR := nCh / ( 2.0 * OCX_SIN( nTh / 2.0 ) )
               a += IIf( nB * nSg > 0.0, 1.0, -1.0 ) * nR * nR / 2.0 * ( nTh - OCX_SIN( nTh ) )
               ap[ 2 ] += nR * nTh - nCh
            ENDIF
         NEXT
         IF ! e[ "is_closed" ] ; cOut += "(polilinea abierta, se cierra con el primer vertice) " ; ENDIF
         cOut += "LWPOLYLINE: Area=" + Vd_Fmt( a ) + "  Perimetro=" + Vd_Fmt( ap[ 2 ] ) + Chr( 10 )
      ENDIF
   NEXT
   IF Empty( cOut ) ; RETURN "AREA: seleccione circulos o polilineas cerradas, o indique puntos" ; ENDIF
RETURN Left( cOut, Len( cOut ) - 1 )

/* ---- comandos ------------------------------------------------------------------- */
FUNCTION VwD_Cmd( s, cK, aTok )
   LOCAL i := 2, p, r := NIL, aP, n1, n2, n3, n4, k
   IF VwC_Is3D( s[ "cam" ] )
      RETURN Vk_Res( "Vuelva a la planta (VISTA SUP) para dibujar o editar" )
   ENDIF
   DO CASE
   CASE cK == "ARRAYRECT"
      IF Len( s[ "sel" ] ) == 0 ; RETURN Vk_Res( "Primero seleccione objetos (clic, caja o SELTODO)" ) ; ENDIF
      IF Len( aTok ) < 5 .OR. ! Vk_IsNum( aTok[ 2 ] ) .OR. ! Vk_IsNum( aTok[ 3 ] ) .OR. ! Vk_IsNum( aTok[ 4 ] ) .OR. ! Vk_IsNum( aTok[ 5 ] )
         RETURN Vk_Res( "Uso: ARRAYRECT filas columnas dx dy" )
      ENDIF
      n1 := Int( Val( aTok[ 2 ] ) ) ; n2 := Int( Val( aTok[ 3 ] ) )
      IF n1 < 1 .OR. n2 < 1 .OR. n1 * n2 > 10000 ; RETURN Vk_Res( "ARRAYRECT: filas y columnas entre 1 y 10000 en total" ) ; ENDIF
      k := Vwe_Array( s, "R", n1, n2, Val( aTok[ 4 ] ), Val( aTok[ 5 ] ) )
      RETURN Vk_Res( hb_ntos( k ) + " copia(s) creada(s)", , .T. )
   CASE cK == "ARRAYPOLAR"
      IF Len( s[ "sel" ] ) == 0 ; RETURN Vk_Res( "Primero seleccione objetos (clic, caja o SELTODO)" ) ; ENDIF
      aP := Vk_Pt( aTok, 2 )
      IF aP == NIL ; RETURN Vk_Res( "Uso: ARRAYPOLAR cx,cy n [angulo]" ) ; ENDIF
      i := IIf( At( ",", aTok[ 2 ] ) > 0, 3, 4 )
      IF Len( aTok ) < i .OR. ! Vk_IsNum( aTok[ i ] ) ; RETURN Vk_Res( "Uso: ARRAYPOLAR cx,cy n [angulo]" ) ; ENDIF
      n3 := Int( Val( aTok[ i ] ) )
      n4 := IIf( Len( aTok ) > i .AND. Vk_IsNum( aTok[ i + 1 ] ), Val( aTok[ i + 1 ] ), 360.0 )
      IF n3 < 2 .OR. n3 > 10000 ; RETURN Vk_Res( "ARRAYPOLAR: n entre 2 y 10000" ) ; ENDIF
      k := Vwe_Array( s, "P", aP, n3, n3, n4 )
      RETURN Vk_Res( hb_ntos( k ) + " copia(s) creada(s)", , .T. )
   CASE cK == "AREA"
      IF Len( aTok ) > 1
         aP := {} ; i := 2
         DO WHILE Len( aTok ) >= i
            p := Vk_Pt( aTok, i )
            IF p == NIL ; RETURN Vk_Res( "Argumento no valido: " + aTok[ i ] ) ; ENDIF
            AAdd( aP, p ) ; i += IIf( At( ",", aTok[ i ] ) > 0, 1, 2 )
         ENDDO
         RETURN Vk_Res( Vwe_Area( s, aP ), .T. )
      ENDIF
      RETURN Vk_Res( Vwe_Area( s, NIL ), .T. )
   ENDCASE
   s[ "pend" ] := hb_Hash( "cmd", cK, "pts", {} )
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
   IF cK == "SPLINE" .AND. Len( aTok ) > 1 .AND. s[ "pend" ] != NIL
      RETURN VwK_Finish( s )
   ENDIF
   IF r != NIL .AND. s[ "pend" ] == NIL ; RETURN r ; ENDIF
RETURN Vk_Res( VwD_Prompt( s[ "pend" ] ) )

FUNCTION VwD_Prompt( pe )
   LOCAL n := Len( pe[ "pts" ] )
   DO CASE
   CASE pe[ "cmd" ] == "ELLIPSE" ; RETURN { "ELLIPSE: centro", "ELLIPSE: extremo del eje mayor", "ELLIPSE: punto del eje menor" }[ Min( n + 1, 3 ) ]
   CASE pe[ "cmd" ] == "SPLINE" ; RETURN IIf( n == 0, "SPLINE: primer punto", "SPLINE: siguiente punto (Intro termina)" )
   ENDCASE
RETURN { "STRETCH: primera esquina de la ventana", "STRETCH: esquina opuesta", "STRETCH: punto base", "STRETCH: punto destino" }[ Min( n + 1, 4 ) ]

FUNCTION VwD_Point( s, pe, x, y )
   LOCAL cK := pe[ "cmd" ], n := Len( pe[ "pts" ] ), k
   DO CASE
   CASE cK == "ELLIPSE"
      IF n == 3
         s[ "pend" ] := NIL
         IF Vwe_Ellipse( s, pe[ "pts" ][ 1 ], pe[ "pts" ][ 2 ], pe[ "pts" ][ 3 ] ) == 0 ; RETURN Vk_Res( "ELLIPSE: ejes no validos" ) ; ENDIF
         RETURN Vk_Res( "Elipse creada", , .T. )
      ENDIF
      RETURN Vk_Res( VwD_Prompt( pe ) )
   CASE cK == "SPLINE"
      RETURN Vk_Res( VwD_Prompt( pe ) )
   CASE cK == "STRETCH"
      IF n == 4
         s[ "pend" ] := NIL
         k := Vwe_Stretch( s, pe[ "pts" ][ 1 ], pe[ "pts" ][ 2 ], x - pe[ "pts" ][ 3 ][ 1 ], y - pe[ "pts" ][ 3 ][ 2 ] )
         RETURN Vk_Res( hb_ntos( k ) + " objeto(s) estirado(s)", , .T. )
      ENDIF
      RETURN Vk_Res( VwD_Prompt( pe ) )
   ENDCASE
RETURN NIL
