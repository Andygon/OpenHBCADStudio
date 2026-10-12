/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/frame.prg
   Origen Rust: opencadkernel/src/geom2d/frame.rs (199 lineas)
   Estado: TRADUCIDO (tests portados en tests/t_frame.prg)
   Frame = {ox,oy,oz} (solo traslacion). Contrato: lift antes de operar,
   lower en cada punto devuelto. Puntos 3D = {x,y,z}; 2D = {x,y}.
----------------------------------------------------------------------------*/
FUNCTION Frame_At( aOrigin )
RETURN { aOrigin[1], aOrigin[2], aOrigin[3] }

FUNCTION Frame_Identity()
RETURN { 0.0, 0.0, 0.0 }

STATIC FUNCTION Midpoint( a, b )   // evita a+b (desbordamiento / perdida de bits)
RETURN a + ( b - a ) * 0.5

// Frame anclado en el punto medio de la caja de aPoints (array de {x,y,z});
// vacio -> identidad
FUNCTION Frame_Around( aPoints )
   LOCAL aMin, aMax, aP, n
   IF Len( aPoints ) == 0
      RETURN Frame_Identity()
   ENDIF
   aMin := AClone( aPoints[ 1 ] ); aMax := AClone( aPoints[ 1 ] )
   FOR EACH aP IN aPoints
      FOR n := 1 TO 3
         IF aP[ n ] < aMin[ n ] ; aMin[ n ] := aP[ n ] ; ENDIF
         IF aP[ n ] > aMax[ n ] ; aMax[ n ] := aP[ n ] ; ENDIF
      NEXT
   NEXT
RETURN { Midpoint( aMin[1], aMax[1] ), Midpoint( aMin[2], aMax[2] ), Midpoint( aMin[3], aMax[3] ) }

FUNCTION Frame_Origin( aF )
RETURN { aF[1], aF[2], aF[3] }

FUNCTION Frame_Lift( aF, aP )
RETURN { aP[1] - aF[1], aP[2] - aF[2], aP[3] - aF[3] }

FUNCTION Frame_Lower( aF, aP )
RETURN { aP[1] + aF[1], aP[2] + aF[2], aP[3] + aF[3] }

FUNCTION Frame_Lift2D( aF, aP )
RETURN { aP[1] - aF[1], aP[2] - aF[2] }

FUNCTION Frame_Lower2D( aF, aP )
RETURN { aP[1] + aF[1], aP[2] + aF[2] }
