# Methods

This document describes the methods behind the results in [results/paper](../results/paper/README.md),
with every setting as it is in the code. File names refer to the `MATLAB` folder. It is meant as the
basis of the methods section of a paper; where a choice was made for a specific reason, the reason is
given.

## 1. Conventions

- All airfoils have unit chord, the leading edge at (0, 0) and the trailing edge at (1, 0).
- Design condition: Reynolds number Re = 10⁶, Mach number 0, free transition with Ncrit = 9.
- Efficiency measures: peak CL/CD (`'LDmax'`), peak CL^1.5/CD (endurance, `'endurance'`), CL/CD at
  one or more design lift coefficients, with weights (`'LDatCL'`), and CL/CD at one or more fixed angles
  of attack (`'LDatAlpha'`).

## 2. Geometry

**Seed airfoils** (`Aerodynamics/readAirfoil.m`).
- NACA 4-digit sections come from `NACA2412/naca4.m`, with the thickness laid off normal to the camber
  line, 150 cosine-spaced stations per surface, and the closed-trailing-edge thickness coefficient
  −0.1036 instead of −0.1015. The standard coefficient leaves a 0.25 % chord gap; closing it by moving
  the last point created a step that disturbed XFOIL.
- NACA 5-digit sections come from `NACA2412/naca5.m`, with standard and reflexed mean lines.
- Other airfoils are read from Selig or Lednicer `.dat` files, then translated, rotated and scaled so
  that the leading edge is at (0, 0) and the trailing edge at (1, 0). The Clark Y coordinates are from
  airfoiltools.com (UIUC database).

**CST parameterisation** (Kulfan 2008; `Optimization/cstBasis.m`, `cstFit.m`, `cstSurfaces.m`).
- Each surface is y(x) = C(x)·Σ Aᵢ Bᵢ,ₙ(x) ± x·Δ/2, with class function C = √x (1 − x) (round nose,
  sharp trailing edge), Bernstein polynomials of order n = 6 (7 coefficients per surface), and the
  trailing-edge thickness Δ of the seed.
- The coefficients of the seed are fitted to its coordinates by linear least squares. For NACA 2412 the
  largest deviation is 2.1 × 10⁻³ c.
- The design variables are the changes of the 14 coefficients, each bounded to ±0.08
  (`'MaxChange'`).
- Designs are evaluated on 150 cosine-spaced stations per surface, 299 points in total.

## 3. Aerodynamic analysis (XFOIL)

XFOIL 6.99 (Drela 1989) is driven from MATLAB by `Aerodynamics/xfoilPolar.m`.

**Run settings.**
- The airfoil is re-panelled by XFOIL (`PANE`, 160 nodes), or with 200 nodes (`PPAR N 200`) for the
  second analysis described in section 4.
- Viscous mode at Re; Mach 0 and Ncrit 9 unless stated; at most 150 iterations per angle (`ITER 150`).

**Angle sweep.**
- The sweep runs in two parts, from the angle closest to 0° up to the last angle and from there down to
  the first. A failure at one end therefore cannot spoil the other.
- The optimisation uses α = −2° to 12° in steps of 0.5°. The final analysis of every design, and the
  maximum-lift limit, use −2° to 18°.

**Restarts (final analyses only).** If a sweep stops converging early, it is restarted from the last
converged angle with a fresh boundary layer and half the step, up to three times. A restart is kept only
if it reproduces the last converged point within 2 % in CL/CD. Inside the optimisers, restarts are
switched off: a failing shape is a poor candidate anyway, and restarting made the search four times
slower.

**Time limit.** Each XFOIL run is stopped after 60 s plus 2 s per angle. A converging sweep needs a few
seconds, so the limit only catches a hanging XFOIL. It is generous on purpose: an earlier limit of 10 s
plus 0.5 s per angle cut sweeps short when the operating system slowed the machine down, which made
results depend on machine speed.

**Filters against spurious solutions.**
- **Drag floor.** Points with CD < 0.9 × 2.656/√Re, below the laminar skin friction of a flat plate on
  both sides, are discarded.
- **Drag-rise filter.** Outside the drag bucket, a point whose CD is below 80 % of the highest CD
  between it and the drag minimum is discarded.
- **Supported peak.** A peak of CL/CD or CL^1.5/CD counts only if a converged neighbouring angle within
  1.01 steps reaches at least 80 % of it (`supportedMax.m`). Angles that did not converge are gaps, not
  neighbours.

**Metrics** (`efficiencyMetrics.m`, `efficiencyValue.m`).
- Peak CL/CD with its angle, and peak CL^1.5/CD.
- CL,max with its angle, and CD,min.
- CM at α = 0, interpolated when α = 0 did not converge.
- CL/CD at a design CL, at the first crossing of that CL on the polar, linearly interpolated; for
  several design CL, the weighted mean or, with `'Aggregate', 'worst'`, the lowest.
- CL/CD at a fixed angle of attack, which must be one of the angles of the sweep. Like a peak, the value
  counts only if a neighbouring angle reaches at least 80 % of it. If XFOIL did not converge at the
  angle itself but at both neighbouring angles, and those agree within 30 %, their mean is used.

## 4. Optimisation problem (`Optimization/optimize_airfoil.m`, `airfoilObjective.m`)

**Objective.** Maximise the chosen efficiency measure of the design, taken as the lower of two XFOIL
analyses with 160 and 200 panel nodes. The second analysis is skipped when the first already scores
below the fitted seed; such a design cannot become the result.

**Several transition conditions** (`'Ncrit'` with more than one value, or `'Conditions'` with a list
of flow settings such as free transition and transition fixed at 5 % chord). The design is analysed at
every condition, each with both panellings, and the values are combined by their mean or, with
`'Aggregate', 'worst'`, by the lowest. The search then takes that many times longer. The polars in the
report of a run are at Ncrit = 9 if it is among the values, or at the first condition of the list.

**Constraints.**

| Constraint | Definition | Handling |
|---|---|---|
| Thickness | t_max ≥ t_max of the fitted seed − 10⁻⁴ (`'MinThickness'` 1.0), and t_max ≤ max(0.25, 1.5 × seed) | geometric |
| Valid shape | upper surface above the lower surface at every station | geometric |
| Curvature (`'Curvature'`, default on) | on each surface, no more curvature reversals than the fitted seed, counted for 0.1 ≤ x ≤ 1 where the curvature magnitude is at least 0.01; trailing-edge curvature (at x = 1) between 0 and the seed's value rounded to 0.1, tolerance 0.05 | geometric |
| Pitching moment | CM at α = 0 no larger in magnitude than the seed's plus 0.05 (`'CmIncrease'`) | after XFOIL |
| Maximum lift (`'KeepCLmax'`, optional) | CL,max ≥ 0.99 × the lower CL,max of the fitted seed at 160 and 200 nodes | after XFOIL |
| Usable polar | at least 12 converged angles, including α = 0 | after XFOIL |

**Curvature limits.**
- They follow the automatic curvature constraints of Xoptfoil2 (`auto_curvature`, checked against its
  Fortran source of 15 September 2026). There are two deliberate differences: the trailing-edge limit
  takes the seed's sign and is not capped at 2, so that the seed always meets its own limits.
- The curvature is computed from exact CST derivatives on 451 stations (`cstCurvature.m`).
- A design with extra reversals is scored by the peaks of its extra curvature segments above the
  threshold (`curvatureSegments.m`, as in Xoptfoil2's reversal penalty). The measure therefore grows
  continuously with the size of the waves.

**Constraint handling.**
- **Geometric constraints** are checked before XFOIL (`designViolation.m`). A design that breaks them
  gets the size of the violation, a positive number, as its objective value. Valid designs have
  negative values (minus the efficiency), so every valid design ranks ahead of every invalid one, and
  smaller violations rank first (Deb's feasibility rule).
- **Failures after XFOIL** (pitching moment, maximum lift, unusable polar) get the value 0, which is
  worse than any valid design. For Bayesian optimisation the value is NaN, which `bayesopt` treats as a
  failed evaluation and models separately.

**Search.** The global stage starts from the fitted seed plus random designs that meet the geometric
limits (rejection sampling). With the curvature limits, only about 0.1 % of the design box does so for
NACA 2412.
- **GA → fmincon** (default). MATLAB `ga` with population 50 and 25 generations, default operators
  (uniform creation, scattered crossover with fraction 0.8, adaptive-feasible mutation, stochastic
  uniform selection, 3 elite members), function tolerance 10⁻³. Then `fmincon` with SQP: at most 15
  iterations, forward finite differences with step 0.01, step tolerance 10⁻⁴, optimality tolerance
  10⁻³. It is restricted to ±25 % of the design box around the GA result and handles the curvature
  limits as nonlinear constraints. Without that region, its first quasi-Newton step crossed the whole
  box in a test run.
- **Particle swarm → pattern search** (`'Algorithm', 'pso'`, the hybrid of Bashir et al. 2021). MATLAB
  `particleswarm` (swarm 50, 25 iterations, function tolerance 10⁻³), then `patternsearch` (at most 280
  evaluations, initial mesh 0.02, mesh tolerance 10⁻³, complete poll).
- **Bayesian optimisation → fmincon** (`'Algorithm', 'bayesopt'`). MATLAB `bayesopt` with expected
  improvement plus, the geometric limits as deterministic constraints on the variables, and the first
  20 starting designs as initial points. The budget is population × (generations + 1) evaluations.
- **Result.** The better of the global and local results. If neither beats the seed, the seed is
  returned.
- **Parallelism.** Candidates are evaluated in parallel on 6 MATLAB workers.

**Random seeds and statistics.** `rng(seed)` is set before the starting designs are drawn. Every case
of the paper batch was run with seeds 1, 2 and 3. Results are reported per seed and as mean ± sample
standard deviation.

**Provenance.** Every evaluation is logged: time, stage, objective value, number of XFOIL analyses,
duration and design variables. `run_info.json` records the MATLAB version, number of workers, XFOIL
executable, git commit of the code, options, limits, results of each stage, and the median duration of
an analysed design, which serves as a check of machine speed.

**Paper batch.** `Paper/run_paper_batch.m` (37 runs) and `Paper/collect_paper_results.m`.

## 5. Validation of XFOIL

XFOIL is compared with NACA 0012 wind-tunnel data (Ladson 1988; NASA Turbulence Modeling Resource data
sets) in `Validation/validate_xfoil.m`; results are in [results/validation](../results/validation/README.md).
Summary:
- With transition fixed at 5 % chord, drag agrees within 3 %.
- With free transition, XFOIL's drag at a given lift is 11–14 % lower than measured, and its maximum lift
  is too high.
- The lift-curve slope agrees within about 2.5 % for the closed trailing edge used here.

## 6. Robustness analyses

- **Transition and Reynolds number** (`Paper/sensitivity_designs.m`). Every design is analysed at
  Ncrit = 5, 7, 9 and 11 (Re = 10⁶) and at Re = 0.5 and 2 × 10⁶ (Ncrit 9). The gain is taken against
  the seed at the same condition.
- **Comparison with Xoptfoil2** (`Paper/benchmark_xoptfoil2.m`). Xoptfoil2 2.0.0 is run three times on
  the same task, and every design is re-analysed with one protocol.
- **Optimiser comparison.** GA, particle swarm and Bayesian optimisation, global stage only, equal
  budget of 640 evaluations, three seeds each.

- **Population study** (`Paper/run_population_study.m`, `Paper/collect_population_results.m`). The same
  optimisation is run for 30 seed airfoils: 18 NACA 4- and 5-digit sections (0009, 0012, 0015, 1408,
  1412, 2408, 2412, 2415, 2418, 4409, 4412, 4415, 4418, 6409, 6412, 23012, 23015, 23018), Clark Y, and
  11 airfoils of other families from the UIUC Airfoil Coordinates Database (E387, S1223, SD7062,
  SG6043, FX 63-137, NLF(1)-0416, RG-15, E423, MH 32, AH 79-100 B, GOE 398).
  - Formulations, all with the default limits and seed 1: peak CL/CD; CL/CD at α = 2°; CL/CD at the
    lift coefficient at which the seed has its peak CL/CD, rounded to 0.05; and peak CL/CD without
    curvature limits. The peak formulation is repeated with seeds 2 and 3. A lift coefficient common to
    all airfoils was not used: five of the highly cambered seeds do not reach CL = 0.5 within the angle
    range of the search.
  - NACA 2412 is also optimised for the mean of the peak CL/CD at Ncrit = 5 and 9 (seeds 1 to 3) and for
    the lower of the two (seed 1), and in the same way for free transition (Ncrit 9) together with
    transition fixed at 5 % chord on both surfaces.
  - Every seed and design is then analysed at the design condition, at Ncrit = 5, 7 and 11, at
    Re = 0.5 and 2 × 10⁶, and with transition fixed at 5 % chord on both surfaces. Gains are taken
    against the seed at the same condition.

## 7. Morphing analyses (`Morphing/`)

- **Morphing envelope** (`morph_envelope.m`). The cruise and loiter designs are blended linearly in 10
  steps. At each lift coefficient, the best CL/CD over all steps is taken (quasi-steady), using the
  lower of the 160- and 200-node analyses.
- **Nose and trailing-edge morphing with a fixed wing box** (`optimize_le_te_morphing.m`). The nose
  (x < 0.15) and the rear part (x > 0.65) are deflected by quadratic functions of the distance from the
  box, and a grid of deflections is analysed.

## 8. CFD (`CFD/`)

Results: [results/cfd](../results/cfd/README.md).

- **Mesh** (`airfoilCGrid.m`, `writeFluentMesh.m`). Structured C-grid, marched from the wall to about
  one chord and continued along straight lines to a C-shaped far field. Surface points are placed by arc
  length. For the studies: 200 cells per surface, 80 along the wake cut, 179 from the wall, far field
  and outlet 500 chords away; first cell 10⁻⁵ c at Re = 10⁶ and 2 × 10⁻⁶ c at 6 × 10⁶ (y+ about 0.5);
  about 100,000 cells.
- **Solver** (`fluentJournal.m`, `run_fluent_cases.m`). ANSYS Fluent 2026 R1 (student licence, 4
  processes), 2-D double precision, pressure-based coupled solver with pseudo-time stepping. Ideal-gas
  air at 288.15 K and M = 0.15, with the viscosity set for the Reynolds number. Pressure far field.
  400 iterations with first-order upwinding, then second-order upwinding for momentum, turbulence and
  energy and second-order pressure interpolation.
- **Pseudo-time step.** Fixed at one chord passage (chord / free-stream speed). Fluent's automatic step
  is tied to the domain size. With it the fine mesh did not reach a steady state, the 15° case fell onto
  a stalled solution and M = 0.1 diverged; with the fixed step all converge, and where both settings
  converge they give the same forces (`timestep_study.m`).
- **Convergence.** The force coefficients are printed every 50 iterations. A run counts as steady if,
  over its last reports, CL varies by less than 10⁻⁴ and CD by less than 10⁻⁵. The tables give the last
  value, the mean and the range, and the scaled residuals at the last iteration.
- **Runs that cycle** (`cycleStatistics.m`). The Transition SST runs of the design study do not settle:
  the laminar shear layer of the separation bubble rolls up into a train of small separation cells that
  drifts during the iterations, and the forces cycle with it. For such a run the period is taken as the
  smallest lag at which the drag history repeats (the mean square difference between the history and
  the history one lag earlier, divided by twice the variance, has its first local minimum below 0.1;
  the first 600 second-order iterations are left out). The forces are the means over the last whole
  periods, and the lowest and highest values in those periods are given with them. The solver settings
  that were tried against the cycle are in `transition_tests.m`.
- **Models.** k-ω SST (fully turbulent) with the free-stream values of the NASA case (0.052 %, viscosity
  ratio 0.009), and Transition SST (γ–Re_θ; Langtry & Menter 2009).
- **Transition SST inflow.** XFOIL's Ncrit = 9 corresponds to Tu ≈ 0.07 % by Mack's relation
  Tu = exp(−(Ncrit + 8.43)/2.4). A far-field value of 0.14 % with viscosity ratio 50 decays to 0.072 %
  one chord ahead of the airfoil, which every run reports from a probe point. The first-order stage of
  the design study uses a pseudo-time step of 20 chord passages, so that the turbulence from the far
  field has reached the airfoil before the second-order stage; a repeat of the NASA case with this
  start-up gives the same forces.
- **Surface data.** Every run writes the pressure coefficient and the wall shear stress on the airfoil
  at its last iteration; the Transition SST runs of the design study also every 200 iterations over
  their last 2400, and their surface data are the means over these snapshots. The transition location
  is taken where the skin friction rises fastest, and the separation location where it first becomes
  negative (`transitionFromCf.m`).
- **Verification** (`verify_naca0012.m`). NASA Turbulence Modeling Resource, 2D NACA 0012 case: SST,
  M = 0.15, Re = 6 × 10⁶. Three geometrically similar meshes (refinement ratio √2; 50,292, 100,240 and
  200,376 cells) at 0°, 10° and 15°, and the medium resolution with the far field at 20 and 100 chords.
  - On the fine mesh the lift is within 1.2 % and the drag within 6.4 % of each of NASA's three codes;
    the skin friction on the upper surface agrees with CFL3D within 1.2 % of its mean value.
  - Discretisation uncertainty of the drag by the grid convergence index (Celik et al. 2008): 0.67 % on
    the fine and 1.61 % on the medium mesh at 10°.
  - A far field 20 chords away raises the drag at 10° by 9.4 %; 100 chords still by 1.5 %.
- **Design study** (`run_design_study.m`, `designStudyAirfoils.m`, `design_study_xfoil.m`). Six
  airfoils at Re = 10⁶ and M = 0.15: NACA 2412; the smooth and the wavy design optimised for the peak
  CL/CD with free transition and the earlier PARSEC design; and two designs optimised for free and
  tripped flow together (the mean, and the lower value). SST at 0°, 2°, 4°, 6°, 8° and 10° (3000
  second-order iterations) and Transition SST at 0°, 2°, 3°, 4°, 5°, 6°, 7° and 8° (5000). NACA 2412 at
  4° is repeated with both models on a mesh refined by √2 in both directions. XFOIL is run at the same
  Mach number with free transition and with transition fixed at 5 % chord.

## 9. Software and hardware

MATLAB R2024b Update 9 (Optimization, Global Optimization, Statistics and Machine Learning, and
Parallel Computing toolboxes); XFOIL 6.99; Xoptfoil2 2.0.0; ANSYS Fluent 2026 R1 Student. The runs were
made on Windows 11, AMD Ryzen 7 7435HS (8 cores, 16 threads), with 6 parallel MATLAB workers.

## References

- Bashir, M., Longtin-Martel, S., Botez, R. M. & Wong, T. (2021). Aerodynamic design optimization of a
  morphing leading edge and trailing edge airfoil – application on the UAS-S45. *Applied Sciences*
  11(4), 1664.
- Celik, I. B., Ghia, U., Roache, P. J., Freitas, C. J., Coleman, H. & Raad, P. E. (2008). Procedure for
  estimation and reporting of uncertainty due to discretization in CFD applications. *Journal of Fluids
  Engineering* 130(7), 078001.
- Deb, K. (2000). An efficient constraint handling method for genetic algorithms. *Computer Methods in
  Applied Mechanics and Engineering* 186, 311–338.
- Drela, M. (1989). XFOIL: an analysis and design system for low Reynolds number airfoils. In *Low
  Reynolds Number Aerodynamics*, Lecture Notes in Engineering 54, Springer, 1–12.
- Kulfan, B. M. (2008). Universal parametric geometry representation method. *Journal of Aircraft*
  45(1), 142–158.
- Langtry, R. B. & Menter, F. R. (2009). Correlation-based transition modeling for unstructured
  parallelized computational fluid dynamics codes. *AIAA Journal* 47(12), 2894–2906.
- Ladson, C. L. (1988). *Effects of independent variation of Mach and Reynolds numbers on the low-speed
  aerodynamic characteristics of the NACA 0012 airfoil section*. NASA TM-4074.
- Xoptfoil2: J. Guenzel, <https://github.com/jxjo/Xoptfoil2> (version 2.0.0).
