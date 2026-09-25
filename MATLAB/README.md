# MATLAB Code

| Folder / file | Contents |
|---|---|
| [NACA2412](NACA2412) | NACA 4-digit geometry (`naca4.m`), XFLR5 `.dat` export (`writeAirfoilDat.m`), baseline script |
| [PARSEC](PARSEC) | PARSEC parameterisation and a least-squares PARSEC fit of NACA 2412 |
| [Optimization](Optimization) | Hybrid GA + fmincon optimisation (method of the report) and the PARSEC genetic algorithm |
| [Morphing](Morphing) | Morphing sequence from the baseline to the optimised airfoil (.dat, AVI, GIF) |
| `make_report_figures.m` | Rebuilds the figures in `results/figures` from the analysed airfoil files |

Run the scripts from this folder (see the main README for the order). Each script adds the folders it
needs to the path and writes its outputs to `output/`.

Requirements: MATLAB R2020a or newer, Optimization Toolbox (`fmincon`, `lsqnonlin`), Global
Optimization Toolbox (`ga`).
