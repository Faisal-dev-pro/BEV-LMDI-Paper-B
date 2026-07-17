%% AE_gear_design.m — Improvement 9: Gear Ratio Design Analysis (Paper Section 5)
%
%  Extracts the design chart data from the verified 15-cell Tesla matrix
%  and the LMDI cross-gear decomposition. Produces:
%
%    1. BMS net Wh/km vs gear ratio (5 cycles, 3 gear ratios)
%    2. FW distance share vs gear ratio (CRG classifier, motor level)
%    3. Gear penalty deltas and marginal Wh/km per unit gear ratio
%    4. Superlinearity metric (second step / first step penalty ratio)
%    5. FW onset speed vs gear ratio and critical gear ratio per cycle
%    6. Cross-gear LMDI structural shares (from LMDI_matrix_results.mat)
%
%  NO simulation. Loads verified files and LMDI results.
%  All data was computed in AE_run_LMDI_matrix.m (tag lmdi-matrix-verified).
%
%  Cross-check: Gear_design_expected_values.md (Python prototype).
%
%  Author: F. Shah Khan, University of East London, July 2026
% -------------------------------------------------------------------------

clear; clc;
script_dir = fileparts(mfilename('fullpath'));
proj_root  = char(java.io.File(fullfile(script_dir, '..', '..')).getCanonicalPath());
addpath(script_dir);

fprintf('\n================================================================\n');
fprintf(' GEAR RATIO DESIGN ANALYSIS — Improvement 9 (Paper Section 5)\n');
fprintf(' Started: %s\n', datestr(now));
fprintf('================================================================\n\n');

%% Parameters
gears   = [7.0, 9.04, 11.0];
g_names = {'g7.0','g9.04','g11.0'};
c_names = {'UDDS','HWFET','US06','WLTP','Artemis'};
ng = numel(gears);
nc = numel(c_names);
omega_base = 906;   % [rad/s] CRG-derived base speed
rw = 0.326;         % [m] wheel radius

%% 1. Load BMS net Wh/km from verified simulation files
res = @(sub, f) fullfile(proj_root, 'results', sub, f);
fnames = { ...
  {res('tesla_g7.0','BMS_UDDS_v26_g7.0_20260713_021559.mat'), ...
   res('tesla_g7.0','BMS_HWFET_v26_g7.0_20260717_071102.mat'), ...
   res('tesla_g7.0','BMS_US06_v26_g7.0_20260712_144011.mat'), ...
   res('tesla_g7.0','BMS_WLTP_v26_g7.0_20260713_081328.mat'), ...
   res('tesla_g7.0','BMS_ArtemisMW130_v26_g7.0_20260714_234304.mat')}, ...
  {res('tesla_g9.04','BMS_UDDS_v26_g9.04_20260716_191321.mat'), ...
   res('tesla_g9.04','BMS_HWFET_v26_g9.04_20260717_040227.mat'), ...
   res('tesla_g9.04','BMS_US06_v26_20260711_231029.mat'), ...
   res('tesla_g9.04','BMS_WLTP_v26_20260712_065209.mat'), ...
   res('tesla_g9.04','BMS_ArtemisMW130_v26_g9.04_20260715_100638.mat')}, ...
  {res('tesla_g11.0','BMS_UDDS_v26_g11.00_20260716_020313.mat'), ...
   res('tesla_g11.0','BMS_HWFET_v26_g11.0_20260717_141827.mat'), ...
   res('tesla_g11.0','BMS_US06_v26_g11.0_20260714_001504.mat'), ...
   res('tesla_g11.0','BMS_WLTP_v26_g11.0_20260714_172410.mat'), ...
   res('tesla_g11.0','BMS_ArtemisMW130_v26_g11.0_20260716_085756.mat')}};

bms_net   = zeros(ng, nc);
bms_gross = zeros(ng, nc);
bms_regen = zeros(ng, nc);

fprintf('Loading 15 verified BMS files...\n');
for gi = 1:ng
    for ci = 1:nc
        f = fnames{gi}{ci};
        assert(exist(f,'file')==2, 'Missing: %s', f);
        D = load(f, 'E_bms_net_Wh', 'E_bms_gross_Wh', 'E_bms_regen_Wh', 'dist_km');
        bms_net(gi,ci)   = D.E_bms_net_Wh / D.dist_km;
        bms_gross(gi,ci) = D.E_bms_gross_Wh / D.dist_km;
        bms_regen(gi,ci) = D.E_bms_regen_Wh / D.E_bms_gross_Wh * 100;
    end
end

fprintf('\n================================================================\n');
fprintf(' BMS NET Wh/km (from simulation files)\n');
fprintf('================================================================\n');
fprintf('%-6s  %8s %8s %8s %8s %8s\n', 'Gear', c_names{:});
for gi = 1:ng
    fprintf('%6.2f  %8.1f %8.1f %8.1f %8.1f %8.1f\n', gears(gi), bms_net(gi,:));
end

%% 2. Load LMDI matrix results (motor-level)
LM = load(fullfile(proj_root, 'results', 'LMDI_matrix_results.mat'));
motor_ept = zeros(ng, nc);
fw_share  = zeros(ng, nc);

fprintf('\n================================================================\n');
fprintf(' MOTOR-LEVEL NET INTENSITY (Ept, Wh/km)\n');
fprintf('================================================================\n');
fprintf('%-6s  %8s %8s %8s %8s %8s\n', 'Gear', c_names{:});
for gi = 1:ng
    for ci = 1:nc
        R = LM.CELLS{gi, ci};
        motor_ept(gi,ci) = R.Ept;
        fw_share(gi,ci)  = R.S(3) * 100;
    end
    fprintf('%6.2f  %8.2f %8.2f %8.2f %8.2f %8.2f\n', gears(gi), motor_ept(gi,:));
end

fprintf('\n================================================================\n');
fprintf(' FW DISTANCE SHARE (%%) — CRG classifier, motor level\n');
fprintf('================================================================\n');
fprintf('%-6s  %8s %8s %8s %8s %8s\n', 'Gear', c_names{:});
for gi = 1:ng
    fprintf('%6.2f  %8.1f %8.1f %8.1f %8.1f %8.1f\n', gears(gi), fw_share(gi,:));
end

%% 3. Gear penalty deltas (BMS level)
fprintf('\n================================================================\n');
fprintf(' GEAR PENALTY (BMS net Wh/km delta)\n');
fprintf('================================================================\n');
steps = {1,2,'g7.0 -> g9.04'; 2,3,'g9.04 -> g11.0'; 1,3,'g7.0 -> g11.0'};
fprintf('%-16s  %8s %8s %8s %8s %8s\n', 'Step', c_names{:});
delta_bms = zeros(3, nc);
for si = 1:3
    i = steps{si,1};  j = steps{si,2};
    delta_bms(si,:) = bms_net(j,:) - bms_net(i,:);
    fprintf('%-16s  %+8.1f %+8.1f %+8.1f %+8.1f %+8.1f\n', steps{si,3}, delta_bms(si,:));
end

%% 4. Marginal penalty (Wh/km per unit gear ratio)
fprintf('\n================================================================\n');
fprintf(' MARGINAL PENALTY: Wh/km per unit gear ratio (BMS net)\n');
fprintf('================================================================\n');
dg = [gears(2)-gears(1), gears(3)-gears(2), gears(3)-gears(1)];
fprintf('%-16s  %5s  %8s %8s %8s %8s %8s\n', 'Step', 'dg', c_names{:});
marginal = zeros(3, nc);
for si = 1:3
    marginal(si,:) = delta_bms(si,:) / dg(si);
    fprintf('%-16s  %5.2f  %8.2f %8.2f %8.2f %8.2f %8.2f\n', steps{si,3}, dg(si), marginal(si,:));
end

%% 5. Superlinearity check
fprintf('\n================================================================\n');
fprintf(' SUPERLINEARITY: penalty per gear step\n');
fprintf('================================================================\n');
fprintf('%-8s %10s %10s %8s %14s\n', 'Cycle', '7->9.04', '9.04->11', 'ratio', 'superlinear?');
superlin_ratio = zeros(1, nc);
for ci = 1:nc
    d1 = delta_bms(1,ci);  % g7->g9.04
    d2 = delta_bms(2,ci);  % g9.04->g11
    m1 = d1 / dg(1);  % per unit ratio
    m2 = d2 / dg(2);
    superlin_ratio(ci) = m2 / m1;
    if superlin_ratio(ci) > 1.1
        tag = 'YES';
    elseif superlin_ratio(ci) > 0.9
        tag = 'marginal';
    else
        tag = 'no';
    end
    fprintf('%-8s %+9.1f Wh %+9.1f Wh %7.2fx %14s\n', c_names{ci}, d1, d2, superlin_ratio(ci), tag);
end

%% 6. FW onset speed vs gear ratio
fprintf('\n================================================================\n');
fprintf(' FW ONSET SPEED vs GEAR RATIO\n');
fprintf('================================================================\n');
g_fine = [7.0, 8.0, 9.04, 10.0, 11.0];
for k = 1:numel(g_fine)
    v_fw = omega_base * rw / g_fine(k);
    fprintf('  g=%5.2f  v_FW = %.1f m/s = %.1f km/h\n', g_fine(k), v_fw, v_fw*3.6);
end
fprintf('  Formula: v_FW = omega_base * r_w / g = 906 * 0.326 / g\n');

%% 7. Critical gear ratio per cycle
fprintf('\n================================================================\n');
fprintf(' CRITICAL GEAR RATIO (g where FW onset = cycle vmax)\n');
fprintf('================================================================\n');
cycle_vmax_ms = [25.3, 26.8, 35.8, 33.3, 36.6];
cycle_vmax_kmh = cycle_vmax_ms * 3.6;
g_crit = omega_base * rw ./ cycle_vmax_ms;
for ci = 1:nc
    fprintf('  %-8s  vmax=%.1f m/s (%.1f km/h)  g_crit=%.2f\n', ...
        c_names{ci}, cycle_vmax_ms(ci), cycle_vmax_kmh(ci), g_crit(ci));
end

%% 8. Cross-gear LMDI structural shares
fprintf('\n================================================================\n');
fprintf(' CROSS-GEAR LMDI (motor level) — structural share of gear penalty\n');
fprintf('================================================================\n');
fprintf('%-8s %-16s %8s %8s %8s %8s %10s\n', 'Cycle', 'Pair', 'Dt', 'Ds', 'Di', 'Ssh', 'Resid');
for k = 1:numel(LM.XGEAR)
    X = LM.XGEAR(k);
    if abs(X.Dt) > 1e-9, ssh = 100*X.Ds/X.Dt; else, ssh = 0; end
    fprintf('%-8s %-16s %+8.2f %+8.2f %+8.2f %7.1f%% %10.2e\n', ...
        X.cycle, X.pair, X.Dt, X.Ds, X.Di, ssh, X.R);
end

%% 9. Cross-check against Python prototype
fprintf('\n================================================================\n');
fprintf(' CROSS-CHECK vs PYTHON PROTOTYPE\n');
fprintf('================================================================\n');

% Expected BMS net from Python (Gear_design_expected_values.md)
expected_bms_net = [ ...
    105.3, 112.1, 143.3, 122.2, 154.0; ...
    108.1, 116.9, 148.7, 126.6, 159.7; ...
    110.6, 122.3, 155.1, 131.5, 168.5];

expected_fw = [ ...
    0.0,  0.0,  0.0,  0.0,  0.0; ...
    0.0,  0.0, 36.3, 21.4, 70.3; ...
    4.1, 29.7, 79.1, 36.5, 85.9];

expected_superlin = [0.94, 1.18, 1.23, 1.18, 1.60];

bms_ok = true;
for gi = 1:ng
    for ci = 1:nc
        d = abs(bms_net(gi,ci) - expected_bms_net(gi,ci));
        if d > 0.15
            fprintf('  BMS MISMATCH: %s %s actual=%.1f expected=%.1f\n', ...
                g_names{gi}, c_names{ci}, bms_net(gi,ci), expected_bms_net(gi,ci));
            bms_ok = false;
        end
    end
end
if bms_ok
    fprintf('BMS net Wh/km: all match to 0.15 Wh/km. OK\n');
end

fw_ok = true;
for gi = 1:ng
    for ci = 1:nc
        d = abs(fw_share(gi,ci) - expected_fw(gi,ci));
        if d > 0.15
            fprintf('  FW MISMATCH: %s %s actual=%.1f expected=%.1f\n', ...
                g_names{gi}, c_names{ci}, fw_share(gi,ci), expected_fw(gi,ci));
            fw_ok = false;
        end
    end
end
if fw_ok
    fprintf('FW distance shares: all match to 0.15 pp. OK\n');
end

sl_ok = true;
for ci = 1:nc
    d = abs(superlin_ratio(ci) - expected_superlin(ci));
    if d > 0.03
        fprintf('  SUPERLIN MISMATCH: %s actual=%.2f expected=%.2f\n', ...
            c_names{ci}, superlin_ratio(ci), expected_superlin(ci));
        sl_ok = false;
    end
end
if sl_ok
    fprintf('Superlinearity ratios: all match to 0.03. OK\n');
end

if bms_ok && fw_ok && sl_ok
    fprintf('\nAll cross-checks PASSED.\n');
else
    fprintf('\nCross-check FAILED — investigate.\n');
end

%% 10. Save
out = fullfile(proj_root, 'results', 'gear_design_analysis.mat');
save(out, 'gears', 'g_names', 'c_names', ...
     'bms_net', 'bms_gross', 'bms_regen', ...
     'motor_ept', 'fw_share', ...
     'delta_bms', 'marginal', 'superlin_ratio', ...
     'g_crit', 'cycle_vmax_ms', 'cycle_vmax_kmh', ...
     'omega_base', 'rw');
fprintf('\nSaved: %s\n', out);

fprintf('\n================================================================\n');
fprintf(' COMPLETE: %s\n', datestr(now));
fprintf(' Paper Section 5: gear ratio design chart data ready.\n');
fprintf(' Key finding: superlinear penalty on high-speed cycles\n');
fprintf(' (1.61x on Artemis), driven by FW onset below cycle vmax.\n');
fprintf(' g_crit(US06) = 8.25, g_crit(Artemis) = 8.07.\n');
fprintf('================================================================\n');
