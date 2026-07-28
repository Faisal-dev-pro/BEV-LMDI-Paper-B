# Decomposition of battery electric vehicle energy consumption by operating regime: LMDI analysis validated on two production vehicles across four drive cycles

Faisal Shah Khan ^a,*, Thamo Sutharssan ^a

^a School of Architecture, Computing and Engineering, University of East London, University Way, London E16 2RD, United Kingdom

\* Corresponding author. Email: u2796240@uel.ac.uk

Email addresses: u2796240@uel.ac.uk, faisalshah.khan@yahoo.com (F.S. Khan), T.Sutharssan@uel.ac.uk (T. Sutharssan).

---

## Highlights

1. LMDI decomposition is implemented within the BEV powertrain.
2. Two production vehicles validated within 5% across four drive cycles.
3. Structural effects explain 78% of the UDDS to US06 energy gap (B3, 370 V).
4. Regime boundary method alters energy attribution by 82 percentage points.
5. For two IPM vehicles, motor parameters dominate gear ratio in regime exposure.

---

## Keywords

LMDI, index decomposition analysis, battery electric vehicle, energy consumption, drive cycle, operating regime, powertrain design

---

## Nomenclature

| Symbol | Definition |
|---|---|
| A, B, C | road load coefficients (N, N s/m, N s^2/m^2) |
| CdA | aerodynamic drag area (m^2) |
| d | distance (km) |
| e | per-regime energy contribution, S · I (Wh/km) |
| E | regime energy (Wh) |
| g | gear ratio |
| I | intensity factor, E/d (Wh/km) |
| i_d, i_q | d- and q-axis stator current (A) |
| k_Vmax | voltage modulation index |
| L(x, y) | logarithmic mean, (x - y) / (ln x - ln y) |
| L_d, L_q | d- and q-axis inductance (H) |
| m_test | test mass (kg) |
| p | pole pairs |
| P_aux | auxiliary power (W) |
| r | regime index |
| R_s | stator resistance (Ohm) |
| r_w | wheel radius (m) |
| S | structural factor (distance share) |
| T | motor torque (N m) |
| v | vehicle speed (km/h) |
| V_dc | DC bus voltage (V) |
| v_FW | field-weakening onset speed (km/h) |
| W_wheel | positive wheel energy (Wh) |
| Delta_str | structural term of LMDI decomposition (Wh/km) |
| Delta_int | intensity term of LMDI decomposition (Wh/km) |
| omega | motor angular speed (rad/s) |
| psi_m | permanent magnet flux linkage (Wb) |

**Abbreviations:** BEV, battery electric vehicle; CRG, current reference generator; FW, field weakening; IPM, interior permanent magnet; LMDI, logarithmic mean Divisia index; MTPA, maximum torque per ampere; B1/B2/B3, boundary methods 1/2/3.

---

## Abstract

Regulatory and real-world battery electric vehicle energy consumption can differ by more than 30%. Vehicle-level Wh/km does not identify the mechanisms governing energy distribution across motor operating regimes.

This study applies logarithmic mean Divisia index (LMDI-I) decomposition within the powertrain to separate drive cycle energy into structural effects (regime residence) and intensity effects (per-regime efficiency). Three regime boundary methods of increasing physical realism are compared, with the most detailed evaluated at three DC bus voltages. Two production vehicles, the Tesla Model 3 and Chevrolet Bolt EV, are validated within 5% of publicly available dynamometer data across four drive cycles and the decomposition is applied to five cycles, including a real-world motorway profile.

Structural effects explain 78% of the 53.1 Wh/km difference between the Urban Dynamometer Driving Schedule (UDDS) and US06 cycles for the Tesla Model 3 under the current reference generator (CRG) derived boundary at 370 V. Under different voltage assumptions, this proportion ranges from 42% to 103%. Cross-vehicle comparisons attribute 88-99% of the motor-level energy difference to structural effects on three of four matched cycles. Boundary selection alters attribution by up to 82 percentage points. The Bolt EV enters field weakening at 88 km/h versus 118 km/h for the Tesla, despite a lower gear ratio. Motor design parameters, rather than gear ratio, are the primary determinant of regime exposure.

These findings offer a quantitative diagnostic linking drive-cycle definition, motor design, and transmission gearing to energy consumption in battery electric vehicles.

---

## 1. Introduction

Road transport accounts for a considerable part of global energy-related carbon dioxide emissions, and the electrification of passenger vehicles has been recognized as a primary strategy for reducing sectoral carbon intensity [9, 10, 14]. Battery electric vehicle adoption has accelerated over the past decade, and the electricity consumed by traction motors and regenerative braking systems now constitutes a measurable fraction of total road transport energy demand [29, 74, 76, 95, 96]. How this energy is distributed across the powertrain's operating conditions is therefore relevant to both vehicle design and energy system assessment [17, 22, 92–94]. Numerous studies have examined the influence of driving behaviour, road gradient, ambient temperature, and auxiliary loads on vehicle-level energy consumption, typically reported as Wh/km or its regulatory equivalents [17–28]. This body of work has produced detailed empirical and model-based estimates of range and output, yet the resulting aggregate metric does not identify which operating conditions within the powertrain are responsible for the consumption observed.

The discrepancy between regulatory and on-road energy consumption highlights this limitation. For battery electric vehicles evaluated under Worldwide Harmonized Light Vehicles Test Procedure (WLTP) and United States Environmental Protection Agency (US EPA) protocols, the difference between type-approval and measured consumption can exceed 30% [61, 62]. Several factors contribute to this gap, including auxiliary thermal loads, the representativeness of test cycles, and driver aggressiveness [24, 60, 63–65]. However, analyses rarely examine data below the aggregate Wh/km level. The electric motor transitions among distinct operating regimes as vehicle speed and torque demand fluctuate throughout a drive cycle, resulting in variations in energy consumption per unit distance in both magnitude and loss composition [29, 33, 34, 36]. A method that distinguishes the effect of regime residence from changes in per-regime efficiency would address this gap by identifying the portion of the consumption difference attributable to structural factors, such as the operating region of the motor, versus intensity effects, which arise from the efficiency with which the motor operates in those regions.

Index decomposition analysis, particularly the logarithmic mean Divisia index (LMDI) method, is widely recognized as the standard framework for attributing changes in aggregate energy consumption to structural and intensity factors [1, 2, 3]. This method has been extensively applied at both national and sectoral levels to attribute transport energy demand [9–12], residential energy consumption [7], and electricity generation carbon intensity [16]. Recent studies have also investigated how the selection of decomposition periods and the definition of structural categories influence attribution outcomes [5, 8]. Despite these advances, three significant gaps remain in the application of LMDI to powertrain-level energy analysis. First, the method has not yet been employed within the powertrain to decompose drive cycle energy across the motor's operating regimes. Second, the delineation between operating regimes has not been considered as an energy accounting decision, even though its definition can substantially affect the decomposition results. Third, there is no cross-vehicle LMDI comparison to determine whether the structural and intensity shares identified for one vehicle are generalizable to machines with differing design parameters.

This research addresses existing limitations by applying LMDI-I decomposition to the battery electric vehicle powertrain for the first time. The primary contributions are outlined below:

1. LMDI-I decomposition is applied at the motor level to partition drive cycle energy consumption into structural effects, which quantify the proportion of distance covered in each operating regime, and intensity effects, which measure energy consumption per unit distance within each regime. Two production vehicles with distinct motor designs, the Tesla Model 3 and Chevrolet Bolt EV, are validated to within 5% accuracy using publicly available dynamometer data across four drive cycles (UDDS, HWFET, US06, WLTP). The analysis is further extended to a fifth cycle, the Artemis Motorway 130, to investigate sustained field-weakening operation beyond the validated range.
2. Three regime boundary methods, each offering progressively greater physical realism, are compared. These range from a simplified back-electromotive force voltage limit to a boundary derived from the motor's exact torque-speed operating trajectory. The most detailed method is further evaluated at three DC bus voltages, yielding five boundary definitions in total. The choice of boundary definition alters energy attribution by as much as 82 percentage points for identical simulation data, demonstrating that regime delineation is a significant factor in energy accounting.
3. Cross-vehicle LMDI comparisons are performed using matched drive cycles. Structural effects explain 88-99% of the motor-level energy difference between the two vehicles across three of four evaluated cycles. The Bolt EV transitions to extended-speed operation at 88 km/h, whereas the Tesla Model 3 does so at 118 km/h. This difference occurs despite the Bolt EV's lower gear ratio, indicating that, for the two IPM machines evaluated, motor design parameters rather than transmission ratio govern regime exposure.

The structure of the paper is as follows. Section 2 reviews previous research on LMDI decomposition in transport and energy applications, as well as studies on battery electric vehicle energy consumption modelling. Section 3 details the methodology, including vehicle models, the LMDI-I decomposition framework, and regime boundary methods. Section 4 presents validation results for both vehicles across four drive cycles. Section 5 provides the LMDI decomposition results, including cross-cycle analysis, cross-vehicle comparisons, and implications for gear ratio design. Section 6 examines the implications for vehicle design and drive cycle assessment. Section 7 concludes the paper.

## 2. Literature review

Ang [1, 2] formalised the LMDI method as a refinement of index decomposition analysis, producing an exact decomposition without unexplained residuals. In the additive (LMDI-I) formulation, changes in aggregate energy quantities between two states are partitioned into structural and intensity components. The structural term captures changes in the composition of activity across categories, while the intensity term reflects changes in per-category energy use [3]. This method has been widely applied at both national and sectoral levels, including electricity generation [16], residential consumption [7], and industrial energy intensity [5, 6]. Within the transport sector, LMDI decompositions have attributed changes in energy demand and carbon emissions to modal share, vehicle fleet composition, and fuel intensity across multiple countries [9–15]. Xiang et al. [8] demonstrated that the definition of structural categories can alter the resulting attribution, a finding directly relevant to the regime boundary examined in this study.

Battery electric vehicle energy consumption has been investigated using both physics-based and data-driven approaches. Xie et al. [17] developed a microsimulation framework to represent the sensitivity of consumption to speed and acceleration profiles. Fiori et al. [22] proposed a power-based model validated against dynamometer data, while De Cauwer et al. [23] and Miri et al. [18] estimated consumption from on-road measurements. Several studies have quantified the influence of drive cycle definition on measured energy performance. Pavlovic et al. [61] and Fontaras et al. [62] reported that the discrepancy between type-approval and on-road consumption for European passenger vehicles exceeds 30%. Galvin [24] demonstrated that speed and acceleration patterns account for a large share of the consumption variation across cycles for battery electric vehicles. Castillo-Calderon et al. [20] reviewed prediction methods and concluded that most approaches operate at the vehicle level without decomposing consumption by powertrain operating condition. Collectively, these studies confirm the cycle dependence of battery electric vehicle energy use but do not attribute the observed differences to specific operating regimes within the motor.

The energy consumed by the traction motor at each point in a drive cycle is determined by the active operating regime. Interior permanent magnet synchronous motors, which are the dominant topology in production battery electric vehicles [29, 38, 76], operate in two principal regimes. Below the base speed, maximum torque per ampere (MTPA) control minimises copper loss for a given torque demand [30, 36, 93, 94]. Above the base speed, field-weakening control reduces the effective flux linkage to maintain operation within the inverter voltage limit, resulting in increased current and reduced efficiency [31, 32, 33, 39]. The transition speed between these regimes depends on motor design parameters, battery voltage, and the control strategy employed [29, 35]. In single-speed drivetrains, the gear ratio determines how vehicle speed maps to motor speed and thus governs the proportion of a drive cycle spent in each regime [41, 42]. Multiple studies have investigated gear ratio and transmission selection for battery electric vehicle energy efficiency [41–47], but none isolated the regime-level contribution from other loss factors. Comparative studies of motor topologies for traction applications have characterised trade-offs among cost, power density, and efficiency [37, 40, 78–82], yet the energy cost of operating in the field-weakening regime, as distinct from the structural effect of regime residence, has not been quantified separately.

LMDI transport studies [9–15] decompose aggregate fleet quantities by mode or fuel type, but not by powertrain operating regime. Vehicle-level energy studies [17–28] quantify consumption sensitivity to cycle and design parameters, yet do not attribute cycle-to-cycle differences to structural and intensity components. The motor regime literature [29–40] characterises the efficiency penalty of field-weakening operation but does not distinguish it from the structural effect of increased regime residence at higher speeds. The sensitivity of LMDI attribution to category definition, as noted by Xiang et al. [8] at the sectoral level, has not been investigated for the motor regime boundary. Bridging these research areas requires a decomposition method that operates at the powertrain level, explicitly accounts for the regime boundary, and is validated across vehicles with distinct motor designs. This study provides such a connection.

## 3. Methodology

### 3.1 Vehicle models and validation data

Two production battery electric vehicles were selected to provide contrasting regime exposure for the LMDI decomposition. The transition speed between maximum torque per ampere control and extended-speed operation determines the proportion of each drive cycle spent in the field-weakening regime (Section 3.3). For the Chevrolet Bolt EV, this transition occurs within the speed range of all five evaluated cycles, including the urban schedule. In contrast, for the Tesla Model 3, the transition speed is reached only during higher-speed profiles. This difference arises from motor design rather than gear ratio. Consequently, the two vehicles exhibit distinct regime residence patterns on identical drive cycles, which enables separation of structural and intensity effects.

The Tesla Model 3 is a 2020 Long Range all-wheel drive variant [77] equipped with a rear interior permanent magnet synchronous motor rated at 188 kW, a 9.04:1 single-speed reduction gear, and a 75 kWh battery at 400 V nominal. The Chevrolet Bolt is a 2020 model [75] featuring an eight-pole double-V interior permanent magnet motor rated at 150 kW, a 7.05:1 gear ratio, and a 60 kWh battery at 350 V nominal. Vehicle parameters, including test mass, road load coefficients, and motor electrical characteristics, are summarised in Table 1.

The Tesla motor is modelled as a d–q axis interior permanent magnet synchronous machine, with current reference commands generated from a maximum torque per ampere lookup table. The Bolt motor is modelled as an efficiency-map torque source, where electrical power is calculated as P_elec = T × ω + P_loss(T, n), with P_loss derived from a two-dimensional lookup table constructed from measured dynamometer data [86, 97, 98]. This modelling approach is necessary because magnetic saturation in the Bolt motor results in a 23% peak torque error at rated current when assuming constant inductance. Both vehicle models utilise a common longitudinal dynamics architecture, which includes a single-speed gearbox, coastdown-derived road load, and a battery equivalent circuit [85, 88–91]. Regenerative braking is implemented using a rule-based split-authority architecture that replicates production one-pedal behaviour [48–57]. The Tesla applies a coast deceleration of 0.15g, while the Bolt applies 0.04g, consistent with values measured from the Argonne dynamometer data. Regenerative braking fractions are validated directly against measured values. Details of the modelling environment, block diagrams, controller parameters, and driver logic are provided in the supplementary material.

![Figure 1: Powertrain schematic illustrating the common longitudinal dynamics architecture with vehicle-specific motor and regenerative braking subsystems](../results/figures/png/Fig1_powertrain_schematic.png)

Validation targets are established using the Argonne National Laboratory Downloadable Dynamometer Database [66, 68], which provides publicly available chassis dynamometer data at 10 Hz recorded using standardised test procedures [67, 69]. Battery-level net energy consumption is determined from CAN-bus cumulative energy for the Tesla and from calibrated power analyser data (Hioki PW6001) for the Bolt, with both methods measuring high-voltage bus power at the battery terminals. The acceptance criterion is set at ±5% of the measured net Wh/km for each cycle. The LMDI decomposition is performed at the motor level, upstream of auxiliary loads and cable losses, to isolate the energy attributable to each operating regime.

Five drive cycles are evaluated, covering a spectrum from urban to aggressive motorway conditions. The Urban Dynamometer Driving Schedule (UDDS, 1369 s) and Highway Fuel Economy Test (HWFET, 765 s) are United States Environmental Protection Agency (EPA) regulatory cycles for city and highway driving, respectively. The US06 Supplemental Federal Test Procedure (600 s) represents aggressive driving, with speeds reaching 129 km/h. The Worldwide Harmonized Light Vehicles Test Procedure (WLTP) Class 3 cycle (1800 s, 23.2 km) serves as the European regulatory cycle [59]. The Artemis Motorway 130 cycle (1068 s, 28.8 km, maximum 132 km/h), derived from measured European motorway driving [58], is included as a real-world representative profile. These cycles encompass conditions ranging from zero field-weakening operation to sustained extended-speed cruise. Figure 2 presents the speed profiles for all five cycles with field-weakening onset speeds indicated for both vehicles, illustrating the contrasting regime exposure.

![Figure 2: Speed profiles for the five evaluated drive cycles, with field-weakening onset speeds for the Tesla Model 3 (117.6 km/h) and Chevrolet Bolt EV (88.4 km/h) indicated as horizontal thresholds](../results/figures/png/Fig2_drive_cycles.png)

**Table 1.** Vehicle and motor parameters.

| Parameter | Tesla Model 3 LR AWD | Chevrolet Bolt EV |
|---|---|---|
| Model year | 2020 | 2020 |
| Motor type | IPM (d-q model) | Double-V IPM (efficiency map) |
| Peak power (kW) | 188 | 150 |
| Peak torque (Nm) | 353 | 360 |
| Pole pairs p | 3 | 4 |
| PM flux linkage psi_m (Wb) | 0.0772 | 0.1017 |
| Stator resistance R_s (mOhm) | 4.75 | 6.59 |
| d-axis inductance L_d (uH) | 125 | 254 (a) |
| q-axis inductance L_q (uH) | 244 | 389 (a) |
| Saliency ratio L_q/L_d | 1.95 | 1.53 |
| Modulation index k_Vmax | 1.10 | 0.904 |
| DC bus voltage V_dc (V) | 370 (b) | 350 |
| Battery capacity (kWh) | 75 | 60 |
| Gear ratio | 9.04 | 7.05 |
| Wheel radius r_w (m) | 0.326 | 0.317 |
| Test mass m_test (kg) | 1928 | 1705 |
| Aerodynamic drag area CdA (m^2) | 0.51 | 0.71 |
| Road load A (N) | 162.0 | 126.3 |
| Road load B (N s/m) | 0.552 | 2.008 |
| Road load C (N s^2/m^2) | 0.315 | 0.434 |
| Auxiliary power P_aux (W) | 690 | 155 |
| Cable resistance R_cable (Ohm) | 0.015 | 0 (c) |
| Regen power cap (kW) | 60 | 50 |
| Coast regen deceleration (g) | 0.15 | 0.04 |
| FW onset speed v_FW (km/h) | 117.6 | 88.4 |

(a) Estimated from published finite element data; not used in the Simscape simulation loop but used for the B3 field-weakening boundary calculation (Section 3.3). (b) Measured traction-average DC bus voltage from Argonne data; nominal battery voltage 400 V. (c) Measured cable drop 1.7 mOhm; set to zero in simulation.

### 3.2 LMDI-I decomposition framework

Aggregate motor-level energy intensity for a specified drive cycle is represented as the sum of contributions from each operating regime:

e = Σ_r S_r · I_r     (1)

Here, r denotes the motor operating regimes defined in Section 3.3. The term S_r = d_r / d_total represents the distance share in regime r (the structural factor), while I_r = E_r / d_r denotes the net energy consumption per unit distance within regime r (the intensity factor). The values d_r and E_r for each regime are calculated from instantaneous motor power and vehicle speed at each solver timestep. Net energy encompasses both traction and regenerative contributions, ensuring that I_r reflects the true energy cost of operating in regime r after accounting for energy recovery.

The difference in aggregate energy intensity between two states, A and B, is decomposed using the LMDI-I additive formulation [1, 2]:

Δe = e_B − e_A = Δ_str + Δ_int     (2)

Δ_str = Σ_r L(e_r,B, e_r,A) · ln(S_r,B / S_r,A)     (3)

Δ_int = Σ_r L(e_r,B, e_r,A) · ln(I_r,B / I_r,A)     (4)

In these expressions, e_r,k = S_r,k · I_r,k denotes the per-regime energy contribution in state k, and L(x, y) = (x − y) / (ln x − ln y) represents the logarithmic mean weight. The structural term Δ_str quantifies the portion of the energy difference attributable to changes in regime residence, while the intensity term Δ_int quantifies the portion attributable to changes in per-regime energy consumption. This decomposition is exact; the residual Δe − Δ_str − Δ_int is identically zero by construction [1].

If a regime exists in one state but is absent in the other, the standard logarithmic mean becomes undefined. In accordance with the zero-value convention of Ang and Liu [4], the entire per-regime contribution is assigned to the structural term. This approach is physically consistent, as the appearance or disappearance of a regime constitutes a structural change rather than an efficiency change. Regimes with distance shares below 1% are merged with adjacent regimes prior to decomposition, thereby preventing near-absent regimes with numerically unstable intensities from distorting the logarithmic ratios.

This framework is implemented in two configurations. In the cross-cycle comparison, states A and B correspond to different drive cycles evaluated on the same vehicle at the same gear ratio. The structural term quantifies the extent to which the Wh/km difference between cycles arises from the varying proportions of distance spent in each regime. In the cross-vehicle comparison, states A and B represent two vehicles evaluated on the same drive cycle. Here, the structural term quantifies the portion of the energy difference attributable to differing regime exposure, while the intensity term reflects differences in per-regime motor efficiency. Both configurations utilise Eqs. (2)–(4) without modification.

LMDI-I is chosen over other decomposition methods because it produces an exact result with zero residual and symmetric treatment of the two comparison states [1, 2]. Laspeyres and Paasche indices use fixed base-period or current-period weights, producing different results depending on the direction of comparison and leaving an interaction term when the total change is allocated across factors. Shapley value decomposition also removes the residual but requires averaging over all possible orderings of factor changes rather than providing a closed-form weight. In the two-factor case considered here, both LMDI and Shapley yield unique decompositions. LMDI is preferred for its closed-form logarithmic mean weight and its established application in energy decomposition analysis [1–3].

### 3.3 CRG-derived field-weakening boundary

The LMDI decomposition described in Section 3.2 requires classification of each solver timestep into one of three motor operating regimes. Below the field-weakening onset speed, the motor operates in the maximum torque per ampere (MTPA) regime. At and above the onset speed, the motor transitions into the field-weakening regime. A transition band, defined as the 5% speed interval immediately below the onset speed, represents the region where the current reference begins to deviate from the MTPA trajectory. This three-regime partition establishes the structural categories for the decomposition. The 5% bandwidth captures the operating region where the CRG current vector begins departing from the MTPA trajectory. Varying this parameter from 2.5% to 10% redistributes distance between the transition and MTPA regimes but does not affect the field-weakening share, which is determined by the onset boundary alone. The maximum transition share across all configurations is 12.5% (Tesla US06, Table 3). Compared with the 82 percentage point range produced by the boundary method comparison (Section 5.1), the transition bandwidth is a second-order parameter.

The onset speed for field weakening is not a fixed value but varies with torque demand. At low torque, the MTPA current vector is small, resulting in the voltage constraint being reached at a higher motor speed. Conversely, at high torque, the increased current produces greater flux linkage, causing the voltage limit to be reached at a lower speed. Consequently, the field-weakening boundary forms a curve in the torque-speed plane. The definition of this boundary determines how distance and energy are attributed to each regime, making it a critical energy accounting decision with direct implications for the decomposition.

Three boundary methods, each offering increasing physical realism, are compared. The first method (B1) defines the onset speed as omega_e = V_dc / (sqrt(3) * psi_m), representing the speed at which the back-electromotive force equals the DC bus voltage under no-load conditions. This boundary remains constant across all torque levels and does not account for saliency or load current. The second method (B2) solves the d-q voltage equation at i_d = 0, with i_q determined by the torque demand. This boundary varies with torque but does not align with the MTPA trajectory, as the assumption i_d = 0 neglects the reluctance torque contribution that shifts the optimal current vector into the negative i_d direction. The third method (B3) determines the onset speed using the motor's current reference generator, which provides the precise MTPA operating point, including saliency and reluctance torque. For the Tesla motor, the onset is identified from a lookup table using a d-axis current departure threshold of 10 A at V_dc = 370 V. For the Bolt motor, an analytically equivalent approach is applied: at each torque level, the MTPA current vector is calculated, and the speed at which the resulting terminal voltage reaches V_dc * k_Vmax / sqrt(3) defines the onset. Both implementations yield a torque-dependent boundary curve that accurately reflects the operating trajectory.

To evaluate the sensitivity of the decomposition to the voltage assumption, B3 is assessed at three DC bus voltages: 350 V, 370 V, and 400 V. The baseline value of 370 V corresponds to the average measured DC bus voltage during traction, as recorded in the Argonne dynamometer data. These five boundary definitions (B1, B2, and B3 at three voltages) are applied to identical simulation data. The net energy intensity for each cycle remains unchanged across all five definitions, indicating that the boundary alters regime classification without affecting the underlying physics. The sensitivity of the LMDI attribution to boundary selection is further quantified in Section 5.

Regenerative braking timesteps are classified using the same speed-based criterion as traction timesteps. Torque magnitude is estimated from motor electrical power and motor speed, applying a fixed drivetrain efficiency of 0.90. Since the decomposition is performed at the motor level (Section 3.1), auxiliary loads and cable losses are excluded from the torque estimate. The use of a fixed efficiency introduces a bounded bias: a ±5% deviation from the assumed value results in a ±5% shift in the torque estimate, which alters the torque-dependent onset speed by less than 2% at typical regenerative operating points. This displacement remains within the 5% transition band. High-speed regeneration is therefore attributed to the field-weakening regime, maintaining consistent net energy intensity across all three regimes.

![Figure 3: Torque-speed diagram showing the three boundary methods (B1, B2, B3) and the resulting regime classification for the Tesla motor](../results/figures/png/Fig3_boundary_methods.png)

## 4. Validation results

Table 2 summarises battery-level validation results for both vehicles across the four drive cycles with Argonne dynamometer targets. The Tesla Artemis Motorway 130 is included without a validation target. Simulated net Wh/km is compared to measured values at the battery terminals. The acceptance criterion is ±5% of the measured value. All eight validated cycle-vehicle combinations meet this criterion.

### 4.1 Tesla Model 3

The US06 cycle yields 148.7 Wh/km, compared with a measured 150.6 Wh/km (-1.2%). The HWFET yields 116.9 Wh/km, up from 114.4 Wh/km (+2.2%). The WLTP yields 126.6 Wh/km against 125.6 Wh/km (+0.8%). The UDDS yields 108.1 Wh/km against 109.0 Wh/km (-0.8%). The root-mean-square error throughout the four cycles is 1.4%.

The WLTP is also evaluated at the sub-phase level. The Low sub-phase yields 111.6 Wh/km versus 108.9 Wh/km (+2.5%), Medium 104.1 versus 103.6 (+0.5%), High 115.7 versus 114.4 (+1.1%), and Extra High 154.6 versus 154.2 (+0.2%). Each sub-phase meets the acceptance criterion.

Regenerative braking fractions are validated alongside net consumption. The US06 fraction is 29.4% versus 29.9%, UDDS is 33.1% versus 35.7%, HWFET is 9.8% versus 11.6%, and WLTP is 24.1% versus 26.9%. All values are within the acceptance band.

The Artemis Motorway 130 cycle does not have a corresponding Argonne dynamometer test. It is reported at 159.7 Wh/km at the battery level without a validation target.

![Figure 4: Simulated and measured cumulative battery energy for the Tesla Model 3 and Chevrolet Bolt EV](../results/figures/png/Fig4_validation_energy.png)

### 4.2 Chevrolet Bolt EV

The WLTP cycle yields 138.2 Wh/km against a measured 136.3 Wh/km (+1.4%). The HWFET yields 127.8 Wh/km against 125.2 Wh/km (+2.1%). The US06 yields 172.7 Wh/km against 167.8 Wh/km (+2.9%). The UDDS yields 105.9 Wh/km, compared with 101.9 Wh/km (+3.9%). The maximum error within the four cycles is 3.9%. Regenerative braking fractions are available for three cycles. The simulated fractions are 31.7% versus 34.6% measured for the UDDS, 23.3% versus 23.9% for the US06, and 20.9% versus 23.3% for the WLTP. All three are within the acceptance band.

The Artemis Motorway 130 cycle is not available in the Argonne database for the Bolt EV. Section 5 uses the four validated cycles common to both vehicles for cross-vehicle comparisons.

**Table 2.** Battery-level validation results. Measured targets from the Argonne National Laboratory dynamometer database. Acceptance criterion: net Wh/km within 5% of the measured value. No measured regen target is available for the Bolt HWFET.

| Vehicle | Cycle | Measured net (Wh/km) | Simulated net (Wh/km) | Error (%) | Regen measured (%) | Regen simulated (%) |
|---|---|---|---|---|---|---|
| Tesla | UDDS | 109.0 | 108.1 | -0.8 | 35.7 | 33.1 |
| Tesla | HWFET | 114.4 | 116.9 | +2.2 | 11.6 | 9.8 |
| Tesla | WLTP | 125.6 | 126.6 | +0.8 | 26.9 | 24.1 |
| Tesla | US06 | 150.6 | 148.7 | -1.2 | 29.9 | 29.4 |
| Tesla | Artemis MW130 | -- | 159.7 | -- | -- | -- |
| Bolt | UDDS | 101.9 | 105.9 | +3.9 | 34.6 | 31.7 |
| Bolt | HWFET | 125.2 | 127.8 | +2.1 | -- | 7.9 |
| Bolt | US06 | 167.8 | 172.7 | +2.9 | 23.9 | 23.3 |
| Bolt | WLTP | 136.3 | 138.2 | +1.4 | 23.3 | 20.9 |

Tesla root-mean-square error across four cycles: 1.4%. Bolt maximum error: 3.9%. The Artemis Motorway 130 has no corresponding Argonne dynamometer test for either vehicle.

### 4.3 Motor-level validation

The battery-level validation in Sections 4.1 and 4.2 confirms that aggregate Wh/km remains within 5% of the ANL dynamometer target. The LMDI decomposition, however, partitions energy at the motor level. This subsection verifies that agreement at the battery terminal translates to fidelity at the motor level.

The ANL test facility measures Tesla motor electrical power independently of the BMS using calibrated Hioki power analysers on the rear inverter AC lines (channel WP4). Three US06 tests (62005016, 62006001, 62006005) report motor-level net energy consumption of 144.9, 142.1, and 138.5 Wh/km (mean 141.8, SD = 2.6). The simulated value is 139.1 Wh/km, resulting in an error of -1.9%. Gross traction energy is 205.9 Wh/km measured and 202.8 Wh/km simulated (-1.5%). The measured regenerative braking fraction (31.1%) matches the simulated value (31.4%) within 0.3 percentage points. Auxiliary power, calculated from the difference between BMS and motor Hioki measurements, is 654 W, which aligns with the model value of 690 W.

The structural term is determined by distance shares above the field-weakening onset. Since the ANL CAN bus does not report regenerative braking torque for the Tesla Model 3, the torque-dependent CRG boundary cannot be applied to measured data at each timestep. Instead, a fixed speed threshold corresponding to the CRG onset at zero torque (117.6 km/h) is applied to both measured and simulated speed traces. Using this consistent approach, measured and simulated distance shares agree within 0.2 percentage points.

The Bolt ANL packages do not include Hioki power analysers on the motor inverter lines. Instead, Hioki instruments are installed at the battery (WP1), DC-DC converter (WP2), AC compressor (WP5), coolant heater (WP6), and battery heater (WP7). Motor-level power is inferred by subtracting Hioki-measured auxiliary loads from the Hioki battery power. This indirect measurement includes inverter switching losses; cable losses between the battery and the DC bus are not subtracted, but they are minimal. Three US06 tests (62009003, 62009019, 62009021) yield indirect motor-level net consumption of 167.6, 165.9, and 164.9 Wh/km (mean 166.1, SD = 1.4). The simulated value is 170.7 Wh/km, resulting in an error of +2.8%.

Independent validation of per-regime energy intensities is not feasible for either vehicle. For the Tesla, the CAN bus does not report regenerative braking torque, which prevents regime classification at each timestep during deceleration. For the Bolt, the indirect measurement does not resolve instantaneous motor power for per-regime binning. Agreement in total motor energy to within 1.9% for the Tesla and 2.8% for the Bolt constrains the per-regime intensity errors, as deviations in one regime must be offset by differences in another.

## 5. LMDI decomposition results

### 5.1 Cross-cycle analysis

Table 3 and Figure 5 report the motor-level regime shares for both vehicles across the evaluated drive cycles. For the Tesla Model 3 at g = 9.04, both the UDDS and HWFET cycles operate exclusively in the MTPA regime. The WLTP allocates 21.4% of its distance to field weakening, primarily within the Extra High sub-phase. The US06 assigns 36.3% to field weakening and 12.5% to the transition band. The Artemis Motorway 130 exhibits the highest field-weakening share at 70.3%, reflecting its sustained high-speed cruise characteristics.

For the Bolt EV, all evaluated cycles enter the field-weakening regime. The UDDS allocates 20.3% of its distance to field weakening, despite a maximum speed of 91.2 km/h, due to the Bolt's field-weakening onset at 88.4 km/h (Figure 2). Because distance accumulates in proportion to speed, intervals spent above the onset speed contribute disproportionately to the distance share. The transition share is 0.0% because the Bolt enters field weakening during high-torque acceleration transients at which the torque-dependent onset speed falls below the vehicle speed. The vehicle traverses the narrow transition band rapidly, producing a distance share below the 1% folding threshold (Section 3.2). The HWFET and US06 allocate 82.3% and 89.5% of their distances, respectively, to field weakening. This consistent field-weakening exposure contrasts with the Tesla, where the UDDS and HWFET cycles remain entirely within the MTPA regime.

Table 4 presents the cross-cycle LMDI decomposition for the Tesla at g = 9.04. The UDDS to US06 comparison yields a total difference of +53.1 Wh/km, with +41.2 Wh/km (78%) attributed to structural effects and +11.9 Wh/km (22%) to intensity. The structural term is dominant because the US06 introduces 36.3% field-weakening distance, which is absent in the UDDS. The comparison between UDDS and Artemis cycles results in an increase of 66.0 Wh/km, with 80% of this difference attributed to structural effects. This outcome reflects the greater proportion of field-weakening operation in the Artemis cycle. The Artemis cycle has not been validated against dynamometer data (Section 4); therefore, this finding represents a model prediction that extrapolates the structural trend observed in the four validated cycles.

The UDDS to HWFET comparison provides a diagnostic contrast. The total difference is +21.8 Wh/km, with zero structural contribution. Since both cycles operate exclusively in the MTPA regime at g = 9.04, the entire energy difference is attributed to intensity. The motor consumes more energy per kilometre at HWFET cruise speeds than at UDDS urban speeds, despite operating within the same regime. Figure 8 juxtaposes these contrasting decompositions: the per-timestep operating points on the torque-speed plane are shown alongside waterfall diagrams for the UDDS to US06 pair (78% structural) and the UDDS to HWFET pair (0% structural). Figure 9 presents the regime-tagged energy flow for both cycles as Sankey diagrams [84], in which stream widths are proportional to Wh/km and the regime split at the motor stage is visible.

For the Bolt EV, the UDDS to US06 comparison yields +69.7 Wh/km, with 54.9% attributed to structural effects. This lower structural share, compared to the Tesla (78%), occurs because the Bolt already operates in field weakening on the UDDS (20.3% field-weakening distance). The structural contrast between cycles is reduced when both cycles include field-weakening operation.

The sensitivity of the decomposition to regime boundary definitions is assessed [83] by applying five boundary definitions (Section 3.3) to the same Tesla g = 9.04 simulation data. Table 5 and Figure 6 report the UDDS to US06 structural share for each method. Under B1 (back-EMF limit), the structural share is 21%. Under B3 at 370 V (the baseline), it is 78%. Under B3 at 350 V, the structural share exceeds 100%, indicating a slightly negative intensity contribution, as a wider field-weakening band at lower voltage reduces per-regime intensity. The full span across all five methods is 82 percentage points. Net energy intensity remains constant across all five methods, confirming that boundary changes affect regime classification but do not alter total energy consumption. The choice of boundary method determines whether the UDDS to US06 difference is attributed to structure or intensity.

**Table 3.** Motor-level regime distance shares and net energy intensity. Tesla at g = 9.04; Bolt at g = 7.05. Transition band defined as the 5% speed interval below the CRG field-weakening onset. Transition shares below 1% are folded into the MTPA regime prior to decomposition (Section 3.2); this applies to the Bolt EV on the UDDS.

| Vehicle | Cycle | Net Wh/km | S_MTPA (%) | S_Trans (%) | S_FW (%) |
|---|---|---|---|---|---|
| Tesla | UDDS | 86.0 | 100.0 | 0.0 | 0.0 |
| Tesla | HWFET | 107.8 | 100.0 | 0.0 | 0.0 |
| Tesla | WLTP | 111.4 | 74.5 | 4.1 | 21.4 |
| Tesla | US06 | 139.1 | 51.2 | 12.5 | 36.3 |
| Tesla | Artemis MW130 | 152.0 | 20.5 | 9.2 | 70.3 |
| Bolt | UDDS | 101.0 | 79.7 | 0.0 | 20.3 |
| Bolt | HWFET | 125.8 | 9.9 | 7.8 | 82.3 |
| Bolt | WLTP | 134.9 | 47.0 | 1.9 | 51.1 |
| Bolt | US06 | 170.7 | 9.4 | 1.1 | 89.5 |

![Figure 5: Stacked bar chart of motor operating regime distance shares (MTPA, transition, field weakening) for four vehicle configurations across five drive cycles](../results/figures/png/Fig5_regime_shares.png)

**Table 4.** Cross-cycle LMDI-I decomposition (Wh/km, motor level). The structural share S indicates the proportion of the total difference attributable to changes in regime residence.

| Vehicle | Pair | Delta | Structural | Intensity | S share (%) |
|---|---|---|---|---|---|
| Tesla | UDDS to HWFET | +21.8 | 0.0 | +21.8 | 0 |
| Tesla | UDDS to WLTP | +25.4 | +19.3 | +6.2 | 75.7 |
| Tesla | UDDS to US06 | +53.1 | +41.2 | +11.9 | 77.6 |
| Tesla | UDDS to Artemis | +66.0 | +52.6 | +13.4 | 79.7 |
| Tesla | WLTP to Artemis | +40.6 | +34.7 | +5.9 | 85.5 |
| Bolt | UDDS to HWFET | +24.9 | +21.0 | +3.9 | 84.3 |
| Bolt | UDDS to US06 | +69.7 | +38.2 | +31.5 | 54.9 |
| Bolt | UDDS to WLTP | +33.9 | +19.1 | +14.8 | 56.3 |

All residuals below 4 x 10^-14 Wh/km. The UDDS to HWFET pair for the Tesla yields zero structural contribution because both cycles operate entirely within the MTPA regime at g = 9.04.

**Table 5.** Sensitivity of the UDDS to US06 decomposition to regime boundary definition. All five definitions are applied to the same Tesla g = 9.04 simulation data. The total energy difference (Delta = +53.1 Wh/km) is identical across all methods; only the structural-intensity partition changes.

| Method | Voltage (V) | US06 S_FW (%) | Structural (Wh/km) | Intensity (Wh/km) | S share (%) |
|---|---|---|---|---|---|
| B1 (back-EMF) | 370 | 6.4 | +11.1 | +42.0 | 20.9 |
| B2 (voltage at i_d = 0) | 370 | 13.4 | +37.8 | +15.2 | 71.3 |
| B3 (CRG) | 350 | 51.5 | +54.4 | -1.3 | 102.5 |
| B3 (CRG) | 370 | 36.3 | +41.2 | +11.9 | 77.6 |
| B3 (CRG) | 400 | 11.5 | +22.4 | +30.7 | 42.2 |

The structural share ranges from 20.9% (B1) to 102.5% (B3 at 350 V), a span of 82 percentage points. An S share exceeding 100% indicates a negative intensity contribution: a wider field-weakening band reduces per-regime intensity, offsetting the structural cost.

![Figure 6: Structural share of the UDDS to US06 energy difference under five boundary definitions, showing an 82 percentage point spread](../results/figures/png/Fig6_boundary_sensitivity.png)

![Figure 7: LMDI waterfall diagram for the UDDS to US06 pair, Tesla Model 3 at g = 9.04](../results/figures/png/Fig7_waterfall_UDDS_US06.png)

![Figure 8: Per-timestep operating points on the torque-speed plane for the UDDS and US06 cycles, with LMDI waterfall diagrams for UDDS to US06 (78% structural) and UDDS to HWFET (0% structural)](../results/figures/png/Fig8_centrepiece.png)

![Figure 9: Sankey energy flow diagrams for the UDDS and US06 cycles (Tesla Model 3, g = 9.04), showing gross traction energy splitting across motor operating regimes](../results/figures/png/Fig9_sankey.png)

### 5.2 Cross-vehicle comparison

Table 6 presents the cross-vehicle LMDI decomposition, comparing the Tesla Model 3 (g = 9.04) and the Bolt EV (g = 7.05) on identical drive cycles. In every case, the Bolt consumes more energy than the Tesla at the motor level.

On the HWFET, the Bolt consumes 18.0 Wh/km more than the Tesla, with 99.1% of this difference attributed to structural effects. This energy difference results from the Bolt operating in field weakening for 82.3% of the HWFET distance, while the Tesla remains in the MTPA regime. The WLTP yields a difference of +23.5 Wh/km, with 97.7% structural, and the US06 yields +31.6 Wh/km, with 88.1% structural.

The UDDS provides a contrasting result. The Bolt consumes 15.0 Wh/km more than the Tesla, but the structural share drops to 57.2%. The Bolt enters field weakening on the UDDS because its onset speed (88.4 km/h) falls below the cycle maximum (91.2 km/h). The Tesla, with an onset speed of 117.6 km/h, remains in MTPA. The smaller structural share on the UDDS results because the Bolt's field-weakening exposure is limited to a narrow speed band near the cycle peak, producing a modest structural contrast alongside a non-negligible intensity difference.

The Bolt features a lower gear ratio (7.05 versus 9.04), which would typically reduce motor speed and decrease field-weakening operation if all other parameters were identical. The Bolt's permanent magnet flux linkage (0.1017 Wb), DC bus voltage (350 V), and modulation index (0.904) produce a lower field-weakening onset speed compared to the Tesla's parameters (0.0772 Wb, 370 V, 1.10). Motor design parameters, rather than gear ratio, are the primary determinant of regime exposure for the two IPM machines evaluated.

The two vehicles differ in motor design, gear ratio, mass (1705 versus 1928 kg), aerodynamic drag area (CdA = 0.71 versus 0.51 m^2), and regenerative braking calibration. The structural term is unaffected by these differences, as distance shares depend solely on the speed profile and the field-weakening boundary curve, which are determined by motor electromagnetic parameters and gear ratio. In contrast, the intensity term incorporates both motor efficiency and demand-side differences between the vehicles. To quantify this confounding factor, the motor-to-wheel energy ratio (E_motor/W_wheel) was calculated for each vehicle and cycle, where W_wheel represents the integrated positive road-load power. On the US06 cycle, this ratio is 1.194 for both vehicles, indicating that the per-distance gap (31.6 Wh/km) is entirely due to the Bolt's higher wheel-energy demand (143 versus 117 Wh/km), attributable to its greater mass and aerodynamic drag. In the WLTP cycle, demand-side differences account for 80% of the 23.5 Wh/km gap, while motor-efficiency differences account for the remaining 20%. On the HWFET cycle, the Bolt is marginally more efficient per unit of wheel energy despite operating predominantly in field weakening, so the entire 18.0 Wh/km gap is demand-driven. On the UDDS cycle, where both vehicles exhibit similar wheel-energy demands at lower average speeds, motor-efficiency differences account for 74% of the 15.0 Wh/km gap. Per-distance normalisation was retained as the primary basis because it yields results in the conventional Wh/km metric and ensures comparability with published BEV energy studies. The structural shares presented in Table 6 quantify the combined effects of motor regime allocation and vehicle platform on per-distance consumption.

**Table 6.** Cross-vehicle LMDI-I decomposition (Wh/km, motor level). Comparison direction: Tesla Model 3 (g = 9.04) to Chevrolet Bolt EV (g = 7.05) on the same drive cycle. Positive values indicate higher consumption for the Bolt.

| Cycle | Delta | Structural | Intensity | S share (%) | Residual |
|---|---|---|---|---|---|
| UDDS | +14.96 | +8.55 | +6.41 | 57.2 | 6.3 x 10^-14 |
| HWFET | +18.02 | +17.86 | +0.17 | 99.1 | 9.4 x 10^-15 |
| US06 | +31.60 | +27.83 | +3.77 | 88.1 | 4.4 x 10^-14 |
| WLTP | +23.47 | +22.94 | +0.53 | 97.7 | 1.1 x 10^-14 |

On HWFET, US06, and WLTP, 88 to 99% of the motor-level energy difference between the two vehicles is structural. The Bolt operates in field weakening for 82.3% (HWFET), 89.5% (US06), and 51.1% (WLTP) of its distance, while the Tesla remains in the MTPA regime on HWFET and allocates 36.3% (US06) and 21.4% (WLTP) to field weakening.

![Figure 10: Structural and intensity contributions for each cross-vehicle cycle pair](../results/figures/png/Fig10_cross_vehicle.png)

### 5.3 Gear ratio design implications

Three gear ratios (7.0, 9.04, and 11.0) are evaluated for the Tesla Model 3 across all five drive cycles. The motor, battery, road load, and drive cycle remain constant in each scenario; only the gear ratio varies. Table 7 presents the motor-level net Wh/km and regime shares for each configuration.

Increasing the gear ratio from 7.0 to 11.0 results in higher motor-level net energy consumption across all cycles. The penalty ranges from +5.2 Wh/km on the UDDS to +14.4 Wh/km on the Artemis Motorway 130. The magnitude of this increase correlates with the extent of field-weakening exposure; the Artemis cycle, characterised by prolonged high-speed segments, produces the largest increase.

Table 8 and Figure 11 present the cross-gear LMDI decomposition. For cycles where the gear change introduces or significantly increases field-weakening operation, both structural and intensity terms are substantial and partially offsetting. On the US06, increasing the gear ratio from 7.0 to 11.0 results in a total penalty of +11.6 Wh/km, with a structural contribution of +59.4 Wh/km and an intensity contribution of -47.8 Wh/km. The structural term exceeds the total because shifting distance from MTPA to field weakening simultaneously reduces per-regime intensity, as the motor operates at partial load within a broader field-weakening band. The Artemis cycle exhibits a similar pattern: +14.4 Wh/km total, +40.2 structural, and -25.8 intensity.

For cycles where both gear ratios remain below the field-weakening onset, the gear penalty manifests solely as intensity. The UDDS at g = 7.0 and g = 9.04 operates entirely in the MTPA regime. The +2.7 Wh/km penalty is attributed entirely to intensity, as the motor operates at higher speed and torque for the same vehicle demand, resulting in increased per-kilometre losses within the same regime.

In high-speed cycles, increasing the gear ratio shifts motor operation into field weakening, resulting in a structural energy penalty. The magnitude of this penalty depends on the cycle's speed profile and the motor's field-weakening onset speed. The LMDI decomposition identifies which mechanism dominates for each cycle and gear ratio combination.

**Table 7.** Motor-level net energy intensity and field-weakening distance share for the Tesla Model 3 at three gear ratios. All vehicle, motor, road load, and drive cycle parameters are held constant; only the gear ratio varies.

| Cycle | Net g = 7.0 | S_FW g = 7.0 (%) | Net g = 9.04 | S_FW g = 9.04 (%) | Net g = 11.0 | S_FW g = 11.0 (%) |
|---|---|---|---|---|---|---|
| UDDS | 83.3 | 0 | 86.0 | 0 | 88.5 | 4.1 |
| HWFET | 103.0 | 0 | 107.8 | 0 | 113.3 | 29.7 |
| WLTP | 107.1 | 0 | 111.4 | 21.4 | 116.4 | 36.5 |
| US06 | 133.8 | 0 | 139.1 | 36.3 | 145.4 | 79.1 |
| Artemis MW130 | 146.4 | 0 | 152.0 | 70.3 | 160.8 | 85.9 |

Net energy intensity is in Wh/km at the motor level. At g = 7.0, all cycles operate below the field-weakening onset (151.9 km/h). At g = 11.0, field-weakening operation appears on all cycles, including the UDDS (onset 96.7 km/h).

**Table 8.** Cross-gear LMDI-I decomposition for the Tesla Model 3 (Wh/km, motor level). The UDDS at g = 7.0 to 9.04 is included to illustrate the pure-intensity case where both gear ratios remain below the field-weakening onset.

| Cycle | Gear pair | Delta | Structural | Intensity |
|---|---|---|---|---|
| UDDS | 7.0 to 9.04 | +2.7 | 0.0 | +2.7 |
| UDDS | 7.0 to 11.0 | +5.2 | +4.8 | +0.4 |
| HWFET | 7.0 to 11.0 | +10.2 | +9.3 | +0.9 |
| WLTP | 7.0 to 11.0 | +9.2 | +23.4 | -14.2 |
| US06 | 7.0 to 11.0 | +11.6 | +59.4 | -47.8 |
| Artemis MW130 | 7.0 to 11.0 | +14.4 | +40.2 | -25.8 |

On cycles where the gear change introduces field-weakening operation (WLTP, US06, Artemis), the structural and intensity contributions are both large and partially offsetting. The structural term exceeds the total because shifting distance into field weakening simultaneously reduces per-regime intensity. On cycles where both gear ratios remain in the MTPA regime (UDDS at g = 7.0 to 9.04), the entire penalty is attributed to intensity.

![Figure 11: Structural and intensity contributions to the cross-gear LMDI decomposition (g = 7.0 to 11.0) for five drive cycles](../results/figures/png/Fig11_cross_gear.png)

![Figure 12: Field-weakening distance share versus gear ratio for five drive cycles](../results/figures/png/Fig12_FW_vs_gear.png)

## 6. Discussion

Vehicle-level Wh/km serves as the standard metric for comparing battery electric vehicle energy consumption across various drive cycles and vehicles. While this metric provides an aggregate outcome, it does not reveal the underlying physical mechanisms responsible for differences in consumption. The LMDI decomposition addresses this limitation by separating the aggregate into two components: the structural term, which quantifies the extent to which differences arise from the distribution of distance across operating regimes, and the intensity term, which quantifies the contribution from changes in per-regime energy consumption.

Comparisons between the UDDS and HWFET, as well as the UDDS and US06 cycles for the Tesla Model 3, exemplify this distinction. In both cases, energy consumption increases on the more demanding cycle. The difference between UDDS and HWFET (+21.8 Wh/km) is attributable entirely to intensity, as both cycles operate within the MTPA regime, and the higher cruise speed of the HWFET increases per-kilometre losses within that regime. In contrast, the UDDS to US06 difference (+53.1 Wh/km) is 78% structural, since the US06 introduces field-weakening operation absent in the UDDS. Although vehicle-level Wh/km treats these as equivalent increases in consumption, the decomposition identifies that the underlying causes are fundamentally different.

A cross-vehicle comparison further supports this finding. The Bolt EV consumes between 18.0 and 31.6 Wh/km more energy than the Tesla Model 3 across matched cycles [77], with structural effects accounting for 88 to 99% of the difference in three out of four cycles. At the motor level, increased operation in the field-weakening regime is the primary channel through which this gap emerges, due to the Bolt's lower onset speed (88.4 km/h versus 117.6 km/h). The wheel-energy analysis (Section 5.2) identifies the underlying physical cause: on the US06 cycle, both demonstrate an identical motor-to-wheel energy ratio (1.194), indicating that the energy gap originates from Bolt's higher wheel-energy demand. Field-weakening operation is nearly energy-neutral per unit wheel energy for these two vehicles; the per-distance penalty arises because the heavier platform requires more energy at the wheel. The intensity term, which remains small in three of four cycles, encompasses both motor efficiency and demand-side differences.

The gear ratio sweep demonstrates the added value of the decomposition beyond per-regime energy reporting. On the US06 cycle, increasing the gear ratio from 7.0 to 11.0 raises motor-level consumption by 11.6 Wh/km. Table 7 shows that field-weakening distance increases from 0% to 79.1%. However, per-regime data alone cannot determine how much of the 11.6 Wh/km increase is due to the regime shift versus changes in within-regime efficiency. The LMDI decomposition attributes +59.4 Wh/km to structural changes and -47.8 Wh/km to intensity changes. The structural cost is five times the net penalty because the motor operates at partial load within the expanded field-weakening band, which reduces per-regime intensity and partially offsets the regime-shift cost. If field-weakening efficiency declines due to thermal loading or motor ageing, this offset decreases and the net penalty approaches the full structural value. This exposure is not visible in aggregate Wh/km comparisons. In general, a lower gear ratio avoids field-weakening during moderate-speed cycles but reduces available wheel torque. A higher gear ratio increases launch torque but results in a structural energy penalty during motorway and aggressive cycles. The LMDI decomposition quantifies this trade-off for each cycle and gear ratio combination, providing a basis for gear ratio selection [87] that accounts for the structural energy cost of regime transitions.

The regime shares presented in Table 3 indicate that a single vehicle can experience fundamentally different structural exposures depending on the drive cycle. For the Tesla Model 3 at a gear ratio of 9.04, both the UDDS and HWFET operate exclusively in the MTPA regime, whereas the Artemis Motorway 130 allocates 70.3% of distance to field-weakening operation. A regulatory assessment based solely on the UDDS would not capture the structural energy cost incurred by this vehicle under motorway conditions. In contrast, the Bolt EV demonstrates the opposite pattern: all evaluated cycles, including the UDDS, enter the field-weakening regime, so no regulatory cycle fully avoids the structural energy cost of field-weakening operation for this vehicle. The Artemis Motorway 130, based on measured European driving data, sustains speeds above the field-weakening onset for extended periods. Although the WLTP Extra High sub-phase reaches a comparable peak speed (131 km/h), it does not maintain sustained residence above the onset threshold. The 70.3% field-weakening share for the Tesla Model 3 on the Artemis cycle, compared with 21.4% on the WLTP and 0% on the UDDS, quantifies the discrepancy between regulatory and on-road structural exposure. This finding has implications for energy labelling and range estimation, as the choice of reference cycle determines whether the structural energy cost of field-weakening operation is reflected in the published consumption figure.

The decomposition results reported above use the CRG-derived boundary at 370 V (B3) as the baseline. As demonstrated in Section 5.1, the choice of boundary definition changes the UDDS to US06 structural share by 82 percentage points. Several findings remain robust to this choice. The structural term remains positive across all five methods, indicating that the US06 consistently incurs a structural energy cost from field-weakening operation, regardless of boundary definition. The UDDS to HWFET decomposition produces a zero structural contribution across all methods, as neither cycle attains field-weakening speeds under any boundary definition. The cross-vehicle comparison is similarly robust: both vehicles are assessed using the same boundary method, and the difference in field-weakening onset speed between the Tesla and the Bolt (118 km/h versus 88 km/h) exceeds the sensitivity range of any single boundary definition. However, the precise structural share for the UDDS to US06 pair (78% under B3 at 370 V) is not robust to the boundary definition. Under B3 voltage assumptions, this share varies from 42% to 103%. Across all five methods, the range is 21% to 103%. Whether the structural term constitutes a majority of the energy difference depends on the boundary definition employed.

Several limitations should be acknowledged in this study. The dynamometer data are recorded at 10 Hz, resulting in sub-second transients in torque and current being averaged within each sample. For the Tesla Model 3, iron losses are calculated from d-q current lookup tables during post-processing, rather than from coupled electromagnetic simulations. For the Bolt EV, motor parameters such as permanent magnet flux linkage and stator resistance are obtained from published finite element analysis and benchmarking reports [71–73], not from direct motor testing. The traction driver employs a proportional-integral controller to track the reference speed profile, which does not replicate the full range of human driving variability, including anticipatory braking and variable pedal modulation. Additionally, the analysis is restricted to single-speed drivetrains; multi-speed or continuously variable transmissions would necessitate additional regime definitions and a revised structural decomposition framework.

The Artemis Motorway 130 results extend the model into sustained field-weakening operation for 70.3% of the distance, surpassing the previously validated maximum share of 36.3% observed on the US06. Several factors reinforce confidence in this extrapolation. The d-q motor model and CRG-derived boundary are continuous functions of speed and torque, with no parameter discontinuity at elevated motor speeds. The WLTP Extra High sub-phase, which encompasses sustained cruising above the field-weakening threshold, demonstrates a validation error of +0.2% (154.6 versus 154.2 Wh/km). Road load, battery equivalent circuit, and regenerative braking logic are each validated independently of the motor operating regime. However, direct measurement confirmation at the 70.3% field-weakening share remains unavailable, and the Artemis results should be regarded as computed predictions rather than validated outcomes.

## 7. Conclusion

LMDI-I decomposition was applied within the battery electric vehicle powertrain, partitioning drive cycle energy consumption into structural effects (regime residence) and intensity effects (per-regime efficiency) for two production vehicles validated across four drive cycles and extended to a fifth.

For the Tesla Model 3 at a gear ratio of 9.04, structural effects account for 78% of the 53.1 Wh/km difference between the UDDS and US06 cycles under the baseline boundary definition (B3 at 370 V). The difference between UDDS and HWFET cycles (+21.8 Wh/km) is entirely due to intensity, confirming that the decomposition distinguishes regime-shift energy costs from within-regime efficiency changes. Cross-vehicle comparisons on matched cycles attribute 88 to 99% of the motor-level energy difference between the Tesla and Bolt EV to structural effects on three of four cycles. The Bolt EV enters field-weakening operation at 88.4 km/h, compared with 117.6 km/h for the Tesla, despite a lower gear ratio (7.05 versus 9.04). For the two IPM machines evaluated, motor design parameters are the primary determinant of regime exposure.

The regime boundary method alters energy attribution by as much as 82 percentage points for identical simulation data. Three boundary methods with increasing physical realism, supplemented by voltage sensitivity at three DC bus levels, yield five definitions that produce the same net energy consumption but partition it differently between the structural and intensity terms. The regime boundary represents an energy accounting decision with significant consequences for attribution.

An increase in gear ratio from 7.0 to 11.0 raises motor-level consumption by 5.2 to 14.4 Wh/km, depending on the drive cycle. On high-speed cycles, the structural and intensity contributions are both substantial and partially offsetting. For example, on the US06 cycle, the structural term is +59.4 Wh/km and the intensity term is -47.8 Wh/km, resulting in a net penalty of +11.6 Wh/km. The net consumption figure alone understates the structural cost associated with the regime shift.

Model estimates for the Artemis Motorway 130, which does not include a dynamometer validation target, show that the Tesla operates in the field-weakening regime for 70.3% of the distance. This contrasts with 21.4% on the WLTP and 0% on the UDDS. Regulatory cycles that rely on urban and suburban speed profiles fail to account for the structural energy cost associated with field-weakening operation during motorway conditions. The decomposition provides a quantitative diagnostic for linking drive cycle definition, motor design, and transmission gearing to energy consumption in battery electric vehicles.

Future research will extend the decomposition to multi-speed drivetrains [43, 46], incorporate thermal effects on motor parameters [70], and apply the method to on-road driving data recorded under varying ambient conditions [18, 19].

---

## References

1. Ang BW. Decomposition analysis for policymaking in energy: which is the preferred method? *Energy Policy* 2004;32(9):1131-1139. https://doi.org/10.1016/S0301-4215(03)00076-4
2. Ang BW. The LMDI approach to decomposition analysis: a practical guide. *Energy Policy* 2005;33(7):867-871. https://doi.org/10.1016/j.enpol.2003.10.010
3. Ang BW. LMDI decomposition approach: a guide for implementation. *Energy Policy* 2015;86:233-238. https://doi.org/10.1016/j.enpol.2015.07.007
4. Ang BW, Liu N. Handling zero values in the logarithmic mean Divisia index decomposition approach. *Energy Policy* 2007;35(1):238-246. https://doi.org/10.1016/j.enpol.2005.11.001
5. Ang BW, Xu XY, Su B. Multi-country comparisons of energy performance: the index decomposition analysis approach. *Energy Economics* 2015;47:68-76. https://doi.org/10.1016/j.eneco.2014.10.011
6. Choi KH, Ang BW. Attribution of changes in Divisia real energy intensity index -- an extension to index decomposition analysis. *Energy Economics* 2012;34(1):171-176. https://doi.org/10.1016/j.eneco.2011.04.011
7. Xu XY, Ang BW. Analysing residential energy consumption using index decomposition analysis. *Applied Energy* 2014;113:342-351. https://doi.org/10.1016/j.apenergy.2013.07.052
8. Roux N, Plank B. The misinterpretation of structure effects of the LMDI and an alternative index decomposition. *MethodsX* 2022;9:101698. https://doi.org/10.1016/j.mex.2022.101698
9. Zhang M, Li H, Zhou M, Mu H. Decomposition analysis of energy consumption in Chinese transportation sector. *Applied Energy* 2011;88(6):2279-2285. https://doi.org/10.1016/j.apenergy.2010.12.077
10. Liu M, Zhang X, Zhang M, Feng Y, Liu Y, Wen J, Liu L. Influencing factors of carbon emissions in transportation industry based on CD function and LMDI decomposition model: China as an example. *Environmental Impact Assessment Review* 2021;90:106623. https://doi.org/10.1016/j.eiar.2021.106623
11. Achour H, Belloumi M. Decomposing the influencing factors of energy consumption in Tunisian transportation sector using the LMDI method. *Transport Policy* 2016;52:64-71. https://doi.org/10.1016/j.tranpol.2016.07.008
12. Jain S, Rankavat S. Analysing driving factors of India's transportation sector CO2 emissions: based on LMDI decomposition method. *Heliyon* 2023;9(9):e19871. https://doi.org/10.1016/j.heliyon.2023.e19871
13. Kim S. Decomposition analysis of greenhouse gas emissions in Korea's transportation sector. *Sustainability* 2019;11(7):1986. https://doi.org/10.3390/su11071986
14. Solaymani S. CO2 emissions patterns in 7 top carbon emitter economies: the case of transport sector. *Energy* 2019;168:989-1001. https://doi.org/10.1016/j.energy.2018.11.145
15. Gu J, Jiang S, Zhang J, Jiang J. An analysis of the decomposition and driving force of carbon emissions in transport sector in China. *Scientific Reports* 2024;14(1):30177. https://doi.org/10.1038/s41598-024-80486-z
16. Goh T, Ang BW, Su B, Wang H. Drivers of stagnating global carbon intensity of electricity and the way forward. *Energy Policy* 2018;113:149-156. https://doi.org/10.1016/j.enpol.2017.10.058
17. Xie Y, Li Y, Zhao Z, Dong H, Wang S, Liu J, Guan J, Duan X. Microsimulation of electric vehicle energy consumption and driving range. *Applied Energy* 2020;267:115081. https://doi.org/10.1016/j.apenergy.2020.115081
18. Miri I, Fotouhi A, Ewin N. Electric vehicle energy consumption modelling and estimation -- a case study. *International Journal of Energy Research* 2021;45(1):501-520. https://doi.org/10.1002/er.5700
19. Zhai Z, Zhang L, Song G, Li X, Yu L. Modeling energy consumption for battery electric vehicles based on in-use vehicle trajectories. *Transportation Research Part D* 2024;137:104509. https://doi.org/10.1016/j.trd.2024.104509
20. Castillo-Calderon J, Larrode-Pellicer E. Energy consumption prediction in battery electric vehicles: a systematic literature review. *Energies* 2026;19(2):371. https://doi.org/10.3390/en19020371
21. Achariyaviriya W, Wongsapai W, Janpoom K, Katongtung T, Mona Y, Tippayawong N, Suttakul P. Estimating energy consumption of battery electric vehicles using vehicle sensor data and machine learning approaches. *Energies* 2023;16(17):6351. https://doi.org/10.3390/en16176351
22. Fiori C, Ahn K, Rakha HA. Power-based electric vehicle energy consumption model: model development and validation. *Applied Energy* 2016;168:257-268. https://doi.org/10.1016/j.apenergy.2016.01.097
23. De Cauwer C, Van Mierlo J, Coosemans T. Energy consumption prediction for electric vehicles based on real-world data. *Energies* 2015;8(8):8573-8593. https://doi.org/10.3390/en8088573
24. Galvin R. Energy consumption effects of speed and acceleration in electric vehicles: laboratory case studies and implications for drivers and policymakers. *Transportation Research Part D* 2017;53:234-248. https://doi.org/10.1016/j.trd.2017.04.020
25. Karabasoglu O, Michalek J. Influence of driving patterns on life cycle cost and emissions of hybrid and plug-in electric vehicle powertrains. *Energy Policy* 2013;60:445-461. https://doi.org/10.1016/j.enpol.2013.03.047
26. Wu X, Freese D, Cabez A, Kitch WA. Electric vehicles energy consumption measurement and estimation. *Transportation Research Part D* 2015;34:52-67. https://doi.org/10.1016/j.trd.2014.10.007
27. Mruzek M, Gajdac I, Kucera L, Barta D. Analysis of parameters influencing electric vehicle range. *Procedia Engineering* 2016;134:165-174. https://doi.org/10.1016/j.proeng.2016.01.056
28. Yuksel T, Michalek JJ. Effects of regional temperature on electric vehicle efficiency, range, and emissions in the United States. *Environmental Science and Technology* 2015;49(6):3228-3235. https://doi.org/10.1021/es505621s
29. Grunditz EA, Thiringer T. Performance analysis of current BEVs based on a comprehensive review of specifications. *IEEE Transactions on Transportation Electrification* 2016;2(3):270-289. https://doi.org/10.1109/TTE.2016.2571783
30. Morimoto S, Takeda Y, Hirasa T, Taniguchi K. Expansion of operating limits for permanent magnet motor by current vector control considering inverter capacity. *IEEE Transactions on Industry Applications* 1990;26(5):866-871. https://doi.org/10.1109/28.60058
31. Bianchi N, Bolognani S, Chalmers BJ. Salient-rotor PM synchronous motors for an extended flux-weakening operation range. *IEEE Transactions on Industry Applications* 2000;36(4):1118-1125. https://doi.org/10.1109/28.855968
32. Soong WL, Miller TJE. Field-weakening performance of brushless synchronous AC motor drives. *IEE Proceedings -- Electric Power Applications* 1994;141(6):331-340. https://doi.org/10.1049/ip-epa:19941470
33. Zhu ZQ, Howe D. Electrical machines and drives for electric, hybrid, and fuel cell vehicles. *Proceedings of the IEEE* 2007;95(4):746-765. https://doi.org/10.1109/JPROC.2006.892482
34. Williamson SS, Rathore AK, Musavi F. Industrial electronics for electric transportation: current state-of-the-art and future challenges. *IEEE Transactions on Industrial Electronics* 2015;62(5):3021-3032. https://doi.org/10.1109/TIE.2015.2409052
35. Pellegrino G, Vagati A, Boazzo B, Guglielmi P. Comparison of induction and PM synchronous motor drives for EV application including design examples. *IEEE Transactions on Industry Applications* 2012;48(6):2322-2332. https://doi.org/10.1109/TIA.2012.2227092
36. Jahns TM, Kliman GB, Neumann TW. Interior permanent-magnet synchronous motors for adjustable-speed drives. *IEEE Transactions on Industry Applications* 1986;IA-22(4):738-747. https://doi.org/10.1109/TIA.1986.4504786
37. Niazi P, Toliyat HA, Cheong D, Kim JC. A low-cost and efficient permanent-magnet-assisted synchronous reluctance motor drive. *IEEE Transactions on Industry Applications* 2007;43(2):542-550. https://doi.org/10.1109/TIA.2006.890033
38. Reddy PB, El-Refaie AM, Huh KK, Tangudu JK, Jahns TM. Comparison of interior and surface PM machines equipped with fractional-slot concentrated windings for hybrid traction applications. *IEEE Transactions on Energy Conversion* 2012;27(3):593-602. https://doi.org/10.1109/TEC.2012.2195316
39. Nguyen QD, Nguyen HP, Vo DN, Nguyen LT, Nguyen ST. Effect of battery voltage variation on electric vehicle performance driven by induction machine with optimal flux-weakening strategy. *IET Electrical Systems in Transportation* 2020;10(4):301-308. https://doi.org/10.1049/iet-est.2020.0013
40. Niu S, Qiu H. The optimal design and research of interior permanent magnet synchronous motors for electric vehicle applications. *The Journal of Engineering* 2023;2023(4):e12258. https://doi.org/10.1049/tje2.12258
41. Spanoudakis P, Moschopoulos G, Stefanoulis T, Sarantinoudis N, Papadokokolakis E, Ioannou I, Piperidis S, Doitsidis L, Tsourveloudis NC. Efficient gear ratio selection of a single-speed drivetrain for improved electric vehicle energy consumption. *Sustainability* 2020;12(21):9254. https://doi.org/10.3390/su12219254
42. Ren Q, Crolla DA, Morris A. Effect of transmission design on electric vehicle (EV) performance. *Vehicle Power and Propulsion Conference (VPPC)*, IEEE, 2009;3508-3513. https://doi.org/10.1109/VPPC.2009.5289707
43. Gao B, Liang Q, Xiang Y, Guo L, Chen H. Gear ratio optimization and shift control of 2-speed I-AMT in electric vehicle. *Mechanical Systems and Signal Processing* 2015;50–51:615-631. https://doi.org/10.1016/j.ymssp.2014.05.045
44. Hofman T, Dai CH. Energy efficiency analysis and comparison of transmission technologies for an electric vehicle. *Vehicle Power and Propulsion Conference (VPPC)*, IEEE, 2010;1-6. https://doi.org/10.1109/VPPC.2010.5729082
45. Srivastava N, Haque I. A review on belt and chain continuously variable transmissions (CVT): dynamics and control. *Mechanism and Machine Theory* 2009;44(1):19-41. https://doi.org/10.1016/j.mechmachtheory.2008.06.007
46. Di Nicola F, Sorniotti A, Holdstock T, Viotto F, Bertolotto S. Optimization of a multiple-speed transmission for downsizing the motor of a fully electric vehicle. *SAE International Journal of Alternative Powertrains* 2012;1(1):134-143. https://doi.org/10.4271/2012-01-0630
47. Yenipinar B, Ocak C, Dalcali A. Impact of gear ratios on drive cycle efficiency and thermal performance in lightweight EVs. *International Journal of Numerical Modelling* 2026;39(1):e70149. https://doi.org/10.1002/jnm.70149
48. Geng C, Ning D, Guo L, Xue Q, Mei Y. Simulation research on regenerative braking control strategy of hybrid electric vehicle. *Energies* 2021;14(8):2202. https://doi.org/10.3390/en14082202
49. Jiang B, Zhang X, Wang Y, Hu W. Regenerative braking control strategy of electric vehicles based on braking stability requirements. *International Journal of Automotive Technology* 2021;22(2):465-473. https://doi.org/10.1007/s12239-021-0043-1
50. Li W, Xu H, Liu X, Wang Y, Zhu Y, Lin X, Wang Z, Zhang Y. Regenerative braking control strategy for pure electric vehicles based on fuzzy neural network. *Ain Shams Engineering Journal* 2023;15(1):102430. https://doi.org/10.1016/j.asej.2023.102430
51. Yin Z, Ma X, Zhang C, Su R, Wang Q. A logic threshold control strategy to improve the regenerative braking energy recovery of electric vehicles. *Sustainability* 2023;15(24):16850. https://doi.org/10.3390/su152416850
52. Nguyen Thi A, Chen CK, Liu X. An efficient regenerative braking system for electric vehicles based on a fuzzy control strategy. *Vehicles* 2024;6(3):1496-1512. https://doi.org/10.3390/vehicles6030071
53. Lv C, Zhang J, Li Y, Yuan Y. Mechanism analysis and evaluation methodology of regenerative braking contribution to energy efficiency improvement of electrified vehicles. *Energy Conversion and Management* 2015;92:469-482. https://doi.org/10.1016/j.enconman.2014.12.092
54. Qiu C, Wang G, Meng M, Shen YJ. A novel control strategy of regenerative braking system for electric vehicles under safety critical driving situations. *Energy* 2018;149:329-340. https://doi.org/10.1016/j.energy.2018.02.046
55. Wager G, Whale J, Braunl T. Performance evaluation of regenerative braking systems. *Proceedings of the Institution of Mechanical Engineers, Part D: Journal of Automobile Engineering* 2018;232(10):1414-1427. https://doi.org/10.1177/0954407017728651
56. Zhang J, Lv C, Gou J, Kong D. Cooperative control of regenerative braking and hydraulic braking of an electrified passenger car. *Proceedings of the Institution of Mechanical Engineers, Part D* 2012;226(10):1289-1302. https://doi.org/10.1177/0954407012441884
57. Xu G, Li W, Xu K, Song Z. An intelligent regenerative braking strategy for electric vehicles. *Energies* 2011;4(9):1461-1477. https://doi.org/10.3390/en4091461
58. Andre M. The ARTEMIS European driving cycles for measuring car pollutant emissions. *Science of the Total Environment* 2004;334-335:73-84. https://doi.org/10.1016/j.scitotenv.2004.04.070
59. Tutuianu M, Bonnel P, Ciuffo B, Haniu T, Ichikawa N, Marotta A, Pavlovic J, Steven H. Development of the World-wide harmonized Light duty Test Cycle (WLTC) and a possible pathway for its introduction in the European legislation. *Transportation Research Part D* 2015;40:61-75. https://doi.org/10.1016/j.trd.2015.07.011
60. Tsiakmakis S, Fontaras G, Cubito C, Pavlovic J, Anagnostopoulos K, Ciuffo B. From NEDC to WLTP: effect on the type-approval CO2 emissions of light-duty vehicles. *JRC Technical Reports*, European Commission, 2017. https://doi.org/10.2760/93419
61. Pavlovic J, Marotta A, Ciuffo B. CO2 emissions and energy demands of vehicles tested under the NEDC and the new WLTP type approval test procedures. *Applied Energy* 2016;177:661-670. https://doi.org/10.1016/j.apenergy.2016.05.110
62. Fontaras G, Zacharof NG, Ciuffo B. Fuel consumption and CO2 emissions from passenger cars in Europe -- laboratory versus real-world emissions. *Progress in Energy and Combustion Science* 2017;60:97-131. https://doi.org/10.1016/j.pecs.2016.12.004
63. Barlow TJ, Latham S, McCrae IS, Boulter PG. A reference book of driving cycles for use in the measurement of road vehicle emissions. TRL Published Project Report PPR354, 2009. https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/4247/ppr-354.pdf
64. Tsiakmakis S, Fontaras G, Anagnostopoulos K, Ciuffo B, Pavlovic J, Marotta A. A simulation-based methodology for quantifying European passenger car fleet CO2 emissions. *Applied Energy* 2017;199:447-465. https://doi.org/10.1016/j.apenergy.2017.04.045
65. Cubito C, Millo F, Boccardo G, Di Pierro G, Ciuffo B, Fontaras G, Serra S, Otura Garcia M, Trentadue G. Impact of different driving cycles and operating conditions on CO2 emissions and energy management strategies of a Euro-6 hybrid electric vehicle. *Energies* 2017;10(10):1590. https://doi.org/10.3390/en10101590
66. Carlson R, Lohse-Busch H, Duoba M, Shidore N. Drive cycle fuel consumption variability of plug-in hybrid electric vehicles due to aggressive driving. *SAE Technical Paper* 2009;2009-01-1335. https://doi.org/10.4271/2009-01-1335
67. Kim N, Duoba M, Kim N, Rousseau A. Validating volt PHEV model with dynamometer test data using Autonomie. *SAE International Journal of Passenger Cars* 2013;6(2):985-992. https://doi.org/10.4271/2013-01-1458
68. Argonne National Laboratory. Downloadable Dynamometer Database (D3). Available at: https://www.anl.gov/taps/downloadable-dynamometer-database (accessed July 2026).
69. Lohse-Busch H, Duoba M, Rask E, Stutenberg K, Gowri V, Slezak L, Anderson D. Ambient temperature (20F, 72F and 95F) impact on fuel and energy consumption for several conventional vehicles, hybrid and plug-in hybrid electric vehicles and battery electric vehicle. *SAE Technical Paper* 2013;2013-01-1462. https://doi.org/10.4271/2013-01-1462
70. Al Haddad R, Mansour C, Kim N, Seo J, Nemer M. Comparative analysis of thermal management systems in electric vehicles at extreme weather conditions: case study on Nissan Leaf 2019 Plus, Chevrolet Bolt 2020 and Tesla Model 3 2020. *Energy Conversion and Management* 2025;326:119706. https://doi.org/10.1016/j.enconman.2025.119706
71. Burress TA, Campbell SL, Coomer CL, Ayers CW, Wereszczak AA, Cunningham JP, Marlino LD, Seiber LE, Lin HT. Evaluation of the 2010 Toyota Prius hybrid synergy drive system. ORNL/TM-2010/253, Oak Ridge National Laboratory, 2011.
72. Hsu JS. Report on Toyota/Prius motor torque-capability, torque-property, no-load back EMF, and mechanical losses. ORNL/TM-2004/185, Oak Ridge National Laboratory, 2004.
73. Burress TA, Campbell S. Benchmarking EV and HEV power electronics and electric machines. *IEEE Transportation Electrification Conference and Expo (ITEC)*, 2013;1-6. https://doi.org/10.1109/ITEC.2013.6574498
74. Rahman KM, Jurkovic S, Stancu C, Morgante J, Savagian PJ. Design and performance of electrical propulsion system of extended range electric vehicle (EREV) Chevrolet Volt. *IEEE Transactions on Industry Applications* 2015;51(3):2479-2488. https://doi.org/10.1109/TIA.2014.2363015
75. Momen F, Rahman KM, Son Y, Savagian PJ. Electric motor design of General Motors' Chevrolet Bolt electric vehicle. *SAE International Journal of Alternative Powertrains* 2016;5(2):286-293. https://doi.org/10.4271/2016-01-1228
76. Husain I, Ozpineci B, Islam MS, Gurpinar E, Su GJ, Yu W, Chowdhury S, Xue L, Rahman D, Sahu R. Electric drive technology trends, challenges, and opportunities for future electric vehicles. *Proceedings of the IEEE* 2021;109(6):1039-1059. https://doi.org/10.1109/JPROC.2020.3046112
77. Wolff S, Kalt S, Bstieler M, Lienkamp S. Quantifying the state of the art of electric powertrains in battery electric vehicles: comprehensive analysis of the Tesla Model 3 on the vehicle level. *World Electric Vehicle Journal* 2024;15(6):268. https://doi.org/10.3390/wevj15060268
78. US Department of Energy. Electric Drive Technical Team Roadmap. March 2024.
79. Boldea I, Tutelea LN, Parsa L, Dorrell D. Automotive electric propulsion systems with reduced or no permanent magnets: an overview. *IEEE Transactions on Industrial Electronics* 2014;61(10):5696-5711. https://doi.org/10.1109/TIE.2014.2301754
80. Dorrell DG, Knight AM, Popescu M, Evans L, Staton DA. Comparison of different motor design drives for hybrid electric vehicles. *Energy Conversion Congress and Exposition (ECCE)*, IEEE, 2010;3352-3359. https://doi.org/10.1109/ECCE.2010.5618318
81. El-Refaie AM. Motors/generators for traction/propulsion applications: a review. *IEEE Vehicular Technology Magazine* 2013;8(1):90-99. https://doi.org/10.1109/MVT.2012.2218438
82. Ozpineci B. Oak Ridge National Laboratory annual progress report for the power electronics and electric motors program. ORNL/TM-2014/598, 2015.
83. Saltelli A, Ratto M, Andres T, Campolongo F, Cariboni J, Gatelli D, Saisana M, Tarantola S. Global sensitivity analysis: the primer. John Wiley and Sons, 2008.
84. Schmidt M. The Sankey diagram in energy and material flow management. *Journal of Industrial Ecology* 2008;12(1):82-94. https://doi.org/10.1111/j.1530-9290.2008.00004.x
85. Ceraolo M, Lutzemberger G, Huria T. Experimentally determined models for high-power lithium batteries. *SAE Technical Paper* 2011;2011-01-1365. https://doi.org/10.4271/2011-01-1365
86. Mahmoudi A, Soong WL, Pellegrino G, Armando E. Loss function modeling of efficiency maps of electric machines. *IEEE Transactions on Industry Applications* 2017;53(5):4221-4231. https://doi.org/10.1109/TIA.2017.2695443
87. Ramakrishnan K, Stipetic S, Gobbi M, Mastinu G. Multi-objective optimization of electric vehicle powertrain using scalable saturated motor model. *Energies* 2019;12(23):4490. https://doi.org/10.3390/en12234490
88. Hentunen A, Lehmuspelto T, Suomela J. Time-domain parameter extraction method for Thevenin-equivalent circuit battery models. *IEEE Transactions on Energy Conversion* 2014;29(3):558-566. https://doi.org/10.1109/TEC.2014.2318205
89. He H, Xiong R, Fan J. Evaluation of lithium-ion battery equivalent circuit models for state of charge estimation by an experimental approach. *Energies* 2011;4(4):582-598. https://doi.org/10.3390/en4040582
90. Plett GL. Extended Kalman filtering for battery management systems of LiPB-based HEV battery packs: Part 3. State and parameter estimation. *Journal of Power Sources* 2004;134(2):277-292. https://doi.org/10.1016/j.jpowsour.2004.02.033
91. Hu X, Li S, Peng H. A comparative study of equivalent circuit models for Li-ion batteries. *Journal of Power Sources* 2012;198:359-367. https://doi.org/10.1016/j.jpowsour.2011.10.013
92. Ehsani M, Gao Y, Longo S, Ebrahimi K. Modern electric, hybrid electric, and fuel cell vehicles: fundamentals, theory, and design. 3rd ed. CRC Press, 2018.
93. Mohan N. Advanced electric drives: analysis, control, and modeling using MATLAB/Simulink. John Wiley and Sons, 2014.
94. Krishnan R. Permanent magnet synchronous and brushless DC motor drives. CRC Press, 2010.
95. Larminie J, Lowry J. Electric vehicle technology explained. 2nd ed. John Wiley and Sons, 2012.
96. Chau KT. Electric vehicle machines and drives: design, analysis and application. John Wiley and Sons, 2015.
97. Patel HD, Deshpande Y, Patel VN, Thakar V, Panchal S, Fraser R, Fowler M. Teardown analysis and FEA motor model of Chevrolet Bolt EV drivetrain. *2025 IEEE/AIAA Transportation Electrification Conference and Electric Aircraft Technologies Symposium (ITEC+EATS)*, IEEE, 2025;1-6.
98. Lan Y, Frikha MA, Croonen J, Benomar Y, El Baghdadi M, Hegazy O. Design optimization of a switched reluctance machine with an improved segmental rotor for electric vehicle applications. *Energies* 2022;15(16):5772. https://doi.org/10.3390/en15165772

---

## Acknowledgements

The authors gratefully acknowledge Argonne National Laboratory for making the D3 dynamometer dataset publicly available. The work was conducted during an industrial placement at the University of East London, School of Architecture, Computing and Engineering.

## Funding

This research did not receive any specific grant from funding agencies in the public, commercial, or not-for-profit sectors.

## CRediT authorship contribution statement

Faisal Shah Khan: Conceptualisation, Methodology, Software, Validation, Formal analysis, Investigation, Data curation, Writing -- original draft, Visualisation. Thamo Sutharssan: Supervision, Writing -- review and editing.

## Declaration of competing interest

The authors declare that they have no known competing financial interests or personal relationships that could have appeared to influence the work reported in this paper.

## Code availability

The Simulink models (AE_TeslaM3_LMDI.slx, AE_BoltEV_LMDI.slx), parameter files (AE_TeslaM3_LMDI_Params.m, AE_BoltEV_LMDI_Params.m), LMDI decomposition scripts (AE_lmdi_decomposition.m, AE_regime_binning.m, AE_run_LMDI_matrix.m), and figure generation scripts are publicly available at: https://github.com/Faisal-dev-pro/BEV-LMDI-Paper-B. The repository includes a version-tagged release corresponding to the simulation results reported in this paper.

## Data availability

The ANL D3 dynamometer test data used for model validation are publicly available from the Argonne National Laboratory Downloadable Dynamometer Database [67]. Battery-level validation targets (Table 2) were obtained from the 2020 Tesla Model 3 Long Range AWD and the 2020 Chevrolet Bolt EV test records. The motor-level test identifiers used for Hioki power analyser validation are listed in Section 4.3. All post-processing scripts required to reproduce the LMDI decomposition from the raw ANL data are included in the GitHub repository above.

## Declaration of generative AI and AI-assisted technologies in the writing process

During the preparation of this manuscript the authors used AI-assisted language tools (Claude, Anthropic) and Grammarly to improve readability and to check phrasing. All scientific content, analysis, numerical results, and conclusions were produced entirely by the authors. The authors reviewed and edited all AI-assisted text and take full responsibility for the content of this publication.

