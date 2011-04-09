;; Some utilities

(define (read-until-char delimiter port)
  (let loop ((acc '()))
    (let ((ch (read-char port)))
      (cond
       ((or (eof-object? ch) (char=? ch delimiter))
        (list->string (reverse acc)))
       (else
        (loop (cons ch acc)))))))

(define drop-char read-char)

(define (read-string n port)
  (let loop ((n n) (result '()))
    (if (zero? n)
        (list->string (reverse result))
        (loop (- n 1) (cons (read-char port) result)))))

(define (string-empty? str)
  (zero? (string-length str)))

;; Parser code

(define (read-tnetstring port)
  (if (eof-object? (peek-char port))
      (read-char port)
      (let* ((len (string->number (read-until-char #\: port)))
             (data (read-string len port))
             (type (read-char port)))
        (case type
          ((#\,) data)
          ((#\#) (string->number data))
          ((#\~) #f)
          ((#\!) (cond ((string=? data "true") #t)
                       ((string=? data "false") #f)
                       (else (error "invalid boolean"))))
          ((#\]) (parse-tnetstring-list data))
          ((#\}) (parse-tnetstring-dict data))
          (else (error "invalid payload type" type))))))

(define (read-tnetstring-pair port)
  (let ((key (read-tnetstring port)))
    (if (eof-object? key)
        key ;; is EOF
        (let ((value (read-tnetstring port)))
          (if (eof-object? value)
              (error "Unbalanced tnetstring pair")
              (cons key value))))))

(define (read-tnetstring-list port)
  (let loop ((result '()) (value (read-tnetstring port)))
    (if (eof-object? value)
        (reverse result)
        (loop (cons value result)
              (read-tnetstring port)))))

(define (read-tnetstring-dict port)
  (let loop ((result '()) (key+value (read-tnetstring-pair port)))
    (if (eof-object? key+value)
        result
        (loop (cons key+value result) (read-tnetstring-pair port)))))

(define (read-from-string/empty string proc)
  (if (string-empty? string)
      '()
      (call-with-input-string string proc)))

(define (parse-tnetstring-list string)
  (read-from-string/empty string read-tnetstring-list))

(define (parse-tnetstring-dict string)
  (read-from-string/empty string read-tnetstring-dict))

(define (parse-tnetstring string)
  (if (string-empty? string)
      (error "Invalid tnetstring, it is empty")
      (call-with-input-string string read-tnetstring)))
