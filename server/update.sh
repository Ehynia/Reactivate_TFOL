#!/usr/bin/env bash
set -Eeuo pipefail
# Update from a verified GitHub release. Data directory is not touched.
exec bash "$(dirname "$0")/install.sh"
