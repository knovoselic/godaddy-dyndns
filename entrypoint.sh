#!/bin/sh
[ -z ${DEBUG_OUTPUT+x} ] || set -x
set -Eeuo pipefail

SLEEP_TIME="${SLEEP_TIME:-300}"

while true; do
  /update_ip.sh
  sleep "${SLEEP_TIME}"
done
