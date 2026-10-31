# Maintenance routine

Upstream MinIO is archived, so nothing flows in from it: security fixes, Go and dependency upgrades are our job. This file is the recurring checklist.

## Schedule

The weekly `schedule` trigger in `.github/workflows/ci.yml` (Mondays 03:00 UTC, default branch) needs no setup. It runs the same checks as a push (including `govulncheck`, which is what catches newly published CVEs). It does not build or publish anything. GitHub disables scheduled workflows after 60 days without repository activity, re-enable it under Actions if that happens.

| When | What |
|---|---|
| Weekly (scheduled workflow) | `govulncheck` job, read the result, fix anything reachable |
| Monthly | Bump the Go patch version, rebuild, cut a release if anything changed |
| On a published CVE for a dependency | Upgrade that module, see below |
| Before every release tag | CI green on `main`, `make version` matches the tag |

The `lint` and `govulncheck` jobs gate merges. A new CVE can turn `govulncheck` red without any code change: fix it by upgrading the module or the Go version, see below.

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

`ALPINE_VERSION` in the `Dockerfile` is the runtime base. Every release rebuilds on the current `alpine:<ALPINE_VERSION>` image, so cut a release when Alpine publishes security fixes, and move to the next Alpine release before the current one reaches end of life.

## Release

Check that the last commit on `main` is green, then on GitHub open Actions > CI > Run workflow, pick branch `main`, tick **release** and run it. The workflow refuses to run from another branch or when that commit already has a release.

Terminal alternative, same result:

```sh
git checkout main && git pull
git tag "$(make -s version)"
git push origin --tags
```

The workflow publishes the multi-arch images to GHCR and the GitHub release with binaries and `SHA256SUMS`, the tag `FORK.<UTC commit time>` is created by the release step. Bump `version` in `helm/minio/Chart.yaml` when the chart itself changed.

## If upstream ever resumes

```sh
git remote add upstream https://github.com/minio/minio.git
git fetch upstream
```

Review its changes before merging: they would bring back the update server, SUBNET and callhome code paths that this fork disabled (see `FORK_CHECKLIST.md`, Phase 2).
