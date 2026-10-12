/* Tests: notification.rs (3 tests 1:1) + [extra] */
#include "ocx.ch"
PROCEDURE T_CodecNotification()
   LOCAL n, c, i, d
   n := Nt_New( NTY_WARNING, "handle missing" ) ; Chk( n[ "notification_type" ] == NTY_WARNING .AND. n[ "message" ] == "handle missing", "notification_creation" )
   c := Ntc_New() ; Chk( Ntc_IsEmpty( c ), "collection_basics vacia" )
   Ntc_Notify( c, NTY_WARNING, "w1" ) ; Ntc_Notify( c, NTY_ERROR, "e1" ) ; Ntc_Notify( c, NTY_WARNING, "w2" )
   Chk( Ntc_Len( c ) == 3 .AND. Len( Ntc_OfType( c, NTY_WARNING ) ) == 2 .AND. Ntc_HasType( c, NTY_ERROR ) .AND. ! Ntc_HasType( c, NTY_NOT_IMPLEMENTED ), "collection_basics" )
   n := Nt_New( NTY_NOT_IMPLEMENTED, "THUMBNAILIMAGE section" ) ; Chk( Nt_Display( n ) == "[NotImplemented] THUMBNAILIMAGE section", "display" )
   c := Ntc_New() ; FOR i := 1 TO 1002
      Ntc_Notify( c, iif( i > 1000, NTY_ERROR, NTY_WARNING ), "x" )
   NEXT
   Chk( Ntc_Len( c ) == 1000 .AND. Ntc_OmittedCount( c ) == 2 .AND. Ntc_ErrorCount( c ) == 2, "[extra] limite de 1000 y omitted_errors" )
   c := Ntc_New() ; Ntc_Notify( c, NTY_WARNING, Replicate( "a", 2500 ) ) ; d := Ntc_Items( c )[ 1 ][ "message" ]
   Chk( hb_UTF8Len( d ) == 2000 + hb_UTF8Len( "… [message truncated]" ) .AND. "[message truncated]" $ d, "[extra] mensaje largo se trunca a 2000 caracteres" )
   d := Ntc_New() ; Ntc_Notify( d, NTY_ERROR, "e" ) ; Ntc_Extend( c, d ) ; Chk( Ntc_Len( c ) == 2 .AND. Ntc_ErrorCount( c ) == 1, "[extra] extend" )
RETURN
