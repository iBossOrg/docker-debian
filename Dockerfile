ARG BASE_IMAGE=debian
ARG ENTRYPOINT_IMAGE=iboss/entrypoint-overlay
FROM ${ENTRYPOINT_IMAGE} AS entrypoint
FROM ${BASE_IMAGE}

ENV \
  CHARSET="UTF-8" \
  LANG="en_US.UTF-8"

ARG SU_EXEC_VERSION=0.2

RUN set -ex; \
  # Get APT cache
  # export DEBIAN_FRONTEND="noninteractive"; \
  apt-get update; \
  # Install packages
  apt-get install --yes --no-install-recommends \
    ca-certificates \
    curl \
    less \
    locales \
    ncat \
    openssl \
    procps \
    tini \
    ; \
  # Use /bin/bash instead of /bin/dash as a shell
  ln -sf /bin/bash /bin/sh; \
  # Set locale
  sed -i -E "s/^[# ]*${LANG} /${LANG} /" /etc/locale.gen; \
  env LC_ALL=C.UTF-8 \
  dpkg-reconfigure --frontend noninteractive locales; \
  update-locale LANG=${LANG}; \
  locale -a; \
  # Install su-exec
  apt-get install --yes --no-install-recommends build-essential; \
  curl -fL https://github.com/ncopa/su-exec/archive/v${SU_EXEC_VERSION}.tar.gz \
    | tar xfz - -C /tmp; \
  ( \
    cd /tmp/su-exec-${SU_EXEC_VERSION}; \
    make; \
    strip su-exec; \
    mv su-exec /usr/bin; \
  ); \
  rm -rf /tmp/su-exec-${SU_EXEC_VERSION}; \
  # Uninstall development dependencies
  apt-get remove --yes build-essential; \
  apt-get autoremove --yes; \
  # Clean APT cache
  rm -rf /var/lib/apt/lists/*; \
  # Show Debian version
  . /etc/os-release; \
  ln -s /etc/debian_version /etc/debian-release; \
  cat /etc/debian-release

COPY --from=entrypoint / /
COPY rootfs /

ENTRYPOINT ["tini", "--", "/container/entrypoint"]
