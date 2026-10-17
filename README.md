# Reactivate TFOL

Community recovery and diagnostic development of Transformers Online.

## Project status

**Development / testing.** The original UE4 client and networked Listen Server have not been validated as a complete public multiplayer game. This repository is for maintenance tooling and server/launcher source; it does not redistribute original game EXE, PAK assets, account databases or passwords.

## VPS: установка одной командой

На Debian 12 / Ubuntu 24.04 с systemd:

```bash
curl -fsSLo /tmp/tfol-install.sh https://raw.githubusercontent.com/Ehynia/Reactivate_TFOL/main/vps/install-online.sh && sudo bash /tmp/tfol-install.sh
```

Установщик автоматически загружает [пакет v56.2](vps/packages/tfol-server-v56.2.tar.gz), проверяет его SHA-256 по [манифесту](vps/manifest.json), запускает сервис и включает ежедневную проверку обновлений. Это сервер подготовки только для `127.0.0.1`, пока не публичный многопользовательский UE4-сервер. [Подробности](vps/README.md).

## Releases and updates

The launcher and VPS server will use the GitHub **Releases** for updates with SHA-256 verification and backups. Pinned source package v56.2 is available directly in this repo for one-line installation; a stable GitHub Release has not been published. Do **not** run an installer pointing at a nonexistent release, or expose the loopback-only preparation server publicly.

See `docs/RELEASES.md` for the release assets and upgrade policy.
