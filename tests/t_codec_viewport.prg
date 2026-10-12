/* Port de tests: viewport.rs (12) + [extra] */
#include "ocx.ch"
STATIC FUNCTION V( x, y, z ) ; RETURN Vc3_New( x, y, z )
STATIC FUNCTION Nr( a, b ) ; RETURN Abs( a - b ) < 0.0000000001
PROCEDURE T_CodecViewport()
   LOCAL vp, a, e, f, l, b
   vp := Evp_New() ; Chk( Evp_IsOn( vp ) .AND. ! Evp_IsLocked( vp ) .AND. Vc3_Eq( vp[ "view_direction" ], Vc3_UnitZ() ), "viewport: test_viewport_creation" )
   vp := Evp_WithSize( V( 100.0, 100.0, 0.0 ), 200.0, 150.0 ) ; Chk( Vc3_Eq( vp[ "center" ], V( 100.0, 100.0, 0.0 ) ) .AND. vp[ "width" ] == 200.0 .AND. vp[ "height" ] == 150.0, "viewport: test_viewport_with_size" )
   vp := Evp_New() ; vp[ "height" ] := 100.0 ; vp[ "view_height" ] := 200.0 ; a := Nr( Evp_Scale( vp ), 0.5 ) ; Evp_SetScale( vp, 0.25 ) ; Chk( a .AND. Nr( vp[ "view_height" ], 400.0 ), "viewport: test_viewport_scale" )
   vp := Evp_New() ; a := ! Evp_IsLocked( vp ) ; Evp_Lock( vp ) ; a := a .AND. Evp_IsLocked( vp ) ; Evp_Unlock( vp ) ; Chk( a .AND. ! Evp_IsLocked( vp ), "viewport: test_viewport_lock" )
   vp := Evp_New() ; Evp_FreezeLayer( vp, Hd_New( 100 ) ) ; Evp_FreezeLayer( vp, Hd_New( 200 ) ) ; a := Len( vp[ "frozen_layers" ] ) == 2 ; Evp_ThawLayer( vp, Hd_New( 100 ) )
   Chk( a .AND. Len( vp[ "frozen_layers" ] ) == 1 .AND. AScan( vp[ "frozen_layers" ], 200 ) > 0, "viewport: test_viewport_frozen_layers" )
   vp := Evp_New() ; Evp_SetStandardView( vp, SV_FRONT ) ; a := Vc3_Eq( vp[ "view_direction" ], V( 0.0, -1.0, 0.0 ) ) ; Evp_SetStandardView( vp, SV_TOP ) ; a := a .AND. Vc3_Eq( vp[ "view_direction" ], Vc3_UnitZ() )
   Evp_SetStandardView( vp, SV_NE_ISOMETRIC ) ; e := Vc3_Normalize( V( 1.0, 1.0, 1.0 ) )
   Chk( a .AND. Nr( vp[ "view_direction" ][ 1 ], e[ 1 ] ) .AND. Nr( vp[ "view_direction" ][ 2 ], e[ 2 ] ) .AND. Nr( vp[ "view_direction" ][ 3 ], e[ 3 ] ), "viewport: test_viewport_standard_views" )
   vp := Evp_WithSize( V( 100.0, 100.0, 0.0 ), 200.0, 100.0 ) ; b := Evp_PaperBounds( vp ) ; Chk( b[ 1 ][ 1 ] == 0.0 .AND. b[ 1 ][ 2 ] == 50.0 .AND. b[ 2 ][ 1 ] == 200.0 .AND. b[ 2 ][ 2 ] == 150.0, "viewport: test_viewport_paper_bounds" )
   f := Vsf_FromBits( 32769 ) ; a := f[ "is_on" ] .AND. f[ "perspective" ] .AND. ! f[ "locked" ] .AND. Vsf_ToBits( f ) == 32769
   l := Vsf_FromBits( 16384 ) ; Chk( a .AND. l[ "locked" ] .AND. ! l[ "is_on" ] .AND. Vsf_ToBits( l ) == 16384, "viewport: test_viewport_status_flags" )
   vp := Evp_New() ; Evp_SetRenderMode( vp, VRM_HIDDEN_LINE ) ; Chk( vp[ "render_mode" ] == VRM_HIDDEN_LINE, "viewport: test_viewport_render_mode" )
   vp := Evp_WithSize( V( 0.0, 0.0, 0.0 ), 100.0, 100.0 ) ; Ent_Translate( vp, V( 50.0, 50.0, 0.0 ) ) ; Chk( Vc3_Eq( vp[ "center" ], V( 50.0, 50.0, 0.0 ) ), "viewport: test_viewport_translate" )
   vp := Evp_WithLocked( Evp_WithScale( Evp_WithViewTarget( Evp_WithCenter( Evp_New(), V( 100.0, 100.0, 0.0 ) ), V( 50.0, 50.0, 0.0 ) ), 0.5 ) )
   Chk( Vc3_Eq( vp[ "center" ], V( 100.0, 100.0, 0.0 ) ) .AND. Vc3_Eq( vp[ "view_target" ], V( 50.0, 50.0, 0.0 ) ) .AND. Evp_IsLocked( vp ), "viewport: test_viewport_builder" )
   // [extra]
   f := Vsf_FromBits( 131072 + 65536 ) ; Chk( f[ "is_off" ] .AND. f[ "non_rectangular_clipping" ] .AND. Vsf_ToBits( f ) == 196608 .AND. Vgf_ToBits( Vgf_FromBits( 11 ) ) == 11 .AND. Vrm_FromValue( 9 ) == 0, "[extra] viewport: bits is_off/non_rect, grid flags, render mode" )
   vp := Evp_New() ; Evp_TurnOff( vp ) ; a := ! Evp_IsOn( vp ) ; Evp_TurnOn( vp ) ; Chk( a .AND. Evp_IsOn( vp ) .AND. Ent_EntityType( vp ) == "VIEWPORT", "[extra] viewport: turn_on/off y entity_type" )
   vp := Evp_New() ; Ent_ApplyTransform( vp, Tf_FromScale( 2.0 ) ) ; Chk( Nr( vp[ "width" ], 594.0 ) .AND. Nr( vp[ "height" ], 420.0 ), "[extra] viewport: transform escala tamano" )
RETURN
