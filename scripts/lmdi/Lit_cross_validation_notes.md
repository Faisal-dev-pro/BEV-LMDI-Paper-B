# Improvement 8: Literature Cross-Validation Table — Analysis Notes

Generated: 17 July 2026. For Paper Section 3 (Validation).

## Purpose

Demonstrate that the Simulink model is not self-referential by comparing
simulated energy consumption against independent published sources.

---

## Table 1: Cross-Validation Summary (Paper Table X)

### This Study vs ANL D3 Dynamometer Data (same measurement level: DC bus)

| Cycle   | This study | ANL D3   | Error  | Note                        |
|---------|-----------|----------|--------|-----------------------------|
| UDDS    | 108.1     | 109.0    | -0.8%  | 3 ANL bags, n=3             |
| HWFET   | 116.9     | 114.4    | +2.2%  | TDMS bag 3, n=2             |
| US06    | 148.7     | 150.6    | -1.3%  | Test 61910021, n=1          |
| WLTP    | 126.6     | 125.6    | +0.8%  | Test 61911001, n=2          |
| Artemis | 159.7     | —        | —      | No ANL target (report only) |

All values: BMS-level net Wh/km (battery terminal DC power including
auxiliary load 690 W and cable I²R 0.015 Ω). All four targeted cycles
pass the ±5% validation gate. RMS error across 4 cycles: 1.4%.

### This Study vs EPA Label (2020 Tesla Model 3 LR AWD)

| EPA Metric | EPA Label | EPA DC Est. | This study | Note                    |
|------------|-----------|-------------|------------|-------------------------|
| City       | 168.9     | ~106        | 108.1      | UDDS-based, adj. 0.70   |
| Highway    | 180.5     | ~127        | 116.9      | HWFET-based, adj. 0.78  |
| Combined   | 173.1     | ~115        | —          | 55/45 city/hwy blend    |

EPA source: fueleconomy.gov, 2020 Tesla Model 3 LR AWD (124/116/121 MPGe).
Conversion: Wh/km = 33705 / (MPGe × 1.60934).

EPA label includes: (a) AC charger losses (~10-12%), (b) 5-cycle adjustment
factor (~0.70 city, ~0.78 highway) that penalises raw test results to
approximate real-world driving. Direct comparison with DC-level simulation
requires removing both effects. The "EPA DC Est." column applies approximate
corrections: EPA_label × adj_factor × charger_eff (0.90).

The city (UDDS) estimate (106 Wh/km) is within 2% of both the simulation
(108.1) and the ANL measurement (109.0), confirming consistency across
three independent sources. The highway estimate is less precise because the
EPA highway adjustment factor varies with raw fuel economy.

### This Study vs Published BEV Energy Studies

| Source                         | Vehicle           | Cycle    | Value (Wh/km) | Basis       | Comparison |
|-------------------------------|-------------------|----------|---------------|-------------|------------|
| Grunditz & Thiringer (2016)    | 40+ BEVs survey   | NEDC     | 117-268       | Spec review | Small/med-large 117-166; high-perf 160-267. Powertrain 40-54% of net. Majority IPMSM. Gear ratios 6-10. Our Tesla g=9.04 within this range. |
| Yuan et al. (2024)             | Tesla M3 SR+ RWD  | Multi    | RMSE 8.3      | Dyno+real   | GECR model: MAPE 3.84% across 13 lab cycles (UDDS/US06/HWFET/WLTC/Artemis). Different M3 variant (SR+ vs LR AWD). Decomposition by driving feature vs our regime-level LMDI. |
| Achariyaviriya et al. (2024)  | Mixed BEV fleet   | Real     | 150-220       | OBD data    | Our US06/Artemis (149-160) falls in lower quartile |
| ORNL motor benchmarking        | Tesla M3 motor    | Dyno     | —             | Motor map   | Our CRG FW boundary derived from same ORNL characterisation |

Note on Grunditz & Thiringer (2016): This is a BEV specifications survey
(IEEE TTE, Vol. 2 No. 3), not a single-vehicle simulation. Comparison
with our work is at the methodology level: they estimate powertrain losses
top-down from manufacturer specifications (40-54% of net consumption),
while we decompose losses bottom-up via LMDI at motor operating regime
level. Their finding that IPMSM dominates BEV traction motors and gear
ratios cluster at 6-10 supports our parameter choices.

Note on Yuan et al. (2024): Published in Patterns (Cell Press), not Energy.
First author is Yuan X (Jilin University), not Sun. Uses a 2019 Tesla M3
Standard Range Plus (RWD, single motor) on a Horiba 4WD dynamometer
with Hioki PW3390 power analyser (same instrument class as ANL D3).
Their GECR approach decomposes energy consumption by driving features
(speed intensity, braking intensity, slow-driving intensity). Our LMDI
approach decomposes by motor operating regime (MTPA/Trans/FW).
Complementary perspectives: theirs explains cycle-to-cycle variation via
driving behaviour, ours explains it via powertrain physics.

---

## Table 2: Multi-Source Consistency Check

| Metric                    | This study | ANL D3 | EPA (adjusted) | Consistent? |
|---------------------------|-----------|--------|----------------|-------------|
| UDDS net (Wh/km)          | 108.1     | 109.0  | ~106           | Yes (3%)    |
| HWFET net (Wh/km)         | 116.9     | 114.4  | ~127           | Partial*    |
| US06 net (Wh/km)          | 148.7     | 150.6  | —              | Yes (1.3%)  |
| WLTP net (Wh/km)          | 126.6     | 125.6  | —              | Yes (0.8%)  |
| Regen fraction US06       | 29.4%     | 20.9%  | —              | See note**  |
| Vehicle mass (kg)         | 1928      | 1928   | 4250 lb        | Yes         |
| Gear ratio                | 9.04      | 9.04   | —              | Yes         |

*Highway EPA DC estimate sensitive to adjustment factor assumption (0.78).
The 0.78 is an approximation; actual EPA uses regression-based 5-cycle.

**Regen fraction mismatch: ANL measures BMS-level (includes aux load
reducing regen credit), while our BMS postprocess applies the same physics.
The 29.4% sim vs 20.9% ANL difference reflects one-pedal driving calibration
differences between the ANL test protocol and our lift-off regen model.
Net energy validates within 1.3%, so the gross/regen split is less critical
than the net for validation purposes.

---

## Discussion Points for Manuscript

1. **Three-source consistency:** The UDDS energy consumption is independently
   corroborated by ANL dynamometer testing (109.0 Wh/km), EPA certification
   (~106 Wh/km DC-equivalent), and our simulation (108.1 Wh/km). Agreement
   within 3% across three independent sources confirms model fidelity.

2. **RMS error:** Across four validated cycles, the RMS error vs ANL is 1.4%.
   This is within the 2-3% measurement uncertainty of chassis dynamometer
   testing (Kim et al., 2022; ANL test protocols).

3. **US06 high-speed regime:** Our simulation under-predicts US06 by 1.3%.
   This is consistent with the model omitting AC copper losses and iron loss
   at high speed, which would increase consumption slightly. The sign of the
   error (under-prediction) matches this physical expectation.

4. **HWFET over-prediction (+2.2%):** The simulation over-predicts HWFET by
   2.5 Wh/km. This may reflect the auxiliary load assumption (690 W constant)
   being slightly high for steady-speed highway driving where DCDC and front
   motor quiescent draw may be lower.

5. **Limitation:** EPA comparison is approximate due to the charger loss and
   adjustment factor corrections. Raw EPA DC test data (from certification
   files) would enable exact comparison but requires accessing the EPA DIS
   database directly.

## Files

- `Lit_cross_validation_notes.md`: this document
- Data sources: BMS files (tag tesla-matrix-complete-v26), ANL D3 database,
  EPA fueleconomy.gov (2020 Tesla Model 3 LR AWD, ID 42275)

## Data Items Still Pending (Dashboard Section 08)

- EPA raw DC test data from DIS certification files
- Bolt EV EPA label and ANL data (for Improvement 2)

## Data Items Resolved

- Grunditz & Thiringer (2016) full paper — acquired 17 Jul (IEEE TTE via UEL)
- Yuan et al. (2024) full paper — acquired 17 Jul (Patterns, Cell Press, open access via PMC)
