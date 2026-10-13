/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/view/vw_camera.prg
   Fase 2 / bloque B2. Origen Rust: src/scene/view/camera.rs + transform.rs
   (camara 2D ortografica). Logica pura, sin FiveWin: se prueba en consola.
   Camara = hash: cx, cy (centro en mundo), scale (px por unidad), w, h (px).
   Pantalla: x hacia la derecha, y hacia abajo (Y mundo hacia arriba).
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION VwC_New()
RETURN hb_Hash( "cx", 0.0, "cy", 0.0, "scale", 1.0, "w", 800, "h", 600 )

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
   LOCAL aW := VwC_S2W( c, sx, sy )
   c[ "scale" ] := VwC_ClampScale( c[ "scale" ] * nFactor )
   c[ "cx" ] := aW[ 1 ] - ( sx - c[ "w" ] / 2.0 ) / c[ "scale" ]
   c[ "cy" ] := aW[ 2 ] + ( sy - c[ "h" ] / 2.0 ) / c[ "scale" ]
RETURN c

/* pan: arrastre de (dx,dy) pixeles de pantalla */
FUNCTION VwC_PanPx( c, dx, dy )
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
