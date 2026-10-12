/* Port de #[cfg(test)] de boundary_recovery.rs (2 tests). UTF-8. */
#include "ocx.ch"
STATIC FUNCTION Line4( a, b )
RETURN { a, { a[1] + ( b[1] - a[1] ) / 3.0, a[2] + ( b[2] - a[2] ) / 3.0 }, { a[1] + 2.0 * ( b[1] - a[1] ) / 3.0, a[2] + 2.0 * ( b[2] - a[2] ) / 3.0 }, b }

STATIC FUNCTION Narrow( nClear )
   LOCAL a := { -1.0, -1.0 }, b := { 0.0, -1.0 }, c := { 0.0, 1.0 }, d := { nClear, 0.999 }, e := { -0.5, 1.5 }, f := { -1.0, 1.5 }
   LOCAL aSpans := { Line4( a, b ), Line4( b, c ), Line4( c, d ), { d, { nClear, 1.1 }, { -0.3, 1.5 }, e }, Line4( e, f ), Line4( f, a ) }
   LOCAL aCtl := { a }, aKn := { 0.0, 0.0, 0.0, 0.0 }, sp, i
   FOR EACH sp IN aSpans
      AAdd( aCtl, sp[2] ) ; AAdd( aCtl, sp[3] ) ; AAdd( aCtl, sp[4] )
   NEXT
   FOR i := 1 TO 5
      AAdd( aKn, i * 1.0 ) ; AAdd( aKn, i * 1.0 ) ; AAdd( aKn, i * 1.0 )
   NEXT
   AAdd( aKn, 6.0 ) ; AAdd( aKn, 6.0 ) ; AAdd( aKn, 6.0 ) ; AAdd( aKn, 6.0 )
RETURN NC_New( 3, aCtl, aKn, NIL )

PROCEDURE T_BoundaryRecovery()
   LOCAL spl, cv, orig, ref, ok, i, pt, j, wasCalled := .F., bIdent := {| p | p }, big, found
   spl := Narrow( 0.00001 )
   cv := Cv_Nurbs( spl )
   orig := Cv_TessellateAngle( cv, Tess_DefaultAngle() )
   Chk( Len( Tg_Rings( { orig } )[2] ) == 0, "recovery: el muestreo original no se triangula" )
   ref := BR_RefineSplineBoundary( orig, {|| { cv } }, bIdent )
   Chk( ref != NIL .AND. Len( Tg_Rings( { ref } )[2] ) > 0, "recovery: los cruces se refinan en el kernel" )
   ok := ref != NIL
   IF ok
      FOR i := 0 TO 6
         pt := NC_PointAt( spl, i / 6.0 ) ; found := .F.
         FOR j := 1 TO Len( ref )
            IF ref[j][1] == pt[1] .AND. ref[j][2] == pt[2] ; found := .T. ; EXIT ; ENDIF
         NEXT
         ok := ok .AND. found
      NEXT
   ENDIF
   Chk( ok, "recovery: el anillo refinado contiene los nudos exactos" )
   cv := Cv_Nurbs( Narrow( 0.01 ) )
   Chk( BR_RefineSplineBoundary( Cv_TessellateAngle( cv, Tess_DefaultAngle() ), {|| wasCalled := .T., {} }, bIdent ) == NIL .AND. ! wasCalled, "recovery: valido no se cambia ni se remuestrea" )
   big := Array( 513 ) ; AFill( big, { 0.0, 0.0 } )
   Chk( BR_RefineSplineBoundary( big, {|| wasCalled := .T., {} }, bIdent ) == NIL .AND. ! wasCalled, "recovery: tope de tamano respetado" )
RETURN
