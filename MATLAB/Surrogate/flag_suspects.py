"""Step 1a: flag logged designs whose XFOIL value is far above what the surrogate predicts out of fold
(grouped 5-fold by airfoil). A false low-drag XFOIL solution is too high, so these are the suspects.
Writes surrogate/suspects_<A|B>.csv (tag, design CST, logged value, prediction)."""
import csv, glob, os, sys
import numpy as np
from sklearn.neural_network import MLPRegressor
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import GroupKFold
W = os.environ.get('AIRFOIL_WORK') or sys.exit('Set AIRFOIL_WORK to the work folder (MATLAB/Surrogate/README.md).')
runs = {r['tag']: r for r in csv.DictReader(open(os.path.join(W, 'feasibility', 'runs_seed_fit.csv')))}
def load(select):
    X, y, g, t = [], [], [], []
    for tag, r in runs.items():
        if not select(r): continue
        seed = np.array([float(r[f'Au{i}']) for i in range(7)] + [float(r[f'Al{i}']) for i in range(7)])
        for f in glob.glob(os.path.join(W, 'population_runs', tag, 'history', 'eval_*.csv')):
            for line in open(f):
                p = line.rstrip(',\n').split(',')
                if len(p) < 19 or not float(p[2]) < 0: continue
                X.append(seed + np.array([float(v) for v in p[5:19]])); y.append(-float(p[2])); g.append(tag.rsplit('_', 2)[0]); t.append(tag)
    X, y, g, t = map(np.array, (X, y, g, t))
    _, keep = np.unique(np.round(X, 9), axis=0, return_index=True); keep = np.sort(keep)
    return X[keep], y[keep], g[keep], t[keep]
sets = {'A': lambda r: r['objective'] == 'LDmax' and r['flows'] == 'free' and r['aggregate'] == 'mean',
        'B': lambda r: r['flows'] == 'free+tripped' and r['aggregate'] == 'mean'}
for name, sel in sets.items():
    X, y, g, t = load(sel)
    pred = np.full(len(y), np.nan)
    for tr, te in GroupKFold(5).split(X, y, g):
        m = make_pipeline(StandardScaler(), MLPRegressor((128, 128, 64), max_iter=200, early_stopping=True, random_state=1))
        m.fit(X[tr], y[tr]); pred[te] = m.predict(X[te])
    r = (y - pred) / pred * 100
    for thr in (10, 15, 20, 30):
        print(f'{name}: logged value more than {thr} % above the prediction: {np.sum(r > thr)} of {len(y)}')
    sus = np.where(r > 15)[0]
    with open(os.path.join(W, 'surrogate', f'suspects_{name}.csv'), 'w', newline='') as f:
        w = csv.writer(f); w.writerow(['tag'] + [f'Au{i}' for i in range(7)] + [f'Al{i}' for i in range(7)] + ['logged', 'predicted'])
        for i in sus: w.writerow([t[i]] + [f'{v:.17g}' for v in X[i]] + [f'{y[i]:.6g}', f'{pred[i]:.6g}'])
    print(f'{name}: {len(sus)} suspects written; by airfoil:', dict(zip(*np.unique(g[sus], return_counts=True))))
