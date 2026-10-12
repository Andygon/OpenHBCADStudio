/* Port de #[cfg(test)] de polyline_edit.rs. UTF-8. */
#include "ocx.ch"
STATIC FUNCTION PLn( aPts, lClosed )
   LOCAL aV := {}, p
   FOR EACH p IN aPts ; AAdd( aV, PV_Straight( p ) ) ; NEXT
RETURN PL_New( aV, lClosed )

PROCEDURE T_PolylineEdit()
   LOCAL shape, arc, orig
   shape := PLn( { {0.0,0.0}, {2.0,2.0}, {8.0,2.0}, {10.0,0.0} }, .F. )
   Chk( PE_MoveSegmentParallel( shape, 1, 2.0 ) .AND. shape[PL_VERTS][2][PV_POS][1] == 4.0 .AND. shape[PL_VERTS][2][PV_POS][2] == 4.0 ;
        .AND. shape[PL_VERTS][3][PV_POS][1] == 6.0 .AND. shape[PL_VERTS][3][PV_POS][2] == 4.0, "moving internal segment reconnects neighbours" )
   shape := PLn( { {0.0,0.0}, {10.0,0.0} }, .F. )
   shape[PL_VERTS][1][PV_BULGE] := 1.0
   Chk( PE_ResizeArc( shape, 0, 8.0 ), "resize open arc ok" )
   arc := PL_SegmentArc( shape, 0 )
   Chk( Abs( arc[BA_RADIUS] - 8.0 ) < 0.000000001 .AND. V2_Distance( arc[BA_CENTER], {5.0,0.0} ) < 0.000000001, "resizing open arc keeps its centre" )
   shape := PLn( { {0.0,0.0}, {2.0,0.0}, {5.0,0.0}, {6.0,2.0} }, .F. )
   orig := hb_ValToExp( shape )
   Chk( ! PE_MoveSegmentParallel( shape, 1, 1.0 ) .AND. hb_ValToExp( shape ) == orig, "impossible parallel edit leaves polyline unchanged" )
RETURN
