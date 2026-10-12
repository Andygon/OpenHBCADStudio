/* Tests de CadDocument parte 4 (xrecords y extension dictionaries) - todos [extra] */
#include "ocx.ch"
PROCEDURE T_DocXrec()
   LOCAL d, e, h, hd, hr, x, m, xr, hm, hdd, t
   d := Doc_New() ; e := Eln_New() ; h := Doc_AddEntity( d, e )
   Chk( Doc_ExtensionDictionaryHandle( d, h ) == NIL .AND. Doc_Xrecord( d, h, "K" ) == NIL, "[extra] sin ext dict" )
   hd := Doc_EnsureExtensionDictionary( d, h )
   Chk( hd > 0 .AND. e[ "common" ][ "xdictionary_handle" ] == hd .AND. d[ "xdic_by_handle" ][ h ] == hd .AND. Doc_EnsureExtensionDictionary( d, h ) == hd .AND. Doc_ObjectOwner( d, hd ) == h, "[extra] ensure_extension_dictionary + object_owner" )
   hr := Doc_EnsureXrecord( d, h, "Key" ) ; x := Doc_Xrecord( d, h, "KEY" )
   Chk( x != NIL .AND. x[ "handle" ] == hr .AND. x[ "owner" ] == hd .AND. x[ "name" ] == "Key" .AND. Doc_EnsureXrecord( d, h, "key" ) == hr, "[extra] ensure_xrecord idempotente, clave sin mayusculas" )
   x[ "name" ] := "zz" ; Doc_ResolveXrecordNames( d ) ; Chk( x[ "name" ] == "Key", "[extra] resolve_xrecord_names" )
   Chk( Doc_ViewportAnnotationScale( d, h ) == NIL, "[extra] annotation scale ausente" )
   Doc_SetViewportAnnotationScale( d, h, 77 ) ; Chk( Doc_ViewportAnnotationScale( d, h ) == 77, "[extra] set/get annotation scale" )
   Chk( Doc_ObjectOwner( d, 999999 ) == NIL .AND. Doc_ExtensionDictionaryHandle( d, 424242 ) == NIL, "[extra] handle inexistente" )
   /* material checker + advanced */
   xr := { Xre_String( 301, "checker" ), Xre_String( 300, "Map1" ), Xre_Int32( 420, 255 ), Xre_String( 300, "Map2" ), Xre_Int32( 420, 7 ), Xre_String( 300, "Mapper" ), Xre_Int32( 420, 9 ) }
   t := Doc_MaterialCheckerTexture( xr ) ; Chk( t != NIL .AND. t[ "color1" ][ "rgb" ] == 255 .AND. t[ "color2" ][ "rgb" ] == 7 .AND. t[ "color1" ][ "flag" ] == 1, "[extra] material_checker_texture" )
   Chk( Doc_MaterialCheckerTexture( { Xre_String( 301, "x" ) } ) == NIL .AND. Doc_MaterialCheckerTexture( { Xre_String( 301, "Checker" ), Xre_String( 300, "Map1" ), Xre_Int32( 420, 1 ) } ) == NIL, "[extra] checker sin 2 colores / sin checker" )
   m := Mat_Default() ; hm := Doc_AllocateHandle( d ) ; m[ "handle" ] := hm ; d[ "objects" ][ hm ] := m
   hdd := Doc_EnsureExtensionDictionary( d, hm ) ; m[ "xdictionary_handle" ] := hdd
   x := Doc_EnsureXrecord( d, hm, "ADVMATERIAL" ) ; d[ "objects" ][ x ][ "entries" ] := { Xre_Double( 460, 50.0 ), Xre_Int16( 270, 3 ), Xre_Bool( 290, .T. ) }
   x := Doc_EnsureXrecord( d, hm, "DIFFUSE" ) ; d[ "objects" ][ x ][ "entries" ] := xr
   Doc_ResolveXrecordBackedProperties( d )
   Chk( m[ "advanced_data_present" ] .AND. Near( m[ "color_bleed_scale" ], 0.5, 0.000001 ) .AND. m[ "luminance_mode" ] == 3 .AND. m[ "two_sided_material" ] .AND. m[ "diffuse_map" ][ "source" ] == 2 .AND. m[ "diffuse_map" ][ "texture" ][ "color2" ][ "rgb" ] == 7, "[extra] resolve_xrecord_backed_properties" )
RETURN
