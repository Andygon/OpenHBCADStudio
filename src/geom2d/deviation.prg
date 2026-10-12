/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/deviation.prg
   Origen Rust: opencadkernel/src/geom2d/deviation.rs (684 lineas)
   Estado: TRADUCIDO (tests portados en tests/t_deviation.prg). Curve::tessellate_angle
   de Line/Ray/XLine/Circle/Arc/Polyline vive en curve.prg; aqui: angular_curve,
   subdivide_angle, tessellate_within y ayudantes.
----------------------------------------------------------------------------*/
#include "ocx.ch"

#define DV_MIN_SEGMENTS 8
#define DV_MAX_SEGMENTS 16384
#define DV_MAX_DEPTH    16

FUNCTION Dv_AngularCurve( c, aBoundaries, nMaxAngle, nMinDepth )
   LOCAL aOut, i
   IF Len( aBoundaries ) == 0 ; RETURN {} ; ENDIF
   aOut := { Cv_PointAt( c, aBoundaries[ 1 ] ) }
   FOR i := 1 TO Len( aBoundaries ) - 1
      Dv_SubdivideAngle( c, aBoundaries[ i ], aBoundaries[ i + 1 ], nMaxAngle, nMinDepth, 0, aOut )
   NEXT
RETURN aOut

STATIC FUNCTION Dv_SubdivideAngle( c, nFrom, nTo, nMaxAngle, nMinDepth, nDepth, aOut )
   LOCAL aDirs := {}, nUnit, lSplit, nMid
   FOR EACH nUnit IN { 0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1.0 }
      AAdd( aDirs, Cv_TangentAt( c, nFrom + ( nTo - nFrom ) * nUnit ) )
   NEXT
   lSplit := nDepth < nMinDepth .OR. Tess_MaxDirectionAngle( aDirs ) > nMaxAngle
   IF lSplit .AND. nDepth < DV_MAX_DEPTH
      nMid := 0.5 * ( nFrom + nTo )
      Dv_SubdivideAngle( c, nFrom, nMid, nMaxAngle, nMinDepth, nDepth + 1, aOut )
      Dv_SubdivideAngle( c, nMid, nTo, nMaxAngle, nMinDepth, nDepth + 1, aOut )
   ELSE
      AAdd( aOut, Cv_PointAt( c, nTo ) )
   ENDIF
RETURN NIL

FUNCTION Cv_TessellateWithin( c, nTol )
   LOCAL d := c[ CV_DATA ]
   DO CASE
   CASE c[ CV_KIND ] == CV_LINE
      RETURN { d[ LN_START ], d[ LN_END ] }
   CASE c[ CV_KIND ] == CV_RAY .OR. c[ CV_KIND ] == CV_XLINE
      RETURN { Cv_PointAt( c, 0.0 ), Cv_PointAt( c, 1.0 ) }
   CASE c[ CV_KIND ] == CV_CIRCLE
      RETURN Dv_SampleUniformly( c, Dv_CircularSteps( d[ CI_RADIUS ], OCX_TAU, nTol ) )
   CASE c[ CV_KIND ] == CV_ARC
      RETURN Dv_SampleUniformly( c, Dv_CircularSteps( d[ AR_RADIUS ], Ar_Sweep( d ), nTol ) )
   CASE c[ CV_KIND ] == CV_ELLIPSE
      RETURN Dv_SampleUniformly( c, Dv_EllipseSteps( d, nTol ) )
   CASE c[ CV_KIND ] == CV_POLYLINE
      RETURN Dv_PolylineWithin( c, nTol )
   ENDCASE
RETURN Dv_NurbsWithin( d, nTol )

STATIC FUNCTION Dv_SamePt( a, b )
RETURN ValType( a ) == "A" .AND. ValType( b ) == "A" .AND. a[ 1 ] == b[ 1 ] .AND. a[ 2 ] == b[ 2 ]

STATIC FUNCTION Dv_PolylineWithin( c, nTol )
   LOCAL pl := c[ CV_DATA ], aVs := pl[ PL_VERTS ], nCount := Len( aVs ), aOut := {}, aPts, i, aSegs, nSkip, k
   IF nCount < 2
      FOR i := 1 TO nCount ; AAdd( aOut, aVs[ i ][ PV_POS ] ) ; NEXT
      RETURN aOut
   ENDIF
   aSegs := Cv_Segments( c )
   FOR i := 0 TO Len( aSegs ) - 1
      aPts := Cv_TessellateWithin( aSegs[ i + 1 ], nTol )
      IF i < nCount                        // vertices.get(index)
         aPts[ 1 ] := aVs[ i + 1 ][ PV_POS ]
      ENDIF
      aPts[ Len( aPts ) ] := aVs[ ( ( i + 1 ) % Max( nCount, 1 ) ) + 1 ][ PV_POS ]
      // segmentos consecutivos comparten vertice: no se emite dos veces
      nSkip := IIF( Len( aOut ) > 0 .AND. Dv_SamePt( ATail( aOut ), aPts[ 1 ] ), 1, 0 )
      FOR k := nSkip + 1 TO Len( aPts ) ; AAdd( aOut, aPts[ k ] ) ; NEXT
   NEXT
RETURN aOut

STATIC FUNCTION Dv_SampleUniformly( c, nSteps )
   LOCAL i, aOut := {}
   FOR i := 0 TO nSteps ; AAdd( aOut, Cv_PointAt( c, i / nSteps ) ) ; NEXT
RETURN aOut

STATIC FUNCTION Dv_Usable( nTol ) ; RETURN OCX_ISFINITE( nTol ) .AND. nTol > 0.0

STATIC FUNCTION Dv_Clamp( n, nLo, nHi ) ; RETURN Max( nLo, Min( nHi, n ) )

STATIC FUNCTION Dv_CircularSteps( nRadius, nSweep, nTol )
   LOCAL nStep
   nRadius := Abs( nRadius ) ; nSweep := Abs( nSweep )
   IF ! Dv_Usable( nTol ) .OR. nRadius <= nTol
      RETURN IIF( nRadius <= nTol, DV_MIN_SEGMENTS, DV_MAX_SEGMENTS )
   ENDIF
   // sag = r(1 - cos(theta/2)) <= tol  =>  theta <= 2 acos(1 - tol/r)
   nStep := 2.0 * OCX_ACOS( Dv_Clamp( 1.0 - nTol / nRadius, -1.0, 1.0 ) )
   IF nStep <= 0.0 ; RETURN DV_MAX_SEGMENTS ; ENDIF
RETURN Int( Dv_Clamp( OCX_CEIL( nSweep / nStep ), DV_MIN_SEGMENTS, DV_MAX_SEGMENTS ) )

STATIC FUNCTION Dv_EllipseSteps( ea, nTol )
   LOCAL e := ea[ EA_ELLIPSE ], nCurv := Max( Abs( e[ ELL_MAJOR_R ] ), Abs( e[ ELL_MINOR_R ] ) ), nSweep := Abs( EA_Sweep( ea ) ), nStep
   IF nCurv <= 0.0 ; RETURN DV_MIN_SEGMENTS ; ENDIF
   IF ! Dv_Usable( nTol ) ; RETURN DV_MAX_SEGMENTS ; ENDIF
   nStep := Sqrt( 8.0 * nTol / nCurv )
   IF nStep <= 0.0 ; RETURN DV_MAX_SEGMENTS ; ENDIF
RETURN Int( Dv_Clamp( OCX_CEIL( nSweep / nStep ), DV_MIN_SEGMENTS, DV_MAX_SEGMENTS ) )

STATIC FUNCTION Dv_NurbsWithin( nc, nTol )
   LOCAL aOut, aSpans, i
   IF ! Dv_Usable( nTol ) ; nTol := 0.0 ; ENDIF
   aOut := { NC_PointAt( nc, 0.0 ) }
   aSpans := Dv_SpanBoundaries( nc )
   FOR i := 1 TO Len( aSpans ) - 1
      Dv_Subdivide( nc, aSpans[ i ], aSpans[ i + 1 ], nTol, 0, aOut )
   NEXT
RETURN aOut

FUNCTION Dv_SpanBoundaries( nc )
   LOCAL aD := NC_Domain( nc ), nWidth := aD[ 2 ] - aD[ 1 ], aVals := { 0.0 }, nKnot, nNorm
   IF nWidth > 0.0
      FOR EACH nKnot IN NC_Knots( nc )
         nNorm := ( nKnot - aD[ 1 ] ) / nWidth
         IF nNorm > 0.000000000001 .AND. nNorm < 1.0 - 0.000000000001
            IF nNorm - ATail( aVals ) > 0.000000000001
               AAdd( aVals, nNorm )
            ENDIF
         ENDIF
      NEXT
   ENDIF
   AAdd( aVals, 1.0 )
RETURN aVals

STATIC FUNCTION Dv_Subdivide( nc, nFrom, nTo, nTol, nDepth, aOut )
   LOCAL nMid := 0.5 * ( nFrom + nTo ), lFlat
   lFlat := nDepth >= DV_MAX_DEPTH
   IF ! lFlat
      lFlat := V2_DistanceToSegment( NC_PointAt( nc, nMid ), NC_PointAt( nc, nFrom ), NC_PointAt( nc, nTo ) ) <= nTol
   ENDIF
   // dos niveles forzados: un tramo cuyo punto medio cae en la cuerda no es necesariamente recto (una S)
   IF lFlat .AND. nDepth >= 2
      AAdd( aOut, NC_PointAt( nc, nTo ) )
      RETURN NIL
   ENDIF
   Dv_Subdivide( nc, nFrom, nMid, nTol, nDepth + 1, aOut )
   Dv_Subdivide( nc, nMid, nTo, nTol, nDepth + 1, aOut )
RETURN NIL
