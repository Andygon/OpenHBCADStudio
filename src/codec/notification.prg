/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/notification.prg
   Origen Rust: opencadcodec/src/notification.rs (217 lineas, 3 tests). Licencia del original: MPL-2.0.
   Prefijos: Nt_ (Notification), Ntc_ (NotificationCollection). NotificationType = enteros NTY_* (ocx.ch).
   NotificationCollection = hash { "items", "omitted", "omitted_errors" }. Las cadenas se tratan como UTF-8 (conteo de caracteres con hb_UTF8Len, como chars().count()).
   into_iter/iter/into_vec: se accede directo a "items" (Ntc_Items). saturating_add: sin desbordamiento practico en enteros Harbour.
----------------------------------------------------------------------------*/
#include "ocx.ch"

#define MAX_NOTIFICATIONS 1000
#define MAX_NOTIFICATION_MESSAGE_CHARS 2000

FUNCTION Nt_TypeDisplay( n )
   DO CASE
   CASE n == NTY_NOT_IMPLEMENTED ; RETURN "NotImplemented"
   CASE n == NTY_NOT_SUPPORTED ; RETURN "NotSupported"
   CASE n == NTY_WARNING ; RETURN "Warning"
   ENDCASE
RETURN "Error"

FUNCTION Nt_New( nType, cMsg ) ; RETURN hb_Hash( "notification_type", nType, "message", cMsg )
FUNCTION Nt_Display( n ) ; RETURN "[" + Nt_TypeDisplay( n[ "notification_type" ] ) + "] " + n[ "message" ]

FUNCTION Ntc_New() ; RETURN hb_Hash( "items", {}, "omitted", 0, "omitted_errors", 0 )

PROCEDURE Ntc_Notify( c, nType, cMsg )
   IF Len( c[ "items" ] ) >= MAX_NOTIFICATIONS
      c[ "omitted" ]++
      IF nType == NTY_ERROR ; c[ "omitted_errors" ]++ ; ENDIF
      RETURN
   ENDIF
   IF hb_UTF8Len( cMsg ) > MAX_NOTIFICATION_MESSAGE_CHARS
      cMsg := hb_UTF8Left( cMsg, MAX_NOTIFICATION_MESSAGE_CHARS ) + "… [message truncated]"
   ENDIF
   AAdd( c[ "items" ], Nt_New( nType, cMsg ) )
RETURN

FUNCTION Ntc_IsEmpty( c ) ; RETURN Len( c[ "items" ] ) == 0
FUNCTION Ntc_Len( c ) ; RETURN Len( c[ "items" ] )
FUNCTION Ntc_Items( c ) ; RETURN c[ "items" ]
FUNCTION Ntc_OmittedCount( c ) ; RETURN c[ "omitted" ]
FUNCTION Ntc_ErrorCount( c )
   LOCAL n := c[ "omitted_errors" ], i
   FOR EACH i IN c[ "items" ]
      IF i[ "notification_type" ] == NTY_ERROR ; n++ ; ENDIF
   NEXT
RETURN n
FUNCTION Ntc_OfType( c, nType )
   LOCAL a := {}, i
   FOR EACH i IN c[ "items" ]
      IF i[ "notification_type" ] == nType ; AAdd( a, i ) ; ENDIF
   NEXT
RETURN a
FUNCTION Ntc_HasType( c, nType ) ; RETURN Len( Ntc_OfType( c, nType ) ) > 0
PROCEDURE Ntc_Extend( c, o )
   LOCAL i
   FOR EACH i IN o[ "items" ]
      Ntc_Notify( c, i[ "notification_type" ], i[ "message" ] )
   NEXT
   c[ "omitted" ] += o[ "omitted" ]
   c[ "omitted_errors" ] += o[ "omitted_errors" ]
RETURN
