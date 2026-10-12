/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/tessellation.prg
   Origen Rust: opencadkernel/src/tessellation.rs (128 lineas)
   Estado: TRADUCIDO. direction_angle<const N> -> arrays de cualquier longitud.
   sample_curve3_angle<P,T>: P y T son codeblocks {|t| aPoint3} / {|t| aTangent3}.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Tess_DefaultAngle() ; RETURN OCX_PI_24
FUNCTION Tess_DisplayAngle() ; RETURN OCX_PI_9
FUNCTION Tess_FineAngle()    ; RETURN OCX_PI_36

FUNCTION Tess_Angle( nValue )
   IF OCX_ISFINITE( nValue ) .AND. nValue > 0.0
      RETURN Min( nValue, OCX_FRAC_PI_2 )
   ENDIF
RETURN OCX_PI_24

STATIC FUNCTION ClampRes( nRes )
   IF OCX_ISFINITE( nRes ) .AND. nRes > 0.0
      RETURN Max( 0.01, Min( 10.0, nRes ) )
   ENDIF
RETURN 1.0

FUNCTION Tess_AngleForResolution( nRes )
   nRes := ClampRes( nRes )
RETURN Max( Tess_Angle( OCX_PI_24 / Sqrt( nRes ) ), OCX_PI_36 )

FUNCTION Tess_DisplayAngleForResolution( nRes )
   nRes := ClampRes( nRes )
RETURN Max( Tess_Angle( OCX_PI_9 / Sqrt( Max( nRes, 1.0 ) ) ), OCX_PI_36 )

FUNCTION Tess_DirectionAngle( a, b )
   LOCAL nDot := 0.0, aa := 0.0, bb := 0.0, nLen, i
   FOR i := 1 TO Len( a )
      nDot += a[ i ] * b[ i ]
   NEXT
   FOR i := 1 TO Len( a )
      aa += a[ i ] * a[ i ]
   NEXT
   FOR i := 1 TO Len( a )
      bb += b[ i ] * b[ i ]
   NEXT
   nLen := Sqrt( aa * bb )
   IF ! OCX_ISFINITE( nLen ) .OR. nLen <= OCX_MIN_POSITIVE
      RETURN OCX_PI
   ENDIF
RETURN OCX_ACOS( Max( -1.0, Min( 1.0, nDot / nLen ) ) )

FUNCTION Tess_MaxDirectionAngle( aDirs )
   LOCAL nLargest := 0.0, nFrom, nTo
   FOR nFrom := 1 TO Len( aDirs )
      FOR nTo := nFrom + 1 TO Len( aDirs )
         nLargest := Max( nLargest, Tess_DirectionAngle( aDirs[ nFrom ], aDirs[ nTo ] ) )
      NEXT
   NEXT
RETURN nLargest

FUNCTION Tess_SampleCurve3Angle( bPointAt, bTangentAt, nMaxAngle )
   LOCAL aOut
   nMaxAngle := Tess_Angle( nMaxAngle )
   aOut := { Eval( bPointAt, 0.0 ) }
   Tess_Refine( bPointAt, bTangentAt, 0.0, 1.0, nMaxAngle, 0, aOut )
RETURN aOut

STATIC PROCEDURE Tess_Refine( bP, bT, nFrom, nTo, nMax, nDepth, aOut )
   LOCAL aDirs := {}, nUnit, lSplit, nMid
   FOR EACH nUnit IN { 0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1.0 }
      AAdd( aDirs, Eval( bT, nFrom + ( nTo - nFrom ) * nUnit ) )
   NEXT
   lSplit := nDepth < 2 .OR. Tess_MaxDirectionAngle( aDirs ) > nMax
   IF lSplit .AND. nDepth < 16
      nMid := 0.5 * ( nFrom + nTo )
      Tess_Refine( bP, bT, nFrom, nMid, nMax, nDepth + 1, aOut )
      Tess_Refine( bP, bT, nMid, nTo, nMax, nDepth + 1, aOut )
   ELSE
      AAdd( aOut, Eval( bP, nTo ) )
   ENDIF
RETURN
