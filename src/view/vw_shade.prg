/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/view/vw_shade.prg
   Fase 2 / B13c: sombreado "painter" de triangulos 3D (los de Sat_Tess) para la vista 3D.
   Logica pura, sin FiveWin: la GUI solo recorre el resultado y rellena poligonos.
   VwS_Shade( cam, aTris [, lCull] ) -> { { {x1,y1}, {x2,y2}, {x3,y3}, nShade, nDepth }, ... }
     ordenado de lejos a cerca (algoritmo del pintor). nShade en 0.25..1.0 (luz = camara,
     ambiente 0.25 + 0.75 * cos del angulo entre normal y direccion a la camara).
     lCull (por defecto .T.): descarta triangulos cuya normal mira de espaldas a la camara.
   VwS_ViewDir( cam ) -> vector unitario del objetivo hacia la camara (requiere yaw/pitch de la camara).
   VwS_Color( nShade, nRGB ) -> color RGB (numero BGR de Windows: R + G*256 + B*65536) oscurecido.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION VwS_ViewDir( c )
   LOCAL cy := OCX_COS( c[ "yaw" ] ), sy := OCX_SIN( c[ "yaw" ] ), cp := OCX_COS( c[ "pitch" ] ), sp := OCX_SIN( c[ "pitch" ] )
   LOCAL r := { cy, sy, 0.0 }, ry := { - sy, cy, 0.0 }
   LOCAL u := { ry[ 1 ] * sp, ry[ 2 ] * sp, cp }
RETURN { r[ 2 ] * u[ 3 ] - r[ 3 ] * u[ 2 ], r[ 3 ] * u[ 1 ] - r[ 1 ] * u[ 3 ], r[ 1 ] * u[ 2 ] - r[ 2 ] * u[ 1 ] }

FUNCTION VwS_Shade( c, aTris, lCull )
   LOCAL aOut := {}, v := VwS_ViewDir( c ), t, n, nl, nDepth, a, b, d, nCos
   IF lCull == NIL ; lCull := .T. ; ENDIF
   VwC_Setup( c )
   FOR EACH t IN aTris
      n := t[ 4 ]
      nl := Sqrt( n[ 1 ] ^ 2 + n[ 2 ] ^ 2 + n[ 3 ] ^ 2 )
      IF nl <= 0.0 ; LOOP ; ENDIF
      nCos := ( n[ 1 ] * v[ 1 ] + n[ 2 ] * v[ 2 ] + n[ 3 ] * v[ 3 ] ) / nl
      IF nCos < 0.0
         IF lCull ; LOOP ; ENDIF
         nCos := - nCos
      ENDIF
      a := t[ 1 ] ; b := t[ 2 ] ; d := t[ 3 ]
      nDepth := ( ( a[ 1 ] + b[ 1 ] + d[ 1 ] ) * v[ 1 ] + ( a[ 2 ] + b[ 2 ] + d[ 2 ] ) * v[ 2 ] + ( a[ 3 ] + b[ 3 ] + d[ 3 ] ) * v[ 3 ] ) / 3.0
      AAdd( aOut, { VwC_P3( c, a[ 1 ], a[ 2 ], a[ 3 ] ), VwC_P3( c, b[ 1 ], b[ 2 ], b[ 3 ] ), VwC_P3( c, d[ 1 ], d[ 2 ], d[ 3 ] ), 0.25 + 0.75 * Min( 1.0, nCos ), nDepth } )
   NEXT
   ASort( aOut, , , {| x, y | x[ 5 ] < y[ 5 ] } )
RETURN aOut

FUNCTION VwS_Color( nShade, nRGB )
   LOCAL r := nRGB % 256, g := Int( nRGB / 256 ) % 256, b := Int( nRGB / 65536 ) % 256
RETURN Int( r * nShade ) + Int( g * nShade ) * 256 + Int( b * nShade ) * 65536
