# CFD (work in progress)

The aim is to check the XFOIL results with RANS CFD in ANSYS Fluent. The main check uses Transition SST
(γ–Re_θ), as Bashir et al. (2021) did. A fully turbulent SST case gives a pessimistic bound.

| File | Purpose |
|---|---|
| `airfoilCGrid.m` | Structured C-grid around an airfoil: marched from the wall to about one chord, then straight lines to a C-shaped far field. Surface points are placed by arc length. |
| `writeFluentMesh.m` | Writes the grid as a Fluent ASCII mesh (zones `airfoil`, `farfield`, `fluid`) |
| `fluentJournal.m` | Batch journal: ideal-gas air, viscosity for the Reynolds number, pressure far field, SST or Transition SST, 400 first-order iterations then blocks of second-order iterations, with forces printed after every block |
| `run_fluent_cases.m` | Runs Fluent once per angle of attack and collects CL, CD and their change over the last block |
| `fluentForces.m` | Reads the force coefficients from a Fluent transcript |

## Verification on the NASA NACA 0012 case

Setup: Turbulence Modeling Resource (TMR) geometry, SST, M = 0.15, Re = 6 × 10⁶, free-stream turbulence
0.052 % with viscosity ratio 0.009. Reference: CFL3D, FUN3D and NTS on a 897 × 257 grid with the far field
about 500 chords away.

| Case | CL | CD | Reference CL / CD |
|---|---:|---:|---:|
| α = 0°, far field 20 c, 83,440 cells | 0.0000 | 0.00812 | 0 / 0.00809 |
| α = 0°, far field 500 c, about 100,000 cells | 0.0000 | 0.00811 | 0 / 0.00809 |
| α = 10°, far field 20 c | 1.0688 | 0.01408 | 1.0778 / 0.01236 (CFL3D) |
| α = 10°, far field 100 c | 1.0741 | 0.01310 | " |
| α = 15°, far field 20 c | 0.79 | 0.33 | 1.5068 / 0.02219: **failed** (stalled solution) |

**Findings so far:**
- **Drag at zero lift matches within 0.4 %.**
- **Lift at 10° is within 1 %.**
- **At 10°, the drag depends strongly on the far-field distance:** +14 % at 20 chords, +6 % at 100 chords.
  This error grows with lift. With a 20-chord far field it would penalise designs that carry more lift,
  so the design study uses a far field 500 chords away.
- **A 20-chord mesh family gave a non-monotonic drag trend** (coarse 0.01438, medium 0.01408, fine
  0.01530). It has to be repeated on the 500-chord domain.
- **Mach number.** At Re = 10⁶ and M = 0.1, the solution diverges from the first iterations, for both
  NACA 0012 and NACA 2412 and on every mesh tried. At M = 0.15 it converges, at both Re = 10⁶ and
  6 × 10⁶. The cause is still unknown. The design study therefore runs at M = 0.15, and XFOIL is run at
  the same Mach number for the comparison.
- **Grid generator bug, fixed.** Cambered NACA sections reach slightly ahead of x = 0 just behind the
  nose, where the old version interpolated y as a function of x. It now places the surface points by arc
  length. This was not the cause of the divergence (see the Mach number above).

**Still to do:**
- Repeat α = 10° and 15° and the mesh family on the 500-chord domain.
- Run the design study: NACA 2412, the smooth and the wavy optimised designs, and the earlier PARSEC
  design, at α = 0–8°, Re = 10⁶, M = 0.15, with Transition SST and SST.

No design results are published until the verification is complete.

**Transition SST inflow.** XFOIL uses Ncrit = 9, which corresponds to a turbulence intensity of about
0.07 % (Mack: Tu = exp(−(Ncrit + 8.43)/2.4)). The turbulence decays on its way from a far field 500 chords
away. By the SST free-stream equations, a far-field value of 0.14 % with viscosity ratio 50 arrives at the
airfoil as about 0.072 %. With a viscosity ratio of 10, no inflow value reaches 0.07 % over that distance.

## Running

Fluent must be installed. Set `FLUENT_EXE` to `fluent.exe`, then:

```matlab
G = airfoilCGrid(xu, yu, xl, yl, 'Radius', 500, 'WakeLength', 500, 'WakeFirstCell', 0.1, 'NNormal', 180);
writeFluentMesh('case.msh', G);
T = run_fluent_cases('case.msh', [0 2 4 6 8], 'Model', 'transition', 'Re', 1e6, 'Mach', 0.15, ...
                     'Intensity', 0.14, 'ViscRatio', 50);
```

The student licence allows one Fluent session at a time. If MATLAB is stopped while Fluent is running,
the Fluent processes keep running and hold the licence until they are ended.
