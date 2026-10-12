/* Tests [extra]: dimstyle.rs no tiene #[test] en Rust */
#include "ocx.ch"
PROCEDURE T_CodecTables6()
   LOCAL d
   d := Dst_Standard() ; Chk( Dst_IsStandard( d ) .AND. d[ "dimdli" ] == 3.75 .AND. d[ "dimlwd" ] == -2 .AND. d[ "dimpost" ] == "<>" .AND. d[ "dimtxsty" ] == "Standard" .AND. d[ "dimdsep" ] == 46, "[extra] dimstyle: valores por defecto de new" )
   Chk( Abs( d[ "dimjogang" ] - OCX_PI / 4.0 ) < 0.0000000001 .AND. d[ "dimclrd_true_color" ] == NIL .AND. Hd_IsNull( d[ "dimblk" ] ) .AND. d[ "dimaltf" ] == 25.4 .AND. d[ "dimatfit" ] == 3, "[extra] dimstyle: jogang, option None y handles nulos" )
   d := Dst_DxfDefaults( "X" ) ; Chk( d[ "name" ] == "X" .AND. ! Dst_IsStandard( d ) .AND. d[ "dimdli" ] == 0.38 .AND. d[ "dimtad" ] == 0 .AND. d[ "dimtih" ] .AND. d[ "dimdec" ] == 4 .AND. d[ "dimtolj" ] == 1 .AND. d[ "dimexo" ] == 0.0625, "[extra] dimstyle: dxf_defaults aplica overrides" )
   Chk( d[ "dimscale" ] == 1.0 .AND. d[ "dimasz" ] == 0.18 .AND. d[ "dimlunit" ] == 2, "[extra] dimstyle: dxf_defaults conserva el resto de new" )
RETURN
