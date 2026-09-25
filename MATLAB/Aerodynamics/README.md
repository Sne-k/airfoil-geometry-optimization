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
| `supportedMax.m` | Peak of a polar quantity that a neighbouring angle confirms (spike filter) |
| `readAirfoil.m` | Reads an airfoil from a NACA 4-digit code or a Selig/Lednicer `.dat` file |
| `compare_approaches.m` | Analyses the final airfoil of every approach tried in the project with the same settings |
| `plot_polars.m` | Redraws the shapes and polars in `results/xfoil` and tabulates L/D at fixed CL |

## Analysis settings

- Re = 10⁶, Mach 0, Ncrit = 9 (free transition)
- XFOIL re-panels every airfoil (`PANE`)
- α from −2° to 18° in 0.5° steps; the optimisation objectives use −2° to 12°
- each sweep runs in two parts: from 0° up, then from 0° down (see below)

For NACA 2412 these settings give similar drag and peak L/D to the report's XFLR5 analysis
(CD = 0.0056 against 0.0057 at 0°; peak L/D 105 at 4.5° against about 100 at 4–5°), but less lift:
CL = 0.23 against 0.25 at 0° and CLmax = 1.43 against 1.55. The report did not record its XFLR5
settings, so the difference cannot be traced. All airfoils in `results/xfoil` were analysed with the
settings above, so they can be compared with each other.

## Guarding against bad XFOIL results

Optimisers exploit numerical errors, so the wrapper and the metrics filter them out:

- **Physical drag limit.** Points with CD below the laminar flat-plate friction of both surfaces
  (2.656/√Re, about 0.0027 at Re = 10⁶) are discarded. XFOIL sometimes "converges" to such
  solutions, and one early run reported a physically impossible L/D of 984.
- **Spike filter.** A peak L/D or CL^1.5/CD counts only if a neighbouring converged angle (one step
  away) confirms it with at least 80 % of its value (`supportedMax.m`). A single spurious point,
  including one at the end of a polar, cannot set the maximum. Angles that did not converge are
  treated as gaps, so a real narrow peak next to a gap is kept. An earlier 3-point moving median
  compared points across such gaps and cut the PARSEC design's 182.5 down to 157.
- **Split sweep.** The sweep starts at 0°, where the solution converges most easily, and runs up to the
  last angle; a second XFOIL run goes from 0° down to the first angle. Before this change, thin cambered
  sections spent the time limit on non-converging negative angles and the polar stopped at α ≈ 1°
  (for example the report airfoil's own `.dat` file). It now converges over the whole range.
- **Two panellings in the optimiser.** `optimize_airfoil` analyses every candidate with XFOIL's default
  160 panel nodes and with 200 (`xfoilPolar(..., exe, 200)`) and scores the lower result, so the search
  cannot exploit a solution that only one panelling produces.
- **Consistent sweeps.** The optimisation and the final check use the same angles and step, so they
  give the same numbers.
- **Time limit.** Each XFOIL run is stopped after 10 s plus 0.5 s per angle if it hangs (uses
  `timeout.exe` from Git for Windows when it is installed).

Known limitations:

- A sharp laminar peak in L/D can fall between two analysed angles, so its height depends a little on
  the angle step. With the closed NACA trailing edge and the gap-aware spike filter, the peak values
  of the main designs change by less than 1 % between 140 and 240 panel nodes (see
  [results/README.md](../../results/README.md#robustness-of-the-peak-values)).
- Some thin, strongly cambered sections still stop converging part-way through the sweep (for example
  the 8 %-thick NACA design of `optimize_xfoil_naca.m` above α = 0.5°). The optimisers penalise such
  incomplete polars.
