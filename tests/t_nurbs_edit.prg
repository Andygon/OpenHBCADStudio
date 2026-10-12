/* Port de #[cfg(test)] de nurbs.rs: insert_knot / reversed / elevated / split_at. UTF-8. */
#include "ocx.ch"
STATIC FUNCTION CL( a, b, e ) ; RETURN Abs( a[1]-b[1] ) < e .AND. Abs( a[2]-b[2] ) < e
STATIC FUNCTION LinearR() ; RETURN NC_New( 1, { {0.0,0.0}, {10.0,0.0}, {10.0,10.0} }, {}, NIL )
STATIC FUNCTION RQuarter()
RETURN NC_New( 2, { {100.0,0.0}, {100.0,100.0}, {0.0,100.0} }, { 0.0,0.0,0.0,1.0,1.0,1.0 }, { 1.0, OCX_COS( OCX_PI / 4.0 ), 1.0 } )
STATIC FUNCTION Uneven()
RETURN NC_New( 3, { {0.0,0.0}, {1.0,6.0}, {4.0,6.0}, {6.0,0.0}, {9.0,4.0}, {12.0,0.0} }, { 0.0,0.0,0.0,0.0,0.2,0.9,1.0,1.0,1.0,1.0 }, NIL )
STATIC FUNCTION Five() ; RETURN NC_New( 3, { {0.0,0.0}, {1.0,5.0}, {4.0,5.0}, {5.0,0.0}, {8.0,-3.0} }, {}, NIL )

PROCEDURE T_NurbsEdit()
   LOCAL c, back, i, t, ok, aCurves, raised, naive, nWorst, d, ins, before, l, r, f, half, p, rad, aSp
   ok := .T.
   FOR EACH c IN { LinearR(), Uneven(), RQuarter() }
      back := NC_Reversed( c )
      FOR i := 0 TO 20
         t := i / 20.0
         ok := ok .AND. CL( NC_PointAt( c, t ), NC_PointAt( back, 1.0 - t ), 0.000000001 )
      NEXT
   NEXT
   Chk( ok, "reversing traces the same curve backwards" )
   c := Uneven()
   aCurves := {}
   FOR i := Len( c[NC_CTRL] ) TO 1 STEP -1 ; AAdd( aCurves, c[NC_CTRL][i] ) ; NEXT
   naive := NC_New( c[NC_DEGREE], aCurves, Spl_ClampedUniformKnots( c[NC_DEGREE], Len( c[NC_CTRL] ) ), NIL )
   nWorst := 0.0
   FOR i := 0 TO 20
      t := i / 20.0
      nWorst := Max( nWorst, V2_Distance( NC_PointAt( c, t ), NC_PointAt( naive, 1.0 - t ) ) )
   NEXT
   Chk( nWorst > 0.1, "regenerating the knots would move the curve" )
   back := NC_Reversed( NC_Reversed( c ) ); ok := .T.
   FOR i := 0 TO 10
      t := i / 10.0
      ok := ok .AND. CL( NC_PointAt( c, t ), NC_PointAt( back, t ), 0.000000000001 )
   NEXT
   Chk( ok, "reversing twice is the original" )
   ok := .T.
   FOR EACH c IN { LinearR(), Uneven(), RQuarter() }
      raised := NC_Elevated( c, 1 )
      ok := ok .AND. raised != NIL .AND. raised[NC_DEGREE] == c[NC_DEGREE] + 1
      IF raised != NIL
         FOR i := 0 TO 20
            t := i / 20.0
            ok := ok .AND. CL( NC_PointAt( c, t ), NC_PointAt( raised, t ), 0.000000001 )
         NEXT
      ENDIF
   NEXT
   Chk( ok, "elevating does not move the curve" )
   raised := NC_Elevated( RQuarter(), 1 ); ok := NC_IsRational( raised )
   FOR i := 0 TO 10
      p := NC_PointAt( raised, i / 10.0 )
      ok := ok .AND. Abs( V2_Length( p ) - 100.0 ) < 0.000000001
   NEXT
   Chk( ok, "elevating a rational curve keeps it rational" )
   c := Uneven(); raised := NC_Elevated( c, 3 ); ok := raised != NIL .AND. raised[NC_DEGREE] == c[NC_DEGREE] + 3
   FOR i := 0 TO 10
      t := i / 10.0
      ok := ok .AND. CL( NC_PointAt( c, t ), NC_PointAt( raised, t ), 0.00000001 )
   NEXT
   Chk( ok, "elevating by more than one step compounds" )
   Chk( NC_Elevated( Uneven(), 0 ) == NIL, "elevating by nothing" )
   c := Five(); before := {}
   FOR i := 0 TO 40 ; AAdd( before, NC_PointAt( c, i / 40.0 ) ) ; NEXT
   ins := { c[NC_DEGREE], AClone( c[NC_KNOTS] ), AClone( c[NC_CTRL] ), AClone( c[NC_WEIGHTS] ) }
   NC_InsertKnot( ins, 0.37 ); ok := Len( ins[NC_CTRL] ) == Len( c[NC_CTRL] ) + 1
   FOR i := 0 TO 40
      ok := ok .AND. CL( NC_PointAt( ins, i / 40.0 ), before[ i + 1 ], 0.000000001 )
   NEXT
   Chk( ok, "inserting a knot leaves the shape alone" )
   c := Five(); aSp := NC_SplitAt( c, 0.4 ); l := aSp[1]; r := aSp[2]
   ok := CL( NC_PointAt( l, 0.0 ), NC_PointAt( c, 0.0 ), 0.000000001 ) .AND. CL( NC_PointAt( l, 1.0 ), NC_PointAt( c, 0.4 ), 0.000000001 ) ;
      .AND. CL( NC_PointAt( r, 0.0 ), NC_PointAt( c, 0.4 ), 0.000000001 ) .AND. CL( NC_PointAt( r, 1.0 ), NC_PointAt( c, 1.0 ), 0.000000001 )
   FOR i := 0 TO 20
      f := i / 20.0
      ok := ok .AND. CL( NC_PointAt( l, f ), NC_PointAt( c, f * 0.4 ), 0.000000001 ) .AND. CL( NC_PointAt( r, f ), NC_PointAt( c, 0.4 + f * 0.6 ), 0.000000001 )
   NEXT
   Chk( ok, "both halves of a split lie on the original" )
   c := NC_New( 2, { {1.0,0.0}, {1.0,1.0}, {0.0,1.0} }, { 0.0,0.0,0.0,1.0,1.0,1.0 }, { 1.0, Sqrt( 0.5 ), 1.0 } )
   aSp := NC_SplitAt( c, 0.5 ); ok := aSp != NIL
   FOR EACH half IN aSp
      FOR i := 0 TO 10
         p := NC_PointAt( half, i / 10.0 ); rad := Sqrt( p[1]*p[1] + p[2]*p[2] )
         ok := ok .AND. Abs( rad - 1.0 ) < 0.000000001
      NEXT
   NEXT
   Chk( ok, "splitting a rational curve keeps it rational" )
   c := LinearR()
   Chk( NC_SplitAt( c, 0.0 ) == NIL .AND. NC_SplitAt( c, 1.0 ) == NIL, "splitting at an end" )
   // [extra] trimmed: el tramo [0.2,0.7] coincide con la curva original
   c := Five(); d := NC_Trimmed( c, 0.2, 0.7 ); ok := d != NIL
   FOR i := 0 TO 10
      f := i / 10.0
      ok := ok .AND. d != NIL .AND. CL( NC_PointAt( d, f ), NC_PointAt( c, 0.2 + f * 0.5 ), 0.000000001 )
   NEXT
   Chk( ok, "[extra] trimmed lies on the original" )
   d := NC_Trimmed( c, 0.7, 0.2 )
   Chk( d != NIL .AND. CL( NC_PointAt( d, 0.0 ), NC_PointAt( c, 0.7 ), 0.000000001 ) .AND. CL( NC_PointAt( d, 1.0 ), NC_PointAt( c, 0.2 ), 0.000000001 ), "[extra] trimmed reversed" )
RETURN
