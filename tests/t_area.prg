/* Port de #[cfg(test)] de area.rs. UTF-8. */
#include "ocx.ch"
STATIC FUNCTION Sq( aPts, lClosed, nBulgeIdx, nBulge )
   LOCAL aV := {}, p
   FOR EACH p IN aPts
      AAdd( aV, PV_Straight( p ) )
   NEXT
   IF nBulgeIdx != NIL ; aV[ nBulgeIdx + 1 ][ PV_BULGE ] := nBulge ; ENDIF
RETURN Cv_Polyline( PL_New( aV, lClosed ) )

PROCEDURE T_Area()
   LOCAL aC, nR, nA, nE, ok, aSq := { {0.0,0.0}, {10.0,0.0}, {10.0,10.0}, {0.0,10.0} }
   LOCAL curve, nSampled, three, last, cv, arc, closing, quarter, up, out, nTotal, weight, back, local_, remote, ell, ray
   ok := .T.
   FOR EACH aC IN { {0.0,0.0}, {100.0,-250.0} }
      FOR EACH nR IN { 0.5, 7.0, 1000.0 }
         nA := Cv_EnclosedArea( Cv_Circle( aC, nR ) ) ; nE := OCX_PI * nR * nR
         IF ! ( Abs( nA - nE ) < 0.000000001 * nE ) ; ok := .F. ; ENDIF
      NEXT
   NEXT
   Chk( ok, "circle pi r2" )
   curve := Cv_Circle( {0.0,0.0}, 1.0 ); nSampled := SignedArea( Cv_Tessellate( curve, 20.0 ) )
   Chk( nSampled < OCX_PI - 0.0001 .AND. Abs( Cv_EnclosedArea( curve ) - OCX_PI ) < 0.000000000001, "circle beats polygon" )
   Chk( Abs( Cv_EnclosedArea( Sq( aSq, .T. ) ) - 100.0 ) < 0.000000001, "closed square" )
   three := Sq( aSq, .F. )
   Chk( Abs( Cv_EnclosedArea( three ) - 100.0 ) < 0.000000001, "open polyline closed by chord" )
   last := Cv_Line( {0.0,10.0}, {0.0,0.0} )
   Chk( Abs( Cv_ChainArea( three ) + Cv_ChainArea( last ) - 100.0 ) < 0.000000001, "chain shares add up" )
   cv := Sq( aSq, .T., 2, 1.0 )
   Chk( Abs( Cv_EnclosedArea( cv ) - ( 100.0 + OCX_PI * 25.0 / 2.0 ) ) < 0.000000001, "bulge adds its bite" )
   cv := Sq( { {0.0,0.0}, {0.0,10.0}, {10.0,10.0}, {10.0,0.0} }, .T. )
   Chk( Cv_EnclosedArea( cv ) < 0.0 .AND. Abs( Cv_EnclosedArea( cv ) + 100.0 ) < 0.000000001, "sign of orientation" )
   ell := Cv_Ellipse( { Ell_New( {3.0,-4.0}, 20.0, 5.0, {0.6,0.8} ), 0.0, OCX_TAU } )
   nE := OCX_PI * 20.0 * 5.0
   Chk( Abs( Cv_EnclosedArea( ell ) - nE ) < 0.000001 * nE, "ellipse pi a b" )
   arc := Cv_Arc( {0.0,0.0}, 10.0, 0.0, OCX_PI ); closing := Cv_Line( {-10.0,0.0}, {10.0,0.0} )
   Chk( Abs( Cv_EnclosedArea( arc ) + Cv_EnclosedArea( closing ) - OCX_PI * 100.0 / 2.0 ) < 0.000000001, "half disc" )
   quarter := Cv_Arc( {0.0,0.0}, 4.0, 0.0, OCX_FRAC_PI_2 ); up := Cv_Line( {0.0,4.0}, {0.0,0.0} ); out := Cv_Line( {0.0,0.0}, {4.0,0.0} )
   nTotal := Cv_EnclosedArea( quarter ) + Cv_EnclosedArea( up ) + Cv_EnclosedArea( out )
   Chk( Abs( nTotal - OCX_PI * 16.0 / 4.0 ) < 0.000000001, "pieces add up" )
   ray := Cv_Ray( {1.0,2.0}, {3.0,4.0} )
   Chk( Cv_EnclosedArea( ray ) == 0.0, "unbounded encloses nothing" )
   weight := OCX_COS( OCX_PI / 4.0 )
   quarter := Cv_Nurbs( NC_New( 2, { {100.0,0.0}, {100.0,100.0}, {0.0,100.0} }, { 0.0,0.0,0.0,1.0,1.0,1.0 }, { 1.0, weight, 1.0 } ) )
   back := Cv_Line( {0.0,100.0}, {0.0,0.0} ); out := Cv_Line( {0.0,0.0}, {100.0,0.0} )
   nTotal := Cv_EnclosedArea( quarter ) + Cv_EnclosedArea( back ) + Cv_EnclosedArea( out ); nE := OCX_PI * 10000.0 / 4.0
   Chk( Abs( nTotal - nE ) < 0.0001 * nE, "spline tracing a circle" )
   local_ := Cv_EnclosedArea( Cv_Circle( {0.0,0.0}, 50.0 ) ); remote := Cv_EnclosedArea( Cv_Circle( {512345.678,4512345.678}, 50.0 ) )
   Chk( Abs( local_ - remote ) < 0.000001 * local_, "survey coordinates same area" )
   // [extra] centroides: cuadrado y circulo
   nE := Cv_EnclosedCentroid( Sq( aSq, .T. ) )
   Chk( nE != NIL .AND. Abs( nE[1] - 5.0 ) < 0.000001 .AND. Abs( nE[2] - 5.0 ) < 0.000001, "[extra] centroid of square" )
   nE := Cv_EnclosedCentroid( Cv_Circle( {7.0,-3.0}, 2.0 ) )
   Chk( nE != NIL .AND. Abs( nE[1] - 7.0 ) < 0.000001 .AND. Abs( nE[2] + 3.0 ) < 0.000001, "[extra] centroid of circle" )
   nE := Cv_ChordClosedCentroid( Cv_Arc( {0.0,0.0}, 10.0, 0.0, OCX_PI ) )
   Chk( nE != NIL .AND. Abs( nE[1] ) < 0.000001 .AND. Abs( nE[2] - 4.0 * 10.0 / ( 3.0 * OCX_PI ) ) < 0.0001, "[extra] chord-closed centroid of half disc" )
   Chk( Cv_ChordClosedArea( ray ) == NIL .AND. Abs( Cv_ChordClosedArea( Cv_Arc( {0.0,0.0}, 10.0, 0.0, OCX_PI ) ) - OCX_PI * 50.0 ) < 0.000000001, "[extra] chord closed area" )
RETURN
