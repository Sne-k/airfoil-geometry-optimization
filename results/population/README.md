# Population study (in progress)

**State: 12 October 2026, 80 of 217 runs.** The batch (`MATLAB/Paper/run_population_study.m`) optimises
30 baseline airfoils under several formulations. The tables in this folder are written by
`MATLAB/Paper/collect_population_results.m` from the runs that are finished, and are replaced when the
batch ends.

| Formulation | Objective | Runs finished |
|---|---|---|
| `peak` | peak CL/CD | 30 of 30 airfoils (seed 1); seeds 2 and 3 still to come |
| `alpha2` | CL/CD at 2° | 30 of 30 |
| `cldes` | CL/CD at the lift coefficient where the original has its peak | 12 of 30 |
| `nocurv` | peak CL/CD without curvature limits | none yet |
| robust formulations | NACA 2412 only, see below | 8 of 8 |
| `robusttrip` for the other 29 airfoils | mean of the peak CL/CD with free transition and with tripped boundary layers, seed 1 | none yet |

Settings of every run: XFOIL at Re = 10⁶ and M = 0, CST shape with 14 design variables (order 6),
genetic algorithm followed by `fmincon`, limits on thickness, pitching moment and curvature
(`docs/methods.md`). Each design is then analysed with 160 panel nodes at the design condition (Ncrit 9),
at Ncrit 5, 7 and 11, at Re = 0.5 and 2 million, and with the boundary layers tripped at 5 % chord on
both surfaces (`conditions.csv`). A gain is always taken against the original airfoil at the same
condition. A polar gives a value only if at least 12 angles converged around 0°; where it does not, the
tables have no value and `summary.csv` counts it.

Two of the 30 `peak` runs (NACA 2418 and NACA 4409) ran while the computer was short of memory, so XFOIL
sweeps of their search may have been stopped by the time limit. Their designs are analysed like all
others and are in the tables. Both runs are repeated before the final tables.

## What survives away from the design condition (30 airfoils)

Gain in peak CL/CD in per cent, over the 30 airfoils (`summary.csv`).

Designs optimised for the peak CL/CD:

| Condition | Median | Quartiles | Lowest to highest | Worse than the original | No value |
|---|---:|---:|---:|---:|---:|
| design | +38.2 | +32.7 to +45.4 | +17.6 to +54.8 | 0 of 30 | 0 |
| Ncrit 5 | +31.1 | +25.4 to +37.9 | +16.1 to +59.8 | 0 of 30 | 0 |
| Ncrit 7 | +37.8 | +28.4 to +43.4 | +16.9 to +54.3 | 0 of 29 | 1 |
| Ncrit 11 | +36.4 | +27.5 to +44.5 | +14.6 to +61.2 | 0 of 30 | 0 |
| Re 0.5e6 | +29.3 | +22.4 to +39.1 | +9.6 to +63.0 | 0 of 29 | 1 |
| Re 2e6 | +36.8 | +31.6 to +45.1 | +20.8 to +64.7 | 0 of 30 | 0 |
| tripped | -1.6 | -6.7 to +3.3 | -25.4 to +33.0 | 19 of 30 | 0 |

Designs optimised for CL/CD at 2°:

| Condition | Median | Quartiles | Lowest to highest | Worse than the original | No value |
|---|---:|---:|---:|---:|---:|
| design | +24.8 | +11.0 to +36.4 | -20.9 to +54.3 | 3 of 30 | 0 |
| Ncrit 5 | +5.3 | -4.4 to +15.2 | -31.1 to +54.0 | 9 of 30 | 0 |
| Ncrit 7 | +16.0 | +5.5 to +34.3 | -30.5 to +57.9 | 4 of 29 | 1 |
| Ncrit 11 | +26.5 | +12.8 to +39.2 | -11.1 to +54.3 | 2 of 30 | 0 |
| Re 0.5e6 | +23.6 | +10.3 to +32.5 | -7.2 to +60.7 | 2 of 29 | 1 |
| Re 2e6 | +13.7 | +2.2 to +28.4 | -32.0 to +57.7 | 6 of 29 | 1 |
| tripped | -9.4 | -15.1 to -3.4 | -22.9 to +123.8 | 25 of 30 | 0 |

![Gain by condition](gains_by_condition.png)

- **A design optimised for the peak keeps its gain when Ncrit or the Reynolds number changes.** The
  median stays between 29.3 and 37.8 %, and no design falls below its original.
- **With tripped boundary layers the gain is gone.** The median is −1.6 %, and 19 of the 30 designs are
  worse than their original. What was found for NACA 2412 holds for the population: the gain of a
  single-point optimisation with free transition is a gain in laminar flow.
- **Optimising at a fixed angle gives less and loses more.** The designs optimised at 2° gain a median of
  24.8 % in peak CL/CD, lose most of it at Ncrit 5 (median 5.3 %), and 25 of 30 are worse than their
  original when tripped.

## The gain depends on the angle at which it is reported

At the design condition, the same designs measured two ways (`conditions.csv`, medians over 30 airfoils):

| Designs optimised for | Gain in CL/CD at 2° | Gain in peak CL/CD |
|---|---:|---:|
| peak CL/CD | +35.4 % | +38.2 % |
| CL/CD at 2° | +49.1 % | +24.8 % |

A design optimised at 2° shows about twice the gain at that angle that it has in peak CL/CD; the largest
single value at 2° is 141 %. `gain_by_angle.csv` and the figure give the gain of the peak-optimised
designs at every angle.

![Gain by reporting angle](gain_by_angle.png)

## Robust formulations for NACA 2412

Four formulations, each maximising the peak CL/CD under two conditions at once. The mean over two
transition conditions is the construction of Caboni et al. (2018), who use Ncrit 0.5 and 9.5
(`docs/literature.md`, section 7):

| Formulation | Conditions | Combined by | Runs |
|---|---|---|---|
| `robustmean` | Ncrit 5 and Ncrit 9 | mean | seeds 1 to 3 |
| `robustworst` | Ncrit 5 and Ncrit 9 | the lower value | seed 1 |
| `robusttrip` | free transition (Ncrit 9) and tripped | mean | seeds 1 to 3 |
| `robusttripworst` | free transition (Ncrit 9) and tripped | the lower value | seed 1 |

Gain in peak CL/CD in per cent (first row: peak CL/CD of the original NACA 2412 at that condition;
`peak_s1` is the single-point design of this batch):

| Run | design | Ncrit 5 | Ncrit 7 | Ncrit 11 | Re 0.5e6 | Re 2e6 | tripped |
|---|---:|---:|---:|---:|---:|---:|---:|
| original NACA 2412 (peak CL/CD) | 104.6 | 87.9 | 96.4 | 110.2 | 90.0 | 111.2 | 73.1 |
| `peak_s1` | +35.5 | +49.5 | +42.9 | +30.5 | +25.9 | +48.6 | -4.9 |
| `robustmean_s1` | +31.5 | +48.4 | +40.0 | +26.3 | +21.2 | +47.5 | +2.2 |
| `robustmean_s2` | +30.1 | +46.2 | +37.7 | +24.5 | +19.6 | +43.9 | +0.1 |
| `robustmean_s3` | +32.5 | +50.1 | +41.0 | +27.3 | +22.1 | +49.6 | +2.4 |
| `robustworst_s1` | +31.9 | +49.3 | +40.2 | +27.0 | +21.9 | +49.2 | +3.3 |
| `robusttrip_s1` | +30.2 | +42.5 | +37.1 | +25.7 | +21.7 | +40.8 | +2.4 |
| `robusttrip_s2` | +24.7 | +39.3 | +32.0 | +20.3 | +16.7 | +38.8 | +4.2 |
| `robusttrip_s3` | +32.2 | +48.8 | +40.0 | +27.6 | +22.5 | +48.7 | +3.0 |
| `robusttripworst_s1` | -0.5 | +12.3 | +5.6 | -4.4 | -6.3 | +10.2 | +6.9 |

What the table shows:

1. **The single-point design was never sensitive to Ncrit.** It gains 35.5 % at the design condition and
   49.5 % at Ncrit 5. Adding Ncrit 5 to the objective gives the same picture, three to five points lower
   at the design condition.
2. **What the single-point design loses is fully turbulent flow.** With tripped boundary layers it is
   4.9 % below the original. The eight robust designs do not fall below the original when tripped.
3. **Putting the tripped condition into the objective removes that loss at little cost.** The
   `robusttrip` designs keep 25 to 32 % at the design condition and are 2 to 4 % better than the original
   when tripped. All eight designs meet the curvature limits.
4. **A design that is best in the worse of the two conditions gives up the laminar gain.**
   `robusttripworst` raises the tripped CL/CD by 6.9 % and has no gain with free transition. In this
   design space, about 7 % is what fully turbulent flow allows for NACA 2412; the larger gains are gains
   in laminar flow.

Two of these designs (`robusttrip_s3`, `robusttripworst_s1`) are part of the RANS design study
([results/cfd](../cfd/README.md)). In fully turbulent Fluent runs their best CL/CD is 3.3 % and 1.5 %
above that of NACA 2412, and with the transition model 17.1 % above and 5.4 % below.

## Files

| File | Content |
|---|---|
| `runs.csv` | one row per finished run: formulation, seed, objective before and after, curvature, effort, code version. The run times include hours in which the laptop was asleep, so the median time per evaluation is the figure to use |
| `conditions.csv` | one row per run and condition: peak CL/CD, CL/CD at 2° and at the design lift coefficient, for the original and the design; converged angles of both polars |
| `summary.csv` | statistics over the airfoils per formulation and condition |
| `gain_by_angle.csv` | gain of the peak-optimised designs at every angle of attack |
| `airfoils/` | coordinates of the optimised designs |
