/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/view/vw_xform.prg
   Fase 2 / modules/draw: ROTATE, SCALE, MIRROR (modify/rotate.rs, scale.rs,
   mirror.rs) y RECT, POLYGON (draw/shapes). Sobre la sesion del visor;
   usa las transformaciones del codec (Ent_ApplyRotation, Ent_ApplyScalingWithOrigin,
   Ent_MirrorAboutLine). Comandos: ROTAR bx,by angulo | ESCALA bx,by factor |
   SIMETRIA x1,y1 x2,y2 [B] | RECTANG x1,y1 x2,y2 | POLIGONO lados cx,cy r.
   Sin argumentos piden los puntos (clic o x,y), como MOVER.
----------------------------------------------------------------------------*/
#include "ocx.ch"

STATIC FUNCTION VwX_Handles( s )
   LOCAL a := {}, k
   FOR EACH k IN hb_HKeys( s[ "sel" ] )
      AAdd( a, Val( k ) )
   NEXT
RETURN a

/* aplica la transformacion cKind a la seleccion; devuelve cuantas entidades.
   ROTATE: aP = {bx,by}, nV = grados. SCALE: aP = {bx,by}, nV = factor.
   MIRROR: aP = {{x1,y1},{x2,y2}}, nV = .T. borra el origen. */
FUNCTION Vwe_Xform( s, cKind, aP, nV )
   LOCAL aOps := {}, h, e, c, n := 0, hNew := hb_Hash(), nRad, hAdd
   FOR EACH h IN VwX_Handles( s )
      e := Doc_GetEntity( s[ "doc" ], h )
      IF e == NIL ; LOOP ; ENDIF
      IF cKind == "MIRROR"
         c := Ent_Clone( e )
         c[ "common" ][ "handle" ] := Hd_Null()
         Ent_MirrorAboutLine( c, { aP[ 1 ][ 1 ], aP[ 1 ][ 2 ], 0.0 }, { aP[ 2 ][ 1 ], aP[ 2 ][ 2 ], 0.0 } )
         hAdd := Doc_AddEntity( s[ "doc" ], c )
         AAdd( aOps, { "add", hAdd } )
         hNew[ hb_ntos( hAdd ) ] := .T.
         IF nV
            AAdd( aOps, { "del", Ent_Clone( e ) } )
            Doc_RemoveEntity( s[ "doc" ], h )
         ENDIF
      ELSE
         AAdd( aOps, { "mod", h, Ent_Clone( e ) } )
         e := Doc_GetEntityMut( s[ "doc" ], h )
         IF cKind == "ROTATE"
            nRad := nV * OCX_PI / 180.0
            Ent_Translate( e, { - aP[ 1 ], - aP[ 2 ], 0.0 } )
            Ent_ApplyRotation( e, { 0.0, 0.0, 1.0 }, nRad )
            Ent_Translate( e, { aP[ 1 ], aP[ 2 ], 0.0 } )
         ELSE
            Ent_ApplyScalingWithOrigin( e, { nV, nV, nV }, { aP[ 1 ], aP[ 2 ], 0.0 } )
         ENDIF
         hNew[ hb_ntos( h ) ] := .T.
      ENDIF
      n++
   NEXT
   Vwe_Push( s, aOps )
   VwS_Rebuild( s )
   s[ "sel" ] := hNew
RETURN n

/* rectangulo por dos esquinas: polilinea cerrada de 4 vertices */
FUNCTION Vwe_Rect( s, p1, p2 )
RETURN Vwe_Pline( s, { { p1[ 1 ], p1[ 2 ] }, { p2[ 1 ], p1[ 2 ] }, { p2[ 1 ], p2[ 2 ] }, { p1[ 1 ], p2[ 2 ] } }, .T. )

/* poligono regular inscrito: nLados, centro, punto del primer vertice */
FUNCTION Vwe_Polygon( s, nSides, pC, pV )
   LOCAL aPts := {}, i, nR := Sqrt( ( pV[ 1 ] - pC[ 1 ] ) ^ 2 + ( pV[ 2 ] - pC[ 2 ] ) ^ 2 )
   LOCAL nA0 := OCX_ATAN2( pV[ 2 ] - pC[ 2 ], pV[ 1 ] - pC[ 1 ] ), nA
   FOR i := 0 TO nSides - 1
      nA := nA0 + 2.0 * OCX_PI * i / nSides
      AAdd( aPts, { pC[ 1 ] + nR * OCX_COS( nA ), pC[ 2 ] + nR * OCX_SIN( nA ) } )
   NEXT
RETURN Vwe_Pline( s, aPts, .T. )

/* arranque del comando (con argumentos en linea o pendiente de puntos) */
FUNCTION VwX_Cmd( s, cK, aTok )
   LOCAL p1, p2, n, i := 2
   IF VwC_Is3D( s[ "cam" ] )
      RETURN Vk_Res( "Vuelva a la planta (VISTA SUP) para dibujar o editar" )
   ENDIF
   IF ( cK == "ROTATE" .OR. cK == "SCALE" .OR. cK == "MIRROR" ) .AND. Len( s[ "sel" ] ) == 0
      RETURN Vk_Res( "Primero seleccione objetos (clic, caja o SELTODO)" )
   ENDIF
   s[ "pend" ] := hb_Hash( "cmd", cK, "pts", {}, "n", 6 )
   IF cK == "POLYGON" .AND. Len( aTok ) >= 2 .AND. Vk_IsNum( aTok[ 2 ] ) .AND. At( ",", aTok[ 2 ] ) == 0
      n := Int( Val( aTok[ 2 ] ) )
      IF n < 3 .OR. n > 1024
         s[ "pend" ] := NIL
         RETURN Vk_Res( "POLIGONO: numero de lados entre 3 y 1024" )
      ENDIF
      s[ "pend" ][ "n" ] := n
      i := 3
   ENDIF
   IF Len( aTok ) >= i
      p1 := Vk_Pt( aTok, i )
      IF p1 == NIL
         s[ "pend" ] := NIL
         RETURN Vk_Res( "Argumento no valido: " + aTok[ i ] )
      ENDIF
      i += IIf( At( ",", aTok[ i ] ) > 0, 1, 2 )
      VwK_Point( s, p1[ 1 ], p1[ 2 ] )
      IF Len( aTok ) >= i
         IF cK == "ROTATE" .OR. cK == "SCALE"
            IF ! Vk_IsNum( aTok[ i ] ) .OR. At( ",", aTok[ i ] ) > 0
               s[ "pend" ] := NIL
               RETURN Vk_Res( "Argumento no valido: " + aTok[ i ] )
            ENDIF
            RETURN VwK_Number( s, Val( aTok[ i ] ) )
         ENDIF
         p2 := Vk_Pt( aTok, i )
         IF p2 == NIL
            s[ "pend" ] := NIL
            RETURN Vk_Res( "Argumento no valido: " + aTok[ i ] )
         ENDIF
         i += IIf( At( ",", aTok[ i ] ) > 0, 1, 2 )
         IF cK == "MIRROR" .AND. Len( aTok ) >= i .AND. Upper( aTok[ i ] ) == "B"
            s[ "pend" ][ "del" ] := .T.
         ENDIF
         RETURN VwK_Point( s, p2[ 1 ], p2[ 2 ] )
      ENDIF
   ENDIF
RETURN Vk_Res( VwK_Prompt( s ) )

/* texto de ayuda de los comandos de este fichero (para VwK_Prompt) */
FUNCTION VwX_Prompt( pe )
   LOCAL n := Len( pe[ "pts" ] ), cK := pe[ "cmd" ]
   DO CASE
   CASE cK == "ROTATE" ; RETURN IIf( n == 0, "ROTAR: punto base", "ROTAR: angulo en grados (o punto de direccion)" )
   CASE cK == "SCALE" ; RETURN IIf( n == 0, "ESCALA: punto base", "ESCALA: factor" )
   CASE cK == "MIRROR" ; RETURN IIf( n == 0, "SIMETRIA: primer punto del eje", "SIMETRIA: segundo punto del eje" )
   CASE cK == "RECT" ; RETURN IIf( n == 0, "RECTANG: primera esquina", "RECTANG: esquina opuesta" )
   ENDCASE
RETURN IIf( n == 0, "POLIGONO (" + hb_ntos( pe[ "n" ] ) + " lados): centro", "POLIGONO: punto del primer vertice" )

/* punto recibido para estos comandos; devuelve NIL si el comando no es de este fichero */
FUNCTION VwX_Point( s, pe, x, y )
   LOCAL cK := pe[ "cmd" ], n := Len( pe[ "pts" ] ), nA, k
   DO CASE
   CASE cK == "ROTATE" .AND. n == 2
      s[ "pend" ] := NIL
      nA := OCX_ATAN2( y - pe[ "pts" ][ 1 ][ 2 ], x - pe[ "pts" ][ 1 ][ 1 ] ) * 180.0 / OCX_PI
      k := Vwe_Xform( s, "ROTATE", pe[ "pts" ][ 1 ], nA )
      RETURN Vk_Res( hb_ntos( k ) + " objeto(s) girado(s)", , .T. )
   CASE cK == "SCALE" .AND. n == 2
      s[ "pend" ] := NIL
      RETURN Vk_Res( "ESCALA: escriba el factor (numero)" )
   CASE cK == "MIRROR" .AND. n == 2
      s[ "pend" ] := NIL
      IF Abs( x - pe[ "pts" ][ 1 ][ 1 ] ) + Abs( y - pe[ "pts" ][ 1 ][ 2 ] ) <= 0
         RETURN Vk_Res( "Eje nulo" )
      ENDIF
      k := Vwe_Xform( s, "MIRROR", { pe[ "pts" ][ 1 ], pe[ "pts" ][ 2 ] }, hb_HHasKey( pe, "del" ) )
      RETURN Vk_Res( hb_ntos( k ) + " objeto(s) reflejado(s)", , .T. )
   CASE cK == "RECT" .AND. n == 2
      s[ "pend" ] := NIL
      Vwe_Rect( s, pe[ "pts" ][ 1 ], pe[ "pts" ][ 2 ] )
      RETURN Vk_Res( "Rectangulo creado", , .T. )
   CASE cK == "POLYGON" .AND. n == 2
      s[ "pend" ] := NIL
      IF Abs( x - pe[ "pts" ][ 1 ][ 1 ] ) + Abs( y - pe[ "pts" ][ 1 ][ 2 ] ) <= 0
         RETURN Vk_Res( "Radio nulo" )
      ENDIF
      Vwe_Polygon( s, pe[ "n" ], pe[ "pts" ][ 1 ], pe[ "pts" ][ 2 ] )
      RETURN Vk_Res( "Poligono creado", , .T. )
   ENDCASE
RETURN NIL

/* numero escrito (angulo / factor) */
FUNCTION VwX_Number( s, pe, nV )
   LOCAL cK := pe[ "cmd" ], k
   IF Len( pe[ "pts" ] ) == 1 .AND. cK == "ROTATE"
      s[ "pend" ] := NIL
      k := Vwe_Xform( s, "ROTATE", pe[ "pts" ][ 1 ], nV )
      RETURN Vk_Res( hb_ntos( k ) + " objeto(s) girado(s)", , .T. )
   ENDIF
   IF Len( pe[ "pts" ] ) == 1 .AND. cK == "SCALE"
      s[ "pend" ] := NIL
      IF nV <= 0 ; RETURN Vk_Res( "Factor no valido" ) ; ENDIF
      k := Vwe_Xform( s, "SCALE", pe[ "pts" ][ 1 ], nV )
      RETURN Vk_Res( hb_ntos( k ) + " objeto(s) escalado(s)", , .T. )
   ENDIF
RETURN NIL
