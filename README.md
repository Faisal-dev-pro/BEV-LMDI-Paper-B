# BEV LMDI Decomposition — Paper B (Applied Energy)

Multi-vehicle LMDI-I decomposition of BEV energy consumption at motor operating regime level (MTPA vs field weakening). Extends Paper A (ECM:X, ECMX-D-26-01632) with gear ratio parametric sweep, Chevrolet Bolt EV cross-vehicle comparison, and CRG-derived field-weakening boundary validation.

Target journal: Applied Energy (IF ~11, Elsevier).

Authors: Faisal Shah Khan, Thas Sutharssan. University of East London.

---

## Project structure

```
BEV_LMDI_Paper_B/
├── model/                      Simulink model and motor parameters
│   ├── AE_TeslaM3_LMDI.slx        v26 Simulink model
│   ├── AE_TeslaM3_LMDI_Params.m   Motor, vehicle, and simulation parameters
│   ├── onepedal_regen_sfcn.m       Level-2 S-Function for one-pedal regen
│   ├── AE_v25_Run.m                Legacy run script (v25)
│   ├── FW_onset_curve.mat          Field-weakening onset vs speed
│   ├── IPMSM_CurrentRef_LUT.mat    d-q current reference lookup table
│   └── TeslaM3_CurrentRefs.mat     CRG-derived current reference grid
│
├── scripts/
│   ├── lmdi/                   LMDI analysis pipeline
│   │   ├── AE_run_LMDI.m          Master LMDI analysis runner
│   │   ├── AE_lmdi_decomposition.m LMDI-I additive decomposition
│   │   ├── AE_regime_binning.m     MTPA/FW regime classification
│   │   ├── AE_loss_decomposition.m Motor loss breakdown
│   │   └── AE_Generate_Figures.m   Publication figure generation
│   ├── validation/             BMS validation and postprocessing
│   │   ├── ANL_Model_Initialization.m  ANL data loader and target extraction
│   │   ├── v26_BMS_postprocess.m       BMS-level energy validation gates
│   │   └── v26_restore_regen.m         Regen fraction restoration
│   ├── gear_sweep/             Gear ratio parametric run scripts (12 total)
│   │   ├── v26_run_UDDS.m, _g7.m, _g11.m
│   │   ├── v26_run_US06_g7.m, _g11.m
│   │   ├── v26_run_WLTP.m, _g7.m, _g11.m
│   │   ├── v26_run_Artemis_MW130_g7.m, _g11.m
│   │   └── v26_run_HWFET_g7.m, _g11.m
│   └── extraction/             Data extraction utilities
│       └── extract_BMS_targets_v2.py   ANL CAN bus BMS target extraction
│
├── data/
│   ├── anl_tesla/              ANL dynamometer data (2020 Tesla Model 3)
│   │   ├── extended_datasets/      63 test files (62005005-62007009)
│   │   ├── dc_fast_charging/       27 DCFC test files
│   │   └── on_road_tests/          82 on-road test subdirectories
│   ├── anl_bolt/               ANL data (2019 Chevrolet Bolt EV)
│   │   ├── 15 TDMS files (61910017-61911008)
│   │   └── Test summary PDF
│   └── drive_cycles/           Drive cycle schedule files
│       ├── UDDS_schedule.mat
│       └── WLTP_Class3b_schedule.mat
│
├── results/
│   ├── tesla_g9.04/            Baseline BMS validation results (15 .mat)
│   ├── tesla_g7.0/             Gear sweep g=7.0 results (6 .mat)
│   ├── tesla_g11.0/            Gear sweep g=11.0 results (4 .mat)
│   └── extraction/             ANL CAN bus extraction CSVs
│
├── manuscript/                 Paper A submission files
│   ├── Khan_Sutharssan_ECMX_2026_LMDI_BEV_Manuscript_v26.tex
│   ├── Khan_Sutharssan_ECMX_2026.docx
│   ├── Khan_Sutharssan_ECMX_2026_marked.docx
│   ├── Khan_Sutharssan_ECMX_2026_v26.docx
│   └── Highlights.docx
│
├── figures/                    Generated publication figures (empty)
│
├── references/                 Reference material
│   ├── 3 Bolt motor characterisation PDFs
│   ├── PaperB_References.md
│   ├── References_AE_2023_2025.md
│   └── Bolt_Motor_Parameters.md
│
├── dashboard/                  Project tracking dashboards
│   ├── PaperB_Dashboard.html
│   ├── paper_dashboard.html
│   └── PaperA_Resubmission_Plan.html
│
└── docs/                       Planning and audit documents
    ├── PLAN_AE.md                  Paper B roadmap
    ├── Validation_Targets.md       BMS-level ANL validation gates
    ├── AUDIT_v26_presubmission.md  Pre-submission audit trail
    ├── AE_Positioning.md           Applied Energy positioning notes
    ├── BMS_Extraction_Audit_Trail.txt
    └── ANL_energy_forensics.md     Energy balance forensics
```

---

## Simulation matrix (Paper B core)

20 runs: 4 configurations x 5 drive cycles.

| Config | UDDS | HWFET | US06 | WLTP | Artemis MW130 |
|--------|------|-------|------|------|---------------|
| Tesla g=7.0 | 105.3 | -- | 143.3 | 122.2 | pending |
| Tesla g=9.04 | 110.6 | 122.3* | 148.7 | 126.6 | 154.0 |
| Tesla g=11.0 | 110.6 | -- | 155.1 | 131.5 | -- |
| Bolt EV g=7.05 | -- | -- | -- | -- | -- |

Values are BMS net Wh/km. *HWFET fails validation (+6.9%), deferred to split-authority driver.

---

## Key finding

UDDS g=11.0 = UDDS g=9.04 = 110.6 Wh/km. UDDS max speed (91 km/h) is below FW onset at both gear ratios (117.6 km/h at g=9.04, 96.7 km/h at g=11.0). Zero FW means zero structural energy penalty. This is the structural contrast anchor for Paper B. On US06, the same gear ratio change produces +6.4 Wh/km because 69.2% of distance is in field weakening.

---

## Motor parameters (2020 Tesla Model 3 RWD)

| Parameter | Value | Unit | Source |
|-----------|-------|------|--------|
| R_s | 0.00475 | Ohm | MotorXP teardown 2020 |
| psi_m | 0.07719 | Wb | Back-EMF (42 V / 1 kRPM) |
| L_d | 0.000125 | H | ANL parameter fit (2.7% RMS) |
| L_q | 0.000244 | H | ANL parameter fit (2.7% RMS) |
| Pole pairs (p) | 3 | -- | MotorXP teardown |
| k_Vmax | 1.10 | -- | CRG script |
| P_max | 188 | kW | ANL D3 test record |
| omega_base (CRG) | 906 | rad/s | CRG-derived (8651 RPM) |

Road load (ANL coastdown 62005005): F = 162.0 + 0.552v + 0.315v^2 [N], v in m/s.

---

## Validation targets (BMS net Wh/km, ANL CAN, 20-25C)

| Cycle | Target | Source |
|-------|--------|--------|
| US06 | 150.6 | ANL CAN cumulative counters |
| HWFET | 114.4 | ANL CAN cumulative counters |
| WLTP | 125.6 | ANL CAN cumulative counters |
| UDDS | 109.0 | ANL CAN cumulative counters |

---

## Setup

```bash
# 1. Complete ANL data copy (large files not transferred by setup)
cd /Users/fsk/Documents/MATLAB/BEV_LMDI_Paper_B
bash complete_anl_data.sh
```

```matlab
% 2. Open MATLAB, set path
cd('/Users/fsk/Documents/MATLAB/BEV_LMDI_Paper_B')
addpath(genpath(pwd))

% 3. Open model
open_system('model/AE_TeslaM3_LMDI')

% 4. Load parameters
AE_TeslaM3_LMDI_Params

% 5. Run gear sweep (example: US06 at g=7.0)
run('scripts/gear_sweep/v26_run_US06_g7.m')
```

---

*Last updated: 14 July 2026*
