# Airfoil Morphing

## `morph_airfoil.m`: the report's morphing sequence

Interpolates `[m p t]` linearly from NACA 2412 to the optimised airfoil in 20 steps. For each step it:

- writes an XFLR5 `.dat` file (`naca2412_morph_00.dat` … `naca2412_morph_20.dat`)
- plots the shape against the baseline outline
- adds a frame to `naca2412_morphing.avi` and `naca2412_morphing.gif`

It uses the result of `Optimization/optimize_naca_ga_nlp.m` if that has been run, and otherwise the
airfoil analysed in the report (m = 0.050, p = 0.516, t = 0.080). Outputs go to `output/morphing`.
The 21 files from the project run are in [`results/morph_sequence`](../../results/morph_sequence).

## `morph_to_design.m`: morphing to any airfoil, with the efficiency of every step

Blends the surface coordinates of NACA 2412 and a target `.dat` file on common cosine-spaced stations,
so the target does not have to be a NACA section. The default target is the XFOIL-optimised PARSEC
airfoil ([`results/xfoil`](../../results/xfoil)). Every step is written as a `.dat` file and a GIF frame,
and XFOIL computes the peak L/D of every second step. Outputs go to `output/morph_to_design`.

For the PARSEC target the peak L/D rises steadily from 101 to 183 along the way
([morph_efficiency.png](../../results/xfoil/morph_efficiency.png)), so every intermediate shape is
more efficient than the one before it.

Both scripts interpolate shapes only. They show the geometries a morphing wing would pass through, but
they do not model the mechanism, flexible skin, structure or actuation.
