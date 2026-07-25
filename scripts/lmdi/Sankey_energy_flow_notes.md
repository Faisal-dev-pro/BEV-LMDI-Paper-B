# Improvement 7: Regime-Tagged Energy Flow — Analysis Notes

Generated: 17 July 2026. Cross-checked vs LMDI_matrix_results.mat (S_diff=0, Ept_diff=0).

## US06 Energy Flow (g=9.04, Tesla Model 3 LR)

Distance: 12.888 km | BMS net: 148.7 Wh/km

### Traction Side (Wh/km)

| Component         | MTPA   | Trans  | FW     | Total  |
|-------------------|--------|--------|--------|--------|
| Motor traction    | 105.1  |  24.4  |  73.4  | 202.8  |
| + Auxiliary       |        |        |        |   6.9  |
| + Cable I²R       |        |        |        |   0.9  |
| = BMS gross       |        |        |        | 210.6  |

### Regen Side (Wh/km)

| Component         | MTPA   | Trans  | FW     | Total  |
|-------------------|--------|--------|--------|--------|
| Motor regen       |  52.6  |   1.3  |   9.8  |  63.7  |
| - Aux during regen|        |        |        |   2.1  |
| - Cable I²R regen |        |        |        |   0.2  |
| = BMS regen       |        |        |        |  61.8  |

### Distance Shares

| Regime | km    | Share |
|--------|-------|-------|
| MTPA   | 6.597 | 51.2% |
| Trans  | 1.610 | 12.5% |
| FW     | 4.681 | 36.3% |

### Key Observation

FW consumes 73.4 Wh/km traction (36% of motor gross) but recovers only
9.8 Wh/km regen (15% of motor regen). Net FW intensity: 63.6 Wh/km.
Net MTPA intensity: 52.5 Wh/km. FW is 21% less efficient per km than MTPA.
This is the physical basis of the LMDI structural effect.

---

## UDDS Energy Flow (g=9.04, Tesla Model 3 LR)

Distance: 11.990 km | BMS net: 108.1 Wh/km

### Traction Side (Wh/km)

| Component         | MTPA   | Trans  | FW     | Total  |
|-------------------|--------|--------|--------|--------|
| Motor traction    | 144.6  |   0.0  |   0.0  | 144.6  |
| + Auxiliary       |        |        |        |  17.1  |
| + Cable I²R       |        |        |        |   0.3  |
| = BMS gross       |        |        |        | 161.5  |

### Regen Side (Wh/km)

| Component         | MTPA   | Trans  | FW     | Total  |
|-------------------|--------|--------|--------|--------|
| Motor regen       |  58.6  |   0.0  |   0.0  |  58.6  |
| - Aux during regen|        |        |        |   4.7  |
| - Cable I²R regen |        |        |        |   0.1  |
| = BMS regen       |        |        |        |  53.5  |

### Distance Shares

| Regime | km     | Share  |
|--------|--------|--------|
| MTPA   | 11.990 | 100.0% |
| Trans  |  0.000 |   0.0% |
| FW     |  0.000 |   0.0% |

### Key Observation

UDDS never reaches FW (max speed 91 km/h, FW onset 118 km/h at g=9.04).
100% MTPA operation. Auxiliary load is proportionally larger (17.1 vs 6.9
Wh/km) because UDDS has more idle time at low power where 690 W is a
larger fraction of total draw.

---

## UDDS vs US06 Contrast (Paper Section 4)

| Metric              | UDDS   | US06   | Delta  |
|---------------------|--------|--------|--------|
| BMS net (Wh/km)     | 108.1  | 148.7  | +40.6  |
| Motor net (Wh/km)   |  86.0  | 139.1  | +53.1  |
| FW distance share   |   0.0% |  36.3% | +36.3pp|
| LMDI structural     |        |        | +41.2  |
| LMDI intensity      |        |        | +11.9  |
| Structural share    |        |        |  77.6% |

The Sankey pair visually demonstrates what the LMDI numbers quantify:
the US06 energy penalty is dominated by the structural shift into FW,
not by changes in per-regime motor efficiency.

## Files

- `AE_sankey_energy_flow.py`: extraction + figure generation
- `results/sankey_energy_flow.mat`: per-regime energy data
- `results/figures/F2_US06_energy_flow.pdf`: US06 Sankey (draft)
- `results/figures/F3_UDDS_energy_flow.pdf`: UDDS Sankey (draft)
