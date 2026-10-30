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

### Release binaries

```sh
make release-binaries   # ./dist/minio-<os>-<arch> + SHA256SUMS
```

Builds linux (amd64, arm64, ppc64le), darwin (amd64, arm64) and windows (amd64) with `-trimpath`, static, version `FORK.<time>`. Restrict the set with `PLATFORMS="linux/amd64 linux/arm64" bash buildscripts/build-release.sh`.

### Container image

The [`Dockerfile`](Dockerfile) compiles MinIO from the vendored source (nothing is downloaded from upstream) on `alpine`.

```sh
make docker             # image for your host platform
make docker-multiarch   # linux/amd64 + linux/arm64, pushed with docker buildx
```

The image is tagged `ghcr.io/phutdzu/minio-fork:FORK.<time>` (override with `REPO=` or `TAG=`). Run it like any MinIO image:

```sh
docker run -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER=admin -e MINIO_ROOT_PASSWORD=change-me-please \
  -v minio-data:/data \
  ghcr.io/phutdzu/minio-fork:latest server /data --console-address :9001
```

Differences from the upstream image: no `mc` and no `curl` inside, runs as root like upstream (use `--user` or a Kubernetes `securityContext` to drop privileges), the deprecated `MINIO_USERNAME` user switching is not supported.

### Releases and CI

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) verifies vendoring, lints, tests, cross compiles and builds the image on every pull request. A release is a tag named after the commit time:

```sh
git tag "$(make -s version)"    # e.g. FORK.2026-10-29T08-55-58Z
git push origin --tags
```

The tag workflow pushes the multi-arch image and `:latest` to GHCR and creates a GitHub release with the binaries and `SHA256SUMS`.

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

A community Helm chart lives in [`helm/minio`](helm/minio). It defaults to the images built by this repository (`ghcr.io/phutdzu/minio-fork` and `ghcr.io/phutdzu/minio-fork/mc`) and is installed from a checkout, see the [chart README](helm/minio/README.md). Pin `image.tag` to a released `FORK.<time>` version in production.

## Development

```sh
make verifiers   # lint + generated-file check
make test        # build, lint and unit tests
```

After changing dependencies always run `go mod tidy && go mod vendor` and commit `go.mod`, `go.sum` and `vendor/` together.

See [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md) and [MAINTENANCE.md](MAINTENANCE.md) (recurring security and upgrade routine).

## Documentation

The `docs/` folder is carried over from upstream and still describes upstream behaviour. Features removed in this fork (in-place update, callhome, SUBNET licensing) are described there as if available.

## License

- Source code: [GNU AGPLv3](LICENSE), copyright MinIO, Inc. and contributors, see [NOTICE](NOTICE) and [CREDITS](CREDITS).
- Documentation in `docs/`: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

The AGPLv3 applies to this fork. If you run a modified version as a network service you must offer its corresponding source to the users of that service, and redistributed binaries or images must be accompanied by the license and source. The license gives no warranty and no support obligation. Check with your own legal counsel whether your use complies.
