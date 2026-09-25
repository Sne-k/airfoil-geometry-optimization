# MATLAB Code

| Folder / file | Contents |
|---|---|
| [NACA2412](NACA2412) | NACA 4-digit geometry (`naca4.m`), XFLR5 `.dat` export (`writeAirfoilDat.m`), baseline script |
| [PARSEC](PARSEC) | PARSEC parameterisation and a least-squares PARSEC fit of NACA 2412 |
| [Aerodynamics](Aerodynamics) | XFOIL wrapper, efficiency metrics, airfoil reader, comparison of all approaches |
| [Optimization](Optimization) | `optimize_airfoil` (any airfoil), XFOIL-in-the-loop optimisations, the report method and the PARSEC genetic algorithm |
| [Morphing](Morphing) | Morphing sequences from NACA 2412 to the optimised airfoils (.dat, GIF, L/D per step) |
| `run_project.m` | Runs everything in order |
| `make_report_figures.m` | Rebuilds the figures in `results/figures` from the analysed airfoil files |

Run the scripts from this folder (see the main README for the order), or run `run_project`. Each
script adds the folders it needs to the path and writes its outputs to `output/`.

Requirements: MATLAB R2020b or newer, Optimization Toolbox (`fmincon`, `lsqnonlin`), Global
Optimization Toolbox (`ga`), and XFOIL for the aerodynamic steps (see [Aerodynamics](Aerodynamics)).
Parallel Computing Toolbox is optional.
