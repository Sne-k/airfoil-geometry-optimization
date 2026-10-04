"""Documented literature search in OpenAlex (https://openalex.org, open index, no account needed).

For every query below the script asks the OpenAlex API for all works whose title or abstract matches,
published from 2010 on, and writes

  queries.csv      query, date of the search, number of hits
  candidates.csv   one row per work (merged over the queries): which queries found it, year, title,
                   source, type, DOI, citation count, open-access status

The abstracts are kept only in a local file (candidates_abstracts.json, not part of the repository),
because they are the publishers' text. Screening and data extraction are recorded by hand in
screening.csv (see docs/literature.md).

Usage:  python search_openalex.py [output folder]
"""
import csv
import datetime
import json
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

QUERIES = {
    "Q1_xfoil_optimisation": '(airfoil OR aerofoil) AND XFOIL AND (optimization OR optimisation)',
    "Q2_stochastic_optimisers": '(airfoil OR aerofoil) AND ("shape optimization" OR "shape optimisation") AND '
                                '("genetic algorithm" OR "particle swarm" OR "Bayesian optimization")',
    "Q3_morphing": 'morphing AND (airfoil OR aerofoil) AND (optimization OR optimisation) AND XFOIL',
    "Q4_curvature": '(airfoil OR aerofoil) AND (optimization OR optimisation) AND '
                    '("curvature constraint" OR "curvature constraints" OR "surface waviness" OR "smoothness constraint")',
    "Q5_xfoil_vs_rans": '(airfoil OR aerofoil) AND XFOIL AND (RANS OR "Navier-Stokes") AND transition AND '
                        '(optimization OR optimisation)',
    "Q6_robust_transition": '(airfoil OR aerofoil) AND (robust OR uncertainty) AND ("laminar flow" OR transition) AND '
                            '(optimization OR optimisation)',
}
FROM_DATE = "2010-01-01"
SELECT = ("id,doi,title,publication_year,type,cited_by_count,open_access,primary_location,authorships,"
          "abstract_inverted_index")
API = "https://api.openalex.org/works"


def fetch(query):
    """All works matching the query in title or abstract (cursor paging)."""
    works, cursor, count = [], "*", None
    while cursor:
        params = {
            "filter": f"title_and_abstract.search:{query},from_publication_date:{FROM_DATE}",
            "select": SELECT, "per-page": "200", "cursor": cursor,
        }
        url = API + "?" + urllib.parse.urlencode(params)
        page = get_json(url)
        count = page["meta"]["count"]
        works.extend(page["results"])
        cursor = page["meta"].get("next_cursor") if page["results"] else None
        time.sleep(1.5)
    return count, works


def get_json(url):
    """GET with retries: the API limits the request rate of users without a key."""
    for attempt in range(6):
        try:
            with urllib.request.urlopen(url, timeout=60) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            if error.code != 429 or attempt == 5:
                raise
            time.sleep(5 * 2 ** attempt)


def abstract_text(inverted):
    if not inverted:
        return ""
    words = sorted((pos, word) for word, positions in inverted.items() for pos in positions)
    return " ".join(word for _, word in words)


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).parent
    out.mkdir(parents=True, exist_ok=True)
    today = datetime.date.today().isoformat()
    merged, abstracts, query_rows = {}, {}, []
    for name, query in QUERIES.items():
        count, works = fetch(query)
        query_rows.append({"query_id": name, "database": "OpenAlex", "field": "title and abstract",
                           "query": query, "published_from": FROM_DATE, "date_searched": today,
                           "hits": count, "retrieved": len(works)})
        for w in works:
            row = merged.setdefault(w["id"], {
                "openalex_id": w["id"].rsplit("/", 1)[-1],
                "queries": [],
                "year": w.get("publication_year"),
                "first_author": (w["authorships"][0]["author"]["display_name"] if w.get("authorships") else ""),
                "authors": len(w.get("authorships") or []),
                "title": " ".join((w.get("title") or "").split()),
                "source": ((w.get("primary_location") or {}).get("source") or {}).get("display_name", ""),
                "type": w.get("type"),
                "doi": (w.get("doi") or "").replace("https://doi.org/", ""),
                "cited_by": w.get("cited_by_count"),
                "open_access": (w.get("open_access") or {}).get("oa_status", ""),
            })
            row["queries"].append(name.split("_")[0])
            abstracts[row["openalex_id"]] = abstract_text(w.get("abstract_inverted_index"))
        print(f"{name}: {count} hits, {len(works)} retrieved")
    rows = sorted(merged.values(), key=lambda r: (-(r["cited_by"] or 0), r["title"]))
    for r in rows:
        r["queries"] = " ".join(sorted(set(r["queries"])))
    with open(out / "queries.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(query_rows[0]))
        writer.writeheader()
        writer.writerows(query_rows)
    with open(out / "candidates.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    local = out / "candidates_abstracts.json"
    local.write_text(json.dumps(abstracts, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"{len(rows)} different works; abstracts in {local.name} (keep out of the repository)")


if __name__ == "__main__":
    main()
