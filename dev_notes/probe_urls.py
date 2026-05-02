"""Probe failing enrichment URLs and find replacements."""
import json
import urllib.request
import urllib.error


def get(url, headers=None, timeout=30):
    req = urllib.request.Request(url, headers=headers or {"User-Agent": "Mozilla/5.0"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as e:
        return f"HTTP_ERROR {e.code}"
    except Exception as e:
        return f"ERROR {type(e).__name__}: {e}"


def head(url, timeout=30):
    req = urllib.request.Request(
        url, method="HEAD", headers={"User-Agent": "Mozilla/5.0"}
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return f"HTTP {r.status} | size {r.headers.get('Content-Length','?')} | type {r.headers.get('Content-Type','?')}"
    except urllib.error.HTTPError as e:
        return f"HTTP {e.code}"
    except Exception as e:
        return f"ERROR {type(e).__name__}: {e}"


print("=== DRYAD WOODINESS ===")
data = get("https://datadryad.org/api/v2/versions/27578/files")
try:
    d = json.loads(data)
    for f in d.get("_embedded", {}).get("stash:files", []):
        print(
            f"  {f['path']} | size {f.get('size')} | https://datadryad.org{f['_links']['stash:download']['href']}"
        )
except Exception as e:
    print("  parse failed:", e)
    print("  raw[:500]:", data[:500])

print("\n=== FUNGUILD — actual db URL from Guilds_v1.1.py ===")
print("  http://www.stbates.org/funguild_db_2.php")
print("  HEAD:", head("http://www.stbates.org/funguild_db_2.php"))
print("  HEAD:", head("https://www.stbates.org/funguild_db_2.php"))

print("\n=== FUNGUILD — alternative: Ebedthan/funguild repo files ===")
data = get("https://api.github.com/repos/Ebedthan/funguild/contents")
try:
    d = json.loads(data)
    for f in d:
        print(f"  {f['name']} | {f.get('download_url','')}")
except Exception as e:
    print("  ERROR:", e)

print("\n=== Seebens 2017 — Crossref look-up ===")
# DOI 10.1038/ncomms14435 is the paper; figshare collection should be linked
data = get("https://api.crossref.org/works/10.1038/ncomms14435")
try:
    d = json.loads(data)
    m = d.get("message", {})
    print("  title:", m.get("title", [""])[0][:80])
    for link in m.get("link", [])[:5]:
        print("  link:", link.get("URL"))
    for r in m.get("relation", {}).get("hasPart", [])[:5]:
        print("  hasPart:", r)
except Exception as e:
    print("  ERROR:", e)

print("\n=== Lizard traits — Meiri 2018 figshare DOI lookup ===")
data = get("https://api.crossref.org/works/10.6084/m9.figshare.5765553")
try:
    d = json.loads(data)
    m = d.get("message", {})
    print("  title:", m.get("title", [""])[0][:80])
    print("  URL:", m.get("URL"))
except Exception as e:
    print("  ERROR:", e)

print("\n=== Seebens — try article 4805108, 5371206 ===")
for art_id in [4805108, 5371206, 5582390, 6738960, 12253014]:
    print(f"  article {art_id}:")
    data = get(f"https://api.figshare.com/v2/articles/{art_id}")
    try:
        d = json.loads(data)
        print(f"    title: {d.get('title','')[:80]}")
        for f in d.get("files", []):
            print(f"    file: {f['name']} -> {f['download_url']}")
    except Exception as e:
        print(f"    ERROR: {e}")
