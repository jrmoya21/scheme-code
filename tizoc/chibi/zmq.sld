(define-library (tizoc chibi zmq)
  (export
   ;; Socket types
   zmq-socket-type/pair
   zmq-socket-type/sub
   zmq-socket-type/pub
   zmq-socket-type/req
   zmq-socket-type/rep
   zmq-socket-type/xreq
   zmq-socket-type/xrep
   zmq-socket-type/push
   zmq-socket-type/pull
   zmq-socket-type/upstream
   zmq-socket-type/downstream

   ;; Messaging flags
   zmq-messaging-flag/sndmore
   zmq-messaging-flag/rcvmore
   zmq-messaging-flag/noblock

   ;; Socket options
   zmq-socket-option/hwm
   zmq-socket-option/swap
   zmq-socket-option/affinity
   zmq-socket-option/identity
   zmq-socket-option/subscribe
   zmq-socket-option/unsubscribe
   zmq-socket-option/rate
   zmq-socket-option/recovery-ivl
   zmq-socket-option/mcast-loop
   zmq-socket-option/sndbuf
   zmq-socket-option/rcvbuf

   ;; Type predicates
   socket?
   context?

   ;; API calls
   zmq-version
   make-context
   terminate-context
   make-socket
   close-socket
   socket-option
   socket-option-set!
   bind-socket
   connect-socket
   send-message
   receive-message
   send-message/noblock
   receive-message/noblock

   ;; Multiplexing
   select

   ;; TODO: use exceptions?
   zmq-errno
   zmq-strerror

   ;; TODO socket-fd

   ;; Parameters
   zmq-default-context
   zmq-io-threads
   )
  (import (scheme) (srfi 39))
  (include-shared "zmq/zmq")
  (include "zmq/zmq.scm"))
