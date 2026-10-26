#!/usr/bin/env bash
# Isolated VM/container only: creates and cleans /opt/reactivate-tfol and a fake unit.
set -Eeuo pipefail
ROOT=$(mktemp -d)
APP=/opt/reactivate-tfol
UNIT=/etc/systemd/system/tfol-server.service
[[ ! -e "$APP" && ! -e "$UNIT" && ! -e /etc/reactivate-tfol && ! -e /var/lib/reactivate-tfol ]] || { echo 'Refusing to test on an existing TFOL host' >&2; exit 1; }
cleanup() {
 rm -rf -- "$ROOT" "$APP" /var/lib/reactivate-tfol /etc/reactivate-tfol
 rm -f -- "$UNIT"
 id tfol >/dev/null 2>&1 && userdel tfol || :
}
trap cleanup EXIT
mkdir -p "$ROOT/bin" "$ROOT/status" "$APP/server" /etc/systemd/system
printf PREVIOUS > "$APP/server/server.py"
printf PREVIOUS_UNIT > "$UNIT"
touch "$ROOT/status/active" "$ROOT/status/enabled"
cat > "$ROOT/bin/systemctl" <<'SH'
#!/bin/bash
S=${TEST_STATUS:?}
case "$*" in
 'is-active --quiet tfol-server.service') test -f "$S/active";;
 'is-enabled --quiet tfol-server.service') test -f "$S/enabled";;
 'stop tfol-server.service') rm -f "$S/active";;
 'enable --now tfol-server.service')
    test ! -f "$S/fail_enable" || exit 12
    touch "$S/active" "$S/enabled";;
 'enable tfol-server.service') touch "$S/enabled";;
 'disable tfol-server.service') rm -f "$S/enabled";;
 'start tfol-server.service') touch "$S/active";;
 'daemon-reload') :;;
 *) echo "Unexpected systemctl: $*" >&2;exit 15;;
esac
SH
cat > "$ROOT/bin/curl" <<'SH'
#!/bin/bash
case "$*" in
 *127.0.0.1:28000/health*) echo ok;;
 *) exit 20;;
esac
SH
chmod +x "$ROOT/bin/systemctl" "$ROOT/bin/curl"
export TEST_STATUS="$ROOT/status" PATH="$ROOT/bin:$PATH"
python3 - "$ROOT" <<'PY'
import tarfile,io,sys
from pathlib import Path
p=Path(sys.argv[1])
with tarfile.open(p/'new.tar.gz','w:gz') as tar:
 for name,data in {'server/server.py':b'NEW', 'server/runtime_config.py':b'config', 'deploy/tfol.service':b'NEW_UNIT'}.items():
  info=tarfile.TarInfo(name);info.size=len(data);tar.addfile(info,io.BytesIO(data))
PY
SHA=$(sha256sum "$ROOT/new.tar.gz" | cut -d' ' -f1)
touch "$ROOT/status/fail_enable"
if bash vps/install.sh --archive "$ROOT/new.tar.gz" --sha256 "$SHA" > "$ROOT/failure.log" 2>&1;then
 echo 'FAIL: expected systemctl failure';exit 1
fi
[[ $(cat "$APP/server/server.py") == PREVIOUS && $(cat "$UNIT") == PREVIOUS_UNIT ]] || { cat "$ROOT/failure.log";echo 'FAIL: rollback';exit 1; }
[[ -f "$ROOT/status/active" && -f "$ROOT/status/enabled" ]] || { echo 'FAIL: prior service state';exit 1; }
[[ -z $(find "$APP" -maxdepth 1 -name '.stage.*' -print -quit) ]] || exit 1
echo 'PASS: rollback on systemctl failure'
rm "$ROOT/status/fail_enable"
bash vps/install.sh --archive "$ROOT/new.tar.gz" --sha256 "$SHA" > "$ROOT/success.log" 2>&1
[[ $(cat "$APP/server/server.py") == NEW && $(cat "$UNIT") == NEW_UNIT ]] || { echo 'FAIL: upgrade';exit 1; }
[[ -z $(find "$APP" -maxdepth 1 -name '.stage.*' -print -quit) ]] || exit 1
echo 'PASS: successful upgrade and cleanup'
(
 flock -n 9
 if bash vps/install.sh --archive "$ROOT/new.tar.gz" --sha256 "$SHA" > "$ROOT/lock.log" 2>&1;then echo 'FAIL: lock ignored';exit 1;fi
 grep -q 'Another TFOL installation' "$ROOT/lock.log"
) 9>"$APP/.install.lock"
echo 'PASS: concurrent update lock'
