"""Find Seebens, Lizard, Diaz alternatives via correct DOIs/Zenodo."""
import json
import urllib.request
import urllib.error


def get(url, timeout=30):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
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


# Search Zenodo for each
queries = {
    "Seebens alien": "Seebens+alien+species+first+records",
    "Meiri lizard": "Meiri+lizards+traits",
    "Diaz plant form function": "Diaz+plant+form+function+spectrum",
    "FungalTraits Polme": "FungalTraits+Polme",
    "GloNAF": "GloNAF+naturalized+alien+flora",
}
for label, q in queries.items():
    print(f"\n=== Zenodo: {label} ===")
    code, body = get(f"https://zenodo.org/api/records?q={q}&size=10&sort=mostrecent")
    if code != 200:
        print(f"  HTTP {code}")
        continue
    try:
        d = json.loads(body)
        for h in d.get("hits", {}).get("hits", []):
            m = h.get("metadata", {})
            title = m.get("title", "")[:90]
            print(f"  {h.get('id')}: {title}")
    except Exception as e:
        print(f"  parse error: {e}")

print()
print("=== Figshare search: Meiri lizard ===")
code, body = get(
    "https://api.figshare.com/v2/articles?search_for=Meiri+lizard+traits&page_size=10"
)
print(f"  HTTP {code}")
try:
    arts = json.loads(body)
    for a in arts:
        print(f"  {a.get('id')}: {a.get('title','')[:80]}")
except Exception as e:
    print(f"  ERROR: {e}")

print()
print("=== Figshare search: Seebens ===")
code, body = get(
    "https://api.figshare.com/v2/articles?search_for=Seebens+alien+first+records&page_size=10"
)
print(f"  HTTP {code}")
try:
    arts = json.loads(body)
    for a in arts:
        print(f"  {a.get('id')}: {a.get('title','')[:80]}")
except Exception as e:
    print(f"  ERROR: {e}")

print()
print("=== Figshare search: Diaz form function ===")
code, body = get(
    "https://api.figshare.com/v2/articles?search_for=Diaz+plant+form+function+spectrum&page_size=10"
)
print(f"  HTTP {code}")
try:
    arts = json.loads(body)
    for a in arts:
        print(f"  {a.get('id')}: {a.get('title','')[:80]}")
except Exception as e:
    print(f"  ERROR: {e}")

print()
print("=== TRY-db / OSF / Diaz alt: nature.com supplementary direct ===")
# Sometimes Nature offers a 'static-content' redirect from the article page
code, body = get("https://www.nature.com/articles/s41586-022-05606-z")
print(f"  Nature article HTTP {code} | body len {len(body)}")
import re

# find xlsx or zip URLs in the page
urls = re.findall(r'https?://[^"\s]+\.(?:xlsx|csv|zip)', body)
for u in sorted(set(urls))[:10]:
    print(f"  {u}")
