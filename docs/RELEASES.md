# Reactivate TFOL release contract (draft)

No update may be reported available until the GitHub Release assets actually exist.

**VPS server release**: tag `v30`, assets `tfol-server-v30.tar.gz` and `tfol-server-v30.tar.gz.sha256`. The installer checks SHA-256 before unpacking. Keep `/var/lib/tfol-server` and `/etc/tfol-server/config.json` across updates.

**Launcher release**: a future `launcher-vNN.zip` and `launcher-vNN.zip.sha256` release pair. The updater downloads to staging, checks integrity, forbids traversal and writes only to launcher-managed paths. Never overwrite account data, settings, locally installed TFOL or original executable/PAKs.

Do not invoke updater or a `curl | sudo bash` one-liner until its release is published, reviewed and its source matches this repo.

## Known limitations

The current VPS package is **loopback-only hosted preparation**, not a publicly playable Listen Server. The genuine UE4 world migration, PvE objectives and result settlement still need Windows integration tests.
