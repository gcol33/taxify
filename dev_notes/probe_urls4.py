"""Final URL hunt: Seebens Zenodo, Lizard Dryad, Diaz alternatives."""
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


print("=== Seebens Zenodo 4632335 ===")
code, body = get("https://zenodo.org/api/records/4632335")
print(f"  HTTP {code}")
if code == 200:
    d = json.loads(body)
    print(f"  title: {d.get('metadata', {}).get('title','')[:90]}")
    for f in d.get("files", []):
        print(f"  {f['key']} | {f.get('size')} | {f['links']['self']}")

print()
print("=== Seebens Zenodo 3690742 (older) ===")
code, body = get("https://zenodo.org/api/records/3690742")
print(f"  HTTP {code}")
if code == 200:
    d = json.loads(body)
    print(f"  title: {d.get('metadata', {}).get('title','')[:90]}")
    for f in d.get("files", []):
        print(f"  {f['key']} | {f.get('size')} | {f['links']['self']}")

print()
print("=== Lizard Dryad doi:10.5061/dryad.f6t39kj ===")
code, body = get("https://datadryad.org/api/v2/datasets/doi%3A10.5061%2Fdryad.f6t39kj")
print(f"  HTTP {code}")
if code == 200:
    d = json.loads(body)
    print(f"  title: {d.get('title','')[:90]}")
    v_href = d.get("_links", {}).get("stash:version", {}).get("href", "")
    print(f"  version href: {v_href}")
    if v_href:
        code, body = get(f"https://datadryad.org{v_href}/files")
        if code == 200:
            d2 = json.loads(body)
            for f in d2.get("_embedded", {}).get("stash:files", []):
                print(
                    f"  {f['path']} | size {f.get('size')} | https://datadryad.org{f['_links']['stash:download']['href']}"
                )

print()
print("=== ReptTraits 2024 figshare 24572683 (Meiri's newer dataset) ===")
code, body = get("https://api.figshare.com/v2/articles/24572683")
print(f"  HTTP {code}")
if code == 200:
    d = json.loads(body)
    print(f"  title: {d.get('title','')[:90]}")
    for f in d.get("files", [])[:10]:
        print(f"  {f['name']} | size {f.get('size')} | {f['download_url']}")

print()
print("=== Diaz: TRY archive doi:10.17871/TRY.81 ===")
code, body = get("https://www.try-db.org/de/Datasets.php")
print(f"  TRY page HTTP {code} | size {len(body)}")

print()
print("=== Diaz: Sandra Diaz CONICET institutional download ===")
# Sometimes Diaz puts the data on an institutional repository
code, body = get(
    "https://api.crossref.org/works/10.1038/s41597-022-01774-9"
)
if code == 200:
    d = json.loads(body)
    m = d.get("message", {})
    print(f"  title: {m.get('title',[''])[0][:90]}")
    for r in m.get("link", []):
        print(f"  link: {r.get('URL')}")
