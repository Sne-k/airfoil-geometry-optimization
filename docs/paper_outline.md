# Paper outline (working document)

State: 5 October 2026. This outline says what the paper would claim, which result supports each claim,
and what is still missing. Nothing here is final; the team decides the scope, the title, the authors and
the journal.

## Working title

Two candidates:
- *How much of an XFOIL-optimised airfoil gain is real? Metric, artefacts, transition and RANS*
- *Single-point airfoil optimisation with XFOIL: what the reported gain depends on and what survives*

## The question and the answer in one paragraph

Many studies optimise an airfoil with XFOIL in the loop and report a gain in lift-to-drag ratio, often
at one angle of attack, from one run, with free transition at Ncrit = 9. The paper asks how much of
such a gain is a property of the airfoil, and answers it in three steps: one design problem taken
apart (NACA 2412), the same analysis over a population of 30 airfoils, and a check with RANS. It then
shows a formulation whose gain survives the loss of laminar flow, and proposes a short reporting
checklist.

## Contributions

| # | Contribution | Evidence | State |
|---|---|---|---|
| 1 | One reported gain taken apart into metric, numerical artefacts, shape artefacts and transition assumption | NACA 2412: `results/paper`, `results/README.md`, `results/cfd/designs/xfoil.csv` | available |
| 2 | The same over 30 airfoils and three formulations, with seeds and with and without curvature limits | `results/population` | batch running (188 runs, 11 done) |
| 3 | Check with RANS: Transition SST with the free-stream turbulence matched to Ncrit, and fully turbulent SST | `results/cfd/designs` | set-up verified; design study running (six airfoils) |
| 4 | A formulation that keeps its gain: optimise for free and tripped flow together | `results/population/README.md` (eight runs for NACA 2412) | XFOIL part done; RANS check queued |
| 5 | Audit of how such results are reported, and a checklist | `docs/literature.md`, sections 8–13 | first version done |
| 6 | Open, checked tools: optimiser with curvature limits, verified Fluent set-up, provenance of every number | repository, `tools/check_numbers.py` | available |

## Structure

**1. Introduction.** XFOIL-in-the-loop optimisation is cheap and common. Gains of tens to hundreds of
per cent are reported. Three reasons to doubt the size of such gains: the metric (fixed angle), the
optimiser's ability to find numerical and shape artefacts, and the dependence on laminar flow. State
the question, the approach and the contributions.

**2. Related work.** From `docs/literature.md`:
- XFOIL-based optimisation and its safeguards (Xoptfoil2; Pangas & Gamboa 2025; Michael et al. 2026).
- Dependence of the optimum on the analysis tool (Adler et al. 2022; Hoyos et al. 2022).
- Checks with RANS (Bashir et al. 2021; Abouzoul et al. 2026).
- Robust design under transition uncertainty for laminar-flow airfoils (Hollom & Qin; Zhao et al.; Li et al.).
- The audit: how gains are reported (metric, repeats, checks).

**3. Methods.** From `docs/methods.md`:
- Geometry and CST parameterisation.
- XFOIL analysis: two panellings, restarts, drag floor, supported maxima.
- Optimisation: GA followed by fmincon; limits on thickness, pitching moment and curvature.
- Formulations: peak CL/CD, CL/CD at a fixed angle, CL/CD at a fixed lift coefficient, the mean or the
  lower value over Ncrit = 5 and 9, and the mean or the lower value over free and tripped flow.
- Population: 30 airfoils (18 NACA, Clark Y, 11 of other families).
- Off-design analysis: Ncrit 5, 7, 11; Re 0.5 and 2 million; tripped boundary layers.
- RANS: mesh generator, Fluent set-up, free-stream turbulence matched to Ncrit.

**4. Verification and validation.**
- XFOIL against NACA 0012 wind-tunnel data (Ladson 1988): `results/validation`.
- Fluent against the NASA NACA 0012 case: forces, pressure and skin friction against CFL3D; mesh
  convergence (grid convergence index); domain size; the pseudo-time step finding: `results/cfd`.

**5. Results.**
- 5.1 One problem taken apart (NACA 2412). Report metric +142.6 % at 0° against +71 % at the peak;
  smooth against wavy designs (3.8 %); spurious optima removed by the checks; Ncrit and tripped flow.
- 5.2 The population: distribution of the gains by formulation; what survives at Ncrit 5 and with
  tripped flow; spread over seeds; effect of the curvature limits; gain as a function of the angle at
  which it is reported.
- 5.3 The robust formulations. First result (NACA 2412): the single-point design keeps its gain between
  Ncrit 5 and 11 and loses it only when tripped; the mean of free and tripped flow as objective keeps
  25 to 32 % with free transition and loses nothing when tripped; the worst case of the two gives up the
  laminar gain for about 7 % in tripped flow.
- 5.4 RANS: do the designs keep their ranking and their gain; transition locations against XFOIL; the
  behaviour of the Transition SST runs (force cycle from drifting separation cells in the laminar
  bubble, means over whole cycles).
- 5.5 Optimiser comparison at equal budget (GA, particle swarm, Bayesian optimisation) and the
  benchmark against Xoptfoil2.

**6. Discussion.** What a reported gain means; the reporting checklist; limits (two-dimensional, no
experiment of our own, XFOIL's free-transition drag is 11–14 % low, one Reynolds number for the search,
the Transition SST runs do not all settle).

**7. Conclusions.**

## Figures and tables (planned)

| Item | Content | Source | State |
|---|---|---|---|
| Fig. 1 | Original and optimised NACA 2412 shapes, with curvature | `results/paper` | available |
| Fig. 2 | The decomposition of the NACA 2412 gain (bar chart) | to make from `results/paper`, `results/cfd/designs/xfoil.csv` | to do |
| Fig. 3 | Population: gain by condition for each formulation | `results/population/gains_by_condition.png` | after the batch |
| Fig. 4 | Population: gain by reporting angle | `results/population/gain_by_angle.png` | after the batch |
| Fig. 5 | Fluent verification: forces, pressure and skin friction | `results/cfd/verification` | available |
| Fig. 6 | RANS and XFOIL polars of the six airfoils | `results/cfd/designs/design_polars.png` | running |
| Fig. 7 | The force cycle of a Transition SST run and the mean skin friction | `results/cfd/designs/transition_cycle.png` | running |
| Tab. 1 | Audit of reporting practice | `docs/literature/screening_summary.csv` | available |
| Tab. 2 | Mesh convergence and domain size | `results/cfd/verification` | available |
| Tab. 3 | Seeds: spread of the result | `results/paper/cases.csv`, `results/population/seeds.csv` | partly |

## Open decisions (for the team)

1. **Scope.** Keep the morphing studies in this paper or leave them for a second one. They are a
   different question; leaving them out makes the paper tighter.
2. **Journal.** Candidates to compare by scope and review time: *Aerospace Science and Technology*,
   *Journal of Aircraft*, *The Aeronautical Journal*, *CEAS Aeronautical Journal*, *Aerospace* (MDPI). The
   choice sets the length and the reference style.
3. **Authors and acknowledgements.** The team's decision. Most journals ask for a statement on the use
   of AI tools; the code, the analysis and this documentation were produced with an AI assistant, and
   that has to be disclosed in the form the journal requires.
4. **Data.** A release of the repository with a DOI (Zenodo) when the paper is submitted.
5. **Searches still missing.** Scopus and Web of Science with the six strings of `docs/literature.md`.

## What must be true before submission

- Every number in the paper comes from a file in `results/` and passes `tools/check_numbers.py`.
- Every reference has been read at the level at which it is cited (`docs/literature.md` marks this).
- The population batch and the CFD design study are complete and their logs show no disturbed runs.
- A person on the team has re-run at least one optimisation and one Fluent case from the repository.
