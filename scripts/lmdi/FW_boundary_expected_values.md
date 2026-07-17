# FW Boundary Comparison — Expected Values (Python Prototype)

Generated: 17 July 2026, from FW_boundary_variants.mat + 5 verified g=9.04 files.
Cross-check target for FW_boundary_comparison.m.

## Boundary Variants

| Label  | Method | Voltage | Zero-torque onset (RPM) |
|--------|--------|---------|-------------------------|
| M1_370 | Back-EMF limit: V/(√3·ψ_m) | 370 V | 8809.07 (constant, all torques) |
| M2_370 | d-q voltage at id=0, iq from torque | 370 V | 8809.07 (at T=0, drops with torque) |
| M3_350 | CRG LUT Id-departure 10A | 350 V | 7583.76 |
| M3_370 | CRG LUT Id-departure 10A | 370 V | 8064.03 (= FW_onset_curve_v2) |
| M3_400 | CRG LUT Id-departure 10A | 400 V | 8668.98 |

## FW Distance Shares (%)

| Variant  | UDDS | HWFET | US06  | WLTP  | Artemis |
|----------|------|-------|-------|-------|---------|
| M1_370   |  0.0 |   0.0 |   6.4 |  13.1 |    47.8 |
| M2_370   |  0.0 |   0.0 |  13.4 |  16.0 |    54.9 |
| M3_350   |  0.0 |   0.0 |  51.5 |  25.6 |    80.1 |
| M3_370   |  0.0 |   0.0 |  36.3 |  21.4 |    70.3 |
| M3_400   |  0.0 |   0.0 |  11.5 |  15.9 |    54.1 |

Note: Net intensity (Ept) is IDENTICAL across variants for each cycle (boundary
changes regime classification, not the underlying physics). UDDS = 86.02,
HWFET = 107.82, US06 = 139.10, WLTP = 111.45, Artemis = 152.04 Wh/km.

## LMDI Sensitivity — Headline Pairs

### UDDS → US06 (Delta_t = +53.08 Wh/km, all variants)

| Variant  | Struct  | Intens  | S share | Residual  |
|----------|---------|---------|---------|-----------|
| M1_370   |  +11.07 |  +42.00 |  20.9%  | ~1e-14    |
| M2_370   |  +37.84 |  +15.24 |  71.3%  | ~1e-14    |
| M3_350   |  +54.38 |   -1.30 | 102.5%  | ~1e-14    |
| M3_370   |  +41.19 |  +11.89 |  77.6%  | ~1e-15    |
| M3_400   |  +22.37 |  +30.71 |  42.2%  | ~1e-14    |

### UDDS → Artemis (Delta_t = +66.02 Wh/km, all variants)

| Variant  | Struct  | Intens  | S share | Residual  |
|----------|---------|---------|---------|-----------|
| M1_370   |  +38.75 |  +27.27 |  58.7%  | ~1e-14    |
| M2_370   |  +45.51 |  +20.51 |  68.9%  | ~1e-14    |
| M3_350   |  +58.30 |   +7.73 |  88.3%  | ~1e-15    |
| M3_370   |  +52.62 |  +13.41 |  79.7%  | ~1e-14    |
| M3_400   |  +47.43 |  +18.60 |  71.8%  | ~1e-14    |

## Per-Cell e(r) Values (for detailed cross-check)

Format: e = [MTPA, Trans, FW] — sum equals Ept.

### M1_370
- UDDS:    e = [86.0174,  0.0000,  0.0000]
- HWFET:   e = [107.8221,  0.0000,  0.0000]
- US06:    e = [108.3223, 18.7799, 11.9931]
- WLTP:    e = [81.6399,  6.8188, 22.9868]
- Artemis: e = [54.9055, 14.5344, 82.6004]

### M2_370
- UDDS:    e = [86.0174,  0.0000,  0.0000]
- HWFET:   e = [107.8221,  0.0000,  0.0000]
- US06:    e = [73.1786, 28.1810, 37.7357]
- WLTP:    e = [75.0651,  5.3814, 30.9991]
- Artemis: e = [41.9456, 12.9305, 97.1643]

### M3_350
- UDDS:    e = [86.0174,  0.0000,  0.0000]
- HWFET:   e = [107.8221,  0.0000,  0.0000]
- US06:    e = [24.3836, 23.6004, 91.1112]
- WLTP:    e = [69.2906,  0.0000, 42.1549]
- Artemis: e = [17.1325,  5.6223, 129.2856]

### M3_370
- UDDS:    e = [86.0174,  0.0000,  0.0000]
- HWFET:   e = [107.8221,  0.0000,  0.0000]
- US06:    e = [52.4618, 23.0389, 63.5946]
- WLTP:    e = [69.3896,  4.7648, 37.2911]
- Artemis: e = [23.3213, 11.1666, 117.5524]

### M3_400
- UDDS:    e = [86.0174,  0.0000,  0.0000]
- HWFET:   e = [107.8221,  0.0000,  0.0000]
- US06:    e = [86.2786, 27.3379, 25.4787]
- WLTP:    e = [75.6390,  6.1653, 29.6412]
- Artemis: e = [40.8625, 14.6552, 96.5226]

## Key Interpretation (Paper Section 2.X)

M1 (back-EMF) assigns only 6.4% of US06 distance to FW and attributes 79%
of the UDDS-US06 gap to intensity (motor works harder per km). M3 at 370V
assigns 36.3% to FW and attributes 78% to structure (motor enters a different
regime). The structural share swings from 21% to 78% depending solely on
boundary method — not on the vehicle, cycle, or motor parameters.

M3_350 pushes structural share above 100% (102.5%), meaning the intensity
contribution is slightly negative: when the FW regime absorbs more distance,
the average intensity *within* each regime drops slightly (the motor is more
efficient at partial load within a wider FW band). This is physically coherent
and is explained in the discussion.

The voltage sensitivity (M3_350 vs M3_370 vs M3_400) shows that the exact
Vdc assumption matters. The paper uses 370V (measured ANL average DC bus
voltage during traction), documented with the supporting evidence.
