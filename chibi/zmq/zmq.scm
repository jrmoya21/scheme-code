;; let-optionals* from the fmt library
(define-syntax let-optionals*
  (syntax-rules ()
    ((_ opt-ls () . body)
     (let () . body))
    ((_ (op . args) vars . body)
     (let ((tmp (op . args)))
       (let-optionals* tmp vars . body)))
    ((_ tmp ((var default) . rest) . body)
     (let ((var (if (pair? tmp) (car tmp) default))
           (tmp2 (if (pair? tmp) (cdr tmp) '())))
       (let-optionals* tmp2 rest . body)))
    ((_ tmp tail . body)
     (let ((tail tmp))
       . body))))

;; zmq

(define (zmq-version) (cdr (%zmq-version)))

(define zmq-default-context (make-parameter #f))
(define zmq-io-threads (make-parameter 1))

(define (zmq-default-context/initialize)
  (or (zmq-default-context)
      (begin (zmq-default-context (zmq-init))
             (zmq-default-context))))

(define (zmq-init . o)
  (let-optionals* o ((threads (zmq-io-threads)))
    (%zmq-init threads)))

(define (zmq-socket type . o)
  (let-optionals* o ((context (zmq-default-context/initialize)))
    (%zmq-socket context type)))

(define (zmq-socket-option-value symbol)
  (case symbol
    ((hwm) zmq-socket-option/hwm)
    ((swap) zmq-socket-option/swap)
    ((affinity) zmq-socket-option/affinity)
    ((identity) zmq-socket-option/identity)
    ((subscribe) zmq-socket-option/subscribe)
    ((unsubscribe ) zmq-socket-option/unsubscribe)
    ((rate) zmq-socket-option/rate)
    ((recovery-ivl) zmq-socket-option/recovery-ivl)
    ((mcast-loop) zmq-socket-option/mcast-loop)
    ((sndbuf) zmq-socket-option/sndbuf)
    ((rcvbuf) zmq-socket-option/rcvbuf)
    ((rcvmore) zmq-messaging-flag/rcvmore)
    (else (error "invalid option" symbol))))

(define sockopt-uint64 (list zmq-socket-option/hwm
                             zmq-socket-option/affinity
                             zmq-socket-option/sndbuf
                             zmq-socket-option/rcvbuf))

(define sockopt-int64 (list zmq-socket-option/swap
                            zmq-socket-option/rate
                            zmq-socket-option/recovery-ivl))

(define sockopt-bool (list zmq-socket-option/mcast-loop))

(define sockopt-string (list zmq-socket-option/identity
                             zmq-socket-option/subscribe
                             zmq-socket-option/unsubscribe))

(define (zmq-setsockopt socket option value)
  (define int-option (if (symbol? option)
                         (zmq-socket-option-value option)
                         option))

  (cond
    ;; uint64_t options
    ((member int-option sockopt-uint64)
     (%zmq-setsockopt-uint64 socket int-option value))
    ;; int64_t options
    ((member int-option sockopt-int64)
     (%zmq-setsockopt-int64 socket int-option value))
    ;; boolean options
    ((member int-option sockopt-bool)
     (%zmq-setsockopt-int64 socket int-option (if value 1 0)))
    ;; blob options
    ((member int-option sockopt-string)
     (%zmq-setsockopt-string socket int-option value (string-bytes-count value)))
    (else (error "invalid option" option))))

(define (zmq-getsockopt socket option)
  (define int-option (if (symbol? option)
                         (zmq-socket-option-value option)
                         option))

  (cond
    ;; uint64_t options
    ((member int-option sockopt-uint64)
     (%zmq-getsockopt-uint64 socket int-option))
    ;; int64_t options
    ((member int-option sockopt-int64)
     (%zmq-getsockopt-int64 socket int-option))
    ;; boolean options
    ((member int-option sockopt-bool)
     (not (zero? (%zmq-getsockopt-int64 socket int-option))))
    ;; blob options
    ((member int-option sockopt-string)
     (%zmq-getsockopt-string socket int-option))
    (else (error "invalid option" option))))

;; TODO: don't pass context and use parametrize?
(define (with-zmq-context body)
  (let* ((context (zmq-init))
         (result (body context)))
    (zmq-term context)
    result))

(define (zmq-msg-init-string string)
  (cond ((not (string? string)) (error "Not a string" string))
        (else
         (let ((message (zmq-msg-init-size (string-bytes-count string))))
           (%zmq-msg-set-string-data message string)
           message))))

(define (zmq-send-string socket string)
  (let ((message (zmq-msg-init-string string)))
    (%zmq-send socket message 0)))

(define (zmq-recv-string socket)
  (let ((message (zmq-msg-init)))
    (%zmq-recv socket message 0)
    (let* ((len (zmq-msg-size message))
           (data (zmq-msg-data message))
           (string (make-c-string data len)))
      (zmq-msg-close message)
      string)))

(define (zmq-select in . o)
  (let-optionals* o ((out #())
                     (err #())
                     (timeout 0))
    (let ((in (if (vector? in) in (list->vector in)))
          (out (if (vector? out) out (list->vector out)))
          (err (if (vector? err) err (list->vector err))))
      (%zmq-select in out err timeout))))