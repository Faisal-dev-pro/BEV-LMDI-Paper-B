# Improvement 12: Cost/Deployment Discussion — Analysis Notes

Generated: 17 July 2026. For Paper Section 6 (Discussion).

## 1. The Gear Ratio vs Motor Sizing Trade-Off

Single-speed BEV drivetrains face a fundamental design trade-off:

**Higher gear ratio (e.g. g=11):**
- Higher wheel torque at low speed → better launch, gradeability
- Motor operates at higher RPM for a given vehicle speed
- Earlier FW onset → energy penalty on high-speed cycles
- Smaller, lighter motor possible (lower peak torque requirement)
- Lower motor cost ($/kW scales with torque, not speed)

**Lower gear ratio (e.g. g=7):**
- Motor stays in MTPA to higher speeds → better highway efficiency
- Later FW onset → minimal structural energy penalty
- Larger motor required for equivalent launch torque
- Higher motor cost and mass
- Better NVH (lower gear noise at highway speed)

## 2. Quantified Trade-Off from This Study

From the verified gear design analysis (AE_gear_design.m):

| Metric                    | g=7.0   | g=9.04  | g=11.0  |
|---------------------------|---------|---------|---------|
| FW onset speed (km/h)     | 152     | 118     | 97      |
| US06 FW share             | 0%      | 36.3%   | 79.1%   |
| US06 BMS net (Wh/km)      | 143.3   | 148.7   | 155.1   |
| Artemis BMS net (Wh/km)   | 154.0   | 159.7   | 168.5   |
| UDDS BMS net (Wh/km)      | 105.3   | 108.1   | 110.6   |
| Marginal penalty US06     | —       | 2.65    | 3.27    |
| (Wh/km per unit ratio)    |         |         |         |

**Design conclusion:** On US06, moving from g=9.04 to g=11.0 costs
+6.4 Wh/km (+4.3%), driven almost entirely by the structural shift
into FW (79% of distance in FW at g=11 vs 36% at g=9.04). On UDDS,
the same gear change costs only +2.5 Wh/km (+2.3%), which is purely
intensity-driven (no FW at any tested ratio on UDDS).

## 3. Motor Cost Implications

### DoE Cost Targets (US DRIVE EDTT Roadmap, 2024)

| Year | Motor cost | Power density | Peak power |
|------|-----------|---------------|------------|
| 2020 | $8/kW     | 5.7 kW/L      | 55 kW      |
| 2025 | $3.30/kW  | 50 kW/L       | 100 kW     |
| 2030 | $2.70/kW  | 100 kW/L      | 100 kW     |

Source: DOE OSTI.GOV (2024), Electric Drive Technical Team Roadmap.

### Motor Sizing vs Gear Ratio

For a given vehicle performance requirement (e.g. 0-100 km/h in 4.6s):

    T_wheel_required = M × a × r_w (simplified)
    T_motor_required = T_wheel / (g × eta_gear)

| Gear ratio | T_motor for 300 Nm wheel | Motor size factor |
|------------|--------------------------|-------------------|
| 7.0        | 42.9 Nm                  | 1.29x (larger)    |
| 9.04       | 33.2 Nm                  | 1.00x (baseline)  |
| 11.0       | 27.3 Nm                  | 0.82x (smaller)   |

At $3.30/kW (DoE 2025), a 200 kW motor costs $660. Scaling by
torque capability (roughly proportional to active mass):
- g=7.0: ~$850 motor (+29%)
- g=9.04: ~$660 motor (baseline)
- g=11.0: ~$540 motor (-18%)

The motor cost saving from g=9.04 to g=11.0 is ~$120.

### Energy Cost of Higher Gear Ratio

On US06-representative driving (aggressive highway), g=11 costs
+6.4 Wh/km vs g=9.04. Over 200,000 km vehicle lifetime with 30%
highway/aggressive driving:

    E_penalty = 6.4 Wh/km × 200,000 km × 0.30 = 384 kWh
    At $0.13/kWh: $50 lifetime energy cost

On Artemis-representative driving (European motorway):

    E_penalty = 8.8 Wh/km × 200,000 km × 0.30 = 528 kWh
    At $0.13/kWh: $69 lifetime energy cost

**The motor cost saving ($120) exceeds the lifetime energy penalty
($50-69), so from a pure cost perspective, higher gear ratios are
favoured.** However, the energy penalty grows superlinearly above
g_crit, so this balance tips at very high ratios.

## 4. Multi-Speed Transmission Alternative

Multi-speed transmissions (2-speed or 3-speed) can avoid the trade-off
entirely by using a low gear for launch and a high gear for highway.
However, production BEVs overwhelmingly use single-speed reduction
(Tesla, VW, BMW, Hyundai, BYD, Rivian) due to:

- Lower cost (~$200-400 vs $800-1200 for multi-speed)
- Higher reliability (no shifting mechanism)
- Lighter mass (10-15 kg saving)
- Simpler thermal management
- Electric motor's inherently wide speed range

The LMDI decomposition provides a quantitative tool for evaluating
whether a second gear is justified for a specific duty cycle: if
the structural share exceeds 60-70% on the dominant cycle, a second
gear targeting that speed range would recover most of the penalty.

## 5. Implications for Motor Material Selection

Higher gear ratios → higher motor speed → stronger dependence on:
- Rotor mechanical integrity (centrifugal stress on magnets/bridges)
- Iron loss at high electrical frequency
- Magnet demagnetisation risk at elevated temperature + FW current

These constraints favour:
- Higher silicon steel grades (lower iron loss per kg, higher cost)
- Bonded or ferrite magnets for cost, but NdFeB for performance
- Robust rotor design with thicker bridges (reduces saliency ratio)

The saliency ratio (Lq/Ld) affects the CRG FW boundary directly.
Motors designed for high-speed operation (high gear ratio) typically
have lower saliency, which shifts the CRG boundary and changes the
LMDI regime attribution.

## 6. Key Paragraph for the Manuscript

"The gear ratio design chart (Fig. 6) reveals a practical trade-off
between motor sizing cost and lifecycle energy consumption. At the
DoE 2025 motor cost target of $3.30/kW, increasing the gear ratio
from 9.04 to 11.0 saves approximately $120 in motor cost by reducing
the required peak torque by 18%. However, this saving comes at a
superlinear energy penalty of +6.4 Wh/km on US06 (+8.8 Wh/km on
Artemis MW130), driven by the structural shift into field-weakening
operation. Over 200,000 km with 30% aggressive-duty driving, the
lifetime energy cost penalty is $50-69 at $0.13/kWh. The net saving
favours higher gear ratios on a cost basis, but the superlinearity
above g_crit (8.25 for US06) means this advantage erodes rapidly
for ratios above 11. The LMDI decomposition quantifies this
inflection point, enabling drivetrain designers to evaluate the
motor-size vs efficiency trade-off for a specific duty cycle profile."

## Sources

- DoE Electric Drive Technical Team Roadmap (2024): energy.gov
- Hofman & Dai (2016): "Energy consumption of single-speed BEV transmissions", Applied Energy
- Gao & Ehsani (2010): "Design of single-speed geared electric drivetrains", IEEE TVT
- This study: gear_design_analysis.mat (verified 17 Jul 2026)
