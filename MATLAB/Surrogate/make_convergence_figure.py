"""Best valid objective so far against the number of XFOIL-analysed designs, ten seeds, surrogate optimiser and current
optimiser (GA -> fmincon), NACA 2412 and S1223 (the convention of Chen, Chiu & Fuge: mean or median best-so-far
against the evaluation count over repeated runs). Same final runs as run_step4.m. Writes
results/surrogate/convergence_ten_seeds.png and convergence_ten_seeds.csv (median and quartiles)."""
import csv, json, os, sys
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

B = os.path.join(os.environ.get('AIRFOIL_WORK') or sys.exit('Set AIRFOIL_WORK (MATLAB/Surrogate/README.md).'), 'surrogate')
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'results', 'surrogate')
FALLBACK = {('NACA_0012', 3), ('S1223', 1), ('S1223', 2), ('S1223', 3)}


def folder(a, method, s):
    if method == 'ga':
        src = 'benchmark' if s <= 3 else 'benchmark_v4'
    elif s <= 3:
        src = 'benchmark_v4' if (a, s) in FALLBACK else 'benchmark_v3'
    elif a == 'NACA_2412' and s == 4:
        src = 'benchmark_v4'
    else:
        src = 'benchmark_v5'
    return os.path.join(B, src, f'{a}_{method}_s{s}')


def curve(path):
    """best objective after each XFOIL-analysed design (the fitted original counts as the start). Only the start
    and global stages raise it: the local stage (fmincon) scores designs without rejecting curvature violations,
    so its values are not all valid results. The last point is the recorded final objective of the run."""
    best, out = None, []
    for r in csv.DictReader(open(os.path.join(path, 'history.csv'))):
        if float(r['xfoil_analyses']) <= 0:
            continue
        f = float(r['objective'])
        if f < 0 and r['stage'] in ('start', 'global'):
            best = -f if best is None else max(best, -f)
        out.append(best if best is not None else np.nan)
    out[-1] = json.load(open(os.path.join(path, 'run_info.json')))['objectiveFinal']
    return np.array(out)


ink, muted, grid, surface = '#1f1f1e', '#6b6a64', '#e4e3de', '#fcfcfb'
colors = {'surrogate': '#2a78d6', 'ga': '#eb6834'}
names = {'surrogate': 'surrogate optimiser', 'ga': 'current optimiser (GA \u2192 fmincon)'}
styles = {'surrogate': '-', 'ga': '--'}
fig, axes = plt.subplots(1, 2, figsize=(11, 4.2), facecolor=surface)
rows = []
for ax, a, title in zip(axes, ['NACA_2412', 'S1223'], ['NACA 2412', 'S1223 (outside the training airfoils)']):
    ax.set_facecolor(surface)
    for m in ['ga', 'surrogate']:
        C = [curve(folder(a, m, s)) for s in range(1, 11)]
        n = max(len(c) for c in C)
        M = np.array([np.concatenate([c, np.full(n - len(c), c[-1])]) for c in C])   # a finished run keeps its best
        med, q1, q3 = np.nanmedian(M, 0), np.nanpercentile(M, 25, 0), np.nanpercentile(M, 75, 0)
        x = np.arange(1, n + 1)
        ax.fill_between(x, q1, q3, color=colors[m], alpha=0.15, linewidth=0)
        ax.plot(x, med, styles[m], color=colors[m], linewidth=2)
        ends = [len(c) for c in C]
        pos = {('NACA_2412', 'surrogate'): (0.24, 0.84), ('NACA_2412', 'ga'): (0.50, 0.12),
               ('S1223', 'surrogate'): (0.04, 0.90), ('S1223', 'ga'): (0.04, 0.74)}[(a, m)]   # empty regions
        ax.plot([pos[0], pos[0] + 0.05], [pos[1] + 0.025] * 2, styles[m], color=colors[m], linewidth=2, transform=ax.transAxes)
        ax.text(pos[0] + 0.065, pos[1], f'{names[m]}\nmedian {med[-1]:.1f} after {int(np.median(ends))} designs',
                transform=ax.transAxes, va='center', fontsize=8.5, color=ink, linespacing=1.3)
        for k in range(n):
            rows.append([a, m, k + 1, med[k], q1[k], q3[k]])
    ax.set_xscale('log')
    ax.set_title(title, fontsize=11, color=ink, loc='left')
    ax.set_xlabel('designs analysed with XFOIL', fontsize=9.5, color=muted)
    ax.grid(True, color=grid, linewidth=0.8)
    for sp in ax.spines.values():
        sp.set_visible(False)
    ax.tick_params(colors=muted, labelsize=8.5)
axes[0].set_ylabel('best objective so far\n(mean of free and tripped peak CL/CD)', fontsize=9.5, color=muted)
handles = [plt.Line2D([], [], color=colors[m], linestyle=styles[m], linewidth=2) for m in ['surrogate', 'ga']]
fig.legend(handles, [names['surrogate'], names['ga']], loc='upper center', ncol=2, frameon=False, fontsize=9)
fig.text(0.01, 0.005, 'Median of ten seeds; band: quartiles. A run that has ended keeps its final value. '
         'The surrogate\'s own evaluations need no XFOIL and are not counted.',
         fontsize=8, color=muted)
fig.tight_layout(rect=(0, 0.03, 1, 0.92))
fig.savefig(os.path.join(OUT, 'convergence_ten_seeds.png'), dpi=150, facecolor=surface)
with open(os.path.join(OUT, 'convergence_ten_seeds.csv'), 'w', newline='') as fh:
    w = csv.writer(fh)
    w.writerow(['airfoil', 'optimiser', 'xfoil_analysed_designs', 'best_median', 'best_q25', 'best_q75'])
    w.writerows([[r[0], r[1], r[2]] + [round(v, 4) for v in r[3:]] for r in rows])
print('done')
