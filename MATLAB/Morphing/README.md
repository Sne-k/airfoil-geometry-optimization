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

For the PARSEC target the peak L/D rises steadily from 105 to 183 along the way
([morph_efficiency.png](../../results/xfoil/morph_efficiency.png)), so every intermediate shape is
more efficient than the one before it.

## `morph_envelope.m`: what a morphing airfoil gains

Blends two optimised airfoils, by default the cruise design (best CL/CD at CL = 0.4) and the loiter
design (best CL^1.5/CD) from `optimize_airfoil`, and analyses every intermediate shape. At each lift
coefficient, a wing that can take any of these shapes flies with the best of them. This *morphing
envelope* is compared with the two fixed designs and with one fixed compromise design (weighted 20 %
cruise, 80 % loiter). Outputs go to `output/morph_envelope`; the results are in
[`results/morphing`](../../results/morphing).

## `optimize_le_te_morphing.m`: nose and trailing-edge morphing with a fixed wing box

Morphs only a droop nose (0–15 % chord) and the trailing edge (65–100 % chord) of NACA 2412 and leaves
the wing box in between unchanged, as in the droop-nose / morphing-trailing-edge study of Bashir et
al. (2021). Both surfaces are shifted by the same smooth deflection, so the thickness is kept. A grid
of nose and trailing-edge deflections is analysed with XFOIL, and the best setting is found for
cruise (CL/CD at CL = 0.4), loiter (maximum CL^1.5/CD) and high lift (CL,max). Outputs go to
`output/le_te_morphing`; the results are in [`results/morphing`](../../results/morphing).

All four scripts model shapes only. They show the geometries a morphing wing would pass through, but
they do not model the mechanism, flexible skin, structure or actuation. The aerodynamics of each step
is also quasi-steady: every intermediate shape is analysed as if it were fixed. Wind-tunnel and CFD
tests of a morphing supercritical airfoil (Wang et al., *Shock and Vibration*, 2021,
doi:10.1155/2021/5588056) show hysteresis in lift and drag that grows with the speed and amplitude of
the shape change, especially for camber changes, so fast morphing will behave differently.
