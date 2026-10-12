/* Port de #[cfg(test)] de clip.rs (14 tests). UTF-8. */
#include "ocx.ch"
#define TOL 0.000001
STATIC FUNCTION Ln( a, b ) ; RETURN Cv_Line( a, b )
STATIC FUNCTION Square()
RETURN { Ln( {0.0,0.0}, {10.0,0.0} ), Ln( {10.0,0.0}, {10.0,10.0} ), Ln( {10.0,10.0}, {0.0,10.0} ), Ln( {0.0,10.0}, {0.0,0.0} ) }
STATIC FUNCTION SqHole()
   LOCAL a := Square()
   AAdd( a, Ln( {3.0,3.0}, {7.0,3.0} ) ) ; AAdd( a, Ln( {7.0,3.0}, {7.0,7.0} ) )
   AAdd( a, Ln( {7.0,7.0}, {3.0,7.0} ) ) ; AAdd( a, Ln( {3.0,7.0}, {3.0,3.0} ) )
RETURN a
STATIC FUNCTION XL( y ) ; RETURN Cv_XLine( { 0.0, y }, { 1.0, 0.0 } )
STATIC FUNCTION SpEq( a, b )
   LOCAL i
   IF a == NIL .OR. b == NIL ; RETURN a == NIL .AND. b == NIL ; ENDIF
   IF Len( a ) != Len( b ) ; RETURN .F. ; ENDIF
   FOR i := 1 TO Len( a )
      IF a[i][1] != b[i][1] .OR. a[i][2] != b[i][2] ; RETURN .F. ; ENDIF
   NEXT
RETURN .T.

PROCEDURE T_Clip()
   LOCAL pcs, aSp, ok, bnd, pc, mid, circ, arc, sp, sh, org, e, al, across, curve, aS
   pcs := Cp_InsidePieces( Square(), XL( 5.0 ), TOL )
   Chk( Len( pcs ) == 1 .AND. Abs( pcs[1][1][1] ) < TOL .AND. Abs( pcs[1][2][1] - 10.0 ) < TOL, "clip: recta infinita recortada a lo de dentro" )
   pcs := Cp_InsidePieces( SqHole(), XL( 5.0 ), TOL )
   ok := Len( pcs ) == 2
   IF ok
      aSp := {}
      FOR EACH pc IN pcs
         AAdd( aSp, { Min( pc[1][1], pc[2][1] ), Max( pc[1][1], pc[2][1] ) } )
      NEXT
      ASort( aSp,,, {| x, y | x[1] < y[1] } )
      ok := Abs( aSp[1][1] ) < TOL .AND. Abs( aSp[1][2] - 3.0 ) < TOL .AND. Abs( aSp[2][1] - 7.0 ) < TOL .AND. Abs( aSp[2][2] - 10.0 ) < TOL
   ENDIF
   Chk( ok, "clip: un hueco deja un vacio en medio" )
   Chk( Len( Cp_InsidePieces( Square(), XL( 50.0 ), TOL ) ) == 0, "clip: recta que falla no da nada" )
   Chk( SpEq( Cp_InsideSpans( Square(), Ln( {2.0,5.0}, {8.0,5.0} ), TOL ), { { 0.0, 1.0 } } ), "clip: segmento totalmente dentro vuelve entero" )
   Chk( Len( Cp_InsideSpans( Square(), Ln( {20.0,5.0}, {30.0,5.0} ), TOL ) ) == 0, "clip: segmento totalmente fuera no da nada" )
   pcs := Cp_InsidePieces( Square(), Ln( {5.0,5.0}, {25.0,5.0} ), TOL )
   Chk( Len( pcs ) == 1 .AND. Abs( pcs[1][1][1] - 5.0 ) < TOL .AND. Abs( pcs[1][2][1] - 10.0 ) < TOL, "clip: segmento medio dentro se corta en el borde" )
   bnd := { Ln( {0.0,0.0}, {10.0,0.0} ), Ln( {10.0,0.0}, {10.0,10.0} ), Ln( {10.0,10.0}, {6.0,5.0} ), Ln( {6.0,5.0}, {10.0,0.1} ), ;
            Ln( {10.0,0.1}, {10.0,0.0} ), Ln( {0.0,10.0}, {0.0,0.0} ), Ln( {10.0,10.0}, {0.0,10.0} ) }
   ok := .T.
   FOR EACH pc IN Cp_InsidePieces( bnd, XL( 5.0 ), TOL )
      mid := V2_Lerp( pc[1], pc[2], 0.5 )
      ok := ok .AND. Co_Contains( bnd, mid, TOL )
   NEXT
   Chk( ok, "clip: rozar una esquina no invierte lo siguiente" )
   circ := { Cv_Circle( { 0.0, 0.0 }, 10.0 ) }
   pcs := Cp_InsidePieces( circ, XL( 6.0 ), TOL )
   Chk( Len( pcs ) == 1 .AND. Abs( Abs( pcs[1][2][1] - pcs[1][1][1] ) - 16.0 ) < 0.0001, "clip: frontera curva recorta igual" )
   arc := Cv_Arc( { 10.0, 5.0 }, 3.0, 0.0, OCX_TAU )
   aSp := Cp_InsideSpans( Square(), arc, TOL )
   ok := Len( aSp ) > 0
   FOR EACH sp IN aSp
      mid := Cv_PointAt( arc, 0.5 * ( sp[1] + sp[2] ) )
      ok := ok .AND. Co_Contains( Square(), mid, TOL ) .AND. mid[1] <= 10.0 + 0.000001
   NEXT
   Chk( ok, "clip: una curva se recorta igual que una recta" )
   Chk( Len( Cp_InsideSpans( {}, XL( 5.0 ), TOL ) ) == 0, "clip: frontera vacia no encierra nada" )
   curve := Ln( {0.0,0.0}, {10.0,0.0} )
   Chk( SpEq( Cp_BreakSpans( curve, 0.8, 0.2, TOL ), { {0.0,0.2}, {0.8,1.0} } ) .AND. SpEq( Cp_BreakSpans( curve, 0.4, 0.4, TOL ), { {0.0,0.4}, {0.4,1.0} } ) .AND. SpEq( Cp_BreakSpans( curve, 0.0, 0.0, TOL ), { {0.0,1.0} } ), "clip: romper curva abierta conserva ambos exteriores" )
   curve := Cv_Circle( { 0.0, 0.0 }, 2.0 )
   Chk( SpEq( Cp_BreakSpans( curve, 0.25, 0.75, TOL ), { {0.75,1.25} } ) .AND. SpEq( Cp_BreakSpans( curve, 0.75, 0.25, TOL ), { {0.25,0.75} } ) ;
        .AND. Cp_BreakSpans( curve, 0.25, 0.25, TOL ) == NIL .AND. Cp_BreakSpans( curve, OCX_NAN(), 0.5, TOL ) == NIL .AND. Cp_BreakSpans( XL( 0.0 ), 0.25, 0.75, TOL ) == NIL, "clip: romper curva cerrada conserva el complemento dirigido" )
   curve := Cv_Polyline( PL_New( { PV_Straight( {0.0,0.0} ), PV_Straight( {1.0,0.0} ), PV_Straight( {1.0,1.0} ) }, .T. ) )
   Chk( SpEq( Cp_BreakSpans( curve, 0.4, 0.4, TOL ), { {0.0,0.4}, {0.4,1.0} } ), "clip: un punto parte polilinea cerrada en su costura" )
   org := { 512345.678, 4512345.678 }
   sh := {}
   FOR EACH e IN Square()
      al := Cv_AsRay( e )
      AAdd( sh, Ln( { org[1] + al[1][1], org[2] + al[1][2] }, { org[1] + al[1][1] + al[2][1], org[2] + al[1][2] + al[2][2] } ) )
   NEXT
   across := Cv_XLine( { org[1], org[2] + 5.0 }, { 1.0, 0.0 } )
   pcs := Cp_InsidePieces( sh, across, TOL )
   Chk( Len( pcs ) == 1 .AND. Abs( Abs( pcs[1][2][1] - pcs[1][1][1] ) - 10.0 ) < 0.0001, "clip: coordenadas topograficas mismas longitudes" )
   aS := Cp_TrimSpans( Ln( {0.0,0.0}, {10.0,0.0} ), { 0.3, 0.6 }, 0.45, TOL )
   Chk( SpEq( aS, { {0.0,0.3}, {0.6,1.0} } ), "[extra] trim_spans: se quita el tramo elegido" )
RETURN
