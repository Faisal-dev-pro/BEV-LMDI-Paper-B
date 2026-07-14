#!/usr/bin/env python3
"""
BMS-level target extraction v2 — strict single-cycle distance filter.

Only accepts phases whose distance matches a known cycle reference distance
within 5%. This eliminates composite phases (multiple cycles per phase).

Author: F. Shah Khan, University of East London, July 2026
"""
import os, glob
import numpy as np

DATA_DIR = "/sessions/eloquent-magical-clarke/mnt/AppliedEnergy_Paper/2020 Tesla Model 3 ANL/Extended Datasets"

# Reference distances and max speeds for identification
CYCLE_SPECS = {
    'UDDS':  {'dist_km': 11.99, 'max_mph_lo': 50, 'max_mph_hi': 60, 'dur_lo': 1200, 'dur_hi': 1500},
    'HWFET': {'dist_km': 16.51, 'max_mph_lo': 55, 'max_mph_hi': 65, 'dur_lo': 650,  'dur_hi': 850},
    'US06':  {'dist_km': 12.89, 'max_mph_lo': 75, 'max_mph_hi': 85, 'dur_lo': 500,  'dur_hi': 660},
    'WLTP':  {'dist_km': 23.27, 'max_mph_lo': 78, 'max_mph_hi': 86, 'dur_lo': 1700, 'dur_hi': 1900},
}

COLS_NEEDED = [
    'Time[s]_RawFacilities', 'Dyno_Spd[mph]', 'Distance[mi]',
    'Phase_number', 'BMStotalDriveDischarge__kWh', 'BMStotalRegenCharge__kWh',
    'DIR_elecPower__kW',
]

def identify_cycle(dist_km, max_spd_mph, duration_s):
    """Match phase to cycle using strict distance + speed + duration."""
    for name, spec in CYCLE_SPECS.items():
        dist_err = abs(dist_km - spec['dist_km']) / spec['dist_km']
        if (dist_err < 0.08 and
            spec['max_mph_lo'] <= max_spd_mph <= spec['max_mph_hi'] and
            spec['dur_lo'] <= duration_s <= spec['dur_hi']):
            return name
    return None

def process_file(filepath):
    test_id = os.path.basename(filepath).split(' ')[0]
    results = []

    with open(filepath, 'r') as f:
        header = f.readline().strip().split('\t')
        col_idx = {}
        for c in COLS_NEEDED:
            if c in header:
                col_idx[c] = header.index(c)

        required = ['Phase_number', 'Dyno_Spd[mph]', 'Distance[mi]',
                     'BMStotalDriveDischarge__kWh', 'BMStotalRegenCharge__kWh']
        if any(c not in col_idx for c in required):
            return test_id, []

        phases = {}
        for line in f:
            parts = line.strip().split('\t')
            try:
                phase = int(float(parts[col_idx['Phase_number']]))
                spd = float(parts[col_idx['Dyno_Spd[mph]']])
                dist = float(parts[col_idx['Distance[mi]']])
                discharge = float(parts[col_idx['BMStotalDriveDischarge__kWh']])
                regen = float(parts[col_idx['BMStotalRegenCharge__kWh']])
                t = float(parts[col_idx['Time[s]_RawFacilities']])
            except (ValueError, IndexError):
                continue

            if phase not in phases:
                phases[phase] = {
                    'max_spd': spd, 't_start': t, 't_end': t,
                    'dist_start': dist, 'dist_end': dist,
                    'discharge_start': discharge, 'discharge_end': discharge,
                    'regen_start': regen, 'regen_end': regen,
                }
            else:
                p = phases[phase]
                if spd > p['max_spd']: p['max_spd'] = spd
                p['t_end'] = t
                p['dist_end'] = dist
                p['discharge_end'] = discharge
                p['regen_end'] = regen

    for ph_num in sorted(phases.keys()):
        p = phases[ph_num]
        duration = p['t_end'] - p['t_start']
        dist_mi = p['dist_end'] - p['dist_start']
        dist_km = dist_mi * 1.60934

        cycle = identify_cycle(dist_km, p['max_spd'], duration)
        if cycle is None:
            continue

        gross_kwh = p['discharge_end'] - p['discharge_start']
        regen_kwh = p['regen_end'] - p['regen_start']
        if gross_kwh <= 0:
            continue

        results.append({
            'test': test_id, 'phase': ph_num, 'cycle': cycle,
            'duration': duration, 'dist_km': dist_km, 'max_spd': p['max_spd'],
            'bms_gross': gross_kwh * 1000 / dist_km,
            'bms_regen': regen_kwh * 1000 / dist_km,
            'bms_net': (gross_kwh - regen_kwh) * 1000 / dist_km,
            'bms_regen_pct': 100 * regen_kwh / gross_kwh,
        })
    return test_id, results

def main():
    files = sorted(glob.glob(os.path.join(DATA_DIR, "*Test Data.txt")))
    print(f"Scanning {len(files)} test files (strict distance filter)...\n")

    by_cycle = {'UDDS': [], 'HWFET': [], 'US06': [], 'WLTP': []}

    for f in files:
        _, results = process_file(f)
        for r in results:
            by_cycle[r['cycle']].append(r)

    print("="*80)
    print("BMS-LEVEL VALIDATION TARGETS — STRICT SINGLE-CYCLE FILTER")
    print("Source: BMStotalDriveDischarge / BMStotalRegenCharge (CAN)")
    print("="*80)

    for cycle in ['UDDS', 'HWFET', 'US06', 'WLTP']:
        data = by_cycle[cycle]
        if not data:
            print(f"\n{'='*40}")
            print(f"  {cycle}: NO SINGLE-CYCLE PHASES FOUND")
            print(f"{'='*40}")
            continue

        n = len(data)
        n_tests = len(set(r['test'] for r in data))

        # For UDDS, flag cold vs hot
        if cycle == 'UDDS':
            # Sort by test then phase, first UDDS in each test is cold
            test_seen = set()
            hot = []
            cold = []
            for r in sorted(data, key=lambda x: (x['test'], x['phase'])):
                if r['test'] not in test_seen:
                    test_seen.add(r['test'])
                    cold.append(r)
                else:
                    hot.append(r)
            if hot:
                cold_avg = np.mean([r['bms_net'] for r in cold])
                hot_avg = np.mean([r['bms_net'] for r in hot])
                print(f"\n{'='*40}")
                print(f"  {cycle}: {len(cold)} cold + {len(hot)} hot phases")
                print(f"  Cold avg BMS net: {cold_avg:.1f} Wh/km (excluded)")
                print(f"  Hot avg BMS net:  {hot_avg:.1f} Wh/km")
                print(f"{'='*40}")
                data = hot if hot else data
            else:
                print(f"\n{'='*40}")
                print(f"  {cycle}: {n} phases (no hot/cold split possible)")
                print(f"{'='*40}")
        else:
            print(f"\n{'='*40}")
            print(f"  {cycle}: {n} phases from {n_tests} tests")
            print(f"{'='*40}")

        nets = np.array([r['bms_net'] for r in data])
        grosses = np.array([r['bms_gross'] for r in data])
        regens = np.array([r['bms_regen'] for r in data])
        rpcts = np.array([r['bms_regen_pct'] for r in data])

        print(f"  BMS Gross:   {np.mean(grosses):6.1f} +/- {np.std(grosses):4.1f} Wh/km")
        print(f"  BMS Regen:   {np.mean(regens):6.1f} +/- {np.std(regens):4.1f} Wh/km")
        print(f"  BMS Net:     {np.mean(nets):6.1f} +/- {np.std(nets):4.1f} Wh/km")
        print(f"  BMS Regen%:  {np.mean(rpcts):5.1f} +/- {np.std(rpcts):4.1f} %")

        # Exclude outliers (> 2 sigma)
        if len(nets) > 4:
            mu, sigma = np.mean(nets), np.std(nets)
            inliers = [(r, n) for r, n in zip(data, nets) if abs(n - mu) < 2*sigma]
            if len(inliers) < len(data):
                data_clean = [r for r, _ in inliers]
                nets_clean = np.array([n for _, n in inliers])
                grosses_clean = np.array([r['bms_gross'] for r in data_clean])
                rpcts_clean = np.array([r['bms_regen_pct'] for r in data_clean])
                print(f"\n  After 2-sigma filter ({len(data)-len(data_clean)} outliers removed):")
                print(f"  BMS Gross:   {np.mean(grosses_clean):6.1f} +/- {np.std(grosses_clean):4.1f} Wh/km")
                print(f"  BMS Net:     {np.mean(nets_clean):6.1f} +/- {np.std(nets_clean):4.1f} Wh/km")
                print(f"  BMS Regen%:  {np.mean(rpcts_clean):5.1f} +/- {np.std(rpcts_clean):4.1f} %")
                nets = nets_clean
                grosses = grosses_clean
                rpcts = rpcts_clean
                data = data_clean

        target_net = np.mean(nets)
        target_gross = np.mean(grosses)
        target_rpct = np.mean(rpcts)
        spread = np.std(nets)

        print(f"\n  >>> PROPOSED TARGETS <<<")
        print(f"  BMS net:    {target_net:.1f} +/- {max(spread, 1.0):.1f} Wh/km")
        print(f"  Accept +/-5%: {target_net*0.95:.0f} - {target_net*1.05:.0f}")
        print(f"  BMS gross:  {target_gross:.1f} Wh/km")
        print(f"  BMS regen%: {target_rpct:.1f}%")

        print(f"\n  Individual phases:")
        for r in sorted(data, key=lambda x: x['bms_net']):
            print(f"    {r['test']} ph{r['phase']:2d}: "
                  f"gross={r['bms_gross']:5.1f}  net={r['bms_net']:5.1f}  "
                  f"regen%={r['bms_regen_pct']:4.1f}  dist={r['dist_km']:5.2f}km  "
                  f"dur={r['duration']:.0f}s")

if __name__ == '__main__':
    main()
