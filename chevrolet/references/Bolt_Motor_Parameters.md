# Bolt EV Motor Parameters — Extraction from Patel et al. (2025)

**Source:** H. D. Patel, B. S. Yilmaz, P. J. Kollmeyer, B. Bilgin, A. Emadi,
"Teardown Analysis and FEA Motor Model of Chevrolet Bolt EV Drivetrain,"
IEEE/AIAA ITEC+EATS 2025, DOI 10.1109/ITEC...2025 (PDF in project uploads).
Companion dataset (lamination DXF, 3D models, Ansys FEA model):
Borealis Data, DOI 10.5683/SP3/LM35Z2.
Published reference values cited therein: Momen, Rahman, Son, "Electrical
propulsion system design of Chevrolet Bolt battery electric vehicle,"
IEEE Trans. Ind. Appl. 55(1):376-384, 2018.

**Extraction date:** 5 July 2026. Calibration tiers follow the project
convention: [V] verified measurement, [D] derived from verified source,
[E] estimate.

## 1. Measured (teardown) parameters

| Parameter | Value | Tier | Note |
|-----------|-------|------|------|
| Rotor poles | 8 (p = 4 pole pairs) | V | double-V IPM, asymmetric pole angles 104.1/110.2 deg |
| Stator slots | 72 | V | hairpin bar winding, 6 conductors/slot, 4 parallel paths |
| Final gear ratio | 7.05 | V | two-stage: 35/73 (2.09) x 21/71 (3.38) |
| Stator OD / ID | 203.8 / 140.5 mm | V | |
| Rotor OD / airgap | 139.5 / 0.5 mm | V | |
| Stack length | 124.75 mm (stator), 127.2 mm (rotor, est.) | V | |
| Lamination thickness | 0.27 mm | V | material assumed M090-27P |
| Magnets | N48EH assumed; bottom 19.75x3.9x15.9, top 9.7x2.35x15.9 mm | V geometry, E grade | 8 magnets axially |

## 2. Ratings (FEA model vs published)

| Parameter | FEA (Patel) | Published (Momen 2018) |
|-----------|-------------|------------------------|
| Peak torque | 353 Nm at 400 Arms | 360 Nm |
| Torque ripple | 11.98% | 8% |
| Rated (base) speed | 4400 rpm | |
| Max speed | 8800 rpm | |
| Peak power at 350 V | 160 kW | 150 kW EPA |
| DC link nominal | 350 V | |
| Max phase voltage | 142.88 V rms (SVPWM equivalent; production uses six-step above base) | |

Caution: the paper text and Table III disagree internally in two places
(rated speed 4200 vs 4400 rpm; iron loss at max speed 4025 vs 2838 W).
The table values are used here. FEA torque is 2% below published, attributed
to assumed magnet and lamination grades.

## 3. Derived electrical parameters

psi_m from FEA back-EMF: phase back-EMF 140.46 V rms at 4400 rpm,
omega_e = 4 x 460.77 = 1843.1 rad/s:

    psi_m = sqrt(2) x 140.46 / 1843.1 = 0.1078 Wb   [D, from FEA back-EMF]

Rs from FEA DC copper loss: 3162 W at 400 Arms, three phases, temperature
rise neglected in the FEA:

    Rs = 3162 / (3 x 400^2) = 6.59 mOhm   [D, DC value, approx 20 C]

Iron loss anchor points for post-processing (same treatment as Tesla model):
1070 W at 4400 rpm, 2838 W at 8800 rpm, magnet loss 27 to 48 W [D].

Torque cross-check: PM-only torque 1.5 x p x psi_m x 566 A = 366 Nm against
353 Nm FEA at MTPA, consistent with a modest saliency contribution.

## 4. Still open: Ld, Lq — fitting plan

Ld and Lq are not reported in any located source. An analytical solve at
the rated corner (353 Nm, 400 Arms, 4400 rpm, 350 V, with psi_m = 0.1078
and the MTPA and voltage-limit conditions) does NOT converge: PM-only
torque at 566 A peak is already 366 Nm, above the 353 Nm target, so no
constant-parameter set is consistent at peak current. This is saturation
and armature reaction depressing effective flux at high current. Two
consequences: parameters must be fitted at cycle-relevant currents (drive
cycles rarely demand more than roughly a third of peak current), and the
manuscript must state the validity domain, exactly as the Tesla fit does
(ANL vehicle fit, 2.7% RMS, cycle loads).

Fitting plan (over-invested deliberately; the CRG boundary for the Bolt
inherits whatever quality this fit has):

Stage 0, data audit. Confirm the meaning of Motor_1 phase current channels
(RMS vs sampled instantaneous at 10 Hz). Verify Motor_1_torque_DMCM1
against Dyno_TractiveForce x r_w / 7.05 over steady segments to bound
CAN torque bias. Select steady-state windows: SSS 65 mph depletion
(61910022, hours of near-constant operating point in FW), HWY cruise
segments, accel pedal mapping staircase (61911004).

Stage A, MTPA-region fit (below ~4400 rpm). Torque equation
T = 1.5 p [psi iq + (Ld - Lq) id iq] across all steady points, psi
constrained by a prior at 0.1078 +/- 5%. Identifies psi_eff and the
saliency term.

Stage B, FW-region fit (above ~4500 rpm; abundant, since the Bolt cruises
in FW). Voltage-limit equation with measured HVBatt_voltage separates Ld
from Lq. The Bolt's deep-FW operation is an identifiability advantage the
Tesla data never offered.

Stage C, holdout validation. Fit on 61910020 plus SSS; validate on
61910021 plus WLTP (61911001). Report holdout RMS torque and power error.

Stage D, uncertainty propagation (the reviewer-proof step). Propagate the
fit covariance of (Ld, Lq, psi_m) through the CRG omega_base calculation
to an uncertainty band, then recompute LMDI regime shares at the band
edges. Report the FW-share attribution shift across the band. If the
shift is small, the paper's central claim is insulated from parameter
uncertainty; if it is large, that is itself a finding about boundary
sensitivity and is reported honestly.

Parallel check if Ansys access exists at UEL: extract flux-linkage maps
from the published FEA model (Borealis DOI above) at two or three current
levels to confirm the saturation trend the corner-solve implies.

Also open: Rs at operating temperature, ANL test mass (verify approx 1700 kg
from test records; Patel Table IV uses 1616 kg curb), k_Vmax equivalent for
six-step operation (modulation above SVPWM limit raises the effective
voltage ceiling; affects the CRG boundary calculation).

## 5. Vehicle model parameters and loss anchors from Allca-Pekarovic et al. (2024)

**Source:** A. Allca-Pekarovic, P. J. Kollmeyer, A. Forsyth, A. Emadi,
"Experimental Characterization and Modeling of a YASA P400 Axial Flux PM
Traction Machine for Performance Analysis of a Chevy Bolt EV," IEEE Trans.
Ind. Appl. 60(2):3107-3118, 2024 (PDF in project uploads). Their Bolt IPM
efficiency map is taken from Momen et al. SAE 2016-01-1228 (their ref [32]),
which means the GM-published measured efficiency map is in that SAE paper
and should be pulled via UEL access for iron loss calibration.

2017 Bolt EV vehicle model (their Table III):

| Parameter | Value | Note |
|-----------|-------|------|
| Mass | 1625 kg vehicle + 80 kg passenger = 1705 kg | consistent with the approx 1700 kg ANL test mass in PLAN_AE, still verify against ANL record |
| Road load A | 126.3 N | SI units, v in m/s |
| Road load B | 2.008 N/(m/s) | |
| Road load C | 0.4336 N/(m/s)^2 | |
| Gear ratio | 7.05 | matches teardown |
| Gearbox efficiency | 98% | |
| Wheel radius | 0.32 m | Patel uses 0.323, PLAN_AE 0.328; resolve from ANL tire spec 215/50R17 |
| Accessory power | 200 W | |
| Top machine speed | 8810 rpm | matches Momen 2018 |

Directly usable: F = 126.3 + 2.008 v + 0.4336 v^2 (N, v in m/s) as the
external brake port road load, same structure as the Tesla implementation
(178 + 3.024 v + 0.370 v^2). Verify against the ANL Bolt coastdown tests
(61911008) before locking.

Motor-only loss anchors from the GM efficiency map (their Table V, 60 kWh
pack, inverter losses excluded from battery consumption):

| Cycle | Bolt IPM motor loss [Wh/km] | Modeled range [km] |
|-------|-----------------------------|---------------------|
| UDDS  | 13.4 | 622 |
| LA92  | 15.7 | 463 |
| HWFET | 8.1  | 481 |
| US06  | 15.0 | 349 |

These provide an independent check on the per-regime loss budget of the
Bolt Simscape model: total motor loss integrated over each cycle should
land near these values. Implied net consumption (60 kWh / range) is 96.5
(UDDS), 129.6 (LA92), 124.7 (HWFET), 171.9 (US06) Wh/km, with the caveat
that inverter and accessory treatment differs from the ANL battery
measurements, so validation targets should still come from the ANL TDMS
extraction, not from this table.

## 6. Consequence for PLAN_AE section 2b (important)

PLAN_AE assumed omega_base_Bolt of roughly 900 rad/s giving FW onset near
151 km/h and "almost no FW on US06". The teardown data contradicts this.
With psi_m = 0.1078 Wb and 350 V the no-load voltage limit is reached at
about 4476 rpm (468.7 rad/s mech), matching the FEA rated speed of 4400 rpm.
At gear 7.05 and wheel radius 0.328 m the FW onset vehicle speed is

    v_FW = 468.7 x 0.328 / 7.05 = 21.8 m/s = 78.5 km/h

against 117.6 km/h for the Tesla. The Bolt therefore enters field weakening
at much lower road speed than the Tesla, not higher. Expected regime
behaviour: substantial FW share on US06 (well above the Tesla 31.3%), and
even UDDS (max 91.25 km/h) briefly exceeds the Bolt FW onset.

The cross-vehicle contrast in Paper B is therefore machine-flux driven, not
gear-ratio driven: the Bolt is a high-flux, low-base-speed design that
relies on deep field weakening with six-step modulation, while the Tesla
holds MTPA to higher road speed. The gear-ratio-governs-structure claim is
carried by the Tesla gear sweep (improvement 2a), and the Bolt strengthens
improvement 1 instead, since a machine operating mostly in FW is exactly
where the choice of FW boundary method changes LMDI attribution most.
Section 2b of PLAN_AE should be revised accordingly.
