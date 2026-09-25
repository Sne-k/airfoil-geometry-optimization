# Aerodynamics (XFOIL)

Aerodynamic analysis is done with XFOIL, the viscous panel code that XFLR5's foil analysis is built on,
driven from MATLAB.

## Setup

1. Download XFOIL 6.99 for Windows (`XFOIL6.99.zip`) from the official page
   <https://web.mit.edu/drela/Public/web/xfoil/>.
2. Put `xfoil.exe` in this folder, or point the environment variable at it:
   `setenv('XFOIL_EXE', 'C:\path\to\xfoil.exe')`.

`xfoil.exe` is git-ignored and not distributed with this repository.

## Files

| File | Purpose |
|---|---|
| `xfoilPolar.m` | Runs a viscous α sweep on any airfoil and returns α, CL, CD, CM |
| `efficiencyMetrics.m` | Peak L/D and where it occurs, peak CL^1.5/CD, CLmax, stall angle, CDmin, CM at α = 0 |
| `efficiencyValue.m` | The objective used in optimisation: `'LDmax'`, `'endurance'` or `'LDatCL'` |
| `readAirfoil.m` | Reads an airfoil from a NACA 4-digit code or a Selig/Lednicer `.dat` file |
| `compare_approaches.m` | Analyses the final airfoil of every approach tried in the project with the same settings |
| `plot_polars.m` | Redraws the shapes and polars in `results/xfoil` and tabulates L/D at fixed CL |

## Analysis settings

- Re = 10⁶, Mach 0, Ncrit = 9 (free transition)
- XFOIL re-panels every airfoil (`PANE`)
- α from −2° to 18° in 0.5° steps; the optimisation objectives use −2° to 12°

For NACA 2412 these settings give the same drag and peak L/D as the report's XFLR5 analysis
(CD = 0.0056 against 0.0057 at 0°; peak L/D 102 at 4.5° against about 100 at 4–5°), but less lift:
CL = 0.20 against 0.25 at 0° and CLmax = 1.46 against 1.55. The report did not record its XFLR5
settings, so the difference cannot be traced. All airfoils in `results/xfoil` were analysed with the
settings above, so they can be compared with each other.

## Guarding against bad XFOIL results

Optimisers exploit numerical errors, so the wrapper and the metrics filter them out:

- **Physical drag limit.** Points with CD below the laminar flat-plate friction of both surfaces
  (2.656/√Re, about 0.0027 at Re = 10⁶) are discarded. XFOIL sometimes "converges" to such
  solutions, and one early run reported a physically impossible L/D of 984.
- **Spike filter.** Peak L/D and CL^1.5/CD are taken from a 3-point moving median, so a single spurious
  point cannot set the maximum.
- **Consistent sweeps.** The optimisation and the final check start at the same α with the same step,
  so they give the same numbers.
- **Time limit.** Each XFOIL call is stopped after 20 s if it hangs (uses `timeout.exe` from Git for
  Windows when it is installed).

Known limitation: for thin sections (8 % thickness) XFOIL's convergence is fragile. The same airfoil
can give a full polar in one run and stop converging after α ≈ 1° in another, and the time limit can
cut a slow sweep short. Results for such airfoils should be checked before they are used.
