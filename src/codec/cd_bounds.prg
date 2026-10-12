/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/cd_bounds.prg
   Origen Rust: opencadcodec/src/types/bounds.rs (313 lineas, 5 tests en t_codec_transform.prg)
   BoundingBox2D = { {minx,miny}, {maxx,maxy} }; BoundingBox3D igual con 3 coordenadas.
   &mut self (expand_to_include) muta en sitio. Display no portado (ver vector.prg).
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Bb2_New( aMin, aMax ) ; RETURN { AClone( aMin ), AClone( aMax ) }
FUNCTION Bb2_FromPoint( p ) ; RETURN { AClone( p ), AClone( p ) }
FUNCTION Bb2_FromPoints( aPts )
   LOCAL b, p, i
   IF Len( aPts ) == 0 ; RETURN NIL ; ENDIF
   b := Bb2_FromPoint( aPts[1] )
   FOR i := 2 TO Len( aPts )
      p := aPts[i]
      b[1][1] := Min( b[1][1], p[1] ) ; b[1][2] := Min( b[1][2], p[2] )
      b[2][1] := Max( b[2][1], p[1] ) ; b[2][2] := Max( b[2][2], p[2] )
   NEXT
RETURN b
FUNCTION Bb2_Width( b ) ; RETURN b[2][1] - b[1][1]
FUNCTION Bb2_Height( b ) ; RETURN b[2][2] - b[1][2]
FUNCTION Bb2_Center( b ) ; RETURN { ( b[1][1] + b[2][1] ) / 2.0, ( b[1][2] + b[2][2] ) / 2.0 }
FUNCTION Bb2_Contains( b, p ) ; RETURN p[1] >= b[1][1] .AND. p[1] <= b[2][1] .AND. p[2] >= b[1][2] .AND. p[2] <= b[2][2]
FUNCTION Bb2_ExpandToInclude( b, p )
   b[1][1] := Min( b[1][1], p[1] ) ; b[1][2] := Min( b[1][2], p[2] )
   b[2][1] := Max( b[2][1], p[1] ) ; b[2][2] := Max( b[2][2], p[2] )
RETURN NIL
FUNCTION Bb2_Merge( a, b )
RETURN { { Min( a[1][1], b[1][1] ), Min( a[1][2], b[1][2] ) }, { Max( a[2][1], b[2][1] ), Max( a[2][2], b[2][2] ) } }

FUNCTION Bb3_Default() ; RETURN { { 0.0, 0.0, 0.0 }, { 0.0, 0.0, 0.0 } }
FUNCTION Bb3_New( aMin, aMax ) ; RETURN { AClone( aMin ), AClone( aMax ) }
FUNCTION Bb3_FromPoint( p ) ; RETURN { AClone( p ), AClone( p ) }
FUNCTION Bb3_FromPoints( aPts )
   LOCAL b, i
   IF Len( aPts ) == 0 ; RETURN NIL ; ENDIF
   b := Bb3_FromPoint( aPts[1] )
   FOR i := 2 TO Len( aPts )
      Bb3_ExpandToInclude( b, aPts[i] )
   NEXT
RETURN b
FUNCTION Bb3_Width( b ) ; RETURN b[2][1] - b[1][1]
FUNCTION Bb3_Height( b ) ; RETURN b[2][2] - b[1][2]
FUNCTION Bb3_Depth( b ) ; RETURN b[2][3] - b[1][3]
FUNCTION Bb3_Center( b ) ; RETURN { ( b[1][1] + b[2][1] ) / 2.0, ( b[1][2] + b[2][2] ) / 2.0, ( b[1][3] + b[2][3] ) / 2.0 }
FUNCTION Bb3_Contains( b, p )
RETURN p[1] >= b[1][1] .AND. p[1] <= b[2][1] .AND. p[2] >= b[1][2] .AND. p[2] <= b[2][2] .AND. p[3] >= b[1][3] .AND. p[3] <= b[2][3]
FUNCTION Bb3_ExpandToInclude( b, p )
   LOCAL i
   FOR i := 1 TO 3
      b[1][i] := Min( b[1][i], p[i] ) ; b[2][i] := Max( b[2][i], p[i] )
   NEXT
RETURN NIL
FUNCTION Bb3_Merge( a, b )
RETURN { { Min( a[1][1], b[1][1] ), Min( a[1][2], b[1][2] ), Min( a[1][3], b[1][3] ) }, ;
         { Max( a[2][1], b[2][1] ), Max( a[2][2], b[2][2] ), Max( a[2][3], b[2][3] ) } }

FUNCTION Bb3_OcsToWcs( b, aNormal )
   LOCAL m, aMin := { OCX_INF(), OCX_INF(), OCX_INF() }, aMax := { -OCX_INF(), -OCX_INF(), -OCX_INF() }, x, y, z, w, i
   IF aNormal[1] == 0.0 .AND. aNormal[2] == 0.0 .AND. aNormal[3] == 1.0 ; RETURN b ; ENDIF
   m := Mx3_ArbitraryAxis( aNormal )
   FOR EACH x IN { b[1][1], b[2][1] }
      FOR EACH y IN { b[1][2], b[2][2] }
         FOR EACH z IN { b[1][3], b[2][3] }
            w := Mx3_TransformPoint( m, { x, y, z } )
            FOR i := 1 TO 3
               aMin[i] := Min( aMin[i], w[i] ) ; aMax[i] := Max( aMax[i], w[i] )
            NEXT
         NEXT
      NEXT
   NEXT
RETURN { aMin, aMax }
