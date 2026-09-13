# object-store-parity

Interop canary: **[`object-store-backend-s3`](https://github.com/egao1980/object-store-backend-s3)** (SigV4) vs dockerized **MinIO**. Exercises `put-object` / `get-object` / `list-objects` / `head-object` over `http-backend-dexador`.

In-memory store tests stay in `object-store-protocol`. Signing fixtures stay in the S3 backend. This repo is **live interop** only.

`list-objects` on the S3 backend does not parse XML yet; the canary asserts keys from the ListObjects response body.

## Run

Default `asdf:test-system` is green **without Docker** — live cases `skip` when MinIO is unreachable.

```bash
ros -e '(asdf:test-system "object-store-parity")' -q
```

Live:

```bash
docker compose up --wait
ros -e '(asdf:test-system "object-store-parity")' -q
```

```bash
PARITY=0 ros -e '(asdf:test-system "object-store-parity")' -q
```

## Env

| Variable | Default | Meaning |
|----------|---------|---------|
| `PARITY` | probe | `0`/`false`/`off` skips live cases |
| `OBJECT_STORE_PARITY` | probe | same, MinIO-only |
| `OBJECT_STORE_PARITY_HOST` | `127.0.0.1` | MinIO host |
| `OBJECT_STORE_PARITY_PORT` | `9000` | S3 API port |
| `OBJECT_STORE_PARITY_ENDPOINT` | `http://$HOST:$PORT` | full URL |
| `OBJECT_STORE_PARITY_ACCESS_KEY` | `minioadmin` | SigV4 access key |
| `OBJECT_STORE_PARITY_SECRET_KEY` | `minioadmin` | SigV4 secret |
| `OBJECT_STORE_PARITY_BUCKET` | `parity` | created on first live run |
| `OBJECT_STORE_PARITY_REGION` | `us-east-1` | signing region |

## Compose pins

| Service | Image |
|---------|--------|
| MinIO | `quay.io/minio/minio:RELEASE.2025-04-22T22-12-26Z` |

## License

MIT
