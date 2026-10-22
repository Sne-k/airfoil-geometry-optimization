# Surrogate-assisted optimiser: benchmark

`optimize_airfoil(..., 'Algorithm', 'surrogate')` (see [MATLAB/Optimization](../../MATLAB/Optimization/README.md#surrogate-assisted-search))
against the current optimiser (GA → fmincon), on six airfoils that the surrogate never saw in training.

## Task and setup

- Objective: the mean of the peak CL/CD with free transition (Ncrit 9) and with transition tripped at 5 %
  chord, Re = 10⁶ (the "robusttrip" formulation of the population study). All limits as in the
  population study: t/c not below the original, |CM| at 0° at most 0.05 above the original, curvature
  limits, CST order 6, every coefficient changed by at most 0.08.
- Airfoils: NACA 2412, NACA 0012, NACA 4415, Clark Y, SD7062 and S1223; three seeds each.
- Surrogate: an ensemble of five neural networks (three hidden layers, 128-128-64, ReLU) that predicts
  the objective from the 14 CST coefficients. It was trained on 10 341 designs that XFOIL analysed
  during the robusttrip runs of the population study, on its other 24 airfoils.
- Warm start: the robusttrip optima of the three training airfoils whose CST fits are closest to the
  airfoil.
- Trust limits, from the training airfoils only: distance from the nearest training airfoil at most
  5.78 (in standardised CST units, the largest such distance between training airfoils); median
  prediction error on the candidates at most 6.2 % (90th percentile of a grouped cross-validation); at
  least half of the candidates with a usable polar.
- The values below are the objectives that the optimiser recorded with XFOIL, with the friction floor.
  The final designs have not yet been put through the full re-analysis of the population study.

All runs: [benchmark_runs.csv](benchmark_runs.csv), with the XFOIL-analysed designs, run time, trust
check and code version of every run.

## Results: final version against the current optimiser

| Airfoil | Original | Surrogate optimiser, seeds 1 / 2 / 3 | Mean | XFOIL designs (mean) | Time (mean) | Current optimiser, seeds 1 / 2 / 3 | Mean | XFOIL designs (mean) | Time (mean) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| NACA 2412 | 88.7 | 107.6 / 106.8 / 108.2 | 107.5 | 84 | 12 min | 105.5 / 103.3 / 106.8 | 105.2 | 915 | 41 min |
| NACA 0012 | 69.9 | 98.7 / 98.4 / 99.2 ¹ | 98.8 | 328 | 22 min | 84.8 / 94.2 / 97.9 | 92.3 | 890 | 41 min |
| NACA 4415 | 89.8 | 108.4 / 108.9 / 108.2 | 108.5 | 58 | 4 min | 108.8 / 106.1 / 108.5 | 107.8 | 982 | 41 min |
| Clark Y | 96.8 | 125.2 / 125.0 / 125.4 | 125.2 | 139 | 11 min | 124.1 / 123.9 / 122.3 | 123.4 | 1018 | 51 min |
| SD7062 | 99.7 | 119.9 / 118.4 / 120.4 | 119.6 | 54 | 6 min | 120.3 / 119.5 / 120.4 | 120.0 | 1063 | 47 min |
| S1223 | 102.4 | 128.3 / 130.1 / 126.5 ¹ | 128.3 | 1096 | 52 min | 126.8 / 126.9 / 123.4 | 125.7 | 1122 | 51 min |

¹ Not trusted; the result comes from the fallback to the genetic algorithm with XFOIL.

- The surrogate was trusted in 14 of 18 runs. In those, it needed 4 to 22 times fewer XFOIL analyses
  than the current optimiser with the same seed. Its result was higher in 9 of the 14 runs and at most
  1.1 lower in the other 5 (NACA 4415 seeds 1 and 3, SD7062 all three seeds).
- S1223 lies far outside the training airfoils (distance 7.48 against the limit 5.78; the other five are
  at 1.17 to 2.78). The check rejects the surrogate in all three seeds, and the fallback then gives a
  result similar to the current optimiser, at a similar cost.
- NACA 0012 seed 3: only a third of the candidates gave a usable polar, so the check rejected the
  surrogate and the run fell back.

## How the method developed

Mean of three seeds: objective / XFOIL-analysed designs. The versions are commits of
`optimize_airfoil.m`.

| Airfoil | v1: no check (d9f9e25) | v2: check + fallback (b709ef0) | v3: + closed loop (23285ba) | v4: fallback restart (021a63d) | Current optimiser |
|---|---:|---:|---:|---:|---:|
| NACA 2412 | 107.5 / 84 | 107.5 / 84 | 107.5 / 84 | 107.5 / 84 | 105.2 / 915 |
| NACA 0012 | 98.3 / 96 | 98.6 / 338 | 98.6 / 317 | 98.8 / 328 | 92.3 / 890 |
| NACA 4415 | 108.5 / 58 | 108.5 / 58 | 108.5 / 58 | 108.5 / 58 | 107.8 / 982 |
| Clark Y | 125.2 / 139 | 125.2 / 139 | 125.2 / 139 | 125.2 / 139 | 123.4 / 1018 |
| SD7062 | 119.5 / 45 | 119.9 / 977 | 119.6 / 54 | 119.6 / 54 | 120.0 / 1063 |
| S1223 | 110.2 / 76 | 126.1 / 1109 | 118.5 / 1153 | 128.3 / 1096 | 125.7 / 1122 |

- **v1** trusted the surrogate everywhere. On S1223 it predicted 161 where XFOIL gave 110, and the
  result stayed 15.5 below the current optimiser.
- **v2** added the trust check and the fallback. It fixed S1223, but SD7062 fell back in every seed
  (about 980 designs) although v1 was already close there.
- **v3** added the closed loop. SD7062 now passes the check after one correction round (54 designs). On
  S1223 the loop lowered the error (seed 1: 45 % → 22 %) but never passed the check. Its candidates,
  all close to one design, then filled the whole starting population of the fallback, which ended
  lower (111.9 and 118.2 in seeds 2 and 3).
- **v4** starts the fallback from the first-search candidates and the usual starting population. Only
  the four runs that fall back (S1223 seeds 1 to 3, NACA 0012 seed 3) were run again; the other 14
  never reach the fallback, so v4 gives them the v3 result.

## Still running

- Optimiser comparison at equal budget on NACA 2412 (peak CL/CD, free transition): GA, particle swarm,
  Bayesian optimisation and the surrogate, three seeds each, all with the current code.
- Seeds 4 to 10 on NACA 2412 and S1223 (surrogate and current optimiser), for a rank test.
- A comparison with Xoptfoil2 on the six airfoils, for peak CL/CD with free transition. Xoptfoil2 can
  trip transition only for the whole run, so it cannot run the free-plus-tripped task above.
- The re-analysis of the final designs with all safeguards of the population study.
