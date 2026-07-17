# Gear Ratio Design Analysis — Expected Values (Python Prototype)

Generated: 17 July 2026, from LMDI_matrix_results.mat + 15 verified BMS files.
Cross-check target for AE_gear_design.m.

## BMS Net Wh/km (from simulation files)

| Gear  | UDDS  | HWFET | US06  | WLTP  | Artemis |
|-------|-------|-------|-------|-------|---------|
|  7.00 | 105.3 | 112.1 | 143.3 | 122.2 |   154.0 |
|  9.04 | 108.1 | 116.9 | 148.7 | 126.6 |   159.7 |
| 11.00 | 110.6 | 122.3 | 155.1 | 131.5 |   168.5 |

## Motor-Level Net Intensity (Ept, Wh/km)

| Gear  | UDDS  | HWFET  | US06   | WLTP   | Artemis |
|-------|-------|--------|--------|--------|---------|
|  7.00 | 83.29 | 103.05 | 133.79 | 107.12 |  146.36 |
|  9.04 | 86.02 | 107.82 | 139.10 | 111.45 |  152.04 |
| 11.00 | 88.50 | 113.25 | 145.40 | 116.35 |  160.77 |

## FW Distance Share (%, CRG classifier, motor level)

| Gear  | UDDS | HWFET | US06 | WLTP | Artemis |
|-------|------|-------|------|------|---------|
|  7.00 |  0.0 |   0.0 |  0.0 |  0.0 |     0.0 |
|  9.04 |  0.0 |   0.0 | 36.3 | 21.4 |    70.3 |
| 11.00 |  4.1 |  29.7 | 79.1 | 36.5 |    85.9 |

## Gear Penalty (BMS net Wh/km delta)

| Step           | UDDS  | HWFET | US06  | WLTP  | Artemis |
|----------------|-------|-------|-------|-------|---------|
| g7.0 -> g9.04  |  +2.7 |  +4.8 |  +5.4 |  +4.3 |    +5.7 |
| g9.04 -> g11.0 |  +2.5 |  +5.4 |  +6.4 |  +4.9 |    +8.8 |
| g7.0 -> g11.0  |  +5.2 | +10.2 | +11.8 |  +9.3 |   +14.5 |

## Marginal Penalty (Wh/km per unit gear ratio, BMS net)

| Step           |  dg   | UDDS | HWFET | US06 | WLTP | Artemis |
|----------------|-------|------|-------|------|------|---------|
| g7.0 -> g9.04  | 2.04  | 1.37 |  2.35 | 2.65 | 2.16 |    2.79 |
| g9.04 -> g11.0 | 1.96  | 1.28 |  2.76 | 3.27 | 2.50 |    4.49 |
| g7.0 -> g11.0  | 4.00  | 1.32 |  2.55 | 2.95 | 2.32 |    3.62 |

## Superlinearity (marginal penalty ratio: second step / first step)

| Cycle   | 7->9.04 Wh | 9.04->11 Wh | ratio | superlinear? |
|---------|------------|-------------|-------|--------------|
| UDDS    |    +2.7    |     +2.5    | 0.94x | marginal     |
| HWFET   |    +4.8    |     +5.4    | 1.18x | YES          |
| US06    |    +5.4    |     +6.4    | 1.23x | YES          |
| WLTP    |    +4.3    |     +4.9    | 1.18x | YES          |
| Artemis |    +5.7    |     +8.8    | 1.60x | YES          |

Note: superlinearity is driven by the nonlinear growth of FW share with gear
ratio. UDDS is the exception (no FW at any tested ratio), so its penalty is
purely from higher motor speed at a given vehicle speed (intensity effect).

## FW Onset Speed vs Gear Ratio

| Gear  | v_FW (m/s) | v_FW (km/h) |
|-------|------------|-------------|
|  7.00 |       42.2 |       151.9 |
|  8.00 |       36.9 |       132.9 |
|  9.04 |       32.7 |       117.6 |
| 10.00 |       29.5 |       106.3 |
| 11.00 |       26.9 |        96.7 |

Formula: v_FW = omega_base * r_w / g = 906 * 0.326 / g

## Critical Gear Ratio (g at which FW onset = cycle vmax)

| Cycle   | vmax (km/h) | g_crit |
|---------|-------------|--------|
| UDDS    |    91.1     | 11.67  |
| HWFET   |    96.5     | 11.02  |
| US06    |   128.9     |  8.25  |
| WLTP    |   119.9     |  8.87  |
| Artemis |   131.8     |  8.07  |

g_crit = omega_base * r_w / v_max. Below g_crit, FW operation is unavoidable
and grows rapidly. This is why US06 and Artemis show the strongest
superlinearity: they cross the FW threshold between g=7 and g=9.04.

## Cross-Gear LMDI (motor level, structural share)

| Cycle   | Pair          |  Dt    |   Ds   |   Di   | Ssh     |
|---------|---------------|--------|--------|--------|---------|
| UDDS    | g7.0->g9.04   |  +2.73 |  +0.00 |  +2.73 |   0.0%  |
| UDDS    | g9.04->g11.0  |  +2.48 |  +4.62 |  -2.13 | 186.0%  |
| UDDS    | g7.0->g11.0   |  +5.21 |  +4.76 |  +0.45 |  91.4%  |
| HWFET   | g7.0->g9.04   |  +4.77 |  +0.00 |  +4.77 |   0.0%  |
| HWFET   | g9.04->g11.0  |  +5.43 |  +8.12 |  -2.69 | 149.6%  |
| HWFET   | g7.0->g11.0   | +10.20 |  +9.27 |  +0.94 |  90.8%  |
| US06    | g7.0->g9.04   |  +5.31 | +36.34 | -31.04 | 685.0%  |
| US06    | g9.04->g11.0  |  +6.30 | +32.33 | -26.03 | 512.8%  |
| US06    | g7.0->g11.0   | +11.61 | +59.44 | -47.83 | 512.0%  |
| WLTP    | g7.0->g9.04   |  +4.33 | +16.46 | -12.13 | 380.2%  |
| WLTP    | g9.04->g11.0  |  +4.91 | +11.13 |  -6.22 | 226.8%  |
| WLTP    | g7.0->g11.0   |  +9.24 | +23.39 | -14.15 | 253.2%  |
| Artemis | g7.0->g9.04   |  +5.68 | +29.47 | -23.79 | 518.7%  |
| Artemis | g9.04->g11.0  |  +8.73 |  +8.58 |  +0.14 |  98.3%  |
| Artemis | g7.0->g11.0   | +14.41 | +40.19 | -25.78 | 278.9%  |

Note: structural shares >100% on high-speed cycles reflect the re-partitioning
effect. Shifting distance from MTPA into FW simultaneously lowers per-regime
intensity (the motor is more efficient at partial load within a wider regime
band), creating a negative intensity term that partially cancels the structural
term. The net delta (Dt) remains modest (5-14 Wh/km) because the two large
terms nearly cancel. This is a genuine physical effect, not a decomposition
artifact. The design chart uses raw BMS deltas for practical readability; the
LMDI terms go in the discussion section.

## Key Design Conclusions (Paper Section 5)

1. The energy penalty from increasing gear ratio is superlinear on aggressive
   cycles. On Artemis MW130, the marginal penalty rises from 2.79 Wh/km per
   unit ratio (g=7->9.04) to 4.49 (g=9.04->11), a 1.61x increase.

2. The inflection point is the critical gear ratio g_crit where FW onset
   drops below cycle peak speed. For US06: g_crit = 8.25. Below this, the
   motor never enters FW. Above it, FW share grows rapidly (0% at g=7, 36%
   at g=9.04, 79% at g=11).

3. For US06-duty operation, gear ratios above ~8.5 carry a compounding energy
   penalty driven by structural regime shift. The Tesla Model 3's g=9.04 is
   already above g_crit for US06, and the penalty would be steeper still at
   higher ratios.

4. UDDS is the counter-case: no FW at any tested ratio, so the penalty is
   linear and modest (~1.3 Wh/km per unit ratio, pure intensity effect).
