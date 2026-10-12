/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_tolerance.prg
   Origen Rust: opencadcodec/src/entities/tolerance.rs (579, 16 tests) + translate_tolerance + transform_tolerance. Licencia del original: MPL-2.0.
   Los numeros se formatean como el "{}" de Rust (F64_Display). Option<&str> = cadena o NIL. Prefijo: Etl_. gdt_symbols = constantes GDT_*.
   Constantes de la entidad: Etl_ENTITY_NAME() "TOLERANCE", SUBCLASS_MARKER "AcDbFcf", OBJECT_TYPE 46.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Etl_EntityName() ; RETURN "TOLERANCE"
FUNCTION Etl_SubclassMarker() ; RETURN "AcDbFcf"
FUNCTION Etl_ObjectType() ; RETURN 46

FUNCTION Etl_New()
RETURN hb_Hash( "_type", "TOLERANCE", "common", Ec_New(), "insertion_point", Vc3_Zero(), "direction", Vc3_UnitX(), "normal", Vc3_UnitZ(), "text", "", ;
   "dimension_style_name", "Standard", "dimension_style_handle", NIL, "text_height", 0.18, "dimension_gap", 0.09, "dwg_unknown_short", 0 )
FUNCTION Etl_WithText( vIns, cText ) ; LOCAL e := Etl_New() ; e[ "insertion_point" ] := vIns ; e[ "text" ] := cText ; RETURN e
FUNCTION Etl_NewFull( vIns, cText, vDir, cStyle )
   LOCAL e := Etl_New()
   e[ "insertion_point" ] := vIns ; e[ "text" ] := cText ; e[ "direction" ] := Vc3_Normalize( vDir ) ; e[ "dimension_style_name" ] := cStyle
RETURN e
FUNCTION Etl_PointToward( e, vTarget )
   LOCAL vD := Vc3_Sub( vTarget, e[ "insertion_point" ] )
   IF Vc3_Length( vD ) > 0.0000000001 ; e[ "direction" ] := Vc3_Normalize( vD ) ; ENDIF
RETURN NIL
FUNCTION Etl_Rotate( e, nAngle )
   LOCAL nC := OCX_COS( nAngle ), nS := OCX_SIN( nAngle ), n := Vc3_Normalize( e[ "normal" ] ), d := e[ "direction" ], nDot, vCr
   nDot := n[ 1 ] * d[ 1 ] + n[ 2 ] * d[ 2 ] + n[ 3 ] * d[ 3 ]
   vCr := Vc3_New( n[ 2 ] * d[ 3 ] - n[ 3 ] * d[ 2 ], n[ 3 ] * d[ 1 ] - n[ 1 ] * d[ 3 ], n[ 1 ] * d[ 2 ] - n[ 2 ] * d[ 1 ] )
   e[ "direction" ] := Vc3_New( d[ 1 ] * nC + vCr[ 1 ] * nS + n[ 1 ] * nDot * ( 1.0 - nC ), d[ 2 ] * nC + vCr[ 2 ] * nS + n[ 2 ] * nDot * ( 1.0 - nC ), d[ 3 ] * nC + vCr[ 3 ] * nS + n[ 3 ] * nDot * ( 1.0 - nC ) )
RETURN NIL
FUNCTION Etl_RotationAngle( e )
   LOCAL n := Vc3_Normalize( e[ "normal" ] ), d := Vc3_Normalize( e[ "direction" ] ), nDot, vP, vX, vY, nPx, nPy
   nDot := n[ 1 ] * d[ 1 ] + n[ 2 ] * d[ 2 ] + n[ 3 ] * d[ 3 ]
   vP := Vc3_New( d[ 1 ] - n[ 1 ] * nDot, d[ 2 ] - n[ 2 ] * nDot, d[ 3 ] - n[ 3 ] * nDot )
   IF Vc3_Length( vP ) < 0.0000000001 ; RETURN 0.0 ; ENDIF
   vX := iif( Abs( Abs( n[ 3 ] ) - 1.0 ) < 0.0000000001, Vc3_UnitX(), Vc3_Normalize( Vc3_New( -n[ 2 ], n[ 1 ], 0.0 ) ) )
   vY := Vc3_New( n[ 2 ] * vX[ 3 ] - n[ 3 ] * vX[ 2 ], n[ 3 ] * vX[ 1 ] - n[ 1 ] * vX[ 3 ], n[ 1 ] * vX[ 2 ] - n[ 2 ] * vX[ 1 ] )
   nPx := vP[ 1 ] * vX[ 1 ] + vP[ 2 ] * vX[ 2 ] + vP[ 3 ] * vX[ 3 ]
   nPy := vP[ 1 ] * vY[ 1 ] + vP[ 2 ] * vY[ 2 ] + vP[ 3 ] * vY[ 3 ]
RETURN OCX_ATAN2( nPy, nPx )
/* str::split("^J") */
FUNCTION Etl_TextLines( e )
   LOCAL aL := {}, c := e[ "text" ], n
   DO WHILE ( n := At( "^J", c ) ) > 0
      AAdd( aL, Left( c, n - 1 ) ) ; c := SubStr( c, n + 2 )
   ENDDO
   AAdd( aL, c )
RETURN aL
FUNCTION Etl_LineCount( e ) ; RETURN Len( Etl_TextLines( e ) )

STATIC FUNCTION S( n ) ; RETURN F64_Display( n )
STATIC FUNCTION O( c ) ; RETURN iif( c == NIL, "", c )
FUNCTION Etl_PositionTolerance( nTol, cA, cB, cC ) ; RETURN "{\Fgdt;p}%%v" + S( nTol ) + "%%v" + O( cA ) + "%%v" + O( cB ) + "%%v" + O( cC ) + "%%v"
FUNCTION Etl_FlatnessTolerance( nTol ) ; RETURN "{\Fgdt;c}%%v" + S( nTol ) + "%%v%%v%%v%%v"
FUNCTION Etl_PerpendicularityTolerance( nTol, cD ) ; RETURN "{\Fgdt;j}%%v" + S( nTol ) + "%%v" + cD + "%%v%%v%%v"
FUNCTION Etl_ParallelismTolerance( nTol, cD ) ; RETURN "{\Fgdt;h}%%v" + S( nTol ) + "%%v" + cD + "%%v%%v%%v"
FUNCTION Etl_ConcentricityTolerance( nTol, cD ) ; RETURN "{\Fgdt;u}%%v" + S( nTol ) + "%%v" + cD + "%%v%%v%%v"
FUNCTION Etl_SymmetryTolerance( nTol, cD ) ; RETURN "{\Fgdt;i}%%v" + S( nTol ) + "%%v" + cD + "%%v%%v%%v"
FUNCTION Etl_RunoutTolerance( nTol, cD, lTotal ) ; RETURN "{\Fgdt;" + iif( lTotal, "t", "r" ) + "}%%v" + S( nTol ) + "%%v" + cD + "%%v%%v%%v"
FUNCTION Etl_CylindricityTolerance( nTol ) ; RETURN "{\Fgdt;e}%%v" + S( nTol ) + "%%v%%v%%v%%v"
FUNCTION Etl_StraightnessTolerance( nTol ) ; RETURN "{\Fgdt;a}%%v" + S( nTol ) + "%%v%%v%%v%%v"
FUNCTION Etl_CircularityTolerance( nTol ) ; RETURN "{\Fgdt;g}%%v" + S( nTol ) + "%%v%%v%%v%%v"
FUNCTION Etl_LineProfileTolerance( nTol, cD ) ; RETURN "{\Fgdt;k}%%v" + S( nTol ) + "%%v" + O( cD ) + "%%v%%v%%v"
FUNCTION Etl_SurfaceProfileTolerance( nTol, cD ) ; RETURN "{\Fgdt;d}%%v" + S( nTol ) + "%%v" + O( cD ) + "%%v%%v%%v"
FUNCTION Etl_MultiLine( aLines )
   LOCAL c := "", i
   FOR i := 1 TO Len( aLines ) ; c += iif( i > 1, "^J", "" ) + aLines[ i ] ; NEXT
RETURN c

FUNCTION Etl_BoundingBox( e )
   LOCAL nHw := Len( e[ "text" ] ) * e[ "text_height" ] * 0.6, nHh := e[ "text_height" ] * Etl_LineCount( e ), p := e[ "insertion_point" ]
RETURN Bb3_New( Vc3_New( p[ 1 ] - nHw * 0.1, p[ 2 ] - nHh * 0.5, p[ 3 ] ), Vc3_New( p[ 1 ] + nHw, p[ 2 ] + nHh * 0.5, p[ 3 ] ) )
FUNCTION Etl_Translate( e, vOff ) ; e[ "insertion_point" ] := Vc3_Add( e[ "insertion_point" ], vOff ) ; RETURN NIL
FUNCTION Etl_Transform( e, t )
   LOCAL nScale
   e[ "insertion_point" ] := Tf_Apply( t, e[ "insertion_point" ] )
   e[ "direction" ] := Vc3_Normalize( Tf_ApplyRotation( t, e[ "direction" ] ) )
   e[ "normal" ] := Vc3_Normalize( Tf_ApplyRotation( t, e[ "normal" ] ) )
   nScale := Vc3_Length( Tf_ApplyRotation( t, Vc3_New( 1.0, 0.0, 0.0 ) ) )
   e[ "text_height" ] *= nScale ; e[ "dimension_gap" ] *= nScale
RETURN NIL
