# Reactivate TFOL — VPS hosting preparation (v56.2)

This directory is **source-only infrastructure**. The actual independent Python server bundle is delivered separately as `tfol-server-v56.2.tar.gz` with its SHA-256 file. The GitHub release is **not published yet**; do not pretend there is a downloadable `v56.2` release.

## Install now using the verified local bundle
1. Download the server tarball, matching `.sha256`, and `install.sh` from the project delivery.
2. On a Debian/Ubuntu VPS, inspect the script and archive before running.
3. Run `sudo bash install.sh --archive ./tfol-server-v56.2.tar.gz --sha256 <64-character SHA256>`.
4. Verify `systemctl status tfol-server` and `curl --noproxy '*' http://127.0.0.1:28000/health`.
5. Install the included systemd update-check service/timer, if desired, for **notification only**.

The service runs as dedicated user `tfol`, stores user data in `/var/lib/reactivate-tfol`, and keeps operator config in `/etc/reactivate-tfol/config.json`. Code upgrades do not reset accounts. Existing versions are preserved as backups.

## GitHub Releases
Only when a maintained, audited **stable** GitHub Release with `tfol-server-v56.2.tar.gz` and `tfol-server-v56.2.tar.gz.sha256` is published will `sudo bash install.sh --tag v56.2` work. The update checker verifies the official GitHub API over validated TLS, and reports missing releases as an ordinary status.

**Limitations:** this is a local-only hosted-preparation coordinator; both HTTP and TF15 sockets intentionally bind to `127.0.0.1`. It is not a public dedicated game server, and the original UE4 world, OB15 results, multiplayer security, and remote auth have not been validated for public deployment. Never open ports 28000/28080 to the Internet or claim a publicly playable server. This repo must not contain original game EXE/PAK or secrets.

## Launcher updates
Windows launcher must request GitHub with TLS 1.2 and normal certificate validation. A valid launcher release also requires `launcher-update.zip` and `launcher-update.zip.sha256`. Never run unverified archives.
