#!/usr/bin/env bash
set -Eeuo pipefail
REPO=Ehynia/Reactivate_TFOL
APP=/opt/reactivate-tfol
STATE=/var/lib/reactivate-tfol
CONF=/etc/reactivate-tfol
ASSET=tfol-server-v56.2.tar.gz
ARCHIVE= SHA= TAG=
while (($#)); do
 case "$1" in
 --archive) ARCHIVE="${2:?}";shift 2;;
 --sha256) SHA="${2:?}";shift 2;;
 --tag) TAG="${2:?}";shift 2;;
 *) echo 'Usage: sudo bash install.sh --archive FILE --sha256 HEX | --tag v56.2' >&2; exit 2;;
 esac
done
[[ $EUID -eq 0 ]] || { echo 'Root required' >&2;exit 1; }
[[ (-n $ARCHIVE && -n $SHA && -z $TAG) || (-n $TAG && -z $ARCHIVE && -z $SHA) ]] || exit 2
if [[ -n $TAG ]]; then [[ $TAG =~ ^v[0-9][0-9A-Za-z._-]*$ ]] || exit 2; fi
if command -v apt-get >/dev/null && { ! command -v curl >/dev/null || ! command -v python3 >/dev/null; }; then
 apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends python3 ca-certificates curl
fi
for c in curl tar sha256sum python3 systemctl useradd;do command -v "$c" >/dev/null || exit 1;done
tmp=$(mktemp -d);trap 'rm -rf "$tmp"' EXIT
if [[ -n $TAG ]]; then
 base="https://github.com/$REPO/releases/download/$TAG/$ASSET"
 curl --proto '=https' --tlsv1.2 -fLSs --retry 3 --max-time 240 -o "$tmp/$ASSET" "$base"
 curl --proto '=https' --tlsv1.2 -fLSs --retry 3 --max-time 60 -o "$tmp/checksum" "$base.sha256"
 ARCHIVE="$tmp/$ASSET";SHA=$(awk 'NR==1{print $1}' "$tmp/checksum")
fi
[[ $SHA =~ ^[a-fA-F0-9]{64}$ ]] || { echo 'Bad SHA256' >&2;exit 1; }
printf '%s  %s\n' "$SHA" "$ARCHIVE" | sha256sum -c - >/dev/null
python3 - "$ARCHIVE" <<'PY'
import sys,tarfile,pathlib
with tarfile.open(sys.argv[1],'r:gz') as t:
 names=set()
 for m in t:
  p=pathlib.PurePosixPath(m.name)
  if p.is_absolute() or '..' in p.parts or not p.parts or p.parts[0] not in ('server','deploy') or not (m.isfile() or m.isdir()) or m.name in names:
   raise SystemExit('Unsafe tar member: '+m.name)
  names.add(m.name)
 if not {'server/server.py','server/runtime_config.py','deploy/tfol.service'}<=names:raise SystemExit('Missing files')
PY
mkdir -p "$APP"
stage=$(mktemp -d "$APP/.stage.XXXXXXXX")
tar -xzf "$ARCHIVE" -C "$stage" --no-same-owner --no-same-permissions
id tfol >/dev/null 2>&1 || useradd --system --home-dir "$STATE" --shell /usr/sbin/nologin tfol
install -d -m 0700 -o tfol -g tfol "$STATE"
install -d -m 0750 -o root -g tfol "$CONF"
if [[ ! -f "$CONF/config.json" ]];then
 printf '%s\n' '{"mode":"hosted-preparation","require_account_keys":true,"capture_packets":false,"api_port":28000,"tcp_port":28080,"local_test_matches":false,"reddit_news_enabled":false,"enable_local_banner_xp":false}' > "$CONF/config.json"
 chown root:tfol "$CONF/config.json";chmod 0640 "$CONF/config.json"
fi
systemctl stop tfol-server.service 2>/dev/null || :
previous=
if [[ -d "$APP/server" ]];then previous="$APP/.previous-$(date -u +%Y%m%dT%H%M%S)";mv "$APP/server" "$previous";fi
mv "$stage/server" "$APP/server"
install -m 0644 "$stage/deploy/tfol.service" /etc/systemd/system/tfol-server.service
chown -R root:root "$APP/server";chmod -R go-w "$APP/server"
[[ -z $TAG ]] || printf '%s\n' "$TAG" > "$APP/installed_tag"
systemctl daemon-reload
systemctl enable --now tfol-server.service
ready=0
for i in $(seq 1 20);do
 if curl --noproxy '*' -fsS --max-time 2 http://127.0.0.1:28000/health >/dev/null 2>&1;then ready=1;break;fi
 sleep 1
done
if [[ $ready != 1 ]];then
 systemctl stop tfol-server.service || :
 rm -rf "$APP/server"
 if [[ -n $previous ]];then mv "$previous" "$APP/server";systemctl start tfol-server.service || :;fi
 echo 'Health check failed; source rolled back' >&2;exit 1
fi
echo 'Server healthy at 127.0.0.1; hosted preparation only, not public gameplay.'
