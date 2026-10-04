# MATLAB Code

| Folder / file | Contents |
|---|---|
| [NACA2412](NACA2412) | NACA 4- and 5-digit geometry (`naca4.m`, `naca5.m`), XFLR5 `.dat` export (`writeAirfoilDat.m`), baseline script |
| [PARSEC](PARSEC) | PARSEC parameterisation and a least-squares PARSEC fit of NACA 2412 |
| [Aerodynamics](Aerodynamics) | XFOIL wrapper, efficiency metrics, airfoil reader, comparison of all approaches |
| [Optimization](Optimization) | `optimize_airfoil` (any airfoil), XFOIL-in-the-loop optimisations, the report method and the PARSEC genetic algorithm |
| [Morphing](Morphing) | Morphing sequences, morphing envelope, nose and trailing-edge morphing |
| [Validation](Validation) | XFOIL compared with NACA 0012 wind-tunnel data (`validate_xfoil.m`) |
| [Paper](Paper) | The 37 optimisation runs behind `results/paper` and the scripts that turn them into tables and figures; the population study (the same optimisation for 30 airfoils) |
| [CFD](CFD) | C-grid generator, Fluent journals and batch runner, verification on NASA's NACA 0012 case, design study, post-processing |
| `airfoils/` | Seed airfoils as `.dat` files (Clark Y) |
| `run_project.m` | Runs everything in order |
| `make_report_figures.m` | Rebuilds the figures in `results/figures` from the analysed airfoil files |

Run the scripts from this folder (see the main README for the order), or run `run_project`. Each
script adds the folders it needs to the path and writes its outputs to `output/`.

Requirements: MATLAB R2021a or newer (tested with R2024b), Optimization Toolbox (`fmincon`,
`lsqnonlin`), Global Optimization Toolbox (`ga`, `particleswarm`, `patternsearch`), and XFOIL for the
aerodynamic steps (see [Aerodynamics](Aerodynamics)). Parallel Computing Toolbox is optional; the
Statistics and Machine Learning Toolbox is needed only for `optimize_airfoil(..., 'Algorithm',
'bayesopt')`.
