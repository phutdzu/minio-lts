# Security Policy

## Supported versions

Only the latest `LTS.<time>` release of this fork receives security fixes. Upstream MinIO no longer publishes fixes, so nothing is inherited from it.

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
4. A fix is prepared and released as a new `LTS.<time>` version.
5. An advisory is added to the release notes. Reporters are credited only if they ask for it.

## Dependencies and scanning

The dependency tree is vendored. Three things watch it:

- `govulncheck` (CI, every change and weekly) reports vulnerabilities the code can actually reach.
- Trivy (`security.yml`, weekly and after every release) scans the published images and lists every known CVE in the Alpine packages and in the Go modules inside the binaries, in the repository's Security tab. It fails only for a CRITICAL vulnerability that has a fixed version.
- The release workflow scans the binaries before anything is published and stops on the same condition. The counts are written into the release notes.

Findings are fixed by upgrading the module and re-running `go mod tidy && go mod vendor`. A finding in a dependency that the code never calls is still fixed, but it is not an emergency. Dependabot opens pull requests for outdated modules.
