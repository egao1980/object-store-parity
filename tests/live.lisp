(in-package #:object-store-parity/tests)

(deftest probe-returns-boolean
  (ok (member (tcp-reachable-p *s3-host* *s3-port*) '(t nil))))

(deftest minio-put-get-list-head
  (cond
    ((not (live-requested-p "OBJECT_STORE_PARITY"))
     (skip "PARITY=0 or OBJECT_STORE_PARITY=0 — live MinIO canary skipped"))
    ((not (tcp-reachable-p *s3-host* *s3-port*))
     (skip (format nil "MinIO unreachable at ~a:~a — live canary skipped"
                   *s3-host* *s3-port*)))
    (t
     (let* ((result (s3-put-get-list-head :payload "hello-minio"))
            (key (getf result :key))
            (body (getf result :body))
            (head (getf result :head))
            (xml-keys (getf result :xml-keys)))
       (ok (object-store-protocol:object-stat-p (getf result :stat)))
       (ok (equalp (object-store-protocol:coerce-object-octets "hello-minio")
                   body))
       (ok (object-store-protocol:object-stat-p head))
       (ok (object-store-protocol:object-listing-p (getf result :listing)))
       (ok (member key xml-keys :test #'string=))))))
