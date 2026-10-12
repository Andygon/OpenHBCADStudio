/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/doc_xrec.prg
   Origen Rust: opencadcodec/src/document.rs: material_checker_texture (L39-88) y CadDocument L3942-4260:
   object_owner, extension_dictionary_handle, xrecord, xrecord_mut, ensure_extension_dictionary, ensure_xrecord, resolve_xrecord_names,
   resolve_xrecord_backed_properties, viewport_annotation_scale, set_viewport_annotation_scale.
   Parte 4 de CadDocument. Licencia del original: MPL-2.0. Tests [extra] (el Rust no tiene #[test] aqui).
   Option<&T>/Option<&mut T> -> el objeto (referencia) o NIL. Los objetos son hashes con "_type"; PlotSettings (Pls_New) NO lleva "_type":
   se reconoce por su ausencia. owner: clave "owner" salvo MultiLeaderStyle/TableStyle/Scale/ObjectContextData/SortEntitiesTable/
   DictionaryVariable ("owner_handle"), TableContent ("common"."owner_handle") y UnderlayDefinition (sin owner -> NIL).
   Nota: HashMap de Rust itera en orden arbitrario; aqui el orden es el de insercion (solo afecta a casos con claves duplicadas).
----------------------------------------------------------------------------*/
#include "ocx.ch"

/* Option<MaterialTexture>: checker de 2 colores desde las entradas de un xrecord */
FUNCTION Doc_MaterialCheckerTexture( aEntries )
   LOCAL e, lChecker := .F., nActive := NIL, aCol := { NIL, NIL }, s, v, t
   FOR EACH e IN aEntries
      s := Xrv_AsString( e[ "value" ] )
      IF e[ "code" ] == 301 .AND. s != NIL .AND. Upper( s ) == "CHECKER" ; lChecker := .T. ; EXIT ; ENDIF
   NEXT
   IF ! lChecker ; RETURN NIL ; ENDIF
   FOR EACH e IN aEntries
      IF e[ "code" ] == 300
         s := Xrv_AsString( e[ "value" ] )
         IF s != NIL
            IF Upper( s ) == "MAP1" ; nActive := 0
            ELSEIF Upper( s ) == "MAP2" ; nActive := 1
            ELSEIF Upper( s ) == "MAPPER" ; nActive := NIL
            ENDIF
         ENDIF
      ELSEIF e[ "code" ] == 420
         v := Xrv_AsI32( e[ "value" ] )
         IF nActive != NIL .AND. v != NIL ; aCol[ nActive + 1 ] := v ; ENDIF
      ENDIF
   NEXT
   IF aCol[ 1 ] == NIL .OR. aCol[ 2 ] == NIL ; RETURN NIL ; ENDIF
   t := Mtx_Default()
   t[ "color1" ] := hb_Hash( "flag", 1, "factor", 1.0, "rgb", aCol[ 1 ] )
   t[ "color2" ] := hb_Hash( "flag", 1, "factor", 1.0, "rgb", aCol[ 2 ] )
RETURN t

STATIC FUNCTION Doc_Ty( o ) ; RETURN iif( hb_HHasKey( o, "_type" ), o[ "_type" ], "PlotSettings" )

FUNCTION Doc_ObjectOwner( d, h )
   LOCAL o, c
   IF ! hb_HHasKey( d[ "objects" ], h ) ; RETURN NIL ; ENDIF
   o := d[ "objects" ][ h ] ; c := Doc_Ty( o )
   IF c == "UnderlayDefinition" ; RETURN NIL ; ENDIF
   IF c == "TableContent" ; RETURN o[ "common" ][ "owner_handle" ] ; ENDIF
   IF "|" + c + "|" $ "|MultiLeaderStyle|TableStyle|Scale|ObjectContextData|SortEntitiesTable|DictionaryVariable|" ; RETURN o[ "owner_handle" ] ; ENDIF
RETURN o[ "owner" ]

FUNCTION Doc_ExtensionDictionaryHandle( d, nOwner )
   LOCAL e := Doc_GetEntity( d, nOwner ), x, o, k
   IF e != NIL .AND. e[ "common" ][ "xdictionary_handle" ] != NIL
      x := e[ "common" ][ "xdictionary_handle" ] ; RETURN iif( Hd_IsNull( x ), NIL, x )
   ENDIF
   IF hb_HHasKey( d[ "xdic_by_handle" ], nOwner )
      x := d[ "xdic_by_handle" ][ nOwner ] ; RETURN iif( Hd_IsNull( x ), NIL, x )
   ENDIF
   IF hb_HHasKey( d[ "objects" ], nOwner )
      o := d[ "objects" ][ nOwner ]
      IF "|" + Doc_Ty( o ) + "|" $ "|Dictionary|Layout|XRecord|PlotSettings|VisualStyle|Material|ProxyObject|" .AND. o[ "xdictionary_handle" ] != NIL .AND. ! Hd_IsNull( o[ "xdictionary_handle" ] )
         RETURN o[ "xdictionary_handle" ]
      ENDIF
      IF o[ "_type" ] == "Dictionary" ; RETURN NIL ; ENDIF
   ENDIF
   FOR EACH k IN hb_HKeys( d[ "objects" ] )
      o := d[ "objects" ][ k ]
      IF Doc_Ty( o ) == "Dictionary" .AND. o[ "owner" ] == nOwner .AND. ! Hd_IsNull( k ) ; RETURN k ; ENDIF
   NEXT
RETURN NIL

/* xrecord y xrecord_mut: el mismo objeto (referencia) */
FUNCTION Doc_Xrecord( d, nOwner, cKey )
   LOCAL nDic := Doc_ExtensionDictionaryHandle( d, nOwner ), nRec
   IF nDic == NIL .OR. ! hb_HHasKey( d[ "objects" ], nDic ) .OR. d[ "objects" ][ nDic ][ "_type" ] != "Dictionary" ; RETURN NIL ; ENDIF
   nRec := Dic_Get( d[ "objects" ][ nDic ], cKey )
   IF nRec == NIL .OR. ! hb_HHasKey( d[ "objects" ], nRec ) .OR. d[ "objects" ][ nRec ][ "_type" ] != "XRecord" ; RETURN NIL ; ENDIF
RETURN d[ "objects" ][ nRec ]

FUNCTION Doc_XrecordMut( d, nOwner, cKey ) ; RETURN Doc_Xrecord( d, nOwner, cKey )

FUNCTION Doc_EnsureExtensionDictionary( d, nOwner )
   LOCAL h := Doc_ExtensionDictionaryHandle( d, nOwner ), dic, e
   IF h != NIL ; RETURN h ; ENDIF
   h := Doc_AllocateHandle( d )
   dic := Dic_New() ; dic[ "handle" ] := h ; dic[ "owner" ] := nOwner ; dic[ "hard_owner" ] := .T.
   d[ "objects" ][ h ] := dic
   e := Doc_GetEntityMut( d, nOwner )
   IF e != NIL ; e[ "common" ][ "xdictionary_handle" ] := h ; ENDIF
   d[ "xdic_by_handle" ][ nOwner ] := h
RETURN h

FUNCTION Doc_EnsureXrecord( d, nOwner, cKey )
   LOCAL nDic := Doc_EnsureExtensionDictionary( d, nOwner ), dic := d[ "objects" ][ nDic ], nH, rec, ent, l := .F.
   IF dic[ "_type" ] == "Dictionary"
      nH := Dic_Get( dic, cKey )
      IF nH != NIL .AND. hb_HHasKey( d[ "objects" ], nH ) .AND. d[ "objects" ][ nH ][ "_type" ] == "XRecord" ; RETURN nH ; ENDIF
   ENDIF
   nH := Doc_AllocateHandle( d )
   rec := Xrc_Named( cKey ) ; rec[ "handle" ] := nH ; rec[ "owner" ] := nDic
   d[ "objects" ][ nH ] := rec
   IF dic[ "_type" ] == "Dictionary"
      FOR EACH ent IN dic[ "entries" ]
         IF Upper( ent[ 1 ] ) == Upper( cKey ) ; ent[ 2 ] := nH ; l := .T. ; EXIT ; ENDIF
      NEXT
      IF ! l ; Dic_AddEntry( dic, cKey, nH ) ; ENDIF
   ENDIF
RETURN nH

PROCEDURE Doc_ResolveXrecordNames( d )
   LOCAL a := {}, o, e, x
   FOR EACH o IN hb_HValues( d[ "objects" ] )
      IF Doc_Ty( o ) == "Dictionary"
         FOR EACH e IN o[ "entries" ] ; AAdd( a, { e[ 2 ], e[ 1 ] } ) ; NEXT
      ENDIF
   NEXT
   ASort( a,,, {| p, q | p[ 1 ] < q[ 1 ] .OR. ( p[ 1 ] == q[ 1 ] .AND. p[ 2 ] < q[ 2 ] ) } )
   FOR EACH x IN a
      IF hb_HHasKey( d[ "objects" ], x[ 1 ] ) .AND. d[ "objects" ][ x[ 1 ] ][ "_type" ] == "XRecord" ; d[ "objects" ][ x[ 1 ] ][ "name" ] := x[ 2 ] ; ENDIF
   NEXT
RETURN

PROCEDURE Doc_ResolveXrecordBackedProperties( d )
   LOCAL hAdv := hb_Hash(), hMaps := hb_Hash(), o, r, cName, xr, tex, nDic, m, e, v, aMap, k
   FOR EACH o IN hb_HValues( d[ "objects" ] )
      IF Doc_Ty( o ) == "Dictionary"
         r := Dic_Get( o, "ADVMATERIAL" )
         IF r != NIL .AND. hb_HHasKey( d[ "objects" ], r ) .AND. d[ "objects" ][ r ][ "_type" ] == "XRecord"
            hAdv[ o[ "handle" ] ] := d[ "objects" ][ r ][ "entries" ]
         ENDIF
      ENDIF
   NEXT
   FOR EACH o IN hb_HValues( d[ "objects" ] )
      IF Doc_Ty( o ) != "Dictionary" ; LOOP ; ENDIF
      FOR EACH cName IN { "DIFFUSE", "SPECULAR", "REFLECTION", "OPACITY", "BUMP", "REFRACTION", "NORMAL" }
         r := Dic_Get( o, cName )
         IF r == NIL .OR. ! hb_HHasKey( d[ "objects" ], r ) ; LOOP ; ENDIF
         xr := d[ "objects" ][ r ] ; IF xr[ "_type" ] != "XRecord" ; LOOP ; ENDIF
         tex := Doc_MaterialCheckerTexture( xr[ "entries" ] )
         IF tex != NIL ; hMaps[ hb_ntos( o[ "handle" ] ) + "|" + cName ] := tex ; ENDIF
      NEXT
   NEXT
   FOR EACH m IN hb_HValues( d[ "objects" ] )
      IF Doc_Ty( m ) != "Material" .OR. m[ "xdictionary_handle" ] == NIL ; LOOP ; ENDIF
      nDic := m[ "xdictionary_handle" ]
      IF hb_HHasKey( hAdv, nDic )
         m[ "advanced_data_present" ] := .T.
         FOR EACH e IN hAdv[ nDic ]
            v := e[ "value" ]
            DO CASE
            CASE e[ "code" ] == 460 .AND. Xrv_AsDouble( v ) != NIL ; m[ "color_bleed_scale" ] := Xrv_AsDouble( v ) / 100.0
            CASE e[ "code" ] == 461 .AND. Xrv_AsDouble( v ) != NIL ; m[ "indirect_bump_scale" ] := Xrv_AsDouble( v ) / 100.0
            CASE e[ "code" ] == 462 .AND. Xrv_AsDouble( v ) != NIL ; m[ "reflectance_scale" ] := Xrv_AsDouble( v ) / 100.0
            CASE e[ "code" ] == 463 .AND. Xrv_AsDouble( v ) != NIL ; m[ "transmittance_scale" ] := Xrv_AsDouble( v ) / 100.0
            CASE e[ "code" ] == 464 .AND. Xrv_AsDouble( v ) != NIL ; m[ "luminance" ] := Xrv_AsDouble( v )
            CASE e[ "code" ] == 270 .AND. v[ "_kind" ] == "Int16" ; m[ "luminance_mode" ] := v[ "value" ]
            CASE e[ "code" ] == 290 .AND. Xrv_AsBool( v ) != NIL ; m[ "two_sided_material" ] := Xrv_AsBool( v )
            CASE e[ "code" ] == 293 .AND. Xrv_AsBool( v ) != NIL ; m[ "is_anonymous" ] := Xrv_AsBool( v )
            CASE e[ "code" ] == 272 .AND. v[ "_kind" ] == "Int16" ; m[ "global_illumination" ] := v[ "value" ]
            CASE e[ "code" ] == 273 .AND. v[ "_kind" ] == "Int16" ; m[ "final_gather" ] := v[ "value" ]
            ENDCASE
         NEXT
      ENDIF
      FOR EACH k IN { { "DIFFUSE", "diffuse_map" }, { "SPECULAR", "specular_map" }, { "REFLECTION", "reflection_map" }, { "OPACITY", "opacity_map" }, ;
                      { "BUMP", "bump_map" }, { "REFRACTION", "refraction_map" }, { "NORMAL", "normal_map" } }
         aMap := hb_ntos( nDic ) + "|" + k[ 1 ]
         IF hb_HHasKey( hMaps, aMap )
            m[ k[ 2 ] ][ "source" ] := 2 ; m[ k[ 2 ] ][ "file_name" ] := "" ; m[ k[ 2 ] ][ "texture" ] := Ent_Clone( hMaps[ aMap ] )
         ENDIF
      NEXT
   NEXT
RETURN

FUNCTION Doc_ViewportAnnotationScale( d, nVp )
   LOCAL x := Doc_Xrecord( d, nVp, "ASDK_XREC_ANNOTATION_SCALE_INFO" )
RETURN iif( x == NIL, NIL, Xrc_AnnotationScaleHandle( x ) )

PROCEDURE Doc_SetViewportAnnotationScale( d, nVp, nScale )
   LOCAL x
   Doc_EnsureXrecord( d, nVp, "ASDK_XREC_ANNOTATION_SCALE_INFO" )
   x := Doc_XrecordMut( d, nVp, "ASDK_XREC_ANNOTATION_SCALE_INFO" )
   IF x != NIL ; Xrc_SetAnnotationScaleHandle( x, nScale ) ; ENDIF
RETURN
