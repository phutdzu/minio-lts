# Security Policy

## Supported versions

Only the latest `FORK.<time>` release of this fork receives security fixes. Upstream MinIO no longer publishes fixes, so nothing is inherited from it.

## Reporting a vulnerability

Please do not report security problems in public issues or pull requests.

Use GitHub **private vulnerability reporting** (the "Security" tab, "Report a vulnerability") of this repository and include:

- the type of issue (DoS, authentication bypass, information disclosure, ...),
- affected version (`minio --version`) and configuration,
- steps to reproduce, and whether credentials are needed to exploit it.

## Handling process

1. A maintainer reproduces the report and assesses the impact.
2. The report is confirmed or rejected with an explanation.
3. The code is audited for similar problems.
4. A fix is prepared and released as a new `FORK.<time>` version.
5. An advisory is added to the release notes. Reporters are credited only if they ask for it.

## Dependencies

The dependency tree is vendored. Known vulnerabilities in dependencies are tracked with `govulncheck ./...` and fixed by upgrading the module and re-running `go mod tidy && go mod vendor`.
