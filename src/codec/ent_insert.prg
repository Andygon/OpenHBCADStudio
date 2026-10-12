/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_insert.prg
   Origen Rust: opencadcodec/src/entities/insert.rs (1336, 34 tests)
              + translate_insert y transform_insert (translate.rs, transform.rs). Licencia del original: MPL-2.0.
   Entidad = hash ("_type" "INSERT"; Ent_EntityType devuelve "MINSERT" si is_minsert). Los campos privados de Rust
   (x_scale, y_scale, z_scale, dwg_minsert) son claves del hash; usa Ein_SetXScale etc. para el guardia de cero.
   Las listas de entidades de bloque son arrays de hashes (EntityType). explode_from_document queda PENDIENTE
   (depende de document.rs). Prefijo: Ein_. Builders with_*: Ein_With* mutan y devuelven el mismo hash.
----------------------------------------------------------------------------*/
#include "ocx.ch"

#define SCALE_EPSILON 0.000000000001

FUNCTION Ein_New( cBlockName, vInsertPoint )
RETURN hb_Hash( "_type", "INSERT", "common", Ec_New(), "block_name", cBlockName, "insert_point", vInsertPoint, "x_scale", 1.0, "y_scale", 1.0, "z_scale", 1.0, ;
                "rotation", 0.0, "normal", Vc3_UnitZ(), "column_count", 1, "row_count", 1, "column_spacing", 0.0, "row_spacing", 0.0, "dwg_minsert", .F., ;
                "attributes", {}, "view_rep_handle", NIL, "seqend_handle", NIL )

STATIC FUNCTION ClampScale( n ) ; RETURN iif( Abs( n ) < SCALE_EPSILON, SCALE_EPSILON, n )
FUNCTION Ein_XScale( e ) ; RETURN e[ "x_scale" ]
FUNCTION Ein_YScale( e ) ; RETURN e[ "y_scale" ]
FUNCTION Ein_ZScale( e ) ; RETURN e[ "z_scale" ]
FUNCTION Ein_SetXScale( e, n ) ; e[ "x_scale" ] := ClampScale( n ) ; RETURN NIL
FUNCTION Ein_SetYScale( e, n ) ; e[ "y_scale" ] := ClampScale( n ) ; RETURN NIL
FUNCTION Ein_SetZScale( e, n ) ; e[ "z_scale" ] := ClampScale( n ) ; RETURN NIL
FUNCTION Ein_WithScale( e, x, y, z ) ; Ein_SetXScale( e, x ) ; Ein_SetYScale( e, y ) ; Ein_SetZScale( e, z ) ; RETURN e
FUNCTION Ein_WithUniformScale( e, n ) ; RETURN Ein_WithScale( e, n, n, n )
FUNCTION Ein_WithRotation( e, nAngle ) ; e[ "rotation" ] := nAngle ; RETURN e
FUNCTION Ein_WithNormal( e, v ) ; e[ "normal" ] := v ; RETURN e
FUNCTION Ein_WithArray( e, nCols, nRows, nColSp, nRowSp )
   e[ "column_count" ] := nCols ; e[ "row_count" ] := nRows ; e[ "column_spacing" ] := nColSp ; e[ "row_spacing" ] := nRowSp ; e[ "dwg_minsert" ] := .T.
RETURN e
FUNCTION Ein_MarkAsMinsert( e ) ; e[ "dwg_minsert" ] := .T. ; RETURN NIL
FUNCTION Ein_HasAttributes( e ) ; RETURN Len( e[ "attributes" ] ) > 0
FUNCTION Ein_IsArray( e ) ; RETURN e[ "column_count" ] > 1 .OR. e[ "row_count" ] > 1
FUNCTION Ein_IsMinsert( e ) ; RETURN e[ "dwg_minsert" ] .OR. Ein_IsArray( e )
FUNCTION Ein_EntityType( e ) ; RETURN iif( Ein_IsMinsert( e ), "MINSERT", "INSERT" )
FUNCTION Ein_InstanceCount( e ) ; RETURN e[ "column_count" ] * e[ "row_count" ]
FUNCTION Ein_ArrayCapacityHint( e ) ; RETURN Min( Ein_InstanceCount( e ), 4096 )
FUNCTION Ein_ArrayPoints( e )
   LOCAL aPts := {}, nRow, nCol, nOx, nOy, nCos := OCX_COS( e[ "rotation" ] ), nSin := OCX_SIN( e[ "rotation" ] )
   FOR nRow := 0 TO e[ "row_count" ] - 1
      FOR nCol := 0 TO e[ "column_count" ] - 1
         nOx := nCol * e[ "column_spacing" ] ; nOy := nRow * e[ "row_spacing" ]
         AAdd( aPts, Vc3_Add( e[ "insert_point" ], Vc3_New( nOx * nCos - nOy * nSin, nOx * nSin + nOy * nCos, 0.0 ) ) )
      NEXT
   NEXT
RETURN aPts
FUNCTION Ein_HasUniformScale( e ) ; RETURN Abs( e[ "x_scale" ] - e[ "y_scale" ] ) < 0.0000000001 .AND. Abs( e[ "y_scale" ] - e[ "z_scale" ] ) < 0.0000000001
/* Option<f64> */
FUNCTION Ein_UniformScale( e ) ; RETURN iif( Ein_HasUniformScale( e ), e[ "x_scale" ], NIL )
FUNCTION Ein_SubclassMarker( e ) ; RETURN iif( Ein_IsMinsert( e ), "AcDbMInsertBlock", "AcDbBlockReference" )

STATIC FUNCTION Upper3( t )
   LOCAL m := t[ 1 ]
RETURN { { m[1][1], m[1][2], m[1][3] }, { m[2][1], m[2][2], m[2][3] }, { m[3][1], m[3][2], m[3][3] } }

FUNCTION Ein_GetTransform( e )
   LOCAL mOcs := Mx4_FromMatrix3( Mx3_ArbitraryAxis( e[ "normal" ] ) ), p := e[ "insert_point" ]
RETURN Tf_FromMatrix( Mx4_Mul( Mx4_Mul( Mx4_Mul( mOcs, Mx4_Translation( p[1], p[2], p[3] ) ), Mx4_RotationZ( e[ "rotation" ] ) ), Mx4_Scaling( e[ "x_scale" ], e[ "y_scale" ], e[ "z_scale" ] ) ) )

/* insert.rs: Insert::transform_normal (== transform_normal de transform.rs) */
FUNCTION Ein_TransformNormal( t, vNormal )
   LOCAL mInv := Mx3_Inverse( Upper3( t ) ), vTr, nLen
   IF mInv == NIL ; RETURN vNormal ; ENDIF
   vTr := Mx3_TransformPoint( Mx3_Transpose( mInv ), vNormal )
   nLen := Vc3_Length( vTr )
   IF nLen < 0.0000000001 ; RETURN vNormal ; ENDIF
RETURN Vc3_Mul( vTr, 1.0 / nLen )

/* common = EntityCommon de la entidad explotada (se modifica en sitio) */
STATIC FUNCTION ResolveProperties( e, common )
   IF common[ "layer" ] == "0" ; common[ "layer" ] := e[ "common" ][ "layer" ] ; ENDIF
   IF Cl_Eq( common[ "color" ], Cl_ByBlock() ) ; common[ "color" ] := Ent_Clone( e[ "common" ][ "color" ] ) ; ENDIF
   IF Lw_Eq( common[ "line_weight" ], Lw_ByBlock() ) ; common[ "line_weight" ] := Ent_Clone( e[ "common" ][ "line_weight" ] ) ; ENDIF
RETURN NIL

STATIC FUNCTION ArrayTransforms( e )
   LOCAL aT := {}, mOcs, mRot, mSc, nRow, nCol, p := e[ "insert_point" ]
   IF ! Ein_IsMinsert( e ) ; RETURN { Ein_GetTransform( e ) } ; ENDIF
   mOcs := Mx4_FromMatrix3( Mx3_ArbitraryAxis( e[ "normal" ] ) )
   mRot := Mx4_RotationZ( e[ "rotation" ] )
   mSc := Mx4_Scaling( e[ "x_scale" ], e[ "y_scale" ], e[ "z_scale" ] )
   FOR nRow := 0 TO e[ "row_count" ] - 1
      FOR nCol := 0 TO e[ "column_count" ] - 1
         AAdd( aT, Tf_FromMatrix( Mx4_Mul( Mx4_Mul( Mx4_Mul( mOcs, Mx4_Translation( p[1] + nCol * e[ "column_spacing" ], p[2] + nRow * e[ "row_spacing" ], p[3] ) ), mRot ), mSc ) ) )
      NEXT
   NEXT
RETURN aT

/* Devuelve un array de entidades (hashes) */
FUNCTION Ein_Explode( e, aBlockEntities )
   LOCAL aResult := {}, t, ent, x
   FOR EACH t IN ArrayTransforms( e )
      FOR EACH ent IN aBlockEntities
         x := ExplodeSingle( e, ent, t )
         IF x != NIL ; AAdd( aResult, x ) ; ENDIF
      NEXT
   NEXT
RETURN aResult

STATIC FUNCTION ExplodeSingle( e, ent, t )
   LOCAL cT := ent[ "_type" ], mOcs, el, nSx, nSy, cl
   DO CASE
   CASE cT == "BLOCK" .OR. cT == "ENDBLK" .OR. cT == "ATTDEF" ; RETURN NIL
   CASE cT == "ARC"
      nSx := Abs( e[ "x_scale" ] ) ; nSy := Abs( e[ "y_scale" ] )
      IF Abs( nSx - nSy ) < 0.0000000001
         RETURN ExplodeArcUniform( e, ent, t )
      ENDIF
      RETURN ExplodeArcToEllipse( e, ent, t )
   CASE cT == "CIRCLE"
      mOcs := Mx3_ArbitraryAxis( ent[ "normal" ] )
      el := Eel_New()
      el[ "common" ] := Ent_Clone( ent[ "common" ] )
      el[ "center" ] := Mx3_TransformPoint( mOcs, ent[ "center" ] )
      el[ "major_axis" ] := Mx3_TransformPoint( mOcs, Vc3_Mul( Vc3_UnitX(), ent[ "radius" ] ) )
      el[ "minor_axis_ratio" ] := 1.0 ; el[ "start_parameter" ] := 0.0 ; el[ "end_parameter" ] := OCX_TAU ; el[ "normal" ] := ent[ "normal" ]
      Eel_Transform( el, t )
      ResolveProperties( e, el[ "common" ] )
      RETURN el
   ENDCASE
   cl := Ent_Clone( ent )
   Ent_ApplyTransform( cl, t )
   ResolveProperties( e, cl[ "common" ] )
RETURN cl

STATIC FUNCTION ExplodeArcUniform( e, arc, t )
   LOCAL mOcs := Mx3_ArbitraryAxis( arc[ "normal" ] ), vCw, vWs, vWe, vNc, vNs, vNe, nNewR, vNn, mNew, mTo, vC, vDs, vDe, na, nb, a, nRad := arc[ "radius" ]
   vCw := Mx3_TransformPoint( mOcs, arc[ "center" ] )
   vWs := Vc3_Add( vCw, Mx3_TransformPoint( mOcs, Vc3_New( nRad * OCX_COS( arc[ "start_angle" ] ), nRad * OCX_SIN( arc[ "start_angle" ] ), 0.0 ) ) )
   vWe := Vc3_Add( vCw, Mx3_TransformPoint( mOcs, Vc3_New( nRad * OCX_COS( arc[ "end_angle" ] ), nRad * OCX_SIN( arc[ "end_angle" ] ), 0.0 ) ) )
   vNc := Tf_Apply( t, vCw ) ; vNs := Tf_Apply( t, vWs ) ; vNe := Tf_Apply( t, vWe )
   nNewR := Vc3_Length( Vc3_Sub( vNs, vNc ) )
   vNn := Ein_TransformNormal( t, arc[ "normal" ] )
   IF Mx3_Determinant( Upper3( t ) ) < 0.0 ; vNn := Vc3_Mul( vNn, -1.0 ) ; ENDIF
   mNew := Mx3_ArbitraryAxis( vNn ) ; mTo := Mx3_Transpose( mNew )
   vC := Mx3_TransformPoint( mTo, vNc )
   vDs := Mx3_TransformPoint( mTo, Vc3_Sub( vNs, vNc ) ) ; vDe := Mx3_TransformPoint( mTo, Vc3_Sub( vNe, vNc ) )
   na := OCX_ATAN2( vDs[ 2 ], vDs[ 1 ] ) ; nb := OCX_ATAN2( vDe[ 2 ], vDe[ 1 ] )
   a := Ear_FromCenterRadiusAngles( vC, nNewR, na, nb )
   a[ "normal" ] := vNn
   a[ "common" ] := Ent_Clone( arc[ "common" ] )
   ResolveProperties( e, a[ "common" ] )
RETURN a

STATIC FUNCTION ExplodeArcToEllipse( e, arc, t )
   LOCAL mOcs := Mx3_ArbitraryAxis( arc[ "normal" ] ), el := Eel_New()
   el[ "common" ] := Ent_Clone( arc[ "common" ] )
   el[ "center" ] := Mx3_TransformPoint( mOcs, arc[ "center" ] )
   el[ "major_axis" ] := Mx3_TransformPoint( mOcs, Vc3_Mul( Vc3_UnitX(), arc[ "radius" ] ) )
   el[ "minor_axis_ratio" ] := 1.0 ; el[ "start_parameter" ] := arc[ "start_angle" ] ; el[ "end_parameter" ] := arc[ "end_angle" ] ; el[ "normal" ] := arc[ "normal" ]
   Eel_Transform( el, t )
   ResolveProperties( e, el[ "common" ] )
RETURN el

FUNCTION Ein_BoundingBox( e ) ; RETURN Bb3_FromPoint( e[ "insert_point" ] )

FUNCTION Ein_Translate( e, vOffset )
   LOCAL mOcs := Mx3_ArbitraryAxis( e[ "normal" ] ), vWorld, att
   vWorld := Vc3_Add( Mx3_TransformPoint( mOcs, e[ "insert_point" ] ), vOffset )
   e[ "insert_point" ] := Mx3_TransformPoint( Mx3_Transpose( mOcs ), vWorld )
   FOR EACH att IN e[ "attributes" ]
      Eat_Translate( att, vOffset )
   NEXT
RETURN NIL

FUNCTION Ein_Transform( e, t )
   LOCAL vNn := Tf_TransformNormal( t, e[ "normal" ] ), mOld := Mx3_ArbitraryAxis( e[ "normal" ] ), vNew, mNew, vPos
   LOCAL mOw, mWoBase, mWo, mTr, v, nRot, mWoRot, s, att
   vNew := Tf_Apply( t, Mx3_TransformPoint( mOld, e[ "insert_point" ] ) )
   mNew := Mx3_ArbitraryAxis( vNn )
   vPos := Mx3_TransformPoint( Mx3_Transpose( mNew ), vNew )
   mOw := Mx3_Mul( Mx3_ArbitraryAxis( e[ "normal" ] ), Mx3_RotationZ( e[ "rotation" ] ) )
   mWoBase := Mx3_ArbitraryAxis( vNn ) ; mWo := Mx3_Transpose( mWoBase )
   mTr := Upper3( t )
   v := Mx3_TransformPoint( mWo, Mx3_TransformPoint( mTr, Mx3_TransformPoint( mOw, Vc3_UnitX() ) ) )
   nRot := OCX_ATAN2( v[ 2 ], v[ 1 ] )
   mWoRot := Mx3_Mul( Mx3_Transpose( Mx3_RotationZ( nRot ) ), mWo )
   s := Mx3_TransformPoint( mWoRot, Mx3_TransformPoint( mTr, Mx3_TransformPoint( mOw, Vc3_New( e[ "x_scale" ], e[ "y_scale" ], e[ "z_scale" ] ) ) ) )
   e[ "normal" ] := vNn
   e[ "insert_point" ] := vPos
   Ein_SetXScale( e, s[ 1 ] ) ; Ein_SetYScale( e, s[ 2 ] ) ; Ein_SetZScale( e, s[ 3 ] )
   e[ "rotation" ] := nRot
   FOR EACH att IN e[ "attributes" ]
      Eat_Transform( att, t )
   NEXT
RETURN NIL
