# Reactivate TFOL — VPS online installer (v56.2)

**One command, no manual download of an archive:**

```bash
curl -fsSLo /tmp/tfol-install.sh https://raw.githubusercontent.com/Ehynia/Reactivate_TFOL/main/vps/install-online.sh && sudo bash /tmp/tfol-install.sh
```

Supports Ubuntu 24.04 / Debian 12 with systemd, Python 3.11+, and curl. It downloads the package directly from this repository, checks the pinned SHA-256 in [manifest.json](manifest.json), validates safe archive paths, installs the `tfol` system user and systemd service, and checks local health. No game EXE, DLL, PAK or account database is part of the server package.

After installation:

```bash
sudo systemctl status tfol-server --no-pager
curl -fsS http://127.0.0.1:28000/health
sudo journalctl -u tfol-server -n 50 --no-pager
sudo systemctl status tfol-update-check.timer --no-pager
```

Re-run the same one-line command to install a new version when [manifest.json](manifest.json) changes. A daily systemd timer checks GitHub for new versions but **never automatically replaces running code**. Config: `/etc/reactivate-tfol/config.json`. SQLite/user data: `/var/lib/reactivate-tfol`. Deployed server: `/opt/reactivate-tfol/server`. Installer preserves account data and previous code version.

**Security/limits:** HTTPS and certificate validation stay enabled; both HTTP and TF15 sockets are intentionally bound to loopback `127.0.0.1`. This is **hosted preparation**, not a publicly playable Transformers Online dedicated server. It is not safe or functional to open these ports to the Internet. Real remote session authentication, game-world hosting, OB15 and multiplayer security are not validated.

Package snapshot: [tfol-server-v56.2.tar.gz](packages/tfol-server-v56.2.tar.gz). The exact Git blob, tag and SHA-256 are pinned via the manifest. A separate GitHub Release is *not required* for one-line installation.

Use only a VPS you control; review the script before executing it with `sudo`.
