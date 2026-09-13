(in-package #:object-store-parity)

(defun env-off-p (name)
  (let ((v (string-downcase (or (uiop:getenv name) ""))))
    (member v '("0" "false" "no" "off") :test #'string=)))

(defun live-requested-p (&optional extra)
  (and (not (env-off-p "PARITY"))
       (or (null extra) (not (env-off-p extra)))))

(defun %env (name &optional default)
  (or (uiop:getenv name) default))

(defparameter *s3-host*
  (%env "OBJECT_STORE_PARITY_HOST" "127.0.0.1"))

(defparameter *s3-port*
  (parse-integer (%env "OBJECT_STORE_PARITY_PORT" "9000") :junk-allowed t))

(defun tcp-reachable-p (host port &key (timeout 0.4))
  (handler-case
      (let ((sock (usocket:socket-connect host port
                                          :timeout timeout
                                          :element-type '(unsigned-byte 8))))
        (usocket:socket-close sock)
        t)
    (error () nil)))

(defun minio-reachable-p ()
  (and (live-requested-p "OBJECT_STORE_PARITY")
       (tcp-reachable-p *s3-host* *s3-port*)))
