/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/obj_group.prg
   Origen Rust: opencadcodec/src/objects/group.rs (289 lineas, 12 tests) y block_visibility.rs (115 lineas, sin tests; [extra]). Licencia del original: MPL-2.0.
   Prefijos: Grp_ (Group), Bvp_ (BlockVisibilityParameter), Bev_ (BlockEvalValue = { BEV_*, xValue }), Bvs_ (BlockVisibilityState), Bpc_/Bpi_ (conexion / property info).
   visit_handles_mut: el bloque recibe un handle y DEVUELVE el handle nuevo (los enteros de Harbour no son referencias); se asigna el resultado en el sitio.
   Los builders with_* mutan y devuelven el mismo hash. Option<Handle> de get -> NIL.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Grp_New( cName )
RETURN hb_Hash( "_type", "Group", "handle", Hd_Null(), "owner", Hd_Null(), "name", cName, "unnamed", .F., "description", "", "entities", {}, "selectable", .T. )
FUNCTION Grp_ObjectType() ; RETURN "GROUP"
FUNCTION Grp_Unnamed() ; LOCAL g := Grp_New( "*A" ) ; g[ "unnamed" ] := .T. ; RETURN g
FUNCTION Grp_Default() ; RETURN Grp_Unnamed()
FUNCTION Grp_WithDescription( cName, cDesc ) ; LOCAL g := Grp_New( cName ) ; g[ "description" ] := cDesc ; RETURN g
FUNCTION Grp_IsUnnamed( g ) ; RETURN g[ "unnamed" ]
PROCEDURE Grp_AddEntity( g, h )
   IF AScan( g[ "entities" ], h ) == 0 ; AAdd( g[ "entities" ], h ) ; ENDIF
RETURN
PROCEDURE Grp_AddEntities( g, a )
   LOCAL h
   FOR EACH h IN a
      Grp_AddEntity( g, h )
   NEXT
RETURN
FUNCTION Grp_RemoveEntity( g, h )
   LOCAL n := AScan( g[ "entities" ], h )
   IF n > 0 ; hb_ADel( g[ "entities" ], n, .T. ) ; RETURN .T. ; ENDIF
RETURN .F.
PROCEDURE Grp_Clear( g ) ; ASize( g[ "entities" ], 0 ) ; RETURN
FUNCTION Grp_Len( g ) ; RETURN Len( g[ "entities" ] )
FUNCTION Grp_IsEmpty( g ) ; RETURN Len( g[ "entities" ] ) == 0
FUNCTION Grp_Contains( g, h ) ; RETURN AScan( g[ "entities" ], h ) > 0
FUNCTION Grp_Get( g, n ) ; RETURN iif( n >= 0 .AND. n < Len( g[ "entities" ] ), g[ "entities" ][ n + 1 ], NIL )
PROCEDURE Grp_SetSelectable( g, l ) ; g[ "selectable" ] := l ; RETURN
FUNCTION Grp_WithDesc( g, c ) ; g[ "description" ] := c ; RETURN g
FUNCTION Grp_WithSelectable( g, l ) ; g[ "selectable" ] := l ; RETURN g
FUNCTION Grp_WithEntity( g, h ) ; Grp_AddEntity( g, h ) ; RETURN g
FUNCTION Grp_WithEntities( g, a ) ; Grp_AddEntities( g, a ) ; RETURN g

FUNCTION Bev_None() ; RETURN { BEV_NONE, NIL }
FUNCTION Bpc_New() ; RETURN hb_Hash( "code", 0, "name", "" )
FUNCTION Bpi_New() ; RETURN hb_Hash( "connections", {} )
FUNCTION Bvs_New() ; RETURN hb_Hash( "name", "", "visible_blocks", {}, "visible_params", {} )

FUNCTION Bvp_New()
RETURN hb_Hash( "_type", "BlockVisibilityParameter", "handle", Hd_Null(), "owner", Hd_Null(), "eval_parent_id", 0, "eval_major", 0, "eval_minor", 0, "eval_value_code", 0, "eval_value", Bev_None(), ;
   "eval_node_id", 0, "element_name", "", "element_major", 0, "element_minor", 0, "element_eed_1071", 0, "show_properties", .F., "chain_actions", .F., "name", "", "description", "", ;
   "def_point", Vc3_Zero(), "property_info", { Bpi_New(), Bpi_New() }, "property_info_count", 0, "is_initialized", .F., "unknown_bool", .F., "all_blocks", {}, "states", {} )

PROCEDURE Bvp_VisitHandlesMut( p, bVisit )
   LOCAL i, s
   p[ "handle" ] := Eval( bVisit, p[ "handle" ] )
   p[ "owner" ] := Eval( bVisit, p[ "owner" ] )
   IF p[ "eval_value" ][ 1 ] == BEV_HANDLE ; p[ "eval_value" ][ 2 ] := Eval( bVisit, p[ "eval_value" ][ 2 ] ) ; ENDIF
   FOR i := 1 TO Len( p[ "all_blocks" ] )
      p[ "all_blocks" ][ i ] := Eval( bVisit, p[ "all_blocks" ][ i ] )
   NEXT
   FOR EACH s IN p[ "states" ]
      FOR i := 1 TO Len( s[ "visible_blocks" ] )
         s[ "visible_blocks" ][ i ] := Eval( bVisit, s[ "visible_blocks" ][ i ] )
      NEXT
      FOR i := 1 TO Len( s[ "visible_params" ] )
         s[ "visible_params" ][ i ] := Eval( bVisit, s[ "visible_params" ][ i ] )
      NEXT
   NEXT
RETURN
