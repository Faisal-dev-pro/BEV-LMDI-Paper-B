# Validation Targets — Paper B Master Reference

Single source of truth for checking every simulation in the Paper B matrix.
After each run, validate against the numbers here and record the result in
the Status column. Compiled 5 July 2026 from ANL D3 data (Tesla txt files,
Bolt TDMS and test summary PDF), Paper A PLAN.md, Patel et al. 2025
(teardown), Allca-Pekarovic et al. 2024 (YASA/Bolt), and Liu et al. 2024.

Status codes: PENDING (not yet run), PASS, MARGINAL, FAIL, PROVISIONAL
(target itself needs confirmation before use).

## 1. Global acceptance criteria (every run)

| # | Criterion | Accept | Source | Status |
|---|-----------|--------|--------|--------|
| G1 | Traction (gross) Wh/km error vs ANL-derived | < 5% | Paper A criterion | PENDING |
| G2 | Net Wh/km error vs ANL measured | within +/-10%, target +/-5% | Paper A criterion | PENDING |
| G3 | Distance error vs cycle reference | < 2% | Paper A criterion | PENDING |
| G4 | LMDI residual, all cycle pairs | identically 0 (< 1e-12) | LMDI-I property | PENDING |
| G5 | Energy closure per regime/cycle | < 1% | Paper A criterion | PENDING |
| G6 | Robustness checks (4 checks x cycles) | < +/-5 pp shift | Paper A criterion | PENDING |
| G7 | Gross drift vs v24 baseline (cycling detector) | < +/-2% | v25 design | PENDING |

## 2. Drive cycle reference data

| Cycle | Duration [s] | Distance [km] | Max speed [km/h] | Notes |
|-------|--------------|---------------|------------------|-------|
| UDDS | 1369 | 11.99 (7.45 mi; bag1 5.78, bag2 6.21) | 91.25 | never reaches Tesla FW at g=9.04 |
| HWFET | 765 | 16.51 (10.26 mi) | 96.4 | |
| US06 | 600 | 12.89 (8.01 mi; city 2.88, hwy 10.01) | 129.2 | |
| WLTP Class 3 | 1800 | 23.27 | 131.3 | sub-phases Low/Med/High/ExHigh |
| Artemis MW130 | 1068 | 28.73 | 130 | CSV still to acquire |

## 3. Tesla Model 3 (g = 9.04, v26 model) — ANL BMS-level validation targets

BMS-level (battery terminal) targets from ANL CAN cumulative counters
(BMStotalDriveDischarge, BMStotalRegenCharge). BMS is the primary
validation level because the BIM product reads CAN bus at battery
terminal. Standard temperature tests only (20-26 C). Re-audited 11 Jul
2026 with full temperature verification from test summary column 7.

Temperature classification: strict 20-25 C only. Standard temperature
tests included: 62005005, 62005016, 62005018, 62006001, 62006002,
62006003, 62006032, 62006034, 62006039, 62006040, 62007008.
Non-standard excluded: 62006005 (-5 C), 62006006 (-18 C),
62006009 (-7 C), 62006011 (-18 C), 62006015 (-18 C),
62006017 (-18 C, regen disabled), 62006019 (-18 C),
62006023 (35 C high temp), 62006029 (non-standard protocol).
Full phase-by-phase arithmetic in BMS_Extraction_Audit_Trail.txt.

### 3a. BMS-level targets (primary)

| # | Quantity | Target | Accept (+/-5%) | Source | Status |
|---|----------|--------|----------------|--------|--------|
| T1 | US06 BMS net Wh/km | 150.6 +/- 0.7 | 143-158 | CAN cumulative, 62006003 ph1-7 (n=7, 1 std-temp test, 20-25 C) | PASS — v26 sim 148.7 (-1.2%) |
| T2 | US06 BMS regen fraction | 29.9% | 27-33% | same | PASS — v26 sim 29.4% |
| T3 | US06 BMS gross Wh/km | 214.9 | 204-226 | same | PASS — v26 sim 210.6 (-2.0%) |
| T4 | HWFET BMS net Wh/km | 114.4 +/- 2.3 | 109-120 | CAN cumulative, 12 phases from 8 std-temp tests | PASS — v26 sim 116.8 (+2.1%) |
| T5 | HWFET BMS regen fraction | 11.6% | 8-15% | same | PASS — v26 sim 9.8% |
| T6 | WLTP BMS net Wh/km | 125.6 | 119-132 | CAN cumulative, 62006002 sub-phases 5-8 (n=1 test) | PENDING |
| T7 | WLTP BMS regen fraction | 26.9% | 22-32% | same | PENDING |
| T8 | WLTP Low BMS net Wh/km | 108.9 | +/-10% | 62006002 ph5, 3.09 km | PENDING |
| T9 | WLTP Medium BMS net Wh/km | 103.6 | +/-10% | 62006002 ph6, 4.76 km | PENDING |
| T10 | WLTP High BMS net Wh/km | 114.4 | +/-10% | 62006002 ph7, 7.08 km | PENDING |
| T11 | WLTP ExHigh BMS net Wh/km | 154.2 | +/-10% | 62006002 ph8, 8.28 km | PENDING |
| T12 | UDDS BMS net Wh/km | 109.0 +/- 3.0 (hot start, n=6, 20-25 C) | 104-114 | CAN cumulative, 6 phases from 6 std-temp tests, all t_start > 1200s (62005016, 62005018, 62006001, 62006032, 62006034, 62006040) | LOCKED |
| T12a | UDDS BMS gross Wh/km | 169.6 | +/-5% | same | LOCKED |
| T13 | UDDS BMS regen fraction | 35.7% | 32-40% | same | LOCKED |
| T14 | v26 US06 net after feedforward regen | 143-158 | within T1 accept band | PLAN_AE improvement 5 | PASS — v26 BMS net 148.7; feedforward regen validated |

### 3b. Motor-level WP4 reference (secondary, for LMDI regime attribution)

Motor-level targets are retained for cross-checking LMDI regime
attribution at inverter level. They are not used for pass/fail
validation.

| # | Quantity | WP4 Target | BMS-WP4 Offset | Source |
|---|----------|------------|----------------|--------|
| T1r | US06 WP4 net | 132.5 +/- 7.0 | +18.1 | ANL WP4, 6 tests |
| T4r | HWFET WP4 net | 109.3 | +6.0 | ANL WP4 |
| T6r | WLTP WP4 net | 118.1 | +7.5 | ANL test summary |
| T12r | UDDS WP4 net | 88.9 +/- 2.3 | +20.1 | ANL WP4, 15 hot-start pairs |

BMS-WP4 offset composition: DCDC aux ~4.7, front motor quiescent ~4.2,
cable and contactor I-squared-R losses ~7 Wh/km (load-dependent). The
offset is largest at low average speed (UDDS 20.1) and high current
(US06 18.1), smallest at steady cruise (HWFET 6.0). This is physically
consistent.

US06 individual WP4 tests for reference: 62005024 123.9 (42.6%),
62006024 125.3 (42.1%), 62006025 136.1 (37.0%), 62006026 135.9 (37.1%),
62006027 141.2 (36.3%), 62006028 129.0 (42.1%) Wh/km (regen %).

## 4. Tesla regime boundaries and FW onset (improvement 1 and 3)

| # | Quantity | Value | Source | Status |
|---|----------|-------|--------|--------|
| B1 | omega_base (CRG, k_Vmax=1.10) | 906 rad/s mech | Paper A CRG script | locked |
| B2 | M1 back-EMF limit boundary | 922 rad/s mech (v_FW 119.9 km/h) | PLAN_AE calc | check in FW_boundary_comparison.m |
| B3 | v_FW at g=9.04 | 117.6 km/h (32.7 m/s) | B1 | locked |
| B4 | v_FW at g=7.0 | 152 km/h (42.2 m/s) | PLAN_AE | check in sweep |
| B5 | v_FW at g=11.0 | 96.6 km/h (26.8 m/s) | PLAN_AE | check in sweep |
| B6 | US06 FW distance share, g=9.04 | 31.3% | Paper A result | reference |
| B7 | UDDS FW distance share, g=9.04 | 0% | UDDS max 91.25 < 117.6 km/h | reference |
| B8 | Iron loss anchors (MTPA/mid-FW/deep-FW) | [37, 524, 1729] W | ANL-calibrated, post-processed | locked |

Gear sweep Wh/km expectations (PLAN_AE section 3) are ESTIMATES for
plausibility checking only, not validation targets: UDDS ~90/95/102,
HWFET ~112/119/128, WLTP ~108/117/130, US06 ~118/133/152 at g=7.0/9.04/11.0.

## 5. Chevrolet Bolt EV (g = 7.05) — validation targets

### 5a. ANL net energy targets, PROVISIONAL

Computed from the test summary PDF net Wh per phase divided by nominal bag
distances; phase-to-cycle mapping inferred from energy magnitudes. MUST be
confirmed by TDMS phase segmentation (Drive_Trace_Schedule / Test_active
channels) before use as manuscript numbers. Battery level (Hioki P1), not
inverter level: includes inverter and DCDC/12V loads, unlike Tesla WP4.

Extracted directly from TDMS Exhaust_Bag segmentation (integer bags,
fractional transitions excluded, per-sample integration) on 5 July 2026.
Battery level (Hioki P1). Scripts output: Results/Bolt_619xxxxx_bags.csv.

| # | Quantity | Target | Accept (+/-5%) | Source | Status |
|---|----------|--------|----------------|--------|--------|
| C1 | UDDS net Wh/km | 109.7 +/- 2.5 (107.7, 112.5, 109.0) | 104-115 | TDMS bags, 3 sequences | LOCKED |
| C1a | UDDS regen fraction (battery level) | 31.5% (30.7-32.1) | 28-35% | same | LOCKED |
| C2 | HWY net Wh/km | 124.0 (123.0, 125.1) | 118-130 | TDMS bag 3, 2 tests | LOCKED |
| C3 | US06 net Wh/km | 176.4 (gross 223.0; city bag 193.3, hwy bag 171.6) | 168-185 | 61910021 bags 6+7, n=1 | LOCKED (single test) |
| C3a | US06 regen fraction (battery level) | 20.9% | 18-24% | same | LOCKED (single test) |
| C4 | WLTP net Wh/km | 136.3 (runs 137.1, 135.5); sub-phases Low 104.0, Med 107.7, High 122.0, ExHigh 177.0 | +/-5% each | 61911001, WLTP x2 | LOCKED |
| C4a | WLTP regen fraction | 23.3% | 20-27% | same | LOCKED |
| C5 | Bolt regen strategy note | Battery-level regen fractions are structurally lower than Tesla inverter-level (21% vs 43% on US06); reflects measurement boundary and possibly drive mode. Confirm drive mode from Trans_regen_button_pos_CAN / Veh_drive_mode_CAN before modelling Bolt lift-off decel | | TDMS | OPEN |
| C6 | Regen decel characterisation | from 61911007 (8 phases) | calibrates Bolt lift-off decel rule (Bolt analogue of 0.15g) | TDMS | PENDING |
| C7 | Road load coefficients | F = 126.3 + 2.008v + 0.4336v^2 (lit.) | verify against coastdowns 61911008 | Allca-Pekarovic Table III; ANL | PROVISIONAL |

### 5b. Motor and powertrain anchors (literature, locked)

| # | Quantity | Value | Source | Status |
|---|----------|-------|--------|--------|
| M1 | Pole pairs p | 4 (8 poles) | Patel teardown | locked |
| M2 | psi_m | 0.1078 Wb | derived, Patel FEA back-EMF 140.46 Vrms @ 4400 rpm | locked (FEA-derived) |
| M3 | Rs | 6.59 mOhm DC ~20 C | derived, Patel DC copper loss 3162 W @ 400 Arms | locked (FEA-derived) |
| M4 | Ld, Lq | TBD, fit at cycle-relevant currents (constant params inconsistent at 400 A corner: saturation) | ANL TDMS two-stage fit, see Bolt_Motor_Parameters.md section 4 | OPEN |
| M4a | Ld/Lq fit RMS torque error (fit set) | < 3% (Tesla fit achieved 2.7%) | fit quality gate | PENDING |
| M4b | Ld/Lq holdout RMS error (61910021 + WLTP) | < 4% | cross-validation gate | PENDING |
| M4c | Fitted psi_m vs FEA-derived 0.1078 Wb | within +/-5% | consistency gate | PENDING |
| M4d | LMDI FW-share shift across CRG omega_base uncertainty band | report; claim insulated if < 3 pp | uncertainty propagation gate | PENDING |
| M5 | Gear ratio | 7.05 (2.09 x 3.38) | Patel teardown; GM spec | locked |
| M6 | Peak torque | 360 Nm published / 353 Nm FEA | Momen 2018; Patel | locked |
| M7 | Base (rated) speed | 4400 rpm | Patel | locked |
| M8 | Max speed | 8800-8810 rpm | Patel; Momen 2018 | locked |
| M9 | V_dc nominal | 350 V | Patel | locked |
| M10 | I_max | 400 Arms | Patel | locked |
| M11 | Bolt FW onset road speed | 78.5 km/h (21.8 m/s) at rw=0.328 | derived M2/M9; REVISES PLAN_AE 2b | locked pending CRG calc |
| M12 | Iron loss anchors | 1070 W @ 4400 rpm, 2838 W @ 8800 rpm (Patel Table III; text says 4025, table preferred) | Patel FEA | reference |
| M13 | Motor-only loss per cycle | UDDS 13.4, LA92 15.7, HWFET 8.1, US06 15.0 Wh/km | Allca-Pekarovic Table V (GM map) | reference |
| M14 | Peak motor efficiency | 97.71% @ 4500 rpm, 150 Nm (FEA); WLTP-weighted 94.97% | Patel | reference |
| M15 | Test mass | ~1705 kg (1625 + 80) | Allca-Pekarovic; verify vs ANL record | PROVISIONAL |
| M16 | Wheel radius | 0.32 / 0.323 / 0.328 m conflict | resolve from ANL 215/50R17 spec | OPEN |
| M17 | Gearbox efficiency | 98% | Allca-Pekarovic | reference (Tesla model uses 97%) |
| M18 | Accessory power | 200 W | Allca-Pekarovic | reference |

## 6. v26 regen fix acceptance (BMS-level gates)

| # | Check | Accept | Status |
|---|-------|--------|--------|
| V1 | US06 BMS gross Wh/km | 214.9 +/- 5% (204-226) | PASS — v26 sim 210.6 (-2.0%) |
| V2 | US06 BMS regen fraction | 27-33% (target 29.9%) | PASS — v26 sim 29.4% |
| V3 | US06 BMS net Wh/km | 143-158 (target 150.6) | PASS — v26 sim 148.7 (-1.2%) |
| V4 | No PID/regen chatter | no sustained oscillation in AccelCmd during decel; gross drift < 2% | PASS — feedforward architecture eliminates PID conflict |
| V5 | Lift-off torque magnitude | 102.3 Nm below 76 km/h; power-capped 60 kW above | PASS — v26 uses full feedforward with 60 kW cap |

## 7. Simulation matrix with per-cell validation source (BMS level)

All validation at BMS level (battery terminal, CAN bus). BIM product
reads CAN, so model accuracy at BMS is the binding requirement.

| Config | UDDS | HWFET | US06 | WLTP | Artemis MW130 |
|--------|------|-------|------|------|----------------|
| Tesla g=7.0 | plausibility only | plausibility only | plausibility only | plausibility only | no target |
| Tesla g=9.04 (v26) | T12/T13 PENDING | T4/T5 PASS (BMS 116.8, 9.8%) | T1/T2/T3/T14 PASS (BMS net 148.7, regen 29.4%) | T6/T7 PENDING | no target (report only) |
| Tesla g=11.0 | plausibility only | plausibility only | plausibility only | plausibility only | no target |
| Bolt g=7.05 | C1 | C2 | C3/C5 | C4 | no target |

Off-baseline gear ratios have no measured counterpart; they are validated
indirectly through the g=9.04 anchor plus the locked motor model, and
checked for plausibility against the section 4 estimate table.

## 8. Outstanding actions that convert PROVISIONAL to locked

1. ~~Extract Tesla BMS targets from ANL CAN data for all four cycles.~~
   DONE 12 Jul 2026. Re-audited with strict 20-25C filter.
   US06 150.6 +/- 0.7 (n=7), HWFET 114.4 +/- 2.3 (n=12),
   WLTP 125.6 (n=1), UDDS 109.0 +/- 3.0 (n=6).
   Full audit trail: BMS_Extraction_Audit_Trail.txt.
2. TDMS phase segmentation for Bolt sequences 61910020/21 and WLTP
   61911001 (C1-C4).
3. Bolt coastdown fit from 61911008 (C7) and regen characterisation from
   61911007 (C6).
4. Resolve Bolt wheel radius (M16) and test mass (M15) from ANL records.
5. Fit Ld, Lq (M4), then compute the CRG omega_base for the Bolt and
   replace the M1-based 78.5 km/h with the CRG value (M11).
6. Acquire Artemis Motorway 130 CSV (section 2).
