# syntax=docker/dockerfile:1

# Builds MinIO from the vendored source tree, nothing is downloaded from
# upstream. Cross compilation runs natively on the build host, so the final
# stage only copies files and needs no emulation for foreign architectures.
#
#   docker build \
#     --build-arg COMMIT_ID=$(git rev-parse HEAD) \
#     --build-arg COMMIT_TIME=$(git log -1 --format=%cI) \
#     -t minio:dev .
#
# `make docker` and `make docker-multiarch` do this for you.

ARG GO_VERSION=1.24
ARG ALPINE_VERSION=3.22

FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS build

ARG TARGETOS
ARG TARGETARCH
# Required: .git is not part of the build context.
ARG COMMIT_ID
ARG COMMIT_TIME

ENV CGO_ENABLED=0 \
    GOFLAGS=-mod=vendor \
    GOPROXY=off \
    GOTOOLCHAIN=local

WORKDIR /src
COPY . .

RUN test -n "${COMMIT_ID}" && test -n "${COMMIT_TIME}" \
    || { echo "COMMIT_ID and COMMIT_TIME build args are required" >&2; exit 1; }; \
    LDFLAGS="$(MINIO_RELEASE=FORK MINIO_COMMIT_ID="${COMMIT_ID}" MINIO_COMMIT_TIME="${COMMIT_TIME}" go run buildscripts/gen-ldflags.go)" && \
    GOOS="${TARGETOS}" GOARCH="${TARGETARCH}" \
    go build -tags kqueue -trimpath -ldflags "${LDFLAGS}" -o /out/minio .

FROM alpine:${ALPINE_VERSION}

ARG COMMIT_ID
ARG COMMIT_TIME

LABEL org.opencontainers.image.title="minio-fork" \
      org.opencontainers.image.description="Unofficial self-maintained fork of the MinIO community edition, S3 compatible object storage" \
      org.opencontainers.image.licenses="AGPL-3.0-only" \
      org.opencontainers.image.revision="${COMMIT_ID}" \
      org.opencontainers.image.created="${COMMIT_TIME}"

ENV MINIO_ACCESS_KEY_FILE=access_key \
    MINIO_SECRET_KEY_FILE=secret_key \
    MINIO_ROOT_USER_FILE=access_key \
    MINIO_ROOT_PASSWORD_FILE=secret_key \
    MINIO_KMS_SECRET_KEY_FILE=kms_master_key \
    MINIO_CONFIG_ENV_FILE=config.env

COPY --from=build /out/minio /usr/bin/minio
COPY --chmod=0755 dockerscripts/docker-entrypoint.sh /usr/bin/docker-entrypoint.sh
COPY CREDITS LICENSE NOTICE /licenses/

EXPOSE 9000
VOLUME ["/data"]

ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]
CMD ["minio"]
