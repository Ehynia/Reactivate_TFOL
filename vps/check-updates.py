#!/usr/bin/env python3
"""GitHub stable-release check; never automatically execute a download."""
import json, pathlib, re, ssl, urllib.error, urllib.request
REPO="Ehynia/Reactivate_TFOL"
ASSET="tfol-server-v56.2.tar.gz"
def check():
    req=urllib.request.Request(f"https://api.github.com/repos/{REPO}/releases/latest",
      headers={"User-Agent":"TFOL-VPS-UpdateCheck/1.0","Accept":"application/vnd.github+json"})
    try:
        with urllib.request.urlopen(req,timeout=20,context=ssl.create_default_context()) as h:release=json.load(h)
    except urllib.error.HTTPError as e:
        if e.code==404:print("No stable release published yet");return 0
        raise
    tag=release.get("tag_name","")
    if not re.fullmatch(r"v[0-9][0-9A-Za-z._-]*",tag) or release.get("draft") or release.get("prerelease"):
        raise SystemExit("Invalid release metadata")
    names={a.get("name") for a in release.get("assets",[]) if isinstance(a,dict)}
    if not {ASSET,ASSET+".sha256"}<=names:
        print("Latest stable release has no verified TFOL server asset pair");return 0
    path=pathlib.Path("/opt/reactivate-tfol/installed_tag")
    current=path.read_text().strip() if path.exists() else "(local bundle)"
    print("Up to date" if current==tag else f"New release: {tag}; installed: {current}")
    return 0
if __name__=="__main__":raise SystemExit(check())
