#!/bin/bash

### LOCALE #####################################################################

# Variable names
# - https://wiki.debian.org/Locale
LOCALE_VARS="LANG LC_ALL LC_ADDRESS LC_COLLATE LC_CTYPE LC_MONETARY LC_MEASUREMENT LC_MESSAGES LC_NUMERIC LC_PAPER LC_RESPONSE LC_TELEPHONE LC_TIME"

# Save original locale.gen
cp /etc/locale.gen /etc/locale.gen.orig

# Enable locales
for VAR in ${LOCALE_VARS}; do
  eval "LOCALE=\${$VAR}"
  if [ -n "${LOCALE}" ]; then
    sed -i -E "s/^[# ]*${LOCALE} /${LOCALE} /" /etc/locale.gen
  fi
done

# Reconfigure locale
if ! diff /etc/locale.gen /etc/locale.gen.orig > /dev/null; then
  # Reconfigure locales package
  env LC_ALL=C.UTF-8 \
  dpkg-reconfigure --frontend noninteractive locales
  # Set default locale
  for VAR in ${LOCALE_VARS}; do
    eval "LOCALE=\${$VAR}"
    if [ -n "${LOCALE}" ]; then
      info "Setting ${VAR}=${LOCALE}"
      update-locale ${VAR}=${LOCALE}
    else
      update-locale ${VAR}
    fi
  done
fi

# Remove original locale.gen
rm -f /etc/locale.gen.orig

################################################################################
