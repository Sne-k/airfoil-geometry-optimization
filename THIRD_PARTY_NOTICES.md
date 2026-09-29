# Third-party material

This repository is released under the MIT licence ([LICENSE](LICENSE)). The material below comes from
other sources and keeps its own terms.

## Code adapted from El Houd & Hallou

The PARSEC genetic algorithm (the reference approach of the project report, ref. [5]) comes from the
reference implementation of El Houd & Hallou (2019), <https://github.com/anasselhoud/Airfoil-Shape_optimization>
(folder `Genetic Algorithm`), released under the MIT licence below. Each file names its source in its
header.

| File in this repository | Upstream file | Changes |
|---|---|---|
| `MATLAB/Optimization/GAairfoil.m` | `GAairfoil.m` | comments added |
| `MATLAB/Optimization/randp.m` | `randp.m` | comments and a closing `end` added |
| `MATLAB/Optimization/run_parsec_ga.m` | `runit.m` | rewritten as a script for this repository |
| `MATLAB/PARSEC/parsec.m` | `parsec.m` | corrected (listed in the file header) |
| `MATLAB/PARSEC/airenaca.m` | `airenaca.m` | comments added |
| `MATLAB/PARSEC/plotairfoil.m` | `plotairfoil.m` | comments added |
| `MATLAB/PARSEC/yCoord2.m` | `yCoord2.m` | comments added |
| `MATLAB/PARSEC/exportAirfoilDat.m` | `plotairfoil.m` | writes the coordinates to a `.dat` file; 100 points per surface |

```
MIT License

Copyright (c) 2020 Anass El Houd

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Data

These files are included, with their sources, so that the results can be reproduced. They are not
covered by the MIT licence of this repository.

| Files | Source |
|---|---|
| `results/validation/experimental/*.dat` | NASA Langley Turbulence Modeling Resource (NACA 0012 validation case): Ladson (1988), Gregory & O'Reilly (1970) and Abbott & von Doenhoff (1959) data as digitised there, and McCroskey's (1988) lift-curve correlation. Details in [results/validation/experimental/README.md](results/validation/experimental/README.md). |
| `results/validation/experimental/Ladson1988_TableI_M015_free.csv` | Transcribed from Table I of Ladson (1988), NASA TM-4074 |
| `MATLAB/airfoils/clarky.dat` | Clark Y coordinates from [airfoiltools.com](http://airfoiltools.com/airfoil/details?airfoil=clarky-il), which takes them from the UIUC Airfoil Coordinates Database |

## Not included

- **XFOIL** (M. Drela and H. Youngren, GNU General Public License) is needed for the aerodynamic
  analyses but is not distributed here; see [MATLAB/Aerodynamics/README.md](MATLAB/Aerodynamics/README.md).
- **Xoptfoil2** (J. Guenzel, MIT licence, <https://github.com/jxjo/Xoptfoil2>) was used for the
  benchmark in `results/xoptfoil2`; only its input file and the airfoil it produced are included.
- **ANSYS Fluent** (commercial) is used by the scripts in `MATLAB/CFD`.
