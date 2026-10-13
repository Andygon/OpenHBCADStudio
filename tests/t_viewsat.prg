/* [extra] Fase 2 / B13: lector SAT reducido (vw_sat.prg). Sin equivalente #[test] en Rust. */
#include "ocx.ch"

STATIC FUNCTION Vs_Text()
   LOCAL c := "700 0 1 0" + Chr( 10 ) + "@8 ACIS 7.0 @3 Foo @24 Mon Jan 01 00:00:00 2024" + Chr( 10 ) + "1 9.9999999999999995e-007 1e-010" + Chr( 10 )
   c += "-0 body $-1 -1 $-1 $1 $-1 $-1 F #" + Chr( 10 )
   c += "-1 lump $-1 -1 $-1 $-1 $2 $0 #" + Chr( 10 )
   c += "-2 shell $-1 -1 $-1 $-1 $-1 $3 $-1 $1 #" + Chr( 10 )
   c += "-3 face $-1 -1 $-1 $-1 $2 $-1 $4 forward single #" + Chr( 10 )
   c += "-4 plane-surface $-1 -1 $-1 0 0 0 0 0 1 1 0 0 forward_v I I I I #" + Chr( 10 )
   c += "End-of-ACIS-data" + Chr( 10 )
RETURN c

PROCEDURE T_ViewSat()
   LOCAL sat := Sat_Parse( Vs_Text() ), e, c, r
   Chk( sat != NIL .AND. sat[ "version" ] == 700, "[extra] sat: cabecera, version 700" )
   Chk( Len( sat[ "records" ] ) == 5, "[extra] sat: 5 registros" )
   Chk( sat[ "records" ][ 4 ][ "type" ] == "face" .AND. sat[ "records" ][ 4 ][ "i" ] == 3, "[extra] sat: tipo e indice del registro 3 (face)" )
   Chk( Len( Sat_Find( sat, "plane-surface" ) ) == 1 .AND. Sat_Find( sat, "plane-surface" )[ 1 ] == 4, "[extra] sat: Sat_Find localiza la superficie plana" )
   r := Sat_Rec( sat, Sat_Ptr( sat[ "records" ][ 4 ][ "tok" ][ 7 ] ) )
   Chk( r != NIL .AND. r[ "type" ] == "plane-surface", "[extra] sat: el puntero de la cara lleva a su superficie" )
   Chk( Sat_Ptr( "$-1" ) == -1 .AND. Sat_Rec( sat, -1 ) == NIL .AND. Sat_Ptr( "forward" ) == NIL, "[extra] sat: $-1 y tokens que no son puntero" )
   Chk( Sat_Parse( "hola" ) == NIL .AND. Sat_Parse( "" ) == NIL, "[extra] sat: texto invalido da NIL" )
   e := Eun_New( "3DSOLID" )
   e[ "raw_dxf_codes" ] := { { 70, 1 }, { 1, "700 0 1 0" }, { 1, "@8 ACIS 7.0 @3 Foo @24 Mon Jan 01" }, { 3, " 00:00:00 2024" }, { 1, "1 1 1" }, { 1, "-0 body $-1 -1 $-1 $-1 $-1 $-1 F #" }, { 1, "End-of-ACIS-data" } }
   c := Sat_FromEntity( e )
   Chk( Left( c, 9 ) == "700 0 1 0" .AND. "00:00:00 2024" $ c, "[extra] sat: Sat_FromEntity une los codigos 1 y 3" )
   Chk( Len( Sat_Parse( c )[ "records" ] ) == 1, "[extra] sat: la entidad se parsea a 1 registro" )
RETURN
