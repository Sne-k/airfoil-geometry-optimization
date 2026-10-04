"""Keyword coding of the abstracts found by search_openalex.py.

Works with XFOIL in the title or abstract (queries Q1, Q3, Q5) and of the types article, conference
paper, preprint or book chapter are coded: each rule below is a regular expression applied to title
plus abstract (case-insensitive). The result says how many abstracts MENTION a topic. An abstract
that does not mention something may still do it in the full text, so the shares are lower bounds.

Writes abstract_coding.csv (one row per work, 1/0 per rule) and abstract_coding_summary.csv, and, in
a local file that is not part of the repository, the sentences that matched selected rules, for the
manual check recorded in docs/literature.md.

Usage:  python code_abstracts.py [folder with candidates.csv and candidates_abstracts.json]
"""
import csv
import json
import re
import sys
from pathlib import Path

RULES = {
    "optimiser_genetic": r"genetic algorithm|NSGA|\bGA\b|evolutionary",
    "optimiser_particle_swarm": r"particle swarm|\bPSO\b",
    "optimiser_gradient": r"gradient[- ]based|adjoint|\bSQP\b|sequential quadratic|fmincon|SLSQP|conjugate gradient",
    "optimiser_surrogate_or_learning": r"surrogate|neural network|machine learning|deep learning|kriging|"
                                       r"gaussian process|bayesian|reinforcement learning|generative",
    "param_cst": r"\bCST\b|class[- ]shape|kulfan",
    "param_parsec": r"parsec",
    "param_bezier_or_spline": r"b[ée]zier|b-?spline|nurbs",
    "param_hicks_henne": r"hicks",
    "metric_lift_to_drag": r"lift[- ]to[- ]drag|\bL/D\b|glide ratio|C_?L\s*/\s*C_?D|aerodynamic efficiency",
    "multi_point_or_robust": r"multi[- ]?point|off[- ]design|robust|uncertain|multiple (angles|operating|flight)|"
                             r"range of (angles|reynolds)",
    "mentions_transition": r"transition|laminar separation|\bn[- ]?crit|turbulence intensity|laminar[- ]turbulent",
    "check_cfd": r"\bCFD\b|RANS|navier[- ]stokes|fluent|openfoam|\bSU2\b|star-?ccm|\bCFX\b",
    "check_experiment": r"wind[- ]tunnel|experiment(al|ally|s)?\b|measurement",
    "repeated_runs": r"independent runs|multiple runs|random seeds?|\bseeds?\b|standard deviation|"
                     r"repeated (runs|optimi[sz]ations)|statistical(ly)? (analysis|significan)|\b\d+ runs\b",
    "smoothness_or_curvature": r"curvature|smoothness|waviness|wavy",
}
CHECK = ["repeated_runs", "smoothness_or_curvature"]          # matched sentences are written out
TYPES = {"article", "conference-paper", "preprint", "book-chapter"}


def main():
    folder = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).parent
    rows = list(csv.DictReader(open(folder / "candidates.csv", encoding="utf-8")))
    abstracts = json.load(open(folder / "candidates_abstracts.json", encoding="utf-8"))
    coded, snippets = [], []
    for r in rows:
        if not set(r["queries"].split()) & {"Q1", "Q3", "Q5"} or r["type"] not in TYPES:
            continue
        abstract = abstracts.get(r["openalex_id"], "")
        if not abstract:
            continue
        text = r["title"] + ". " + abstract
        out = {"openalex_id": r["openalex_id"], "year": r["year"], "doi": r["doi"], "title": r["title"]}
        for name, pattern in RULES.items():
            hit = re.search(pattern, text, flags=re.IGNORECASE)
            out[name] = int(bool(hit))
            if hit and name in CHECK:
                sentence = [s for s in re.split(r"(?<=[.!?])\s+", text) if re.search(pattern, s, flags=re.IGNORECASE)]
                snippets.append({"rule": name, "openalex_id": r["openalex_id"], "year": r["year"],
                                 "title": r["title"], "sentences": sentence})
        coded.append(out)
    with open(folder / "abstract_coding.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(coded[0]))
        writer.writeheader()
        writer.writerows(coded)
    n = len(coded)
    with open(folder / "abstract_coding_summary.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["rule", "abstracts_mentioning", "abstracts_coded", "percent"])
        for name in RULES:
            k = sum(c[name] for c in coded)
            writer.writerow([name, k, n, f"{100 * k / n:.1f}"])
            print(f"{name:34s} {k:4d} of {n} ({100 * k / n:.1f} %)")
    (folder / "abstract_coding_check.json").write_text(json.dumps(snippets, ensure_ascii=False, indent=1),
                                                       encoding="utf-8")


if __name__ == "__main__":
    main()
