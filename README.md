# BEV LMDI Decomposition

Logarithmic Mean Divisia Index (LMDI-I) decomposition of battery electric vehicle energy consumption by motor operating regime, validated on two production vehicles across five drive cycles.

**Published in Results in Engineering (Elsevier), 2026.**
DOI: [10.1016/j.rineng.2026.104192](https://doi.org/10.1016/j.rineng.2026.104192)

Authors: Faisal Shah Khan, Thamo Sutharssan
University of East London

---

## Overview

This repository contains the MATLAB/Simulink simulation framework and LMDI analysis pipeline used to produce the results in the published paper. The method decomposes cross-cycle and cross-vehicle energy consumption differences into structural (regime residence) and intensity (per-regime efficiency) terms at the motor operating regime level, with exact zero residual.

Two vehicles are modelled:
- **Tesla Model 3** (2020 LR AWD): 188 kW IPM, gear ratio 9.04, field-weakening onset 117.6 km/h
- **Chevrolet Bolt EV** (2020): 150 kW double-V IPM, gear ratio 7.05, field-weakening onset 88.4 km/h

Five drive cycles are evaluated: UDDS, HWFET, WLTP Class 3b, US06, and Artemis Motorway 130.

---

## Citation

```bibtex
@article{Khan2026LMDI,
  title     = {Decomposition of battery electric vehicle energy consumption by
               operating regime: {LMDI} analysis validated on two production
               vehicles across four drive cycles},
  author    = {Khan, Faisal Shah and Sutharssan, Thamo},
  journal   = {Results in Engineering},
  year      = {2026},
  doi       = {10.1016/j.rineng.2026.104192},
  publisher = {Elsevier}
}
```

---

## Repository structure

```
BEV_LMDI_Paper_B/
├── model/                          Tesla Model 3 Simulink model
│   ├── AE_TeslaM3_LMDI.slx            Simscape vehicle model (v26)
│   ├── AE_TeslaM3_LMDI_Params.m       Vehicle, motor, and simulation parameters
│   ├── onepedal_regen_sfcn.m           Level-2 S-Function: one-pedal regen logic
│   ├── IPMSM_CurrentRef_LUT.mat        d-q current reference lookup table (CRG)
│   ├── TeslaM3_CurrentRefs.mat         CRG-derived current reference grid
│   ├── FW_onset_curve_v2.mat           Torque-dependent FW onset speed curve
│   └── FW_boundary_variants.mat        Boundary method comparison data (B1/B2/B3)
│
├── chevrolet/                      Chevrolet Bolt EV model
│   ├── AE_BoltEV_LMDI.slx             Simscape vehicle model
│   ├── scripts/                        Bolt-specific parameter fitting and run scripts
│   ├── results/                        Bolt simulation outputs (.mat)
│   ├── data/                           Bolt ANL extraction summaries
│   └── BoltEV_Implementation.md        Implementation notes
│
├── scripts/
│   ├── lmdi/                       LMDI analysis pipeline
│   │   ├── AE_run_LMDI.m              Master LMDI runner (single pair)
│   │   ├── AE_run_LMDI_matrix.m       Full cross-cycle decomposition matrix
│   │   ├── AE_lmdi_decomposition.m    LMDI-I additive decomposition
│   │   ├── AE_lmdi_pair.m             Pairwise LMDI computation
│   │   ├── AE_regime_binning.m        MTPA / transition / FW classification
│   │   ├── AE_fold_regimes.m          Transition band folding (<1% threshold)
│   │   ├── AE_loss_decomposition.m    Motor loss breakdown
│   │   ├── AE_cross_vehicle_LMDI.m    Tesla vs Bolt comparison
│   │   ├── AE_gear_design.m           Gear ratio design analysis
│   │   ├── FW_boundary_comparison.m   B1/B2/B3 boundary method sensitivity
│   │   ├── AE_sankey_energy_flow.py   Sankey diagram data generation
│   │   └── AE_Generate_Figures.m      Publication figure generation
│   ├── figures/                    Figure generation scripts (12 figures)
│   ├── gear_sweep/                 Gear ratio parametric run scripts (15 scripts)
│   ├── extraction/                 ANL data extraction
│   │   └── extract_BMS_targets_v2.py  BMS target extraction from ANL CAN data
│   ├── sensitivity/                Sensitivity sweep runner
│   │   └── AE_sensitivity_sweep.m
│   └── validation/                 Validation and postprocessing
│       ├── ANL_Model_Initialization.m  ANL data loader
│       └── v26_BMS_postprocess.m       BMS-level energy validation
│
├── data/
│   ├── anl_tesla/                  ANL dynamometer data, Tesla (not included; see below)
│   ├── anl_bolt/                   ANL dynamometer data, Bolt (not included; see below)
│   └── drive_cycles/               Drive cycle schedule files (.mat)
│
├── results/
│   ├── tesla_g9.04/                Baseline results: Tesla at production gear ratio
│   ├── tesla_g7.0/                 Gear sweep: Tesla at g = 7.0
│   ├── tesla_g11.0/                Gear sweep: Tesla at g = 11.0
│   ├── sensitivity/                Sensitivity analysis results
│   ├── figures/                    Publication figures (PDF and PNG)
│   ├── LMDI_matrix_results.mat             Cross-cycle LMDI decomposition
│   ├── cross_vehicle_LMDI_results.mat      Tesla vs Bolt comparison
│   ├── FW_boundary_comparison.mat          Boundary method sensitivity
│   ├── gear_design_analysis.mat            Gear ratio design implications
│   └── sankey_energy_flow.mat              Energy flow data for Sankey diagrams
│
└── references/                     Motor characterisation references (not included)
```

---

## Validation

All simulations validated against Argonne National Laboratory dynamometer measurements within a 5% acceptance criterion.

| Vehicle | Cycle | Measured (Wh/km) | Simulated (Wh/km) | Error |
|---------|-------|------------------:|-------------------:|------:|
| Tesla | UDDS | 109.0 | 108.1 | -0.8% |
| Tesla | HWFET | 114.4 | 116.9 | +2.2% |
| Tesla | WLTP | 125.6 | 126.6 | +0.8% |
| Tesla | US06 | 150.6 | 148.7 | -1.2% |
| Bolt | UDDS | 101.9 | 105.9 | +3.9% |
| Bolt | HWFET | 125.2 | 127.8 | +2.1% |
| Bolt | US06 | 167.8 | 172.7 | +2.9% |
| Bolt | WLTP | 136.3 | 138.2 | +1.4% |

Tesla RMS error across four cycles: 1.4%. Bolt maximum error: 3.9%.
The Artemis Motorway 130 has no corresponding ANL test for either vehicle.

---

## Key findings

- **Cross-cycle (Tesla, UDDS to US06):** +53.1 Wh/km total difference at motor level; 78% structural. The US06 allocates 36.3% of distance to field weakening, versus 0% on the UDDS.
- **Cross-cycle (Tesla, UDDS to HWFET):** +21.8 Wh/km, 0% structural. Both cycles operate entirely in MTPA at g = 9.04; the full difference is intensity.
- **Cross-vehicle (Tesla vs Bolt, same cycles):** 88-99% structural on HWFET, US06, and WLTP. The Bolt enters field weakening at 88.4 km/h versus 117.6 km/h for the Tesla, despite a lower gear ratio. Motor design parameters dominate gear ratio in determining regime exposure.
- **Gear ratio sweep (g = 7.0 to 11.0, Tesla):** Structural and intensity terms are large and partially offsetting on high-speed cycles. US06: +59.4 structural, -47.8 intensity, net +11.6 Wh/km.
- **Boundary sensitivity:** Five boundary definitions applied to identical data produce structural shares spanning 82 percentage points for the UDDS-to-US06 pair.

---

## Vehicle parameters

| Parameter | Tesla Model 3 | Bolt EV | Unit |
|-----------|:-------------:|:-------:|------|
| Motor type | IPM (d-q model) | Double-V IPM (efficiency map) | -- |
| Peak power | 188 | 150 | kW |
| Peak torque | 353 | 360 | Nm |
| Pole pairs | 3 | 4 | -- |
| PM flux linkage | 0.0772 | 0.1017 | Wb |
| Stator resistance | 4.75 | 6.59 | mOhm |
| L_d | 125 | 254 | uH |
| L_q | 244 | 389 | uH |
| Saliency ratio | 1.95 | 1.53 | -- |
| DC bus voltage | 370 | 350 | V |
| Gear ratio | 9.04 | 7.05 | -- |
| Test mass | 1928 | 1705 | kg |
| FW onset speed | 117.6 | 88.4 | km/h |

Tesla road load (ANL coastdown): F = 162.0 + 0.552v + 0.315v^2 [N], v in m/s.
Bolt road load: F = 126.3 + 2.008v + 0.434v^2 [N], v in m/s.

---

## Data availability

The Argonne National Laboratory dynamometer data used for validation are publicly available from the [ANL D3 database](https://www.anl.gov/taps/d3). The raw data files are not included in this repository due to their size and distribution terms.

- Tesla Model 3: Tests 62005005--62007009 (2020 Tesla Model 3 Long Range AWD)
- Chevrolet Bolt EV: Tests 61910017--61911008 (2020 Chevrolet Bolt EV)

---

## Requirements

- MATLAB R2023b or later
- Simulink with Simscape and Simscape Electrical toolboxes
- Powertrain Blockset (for drive cycle definitions)

---

## Quick start

```matlab
% 1. Set path
cd('/path/to/BEV_LMDI_Paper_B')
addpath(genpath(pwd))

% 2. Open and parameterise the Tesla model
open_system('model/AE_TeslaM3_LMDI')
AE_TeslaM3_LMDI_Params

% 3. Run a simulation (example: US06 at baseline gear ratio)
run('scripts/gear_sweep/v26_run_US06_g7.m')

% 4. Run the full LMDI decomposition matrix
run('scripts/lmdi/AE_run_LMDI_matrix.m')

% 5. Generate publication figures
run('scripts/lmdi/AE_Generate_Figures.m')
```

---

## Licence

This repository is provided for academic reference and reproducibility. Please cite the published paper if you use this work.

---

*Last updated: 30 September 2026*
