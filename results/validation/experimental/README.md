# Wind-tunnel data for the validation of the XFOIL analysis (NACA 0012)

| File | Content | Source |
|---|---|---|
| `Ladson1988_TableI_M015_free.csv` | α, c_d, c_l, c_m and the printed l/d at M = 0.15, **free transition**, Re = 2.00, 3.94 and 5.97 × 10⁶ | Ladson (1988), Table I, p. 6. Transcribed by hand for this project from the page images of the report. |
| `CLCD_Ladson_expdata.dat` | α, c_l, c_d at M = 0.15, Re = 6 × 10⁶, **transition fixed** with No. 80, 120 and 180 grit | Ladson (1988), via the NASA Turbulence Modeling Resource (TMR) |
| `0012.abbottdata.cl.dat`, `0012.abbottdata.cd.dat` | c_l(α) and c_d(c_l), Re = 6 × 10⁶, free transition. The TMR file header says the digitising is "only approximate, due to poor quality of plot in the book". | Abbott & von Doenhoff (1959), digitised by the TMR |
| `CL_Gregory_expdata.dat` | c_l(α), Re = 3 × 10⁶, transition tripped (digitised, "only approximate") | Gregory & O'Reilly (1970), digitised by the TMR |
| `0012.mccroskeydata.cl.dat` | best-fit lift curve at Re = 6 × 10⁶, M = 0.15; the header gives the correlation dc_l/dα = (0.1025 + 0.00485 log₁₀(Re/10⁶)) / √(1 − M²) per degree | McCroskey (1988), via the TMR |

The TMR files were downloaded on 29 September 2026 from
<https://tmbwg.github.io/turbmodels/NACA0012_validation/> (the NASA Langley Turbulence Modeling Resource,
formerly <https://turbmodels.larc.nasa.gov/naca0012_val.html>) and are unchanged.

**Check of the transcription.** Every row of `Ladson1988_TableI_M015_free.csv` with a drag value was checked
against the l/d column printed in the report: c_l/c_d agrees with it to within 0.04 (rounding of the printed
coefficients); all 44 rows were also compared with a high-resolution image of the page.

**Test details from Ladson (1988)** (p. 2-3): Langley Low-Turbulence Pressure Tunnel; model chord 23.66 in
(60.10 cm), span 36.00 in; ordinates within 0.0002c of the design ordinates; for the fixed-transition runs,
carborundum strips about 0.01c wide at 0.05c on both surfaces, grit size chosen for each Reynolds number.
The report does not state the trailing-edge thickness of the model.

## References

- Ladson, C. L. (1988). *Effects of independent variation of Mach and Reynolds numbers on the low-speed
  aerodynamic characteristics of the NACA 0012 airfoil section.* NASA TM-4074.
  <https://ntrs.nasa.gov/citations/19880019495>
- Abbott, I. H. & von Doenhoff, A. E. (1959). *Theory of Wing Sections.* Dover.
- Gregory, N. & O'Reilly, C. L. (1970). *Low-speed aerodynamic characteristics of NACA 0012 aerofoil section,
  including the effects of upper-surface roughness simulating hoar frost.* ARC R&M 3726.
- McCroskey, W. J. (1988). A critical assessment of wind tunnel results for the NACA 0012 airfoil. AGARD CP-429.
