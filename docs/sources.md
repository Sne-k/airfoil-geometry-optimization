# Sources and what the project learnt from them

One place for every source that went into the project: the papers sent by the project owner, the papers and
reports found during the work, the GitHub repositories that were reviewed, and the data and tools. For each
source it says what was learnt, where the project uses it, and what is still open. The full bibliographic
data, the documented literature search, the audit of reporting practice and the research gaps are in
[literature.md](literature.md); this file does not repeat them.

**Status.** *Full text*: read for this project. *Abstract*: only the abstract or a publisher's summary;
use such a source only for what that summary says. *To check*: not yet verified. Summaries are in our own
words.

## 1. Papers sent by the project owner

### 1.1 First batch (14 October 2026, seven papers)

| Paper | Status | What we learnt | Where it is used |
|---|---|---|---|
| He, Li, Mader, Yildirim & Martins (2019). Robust aerodynamic shape optimization — from a circle to an airfoil. *Aerosp. Sci. Technol.* 87, 48–61 | full text | "Robust" here means a robust optimisation *process* (parameterisation, mesh deformation, solver failures). On the same RANS benchmarks, optima published by different groups differ by up to 23 drag counts. Their RANS optimisations reach the same optimum from very different starting shapes, including a circle, which points to a unimodal problem | Gap 1 (the analysis tool changes the answer) and gap 3 (one run is not enough: our XFOIL runs end at different designs for different seeds) in [literature.md](literature.md); the E387 validation was added because neither tool is a default reference |
| Hollom & Qin (2021). Uncertainty analysis and robust shape optimisation for laminar flow aerofoils. *Aeronaut. J.* 125, 365–388 (sent as `hollom2020.pdf`) | full text | Ncrit treated as uncertain (from 9 down to 0) with XFOIL (300 panels, CST). Robust optimisation lowers mean drag and its spread, at a trade-off; robustness gained at the design point can be lost off-design; the pitching moment of the optimised aerofoils grows considerably | Credited for the free-and-reduced-Ncrit construction of our robust objectives (literature.md section 7); supports the pitching-moment limit of `optimize_airfoil` |
| Li, Gao, Huang & Zhao (2013). Robust design of NLF airfoils. *Chin. J. Aeronaut.* 26, 309–318 | full text | Robust design of the NLF-0115 with RANS and the same γ–Re_θ transition model as our Fluent runs, checked against wind-tunnel data, with Kriging and particle swarm over uncertain lift and Mach number | Background for the robust-design section |
| Morgado, Vizinho, Silvestre & Páscoa (2016). XFOIL vs CFD performance predictions for high lift low Reynolds number airfoils. *Aerosp. Sci. Technol.* 52, 207–214 | full text | For E387 and S1223 at Re = 2 × 10⁵, XFOIL matched the wind-tunnel data at least as well as k-ω SST and a transition model in two RANS codes | Neither XFOIL nor RANS is treated as the truth; the reason for validating both tools on the Eppler 387 ([results/cfd](../results/cfd/README.md)) |
| Ribeiro, Awruch & Gomes (2012). An airfoil optimization technique for wind turbines. *Appl. Math. Model.* 36, 4898–4907 | full text | Fully turbulent RANS with single- and multi-objective genetic algorithms and a **neural-network surrogate**; the far field had to be further away than the usual 100 chords | Supports the 500-chord domain of the CFD meshes. Also prior work for the surrogate optimiser (section 7 below) |
| Suprayitno, Yu, Aminnudin & Wulandari (2020). Airfoil aerodynamics optimization under uncertain operating conditions. *J. Phys.: Conf. Ser.* 1446, 012014 | full text | XFOIL, NACA 0012, nine PARSEC variables, a Taguchi array; the gain is reported as a signal-to-noise ratio ("69 %"), not as a lift-to-drag ratio | An example for the reporting audit and checklist (literature.md sections 10 and 13) |
| Zhao, Gao, Gao & Wang (2017). Effective robust design of high lift NLF airfoil under multi-parameter uncertainty. *Aerosp. Sci. Technol.* 68, 530–542 | full text | The deterministic single-point design is ill-posed: its drag rises sharply away from the design point; robust design over Mach number and lift avoids this | Independent support for the fragility of single-point designs that the population study shows |

Verdict at the time: none of the seven takes away what the paper can claim, and every robust-design study
among them works on one or two airfoils without a tripped-flow or RANS check of the result.

### 1.2 Second batch (20 October 2026)

| Paper | Status | What we learnt | Where it is used |
|---|---|---|---|
| Counsil & Goni Boulama (2012, online 2011). Validating the URANS SST γ–Re_θ model for low-Reynolds-number external aerodynamics. *Int. J. Numer. Methods Fluids* 69, 1411–1432 | full text | Run time-accurately for NACA 0012 at Re = 5 × 10⁴ to 2.5 × 10⁵, the model reproduces the DNS separation bubble at Re = 10⁵ and 4°; XFLR5 gives a bubble about half as long and over-optimistic lift. Vortex shedding from the bubble makes transition and reattachment fluctuate strongly while separation stays nearly fixed. The solution is sensitive to the inlet turbulence and eddy-viscosity ratio; a 10-chord inlet distance spoils the reattachment | Supports the cycling Transition SST runs, their averaging over whole cycles and the long domain ([results/cfd](../results/cfd/README.md), [methods.md](methods.md)) |
| Hollom & Qin (2018). Quantification and multi-point optimization of natural laminar flow airfoil robustness to transition amplification factor. AIAA 2018-1161 | full text | XFOIL with NSGA-II and CST on three NLF airfoils at Re = 4 to 9 × 10⁶. Drag at fixed lift trades against robustness to a lower Ncrit: the minimum-drag designs lose laminar flow fastest, and a small drag increase buys much robustness. Extending laminar flow moves the maximum thickness aft and raises the pitching moment. **Comparing two discrete Ncrit values can misrepresent robustness** | The fixed-lift result of the population study (designs at the design lift lose half their gain at Ncrit 5), the outline section 5.2; and now the limit on discrete Ncrit values in [PAPER.md](../PAPER.md) |

### 1.3 Third batch (20 October 2026)

| Paper | Status | What we learnt | Where it is used |
|---|---|---|---|
| Michael, Abagero, Tullu, Abebe & Jung (2026). Accelerated airfoil optimization via a geometry-based discriminator within particle swarm optimization. *IEEE Access* 14, 59022–59034 | full text | Particle swarm with NURBS and XFOIL on S1223 (Re = 3 × 10⁵) and NACA 2412 (Re = 5 × 10⁵). Before XFOIL, candidates are rejected if a surface changes slope direction more than 4 times or a slope jump exceeds 0.06 (limits from the UIUC database); the filter cuts XFOIL calls by 61 % (1000 to 390) and raises the peak CL/CD of the result by 16.85 %, although the same number is elsewhere described as the gain over the original. The objective is the worst CL/CD over 0–8°, but the peak is reported. One run per configuration | A third geometric safeguard beside Xoptfoil2 and Pangas & Gamboa (literature.md gaps 1 and 4); now also the comparison point for the XFOIL saving of the surrogate optimiser (section 7) |

### 1.4 Fourth batch (24 October 2026)

| Paper | Status | What we learnt | Where it is used |
|---|---|---|---|
| Li, Du & Martins (2022). Machine learning in aerodynamic shape optimization. *Prog. Aerosp. Sci.* 134, 100849 (open access) | full text of the parts on design space, aerodynamic models, surrogate-based and interactive optimisation, and the conclusions | Most learned models interpolate and lose accuracy when they extrapolate; the field keeps extrapolation down by shrinking the design space (geometric filtering, for example a validity model trained on over 10 000 airfoils) and by more training data, and names extrapolatory models as an open problem. A check at run time of whether a model may be used for a new case is not among the methods reviewed. Models trained across many airfoils need about 10⁵ RANS samples (Webfoil and successors, mean drag errors of 0.1 to 5 counts), and relative errors below 1 % are said to be needed for optima like those of CFD-based optimisation. Transition makes objectives discontinuous, which hampers gradient-based optimisation. ML studies should end with a comparison with state-of-the-art methods | The claim of the surrogate optimiser (detect extrapolation and fall back, instead of avoiding it); the comparison with the current optimiser, particle swarm, Bayesian optimisation and Xoptfoil2; the case for gradient-free search with XFOIL ([PAPER.md](../PAPER.md), outline section 5.5) |
| Meliani, Bartoli, Lefebvre, Bouhlel, Martins & Morlier (2019). Multi-fidelity efficient global optimization: methodology and application to airfoil shape design. AIAA 2019-3236 | full text | Multi-fidelity Bayesian optimisation with XFOIL (1/200 of the cost) as the low and RANS as the high fidelity for one subsonic airfoil; about half the cost of single-fidelity Bayesian optimisation, and in the 15-variable case the gradient-based optimum (110.5 against 110.7) after 8 RANS and 437 XFOIL analyses beyond a starting sample. Only high-fidelity values may update the best solution. The surrogate is built for the one problem from its own samples | Prior work named in PAPER.md; the parallel with our rule that every kept design is analysed with XFOIL; the contrast that our surrogate is trained once on the logs of earlier optimisations of 24 airfoils and used for new airfoils |

## 2. Papers and reports found during the work (full text)

| Source | What we learnt | Where it is used |
|---|---|---|
| Adler, Christison Gray & Martins (2022). To CFD or not to CFD? ICAS 2022 (free on the ICAS site) | Single-point drag minimisation at CL = 0.5 in XFOIL and in fully turbulent RANS. XFOIL designs have 20–25 drag counts less drag than RANS designs when analysed in XFOIL; XFOIL designs with tripped boundary layers resemble the RANS designs. XFOIL's objective has small dips each time the transition point crosses a panel, which create false local optima | The tripped condition of the robust objective; the false-solution discussion; the novelty statement (they check XFOIL designs with fully turbulent RANS, not with a transition model) |
| Eça et al. (2022). Assessment of numerical and modeling errors of RANS-based transition models for low-Reynolds number 2-D flows. 34th Symposium on Naval Hydrodynamics (NASA NTRS) | Different RANS codes with nominally the same transition model rarely agree within their numerical uncertainty; grid convergence in the bubble can be scattered; on the Eppler 387 the γ–Re_θ model gives the largest bubble, and at 7° RANS shows a bubble that the experiment does not | The caveat on the Fluent numbers (one implementation) in PAPER.md and the CFD README; the E387 discussion |
| Caboni, Minisci & Riccardi (2018). *J. Phys.: Conf. Ser.* 1037, 042011 (repository copy) | The mean of the lift-to-drag ratio at Ncrit 0.5 and 9.5 ("pseudo-deterministic") as the objective, close to common practice; uncertainty-based designs trade a little mean for less spread, mostly through thickness | The earlier work our robust formulation is credited to |
| McGhee, Walker & Millard (1988). NASA TM-4062 (Eppler 387 in the Langley LTPT) | Forces, pressures and oil-flow separation and reattachment at Re = 300 000 | The validation of XFOIL and Fluent with laminar separation bubbles |
| Ladson (1988). NASA TM-4074; NASA Turbulence Modeling Resource NACA 0012 case | Measured NACA 0012 data with free and fixed transition; reference solutions of three RANS codes | XFOIL validation; Fluent verification |
| Celik et al. (2008). Grid convergence index procedure (ASME) | The GCI equations and the advice on refinement ratios | `gridConvergence.m`; the author list is still to check |
| Pangas & Gamboa (2025); Mar Aye et al. (2023); Belda & Hyhlík (2024); Song, Wang & Luo (2022); Akram & Kim (2021); Hoyos et al. (2022); Khan et al. (2025); Bashir et al. (2021, 2022); Kulfan (2008); Drela (1989); El Houd & Hallou (2019) | One line each in [literature.md](literature.md) sections 3 to 6. Key points: smoothness check and laminar drag bound before the analysis (Pangas & Gamboa); 20 runs per method (Mar Aye); the same design gains +94.7 % at 0° and +16.1 % at 6.2° (Belda & Hyhlík); gains reported at a fixed angle (Song, Akram & Kim); different tools give different optima (Hoyos); a neural network trained on fully turbulent SST and optimised for NACA 2412, 4415 and 0012, compared with XFOIL only (Khan) | The audit, the checklist, the reporting decisions and the positioning of the surrogate optimiser |

## 3. GitHub repositories

| Repository | Reviewed | What we learnt | What was taken |
|---|---|---|---|
| [karanchawla/Airfoil-Optimization](https://github.com/karanchawla/Airfoil-Optimization) (Python 2, MIT) | 27 Sep 2026, on request | A course project comparing optimisers; its XFOIL wrapper has no time limit or false-result filter; its NACA 5-digit constants match ours (a cross-check); it argues for particle swarm and for designing over an operating range | The particle swarm option (`'Algorithm', 'pso'`) and objectives over several lift coefficients (`'LDatCL'` with weights). No code copied |
| [IDEALLab/airfoil-opt-gan](https://github.com/IDEALLab/airfoil-opt-gan) (Chen, Chiu & Fuge; Python 2, TensorFlow, MIT) | 27 Sep 2026, on request | A GAN-learned Bézier shape space with Bayesian optimisation then a GA; methods compared over repeated runs as mean best-so-far against the number of evaluations; its XFOIL guard simply discards CL/CD above 300 | The Bayesian optimisation option, the multi-seed comparison at equal budget, and (24 Oct 2026) the best-so-far figure of the surrogate benchmark ([results/surrogate](../results/surrogate/README.md)). The GAN itself is future work |
| [jxjo/Xoptfoil2](https://github.com/jxjo/Xoptfoil2) (Fortran, MIT; version 2.0.0 used) | 27 Sep 2026, on request; source read for the curvature constraints | Operating points by lift rather than angle; retries and outlier filtering of XFOIL; optimisers learn to build trailing-edge "spoilers" and nose ripples that XFOIL rewards, hence curvature checks. Running it showed: it accepts at most 2 curvature reversals per surface, rejects seeds whose Bézier fit violates its curvature checks (the NACA 2412 seed fails the leading-edge check; S1223 needs 7 Bézier points), and reads but does not enforce `min_thickness` on the result (a thickness geometry target does) | The curvature limits of `optimize_airfoil` (`auto_curvature`, with two deliberate differences), the NACA 2412 benchmark and the six-airfoil peak comparison |
| [anasselhoud/Airfoil-Shape_optimization](https://github.com/anasselhoud/Airfoil-Shape_optimization) (El Houd & Hallou, MIT) | during the curation | The PARSEC + GA code behind the reference study of the project report | The PARSEC reference branch, credited in `THIRD_PARTY_NOTICES.md` |

## 4. Data and tools

- **UIUC Airfoil Coordinates Database**: coordinates of the non-NACA seeds of the population study. The
  coordinate files are not redistributed; the optimised designs are.
- **Clark Y**: coordinates from airfoiltools.com (`MATLAB/airfoils/clarky.dat`).
- **XFOIL 6.99** (M. Drela, GPL): the analysis code; not in the repository.
- **Xoptfoil2 2.0.0**: the benchmark optimiser; not in the repository.
- **ANSYS Fluent 2026 R1 Student**: the RANS solver.
- **MATLAB R2024b** with the Optimization, Global Optimization, Statistics and Machine Learning, and
  Parallel Computing toolboxes; **scikit-learn** for training the surrogates.

## 5. Other material

- **The project report (RT1.pdf)**: the starting point. Its "144 %" is an α = 0° value; its optimum sits on
  the bounds of the geometric objective. The report is not published here (it names the team members); a
  correction list was made.
- **A review of the earlier cleaned repository (25 Sep 2026)**: the NACA generator used the
  closed-trailing-edge coefficient −0.1036 while the original code used −0.1015, so the two geometries
  differ; the exporter needed geometric checks; the optimiser of the report was geometric, not
  aerodynamic. All three are handled ([methods.md](methods.md) section 2).

## 6. References read at abstract level or still to check

Listed with details in [literature.md](literature.md): Drela & Giles (1987); Mack (1977, to check); van
Ingen (2008, to check); Menter (1994); Langtry & Menter (2009); Eça et al. (2022, SciTech); Avirović et al.
(2026); Spalart & Rumsey (2007); Thomas & Salas (1986); Roache (1994); Masters et al. (2017); Hicks & Henne
(1978); Chen, Chiu & Fuge (2020, paper overview and code); Kennedy & Eberhart (1995); Jones, Schonlau &
Welch (1998); Deb (2000); Owoyele & Pal (2021); Abouzoul et al. (2026, two papers); Hoyos et al. (2021); Fakhari & Mrad (2025); Barbarino et al. (2011); Secanell,
Suleman & Gamboa (2006); Koreanschi et al. (2016); Majid & Jo (2021); Chen et al. (2023); Rashad & Zingg
(2016); Abbott & von Doenhoff (1959); Gregory & O'Reilly (1970); McCroskey (1987). The screened papers of
the audit are in `literature/screening.csv`.

Worth reading in full next: **Abouzoul et al. (2026)**, two papers (doi:10.1016/j.ast.2026.113128 and
doi:10.1016/j.ast.2026.112630), a surrogate optimiser with morphing on NACA 2412 checked with Transition
SST, which matters for the decision on morphing. No free copy exists (no preprint on arXiv, SSRN or HAL;
searched 24 October 2026); their abstracts are summarised in literature.md. The same group's open-access
conference paper (Abouzoul, Gaber & Tayane 2025, *E3S Web of Conferences* 680, 00095,
doi:10.1051/e3sconf/202568000095) describes the earlier stage of the method (surrogates trained on NACA
profiles with Bayesian optimisation); its site refuses automated reading, so it has to be downloaded by
hand. Li, Du & Martins (2022) and Meliani et al. (2019) were read
on 24 October 2026 (section 1.4).

## 7. Knowledge that was not yet used, and what was done with it (24 October 2026)

| Knowledge | Source | Done |
|---|---|---|
| Compare optimisers by the best value so far against the number of evaluations over repeated runs | Chen, Chiu & Fuge (IDEALLab) | Figure `results/surrogate/convergence_ten_seeds.png`: median and quartiles of ten seeds against the number of XFOIL-analysed designs, surrogate against GA, NACA 2412 and S1223 |
| Surrogate-assisted airfoil optimisation is not new: a neural network with a GA on RANS (Ribeiro et al. 2012), multi-fidelity Bayesian optimisation with XFOIL and RANS (Meliani et al. 2019), a multi-fidelity surrogate with XFOIL and Fluent (Mar Aye et al. 2023) | literature.md | Named as prior work in [PAPER.md](../PAPER.md) ("Not new") and in the outline section 5.5; the claim is the trust check and its test on unseen airfoils |
| RANS optima are reached from any start; XFOIL runs end at different designs for different seeds | He et al. (2019) | Used to read the ten-seed result: the GA spreads over 98.1 to 106.9 on NACA 2412, the surrogate optimiser over 106.8 to 108.2 ([results/surrogate](../results/surrogate/README.md)) |
| A geometric filter saves 61 % of the XFOIL calls on S1223 and NACA 2412 | Michael et al. (2026) | A comparison point in the outline section 5.5 (our trusted runs on NACA 2412 need 92 % fewer, at another Reynolds number and objective, so not like for like) |
| Two discrete Ncrit values can misrepresent robustness | Hollom & Qin (2018) | Cited at the limit on discrete Ncrit values in PAPER.md |
| Learned models interpolate; extrapolation is an open problem, handled in the literature by shrinking the design space or adding data | Li, Du & Martins (2022) | The claim of the surrogate optimiser is worded against it in PAPER.md and the outline: the trust check detects extrapolation and falls back to XFOIL |
| Only the accurate model may update the best solution | Meliani et al. (2019) | Named as the same principle as our verification of every kept design (outline section 5.5) |
| Cross-airfoil models need about 10⁵ dedicated RANS samples; ours reuses the logs of earlier optimisations (10 341 and 43 737 XFOIL designs), at no extra cost | Li, Du & Martins (2022) | Outline section 5.5 |
