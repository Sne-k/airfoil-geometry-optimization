# Airfoil Optimization

## `optimize_airfoil`: make any airfoil more efficient

```matlab
r = optimize_airfoil('NACA 2412');                          % NACA 4-digit code
r = optimize_airfoil('NACA 23012');                         % NACA 5-digit code
r = optimize_airfoil('myfoil.dat');                         % any Selig or Lednicer .dat file
r = optimize_airfoil('myfoil.dat', 'Re', 5e5, 'Objective', 'endurance');
r = optimize_airfoil('NACA 2412', 'Algorithm', 'pso');       % particle swarm -> pattern search
r = optimize_airfoil('NACA 2412', 'Objective', 'LDatCL', ...  % cruise at CL 0.4 (20 %) and
      'DesignCL', [0.4 1.0], 'Weights', [0.2 0.8]);           % loiter at CL 1.0 (80 %)
r = optimize_airfoil('NACA 2412', 'KeepCLmax', true);        % never lose maximum lift
r = optimize_airfoil('NACA 2412', 'Algorithm', 'bayesopt');  % Bayesian optimisation -> fmincon
r = optimize_airfoil('NACA 2412', 'Seed', 2);                % another random seed
```

1. Reads the airfoil and analyses it in XFOIL.
2. Fits it with a **CST** (class-shape transformation) parameterisation: 7 coefficients per surface.
   CST can represent almost any airfoil, so this step does not depend on the airfoil family.
3. Derives **curvature limits** from the fitted original (see below): the design may not be wavier
   than the original.
4. Runs a hybrid search: by default the method of the report, a **genetic algorithm** (global,
   parallel) followed by **fmincon** (SQP, local). With `'Algorithm', 'pso'` it runs a **particle
   swarm** followed by **pattern search**, the hybrid used by Bashir et al. (2021); pattern search needs
   no gradients, which suits the noisy XFOIL results. With `'Algorithm', 'bayesopt'` it runs
   **Bayesian optimisation** (MATLAB `bayesopt`: Gaussian-process model, expected improvement)
   followed by fmincon. The global search starts from the fitted original and random designs that meet
   all geometric limits.
5. Checks the geometric limits (thickness, crossing surfaces, curvature) before any XFOIL analysis. A
   design that breaks them is not analysed; it gets the size of the violation as its score, so it ranks
   behind every valid design and smaller violations rank first (Deb's feasibility rule).
6. Scores every other candidate with two XFOIL panellings (160 and 200 nodes) and keeps the lower
   result, so the search cannot exploit a numerical artefact that only one panelling produces.
   Candidates that already score below the original with the first panelling skip the second one,
   because they cannot become the result.
7. fmincon treats the curvature limits as nonlinear constraints and works in a region of ±25 % of the
   search box around the global result. Without that region its first quasi-Newton step crossed the
   whole box and left the limits (seen in a test run).
8. Returns the better of the global and local results. If neither beats the original, it returns the
   original.

### Curvature limits

Optimisers exploit XFOIL's sensitivity to small shape details, for example a wavy surface or a tiny
"spoiler" at the trailing edge. `optimize_airfoil` therefore applies the automatic curvature
constraints of [Xoptfoil2](https://github.com/jxjo/Xoptfoil2) (`auto_curvature`; checked against its
source code, version of 15 September 2026):

- **Reversals.** The curvature of each surface is evaluated exactly from the CST functions between
  x/c = 0.1 and 1. A reversal is a change of sign, counting only values with |curvature| ≥ 0.01
  (`CurvatureThreshold`). The design may have no more reversals on each surface than the fitted
  original. A design with too many is scored by the peaks of its extra waves (as in Xoptfoil2), so the
  measure grows continuously with the size of the waves.
- **Trailing-edge curvature.** The curvature at x/c = 1 must lie between 0 and the original's value
  rounded to 0.1, with a tolerance of 0.05. Unlike Xoptfoil2, the limit is not capped at 2 and its sign
  is taken from the original, so that the original always meets its own limits.

For NACA 2412, only about 0.1 % of random designs in the default search box (±0.08 on every CST
coefficient) meet these limits (±0.02: 4.5 %). This is why the starting population is drawn from valid
designs only. `'Curvature', false` switches the limits off.

| Option | Default | Meaning |
|---|---|---|
| `Objective` | `'LDmax'` | `'LDmax'` (peak CL/CD), `'endurance'` (peak CL^1.5/CD), `'LDatCL'` (CL/CD at `DesignCL`), `'LDatAlpha'` (CL/CD at `DesignAlpha`) |
| `DesignCL`, `Weights` | 0.5, equal | One or more design lift coefficients for `'LDatCL'` and their weights (weighted mean of CL/CD) |
| `DesignAlpha` | 2 | One or more angles of attack (deg, multiples of 0.5 between −2 and 12) for `'LDatAlpha'`. Many papers pose the objective this way; a gain at a fixed angle is not a gain at fixed lift |
| `Ncrit` | 9 | XFOIL's transition parameter. With several values, e.g. `[5 9]`, every design is analysed at each of them (the search takes that many times longer) |
| `Conditions` | `{}` | Flow conditions as a cell array of structs for `xfoilPolar`, e.g. `{struct('Ncrit', 9), struct('Xtr', [0.05 0.05])}` for free and tripped transition. Replaces `Ncrit` |
| `Aggregate` | `'mean'` | How several design points and conditions are combined: `'mean'` or `'worst'` (the lowest) |
| `KeepCLmax` | false | Reject shapes whose maximum lift is below the original's (the sweep then runs to 18°) |
| `Curvature` | true | Curvature limits from the original (see above) |
| `CurvatureThreshold` | 0.01 | Curvature below which a sign change is not counted as a reversal |
| `Algorithm` | `'ga'` | `'ga'` (GA → fmincon), `'pso'` (particle swarm → pattern search) or `'bayesopt'` (Bayesian optimisation → fmincon) |
| `LocalSearch` | true | Run the local stage after the global search |
| `Seed` | 1 | Random number seed; the results of GA, particle swarm and Bayesian optimisation depend on it |
| `Re` | 1e6 | Reynolds number |
| `MinThickness` | 1.0 | Minimum t/c as a fraction of the original's (1.0 = never thinner than the original) |
| `CmIncrease` | 0.05 | Allowed increase of the pitching moment \|CM\| at α = 0 |
| `Order` | 6 | CST order (Order + 1 coefficients per surface) |
| `MaxChange` | 0.08 | Bound on the change of each CST coefficient |
| `Population`, `Generations`, `NLPIterations` | 50, 25, 15 | Search effort (swarm size and iterations for `'pso'`; Bayesian optimisation gets Population × (Generations + 1) evaluations; pattern search uses 20 evaluations per variable) |

Outputs, in `MATLAB/output/optimize_airfoil/<name>/`:
- `<name>_optimized.dat` (199–299 points, loads in XFLR5)
- `polar_original.csv` and `polar_optimized.csv`
- `summary.csv` (before/after table, including the curvature reversals and trailing-edge curvature of
  the fitted original and of the design)
- `comparison.png`, `curvature.png` (curvature of both surfaces) and `convergence.png` (best objective
  against the number of designs analysed with XFOIL)
- `history.csv`: every evaluation of the search in time order (stage, objective value, number of XFOIL
  analyses, duration of the evaluation, CST changes). Each MATLAB process appends to its own file in
  `history/`, so parallel workers never write to the same file.
- `run_info.json`: date, run time, MATLAB version, number of parallel workers, XFOIL executable, git
  commit of the code (marked if files under `MATLAB/` had been changed), all options, the limits, the
  objective after each stage, whether the design meets the curvature limits, the median duration of an
  analysed design (a check that the machine ran at its normal speed), and the solver outputs
- `result.mat`

A run takes about 20–35 min on 8 cores.

The results in [results/optimize_airfoil](../../results/optimize_airfoil) were produced before the
curvature limits were added, and their designs do not meet the limits (see the curvature check in
[results/README.md](../../results/README.md)). They were repeated with the limits and three random seeds
each; see [results/paper](../../results/paper/README.md).

## Report method and its XFOIL versions

| Script | Variables | Objective |
|---|---|---|
| `optimize_naca_ga_nlp.m` | NACA `[m p t]` | camber/thickness (report method; geometric) |
| `optimize_xfoil_naca.m` | NACA `[m p t]` | peak L/D from XFOIL |
| `optimize_xfoil_parsec.m` | 9 PARSEC parameters | peak L/D from XFOIL |
| `run_parsec_ga.m` | 11 PARSEC parameters | cross-sectional area (reference method from El Houd & Hallou) |

All of them use GA → fmincon except `run_parsec_ga.m`, which uses its own GA.

The report's camber/thickness objective always pushes `m` to its upper bound and `t` to its lower
bound. `optimize_naca_ga_nlp.m` repeats the search over five random seeds to show this. With t ≥ 0.08
the XFOIL search in the NACA 4-digit family ends at the same corner (m = 0.050, t = 0.080), so the
proxy happened to point at the right NACA shape. Only XFOIL shows what that shape costs: an earlier
stall and a pitching moment more than three times that of NACA 2412.

With the thickness held at t ≥ 0.12, `optimize_xfoil_naca.m` reaches a peak L/D of 153 and
`optimize_xfoil_parsec.m` reaches 182.5 (NACA 2412: 104.6). The PARSEC design is the recommended
airfoil; see [results/README.md](../../results/README.md) for the comparison and its trade-offs.

Supporting functions:

| File | Purpose |
|---|---|
| `camberThicknessRatio.m` | Geometric objective of the report method |
| `nacaMaxLD.m` | XFOIL objective for NACA parameters |
| `parsecMaxLD.m` | XFOIL objective for PARSEC parameters |
| `airfoilObjective.m` | XFOIL objective for `optimize_airfoil` (optionally logs every evaluation) |
| `designViolation.m` | Geometric limits of a design (thickness, crossing surfaces, curvature), checked without XFOIL |
| `curvatureLimits.m`, `curvatureViolation.m`, `curvatureSegments.m` | Curvature limits from the original, and how far a design is outside them |
| `cstCurvature.m`, `cstCurvatureBasis.m` | Exact curvature of a CST surface |
| `cstBasis.m`, `cstFit.m`, `cstSurfaces.m` | CST geometry |
| `GAairfoil.m`, `randp.m` | PARSEC genetic algorithm from the reference study |
