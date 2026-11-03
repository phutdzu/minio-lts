# Contributing

This is a self-maintained fork, changes are made through pull requests on GitHub.

## Workflow

1. Create a branch from `main`, one topic per branch.
2. Keep each commit focused and explain the **why** in the message.
3. Run the checks below locally.
4. Open a pull request, describe the change and how you tested it.

## Setup

```sh
git clone <this repository>
cd minio
make build
```

Go 1.26 or newer is required. Dependencies are vendored, no network is needed to build.

## Build

```sh
# local development build, version shows as DEVELOPMENT.<time>
make build

# release-style build, version shows as LTS.<time>
MINIO_RELEASE=LTS make build

# cross compile
GOOS=linux GOARCH=arm64 MINIO_RELEASE=LTS make build

./minio --version
```

No network access is needed, `vendor/` is used automatically.

Release binaries (`./dist/minio-<os>-<arch>`, `mc-<os>-<arch>` and `SHA256SUMS`, static, `-trimpath`):

```sh
make release-binaries
PLATFORMS="linux/amd64 linux/arm64" bash buildscripts/build-release.sh   # a subset
```

Container image, compiled from the vendored source (nothing is downloaded from upstream):

```sh
make docker             # server image for your host platform
make docker-mc          # client image
make docker-multiarch   # linux/amd64 + linux/arm64, pushed with docker buildx
```

Images are tagged `ghcr.io/phutdzu/minio-lts-server:LTS.<time>` (override with `REPO=` or `TAG=`). `make version` prints the version your checkout would get.

## CI

[`ci.yml`](.github/workflows/ci.yml) runs on every pull request, every push to `main` and weekly: vendoring, lint, unit tests, `govulncheck` and `helm lint`. It builds and publishes nothing. All five checks must be green to merge. Releases are a separate, manual workflow, see [MAINTENANCE.md](MAINTENANCE.md#release).

## Checks before a pull request

```sh
make verifiers          # golangci-lint + generated-file check
make test               # build, lint, unit tests
go test ./cmd/ -run <TestName> -count=1   # a single test
```

Some end-to-end suites (`make verify-healing`, `make test-replication`, `make test-iam`, ...) need extra tooling and are slow, run the ones related to the code you touched.


## Dependencies

```sh
go get <module>@<version>
go mod tidy
go mod vendor
```

Commit `go.mod`, `go.sum` and `vendor/` in the same commit. Afterwards make sure no vendored file is hidden by `.gitignore`:

```sh
git ls-files --others --ignored --exclude-standard vendor   # must print nothing
```

## Code style

- Follow the surrounding code, run `gofmt` and `golangci-lint` (`make lint`).
- Add or update tests for behaviour changes.
- Every new Go file starts with the AGPLv3 header used by the other files.
- Do not reintroduce calls to upstream services (update server, SUBNET, callhome).

## Security issues

Do not open a public issue, see [SECURITY.md](SECURITY.md).
