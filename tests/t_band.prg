/* band.rs no tiene tests en Rust: todos los de este fichero son [extra]. */
#include "ocx.ch"
PROCEDURE T_Band()
   LOCAL pl, r, nArea, e, ring, aPts
   pl := PL_New( { PV_Straight( {0.0,0.0} ), PV_Straight( {10.0,0.0} ) }, .F. )
   r := Bd_PolylineBandBoundary( pl, { {2.0,2.0} }, 0.1 )
   Chk( Len( r[1] ) == 4 .AND. Len( r[2] ) == 1 .AND. Abs( r[3] - 10.0 ) < 0.000000001, "[extra] band: recta de ancho 2 -> 4 aristas, 1 tramo, longitud 10" )
   aPts := {}
   FOR EACH e IN r[1] ; AAdd( aPts, e[1][1] ) ; NEXT
   nArea := Abs( SignedArea( aPts ) )
   Chk( Abs( nArea - 20.0 ) < 0.000001, "[extra] band: area del contorno = 20" )
   Chk( Len( Bd_PolylineBandBoundary( pl, { {0.0,0.0} }, 0.1 )[1] ) == 0, "[extra] band: ancho cero -> vacio" )
   Chk( Len( Bd_PolylineBandBoundary( pl, { {1.0,1.0}, {1.0,1.0} }, 0.1 )[1] ) == 0, "[extra] band: anchos de longitud incorrecta -> vacio" )
   Chk( Len( Bd_PolylineBandBoundary( pl, { {-1.0,1.0} }, 0.1 )[1] ) == 0, "[extra] band: ancho negativo -> vacio" )
   pl := PL_New( { PV_Straight( {0.0,0.0} ), PV_Straight( {10.0,0.0} ), PV_Straight( {10.0,10.0} ) }, .F. )
   r := Bd_PolylineBandBoundary( pl, { {2.0,2.0}, {2.0,2.0} }, 0.1 )
   Chk( Abs( r[3] - 20.0 ) < 0.000000001 .AND. Len( r[2] ) == 2 .AND. Len( r[1] ) >= 6, "[extra] band: codo a 90 grados" )
   ring := {}
   FOR EACH e IN r[1] ; AAdd( ring, e[1][1] ) ; NEXT
   // area de un codo con ingletes: 2*10 + 2*10 - solape 1*... = 2*(10+1)+... se comprueba solo > 0
   Chk( Abs( SignedArea( ring ) ) > 30.0, "[extra] band: codo tiene area razonable" )
   pl := PL_New( { PV_Curved( {0.0,0.0}, 1.0 ), PV_Straight( {2.0,0.0} ) }, .F. )
   r := Bd_PolylineBandBoundary( pl, { {0.5,0.5} }, 0.2 )
   Chk( Len( r[1] ) > 4 .AND. Abs( r[3] - ( OCX_TAU / 2.0 ) ) < 0.000001, "[extra] band: semicirculo -> longitud pi y varias aristas" )
RETURN
