# Airfoil Optimization

## Hybrid GA + NLP on the NACA parameters (method of the report)

`optimize_naca_ga_nlp.m` optimises `v = [m p t]` within `0 ≤ m ≤ 0.05`, `0.2 ≤ p ≤ 0.6` and
`0.08 ≤ t ≤ 0.15`:

1. **Genetic algorithm** (`ga`, population 100, 100 generations): global search.
2. **Nonlinear programming** (`fmincon`, interior-point): local refinement from the GA result.

The objective (`camberThicknessRatio.m`) is maximum camber divided by maximum thickness, a geometric
stand-in for lift-to-drag. Because it always grows with camber and shrinks with thickness, the optimum
is the corner `m = 0.05`, `t = 0.08`, and `p` stays close to where the GA left it. The script runs the
hybrid search with five random seeds to show this. Every seed gives m = 0.050, t = 0.080 and
camber/thickness = 0.627, while `p` varies between about 0.48 and 0.60. It exports the baseline and
optimised airfoils as `.dat` files for XFLR5.

To make the optimisation aerodynamic, replace the objective with a lift/drag evaluation. XFOIL can be
called from MATLAB with `system()`; XFLR5 itself cannot be scripted.

## PARSEC + genetic algorithm (reference branch)

`run_parsec_ga.m` runs `GAairfoil.m` (population 40, elitism, one-point crossover, mutation through
`randp.m`) on the 11 PARSEC parameters, starting from the PARSEC fit of NACA 2412. Its fitness is the
airfoil's cross-sectional area, so it produces a thinner airfoil (area 0.082 → 0.044), not an
aerodynamically better one. The GA code comes from the reference study of El Houd & Hallou (2022).
