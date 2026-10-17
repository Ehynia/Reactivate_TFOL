#!/usr/bin/env python3
"""Read-only GitHub manifest update check; validated HTTPS; never auto-installs."""
import json
import pathlib
import re
import ssl
import urllib.request
import urllib.error

ROOT = "https://raw.githubusercontent.com/Ehynia/Reactivate_TFOL/main/vps/manifest.json"
CURRENT = pathlib.Path("/opt/reactivate-tfol/installed_tag")
CURRENT_SHA = pathlib.Path("/opt/reactivate-tfol/installed_sha256")

def main():
    request = urllib.request.Request(ROOT, headers={"User-Agent": "TFOL-VPS-UpdateCheck/2.0"})
    with urllib.request.urlopen(request, timeout=25, context=ssl.create_default_context()) as response:
        if response.status != 200:
            raise RuntimeError("GitHub returned HTTP " + str(response.status))
        manifest = json.load(response)
    if (manifest.get("schema") != 1
            or manifest.get("repository") != "Ehynia/Reactivate_TFOL"
            or manifest.get("mode") != "hosted-preparation"
            or not re.fullmatch(r"v[0-9][A-Za-z0-9._-]*", str(manifest.get("release", "")))
            or not re.fullmatch(r"[a-f0-9]{64}", str(manifest.get("sha256", "")))
            or not re.fullmatch(r"[0-9a-f]{40}", str(manifest.get("git_ref", "")))):
        raise RuntimeError("Invalid GitHub manifest")
    installed = CURRENT.read_text("utf-8").strip() if CURRENT.exists() else "(unknown)"
    digest = CURRENT_SHA.read_text("utf-8").strip() if CURRENT_SHA.exists() else "(unknown)"
    if installed == manifest["release"] and digest == manifest["sha256"]:
        print("TFOL VPS hosted-preparation is up to date:", installed)
    else:
        print("TFOL VPS update available:", manifest["release"], "installed:", installed)
        print("Re-run the one-line installation command after reviewing the update.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
