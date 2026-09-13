(defsystem "object-store-parity"
  :version "0.1.0"
  :description "Interop canary: object-store-backend-s3 SigV4 vs dockerized MinIO"
  :author "egao1980"
  :license "MIT"
  :depends-on ("object-store-protocol"
               "object-store-backend-s3"
               "http-protocol"
               "http-backend-dexador"
               "usocket"
               "uiop")
  :serial t
  :pathname "src"
  :components ((:file "package")
               (:file "probe")
               (:file "minio")
               (:file "report"))
  :in-order-to ((test-op (test-op "object-store-parity/tests"))))

(defsystem "object-store-parity/tests"
  :depends-on ("object-store-parity" "rove")
  :pathname "tests"
  :serial t
  :components ((:file "package")
               (:file "live"))
  :perform (test-op (o c)
             (unless (symbol-call :rove :run c)
               (error "object-store-parity tests failed"))))
