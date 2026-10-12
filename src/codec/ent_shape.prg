/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_shape.prg
   Origen Rust: opencadcodec/src/entities/shape.rs (582, 22 tests) + translate_shape + transform_shape + mirror_shape. Licencia del original: MPL-2.0.
   Prefijo Esh_. Option<Handle> = NIL. transform_matrix devuelve array de 12 (base 1 en Harbour: [10]=tx). standard_shapes = SHP_*, gdt_shapes = GDS_* en ocx.ch.
   Constantes: ENTITY_NAME "SHAPE", SUBCLASS_MARKER "AcDbShape", OBJECT_TYPE 0x21.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Esh_EntityName() ; RETURN "SHAPE"
FUNCTION Esh_SubclassMarker() ; RETURN "AcDbShape"
FUNCTION Esh_ObjectType() ; RETURN 33

FUNCTION Esh_New()
RETURN hb_Hash( "_type", "SHAPE", "common", Ec_New(), "insertion_point", Vc3_Zero(), "size", 1.0, "shape_name", "", "shape_number", 0, "rotation", 0.0, ;
   "relative_x_scale", 1.0, "oblique_angle", 0.0, "normal", Vc3_UnitZ(), "thickness", 0.0, "style_name", "", "style_handle", NIL )
FUNCTION Esh_WithName( vIns, cName, nSize ) ; LOCAL e := Esh_New() ; e[ "insertion_point" ] := vIns ; e[ "shape_name" ] := cName ; e[ "size" ] := nSize ; RETURN e
FUNCTION Esh_WithNumber( vIns, nNum, nSize ) ; LOCAL e := Esh_New() ; e[ "insertion_point" ] := vIns ; e[ "shape_number" ] := nNum ; e[ "size" ] := nSize ; RETURN e
FUNCTION Esh_WithStyle( vIns, cName, cStyle, nSize, nRot )
   LOCAL e := Esh_New()
   e[ "insertion_point" ] := vIns ; e[ "shape_name" ] := cName ; e[ "style_name" ] := cStyle ; e[ "size" ] := nSize ; e[ "rotation" ] := nRot
RETURN e
FUNCTION Esh_SetRotationDegrees( e, nDeg ) ; e[ "rotation" ] := nDeg * ( OCX_PI / 180.0 ) ; RETURN NIL
FUNCTION Esh_RotationDegrees( e ) ; RETURN e[ "rotation" ] * ( 180.0 / OCX_PI )
FUNCTION Esh_SetObliqueDegrees( e, nDeg ) ; e[ "oblique_angle" ] := nDeg * ( OCX_PI / 180.0 ) ; RETURN NIL
FUNCTION Esh_ObliqueDegrees( e ) ; RETURN e[ "oblique_angle" ] * ( 180.0 / OCX_PI )
FUNCTION Esh_Width( e ) ; RETURN e[ "size" ] * e[ "relative_x_scale" ]
FUNCTION Esh_Height( e ) ; RETURN e[ "size" ]
FUNCTION Esh_Direction( e ) ; RETURN Vc3_New( OCX_COS( e[ "rotation" ] ), OCX_SIN( e[ "rotation" ] ), 0.0 )
FUNCTION Esh_Rotate( e, nAngle )
   e[ "rotation" ] += nAngle
   DO WHILE e[ "rotation" ] < 0.0 ; e[ "rotation" ] += OCX_TAU ; ENDDO
   DO WHILE e[ "rotation" ] >= OCX_TAU ; e[ "rotation" ] -= OCX_TAU ; ENDDO
RETURN NIL
FUNCTION Esh_Scale( e, nF ) ; e[ "size" ] *= nF ; RETURN NIL
FUNCTION Esh_ScaleXy( e, nX, nY ) ; e[ "size" ] *= nY ; e[ "relative_x_scale" ] *= nX / nY ; RETURN NIL
FUNCTION Esh_SetNormal( e, vN ) ; e[ "normal" ] := Vc3_Normalize( vN ) ; RETURN NIL
FUNCTION Esh_HasThickness( e ) ; RETURN Abs( e[ "thickness" ] ) > 0.0000000001
FUNCTION Esh_HasCustomNormal( e ) ; LOCAL n := e[ "normal" ] ; RETURN Abs( n[ 1 ] ) > 0.0000000001 .OR. Abs( n[ 2 ] ) > 0.0000000001 .OR. Abs( n[ 3 ] - 1.0 ) > 0.0000000001
FUNCTION Esh_IsOblique( e ) ; RETURN Abs( e[ "oblique_angle" ] ) > 0.0000000001
FUNCTION Esh_IsScaled( e ) ; RETURN Abs( e[ "relative_x_scale" ] - 1.0 ) > 0.0000000001
FUNCTION Esh_MirrorX( e ) ; e[ "relative_x_scale" ] := - e[ "relative_x_scale" ] ; e[ "rotation" ] := OCX_PI - e[ "rotation" ] ; RETURN NIL
FUNCTION Esh_MirrorY( e ) ; e[ "rotation" ] := - e[ "rotation" ] ; RETURN NIL
/* devuelve { vMin, vMax } */
FUNCTION Esh_ApproximateBounds( e )
   LOCAL nHw := Esh_Width( e ) / 2.0, nHh := Esh_Height( e ) / 2.0, p := e[ "insertion_point" ]
RETURN { Vc3_New( p[ 1 ] - nHw, p[ 2 ] - nHh, p[ 3 ] ), Vc3_New( p[ 1 ] + nHw, p[ 2 ] + nHh, p[ 3 ] + e[ "thickness" ] ) }
FUNCTION Esh_TransformMatrix( e )
   LOCAL nC := OCX_COS( e[ "rotation" ] ), nS := OCX_SIN( e[ "rotation" ] ), nT := OCX_TAN( e[ "oblique_angle" ] ), nSx := e[ "relative_x_scale" ] * e[ "size" ], nSy := e[ "size" ], p := e[ "insertion_point" ]
RETURN { nC * nSx, - nS * nSy + nC * nT * nSy, 0.0, nS * nSx, nC * nSy + nS * nT * nSy, 0.0, 0.0, 0.0, Max( e[ "thickness" ], 1.0 ), p[ 1 ], p[ 2 ], p[ 3 ] }
FUNCTION Esh_BoundingBox( e )
   LOCAL a := Esh_ApproximateBounds( e )
RETURN Bb3_OcsToWcs( Bb3_New( a[ 1 ], a[ 2 ] ), e[ "normal" ] )
FUNCTION Esh_Translate( e, vOff ) ; e[ "insertion_point" ] := Vc3_Add( e[ "insertion_point" ], Mx3_TransformPoint( Mx3_Transpose( Mx3_ArbitraryAxis( e[ "normal" ] ) ), vOff ) ) ; RETURN NIL
FUNCTION Esh_Transform( e, t )
   LOCAL vNn := Vc3_Normalize( Tf_ApplyRotation( t, e[ "normal" ] ) ), mOcs := Mx3_ArbitraryAxis( e[ "normal" ] ), mNt := Mx3_Transpose( Mx3_ArbitraryAxis( vNn ) )
   e[ "insertion_point" ] := Mx3_TransformPoint( mNt, Tf_Apply( t, Mx3_TransformPoint( mOcs, e[ "insertion_point" ] ) ) )
   e[ "size" ] *= Vc3_Length( Tf_ApplyRotation( t, Vc3_New( 1.0, 0.0, 0.0 ) ) )
   e[ "normal" ] := vNn
   e[ "rotation" ] := Tf_RotateStoredAngle( e[ "rotation" ], t )
RETURN NIL
FUNCTION Esh_Mirror( e, t )
   Esh_Transform( e, t )
   e[ "relative_x_scale" ] := - e[ "relative_x_scale" ] ; e[ "oblique_angle" ] := - e[ "oblique_angle" ]
RETURN NIL
