# Validation

`validate_xfoil.m` compares the XFOIL analysis used throughout this project (`xfoilPolar`: XFOIL 6.99,
re-panelled with `PANE`, 160 panel nodes, Ncrit = 9) with NACA 0012 wind-tunnel data.

```matlab
summary = validate_xfoil;          % about 10 min; needs XFOIL (see ../Aerodynamics/README.md)
```

| Case | Data | XFOIL settings |
|---|---|---|
| A. free transition | Ladson (1988), Table I: Re = 2.00, 3.94 and 5.97 × 10⁶, M = 0.15 | same Re and M, free transition |
| B. transition fixed | Ladson (1988): Re = 6 × 10⁶, M = 0.15, 80, 120 and 180 grit at 0.05c | transition forced at x/c = 0.05 on both surfaces |
| C. other data sets | Abbott & von Doenhoff (Re = 6 × 10⁶, free transition); Gregory & O'Reilly (Re = 3 × 10⁶, tripped, lift only) | free transition; for Gregory & O'Reilly also forced at 0.05c (their trip location is not given in the data file) |
| D. lift-curve slope | McCroskey's (1988) correlation of many wind tunnels, evaluated at Re = 10⁶, M = 0 (the design condition of this project) | Re = 10⁶, M = 0 |

The data files and their sources are listed in
[results/validation/experimental/README.md](../../results/validation/experimental/README.md).

**Geometry.** Ladson's model had the design ordinates of the NACA 0012; the standard ordinates end in a
trailing edge 0.25 % of the chord thick. That geometry is analysed, and so is the closed-trailing-edge
variant that all optimisations in this project use. Sensitivity checks: 200 panel nodes, and Ncrit = 12
(XFOIL's documentation lists 10–12 for a clean wind tunnel).

**Comparison.**
- Lift at the measured angles of attack, for angles before the measured stall and |α| ≤ 10°.
- Drag at the measured lift coefficient, for points before the measured stall and |CL| ≤ 1.0. XFOIL's
  drag is interpolated on its polar below its own maximum lift.
- Lift-curve slope: straight-line fit over |α| ≤ 4° (XFOIL) and |α| ≤ 4.5° (measurements).
- Peak L/D: XFOIL as everywhere in this project (`supportedMax`); measurements: the highest cl/cd of the
  listed points (a point measurement, so it can miss the true peak between two angles).

**Check of the XFOIL settings.** XFOIL writes the Reynolds number, Mach number, Ncrit and forced
transition locations it used into the header of its polar file. The script compares them with the
requested values for every case and stops if they differ.

Outputs (default `results/validation/xfoil`): `summary.csv`, the XFOIL polars (`polar_<case>.csv`) and
the figures `validation_free_transition.png` and `validation_tripped.png`. The results are discussed in
[results/validation/README.md](../../results/validation/README.md).
