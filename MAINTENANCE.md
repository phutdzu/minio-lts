# Maintenance routine

Upstream MinIO is archived, so nothing flows in from it: security fixes, Go and dependency upgrades are our job. This file is the recurring checklist.

## Schedule

The weekly `schedule` trigger in `.github/workflows/ci.yml` (Mondays 03:00 UTC, default branch) needs no setup. It runs the same jobs as a push and therefore also rebuilds and pushes the `edge` images, which picks up new Alpine patch releases. GitHub disables scheduled workflows after 60 days without repository activity, re-enable it under Actions if that happens.

| When | What |
|---|---|
| Weekly (scheduled workflow) | `govulncheck` job, read the result, fix anything reachable |
| Monthly | Bump the Go patch version, rebuild, cut a release if anything changed |
| On a published CVE for a dependency | Upgrade that module, see below |
| Before every release tag | CI green on `main`, `make version` matches the tag |

The jobs `lint` and `govulncheck` in `.github/workflows/ci.yml` are `continue-on-error: true` until they have run green once. After that remove the flag so that they gate merges.

## Fix a vulnerable dependency

```sh
go get example.com/module@v1.2.3     # the fixed version
go mod tidy -e   # -e: a test-only import of github.com/go-openapi/swag is unresolvable upstream
go mod vendor
git ls-files --others --ignored --exclude-standard vendor   # must print nothing
go build ./... && go test ./internal/... 
```

Commit `go.mod`, `go.sum` and `vendor/` together, in one commit that names the CVE. The `vendor-check` job fails the pull request if they are out of sync.

Modules under `github.com/minio/*` (`madmin-go`, `minio-go`, `pkg`, `console`, `mc`, ...) live in separate upstream repositories that may no longer get fixes. If a vulnerable one has no fixed release, patch it here: `replace` it with a patched fork in `go.mod` and vendor that.

## Upgrade Go

1. Change `GO_VERSION` in the `Dockerfile` (`ARG GO_VERSION`) and in `.github/workflows/ci.yml` (`env.GO_VERSION`).
2. Change `go` / `toolchain` in `go.mod` only if the minimum language version must move.
3. `go mod tidy -e && go mod vendor`, run the tests, rebuild the image.

Go patch releases carry most of the standard library security fixes (`net/http`, `crypto/tls`, ...), this is the most valuable monthly task.

## Base image

`ALPINE_VERSION` in the `Dockerfile` is the runtime base. Rebuild regularly (the weekly schedule does) and move to the next Alpine release before the current one reaches end of life.

## Release

```sh
git checkout main && git pull
git tag "$(make -s version)"
git push origin --tags
```

The tag workflow publishes the multi-arch images to GHCR, binaries with `SHA256SUMS`, and the GitHub release. Bump `version` in `helm/minio/Chart.yaml` when the chart itself changed.

## If upstream ever resumes

```sh
git remote add upstream https://github.com/minio/minio.git
git fetch upstream
```

Review its changes before merging: they would bring back the update server, SUBNET and callhome code paths that this fork disabled (see `FORK_CHECKLIST.md`, Phase 2).
