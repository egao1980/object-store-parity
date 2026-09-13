(in-package #:object-store-parity)

(defvar *last-s3-response* nil)

(defun %s3-endpoint ()
  (%env "OBJECT_STORE_PARITY_ENDPOINT"
        (format nil "http://~a:~a" *s3-host* *s3-port*)))

(defun make-s3-http-fn ()
  (let ((backend (http-backend-dexador:make-dexador-backend)))
    (lambda (req)
      (let* ((http-req
               (cond
                 ((http-protocol:http-request-p req) req)
                 ((object-store-backend-s3:s3-http-request-p req)
                  (http-protocol:make-http-request
                   :method (object-store-backend-s3:s3-http-request-method req)
                   :url (object-store-backend-s3:s3-http-request-url req)
                   :headers (object-store-backend-s3:s3-http-request-headers req)
                   :content (object-store-backend-s3:s3-http-request-body req)
                   :force-binary t
                   :raise-for-status nil))
                 (t (error 'object-store-protocol:object-store-error
                           :message (format nil "not an S3 HTTP request: ~s" req)))))
             (client (http-protocol:make-http-client backend))
             (resp (http-protocol:send backend client http-req)))
        (setf *last-s3-response* resp)
        resp))))

(defun make-live-s3-backend (&key (endpoint (%s3-endpoint))
                               (bucket nil)
                               (access-key nil)
                               (secret-key nil)
                               (region nil))
  (object-store-backend-s3:make-s3-backend
   :endpoint endpoint
   :region (or region (%env "OBJECT_STORE_PARITY_REGION" "us-east-1"))
   :access-key (or access-key (%env "OBJECT_STORE_PARITY_ACCESS_KEY" "minioadmin"))
   :secret-key (or secret-key (%env "OBJECT_STORE_PARITY_SECRET_KEY" "minioadmin"))
   :bucket (or bucket (%env "OBJECT_STORE_PARITY_BUCKET" "parity"))
   :http-fn (make-s3-http-fn)))

(defun %response-status (resp)
  (cond
    ((http-protocol:http-response-p resp)
     (http-protocol:response-status resp))
    ((and (consp resp) (integerp (car resp))) (car resp))
    (t 0)))

(defun %response-body-string (resp)
  (let ((body (cond
                ((http-protocol:http-response-p resp)
                 (http-protocol:response-body resp))
                ((and (consp resp) (cadr resp)) (cadr resp))
                ((vectorp resp) resp)
                ((stringp resp) resp)
                (t ""))))
    (cond
      ((stringp body) body)
      ((vectorp body) (map 'string #'code-char body))
      (t (princ-to-string (or body ""))))))

(defun xml-object-keys (resp)
  "Pull <Key>…</Key> from a ListObjects body (backend listing is a stub)."
  (let ((s (%response-body-string resp))
        (keys nil)
        (start 0))
    (loop
      (let ((a (search "<Key>" s :start2 start)))
        (unless a (return (nreverse keys)))
        (let ((b (search "</Key>" s :start2 a)))
          (unless b (return (nreverse keys)))
          (push (subseq s (+ a 5) b) keys)
          (setf start b))))))

(defun ensure-bucket (store &optional (bucket (object-store-backend-s3:s3-backend-bucket store)))
  "Signed PUT /bucket. 200/204/409 are success."
  (let* ((tmp (object-store-backend-s3:make-s3-backend
               :endpoint (object-store-backend-s3:s3-backend-endpoint store)
               :region (object-store-backend-s3:s3-backend-region store)
               :access-key (object-store-backend-s3:s3-backend-access-key store)
               :secret-key (object-store-backend-s3:s3-backend-secret-key store)
               :bucket nil
               :http-fn (object-store-backend-s3:s3-backend-http-fn store)))
         (req (object-store-backend-s3:build-s3-request tmp :method :put :key bucket))
         (resp (funcall (object-store-backend-s3:s3-backend-http-fn store) req))
         (status (%response-status resp)))
    (unless (member status '(200 204 409))
      (error 'object-store-protocol:object-store-error
             :store store
             :message (format nil "CreateBucket HTTP ~a" status)))
    status))

(defun s3-put-get-list-head (&key (payload "minio-parity"))
  (let* ((store (make-live-s3-backend))
         (key (format nil "parity/canary-~d.txt" (get-universal-time))))
    (ensure-bucket store)
    (let ((stat (object-store-protocol:put-object
                 store key payload :content-type "text/plain")))
      (let ((body (object-store-protocol:get-object store key))
            (head (object-store-protocol:head-object store key))
            (listing (object-store-protocol:list-objects store :prefix "parity/")))
        (list :key key
              :stat stat
              :body body
              :head head
              :listing listing
              :xml-keys (xml-object-keys *last-s3-response*))))))
