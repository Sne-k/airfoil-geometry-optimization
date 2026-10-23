"""Step 1c: train the surrogates for the surrogate-assisted optimiser and export them for MATLAB.

Data: the logged XFOIL evaluations of the population study (population_runs/<tag>/history/eval_*.csv),
absolute CST shape = seed fit (feasibility/runs_seed_fit.csv) + logged change d. Rows with f < 0 only.
Target A: peak CL/CD, free transition ('peak' and 'nocurv' runs); target B: mean of the peak CL/CD with
free and tripped transition ('robusttrip' runs). For A, the suspect designs flagged by flag_suspects.py
are replaced by their values recomputed with the friction floor (relabel_suspects.m; dropped where the
polar is unusable with the floor).

The benchmark airfoils (HELD_OUT) are excluded from training, so the benchmark runs on airfoils the
surrogate has never seen. Each target gets an ensemble of 5 networks (different seeds).
Output: surrogate/model_<A|B>.json (scaler, weights and biases of each network, ReLU hidden layers,
linear output) and surrogate/training_summary.json.
"""
import csv, glob, json, os, sys
import numpy as np
from sklearn.neural_network import MLPRegressor
from sklearn.preprocessing import StandardScaler

W = os.environ.get('AIRFOIL_WORK') or sys.exit('Set AIRFOIL_WORK to the work folder (MATLAB/Surrogate/README.md).')
HELD_OUT = ['NACA_2412', 'NACA_0012', 'NACA_4415', 'CLARK_Y', 'SD7062', 'S1223']
runs = {r['tag']: r for r in csv.DictReader(open(os.path.join(W, 'feasibility', 'runs_seed_fit.csv')))}


def load(select):
    X, y, g = [], [], []
    for tag, r in runs.items():
        if not select(r):
            continue
        seed = np.array([float(r[f'Au{i}']) for i in range(7)] + [float(r[f'Al{i}']) for i in range(7)])
        for f in glob.glob(os.path.join(W, 'population_runs', tag, 'history', 'eval_*.csv')):
            for line in open(f):
                p = line.rstrip(',\n').split(',')
                if len(p) < 19 or not float(p[2]) < 0:
                    continue
                X.append(seed + np.array([float(v) for v in p[5:19]])); y.append(-float(p[2])); g.append(tag.rsplit('_', 2)[0])
    X, y, g = map(np.array, (X, y, g))
    _, keep = np.unique(np.round(X, 9), axis=0, return_index=True)
    keep = np.sort(keep)
    return X[keep], y[keep], g[keep]


def relabel(X, y, path):
    """Replace the suspect designs by their values with the friction floor; drop unusable ones."""
    if not os.path.isfile(path):
        raise SystemExit(f'missing {path}: run relabel_suspects.m first')
    rows = list(csv.DictReader(open(path)))
    key = {tuple(np.round([float(r[f'Au{i}']) for i in range(7)] + [float(r[f'Al{i}']) for i in range(7)], 9)): float(r['floor_min'])
           for r in rows}
    keep = np.ones(len(y), bool); changed = dropped = 0
    for i, xi in enumerate(np.round(X, 9)):
        v = key.get(tuple(xi))
        if v is None:
            continue
        if v > 0:
            changed += abs(v - y[i]) > 1e-6 * y[i]; y[i] = v
        else:
            keep[i] = False; dropped += 1
    return X[keep], y[keep], keep, {'suspects': len(rows), 'changed': int(changed), 'dropped': int(dropped)}


def export(name, X, y, g):
    tr = ~np.isin(g, HELD_OUT)
    sc = StandardScaler().fit(X[tr])
    nets = []
    for s in range(1, 6):
        m = MLPRegressor((128, 128, 64), max_iter=300, early_stopping=True, random_state=s).fit(sc.transform(X[tr]), y[tr])
        nets.append({'weights': [w.tolist() for w in m.coefs_], 'biases': [b.tolist() for b in m.intercepts_]})
    json.dump({'target': name, 'inputs': [f'Au{i}' for i in range(7)] + [f'Al{i}' for i in range(7)], 'mean': sc.mean_.tolist(),
               'scale': sc.scale_.tolist(), 'networks': nets, 'held_out': HELD_OUT, 'training_designs': int(tr.sum()),
               'training_airfoils': sorted(set(g[tr]))}, open(os.path.join(W, 'surrogate', f'model_{name}.json'), 'w'))
    return int(tr.sum()), len(set(g[tr]))


summary = {'held_out': HELD_OUT}
XA, yA, gA = load(lambda r: r['objective'] == 'LDmax' and r['flows'] == 'free' and r['aggregate'] == 'mean')
XA, yA, keepA, info = relabel(XA, yA, os.path.join(W, 'surrogate', 'suspects_A_relabelled.csv'))
gA = gA[keepA]
summary['A'] = dict(info, designs=len(yA))
summary['A']['training_designs'], summary['A']['training_airfoils'] = export('A', XA, yA, gA)
XB, yB, gB = load(lambda r: r['flows'] == 'free+tripped' and r['aggregate'] == 'mean')
summary['B'] = {'designs': len(yB)}
summary['B']['training_designs'], summary['B']['training_airfoils'] = export('B', XB, yB, gB)
json.dump(summary, open(os.path.join(W, 'surrogate', 'training_summary.json'), 'w'), indent=1)
print(json.dumps(summary, indent=1))
