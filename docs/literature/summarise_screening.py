"""Counts from screening.csv (the full-text audit), written to screening_summary.csv.

Usage:  python summarise_screening.py [folder]
"""
import csv
import sys
from collections import Counter
from pathlib import Path


def main():
    folder = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).parent
    rows = [r for r in csv.DictReader(open(folder / "screening.csv", encoding="utf-8")) if r["no"] != "extra"]
    scope = Counter(r["in_scope"].split(" ")[0] for r in rows)
    inside = [r for r in rows if r["in_scope"] == "yes"]
    full = [r for r in inside if r["basis"].startswith("full text")]

    def count(items, test):
        return sum(1 for r in items if test(r))

    def known(field):
        return lambda r: not r[field].startswith("not ") and r[field] != ""

    out = [
        ("works in the sample", len(rows)),
        ("in scope (XFOIL evaluates the candidates of a section or morphing-shape optimisation)", scope["yes"]),
        ("partly in scope", scope["partly"]),
        ("not in scope or not assessed", scope["no"] + scope["not"]),
        ("in scope, read in full", len(full)),
        ("in scope, abstract only", len(inside) - len(full)),
    ]
    metric = Counter(r["metric_class"] for r in inside)
    for name in ("fixed angle", "peak", "multi-condition", "robust", "single condition", "not in abstract"):
        out.append((f"in scope, objective posed as: {name}", metric[name]))
    out += [
        ("in scope, read in full: several independent optimisation runs reported",
         count(full, lambda r: r["independent_runs"][:1].isdigit())),
        ("in scope: optimum checked with RANS",
         count(inside, lambda r: not r["check_of_optimum"].startswith("none") and any(
             k in r["check_of_optimum"] for k in ("RANS", "Fluent", "OpenFOAM", "higher-fidelity", "high-fidelity")))),
        ("in scope: optimum checked in a wind tunnel (done or announced)",
         count(inside, lambda r: "wind" in r["check_of_optimum"].lower())),
        ("in scope, read in full: no check of the optimum with another flow solver or an experiment",
         count(full, lambda r: r["check_of_optimum"].startswith("none"))),
        ("in scope, read in full: surface smoothness or curvature limited explicitly",
         count(full, lambda r: any(k in r["smoothness_handling"] for k in ("smoothness", "curvature", "wavy")))),
    ]
    with open(folder / "screening_summary.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["item", "count"])
        writer.writerows(out)
    for item, n in out:
        print(f"{n:3d}  {item}")


if __name__ == "__main__":
    main()
