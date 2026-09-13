(defpackage #:object-store-parity
  (:use #:cl)
  (:export #:*s3-host*
           #:*s3-port*
           #:env-off-p
           #:live-requested-p
           #:tcp-reachable-p
           #:minio-reachable-p
           #:make-live-s3-backend
           #:ensure-bucket
           #:xml-object-keys
           #:s3-put-get-list-head
           #:print-matrix))

(in-package #:object-store-parity)
