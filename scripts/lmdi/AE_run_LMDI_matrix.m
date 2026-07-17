%% AE_run_LMDI_matrix.m — LMDI-I decomposition over the verified Tesla matrix
%
%  Replaces AE_run_LMDI.m (legacy, pre-matrix: re-ran sims, 3 cycles,
%  1 gear, missing WLTP mat). This runner performs NO simulation: it
%  loads the 15 gear-verified result files from results/tesla_g*/
%  (tag tesla-matrix-complete-v26) and computes:
%
%    1. Per-cell regime quantities (S, I, e) via AE_lmdi_decomposition
%       -> CRG torque-dependent boundary, regen binned by speed
%    2. Cross-CYCLE LMDI-I pairs within each gear (10 pairs x 3 gears)
%    3. Cross-GEAR LMDI-I pairs within each cycle (3 pairs x 5 cycles)
%       -> structural vs intensity attribution of the gear penalty
%
%  Zero-regime handling (Ang & Liu 2007 analysis, verified numerically
%  17 Jul 2026): an emerging/disappearing regime contributes its FULL
%  e = S*I to the STRUCTURAL term (intensity-unchanged convention);
%  naive eps-substitution splits it arbitrarily and blows the residual.
%  Sub-threshold regimes (S < 1% distance share) are FOLDED into the
%  adjacent regime (FW->Trans->MTPA) before decomposition, so
%  near-absent slivers with noisy intensities cannot dominate the log
%  ratios. Residuals verified at machine precision (~1e-14) across all
%  25 pairs in the Python prototype.
%
%  Level note: all quantities are MOTOR-level (P_batt = inverter DC
%  input). BMS-level tables in the validation section include +aux and
%  +cable and are NOT directly comparable. Do not mix levels.
%
%  Author: F. Shah Khan, University of East London, July 2026
% -------------------------------------------------------------------------

clear; clc;
script_dir = fileparts(mfilename('fullpath'));
proj_root  = char(java.io.File(fullfile(script_dir, '..', '..')).getCanonicalPath());
addpath(script_dir);
res = @(sub, f) fullfile(proj_root, 'results', sub, f);

%% Parameters
wheel_r   = 0.326;
eta_drive = 0.90;
fold_tol  = 0.01;                  % fold regimes with S < 1% into adjacent
pres_tol  = 1e-9;                  % presence threshold in the pair formula
rlbl      = {'MTPA','Trans','FW'};
gears     = [7.0, 9.04, 11.0];
g_names   = {'g7.0','g9.04','g11.0'};
c_names   = {'UDDS','HWFET','US06','WLTP','Artemis'};

%% Load CRG FW onset curve (v2: includes T=0 breakpoint, 17 Jul 2026)
% v1 started at 22 Nm; light-load cruise below that forced an
% extrapolate-vs-clamp choice that shifted FW shares by up to 7 pp
% (found by MATLAB-vs-Python cross-check). v2 adds the T=0 point
% (8064 rpm, extracted from the LUT with the same methodology), so all
% lookups are in-range interpolation.
FW = load(fullfile(proj_root, 'model', 'FW_onset_curve_v2.mat'));
fw_tq  = FW.fw_tq_Nm(:);
fw_rpm = FW.fw_rpm_mech(:);
fprintf('CRG FW onset curve: %d breakpoints, Vdc=%.0f V, Id threshold %.0f A\n', ...
    numel(fw_tq), FW.Vdc_V, FW.threshold_A);
fprintf('Zero-torque onset: %.0f rpm; note the sweep tables use the\n', max(fw_rpm));
fprintf('906 rad/s (8652 rpm) zero-torque limit — different definition,\n');
fprintf('see reconciliation paragraph in Section 4.\n\n');

%% The 15 verified matrix files (tag tesla-matrix-complete-v26)
files = { ... % rows: gears (7.0, 9.04, 11.0); cols: UDDS HWFET US06 WLTP Artemis
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

%% 1. Per-cell regime decomposition
CELLS = cell(3,5);
fprintf('=== Per-cell regime decomposition (motor level) ===\n');
for gi = 1:3
    for ci = 1:5
        f = files{gi}{ci};
        assert(exist(f,'file')==2, 'Missing verified file: %s', f);
        D = load(f, 'P_batt', 'v_spd', 't_batt', 'gear_ratio');
        % Gear provenance guard: file must carry the expected gear
        if isfield(D, 'gear_ratio')
            assert(abs(D.gear_ratio - gears(gi)) < 0.01, ...
                'Gear mismatch in %s: file says %.2f, expected %.2f', ...
                f, D.gear_ratio, gears(gi));
        else
            warning('No gear_ratio field in %s (pre-hardening file) — verified by audit.', f);
        end
        R = AE_lmdi_decomposition(D.P_batt, D.v_spd, D.t_batt, ...
                fw_tq, fw_rpm, eta_drive, wheel_r, gears(gi));
        R = AE_fold_regimes(R, fold_tol);
        CELLS{gi,ci} = R;
        fprintf('%-6s %-8s dk=%6.2f km  Net=%6.1f Wh/km  S=[%5.1f %4.1f %5.1f]%%  I=[%6.1f %6.1f %6.1f]\n', ...
            g_names{gi}, c_names{ci}, R.dk, R.Ept, 100*R.S, R.I);
    end
end

%% 2. Cross-CYCLE pairs within each gear
fprintf('\n=== Cross-cycle LMDI-I (within gear) ===\n');
fprintf('%-8s %-18s %8s %8s %8s %10s\n','Gear','Pair','Delta','Struct','Intens','Residual');
pairs_c = nchoosek(1:5, 2);
XCYC = struct('gear',{},'pair',{},'Dt',{},'Ds',{},'Di',{},'R',{});
for gi = 1:3
    for pp = 1:size(pairs_c,1)
        A = CELLS{gi, pairs_c(pp,1)};  B = CELLS{gi, pairs_c(pp,2)};
        [Dt, Ds, Di, Rres] = AE_lmdi_pair(A, B, pres_tol);
        XCYC(end+1) = struct('gear',g_names{gi}, ...
            'pair',sprintf('%s->%s', c_names{pairs_c(pp,1)}, c_names{pairs_c(pp,2)}), ...
            'Dt',Dt,'Ds',Ds,'Di',Di,'R',Rres); %#ok<SAGROW>
        fprintf('%-8s %-18s %+8.2f %+8.2f %+8.2f %10.2e\n', ...
            g_names{gi}, XCYC(end).pair, Dt, Ds, Di, Rres);
    end
end

%% 3. Cross-GEAR pairs within each cycle (the gear design attribution)
fprintf('\n=== Cross-gear LMDI-I (within cycle) — structural share of gear penalty ===\n');
fprintf('%-8s %-16s %8s %8s %8s %8s %10s\n','Cycle','Pair','Delta','Struct','Intens','S share','Residual');
pairs_g = [1 2; 2 3; 1 3];
XGEAR = struct('cycle',{},'pair',{},'Dt',{},'Ds',{},'Di',{},'R',{});
for ci = 1:5
    for pp = 1:3
        A = CELLS{pairs_g(pp,1), ci};  B = CELLS{pairs_g(pp,2), ci};
        [Dt, Ds, Di, Rres] = AE_lmdi_pair(A, B, pres_tol);
        if abs(Dt) > 1e-9, s_share = 100*Ds/Dt; else, s_share = 0; end
        XGEAR(end+1) = struct('cycle',c_names{ci}, ...
            'pair',sprintf('%s->%s', g_names{pairs_g(pp,1)}, g_names{pairs_g(pp,2)}), ...
            'Dt',Dt,'Ds',Ds,'Di',Di,'R',Rres); %#ok<SAGROW>
        fprintf('%-8s %-16s %+8.2f %+8.2f %+8.2f %7.1f%% %10.2e\n', ...
            c_names{ci}, XGEAR(end).pair, Dt, Ds, Di, s_share, Rres);
    end
end

%% 4. Residual check
allR = [ [XCYC.R] [XGEAR.R] ];
fprintf('\nMax |residual| over all %d pairs: %.3e Wh/km ', numel(allR), max(abs(allR)));
if max(abs(allR)) < 1e-6
    fprintf('(LMDI exact) OK\n');
else
    fprintf('- INVESTIGATE before using results\n');
end

%% 5. Save
out = fullfile(proj_root, 'results', 'LMDI_matrix_results.mat');
save(out, 'CELLS', 'XCYC', 'XGEAR', 'g_names', 'c_names', 'rlbl', ...
     'fw_tq', 'fw_rpm', 'eta_drive', 'fold_tol', 'files');
fprintf('Saved: %s\nComplete: %s\n', out, datestr(now));

%% ========================================================================
%  Local functions fold_small_regimes and lmdi_pair were extracted to
%  AE_fold_regimes.m and AE_lmdi_pair.m (17 Jul 2026) so that
%  FW_boundary_comparison.m shares the identical verified code.
