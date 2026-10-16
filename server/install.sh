#!/usr/bin/env bash
set -Eeuo pipefail
# Server bootstrap: inspect before running. No releases are published by default.
REPO="Ehynia/Reactivate_TFOL"
TAG="${TFOL_TAG:-v30}"
ASSET="tfol-server-v30.tar.gz"
[[ $EUID -eq 0 ]] || { echo 'Run via sudo' >&2; exit 1; }
for c in curl sha256sum tar python3 systemctl; do command -v "$c" >/dev/null || { echo "missing: $c" >&2; exit 1; }; done
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
url="https://github.com/$REPO/releases/download/$TAG/$ASSET"
curl -fLSs --retry 3 --connect-timeout 20 -o "$tmp/$ASSET" "$url"
curl -fLSs --retry 3 --connect-timeout 20 -o "$tmp/$ASSET.sha256" "$url.sha256"
(cd "$tmp" && sha256sum -c "$ASSET.sha256")
python3 - "$tmp/$ASSET" <<'PY'
import tarfile,sys,pathlib
with tarfile.open(sys.argv[1],"r:gz") as tf:
 for member in tf:
  p=pathlib.PurePosixPath(member.name)
  if p.is_absolute() or ".." in p.parts or not p.parts or p.parts[0]!="server" or not (member.isfile() or member.isdir()):
   raise SystemExit("Unsafe member: "+member.name)
PY
id tfol >/dev/null 2>&1 || useradd --system --home /var/lib/tfol-server --shell /usr/sbin/nologin tfol
install -d -m 0700 -o tfol -g tfol /var/lib/tfol-server
install -d -m 0750 -o root -g tfol /etc/tfol-server
if [ ! -e /etc/tfol-server/config.json ]; then
 printf '%s\n' '{"mode":"hosted-preparation","require_account_keys":true,"capture_packets":false,"api_port":28000,"tcp_port":28080,"data_directory":"data","local_test_matches":false}' > /etc/tfol-server/config.json
 chown root:tfol /etc/tfol-server/config.json; chmod 0640 /etc/tfol-server/config.json
fi
systemctl stop tfol-server.service 2>/dev/null || true
mkdir -p /opt/tfol-server
staging=$(mktemp -d /opt/tfol-server/.new.XXXXXXXX)
tar -xzf "$tmp/$ASSET" -C "$staging"
if [ -d /opt/tfol-server/server ]; then
 mv /opt/tfol-server/server "/opt/tfol-server/.previous-$(date -u +%Y%m%d%H%M%S)"
fi
mv "$staging/server" /opt/tfol-server/server
rmdir "$staging"
chown -R root:root /opt/tfol-server/server
cat > /etc/systemd/system/tfol-server.service <<'UNIT'
[Unit]
Description=Reactivate TFOL hosted-preparation coordination service (local only)
After=network.target
[Service]
Type=simple
User=tfol
Group=tfol
WorkingDirectory=/opt/tfol-server/server
ExecStart=/usr/bin/python3 -u /opt/tfol-server/server/server.py --data /var/lib/tfol-server --config /etc/tfol-server/config.json
Environment=PYTHONDONTWRITEBYTECODE=1
Restart=on-failure
RestartSec=5
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
ReadWritePaths=/var/lib/tfol-server
UMask=0077
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now tfol-server.service
systemctl is-active --quiet tfol-server.service || { echo 'Service unhealthy. Check journalctl -u tfol-server.' >&2; exit 1; }
echo "TFOL preparation server running; ports accessible on loopback only."
