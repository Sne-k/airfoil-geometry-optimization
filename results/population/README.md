# Population study (in progress)

**State: 5 October 2026, 11 of 188 runs.** The batch (`MATLAB/Paper/run_population_study.m`) optimises
30 baseline airfoils under several formulations and takes about a week. The tables in this folder are
written by `MATLAB/Paper/collect_population_results.m` from the runs that are finished, and are
replaced when the batch ends. With three airfoils done, `summary.csv`, `gain_by_angle.csv` and the two
figures are not yet statistics; only the first block of runs, the robust formulations for NACA 2412,
is complete and is discussed here.

Settings of every run: XFOIL at Re = 10⁶ and M = 0, CST shape with 14 design variables (order 6),
genetic algorithm followed by `fmincon`, limits on thickness, pitching moment and curvature
(`docs/methods.md`). Each design is then analysed
with 160 panel nodes at the design condition (Ncrit 9), at Ncrit 5, 7 and 11, at Re = 0.5 and 2 million,
and with the boundary layers tripped at 5 % chord on both surfaces (`conditions.csv`). A gain is always
taken against the original airfoil at the same condition.

## Robust formulations for NACA 2412

Four formulations, each maximising the peak CL/CD under two conditions at once:

| Formulation | Conditions | Combined by | Runs |
|---|---|---|---|
| `robustmean` | Ncrit 5 and Ncrit 9 | mean | seeds 1 to 3 |
| `robustworst` | Ncrit 5 and Ncrit 9 | the lower value | seed 1 |
| `robusttrip` | free transition (Ncrit 9) and tripped | mean | seeds 1 to 3 |
| `robusttripworst` | free transition (Ncrit 9) and tripped | the lower value | seed 1 |

Gain in peak CL/CD in per cent (first row: peak CL/CD of the original NACA 2412 at that condition):

| Run | design | Ncrit 5 | Ncrit 7 | Ncrit 11 | Re 0.5e6 | Re 2e6 | tripped |
|---|---:|---:|---:|---:|---:|---:|---:|
| original NACA 2412 (peak CL/CD) | 104.6 | 87.9 | 96.4 | 110.2 | 90.0 | 111.2 | 73.1 |
| `robustmean_s1` | +31.5 | +48.4 | +40.0 | +26.3 | +21.2 | +47.5 | +2.2 |
| `robustmean_s2` | +30.1 | +46.2 | +37.7 | +24.5 | +19.6 | +43.9 | +0.1 |
| `robustmean_s3` | +32.5 | +50.1 | +41.0 | +27.3 | +22.1 | +49.6 | +2.4 |
| `robustworst_s1` | +31.9 | +49.3 | +40.2 | +27.0 | +21.9 | +49.2 | +3.3 |
| `robusttrip_s1` | +30.2 | +42.5 | +37.1 | +25.7 | +21.7 | +40.8 | +2.4 |
| `robusttrip_s2` | +24.7 | +39.3 | +32.0 | +20.3 | +16.7 | +38.8 | +4.2 |
| `robusttrip_s3` | +32.2 | +48.8 | +40.0 | +27.6 | +22.5 | +48.7 | +3.0 |
| `robusttripworst_s1` | -0.5 | +12.3 | +5.6 | -4.4 | -6.3 | +10.2 | +6.9 |

What the table shows:

1. **The single-point design was never sensitive to Ncrit.** The design optimised at Ncrit 9 alone
   gains 35.3 % there and 49.5 % at Ncrit 5 (`results/paper/sensitivity.csv`). Adding Ncrit 5 to the
   objective gives the same picture, three to five points lower at the design condition.
2. **What the single-point design loses is fully turbulent flow.** With tripped boundary layers its best
   CL/CD is 68.3 against 72.6 for the original, a loss of 5.9 % (`results/cfd/designs/xfoil.csv`,
   M = 0.15). The designs of the table above do not fall below the original when tripped.
3. **Putting the tripped condition into the objective removes that loss at little cost.** The
   `robusttrip` designs keep 25 to 32 % at the design condition and are 2 to 4 % better than the original
   when tripped. All eight designs meet the curvature limits.
4. **A design that is best in the worse of the two conditions gives up the laminar gain.**
   `robusttripworst` raises the tripped CL/CD by 6.9 % and has no gain with free transition. In this
   design space, about 7 % is what fully turbulent flow allows for NACA 2412; the larger gains are gains
   in laminar flow.

Two of these designs (`robusttrip_s3`, `robusttripworst_s1`) have been added to the RANS design study
(`MATLAB/CFD/designStudyAirfoils.m`); their Fluent runs are queued.

## Files

| File | Content |
|---|---|
| `runs.csv` | one row per finished run: formulation, seed, objective before and after, curvature, effort, code version |
| `conditions.csv` | one row per run and condition: peak CL/CD, CL/CD at 2° and at the design lift coefficient, for the original and the design |
| `summary.csv` | statistics over the airfoils per formulation and condition (not meaningful before the batch ends) |
| `gain_by_angle.csv` | gain of the peak-optimised designs at every angle of attack |
| `airfoils/` | coordinates of the optimised designs |
