#!/usr/bin/env bash
# Reactivate TFOL v56.2: single-command VPS installer; no manual archive download.
# Installs hosted-preparation mode only (loopback-bound; not a public UE4 match server).
set -Eeuo pipefail

REPO="Ehynia/Reactivate_TFOL"
RAW="https://raw.githubusercontent.com/${REPO}"
TMPDIR_INSTALL=""
cleanup() { if [[ -n "$TMPDIR_INSTALL" ]]; then rm -rf -- "$TMPDIR_INSTALL"; fi; }
trap cleanup EXIT

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this installer as root (e.g. curl ... -o /tmp/tfol.sh && sudo bash /tmp/tfol.sh)" >&2
  exit 1
fi
if [[ ! -e /run/systemd/system ]]; then
  echo "This VPS must run systemd (Debian 12+ / Ubuntu 24.04 recommended)." >&2
  exit 1
fi
if ! command -v python3 >/dev/null || ! command -v curl >/dev/null || ! command -v sha256sum >/dev/null; then
  if command -v apt-get >/dev/null; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y --no-install-recommends python3 curl ca-certificates coreutils
  else
    echo "Install Python 3.11+, curl, CA certificates and coreutils first." >&2
    exit 1
  fi
fi
python3 -c 'import sys; assert sys.version_info >= (3, 11), "Python 3.11+ is required"'
command -v tar >/dev/null || { echo "tar is required" >&2; exit 1; }

TMPDIR_INSTALL=$(mktemp -d)
chmod 0700 "$TMPDIR_INSTALL"
download() {
  curl --proto '=https' --proto-redir '=https' --tlsv1.2 -fsSL \
    --retry 3 --connect-timeout 20 --max-time 180 "$1" -o "$2"
}

echo "[TFOL] Retrieving update manifest from GitHub..."
download "${RAW}/main/vps/manifest.json" "$TMPDIR_INSTALL/manifest.json"
META=$(python3 - "$TMPDIR_INSTALL/manifest.json" <<'PY'
import json,re,sys
from pathlib import Path
o=json.loads(Path(sys.argv[1]).read_text("utf-8"))
assert o.get("schema")==1 and o.get("repository")=="Ehynia/Reactivate_TFOL"
assert o.get("mode")=="hosted-preparation"
assert re.fullmatch(r"v[0-9][A-Za-z0-9._-]*",o["release"])
assert re.fullmatch(r"[0-9a-f]{40}",o["git_ref"])
assert re.fullmatch(r"[a-f0-9]{64}",o["sha256"])
assert o["asset"]==f'vps/packages/tfol-server-{o["release"]}.tar.gz'
print(o["release"])
print(o["git_ref"])
print(o["asset"])
print(o["sha256"])
PY
)
mapfile -t FIELDS <<< "$META"
TAG="${FIELDS[0]}"
PIN="${FIELDS[1]}"
ASSET="${FIELDS[2]}"
EXPECTED_SHA="${FIELDS[3]}"
[[ -n "$TAG" && -n "$EXPECTED_SHA" ]] || exit 1

echo "[TFOL] Fetching $TAG from pinned Git commit $PIN..."
download "${RAW}/${PIN}/${ASSET}" "$TMPDIR_INSTALL/server.tar.gz"
ACTUAL_SHA=$(sha256sum "$TMPDIR_INSTALL/server.tar.gz" | cut -d' ' -f1)
if [[ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]]; then
  echo "[TFOL] FAIL: server SHA-256 mismatch; nothing installed." >&2
  exit 1
fi
download "${RAW}/${PIN}/vps/install.sh" "$TMPDIR_INSTALL/install.sh"

echo "[TFOL] Archive verified. Installing systemd service (loopback-only)..."
bash "$TMPDIR_INSTALL/install.sh" --archive "$TMPDIR_INSTALL/server.tar.gz" --sha256 "$EXPECTED_SHA"

# The update checker is read-only. Updates are applied by re-running this installer.
download "${RAW}/${PIN}/vps/check-online-updates.py" "$TMPDIR_INSTALL/check-updates.py"
install -m 0644 -o root -g root "$TMPDIR_INSTALL/check-updates.py" \
  /opt/reactivate-tfol/server/check-updates.py
printf '%s\n' "$TAG" > /opt/reactivate-tfol/installed_tag
chmod 0644 /opt/reactivate-tfol/installed_tag
printf '%s\n' "$EXPECTED_SHA" > /opt/reactivate-tfol/installed_sha256
chmod 0644 /opt/reactivate-tfol/installed_sha256

# Daily update notifications, never automatic replacement.
download "${RAW}/${PIN}/vps/tfol-update-check.service" "$TMPDIR_INSTALL/update.service"
download "${RAW}/${PIN}/vps/tfol-update-check.timer" "$TMPDIR_INSTALL/update.timer"
install -m 0644 "$TMPDIR_INSTALL/update.service" /etc/systemd/system/tfol-update-check.service
install -m 0644 "$TMPDIR_INSTALL/update.timer" /etc/systemd/system/tfol-update-check.timer
systemctl daemon-reload
systemctl enable --now tfol-update-check.timer

echo "[TFOL] Completed. View service: systemctl status tfol-server"
echo "[TFOL] Check localhost health: curl http://127.0.0.1:28000/health"
echo "[TFOL] To apply a future GitHub update, re-run the same one-line installer."
echo "[TFOL] Public game connections remain DISABLED until a real UE4 server is validated."
