"""More targeted probe."""
import json
import urllib.request
import urllib.error


def get(url, headers=None, timeout=30):
    req = urllib.request.Request(url, headers=headers or {"User-Agent": "Mozilla/5.0"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, r.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as e:
        body = ""
        try:
            body = e.read().decode("utf-8", errors="replace")[:300]
        except Exception:
            pass
        return e.code, body
    except Exception as e:
        return 0, f"ERROR {type(e).__name__}: {e}"


print("=== Figshare API: real Seebens collection 3924424 ===")
code, body = get("https://api.figshare.com/v2/collections/3924424/articles?page_size=20")
print(f"  {code}")
try:
    arts = json.loads(body)
    for a in arts:
        print(f"  art {a.get('id')}: {a.get('title','')[:80]}")
except Exception as e:
    print("  body:", body[:300])

print()
print("=== Figshare: try article ID 5188273 (Seebens dataset v1) ===")
for art_id in [5188273, 5688898, 5371188, 4805108]:
    code, body = get(f"https://api.figshare.com/v2/articles/{art_id}")
    print(f"  art {art_id}: HTTP {code}")
    if code == 200:
        try:
            d = json.loads(body)
            print(f"    title: {d.get('title','')[:80]}")
            for f in d.get("files", [])[:3]:
                print(f"    file: {f['name']} -> {f['download_url']}")
        except Exception:
            print("  body[:200]:", body[:200])

print()
print("=== Figshare: real Meiri lizard 5765553 (try direct + ndownloader) ===")
code, body = get("https://api.figshare.com/v2/articles/5765553")
print(f"  art 5765553: HTTP {code}")
if code == 200:
    try:
        d = json.loads(body)
        print(f"  title: {d.get('title','')[:80]}")
        for f in d.get("files", [])[:5]:
            print(f"  file: {f['name']} -> {f['download_url']}")
    except Exception:
        print("  body[:200]:", body[:200])
else:
    print("  body[:300]:", body[:300])

print()
print("=== Diaz 2022 — alternative sources ===")
# Diaz 2022 also lives on TRY-db / Sandra Diaz repo / OSF
# Check Wayback for Springer URL
import urllib.parse

orig = "https://static-content.springer.com/esm/art%3A10.1038%2Fs41586-022-05606-z/MediaObjects/41586_2022_5606_MOESM3_ESM.xlsx"
wayback = f"https://archive.org/wayback/available?url={urllib.parse.quote(orig)}"
code, body = get(wayback)
print(f"  wayback HTTP {code}")
try:
    d = json.loads(body)
    snap = d.get("archived_snapshots", {}).get("closest")
    if snap:
        print(f"  archived URL: {snap.get('url')}")
        print(f"  status: {snap.get('status')}")
        print(f"  timestamp: {snap.get('timestamp')}")
    else:
        print(f"  no snapshot: {body[:200]}")
except Exception as e:
    print("  ERROR:", e, body[:200])

print()
print("=== Fungal Traits: Polme 2020 — alt sources ===")
ft = "https://static-content.springer.com/esm/art%3A10.1007%2Fs13225-020-00466-2/MediaObjects/13225_2020_466_MOESM2_ESM.xlsx"
wb = f"https://archive.org/wayback/available?url={urllib.parse.quote(ft)}"
code, body = get(wb)
print(f"  wayback HTTP {code}")
try:
    d = json.loads(body)
    snap = d.get("archived_snapshots", {}).get("closest")
    if snap:
        print(f"  archived URL: {snap.get('url')}")
        print(f"  status: {snap.get('status')}")
    else:
        print(f"  no snapshot")
except Exception as e:
    print("  ERROR:", e)

# fungaltraits R pkg uses a different file
print()
print("=== fungaltraits R package release file ===")
print("  https://github.com/traitecoevo/fungaltraits/releases/download/v0.0.3/funtothefun.csv")
import urllib.request
req = urllib.request.Request(
    "https://github.com/traitecoevo/fungaltraits/releases/download/v0.0.3/funtothefun.csv",
    headers={"User-Agent": "Mozilla/5.0"},
)
try:
    with urllib.request.urlopen(req, timeout=30) as r:
        data = r.read()
        head = data[:500].decode("utf-8", errors="replace")
        print(f"  HTTP {r.status} | size {len(data)} bytes")
        print(f"  head:\n{head}")
except Exception as e:
    print(f"  ERROR: {e}")
