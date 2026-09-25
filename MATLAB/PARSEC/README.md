# PARSEC Parameterization

PARSEC describes each surface as `z(x) = Σ aₙ x^(n−1/2)`, n = 1…6, with the coefficients set by 11
geometric parameters: leading-edge radius, upper and lower crest position, height and curvature,
trailing-edge height, thickness, direction and wedge angle.

| File | Purpose |
|---|---|
| `parsec.m` | PARSEC parameters → the 12 polynomial coefficients |
| `yCoord2.m` | Upper/lower surface height at a given x |
| `airenaca.m` | Cross-sectional area and maximum thickness (fitness of the PARSEC GA) |
| `plotairfoil.m` | Plots a PARSEC airfoil |
| `exportAirfoilDat.m` | Exports a PARSEC airfoil as `.dat` (100 cosine-spaced points per surface) |
| `fit_parsec_naca2412.m` | Least-squares PARSEC fit of NACA 2412 (maximum error 0.3 % chord) |

The routines come from the reference study of El Houd & Hallou (2022). Four errors were corrected here
(details in the header of `parsec.m`):

- The crest-curvature coefficient was 53/4; the correct value is 63/4.
- The lower surface's leading-edge-radius condition was applied to the wrong coefficient.
- The lower surface used the upper surface's trailing-edge thickness term.
- The lower surface used the upper surface's trailing-edge slope term.

With the original code, the "NACA 2412" starting point was only NACA-2412-like (t ≈ 0.118, camber at
52 % chord). `fit_parsec_naca2412.m` produces a proper PARSEC representation instead.
