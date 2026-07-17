# LMDI matrix — expected values (Python prototype, 17 Jul 2026, v2 curve)

Independent prototype of AE_run_LMDI_matrix.m run on the 15 verified
matrix files (tag tesla-matrix-complete-v26). The MATLAB run must
reproduce these to ~0.1 Wh/km; residuals must be ~1e-13 or better.

REVISION (17 Jul, second pass): the first MATLAB-vs-Python cross-check
caught a divergence of up to 7 pp in FW shares, traced to the FW onset
curve starting at 22 Nm: MATLAB extrapolated below it, Python clamped.
Neither was correct. FW_onset_curve_v2.mat adds the true T=0 breakpoint
(8064.03 rpm = 109.6 km/h at g=9.04), extracted from
IPMSM_CurrentRef_LUT.mat with the same Id-departure methodology,
verified to reproduce every v1 breakpoint to 0.01 rpm. All lookups are
now in-range interpolation; both implementations agree by construction.

Method: CRG torque-dependent FW boundary (v2 curve, Id departure 10 A
at Vdc=370 V), regen binned by speed with T = |Pb|/(eta*omega),
eta_drive = 0.90, 5% Trans band, regimes with S < 1% folded into the
adjacent regime, zero-regime pairs fully structural. MOTOR level.

## Per-cell: Net Wh/km | S% [MTPA Trans FW] | I Wh/km [MTPA Trans FW]

| Cell | Net | S% | I |
|---|---|---|---|
| g7.0 UDDS | 83.3 | 100 / 0 / 0 | 83.3 / - / - |
| g7.0 HWFET | 103.0 | 100 / 0 / 0 | 103.0 / - / - |
| g7.0 US06 | 133.8 | 97.7 / 2.3 / 0 | 126.6 / 435.1 / - |
| g7.0 WLTP | 107.1 | 100 / 0 / 0 | 107.1 / - / - |
| g7.0 Artemis | 146.4 | 95.9 / 4.1 / 0 | 139.7 / 303.5 / - |
| g9.04 UDDS | 86.0 | 100 / 0 / 0 | 86.0 / - / - |
| g9.04 HWFET | 107.8 | 100 / 0 / 0 | 107.8 / - / - |
| g9.04 US06 | 139.1 | 51.2 / 12.5 / 36.3 | 102.5 / 184.4 / 175.1 |
| g9.04 WLTP | 111.4 | 74.5 / 4.1 / 21.4 | 93.2 / 115.6 / 174.3 |
| g9.04 Artemis | 152.0 | 20.5 / 9.2 / 70.3 | 113.7 / 121.5 / 167.2 |
| g11.0 UDDS | 88.5 | 89.3 / 6.5 / 4.1 | 83.8 / 117.4 / 145.4 |
| g11.0 HWFET | 113.3 | 56.0 / 14.3 / 29.7 | 104.3 / 116.5 / 128.6 |
| g11.0 US06 | 145.4 | 16.4 / 4.5 / 79.1 | 51.8 / 130.3 / 165.6 |
| g11.0 WLTP | 116.4 | 60.7 / 2.8 / 36.5 | 89.3 / 118.1 / 161.2 |
| g11.0 Artemis | 160.8 | 13.0 / 1.1 / 85.9 | 91.0 / 133.9 / 171.7 |

## Cross-cycle LMDI at g=9.04 (Delta = Struct + Intens, Wh/km)

| Pair | Delta | Struct | Intens |
|---|---|---|---|
| UDDS->HWFET | +21.80 | 0.00 | +21.80 |
| UDDS->US06 | +53.08 | +41.19 | +11.89 |
| UDDS->WLTP | +25.43 | +19.25 | +6.18 |
| UDDS->Artemis | +66.02 | +52.62 | +13.41 |
| HWFET->US06 | +31.27 | +35.17 | -3.90 |
| HWFET->WLTP | +3.62 | +16.37 | -12.74 |
| HWFET->Artemis | +44.22 | +41.28 | +2.94 |
| US06->WLTP | -27.65 | -16.23 | -11.42 |
| US06->Artemis | +12.95 | +20.10 | -7.15 |
| WLTP->Artemis | +40.59 | +34.69 | +5.90 |

Headline: UDDS->US06 is 78% structural, UDDS->Artemis 80% structural
(the regime-shift thesis). UDDS->HWFET is pure intensity (both cycles
100% MTPA at g=9.04).

## Cross-gear LMDI per cycle

| Cycle / Pair | Delta | Struct | Intens |
|---|---|---|---|
| UDDS g7->g9.04 | +2.73 | 0.00 | +2.73 |
| UDDS g9.04->g11 | +2.48 | +4.62 | -2.13 |
| UDDS g7->g11 | +5.21 | +4.76 | +0.45 |
| HWFET g7->g9.04 | +4.77 | 0.00 | +4.77 |
| HWFET g9.04->g11 | +5.43 | +8.12 | -2.69 |
| HWFET g7->g11 | +10.20 | +9.27 | +0.94 |
| US06 g7->g9.04 | +5.31 | +36.34 | -31.04 |
| US06 g9.04->g11 | +6.30 | +32.33 | -26.03 |
| US06 g7->g11 | +11.61 | +59.44 | -47.83 |
| WLTP g7->g9.04 | +4.33 | +16.46 | -12.13 |
| WLTP g9.04->g11 | +4.91 | +11.13 | -6.22 |
| WLTP g7->g11 | +9.24 | +23.39 | -14.15 |
| Artemis g7->g9.04 | +5.68 | +29.47 | -23.79 |
| Artemis g9.04->g11 | +8.73 | +8.58 | +0.14 |
| Artemis g7->g11 | +14.41 | +40.19 | -25.78 |

INTERPRETATION CAUTION (for the writing): where a gear change
re-partitions distance between regimes (US06/WLTP/Artemis), structural
and intensity terms are large and partly canceling — exact LMDI
behaviour: moving high-speed distance into FW raises the structural
term while LOWERING the remaining MTPA intensity. Below-onset cases
(UDDS, HWFET at g<=9.04) show the gear penalty as pure intensity.
The design-chart section should use raw sweep deltas; the LMDI section
interprets composition vs intensity.

## Definitional reconciliations for Section 4

- LMDI FW shares use the torque-dependent Id-departure boundary
  (zero-torque onset 8064 rpm = 109.6 km/h at g=9.04); sweep and
  validation tables use the 906 rad/s zero-torque limit (117.6 km/h).
  Example: Artemis g=9.04 FW share 70.3% (LMDI) vs 51.3% (sweep).
- LMDI is motor level; validation tables are BMS level (+aux, +cable).
