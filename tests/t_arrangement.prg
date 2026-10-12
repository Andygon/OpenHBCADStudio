/* Port de #[cfg(test)] de arrangement.rs (18 tests). UTF-8. */
#include "ocx.ch"
#define TOL 0.000001
STATIC FUNCTION Ln( a, b ) ; RETURN { a, b }
STATIC FUNCTION Rect( w, h ) ; RETURN { Ln( {0.0,0.0}, {w,0.0} ), Ln( {w,0.0}, {w,h} ), Ln( {w,h}, {0.0,h} ), Ln( {0.0,h}, {0.0,0.0} ) }
STATIC FUNCTION Sh( aLs, o )
   LOCAL r := {}, l
   FOR EACH l IN aLs
      AAdd( r, Ln( { o[1] + l[1][1], o[2] + l[1][2] }, { o[1] + l[2][1], o[2] + l[2][2] } ) )
   NEXT
RETURN r

PROCEDURE T_Arrangement()
   LOCAL f, rev, l, segs, areas, ring, org, cr, gap, a, b, ok
   f := Ar_BoundedFaces( Rect( 10.0, 5.0 ), TOL )
   Chk( Len( f ) == 1 .AND. Abs( SignedArea( f[1] ) - 50.0 ) < 0.000000001, "arr: cuatro segmentos encierran una region" )
   rev := {}
   FOR EACH l IN Rect( 4.0, 3.0 ) ; AAdd( rev, Ln( l[2], l[1] ) ) ; NEXT
   rev := { rev[4], rev[3], rev[2], rev[1] }
   f := Ar_BoundedFaces( rev, TOL )
   Chk( Len( f ) == 1 .AND. SignedArea( f[1] ) > 0.0, "arr: anillo sale antihorario" )
   segs := { Ln( {-1.0,0.0}, {11.0,0.0} ), Ln( {-1.0,10.0}, {11.0,10.0} ), Ln( {0.0,-1.0}, {0.0,11.0} ), Ln( {10.0,-1.0}, {10.0,11.0} ) }
   f := Ar_BoundedFaces( segs, TOL )
   Chk( Len( f ) == 1 .AND. Abs( SignedArea( f[1] ) - 100.0 ) < 0.000000001, "arr: segmentos que se cruzan encierran lo que acotan" )
   segs := { Ln( {0.0,0.0}, {10.0,0.0} ), Ln( {10.0,0.0}, {10.0,10.0} ), Ln( {10.0,10.0}, {0.0,10.0} ), Ln( {0.0,10.0}, {0.0,0.0} ), Ln( {5.0,0.0}, {5.0,10.0} ) }
   areas := {}
   FOR EACH ring IN Ar_BoundedFaces( segs, TOL ) ; AAdd( areas, SignedArea( ring ) ) ; NEXT
   ASort( areas )
   Chk( Len( areas ) == 2 .AND. Abs( areas[1] - 50.0 ) < 0.000000001 .AND. Abs( areas[2] - 50.0 ) < 0.000000001, "arr: dos regiones con arista compartida" )
   gap := 0.000000001
   segs := { Ln( {0.0,0.0}, {10.0,0.0} ), Ln( {10.0,gap}, {10.0,10.0} ), Ln( {10.0,10.0}, {0.0,10.0} ), Ln( {0.0,10.0}, {0.0,0.0} ) }
   Chk( Len( Ar_BoundedFaces( segs, TOL ) ) == 1 .AND. Len( Ar_BoundedFaces( segs, 0.000000000001 ) ) == 0, "arr: hueco menor que la tolerancia se suelda" )
   Chk( Len( Ar_BoundedFaces( { Ln( {0.0,0.0}, {10.0,0.0} ), Ln( {10.0,0.0}, {10.0,10.0} ) }, TOL ) ) == 0, "arr: cadena abierta no encierra nada" )
   segs := Rect( 10.0, 10.0 ) ; AAdd( segs, Ln( {5.0,10.0}, {5.0,15.0} ) )
   f := Ar_BoundedFaces( segs, TOL )
   Chk( Len( f ) == 1 .AND. Abs( SignedArea( f[1] ) - 100.0 ) < 0.000000001, "arr: un espolon no es su propia cara" )
   cr := Ar_SegmentCrossing( Ln( {0.0,0.0}, {10.0,0.0} ), Ln( {4.0,0.0}, {14.0,0.0} ), TOL )
   Chk( cr[1] == SX_OVERLAP .AND. Abs( cr[2][1] - 0.4 ) < 0.000000000001 .AND. Abs( cr[2][2] - 1.0 ) < 0.000000000001 .AND. Abs( cr[3][1] ) < 0.000000000001 .AND. Abs( cr[3][2] - 0.6 ) < 0.000000000001, "arr: solape colineal es un tramo" )
   cr := Ar_SegmentCrossing( Ln( {0.0,0.0}, {10.0,0.0} ), Ln( {10.0,0.0}, {20.0,0.0} ), TOL )
   Chk( cr[1] == SX_POINT .AND. Abs( cr[2] - 1.0 ) < 0.000000001, "arr: extremo con extremo es un punto" )
   Chk( Ar_SegmentCrossing( Ln( {0.0,0.0}, {10.0,0.0} ), Ln( {0.0,5.0}, {10.0,5.0} ), TOL )[1] == SX_NONE, "arr: paralelas separadas no se encuentran" )
   cr := Ar_SegmentCrossing( Ln( {0.0,0.0}, {10.0,0.0} ), Ln( {2.0,-1.0}, {2.0,1.0} ), TOL )
   Chk( cr[1] == SX_POINT .AND. Abs( cr[2] - 0.2 ) < 0.000000000001 .AND. Abs( cr[3] - 0.5 ) < 0.000000000001, "arr: cruce en el sitio correcto de ambos" )
   org := { 512345.678, 4512345.678 }
   ring := {}
   FOR EACH l IN { {0.0,0.0}, {10.0,0.0}, {10.0,10.0}, {0.0,10.0}, {0.0,0.0} } ; AAdd( ring, { org[1] + l[1], org[2] + l[2] } ) ; NEXT
   Chk( Abs( SignedArea( ring ) - 100.0 ) < 0.000001, "arr: signed_area estable en coordenadas topograficas" )
   f := Ar_BoundedFaces( Sh( Rect( 10.0, 5.0 ), org ), TOL )
   Chk( Len( f ) == 1 .AND. Abs( SignedArea( f[1] ) - 50.0 ) < 0.000001, "arr: region en coordenadas topograficas" )
   segs := { Ln( {0.0,0.0}, {1000000000000.0,0.0} ), Ln( {0.0,1.0}, {1000000000000.0,1.0} ), Ln( {1.0,-1.0}, {1.0,2.0} ), Ln( {2.0,-1.0}, {2.0,2.0} ) }
   f := Ar_BoundedFaces( segs, TOL )
   Chk( Len( f ) == 1 .AND. Abs( SignedArea( f[1] ) - 1.0 ) < 0.000000001, "arr: corte en segmento larguisimo conserva escala" )
   segs := { Ln( {0.0,0.0}, {7.0,0.0} ), Ln( {3.0,0.0}, {10.0,0.0} ), Ln( {10.0,0.0}, {10.0,10.0} ), Ln( {10.0,10.0}, {0.0,10.0} ), Ln( {0.0,10.0}, {0.0,0.0} ) }
   f := Ar_BoundedFaces( segs, TOL )
   Chk( Len( f ) == 1 .AND. Abs( SignedArea( f[1] ) - 100.0 ) < 0.000001, "arr: dos tramos colineales solapados cierran un anillo" )
   a := Ln( {0.0,0.0}, {1000000000.0,0.001} ) ; b := Ln( {500000000.0,0.0005 + 0.0000005}, {1500000000.0,0.0015 + 0.0000005} )
   Chk( Ar_SegmentCrossing( a, b, TOL )[1] == SX_OVERLAP, "arr: casi colineales lejos se leen como solape" )
   f := Ar_BoundedFaces( Rect( 10.0, 10.0 ), 0.000000000000001 )
   Chk( Len( f ) == 1 .AND. Abs( SignedArea( f[1] ) - 100.0 ) < 0.000000001, "arr: tolerancia mas fina que la geometria" )
   segs := Rect( 10.0, 10.0 ) ; AAdd( segs, Ln( {3.0,3.0}, {3.0,3.0} ) )
   Chk( Len( Ar_BoundedFaces( segs, TOL ) ) == 1, "arr: segmentos colapsados se descartan" )
   // [extra] aristas con etiqueta
   f := Ar_BoundedFaceEdges( { { Ln( {0.0,0.0}, {4.0,0.0} ), 7 }, { Ln( {4.0,0.0}, {4.0,3.0} ), 8 }, { Ln( {4.0,3.0}, {0.0,3.0} ), 9 }, { Ln( {0.0,3.0}, {0.0,0.0} ), 10 } }, TOL )
   ok := Len( f ) == 1 .AND. Len( f[1] ) == 4
   Chk( ok, "[extra] bounded_face_edges: un anillo de 4 aristas" )
RETURN
