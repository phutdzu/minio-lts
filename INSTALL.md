# Install and first steps

How to install and run the binaries and container images published by this repository. Everything here uses the [releases](https://github.com/phutdzu/minio-lts/releases) and the images on GHCR, nothing is downloaded from MinIO, Inc.

- [Which method?](#which-method)
- [Versions](#versions)
- [Docker](#docker)
- [Linux binary and systemd](#linux-binary-and-systemd)
- [macOS and Windows](#macos-and-windows)
- [Kubernetes (Helm)](#kubernetes-helm)
- [First steps with `mc`](#first-steps-with-mc)
- [Before production](#before-production)
- [Upgrade and uninstall](#upgrade-and-uninstall)
- [Differences from upstream](#differences-from-upstream)

## Which method?

| You have | Use |
|---|---|
| A machine with Docker | [Docker](#docker) |
| A Linux server, no containers | [Linux binary and systemd](#linux-binary-and-systemd) |
| A Kubernetes cluster | [Helm](#kubernetes-helm) |
| A laptop for trying it out | [Docker](#docker) or the binary for your OS |

## Versions

Every release has the version `LTS.<UTC commit time>`, for example `LTS.2026-11-01T04-07-36Z`. The same string is the git tag, the image tag and what `minio --version` prints.

- `latest` always points to the newest release. Fine for trying it out.
- For anything you keep running, **pin the full version** so upgrades happen when you decide.

The newest version is shown on the [releases page](https://github.com/phutdzu/minio-lts/releases/latest). "LTS" is only a label, it does not promise long term support, see [SECURITY.md](SECURITY.md).

## Docker

Two images, both for `linux/amd64` and `linux/arm64`:

| Image | What |
|---|---|
| `ghcr.io/phutdzu/minio-lts-server` | the object storage server |
| `ghcr.io/phutdzu/minio-lts-client` | the `mc` command line client |

They are public, no login is needed to pull.

```sh
docker run -d --name minio \
  -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER=admin \
  -e MINIO_ROOT_PASSWORD=change-me-please \
  -v minio-data:/data \
  ghcr.io/phutdzu/minio-lts-server:LTS.2026-11-01T04-07-36Z \
  server /data --console-address :9001
```

- S3 API: <http://localhost:9000>
- Web console: <http://localhost:9001>, log in with the user and password above.

Docker Compose:

```yaml
services:
  minio:
    image: ghcr.io/phutdzu/minio-lts-server:LTS.2026-11-01T04-07-36Z
    command: server /data --console-address ":9001"
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      MINIO_ROOT_USER: admin
      MINIO_ROOT_PASSWORD: change-me-please
    volumes:
      - minio-data:/data
    restart: unless-stopped

volumes:
  minio-data:
```

Notes:

- The container runs as root by default, like upstream. To drop privileges use `--user 1000:1000` (or `user:` in Compose) and make sure the data directory is writable by that user. The old `MINIO_USERNAME` switching is not supported.
- There is no `curl` or `mc` inside the server image. Use the client image or a separate `mc`, see [First steps](#first-steps-with-mc).
- Use a volume or a bind mount for `/data`, otherwise the data disappears with the container.

## Linux binary and systemd

Binaries are static, there is nothing else to install. Files per release: `minio-<os>-<arch>` and `mc-<os>-<arch>` for linux (`amd64`, `arm64`, `ppc64le`), darwin (`amd64`, `arm64`) and windows (`amd64`, `.exe`), plus `SHA256SUMS`.

Download, verify, install (replace `amd64` with `arm64` or `ppc64le` if needed; `latest` in the URL means the newest release, put a version there to pin):

```sh
BASE=https://github.com/phutdzu/minio-lts/releases/latest/download
mkdir -p /tmp/minio-dl && cd /tmp/minio-dl
curl -fsSLO "$BASE/minio-linux-amd64"
curl -fsSLO "$BASE/SHA256SUMS"
grep ' minio-linux-amd64$' SHA256SUMS | sha256sum -c -     # must print: minio-linux-amd64: OK

sudo install -m 0755 minio-linux-amd64 /usr/local/bin/minio
minio --version
```

To pin a version, use `https://github.com/phutdzu/minio-lts/releases/download/LTS.2026-11-01T04-07-36Z` as `BASE`.

Run it by hand to try it out:

```sh
MINIO_ROOT_USER=admin MINIO_ROOT_PASSWORD=change-me-please \
  minio server /tmp/minio-data --console-address :9001
```

### Run as a service

Create a user and a data directory:

```sh
sudo useradd --system --no-create-home --shell /usr/sbin/nologin minio-user
sudo mkdir -p /var/lib/minio
sudo chown minio-user:minio-user /var/lib/minio
```

`/etc/default/minio` (holds the password, make it readable by root only: `sudo chmod 600 /etc/default/minio`):

```sh
MINIO_VOLUMES="/var/lib/minio"
MINIO_OPTS="--console-address :9001"
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=change-me-please
```

`/etc/systemd/system/minio.service`:

```ini
[Unit]
Description=MinIO LTS object storage
Documentation=https://github.com/phutdzu/minio-lts
Wants=network-online.target
After=network-online.target
AssertFileIsExecutable=/usr/local/bin/minio

[Service]
User=minio-user
Group=minio-user
EnvironmentFile=/etc/default/minio
ExecStart=/usr/local/bin/minio server $MINIO_OPTS $MINIO_VOLUMES
Restart=always
LimitNOFILE=1048576
TasksMax=infinity
TimeoutStopSec=infinity
SendSIGKILL=no

[Install]
WantedBy=multi-user.target
```

```sh
sudo systemctl daemon-reload
sudo systemctl enable --now minio
sudo systemctl status minio
journalctl -u minio -f
```

## macOS and Windows

Same files, pick `minio-darwin-arm64` (Apple silicon), `minio-darwin-amd64` (Intel Mac) or `minio-windows-amd64.exe`.

```sh
# macOS
curl -fsSLO https://github.com/phutdzu/minio-lts/releases/latest/download/minio-darwin-arm64
chmod +x minio-darwin-arm64
MINIO_ROOT_USER=admin MINIO_ROOT_PASSWORD=change-me-please \
  ./minio-darwin-arm64 server ~/minio-data --console-address :9001
```

```powershell
# Windows (PowerShell)
Invoke-WebRequest https://github.com/phutdzu/minio-lts/releases/latest/download/minio-windows-amd64.exe -OutFile minio.exe
$env:MINIO_ROOT_USER = "admin"; $env:MINIO_ROOT_PASSWORD = "change-me-please"
.\minio.exe server C:\minio-data --console-address :9001
```

The binaries are not code signed or notarized. If macOS blocks a file you downloaded with a browser, clear the quarantine flag after checking the checksum: `xattr -d com.apple.quarantine minio-darwin-arm64`. Windows SmartScreen may warn too. Windows and the extra platforms are mainly for trying things out, production use is on Linux (binary or container).

## Kubernetes (Helm)

The chart is not published to a Helm repository, install it from a checkout:

```sh
git clone https://github.com/phutdzu/minio-lts.git
cd minio-lts
git checkout LTS.2026-11-01T04-07-36Z        # the release you want

helm install minio ./helm/minio \
  --namespace minio --create-namespace \
  --set image.tag=LTS.2026-11-01T04-07-36Z \
  --set mcImage.tag=LTS.2026-11-01T04-07-36Z \
  --set rootUser=rootuser,rootPassword=change-me-please
```

A small throwaway setup for testing:

```sh
helm install minio ./helm/minio --set mode=standalone --set replicas=1 \
  --set persistence.enabled=false --set resources.requests.memory=512Mi \
  --set rootUser=rootuser,rootPassword=change-me-please
```

All settings are in [helm/minio/values.yaml](helm/minio/values.yaml) and explained in the [chart README](helm/minio/README.md). Do not keep passwords on the command line in real deployments, use a Kubernetes Secret (`existingSecret`, see the chart README).

## First steps with `mc`

`mc` is the command line client. Get it from the same release (`mc-<os>-<arch>`), or use the client image. Any other S3 client or SDK works as well.

```sh
# binary
curl -fsSLo mc https://github.com/phutdzu/minio-lts/releases/latest/download/mc-linux-amd64 && chmod +x mc

# or the image (note: --network host works on Linux only; on Mac/Windows use http://host.docker.internal:9000)
alias mc='docker run --rm -it --network host -v "$HOME/.mc:/tmp/.mc" ghcr.io/phutdzu/minio-lts-client:latest'
```

```sh
mc alias set local http://localhost:9000 admin change-me-please
mc mb local/photos                       # create a bucket
mc cp ./cat.jpg local/photos/            # upload
mc ls local/photos                       # list
mc cp local/photos/cat.jpg ./copy.jpg    # download
mc rm local/photos/cat.jpg               # delete
mc rb local/photos                       # remove the (empty) bucket
```

Users, access keys and policies are managed with `mc admin` (see `mc admin --help`). Create a separate user or access key per application instead of using the root user.

## Before production

- **Change the credentials.** Without `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD` the server uses `minioadmin:minioadmin`. Never expose that.
- **Use TLS**, directly (put `public.crt` and `private.key` in `~/.minio/certs` or the `--certs-dir`) or behind a reverse proxy. See [docs/tls](docs/tls/README.md).
- **Back up the data**, object storage is not a backup. Replication or `mc mirror` to another place.
- **Disks.** A single drive has no redundancy. For erasure coding give the server several drives, e.g. `server /data{1...4}`, see [docs/erasure](docs/erasure/README.md) and [docs/distributed](docs/distributed/README.md).
- **Pin the version** and read [MAINTENANCE.md](MAINTENANCE.md) for how fixes reach releases.

The pages under `docs/` are carried over from upstream and describe upstream behaviour, see [Differences from upstream](#differences-from-upstream) for what is not available here.

## Upgrade and uninstall

There is no in-place updater, you replace the binary or the image yourself. Back up first, and read the release page for the version you are moving to.

| | Upgrade | Remove |
|---|---|---|
| Docker | pull the new tag, `docker rm -f minio`, run again with the same volume | `docker rm -f minio && docker volume rm minio-data` (**deletes the data**) |
| Binary | stop the service, replace `/usr/local/bin/minio`, start | `systemctl disable --now minio`, remove the unit, binary, `/etc/default/minio`, and (**deletes the data**) `/var/lib/minio` |
| Helm | `helm upgrade minio ./helm/minio --reuse-values --set image.tag=<new>` | `helm uninstall minio` (volumes stay until you delete the PVCs) |

## Differences from upstream

- `mc admin update` and the in-place updater are disabled, the server never contacts `dl.min.io`.
- Callhome and SUBNET are disabled, nothing is sent to MinIO, Inc.
- Images are built from this repository on Alpine, with no `mc` or `curl` in the server image.
- Release binaries are unsigned (SHA256SUMS only), and there are no `.deb`/`.rpm` packages yet.

This project is unofficial and not affiliated with MinIO, Inc. See [README.md](README.md) and the [license](README.md#license).
