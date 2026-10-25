# Paper outline (working document)

State: 13 October 2026. This outline says what the paper would claim, which result supports each claim,
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
| 2 | The same over 30 airfoils and three formulations, with seeds and with and without curvature limits | `results/population` | available (217 runs) |
| 3 | Check with RANS: Transition SST with the free-stream turbulence matched to Ncrit, and fully turbulent SST | `results/cfd/designs` | available (six airfoils, 84 runs, and one time-accurate run) |
| 4 | A formulation that keeps its gain: optimise for free and tripped flow together (the two-condition mean of Caboni et al. 2018, with tripped flow as the second condition; the formulation itself is not new) | `results/population/README.md` (eight runs for NACA 2412), `results/cfd/README.md` | available (NACA 2412 and all 30 airfoils) |
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
- Fluent and XFOIL against wind-tunnel measurements with laminar separation bubbles (Eppler 387,
  Re = 300 000, NASA TM-4062): forces, laminar separation and reattachment: `results/cfd/e387`.
- False XFOIL solutions: the friction floor (validated on 462 polars), exact against rounded
  coordinates in the analysis, and the sensitivity test of every final design; the three steered runs
  and their repetition: `results/population`.

**5. Results.**
- 5.1 One problem taken apart (NACA 2412). Report metric +142.6 % at 0° against +71 % at the peak;
  smooth against wavy designs (3.8 %); spurious optima removed by the checks; Ncrit and tripped flow.
- 5.2 The population: distribution of the gains by formulation; what survives at Ncrit 5 and with
  tripped flow; spread over seeds; effect of the curvature limits; gain as a function of the angle at
  which it is reported. Result (217 runs): the designs optimised for peak CL/CD gain a
  median of 38.2 %, keep 29.2 to 37.4 % at other Ncrit and Reynolds numbers and have −1.6 % when
  tripped; the designs optimised at 2° gain 49.1 % at 2° and 24.8 % at the peak. At the design lift the
  peak designs keep their gain at Ncrit 5 and the fixed-lift designs lose half of it, as Hollom & Qin
  (2018) find for drag minimisation at fixed lift.
- 5.3 The robust formulations. First result (NACA 2412): the single-point design keeps its gain between
  Ncrit 5 and 11 and loses it only when tripped; the mean of free and tripped flow as objective keeps
  25 to 32 % with free transition and loses nothing when tripped; the worst case of the two gives up the
  laminar gain for about 7 % in tripped flow. Over all 30 airfoils the mean of free and tripped flow
  gains a median of 34.7 % and is better than the single-point design with tripped flow for 29.
- 5.4 RANS: do the designs keep their ranking and their gain; transition locations against XFOIL; the
  behaviour of the Transition SST runs (force cycle from drifting separation cells in the laminar
  bubble, means over whole cycles); one case in physical time, whose mean forces agree with the cycle
  means within 0.5 %.
- 5.5 The optimiser. A surrogate-assisted search that verifies every kept design with XFOIL and checks
  whether its surrogate can be trusted for the airfoil (`results/surrogate`). On six airfoils it never
  saw (robust objective) it is trusted in 14 of 18 runs and then needs 4 to 22 times fewer XFOIL analyses
  for a similar or higher result; it rejects itself on S1223, outside the training airfoils. Ten seeds:
  NACA 2412 107.5 ± 0.5 against 104.1 ± 2.8 (p = 0.0004); S1223 126.8 against 122.9 (p = 0.19). How the
  method developed (no check, check and fallback, closed loop, two fixes found by the benchmark). At
  equal budget on NACA 2412: 140.3 against 126.1 to 132.7 for GA, particle swarm and Bayesian
  optimisation. Against Xoptfoil2 on the six airfoils (peak, free transition): level or ahead except
  where Xoptfoil2 breaks the moment limit. All final designs pass the safeguards. RANS check of the
  NACA 2412 and NACA 0012 surrogate designs: fully turbulent +6.5 % and +14.1 % (the current optimiser's
  NACA 2412 design +3.3 %), Transition SST +15.0 % and +50.9 % (smaller than XFOIL's free-transition gain,
  as in the design study). Figure: best value so far against XFOIL-analysed designs over ten seeds
  (`results/surrogate/convergence_ten_seeds.png`). Position: surrogate-assisted airfoil optimisation
  exists (Ribeiro et al. 2012; Meliani et al. 2019; Mar Aye et al. 2023); Khan et al. (2025) optimise,
  with a GA, a network trained on fully turbulent SST results for three of our six airfoils (NACA 2412,
  4415, 0012) and compare its optimum with XFOIL only. What is ours is the trust check from the training
  airfoils and its test on airfoils the surrogate never saw: Li, Du & Martins (2022) name extrapolation as
  an open problem and avoid it with a smaller design space or more data; we detect it and fall back.
  Meliani et al. (2019) let only the high-fidelity model update the best solution, the same principle as
  analysing every kept design with XFOIL; their surrogate is built for one problem, ours is trained once on
  the logs of earlier optimisations (10 341 and 43 737 XFOIL designs, no extra sampling), where cross-airfoil
  models in the review need about 10⁵ dedicated RANS samples. Li et al. ask for relative errors below 1 %
  for data-based optima; ours is about 2 % on unseen airfoils, which is enough because the surrogate only
  ranks and XFOIL decides. Transition makes the objective discontinuous (Li et al.), one reason for the
  gradient-free global stage. Michael et al. (2026) save 61 % of the XFOIL
  calls with a geometric filter (S1223, NACA 2412); our trusted NACA 2412 runs need 92 % fewer (another
  Reynolds number and objective, so not like for like). He et al. (2019) find RANS optima independent of
  the start; with XFOIL the GA ends 98.1 to 106.9 on NACA 2412 over ten seeds, the surrogate optimiser
  106.8 to 108.2.

**6. Discussion.** What a reported gain means; the reporting checklist; limits (two-dimensional, no
experiment of our own, XFOIL's free-transition drag is 11–14 % low, one Reynolds number for the search,
the Transition SST runs do not all settle). One short paragraph on reaching a robust design gradually:
along a linear blend from the original to the robust designs every intermediate shape is better than the
original with free and with tripped flow, and the objective rises at every step (80 % of the deformation
gives 83 to 89 % of the gain); Abouzoul et al. (2026) judge morphing targets by such paths
(`results/surrogate/morphing_paths.csv`).

**7. Conclusions.**

## Figures and tables (planned)

| Item | Content | Source | State |
|---|---|---|---|
| Fig. 1 | Original and optimised NACA 2412 shapes, with curvature | `results/paper` | available |
| Fig. 2 | The decomposition of the NACA 2412 gain (bar chart) | `results/paper/gain_decomposition.png` (`MATLAB/Paper/gain_decomposition.m`) | available |
| Fig. 3 | Population: gain by condition for each formulation | `results/population/gains_by_condition.png` | available |
| Fig. 4 | Population: gain by reporting angle | `results/population/gain_by_angle.png` | available |
| Fig. 5 | Fluent verification: forces, pressure and skin friction | `results/cfd/verification` | available |
| Fig. 6 | RANS and XFOIL polars of the six airfoils | `results/cfd/designs/design_polars.png` | available |
| Fig. 7 | The force cycle of a Transition SST run and the mean skin friction | `results/cfd/designs/transition_cycle.png` | available |
| Tab. 1 | Audit of reporting practice | `docs/literature/screening_summary.csv` | available |
| Tab. 2 | Mesh convergence and domain size | `results/cfd/verification` | available |
| Tab. 3 | Seeds: spread of the result | `results/paper/cases.csv`, `results/population/seeds.csv` | available |

## Open decisions (for the team)

1. **Scope.** Decided on 25 October 2026: the morphing studies are not part of the paper. They answer a
   different question, are XFOIL-only and predate the safeguards and the RANS checks, and Abouzoul et al.
   (2026) already combine surrogate optimisation, morphing and Transition SST on NACA 2412; a morphing
   section would make the contribution less clear. The morphing-path result goes into the discussion
   (one paragraph). The studies stay in the repository as part of the project's history.
2. **Journal.** Candidates to compare by scope and review time: *Aerospace Science and Technology*,
   *Journal of Aircraft*, *The Aeronautical Journal*, *CEAS Aeronautical Journal*, *Aerospace* (MDPI). The
   choice sets the length and the reference style.
3. **Authors and acknowledgements.** The team's decision. Most journals ask for a statement on the use
   of AI tools; the code, the analysis and this documentation were produced with an AI assistant, and
   that has to be disclosed in the form the journal requires.
4. **Data.** A release of the repository with a DOI (Zenodo) when the paper is submitted.
5. **Databases.** Scopus and Web of Science are not available to the team (the VTU consortium does not
   include them). The search uses OpenAlex and Semantic Scholar, and the paper must name them as the
   databases searched.

## What must be true before submission

- Every number in the paper comes from a file in `results/` and passes `tools/check_numbers.py`.
- Every reference has been read at the level at which it is cited (`docs/literature.md` marks this).
- The population batch and the CFD design study are complete and their logs show no disturbed runs.
- A person on the team has re-run at least one optimisation and one Fluent case from the repository.
