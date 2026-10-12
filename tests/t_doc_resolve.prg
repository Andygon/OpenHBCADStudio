/* Tests de CadDocument parte 6 (resolve_references, resolve_book_colors) - todos [extra] */
#include "ocx.ch"
PROCEDURE T_DocResolve()
   LOCAL d, e, h, o, l, k, n, bc, hBc
   d := Doc_New() ; e := Eln_New() ; Doc_AddEntity( d, e )
   l := Lyr_New( "A" ) ; Tb_Add( d[ "layers" ], l )
   Doc_ResolveReferences( d )
   Chk( l[ "handle" ] > 0 .AND. d[ "header" ][ "handle_seed" ] >= d[ "next_handle" ], "[extra] resolve: handle de capa y seed" )
   Chk( e[ "common" ][ "entity_mode" ] == 2 .AND. e[ "common" ][ "owner_handle" ] == d[ "header" ][ "model_space_block_handle" ], "[extra] resolve: owner y entity_mode modelo" )
   /* objeto con handle nulo en clave 0 */
   o := Dic_New() ; d[ "objects" ][ 0 ] := o ; Doc_ResolveReferences( d )
   Chk( ! hb_HHasKey( d[ "objects" ], 0 ) .AND. o[ "handle" ] > 0 .AND. d[ "objects" ][ o[ "handle" ] ] == o, "[extra] resolve: clave 0 renumerada" )
   /* handle de objeto choca con una capa: se renumera y se remapean referencias */
   h := l[ "handle" ] ; o := Dic_New() ; o[ "handle" ] := h ; o[ "owner" ] := 5 ; d[ "objects" ][ h ] := o
   k := Dic_New() ; k[ "handle" ] := 99999 ; k[ "owner" ] := 5 ; Dic_AddEntry( k, "X", h ) ; d[ "objects" ][ 99999 ] := k
   Doc_ResolveReferences( d )
   n := o[ "handle" ]
   Chk( n != h .AND. d[ "objects" ][ n ] == o .AND. k[ "entries" ][ 1 ][ 2 ] == n, "[extra] resolve: remapeo por colision" )
   /* ACAD primero en app_ids */
   d := Doc_New()
   Chk( Upper( Tb_Values( d[ "app_ids" ] )[ 1 ][ "name" ] ) == "ACAD", "[extra] app_ids: ACAD primero por defecto" )
   /* book colors */
   d := Doc_New() ; hBc := Bkc_New() ; hBc[ "book_name" ] := "PANTONE" ; hBc[ "color_name" ] := "Rojo" ; hBc[ "handle" ] := 7777 ; d[ "objects" ][ 7777 ] := hBc
   e := Eln_New() ; e[ "common" ][ "color_name" ] := "pantone$ROJO" ; Doc_AddEntity( d, e )
   Doc_ResolveBookColors( d )
   Chk( e[ "common" ][ "color_book_handle" ] == 7777 .AND. e[ "common" ][ "color_name" ] == "PANTONE$Rojo", "[extra] resolve_book_colors por nombre" )
   bc := Eln_New() ; Doc_AddEntity( d, bc ) ; Doc_ResolveBookColors( d ) ; Chk( bc[ "common" ][ "color_book_handle" ] == NIL, "[extra] sin libro no cambia" )
RETURN
