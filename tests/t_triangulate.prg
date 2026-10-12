/* Port de #[cfg(test)] de triangulate.rs (14 tests). UTF-8. */
#include "ocx.ch"
STATIC FUNCTION Ar( aPts, aTris )
   LOCAL t, nSum := 0.0
   FOR EACH t IN aTris
      nSum += Abs( V2_Cross( V2_Sub( aPts[ t[2]+1 ], aPts[ t[1]+1 ] ), V2_Sub( aPts[ t[3]+1 ], aPts[ t[1]+1 ] ) ) ) * 0.5
   NEXT
RETURN nSum
STATIC FUNCTION Sq( s ) ; RETURN { {0.0,0.0}, {s,0.0}, {s,s}, {0.0,s} }
STATIC FUNCTION TriEq( a, b )
   LOCAL i
   IF Len( a ) != Len( b ) ; RETURN .F. ; ENDIF
   FOR i := 1 TO Len( a )
      IF a[i][1] != b[i][1] .OR. a[i][2] != b[i][2] .OR. a[i][3] != b[i][3] ; RETURN .F. ; ENDIF
   NEXT
RETURN .T.
STATIC FUNCTION Circle( aC, nR, n )
   LOCAL a := {}, i, ang
   FOR i := 0 TO n - 1
      ang := OCX_TAU * i / n
      AAdd( a, { aC[1] + nR * OCX_COS( ang ), aC[2] + nR * OCX_SIN( ang ) } )
   NEXT
RETURN a

PROCEDURE T_Triangulate()
   LOCAL r, c, pts, corners, side, i, a, b, back, closed, shape, hole, holes, outer, nExp, h, ok, tri, cen, org, shifted, p, ring, bow
   r := Tg_Polygon( Sq( 10.0 ), {} )
   Chk( Len( r[2] ) == 2 .AND. Abs( Ar( r[1], r[2] ) - 100.0 ) < 0.000000001, "tri: cuadrado = 2 triangulos" )
   pts := Sq( 10.0 )
   Chk( TriEq( Tg_ClipEars( pts, { 0, 1, 2, 3 } ), { {3,0,1}, {1,2,3} } ), "tri: empates mantienen la primera oreja valida (cuadrado)" )
   corners := Sq( 10.0 ) ; pts := {}
   FOR side := 0 TO 3
      a := corners[ side + 1 ] ; b := corners[ ( side + 1 ) % 4 + 1 ]
      FOR i := 0 TO 4
         AAdd( pts, { a[1] + ( b[1] - a[1] ) * i / 5.0, a[2] + ( b[2] - a[2] ) * i / 5.0 } )
      NEXT
   NEXT
   ring := {}
   FOR i := 0 TO 19 ; AAdd( ring, i ) ; NEXT
   Chk( TriEq( Tg_ClipEars( pts, ring ), { {19,0,1}, {4,5,6}, {9,10,11}, {14,15,16}, {19,1,2}, {3,4,6}, {8,9,11}, {13,14,16}, ;
        {3,6,7}, {8,11,12}, {13,16,17}, {18,19,2}, {18,2,3}, {3,7,8}, {8,12,13}, {13,17,18}, {18,3,8}, {8,13,18} } ), "tri: salida completa de 20 puntos identica a Rust" )
   back := Sq( 10.0 ) ; back := { back[4], back[3], back[2], back[1] }
   r := Tg_Polygon( back, {} )
   Chk( Abs( Ar( r[1], r[2] ) - 100.0 ) < 0.000000001, "tri: el sentido no importa" )
   closed := Sq( 10.0 ) ; AAdd( closed, closed[1] )
   r := Tg_Polygon( closed, {} )
   Chk( Len( r[2] ) == 2 .AND. Abs( Ar( r[1], r[2] ) - 100.0 ) < 0.000000001, "tri: anillo cerrado repitiendo el primero" )
   shape := { {0.0,0.0}, {10.0,0.0}, {10.0,4.0}, {4.0,4.0}, {4.0,10.0}, {0.0,10.0} }
   r := Tg_Polygon( shape, {} )
   Chk( Len( r[2] ) == 4 .AND. Abs( Ar( r[1], r[2] ) - 64.0 ) < 0.000000001, "tri: poligono concavo (L)" )
   hole := { {3.0,3.0}, {7.0,3.0}, {7.0,7.0}, {3.0,7.0} }
   r := Tg_Polygon( Sq( 10.0 ), { hole } )
   Chk( Len( r[2] ) > 0 .AND. Abs( Ar( r[1], r[2] ) - 84.0 ) < 0.000000001, "tri: un hueco queda vacio" )
   holes := { { {1.0,1.0}, {3.0,1.0}, {3.0,3.0}, {1.0,3.0} }, { {6.0,6.0}, {9.0,6.0}, {9.0,9.0}, {6.0,9.0} } }
   r := Tg_Polygon( Sq( 10.0 ), holes )
   Chk( Abs( Ar( r[1], r[2] ) - ( 100.0 - 4.0 - 9.0 ) ) < 0.000000001, "tri: dos huecos vacios" )
   outer := { {0.0,0.0}, {12.0,0.0}, {12.0,8.0}, {11.0,8.0}, {11.0,2.0}, {2.0,2.0}, {1.8,2.1}, {1.8,12.0}, {0.0,12.0} }
   holes := { Circle( { 1.68, 6.0 }, 0.08, 24 ), Circle( { 1.68, 9.0 }, 0.08, 24 ) }
   nExp := Abs( Tg_SignedAreaPub( outer ) )
   FOR EACH h IN holes ; nExp -= Abs( Tg_SignedAreaPub( h ) ) ; NEXT
   r := Tg_Polygon( outer, holes )
   Chk( Len( r[2] ) > 0 .AND. Abs( Ar( r[1], r[2] ) - nExp ) < 0.000000001, "tri: dos huecos alineados en brazo concavo estrecho" )
   r := Tg_Polygon( shape, {} ) ; ok := .T.
   FOR EACH tri IN r[2]
      cen := V2_Div( V2_Add( V2_Add( r[1][ tri[1]+1 ], r[1][ tri[2]+1 ] ), r[1][ tri[3]+1 ] ), 3.0 )
      ok := ok .AND. ( ( cen[1] <= 10.0 .AND. cen[2] <= 4.0 ) .OR. ( cen[1] <= 4.0 .AND. cen[2] <= 10.0 ) ) .AND. cen[1] >= 0.0 .AND. cen[2] >= 0.0
   NEXT
   Chk( ok, "tri: cada triangulo queda dentro del poligono" )
   bow := { {0.0,0.0}, {10.0,10.0}, {10.0,0.0}, {0.0,10.0} }
   r := Tg_Polygon( bow, {} ) ; ok := .T.
   FOR EACH tri IN r[2]
      ok := ok .AND. Abs( V2_Cross( V2_Sub( r[1][ tri[2]+1 ], r[1][ tri[1]+1 ] ), V2_Sub( r[1][ tri[3]+1 ], r[1][ tri[1]+1 ] ) ) ) > 0.0
   NEXT
   Chk( ok, "tri: anillo autocruzado termina sin triangulos colapsados" )
   Chk( Len( Tg_Polygon( {}, {} )[2] ) == 0 .AND. Len( Tg_Polygon( { {0.0,0.0}, {1.0,0.0} }, {} )[2] ) == 0, "tri: pocos puntos no es poligono" )
   org := { 512345.678, 4512345.678 } ; shifted := {}
   FOR EACH p IN Sq( 10.0 )
      AAdd( shifted, { org[1] + p[1], org[2] + p[2] } )
   NEXT
   r := Tg_Polygon( shifted, {} )
   Chk( Abs( Ar( r[1], r[2] ) - 100.0 ) < 0.000001, "tri: poligono en coordenadas topograficas" )
   r := Tg_Polygon( Circle( { 0.0, 0.0 }, 10.0, 64 ), {} )
   Chk( Len( r[2] ) == 62 .AND. Abs( Ar( r[1], r[2] ) - 0.5 * 64.0 * 100.0 * OCX_SIN( OCX_TAU / 64.0 ) ) < 0.000001, "tri: anillo de 64 lados n-2 triangulos" )
   // [extra]: wrappers publicos
   r := Tg_Rings( { Sq( 10.0 ), { {3.0,3.0}, {7.0,3.0}, {7.0,7.0}, {3.0,7.0} } } )
   Chk( Len( r[2] ) > 0 .AND. Abs( Ar( r[1], r[2] ) - 84.0 ) < 0.000000001, "[extra] rings: cuadrado con hueco por par-impar" )
   Chk( Tg_NestingDepths( { Sq( 10.0 ), { {3.0,3.0}, {7.0,3.0}, {7.0,7.0}, {3.0,7.0} } } )[2] == 1, "[extra] nesting_depths" )
   c := Tg_PolygonFrame( Sq( 10.0 ), 0.000001 )
   Chk( c != NIL .AND. c[1][1] == 0.0 .AND. c[2][1] == 10.0 .AND. Len( c[3] ) == 4 .AND. Tg_PolygonFrame( bow, 0.000001 ) == NIL, "[extra] polygon_frame" )
RETURN
