# Literature and research gaps (working document)

This is the literature basis for a paper on this project. It is **not yet a systematic review**. The
references were found with targeted web searches, by following the references of the project report,
and through the tools used here. A full review should add a documented search in Scopus or Web of
Science (see the last section).

**How the references were checked.**
- The bibliographic data (authors, year, title, journal, volume, pages, DOI) of every entry with a DOI
  were looked up on Crossref on 1 October 2026.
- Reports and books were checked on the NASA Technical Reports Server or the publisher's page.
- The column "content" says how well the statement about the work is supported: **read** (the full
  text was read for this project), **abstract** (only the abstract or the publisher's summary), or
  **to check**. Only statements marked "read" or "abstract" should go into a paper as they stand.

## 1. Analysis tools

| Reference | What it provides | Content |
|---|---|---|
| Drela, M. (1989). XFOIL: an analysis and design system for low Reynolds number airfoils. *Low Reynolds Number Aerodynamics*, Lecture Notes in Engineering 54, Springer, 1–12. doi:10.1007/978-3-642-84010-4_1 | the analysis code used here | read (documentation) |
| Drela, M. & Giles, M. B. (1987). Viscous-inviscid analysis of transonic and low Reynolds number airfoils. *AIAA Journal* 25(10), 1347–1355. doi:10.2514/3.9789 | the boundary-layer formulation behind XFOIL | abstract |
| Mack, L. M. (1977). Transition prediction and linear stability theory. AGARD CP-224 | e^N method; the usual link between Ncrit and free-stream turbulence (Ncrit = −8.43 − 2.4 ln Tu) | to check (cited through XFOIL's documentation) |
| Menter, F. R. (1994). Two-equation eddy-viscosity turbulence models for engineering applications. *AIAA Journal* 32(8), 1598–1605. doi:10.2514/3.12149 | k-ω SST model (CFD) | abstract |
| Langtry, R. B. & Menter, F. R. (2009). Correlation-based transition modeling for unstructured parallelized computational fluid dynamics codes. *AIAA Journal* 47(12), 2894–2906. doi:10.2514/1.42362 | γ–Re_θ transition model (CFD) | abstract |
| Morgado, J., Vizinho, R., Silvestre, M. A. R. & Páscoa, J. C. (2016). XFOIL vs CFD performance predictions for high lift low Reynolds number airfoils. *Aerospace Science and Technology* 52, 207–214. doi:10.1016/j.ast.2016.02.031 | XFOIL compared with RANS for high-lift low-Re airfoils | abstract |
| Adler, E. J., Christison Gray, A. & Martins, J. R. R. A. (2022). To CFD or not to CFD? Comparing RANS and viscous panel methods for airfoil shape optimization. 33rd ICAS Congress, paper ICAS2022_0905 | optimal shapes depend on the analysis tool; modelling transition gives significantly lower-drag designs; "few, if any" earlier studies compared this | abstract |

## 2. Validation data

| Reference | Content |
|---|---|
| Ladson, C. L. (1988). NASA TM-4074 (NACA 0012, Langley LTPT, M 0.05–0.36, Re 2–12 × 10⁶, free and fixed transition) | read; Table I transcribed |
| Abbott, I. H. & von Doenhoff, A. E. (1959). *Theory of Wing Sections*. Dover | data digitised by the NASA TMR |
| Gregory, N. & O'Reilly, C. L. (1970). ARC R&M 3726 | data digitised by the NASA TMR |
| McCroskey, W. J. (1987). A critical assessment of wind tunnel results for the NACA 0012 airfoil. NASA TM-100019 / AGARD CP-429 | lift-slope correlation, through the NASA TMR |
| NASA Langley Turbulence Modeling Resource, 2D NACA 0012 validation case (CFD reference results: CFL3D, FUN3D, NTS) | read (web page) |

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

## 5. Airfoil optimisation studies (comparison and metrics)

| Reference | What it does | Content |
|---|---|---|
| Song, X., Wang, L. & Luo, X. (2022). Airfoil optimization using a machine learning-based optimization algorithm. *J. Phys.: Conf. Ser.* 2217, 012009. doi:10.1088/1742-6596/2217/1/012009 | NACA 0012, CST, XFOIL; objective CL/CD at a fixed α = 1°, gain +220 % | read |
| Khan et al. (2025). Aerodynamic analysis and ANN-based optimization of NACA airfoils for enhanced UAV performance. *Scientific Reports* 15. doi:10.1038/s41598-025-95848-4 | NACA airfoils incl. 2412; CFD, XFOIL and an ANN–GA model | to check |
| Pangas et al. (2025). Low-speed airfoil optimization for improved off-design performance. *Aerospace* 12(8), 685. doi:10.3390/aerospace12080685 | off-design and multi-point formulation, transition | to check |
| Ribeiro, A. F. P., Awruch, A. M. & Gomes, H. M. (2012). An airfoil optimization technique for wind turbines. *Applied Mathematical Modelling* 36(10), 4898–4907. doi:10.1016/j.apm.2011.12.026 | airfoil optimisation for wind turbines | to check |
| El Houd, A. & Hallou, Y. (2019). Optimization study of NACA airfoil using nonlinear programming & genetic algorithms. Project report, ENSAM Meknès (code on GitHub) | reference study of the project report; NACA 2412, PARSEC, area objective | read |

## 6. Morphing

| Reference | What it does | Content |
|---|---|---|
| Barbarino, S., Bilgen, O., Ajaj, R. M., Friswell, M. I. & Inman, D. J. (2011). A review of morphing aircraft. *Journal of Intelligent Material Systems and Structures* 22(9), 823–877. doi:10.1177/1045389X11414084 | review | abstract |
| Secanell, M., Suleman, A. & Gamboa, P. (2006). Design of a morphing airfoil using aerodynamic shape optimization. *AIAA Journal* 44(7), 1550–1562. doi:10.2514/1.18109 | separate optimal shapes for six UAV flight conditions (RANS, SQP) | abstract |
| Bashir, M., Longtin-Martel, S., Botez, R. M. & Wong, T. (2021). Aerodynamic design optimization of a morphing leading edge and trailing edge airfoil – application on the UAS-S45. *Applied Sciences* 11(4), 1664. doi:10.3390/app11041664 | nose and trailing-edge morphing, PSO + pattern search, XFOIL + Fluent (transition SST) | read |
| Majid, T. & Jo, B. W. (2021). Comparative aerodynamic performance analysis of camber morphing and conventional airfoils. *Applied Sciences* 11(22), 10663. doi:10.3390/app112210663 | camber morphing against a flap | read (through the project chats) |

## Research gaps

The statements below hold for the literature listed above. A systematic search must confirm them before
they appear in a paper.

1. **How much of an XFOIL-optimised gain is real.** Optimisers exploit numerical and shape artefacts;
   Xoptfoil2 limits curvature for this reason. Adler et al. (2022) show that the analysis tool changes
   the optimum. We did not find a study that takes one design problem and separates the reported gain
   into its parts: the metric, numerical artefacts (panelling, spurious convergence), shape artefacts
   (curvature) and what survives in RANS with a transition model.
   *This project so far:*
   - Smoothness limits cost 3.8 % of peak CL/CD on NACA 2412.
   - The earlier wavy PARSEC design keeps +36 % of its +74 % at Ncrit = 5.
   - Physical drag filters removed spurious XFOIL optima such as L/D 836 and 984.
   - Two-panelling scoring prevents optima that appear with only one panelling.
   - CFD is in progress.
2. **Metric choice.** Gains are often reported at a fixed angle of attack: Song et al. (2022) at 1°, and
   the project report at 0°. At fixed angle a cambered design gains mostly because it carries more lift.
   Peak CL/CD or CL/CD at a fixed CL is the relevant comparison for a wing flying at a given weight.
   *This project:* the report's +142.6 % at α = 0° corresponds to +71 % in peak CL/CD for the same airfoil.
3. **Variability of stochastic optimisers.** Studies usually report a single run.
   *This project:* the spread over three seeds is ±1.2 to ±9.1 in peak CL/CD (NACA 4412: 158.6–176.9).
4. **Comparing optimisers fairly.** The ranking of GA, particle swarm and Bayesian optimisation depends on
   whether the budget counts all evaluations or only XFOIL analyses. Under smoothness limits, particle
   swarm analysed only 70–85 of its 640 designs.
5. **Off-design robustness of designs and of morphing.** Morphing studies optimise one shape per flight
   condition (Secanell et al. 2006; Bashir et al. 2021).
   *This project:*
   - A fixed multi-point design can beat the morphing path between two phase-optimal shapes at
     intermediate lift.
   - Its advantage can vanish off-design: +43 % at the design point, about +1 % at Ncrit = 5 or
     Re = 2 × 10⁶.

## Still to do for a publishable review

- A documented search in Scopus, Web of Science and Google Scholar, recording the query strings, dates
  and numbers of hits. Candidate queries: "airfoil shape optimization" AND XFOIL; "airfoil optimization"
  AND (genetic OR "particle swarm" OR Bayesian); "morphing airfoil" AND optimization; "airfoil" AND
  "curvature constraint".
- Reading the full texts marked "abstract" or "to check".
- Checking how recent XFOIL-based optimisation papers report their gains (metric, number of runs,
  validation), to support gaps 2 to 4 with numbers.
