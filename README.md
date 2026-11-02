# MinIO LTS

An unofficial, self-maintained continuation of the MinIO community edition: a high-performance, S3-compatible object storage server written in Go. Prebuilt binaries and container images are published from this repository.

> [!IMPORTANT]
> This project is **not affiliated with or endorsed by MinIO, Inc.**
> Upstream [`minio/minio`](https://github.com/minio/minio) is no longer maintained and no longer ships binaries or container images.
> This project keeps the source buildable, fixes security issues and may add features. "LTS" is only a name, there is no support promise. Use it at your own risk (see [License](#license)).

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
- **In-place update is disabled.** The server never contacts `dl.min.io` and the upstream signing key was removed.
- **Callhome and SUBNET are disabled.** Nothing is sent to MinIO, Inc. services.
- Dependencies and Go are kept current, `govulncheck` runs on every change and weekly.
- Release binaries are not signed (checksums only) and there are no `.deb`/`.rpm` packages yet.

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
