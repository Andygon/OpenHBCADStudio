/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/arrangement.prg
   Origen Rust: opencadkernel/src/geom2d/arrangement.rs
   Estado: PARCIAL - solo signed_area (la necesita area.rs). Resto pendiente.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION SignedArea( aRing )
   LOCAL aOrigin, nTotal := 0.0, i, a, b
   IF Len( aRing ) < 3 ; RETURN 0.0 ; ENDIF
   aOrigin := { aRing[1][1], aRing[1][2] }
   // ring[1..].windows(2)
   FOR i := 2 TO Len( aRing ) - 1
      a := V2_Sub( { aRing[i][1], aRing[i][2] }, aOrigin )
      b := V2_Sub( { aRing[i+1][1], aRing[i+1][2] }, aOrigin )
      nTotal += V2_Cross( a, b )
   NEXT
RETURN nTotal * 0.5
