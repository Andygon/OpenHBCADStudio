/* Tests [extra]: HeaderVariables (document.rs) no tiene #[test] propios en Rust */
#include "ocx.ch"
PROCEDURE T_CodecDocument1()
   LOCAL h := Hdr_New()
   Chk( Len( h ) == 282, "[extra] header: 282 campos como en la struct Rust" )
   Chk( h[ "associate_dimensions" ] .AND. h[ "current_layer_name" ] == "0" .AND. h[ "tree_depth" ] == 3020 .AND. h[ "multiline_style" ] == "Standard" .AND. h[ "current_linetype_name" ] == "ByLayer", "[extra] header: valores por defecto conocidos" )
   h[ "create_date_julian" ] := 2451545.5
   Chk( Hdr_UniversalCreateOrLocal( h ) == 2451545.5, "[extra] header: universal_create cae a la fecha local" )
   h[ "universal_create_date_julian" ] := 2451546.5 ; h[ "update_date_julian" ] := 3.0
   Chk( Hdr_UniversalCreateOrLocal( h ) == 2451546.5 .AND. Hdr_UniversalUpdateOrLocal( h ) == 3.0, "[extra] header: universal_create y update_or_local" )
RETURN
