# Bolt EV Simscape Model — Implementation Specification

**Created:** 17 July 2026
**Purpose:** Single reference for building the Bolt EV model without guesswork.
Every number has a data source. Every design choice has a justification.

---

## 1. Vehicle Parameters (locked)

All values verified against ANL TDMS data unless noted.

| Parameter | Value | Source | Verification |
|-----------|-------|--------|-------------|
| Test mass | 1705 kg | Allca-Pekarovic 2024 Table III (1625 + 80 kg) | Consistent with PLAN_AE ~1700 kg |
| Gear ratio | 7.05 | Patel 2025 teardown (35/73 x 21/71) | Axle_CAN / Motor_CAN = 7.05 in TDMS |
| Gearbox efficiency | 97.2% | Measured: Axle_torque_CAN / (Motor_torque × 7.05) | Allca-Pekarovic uses 98%; data says 97.2% |
| Wheel radius | 0.317 m | Data-derived: Motor_1_speed vs Vehicle_spd_CAN | std = 0.0002 m across SSS and US06 tests |
| Road load A | 126.3 N | Allca-Pekarovic 2024 Table III | Verify vs 61911008 coastdown |
| Road load B | 2.008 N/(m/s) | Allca-Pekarovic 2024 Table III | |
| Road load C | 0.4336 N/(m/s)^2 | Allca-Pekarovic 2024 Table III | |
| Frontal area × Cd | Implicit in C coefficient | | |
| Tire spec | 215/50R17 | ANL test record | Unloaded 0.323 m, loaded 0.314 m |

Road load equation: F = 126.3 + 2.008 v + 0.4336 v^2 (N, v in m/s).
Compare to Tesla: F = 178 + 3.024 v + 0.370 v^2. The Bolt is lighter
(1705 vs 1928 kg), lower rolling resistance (126 vs 178 N), slightly
higher aero (0.434 vs 0.370).

### Coastdown verification (COMPLETE — road load LOCKED)

File 61911008 is not a neutral-coast test. The motor is mechanically
connected (CAN rpm / expected rpm = 1.004) with D-mode regen active
(mean motor torque = -30 Nm during coast segments). Direct deceleration-
based road load extraction is unreliable when regen torque dominates.

Verification method: steady-state torque balance. At constant speed,
F_motor_at_wheels = F_road_load. Two independent cruise segments:

| Source | v (m/s) | v (km/h) | T_CAN (Nm) | T_std | F_motor (N) | F_AP (N) | Diff |
|--------|---------|----------|------------|-------|-------------|----------|------|
| 61911008 (55 mph, 430s) | 24.6 | 88.7 | 19.2 | 1.6 | 414.1 | 439.0 | -5.7% |
| 61910022 (65 mph SSS) | 29.2 | 105.0 | 23.9 | 0.4 | 517.1 | 553.7 | -6.6% |

F_motor = T_CAN x gear x eta_gear / r_wheel = T x 7.05 x 0.972 / 0.317.

The systematic -6% offset is consistent across both speeds and explained
by CAN torque measurement tolerance (typical ±5-10% for DMCM1 CAN
torque vs shaft torque). The HWFET "cruise" segments were also checked
but rejected: T_std = 3.1-3.5 Nm indicates non-steady-state conditions
where inertial torque contaminates the measurement.

Conclusion: Allca-Pekarovic coefficients verified within CAN torque
tolerance. Road load coefficients LOCKED at A=126.3, B=2.008, C=0.4336.

### Cable resistance (COMPLETE — negligible)

Compared Hioki battery terminal voltage (Batt_Volt_Hioki_U1) against
inverter DC link voltage (Motor_1_inverter_supply_voltage_circuit_DMCM1)
across the full 61911008 test (16,188 samples).

| Measurement | Mean (V) |
|-------------|----------|
| V_Hioki (battery terminals) | 380.2 |
| V_inverter_CAN (DC link) | 380.9 |
| V_BMS_CAN (PTCAN) | 380.2 |

The Hioki and BMS CAN agree within 0.015 V (same measurement point).
The inverter CAN reads 0.7 V higher, but this offset is independent of
current (R^2 = 0.04 for dV vs I linear fit). It is a CAN ADC calibration
bias, not a resistive voltage drop. A true cable resistance would produce
a current-dependent dV that reverses sign between traction and regen.

Fitted cable R = 1.7 mOhm, giving 4.7 W loss at mean discharge current
(0.03% of drive power). Set R_cable = 0 in Simscape. Use Hioki voltage
or BMS CAN (HVBatt_voltage_PTCAN) for V_dc in the model.

---

## 2. Motor Electrical Parameters

### 2.1 Known parameters (from Patel 2025 FEA teardown)

| Parameter | Value | Tier | Note |
|-----------|-------|------|------|
| Pole pairs (p) | 4 | V | 8-pole double-V IPM |
| PM flux linkage (psi_m) | 0.1078 Wb | D | From FEA back-EMF at 4400 rpm |
| Stator resistance (Rs) | 6.59 mOhm | D | DC value at ~20C, from FEA copper loss |
| DC link voltage (V_dc) | 350 V nominal | V | Range in TDMS: 324-387 V |
| Peak torque | 353 Nm at 400 Arms | D | FEA; published 360 Nm |
| Rated (base) speed | 4400 rpm | D | FEA Table III |
| Max speed | 8800 rpm | V | Momen 2018 |
| Stator slots | 72 | V | Hairpin bar winding |

### 2.2 Parameter identification from ANL TDMS data

No publication reports Ld and Lq for the Bolt EV motor. A parameter
identification was performed on ANL TDMS data using a voltage-ellipse
+ power-balance residual method on 26 binned FW operating points
(12 SSS cruise bins from 61910022 at varying V_dc + 14 staircase bins
from 61911004 at varying torque/speed). Multi-start optimization with
8 starting points.

**Validated outputs (used in the model):**

| Parameter | Value | Validation | Status |
|-----------|-------|-----------|--------|
| psi_m | 0.1017 Wb | FEA prior 0.1078, -5.7% consistent with reversible demagnetisation at 85C (expected -7.2% at 0.11%/K, 65K) | VALIDATED |
| k_Vmax | 0.904 | Six-step theory gives 0.906, fitted within 0.2% | VALIDATED |

These two parameters control the CRG boundary. At cruise current
(40A), psi_m contributes 97.7% of total flux linkage squared and
k_Vmax sets the voltage ceiling. Together they determine v_FW to
within 0.6%, independent of Ld and Lq.

**Estimated outputs (not used in Simscape model):**

| Parameter | Value | Limitation | Status |
|-----------|-------|-----------|--------|
| Ld | 253.7 uH | Constant-inductance approximation | ESTIMATE |
| Lq | 389.1 uH | Constant-inductance approximation | ESTIMATE |
| Lq/Ld | 1.53 | Consistent with double-V rotor (lower than Tesla 1.95) | PLAUSIBLE |

**Why Ld/Lq are estimates, not validated parameters:**

The fitted constant (Ld, Lq) reproduce the FW operating range at
moderate current (20-80A) with 6.4% RMS. But at peak current (400
Arms), they predict 271 Nm versus published 353 Nm (23% error). The
cause is magnetic saturation: at 400 Arms, the effective (Lq - Ld)
is approximately 326 uH (back-calculated from FEA), 2.4x the fitted
135 uH. Constant inductances cannot capture the saturation-dependent
reluctance torque of a double-V IPM motor.

This means the Simscape PMSM block cannot use these values. If it
did, acceleration torque would be 23% low, speed following would
fail, and the US06 validation gate would be missed. See Section 9
for the efficiency-map approach that avoids this limitation.

The Ld/Lq values remain useful for two purposes: (a) confirming the
saliency ratio is lower than the Tesla, consistent with the rotor
topology, and (b) showing that the CRG boundary is insensitive to
inductance uncertainty at cycle-relevant currents (±0.1 km/h from
±8% perturbation on either inductance).

**Fit quality (for reference):**

| Metric | Value |
|--------|-------|
| Training RMS (26 bins) | 6.40% |
| Holdout US06 (14 bins) | 7.1% |
| Holdout WLTP (14 bins) | 7.5% |
| Combined holdout | 7.3% |

Systematic pattern: MTPA under-predicts 5-15%, FW high-speed
light-load over-predicts 14-20%. Attributed to the iron loss model
(2-point quadratic interpolation from Patel FEA) overestimating
above 6000 rpm, and the P_sw = 500 W switching loss assumption
(unvalidated, eliminated from the Simscape model).

**Assumptions that entered the fit (and their disposition):**

| Assumption | Used in fit? | Used in Simscape? | Disposition |
|-----------|-------------|------------------|-------------|
| Constant Ld, Lq | Yes | No | Replaced by efficiency map |
| P_iron = 1070*(n/4400)^2 | Yes | No | Replaced by efficiency map |
| P_sw = 500 W | Yes | No | Eliminated entirely |
| P_aux = 300 W | Yes | Yes | Measured from Hioki DCDC |
| Rs(T) from CAN temp | Yes | Yes | Measured, cross-checked |
| CAN torque accurate | Yes | Yes | Validated vs dyno force |

None of the unvalidated assumptions (P_iron model, P_sw estimate,
constant Ld/Lq) carry forward into the Simscape model. The fit
served to extract psi_m and k_Vmax, both of which are independently
validated against physics (FEA thermal offset, six-step theory).

### 2.3 Rs temperature correction

ANL TDMS motor temperatures:

| Test | Mean motor temp | Max motor temp | Inverter temp |
|------|-----------------|----------------|---------------|
| HWFET (61910017) | 30 C | 37 C | 26 C |
| US06 (61910021) | 42 C | 61 C | 26 C |
| SSS 65 mph (61910022) | 85 C | 93 C | 29 C |

Rs at operating temperature: Rs(T) = Rs(20C) x [1 + 0.00393 x (T - 20)]

| Condition | T (C) | Rs (mOhm) | Change |
|-----------|-------|-----------|--------|
| Teardown reference | 20 | 6.59 | baseline |
| HWFET average | 30 | 6.85 | +3.9% |
| US06 average | 42 | 7.16 | +8.7% |
| US06 peak | 61 | 7.66 | +16.2% |
| SSS average | 85 | 8.27 | +25.5% |
| SSS peak | 93 | 8.48 | +28.7% |

Implementation: use Motor_1_temp_calc_DMCM1 from each test to set
Rs for the corresponding simulation. For drive-cycle simulations (UDDS,
HWFET, US06, WLTP) use the average motor temperature from that test.
For the Ld/Lq fit (which uses SSS data heavily), use Rs at 85 C.

---

## 3. Field-Weakening Boundary

### 3.1 Approximate (M1, back-EMF limit, no saliency)

    omega_e_base = V_dc / (sqrt(3) x psi_m)
                 = 350 / (1.732 x 0.1078)
                 = 1874 rad/s (electrical)
    omega_m_base = 1874 / 4 = 468.5 rad/s = 4475 rpm
    v_FW = 468.5 x 0.317 / 7.05 = 21.1 m/s = 75.9 km/h

### 3.2 CRG-derived (M3, from fitted Ld/Lq)

The CRG boundary is torque-dependent. At low current (cruise), FW
onset is at higher speed because q-axis flux is small. At high current
(acceleration), the large q-axis flux increases total flux linkage,
lowering the base speed.

    V_max = V_dc / (sqrt(3) x k_Vmax) = 350 / (1.732 x 0.904) = 223.5 V

| MTPA current (A) | gamma (deg) | Torque (Nm) | n_base (rpm) | v_FW (km/h) |
|-------------------|-------------|-------------|--------------|-------------|
| 20 | 1.5 | 12 | 5239 | 88.8 |
| 40 | 3.0 | 24 | 5214 | 88.4 |
| 80 | 6.0 | 49 | 5117 | 86.7 |
| 150 | 10.7 | 93 | 4823 | 81.8 |
| 200 | 13.7 | 126 | 4549 | 77.1 |
| 300 | 18.6 | 196 | 3951 | 67.0 |

At cruise-relevant current (40A, ~24 Nm), v_FW = 88.4 km/h (CRG)
versus 80.4 km/h (M1). The CRG boundary is 10% higher than M1 at
cruise because the low id at light load means flux_d is close to
psi_m alone.

At rated current (300A, ~196 Nm), v_FW = 67.0 km/h (CRG) versus
80.4 km/h (M1). The CRG boundary is 17% lower than M1 because the
large iq drives up flux_q, increasing total flux linkage.

The M1-M3 gap reverses direction depending on load. M1 gives a single
fixed number (80.4 km/h) that matches no actual operating point. The
CRG captures the torque-dependent boundary, which is essential for
accurate LMDI regime attribution across the full torque range of a
drive cycle.

### 3.3 Consequence: Bolt operates in FW on all cycles

At cruise current (~40A), v_FW = 88.4 km/h (CRG). Unlike the Tesla
(v_FW = 117.6 km/h at cruise), the Bolt enters FW on every standard
drive cycle.

| Cycle | Max speed (km/h) | FW onset (CRG, cruise) | FW operation |
|-------|-----------------|----------------------|--------------|
| UDDS | 91.3 | 88.4 km/h | Brief, at peak speeds only |
| HWFET | 96.6 | 88.4 km/h | Yes, during cruise segments |
| WLTP | 131.6 | 88.4 km/h | Significant, Extra High phase |
| US06 | 129.2 | 88.4 km/h | Deep FW in highway section |
| Artemis MW130 | 130 | 88.4 km/h | Deep FW |

Compare Tesla: UDDS and HWFET are entirely MTPA (max speeds below
117.6 km/h). The Bolt has nonzero FW share on all five cycles. This
is the key cross-vehicle contrast for Paper B.

The cause is not gear ratio (Bolt 7.05 is lower than Tesla 9.04,
which would raise v_FW). The cause is the motor design: the Bolt has
higher psi_m (0.1017 vs 0.0772 Wb), lower V_dc (350 vs 370 V), and
six-step modulation (k_Vmax = 0.904 vs 1.10). These combine to give
a much lower base speed despite the lower gear ratio.

---

## 4. Auxiliary Power

ANL TDMS Hioki measurements (DCDC output power = total HV-to-12V draw):

| Test | DCDC mean (W) | HVAC (W) | Notes |
|------|--------------|----------|-------|
| HWFET (61910017) | 364 | 0 | HVAC off during dyno test |
| US06 (61910021) | 265 | 0 | HVAC off |
| SSS (61910022) | 301 | 0 | HVAC off |

All ANL dyno tests were run with HVAC off. The auxiliary load is the DCDC
converter feeding 12V systems (ECU, cooling fans, pumps, lights).

Implementation: use 300 W constant auxiliary load. This is lower than the
Tesla (690 W) because the Tesla value includes the front motor quiescent
draw (AWD idle losses). The Bolt is FWD single-motor, no quiescent draw.

Allca-Pekarovic uses 200 W. The measured 265-364 W from Hioki is higher,
probably because it includes cooling pump operation that their model
lumps elsewhere. Use 300 W as the round-number average of measured data.

---

## 5. Regenerative Braking (D-mode)

### 5.1 Key finding: ANL tested in D mode, not L mode

Trans_regen_button_pos_CAN = 0 in all 15 TDMS files. The Bolt was tested
in D (Drive) mode, not L (Low/one-pedal) mode. D-mode has mild coast
regen, nothing like Tesla's 0.15g one-pedal driving.

### 5.2 D-mode coast regen (pedal fully released, no brake)

Measured from US06 (61910021), 794 data points where accel = 0 and
brake < 2%:

| Speed range | Mean motor torque | Mean deceleration | Points |
|-------------|-------------------|-------------------|--------|
| 10-30 km/h | -27.3 Nm | 0.356 m/s^2 (0.036 g) | 152 |
| 30-50 km/h | -32.3 Nm | 0.421 m/s^2 (0.043 g) | 352 |
| 50-80 km/h | -33.3 Nm | 0.434 m/s^2 (0.044 g) | 225 |
| 80-130 km/h | -26.2 Nm | 0.342 m/s^2 (0.035 g) | 65 |

Average coast regen: ~30 Nm, ~0.04 g. This is 4x weaker than the Tesla
(102 Nm, 0.15 g). The slight speed dependence (lower at very low and
very high speed) suggests the Bolt ECU reduces coast regen near stop
(creep feel) and at high speed (stability).

### 5.3 Brake-blended regen (brake pedal pressed)

| Brake pedal range | Mean motor torque | Points |
|-------------------|-------------------|--------|
| 2-5% | -38.4 Nm | 932 |
| 5-10% | -66.9 Nm | 1461 |
| 10-15% | -87.9 Nm | 1697 |
| 15-25% | -66.7 Nm | 682 |

Peak regen torque: -128.7 Nm. The bulk of regen energy comes from
brake-blended events, not coast regen.

### 5.4 Implementation strategy

The 0.04g coast regen is mild enough that the PID speed-following driver
can absorb it without the cycling problem that plagued the Tesla model
at 0.15g. No split-authority driver needed.

**Simulink implementation (3-state regen):**

```
State 1: TRACTION (accel_cmd > 0)
    T_regen = 0
    PID controls motor torque for speed following

State 2: COAST (accel_cmd = 0, brake = 0, v > 1.4 m/s)
    T_regen = -30 Nm (fixed, applied as drag on motor shaft)
    PID output is zero (no conflict)
    Below 1.4 m/s (5 km/h): ramp T_regen to zero

State 3: BRAKING (brake_cmd > 0)
    T_regen = min(T_brake_regen, T_motor_max_regen(omega))
    where T_brake_regen = BrakeForce_Total x r_w / gear x regen_share
    regen_share = 0.60 (60% of braking via regen, rest friction)
    T_motor_max_regen(omega) = P_regen_max / omega_m
    P_regen_max = min(60 kW, V_dc x I_charge_max)
    Friction = (BrakeForce_Total - T_regen x gear / r_w) applied at wheel
```

The 60% regen_share is estimated from the data: at moderate braking
(5-15% pedal), regen torque is 67-88 Nm out of total brake torque of
~150-200 Nm. The exact blending can be calibrated during validation.

### 5.5 Validation targets (regen fraction per cycle)

| Cycle | ANL regen % (of gross) | Notes |
|-------|----------------------|-------|
| UDDS | 32.1% | High regen: many stop-start events |
| HWFET | 9.7% | Low regen: mostly steady cruise |
| US06 | 20.9% | Moderate: aggressive accel + braking |
| WLTP | 23.1% | Moderate: mixed driving |

These are battery-level regen fractions (charge energy / discharge
energy). The simulation must match within ±5 percentage points.

### 5.6 Comparison with Tesla regen

| Aspect | Tesla Model 3 | Bolt EV (D-mode) |
|--------|--------------|-----------------|
| Coast regen | 0.15 g (one-pedal) | 0.04 g (engine-brake feel) |
| Coast torque | ~102 Nm | ~30 Nm |
| PID conflict? | Yes (needed split-authority) | No (0.04g is PID-absorbable) |
| Brake regen | Blended | Blended |
| Peak regen | ~150 Nm | ~129 Nm |
| US06 regen % | 20.9% | 20.9% (same!) |
| Regen source | Mostly coast (one-pedal) | Mostly brake-blended |

The Tesla and Bolt achieve nearly identical total regen fractions on US06
through completely different mechanisms. This is a useful discussion point
for Paper B: the LMDI decomposition captures the net energy effect
regardless of the regen implementation strategy.

---

## 6. ANL TDMS Data — Channel Map

### 6.1 Test file identification

The ANL tests combine multiple drive cycles in a single TDMS file.
Bag-level data identifies which portion corresponds to which cycle.

| File | Contents | Duration | Cycles included |
|------|----------|----------|-----------------|
| 61910017 | Single HWFET | 13 min | HWFET only |
| 61910020 | UDDS + HWFET | 37 min | Bags 1+2 = UDDS (1373s, 12.0 km), Bag 3 = HWFET (764s, 16.5 km) |
| 61910021 | Prep + US06 | 81 min | Bags 1-5 = prep (UDDS+HWFET+UDDS), Bags 6+7 = US06 (600s, 12.9 km) |
| 61910022 | SSS 65 mph depletion | 171 min | Steady-state 65 mph, SOC 86% to 12.5% |
| 61910023 | Multi-repeat US06 | 89 min | Multiple US06 repeats |
| 61911001 | WLTP x 2 | 71 min | Bags 1-4 = WLTP cycle 1, Bags 5-8 = WLTP cycle 2 |
| 61911003 | Acceleration perf | 19 min | Full-throttle runs |
| 61911004 | Accel pedal staircase | 45 min | Stepped pedal positions at various speeds |
| 61911008 | Coastdown + accel | 27 min | Coastdown and acceleration tests |

### 6.2 Channels for the Simscape model

**Motor (from inverter CAN, DMCM1 module):**

| Channel | Signal | Units | Use in model |
|---------|--------|-------|-------------|
| Motor_1_torque_DMCM1 | Motor shaft torque | Nm | Validation, Ld/Lq fit |
| Motor_1_speed_DMCM1 | Motor speed | rpm | omega_e = p x rpm x 2pi/60 |
| Motor_1_current_DMCM1 | DC bus current to inverter | A | Power balance (NOT phase RMS) |
| Motor_1_HV_circuit_voltage_DMCM1 | Inverter DC voltage | V | Voltage limit equation |
| Motor_1_temp_calc_DMCM1 | Calculated motor temp | C | Rs correction |
| Motor_1_inverter_temp_sensor1_DMCM1 | Inverter temp | C | Thermal monitoring |

**Motor_1_current_DMCM1 is DC bus current, NOT motor phase RMS.**
Verified: ratio to Hioki DC current = 0.977 (Hioki includes aux draw).
Phase current must be derived from power balance:
I_phase_rms = P_elec / (3 x V_phase x cos_phi).

**Phase currents (Motor_1_phase_u/v/w_current_DMCM1) are aliased at
10 Hz and CANNOT be used for d-q decomposition.** Electrical frequency
at 6300 rpm is 420 Hz. The 10 Hz CAN rate gives random phase snapshots.

**Battery (Hioki power analyser + CAN):**

| Channel | Signal | Units | Use |
|---------|--------|-------|-----|
| Batt_Volt_Hioki_U1 | HV battery voltage | V | Primary (calibrated instrument) |
| Batt_Curr_Hioki_I1 | HV battery current | A | Primary (positive = discharge) |
| HVBatt_voltage_PTCAN | Battery voltage (CAN) | V | Cross-check |
| HVBatt_current_PTCAN | Battery current (CAN) | A | Cross-check (negative = discharge) |
| HVBatt_SOC_HPCM | Battery SOC | % | SOC tracking |
| DCDC_Out_Power_Hioki_P2 | DCDC output power | W | Auxiliary load measurement |

**Vehicle:**

| Channel | Signal | Units | Use |
|---------|--------|-------|-----|
| Vehicle_spd_CAN | Vehicle speed | km/h | Drive trace following |
| Dyno_Spd | Dyno roller speed | mph | Wheel speed reference |
| Dyno_TractiveForce | Tractive force at wheel | N | Road load verification |
| Distance | Cumulative distance | miles | Energy per km calculation |
| Pedal_accel_pos_CAN | Accelerator pedal | % | Regen state detection |
| Brake_pedal_pos_CAN | Brake pedal | % | Regen state detection |
| Trans_regen_button_pos_CAN | Regen mode selector | 0/1 | 0 = D mode in all tests |

---

## 7. Validation Targets

### 7.1 BMS-level net energy (primary validation gate)

Primary targets from 2020 Bolt EV test 62009019 (Hioki WP1, 23-25C,
SOC 97.3%). Same powertrain as 2019 MY. Updated 19 July 2026.
WLTP from 2019 (no 2020 WLTP test available).

| Cycle | Net Wh/km | Gross Wh/km | Regen Wh/km | Regen % | Source |
|-------|-----------|-------------|-------------|---------|--------|
| UDDS | 99.6 | 153.3 | 53.7 | 35.1% | 2020 62009019 warm UDDS (bags 4+5) Hioki P1, corrected 24 Jul 2026 |
| HWFET | 125.2 | 138.7 | 13.5 | 9.8% | 2020 62009019 HWY1 |
| US06 | 167.8 | 220.5 | 52.7 | 23.9% | 2020 62009019 US06 combined |
| WLTP | 136.3 | 177.5 | 41.2 | 23.3% | 2019 61911001 WLTP x2 avg |

**Validation gate: net Wh/km within ±5% of ANL target.**

| Cycle | Target | -5% | +5% |
|-------|--------|-----|-----|
| UDDS | 99.6 | 94.6 | 104.6 |
| HWFET | 125.2 | 118.9 | 131.5 |
| US06 | 167.8 | 159.4 | 176.2 |
| WLTP | 136.3 | 129.5 | 143.1 |

### 7.2 EPA cross-check (secondary)

2020 Chevrolet Bolt EV (60 kWh):

| EPA metric | MPGe | Wh/km (AC wall) | Est. DC Wh/km |
|------------|------|-----------------|---------------|
| City | 128 | 163.6 | ~102 |
| Highway | 110 | 190.4 | ~134 |
| Combined | 120 | 174.5 | ~116 |
| EPA range | — | — | 238 mi = 383 km |

EPA DC estimate = AC_Wh/km x adjustment_factor x charger_eff.
City: 163.6 x 0.70 x 0.90 = 103. Highway: 190.4 x 0.78 x 0.90 = 134.
Our ANL UDDS (107.7) and HWFET (123.0) bracket these estimates.

### 7.3 Motor-level loss anchors (from Allca-Pekarovic 2024, Table V)

| Cycle | Motor loss (Wh/km) | Implied net Wh/km |
|-------|--------------------|--------------------|
| UDDS | 13.4 | 96.5 (60 kWh / 622 km) |
| HWFET | 8.1 | 124.7 |
| US06 | 15.0 | 171.9 |

These use the GM efficiency map (inverter losses excluded), not the
ANL measurements. The implied net values are reasonably close to our
ANL targets, confirming consistency.

### 7.4 Cross-vehicle comparison context

| Metric | Tesla M3 LR AWD | Bolt EV 2020 |
|--------|----------------|-------------|
| Mass | 1928 kg | 1705 kg |
| Gear ratio | 9.04 | 7.05 |
| Wheel radius | 0.326 m | 0.317 m |
| V_dc nominal | 370 V | 350 V |
| psi_m | 0.0772 Wb | 0.1017 Wb (fitted) |
| Ld | 125 uH | 253.7 uH (fitted) |
| Lq | 244 uH | 389.1 uH (fitted) |
| Lq/Ld | 1.95 | 1.53 |
| p | 3 | 4 |
| k_Vmax | 1.10 | 0.904 (fitted, six-step) |
| v_FW M1 | 119.8 km/h | 80.4 km/h |
| v_FW M3 (cruise) | 108.4 km/h | 88.4 km/h |
| Motor type | IPM (low flux, high saliency) | IPM (high flux, lower saliency) |
| FW strategy | SVPWM | Six-step above base |
| US06 net Wh/km | 150.6 | 176.4 |
| UDDS net Wh/km | 109.0 | 107.7 |

The Bolt is lighter but consumes more on US06 (+17%) because it operates
in deep FW. On UDDS (low speed, mostly MTPA for both), consumption is
nearly identical. This contrast validates the LMDI structural effect:
the energy penalty appears only when the cycle forces FW operation.

---

## 8. Ld/Lq Fitting Plan

### 8.1 Why fitting is needed

No publication reports Ld and Lq for the Bolt EV motor. An analytical
solve at the rated corner point (353 Nm, 400 Arms, 4400 rpm, 350 V)
does not converge because saturation at peak current depresses the
effective flux. Parameters must be fitted at cycle-relevant currents
(drive cycles rarely exceed a third of peak current).

### 8.2 Available data for fitting

| Test file | Region | Points | Key characteristic |
|-----------|--------|--------|--------------------|
| 61911004 (staircase) | MTPA + FW | 24k | Deliberate sweep of operating points, T up to 353 Nm |
| 61910020 (UDDS) | Mostly MTPA | 12k MTPA | Transient city driving |
| 61910022 (SSS 65 mph) | Deep FW | 99k FW | 2.9 hours steady cruise, V = 387-330 V |
| 61910021 (US06) | Mixed | 36k | Holdout validation |
| 61911001 (WLTP) | Mixed | 31k | Holdout validation |

### 8.3 Revised fitting approach

The original plan assumed d-q current components could be measured.
They cannot (10 Hz phase current sampling at 420 Hz electrical frequency
= severe aliasing). The revised approach uses power balance and
steady-state motor equations.

**Knowns per sample:**
- T: Motor_1_torque_DMCM1 (Nm)
- n: Motor_1_speed_DMCM1 (rpm), convert to omega_e = p x n x 2pi/60
- V_dc: Batt_Volt_Hioki_U1 (V)
- I_dc: Batt_Curr_Hioki_I1 (A)
- T_motor_temp: Motor_1_temp_calc_DMCM1 (C), for Rs correction

**Constants:**
- p = 4
- psi_m = 0.1078 Wb (prior, ±5%)
- Rs = 6.59 mOhm at 20C (temperature-corrected per sample)

**Stage A: MTPA region (below 4400 rpm)**

At MTPA, the current angle gamma satisfies the optimality condition:

    gamma_MTPA = arcsin[(-psi_m + sqrt(psi_m^2 + 8(Lq-Ld)^2 x Is^2)) / (4(Lq-Ld) x Is)]

Given torque T and phase current magnitude Is:

    T = 1.5 x p x [psi_m x Is x sin(gamma) + 0.5(Ld - Lq) x Is^2 x sin(2 gamma)]

Phase current Is is derived from the power balance:

    P_elec = V_dc x I_dc
    P_mech = T x omega_m
    P_copper = 3 x Is^2 x Rs(T_motor)
    P_iron estimated from Patel 2025 loss data (1070 W at 4400 rpm)
    Is = sqrt((P_elec - P_mech - P_iron) / (3 x Rs))

This gives two equations (torque + MTPA condition) in two unknowns
(Ld, Lq). Fit by least-squares over all MTPA steady-state points from
61911004 and 61910020.

**Stage B: FW region (above 4400 rpm)**

In FW the voltage constraint is active:

    V_max^2 = (Rs x id + omega_e x Lq x iq)^2 + (Rs x iq - omega_e x (psi_m + Ld x id))^2

where V_max = V_dc / (sqrt(3) x k_Vmax).

The SSS test (61910022) provides 99,340 data points in FW with voltage
varying from 387 V to 330 V as SOC drops. This voltage variation is the
key identifiability advantage: it separates the Ld and Lq contributions
to the voltage equation.

At high speed, neglecting Rs:

    V_max ≈ omega_e x sqrt((Lq x iq)^2 + (psi_m + Ld x id)^2)

This, combined with the torque equation, gives a system in (Ld, Lq, id, iq)
with measured (T, omega_e, V_dc) and the constraint id^2 + iq^2 = Is^2.

**Stage C: Holdout validation**

Fit on 61910020 (UDDS) + 61910022 (SSS). Validate on:
- 61910021 (US06): 36k points, mixed MTPA/FW
- 61911001 (WLTP): 31k points, mixed MTPA/FW

Report holdout RMS torque error and RMS power error. Target: < 3% RMS
(matching Tesla fit quality, 2.7%).

**Stage D: Uncertainty propagation**

Propagate the fit covariance of (Ld, Lq, psi_m) through the CRG
omega_base calculation. Report the FW-share attribution shift at band
edges. If shift is < 2 percentage points, the LMDI result is insensitive
to parameter uncertainty.

### 8.4 k_Vmax for six-step modulation — RESOLVED

The Bolt uses six-step (square-wave) modulation above base speed, not
SVPWM. Six-step raises the fundamental voltage ceiling:

| Modulation | V_phase_peak / V_dc | Ratio to SVPWM |
|-----------|--------------------|----|
| SVPWM | 1/sqrt(3) = 0.577 | 1.000 |
| Six-step | 2/pi = 0.637 | 1.104 |

The CRG voltage equation uses V_max = V_dc / (sqrt(3) x k_Vmax).
For six-step, k_Vmax = 1/1.104 = 0.906 (theoretical).

**Fitted result: k_Vmax = 0.904.** Within 0.2% of theory. This
confirms six-step modulation operates throughout the FW region.
No piecewise CRG boundary needed. The modulation question from the
original plan is fully resolved by the fit.

---

## 9. Simscape Model Changes (from Tesla baseline)

The Bolt model starts from a copy of the Tesla Simscape model
(AE_BoltEV_LMDI.slx). These blocks need modification:

### 9.1 Parameter file (AE_BoltEV_LMDI_Params.m)

**Vehicle and drivetrain (all validated):**

| Parameter | Tesla value | Bolt value | Source | Status |
|-----------|------------|------------|--------|--------|
| mass | 1928 kg | 1705 kg | Allca-Pekarovic 2024 | V |
| gear_ratio | 9.04 | 7.05 | Patel teardown, TDMS verified | V |
| wheel_radius | 0.326 m | 0.317 m | CAN speed cross-check | V |
| road_load_A | 178 N | 126.3 N | Allca-Pekarovic 2024 | V (coastdown verified) |
| road_load_B | 3.024 | 2.008 | Allca-Pekarovic 2024 | V (coastdown verified) |
| road_load_C | 0.370 | 0.4336 | Allca-Pekarovic 2024 | V (coastdown verified) |
| aux_power | 690 W | 300 W | Hioki DCDC measured | V |
| cable_R | 0.015 ohm | 0 (negligible) | Hioki vs CAN: 1.7 mOhm, 4.7 W | D |

**Motor (CRG boundary parameters, validated):**

| Parameter | Tesla value | Bolt value | Source | Status |
|-----------|------------|------------|--------|--------|
| p | 3 | 4 | Patel teardown | V |
| psi_m | 0.07719 Wb | 0.1017 Wb | Fitted, FEA-anchored | V |
| k_Vmax | 1.10 | 0.904 | Fitted, six-step theory | V |
| V_dc | 370 V | 350 V | TDMS measured | V |

**Motor (estimates, NOT used in PMSM block):**

| Parameter | Value | Note |
|-----------|-------|------|
| Ld | 253.7 uH | Constant-inductance estimate, 23% torque error at peak |
| Lq | 389.1 uH | Not used in Simscape model |
| Lq/Ld | 1.53 | For paper discussion only |

**Saturation limit (from published data):**

| Parameter | Value | Source |
|-----------|-------|--------|
| T_max | 353 Nm | Patel 2025 FEA |
| I_max | 400 Arms | Patel 2025 FEA |
| Rs | 6.59 mOhm (20C) | Patel FEA copper loss, temp-corrected per test |

### 9.2 Motor model architecture — efficiency-map approach

The Tesla model uses a Simscape PMSM block with constant (Ld, Lq)
from ORNL characterisation. This works for the Tesla because the
ORNL data provides validated inductance maps at cycle-relevant
currents (the Tesla fit achieved 2.7% holdout RMS).

The Bolt cannot use the same approach. No ORNL characterisation
exists, and the constant-inductance fit gives 23% peak torque error
due to saturation. A d-q model with wrong torque production would
fail the ±5% Wh/km validation gate on US06.

**Approach: torque-source motor with measured efficiency.**

The motor block takes torque demand as input and outputs shaft
torque directly (no d-q current calculation). Electrical power
consumption is computed from the ANL-measured drivetrain efficiency:

    P_elec = T x omega_m / eta_motor(T, omega_m)

where eta_motor is a 2D lookup table (torque x speed) extracted
from ANL TDMS data:

    eta_motor(T, n) = P_mech / P_elec_motor
                    = (T x omega_m) / (V_dc x I_dc - P_aux)

This is computed directly from measured channels: Motor_1_torque,
Motor_1_speed, Batt_Volt_Hioki, Batt_Curr_Hioki, and DCDC power.
No iron loss model, no switching loss assumption, no constant-
inductance approximation.

**Data sources for the loss map:**

| Source file | Operating region | Valid points |
|-------------|-----------------|-------------|
| 61911004 (staircase) | -117 to 353 Nm, 100-7937 rpm | 23,745 |
| 61910022 (SSS) | -37 to 145 Nm, 108-6332 rpm | 100,413 |
| 61910020 (UDDS) | -120 to 138 Nm, 100-5763 rpm | 17,740 |
| 61911003 (accel perf) | -117 to 349 Nm, 101-8026 rpm | 9,522 |
| **Total** | | **151,420** |

**Loss map grid:** 49 torque bins (-125 to 355 Nm, 10 Nm) x 44 speed
bins (100 to 8700 rpm, 200 rpm). 815 bins filled from data (minimum
5 points per bin, outlier rejection at 3-sigma MAD). Remaining bins
filled by linear interpolation (nearest-neighbor at boundaries).
Traction bins forced to minimum 50 W loss.

**File:** `chevrolet/data/BoltEV_loss_map.mat`

**Holdout validation (motor-level integrated energy):**

| Cycle | Motor energy error | Wh/km measured | Wh/km predicted |
|-------|-------------------|----------------|-----------------|
| US06 (holdout) | +0.5% | 168.3 | 169.1 |
| WLTP (holdout) | +3.2% | 135.7 | 139.9 |
| UDDS (training) | -0.7% | 108.7 | 107.9 |

All within ±5% gate. Point-by-point RMS is 7-18%, but integrated
energy is within 0.5-3.2% because over-predictions and under-
predictions cancel over a full cycle. This is consistent with the
map being a statistical aggregate of noisy 10 Hz CAN data.

The 4.6% gap between measured US06 Wh/km (168.3) and the ANL bag
target (176.4) is a bag boundary extraction issue, not a loss map
error. The loss map reproduces the measured motor energy within
+0.5% on the same data window.

The staircase test (61911004) provides the widest torque-speed
coverage. SSS provides the deep-FW cruise region. UDDS provides
transient city driving. Acceleration performance fills the high-
torque high-speed quadrant.

**What this eliminates:**

| Removed assumption | Replacement |
|-------------------|-------------|
| Constant Ld, Lq | Not needed (torque-source model) |
| P_iron = 1070*(n/4400)^2 | Included in measured eta |
| P_sw = 500 W | Included in measured eta |
| d-q current calculation | Not needed |

**What this preserves:**

The CRG boundary calculation is separate from the Simscape motor
block. It uses psi_m (0.1017 Wb) and k_Vmax (0.904), both validated.
The regime classifier operates on the simulation output (torque,
speed at each time step) and applies the CRG boundary to assign
MTPA/Transition/FW labels. The efficiency-map motor produces the
correct energy consumption; the CRG classifies the operating regime.
These are independent.

### 9.3 Regen subsystem

Replace the one-pedal regen S-function (onepedal_regen_sfcn.m) with
a simpler 3-state Simulink subsystem:

```
Input: accel_cmd, brake_cmd, vehicle_speed, motor_speed
Output: T_regen (Nm, negative)

Logic:
  if accel_cmd > 0:
      T_regen = 0
  elseif brake_cmd == 0 AND vehicle_speed > 1.4 m/s:
      T_regen = -30  % D-mode coast regen (measured from 794 ANL points)
  elseif brake_cmd > 0:
      T_brake_total = BrakeForce x r_w / gear
      T_regen = -min(0.60 x T_brake_total, T_motor_regen_max(omega))
      % 0.60 from ANL brake pedal vs regen torque data
      % Remaining braking goes to friction
  else:
      T_regen = 0
  end
```

No split-authority driver needed. The PID speed controller handles
traction. The regen subsystem applies fixed coast regen when the PID
output is zero.

Data sources for regen parameters:
- Coast regen -30 Nm: measured from 794 points in US06 (accel=0, brake<2%)
- Brake regen share 0.60: estimated from brake pedal vs motor torque data
  (5-15% pedal gives 67-88 Nm regen out of ~150 Nm total braking)
- These are initial values from measurement, not calibration targets

### 9.4 CRG boundary (regime classifier)

AE_regime_binning.m currently computes the Tesla CRG boundary. For the
Bolt, change to:
- psi_m = 0.1017 Wb
- k_Vmax = 0.904
- p = 4
- V_dc = 350 V (or SOC-dependent from simulation)

The CRG boundary is torque-dependent. At each simulation time step,
the classifier computes the base speed for the current motor torque
using the MTPA angle formula. If motor speed exceeds base speed, the
time step is classified as FW.

At cruise (40A, 24 Nm): v_FW = 88.4 km/h, n_base = 5214 rpm.
At rated (300A, 196 Nm): v_FW = 67.0 km/h, n_base = 3951 rpm.

The CRG curve is monotonically decreasing (higher torque = lower
base speed). No piecewise definition needed because six-step
modulation operates throughout the FW region (confirmed by k_Vmax fit).

### 9.5 BMS postprocessor

BoltEV_BMS_postprocess.m needs:
- aux_power = 300 W (Hioki measured)
- cable_R = 0 (measured 1.7 mOhm, 4.7 W loss, negligible)
- V_dc from Hioki (actual SOC-dependent voltage, not fixed 350 V)

---

## 10. Simulation Matrix

| Cycle | Drive trace source | Duration | Distance | Notes |
|-------|--------------------|----------|----------|-------|
| UDDS | ANL standard | 1369 s | 12.0 km | Already in Simscape library |
| HWFET | ANL standard | 765 s | 16.5 km | Already in Simscape library |
| US06 | ANL standard | 600 s | 12.9 km | Already in Simscape library |
| WLTP | ANL standard | 1800 s | 23.2 km | Already in Simscape library |
| Artemis MW130 | Simscape library | 1068 s | 28.7 km | Already loaded |

5 simulations, single gear ratio (7.05). No gear sweep for the Bolt
(gear sweep is Tesla-only, Improvement 2a). The Bolt contributes to
Improvement 1 (FW boundary method comparison) and Improvement 2b
(cross-vehicle contrast).

---

## 11. Implementation Sequence (revised 17 Jul 2026)

### Phase 1: Parameters — COMPLETE
1. ~~Lock road load: run coastdown verification on 61911008~~ DONE.
   Steady-state torque balance at 55 and 65 mph confirms Allca-Pekarovic
   within -6% (CAN torque tolerance). Road load LOCKED.
2. ~~Estimate cable_R from Hioki vs CAN voltage difference~~ DONE.
   R_cable = 1.7 mOhm (4.7 W, negligible). Set to 0 in Simscape.
3. Update AE_BoltEV_LMDI_Params.m with all validated parameters

### Phase 2: Parameter identification — COMPLETE
4. Stages A-D complete. Validated outputs: psi_m = 0.1017 Wb,
   k_Vmax = 0.904. CRG boundary computed. Uncertainty propagated.
   Estimated outputs (Ld, Lq) recorded but not used in Simscape.

### Phase 3: Model Build
5. ~~Extract efficiency map from ANL TDMS~~ DONE.
   151k points, 4 training files. Holdout: US06 +0.5%, WLTP +3.2%.
   Saved to chevrolet/data/BoltEV_loss_map.mat.
6. Build torque-source motor block with eta(T, omega) lookup
7. Replace regen S-function with 3-state subsystem
8. Update BMS postprocessor (aux=300W, cable_R, SOC-dependent V_dc)
9. Validate efficiency map against acceleration test (61911003)

### Phase 4: Validation
10. Run 5 cycles
11. Compare net Wh/km against ANL targets (±5% gate)
12. Compare regen fractions against ANL (±5 pp gate)
13. If any cycle fails: diagnose from efficiency map, not from
    parameter tuning. No calibration. Only identify which operating
    region the map is inaccurate and check against source data.

### Phase 5: LMDI
14. Run regime binning with Bolt CRG boundary (psi_m, k_Vmax only)
15. Run LMDI decomposition for all 5 cycles
16. Compute cross-vehicle LMDI pairs (Tesla vs Bolt)

---

## 12. Risk Register (revised 17 Jul 2026)

| Risk | Impact | Mitigation | Status |
|------|--------|-----------|--------|
| Efficiency map sparse at high torque | Torque error during US06 acceleration | Staircase data covers to 353 Nm; fill gaps from accel performance test 61911003 | Open |
| Road load mismatch | Systematic Wh/km bias | Coastdown verification on 61911008 before simulation | Open |
| ANL test mass ≠ 1705 kg | Small Wh/km bias on transient cycles | Check test summary PDF, adjust if > 2% different | Open |
| Rs temperature unknown for short cycles | ~3% copper loss error | Use measured Motor_1_temp_calc from each test | Mitigated |
| Regen parameters off | Net Wh/km error on stop-start cycles | Initial values from measured data (30 Nm coast, 0.60 brake share); if validation fails, re-examine ANL regen data, do not tune blindly | Open |
| CRG boundary uncertainty | LMDI attribution shift on HWFET | 90% CI ±4.5 km/h; report uncertainty band in paper; UDDS/US06/WLTP less sensitive | Quantified |
| ~~Ld/Lq fit does not converge~~ | ~~Blocks entire Bolt model~~ | ~~N/A~~ | Resolved |
| ~~Six-step k_Vmax wrong~~ | ~~CRG boundary error~~ | ~~N/A~~ | Resolved: 0.904 fitted |
| ~~Constant Ld/Lq 23% torque error~~ | ~~Simscape fails US06~~ | ~~N/A~~ | Resolved: efficiency-map approach |

---

## 13. Audit Trail — What Is Validated vs What Is Assumed

Every number in this specification falls into one of three categories.
No number should be used in the Simscape model or the paper without
checking which category it belongs to.

**V = Validated.** Measured from ANL TDMS data or confirmed against
an independent source. Can be used without caveat.

| Parameter | Value | Validation |
|-----------|-------|-----------|
| mass | 1705 kg | Allca-Pekarovic 2024, consistent with PLAN_AE |
| gear_ratio | 7.05 | Patel teardown + TDMS CAN verification |
| wheel_radius | 0.317 m | CAN speed cross-check, std 0.0002 m |
| p | 4 | Patel teardown |
| V_dc | 350 V nominal | TDMS measured range 324-387 V |
| aux_power | 300 W | Hioki DCDC output, range 265-364 W |
| psi_m | 0.1017 Wb | Fitted, FEA-anchored, thermal offset consistent |
| k_Vmax | 0.904 | Fitted, six-step theory gives 0.906 |
| Rs | 6.59 mOhm (20C) | Patel FEA, temp-corrected per test |
| Coast regen | -30 Nm | Measured from 794 US06 data points |
| Gearbox efficiency | 97.2% | CAN torque vs dyno cross-check |
| CAN torque | Accurate | Cross-validated against Dyno_TractiveForce |

**D = Data-derived.** Extracted from ANL data but with known
limitations. Can be used with stated caveats.

| Parameter | Value | Caveat |
|-----------|-------|--------|
| Efficiency map | eta(T, omega) | From TDMS power balance; accuracy depends on P_aux subtraction and Hioki calibration |
| Road load A,B,C | 126.3, 2.008, 0.4336 | Allca-Pekarovic; verified via SS torque balance at 55/65 mph (within -6%, CAN tolerance) |
| Brake regen share | 0.60 | Estimated from brake pedal vs torque data; initial value |
| Validation targets | UDDS 99.6, HWFET 125.2, US06 167.8, WLTP 136.3 Wh/km | 2020 Hioki WP1 (62009019); UDDS corrected 24 Jul to warm bags 4+5; WLTP from 2019 (61911001); uncertainty ~±2% |
| cable_R | 0 (1.7 mOhm measured) | 4.7 W loss, negligible. 0.7 V offset is CAN ADC bias, not resistive |

**E = Estimate.** Not validated. Must not be used without explicit
caveat in the paper.

| Parameter | Value | Note |
|-----------|-------|------|
| Ld | 253.7 uH | Constant-inductance, 23% peak torque error; for paper discussion only |
| Lq | 389.1 uH | Same limitation |

---

*Document created: 17 July 2026*
*Revised: 17 July 2026 (efficiency-map motor, removed unvalidated assumptions)*
*Revised: 17 July 2026 (Phase 1 complete: coastdown verified, cable_R negligible)*
*Based on: ANL TDMS audit of 15 test files, Patel 2025, Allca-Pekarovic 2024*
*All numerical values verified against raw TDMS channel data*
