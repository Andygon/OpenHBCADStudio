/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/tessellate.prg
   Origen Rust: opencadkernel/src/geom2d/tessellate.rs (278 lineas, 11 tests en t_tessellate.prg)
   Puntos 3D = {x,y,z} (f64). Ellipse = Ell_New(...). Se mantiene f64 (el estrechamiento a f32 queda en la GPU).
----------------------------------------------------------------------------*/
#include "ocx.ch"
#define TZ_DEFAULT_SEGMENTS_PER_RADIAN 20.0
#define TZ_MINIMUM_SEGMENTS 4

FUNCTION Tz_DefaultSegmentsPerRadian() ; RETURN TZ_DEFAULT_SEGMENTS_PER_RADIAN
FUNCTION Tz_MinimumSegments() ; RETURN TZ_MINIMUM_SEGMENTS

STATIC FUNCTION Tz_SegmentCount( nSweep, nSpr )
   LOCAL nWanted := OCX_CEIL( Abs( nSweep ) * nSpr )
RETURN IIf( OCX_ISFINITE( nWanted ) .AND. nWanted > TZ_MINIMUM_SEGMENTS, Int( nWanted ), TZ_MINIMUM_SEGMENTS )

FUNCTION Tz_Arc( aCentre, nRadius, nStartAngle, nEndAngle, z, nSpr )
   LOCAL nSweep := ArcSpan( nStartAngle, nEndAngle ), nSegs := Tz_SegmentCount( nSweep, nSpr ), nBase := NormalizeAngle( nStartAngle ), i, nAng, aOut := {}
   FOR i := 0 TO nSegs
      nAng := nBase + nSweep * ( i / nSegs )
      AAdd( aOut, { aCentre[1] + nRadius * OCX_COS( nAng ), aCentre[2] + nRadius * OCX_SIN( nAng ), z } )
   NEXT
RETURN aOut

FUNCTION Tz_EllipseArc( e, nStartP, nEndP, z, nSpr )
   LOCAL nSweep := nEndP - nStartP, nSegs := Tz_SegmentCount( nSweep, nSpr ), i, t, p, aOut := {}
   FOR i := 0 TO nSegs
      t := nStartP + nSweep * ( i / nSegs )
      p := Ell_PointAt( e, t )
      AAdd( aOut, { p[1], p[2], z } )
   NEXT
RETURN aOut

FUNCTION Tz_Lerp( aFrom, aTo, t )
RETURN V2_Lerp( aFrom, aTo, t )
