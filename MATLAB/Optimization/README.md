# Airfoil Optimization

## `optimize_airfoil`: make any airfoil more efficient

```matlab
r = optimize_airfoil('NACA 2412');                          % NACA 4-digit code
r = optimize_airfoil('myfoil.dat');                         % any Selig or Lednicer .dat file
r = optimize_airfoil('myfoil.dat', 'Re', 5e5, 'Objective', 'endurance');
```

1. Reads the airfoil and analyses it in XFOIL.
2. Fits it with a **CST** (class-shape transformation) parameterisation: 7 coefficients per surface.
   CST can represent almost any airfoil, so this step does not depend on the airfoil family.
3. Runs the hybrid search from the report: **genetic algorithm** (global, parallel, seeded with the
   original shape), then **fmincon** (SQP, local). Every candidate is scored by XFOIL.
4. Returns the better of the GA and fmincon results. If neither beats the original, it returns the
   original.

| Option | Default | Meaning |
|---|---|---|
| `Objective` | `'LDmax'` | `'LDmax'` (peak CL/CD), `'endurance'` (peak CL^1.5/CD), `'LDatCL'` (CL/CD at `DesignCL`) |
| `Re` | 1e6 | Reynolds number |
| `MinThickness` | 1.0 | Minimum t/c as a fraction of the original's (1.0 = never thinner than the original) |
| `CmIncrease` | 0.05 | Allowed increase of the pitching moment \|CM\| at α = 0 |
| `Order` | 6 | CST order (Order + 1 coefficients per surface) |
| `MaxChange` | 0.08 | Bound on the change of each CST coefficient |
| `Population`, `Generations`, `NLPIterations` | 50, 25, 15 | Search effort |

Outputs, in `MATLAB/output/optimize_airfoil/<name>/`:
- `<name>_optimized.dat` (199–299 points, loads in XFLR5)
- `polar_original.csv` and `polar_optimized.csv`
- `summary.csv` (before/after table)
- `comparison.png`
- `result.mat`

A run takes roughly 10–20 min on 8 cores.

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
stall and a pitching moment 3.5 times that of NACA 2412.

With the thickness held at t ≥ 0.12, `optimize_xfoil_naca.m` reaches a peak L/D of 143 and
`optimize_xfoil_parsec.m` reaches 182.5 (NACA 2412: 102). The PARSEC design is the recommended
airfoil; see [results/README.md](../../results/README.md) for the comparison and its trade-offs.

Supporting functions:

| File | Purpose |
|---|---|
| `camberThicknessRatio.m` | Geometric objective of the report method |
| `nacaMaxLD.m` | XFOIL objective for NACA parameters |
| `parsecMaxLD.m` | XFOIL objective for PARSEC parameters |
| `airfoilObjective.m` | XFOIL objective for `optimize_airfoil` |
| `cstBasis.m`, `cstFit.m`, `cstSurfaces.m` | CST geometry |
| `GAairfoil.m`, `randp.m` | PARSEC genetic algorithm from the reference study |
