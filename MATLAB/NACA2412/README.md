# NACA 2412 Airfoil

| File | Purpose |
|---|---|
| `naca4.m` | Coordinates of any NACA 4-digit section from `m`, `p`, `t` (thickness applied normal to the camber line); `naca4(m, p, t, x, true)` gives the closed-trailing-edge form for XFOIL |
| `writeAirfoilDat.m` | Writes a Selig-format `.dat` file for XFLR5/XFOIL (trailing edge → upper surface → leading edge → lower surface → trailing edge) |
| `naca2412_baseline.m` | Generates, plots and exports the NACA 2412 baseline (`output/naca2412`) |

`naca4(0.02, 0.40, 0.12, linspace(0,1,100)')` reproduces the baseline airfoil analysed in the report
exactly.

By default the generator uses the standard thickness coefficient −0.1015 and then sets the last point
of each surface to (1, 0), which reproduces the report's airfoils. The standard formula leaves about
0.13 % chord of thickness on each surface at the trailing edge, so this closure is a small step. On the
fine grids used for XFOIL the step is almost vertical and costs NACA 2412 a few percent of its peak L/D
(and breaks XFOIL at high panel counts). All aerodynamic analysis therefore uses
`naca4(m, p, t, x, true)`, the closed-trailing-edge coefficient −0.1036.

For XFOIL work, use cosine spacing, e.g. `x = (1 - cos(linspace(0, pi, 150)'))/2`. The uniform
100-point spacing of the report files under-resolves the leading edge: XFOIL on the raw file gives a
peak L/D of 102.5 instead of 104.6 for the cosine-spaced, closed-trailing-edge section.

`writeAirfoilDat` checks the coordinates before writing them. It rejects NaN values, duplicate
points, crossing surfaces and more than 300 points, which is the most XFLR5 accepts per foil
("Panel number cannot exceed 300").
