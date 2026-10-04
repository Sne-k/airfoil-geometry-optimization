# CFD

RANS checks of the XFOIL results with ANSYS Fluent. The set-up is verified on NASA's NACA 0012 case; the
design study of the NACA 2412 designs is running. Results and their discussion:
[results/cfd](../../results/cfd/README.md).

## Files

| File | Purpose |
|---|---|
| `airfoilCGrid.m` | Structured C-grid around an airfoil: marched from the wall to about one chord, then straight lines to a C-shaped far field. Surface points are placed by arc length. |
| `writeFluentMesh.m` | Writes the grid as a Fluent ASCII mesh (zones `airfoil`, `farfield`, `fluid`) |
| `fluentJournal.m` | Batch journal for one case: ideal-gas air, viscosity for the Reynolds number, pressure far field, SST or Transition SST, first-order then second-order iterations, forces printed after every block |
| `run_fluent_cases.m` | Runs Fluent for a list of angles and collects forces, their history, residuals and probe values. Finished runs are not repeated |
| `fluentForces.m`, `fluentResiduals.m`, `fluentProbes.m`, `fluentSurface.m` | Read forces, residuals, probe values and surface distributions from Fluent's output |
| `transitionFromCf.m` | Transition and separation locations from a skin-friction distribution |
| `gridConvergence.m` | Discretisation error from three meshes (Celik et al. 2008) |
| `timestep_study.m` | Compares Fluent's automatic pseudo-time step with a fixed one on the NASA case |
| `verify_naca0012.m` | The verification: three meshes at 0°, 10° and 15°, and two smaller domains |
| `run_design_study.m` | The four NACA 2412 designs with Transition SST and SST |
| `design_study_xfoil.m` | XFOIL polars of the same designs at the same condition |
| `collect_cfd_results.m` | Turns the outputs into the tables and figures of `results/cfd` |
| `writeRunInfo.m` | Records the code version, software and options of a batch |

## Set-up

- **Mesh.** C-grid with 200 cells per surface, 80 along the wake cut and 179 from the wall; the far
  field and the outlet are 500 chords away. First cell 10⁻⁵ chords at Re = 10⁶ (2 × 10⁻⁶ at 6 × 10⁶),
  which gives y+ of about 0.5. About 100,000 cells.
- **Solver.** Fluent 2026 R1, 2-D, double precision, pressure-based coupled solver, ideal gas, pressure
  far field. 400 iterations with first-order upwinding, then second order.
- **Pseudo-time step: fixed at one chord passage** (chord / free-stream speed). Fluent's automatic step
  is tied to the domain size. With it, the fine mesh did not reach a steady state, the 15° case fell
  onto a stalled solution, and Mach 0.1 diverged. With the fixed step all three converge.
- **Domain: 500 chords.** With 20 chords the drag at 10° is 9.4 % too high, and the error grows with lift.
- **Mach number 0.15**, the condition of the NASA case. XFOIL's peak CL/CD changes by less than 1 %
  between M = 0 and 0.15.
- **Forces every 50 iterations.** A run counts as steady if CL varies by less than 0.0001 and CD by less
  than 0.00001 over its last reports.

**Transition SST inflow.** XFOIL's Ncrit = 9 corresponds to a turbulence intensity of about 0.07 %
(Mack: Tu = exp(−(Ncrit + 8.43)/2.4)). The turbulence decays on its way from the far field. A far-field
value of 0.14 % with viscosity ratio 50 arrives one chord ahead of the airfoil as 0.072 %, which the
runs confirm with a probe there. At that point the viscosity ratio has fallen to about 4, so the
laminar boundary layers are not disturbed. The turbulence has to travel 500 chords from the far field,
so the design study runs its first-order stage with a pseudo-time step of 20 chord passages. After the
switch to second order, the intensity at the probe settles within about 800 iterations.

## Verification in short

On NASA's NACA 0012 case (SST, M = 0.15, Re = 6 × 10⁶) the fine mesh gives a lift within 1.2 % and a
drag within 6.4 % of each of NASA's three codes, which differ among themselves by up to 4 % in drag. The
skin friction on the upper surface agrees with CFL3D within 1.2 % of its mean value on every mesh. The
mesh-convergence estimate of the drag uncertainty of the medium mesh is 1.6 % at 10°.

## Running

Fluent must be installed. Set `FLUENT_EXE` to `fluent.exe`, then, from this folder:

```matlab
timestep_study      % 13 runs, about 4 hours
verify_naca0012     % 11 runs, about 4 hours
run_design_study    % 53 runs, about 15 hours
design_study_xfoil  % XFOIL side of the comparison (needs XFOIL)
collect_cfd_results % tables and figures in results/cfd
```

A single case:

```matlab
G = airfoilCGrid(xu, yu, xl, yl, 'Radius', 500, 'WakeLength', 500, 'WakeFirstCell', 0.1, 'NNormal', 180);
writeFluentMesh('case.msh', G);
T = run_fluent_cases('case.msh', [0 2 4 6 8], 'Model', 'sst', 'Re', 1e6, 'Mach', 0.15, 'TimeStep', 1);
```

Notes:
- The student licence allows one Fluent session with at most 4 solver processes.
- If MATLAB is stopped while Fluent is running, the Fluent processes keep running and hold the licence
  until they are ended.
- Option names must be written in full. An early version matched `'Re'` to the option `'Reuse'` and ran
  a batch at the default Reynolds number; partial matching is now switched off.
