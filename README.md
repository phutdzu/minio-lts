# MinIO LTS

[![CI](https://github.com/phutdzu/minio-lts/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/phutdzu/minio-lts/actions/workflows/ci.yml)
[![Security scan](https://github.com/phutdzu/minio-lts/actions/workflows/security.yml/badge.svg?branch=main)](https://github.com/phutdzu/minio-lts/actions/workflows/security.yml)
[![Release](https://img.shields.io/github/v/release/phutdzu/minio-lts?label=release)](https://github.com/phutdzu/minio-lts/releases/latest)

An unofficial, self-maintained continuation of the MinIO community edition: a high-performance, S3-compatible object storage server written in Go. Prebuilt binaries and container images are published from this repository.

> [!IMPORTANT]
> This project is **not affiliated with or endorsed by MinIO, Inc.**
> Upstream [`minio/minio`](https://github.com/minio/minio) is no longer maintained and no longer ships binaries or container images.
> This project keeps the source buildable and upgrades dependencies when vulnerabilities are found. It is maintained by one person: no support, no response time and no data guarantee are promised, and "LTS" is only a name. Use it at your own risk (see [License](#license)).

## Quick start

Pick one, the full guide is in **[INSTALL.md](INSTALL.md)**.

**Docker**

```sh
docker run -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER=admin -e MINIO_ROOT_PASSWORD=change-me-please \
  -v minio-data:/data \
  ghcr.io/phutdzu/minio-lts-server:latest server /data --console-address :9001
```

**Linux binary**

```sh
curl -fsSLO https://github.com/phutdzu/minio-lts/releases/latest/download/minio-linux-amd64
curl -fsSLO https://github.com/phutdzu/minio-lts/releases/latest/download/SHA256SUMS
grep ' minio-linux-amd64$' SHA256SUMS | sha256sum -c -
chmod +x minio-linux-amd64
MINIO_ROOT_USER=admin MINIO_ROOT_PASSWORD=change-me-please \
  ./minio-linux-amd64 server ./data --console-address :9001
```

**Kubernetes**: Helm chart in [`helm/minio`](helm/minio), see [INSTALL.md](INSTALL.md#kubernetes-helm).

Then open the console at <http://localhost:9001> or use any S3 client, for example [`mc`](INSTALL.md#first-steps-with-mc). Without `MINIO_ROOT_USER`/`MINIO_ROOT_PASSWORD` the server falls back to the well-known `minioadmin:minioadmin`, never use that outside of local testing.

## What you get

| | Where |
|---|---|
| Server image | `ghcr.io/phutdzu/minio-lts-server` (linux/amd64, linux/arm64) |
| Client (`mc`) image | `ghcr.io/phutdzu/minio-lts-client` (linux/amd64, linux/arm64) |
| Binaries | [GitHub Releases](https://github.com/phutdzu/minio-lts/releases): `minio` and `mc` for linux (amd64, arm64, ppc64le), macOS (amd64, arm64), windows (amd64), with `SHA256SUMS` |
| Kubernetes | [Helm chart](helm/minio) |

Versions look like `LTS.<UTC commit time>`, e.g. `LTS.2026-11-01T04-07-36Z`. It is the git tag, the image tag and what `minio --version` prints. Pin a full version for anything you keep running, `latest` is the newest release.

## What differs from upstream

- All dependencies are vendored in [`vendor/`](vendor), so the build works offline and does not depend on upstream repositories staying online.
- **In-place update is removed from the server code.** There is no reference to `dl.min.io` left in this repository's Go code and the upstream signing key was removed.
- **Callhome and SUBNET are switched off in the server code** (callhome is hard-coded off). The libraries vendored from MinIO (the web console, the `mc` client, `madmin-go`) were not audited, and `mc update` still points at `dl.min.io`. Network traffic of a release has not been captured and checked, if that matters to you, block outbound access and test.
- Dependencies and Go are kept current, `govulncheck` runs on every change and weekly.
- **The web console is an object browser only.** The console bundled with the 2025-09 community code has no pages for users, policies, access keys or settings. Manage them with `mc admin`, see [INSTALL.md](INSTALL.md#first-steps-with-mc). It still shows the upstream MinIO logo, "Community Edition" and links to MinIO's commercial license page, and nobody has checked yet whether it contacts `min.io`.
- Release binaries are not signed (checksums only) and there are no `.deb`/`.rpm` packages yet.

## Tested

Checked on the release `LTS.2026-11-03T07-00-07Z` and the one before it, by hand, not by an automated suite:

- **Binaries and images** (anonymous pull): linux/arm64 on macOS and linux/amd64 on Ubuntu. Version string, health check, S3 round trip with `mc`, data kept after restart, container removal and `SIGKILL`.
- **Upgrade from `RELEASE.2025-04-08T15-41-24Z`** on a copy of a real volume: about 85 GB, about 44,000 objects with versions, 8 buckets, one drive. The new image started on the old volume, listed the same objects, versions and total size as the old server, showed no errors in its log, and served files (an image preview in the console). On a small test volume, users, a read-only policy and bucket versioning also survived.

Not tested, so do not assume it works: an application running against it, multi-node or multi-drive (erasure coded) setups, replication, lifecycle rules, KMS/encryption, downgrading back to the old release after the new one wrote to the volume, ppc64le and Windows binaries, the Helm chart on a real cluster, the systemd unit in [INSTALL.md](INSTALL.md). Copy the volume first and try it on the copy.

## Security status

The images are scanned for known vulnerabilities (Trivy) every week and after every release, the way a registry shows a severity bar:

- **Current findings:** the repository's [Security tab > Code scanning](https://github.com/phutdzu/minio-lts/security/code-scanning), one entry per CVE with the affected package, the installed version and the version that fixes it.
- **Per release:** the release notes list the vulnerability counts found in the binaries when it was built.
- **The "Security scan" badge** turns red only for a CRITICAL vulnerability that already has a fixed version. HIGH, MEDIUM and LOW findings do not turn it red, read the Security tab, it is the full picture.
- Dependency updates arrive as Dependabot pull requests.

Fixes are welcome: upgrade the vulnerable module (see [CONTRIBUTING.md](CONTRIBUTING.md#dependencies)) and open a pull request, or open an issue for a finding you want to discuss. Report new vulnerabilities in this project's own code privately, see [SECURITY.md](SECURITY.md).

## Documentation

| | |
|---|---|
| [INSTALL.md](INSTALL.md) | install (Docker, Linux/systemd, macOS, Windows, Helm), first steps, production checklist, upgrade |
| [CONTRIBUTING.md](CONTRIBUTING.md) | build from source, run the tests, send a pull request |
| [SECURITY.md](SECURITY.md) | report a vulnerability, which versions get fixes |
| [MAINTENANCE.md](MAINTENANCE.md) | maintainer routine: CVE fixes, Go upgrades, cutting a release |
| [FORK_CHECKLIST.md](FORK_CHECKLIST.md) | project history and decisions |
| [`docs/`](docs) | carried over from upstream, still describes upstream behaviour: features removed here (in-place update, callhome, SUBNET licensing) are described there as if available |

## Origin

|  |  |
|---|---|
| Upstream | <https://github.com/minio/minio> |
| Forked from | `7aac2a2c5` (upstream `master`, 2026-02-12) |
| Last upstream release tag | `RELEASE.2025-10-15T17-29-55Z` |

## License

- Source code: [GNU AGPLv3](LICENSE), copyright MinIO, Inc. and contributors, see [NOTICE](NOTICE) and [CREDITS](CREDITS).
- Documentation in `docs/`: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

The AGPLv3 applies to this project. If you run a modified version as a network service you must offer its corresponding source to the users of that service, and redistributed binaries or images must be accompanied by the license and source. The license gives no warranty and no support obligation. Check with your own legal counsel whether your use complies.
