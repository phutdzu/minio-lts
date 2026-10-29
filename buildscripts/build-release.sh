#!/usr/bin/env bash
#
# Builds fork release binaries for several platforms into ./dist together with
# a SHA256SUMS file. Everything is built from the vendored sources, offline.
#
#   PLATFORMS="linux/amd64 linux/arm64" buildscripts/build-release.sh

set -euo pipefail

cd "$(dirname "$0")/.."

PLATFORMS="${PLATFORMS:-linux/amd64 linux/arm64 linux/ppc64le darwin/amd64 darwin/arm64 windows/amd64}"
DIST="${DIST:-dist}"

export CGO_ENABLED=0
export MINIO_RELEASE=FORK

LDFLAGS="$(go run buildscripts/gen-ldflags.go)"

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
done

(
	cd "${DIST}"
	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum minio-* >SHA256SUMS
	else
		shasum -a 256 minio-* >SHA256SUMS
	fi
)

echo "Wrote ${DIST}/SHA256SUMS"
