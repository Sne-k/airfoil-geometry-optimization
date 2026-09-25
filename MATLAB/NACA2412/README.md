# NACA 2412 Airfoil

| File | Purpose |
|---|---|
| `naca4.m` | Coordinates of any NACA 4-digit section from `m`, `p`, `t` (thickness applied normal to the camber line, trailing edge closed at (1, 0)) |
| `writeAirfoilDat.m` | Writes a Selig-format `.dat` file for XFLR5/XFOIL (trailing edge → upper surface → leading edge → lower surface → trailing edge) |
| `naca2412_baseline.m` | Generates, plots and exports the NACA 2412 baseline (`output/naca2412`) |

`naca4(0.02, 0.40, 0.12, linspace(0,1,100)')` reproduces the baseline airfoil analysed in the report
exactly.

The generator uses the standard thickness coefficient −0.1015 and then sets the last point of each
surface to (1, 0). The −0.1036 closed-trailing-edge variant of the formula gives a slightly different
shape, so keep −0.1015 if you need to reproduce the report's airfoils.

For XFOIL work, use cosine spacing, e.g. `x = (1 - cos(linspace(0, pi, 150)'))/2`. The uniform
100-point spacing of the report files under-resolves the leading edge: XFOIL on the raw file gives a
peak L/D of 87 instead of about 104.

`writeAirfoilDat` checks the coordinates before writing them. It rejects NaN values, duplicate
points, crossing surfaces and more than 300 points, which is the most XFLR5 accepts per foil
("Panel number cannot exceed 300").
