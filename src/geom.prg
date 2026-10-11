/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom.prg
   Rust origen: glam::DVec3 + src/scene/convert/tess_util.rs +
                src/snap.rs + src/scene/camera_ops.rs (parte 2D) +
                csrc/ocad_geom.c (envoltorios Harbour del n??cleo C MSVC22).
   Puntos 2D = array { x, y }. Puntos 3D = array { x, y, z }.
----------------------------------------------------------------------------*/
#include "ohbcad.ch"

//--- Distancia / ??ngulo / polar (acelerado en C) -----------------------------
FUNCTION OC_Dist2D( aP, aQ )
RETURN OCX_DIST( aP[ 1 ], aP[ 2 ], aQ[ 1 ], aQ[ 2 ] )

FUNCTION OC_Ang2D( aP, aQ )
RETURN OCX_ANGLE( aP[ 1 ], aP[ 2 ], aQ[ 1 ], aQ[ 2 ] )

FUNCTION OC_Polar2D( aP, nAng, nDist )
RETURN OCX_POLAR( aP[ 1 ], aP[ 2 ], nAng, nDist )

FUNCTION OC_Mid2D( aP, aQ )
RETURN { ( aP[ 1 ] + aQ[ 1 ] ) / 2, ( aP[ 2 ] + aQ[ 2 ] ) / 2 }

//--- Intersecci??n (Rust: hit_test.rs / trim.rs / fillet.rs) -------------------
FUNCTION OC_IntersLL( aP1, aP2, aP3, aP4, lSeg )
   hb_default( @lSeg, .F. )
RETURN OCX_INTERS( aP1[ 1 ], aP1[ 2 ], aP2[ 1 ], aP2[ 2 ], ;
                  aP3[ 1 ], aP3[ 2 ], aP4[ 1 ], aP4[ 2 ], lSeg )

//--- Punto-segmento (Rust: pick/hit_test.rs) ----------------------------------
FUNCTION OC_PtSeg( aP, aA, aB )
RETURN OCX_PTSEG( aP[ 1 ], aP[ 2 ], aA[ 1 ], aA[ 2 ], aB[ 1 ], aB[ 2 ] )

//--- Transformaci??n af??n 2D [m11 m12 dx; m21 m22 dy] ---------------------------
FUNCTION OC_XfPt( aP, aM )
RETURN OCX_XFPT( aP[ 1 ], aP[ 2 ], aM[ 1 ], aM[ 2 ], aM[ 3 ], aM[ 4 ], ;
                aM[ 5 ], aM[ 6 ] )

FUNCTION OC_MoveM( nDx, nDy )
RETURN { 1, 0, 0, 1, nDx, nDy }

FUNCTION OC_RotM( nAng, aCen )
   LOCAL c := Cos( nAng ), s := Sin( nAng )
   LOCAL x0 := 0, y0 := 0
   IF aCen != NIL
      x0 := aCen[ 1 ]; y0 := aCen[ 2 ]
   ENDIF
RETURN { c, -s, s, c, x0 - c * x0 + s * y0, y0 - s * x0 - c * y0 }

FUNCTION OC_ScaleM( nSx, nSy, aCen )
   LOCAL x0 := 0, y0 := 0
   hb_default( @nSy, nSx )
   IF aCen != NIL
      x0 := aCen[ 1 ]; y0 := aCen[ 2 ]
   ENDIF
RETURN { nSx, 0, 0, nSy, x0 - nSx * x0, y0 - nSy * y0 }

FUNCTION OC_MirrorM( aP1, aP2 )
   // Simetr??a respecto a la recta P1-P2: T(P1)??R??T(-P1), R = reflexi??n eje X
   LOCAL nA := OC_Ang2D( aP1, aP2 )
   LOCAL c := Cos( 2 * nA ), s := Sin( 2 * nA )
   LOCAL x0 := aP1[ 1 ], y0 := aP1[ 2 ]
RETURN { c, s, s, -c, x0 - c * x0 - s * y0, y0 - s * x0 + c * y0 }

//--- Polil??neas (Rust: entities/lwpolyline.rs, polyline.rs) --------------------
FUNCTION OC_PolyLen( aVerts, lClosed )
   LOCAL n := OCX_POLYLEN( aVerts )
   hb_default( @lClosed, .F. )
   IF lClosed .AND. Len( aVerts ) > 1
      n += OC_Dist2D( ATail( aVerts ), aVerts[ 1 ] )
   ENDIF
RETURN n

FUNCTION OC_PolyArea( aVerts )
RETURN OCX_POLYAREA( aVerts )

FUNCTION OC_BBoxPts( aVerts )
RETURN OCX_BBOXPTS( aVerts )

//--- Arcos (Rust: scene/convert/tess.rs) ---------------------------------------
FUNCTION OC_TessArc( aCen, nR, nA0, nA1, nSag )
   LOCAL n
   hb_default( @nSag, nR * 0.01 )
RETURN OCX_TESSARC( aCen[ 1 ], aCen[ 2 ], nR, nA0, nA1, ;
                   OCX_ARCN( aCen[ 1 ], aCen[ 2 ], nR, nA0, nA1, nSag ) )

//--- Paralela de segmento (Rust: modules/draw/modify/offset.rs) -----------------
FUNCTION OC_OffSeg( aA, aB, nD )
   LOCAL a := OCX_OFFSEG( aA[ 1 ], aA[ 2 ], aB[ 1 ], aB[ 2 ], nD )
RETURN { { a[ 1 ], a[ 2 ] }, { a[ 3 ], a[ 4 ] } }

//--- Normalizaci??n angular ------------------------------------------------------
FUNCTION OC_NormAng( nA )
   LOCAL TAU := 8 * ATan( 1 )
   DO WHILE nA < 0
      nA += TAU
   ENDDO
   DO WHILE nA >= TAU
      nA -= TAU
   ENDDO
RETURN nA

FUNCTION OC_Deg2Rad( nD )
RETURN nD * ATan( 1 ) / 45

FUNCTION OC_Rad2Deg( nR )
RETURN nR * 45 / ATan( 1 )
