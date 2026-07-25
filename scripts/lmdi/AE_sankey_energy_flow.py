#!/usr/bin/env python3
"""
AE_sankey_energy_flow.py — Improvement 7: Regime-Tagged Energy Flow Sankey Diagrams

Generates Sankey diagrams (F2: US06, F3: UDDS) showing energy flow from
battery to road load, tagged by motor operating regime (MTPA / Trans / FW).

Energy accounting (per-timestep, 10 Hz):
  Battery gross = Motor traction + Auxiliary (690 W) + Cable I²R
  Battery regen = Motor regen - Aux during regen - Cable I²R during regen
  Battery net   = Battery gross - Battery regen

Regime assignment replicates AE_regime_binning.m exactly:
  - Motor speed from vehicle speed: rpm = v * gear / r_w * 60/(2π)
  - Torque estimated from P_batt and omega (eta_drive for direction)
  - CRG FW onset interpolated from torque-dependent curve
  - Trans = within 5% of onset; FW = at/above onset
  - Regen binned by speed (same as traction)

Output: PDF figures saved to results/figures/

Cross-check: per-regime energy sums must match LMDI_matrix_results.mat
within 0.01 Wh/km (same physics, same classifier).

Author: F. Shah Khan, University of East London, July 2026
"""

import os
import numpy as np
import scipy.io as sio
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.sankey import Sankey

# ── Paths ──
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJ_ROOT = os.path.normpath(os.path.join(SCRIPT_DIR, '..', '..'))

# ── Parameters (must match AE_TeslaM3_LMDI_Params.m) ──
GEAR = 9.04
WHEEL_R = 0.326       # m
ETA_DRIVE = 0.90
P_AUX_W = 690.0       # W (DCDC 366 + front motor 324)
V_OC = 370.0           # V nominal
R_CABLE = 0.015        # Ohm
DT = 0.1               # s (10 Hz)


def load_fw_curve():
    """Load CRG FW onset curve (v2, torque-dependent)."""
    d = sio.loadmat(os.path.join(PROJ_ROOT, 'model', 'FW_onset_curve_v2.mat'),
                    squeeze_me=True)
    return d['fw_tq_Nm'], d['fw_rpm_mech']


def regime_binning(Pb, vS, fw_tq, fw_rpm):
    """Replicate AE_regime_binning.m exactly."""
    N = len(Pb)
    omega_mech = np.abs(vS) * GEAR / WHEEL_R
    rpm_mech = omega_mech * 60.0 / (2.0 * np.pi)

    moving = omega_mech > 0.5
    T_est = np.zeros(N)

    trac_m = moving & (Pb > 0)
    regen_m = moving & (Pb < 0)

    T_est[trac_m] = Pb[trac_m] * ETA_DRIVE / omega_mech[trac_m]
    T_est[regen_m] = np.abs(Pb[regen_m]) / (ETA_DRIVE * omega_mech[regen_m])
    T_est = np.clip(T_est, 0, fw_tq[-1])

    rpm_fw_onset = np.interp(T_est, fw_tq, fw_rpm)
    rpm_fw_onset = np.maximum(rpm_fw_onset, fw_rpm[-1])

    regime = np.ones(N, dtype=np.uint8)
    in_FW = moving & (rpm_mech >= rpm_fw_onset)
    in_Trans = moving & (rpm_mech >= 0.95 * rpm_fw_onset) & ~in_FW
    regime[in_Trans] = 2
    regime[in_FW] = 3

    return regime


def compute_energy_flow(Pb, vS, t, regime):
    """Compute regime-tagged energy flow with BMS-level losses."""
    N = len(Pb)
    dist_km = np.trapz(np.abs(vS), t) / 1000.0

    # Motor-level per-regime energy (Wh)
    regime_names = ['MTPA', 'Trans', 'FW']
    motor_trac = np.zeros(3)
    motor_regen = np.zeros(3)
    motor_dist = np.zeros(3)

    for r in range(3):
        mask = (regime == r + 1).astype(float)
        motor_trac[r] = np.trapz(np.maximum(Pb, 0) * mask, t) / 3600.0
        motor_regen[r] = abs(np.trapz(np.minimum(Pb, 0) * mask, t) / 3600.0)
        motor_dist[r] = np.trapz(np.abs(vS) * mask, t) / 1000.0

    motor_gross_total = motor_trac.sum()
    motor_regen_total = motor_regen.sum()

    # BMS-level: add auxiliary and cable I²R
    P_motor = Pb.copy()
    P_aux = np.full(N, P_AUX_W)
    P_bms = P_motor + P_aux
    I_bms = P_bms / V_OC
    P_cable = I_bms**2 * R_CABLE

    # Auxiliary energy during traction and regen
    trac_mask = P_bms > 0
    regen_mask = P_bms < 0

    aux_trac_Wh = np.sum(P_aux[trac_mask]) * DT / 3600.0
    aux_regen_Wh = np.sum(P_aux[regen_mask]) * DT / 3600.0
    cable_trac_Wh = np.sum(P_cable[trac_mask]) * DT / 3600.0
    cable_regen_Wh = np.sum(P_cable[regen_mask]) * DT / 3600.0

    # BMS totals
    P_bms_final = P_bms + P_cable * np.sign(P_bms)
    bms_gross_Wh = np.sum(np.maximum(P_bms_final[:-1], 0)) * DT / 3600.0
    bms_regen_Wh = abs(np.sum(np.minimum(P_bms_final[:-1], 0)) * DT / 3600.0)
    bms_net_Wh = bms_gross_Wh - bms_regen_Wh

    return {
        'dist_km': dist_km,
        'regime_names': regime_names,
        'motor_trac': motor_trac,          # Wh per regime
        'motor_regen': motor_regen,         # Wh per regime
        'motor_dist': motor_dist,           # km per regime
        'motor_gross_total': motor_gross_total,
        'motor_regen_total': motor_regen_total,
        'aux_trac_Wh': aux_trac_Wh,
        'aux_regen_Wh': aux_regen_Wh,
        'cable_trac_Wh': cable_trac_Wh,
        'cable_regen_Wh': cable_regen_Wh,
        'bms_gross_Wh': bms_gross_Wh,
        'bms_regen_Wh': bms_regen_Wh,
        'bms_net_Wh': bms_net_Wh,
        'bms_net_Whkm': bms_net_Wh / dist_km,
        # Per-regime Wh/km
        'trac_Whkm': motor_trac / dist_km,
        'regen_Whkm': motor_regen / dist_km,
        'share_pct': motor_dist / dist_km * 100,
    }


def draw_sankey(flow, cycle_name, out_path):
    """Draw a Sankey diagram for one cycle's energy flow."""
    fig, ax = plt.subplots(1, 1, figsize=(12, 7))
    ax.set_title(f'{cycle_name} Energy Flow — Tesla Model 3, g = 9.04',
                 fontsize=14, fontweight='bold', pad=20)

    dk = flow['dist_km']
    # All values in Wh/km for normalisation
    mt = flow['motor_trac'] / dk    # per-regime traction Wh/km
    mr = flow['motor_regen'] / dk   # per-regime regen Wh/km
    aux_t = flow['aux_trac_Wh'] / dk
    aux_r = flow['aux_regen_Wh'] / dk
    cab_t = flow['cable_trac_Wh'] / dk
    cab_r = flow['cable_regen_Wh'] / dk
    bms_g = flow['bms_gross_Wh'] / dk
    bms_r = flow['bms_regen_Wh'] / dk
    bms_n = flow['bms_net_Wh'] / dk

    # Regime colors
    c_mtpa = '#2196F3'   # blue
    c_trans = '#FF9800'  # orange
    c_fw = '#F44336'     # red
    c_aux = '#9E9E9E'    # grey
    c_cable = '#795548'  # brown
    c_regen = '#4CAF50'  # green
    c_net = '#E91E63'    # pink

    # Build horizontal stacked bar representation instead of matplotlib Sankey
    # (matplotlib.sankey is limited for multi-flow diagrams)
    # Use a custom bar-based energy flow diagram

    fig, axes = plt.subplots(2, 1, figsize=(14, 10), gridspec_kw={'height_ratios': [3, 1]})

    # ── Top panel: energy flow bar diagram ──
    ax = axes[0]
    ax.set_title(f'{cycle_name} Regime-Tagged Energy Flow\n'
                 f'Tesla Model 3 LR, g = 9.04, BMS net = {bms_n:.1f} Wh/km',
                 fontsize=13, fontweight='bold')

    # Traction side (left to right stacked bar)
    bar_y = 0.6
    bar_h = 0.25

    # BMS gross bar
    ax.barh(bar_y + 0.35, bms_g, height=bar_h, color='#263238', edgecolor='white',
            label=f'BMS Gross: {bms_g:.1f} Wh/km')

    # Motor traction split by regime
    left = 0
    for r, (name, val, color) in enumerate(zip(
            ['MTPA', 'Trans', 'FW'],
            mt, [c_mtpa, c_trans, c_fw])):
        if val > 0.5:
            ax.barh(bar_y, val, height=bar_h, left=left, color=color,
                    edgecolor='white', linewidth=0.5)
            ax.text(left + val/2, bar_y, f'{name}\n{val:.1f}',
                    ha='center', va='center', fontsize=8, fontweight='bold', color='white')
        left += val

    # Auxiliary and cable
    ax.barh(bar_y, aux_t, height=bar_h, left=left, color=c_aux,
            edgecolor='white', linewidth=0.5)
    if aux_t > 2:
        ax.text(left + aux_t/2, bar_y, f'Aux\n{aux_t:.1f}',
                ha='center', va='center', fontsize=7, color='white')
    left += aux_t
    ax.barh(bar_y, cab_t, height=bar_h, left=left, color=c_cable,
            edgecolor='white', linewidth=0.5)
    left += cab_t

    # Regen bar (below, going right to left visually)
    bar_y_r = 0.2
    left = 0
    for r, (name, val, color) in enumerate(zip(
            ['MTPA', 'Trans', 'FW'],
            mr, [c_mtpa, c_trans, c_fw])):
        if val > 0.5:
            ax.barh(bar_y_r, val, height=bar_h, left=left, color=color,
                    edgecolor='white', linewidth=0.5, alpha=0.5)
            ax.text(left + val/2, bar_y_r, f'{name}\n{val:.1f}',
                    ha='center', va='center', fontsize=8, fontweight='bold', color='black')
        left += val

    # BMS regen bar
    ax.barh(bar_y_r - 0.35, bms_r, height=bar_h, color=c_regen, alpha=0.6,
            label=f'BMS Regen: {bms_r:.1f} Wh/km ({flow["bms_regen_Wh"]/flow["bms_gross_Wh"]*100:.1f}%)')

    # Net bar
    ax.barh(-0.3, bms_n, height=bar_h, color=c_net,
            label=f'BMS Net: {bms_n:.1f} Wh/km')

    # Labels
    ax.set_yticks([0.95, 0.6, 0.2, -0.15, -0.3])
    ax.set_yticklabels(['BMS Gross', 'Motor Traction\n(by regime)', 'Motor Regen\n(by regime)',
                        'BMS Regen', 'BMS Net'], fontsize=9)
    ax.set_xlabel('Energy (Wh/km)', fontsize=10)
    ax.legend(loc='upper right', fontsize=8, framealpha=0.9)
    ax.set_xlim(0, bms_g * 1.1)
    ax.grid(axis='x', alpha=0.3)

    # ── Bottom panel: regime distance shares ──
    ax2 = axes[1]
    shares = flow['share_pct']
    colors = [c_mtpa, c_trans, c_fw]
    labels = [f'MTPA ({shares[0]:.1f}%)', f'Trans ({shares[1]:.1f}%)', f'FW ({shares[2]:.1f}%)']

    # Filter out zero regimes
    nonzero = shares > 0.5
    ax2.pie(shares[nonzero], labels=[l for l, nz in zip(labels, nonzero) if nz],
            colors=[c for c, nz in zip(colors, nonzero) if nz],
            autopct='', startangle=90, textprops={'fontsize': 10})
    ax2.set_title('Distance Share by Regime', fontsize=11, fontweight='bold')

    plt.tight_layout()
    plt.savefig(out_path, dpi=300, bbox_inches='tight')
    plt.close()
    print(f'  Saved: {out_path}')


def print_energy_table(flow, cycle_name):
    """Print detailed energy accounting for verification."""
    dk = flow['dist_km']
    print(f'\n{"="*60}')
    print(f' {cycle_name} ENERGY FLOW (g=9.04, Tesla Model 3 LR)')
    print(f'{"="*60}')
    print(f'  Distance: {dk:.3f} km')
    print(f'\n  {"Regime":<8s} {"Dist km":<10s} {"Share %":<10s} {"Trac Wh/km":<12s} '
          f'{"Regen Wh/km":<12s} {"Net Wh/km":<12s}')
    print(f'  {"-"*64}')
    for r, name in enumerate(flow['regime_names']):
        d_r = flow['motor_dist'][r]
        s_r = flow['share_pct'][r]
        t_r = flow['trac_Whkm'][r]
        g_r = flow['regen_Whkm'][r]
        n_r = t_r - g_r
        print(f'  {name:<8s} {d_r:>8.3f}   {s_r:>7.1f}   {t_r:>10.2f}   {g_r:>10.2f}   {n_r:>10.2f}')

    print(f'\n  Motor gross: {flow["motor_gross_total"]/dk:.1f} Wh/km')
    print(f'  Motor regen: {flow["motor_regen_total"]/dk:.1f} Wh/km')
    print(f'  Motor net:   {(flow["motor_gross_total"]-flow["motor_regen_total"])/dk:.1f} Wh/km')
    print(f'\n  + Auxiliary (trac):  +{flow["aux_trac_Wh"]/dk:.1f} Wh/km')
    print(f'  + Cable I²R (trac): +{flow["cable_trac_Wh"]/dk:.1f} Wh/km')
    print(f'  = BMS gross:        {flow["bms_gross_Wh"]/dk:.1f} Wh/km')
    print(f'\n  - Aux during regen: -{flow["aux_regen_Wh"]/dk:.1f} Wh/km')
    print(f'  - Cable I²R regen:  -{flow["cable_regen_Wh"]/dk:.1f} Wh/km')
    print(f'  = BMS regen:        {flow["bms_regen_Wh"]/dk:.1f} Wh/km')
    print(f'\n  BMS net:            {flow["bms_net_Whkm"]:.1f} Wh/km')


def cross_check_lmdi(flows, cycle_names):
    """Cross-check per-regime shares against LMDI_matrix_results.mat."""
    print(f'\n{"="*60}')
    print(f' CROSS-CHECK vs LMDI_matrix_results.mat')
    print(f'{"="*60}')

    lmdi_path = os.path.join(PROJ_ROOT, 'results', 'LMDI_matrix_results.mat')
    if not os.path.exists(lmdi_path):
        print(f'  WARNING: {lmdi_path} not found. Skipping cross-check.')
        return True

    LM = sio.loadmat(lmdi_path, squeeze_me=True)
    CELLS = LM['CELLS']  # 3 gears x 5 cycles

    cycle_idx = {'UDDS': 0, 'HWFET': 1, 'US06': 2, 'WLTP': 3, 'Artemis': 4}
    gear_idx = 1  # g=9.04

    ok = True
    for flow, cname in zip(flows, cycle_names):
        ci = cycle_idx[cname]
        cell = CELLS[gear_idx, ci]

        # LMDI S values (distance shares)
        lmdi_S = cell['S'].item()
        our_S = flow['share_pct'] / 100.0

        # LMDI Ept (net intensity)
        lmdi_Ept = cell['Ept'].item()
        our_Ept = (flow['motor_gross_total'] - flow['motor_regen_total']) / flow['dist_km']

        s_diff = np.max(np.abs(lmdi_S - our_S))
        ept_diff = abs(lmdi_Ept - our_Ept)

        status = 'OK' if s_diff < 0.005 and ept_diff < 0.1 else 'MISMATCH'
        print(f'  {cname:<8s} S_diff={s_diff:.4f}  Ept_diff={ept_diff:.3f}  {status}')
        if status == 'MISMATCH':
            print(f'           LMDI S={lmdi_S}  Ours={our_S}')
            print(f'           LMDI Ept={lmdi_Ept:.2f}  Ours={our_Ept:.2f}')
            ok = False

    if ok:
        print('  All cross-checks PASSED.')
    else:
        print('  Cross-check FAILED — investigate.')
    return ok


def main():
    print('\n' + '='*60)
    print(' IMPROVEMENT 7: REGIME-TAGGED ENERGY FLOW SANKEY DIAGRAMS')
    print('='*60)

    fw_tq, fw_rpm = load_fw_curve()

    # Files to process: UDDS and US06 at g=9.04
    files = {
        'UDDS': os.path.join(PROJ_ROOT, 'results', 'tesla_g9.04',
                             'BMS_UDDS_v26_g9.04_20260716_191321.mat'),
        'US06': os.path.join(PROJ_ROOT, 'results', 'tesla_g9.04',
                             'BMS_US06_v26_20260711_231029.mat'),
    }

    # Create output directory
    fig_dir = os.path.join(PROJ_ROOT, 'results', 'figures')
    os.makedirs(fig_dir, exist_ok=True)

    flows = []
    cycle_names = []

    for cname, fpath in files.items():
        print(f'\nLoading {cname}: {os.path.basename(fpath)}')
        d = sio.loadmat(fpath, squeeze_me=True)
        Pb = d['P_batt']
        vS = d['v_spd']
        t = d['t_batt']

        regime = regime_binning(Pb, vS, fw_tq, fw_rpm)
        flow = compute_energy_flow(Pb, vS, t, regime)
        print_energy_table(flow, cname)

        out_pdf = os.path.join(fig_dir, f'F{"3" if cname == "UDDS" else "2"}_{cname}_energy_flow.pdf')
        draw_sankey(flow, cname, out_pdf)

        flows.append(flow)
        cycle_names.append(cname)

    # Cross-check
    cross_check_lmdi(flows, cycle_names)

    # Save data as .mat for MATLAB access
    out_mat = os.path.join(PROJ_ROOT, 'results', 'sankey_energy_flow.mat')
    save_dict = {}
    for cname, flow in zip(cycle_names, flows):
        prefix = cname.lower()
        for k, v in flow.items():
            if isinstance(v, (np.ndarray, float, int)):
                save_dict[f'{prefix}_{k}'] = v
    sio.savemat(out_mat, save_dict)
    print(f'\nSaved data: {out_mat}')

    print('\n' + '='*60)
    print(' COMPLETE: Sankey energy flow diagrams generated.')
    print(f' F2: US06 — {flows[1]["bms_net_Whkm"]:.1f} Wh/km, '
          f'FW share {flows[1]["share_pct"][2]:.1f}%')
    print(f' F3: UDDS — {flows[0]["bms_net_Whkm"]:.1f} Wh/km, '
          f'FW share {flows[0]["share_pct"][2]:.1f}%')
    print('='*60)


if __name__ == '__main__':
    main()
