# MinIO community fork

An unofficial, self-maintained fork of the MinIO community edition: a high-performance, S3-compatible object storage server written in Go.

> [!IMPORTANT]
> This project is **not affiliated with or endorsed by MinIO, Inc.**
> Upstream [`minio/minio`](https://github.com/minio/minio) is no longer maintained and no longer ships binaries or container images.
> This fork keeps the source buildable, fixes security issues and may add features. Use it at your own risk (see [License](#license)).

## Origin

|  |  |
|---|---|
| Upstream | <https://github.com/minio/minio> |
| Forked from | `7aac2a2c5` (upstream `master`, 2026-02-12) |
| Last upstream release tag | `RELEASE.2025-10-15T17-29-55Z` |

## What differs from upstream

- All dependencies are vendored in [`vendor/`](vendor), so the build works offline and does not depend on upstream repositories staying online.
- **In-place update is disabled.** The server never contacts `dl.min.io` and the upstream signing key was removed.
- **Callhome and SUBNET are disabled.** Nothing is sent to MinIO, Inc. services.
- Release tags look like `FORK.<UTC commit time>`, e.g. `FORK.2026-10-29T06-55-51Z`.

Progress and decisions are tracked in [FORK_CHECKLIST.md](FORK_CHECKLIST.md).

## Build

Requirements: Go 1.24 or newer (see `go.mod`). No network access is needed, `vendor/` is used automatically.

```sh
# local development build, version shows as DEVELOPMENT.<time>
make build

# fork release build, version shows as FORK.<time>
MINIO_RELEASE=FORK make build
```

This produces `./minio`. Cross compile with `GOOS`/`GOARCH`:

```sh
GOOS=linux GOARCH=arm64 MINIO_RELEASE=FORK make build
```

Check what you built:

```sh
./minio --version
```

> [!NOTE]
> Container images and CI release pipelines are not set up yet, see Phase 4 in [FORK_CHECKLIST.md](FORK_CHECKLIST.md).

## Run

```sh
MINIO_ROOT_USER=admin MINIO_ROOT_PASSWORD=change-me-please \
  ./minio server /path/to/data --console-address :9001
```

- S3 API: <http://127.0.0.1:9000>
- Web console: <http://127.0.0.1:9001>

Without `MINIO_ROOT_USER`/`MINIO_ROOT_PASSWORD` the server falls back to the well-known default `minioadmin:minioadmin`, never use that outside of local testing.

Any S3 client works, for example the MinIO Client [`mc`](https://github.com/minio/mc):

```sh
mc alias set local http://localhost:9000 admin change-me-please
mc mb local/data
mc cp ./file local/data/
mc ls local/data
```

## Kubernetes

A community Helm chart lives in [`helm/minio`](helm/minio). Its default image still points at upstream (`quay.io/minio/minio`), which no longer exists, so override `image.repository` and `image.tag` with an image you built.

## Development

```sh
make verifiers   # lint + generated-file check
make test        # build, lint and unit tests
```

After changing dependencies always run `go mod tidy && go mod vendor` and commit `go.mod`, `go.sum` and `vendor/` together.

See [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md).

## Documentation

The `docs/` folder is carried over from upstream and still describes upstream behaviour. Features removed in this fork (in-place update, callhome, SUBNET licensing) are described there as if available.

## License

- Source code: [GNU AGPLv3](LICENSE), copyright MinIO, Inc. and contributors, see [NOTICE](NOTICE) and [CREDITS](CREDITS).
- Documentation in `docs/`: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

The AGPLv3 applies to this fork. If you run a modified version as a network service you must offer its corresponding source to the users of that service, and redistributed binaries or images must be accompanied by the license and source. The license gives no warranty and no support obligation. Check with your own legal counsel whether your use complies.
