#!/usr/bin/env bash
#
# Builds fork release binaries (minio and mc) for several platforms into ./dist
# together with a SHA256SUMS file. Everything is built from the vendored sources, offline.
#
#   PLATFORMS="linux/amd64 linux/arm64" buildscripts/build-release.sh

set -euo pipefail

cd "$(dirname "$0")/.."

PLATFORMS="${PLATFORMS:-linux/amd64 linux/arm64 linux/ppc64le darwin/amd64 darwin/arm64 windows/amd64}"
DIST="${DIST:-dist}"

export CGO_ENABLED=0
export MINIO_RELEASE=LTS

LDFLAGS="$(go run buildscripts/gen-ldflags.go)"
# mc has the same version variables, only the package path differs.
MC_LDFLAGS="${LDFLAGS//github.com\/minio\/minio\/cmd/github.com\/minio\/mc\/cmd}"

rm -rf "${DIST}"
mkdir -p "${DIST}"

for osarch in ${PLATFORMS}; do
	os="${osarch%/*}"
	arch="${osarch#*/}"
	ext=""
	if [ "${os}" = "windows" ]; then
		ext=".exe"
	fi
	out="${DIST}/minio-${os}-${arch}${ext}"
	printf -- "--> %-16s %s\n" "${osarch}" "${out}"
	GOOS="${os}" GOARCH="${arch}" go build -tags kqueue -trimpath -ldflags "${LDFLAGS}" -o "${out}" .

	mc_out="${DIST}/mc-${os}-${arch}${ext}"
	printf -- "--> %-16s %s\n" "${osarch}" "${mc_out}"
	GOOS="${os}" GOARCH="${arch}" go build -trimpath -ldflags "${MC_LDFLAGS}" -o "${mc_out}" ./tools/mc
done

(
	cd "${DIST}"
	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum minio-* mc-* >SHA256SUMS
	else
		shasum -a 256 minio-* mc-* >SHA256SUMS
	fi
)

echo "Wrote ${DIST}/SHA256SUMS"
