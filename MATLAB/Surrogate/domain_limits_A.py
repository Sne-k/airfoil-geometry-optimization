"""Trust limits of surrogate A (free transition, peak CL/CD; relabelled suspects as in train_export.py) from the training airfoils only (no test airfoil involved):
max_median_error = 90th percentile of the relative out-of-fold error (grouped 5-fold CV by airfoil, 24 airfoils);
max_distance = largest distance, in standardised CST units, of a training airfoil's seed fit from its nearest
other training airfoil. Writes surrogate/model_A_domain.json with the seed fits of the training airfoils."""
import csv, glob, json, os, sys
import numpy as np
from sklearn.model_selection import GroupKFold
from sklearn.neural_network import MLPRegressor
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
W = os.environ.get('AIRFOIL_WORK') or sys.exit('Set AIRFOIL_WORK to the work folder (MATLAB/Surrogate/README.md).')
m = json.load(open(os.path.join(W, 'surrogate', 'model_A.json')))
runs = {r['tag']: r for r in csv.DictReader(open(os.path.join(W, 'feasibility', 'runs_seed_fit.csv')))}
X, y, g, seeds = [], [], [], {}
for tag, r in runs.items():
    a = tag.rsplit('_', 2)[0]
    seed = np.array([float(r[f'Au{i}']) for i in range(7)] + [float(r[f'Al{i}']) for i in range(7)])
    seeds.setdefault(a, seed)
    if r['objective'] != 'LDmax' or r['flows'] != 'free' or r['aggregate'] != 'mean' or a in m['held_out']: continue
    for f in glob.glob(os.path.join(W, 'population_runs', tag, 'history', 'eval_*.csv')):
        for line in open(f):
            p = line.rstrip(',\n').split(',')
            if len(p) < 19 or not float(p[2]) < 0: continue
            X.append(seed + np.array([float(v) for v in p[5:19]])); y.append(-float(p[2])); g.append(a)
X, y, g = map(np.array, (X, y, g))
_, k = np.unique(np.round(X, 9), axis=0, return_index=True); k = np.sort(k); X, y, g = X[k], y[k], g[k]
fl = {tuple(np.round([float(r[f'Au{i}']) for i in range(7)] + [float(r[f'Al{i}']) for i in range(7)], 9)): float(r['floor_min'])
      for r in csv.DictReader(open(os.path.join(W, 'surrogate', 'suspects_A_relabelled.csv')))}
keep = np.ones(len(y), bool)
for i, xi in enumerate(np.round(X, 9)):
    v = fl.get(tuple(xi))
    if v is None: continue
    if v > 0: y[i] = v
    else: keep[i] = False
X, y, g = X[keep], y[keep], g[keep]
pred = np.full(len(y), np.nan)
for tr, te in GroupKFold(5).split(X, y, g):
    mm = make_pipeline(StandardScaler(), MLPRegressor((128, 128, 64), max_iter=300, early_stopping=True, random_state=1)).fit(X[tr], y[tr])
    pred[te] = mm.predict(X[te])
err = np.abs(pred - y) / y
train = sorted(a for a in seeds if a not in m['held_out'])
S = np.array([seeds[a] for a in train]); sc = np.array(m['scale'])
D = np.linalg.norm((S[:, None, :] - S[None, :, :]) / sc, axis=2); np.fill_diagonal(D, np.inf)
out = {'max_median_error': float(np.percentile(err, 90)), 'median_error': float(np.median(err)), 'max_distance': float(D.min(1).max()),
       'min_usable_fraction': 0.5, 'training_airfoils': train, 'training_seeds': S.tolist()}
json.dump(out, open(os.path.join(W, 'surrogate', 'model_A_domain.json'), 'w'), indent=1)
print({k: v for k, v in out.items() if k not in ('training_seeds', 'training_airfoils')})
