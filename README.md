# Airfoil Geometry Optimization (NACA 2412)

MATLAB code and results of a 4th-semester aeronautical engineering mini project (2024–25):
parametric optimisation of the NACA 2412 airfoil with a hybrid **Genetic Algorithm + Nonlinear
Programming (fmincon)** search, a geometric **morphing** sequence from the baseline to the optimised
shape, and `.dat` export for aerodynamic analysis in **XFLR5**.

![Morphing from NACA 2412 to the optimised airfoil](results/figures/morphing.gif)

## Method

```
NACA 2412  ->  design variables [m p t]  ->  GA (global)  ->  fmincon (local)  ->  optimised airfoil
                                                                                      |
                              morphing sequence (21 .dat files)  <--------------------+
                                                                                      |
                                              XFLR5 analysis: CL, CD, CL/CD vs alpha <-+
```

- **Geometry:** NACA 4-digit equations; `m` = maximum camber, `p` = its chordwise position,
  `t` = maximum thickness. Bounds: `0 ≤ m ≤ 0.05`, `0.2 ≤ p ≤ 0.6`, `0.08 ≤ t ≤ 0.15`.
- **Objective:** maximise camber/thickness. This is a geometric stand-in for lift-to-drag; no
  aerodynamic solver runs inside the optimisation loop.
- **Optimiser:** `ga` (population 100, 100 generations), then `fmincon` (interior-point) from the GA result.
- **Aerodynamics:** the baseline and optimised `.dat` files were analysed afterwards in XFLR5.

## Results

The optimiser returns **m = 0.050, p ≈ 0.52, t = 0.080** (roughly a NACA 5508):

![Baseline vs optimised airfoil](results/figures/geometry_comparison.png)

XFLR5 results from the project report:

| | NACA 2412 | Optimised | Change |
|---|---:|---:|---:|
| CL at α = 0° | 0.247 | 0.591 | +139 % |
| CD at α = 0° | 0.00572 | 0.00564 | −1.4 % |
| CL/CD at α = 0° | 43.2 | 104.8 | **+142.6 %** |
| Peak CL/CD (read from the polar plot) | ≈ 100 at α ≈ 4–5° | ≈ 160 at α ≈ 2° | ≈ **+55–60 %** |
| CL,max | 1.549 at 16° | 1.531 at 13.3° | −1.1 %, stall 2.7° earlier |

The optimised airfoil is more efficient at low angles of attack. Its maximum lift is slightly lower
and it stalls earlier. Details, figures and caveats are in [results/README.md](results/README.md).

### Limitations

- The optimum lies on the bounds. Camber/thickness always increases with more camber and less
  thickness, so every run ends at `m` = upper bound and `t` = lower bound. `p` barely changes the
  objective, so its value depends on the GA's random start
  ([objective landscape](results/figures/objective_landscape.png), [5-seed runs](results/ga_nlp_seeds.csv)).
  The result is set by the chosen bounds rather than by the optimiser.
- The aerodynamic comparison covers two airfoils in 2-D. It does not include pitching moment,
  Reynolds-number effects, structure or 3-D effects, and the XFLR5 settings were not recorded.
- The morphing is a geometric interpolation of `[m p t]`. No mechanism, skin or actuation is modelled.

Next steps: run XFOIL inside the loop so the objective is a real aerodynamic quantity (for example
CL^1.5/CD at a design lift coefficient), add thickness and pitching-moment constraints, and optimise
separate shapes for different flight phases so that the morphing between them has a purpose.

## Repository layout

```
MATLAB/
  NACA2412/       naca4.m (geometry), writeAirfoilDat.m (XFLR5 export), naca2412_baseline.m
  PARSEC/         PARSEC parameterisation (parsec.m ...), fit_parsec_naca2412.m
  Optimization/   optimize_naca_ga_nlp.m (report method), run_parsec_ga.m (PARSEC branch)
  Morphing/       morph_airfoil.m (.dat per step, AVI, GIF)
  make_report_figures.m
results/
  morph_sequence/ the 21 .dat files analysed in XFLR5 for the report
  airfoils/       baseline and optimised airfoil (.dat)
  figures/        README figures and the report's CL/CD polars
```

## Running the code

Requirements: MATLAB R2020a or newer, Optimization Toolbox, Global Optimization Toolbox.

```matlab
cd MATLAB
run NACA2412/naca2412_baseline.m          % baseline geometry and .dat
run Optimization/optimize_naca_ga_nlp.m   % GA + fmincon (5 seeds), optimised .dat
run Morphing/morph_airfoil.m              % 21-step morphing: .dat files, AVI, GIF
run PARSEC/fit_parsec_naca2412.m          % PARSEC fit of NACA 2412
run Optimization/run_parsec_ga.m          % PARSEC + GA (area-based reference method)
run make_report_figures.m                 % rebuilds results/figures
```

Outputs are written to `MATLAB/output/` (not tracked). To analyse an airfoil, open the `.dat` file in
XFLR5 (File → Open). XFLR5 accepts at most 300 points per foil, and the exported files have 199.

## Development history

The project started as an adaptive morphing-wing study (subsonic ↔ supersonic airfoils) and was
narrowed down over several attempts:

| Approach | Outcome |
|---|---|
| NACA 6A-412 / 63(1)-412 with Bezier camber lines | dropped: no validated reference geometry |
| UAS-S45 airfoil in Bezier–PARSEC form (Bashir et al.) | dropped: the published geometry could not be reproduced |
| PARSEC + genetic algorithm (El Houd & Hallou) | kept as a reference branch (area-based fitness) |
| PARSEC + fmincon | dropped: ill-conditioned PARSEC systems |
| 8-parameter NACA-type GA/NLP | dropped: no feasible designs |
| **NACA [m p t] + GA → fmincon + morphing** | **final method** |

Many early `.dat` files would not load in XFLR5 because they had about 400 points; XFLR5 allows at
most 300.

## Credits

- The PARSEC and GA routines (`MATLAB/PARSEC`, `GAairfoil.m`, `randp.m`) come from the reference study
  A. El Houd and Y. Hallou, *Optimization study of NACA airfoil using nonlinear programming & genetic
  algorithms*, Bachelor's thesis, 2022. They were corrected for this repository; see the header of
  `parsec.m`.
- The morphing-airfoil idea draws on M. Bashir, S. Longtin-Martel, R. M. Botez and T. Wong,
  *Aerodynamic Design Optimization of a Morphing Leading Edge and Trailing Edge Airfoil–Application on
  the UAS-S45*, Applied Sciences 11(4):1664, 2021.
