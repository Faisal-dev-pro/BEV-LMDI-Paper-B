# Quarantined result files — do not use

Updated 16 July 2026 after the gear contamination audit was RESOLVED.
One failure mechanism explains everything. Nothing here should enter
the paper.

## Root cause (single mechanism, two victims)

On 10 July 2026 the two baseline runs executed with a stale
`gear_override` variable in the MATLAB base workspace, silently picked
up by the `exist()` check in `AE_TeslaM3_LMDI_Params.m` (line 79):

1. `BMS_Artemis_MW130_v26_20260710_135939.mat` (13:59) ran at **g=7.0**.
   Proof: bit-identical to the validated 14 Jul g=7.0 run
   (E_bms_gross = 5308.927106 Wh in both). Replaced by the 15 Jul
   rerun: BMS net 159.7 Wh/km, FW 51.3%, gear guards pass.
2. `BMS_UDDS_v26_20260710_190022.mat` (19:00) ran at **g=11**.
   Proof (16 Jul): its first-60 s gross energy is 74.7770 Wh, exactly
   the g=11 signature measured by `diag_gear_effective.m`
   (true g=9.04 gives 74.3681 Wh). Full-cycle E_bms_gross
   1962.974889 Wh matches every genuine g=11 UDDS run bit-for-bit.
   **Consequence: no valid UDDS g=9.04 run exists and the T12/T12a/T13
   ANL validation must be re-established with
   `scripts/gear_sweep/v26_run_UDDS_g904.m`.**

## Corrections to earlier audit conclusions (15 Jul)

- The UDDS g=11 runs of 14 Jul, 15 Jul, and 16 Jul were all VALID g=11
  simulations (BMS net 110.6, gross 163.7, regen 32.5%). They were
  wrongly rejected because the guard reference (the 10 Jul "baseline")
  was itself the contaminated file. The 16 Jul run
  (`BMS_UDDS_v26_g11.00_20260716_020313.mat`) is kept in
  `results/tesla_g11.0/` as the canonical g=11 UDDS result.
- The earlier "Simscape Accelerator cache" and "in-memory compiled
  network reuse" explanations are WITHDRAWN. The effective-gear
  diagnostic showed gear changes apply correctly (g_eff 9.128/11.119,
  ratio 1.2181 vs expected 1.2168). No caching failure was ever
  demonstrated. The bdclose/literal-ratio/cache-clear protections in
  the run scripts are retained as cheap insurance only.

## Quarantined files

| File | Truth |
|---|---|
| BMS_Artemis_MW130_v26_20260710_135939.mat | g=7.0 physics, mislabeled baseline |
| BMS_UDDS_v26_20260710_190022.mat | g=11 physics, mislabeled baseline |
| BMS_ArtemisMW130_v26_20260713_*.mat (3 files) | g=7.0 attempt copies, misfiled into tesla_g9.04 |
| BMS_UDDS_v26_20260713_021559.mat | duplicate of tesla_g7.0 UDDS |
| BMS_UDDS_v26_20260714_092637.mat | duplicate of the (valid) 14 Jul g=11 run |
| BMS_UDDS_v26_g11.0_20260714_092637.mat | VALID g=11 data; superseded by 16 Jul canonical file |
| BMS_US06_v26_20260712_144011.mat | duplicate of tesla_g7.0 US06 |
| BMS_US06_v26_20260714_001504.mat | duplicate of tesla_g11.0 US06 |
| BMS_WLTP_v26_20260711_133350.mat | duplicate of tesla_g11.0 WLTP |
| BMS_WLTP_v26_20260713_081328.mat | duplicate of tesla_g7.0 WLTP |
| BMS_WLTP_v26_20260714_172410.mat | duplicate of tesla_g11.0 WLTP |
| stale_cache/ | old slxc/slprj artifacts (root + scripts/gear_sweep) |

## Verified matrix (16 Jul 2026, BMS net Wh/km)

g=7.0:  UDDS 105.3, US06 143.3, WLTP 122.2, Artemis 154.0 (0% FW)
g=9.04: US06 148.7, WLTP 126.6, Artemis 159.7 (FW 51.3%), HWFET 122.3 (FAIL). UDDS RERUN NEEDED
g=11.0: UDDS 110.6 (0% FW), US06 155.1, WLTP 131.5

## Detection rules that caught everything

1. Bit-identical energy across supposedly different gear configs.
2. First-60 s gross signature: UDDS 74.3681 Wh (g=9.04) vs
   74.7770 Wh (g=11) from diag_gear_effective.m.
3. Effective gear measurement g_eff = omega_motor * r_w / v.

## Prevention (in run scripts since 15-16 Jul 2026)

1. Explicit gear_override in every script (never rely on workspace).
2. bdclose + fresh load_system; literal ratio written per run and
   restored after; slprj cleared; Normal mode.
3. Gear guards with verified reference values in every sweep script.
4. v26_BMS_postprocess.m embeds gear_ratio in filename and struct.

## Addendum 17 July 2026: third victim found

`BMS_HWFET_v26_20260710_214929.mat` (10 Jul 21:49) also ran at g=11.
Verified g=9.04 rerun differs by -85.2 Wh (2138.014748 vs 2223.232382)
and PASSES all three ANL gates (net 116.9 vs 114.4, +2.2%). The
historical "HWFET FAIL +6.9%" was contamination, not a model deficiency.
All three baselines run on 10 July were gear_override victims: Artemis
13:59 (g=7), UDDS 19:00 (g=11), HWFET 21:49 (g=11). Five-cycle ANL
validation is now complete on v26. The quarantined file's energy
(2223.232382152 Wh) doubles as the PREDICTION for a verified g=11 HWFET
run; bit-exact reproduction confirms the story end to end.
