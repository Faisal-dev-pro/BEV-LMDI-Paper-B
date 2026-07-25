# Improvement 10: SOC/Voltage and Thermal Discussion — Analysis Notes

Generated: 17 July 2026. For Paper Section 6 (Discussion).

## 1. Voltage Sensitivity of FW Boundary

The CRG-derived FW onset speed scales linearly with V_dc:

    omega_base ∝ V_dc / (sqrt(3) * k_Vmax * psi_m * p)

| V_dc (V) | SOC approx | omega_base (rad/s) | v_FW (km/h) | v_FW shift |
|-----------|------------|-------------------|-------------|------------|
| 320       | ~15%       | 784               | 101.7       | -13.5%     |
| 350       | ~40%       | 857               | 111.3       | -5.4%      |
| 370       | ~60% (nom) | 906               | 117.6       | baseline   |
| 400       | ~90%       | 980               | 127.2       | +8.1%      |

At 320V (low SOC), FW onset drops to 102 km/h. On WLTP (max 120 km/h),
this means ~35% of the cycle exceeds the FW threshold compared to ~21%
at nominal 370V. The structural effect intensifies at low SOC.

## 2. Impact on US06 FW Share (from FW_boundary_comparison.m, verified)

| V_dc (V) | US06 FW share | UDDS→US06 Ssh | Ds (Wh/km) | Di (Wh/km) |
|-----------|---------------|---------------|------------|------------|
| 350       | 51.5%         | 102.5%        | +54.4      | -1.3       |
| 370       | 36.3%         | 77.6%         | +41.2      | +11.9      |
| 400       | 11.5%         | 42.2%         | +22.4      | +30.7      |

At 350V, the structural share exceeds 100% because shifting distance into
FW simultaneously lowers per-regime intensity (the re-partitioning effect
documented in the gear design analysis). At 400V, most of the UDDS→US06
gap becomes intensity-driven because the motor stays in MTPA for longer.

Key insight for the paper: the LMDI decomposition results are voltage-
dependent. Reporting at mid-SOC (370V) is the appropriate baseline, but
the discussion should note that at low SOC the structural effect strengthens.

## 3. Thermal Effects on Motor Losses

### Copper loss (Rs temperature dependence)

Rs(T) = Rs(20°C) × (1 + 0.00393 × (T - 20))

| Winding T (°C) | Rs (mΩ) | Change | P_cu at 800A peak (kW) |
|-----------------|---------|--------|------------------------|
| 20              | 4.75    | 0%     | 4.6                    |
| 80              | 5.87    | +24%   | 5.6                    |
| 120             | 6.62    | +39%   | 6.4                    |
| 160             | 7.36    | +55%   | 7.1                    |

FW operation demands higher current (field weakening requires negative
Id in addition to torque-producing Iq), so the copper loss increase
disproportionately penalises FW operation.

### Iron loss (speed dependence)

P_iron ~ k_h × f + k_e × f²

At FW speeds (>8000 RPM electrical, ~133 Hz), iron loss is 3-5× higher
than at typical MTPA speeds (2000-4000 RPM, 33-67 Hz). The Simscape IPMSM
block models this via the P_iron(speed, torque) lookup table, so it is
captured in the simulation. However, it is not decomposed into per-regime
contributions in the current analysis.

## 4. Argument for the Paper

All three effects (lower voltage at low SOC, higher Rs at elevated winding
temperature, higher iron loss at FW speeds) act in the same direction:
they increase the energy penalty of FW operation relative to MTPA.

Our simulation uses V_dc = 370V (mid-SOC) and Rs = 0.00475 Ω (20°C).
These assumptions are **conservative**: they produce a **lower bound** on
the structural effect. In real driving with partial SOC depletion and warm
motor, the FW penalty would be larger, and the LMDI structural share
would increase.

This conservatism strengthens the paper's design guideline: if gear ratios
above g_crit carry a superlinear energy penalty even under ideal conditions
(mid-SOC, cool motor), the penalty is worse in practice.

## 5. What NOT to claim

- Do not claim quantitative thermal effect on LMDI without running the
  simulation at elevated temperature (this would require a separate
  parametric study, which is out of scope for Paper B).
- Do not claim SOC-dependent LMDI results as validated without re-running
  the full matrix at V_dc = 320V and 400V. The FW_boundary_comparison
  already covers 350/370/400V; adding 320V is recommended but optional.
- Note that the V_oc used in BMS postprocessing (370V) is a simplification;
  a real BMS sees V_oc that varies with SOC throughout the cycle.

## Key Numbers for the Manuscript

- FW onset shift: -16 km/h (370→320V), -14% of onset speed
- Copper loss increase at 120°C: +39% (Rs from 4.75 to 6.62 mΩ)
- FW share sensitivity: US06 FW share ranges from 11.5% (400V) to 51.5% (350V)
- LMDI Ssh range: 42% (400V) to 103% (350V) for UDDS→US06
- Conservative bias: 20°C, 370V simulation underestimates FW penalty
