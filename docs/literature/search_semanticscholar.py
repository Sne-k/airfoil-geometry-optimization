"""The documented literature search repeated in Semantic Scholar (https://www.semanticscholar.org, open, no account).

The six queries of search_openalex.py, written in the syntax of the Semantic Scholar bulk search
(+ for AND, | for OR, quotes for phrases), which matches title and abstract, for works from 2010 on.
The script writes

  semanticscholar_queries.csv      query, date of the search, number of hits
  semanticscholar_candidates.csv   one row per work (merged over the queries): which queries found it,
                                   year, title, venue, DOI, citation count, and whether the OpenAlex
                                   search (candidates.csv) found it as well (same DOI or same title)

Abstracts are not stored. Usage:  python search_semanticscholar.py [folder with candidates.csv]
"""
import csv
import datetime
import json
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

QUERIES = {
    "Q1_xfoil_optimisation": '(airfoil | aerofoil) + xfoil + (optimization | optimisation)',
    "Q2_stochastic_optimisers": '(airfoil | aerofoil) + ("shape optimization" | "shape optimisation") + '
                                '("genetic algorithm" | "particle swarm" | "Bayesian optimization")',
    "Q3_morphing": 'morphing + (airfoil | aerofoil) + (optimization | optimisation) + xfoil',
    "Q4_curvature": '(airfoil | aerofoil) + (optimization | optimisation) + '
                    '("curvature constraint" | "curvature constraints" | "surface waviness" | "smoothness constraint")',
    "Q5_xfoil_vs_rans": '(airfoil | aerofoil) + xfoil + (RANS | "Navier-Stokes") + transition + '
                        '(optimization | optimisation)',
    "Q6_robust_transition": '(airfoil | aerofoil) + (robust | uncertainty) + ("laminar flow" | transition) + '
                            '(optimization | optimisation)',
}
YEARS = "2010-"
FIELDS = "title,year,venue,externalIds,citationCount,publicationTypes"
URL = "https://api.semanticscholar.org/graph/v1/paper/search/bulk"


def get(params):
    """One page of results; waits and tries again when the shared rate limit is reached."""
    url = URL + "?" + urllib.parse.urlencode(params)
    for attempt in range(8):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "airfoil-geometry-optimization literature search"})
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            if e.code in (429, 500, 502, 503, 504):
                time.sleep(5 * (attempt + 1))
                continue
            raise
    raise RuntimeError("Semantic Scholar did not answer after 8 attempts")


def norm(title):
    return re.sub(r"[^a-z0-9]", "", (title or "").lower())


def main(folder):
    folder = Path(folder)
    today = datetime.date.today().isoformat()
    works, rows = {}, []
    for qid, q in QUERIES.items():
        params = {"query": q, "year": YEARS, "fields": FIELDS}
        found, total = [], None
        while True:
            d = get(params)
            total = d.get("total") if total is None else total
            found += d.get("data", [])
            if not d.get("token"):
                break
            params["token"] = d["token"]
            time.sleep(1)
        rows.append({"query_id": qid, "database": "Semantic Scholar", "field": "title and abstract", "query": q,
                     "published_from": "2010", "date_searched": today, "hits": total, "retrieved": len(found)})
        for p in found:
            w = works.setdefault(p["paperId"], {"paper": p, "queries": []})
            w["queries"].append(qid.split("_")[0])
        time.sleep(1)

    oa = list(csv.DictReader(open(folder / "candidates.csv", encoding="utf-8")))
    oa_doi = {r["doi"].lower() for r in oa if r["doi"]}
    oa_title = {norm(r["title"]) for r in oa}
    out = []
    for pid, w in works.items():
        p = w["paper"]
        doi = (p.get("externalIds") or {}).get("DOI") or ""
        in_oa = bool(doi and doi.lower() in oa_doi) or norm(p.get("title")) in oa_title
        out.append({"paper_id": pid, "queries": "+".join(w["queries"]), "year": p.get("year"), "title": p.get("title"),
                    "venue": p.get("venue"), "type": ";".join(p.get("publicationTypes") or []), "doi": doi,
                    "cited_by": p.get("citationCount"), "in_openalex_search": "yes" if in_oa else "no"})
    out.sort(key=lambda r: (r["in_openalex_search"], -(r["cited_by"] or 0)))
    with open(folder / "semanticscholar_queries.csv", "w", newline="", encoding="utf-8") as f:
        wr = csv.DictWriter(f, fieldnames=list(rows[0]))
        wr.writeheader()
        wr.writerows(rows)
    with open(folder / "semanticscholar_candidates.csv", "w", newline="", encoding="utf-8") as f:
        wr = csv.DictWriter(f, fieldnames=list(out[0]))
        wr.writeheader()
        wr.writerows(out)
    new = sum(r["in_openalex_search"] == "no" for r in out)
    print(f"{len(out)} different works; {len(out) - new} also in the OpenAlex search, {new} only here")
    for r in rows:
        print(f"  {r['query_id']}: {r['hits']} hits, {r['retrieved']} retrieved")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else Path(__file__).parent)
