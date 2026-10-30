# Contributing

This is a self-maintained fork, changes are made through pull requests on GitHub.

## Workflow

1. Create a branch from `master`, one topic per branch.
2. Keep each commit focused and explain the **why** in the message.
3. Run the checks below locally.
4. Open a pull request, describe the change and how you tested it.

## Setup

```sh
git clone <this repository>
cd minio
make build
```

Go 1.24 or newer is required. Dependencies are vendored, no network is needed to build.

## Checks before a pull request

```sh
make verifiers          # golangci-lint + generated-file check
make test               # build, lint, unit tests
go test ./cmd/ -run <TestName> -count=1   # a single test
```

Some end-to-end suites (`make verify-healing`, `make test-replication`, `make test-iam`, ...) need extra tooling and are slow, run the ones related to the code you touched.

Known failure: `TestTrackingResponseWriter` fails with Go 1.26 and is unrelated to your change, see [FORK_CHECKLIST.md](FORK_CHECKLIST.md).

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
