# CFD results (ANSYS Fluent)

The RANS runs check the XFOIL results with an independent method. This folder has three parts:

| Folder | Contents | State |
|---|---|---|
| [timestep_study](timestep_study) | which solver settings give a steady solution | done |
| [verification](verification) | the set-up against NASA's NACA 0012 case | done |
| [designs](designs) | the NACA 2412 designs with Transition SST and SST | XFOIL side done; SST done for four of the six airfoils; Transition SST in progress |

All files are written by `MATLAB/CFD/collect_cfd_results.m` from the outputs of `timestep_study.m`,
`verify_naca0012.m` and `run_design_study.m`. The Fluent transcripts are not published, because they
contain local paths.

## Verification on NASA's NACA 0012 case

**Case.** 2D NACA 0012 validation case of the NASA Turbulence Modeling Resource: k-ω SST, M = 0.15,
Re = 6 × 10⁶, free-stream turbulence 0.052 % with viscosity ratio 0.009. NASA lists results of three
codes (CFL3D, FUN3D, NTS) on one 897 × 257 grid and notes that they agree within 1 % in lift and 5 % in
drag, and that the results are "representative, but not truth".

**Our runs.** Three geometrically similar meshes (refinement ratio √2) with the far field 500 chords
away: 50,292, 100,240 and 200,376 cells. Fixed pseudo-time step of one chord passage, 400 first-order and
3000 second-order iterations. All runs below are steady: over the last 500 iterations CL varies by less
than 0.0001 and CD by less than 0.00001.

| α | | Coarse | Medium | Fine | CFL3D | FUN3D | NTS |
|---|---|---:|---:|---:|---:|---:|---:|
| 0° | CD | 0.00807 | 0.00812 | 0.00814 | 0.00809 | 0.00808 | 0.00809 |
| 10° | CL | 1.0747 | 1.0757 | 1.0749 | 1.0778 | 1.0840 | 1.0765 |
| 10° | CD | 0.01307 | 0.01284 | 0.01274 | 0.01236 | 0.01253 | 0.01251 |
| 15° | CL | not steady | 1.4955 | 1.4925 | 1.5068 | 1.5109 | 1.5100 |
| 15° | CD | not steady | 0.02339 | 0.02326 | 0.02219 | 0.02275 | 0.02187 |

- **Lift** on the fine mesh is 0.1 to 0.8 % below the three codes at 10° and 0.9 to 1.2 % below them at 15°.
- **Drag** on the fine mesh is 0.7 to 0.8 % above them at 0°, 1.7 to 3.1 % above at 10° and 2.3 to 6.4 %
  above at 15°. The three codes themselves differ by up to 4 % at 15°.
- **The medium mesh**, whose resolution the design study uses, is 2.4 to 3.9 % above the three codes in
  drag at 10°.
- **On the coarse mesh the 15° case does not reach a steady state**; it falls onto a stalled solution.

![Lift and drag against NASA's results](verification/verification_forces.png)

**Pressure and skin friction** ([surface_comparison.csv](verification/surface_comparison.csv)). On the
medium mesh the skin friction on the upper surface differs from CFL3D's by 0.6 %, 0.4 % and 0.7 % of its
mean value at 0°, 10° and 15° (between 5 % and 95 % chord). The suction peak at 10° is −5.576 against
−5.604.

![Pressure and skin friction against CFL3D](verification/verification_surface.png)

**Mesh convergence** ([grid_convergence.csv](verification/grid_convergence.csv); procedure of Celik et
al. 2008).

| α | Quantity | Apparent order | Extrapolated | Uncertainty, fine mesh | Uncertainty, medium mesh |
|---|---|---:|---:|---:|---:|
| 0° | CD | 2.4 | 0.00816 | 0.28 % | 0.64 % |
| 10° | CD | 2.6 | 0.01267 | 0.67 % | 1.61 % |

The lift at 10° changes by less than 0.1 % between the meshes and not monotonically, so no order is
given for it. At 15° only two meshes give a steady solution; the medium mesh is 0.6 % above the fine one
in drag.

![Mesh convergence of the drag](verification/grid_convergence.png)

**Domain size** ([farfield.csv](verification/farfield.csv)). With the resolution of the medium mesh at
10°, a far field 20 chords away raises the drag by 9.4 % and lowers the lift by 0.5 %; at 100 chords
the drag is still 1.5 % too high. The error falls roughly in proportion to the distance, which leaves
about 0.3 % at 500 chords. It grows with lift, so a small domain would penalise exactly the designs that
carry more lift.

![Drag against the distance of the far field](verification/farfield.png)

## Which solver settings give a steady solution

Fluent's pressure-based coupled solver advances in pseudo-time. Its automatic time step is tied to the
size of the domain, so it is very large for a 500-chord domain. `timestep_study.m` compares it with a
fixed step of one chord passage ([forces.csv](timestep_study/forces.csv)).

| Case | Automatic step | Fixed step (one chord passage) |
|---|---|---|
| 10°, coarse mesh | CD 0.01307, steady | CD 0.01307, steady |
| 10°, medium mesh | CD 0.01284, steady | CD 0.01284, steady |
| 10°, fine mesh | not steady: CD varies by 0.0039 over the last 500 iterations | CD 0.01274, steady |
| 15°, medium mesh, started directly | stalled: CL 0.69, CD 0.28 | CL 1.4955, CD 0.02339, steady |
| 15°, medium mesh, reached from 10° in steps | CL 1.4954, CD 0.02339, steady | not settled after 1500 iterations per angle |

- **Where both settings converge, they give the same forces.**
- **The differentiable slope limiter does not help:** the fine mesh with the automatic step stays unsteady.
- **Mach 0.1 converges with the fixed step** (CD 0.00812 at 0°). With the automatic step it had diverged.

![Force histories with the two settings](timestep_study/timestep_history.png)

## Design study

Six airfoils at Re = 10⁶ and M = 0.15 (`MATLAB/CFD/designStudyAirfoils.m`): NACA 2412; three designs
optimised for the peak CL/CD with free transition (the smooth and the wavy design of `results/paper` and
the earlier PARSEC design); and two designs optimised for free and tripped flow together
(`results/population`).

**XFOIL at the same condition** ([designs/xfoil.csv](designs/xfoil.csv)), best CL/CD between −2° and 12°:

| Airfoil | Free transition, Ncrit 9 | Tripped at 5 % chord |
|---|---:|---:|
| NACA 2412 | 104.2 | 72.6 |
| optimised, smooth | 140.7 | 68.3 |
| optimised, no curvature limits | 146.0 | 70.1 |
| PARSEC design | 182.1 | 53.2 |
| optimised for free and tripped flow (mean) | 138.1 | 74.5 |
| optimised for the worse of free and tripped | 103.4 | 77.4 |

- **With tripped boundary layers the three designs optimised for free transition alone are worse than
  the original.** Their gain comes from laminar flow.
- **The two designs that had the tripped condition in their objective are not.** The first keeps almost
  the whole free-transition gain; the second gives it up for the best tripped value.
- **The Mach number matters little:** at M = 0 the free-transition values of the first four are 104.6,
  141.6, 145.9 and 182.5.

**Fluent, start-up check.** The first run repeats the NASA case with the start-up of the design study and
gives the same forces as the
verification (CL 1.0757, CD 0.01284).

### Fully turbulent flow (SST)

All six airfoils at 0° to 10° (36 runs, all steady). CL/CD from Fluent, and in brackets from XFOIL with
the boundary layers tripped at 5 % chord ([designs/comparison.csv](designs/comparison.csv)):

| Airfoil | 0° | 2° | 4° | 6° | 8° | 10° |
|---|---:|---:|---:|---:|---:|---:|
| NACA 2412 | 18.8 (18.6) | 36.8 (36.9) | 51.4 (52.6) | 61.3 (64.7) | 65.8 (72.0) | 64.8 (68.5) |
| optimised, smooth | 32.2 (32.0) | 47.8 (47.7) | 59.2 (59.9) | 65.3 (67.2) | 65.5 (68.0) | 59.1 (58.9) |
| optimised, no curvature limits | 28.1 (28.0) | 44.8 (45.0) | 57.3 (58.5) | 64.4 (67.4) | 65.3 (69.7) | 58.5 (57.1) |
| PARSEC design | 35.2 (28.7) | 46.9 (39.2) | 53.7 (46.7) | 55.5 (51.4) | 53.5 (53.1) | 49.0 (52.3) |
| optimised for free and tripped flow (mean) | 29.2 (29.4) | 46.0 (46.6) | 58.7 (60.4) | 66.3 (70.1) | 67.9 (74.5) | 63.1 (65.4) |
| optimised for the worse of free and tripped | 19.3 (19.1) | 37.3 (37.5) | 51.9 (53.3) | 61.9 (65.5) | 66.7 (73.7) | 66.4 (77.2) |

![Fluent and XFOIL polars of the designs](designs/design_polars.png)

- **Without laminar flow the designs optimised for free transition alone have no advantage.** The best
  CL/CD over these angles is 65.8 for NACA 2412, 65.5 and 65.3 for the two CST designs (0.4 % and 0.8 %
  lower) and 55.5 for the PARSEC design (15.6 % lower) ([designs/peaks.csv](designs/peaks.csv)). XFOIL
  with tripped boundary layers puts these three designs 5.6 %, 3.2 % and 26.2 % below the original at
  the same angles. Both methods put the PARSEC design far behind; Fluent sees a smaller loss for the CST
  designs.
- **The design optimised for free and tripped flow together is better than the original here as well:**
  67.9, which is 3.3 % higher; XFOIL had given 3.5 %. The design optimised for the worse of the two
  conditions reaches 66.7 (1.5 % higher; XFOIL: 7.4 %).
- **At a fixed small angle the designs look better even here.** At 4° the five designs reach 51.9 to
  59.2 against 51.4, mostly because they carry more lift at the same angle.
- **Fluent and tripped XFOIL agree closely at low lift.** Leaving the PARSEC design aside, Fluent's drag
  is higher than XFOIL's by 0.2 to 1.1 % at 0°, by 9.9 to 11.3 % at 8° and by 6.3 to 16.0 % at 10°, and
  its lift differs by −0.4 to +9.7 %. For the PARSEC design Fluent's lift is 8.1 to 23.9 % higher.
- **The peak lies inside the range of the runs:** every airfoil has its best value at 6° or 8° and a
  lower one at 10°.
- **Mesh.** NACA 2412 at 4° on the refined mesh (200,376 cells) gives a drag that differs by 0.03 % from
  the mesh of the design study ([designs/mesh_check.csv](designs/mesh_check.csv)).

### Transition SST

The first of 49 runs is done (NACA 2412 at 4°); the others are in progress.

**The runs do not settle.** Lift and drag cycle, here with a period of 2550 iterations
([designs/history.csv](designs/history.csv), [designs/cycle_naca2412_a4.csv](designs/cycle_naca2412_a4.csv)):

![Force cycle and wall shear of a Transition SST run](designs/transition_cycle.png)

- **What cycles.** The drag moves between 0.00561 and 0.00673 and the lift between 0.7179 and 0.7335.
  The friction part of the drag stays at 0.0035; the whole change is in the pressure part (0.0021 to
  0.0031 in the wall snapshots).
- **Why.** The laminar boundary layer of the upper surface separates near one third of the chord. In
  every snapshot the separated region is not one bubble but a train of small separation cells, with
  reversed flow starting between x/c = 0.32 and 0.35 and ending between 0.51 and 0.54. The train drifts
  from one iteration to the next, and the forces follow it. On the lower surface the laminar layer
  separates at x/c = 0.89 to 0.91 and stays separated to the trailing edge.
- **What is reported.** The forces are means over whole cycles, with the lowest and the highest value in
  the cycle, and the surface data are means over the 12 snapshots of a run. The mean skin friction of
  the upper surface is close to zero from the separation to x/c = 0.57 and then rises steeply (0.585).
- **Against XFOIL** (free transition, Ncrit 9, same angle): CL 0.7249 against 0.7356, CD 0.00613 against
  0.00728, CL/CD 118.2 (108.6 to 128.2 within the cycle) against 101.0. XFOIL has transition on the upper
  surface at x/c = 0.38, Fluent near 0.59: the transition model keeps the separated layer laminar for
  much longer, and its drag is 15.7 % lower.
- **Inflow.** The turbulence intensity one chord ahead of the airfoil is 0.0717 %, which corresponds to
  Ncrit = 8.95 by Mack's relation.

The solver settings that were tried against the cycle are in `MATLAB/CFD/transition_tests.m`; their
runs are queued behind the design study.
