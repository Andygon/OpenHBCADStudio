/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_hatch.prg
   Origen Rust: opencadcodec/src/entities/hatch.rs (708, sin tests) + hatch_origin.rs (tests 1:1, salvo el de DWG que queda fuera de alcance)
              + translate_hatch, transform_hatch, mirror_hatch. Licencia del original: MPL-2.0.
   Modelo: Hatch = hash ("_type" "HATCH"). BoundaryPathFlags = entero con los bits (Bpf_*). EdgeType/HatchPatternType/HatchStyleType = enteros (HPT_*, HST_*).
   Aristas = hash con "kind" ("Line","CircularArc","EllipticArc","Spline","Polyline"). Vertices de PolylineEdge = Vector3 {x,y,bulge}.
   Prefijos: Bpf_ (flags), Bpa_ (BoundaryPath), Hpt_ (HatchPattern), Hgp_ (gradiente), Ehh_ (Hatch).
----------------------------------------------------------------------------*/
#include "ocx.ch"

#define HPT_USERDEFINED 0
#define HPT_PREDEFINED  1
#define HPT_CUSTOM      2
#define HST_NORMAL      0
#define HST_OUTER       1
#define HST_IGNORE      2

// ---- BoundaryPathFlags (bits u32) ----
FUNCTION Bpf_IsSet( n, nBit ) ; RETURN hb_bitAnd( n, nBit ) != 0
FUNCTION Bpf_Set( n, nBit, lVal ) ; RETURN iif( lVal, hb_bitOr( n, nBit ), hb_bitAnd( n, hb_bitNot( nBit ) ) )
FUNCTION Bpf_IsExternal( n ) ; RETURN Bpf_IsSet( n, 1 )
FUNCTION Bpf_IsPolyline( n ) ; RETURN Bpf_IsSet( n, 2 )
FUNCTION Bpf_IsDerived( n ) ; RETURN Bpf_IsSet( n, 4 )
FUNCTION Bpf_IsOutermost( n ) ; RETURN Bpf_IsSet( n, 16 )
FUNCTION Bpf_IsNotClosed( n ) ; RETURN Bpf_IsSet( n, 32 )

// ---- aristas ----
FUNCTION Bed_Line( vStart, vEnd ) ; RETURN hb_Hash( "kind", "Line", "start", vStart, "end", vEnd )
FUNCTION Bed_CircularArc( vCenter, nRadius, nStart, nEnd, lCcw ) ; RETURN hb_Hash( "kind", "CircularArc", "center", vCenter, "radius", nRadius, "start_angle", nStart, "end_angle", nEnd, "counter_clockwise", lCcw )
FUNCTION Bed_EllipticArc( vCenter, vMajor, nRatio, nStart, nEnd, lCcw ) ; RETURN hb_Hash( "kind", "EllipticArc", "center", vCenter, "major_axis_endpoint", vMajor, "minor_axis_ratio", nRatio, "start_angle", nStart, "end_angle", nEnd, "counter_clockwise", lCcw )
FUNCTION Bed_Spline() ; RETURN hb_Hash( "kind", "Spline", "degree", 0, "rational", .F., "periodic", .F., "knots", {}, "control_points", {}, "fit_points", {}, "start_tangent", Vc2_Zero(), "end_tangent", Vc2_Zero() )
/* PolylineEdge::new(vertices: Vec<Vector2>, is_closed) */
FUNCTION Bed_Polyline( aVerts2, lClosed )
   LOCAL v, a := {}
   FOR EACH v IN aVerts2 ; AAdd( a, Vc3_New( v[ 1 ], v[ 2 ], 0.0 ) ) ; NEXT
RETURN hb_Hash( "kind", "Polyline", "vertices", a, "is_closed", lClosed )
FUNCTION Bed_AddVertex( e, vPoint, nBulge ) ; AAdd( e[ "vertices" ], Vc3_New( vPoint[ 1 ], vPoint[ 2 ], nBulge ) ) ; RETURN NIL
FUNCTION Bed_HasBulge( e )
   LOCAL v
   FOR EACH v IN e[ "vertices" ]
      IF Abs( v[ 3 ] ) > 0.0000000001 ; RETURN .T. ; ENDIF
   NEXT
RETURN .F.

// ---- BoundaryPath ----
FUNCTION Bpa_New() ; RETURN hb_Hash( "flags", 0, "edges", {}, "boundary_handles", {} )
FUNCTION Bpa_WithFlags( nFlags ) ; RETURN hb_Hash( "flags", nFlags, "edges", {}, "boundary_handles", {} )
FUNCTION Bpa_External()
   LOCAL p := Bpa_New()
   p[ "flags" ] := Bpf_Set( p[ "flags" ], 1, .T. )
RETURN p
FUNCTION Bpa_AddEdge( p, e )
   IF e[ "kind" ] == "Polyline" ; p[ "flags" ] := Bpf_Set( p[ "flags" ], 2, .T. ) ; ENDIF
   AAdd( p[ "edges" ], e )
RETURN NIL
FUNCTION Bpa_AddBoundaryHandle( p, h ) ; AAdd( p[ "boundary_handles" ], h ) ; RETURN NIL
FUNCTION Bpa_IsPolyline( p ) ; RETURN Len( p[ "edges" ] ) == 1 .AND. p[ "edges" ][ 1 ][ "kind" ] == "Polyline"

// ---- HatchPattern ----
FUNCTION Hpl_New( nAngle, vBase, vOffset, aDash ) ; RETURN hb_Hash( "angle", nAngle, "base_point", vBase, "offset", vOffset, "dash_lengths", aDash )
FUNCTION Hpt_New( cName ) ; RETURN hb_Hash( "name", cName, "description", "", "lines", {} )
FUNCTION Hpt_Solid() ; RETURN Hpt_New( "SOLID" )
FUNCTION Hpt_AddLine( p, l ) ; AAdd( p[ "lines" ], l ) ; RETURN NIL
FUNCTION Hpt_Update( p, vBase, nAngle, nScale )
   LOCAL l, i
   HB_SYMBOL_UNUSED( vBase )
   FOR EACH l IN p[ "lines" ]
      l[ "angle" ] += nAngle
      l[ "offset" ] := Vc2_Mul( l[ "offset" ], nScale )
      FOR i := 1 TO Len( l[ "dash_lengths" ] ) ; l[ "dash_lengths" ][ i ] *= nScale ; NEXT
   NEXT
RETURN NIL

// ---- gradiente ----
FUNCTION Hgp_New() ; RETURN hb_Hash( "enabled", .F., "reserved", 0, "angle", 0.0, "shift", 0.0, "is_single_color", .F., "color_tint", 0.0, "colors", {}, "name", "" )
FUNCTION Hgp_IsEnabled( g ) ; RETURN g[ "enabled" ]
FUNCTION Hgp_AddColor( g, nValue, aColor ) ; AAdd( g[ "colors" ], hb_Hash( "value", nValue, "color", aColor ) ) ; RETURN NIL

// ---- Hatch ----
FUNCTION Ehh_New()
RETURN hb_Hash( "_type", "HATCH", "common", Ec_New(), "is_mpolygon", .F., "elevation", 0.0, "normal", Vc3_UnitZ(), "pattern", Hpt_Solid(), "is_solid", .T., ;
   "is_associative", .F., "pattern_type", HPT_PREDEFINED, "pattern_angle", 0.0, "pattern_scale", 1.0, "is_double", .F., "style", HST_NORMAL, "paths", {}, ;
   "seed_points", {}, "pixel_size", 0.0, "gradient_color", Hgp_New(), "mpolygon_hatch_color", Cl_ByLayer(), "mpolygon_x_direction", Vc2_Zero(), "mpolygon_invalid_loops", {} )
FUNCTION Ehh_Solid()
   LOCAL h := Ehh_New()
   h[ "is_solid" ] := .T. ; h[ "pattern" ] := Hpt_Solid()
RETURN h
FUNCTION Ehh_WithPattern( pPattern )
   LOCAL h := Ehh_New()
   h[ "is_solid" ] := .F. ; h[ "pattern" ] := pPattern
RETURN h
FUNCTION Ehh_SetPatternAngle( h, nAngle ) ; h[ "pattern_angle" ] := nAngle ; Hpt_Update( h[ "pattern" ], Vc2_Zero(), nAngle, h[ "pattern_scale" ] ) ; RETURN NIL
FUNCTION Ehh_SetPatternScale( h, nScale ) ; h[ "pattern_scale" ] := nScale ; Hpt_Update( h[ "pattern" ], Vc2_Zero(), h[ "pattern_angle" ], nScale ) ; RETURN NIL
/* with_*: mutan y devuelven h (builders) */
FUNCTION Ehh_WithPatternAngle( h, nAngle ) ; Ehh_SetPatternAngle( h, nAngle ) ; RETURN h
FUNCTION Ehh_WithPatternScale( h, nScale ) ; Ehh_SetPatternScale( h, nScale ) ; RETURN h
FUNCTION Ehh_WithNormal( h, v ) ; h[ "normal" ] := v ; RETURN h
FUNCTION Ehh_WithElevation( h, n ) ; h[ "elevation" ] := n ; RETURN h
FUNCTION Ehh_AddPath( h, p ) ; AAdd( h[ "paths" ], p ) ; RETURN NIL
FUNCTION Ehh_AddSeedPoint( h, v ) ; AAdd( h[ "seed_points" ], v ) ; RETURN NIL
FUNCTION Ehh_PathCount( h ) ; RETURN Len( h[ "paths" ] )
FUNCTION Ehh_HasPaths( h ) ; RETURN Len( h[ "paths" ] ) > 0

FUNCTION Ehh_BoundingBox( h )
   LOCAL aPts := {}, p, e, z := h[ "elevation" ], nL, v, bb
   FOR EACH p IN h[ "paths" ]
      FOR EACH e IN p[ "edges" ]
         DO CASE
         CASE e[ "kind" ] == "Line"
            AAdd( aPts, Vc3_New( e[ "start" ][ 1 ], e[ "start" ][ 2 ], z ) ) ; AAdd( aPts, Vc3_New( e[ "end" ][ 1 ], e[ "end" ][ 2 ], z ) )
         CASE e[ "kind" ] == "CircularArc"
            AAdd( aPts, Vc3_New( e[ "center" ][ 1 ] - e[ "radius" ], e[ "center" ][ 2 ] - e[ "radius" ], z ) )
            AAdd( aPts, Vc3_New( e[ "center" ][ 1 ] + e[ "radius" ], e[ "center" ][ 2 ] + e[ "radius" ], z ) )
         CASE e[ "kind" ] == "EllipticArc"
            nL := Vc2_Length( e[ "major_axis_endpoint" ] )
            AAdd( aPts, Vc3_New( e[ "center" ][ 1 ] - nL, e[ "center" ][ 2 ] - nL, z ) )
            AAdd( aPts, Vc3_New( e[ "center" ][ 1 ] + nL, e[ "center" ][ 2 ] + nL, z ) )
         CASE e[ "kind" ] == "Spline"
            FOR EACH v IN e[ "control_points" ] ; AAdd( aPts, Vc3_New( v[ 1 ], v[ 2 ], z ) ) ; NEXT
         CASE e[ "kind" ] == "Polyline"
            FOR EACH v IN e[ "vertices" ] ; AAdd( aPts, Vc3_New( v[ 1 ], v[ 2 ], z ) ) ; NEXT
         ENDCASE
      NEXT
   NEXT
   IF Len( aPts ) == 0 ; RETURN Bb3_New( Vc3_Zero(), Vc3_Zero() ) ; ENDIF
   bb := Bb3_FromPoints( aPts )
RETURN Bb3_OcsToWcs( bb, h[ "normal" ] )

// ---- hatch_origin.rs ----
STATIC FUNCTION OriginIndex( r )
   LOCAL nDepth := 0, i, v, aV := Xr_Values( r )
   FOR i := 1 TO Len( aV )
      v := aV[ i ]
      DO CASE
      CASE v[ 1 ] == XV_CONTROLSTRING .AND. v[ 2 ] == "{" ; nDepth++
      CASE v[ 1 ] == XV_CONTROLSTRING .AND. v[ 2 ] == "}" ; nDepth := Max( nDepth - 1, 0 )
      CASE v[ 1 ] == XV_POINT3D .AND. nDepth == 0 ; RETURN i
      ENDCASE
   NEXT
RETURN 0
/* Option<Vector2> */
FUNCTION Ehh_StoredPatternOrigin( h )
   LOCAL r := Xd_GetRecord( h[ "common" ][ "extended_data" ], "ACAD" ), n, pt
   IF r == NIL ; RETURN NIL ; ENDIF
   n := OriginIndex( r ) ; IF n == 0 ; RETURN NIL ; ENDIF
   pt := Xr_Values( r )[ n ][ 2 ]
RETURN iif( OCX_ISFINITE( pt[ 1 ] ) .AND. OCX_ISFINITE( pt[ 2 ] ), Vc2_New( pt[ 1 ], pt[ 2 ] ), NIL )
FUNCTION Ehh_PatternOrigin( h )
   LOCAL o := Ehh_StoredPatternOrigin( h )
RETURN iif( o == NIL, Vc2_New( 0.0, 0.0 ), o )
FUNCTION Ehh_RecordPatternOrigin( h, vOrigin )
   LOCAL r, n, xv := Xv_New( XV_POINT3D, Vc3_New( vOrigin[ 1 ], vOrigin[ 2 ], 0.0 ) ), xd := h[ "common" ][ "extended_data" ]
   IF ! OCX_ISFINITE( vOrigin[ 1 ] ) .OR. ! OCX_ISFINITE( vOrigin[ 2 ] ) ; RETURN .F. ; ENDIF
   r := Xd_GetRecord( xd, "ACAD" )
   r := iif( r == NIL, Xr_New( "ACAD" ), Ent_Clone( r ) )
   n := OriginIndex( r )
   IF n > 0 ; Xr_Values( r )[ n ] := xv ; ELSE ; Xr_AddValue( r, xv ) ; ENDIF
   Xd_UpsertRecord( xd, r )
RETURN .T.
FUNCTION Ehh_SetPatternOrigin( h, vOrigin )
   LOCAL vPrev, nDx, nDy, l
   IF ! OCX_ISFINITE( vOrigin[ 1 ] ) .OR. ! OCX_ISFINITE( vOrigin[ 2 ] ) ; RETURN .F. ; ENDIF
   vPrev := Ehh_PatternOrigin( h )
   nDx := vOrigin[ 1 ] - vPrev[ 1 ] ; nDy := vOrigin[ 2 ] - vPrev[ 2 ]
   IF ! OCX_ISFINITE( nDx ) .OR. ! OCX_ISFINITE( nDy ) ; RETURN .F. ; ENDIF
   FOR EACH l IN h[ "pattern" ][ "lines" ]
      IF ! OCX_ISFINITE( l[ "base_point" ][ 1 ] + nDx ) .OR. ! OCX_ISFINITE( l[ "base_point" ][ 2 ] + nDy ) ; RETURN .F. ; ENDIF
   NEXT
   FOR EACH l IN h[ "pattern" ][ "lines" ]
      l[ "base_point" ][ 1 ] += nDx ; l[ "base_point" ][ 2 ] += nDy
   NEXT
RETURN Ehh_RecordPatternOrigin( h, vOrigin )
FUNCTION Ehh_ScalePatternAboutOrigin( h, nF )
   LOCAL o, l, i
   IF ! OCX_ISFINITE( nF ) .OR. nF <= 0.0 ; RETURN NIL ; ENDIF
   o := Ehh_PatternOrigin( h )
   FOR EACH l IN h[ "pattern" ][ "lines" ]
      l[ "base_point" ][ 1 ] := o[ 1 ] + ( l[ "base_point" ][ 1 ] - o[ 1 ] ) * nF
      l[ "base_point" ][ 2 ] := o[ 2 ] + ( l[ "base_point" ][ 2 ] - o[ 2 ] ) * nF
      l[ "offset" ][ 1 ] *= nF ; l[ "offset" ][ 2 ] *= nF
      FOR i := 1 TO Len( l[ "dash_lengths" ] ) ; l[ "dash_lengths" ][ i ] *= nF ; NEXT
   NEXT
RETURN NIL
FUNCTION Ehh_RotatePatternAboutOrigin( h, nA )
   LOCAL o, l, x, y, nC, nS
   IF ! OCX_ISFINITE( nA ) ; RETURN NIL ; ENDIF
   o := Ehh_PatternOrigin( h ) ; nC := OCX_COS( nA ) ; nS := OCX_SIN( nA )
   FOR EACH l IN h[ "pattern" ][ "lines" ]
      x := l[ "base_point" ][ 1 ] - o[ 1 ] ; y := l[ "base_point" ][ 2 ] - o[ 2 ]
      l[ "base_point" ][ 1 ] := o[ 1 ] + x * nC - y * nS
      l[ "base_point" ][ 2 ] := o[ 2 ] + x * nS + y * nC
      x := l[ "offset" ][ 1 ] ; y := l[ "offset" ][ 2 ]
      l[ "offset" ][ 1 ] := x * nC - y * nS
      l[ "offset" ][ 2 ] := x * nS + y * nC
      l[ "angle" ] += nA
   NEXT
RETURN NIL

// ---- translate_hatch ----
FUNCTION Ehh_Translate( h, vOffset )
   LOCAL mO2W := Mx3_ArbitraryAxis( h[ "normal" ] ), vO := Mx3_TransformPoint( Mx3_Transpose( mO2W ), vOffset ), vOrg := Ehh_PatternOrigin( h )
   LOCAL p, e, v
   Ehh_SetPatternOrigin( h, Vc2_New( vOrg[ 1 ] + vO[ 1 ], vOrg[ 2 ] + vO[ 2 ] ) )
   h[ "elevation" ] += vO[ 3 ]
   FOR EACH p IN h[ "paths" ]
      FOR EACH e IN p[ "edges" ]
         DO CASE
         CASE e[ "kind" ] == "Line"
            e[ "start" ][ 1 ] += vO[ 1 ] ; e[ "start" ][ 2 ] += vO[ 2 ] ; e[ "end" ][ 1 ] += vO[ 1 ] ; e[ "end" ][ 2 ] += vO[ 2 ]
         CASE e[ "kind" ] == "CircularArc" .OR. e[ "kind" ] == "EllipticArc"
            e[ "center" ][ 1 ] += vO[ 1 ] ; e[ "center" ][ 2 ] += vO[ 2 ]
         CASE e[ "kind" ] == "Spline"
            FOR EACH v IN e[ "control_points" ] ; v[ 1 ] += vO[ 1 ] ; v[ 2 ] += vO[ 2 ] ; NEXT
            FOR EACH v IN e[ "fit_points" ] ; v[ 1 ] += vO[ 1 ] ; v[ 2 ] += vO[ 2 ] ; NEXT
         CASE e[ "kind" ] == "Polyline"
            FOR EACH v IN e[ "vertices" ] ; v[ 1 ] += vO[ 1 ] ; v[ 2 ] += vO[ 2 ] ; NEXT
         ENDCASE
      NEXT
   NEXT
   FOR EACH v IN h[ "seed_points" ] ; v[ 1 ] += vO[ 1 ] ; v[ 2 ] += vO[ 2 ] ; NEXT
RETURN NIL

// ---- transform_hatch ----
STATIC FUNCTION HPt( p, mOld, mNew, nElev, t )
   LOCAL w := Tf_Apply( t, Mx3_TransformPoint( mOld, Vc3_New( p[ 1 ], p[ 2 ], nElev ) ) ), o := Mx3_TransformPoint( mNew, w )
RETURN Vc2_New( o[ 1 ], o[ 2 ] )
STATIC FUNCTION HDir( d, mOld, mNew, t )
   LOCAL o := Mx3_TransformPoint( mNew, Tf_ApplyRotation( t, Mx3_TransformPoint( mOld, Vc3_New( d[ 1 ], d[ 2 ], 0.0 ) ) ) )
RETURN Vc2_New( o[ 1 ], o[ 2 ] )
STATIC FUNCTION HAng( nA, mOld, mNew, t )
   LOCAL d := HDir( Vc2_New( OCX_COS( nA ), OCX_SIN( nA ) ), mOld, mNew, t ), n := OCX_ATAN2( d[ 2 ], d[ 1 ] )
   IF n < 0.0 ; n += 2.0 * OCX_PI ; ENDIF
RETURN n
STATIC FUNCTION HAngRaw( nA, mOld, mNew, t )
   LOCAL d := HDir( Vc2_New( OCX_COS( nA ), OCX_SIN( nA ) ), mOld, mNew, t )
RETURN OCX_ATAN2( d[ 2 ], d[ 1 ] )
STATIC FUNCTION Norm( a ) ; RETURN OCX_REMEUCLID( a, 2.0 * OCX_PI )
STATIC FUNCTION ToTrue( a, lCcw ) ; RETURN iif( lCcw, a, -a )

FUNCTION Ehh_Transform( h, t )
   LOCAL vOldN := h[ "normal" ], nOldZ := h[ "elevation" ], vNewN, mOld, mNew, vOrgW, vNewOrgW, nNewZ
   LOCAL vOx, vOy, vTx, vTy, nSx, nSy, lUni, vXn, vYn, lFlip, p, e, v, nSweep, nTrueStart, lNewCcw, vC, nNewStart, vMajW, vMaj3, nRatio, vMaj, nLen, nShift
   LOCAL vOldMajW, nOldMajLen, nOldMinLen, vOldMinDir, vOldMinW, vNewMajW, vNewMinW, vNewMaj3, vNewMin3, vNewMaj, vNewMin, nNewMajLen, nNewMinLen, i, l, vPo, vD, vOff, vP2
   LOCAL nEi
   LOCAL nHalfPi := OCX_PI / 2.0
   vNewN := Vc3_Normalize( Tf_ApplyRotation( t, vOldN ) )
   mOld := Mx3_ArbitraryAxis( vOldN ) ; mNew := Mx3_Transpose( Mx3_ArbitraryAxis( vNewN ) )
   vOrgW := Mx3_TransformPoint( mOld, Vc3_New( 0.0, 0.0, nOldZ ) )
   vNewOrgW := Tf_Apply( t, vOrgW )
   nNewZ := Mx3_TransformPoint( mNew, vNewOrgW )[ 3 ]
   vOx := Mx3_TransformPoint( mOld, Vc3_UnitX() ) ; vOy := Mx3_TransformPoint( mOld, Vc3_UnitY() )
   vTx := Tf_ApplyRotation( t, vOx ) ; vTy := Tf_ApplyRotation( t, vOy )
   nSx := Vc3_Length( vTx ) ; nSy := Vc3_Length( vTy )
   lUni := Abs( nSx - nSy ) < 0.0000000001 .AND. Abs( Vc3_Dot( vTx, vTy ) ) < 0.0000000001
   vXn := Mx3_TransformPoint( mNew, vTx ) ; vYn := Mx3_TransformPoint( mNew, vTy )
   lFlip := ( vXn[ 1 ] * vYn[ 2 ] - vXn[ 2 ] * vYn[ 1 ] ) < 0.0
   FOR EACH p IN h[ "paths" ]
      FOR nEi := 1 TO Len( p[ "edges" ] )
         e := p[ "edges" ][ nEi ]
         DO CASE
         CASE e[ "kind" ] == "Line"
            e[ "start" ] := HPt( e[ "start" ], mOld, mNew, nOldZ, t ) ; e[ "end" ] := HPt( e[ "end" ], mOld, mNew, nOldZ, t )
         CASE e[ "kind" ] == "CircularArc"
            nSweep := e[ "end_angle" ] - e[ "start_angle" ]
            nTrueStart := ToTrue( e[ "start_angle" ], e[ "counter_clockwise" ] )
            lNewCcw := iif( lFlip, ! e[ "counter_clockwise" ], e[ "counter_clockwise" ] )
            vC := HPt( e[ "center" ], mOld, mNew, nOldZ, t )
            IF lUni
               nNewStart := Norm( ToTrue( HAng( nTrueStart, mOld, mNew, t ), lNewCcw ) )
               e[ "center" ] := vC ; e[ "radius" ] *= nSx ; e[ "counter_clockwise" ] := lNewCcw
               e[ "start_angle" ] := nNewStart ; e[ "end_angle" ] := nNewStart + nSweep
            ELSE
               vMajW := Vc3_Mul( vTx, e[ "radius" ] ) ; vMaj3 := Mx3_TransformPoint( mNew, vMajW )
               nNewStart := Norm( ToTrue( nTrueStart, lNewCcw ) )
               nRatio := nSy / nSx ; vMaj := Vc2_New( vMaj3[ 1 ], vMaj3[ 2 ] )
               IF nRatio > 1.0
                  nLen := Vc2_Length( vMaj ) * nRatio
                  vMaj := Vc2_Mul( Vc2_Normalize( Vc2_New( -vMaj[ 2 ], vMaj[ 1 ] ) ), nLen )
                  nRatio := 1.0 / nRatio
                  nShift := iif( lNewCcw, -nHalfPi, nHalfPi )
                  nNewStart := Norm( nNewStart + nShift )
               ENDIF
               p[ "edges" ][ nEi ] := Bed_EllipticArc( vC, vMaj, nRatio, nNewStart, nNewStart + nSweep, lNewCcw )
            ENDIF
         CASE e[ "kind" ] == "EllipticArc"
            vC := HPt( e[ "center" ], mOld, mNew, nOldZ, t )
            vOldMajW := Mx3_TransformPoint( mOld, Vc3_New( e[ "major_axis_endpoint" ][ 1 ], e[ "major_axis_endpoint" ][ 2 ], 0.0 ) )
            nOldMajLen := Vc2_Length( e[ "major_axis_endpoint" ] ) ; nOldMinLen := nOldMajLen * e[ "minor_axis_ratio" ]
            vOldMinDir := Vc2_Normalize( Vc2_New( -e[ "major_axis_endpoint" ][ 2 ], e[ "major_axis_endpoint" ][ 1 ] ) )
            vOldMinW := Mx3_TransformPoint( mOld, Vc3_New( vOldMinDir[ 1 ] * nOldMinLen, vOldMinDir[ 2 ] * nOldMinLen, 0.0 ) )
            vNewMajW := Tf_ApplyRotation( t, vOldMajW ) ; vNewMinW := Tf_ApplyRotation( t, vOldMinW )
            vNewMaj3 := Mx3_TransformPoint( mNew, vNewMajW ) ; vNewMin3 := Mx3_TransformPoint( mNew, vNewMinW )
            vNewMaj := Vc2_New( vNewMaj3[ 1 ], vNewMaj3[ 2 ] ) ; vNewMin := Vc2_New( vNewMin3[ 1 ], vNewMin3[ 2 ] )
            nNewMajLen := Vc2_Length( vNewMaj ) ; nNewMinLen := Vc2_Length( vNewMin )
            e[ "center" ] := vC
            nSweep := e[ "end_angle" ] - e[ "start_angle" ]
            IF lFlip
               e[ "counter_clockwise" ] := ! e[ "counter_clockwise" ]
               e[ "start_angle" ] := Norm( -e[ "start_angle" ] )
            ENDIF
            IF nNewMinLen > nNewMajLen + 0.000000000001
               e[ "major_axis_endpoint" ] := vNewMin ; e[ "minor_axis_ratio" ] := nNewMajLen / nNewMinLen
               nShift := iif( e[ "counter_clockwise" ], -nHalfPi, nHalfPi )
               e[ "start_angle" ] := Norm( e[ "start_angle" ] + nShift )
               e[ "end_angle" ] := e[ "start_angle" ] + nSweep
            ELSE
               e[ "major_axis_endpoint" ] := vNewMaj
               e[ "minor_axis_ratio" ] := iif( nNewMajLen > 0.000000000001, nNewMinLen / nNewMajLen, 1.0 )
               e[ "end_angle" ] := e[ "start_angle" ] + nSweep
            ENDIF
         CASE e[ "kind" ] == "Spline"
            FOR EACH v IN e[ "control_points" ]
               vP2 := HPt( v, mOld, mNew, nOldZ, t ) ; v[ 1 ] := vP2[ 1 ] ; v[ 2 ] := vP2[ 2 ]
            NEXT
            FOR i := 1 TO Len( e[ "fit_points" ] ) ; e[ "fit_points" ][ i ] := HPt( e[ "fit_points" ][ i ], mOld, mNew, nOldZ, t ) ; NEXT
            e[ "start_tangent" ] := HDir( e[ "start_tangent" ], mOld, mNew, t ) ; e[ "end_tangent" ] := HDir( e[ "end_tangent" ], mOld, mNew, t )
         CASE e[ "kind" ] == "Polyline"
            FOR EACH v IN e[ "vertices" ]
               vP2 := HPt( v, mOld, mNew, nOldZ, t ) ; v[ 1 ] := vP2[ 1 ] ; v[ 2 ] := vP2[ 2 ]
               IF lFlip ; v[ 3 ] := -v[ 3 ] ; ENDIF
            NEXT
         ENDCASE
      NEXT
   NEXT
   FOR i := 1 TO Len( h[ "seed_points" ] ) ; h[ "seed_points" ][ i ] := HPt( h[ "seed_points" ][ i ], mOld, mNew, nOldZ, t ) ; NEXT
   h[ "pattern_angle" ] := HAngRaw( h[ "pattern_angle" ], mOld, mNew, t )
   h[ "pattern_scale" ] *= nSx
   vPo := HPt( Ehh_PatternOrigin( h ), mOld, mNew, nOldZ, t )
   Ehh_RecordPatternOrigin( h, vPo )
   FOR EACH l IN h[ "pattern" ][ "lines" ]
      l[ "angle" ] := HAngRaw( l[ "angle" ], mOld, mNew, t )
      l[ "base_point" ] := HPt( l[ "base_point" ], mOld, mNew, nOldZ, t )
      vOff := HDir( l[ "offset" ], mOld, mNew, t ) ; l[ "offset" ] := vOff
      vD := l[ "dash_lengths" ]
      FOR i := 1 TO Len( vD ) ; vD[ i ] *= nSx ; NEXT
   NEXT
   IF h[ "gradient_color" ][ "enabled" ]
      h[ "gradient_color" ][ "angle" ] := HAngRaw( h[ "gradient_color" ][ "angle" ], mOld, mNew, t )
   ENDIF
   h[ "normal" ] := vNewN ; h[ "elevation" ] := nNewZ
RETURN NIL
