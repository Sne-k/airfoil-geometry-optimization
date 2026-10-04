"""Checks numbers in the documents against the result files they come from.

Every row of tools/numbers.csv names
  file    the document (path from the repository root)
  text    a fragment of one line of the document that contains the number
  value   the number as it is written in that fragment
  source  the CSV file the number comes from
  expr    a Python expression that computes the number from the CSV

and the script verifies that the fragment is in the document, that the number is in the fragment, and that
the expression, rounded to the number of decimals written, gives that number.

In an expression:
  rows                 all rows of the CSV (numbers converted)
  one(col=value, ...)  the single row that matches
  sel(col=value, ...)  all rows that match
  col(rows, 'name')    the values of a column
  mean, median, stdev, min, max, len, abs, sum, set, str, float, int, round

Usage:  python tools/check_numbers.py            (from the repository root; exit code 1 if a check fails)
"""
import csv
import statistics
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def convert(value):
    try:
        return float(value)
    except (TypeError, ValueError):
        return value


def load(source):
    with open(ROOT / source, encoding="utf-8-sig", newline="") as f:
        return [{k: convert(v) for k, v in row.items()} for row in csv.DictReader(f)]


def decimals(text):
    return len(text.split(".")[1]) if "." in text else 0


def check(entry, cache):
    doc = (ROOT / entry["file"]).read_text(encoding="utf-8")
    if entry["text"] not in doc:
        return "text not found in the document"
    written = entry["value"]
    if written not in entry["text"]:
        return "value not in the text fragment"
    rows = cache.setdefault(entry["source"], load(entry["source"]))

    def sel(**filters):
        return [r for r in rows if all(r.get(k) == convert(v) for k, v in filters.items())]

    def one(**filters):
        found = sel(**filters)
        if len(found) != 1:
            raise ValueError(f"{len(found)} rows match {filters}")
        return found[0]

    names = {"rows": rows, "sel": sel, "one": one, "col": lambda rs, name: [r[name] for r in rs],
             "mean": statistics.mean, "median": statistics.median, "stdev": statistics.stdev,
             "min": min, "max": max, "len": len, "abs": abs, "sum": sum, "set": set, "str": str,
             "float": float, "int": int, "round": round}
    try:
        # the manifest is part of this repository; the names are globals so that generator expressions see them
        computed = eval(entry["expr"], {"__builtins__": {}, **names})
    except Exception as error:  # noqa: BLE001
        return f"expression failed: {error}"
    target = float(written.replace("−", "-").replace(",", ""))
    if round(float(computed), decimals(written)) != round(target, decimals(written)):
        return f"document says {written}, the source gives {computed:.6g}"
    return ""


def main():
    with open(ROOT / "tools" / "numbers.csv", encoding="utf-8", newline="") as f:
        entries = list(csv.DictReader(f))
    cache, failures = {}, 0
    for n, entry in enumerate(entries, start=2):
        problem = check(entry, cache)
        if problem:
            failures += 1
            print(f"numbers.csv line {n}: {entry['file']}: \"{entry['text'][:70]}\": {problem}")
    print(f"{len(entries) - failures} of {len(entries)} numbers agree with their sources")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
