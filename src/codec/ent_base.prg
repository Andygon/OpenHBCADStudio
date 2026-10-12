/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_base.prg
   Origen Rust: opencadcodec/src/entities/mod.rs (trait Entity + EntityCommon; mod.rs tiene 818 lineas,
   se portan por tandas junto a cada entidad). Licencia del original: MPL-2.0.
   MODELO: una entidad es un hash (hb_Hash) cuyas claves son los nombres de campo de Rust
   ("start", "end", "normal"...), mas "_type" (= entity_type(), p.ej. "LINE") y "common" (EntityCommon).
   El trait Entity pasa a funciones Ent_* que despachan por "_type". Option<T> -> NIL.
   Los tipos de entidad nuevos se anaden a Ent_Translate / Ent_ApplyTransform / Ent_ApplyMirror /
   Ent_BoundingBox cuando se portan.
----------------------------------------------------------------------------*/
#include "ocx.ch"

/* --- EntityCommon --- */
FUNCTION Ec_New()
RETURN hb_Hash( ;
   "raw_record", NIL, "handle", Hd_Null(), "layer", "0", "layer_handle", NIL, ;
   "color", Cl_ByLayer(), "line_weight", Lw_ByLayer(), "linetype", "", "linetype_handle", NIL, ;
   "linetype_scale", 1.0, "transparency", Tp_ByLayer(), "color_name", NIL, "invisible", .F., ;
   "extended_data", Xd_New(), "graphic_data", NIL, "reactors", {}, "xdictionary_handle", NIL, ;
   "owner_handle", Hd_Null(), "color_book_handle", NIL, "full_visual_style_handle", NIL, ;
   "face_visual_style_handle", NIL, "edge_visual_style_handle", NIL, "material_flags", 0, ;
   "material_handle", NIL, "shadow_flags", 0, "plotstyle_flags", 0, "plotstyle_handle", NIL, ;
   "entity_mode", NIL, "has_ds_data", .F. )

FUNCTION Ec_WithLayer( cLayer )
   LOCAL c := Ec_New()
   c[ "layer" ] := cLayer
RETURN c

FUNCTION Ec_HasLinetype( c ) ; RETURN Len( c[ "linetype" ] ) > 0 .AND. c[ "linetype" ] != "ByLayer"

/* preserve_storage_data_from (privada en Rust): copia campos de almacenamiento DWG */
FUNCTION Ec_PreserveStorageDataFrom( c, s )
   LOCAL k
   FOR EACH k IN { "layer_handle", "linetype_handle", "graphic_data", "color_book_handle", "face_visual_style_handle", ;
                   "edge_visual_style_handle", "material_flags", "material_handle", "shadow_flags", "plotstyle_flags", ;
                   "plotstyle_handle", "entity_mode", "has_ds_data" }
      c[ k ] := IIf( ValType( s[ k ] ) == "A", AClone( s[ k ] ), s[ k ] )
   NEXT
RETURN NIL

/* --- trait Entity: accesores --- */
FUNCTION Ent_Handle( e ) ; RETURN e[ "common" ][ "handle" ]
FUNCTION Ent_SetHandle( e, h ) ; e[ "common" ][ "handle" ] := h ; RETURN NIL
FUNCTION Ent_Layer( e ) ; RETURN e[ "common" ][ "layer" ]
FUNCTION Ent_SetLayer( e, c ) ; e[ "common" ][ "layer" ] := c ; RETURN NIL
FUNCTION Ent_Color( e ) ; RETURN e[ "common" ][ "color" ]
FUNCTION Ent_SetColor( e, c ) ; e[ "common" ][ "color" ] := c ; RETURN NIL
FUNCTION Ent_LineWeight( e ) ; RETURN e[ "common" ][ "line_weight" ]
FUNCTION Ent_SetLineWeight( e, w ) ; e[ "common" ][ "line_weight" ] := w ; RETURN NIL
FUNCTION Ent_Transparency( e ) ; RETURN e[ "common" ][ "transparency" ]
FUNCTION Ent_SetTransparency( e, t ) ; e[ "common" ][ "transparency" ] := t ; RETURN NIL
FUNCTION Ent_IsInvisible( e ) ; RETURN e[ "common" ][ "invisible" ]
FUNCTION Ent_SetInvisible( e, l ) ; e[ "common" ][ "invisible" ] := l ; RETURN NIL
FUNCTION Ent_EntityType( e ) ; RETURN iif( e[ "_type" ] == "POLYLINE2D" .OR. e[ "_type" ] == "POLYLINE3D", "POLYLINE", e[ "_type" ] )

/* --- trait Entity: despacho por tipo --- */
FUNCTION Ent_BoundingBox( e )
   DO CASE
   CASE e[ "_type" ] == "LINE" ; RETURN Eln_BoundingBox( e )
   CASE e[ "_type" ] == "POINT" ; RETURN Ept_BoundingBox( e )
   CASE e[ "_type" ] == "CIRCLE" ; RETURN Eci_BoundingBox( e )
   CASE e[ "_type" ] == "ARC" ; RETURN Ear_BoundingBox( e )
   CASE e[ "_type" ] == "ELLIPSE" ; RETURN Eel_BoundingBox( e )
   CASE e[ "_type" ] == "RAY" ; RETURN Ery_BoundingBox( e )
   CASE e[ "_type" ] == "XLINE" ; RETURN Exl_BoundingBox( e )
   CASE e[ "_type" ] == "SOLID" ; RETURN Eso_BoundingBox( e )
   CASE e[ "_type" ] == "3DFACE" ; RETURN Ef3_BoundingBox( e )
   CASE e[ "_type" ] == "TEXT" ; RETURN Etx_BoundingBox( e )
   CASE e[ "_type" ] == "MTEXT" ; RETURN Emt_BoundingBox( e )
   CASE e[ "_type" ] == "LWPOLYLINE" ; RETURN Elw_BoundingBox( e )
   CASE e[ "_type" ] == "SPLINE" ; RETURN Esp_BoundingBox( e )
   CASE e[ "_type" ] == "POLYLINE2D" ; RETURN Pl2_BoundingBox( e )
   CASE e[ "_type" ] == "POLYLINE" ; RETURN Plh_BoundingBox( e )
   CASE e[ "_type" ] == "POLYLINE3D" ; RETURN P3d_BoundingBox( e )
   CASE e[ "_type" ] == "BLOCK" ; RETURN Ebk_BoundingBox( e )
   CASE e[ "_type" ] == "INSERT" ; RETURN Ein_BoundingBox( e )
   CASE e[ "_type" ] == "HATCH" ; RETURN Ehh_BoundingBox( e )
   CASE e[ "_type" ] == "LEADER" ; RETURN Eld_BoundingBox( e )
   CASE e[ "_type" ] == "TOLERANCE" ; RETURN Etl_BoundingBox( e )
   CASE e[ "_type" ] == "SHAPE" ; RETURN Esh_BoundingBox( e )
   CASE e[ "_type" ] == "MLINE" ; RETURN Eml_BoundingBox( e )
   CASE e[ "_type" ] == "VIEWPORT" ; RETURN Evp_BoundingBox( e )
   CASE e[ "_type" ] == "WIPEOUT" ; RETURN Ewp_BoundingBox( e )
   CASE Edm_IsDimension( e[ "_type" ] ) ; RETURN Edm_BoundingBox( e )
   CASE e[ "_type" ] == "ATTRIB" ; RETURN Eat_BoundingBox( e )
   CASE e[ "_type" ] == "ATTDEF" ; RETURN Ead_BoundingBox( e )
   CASE e[ "_type" ] == "ENDBLK" ; RETURN Ebe_BoundingBox( e )
   CASE e[ "_type" ] == "SEQEND" ; RETURN Esq_BoundingBox( e )
   ENDCASE
RETURN NIL

FUNCTION Ent_Translate( e, vOffset )
   DO CASE
   CASE e[ "_type" ] == "LINE" ; Eln_Translate( e, vOffset )
   CASE e[ "_type" ] == "POINT" ; Ept_Translate( e, vOffset )
   CASE e[ "_type" ] == "CIRCLE" ; Eci_Translate( e, vOffset )
   CASE e[ "_type" ] == "ARC" ; Ear_Translate( e, vOffset )
   CASE e[ "_type" ] == "ELLIPSE" ; Eel_Translate( e, vOffset )
   CASE e[ "_type" ] == "RAY" ; Ery_Translate( e, vOffset )
   CASE e[ "_type" ] == "XLINE" ; Exl_Translate( e, vOffset )
   CASE e[ "_type" ] == "SOLID" ; Eso_Translate( e, vOffset )
   CASE e[ "_type" ] == "3DFACE" ; Ef3_Translate( e, vOffset )
   CASE e[ "_type" ] == "TEXT" ; Etx_Translate( e, vOffset )
   CASE e[ "_type" ] == "MTEXT" ; Emt_Translate( e, vOffset )
   CASE e[ "_type" ] == "LWPOLYLINE" ; Elw_Translate( e, vOffset )
   CASE e[ "_type" ] == "SPLINE" ; Esp_Translate( e, vOffset )
   CASE e[ "_type" ] == "POLYLINE2D" ; Pl2_Translate( e, vOffset )
   CASE e[ "_type" ] == "POLYLINE" ; Plh_Translate( e, vOffset )
   CASE e[ "_type" ] == "POLYLINE3D" ; P3d_Translate( e, vOffset )
   CASE e[ "_type" ] == "BLOCK" ; Ebk_Translate( e, vOffset )
   CASE e[ "_type" ] == "INSERT" ; Ein_Translate( e, vOffset )
   CASE e[ "_type" ] == "HATCH" ; Ehh_Translate( e, vOffset )
   CASE e[ "_type" ] == "LEADER" ; Eld_Translate( e, vOffset )
   CASE e[ "_type" ] == "TOLERANCE" ; Etl_Translate( e, vOffset )
   CASE e[ "_type" ] == "SHAPE" ; Esh_Translate( e, vOffset )
   CASE e[ "_type" ] == "MLINE" ; Eml_Translate( e, vOffset )
   CASE e[ "_type" ] == "VIEWPORT" ; Evp_Translate( e, vOffset )
   CASE e[ "_type" ] == "WIPEOUT" ; Ewp_Translate( e, vOffset )
   CASE Edm_IsDimension( e[ "_type" ] ) ; Edm_Translate( e, vOffset )
   CASE e[ "_type" ] == "ATTRIB" ; Eat_Translate( e, vOffset )
   CASE e[ "_type" ] == "ATTDEF" ; Ead_Translate( e, vOffset )
   ENDCASE
RETURN NIL

/* apply_transform: por defecto extrae la traslacion y traslada (como el trait de Rust) */
FUNCTION Ent_ApplyTransform( e, t )
   DO CASE
   CASE e[ "_type" ] == "LINE" ; Eln_Transform( e, t )
   CASE e[ "_type" ] == "POINT" ; Ept_Transform( e, t )
   CASE e[ "_type" ] == "CIRCLE" ; Eci_Transform( e, t )
   CASE e[ "_type" ] == "ARC" ; Ear_Transform( e, t )
   CASE e[ "_type" ] == "ELLIPSE" ; Eel_Transform( e, t )
   CASE e[ "_type" ] == "RAY" ; Ery_Transform( e, t )
   CASE e[ "_type" ] == "XLINE" ; Exl_Transform( e, t )
   CASE e[ "_type" ] == "SOLID" ; Eso_Transform( e, t )
   CASE e[ "_type" ] == "3DFACE" ; Ef3_Transform( e, t )
   CASE e[ "_type" ] == "TEXT" ; Etx_Transform( e, t )
   CASE e[ "_type" ] == "MTEXT" ; Emt_Transform( e, t )
   CASE e[ "_type" ] == "LWPOLYLINE" ; Elw_Transform( e, t )
   CASE e[ "_type" ] == "SPLINE" ; Esp_Transform( e, t )
   CASE e[ "_type" ] == "POLYLINE2D" ; Pl2_Transform( e, t )
   CASE e[ "_type" ] == "POLYLINE" ; Plh_Transform( e, t )
   CASE e[ "_type" ] == "POLYLINE3D" ; P3d_Transform( e, t )
   CASE e[ "_type" ] == "BLOCK" ; Ebk_Transform( e, t )
   CASE e[ "_type" ] == "INSERT" ; Ein_Transform( e, t )
   CASE e[ "_type" ] == "HATCH" ; Ehh_Transform( e, t )
   CASE e[ "_type" ] == "LEADER" ; Eld_Transform( e, t )
   CASE e[ "_type" ] == "TOLERANCE" ; Etl_Transform( e, t )
   CASE e[ "_type" ] == "SHAPE" ; Esh_Transform( e, t )
   CASE e[ "_type" ] == "MLINE" ; Eml_Transform( e, t )
   CASE e[ "_type" ] == "VIEWPORT" ; Evp_Transform( e, t )
   CASE e[ "_type" ] == "WIPEOUT" ; Ewp_Transform( e, t )
   CASE Edm_IsDimension( e[ "_type" ] ) ; Edm_Transform( e, t )
   CASE e[ "_type" ] == "ATTRIB" ; Eat_Transform( e, t )
   CASE e[ "_type" ] == "ATTDEF" ; Ead_Transform( e, t )
   CASE e[ "_type" ] == "ENDBLK" .OR. e[ "_type" ] == "SEQEND" ; HB_SYMBOL_UNUSED( e )
   OTHERWISE ; Ent_Translate( e, Tf_Apply( t, Vc3_Zero() ) )
   ENDCASE
RETURN NIL

/* apply_mirror: por defecto igual que apply_transform; las entidades que lo sobreescriben se anaden aqui */
FUNCTION Ent_ApplyMirror( e, t )
   DO CASE
   CASE e[ "_type" ] == "ARC" ; Ear_Mirror( e, t )
   CASE e[ "_type" ] == "ELLIPSE" ; Eel_Mirror( e, t )
   CASE e[ "_type" ] == "SOLID" ; Eso_Mirror( e, t )
   CASE e[ "_type" ] == "3DFACE" ; Ef3_Mirror( e, t )
   CASE e[ "_type" ] == "TEXT" ; Etx_Mirror( e, t )
   CASE e[ "_type" ] == "MTEXT" ; Emt_Mirror( e, t )
   CASE e[ "_type" ] == "SHAPE" ; Esh_Mirror( e, t )
   OTHERWISE ; Ent_ApplyTransform( e, t )
   ENDCASE
RETURN NIL

FUNCTION Ent_ApplyRotation( e, vAxis, nAngle ) ; Ent_ApplyTransform( e, Tf_FromRotation( vAxis, nAngle ) ) ; RETURN NIL
FUNCTION Ent_ApplyScaling( e, nScale ) ; Ent_ApplyTransform( e, Tf_FromScale( nScale ) ) ; RETURN NIL
FUNCTION Ent_ApplyScalingXyz( e, vScale ) ; Ent_ApplyTransform( e, Tf_FromScaling( vScale ) ) ; RETURN NIL
FUNCTION Ent_ApplyScalingWithOrigin( e, vScale, vOrigin ) ; Ent_ApplyTransform( e, Tf_FromScalingWithOrigin( vScale, vOrigin ) ) ; RETURN NIL
FUNCTION Ent_MirrorX( e ) ; Ent_ApplyMirror( e, Tf_FromMirrorX() ) ; RETURN NIL
FUNCTION Ent_MirrorY( e ) ; Ent_ApplyMirror( e, Tf_FromMirrorY() ) ; RETURN NIL
FUNCTION Ent_MirrorZ( e ) ; Ent_ApplyMirror( e, Tf_FromMirrorZ() ) ; RETURN NIL
FUNCTION Ent_MirrorAboutLine( e, p1, p2 ) ; Ent_ApplyMirror( e, Tf_FromMirrorLine( p1, p2 ) ) ; RETURN NIL
FUNCTION Ent_MirrorAboutPlane( e, vPoint, vNormal ) ; Ent_ApplyMirror( e, Tf_FromMirrorPlane( vPoint, vNormal ) ) ; RETURN NIL
