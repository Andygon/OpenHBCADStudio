/* Tests [extra]: appid, vx, ucs y layer no tienen #[test] en Rust */
#include "ocx.ch"
PROCEDURE T_CodecTables2()
   LOCAL a, l, u, t, v
   a := Aid_Acad() ; Chk( a[ "name" ] == "ACAD" .AND. Aid_IsStandard( a ) .AND. ! Aid_IsStandard( Aid_New( "Foo" ) ) .AND. Hd_IsNull( a[ "handle" ] ), "[extra] appid: acad y is_standard" )
   l := Lyr_Layer0() ; Chk( l[ "name" ] == "0" .AND. Lyr_IsStandard( l ) .AND. l[ "line_type" ] == "Continuous" .AND. l[ "is_plottable" ] .AND. Lyr_IsVisible( l ), "[extra] layer: layer_0 y valores por defecto" )
   Lyr_Freeze( l ) ; a := Lyr_IsFrozen( l ) .AND. ! Lyr_IsVisible( l ) ; Lyr_Thaw( l ) ; Lyr_TurnOff( l ) ; v := Lyr_IsOff( l ) .AND. ! Lyr_IsVisible( l ) ; Lyr_TurnOn( l )
   Lyr_Lock( l ) ; t := Lyr_IsLocked( l ) ; Lyr_Unlock( l )
   Chk( a .AND. v .AND. t .AND. ! Lyr_IsLocked( l ) .AND. ! Lyr_IsFrozen( l ) .AND. ! Lyr_IsOff( l ), "[extra] layer: freeze/thaw/lock/off y visibilidad" )
   l := Lyr_WithColor( "Muros", Cl_Index( 1 ) ) ; Chk( l[ "name" ] == "Muros" .AND. Cl_Eq( l[ "color" ], Cl_Index( 1 ) ) .AND. ! Lyr_IsStandard( l ) .AND. Lyr_DescriptionApp() == "AcAecLayerStandard", "[extra] layer: with_color" )
   u := Ucs_New( "U1" ) ; Chk( Vc3_Eq( u[ "x_axis" ], Vc3_UnitX() ) .AND. Vc3_Eq( Ucs_ZAxis( u ), Vc3_UnitZ() ) .AND. u[ "elevation" ] == 0.0, "[extra] ucs: valores por defecto y z_axis" )
   u := Ucs_FromOriginAxes( "U2", Vc3_New( 1.0, 2.0, 3.0 ), Vc3_UnitY(), Vc3_UnitX() ) ; Chk( Vc3_Eq( u[ "origin" ], Vc3_New( 1.0, 2.0, 3.0 ) ) .AND. Vc3_Eq( Ucs_ZAxis( u ), Vc3_New( 0.0, 0.0, -1.0 ) ), "[extra] ucs: from_origin_axes y z_axis" )
   v := Vxr_Default() ; Chk( v[ "name" ] == "" .AND. ! v[ "is_on" ] .AND. v[ "legacy_viewport_index" ] == 0, "[extra] vx: valores por defecto" )
   t := Tb_New() ; Tb_Add( t, Lyr_Layer0() ) ; Tb_Add( t, Lyr_New( "Muros" ) ) ; Chk( Tb_Len( t ) == 2 .AND. Lyr_IsStandard( Tb_Get( t, "0" ) ) .AND. Tb_Get( t, "muros" ) != NIL, "[extra] tabla de capas con Tb_Add/Tb_Get" )
RETURN
