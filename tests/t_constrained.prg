/* Tests PROPIOS [extra] de constrained.prg (equivalente propio de spade; el Rust no tiene #[test] en constrained.rs). */
#include "ocx.ch"
STATIC FUNCTION TriArea( t )
   LOCAL p := t[ 1 ]
RETURN ( ( p[ 2 ][ 1 ] - p[ 1 ][ 1 ] ) * ( p[ 3 ][ 2 ] - p[ 1 ][ 2 ] ) - ( p[ 2 ][ 2 ] - p[ 1 ][ 2 ] ) * ( p[ 3 ][ 1 ] - p[ 1 ][ 1 ] ) ) / 2.0
STATIC FUNCTION SumArea( a )
   LOCAL n := 0.0, t
   FOR EACH t IN a ; n += TriArea( t ) ; NEXT
RETURN n
STATIC FUNCTION AllCcw( a )
   LOCAL t
   FOR EACH t IN a
      IF TriArea( t ) <= 0 ; RETURN .F. ; ENDIF
   NEXT
RETURN .T.
STATIC FUNCTION NoneNegative( a )
   LOCAL t
   FOR EACH t IN a
      IF TriArea( t ) < 0 ; RETURN .F. ; ENDIF
   NEXT
RETURN .T.
STATIC FUNCTION CountCons( a )
   LOCAL n := 0, t, c
   FOR EACH t IN a
      FOR EACH c IN t[ 2 ]
         IF c ; n++ ; ENDIF
      NEXT
   NEXT
RETURN n
STATIC FUNCTION Sq( x0, y0, x1, y1 ) ; RETURN { { x0, y0 }, { x1, y0 }, { x1, y1 }, { x0, y1 } }
STATIC FUNCTION Shoelace( r )
   LOCAL n := 0.0, i, k := Len( r )
   FOR i := 1 TO k
      n += r[ i ][ 1 ] * r[ i % k + 1 ][ 2 ] - r[ i % k + 1 ][ 1 ] * r[ i ][ 2 ]
   NEXT
RETURN Abs( n ) / 2.0
// no hay punto de otro triangulo dentro de la circunferencia de este (Delaunay), salvo bordes restringidos
STATIC FUNCTION DelaunayOk( a )
   LOCAL t, u, p, k, ax, ay, bx, by, cx, cy, dx, dy, nDet
   FOR EACH t IN a
      FOR EACH u IN a
         FOR k := 1 TO 3
            p := u[ 1 ][ k ]
            ax := t[ 1 ][ 1 ][ 1 ] - p[ 1 ] ; ay := t[ 1 ][ 1 ][ 2 ] - p[ 2 ]
            bx := t[ 1 ][ 2 ][ 1 ] - p[ 1 ] ; by := t[ 1 ][ 2 ][ 2 ] - p[ 2 ]
            cx := t[ 1 ][ 3 ][ 1 ] - p[ 1 ] ; cy := t[ 1 ][ 3 ][ 2 ] - p[ 2 ]
            dx := 0 ; dy := dx
            nDet := ( ax*ax + ay*ay ) * ( bx*cy - cx*by ) - ( bx*bx + by*by ) * ( ax*cy - cx*ay ) + ( cx*cx + cy*cy ) * ( ax*by - bx*ay )
            IF nDet > 0.000000001 .AND. dy == 0 ; RETURN .F. ; ENDIF
         NEXT
      NEXT
   NEXT
RETURN .T.

PROCEDURE T_Constrained()
   LOCAL m, a, r, i, ring, star, n, outer, hole, l, ok
   // cuadrado: 2 triangulos, area 1, 4 aristas restringidas (una por borde)
   m := Cdt_New( { Sq( 0.0, 0.0, 1.0, 1.0 ) } ) ; a := Cdt_Triangles( m )
   Chk( m != NIL .AND. Len( a ) == 2 .AND. Abs( SumArea( a ) - 1.0 ) < 0.000000000001 .AND. AllCcw( a ) .AND. CountCons( a ) == 4, "constrained: cuadrado" )
   // anillo con agujero: n+2h-2 = 8 triangulos, area 100-36
   outer := Sq( 0.0, 0.0, 10.0, 10.0 ) ; hole := Sq( 2.0, 2.0, 8.0, 8.0 )
   m := Cdt_New( { outer, hole } ) ; a := Cdt_Triangles( m )
   Chk( Len( a ) == 8 .AND. Abs( SumArea( a ) - 64.0 ) < 0.000000001 .AND. AllCcw( a ) .AND. CountCons( a ) == 8, "constrained: agujero no se rellena" )
   // forma en L (concava): 6 vertices -> 4 triangulos, area 3
   l := { { 0.0, 0.0 }, { 2.0, 0.0 }, { 2.0, 1.0 }, { 1.0, 1.0 }, { 1.0, 2.0 }, { 0.0, 2.0 } }
   m := Cdt_New( { l } ) ; a := Cdt_Triangles( m )
   Chk( Len( a ) == 4 .AND. Abs( SumArea( a ) - 3.0 ) < 0.000000000001 .AND. AllCcw( a ), "constrained: L concava" )
   // estrella concava de 10 puntos: area = shoelace
   star := {}
   FOR i := 0 TO 9
      r := iif( i % 2 == 0, 5.0, 2.0 )
      AAdd( star, { r * OCX_COS( OCX_TAU * i / 10.0 ), r * OCX_SIN( OCX_TAU * i / 10.0 ) } )
   NEXT
   m := Cdt_New( { star } ) ; a := Cdt_Triangles( m )
   Chk( Len( a ) == 8 .AND. Abs( SumArea( a ) - Shoelace( star ) ) < 0.000000001 .AND. AllCcw( a ), "constrained: estrella concava" )
   // insert: punto interior nuevo suma 2 triangulos; duplicado devuelve .F.
   m := Cdt_New( { Sq( 0.0, 0.0, 4.0, 4.0 ) } )
   Chk( Cdt_Insert( m, { 1.0, 1.5 } ) == .T. .AND. Len( Cdt_Triangles( m ) ) == 4 .AND. Cdt_Insert( m, { 1.0, 1.5 } ) == .F. .AND. Len( Cdt_Triangles( m ) ) == 4, "constrained: insert" )
   // insert sobre una arista restringida la divide en dos restricciones
   m := Cdt_New( { Sq( 0.0, 0.0, 4.0, 4.0 ) } )
   ok := Cdt_Insert( m, { 2.0, 0.0 } ) ; a := Cdt_Triangles( m )
   Chk( ok == .T. .AND. CountCons( a ) == 5 .AND. Abs( SumArea( a ) - 16.0 ) < 0.000000001, "constrained: insert sobre arista restringida" )
   // constrain: dos restricciones que se cruzan -> un vertice nuevo en el cruce
   m := Cdt_New( { Sq( 0.0, 0.0, 4.0, 4.0 ) } )
   Chk( Cdt_Constrain( m, { 0.0, 0.0 }, { 4.0, 4.0 } ) == 0, "constrained: constrain diagonal sin vertices nuevos" )
   n := Cdt_Constrain( m, { 4.0, 0.0 }, { 0.0, 4.0 } ) ; a := Cdt_Triangles( m )
   Chk( n == 1 .AND. Len( a ) == 4 .AND. Abs( SumArea( a ) - 16.0 ) < 0.000000001 .AND. CountCons( a ) == 12, "constrained: constrain con cruce (split)" )
   // restriccion interior no cruzada por flips: el segmento aparece como arista
   m := Cdt_New( { Sq( 0.0, 0.0, 10.0, 10.0 ) } )
   Cdt_Insert( m, { 3.0, 5.0 } ) ; Cdt_Insert( m, { 7.0, 5.0 } ) ; Cdt_Insert( m, { 5.0, 1.0 } ) ; Cdt_Insert( m, { 5.0, 9.0 } )
   n := Cdt_Constrain( m, { 3.0, 5.0 }, { 7.0, 5.0 } ) ; a := Cdt_Triangles( m )
   Chk( n == 0 .AND. Abs( SumArea( a ) - 100.0 ) < 0.000000001 .AND. AllCcw( a ), "constrained: restriccion interior" )
   // anillos invalidos
   Chk( Cdt_New( {} ) == NIL .AND. Cdt_New( { { { 0.0, 0.0 }, { 1.0, 0.0 } } } ) == NIL, "constrained: <3 puntos o sin anillos" )
   Chk( Cdt_New( { { { 0.0, 0.0 }, { 1.0, 0.0 }, { 2.0, 0.0 } } } ) == NIL, "constrained: dominio degenerado (escala 0)" )
   Chk( Cdt_New( { { { 0.0, 0.0 }, { 4.0, 4.0 }, { 4.0, 0.0 }, { 0.0, 4.0 } } } ) == NIL, "constrained: anillo que se cruza a si mismo falla" )
   // Delaunay en conjunto sin restricciones internas: poligono convexo + centro
   ring := {}
   FOR i := 0 TO 11
      AAdd( ring, { 5.0 * OCX_COS( OCX_TAU * i / 12.0 ), 5.0 * OCX_SIN( OCX_TAU * i / 12.0 ) } )
   NEXT
   m := Cdt_New( { ring } ) ; Cdt_Insert( m, { 0.3, 0.2 } ) ; Cdt_Insert( m, { -1.5, 2.0 } ) ; Cdt_Insert( m, { 2.2, -2.5 } )
   a := Cdt_Triangles( m )
   Chk( Abs( SumArea( a ) - Shoelace( ring ) ) < 0.000000001 .AND. AllCcw( a ) .AND. DelaunayOk( a ), "constrained: Delaunay (circuncirculo vacio)" )
   // 80 puntos pseudoaleatorios (LCG fijo): area total, CCW, Euler y Delaunay; luego restricciones con cruces
   m := Cdt_New( { Sq( 0.0, 0.0, 100.0, 100.0 ) } ) ; n := 12345
   FOR i := 1 TO 80
      n := ( n * 1103515245 + 12345 ) % 2147483648 ; ok := ( n % 9973 ) / 99.73
      n := ( n * 1103515245 + 12345 ) % 2147483648
      Cdt_Insert( m, { ok, ( n % 9973 ) / 99.73 } )
   NEXT
   a := Cdt_Triangles( m )
   Chk( Abs( SumArea( a ) - 10000.0 ) < 0.0000001 .AND. AllCcw( a ), "constrained: 80 puntos aleatorios area y CCW" )
   Chk( DelaunayOk( a ), "constrained: 80 puntos Delaunay" )
   Cdt_Constrain( m, { 5.0, 5.0 }, { 95.0, 90.0 } ) ; Cdt_Constrain( m, { 5.0, 95.0 }, { 95.0, 10.0 } ) ; Cdt_Constrain( m, { 50.0, 1.0 }, { 51.0, 99.0 } )
   a := Cdt_Triangles( m )
   // los puntos de cruce se redondean como en spade: puede aparecer algun triangulo de area 0 en parametros, nunca negativa
   Chk( Abs( SumArea( a ) - 10000.0 ) < 0.0000001 .AND. NoneNegative( a ) .AND. CountCons( a ) > 0, "constrained: restricciones con cruces sobre malla densa" )
RETURN
