/* Port 1:1 de #[cfg(test)] de bounds.rs. UTF-8. */
#include "ocx.ch"
STATIC FUNCTION CloseB( a, e, cName )
   LOCAL ax, lOk := ValType( a ) == "A"
   IF lOk
      FOR ax := 1 TO 2
         lOk := lOk .AND. Abs( a[1][ax] - e[1][ax] ) < 0.000000001 .AND. Abs( a[2][ax] - e[2][ax] ) < 0.000000001
      NEXT
   ENDIF
RETURN Chk( lOk, cName )

STATIC FUNCTION PolyB( nBulge )
RETURN Cv_Polyline( PL_New( { PV_Curved( {-1.0,0.0}, nBulge ), PV_Straight( {1.0,0.0} ) }, .F. ) )

PROCEDURE T_Bounds()
   LOCAL nExt := Sqrt( 10.0 ), nS := 0.70710678118654752440
   // partial_conics_include_only_extrema_on_their_spans
   CloseB( AnalyticCurveBounds( { Cv_Arc( {2.0,3.0}, 4.0, 0.0, OCX_FRAC_PI_2 ) } ), { {2.0,3.0}, {6.0,7.0} }, "arc quarter bounds" )
   CloseB( AnalyticCurveBounds( { Cv_Ellipse( { Ell_New( {1.0,-2.0}, 4.0, 2.0, {nS,nS} ), 0.0, OCX_TAU } ) } ), ;
           { {1.0-nExt,-2.0-nExt}, {1.0+nExt,-2.0+nExt} }, "rotated ellipse bounds" )
   // signed_bulges_expand_bounds_on_the_correct_side
   CloseB( AnalyticCurveBounds( { PolyB( 1.0 ) } ),  { {-1.0,-1.0}, {1.0,0.0} }, "positive bulge below" )
   CloseB( AnalyticCurveBounds( { PolyB( -1.0 ) } ), { {-1.0,0.0}, {1.0,1.0} }, "negative bulge above" )
   // collections_combine_and_invalid_or_unbounded_curves_fail
   CloseB( AnalyticCurveBounds( { Cv_Line( {-2.0,1.0}, {3.0,4.0} ), Cv_Circle( {8.0,0.0}, 2.0 ) } ), { {-2.0,-2.0}, {10.0,4.0} }, "collection" )
   Chk( ValType( AnalyticCurveBounds( {} ) ) == "U", "empty -> None" )
   Chk( ValType( AnalyticCurveBounds( { Cv_XLine( {0.0,0.0}, {1.0,0.0} ) } ) ) == "U", "xline -> None" )
   Chk( ValType( AnalyticCurveBounds( { Cv_Circle( {0.0,0.0}, 0.0 ) } ) ) == "U", "zero radius -> None" )
   // [extra]
   Chk( ValType( AnalyticCurveBounds( { Cv_Nurbs( NC_New( 1, { {0.0,0.0}, {1.0,1.0} }, {}, NIL ) ) } ) ) == "U", "[extra] nurbs -> None" )
   CloseB( AnalyticCurveBounds( { Cv_Circle( {1.0,1.0}, 2.0 ) } ), { {-1.0,-1.0}, {3.0,3.0} }, "[extra] circle bounds" )
RETURN
