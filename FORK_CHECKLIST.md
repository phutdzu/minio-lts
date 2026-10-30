# Fork cleanup checklist

Tracking file for turning the archived upstream `minio/minio` source into a self-maintained fork, hosted on GitHub (`phutdzu/minio-fork`) since 2026-10-30 (GitLab was the first target).
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
- [x] 2.6 Fix tests broken by 2.1-2.5 (`cmd/update_test.go`, `cmd/update-notifier_test.go`, ...)

## Phase 3 - Repo hygiene

- [x] 3.1 Remove dead Dockerfiles (`Dockerfile`, `.release`, `.release.old_cpu`, `.hotfix`, `.cicd`), `docker-buildx.sh`
- [x] 3.2 Remove Makefile targets that depend on them (`hotfix*`, `docker-hotfix*`, old `docker`)
- [x] 3.3 Archive then remove `.github/` (list jobs worth porting to GitLab CI first)
- [x] 3.4 Remove Helm repo leftovers: `helm-releases/`, `index.yaml`, `helm-reindex.sh`
- [x] 3.5 Remove site leftovers: `CNAME`, `_config.yml` (`update-credits.sh` and `.mailmap` kept on purpose, see log)
- [x] 3.6 Rewrite `README.md` (fork purpose, build, upstream origin + commit, AGPLv3)
- [x] 3.7 Rewrite/trim `CONTRIBUTING.md`, `PULL_REQUESTS_ETIQUETTE.md`, `SECURITY.md`, `VULNERABILITY_REPORT.md`, `code_of_conduct.md`
- [x] 3.8 Check `LICENSE`/`NOTICE`/`CREDITS` kept intact (AGPLv3 obligations)

## Phase 4 - Build artifacts (after repo is clean)

- [x] 4.1 New multi-stage `Dockerfile` building from source
- [x] 4.2 Multi-arch image (amd64/arm64) build
- [x] 4.3 Binary builds for linux/amd64, linux/arm64 (+ others as needed), with checksums
- [~] 4.4 `.github/workflows/ci.yml` (was `.gitlab-ci.yml`): lint, test, govulncheck, build binaries, build+push image
- [~] 4.5 Publish to GHCR (`ghcr.io/phutdzu/minio-fork`) and GitHub Releases

## Phase 5 - Helm & later

- [x] 5.1 Repoint `helm/minio/values.yaml` images to our registry
- [x] 5.2 Decide on `mc` image source (separate upstream repo)
- [x] 5.3 Replace hardcoded `docs.min.io` / `play.min.io` / `slack.min.io` text in code
- [x] 5.4 Recurring security routine: `govulncheck`, Go patch upgrades, dependency bumps

## Phase 6 - Open items found on re-check (2026-10-29)

- [ ] 6.1 Integration scripts still download upstream artifacts and would break if `dl.min.io` goes away: `buildscripts/minio-iam-ldap-upgrade-import-test.sh` (old minio binary), `docs/site-replication/run-*.sh` (4 scripts, `mc` binary). Point them at our `mc` binary / image or at a release of this fork before porting those suites to CI.
- [ ] 6.2 `docs/orchestration/docker-compose/docker-compose.yaml`, `docs/site-replication/ldap.yaml` and `docs/docker/README.md` use `quay.io/minio/*` images.
- [ ] 6.3 `cmd/update.go` `getDownloadURL` still returns `podman pull quay.io/minio/minio:<tag>` (unreachable, update is disabled).
- [x] 6.4 `TestTrackingResponseWriter` fixed (status 299 instead of 1xx), tests pass on Go 1.26
- [x] 6.5 First pipeline run on GitLab: fix red jobs, then drop `allow_failure` from `lint` and `govulncheck`.
- [ ] 6.6 Publish the first `FORK.<time>` tag, create the weekly pipeline schedule, install the Helm chart on a real cluster.

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
| 2026-10-29 | 2.6 | Full `go test ./cmd/` (210s): only `TestTrackingResponseWriter` fails. It also fails on the untouched upstream commit `7aac2a2c5` with the same message (Go 1.26 net/http no longer allows a body for that status), so it is a pre-existing toolchain issue, not caused by Phase 2. TODO: fix test or pin Go 1.24 in CI. |
| 2026-10-29 | 3.1/3.2 | Removed `Dockerfile`, `.cicd`, `.hotfix`, `.release`, `.release.old_cpu`, `docker-buildx.sh` (all pulled upstream images/binaries) and Makefile targets `hotfix*`, `docker-hotfix*`, `docker`. Kept `Dockerfile.scratch` and `dockerscripts/` (entrypoint, static curl) as inputs for 4.1. `VERSION/REPO/TAG` Makefile vars kept for 4.x. |
| 2026-10-29 | 3.3 | Removed `.github/` (still in git history at `61c6f5319`, e.g. `git show 61c6f5319:.github/workflows/go-lint.yml`). Job map to port in 4.4 below. |
| 2026-10-29 | 3.4/3.5 | Removed `helm-releases/`, `index.yaml`, `helm-reindex.sh`, `CNAME`, `_config.yml`. Kept `update-credits.sh` (regenerates `CREDITS`, needed to keep license credits current) and `.mailmap` (clean `git shortlog` attribution). |
| 2026-10-29 | 3.6-3.8 | Rewrote `README.md`, `CONTRIBUTING.md`, `SECURITY.md`; removed `PULL_REQUESTS_ETIQUETTE.md`, `VULNERABILITY_REPORT.md`, `COMPLIANCE.md` (upstream-specific); `code_of_conduct.md` contact changed to confidential GitLab issue; `NOTICE` got a fork note appended. `LICENSE`, `CREDITS` and original `NOTICE` text untouched (AGPLv3). README states the fork is unofficial/not affiliated. `docs/` is still upstream text (describes removed features), left as is. |

### CI jobs to port to `.gitlab-ci.yml` (from the removed GitHub workflows)

All used Go `1.24.x` on ubuntu. Run order suggestion: lint/test first, slow suites on schedule or manual.

| Priority | GitHub workflow | What it ran | Notes |
|---|---|---|---|
| must | `go-lint.yml` | `make test`, `make test-race` | Known failing test `TestTrackingResponseWriter` on Go 1.26, pin Go 1.24 or fix the test |
| must | `vulncheck.yml` | `govulncheck -show verbose ./...` | Core of the security routine (5.4) |
| must | `go-cross.yml` | `make crosscompile` | Cheap build matrix check |
| should | `typos.yml`, `shfmt.yml` | spelling, shell format | `vendor/` already excluded from typos |
| should | `helm-lint.yml` | `helm lint` on `helm/minio` | Keep, chart is retained |
| should | `go.yml` | `make verify`, `make test-timeout` | Functional tests |
| later | `go-healing.yml` | `make verify-healing*` (4 targets) | Slow |
| later | `replication.yaml` | `make test-decom/ilm/pbac/configfile/replication/site-replication-minio` | Slow, needs docker-less setup |
| later | `go-resiliency.yml` | `make test-resiliency` | Needs docker + built image |
| later | `iam-integrations.yaml`, `root-disable.yml`, `upgrade-ci-cd.yaml` | `make test-iam`, `test-root-disable`, `test-upgrade` | IAM needs LDAP/etcd/dex service containers from `quay.io/minio/*` which may be gone |
| drop | `mint.yml`, `depsreview.yaml`, `issues.yaml`, `lock.yml`, `stale.yml` | mint S3 compat (needs `minio/mint` image + built image), GitHub dependency review, issue bots | Mint worth revisiting after 4.x if `minio/mint` still pulls |
| 2026-10-29 | 4.1 | New multi-stage `Dockerfile`: `golang:1.24-alpine` build stage (`--platform=$BUILDPLATFORM`, offline `-mod=vendor`, `-trimpath`, `-tags kqueue`) + plain `alpine:3.22` runtime that only `COPY`s (no `RUN`, so no QEMU needed for foreign arch). `COMMIT_ID`/`COMMIT_TIME` build args are required because `.git` is not in the context; `buildscripts/gen-ldflags.go` got `MINIO_COMMIT_ID`/`MINIO_COMMIT_TIME` env overrides for that. Removed `Dockerfile.scratch` and `dockerscripts/download-static-curl.sh`. Decisions: base alpine, runs as root like upstream, no `mc`/`curl` in image, labels are OCI (`minio-fork`), `MINIO_UPDATE_MINISIGN_PUBKEY` env dropped. |
| 2026-10-29 | 4.1/4.2 verified | Built on an arm64 host: `linux/arm64` image 158MB, runs, `minio --version` = `FORK.2026-10-29T08-55-58Z` on go1.24.13, health 200, console 200, S3 round trip OK (create bucket, put, get, unsigned get = 403). `linux/amd64` image built on the same host and `minio --version` runs under QEMU. |
| 2026-10-29 | 4.3 | `buildscripts/build-release.sh` + `make release-binaries` -> `dist/minio-<os>-<arch>` and `SHA256SUMS` for linux amd64/arm64/ppc64le, darwin amd64/arm64, windows amd64 (`dist/` is git-ignored). Verified for linux/arm64 (static ELF, 99MB) and windows/amd64 (PE32+); the other 4 platforms built earlier in Phase 1 but were not re-run through this script. No minisign signing (upstream key is gone), integrity via SHA256SUMS only. |
| 2026-10-29 | 4.4 | `.gitlab-ci.yml`: vendor-check, verify-tag, lint (golangci-lint v2.5.0 image), unit-test, govulncheck (v1.1.4), helm-lint, binaries, image (buildx multi-arch, dind), upload-binaries, release. YAML parsed and stage/needs checked locally, **never run on a GitLab runner**. `lint`, `govulncheck`, `helm-lint` are `allow_failure: true` until proven green. Not verified locally: the golangci-lint config under v2.5.0 (running its installer in a container was blocked), govulncheck results, image tags `curlimages/curl:8.11.1`, `alpine/helm:3.17.0`, release-cli. |
| 2026-10-29 | 4.5 | Publishing is wired in CI (container registry `$CI_REGISTRY_IMAGE`, generic package registry, release links) but nothing has been published. Makefile: `REPO` now `registry.gitlab.com/phucdzu-resource`, new targets `version`, `docker`, `docker-multiarch`, `release-binaries`. Release flow: `git tag "$(make -s version)"` then push the tag (job `verify-tag` enforces tag == FORK.<UTC commit time>). |
| 2026-10-29 | 4.4 test run on Go 1.24 | `golang:1.24` container on a Docker VM with 3GB RAM / 2 CPU: `go test ./...` killed the compiler (`signal: killed`) when building the `cmd` test binary, also with `-p 1` and a single test selected, so it is memory, not code. Could not confirm whether `TestTrackingResponseWriter` passes on Go 1.24 (still open). `internal/grid` `TestStreamSuite/testServerStreamTwowayPingReq` failed once under load and passed 3/3 when run alone (flaky). **CI runners need roughly 4GB+ RAM to build the `cmd` tests**, check the runner size before trusting the `unit-test` job. |
| 2026-10-29 | 5.1 | Helm chart: `Chart.yaml` version 5.5.0, appVersion `latest`, home/sources/maintainers point at the GitLab project, MinIO logo and `dev@minio.io` removed. `values.yaml`: `image` -> `registry.gitlab.com/phucdzu-resource/minio:latest`, `mcImage` -> `.../minio/mc:latest`, pullPolicy `Always` (pin a `FORK.<time>` tag in production). Chart README rewritten for installing from a checkout (`./helm/minio`), no Helm repo is published. Verified with `alpine/helm:3.17.0`: `helm lint` passes (only "icon is recommended"), `helm template` renders our images for distributed, standalone and with-buckets (post-job) cases. Not done: installing into a real cluster. |
| 2026-10-29 | 5.2 | `mc` source: instead of depending on a separate `minio/mc` image, `tools/mc/main.go` builds the already vendored `github.com/minio/mc/cmd` (go.mod: mc moved from indirect to direct, vendor unchanged). Dockerfile has targets `mc` and `minio` (default); `make docker-mc`; `build-release.sh` also emits `mc-<os>-<arch>`; CI builds and pushes `$CI_REGISTRY_IMAGE/mc`. Verified: 54MB image, `mc --version` = `FORK.<time>`, and the chart's own commands (`alias set`, `mb`, `pipe`, `ls`, `admin info`) work against a fork server over a Docker network. mc's startup update check is off because it only runs for `RELEASE.*` tags; explicit `mc update` still targets `dl.min.io` (not removed). |
| 2026-10-29 | 5.3 | Replaced the misleading "Please contact MinIO at https://slack.min.io" error text. Left `docs.min.io` links (informational) and the `play.min.io` example comment. Also ran `gofmt` on `internal/config/subnet/config_test.go` (Phase 2 file with a stray blank line). |
| 2026-10-29 | 5.4 | Added `MAINTENANCE.md`: weekly scheduled pipeline (govulncheck + image rebuild), monthly Go patch bump, dependency fix procedure, base image, release steps, what to review if upstream resumes. The GitLab schedule itself still has to be created in the UI. `helm-lint` CI job is no longer `allow_failure` (ran green locally). |
| 2026-10-29 | re-check | Working tree clean, 16 commits on `fork/cleanup` since `7aac2a2c5`, `go build ./...`, `go vet` and gofmt clean, vendor in sync (8541 files tracked, 0 ignored), fork tests pass, CI yaml parses (10 jobs, `allow_failure` only on `lint` and `govulncheck`). Fixed: 2.6 was still unchecked although done. Found: Phase 6 items above. |
| 2026-10-30 | move to GitHub | Decision: GitHub instead of GitLab (free unlimited CI and anonymous GHCR pulls for public repos, larger community). Repo `git@github.com:phutdzu/minio-fork.git`. `.gitlab-ci.yml` replaced by `.github/workflows/ci.yml` with the same jobs (vendor-check, verify-tag, lint, unit-test, govulncheck, helm-lint, binaries, image, release); `lint` and `govulncheck` are `continue-on-error`. Images: `ghcr.io/phutdzu/minio-fork` and `ghcr.io/phutdzu/minio-fork/mc` (Makefile `REPO`, Helm values, README, `org.opencontainers.image.source` label). Binaries and `SHA256SUMS` go to the GitHub release. Weekly schedule is built into the workflow (also rebuilds `edge`). SECURITY.md/code_of_conduct.md now use GitHub private vulnerability reporting. **Workflow never run, nothing pushed yet.** Manual steps after the first push: enable Actions write permission, enable private vulnerability reporting, make the GHCR packages public (first push creates them private) and link them to the repo, protect tags `FORK.*`. |
| 2026-10-30 | CI #1 | First GitHub Actions run (Actions had to be enabled in the repo first): vendor-check, lint, unit-test, helm-lint, binaries, image green; verify-tag/release skipped (not a tag); `govulncheck` red. `lint` and `unit-test` were never proven before, both pass on Go 1.24.13. |
| 2026-10-30 | govulncheck | Local run (Go 1.26.5) found 54 reachable vulnerabilities, 9 modules plus stdlib. Upgraded `golang.org/x/{crypto,net,text,sys,sync,term,mod,tools}`, `rabbitmq/amqp091-go` 1.14.0, `google.golang.org/grpc` 1.83.1, `otel/sdk` 1.45.0, `prometheus/prometheus` 0.311.3, `go-jose/v4` 4.1.4, `paho.mqtt.golang` 1.5.1 (plus their transitive deps). The new `x/*` versions require Go 1.26, so `go.mod` is now `go 1.26.0` (toolchain line dropped), `Dockerfile`/`ci.yml` use Go 1.26. After the upgrade govulncheck reports only stdlib issues (fixed by the latest 1.26 patch, the local toolchain is 1.26.5). `go build ./...`, `go vet`, full `go test ./...` pass. Fixed on the way: `TestTrackingResponseWriter` used status 123 (1xx, no body allowed on Go 1.26), now 299; `%q` of a struct pointer in `internal/grid/grid_test.go` (vet). **`go mod tidy` now fails on an unresolvable test-only import in `go-openapi/swag`, use `go mod tidy -e`** (CI vendor-check updated). Still to confirm on CI: govulncheck green on the 1.26 runner, then drop `continue-on-error`. |
| 2026-10-30 | lint | CI `lint` failed with `golangci-lint exit with code 3` (tool could not run): v2.5.0 was built with a Go older than the module's `go 1.26`. Moved CI to golangci-lint v2.15.0 (run locally with the repo `.golangci.yml`: it runs and found 19 real issues, 11 gofumpt + 8 staticcheck, all in existing upstream code). Fixed all: `golangci-lint fmt` over 12 files, `fmt.Fprintf` instead of `WriteString(Sprintf)` in `cmd/iam-object-store.go` and `cmd/server_test.go`, dropped three dead assignments in `cmd/os-readdir_test.go`, split the return in `internal/ioutil/wait_pipe.go`. Result: 0 issues, build and the related tests pass. `govulncheck` was green on CI after the module upgrade (checked through the public API). Left: golangci-lint warns that linter `gomodguard` is deprecated (replaced by `gomodguard_v2`). |
| 2026-10-30 | CI green | CI on `main` (`9243914e8`) fully green: vendor-check, lint, unit-test, govulncheck, helm-lint, binaries, image (verify-tag/release skipped, not a tag). `continue-on-error` removed from `lint` and `govulncheck`, they now gate merges. GHCR packages `minio-fork` and `minio-fork/mc` exist with tags `edge`, `<sha>` and are publicly pullable (anonymous token lists the tags). No release/tag yet. |

