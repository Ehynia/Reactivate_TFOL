# Windows launcher updater integration

Current launcher is WinForms (.NET Framework); server and launcher distributions must remain separate.

`Check-ReactivateUpdate.ps1` queries the latest GitHub release and displays available tagged versions.
`Install-ReactivateUpdate.ps1` requires an explicit release tag; SHA256 of downloaded asset is checked.
The updater performs a safe extraction to a staging directory. It does NOT modify active launcher files or game data automatically; users must close Reactivate and perform a reviewed replacement. This is a development integration stage, not unattended updates.

Never run scripts from untrusted forks or auto-execute an unverified archive from a mutable URL.
