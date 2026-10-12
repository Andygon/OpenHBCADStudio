/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/cd_transform.prg
   Origen Rust: opencadcodec/src/types/transform.rs (737 lineas, 16 tests en t_codec_transform.prg)
   Matrix3 = array 3x3 (m[i][j] base 1 en Harbour, la API Rust es base 0 y aqui se aplica +1 al acceder);
   Matrix4 = 4x4; Transform = { Matrix4 }. Vector3 = {x,y,z}. Operador * -> Mx3_Mul / Mx4_Mul / Tf_Compose.
   Prefijos: Mx3_, Mx4_, Tf_, Cd_ (rotate_point_2d, is_zero_angle, normalize_angle).
----------------------------------------------------------------------------*/
#include "ocx.ch"

// ---- Matrix3 ----
FUNCTION Mx3_Identity() ; RETURN { {1.0,0.0,0.0}, {0.0,1.0,0.0}, {0.0,0.0,1.0} }
FUNCTION Mx3_Zero() ; RETURN { {0.0,0.0,0.0}, {0.0,0.0,0.0}, {0.0,0.0,0.0} }
FUNCTION Mx3_FromRows( r0, r1, r2 ) ; RETURN { AClone( r0 ), AClone( r1 ), AClone( r2 ) }
FUNCTION Mx3_RotationZ( a )
   LOCAL c := OCX_COS( a ), s := OCX_SIN( a )
RETURN { {c,-s,0.0}, {s,c,0.0}, {0.0,0.0,1.0} }
FUNCTION Mx3_Scaling( sx, sy, sz ) ; RETURN { {sx,0.0,0.0}, {0.0,sy,0.0}, {0.0,0.0,sz} }

FUNCTION Mx3_ArbitraryAxis( aNormal )
   LOCAL n := Vc3_Normalize( aNormal ), ax, xd, yd
   IF Abs( n[1] ) < 1.0 / 64.0 .AND. Abs( n[2] ) < 1.0 / 64.0
      ax := { 0.0, 1.0, 0.0 }
   ELSE
      ax := { 0.0, 0.0, 1.0 }
   ENDIF
   xd := Vc3_Normalize( Vc3_Cross( ax, n ) )
   yd := Vc3_Normalize( Vc3_Cross( n, xd ) )
RETURN { { xd[1], yd[1], n[1] }, { xd[2], yd[2], n[2] }, { xd[3], yd[3], n[3] } }

FUNCTION Mx3_Transpose( m ) ; RETURN { {m[1][1],m[2][1],m[3][1]}, {m[1][2],m[2][2],m[3][2]}, {m[1][3],m[2][3],m[3][3]} }

FUNCTION Mx3_Determinant( m )
RETURN m[1][1] * ( m[2][2] * m[3][3] - m[2][3] * m[3][2] ) ;
     - m[1][2] * ( m[2][1] * m[3][3] - m[2][3] * m[3][1] ) ;
     + m[1][3] * ( m[2][1] * m[3][2] - m[2][2] * m[3][1] )

FUNCTION Mx3_Inverse( m )
   LOCAL det := Mx3_Determinant( m ), inv
   IF Abs( det ) < 0.0000000001 ; RETURN NIL ; ENDIF
   inv := 1.0 / det
RETURN { ;
  { ( m[2][2]*m[3][3] - m[2][3]*m[3][2] ) * inv, ( m[1][3]*m[3][2] - m[1][2]*m[3][3] ) * inv, ( m[1][2]*m[2][3] - m[1][3]*m[2][2] ) * inv }, ;
  { ( m[2][3]*m[3][1] - m[2][1]*m[3][3] ) * inv, ( m[1][1]*m[3][3] - m[1][3]*m[3][1] ) * inv, ( m[1][3]*m[2][1] - m[1][1]*m[2][3] ) * inv }, ;
  { ( m[2][1]*m[3][2] - m[2][2]*m[3][1] ) * inv, ( m[1][2]*m[3][1] - m[1][1]*m[3][2] ) * inv, ( m[1][1]*m[2][2] - m[1][2]*m[2][1] ) * inv } }

FUNCTION Mx3_TransformPoint( m, v )
RETURN { m[1][1]*v[1] + m[1][2]*v[2] + m[1][3]*v[3], m[2][1]*v[1] + m[2][2]*v[2] + m[2][3]*v[3], m[3][1]*v[1] + m[3][2]*v[2] + m[3][3]*v[3] }

FUNCTION Mx3_Mul( a, b )
   LOCAL r := Mx3_Zero(), i, j, k
   FOR i := 1 TO 3
      FOR j := 1 TO 3
         FOR k := 1 TO 3 ; r[i][j] += a[i][k] * b[k][j] ; NEXT
      NEXT
   NEXT
RETURN r

// ---- Matrix4 ----
FUNCTION Mx4_Identity() ; RETURN { {1.0,0.0,0.0,0.0}, {0.0,1.0,0.0,0.0}, {0.0,0.0,1.0,0.0}, {0.0,0.0,0.0,1.0} }
FUNCTION Mx4_Zero() ; RETURN { {0.0,0.0,0.0,0.0}, {0.0,0.0,0.0,0.0}, {0.0,0.0,0.0,0.0}, {0.0,0.0,0.0,0.0} }
FUNCTION Mx4_Translation( tx, ty, tz ) ; RETURN { {1.0,0.0,0.0,tx}, {0.0,1.0,0.0,ty}, {0.0,0.0,1.0,tz}, {0.0,0.0,0.0,1.0} }
FUNCTION Mx4_Scaling( sx, sy, sz ) ; RETURN { {sx,0.0,0.0,0.0}, {0.0,sy,0.0,0.0}, {0.0,0.0,sz,0.0}, {0.0,0.0,0.0,1.0} }
FUNCTION Mx4_ScalingWithOrigin( sx, sy, sz, o )
RETURN Mx4_Mul( Mx4_Mul( Mx4_Translation( o[1], o[2], o[3] ), Mx4_Scaling( sx, sy, sz ) ), Mx4_Translation( -o[1], -o[2], -o[3] ) )
FUNCTION Mx4_RotationX( a )
   LOCAL c := OCX_COS( a ), s := OCX_SIN( a )
RETURN { {1.0,0.0,0.0,0.0}, {0.0,c,-s,0.0}, {0.0,s,c,0.0}, {0.0,0.0,0.0,1.0} }
FUNCTION Mx4_RotationY( a )
   LOCAL c := OCX_COS( a ), s := OCX_SIN( a )
RETURN { {c,0.0,s,0.0}, {0.0,1.0,0.0,0.0}, {-s,0.0,c,0.0}, {0.0,0.0,0.0,1.0} }
FUNCTION Mx4_RotationZ( a )
   LOCAL c := OCX_COS( a ), s := OCX_SIN( a )
RETURN { {c,-s,0.0,0.0}, {s,c,0.0,0.0}, {0.0,0.0,1.0,0.0}, {0.0,0.0,0.0,1.0} }

FUNCTION Mx4_Rotation( aAxis, a )
   LOCAL ax := Vc3_Normalize( aAxis ), c := OCX_COS( a ), s := OCX_SIN( a ), omc := 1.0 - c, x := ax[1], y := ax[2], z := ax[3]
RETURN { ;
  { c + x*x*omc, x*y*omc - z*s, x*z*omc + y*s, 0.0 }, ;
  { y*x*omc + z*s, c + y*y*omc, y*z*omc - x*s, 0.0 }, ;
  { z*x*omc - y*s, z*y*omc + x*s, c + z*z*omc, 0.0 }, ;
  { 0.0, 0.0, 0.0, 1.0 } }

FUNCTION Mx4_FromMatrix3( m3 )
RETURN { {m3[1][1],m3[1][2],m3[1][3],0.0}, {m3[2][1],m3[2][2],m3[2][3],0.0}, {m3[3][1],m3[3][2],m3[3][3],0.0}, {0.0,0.0,0.0,1.0} }
FUNCTION Mx4_ToMatrix3( m )
RETURN { {m[1][1],m[1][2],m[1][3]}, {m[2][1],m[2][2],m[2][3]}, {m[3][1],m[3][2],m[3][3]} }
FUNCTION Mx4_Transpose( m )
   LOCAL r := Mx4_Zero(), i, j
   FOR i := 1 TO 4
      FOR j := 1 TO 4 ; r[i][j] := m[j][i] ; NEXT
   NEXT
RETURN r

FUNCTION Mx4_TransformPoint( m, v )
   LOCAL w := m[4][1]*v[1] + m[4][2]*v[2] + m[4][3]*v[3] + m[4][4]
   IF Abs( w ) < 0.0000000001 ; w := 1.0 ; ENDIF
RETURN { ( m[1][1]*v[1] + m[1][2]*v[2] + m[1][3]*v[3] + m[1][4] ) / w, ;
         ( m[2][1]*v[1] + m[2][2]*v[2] + m[2][3]*v[3] + m[2][4] ) / w, ;
         ( m[3][1]*v[1] + m[3][2]*v[2] + m[3][3]*v[3] + m[3][4] ) / w }

FUNCTION Mx4_TransformDirection( m, v )
RETURN { m[1][1]*v[1] + m[1][2]*v[2] + m[1][3]*v[3], m[2][1]*v[1] + m[2][2]*v[2] + m[2][3]*v[3], m[3][1]*v[1] + m[3][2]*v[2] + m[3][3]*v[3] }

FUNCTION Mx4_Mul( a, b )
   LOCAL r := Mx4_Zero(), i, j, k
   FOR i := 1 TO 4
      FOR j := 1 TO 4
         FOR k := 1 TO 4 ; r[i][j] += a[i][k] * b[k][j] ; NEXT
      NEXT
   NEXT
RETURN r

FUNCTION Mx4_Eq( a, b )
   LOCAL i, j
   FOR i := 1 TO 4
      FOR j := 1 TO 4
         IF a[i][j] != b[i][j] ; RETURN .F. ; ENDIF
      NEXT
   NEXT
RETURN .T.

// ---- Transform = { Matrix4 } ----
FUNCTION Tf_Identity() ; RETURN { Mx4_Identity() }
FUNCTION Tf_FromMatrix( m ) ; RETURN { m }
FUNCTION Tf_FromRotation( aAxis, a ) ; RETURN { Mx4_Rotation( aAxis, a ) }
FUNCTION Tf_FromTranslation( t ) ; RETURN { Mx4_Translation( t[1], t[2], t[3] ) }
FUNCTION Tf_FromScale( s ) ; RETURN { Mx4_Scaling( s, s, s ) }
FUNCTION Tf_FromScaling( s ) ; RETURN { Mx4_Scaling( s[1], s[2], s[3] ) }
FUNCTION Tf_FromScalingWithOrigin( s, o ) ; RETURN { Mx4_ScalingWithOrigin( s[1], s[2], s[3], o ) }
FUNCTION Tf_Apply( t, p ) ; RETURN Mx4_TransformPoint( t[1], p )
FUNCTION Tf_ApplyRotation( t, d ) ; RETURN Mx4_TransformDirection( t[1], d )
FUNCTION Tf_Then( t, o ) ; RETURN { Mx4_Mul( o[1], t[1] ) }
FUNCTION Tf_Compose( t, o ) ; RETURN { Mx4_Mul( t[1], o[1] ) }
FUNCTION Tf_FromMirrorX() ; RETURN { Mx4_Scaling( -1.0, 1.0, 1.0 ) }
FUNCTION Tf_FromMirrorY() ; RETURN { Mx4_Scaling( 1.0, -1.0, 1.0 ) }
FUNCTION Tf_FromMirrorZ() ; RETURN { Mx4_Scaling( 1.0, 1.0, -1.0 ) }

FUNCTION Tf_FromMirrorPlane( p, normal )
   LOCAL n := Vc3_Normalize( normal ), d := -( n[1]*p[1] + n[2]*p[2] + n[3]*p[3] )
RETURN { { ;
  { 1.0 - 2.0*n[1]*n[1], -2.0*n[1]*n[2], -2.0*n[1]*n[3], -2.0*n[1]*d }, ;
  { -2.0*n[2]*n[1], 1.0 - 2.0*n[2]*n[2], -2.0*n[2]*n[3], -2.0*n[2]*d }, ;
  { -2.0*n[3]*n[1], -2.0*n[3]*n[2], 1.0 - 2.0*n[3]*n[3], -2.0*n[3]*d }, ;
  { 0.0, 0.0, 0.0, 1.0 } } }

FUNCTION Tf_FromMirrorLine( p1, p2 )
   LOCAL dir := Vc3_Normalize( Vc3_Sub( p2, p1 ) )
RETURN Tf_FromMirrorPlane( p1, { -dir[2], dir[1], 0.0 } )

FUNCTION Tf_IsIdentity( t ) ; RETURN Mx4_Eq( t[1], Mx4_Identity() )

// ---- funciones sueltas ----
FUNCTION Cd_RotatePoint2d( p, c, a )
   LOCAL cs := OCX_COS( a ), sn := OCX_SIN( a ), dx := p[1] - c[1], dy := p[2] - c[2]
RETURN { c[1] + dx * cs - dy * sn, c[2] + dx * sn + dy * cs }

FUNCTION Cd_IsZeroAngle( a ) ; RETURN Abs( a ) < 0.0000000001

FUNCTION Cd_NormalizeAngle( a )
   LOCAL nTwoPi := 2.0 * ( OCX_TAU / 2.0 ), r := OCX_FMOD( a, nTwoPi )
   IF r < 0.0 ; r += nTwoPi ; ENDIF
RETURN r
