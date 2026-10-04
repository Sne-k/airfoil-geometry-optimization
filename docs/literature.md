# Literature and research gaps (working document)

This is the literature basis for a paper on this project. It has two parts: the references the project
uses (sections 1 to 7), and a documented search with an audit of how studies that optimise airfoils with
XFOIL report their results (sections 8 to 10). Sections 11 to 13 give the research gaps, the tasks they
lead to, and a draft reporting checklist.

**How the references were checked.**
- The bibliographic data (authors, year, title, journal, volume, pages, DOI) of every entry with a DOI
  were looked up on Crossref, on 1 October 2026 or, for the entries added later, on 4 October 2026 with
  `docs/literature/check_crossref.py` (result: `docs/literature/crossref_check.csv`).
- Reports and books were checked on the NASA Technical Reports Server or the publisher's page.
- The column "content" says how well the statement about the work is supported: **read** (the full
  text was read for this project), **abstract** (only the abstract or the publisher's summary), or
  **to check**. Only statements marked "read" or "abstract" should go into a paper as they stand.

## 1. Analysis tools and numerical methods

| Reference | What it provides | Content |
|---|---|---|
| Drela, M. (1989). XFOIL: an analysis and design system for low Reynolds number airfoils. *Low Reynolds Number Aerodynamics*, Lecture Notes in Engineering 54, Springer, 1–12. doi:10.1007/978-3-642-84010-4_1 | the analysis code used here | read (documentation) |
| Drela, M. & Giles, M. B. (1987). Viscous-inviscid analysis of transonic and low Reynolds number airfoils. *AIAA Journal* 25(10), 1347–1355. doi:10.2514/3.9789 | the boundary-layer formulation behind XFOIL | abstract |
| Mack, L. M. (1977). Transition prediction and linear stability theory. AGARD CP-224 | e^N method; the usual link between Ncrit and free-stream turbulence (Ncrit = −8.43 − 2.4 ln Tu) | to check (cited through XFOIL's documentation) |
| van Ingen, J. (2008). The eN method for transition prediction. Historical review of work at TU Delft. 38th Fluid Dynamics Conference, AIAA paper 2008-3830. doi:10.2514/6.2008-3830 | history of the e^N method | to check |
| Menter, F. R. (1994). Two-equation eddy-viscosity turbulence models for engineering applications. *AIAA Journal* 32(8), 1598–1605. doi:10.2514/3.12149 | k-ω SST model (CFD) | abstract |
| Langtry, R. B. & Menter, F. R. (2009). Correlation-based transition modeling for unstructured parallelized computational fluid dynamics codes. *AIAA Journal* 47(12), 2894–2906. doi:10.2514/1.42362 | γ–Re_θ transition model (CFD) | abstract |
| Spalart, P. R. & Rumsey, C. L. (2007). Effective inflow conditions for turbulence models in aerodynamic calculations. *AIAA Journal* 45(10), 2544–2553. doi:10.2514/1.29373 | decay of free-stream turbulence between the inflow boundary and the body | abstract |
| Thomas, J. L. & Salas, M. D. (1986). Far-field boundary conditions for transonic lifting solutions to the Euler equations. *AIAA Journal* 24(7), 1074–1080. doi:10.2514/3.9394 | point-vortex correction of the far-field boundary; named by the NASA TMR as the alternative to a 500-chord domain | abstract |
| Celik, I. B., Ghia, U., Roache, P. J., Freitas, C. J., Coleman, H. & Raad, P. E. (2008). Procedure for estimation and reporting of uncertainty due to discretization in CFD applications. *Journal of Fluids Engineering* 130(7), 078001. doi:10.1115/1.2960953 | grid convergence index, used for the CFD mesh study | to check (formulas used from memory of the paper; Crossref lists no authors, so the author list must be confirmed on the article) |
| Roache, P. J. (1994). Perspective: a method for uniform reporting of grid refinement studies. *Journal of Fluids Engineering* 116(3), 405–413. doi:10.1115/1.2910291 | origin of the grid convergence index | abstract |
| Morgado, J., Vizinho, R., Silvestre, M. A. R. & Páscoa, J. C. (2016). XFOIL vs CFD performance predictions for high lift low Reynolds number airfoils. *Aerospace Science and Technology* 52, 207–214. doi:10.1016/j.ast.2016.02.031 | XFOIL compared with RANS for high-lift low-Re airfoils | abstract |
| Adler, E. J., Christison Gray, A. & Martins, J. R. R. A. (2022). To CFD or not to CFD? Comparing RANS and viscous panel methods for airfoil shape optimization. 33rd ICAS Congress, paper ICAS2022_0905 | optimal shapes depend on the analysis tool; modelling transition gives significantly lower-drag designs; "few, if any" earlier studies compared this | abstract |

## 2. Validation and verification data

| Reference | Content |
|---|---|
| Ladson, C. L. (1988). NASA TM-4074 (NACA 0012, Langley LTPT, M 0.05–0.36, Re 2–12 × 10⁶, free and fixed transition) | read; Table I transcribed |
| Abbott, I. H. & von Doenhoff, A. E. (1959). *Theory of Wing Sections*. Dover | data digitised by the NASA TMR |
| Gregory, N. & O'Reilly, C. L. (1970). ARC R&M 3726 | data digitised by the NASA TMR |
| McCroskey, W. J. (1987). A critical assessment of wind tunnel results for the NACA 0012 airfoil. NASA TM-100019 / AGARD CP-429 | lift-slope correlation, through the NASA TMR |
| NASA Turbulence Modeling Resource, 2D NACA 0012 validation case, <https://tmbwg.github.io/turbmodels/naca0012_val.html> and the SST results page `naca0012_val_sst.html` (CFL3D, FUN3D, NTS on the 897 × 257 grid; pressure and skin-friction files of CFL3D). The site moved from turbmodels.larc.nasa.gov; pages read on 4 October 2026 | read (web pages) |

## 3. Parameterisation

| Reference | What it provides | Content |
|---|---|---|
| Kulfan, B. M. (2008). Universal parametric geometry representation method. *Journal of Aircraft* 45(1), 142–158. doi:10.2514/1.29958 | CST, used here | read (method) |
| Masters, D. A., Taylor, N. J., Rendall, T. C. S., Allen, C. B. & Poole, D. J. (2017). Geometric comparison of aerofoil shape parameterization methods. *AIAA Journal* 55(5), 1575–1589. doi:10.2514/1.J054943 | CST performs well with few variables; 20–25 variables are needed to cover the design space | abstract |
| Hicks, R. M. & Henne, P. A. (1978). Wing design by numerical optimization. *Journal of Aircraft* 15(7), 407–412. doi:10.2514/3.58379 | bump functions | abstract |
| Chen, W., Chiu, K. & Fuge, M. D. (2020). Airfoil design parameterization and optimization using Bézier generative adversarial networks. *AIAA Journal* 58(11), 4723–4735. doi:10.2514/1.J059317 | data-driven parameterisation (BézierGAN) with efficient global optimisation | read (code and paper overview) |

## 4. Optimisers and constraint handling

| Reference | What it provides | Content |
|---|---|---|
| Kennedy, J. & Eberhart, R. (1995). Particle swarm optimization. *Proceedings of ICNN'95*, 4, 1942–1948. doi:10.1109/ICNN.1995.488968 | particle swarm | abstract |
| Jones, D. R., Schonlau, M. & Welch, W. J. (1998). Efficient global optimization of expensive black-box functions. *Journal of Global Optimization* 13(4), 455–492. doi:10.1023/A:1008306431147 | Gaussian-process optimisation with expected improvement (basis of Bayesian optimisation) | abstract |
| Deb, K. (2000). An efficient constraint handling method for genetic algorithms. *Computer Methods in Applied Mechanics and Engineering* 186(2–4), 311–338. doi:10.1016/S0045-7825(99)00389-8 | feasibility rules used here | abstract |
| Owoyele, O. & Pal, P. (2021). A novel machine learning-based optimization algorithm (ActivO) for accelerating simulation-driven engine design. *Applied Energy* 285, 116455. doi:10.1016/j.apenergy.2021.116455 | the optimiser used by Song et al. (2022) | abstract |
| Li, J., Du, X. & Martins, J. R. R. A. (2022). Machine learning in aerodynamic shape optimization. *Progress in Aerospace Sciences* 134, 100849. doi:10.1016/j.paerosci.2022.100849 | review of surrogate and learning-based optimisation | abstract |
| He, X., Li, J., Mader, C. A., Yildirim, A. & Martins, J. R. R. A. (2019). Robust aerodynamic shape optimization — from a circle to an airfoil. *Aerospace Science and Technology* 87, 48–61. doi:10.1016/j.ast.2019.01.051 | robustness of RANS-based shape optimisation | to check |
| Xoptfoil2, J. Guenzel, <https://github.com/jxjo/Xoptfoil2> (2.0.0) | XFOIL-based optimiser with curvature constraints against numerical artefacts | read (documentation and source) |

## 5. Airfoil optimisation studies with XFOIL (comparison and metrics)

The works of the audit (section 10) are listed in `docs/literature/screening.csv`. The ones that matter
most for the positioning of this project:

| Reference | What it does | Content |
|---|---|---|
| Pangas, G. F. S. & Gamboa, P. V. (2025). Low-speed airfoil optimization for improved off-design performance. *Aerospace* 12(8), 685. doi:10.3390/aerospace12080685 | XOPTFOIL (particle swarm, XFOIL 6.97), B-splines, objective over 17 operating points plus a mission score. **Before the analysis, shapes are checked for surface smoothness ("wavy surfaces are not desired"), and a drag that is too low is compared with a laminar bound.** One run per weighting; no check beyond XFOIL | read |
| Michael, L. W., Abagero, A., Tullu, A. & Abebe, Y. (2026). Accelerated airfoil optimization via a geometry-based discriminator within particle swarm optimization. *IEEE Access* 14, 59022–59034. doi:10.1109/access.2026.3683048 | particle swarm with XFOIL at Re = 3 × 10⁵; candidates are rejected before the analysis by **the number of surface curvature peaks** and a deviation from the UIUC airfoils; 61 % fewer solver calls and a higher peak L/D (85.2 → 99.6) than plain particle swarm | abstract |
| Abouzoul, W., Tayane, S., Gaber, J. & Ennaji, M. (2026). Surrogate-based constrained optimization of camber-morphing airfoils: onset location as a design variable and quantification of adaptive versus robust morphing strategies. *Aerospace Science and Technology* 178, 113128. doi:10.1016/j.ast.2026.113128 | camber morphing of NACA 2412 and others; L/D 40.6 → 101.5 in the best case, **percentages given together with absolute values; Transition SST at Re = 10⁶ confirms the optima within 6 %** | abstract |
| Abouzoul, W., Tayane, S., Gaber, J. & Ennaji, M. (2026). Reinterpreting aerodynamic optimality for morphing airfoils under continuous shape evolution. *Aerospace Science and Technology* 176, 112630. doi:10.1016/j.ast.2026.112630 | performance along the deformation path from the baseline to the optimum (XFOIL, then RANS), not only at the end point | abstract |
| Mar Aye, C. et al. (2023). Airfoil shape optimisation using a multi-fidelity surrogate-assisted metaheuristic with a new multi-objective infill sampling technique. *Computer Modeling in Engineering & Sciences* 137(3), 2111–2128. doi:10.32604/cmes.2023.028632 | XFOIL as low and Fluent as high fidelity; **20 independent optimisation runs per method** | read |
| Belda, M. & Hyhlík, T. (2024). Interactive airfoil optimization using Parsec parametrization and adjoint method. *Applied Sciences* 14(8), 3495. doi:10.3390/app14083495 | lift of NREL S809 optimised at 0° with an inviscid panel method, checked with XFOIL: **+94.7 % at 0° and +16.1 % at 6.2° for the same design** | read |
| Song, X., Wang, L. & Luo, X. (2022). Airfoil optimization using a machine learning-based optimization algorithm. *J. Phys.: Conf. Ser.* 2217, 012009. doi:10.1088/1742-6596/2217/1/012009 | NACA 0012, CST, XFOIL; objective CL/CD at a fixed α = 1°, gain +220 % | read |
| Akram, M. T. & Kim, M.-H. (2021). CFD analysis and shape optimization of airfoils using class shape transformation and genetic algorithm—Part I. *Applied Sciences* 11(9), 3791. doi:10.3390/app11093791; and Part II (NREL S809), *Applied Sciences* 11(5), 2211. doi:10.3390/app11052211 | GA with XFOIL at fixed angles (3°; 0° and 6.2°); L/D +7.4 to +15.9 %; RANS (SST) of the result | read |
| Hoyos, J. D. et al. (2022). Aircraft propeller design through constrained aero-structural particle swarm optimization. *Aerospace* 9(3), 153. doi:10.3390/aerospace9030153 | propeller design with section data from XFOIL or OpenFOAM; **the two tools lead to different optimal propellers**; wind-tunnel tests | read |
| Hoyos, J. D. et al. (2021). Airfoil shape optimization: comparative study of meta-heuristic algorithms, airfoil parameterization methods and Reynolds number impact. *IOP Conf. Ser.: Mater. Sci. Eng.* 1154, 012016. doi:10.1088/1757-899x/1154/1/012016 | GA, particle swarm and sine-cosine algorithm with three parameterisations; XFOIL and OpenFOAM | abstract |
| Fakhari, S. M. & Mrad, H. (2025). Aerodynamic shape optimization of NACA airfoils based on a novel unconstrained conjugate gradient algorithm. *Journal of Engineering Research* 13(3), 2026–2035. doi:10.1016/j.jer.2024.07.020 | NACA 4412 and NACA 2415, Bézier, XFOIL; L/D +13.7 % and +32 % | abstract |
| Khan et al. (2025). Aerodynamic analysis and ANN-based optimization of NACA airfoils for enhanced UAV performance. *Scientific Reports* 15. doi:10.1038/s41598-025-95848-4 | NACA 2412, 4415 and 0012; a neural network trained on fully turbulent SST results is optimised with a GA; XFOIL is only compared | read |
| Ribeiro, A. F. P., Awruch, A. M. & Gomes, H. M. (2012). An airfoil optimization technique for wind turbines. *Applied Mathematical Modelling* 36(10), 4898–4907. doi:10.1016/j.apm.2011.12.026 | airfoil optimisation for wind turbines | to check |
| El Houd, A. & Hallou, Y. (2019). Optimization study of NACA airfoil using nonlinear programming & genetic algorithms. Project report, ENSAM Meknès (code on GitHub) | reference study of the project report; NACA 2412, PARSEC, area objective | read |

## 6. Morphing

| Reference | What it does | Content |
|---|---|---|
| Barbarino, S., Bilgen, O., Ajaj, R. M., Friswell, M. I. & Inman, D. J. (2011). A review of morphing aircraft. *Journal of Intelligent Material Systems and Structures* 22(9), 823–877. doi:10.1177/1045389X11414084 | review | abstract |
| Secanell, M., Suleman, A. & Gamboa, P. (2006). Design of a morphing airfoil using aerodynamic shape optimization. *AIAA Journal* 44(7), 1550–1562. doi:10.2514/1.18109 | separate optimal shapes for six UAV flight conditions (RANS, SQP) | abstract |
| Bashir, M., Longtin-Martel, S., Botez, R. M. & Wong, T. (2021). Aerodynamic design optimization of a morphing leading edge and trailing edge airfoil – application on the UAS-S45. *Applied Sciences* 11(4), 1664. doi:10.3390/app11041664 | nose and trailing-edge morphing, PSO + pattern search, XFOIL at given angles; Fluent Transition SST of the results | read |
| Bashir, M., Longtin-Martel, S., Botez, R. M. & Wong, T. (2022). Optimization and design of a flexible droop-nose leading-edge morphing wing based on a novel black widow optimization algorithm—Part I. *Designs* 6(1), 10. doi:10.3390/designs6010010 | the same airfoil with another optimiser and a modified CST | read (methods) |
| Koreanschi, A., Sugar-Gabor, O. & Botez, R. M. (2016). Drag optimisation of a wing equipped with a morphing upper surface. *The Aeronautical Journal* 120(1225), 473–493. doi:10.1017/aer.2016.6; and Numerical and experimental validation of a morphed wing geometry using Price-Païdoussis wind-tunnel testing. *The Aeronautical Journal* 120(1227), 757–795. doi:10.1017/aer.2016.30 | GA with XFOIL for a morphing upper surface; wind-tunnel pressures and transition positions compared with XFOIL | abstract |
| Majid, T. & Jo, B. W. (2021). Comparative aerodynamic performance analysis of camber morphing and conventional airfoils. *Applied Sciences* 11(22), 10663. doi:10.3390/app112210663 | camber morphing against a flap | read (through the project chats) |

## 7. Robust design under transition uncertainty

Designing for a range of transition conditions is established for natural-laminar-flow airfoils, mostly
transonic and with RANS. This project applies the idea to low-speed XFOIL optimisation; it does not
claim the idea.

| Reference | What it does | Content |
|---|---|---|
| Hollom, J. & Qin, N. (2018). Quantification and multi-point optimization of natural laminar flow airfoil robustness to transition amplification factor. AIAA paper 2018-1161. doi:10.2514/6.2018-1161 | robustness of laminar-flow airfoils to the critical N factor, improved by multi-point optimisation | abstract (title) |
| Hollom, J. & Qin, N. (2021). Uncertainty analysis and robust shape optimisation for laminar flow aerofoils. *The Aeronautical Journal* 125(1284), 365–388. doi:10.1017/aer.2020.63 | robust shape optimisation of laminar-flow aerofoils under uncertainty | abstract (title) |
| Zhao, H., Gao, Z., Gao, Y. & Wang, C. (2017). Effective robust design of high lift NLF airfoil under multi-parameter uncertainty. *Aerospace Science and Technology* 68, 530–542. doi:10.1016/j.ast.2017.06.009 | robust design of a high-lift laminar-flow airfoil | abstract (title) |
| Li, J., Gao, Z., Huang, J. & Zhao, K. (2013). Robust design of NLF airfoils. *Chinese Journal of Aeronautics* 26(2), 309–318. doi:10.1016/j.cja.2013.02.007 | robust design of laminar-flow airfoils | abstract (title) |
| Chen, Y. et al. (2023). Adjoint-based robust optimization design of laminar flow airfoil under flight condition uncertainties. *Aerospace Science and Technology* 140, 108465. doi:10.1016/j.ast.2023.108465 | adjoint-based robust design under uncertain flight conditions | abstract (title) |
| Rashad, R. & Zingg, D. W. (2016). Aerodynamic shape optimization for natural laminar flow using a discrete-adjoint approach. *AIAA Journal* 54(11), 3321–3337. doi:10.2514/1.J054940 | laminar-flow optimisation with RANS and transition prediction | abstract (title) |
| Suprayitno, Yu, J. C., Aminnudin & Wulandari, R. (2020). Airfoil aerodynamics optimization under uncertain operating conditions. *J. Phys.: Conf. Ser.* 1446, 012014. doi:10.1088/1742-6596/1446/1/012014 | XFOIL, NACA 0012, PARSEC, Taguchi method: mean and standard deviation of L/D under varying Mach number and angle | abstract |

These entries must be read before they are used for more than the statement that such work exists.

## 8. Documented search (OpenAlex, 4 October 2026)

The search is reproducible: `docs/literature/search_openalex.py` queries the OpenAlex index (open, no
account) for works from 2010 on whose **title or abstract** matches, and writes `queries.csv` and
`candidates.csv`.

| Query | Search string | Hits |
|---|---|---:|
| Q1 | (airfoil OR aerofoil) AND XFOIL AND (optimization OR optimisation) | 329 |
| Q2 | (airfoil OR aerofoil) AND ("shape optimization" OR "shape optimisation") AND ("genetic algorithm" OR "particle swarm" OR "Bayesian optimization") | 190 |
| Q3 | morphing AND (airfoil OR aerofoil) AND (optimization OR optimisation) AND XFOIL | 34 |
| Q4 | (airfoil OR aerofoil) AND (optimization OR optimisation) AND ("curvature constraint" OR "curvature constraints" OR "surface waviness" OR "smoothness constraint") | 2 |
| Q5 | (airfoil OR aerofoil) AND XFOIL AND (RANS OR "Navier-Stokes") AND transition AND (optimization OR optimisation) | 8 |
| Q6 | (airfoil OR aerofoil) AND (robust OR uncertainty) AND ("laminar flow" OR transition) AND (optimization OR optimisation) | 115 |

Together 598 different works; 329 of them name XFOIL (Q1, Q3 or Q5).

**Limits.**
- Scopus and Web of Science need an institutional account and were not searched. The team should run
  the same strings there before the paper is submitted.
- A work whose abstract does not name XFOIL is missed. Pangas & Gamboa (2025) is an example: it uses
  XFOIL through XOPTFOIL and was known from another source.
- Google Scholar was not used (no reproducible query interface).

## 9. What the abstracts mention

`docs/literature/code_abstracts.py` applies keyword rules to the title and abstract of the 238 works of
Q1, Q3 and Q5 that are articles, conference papers, preprints or book chapters and have an abstract in
the index. The shares are lower bounds: an abstract need not mention what the paper does.

| Abstract mentions | Works | Share |
|---|---:|---:|
| genetic or evolutionary algorithm | 88 | 37.0 % |
| particle swarm | 18 | 7.6 % |
| gradient-based or adjoint method | 21 | 8.8 % |
| surrogate, neural network or other learning method | 48 | 20.2 % |
| CST | 30 | 12.6 % |
| PARSEC | 19 | 8.0 % |
| Bézier or spline | 34 | 14.3 % |
| lift-to-drag ratio as a measure | 78 | 32.8 % |
| several design points, off-design or robustness | 47 | 19.7 % |
| transition | 30 | 12.6 % |
| CFD or RANS | 129 | 54.2 % |
| experiment or wind tunnel | 81 | 34.0 % |
| repeated runs, seeds or run statistics | 4 | 1.7 % |
| curvature or smoothness | 13 | 5.5 % |

The matches of the last two rules were read one by one:
- **Repeated runs:** none of the 4 matches is about repeating an optimisation. They concern pressure
  measurements, the spread of L/D over operating conditions, the seed of a neural network, and wind
  statistics. So no abstract of the 238 reports repeated optimisation runs.
- **Curvature or smoothness:** of the 13 matches, 7 concern the smoothness or curvature of the
  optimised shape. Six obtain it from the parameterisation, limit it for manufacturing, or name it as
  a problem. One limits it with a rule: Michael et al. (2026), who reject candidates by the number of
  curvature peaks.

## 10. Full-text audit of how results are reported

**Sample.** All works of Q1, Q3 and Q5 that are open access, articles or conference papers, from 2015
on, with at least 10 citations in OpenAlex on the day of the search: 33 works. Each was opened; the
full text was read where the publisher's page could be read from the browser used. Several publishers
(ScienceDirect, IOP, SAGE, Taylor & Francis) answered with a bot check, and one journal offers only a
PDF, so those works were judged from their abstracts. The table with every work is
`docs/literature/screening.csv`; the counts below are computed from it by `summarise_screening.py`.

| Item | Works |
|---|---:|
| in the sample | 33 |
| in scope: XFOIL evaluates the candidates of a section or morphing-shape optimisation | 18 |
| partly in scope (noise objective, turbine blade, parametric study, XFOIL only as a check) | 4 |
| not in scope or not assessed | 11 |
| in scope and read in full | 8 |
| in scope, judged from the abstract | 10 |

**How the objective is posed (18 works in scope).**

| Objective | Works |
|---|---:|
| at one or several fixed angles of attack | 9 |
| peak over the angle of attack | 2 |
| several conditions combined, or robustness | 2 |
| one condition, not classified further | 1 |
| not stated in the abstract | 4 |

**Other findings.**
- **Repeated runs:** 1 of the 8 works read in full reports several independent optimisation runs
  (Mar Aye et al. 2023: 20 per method). The other 7 show one run per case, or the number of runs was
  not found.
- **Check of the optimum:** 8 of the 18 works check it with RANS and 2 with a wind tunnel (one
  announced). 3 of the 8 works read in full have no check with another flow solver or an experiment.
- **Smoothness:** none of the 8 works read in full limits the smoothness or curvature of the shape
  explicitly; they rely on the parameterisation or on thickness bounds. Pangas & Gamboa (2025), outside
  the sample, do.
- **Transition setting:** in the full texts read, no work re-evaluates its optimum at another Ncrit or
  with tripped boundary layers. This rests on the sentences extracted with keyword filters, so it has
  to be confirmed when the papers are cited.
- **The size of the gain depends on the angle chosen:** Belda & Hyhlík (2024) report +94.7 % at 0° and
  +16.1 % at 6.2° for the same optimised airfoil.

**Limits of the audit.** The sample is small and favours open-access, well-cited works. Ten of the 18
in-scope works were judged from abstracts only. The extraction used keyword filters on the page text,
so a detail that a paper gives in a table or figure can be missed.

## 11. Research gaps

The statements hold for the literature above. They are stronger than before the search, but Scopus and
Web of Science must still be checked.

1. **How much of an XFOIL-optimised gain is real.** Safeguards exist: Xoptfoil2 and XOPTFOIL limit
   curvature and reject drag below a laminar bound (Pangas & Gamboa 2025), and Michael et al. (2026)
   filter by curvature peaks. Adler et al. (2022) and Hoyos et al. (2022) show that the analysis tool
   changes the optimum. Abouzoul et al. (2026) confirm NACA 2412 morphing optima with Transition SST
   within 6 %. We did not find a study that takes one design problem and separates the reported gain
   into its parts: the metric, numerical artefacts, shape artefacts, the transition assumption, and
   what survives in RANS.
   *This project so far:*
   - Smoothness limits cost 3.8 % of peak CL/CD on NACA 2412.
   - The earlier wavy PARSEC design keeps +36 % of its +74 % at Ncrit = 5.
   - **With tripped boundary layers, XFOIL rates all three optimised NACA 2412 designs below the
     original** (best CL/CD 68.3, 70.1 and 53.2 against 72.6; `results/cfd/designs/xfoil.csv`).
   - Physical drag filters removed spurious XFOIL optima such as L/D 836 and 984.
   - CFD: verification done for SST; the design study is running.
2. **Metric choice.** In the audit, 9 of the 14 in-scope works whose objective could be classified pose
   it at fixed angles of attack. At a fixed angle a cambered design gains mostly because it carries
   more lift.
   *This project:* the report's +142.6 % at α = 0° corresponds to +71 % in peak CL/CD for the same airfoil.
3. **Variability of stochastic optimisers.** One of 8 works read in full reports repeated runs, and no
   abstract of 238 mentions them.
   *This project:* the spread over three seeds is ±1.2 to ±9.1 in peak CL/CD (NACA 4412: 158.6–176.9).
4. **Comparing optimisers fairly.** The ranking of GA, particle swarm and Bayesian optimisation depends on
   whether the budget counts all evaluations or only XFOIL analyses. Under smoothness limits, particle
   swarm analysed only 70–85 of its 640 designs. Michael et al. (2026) report the related effect that
   filtering saves 61 % of the solver calls.
5. **Off-design robustness of designs and of morphing.** Multi-point and robust formulations exist
   (section 7; Pangas & Gamboa 2025; Suprayitno et al. 2020), and Abouzoul et al. (2026) evaluate
   performance along the morphing path. What is missing for XFOIL-based single-point optimisation is a
   statement over many airfoils of how much of the gain survives a change of the transition condition.
   *This project:*
   - A fixed multi-point design can beat the morphing path between two phase-optimal shapes at
     intermediate lift.
   - Its advantage can vanish off-design: +43 % at the design point, about +1 % at Ncrit = 5 or
     Re = 2 × 10⁶.

## 12. Tasks that follow from the gaps

| Task | Fills gap | State on 4 October 2026 |
|---|---|---|
| Population study: 30 baseline airfoils, three formulations (peak, fixed angle, fixed lift), with and without curvature limits, three seeds for the peak formulation | 1, 2, 3, 5 | batch of 184 runs started (`MATLAB/Paper/run_population_study.m`) |
| Re-analyse every design of the population at Ncrit 5, 7, 11, at Re 0.5 and 2 million, and with tripped boundary layers; give the share of the gain that survives | 1, 5 | to write (`collect_population_results.m`) |
| Metric translation: the gain of every design under all three metrics, and the gain as a function of the angle at which it is reported | 2 | to write (same script) |
| Robust formulation: optimise the mean or the worst case over Ncrit 5 and 9, and show what survives | 5 | four runs for NACA 2412 are at the start of the population batch |
| Robust formulation against tripping: optimise the mean or the worst case of free transition and transition fixed at 5 % chord. Added because the gains of the single-point designs vanish with tripped boundary layers, while they survive a lower Ncrit | 1, 5 | four runs for NACA 2412 added to the population batch |
| RANS check of the NACA 2412 designs with the free-stream turbulence matched to Ncrit, transition locations compared with XFOIL, and a fully turbulent bound | 1 | verification done; design study queued |
| Reporting checklist | 2, 3 | draft in section 13 |
| Optimise with RANS in the loop to see how the optimum itself moves | 1 | not feasible on the laptop; name as future work |
| Wind-tunnel test of a design | 1 | outside this project; name as a limitation |

## 13. Draft reporting checklist for XFOIL-based airfoil optimisation

1. **Metric and condition.** Say whether the gain is at a fixed angle, at a fixed lift coefficient or
   at the peak, and give absolute values next to percentages.
2. **A second metric.** If the design was optimised at a fixed angle, also give the gain in peak CL/CD
   or at fixed lift.
3. **Transition.** State Ncrit, and re-evaluate the result at a lower Ncrit and with tripped boundary
   layers.
4. **Repeats.** Run a stochastic search with at least three seeds and report the spread.
5. **Shape limits.** State the geometric limits, including smoothness, and show the curvature of the
   result.
6. **Numerical checks.** Analyse the result with a second panelling and reject drag below the laminar
   flat-plate value.
7. **Independent check.** Check the result with a method that models transition (RANS with the
   free-stream turbulence matched to Ncrit) or with an experiment, and report mesh and iterative
   convergence.
8. **Data.** Publish the coordinates, the polars and the settings.

## Still to do for a publishable review

- Run the six search strings in Scopus and Web of Science (institutional access).
- Read the full texts marked "abstract" or "to check", above all section 7 and the audit works behind
  bot checks.
- Extend the audit sample if the paper leans on its counts: with 18 in-scope works they are indicative.
