# Fork cleanup checklist

Tracking file for turning the archived upstream `minio/minio` source into a self-maintained fork hosted on GitLab.
Base commit: `7aac2a2c5` (upstream master, 2026-02-12). Work branch: `fork/cleanup`.

Legend: `[ ]` todo · `[~]` in progress · `[x]` done · `[-]` skipped (with reason)

## Decisions

- Keep Go module path `github.com/minio/minio` (381 files import it; renaming only creates merge noise).
- Keep the embedded web console for now (`github.com/minio/console`), revisit later.
- Disable self-update, callhome and SUBNET by default rather than rewriting them.
- Keep `helm/minio`, repoint images to our registry later.

## Phase 0 - Baseline

- [x] 0.1 Create work branch `fork/cleanup`
- [x] 0.2 Confirm `go build ./...` works on current toolchain
- [x] 0.3 Record baseline binary size / `--version` output

## Phase 1 - Freeze dependencies

- [x] 1.1 `go mod vendor` (or other mirror) so build does not depend on `github.com/minio/*` staying online
- [x] 1.2 Verify offline build: `go build -mod=vendor`
- [x] 1.3 Commit full `vendor/` (decision: full vendor, repo must build offline forever)

## Phase 2 - Cut ties to MinIO infrastructure (code)

- [x] 2.1 Disable self-update (`cmd/build-constants.go` `MinioReleaseBaseURL`, `cmd/update.go`, `cmd/update-notifier.go`, `cmd/server-main.go` update check)
- [x] 2.2 Remove/neutralise upstream minisign pubkey default in `cmd/update.go`
- [x] 2.3 Disable callhome by default (`cmd/callhome.go`, `internal/config/callhome`)
- [x] 2.4 Disable SUBNET license/registration (`internal/config/subnet`, `cmd/globals.go`)
- [x] 2.5 Define fork version scheme and update `buildscripts/gen-ldflags.go` / `cmd/build-constants.go`
- [ ] 2.6 Fix tests broken by 2.1-2.5 (`cmd/update_test.go`, `cmd/update-notifier_test.go`, ...)

## Phase 3 - Repo hygiene

- [ ] 3.1 Remove dead Dockerfiles (`Dockerfile`, `.release`, `.release.old_cpu`, `.hotfix`, `.cicd`), `docker-buildx.sh`
- [ ] 3.2 Remove Makefile targets that depend on them (`hotfix*`, `docker-hotfix*`, old `docker`)
- [ ] 3.3 Archive then remove `.github/` (list jobs worth porting to GitLab CI first)
- [ ] 3.4 Remove Helm repo leftovers: `helm-releases/`, `index.yaml`, `helm-reindex.sh`
- [ ] 3.5 Remove site leftovers: `CNAME`, `_config.yml`, `update-credits.sh`, `.mailmap`
- [ ] 3.6 Rewrite `README.md` (fork purpose, build, upstream origin + commit, AGPLv3)
- [ ] 3.7 Rewrite/trim `CONTRIBUTING.md`, `PULL_REQUESTS_ETIQUETTE.md`, `SECURITY.md`, `VULNERABILITY_REPORT.md`, `code_of_conduct.md`
- [ ] 3.8 Check `LICENSE`/`NOTICE`/`CREDITS` kept intact (AGPLv3 obligations)

## Phase 4 - Build artifacts (after repo is clean)

- [ ] 4.1 New multi-stage `Dockerfile` building from source
- [ ] 4.2 Multi-arch image (amd64/arm64) build
- [ ] 4.3 Binary builds for linux/amd64, linux/arm64 (+ others as needed), with checksums
- [ ] 4.4 `.gitlab-ci.yml`: lint, test, govulncheck, build binaries, build+push image
- [ ] 4.5 Publish to GitLab Container Registry / Package Registry

## Phase 5 - Helm & later

- [ ] 5.1 Repoint `helm/minio/values.yaml` images to our registry
- [ ] 5.2 Decide on `mc` image source (separate upstream repo)
- [ ] 5.3 Replace hardcoded `docs.min.io` / `play.min.io` / `slack.min.io` text in code
- [ ] 5.4 Recurring security routine: `govulncheck`, Go patch upgrades, dependency bumps

## Log

| Date | Item | Note |
|---|---|---|
| 2026-10-29 | 0.2/0.3 | Baseline `go build .` OK with local go1.26.5 (go.mod: go 1.24.0, toolchain go1.24.8). Binary 138MB, `--version` = `DEVELOPMENT.GOGET`. First build ~4 min (downloads deps, mod cache 2.1G). |
| 2026-10-29 | 1.1/1.2 | `go mod vendor` -> 128MB, 8541 files, includes all 22 `github.com/minio/*` modules. Offline build (`GOPROXY=off GOFLAGS=-mod=vendor`) OK, 52s. `vendor/` is currently git-ignored (`.gitignore:12`). |
| 2026-10-29 | 1.3 | Decision: commit full `vendor/` (128MB, 8541 files). |
| 2026-10-29 | 1.x checks | `go mod verify` OK; `go mod tidy` no diff; offline build OK for linux/{amd64,arm64}, windows/amd64, darwin/amd64, freebsd/amd64; `go vet ./cmd/ ./internal/...` clean. |
| 2026-10-29 | 1.x gotcha | `.gitignore` patterns `mc` and `xattr` were unanchored and silently ignored `vendor/github.com/minio/mc` and `vendor/github.com/pkg/xattr` (384 files). Anchored all bare binary names to repo root (`/mc`, `/xattr`, ...). Always check `git ls-files --others --ignored --exclude-standard vendor` is empty after `go mod vendor`. |
| 2026-10-29 | 1.x | Added `vendor/` to `.typos.toml` extend-exclude. After any dependency change: `go mod tidy && go mod vendor` and commit both. |
| 2026-10-29 | 2.1/2.2 | `globalInplaceUpdateDisabled` is now always true (blocks startup update check + both admin `/update` handlers -> 405). `MinioReleaseBaseURL` and `defaultMinisignPubkey` emptied; `verifyBinary` fails closed without a pubkey. Added `TestInplaceUpdateDisabledByDefault`. `MINIO_UPDATE` env is now ignored. Unreachable leftovers kept: `getDownloadURL` still mentions `quay.io/minio/minio`. |
| 2026-10-29 | 2.3/2.4 | Callhome and SUBNET were already off by default and inert without an API key. Hardened anyway: `callhomeSupported = false` (initCallhome never starts), enabling callhome via config is rejected, SUBNET `baseURL` emptied so requests cannot reach `subnet.min.io`. Tests: `TestCallhomeRejected`, `subnet.TestBaseURLIsEmpty`. `mc license register` and the console SUBNET UI now fail instead of contacting upstream. |
| 2026-10-29 | 2.5 | Version scheme: official fork builds use `MINIO_RELEASE=FORK` -> `ReleaseTag=FORK.<UTC commit time>` (e.g. `FORK.2026-10-29T06-55-51Z`); local dev builds stay `DEVELOPMENT.<time>`. Fork git tags and image tags use the same `FORK.<time>` string. Makefile `VERSION` now uses `git describe --match 'FORK.*' --always` so the 523 upstream `RELEASE.*` tags are ignored. `Copyright ... MinIO, Inc.` kept on purpose (AGPL). |
| 2026-10-29 | 2.x smoke | Built with `MINIO_RELEASE=FORK`, started a 1-drive server: health 200, console 200, no update message in log, no outbound sockets. Not covered: calling admin `/update` with a signed request (covered by unit logic only). |
| 2026-10-29 | NOTE for 4.1 | `buildscripts/gen-ldflags.go` runs `git log` and exits 1 without `.git`; `.dockerignore` excludes `.git`. The Dockerfile build must receive ldflags/commit as build args (or keep `.git` in context). Also Makefile `REPO ?= quay.io/minio` must be repointed in Phase 4. |
