# Surrogate of XFOIL for the surrogate-assisted optimiser

The trained surrogates and the scripts that made them and ran the benchmark of
[results/surrogate](../../results/surrogate/README.md). The search itself is part of `optimize_airfoil`
(`'Algorithm', 'surrogate'`, see [Optimization](../Optimization/README.md#surrogate-assisted-search)).

## Using a model

```matlab
cd MATLAB/Optimization
r = optimize_airfoil('NACA 2412', 'Algorithm', 'surrogate', ...
    'SurrogateModel', fullfile('..', 'Surrogate', 'models', 'model_A.json'));   % peak CL/CD, free transition
```

| Model | Predicts | Trained on | Trust limits (`_domain.json`) |
|---|---|---|---|
| `models/model_A.json` | peak CL/CD with free transition (Ncrit 9, Re = 10⁶) | 43 737 designs of the peak and no-curvature runs of the population study, 24 airfoils | distance 5.15, median error 7.0 % |
| `models/model_B.json` | mean of the peak CL/CD with free transition and with transition tripped at 5 % chord | 10 341 designs of the robusttrip runs, 24 airfoils | distance 5.78, median error 6.2 % |

Each model is an ensemble of five networks (14 CST coefficients in, hidden layers 128-128-64 with ReLU, one
output), stored as weights and the input scaling; `../Optimization/surrogateModel.m` reads it. Six
airfoils were held out of the training (NACA 2412, NACA 0012, NACA 4415, Clark Y, SD7062, S1223). A model
fits only the objective and settings it was trained for; for an airfoil far from the training airfoils
the trust check rejects it, and the search falls back to the genetic algorithm with XFOIL.

## Reproducing the training and the benchmark

The training data are the evaluation logs of the 217 runs of the population study (`history/eval_*.csv`,
about 170 MB), which are not in the repository. The scripts read them from a work folder named by the
environment variable `AIRFOIL_WORK`:

```text
AIRFOIL_WORK/
  population_runs/<tag>/        the run folders of run_population_study.m (result.mat, run_info.json, history/)
  feasibility/runs_seed_fit.csv written by export_runs.m
  surrogate/                    outputs of the steps below
  refs/uiuc/<name>.dat          UIUC coordinates of the non-NACA seeds (not redistributed)
  tools/xfoil.exe, tools/xoptfoil2/x2/xoptfoil2.exe
```

| Step | Script | Output (in `AIRFOIL_WORK`) |
|---|---|---|
| 1 | `export_runs.m`: seed CST fit and settings of every population run | `feasibility/runs_seed_fit.csv` |
| 2 | `feasibility_check.py`: can a surrogate rank designs of unseen airfoils (several model types, grouped cross-validation)? | log |
| 3 | `flag_suspects.py`: logged designs far above the out-of-fold prediction (possible false XFOIL solutions) | `surrogate/suspects_A.csv` |
| 4 | `relabel_suspects.m`: the suspects analysed again with the friction floor | `surrogate/suspects_A_relabelled.csv` |
| 5 | `train_export.py`: the two ensembles | `surrogate/model_A.json`, `model_B.json` |
| 6 | `domain_limits.py`, `domain_limits_A.py`: trust limits from the training airfoils only | `surrogate/model_*_domain.json` |
| 7 | `benchmark_case.m`: one benchmark run (`'surrogate'` or `'ga'`, robust objective) | `surrogate/benchmark_v5/<run>/` |
| 8 | `equal_budget_case.m`: one run of the comparison at equal budget on NACA 2412 | `surrogate/compare_v4/<run>/` |
| 9 | `peak_compare.m`: the six-airfoil comparison with Xoptfoil2 | `surrogate/peak_compare/` |
| 10 | `safeguards_final_designs.m`: the final designs through the safeguards of the population study | `surrogate/step4/` |
| 11 | `make_convergence_figure.py`: best value so far against XFOIL-analysed designs | `results/surrogate/convergence_ten_seeds.*` |

The published runs used frozen copies of the code at the commits recorded in each `run_info.json`
(v1 d9f9e25, v2 b709ef0, v3 23285ba, v4 021a63d, v5 be7baa1); these scripts use the code of this
repository. The models in `models/` are the ones the benchmark used. Python 3 with numpy, scikit-learn,
scipy and matplotlib.
