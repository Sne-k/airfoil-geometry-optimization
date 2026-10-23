"""Feasibility check: can a surrogate trained on the logged XFOIL evaluations of the population study
predict and rank designs of airfoils it has not seen?

Data: population_runs/<tag>/history/eval_*.csv (time, stage, f, nXfoil, seconds, d1..d14) and
feasibility/runs_seed_fit.csv (seed CST fit per run). Absolute shape = seed fit + d. Rows with f < 0 are
designs XFOIL evaluated: objective = -f (the lower of the 160- and 200-node values). f = 0 (unusable polar)
and f > 0 (rejected before XFOIL) are excluded from the regression.

Targets:  A  peak CL/CD with free transition (runs 'peak' and 'nocurv', 120 runs)
          B  mean of the peak CL/CD with free and tripped transition (runs 'robusttrip', 32 runs)
Test:     grouped 5-fold cross-validation by airfoil (the model never sees the test airfoils).
Metrics:  R2, median absolute error (%), Spearman rank correlation per test airfoil, and the 'pick test':
          among all designs logged for a test airfoil, the one the surrogate ranks first, compared with the
          best logged design (shortfall in % of the best).
"""
import csv, glob, os, sys, time
import numpy as np
from scipy.stats import spearmanr
from sklearn.ensemble import HistGradientBoostingRegressor
from sklearn.neighbors import KNeighborsRegressor
from sklearn.neural_network import MLPRegressor
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import GroupKFold

W = os.environ.get('AIRFOIL_WORK') or sys.exit('Set AIRFOIL_WORK to the work folder (MATLAB/Surrogate/README.md).')
runs = {r['tag']: r for r in csv.DictReader(open(os.path.join(W, 'feasibility', 'runs_seed_fit.csv')))}


def airfoil_of(tag):
    return tag.rsplit('_', 2)[0]


def load(select):
    X, y, g, t = [], [], [], []
    for tag, r in runs.items():
        if not select(tag, r):
            continue
        seed = np.array([float(r[f'Au{i}']) for i in range(7)] + [float(r[f'Al{i}']) for i in range(7)])
        for f in glob.glob(os.path.join(W, 'population_runs', tag, 'history', 'eval_*.csv')):
            for line in open(f):
                p = line.rstrip(',\n').split(',')
                if len(p) < 19:
                    continue
                fv = float(p[2])
                if not fv < 0:
                    continue
                d = np.array([float(v) for v in p[5:19]])
                X.append(seed + d); y.append(-fv); g.append(airfoil_of(tag)); t.append(tag)
    X = np.array(X); y = np.array(y); g = np.array(g); t = np.array(t)
    _, keep = np.unique(np.round(X, 9), axis=0, return_index=True)     # one row per distinct design
    keep = np.sort(keep)
    return X[keep], y[keep], g[keep], t[keep]


def evaluate(name, X, y, g, models):
    print(f'\n=== {name}: {len(y)} distinct evaluated designs, {len(set(g))} airfoils, CL/CD {y.min():.0f} to {y.max():.0f}')
    gkf = GroupKFold(n_splits=5)
    for mname, make in models.items():
        t0 = time.time()
        pred = np.full(len(y), np.nan)
        for tr, te in gkf.split(X, y, g):
            m = make(); m.fit(X[tr], y[tr]); pred[te] = m.predict(X[te])
        r2 = 1 - np.sum((pred - y) ** 2) / np.sum((y - y.mean()) ** 2)
        ape = np.abs(pred - y) / y * 100
        rho, short, top = [], [], []
        for a in sorted(set(g)):
            i = g == a
            rho.append(spearmanr(pred[i], y[i]).correlation)
            best = y[i].max(); pick = y[i][np.argmax(pred[i])]
            short.append(100 * (best - pick) / best)
            k = max(1, int(0.01 * i.sum()))                            # top 1 % by the surrogate
            top.append(100 * (best - y[i][np.argsort(pred[i])[-k:]].max()) / best)
        print(f'  {mname:22s} R2 {r2:5.2f} | median error {np.median(ape):5.1f} % (90 %: {np.percentile(ape, 90):5.1f} %) | '
              f'Spearman per airfoil median {np.median(rho):.2f} | pick shortfall median {np.median(short):4.1f} %, '
              f'worst {max(short):5.1f} % | best of its top 1 %: median {np.median(top):4.1f} %, worst {max(top):5.1f} %  ({time.time() - t0:.0f} s)')


models = {
    'nearest neighbours': lambda: make_pipeline(StandardScaler(), KNeighborsRegressor(n_neighbors=10, weights='distance')),
    'gradient boosting': lambda: HistGradientBoostingRegressor(max_iter=600, learning_rate=0.08, max_leaf_nodes=63, random_state=1),
    'neural network': lambda: make_pipeline(StandardScaler(), MLPRegressor(hidden_layer_sizes=(128, 128, 64), max_iter=200,
                                                                            early_stopping=True, random_state=1)),
}
XA, yA, gA, tA = load(lambda tag, r: r['objective'] == 'LDmax' and r['flows'] == 'free' and r['aggregate'] == 'mean')
evaluate('A  peak CL/CD, free transition', XA, yA, gA, models)
XB, yB, gB, tB = load(lambda tag, r: r['flows'] == 'free+tripped' and r['aggregate'] == 'mean')
evaluate('B  mean of free and tripped peak CL/CD', XB, yB, gB, models)
