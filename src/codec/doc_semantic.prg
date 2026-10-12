/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/doc_semantic.prg
   Origen Rust: opencadcodec/src/document/semantic_inventory.rs (499 lineas, 1 #[test]). Licencia del original: MPL-2.0.
   Prefijo Sem_. SEMANTIC_INVENTORY_VERSION = 1 (funcion Sem_Version()).
   Los enums se portan como hashes con "kind":
     SemanticReferenceV1: { "resolved" => .T., "node" => nodo } | { "resolved" => .F. }
     SemanticNodeV1: { "kind" => "Document"|"Entity"|"Object"|"TableRecord", "value" => entidad|objeto|{ "table" => nombre, "record" => reg } }
     SemanticPartV1: { "part" => "Header"|"TableRecord"|"Class"|"Entity"|"Object"|"SummaryInfo"|"Preview"|"Relationship"|"NonEntityExtendedData", ... }
       Relationship: "kind" (Ownership|ExtensionDictionary|Reactor), "source", "target".
       NonEntityExtendedData: "owner", "application" (AppId|NIL), "values" (array de XDataValue o NIL).
     SemanticEntityV1: { "typed" => .T., "entity" } | { "typed" => .F., "type_name", "common" }; igual para objetos ("object").
   El visitante es un codeblock {| hPart | ... }. Orden de recorrido = el del Rust (las tablas en su orden de insercion).
   DIFERENCIA DOCUMENTADA: el Rust decodifica los bloques EED de DWG con io::dwg::eed_codec::decode_values (DWG, aparcado).
   Aqui se inyecta con Sem_SetEedDecoder( {| cBytes, lWide, bLayerName | aValues|NIL } ); sin decodificador los values son NIL.
   El test Rust (inventory_exposes_private_relationships_without_raw_bytes) se porta sin el tramo EED; el tramo EED queda PENDIENTE de eed_codec.
----------------------------------------------------------------------------*/
#include "ocx.ch"

STATIC s_bEedDecoder := NIL

FUNCTION Sem_Version() ; RETURN 1
PROCEDURE Sem_SetEedDecoder( b ) ; s_bEedDecoder := b ; RETURN

STATIC FUNCTION Sem_Tables() ; RETURN { { "layers", "Layer" }, { "line_types", "LineType" }, { "text_styles", "TextStyle" }, { "block_records", "BlockRecord" }, ;
   { "dim_styles", "DimStyle" }, { "app_ids", "AppId" }, { "views", "View" }, { "vports", "VPort" }, { "ucss", "Ucs" }, { "vx_table", "Vx" } }

STATIC FUNCTION Sem_Ref( d, nHandle )
   LOCAL n := Sem_Resolve( d, nHandle )
RETURN iif( n == NIL, hb_Hash( "resolved", .F. ), hb_Hash( "resolved", .T., "node", n ) )

/* SemanticInventoryV1::resolve: nodo o NIL */
FUNCTION Sem_Resolve( d, nHandle )
   LOCAL e, t, r
   IF Hd_IsNull( nHandle ) ; RETURN hb_Hash( "kind", "Document", "value", NIL ) ; ENDIF
   e := Doc_GetEntity( d, nHandle )
   IF e != NIL ; RETURN hb_Hash( "kind", "Entity", "value", e ) ; ENDIF
   IF hb_HHasKey( d[ "objects" ], nHandle ) ; RETURN hb_Hash( "kind", "Object", "value", d[ "objects" ][ nHandle ] ) ; ENDIF
   FOR EACH t IN Sem_Tables()
      FOR EACH r IN Tb_Values( d[ t[ 1 ] ] )
         IF r[ "handle" ] == nHandle ; RETURN hb_Hash( "kind", "TableRecord", "value", hb_Hash( "table", t[ 2 ], "record", r ) ) ; ENDIF
      NEXT
   NEXT
RETURN NIL

STATIC PROCEDURE Sem_Rel( d, bV, cKind, hSource, nTarget )
   Eval( bV, hb_Hash( "part", "Relationship", "kind", cKind, "source", hSource, "target", Sem_Ref( d, nTarget ) ) )
RETURN

STATIC FUNCTION Sem_NodeRef( cKind, xVal ) ; RETURN hb_Hash( "resolved", .T., "node", hb_Hash( "kind", cKind, "value", xVal ) )

FUNCTION Sem_ClassifyEntity( e )
   IF e[ "_type" ] == "UNKNOWN" ; RETURN hb_Hash( "typed", .F., "type_name", e[ "dxf_name" ], "common", e[ "common" ] ) ; ENDIF
RETURN hb_Hash( "typed", .T., "entity", e )

FUNCTION Sem_ClassifyObject( o )
   IF hb_HHasKey( o, "_type" ) .AND. o[ "_type" ] == "Unknown" ; RETURN hb_Hash( "typed", .F., "type_name", o[ "type_name" ] ) ; ENDIF
RETURN hb_Hash( "typed", .T., "object", o )

PROCEDURE Sem_Visit( d, bV )
   LOCAL t, r, c, e, x, k, nOwner, aRecs, rec, cApp, hApp, lRaw, aVals, lWide, hSrc, p, a, blk
   Eval( bV, hb_Hash( "part", "Header", "header", d[ "header" ] ) )
   FOR EACH t IN Sem_Tables()
      FOR EACH r IN Tb_Values( d[ t[ 1 ] ] ) ; Eval( bV, hb_Hash( "part", "TableRecord", "table", t[ 2 ], "record", r ) ) ; NEXT
   NEXT
   FOR EACH c IN Dcc_Entries( d[ "classes" ] ) ; Eval( bV, hb_Hash( "part", "Class", "class", c ) ) ; NEXT
   FOR EACH e IN d[ "entities" ]
      Eval( bV, hb_Hash( "part", "Entity", "entity", Sem_ClassifyEntity( e ) ) )
      hSrc := Sem_NodeRef( "Entity", e )
      Sem_Rel( d, bV, "Ownership", hSrc, e[ "common" ][ "owner_handle" ] )
      IF e[ "common" ][ "xdictionary_handle" ] != NIL ; Sem_Rel( d, bV, "ExtensionDictionary", hSrc, e[ "common" ][ "xdictionary_handle" ] ) ; ENDIF
      FOR EACH x IN e[ "common" ][ "reactors" ] ; Sem_Rel( d, bV, "Reactor", hSrc, x ) ; NEXT
   NEXT
   FOR EACH k IN hb_HKeys( d[ "objects" ] )
      Eval( bV, hb_Hash( "part", "Object", "object", Sem_ClassifyObject( d[ "objects" ][ k ] ) ) )
      nOwner := Doc_ObjectOwner( d, k )
      IF nOwner != NIL ; Sem_Rel( d, bV, "Ownership", Sem_NodeRef( "Object", d[ "objects" ][ k ] ), nOwner ) ; ENDIF
   NEXT
   Eval( bV, hb_Hash( "part", "SummaryInfo", "summary_info", d[ "summary_info" ] ) )
   IF d[ "preview" ] != NIL ; Eval( bV, hb_Hash( "part", "Preview", "preview", d[ "preview" ] ) ) ; ENDIF
   FOR EACH k IN hb_HKeys( d[ "xdic_by_handle" ] ) ; Sem_Rel( d, bV, "ExtensionDictionary", Sem_Ref( d, k ), d[ "xdic_by_handle" ][ k ] ) ; NEXT
   FOR EACH k IN hb_HKeys( d[ "reactors_by_handle" ] )
      FOR EACH x IN d[ "reactors_by_handle" ][ k ] ; Sem_Rel( d, bV, "Reactor", Sem_Ref( d, k ), x ) ; NEXT
   NEXT
   lWide := iif( d[ "dwg_source_version" ] != NIL, d[ "dwg_source_version" ], d[ "version" ] ) >= 1021
   FOR EACH k IN hb_HKeys( d[ "eed_by_handle" ] )
      FOR EACH rec IN d[ "eed_by_handle" ][ k ]
         hApp := NIL
         FOR EACH a IN Tb_Values( d[ "app_ids" ] )
            IF a[ "handle" ] == rec[ 1 ] ; hApp := a ; EXIT
            ENDIF
         NEXT
         aVals := NIL
         IF s_bEedDecoder != NIL
            blk := {| nH | Sem_LayerName( d, nH ) }
            aVals := Eval( s_bEedDecoder, rec[ 2 ], lWide, blk )
         ENDIF
         Eval( bV, hb_Hash( "part", "NonEntityExtendedData", "owner", Sem_Ref( d, k ), "application", hApp, "values", aVals ) )
      NEXT
   NEXT
   FOR EACH k IN hb_HKeys( d[ "object_xdata" ] )
      aRecs := Xd_Records( d[ "object_xdata" ][ k ] )
      FOR EACH rec IN aRecs
         cApp := Xr_ApplicationName( rec ) ; hApp := Tb_Get( d[ "app_ids" ], cApp ) ; lRaw := .F.
         IF hApp != NIL .AND. hb_HHasKey( d[ "eed_by_handle" ], k )
            FOR EACH p IN d[ "eed_by_handle" ][ k ]
               IF p[ 1 ] == hApp[ "handle" ] ; lRaw := .T. ; EXIT
               ENDIF
            NEXT
         ENDIF
         IF ! lRaw
            Eval( bV, hb_Hash( "part", "NonEntityExtendedData", "owner", Sem_Ref( d, k ), "application", hApp, "values", Ent_Clone( Xr_Values( rec ) ) ) )
         ENDIF
      NEXT
   NEXT
RETURN

STATIC FUNCTION Sem_LayerName( d, nH )
   LOCAL l
   FOR EACH l IN Tb_Values( d[ "layers" ] )
      IF l[ "handle" ] == nH ; RETURN l[ "name" ]
      ENDIF
   NEXT
RETURN NIL
