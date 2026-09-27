# CFD (work in progress)

The aim is to check the XFOIL results with RANS CFD in ANSYS Fluent, using Transition SST (γ–Re_θ) as
Bashir et al. (2021) did, plus a fully turbulent SST case as a pessimistic bound.

| File | Purpose | Status |
|---|---|---|
| `airfoilCGrid.m` | Structured C-grid around an airfoil. 561 × 150 cells; first cell 10⁻⁵ c at the wall, growing along the wake; far field and wake 20 c. Marched from the wall to about one chord, then straight lines to the far field. | Works: no folded cells, minimum orthogonal quality 0.68 in Fluent's mesh check |
| `writeFluentMesh.m` | Writes the grid as a Fluent ASCII mesh (zones `airfoil`, `farfield`, `fluid`) | Works: read by Fluent 2026 R1 |
| `fluentJournal.m` | Batch journal: ideal-gas air at Mach 0.1, Re = 10⁶, Transition SST or SST, force coefficients after every iteration block | The command sequence runs in Fluent 2026 R1 (student licence) |
| `fluentForces.m` | Reads the lift and drag coefficients from a Fluent transcript | |

**Not working yet.** The flow solution does not converge: the force coefficients still jump between
iteration blocks. The solver settings (initialisation, discretisation order, pseudo-time step) need
more work. No CFD results are published until they do.

Run Fluent in batch mode with, for example:

```
fluent 2ddp -g -t4 -wait -i case.jou
```
