/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/obj_sortents.prg
   Origen Rust: opencadcodec/src/objects/sort_entities_table.rs (566 lineas, 22 tests). Licencia del original: MPL-2.0.
   Prefijos: Sot_ (SortEntitiesTable), Sen_ (SortEntsEntry).
   entries = array de hashes { entity_handle, sort_handle }; entry_map = hash handle -> indice base 0 (como Rust).
   saturating_sub/add sobre u64: Handle < 1 se reduce con .max(1) igual que Rust; saturating_add no se alcanza en rangos reales.
   sorted_entries: ordenacion estable por sort_handle (sort_by_key de Rust es estable).
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Sot_ObjectName() ; RETURN "SORTENTSTABLE"
FUNCTION Sot_SubclassMarker() ; RETURN "AcDbSortentsTable"
FUNCTION Sot_DictionaryKey() ; RETURN "ACAD_SORTENTS"

FUNCTION Sen_New( nEntity, nSort ) ; RETURN hb_Hash( "entity_handle", nEntity, "sort_handle", nSort )

FUNCTION Sot_New()
RETURN hb_Hash( "_type", "SortEntitiesTable", "handle", Hd_Null(), "owner_handle", Hd_Null(), "block_owner_handle", Hd_Null(), ;
   "entries", {}, "entry_map", hb_Hash(), "raw_dxf_codes", NIL, "raw_dxf_version", NIL )

FUNCTION Sot_ForBlock( nBlock )
   LOCAL t := Sot_New()
   t[ "block_owner_handle" ] := nBlock
RETURN t

FUNCTION Sot_Len( t ) ; RETURN Len( t[ "entries" ] )
FUNCTION Sot_IsEmpty( t ) ; RETURN Len( t[ "entries" ] ) == 0

FUNCTION Sot_AddEntry( t, nEntity, nSort )
   LOCAL nOld, nIdx
   IF hb_HHasKey( t[ "entry_map" ], nEntity )
      nIdx := t[ "entry_map" ][ nEntity ]
      nOld := t[ "entries" ][ nIdx + 1 ][ "sort_handle" ]
      t[ "entries" ][ nIdx + 1 ][ "sort_handle" ] := nSort
      RETURN nOld
   ENDIF
   nIdx := Len( t[ "entries" ] )
   AAdd( t[ "entries" ], Sen_New( nEntity, nSort ) )
   t[ "entry_map" ][ nEntity ] := nIdx
RETURN NIL

FUNCTION Sot_RemoveEntry( t, nEntity )
   LOCAL nIdx, e, nLast
   IF ! hb_HHasKey( t[ "entry_map" ], nEntity )
      RETURN NIL
   ENDIF
   nIdx := t[ "entry_map" ][ nEntity ]
   hb_HDel( t[ "entry_map" ], nEntity )
   e := t[ "entries" ][ nIdx + 1 ]
   nLast := Len( t[ "entries" ] )
   t[ "entries" ][ nIdx + 1 ] := t[ "entries" ][ nLast ]
   ASize( t[ "entries" ], nLast - 1 )
   IF nIdx < Len( t[ "entries" ] )
      t[ "entry_map" ][ t[ "entries" ][ nIdx + 1 ][ "entity_handle" ] ] := nIdx
   ENDIF
RETURN e

FUNCTION Sot_GetSortHandle( t, nEntity )
   IF hb_HHasKey( t[ "entry_map" ], nEntity )
      RETURN t[ "entries" ][ t[ "entry_map" ][ nEntity ] + 1 ][ "sort_handle" ]
   ENDIF
RETURN NIL

FUNCTION Sot_Contains( t, nEntity ) ; RETURN hb_HHasKey( t[ "entry_map" ], nEntity )
FUNCTION Sot_Entries( t ) ; RETURN t[ "entries" ]

FUNCTION Sot_SortedEntries( t )
   LOCAL a := {}, i
   FOR i := 1 TO Len( t[ "entries" ] )
      AAdd( a, { t[ "entries" ][ i ][ "sort_handle" ], i, t[ "entries" ][ i ] } )
   NEXT
   ASort( a,,, {| x, y | x[ 1 ] < y[ 1 ] .OR. ( x[ 1 ] == y[ 1 ] .AND. x[ 2 ] < y[ 2 ] ) } )
   FOR i := 1 TO Len( a )
      a[ i ] := a[ i ][ 3 ]
   NEXT
RETURN a

PROCEDURE Sot_Clear( t )
   ASize( t[ "entries" ], 0 )
   hb_HClear( t[ "entry_map" ] )
RETURN

FUNCTION Sot_SendToBack( t, nEntity )
   LOCAL nMin := 256, i, nNew
   IF Len( t[ "entries" ] ) > 0
      nMin := t[ "entries" ][ 1 ][ "sort_handle" ]
      FOR i := 2 TO Len( t[ "entries" ] )
         nMin := Min( nMin, t[ "entries" ][ i ][ "sort_handle" ] )
      NEXT
   ENDIF
   nNew := Max( iif( nMin > 0, nMin - 1, 0 ), 1 )
   Sot_AddEntry( t, nEntity, nNew )
RETURN nNew

FUNCTION Sot_BringToFront( t, nEntity )
   LOCAL nMax := 0, i, nNew
   FOR i := 1 TO Len( t[ "entries" ] )
      nMax := Max( nMax, t[ "entries" ][ i ][ "sort_handle" ] )
   NEXT
   nNew := nMax + 1
   Sot_AddEntry( t, nEntity, nNew )
RETURN nNew

FUNCTION Sot_MoveAbove( t, nEntity, nTarget )
   LOCAL nTs := Sot_GetSortHandle( t, nTarget ), nNew
   IF nTs == NIL ; RETURN NIL ; ENDIF
   nNew := nTs + 1
   Sot_AddEntry( t, nEntity, nNew )
RETURN nNew

FUNCTION Sot_MoveBelow( t, nEntity, nTarget )
   LOCAL nTs := Sot_GetSortHandle( t, nTarget ), nNew
   IF nTs == NIL ; RETURN NIL ; ENDIF
   nNew := Max( iif( nTs > 0, nTs - 1, 0 ), 1 )
   Sot_AddEntry( t, nEntity, nNew )
RETURN nNew

PROCEDURE Sot_RebuildMap( t )
   LOCAL i
   hb_HClear( t[ "entry_map" ] )
   FOR i := 1 TO Len( t[ "entries" ] )
      t[ "entry_map" ][ t[ "entries" ][ i ][ "entity_handle" ] ] := i - 1
   NEXT
RETURN

FUNCTION Sot_EffectiveSortHandle( t, nEntity )
   LOCAL n := Sot_GetSortHandle( t, nEntity )
RETURN iif( n == NIL, nEntity, n )
