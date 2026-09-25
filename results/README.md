# Results

## XFOIL comparison of all approaches (`xfoil/`)

The final airfoil of every approach tried during the project was analysed with the same XFOIL
settings: Re = 10⁶, M = 0, Ncrit = 9, re-panelled, α = −2° to 18° in 0.5° steps
(`MATLAB/Aerodynamics/compare_approaches.m`). NACA sections use the closed-trailing-edge form of the
thickness formula. A peak value counts only if a neighbouring angle confirms it, so a single spurious
XFOIL point cannot set it.

![Approach comparison](xfoil/approach_comparison.png)

| Approach | t/c | Peak CL/CD (α) | Peak CL^1.5/CD | CL,max (α) | CM at 0° |
|---|---:|---:|---:|---:|---:|
| **XFOIL GA + fmincon, PARSEC, t ≥ 0.12** (`optimize_xfoil_parsec.m`) | 0.123 | **182.5** (4.5°) | **190.5** | 1.553 (16.5°) | −0.124 |
| Report method: GA + fmincon, camber/thickness (`gian.m`) | 0.080 | 178.9 (2.5°) | 170.6 | 1.524 (13.5°) | −0.156 |
| NSGA-II multi-objective (`idkwimdt.m`) | 0.080 | 175.7 (3.0°) | 174.4 | 1.541 (14.0°) | −0.159 |
| XFOIL GA + fmincon, NACA [m p t], t ≥ 0.12 (`optimize_xfoil_naca.m`) | 0.127 | 153.2 (3.0°) | 150.5 | 1.603 (17.5°) | −0.150 |
| XFOIL GA + fmincon, PARSEC, t ≥ 0.08 \* | 0.081 | 143.9 (2.5°) | 143.1 | 1.741 (15.5°) | −0.184 |
| `optimize_airfoil('NACA 2412')`, CST + XFOIL | 0.121 | 141.0 (5.5°) | 148.1 | 1.493 (17.5°) | −0.065 |
| XFOIL GA + fmincon, NACA [m p t], t ≥ 0.08 \* | 0.080 | 124.8 (0.5°) | 102.9 | 0.680 (0.5°) | −0.149 |
| Bezier camber line, 12 % thick (`letshope.m`, fixed) | 0.120 | 112.2 (4.5°) | 106.1 | 1.483 (16.0°) | −0.056 |
| PARSEC fit of NACA 2412 | 0.120 | 104.9 (6.0°) | 102.1 | 1.404 (15.0°) | −0.046 |
| **NACA 2412 (baseline)** | 0.120 | **104.6** (4.5°) | **95.7** | 1.429 (16.0°) | −0.048 |
| PARSEC GA, minimum area (`GAairfoil.m`, reference method) | 0.101 | 97.1 (3.5°) | 99.6 | 1.705 (15.5°) | −0.115 |
| GA + PSO + fmincon with the sign error (`suniyo.m` / `deki.m`) | 0.130 | 77.3 (9.0°) | 79.2 | 1.313 (16.5°) | 0.000 |
| Thin Bezier "supersonic" target (`trialgp.m`) | 0.050 | 55.4 (1.0°) | 35.5 | 0.610 (5.5°) | −0.009 |

\* Not reliable. The PARSEC t ≥ 0.08 design scored 394.6 inside its optimiser, which used an earlier
XFOIL wrapper, and scores 143.9 here. XFOIL does not converge above α = 0.5° for the NACA t ≥ 0.08
design, so its polar is incomplete.

What the comparison shows:

- **Putting XFOIL in the loop is what makes the difference.** The geometric objectives (camber/thickness,
  minimum area) either run to the bounds or do not target efficiency at all. The area-minimising PARSEC
  GA ends up below the baseline.
- **Shape freedom matters.** With the thickness held at 12 %, the best NACA 4-digit section (m = 0.050,
  p = 0.52, t = 0.127) reaches 153. PARSEC can also move the thickness peak and shape the rear of the
  section, which adds another 19 % (182.5).
- **The 8 %-thick designs owe their efficiency to being thin.** The report airfoil and the NSGA-II
  design reach 176–179, but with a third less thickness, the largest pitching moments and the earliest
  stall.
- **The sign error explains the "no improvement" runs.** `suniyo.m` and `deki.m` minimised camber
  instead of maximising it and produced symmetric airfoils, 26 % worse than NACA 2412.
- **XFOIL is consistent.** The PARSEC fit of NACA 2412 scores within 0.3 % of NACA 2412 itself (104.9
  against 104.6), and the peak values of the main designs change by less than 1 % between 140 and 240
  panel nodes (next section).

### Robustness of the peak values

Two problems made earlier numbers depend on how XFOIL panelled the airfoil. Both are fixed:

- The standard NACA thickness formula leaves a trailing edge 0.25 % of chord thick, which the
  geometry routine closed with a small, almost vertical step. The step cost NACA 2412 about 2.5 % of
  its peak L/D (102.0 instead of 104.6), and XFOIL broke down on it at 240 panel nodes. NACA sections
  are now generated with the closed-trailing-edge coefficient (−0.1036) for all aerodynamic work.
- The earlier peak filter, a 3-point moving median, compared points across angles that had not
  converged, and in one case cut the PARSEC design's peak of 182.5 down to 157.

Peak CL/CD after both fixes ([panel_check.csv](xfoil/panel_check.csv)):

| Panel nodes | 140 | 160 | 180 | 200 | 220 | 240 |
|---|---:|---:|---:|---:|---:|---:|
| NACA 2412 | 104.4 | 104.6 | 104.7 | 104.9 | 105.1 | 104.9 |
| Report airfoil | 178.9 | 178.9 | 178.6 | 178.6 | 178.7 | 178.7 |
| PARSEC, t ≥ 12 % | 183.1 | 182.5 | 182.7 | 182.8 | 182.4 | 182.5 |
| CST, `optimize_airfoil` | 141.0 | 141.0 | 141.0 | 140.8 | 140.7 | 140.4 |
| NACA [m p t], t ≥ 12 % | 152.9 | 153.0 | 152.9 | 153.0 | 152.8 | 153.0 |

### Recommended design

**PARSEC, XFOIL-optimised, t ≥ 12 %**: [`NACA2412_parsec_t12_optimized.dat`](xfoil/NACA2412_parsec_t12_optimized.dat)

| r_le | x_up | y_up | y_xx,up | x_lo | y_lo | y_xx,lo | y_te | Δy_te | α_te | β_te |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 0.01622 | 0.45933 | 0.10751 | −0.52059 | 0.42516 | −0.01575 | 0.31189 | 0 | 0 | −2.710° | 13.003° |

Compared with NACA 2412: peak L/D +74 %, peak CL^1.5/CD +99 %, CL,max +8.6 % with stall 0.5° later,
same thickness (12.3 %, at 44 % chord instead of 30 %). Two things to consider before using it:

- The pitching moment at α = 0° is −0.124, about 2.6 times that of NACA 2412 (−0.048), so the tail must
  trim a larger nose-down moment.
- The efficiency peak is narrow, about 1° of α. At CL = 0.5 the airfoil is less efficient than NACA
  2412 (63 against 83).

If these matter more than peak efficiency, the CST design from `optimize_airfoil`
([`NACA2412_cst_optimized.dat`](xfoil/NACA2412_cst_optimized.dat)) is the better choice: +35 % peak
L/D and +55 % CL^1.5/CD with a pitching moment of only −0.065, and more efficient than NACA 2412 from
CL ≈ 0.5 to 1.35.

![Shapes](xfoil/designs.png)

![Polars](xfoil/polars.png)

| CL/CD at | CL = 0.3 | CL = 0.5 | CL = 0.8 | CL = 1.0 | CL = 1.2 |
|---|---:|---:|---:|---:|---:|
| NACA 2412 | 55.6 | 83.0 | 104.5 | 90.4 | 78.5 |
| Report airfoil | – | 84.6 | 168.7 | 165.1 | 89.8 |
| PARSEC, t ≥ 12 % | – | 63.1 | 124.5 | 168.9 | 80.5 |
| CST, `optimize_airfoil` | 46.0 | 85.2 | 126.7 | 139.8 | 125.3 |

(– : the airfoil does not reach that low a CL within α ≥ −2°.)

### Morphing to the recommended design

`MATLAB/Morphing/morph_to_design.m` blends NACA 2412 into the PARSEC design in 20 steps. The peak L/D
rises at every step analysed, from 105 to 183.

| | |
|---|---|
| ![Morph](xfoil/morph_to_design.gif) | ![Efficiency along the morph](xfoil/morph_efficiency.png) |

### Files

| File | Contents |
|---|---|
| `NACA2412_parsec_t12_optimized.dat` | Recommended airfoil (PARSEC, XFOIL-optimised, t ≥ 12 %) |
| `NACA2412_cst_optimized.dat` | Result of `optimize_airfoil('NACA 2412')` |
| `NACA2412_naca_t12_optimized.dat` | Best NACA 4-digit section with t ≥ 12 % (m = 0.050, p = 0.524, t = 0.127) |
| `polar_*.csv` | α, CL, CD, CM of NACA 2412, the report airfoil and the three designs above |
| `ld_at_cl.csv` | L/D at fixed lift coefficients |
| `panel_check.csv` | Peak L/D of the main designs for 140–240 panel nodes |
| `approach_comparison.csv`, `approach_comparison.png`, `ld_polars.png` | All approaches ranked; L/D against α |
| `designs.png`, `polars.png` | Shapes; lift, L/D against CL and pitching moment |
| `NACA2412_cst_summary.csv`, `NACA2412_cst_comparison.png` | Before/after output of `optimize_airfoil` |
| `morph_to_design.gif`, `morph_efficiency.png`, `morph_efficiency.csv` | Morph to the PARSEC design with the peak L/D of every second step |

All `.dat` files are in Selig format with fewer than 300 points and open in XFLR5.

## `optimize_airfoil` on other airfoils (`optimize_airfoil/`)

Same XFOIL settings and default options: never thinner than the original, and |CM| at 0° may grow by
at most 0.05.

| Airfoil | Peak CL/CD | Peak CL^1.5/CD | CM at 0° | t/c | Run time (8 cores) |
|---|---|---|---|---|---:|
| NACA 0012 | 76.5 → 123.7 (+62 %) | 76.0 → 117.6 (+55 %) | 0.000 → −0.027 | 0.120 → 0.120 | 48 min |
| NACA 2412 | 104.6 → 140.8 (+35 %) | 95.7 → 148.1 (+55 %) | −0.048 → −0.065 | 0.120 → 0.121 | – |
| NACA 4412 | 129.6 → 168.5 (+30 %) | 133.6 → 172.0 (+29 %) | −0.096 → −0.131 | 0.120 → 0.121 | 32 min |

- Each folder holds the optimised `.dat` file, both polars, `summary.csv` and `comparison.png`.
- The gains hold under the optimiser's own score, the lower result of two panellings (NACA 0012:
  76.5 → 123.4, NACA 4412: 129.5 → 168.1).
- The NACA 2412 result comes from an earlier version that scored each candidate with one panelling.
- During the NACA 0012 run the pitching-moment limit was not active, because of a bug that has since
  been fixed; the result is within the limit anyway.
- Baselines are the closed-trailing-edge sections.

## Airfoils analysed in XFLR5 for the report

`morph_sequence/` holds the 21 files (steps 00–20) produced by the project run and analysed for the
report. Step 00 is the NACA 2412 baseline and step 20 is the optimised airfoil; the same two files
are in `airfoils/` with descriptive names.

| | m | p | t | camber/thickness |
|---|---:|---:|---:|---:|
| NACA 2412 (baseline) | 0.020 | 0.400 | 0.120 | 0.167 |
| Optimised | 0.050 | 0.516 | 0.080 | 0.627 |

The optimised parameters were recovered from the step-20 file by fitting the NACA equations to its
coordinates (rms error 4×10⁻⁷, i.e. rounding level). `MATLAB/NACA2412/naca4.m` reproduces the baseline
file byte for byte.

![Baseline vs optimised](figures/geometry_comparison.png)

## Why the report's optimum sits on the bounds

The objective (camber/thickness) keeps increasing with camber and decreasing with thickness, so the
maximum is always the corner `m = 0.05`, `t = 0.08`. The GA + fmincon run was repeated with five random
seeds ([ga_nlp_seeds.csv](ga_nlp_seeds.csv)). Every run gives m = 0.050, t = 0.080 and camber/thickness
= 0.627, while `p` ends anywhere between 0.48 and 0.60 because it hardly affects the objective.

![Objective landscape](figures/objective_landscape.png)

## XFLR5 results (from the project report)

| | NACA 2412 | Optimised | Change |
|---|---:|---:|---:|
| CL at α = 0° | 0.24713 | 0.59103 | +139.2 % |
| CD at α = 0° | 0.00572 | 0.00564 | −1.4 % |
| CL/CD at α = 0° | 43.20 | 104.79 | +142.6 % |
| CL at stall | 1.54895 (α = 16°) | 1.53146 (α = 13.3°) | −1.1 % |
| CL/CD at stall | 33.45 (α = 16°) | 38.96 (α = 13.3°) | different α, not comparable |

Notes on reading these numbers:

- **The α = 0° values are not the peak values.** The report's CL/CD polars show the baseline peaking at
  about 100 near α ≈ 4–5° and the optimised airfoil at about 160 near α ≈ 2°, roughly +55–60 % peak to
  peak (XFOIL: 104.6 → 178.9, +71 %). The +142.6 % applies only at α = 0°, where the extra camber
  raises the lift on its own.
- Above α ≈ 6° the baseline has the higher CL/CD, and the optimised airfoil stalls about 2.7° earlier
  with a slightly lower CL,max.
- The XFLR5 settings (Reynolds number, Mach number, Ncrit, panelling) were not recorded. The drag
  values suggest Re ≈ 10⁶. XFOIL at Re = 10⁶ gives similar drag and peak L/D for NACA 2412, but
  about 0.02 less lift at 0° and a lower CL,max (1.43).
- The report did not evaluate the pitching moment. XFOIL gives CM = −0.156 at α = 0° for the optimised
  airfoil against −0.048 for NACA 2412.

| Baseline CL/CD vs α (report Fig. 4.4) | Optimised (blue) vs baseline (black) (report Fig. 4.8) |
|---|---|
| ![Fig 4.4](figures/report_fig4_4_cl_cd_baseline.png) | ![Fig 4.8](figures/report_fig4_8_cl_cd.png) |

The polar curves are noisy at negative angles of attack (XFOIL convergence); only the positive-α
part is used above.
