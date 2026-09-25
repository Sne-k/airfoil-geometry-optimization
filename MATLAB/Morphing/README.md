# Airfoil Morphing

`morph_airfoil.m` interpolates `[m p t]` linearly from NACA 2412 to the optimised airfoil in 20 steps.
For each step it:

- writes an XFLR5 `.dat` file (`naca2412_morph_00.dat` … `naca2412_morph_20.dat`)
- plots the shape against the baseline outline
- adds a frame to `naca2412_morphing.avi` and `naca2412_morphing.gif`

It uses the result of `Optimization/optimize_naca_ga_nlp.m` if that has been run, and otherwise the
airfoil analysed in the report (m = 0.050, p = 0.516, t = 0.080). Outputs go to `output/morphing`.

This is a shape interpolation only. It shows the intermediate geometries a morphing wing would pass
through, but it does not model the mechanism, flexible skin, structure or actuation. The 21 files
from the project run are in [`results/morph_sequence`](../../results/morph_sequence).
