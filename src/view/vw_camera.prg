/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/view/vw_camera.prg
   Fase 2 / bloque B2. Origen Rust: src/scene/view/camera.rs + transform.rs
   (camara 2D ortografica). Logica pura, sin FiveWin: se prueba en consola.
   Camara = hash: cx, cy (centro en mundo), scale (px por unidad), w, h (px).
   Fase 2 / B12 (3D): cz (altura del punto objetivo), yaw (giro alrededor de Z, rad) y pitch
   (elevacion de la camara sobre el plano XY, rad; PI/2 = vista en planta = la camara 2D de siempre).
   Proyeccion ortografica: xr = dx*cos(yaw) + dy*sin(yaw); yr = -dx*sin(yaw) + dy*cos(yaw);
   arriba = yr*sin(pitch) + dz*cos(pitch); sx = w/2 + xr*scale; sy = h/2 - arriba*scale.
   Pantalla: x hacia la derecha, y hacia abajo (Y mundo hacia arriba).
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION VwC_New()
RETURN hb_Hash( "cx", 0.0, "cy", 0.0, "scale", 1.0, "w", 800, "h", 600, "cz", 0.0, "yaw", 0.0, "pitch", OCX_PI / 2.0 )

FUNCTION VwC_SetSize( c, nW, nH )
   c[ "w" ] := Max( 1, nW )
   c[ "h" ] := Max( 1, nH )
RETURN c

FUNCTION VwC_W2S( c, x, y )
RETURN { c[ "w" ] / 2.0 + ( x - c[ "cx" ] ) * c[ "scale" ], c[ "h" ] / 2.0 - ( y - c[ "cy" ] ) * c[ "scale" ] }

FUNCTION VwC_S2W( c, sx, sy )
RETURN { c[ "cx" ] + ( sx - c[ "w" ] / 2.0 ) / c[ "scale" ], c[ "cy" ] - ( sy - c[ "h" ] / 2.0 ) / c[ "scale" ] }

/* limites de zoom (como OHB_ZOOM_MIN/MAX_FACTOR del esqueleto) */
FUNCTION VwC_ClampScale( n )
   IF n < 0.000001 ; RETURN 0.000001 ; ENDIF
   IF n > 1000000.0 ; RETURN 1000000.0 ; ENDIF
RETURN n

/* zoom por factor manteniendo fijo el punto de pantalla (sx,sy) */
FUNCTION VwC_ZoomAt( c, nFactor, sx, sy )
   LOCAL aW
   IF VwC_Is3D( c )
      c[ "scale" ] := VwC_ClampScale( c[ "scale" ] * nFactor )
      RETURN c
   ENDIF
   aW := VwC_S2W( c, sx, sy )
   c[ "scale" ] := VwC_ClampScale( c[ "scale" ] * nFactor )
   c[ "cx" ] := aW[ 1 ] - ( sx - c[ "w" ] / 2.0 ) / c[ "scale" ]
   c[ "cy" ] := aW[ 2 ] + ( sy - c[ "h" ] / 2.0 ) / c[ "scale" ]
RETURN c

/* pan: arrastre de (dx,dy) pixeles de pantalla */
FUNCTION VwC_PanPx( c, dx, dy )
   LOCAL cy, sy, cp, sp
   IF VwC_Is3D( c )
      // el objetivo se desplaza por los ejes derecha/arriba de la pantalla
      cy := OCX_COS( c[ "yaw" ] ) ; sy := OCX_SIN( c[ "yaw" ] ) ; cp := OCX_COS( c[ "pitch" ] ) ; sp := OCX_SIN( c[ "pitch" ] )
      c[ "cx" ] += ( - dx * cy - dy * sy * sp ) / c[ "scale" ]
      c[ "cy" ] += ( - dx * sy + dy * cy * sp ) / c[ "scale" ]
      c[ "cz" ] += dy * cp / c[ "scale" ]
      RETURN c
   ENDIF
   c[ "cx" ] -= dx / c[ "scale" ]
   c[ "cy" ] += dy / c[ "scale" ]
RETURN c

/* encuadra la extension aExt = { minx, miny, maxx, maxy } con margen (0.9 = 10 %) */
FUNCTION VwC_FitExtents( c, aExt, nMargin )
   LOCAL nW, nH
   IF aExt == NIL
      c[ "cx" ] := 0.0 ; c[ "cy" ] := 0.0 ; c[ "scale" ] := 1.0
      RETURN c
   ENDIF
   hb_default( @nMargin, 0.9 )
   nW := aExt[ 3 ] - aExt[ 1 ]
   nH := aExt[ 4 ] - aExt[ 2 ]
   c[ "cx" ] := ( aExt[ 1 ] + aExt[ 3 ] ) / 2.0
   c[ "cy" ] := ( aExt[ 2 ] + aExt[ 4 ] ) / 2.0
   IF nW < 0.000000001 .AND. nH < 0.000000001
      c[ "scale" ] := 1.0
   ELSEIF nW < 0.000000001
      c[ "scale" ] := VwC_ClampScale( c[ "h" ] * nMargin / nH )
   ELSEIF nH < 0.000000001
      c[ "scale" ] := VwC_ClampScale( c[ "w" ] * nMargin / nW )
   ELSE
      c[ "scale" ] := VwC_ClampScale( Min( c[ "w" ] * nMargin / nW, c[ "h" ] * nMargin / nH ) )
   ENDIF
RETURN c

/* rectangulo mundo visible { minx, miny, maxx, maxy } */
FUNCTION VwC_Visible( c )
   LOCAL a := VwC_S2W( c, 0, c[ "h" ] ), b := VwC_S2W( c, c[ "w" ], 0 )
RETURN { a[ 1 ], a[ 2 ], b[ 1 ], b[ 2 ] }

/* zoom a ventana: aExt en mundo */
FUNCTION VwC_ZoomWindow( c, aExt )
RETURN VwC_FitExtents( c, aExt, 1.0 )

//--- 3D (B12) ---------------------------------------------------------------------
/* .T. si la vista no es la planta (yaw = 0 y pitch = 90 grados) */
FUNCTION VwC_Is3D( c )
RETURN Abs( c[ "yaw" ] ) > 0.000000001 .OR. c[ "pitch" ] < OCX_PI / 2.0 - 0.000000001

/* prepara senos y cosenos para VwC_P3 (llamar una vez por dibujo o tras cambiar yaw/pitch) */
FUNCTION VwC_Setup( c )
   c[ "_t" ] := { OCX_COS( c[ "yaw" ] ), OCX_SIN( c[ "yaw" ] ), OCX_COS( c[ "pitch" ] ), OCX_SIN( c[ "pitch" ] ) }
RETURN c

/* punto mundo (x,y,z) -> { sx, sy } (requiere VwC_Setup previo) */
FUNCTION VwC_P3( c, x, y, z )
   LOCAL t := c[ "_t" ], dx := x - c[ "cx" ], dy := y - c[ "cy" ], dz := z - c[ "cz" ], xr, yr
   xr := dx * t[ 1 ] + dy * t[ 2 ]
   yr := - dx * t[ 2 ] + dy * t[ 1 ]
RETURN { c[ "w" ] / 2.0 + xr * c[ "scale" ], c[ "h" ] / 2.0 - ( yr * t[ 4 ] + dz * t[ 3 ] ) * c[ "scale" ] }

FUNCTION VwC_Proj( c, x, y, z )
   VwC_Setup( c )
RETURN VwC_P3( c, x, y, z )

/* orbita: incrementos en radianes; el pitch queda entre -90 y +90 grados */
FUNCTION VwC_Orbit( c, nDYaw, nDPitch )
   c[ "yaw" ] += nDYaw
   c[ "pitch" ] := Max( - OCX_PI / 2.0, Min( OCX_PI / 2.0, c[ "pitch" ] + nDPitch ) )
RETURN c

/* vistas predefinidas; devuelve .F. si el nombre no existe */
FUNCTION VwC_View( c, cName )
   cName := Upper( cName )
   DO CASE
   CASE cName == "SUP" .OR. cName == "PLANTA" .OR. cName == "TOP" ; c[ "yaw" ] := 0.0 ; c[ "pitch" ] := OCX_PI / 2.0
   CASE cName == "FRONTAL" .OR. cName == "FRONT" ; c[ "yaw" ] := 0.0 ; c[ "pitch" ] := 0.0
   CASE cName == "POSTERIOR" .OR. cName == "BACK" ; c[ "yaw" ] := OCX_PI ; c[ "pitch" ] := 0.0
   CASE cName == "DERECHA" .OR. cName == "RIGHT" ; c[ "yaw" ] := OCX_PI / 2.0 ; c[ "pitch" ] := 0.0
   CASE cName == "IZQUIERDA" .OR. cName == "LEFT" ; c[ "yaw" ] := - OCX_PI / 2.0 ; c[ "pitch" ] := 0.0
   CASE cName == "ISO" .OR. cName == "ISO-SO" ; c[ "yaw" ] := - OCX_PI / 4.0 ; c[ "pitch" ] := 0.6154797086703874
   CASE cName == "ISO-SE" ; c[ "yaw" ] := OCX_PI / 4.0 ; c[ "pitch" ] := 0.6154797086703874
   CASE cName == "ISO-NE" ; c[ "yaw" ] := 3.0 * OCX_PI / 4.0 ; c[ "pitch" ] := 0.6154797086703874
   CASE cName == "ISO-NO" ; c[ "yaw" ] := - 3.0 * OCX_PI / 4.0 ; c[ "pitch" ] := 0.6154797086703874
   OTHERWISE ; RETURN .F.
   ENDCASE
RETURN .T.

/* encuadra la caja 3D aE = { minx, miny, minz, maxx, maxy, maxz } con la vista actual */
FUNCTION VwC_Fit3( c, aE, nMargin )
   LOCAL x, y, z, a, nMinX := 0.0, nMaxX := 0.0, nMinY := 0.0, nMaxY := 0.0, lF := .T., nS, nW, nH
   IF aE == NIL
      c[ "cx" ] := 0.0 ; c[ "cy" ] := 0.0 ; c[ "cz" ] := 0.0 ; c[ "scale" ] := 1.0
      RETURN c
   ENDIF
   hb_default( @nMargin, 0.9 )
   c[ "cx" ] := ( aE[ 1 ] + aE[ 4 ] ) / 2.0 ; c[ "cy" ] := ( aE[ 2 ] + aE[ 5 ] ) / 2.0 ; c[ "cz" ] := ( aE[ 3 ] + aE[ 6 ] ) / 2.0
   c[ "scale" ] := 1.0
   VwC_Setup( c )
   FOR EACH x IN { aE[ 1 ], aE[ 4 ] }
      FOR EACH y IN { aE[ 2 ], aE[ 5 ] }
         FOR EACH z IN { aE[ 3 ], aE[ 6 ] }
            a := VwC_P3( c, x, y, z )
            a := { a[ 1 ] - c[ "w" ] / 2.0, c[ "h" ] / 2.0 - a[ 2 ] }
            IF lF
               nMinX := a[ 1 ] ; nMaxX := a[ 1 ] ; nMinY := a[ 2 ] ; nMaxY := a[ 2 ] ; lF := .F.
            ELSE
               nMinX := Min( nMinX, a[ 1 ] ) ; nMaxX := Max( nMaxX, a[ 1 ] )
               nMinY := Min( nMinY, a[ 2 ] ) ; nMaxY := Max( nMaxY, a[ 2 ] )
            ENDIF
         NEXT
      NEXT
   NEXT
   // con scale = 1 las coordenadas son unidades mundo; el centro de la caja proyecta a (0,0)
   nW := Max( Abs( nMinX ), Abs( nMaxX ) ) * 2.0 ; nH := Max( Abs( nMinY ), Abs( nMaxY ) ) * 2.0
   IF nW < 0.000000001 .AND. nH < 0.000000001
      nS := 1.0
   ELSEIF nW < 0.000000001
      nS := c[ "h" ] * nMargin / nH
   ELSEIF nH < 0.000000001
      nS := c[ "w" ] * nMargin / nW
   ELSE
      nS := Min( c[ "w" ] * nMargin / nW, c[ "h" ] * nMargin / nH )
   ENDIF
   c[ "scale" ] := VwC_ClampScale( nS )
RETURN c
