"""Looks up the bibliographic data of the DOIs in dois.txt on Crossref and writes crossref_check.csv.

Every reference in docs/literature.md that has a DOI was checked this way. Usage:
  python check_crossref.py [folder with dois.txt]
"""
import csv
import json
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


def lookup(doi):
    url = "https://api.crossref.org/works/" + urllib.parse.quote(doi)
    for attempt in range(4):
        try:
            with urllib.request.urlopen(url, timeout=60) as response:
                return json.load(response)["message"]
        except urllib.error.HTTPError as error:
            if error.code == 404:
                return None
            time.sleep(3 * (attempt + 1))
    return None


def main():
    folder = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).parent
    dois = [d.strip() for d in open(folder / "dois.txt", encoding="utf-8") if d.strip() and not d.startswith("#")]
    rows = []
    for doi in dois:
        m = lookup(doi)
        if m is None:
            rows.append({"doi": doi, "found": "no"})
            continue
        year = (m.get("published-print") or m.get("published-online") or m.get("issued") or {}).get("date-parts", [[None]])[0][0]
        rows.append({
            "doi": doi, "found": "yes",
            "authors": "; ".join((a.get("family") or a.get("name") or "") + (", " + a["given"] if a.get("given") else "")
                                 for a in m.get("author", [])),
            "year": year,
            "title": " ".join((m.get("title") or [""])[0].split()),
            "container": (m.get("container-title") or [""])[0],
            "volume": m.get("volume", ""), "issue": m.get("issue", ""),
            "pages": m.get("page", "") or m.get("article-number", ""),
            "type": m.get("type", ""),
        })
        time.sleep(0.5)
    fields = ["doi", "found", "authors", "year", "title", "container", "volume", "issue", "pages", "type"]
    with open(folder / "crossref_check.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)
    for r in rows:
        print(r["doi"], "|", r.get("authors", "")[:70], "|", r.get("year"), "|", r.get("title", "")[:80], "|",
              r.get("container", "")[:40], r.get("volume", ""), r.get("issue", ""), r.get("pages", ""))


if __name__ == "__main__":
    main()
