/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/obj_xrecord.prg
   Origen Rust: opencadcodec/src/objects/xrecord.rs (987 lineas, 13 tests). Licencia del original: MPL-2.0.
   Prefijos: Dcf_ (DictionaryCloningFlags: el valor i16 0..5 es el propio enum), Xvt_ (XRecordValueType, XVT_* en ocx.ch),
             Xrv_ (XRecordValue), Xre_ (XRecordEntry), Xrk_ (KnownXRecordKind, XRK_*; mapa de 84 nombres generado del Rust), Xrc_ (XRecord).
   XRecordValue = hash { "_kind": "String"|"Double"|"Int16"|"Int32"|"Int64"|"Byte"|"Bool"|"Handle"|"Point3D"|"Chunk", "value": x }; Point3D -> { x, y, z }.
   XRecordEntry = hash { code, value }. XRecordSection = hash { name, entries }. Option -> NIL. as_point3d devuelve { x, y, z }.
   La condicion xrecord_entries_complete() es siempre true en Rust. ProxyObjectReference/ProxyReferenceKind vienen de obj_semantic.prg (PRK_*).
   Los metodos &mut self mutan el hash en sitio.
----------------------------------------------------------------------------*/
#include "ocx.ch"

/* ---- DictionaryCloningFlags ---- */
FUNCTION Dcf_FromValue( n ) ; RETURN iif( n >= 1 .AND. n <= 5, n, 0 )
FUNCTION Dcf_ToValue( n ) ; RETURN n
FUNCTION Dcf_ToCode( n ) ; RETURN n

/* ---- XRecordValueType ---- */
FUNCTION Xvt_FromCode( n )
   IF n < 0 ; RETURN XVT_HANDLE ; ENDIF
   IF n == 5 .OR. n == 105 .OR. ( n >= 320 .AND. n <= 329 ) .OR. ( n >= 480 .AND. n <= 481 ) ; RETURN XVT_HANDLE ; ENDIF
   IF n >= 330 .AND. n <= 369 ; RETURN XVT_OBJECT_ID ; ENDIF
   IF ( n >= 390 .AND. n <= 399 ) .OR. n == 1005 ; RETURN XVT_HANDLE ; ENDIF
   IF ( n >= 0 .AND. n <= 4 ) .OR. ( n >= 6 .AND. n <= 9 ) .OR. ( n >= 100 .AND. n <= 102 ) .OR. ( n >= 300 .AND. n <= 309 ) .OR. ( n >= 410 .AND. n <= 419 ) ;
      .OR. ( n >= 430 .AND. n <= 439 ) .OR. ( n >= 470 .AND. n <= 479 ) .OR. n == 999 .OR. ( n >= 1000 .AND. n <= 1003 )
      RETURN XVT_STRING
   ENDIF
   IF ( n >= 10 .AND. n <= 37 ) .OR. ( n >= 110 .AND. n <= 139 ) .OR. ( n >= 210 .AND. n <= 269 ) .OR. ( n >= 1010 .AND. n <= 1039 ) .OR. ( n >= 1043 .AND. n <= 1069 )
      RETURN XVT_POINT3D
   ENDIF
   IF ( n >= 38 .AND. n <= 59 ) .OR. ( n >= 140 .AND. n <= 149 ) .OR. ( n >= 460 .AND. n <= 469 ) .OR. ( n >= 1040 .AND. n <= 1042 ) ; RETURN XVT_DOUBLE ; ENDIF
   IF n >= 280 .AND. n <= 289 ; RETURN XVT_BYTE ; ENDIF
   IF ( n >= 60 .AND. n <= 79 ) .OR. ( n >= 170 .AND. n <= 179 ) .OR. ( n >= 270 .AND. n <= 279 ) .OR. ( n >= 370 .AND. n <= 389 ) .OR. ( n >= 400 .AND. n <= 409 ) .OR. n == 1070
      RETURN XVT_INT16
   ENDIF
   IF ( n >= 80 .AND. n <= 99 ) .OR. ( n >= 420 .AND. n <= 429 ) .OR. ( n >= 440 .AND. n <= 459 ) .OR. n == 1071 ; RETURN XVT_INT32 ; ENDIF
   IF n >= 150 .AND. n <= 169 ; RETURN XVT_INT64 ; ENDIF
   IF n >= 290 .AND. n <= 299 ; RETURN XVT_BOOL ; ENDIF
   IF ( n >= 310 .AND. n <= 319 ) .OR. n == 1004 ; RETURN XVT_CHUNK ; ENDIF
RETURN XVT_UNKNOWN
FUNCTION Xvt_IsHandle( n ) ; RETURN n == XVT_HANDLE .OR. n == XVT_OBJECT_ID

/* ---- XRecordValue ---- */
FUNCTION Xrv_New( cKind, xVal ) ; RETURN hb_Hash( "_kind", cKind, "value", xVal )
FUNCTION Xrv_AsString( v ) ; RETURN iif( v[ "_kind" ] == "String", v[ "value" ], NIL )
FUNCTION Xrv_AsDouble( v ) ; RETURN iif( v[ "_kind" ] == "Double", v[ "value" ], NIL )
FUNCTION Xrv_AsI32( v ) ; RETURN iif( v[ "_kind" ] $ "|Int32|Int16|Byte|", v[ "value" ], NIL )
FUNCTION Xrv_AsHandle( v ) ; RETURN iif( v[ "_kind" ] == "Handle", v[ "value" ], NIL )
FUNCTION Xrv_AsBool( v ) ; RETURN iif( v[ "_kind" ] == "Bool", v[ "value" ], NIL )
FUNCTION Xrv_AsPoint3d( v ) ; RETURN iif( v[ "_kind" ] == "Point3D", v[ "value" ], NIL )

/* ---- XRecordEntry ---- */
FUNCTION Xre_New( nCode, hValue ) ; RETURN hb_Hash( "code", nCode, "value", hValue )
FUNCTION Xre_String( nCode, c ) ; RETURN Xre_New( nCode, Xrv_New( "String", c ) )
FUNCTION Xre_Double( nCode, n ) ; RETURN Xre_New( nCode, Xrv_New( "Double", n ) )
FUNCTION Xre_Int16( nCode, n ) ; RETURN Xre_New( nCode, Xrv_New( "Int16", n ) )
FUNCTION Xre_Int32( nCode, n ) ; RETURN Xre_New( nCode, Xrv_New( "Int32", n ) )
FUNCTION Xre_Handle( nCode, n ) ; RETURN Xre_New( nCode, Xrv_New( "Handle", n ) )
FUNCTION Xre_Bool( nCode, l ) ; RETURN Xre_New( nCode, Xrv_New( "Bool", l ) )
FUNCTION Xre_Point3d( nCode, x, y, z ) ; RETURN Xre_New( nCode, Xrv_New( "Point3D", { x, y, z } ) )
FUNCTION Xre_ValueType( e ) ; RETURN Xvt_FromCode( e[ "code" ] )
FUNCTION Xre_HasLinkedObject( e ) ; RETURN e[ "value" ][ "_kind" ] == "Handle"

/* ---- KnownXRecordKind ---- */
FUNCTION Xrk_FromName( cName )
   STATIC s_h
   LOCAL h
   IF s_h == NIL
      h := hb_Hash()
   hb_HSet( h, "ADSK_XREC_LAYER_ALPHA_OVR", XRK_LAYER_VIEWPORT_ALPHA_OVERRIDE )
   hb_HSet( h, "ADSK_XREC_LAYER_COLOR_OVR", XRK_LAYER_VIEWPORT_COLOR_OVERRIDE )
   hb_HSet( h, "ADSK_XREC_LAYER_LINETYPE_OVR", XRK_LAYER_VIEWPORT_LINETYPE_OVERRIDE )
   hb_HSet( h, "ADSK_XREC_LAYER_LINEWT_OVR", XRK_LAYER_VIEWPORT_LINEWEIGHT_OVERRIDE )
   hb_HSet( h, "ADSK_XREC_LAYER_RECONCILED", XRK_LAYER_RECONCILED )
   hb_HSet( h, "ACADLAYERSTATEANNOSCALE", XRK_LAYER_STATE_ANNOTATION_SCALE )
   hb_HSet( h, "ASDK_XREC_ANNOTATION_SCALE_INFO", XRK_ANNOTATION_SCALE )
   hb_HSet( h, "ASDK_XREC_ANNO_SCALE_INFO", XRK_ANNOTATION_SCALE )
   hb_HSet( h, "ADSK_XREC_VTR_ANNOSCALE_DATA", XRK_ANNOTATION_SCALE )
   hb_HSet( h, "ADSK_XREC_SUBDVERTEXTEXCOORDS", XRK_MESH_TEXTURE_COORDINATES )
   hb_HSet( h, "ACAD_XREC_ROUNDTRIP", XRK_XRECORD_ROUND_TRIP )
   hb_HSet( h, "ACAD_MTEXT_RT", XRK_MTEXT_ROUND_TRIP )
   hb_HSet( h, "ACAD_MTEXT_2008_RT", XRK_MTEXT_ROUND_TRIP )
   hb_HSet( h, "ACDBHEADERROUNDTRIPXREC", XRK_HEADER_ROUND_TRIP )
   hb_HSet( h, "AUXHDRRNDTRIPDATA", XRK_HEADER_ROUND_TRIP )
   hb_HSet( h, "ACDB_RECOMPOSE_DATA", XRK_RECOMPOSE_DATA )
   hb_HSet( h, "ACAD_ENHANCEDBLOCKHISTORY", XRK_DYNAMIC_BLOCK_HISTORY )
   hb_HSet( h, "ASEBLOCKHIERARCHYINDEXRECORD", XRK_DYNAMIC_BLOCK_HISTORY )
   hb_HSet( h, "ADSK_XREC_LAYOUTTHUMBNAIL", XRK_LAYOUT_THUMBNAIL )
   hb_HSet( h, "ADSK_XREC_VTRANIMATIONINFO", XRK_VIEW_TRANSITION )
   hb_HSet( h, "ADSK_XREC_VTRTHUMBNAIL", XRK_VIEW_TRANSITION )
   hb_HSet( h, "ADSK_XREC_VTRVIEWINFO", XRK_VIEW_TRANSITION )
   hb_HSet( h, "ADSK_XREC_PHOTOMETRICLIGHTINFO", XRK_PHOTOMETRIC_LIGHT )
   hb_HSet( h, "LIGHTINGQUALITY", XRK_PHOTOMETRIC_LIGHT )
   hb_HSet( h, "ACAD_LAST_SAVED_VERSION_INFO", XRK_LAST_SAVED_VERSION )
   hb_HSet( h, "ACAD_CIP_PREVIOUS_PRODUCT_INFO", XRK_PREVIOUS_PRODUCT_INFO )
   hb_HSet( h, "DWGPROPS", XRK_DRAWING_PROPERTIES )
   hb_HSet( h, "FINGERPRINTGUID", XRK_FINGERPRINT_GUID )
   hb_HSet( h, "ACADDIM", XRK_DIMENSION_STYLE_DATA )
   hb_HSet( h, "DIMSTYLEDATA", XRK_DIMENSION_STYLE_DATA )
   hb_HSet( h, "DIMLTEX1", XRK_DIMENSION_STYLE_DATA )
   hb_HSet( h, "DIMLTEX2", XRK_DIMENSION_STYLE_DATA )
   hb_HSet( h, "DIMLTYPE", XRK_DIMENSION_STYLE_DATA )
   hb_HSet( h, "TSTACKALIGN", XRK_DIMENSION_STYLE_DATA )
   hb_HSet( h, "TSTACKSIZE", XRK_DIMENSION_STYLE_DATA )
   hb_HSet( h, "PUCSBASE", XRK_UCS_DATA )
   hb_HSet( h, "PUCSORGBACK", XRK_UCS_DATA )
   hb_HSet( h, "PUCSORGBOTTOM", XRK_UCS_DATA )
   hb_HSet( h, "PUCSORGFRONT", XRK_UCS_DATA )
   hb_HSet( h, "PUCSORGLEFT", XRK_UCS_DATA )
   hb_HSet( h, "PUCSORGRIGHT", XRK_UCS_DATA )
   hb_HSet( h, "PUCSORGTOP", XRK_UCS_DATA )
   hb_HSet( h, "PUCSORTHOREF", XRK_UCS_DATA )
   hb_HSet( h, "PUCSORTHOVIEW", XRK_UCS_DATA )
   hb_HSet( h, "UCSBASE", XRK_UCS_DATA )
   hb_HSet( h, "UCSORGBACK", XRK_UCS_DATA )
   hb_HSet( h, "UCSORGBOTTOM", XRK_UCS_DATA )
   hb_HSet( h, "UCSORGFRONT", XRK_UCS_DATA )
   hb_HSet( h, "UCSORGLEFT", XRK_UCS_DATA )
   hb_HSet( h, "UCSORGRIGHT", XRK_UCS_DATA )
   hb_HSet( h, "UCSORGTOP", XRK_UCS_DATA )
   hb_HSet( h, "UCSORTHOREF", XRK_UCS_DATA )
   hb_HSet( h, "UCSORTHOVIEW", XRK_UCS_DATA )
   hb_HSet( h, "ACAD_LAYOUTSELFREF", XRK_PLOT_DATA )
   hb_HSet( h, "LAYOUTDICT", XRK_PLOT_DATA )
   hb_HSet( h, "PLOTSETDICT", XRK_PLOT_DATA )
   hb_HSet( h, "PLOTSTYLNAMDICT", XRK_PLOT_DATA )
   hb_HSet( h, "PSVPSCALE", XRK_PLOT_DATA )
   hb_HSet( h, "STYLESHEET", XRK_PLOT_DATA )
   hb_HSet( h, "HYPERLINKBASE", XRK_HYPERLINK )
   hb_HSet( h, "ADVMATERIAL", XRK_ADVANCED_MATERIAL )
   hb_HSet( h, "FBXASSET", XRK_MATERIAL_ASSET )
   hb_HSet( h, "BUMPTILE", XRK_MATERIAL_ASSET )
   hb_HSet( h, "DIFFUSETILE", XRK_MATERIAL_ASSET )
   hb_HSet( h, "OPACITYTILE", XRK_MATERIAL_ASSET )
   hb_HSet( h, "REFLECTIONTILE", XRK_MATERIAL_ASSET )
   hb_HSet( h, "REFRACTIONTILE", XRK_MATERIAL_ASSET )
   hb_HSet( h, "SPECULARTILE", XRK_MATERIAL_ASSET )
   hb_HSet( h, "BUMP", XRK_MATERIAL_ASSET )
   hb_HSet( h, "DIFFUSE", XRK_MATERIAL_ASSET )
   hb_HSet( h, "MATERIALDICT", XRK_MATERIAL_ASSET )
   hb_HSet( h, "VIZ XML MATERIAL DEFINITION", XRK_MATERIAL_ASSET )
   hb_HSet( h, "ACAD_MLATT", XRK_METADATA )
   hb_HSet( h, "ACAD_VIEWS_VIEW_CUSTOM", XRK_METADATA )
   hb_HSet( h, "AECDEPRECATIONHISTORY", XRK_METADATA )
   hb_HSet( h, "CEPSNID", XRK_METADATA )
   hb_HSet( h, "CEPSNTYPE", XRK_METADATA )
   hb_HSet( h, "COLORDICT", XRK_METADATA )
   hb_HSet( h, "INSUNITS", XRK_METADATA )
   hb_HSet( h, "LWETCUNION", XRK_METADATA )
   hb_HSet( h, "MCS_DOCUMENT_ID", XRK_METADATA )
   hb_HSet( h, "MCS_PARAMS_DATA", XRK_METADATA )
   hb_HSet( h, "MC_VERSION_DATA", XRK_METADATA )
   hb_HSet( h, "VERSIONGUID", XRK_METADATA )
      s_h := h
   ENDIF
   cName := Upper( cName )
   IF hb_HHasKey( s_h, cName ) ; RETURN s_h[ cName ] ; ENDIF
RETURN XRK_UNKNOWN

/* ---- XRecord ---- */
FUNCTION Xrc_ObjectType() ; RETURN "XRECORD"

FUNCTION Xrc_New()
RETURN hb_Hash( "_type", "XRecord", "handle", Hd_Null(), "owner", Hd_Null(), "reactors", {}, "xdictionary_handle", NIL, "name", "", "cloning_flags", 0, "entries", {}, ;
   "object_references", {}, "preserve_object_reference_stream", .F., "entries_complete", .T., "raw_data", "", "raw_dwg_data", NIL, "raw_dwg_handle_bits", 0, "raw_dwg_version", NIL )

FUNCTION Xrc_Named( cName )
   LOCAL x := Xrc_New()
   x[ "name" ] := cName
RETURN x

PROCEDURE Xrc_AddEntry( x, e )
   LOCAL l := e[ "code" ] >= 330 .AND. e[ "code" ] <= 369
   AAdd( x[ "entries" ], e )
   IF l ; Xrc_SynchronizeObjectReferences( x ) ; ENDIF
   x[ "entries_complete" ] := .T.
RETURN

STATIC PROCEDURE Xrc_Push( x, e )
   AAdd( x[ "entries" ], e )
   x[ "entries_complete" ] := .T.
RETURN
PROCEDURE Xrc_AddString( x, nCode, c ) ; Xrc_Push( x, Xre_String( nCode, c ) ) ; RETURN
PROCEDURE Xrc_AddDouble( x, nCode, n ) ; Xrc_Push( x, Xre_Double( nCode, n ) ) ; RETURN
PROCEDURE Xrc_AddInt16( x, nCode, n ) ; Xrc_Push( x, Xre_Int16( nCode, n ) ) ; RETURN
PROCEDURE Xrc_AddInt32( x, nCode, n ) ; Xrc_Push( x, Xre_Int32( nCode, n ) ) ; RETURN
PROCEDURE Xrc_AddBool( x, nCode, l ) ; Xrc_Push( x, Xre_Bool( nCode, l ) ) ; RETURN
PROCEDURE Xrc_AddPoint3d( x, nCode, a, b, c ) ; Xrc_Push( x, Xre_Point3d( nCode, a, b, c ) ) ; RETURN
PROCEDURE Xrc_AddHandle( x, nCode, n )
   AAdd( x[ "entries" ], Xre_Handle( nCode, n ) )
   IF nCode >= 330 .AND. nCode <= 369 ; Xrc_SynchronizeObjectReferences( x ) ; ENDIF
   x[ "entries_complete" ] := .T.
RETURN

FUNCTION Xrc_Len( x ) ; RETURN Len( x[ "entries" ] )
FUNCTION Xrc_IsEmpty( x ) ; RETURN Len( x[ "entries" ] ) == 0
FUNCTION Xrc_Get( x, nIdx ) ; RETURN iif( nIdx >= 0 .AND. nIdx < Len( x[ "entries" ] ), x[ "entries" ][ nIdx + 1 ], NIL )

FUNCTION Xrc_GetByCode( x, nCode )
   LOCAL a := {}, e
   FOR EACH e IN x[ "entries" ]
      IF e[ "code" ] == nCode ; AAdd( a, e ) ; ENDIF
   NEXT
RETURN a

FUNCTION Xrc_GetFirstByCode( x, nCode )
   LOCAL e
   FOR EACH e IN x[ "entries" ]
      IF e[ "code" ] == nCode ; RETURN e ; ENDIF
   NEXT
RETURN NIL

FUNCTION Xrc_GetStrings( x, nCode )
   LOCAL a := {}, e, s
   FOR EACH e IN x[ "entries" ]
      IF e[ "code" ] == nCode
         s := Xrv_AsString( e[ "value" ] )
         IF s != NIL ; AAdd( a, s ) ; ENDIF
      ENDIF
   NEXT
RETURN a

FUNCTION Xrc_GetString( x, nCode )
   LOCAL e := Xrc_GetFirstByCode( x, nCode )
RETURN iif( e == NIL, NIL, Xrv_AsString( e[ "value" ] ) )
FUNCTION Xrc_GetDouble( x, nCode )
   LOCAL e := Xrc_GetFirstByCode( x, nCode )
RETURN iif( e == NIL, NIL, Xrv_AsDouble( e[ "value" ] ) )
FUNCTION Xrc_GetI32( x, nCode )
   LOCAL e := Xrc_GetFirstByCode( x, nCode )
RETURN iif( e == NIL, NIL, Xrv_AsI32( e[ "value" ] ) )

PROCEDURE Xrc_RemoveByCode( x, nCode )
   LOCAL a := {}, e
   FOR EACH e IN x[ "entries" ]
      IF e[ "code" ] != nCode ; AAdd( a, e ) ; ENDIF
   NEXT
   x[ "entries" ] := a
   IF nCode >= 330 .AND. nCode <= 369 ; Xrc_SynchronizeObjectReferences( x ) ; ENDIF
   x[ "entries_complete" ] := .T.
RETURN

PROCEDURE Xrc_Clear( x )
   x[ "entries" ] := {}
   x[ "object_references" ] := {}
   x[ "preserve_object_reference_stream" ] := .F.
   x[ "entries_complete" ] := .T.
RETURN

FUNCTION Xrc_GetReferences( x )
   LOCAL a := {}, e, h, r, i
   FOR EACH e IN x[ "entries" ]
      h := Xrv_AsHandle( e[ "value" ] )
      IF h != NIL ; AAdd( a, h ) ; ENDIF
   NEXT
   FOR EACH r IN x[ "object_references" ]
      AAdd( a, r[ "handle" ] )
   NEXT
   ASort( a )
   r := {}
   FOR i := 1 TO Len( a )
      IF i == 1 .OR. a[ i ] != a[ i - 1 ] ; AAdd( r, a[ i ] ) ; ENDIF
   NEXT
RETURN r

FUNCTION Xrc_KnownKind( x ) ; RETURN Xrk_FromName( x[ "name" ] )

STATIC FUNCTION Xrs_New( cName, aEntries ) ; RETURN hb_Hash( "name", cName, "entries", aEntries )

STATIC FUNCTION Xrc_IsOpen( v ) ; RETURN Left( v, 1 ) == "{"
STATIC FUNCTION Xrc_EndsClose( v ) ; RETURN Right( v, 1 ) == "}"

FUNCTION Xrc_Sections( x )
   LOCAL aSec := {}, aStack := {}, e, v, nTop, lClose, top, c, sec, par, k, cName
   FOR EACH e IN x[ "entries" ]
      v := e[ "value" ]
      IF e[ "code" ] == 102 .AND. v[ "_kind" ] == "String" .AND. Xrc_IsOpen( v[ "value" ] )
         cName := v[ "value" ]
         DO WHILE Left( cName, 1 ) == "{"
            cName := SubStr( cName, 2 )
         ENDDO
         AAdd( aStack, { cName, {} } )
         LOOP
      ENDIF
      lClose := .F.
      IF e[ "code" ] == 102 .AND. v[ "_kind" ] == "String" .AND. Len( aStack ) > 0
         top := aStack[ Len( aStack ) ]
         c := v[ "value" ]
         lClose := c == "}" .OR. ( Xrc_EndsClose( c ) .AND. Lower( Left( c, Len( c ) - 1 ) ) == Lower( top[ 1 ] ) )
      ENDIF
      IF lClose
         top := aStack[ Len( aStack ) ]
         ASize( aStack, Len( aStack ) - 1 )
         sec := Xrs_New( top[ 1 ], top[ 2 ] )
         IF Len( aStack ) > 0
            par := aStack[ Len( aStack ) ][ 2 ]
            AAdd( par, Xre_String( 102, "{" + sec[ "name" ] ) )
            FOR EACH k IN sec[ "entries" ]
               AAdd( par, Ent_Clone( k ) )
            NEXT
            AAdd( par, Xre_String( 102, "}" ) )
         ENDIF
         AAdd( aSec, sec )
      ELSEIF Len( aStack ) > 0
         nTop := Len( aStack )
         AAdd( aStack[ nTop ][ 2 ], Ent_Clone( e ) )
      ENDIF
   NEXT
RETURN aSec

FUNCTION Xrc_Section( x, cName )
   LOCAL s
   FOR EACH s IN Xrc_Sections( x )
      IF Lower( s[ "name" ] ) == Lower( cName ) ; RETURN s ; ENDIF
   NEXT
RETURN NIL

PROCEDURE Xrc_SetSection( x, cName, aEntries )
   LOCAL cStart := "{" + cName, nStart := NIL, nEnd := NIL, nDepth := 0, i, e, v, aRep := {}, aNew := {}, k
   FOR i := 0 TO Len( x[ "entries" ] ) - 1
      e := x[ "entries" ][ i + 1 ]
      v := e[ "value" ]
      IF e[ "code" ] != 102 .OR. v[ "_kind" ] != "String"
         LOOP
      ENDIF
      IF Lower( v[ "value" ] ) == Lower( cStart )
         IF nStart == NIL
            nStart := i ; nDepth := 1
         ELSEIF nDepth > 0
            nDepth++
         ENDIF
      ELSEIF nStart != NIL .AND. Left( v[ "value" ], 1 ) == "{"
         nDepth++
      ELSEIF nStart != NIL .AND. ( v[ "value" ] == "}" .OR. ( Left( v[ "value" ], 1 ) != "{" .AND. Right( v[ "value" ], 1 ) == "}" ) )
         nDepth := Max( nDepth - 1, 0 )
         IF nDepth == 0
            nEnd := i
            EXIT
         ENDIF
      ENDIF
   NEXT
   AAdd( aRep, Xre_String( 102, cStart ) )
   FOR EACH k IN aEntries
      AAdd( aRep, k )
   NEXT
   AAdd( aRep, Xre_String( 102, "}" ) )
   IF nStart != NIL .AND. nEnd != NIL
      FOR i := 0 TO nStart - 1
         AAdd( aNew, x[ "entries" ][ i + 1 ] )
      NEXT
      FOR EACH k IN aRep
         AAdd( aNew, k )
      NEXT
      FOR i := nEnd + 1 TO Len( x[ "entries" ] ) - 1
         AAdd( aNew, x[ "entries" ][ i + 1 ] )
      NEXT
      x[ "entries" ] := aNew
   ELSE
      FOR EACH k IN aRep
         AAdd( x[ "entries" ], k )
      NEXT
   ENDIF
   Xrc_SynchronizeObjectReferences( x )
   x[ "entries_complete" ] := .T.
RETURN

FUNCTION Xrc_MeshTextureCoordinates( x )
   LOCAL aRes := {}, a := x[ "entries" ], i := 1, e, u, ev, ew, nV, nW
   DO WHILE i <= Len( a )
      e := a[ i ] ; i++
      IF e[ "code" ] != 43 ; LOOP ; ENDIF
      u := Xrv_AsDouble( e[ "value" ] )
      IF u == NIL ; LOOP ; ENDIF
      IF i > Len( a ) ; EXIT ; ENDIF
      ev := a[ i ] ; i++
      IF i > Len( a ) ; EXIT ; ENDIF
      ew := a[ i ] ; i++
      IF ev[ "code" ] == 44 .AND. ew[ "code" ] == 45
         nV := Xrv_AsDouble( ev[ "value" ] ) ; nW := Xrv_AsDouble( ew[ "value" ] )
         IF nV != NIL .AND. nW != NIL
            AAdd( aRes, { u, nV, nW } )
         ENDIF
      ENDIF
   ENDDO
RETURN aRes

PROCEDURE Xrc_SetMeshTextureCoordinates( x, aCoords )
   LOCAL a := {}, e, c
   FOR EACH e IN x[ "entries" ]
      IF ! ( e[ "code" ] >= 43 .AND. e[ "code" ] <= 45 ) ; AAdd( a, e ) ; ENDIF
   NEXT
   x[ "entries" ] := a
   FOR EACH c IN aCoords
      AAdd( a, Xre_Double( 43, c[ 1 ] ) )
      AAdd( a, Xre_Double( 44, c[ 2 ] ) )
      AAdd( a, Xre_Double( 45, c[ 3 ] ) )
   NEXT
   x[ "entries_complete" ] := .T.
RETURN

FUNCTION Xrc_AnnotationScaleHandle( x )
   LOCAL e
   FOR EACH e IN x[ "entries" ]
      IF e[ "code" ] == 340 ; RETURN Xrv_AsHandle( e[ "value" ] ) ; ENDIF
   NEXT
RETURN NIL

PROCEDURE Xrc_SetAnnotationScaleHandle( x, nHandle )
   LOCAL e, l := .F.
   FOR EACH e IN x[ "entries" ]
      IF e[ "code" ] == 340
         e[ "value" ] := Xrv_New( "Handle", nHandle ) ; l := .T. ; EXIT
      ENDIF
   NEXT
   IF ! l ; AAdd( x[ "entries" ], Xre_Handle( 340, nHandle ) ) ; ENDIF
   Xrc_SynchronizeObjectReferences( x )
   x[ "entries_complete" ] := .T.
RETURN

/* devuelve array de { handle, value } */
FUNCTION Xrc_LayerViewportOverrides( x, nValueCode )
   LOCAL aRes := {}, nVp := NIL, e
   FOR EACH e IN x[ "entries" ]
      IF e[ "code" ] == 335
         nVp := Xrv_AsHandle( e[ "value" ] )
      ELSEIF e[ "code" ] == nValueCode
         IF nVp != NIL
            AAdd( aRes, { nVp, Ent_Clone( e[ "value" ] ) } )
            nVp := NIL
         ENDIF
      ENDIF
   NEXT
RETURN aRes

PROCEDURE Xrc_SetLayerViewportOverride( x, cSection, nValueCode, nViewport, hValue )
   LOCAL lUpd := .F., i := 0, j, a := x[ "entries" ], e, h
   DO WHILE i < Len( a )
      IF a[ i + 1 ][ "code" ] == 335
         h := Xrv_AsHandle( a[ i + 1 ][ "value" ] )
         IF h != NIL .AND. h == nViewport
            FOR j := i + 1 TO Len( a ) - 1
               e := a[ j + 1 ]
               IF e[ "code" ] == 335 .OR. ( e[ "code" ] == 102 .AND. e[ "value" ][ "_kind" ] == "String" .AND. Xrc_EndsClose( e[ "value" ][ "value" ] ) )
                  EXIT
               ENDIF
               IF e[ "code" ] == nValueCode
                  e[ "value" ] := Ent_Clone( hValue ) ; lUpd := .T. ; EXIT
               ENDIF
            NEXT
            IF lUpd ; EXIT ; ENDIF
         ENDIF
      ENDIF
      i++
   ENDDO
   IF ! lUpd
      AAdd( a, Xre_String( 102, "{" + cSection ) )
      AAdd( a, Xre_Handle( 335, nViewport ) )
      AAdd( a, Xre_New( nValueCode, hValue ) )
      AAdd( a, Xre_String( 102, "}" ) )
   ENDIF
   x[ "entries_complete" ] := .T.
   Xrc_SynchronizeObjectReferences( x )
RETURN

PROCEDURE Xrc_SynchronizeObjectReferences( x )
   LOCAL aPrev := x[ "object_references" ], aNew := {}, e, h, n := 0, nKind, c
   FOR EACH e IN x[ "entries" ]
      c := e[ "code" ]
      IF c >= 330 .AND. c <= 369
         h := Xrv_AsHandle( e[ "value" ] )
         IF h != NIL
            n++
            IF n <= Len( aPrev )
               nKind := aPrev[ n ][ "kind" ]
            ELSEIF c <= 339 ; nKind := PRK_SOFT_POINTER
            ELSEIF c <= 349 ; nKind := PRK_HARD_POINTER
            ELSEIF c <= 359 ; nKind := PRK_SOFT_OWNERSHIP
            ELSE ; nKind := PRK_HARD_OWNERSHIP
            ENDIF
            AAdd( aNew, Ppr_NewRef( h, nKind ) )
         ENDIF
      ENDIF
   NEXT
   x[ "object_references" ] := aNew
   x[ "preserve_object_reference_stream" ] := .F.
RETURN
