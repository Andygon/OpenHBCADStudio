/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/curve.prg
   Origen Rust: opencadkernel/src/geom2d/curve.rs (718 lineas) + parte de
   deviation.rs (Curve::tessellate_angle / polyline_angle).
   Estado: TRADUCIDO curve.rs + tessellate_angle (Ellipse/NURBS en deviation.prg).
   Representacion: Curve = { nKind, aData } (CV_*). Formas:
     Line {aStart,aEnd}  Circle {aCentre,nRadius}  Arc {aCentre,nRadius,nStart,nEnd}
     EllipseArc {aEllipse,nStart,nEnd}  Polyline (ver polyline.prg)  Nurbs (nurbs.prg)
     Ray {aOrigin,aDir}  XLine {aBase,aDir}.   Option -> NIL.
----------------------------------------------------------------------------*/
#include "ocx.ch"

// ---- constructores ---------------------------------------------------------
FUNCTION Cv_Line( aStart, aEnd )          ; RETURN { CV_LINE, { aStart, aEnd } }
FUNCTION Cv_Circle( aCentre, nRadius )    ; RETURN { CV_CIRCLE, { aCentre, nRadius } }
FUNCTION Cv_Arc( aCentre, nR, nS, nE )    ; RETURN { CV_ARC, { aCentre, nR, nS, nE } }
FUNCTION Cv_Ellipse( aArc )               ; RETURN { CV_ELLIPSE, aArc }
FUNCTION Cv_Polyline( aPoly )             ; RETURN { CV_POLYLINE, aPoly }
FUNCTION Cv_Nurbs( aNurbs )               ; RETURN { CV_NURBS, aNurbs }
FUNCTION Cv_Ray( aOrigin, aDir )          ; RETURN { CV_RAY, { aOrigin, aDir } }
FUNCTION Cv_XLine( aBase, aDir )          ; RETURN { CV_XLINE, { aBase, aDir } }

// ---- Line / Arc / EllipseArc ----------------------------------------------
FUNCTION Ln_Direction( ln ) ; RETURN V2_Sub( ln[ LN_END ], ln[ LN_START ] )
FUNCTION Ln_Length( ln )    ; RETURN V2_Distance( ln[ LN_START ], ln[ LN_END ] )
FUNCTION Ar_Sweep( ar )     ; RETURN ArcSpan( ar[ AR_START ], ar[ AR_END ] )

FUNCTION EA_Full( aEllipse ) ; RETURN { aEllipse, 0.0, OCX_TAU }
FUNCTION EA_Sweep( ea )
   LOCAL nRaw := ea[ EA_END ] - ea[ EA_START ]
RETURN IIF( nRaw <= 0.0, nRaw + OCX_TAU, nRaw )

// ---- Extent ----------------------------------------------------------------
FUNCTION Ext_Holds( nExtent, t )
   LOCAL nSlack := 0.000000001
   DO CASE
   CASE nExtent == EXT_BOUNDED ; RETURN t >= -nSlack .AND. t <= 1.0 + nSlack
   CASE nExtent == EXT_FORWARD ; RETURN t >= -nSlack
   ENDCASE
RETURN .T.

// ---- Curve -----------------------------------------------------------------
FUNCTION Cv_Extent( c )
   IF c[ CV_KIND ] == CV_RAY   ; RETURN EXT_FORWARD ; ENDIF
   IF c[ CV_KIND ] == CV_XLINE ; RETURN EXT_INFINITE ; ENDIF
RETURN EXT_BOUNDED

FUNCTION Cv_IsStraight( c )
RETURN c[ CV_KIND ] == CV_LINE .OR. c[ CV_KIND ] == CV_RAY .OR. c[ CV_KIND ] == CV_XLINE

STATIC FUNCTION ParamNear( a, b )
RETURN Abs( a - b ) <= OCX_EPSILON() * 128.0 * Max( Max( Abs( a ), Abs( b ) ), 1.0 )

STATIC FUNCTION ParamWithin( nValue, aB )
   LOCAL nScale := Max( Max( Max( Abs( nValue ), Abs( aB[ 1 ] ) ), Abs( aB[ 2 ] ) ), 1.0 )
RETURN nValue >= aB[ 1 ] - OCX_EPSILON() * 128.0 * nScale .AND. nValue <= aB[ 2 ] + OCX_EPSILON() * 128.0 * nScale

// Option<usize>; aBounds = { {xmin,xmax}, {ymin,ymax} } (bounds[eje][lado])
FUNCTION Cv_RectangleSide( c, aBounds )
   LOCAL aEnd := { Cv_PointAt( c, 0.0 ), Cv_PointAt( c, 1.0 ) }
   LOCAL nFixed, nVarying, nSide, nFixedValue, lOn, lCovers, p
   FOR nFixed := 0 TO 1
      nVarying := 1 - nFixed
      FOR nSide := 0 TO 1
         nFixedValue := aBounds[ nFixed + 1 ][ nSide + 1 ]
         DO CASE
         CASE c[ CV_KIND ] == CV_LINE
            lOn := ParamNear( c[ CV_DATA ][ LN_START ][ nFixed + 1 ], nFixedValue ) .AND. ;
                   ParamNear( c[ CV_DATA ][ LN_END ][ nFixed + 1 ], nFixedValue )
         CASE c[ CV_KIND ] == CV_NURBS
            lOn := .T.
            FOR EACH p IN NC_ControlPoints( c[ CV_DATA ] )
               IF ! ( ParamNear( p[ nFixed + 1 ], nFixedValue ) .AND. ParamWithin( p[ nVarying + 1 ], aBounds[ nVarying + 1 ] ) )
                  lOn := .F. ; EXIT
               ENDIF
            NEXT
         OTHERWISE
            RETURN NIL
         ENDCASE
         lCovers := ( ParamNear( aEnd[ 1 ][ nVarying + 1 ], aBounds[ nVarying + 1 ][ 1 ] ) .AND. ParamNear( aEnd[ 2 ][ nVarying + 1 ], aBounds[ nVarying + 1 ][ 2 ] ) ) .OR. ;
                    ( ParamNear( aEnd[ 2 ][ nVarying + 1 ], aBounds[ nVarying + 1 ][ 1 ] ) .AND. ParamNear( aEnd[ 1 ][ nVarying + 1 ], aBounds[ nVarying + 1 ][ 2 ] ) )
         IF lOn .AND. lCovers
            RETURN nFixed * 2 + nSide
         ENDIF
      NEXT
   NEXT
RETURN NIL

// Option<(origin, direction)> -> NIL o { origin, direction }
FUNCTION Cv_AsRay( c )
   DO CASE
   CASE c[ CV_KIND ] == CV_LINE  ; RETURN { c[ CV_DATA ][ LN_START ], Ln_Direction( c[ CV_DATA ] ) }
   CASE c[ CV_KIND ] == CV_RAY   ; RETURN { c[ CV_DATA ][ RY_ORIGIN ], c[ CV_DATA ][ RY_DIR ] }
   CASE c[ CV_KIND ] == CV_XLINE ; RETURN { c[ CV_DATA ][ XL_BASE ], c[ CV_DATA ][ XL_DIR ] }
   ENDCASE
RETURN NIL

FUNCTION Cv_Segments( c )
   LOCAL pl, nCount, nVerts, i, aStart, aEnd, ba, nFrom, nTo, aOut := {}
   IF c[ CV_KIND ] != CV_POLYLINE ; RETURN {} ; ENDIF
   pl := c[ CV_DATA ]
   nCount := PolySegCount( pl )
   nVerts := Len( pl[ PL_VERTS ] )
   FOR i := 0 TO nCount - 1
      aStart := pl[ PL_VERTS ][ i + 1 ][ PV_POS ]
      aEnd   := pl[ PL_VERTS ][ ( ( i + 1 ) % nVerts ) + 1 ][ PV_POS ]
      ba := PL_SegmentArc( pl, i )
      IF ba != NIL
         // Los arcos corren CCW: un bulge horario se guarda con los extremos al reves
         IF ba[ BA_SWEEP ] >= 0.0
            nFrom := ba[ BA_START ] ; nTo := ba[ BA_START ] + ba[ BA_SWEEP ]
         ELSE
            nFrom := ba[ BA_END ] ; nTo := ba[ BA_END ] - ba[ BA_SWEEP ]
         ENDIF
         AAdd( aOut, Cv_Arc( ba[ BA_CENTER ], ba[ BA_RADIUS ], nFrom, nTo ) )
      ELSE
         AAdd( aOut, Cv_Line( aStart, aEnd ) )
      ENDIF
   NEXT
RETURN aOut

FUNCTION Cv_IsClosed( c )
   DO CASE
   CASE c[ CV_KIND ] == CV_LINE     ; RETURN .F.
   CASE c[ CV_KIND ] == CV_CIRCLE   ; RETURN .T.
   CASE c[ CV_KIND ] == CV_ARC      ; RETURN Abs( Ar_Sweep( c[ CV_DATA ] ) - OCX_TAU ) < 0.000000001
   CASE c[ CV_KIND ] == CV_ELLIPSE  ; RETURN Abs( EA_Sweep( c[ CV_DATA ] ) - OCX_TAU ) < 0.000000001
   CASE c[ CV_KIND ] == CV_POLYLINE ; RETURN c[ CV_DATA ][ PL_CLOSED ]
   CASE c[ CV_KIND ] == CV_NURBS    ; RETURN NC_IsClosed( c[ CV_DATA ] )
   ENDCASE
RETURN .F.     // Ray | XLine

FUNCTION Cv_PointAt( c, t )
   LOCAL d := c[ CV_DATA ], nAngle
   DO CASE
   CASE c[ CV_KIND ] == CV_LINE
      RETURN { d[ LN_START ][ 1 ] + t * ( d[ LN_END ][ 1 ] - d[ LN_START ][ 1 ] ), ;
               d[ LN_START ][ 2 ] + t * ( d[ LN_END ][ 2 ] - d[ LN_START ][ 2 ] ) }
   CASE c[ CV_KIND ] == CV_CIRCLE
      nAngle := t * OCX_TAU
      RETURN { d[ CI_CENTRE ][ 1 ] + d[ CI_RADIUS ] * OCX_COS( nAngle ), d[ CI_CENTRE ][ 2 ] + d[ CI_RADIUS ] * OCX_SIN( nAngle ) }
   CASE c[ CV_KIND ] == CV_ARC
      nAngle := NormalizeAngle( d[ AR_START ] ) + t * Ar_Sweep( d )
      RETURN { d[ AR_CENTRE ][ 1 ] + d[ AR_RADIUS ] * OCX_COS( nAngle ), d[ AR_CENTRE ][ 2 ] + d[ AR_RADIUS ] * OCX_SIN( nAngle ) }
   CASE c[ CV_KIND ] == CV_ELLIPSE
      RETURN Ell_PointAt( d[ EA_ELLIPSE ], d[ EA_START ] + t * EA_Sweep( d ) )
   CASE c[ CV_KIND ] == CV_POLYLINE
      RETURN PointOnPolyline( d, t )
   CASE c[ CV_KIND ] == CV_NURBS
      RETURN NC_PointAt( d, t )
   CASE c[ CV_KIND ] == CV_RAY
      RETURN { d[ RY_ORIGIN ][ 1 ] + t * d[ RY_DIR ][ 1 ], d[ RY_ORIGIN ][ 2 ] + t * d[ RY_DIR ][ 2 ] }
   ENDCASE
   // XLine
RETURN { d[ XL_BASE ][ 1 ] + t * d[ XL_DIR ][ 1 ], d[ XL_BASE ][ 2 ] + t * d[ XL_DIR ][ 2 ] }

FUNCTION Cv_ParameterAt( c, aPoint )
   LOCAL d := c[ CV_DATA ], aAlong, nSq, nAngle, nParam, nTravelled, aRay
   DO CASE
   CASE c[ CV_KIND ] == CV_LINE
      aAlong := Ln_Direction( d ) ; nSq := V2_LengthSquared( aAlong )
      IF nSq < 0.000000000000000000000001 ; RETURN 0.0 ; ENDIF
      RETURN V2_Dot( V2_Sub( aPoint, d[ LN_START ] ), aAlong ) / nSq
   CASE c[ CV_KIND ] == CV_CIRCLE
      nAngle := OCX_ATAN2( aPoint[ 2 ] - d[ CI_CENTRE ][ 2 ], aPoint[ 1 ] - d[ CI_CENTRE ][ 1 ] )
      RETURN NormalizeAngle( nAngle ) / OCX_TAU
   CASE c[ CV_KIND ] == CV_ARC
      nAngle := OCX_ATAN2( aPoint[ 2 ] - d[ AR_CENTRE ][ 2 ], aPoint[ 1 ] - d[ AR_CENTRE ][ 1 ] )
      RETURN ArcParameter( nAngle, d[ AR_START ], d[ AR_END ] )
   CASE c[ CV_KIND ] == CV_ELLIPSE
      nParam := Ell_ClosestParameter( d[ EA_ELLIPSE ], aPoint )
      nTravelled := OCX_REMEUCLID( nParam - d[ EA_START ], OCX_TAU )
      RETURN nTravelled / EA_Sweep( d )
   CASE c[ CV_KIND ] == CV_POLYLINE
      RETURN ParameterOnPolyline( d, aPoint )
   CASE c[ CV_KIND ] == CV_NURBS
      RETURN NC_ParameterAt( d, aPoint )
   ENDCASE
   // Ray | XLine
   aRay := Cv_AsRay( c )
   aAlong := aRay[ 2 ] ; nSq := V2_LengthSquared( aAlong )
   IF nSq < 0.000000000000000000000001 ; RETURN 0.0 ; ENDIF
RETURN V2_Dot( V2_Sub( aPoint, aRay[ 1 ] ), aAlong ) / nSq

FUNCTION Cv_SegmentCount( c )
   IF c[ CV_KIND ] == CV_POLYLINE ; RETURN PolySegCount( c[ CV_DATA ] ) ; ENDIF
RETURN 1

FUNCTION Cv_Tessellate( c, nSegsPerRadian )
   LOCAL nMax
   IF OCX_ISFINITE( nSegsPerRadian ) .AND. nSegsPerRadian > 0.0
      nMax := 1.0 / nSegsPerRadian
   ELSE
      nMax := Tess_DefaultAngle()
   ENDIF
RETURN Cv_TessellateAngle( c, nMax )

// ---- ayudantes de polilinea (privados en Rust) -----------------------------
STATIC FUNCTION PolySegCount( pl )
   LOCAL n := Len( pl[ PL_VERTS ] )
   IF n < 2 ; RETURN 0 ; ENDIF
RETURN IIF( pl[ PL_CLOSED ], n, n - 1 )

// Option<(usize,f64)> -> NIL | { index, local }
STATIC FUNCTION SplitParameter( pl, t )
   LOCAL nCount := PolySegCount( pl ), nScaled, nIndex
   IF nCount == 0 ; RETURN NIL ; ENDIF
   nScaled := Max( 0.0, Min( nCount * 1.0, t * nCount ) )
   nIndex := Min( Int( OCX_FLOOR( nScaled ) ), nCount - 1 )
RETURN { nIndex, nScaled - nIndex }

STATIC FUNCTION PointOnPolyline( pl, t )
   LOCAL aSp := SplitParameter( pl, t ), nCount, aStart, aEnd, ba
   IF aSp == NIL
      RETURN IIF( Len( pl[ PL_VERTS ] ) > 0, pl[ PL_VERTS ][ 1 ][ PV_POS ], { 0.0, 0.0 } )
   ENDIF
   nCount := Len( pl[ PL_VERTS ] )
   aStart := pl[ PL_VERTS ][ aSp[ 1 ] + 1 ][ PV_POS ]
   aEnd   := pl[ PL_VERTS ][ ( ( aSp[ 1 ] + 1 ) % nCount ) + 1 ][ PV_POS ]
   ba := PL_SegmentArc( pl, aSp[ 1 ] )
   IF ba != NIL
      RETURN BA_Sample( ba, aSp[ 2 ] )
   ENDIF
RETURN V2_Lerp( aStart, aEnd, aSp[ 2 ] )

STATIC FUNCTION ParameterOnPolyline( pl, aPoint )
   LOCAL nCount := PolySegCount( pl ), nVerts := Len( pl[ PL_VERTS ] ), nBestD, nBestT := 0.0
   LOCAL i, aStart, aEnd, ba, nAngle, nTravelled, nLocal, aAlong, nSq, nCand, nDist
   IF nCount == 0 ; RETURN 0.0 ; ENDIF
   FOR i := 0 TO nCount - 1
      aStart := pl[ PL_VERTS ][ i + 1 ][ PV_POS ]
      aEnd   := pl[ PL_VERTS ][ ( ( i + 1 ) % nVerts ) + 1 ][ PV_POS ]
      ba := PL_SegmentArc( pl, i )
      IF ba != NIL
         nAngle := OCX_ATAN2( aPoint[ 2 ] - ba[ BA_CENTER ][ 2 ], aPoint[ 1 ] - ba[ BA_CENTER ][ 1 ] )
         // atan2 cae en -pi..pi: la diferencia se envuelve en el sentido en que viaja el arco
         IF ba[ BA_SWEEP ] >= 0.0
            nTravelled := OCX_REMEUCLID( nAngle - ba[ BA_START ], OCX_TAU )
         ELSE
            nTravelled := -OCX_REMEUCLID( ba[ BA_START ] - nAngle, OCX_TAU )
         ENDIF
         nLocal := Max( 0.0, Min( 1.0, nTravelled / ba[ BA_SWEEP ] ) )
      ELSE
         aAlong := V2_Sub( aEnd, aStart ) ; nSq := V2_LengthSquared( aAlong )
         IF nSq < 0.000000000000000000000001
            nLocal := 0.0
         ELSE
            nLocal := Max( 0.0, Min( 1.0, V2_Dot( V2_Sub( aPoint, aStart ), aAlong ) / nSq ) )
         ENDIF
      ENDIF
      nCand := ( i + nLocal ) / nCount
      nDist := V2_DistanceSquared( PointOnPolyline( pl, nCand ), aPoint )
      IF nBestD == NIL .OR. nDist < nBestD
         nBestD := nDist ; nBestT := nCand
      ENDIF
   NEXT
RETURN nBestT

// ---- deviation.rs (parcial): Curve::tessellate_angle -------------------------
STATIC FUNCTION AngularSteps( nSweep, nMaxAngle )
RETURN Int( Max( OCX_CEIL( Abs( nSweep ) / nMaxAngle ), 1.0 ) )

STATIC FUNCTION SampleUniformly( c, nSteps )
   LOCAL i, aOut := {}
   FOR i := 0 TO nSteps ; AAdd( aOut, Cv_PointAt( c, i / nSteps ) ) ; NEXT
RETURN aOut

FUNCTION Cv_TessellateAngle( c, nMaxAngle )
   nMaxAngle := Tess_Angle( nMaxAngle )
   DO CASE
   CASE c[ CV_KIND ] == CV_LINE
      RETURN { c[ CV_DATA ][ LN_START ], c[ CV_DATA ][ LN_END ] }
   CASE c[ CV_KIND ] == CV_RAY .OR. c[ CV_KIND ] == CV_XLINE
      RETURN { Cv_PointAt( c, 0.0 ), Cv_PointAt( c, 1.0 ) }
   CASE c[ CV_KIND ] == CV_CIRCLE
      RETURN SampleUniformly( c, AngularSteps( OCX_TAU, nMaxAngle ) )
   CASE c[ CV_KIND ] == CV_ARC
      RETURN SampleUniformly( c, AngularSteps( Ar_Sweep( c[ CV_DATA ] ), nMaxAngle ) )
   CASE c[ CV_KIND ] == CV_POLYLINE
      RETURN PolylineAngle( c, nMaxAngle )
   ENDCASE
   IF c[ CV_KIND ] == CV_ELLIPSE
      RETURN Dv_AngularCurve( c, { 0.0, 1.0 }, nMaxAngle, 0 )
   ENDIF
   // Nurbs
RETURN Dv_AngularCurve( c, Dv_SpanBoundaries( c[ CV_DATA ] ), nMaxAngle, 2 )

FUNCTION OcxError( cMsg )
   LOCAL oErr := ErrorNew()
   oErr:description := cMsg
   oErr:severity := 2
RETURN oErr

STATIC FUNCTION SamePt( a, b )
RETURN ValType( a ) == "A" .AND. ValType( b ) == "A" .AND. a[ 1 ] == b[ 1 ] .AND. a[ 2 ] == b[ 2 ]

STATIC FUNCTION PolylineAngle( c, nMaxAngle )
   LOCAL pl := c[ CV_DATA ], nCount := Len( pl[ PL_VERTS ] ), nSegs, i, nNext, aPts, ba, aOut := {}, nSkip, k, aVs := pl[ PL_VERTS ]
   nSegs := IIF( pl[ PL_CLOSED ], nCount, Max( nCount - 1, 0 ) )
   IF nSegs == 0
      FOR i := 1 TO nCount ; AAdd( aOut, aVs[ i ][ PV_POS ] ) ; NEXT
      RETURN aOut
   ENDIF
   FOR i := 0 TO nSegs - 1
      nNext := ( i + 1 ) % nCount
      ba := PL_SegmentArc( pl, i )
      IF ba != NIL
         aPts := BA_TessellateAngle( ba, nMaxAngle )
      ELSE
         aPts := { aVs[ i + 1 ][ PV_POS ], aVs[ nNext + 1 ][ PV_POS ] }
      ENDIF
      aPts[ 1 ] := aVs[ i + 1 ][ PV_POS ]
      aPts[ Len( aPts ) ] := aVs[ nNext + 1 ][ PV_POS ]
      nSkip := IIF( Len( aOut ) > 0 .AND. SamePt( ATail( aOut ), aPts[ 1 ] ), 1, 0 )
      FOR k := nSkip + 1 TO Len( aPts ) ; AAdd( aOut, aPts[ k ] ) ; NEXT
   NEXT
RETURN aOut
