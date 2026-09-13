(in-package #:object-store-parity)

(defun print-matrix ()
  (format t "~&object-store-parity matrix~%")
  (format t "  put/get/list/head vs MinIO at ~a:~a (SigV4, skip if unreachable)~%"
          *s3-host* *s3-port*)
  (format t "  list keys asserted from ListObjects XML (backend listing is a stub)~%")
  (format t "  PARITY=0 or OBJECT_STORE_PARITY=0 forces skip~%"))
