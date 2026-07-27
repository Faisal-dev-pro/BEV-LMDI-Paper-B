# Supplementary Material

## Decomposition of battery electric vehicle energy consumption by operating regime: LMDI analysis validated on two production vehicles across four drive cycles

Faisal Shah Khan, Thamo Sutharssan

University of East London, School of Architecture, Computing and Engineering

---

## S1. Simulink model architecture

[Block diagram of the common longitudinal dynamics architecture. Show signal flow from drive cycle input through driver controller, motor/inverter, gearbox, vehicle dynamics, and battery. Annotate the motor-level measurement point used for LMDI decomposition.]

### S1.1 Tesla Model 3 motor subsystem

[Block diagram of the d-q axis IPMSM implementation in Simscape Electrical. Show FOC structure: speed reference -> torque demand -> MTPA current reference lookup -> PI current controllers -> PWM inverter -> IPMSM block.]

### S1.2 Chevrolet Bolt EV motor subsystem

[Block diagram of the efficiency-map motor implementation. Show: torque demand -> P_elec = T * omega + P_loss(T, n) -> loss map lookup -> electrical power output. Note: constant-inductance d-q model gives 23% peak torque error at rated current due to magnetic saturation; efficiency map avoids this.]

### S1.3 Battery equivalent circuit

[Block diagram of the Simscape battery block. Parameters: V_nom, R_int, SOC_0, capacity. Note: Tesla V_nom = 400 V (96s NCA), Bolt V_nom = 350 V (96s pouch). SOC variation during a single drive cycle is < 5%, so the constant-R_int approximation is adequate.]

---

## S2. Driver model

### S2.1 Speed-tracking controller

[Block diagram of the PI speed controller with feedforward.]

| Parameter | Tesla | Bolt |
|---|---|---|
| Proportional gain K_p | 500 | [value] |
| Integral gain K_i | 100 | [value] |
| Feedforward gain K_ff | 0.15 | [value] |
| Distance error (all cycles) | < 0.1% | < 0.1% |

### S2.2 Split-authority regenerative braking

[Block diagram showing the three-mode logic: traction (PID active), coast regen (rule-based fixed deceleration), and active braking (friction + regen blend).]

| Parameter | Tesla | Bolt |
|---|---|---|
| Coast regen deceleration | 0.15 g | 0.04 g |
| Regen power cap | 60 kW | 50 kW |
| Minimum regen speed | 1.39 m/s | 1.39 m/s |
| Pedal state logic | accel_cmd = 0 AND v > v_min | accel_cmd = 0 AND v > v_min |

---

## S3. Current controller gains

Gains derived using the internal model control (IMC) method with bandwidth omega_bw = 2*pi*f_sw/10.

### S3.1 Tesla Model 3

| Parameter | Value | Derivation |
|---|---|---|
| Switching frequency f_sw | 10 kHz | Estimate |
| Current loop sample time T_si | 100 us | Estimate |
| K_p,id | 0.7854 | omega_bw * L_d |
| K_i,id | 29.845 | omega_bw * R_s |
| K_p,iq | 1.5331 | omega_bw * L_q |
| K_i,iq | 29.845 | omega_bw * R_s |

### S3.2 Chevrolet Bolt EV

[Same IMC derivation with Bolt motor parameters.]

---

## S4. Current reference generation

### S4.1 Tesla MTPA lookup table

[Description of TeslaM3_CurrentRefs.mat: id_table, iq_table as 2D lookups indexed by torque (T_vec) and speed (rpm_vec), 200 x 200 grid. Source: offline MTPA + voltage-constrained optimisation.]

### S4.2 Bolt MTPA calculation

[Description of the analytical MTPA approach for the Bolt: at each torque level, i_d and i_q are computed from the MTPA condition, and the onset speed is identified where terminal voltage reaches V_dc * k_Vmax / sqrt(3).]

---

## S5. Bolt EV motor loss map

[Description of BoltEV_loss_map.mat construction.]

| Property | Value |
|---|---|
| Torque bins | 49 (range: -125 to 355 Nm) |
| Speed bins | 44 (range: 100 to 8700 rpm) |
| Training data points | 151,420 across 4 ANL test files |
| Holdout validation error | US06 +0.5%, WLTP +3.2% |

[Figure: Bolt EV loss map surface or contour plot.]

---

## S6. Road load verification

Road load coefficients from ANL coastdown testing. Force model: F = A + B*|v| + C*v^2.

### S6.1 Tesla Model 3

Source: ANL test 62005005, three independent coastdown runs averaged.

| Run | A (N) | B (N s/m) | C (N s^2/m^2) |
|---|---|---|---|
| CD1 | 161.69 | 0.520 | 0.3142 |
| CD2 | 161.76 | 0.580 | 0.3152 |
| CD3 | 162.36 | 0.578 | 0.3158 |
| Average | 162.0 | 0.552 | 0.315 |

### S6.2 Chevrolet Bolt EV

[Source: ANL coastdown data. Coefficients: A = 126.3, B = 2.008, C = 0.434.]

---

## S7. Drive cycle speed profiles

[Tabulated speed-time data sources for each cycle, or reference to repository files.]

| Cycle | Duration (s) | Distance (km) | Max speed (km/h) | Source |
|---|---|---|---|---|
| UDDS | 1369 | 12.0 | 91.2 | EPA 40 CFR 86 |
| HWFET | 765 | 16.5 | 96.4 | EPA 40 CFR 600 |
| US06 | 600 | 12.9 | 129.2 | EPA 40 CFR 86 |
| WLTP Class 3 | 1800 | 23.2 | 131.3 | UNECE GTR 15 |
| Artemis MW130 | 1068 | 28.8 | 132.0 | Andre 2004 |

---

## S8. LMDI post-processing scripts

[Brief description of the three core scripts and their inputs/outputs.]

| Script | Purpose | Input | Output |
|---|---|---|---|
| AE_regime_binning.m | Classify timesteps into MTPA, transition, FW | Simulation .mat, FW boundary curve | Per-regime distance, energy, shares |
| AE_lmdi_decomposition.m | LMDI-I additive decomposition | Two regime-binned states | Delta_str, Delta_int, residual |
| AE_run_LMDI_matrix.m | Batch all cycle pairs | All simulation results | LMDI_matrix_results.mat |

---

## References

[Reference any sources cited only in the supplementary material, if applicable.]
