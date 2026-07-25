%% BoltEV_run_LMDI.m
%  LMDI-I decomposition for the Chevrolet Bolt EV across four drive cycles.
%
%  Loads per-cycle trace files saved by BoltEV_Simscape_AllCycles.m
%  (BoltEV_Simscape_UDDS.mat, etc.) and applies the same CRG-based
%  regime binning and LMDI-I decomposition as the Tesla matrix
%  (AE_run_LMDI_matrix.m).
%
%  IMPORTANT: all quantities are MOTOR-level (P_batt = motor electrical
%  power from Simulink, NO auxiliary load). This matches the Tesla LMDI
%  convention. BMS-level validation is separate (BoltEV_Simscape_AllCycles.m).
%
%  Rewritten 24 July 2026 to use Simscape traces. The previous version
%  used an inline pure MATLAB forward simulation which is now deprecated.
%
%  Prerequisite: run BoltEV_Simscape_AllCycles.m first (saves trace files).
%
%  Author: F. Shah Khan, University of East London, July 2026
% =========================================================================

clear; clc;
fprintf('\n================================================================\n');
fprintf(' Bolt EV: LMDI-I Decomposition — From Simscape Traces\n');
fprintf(' %s\n', datestr(now));
fprintf('================================================================\n');

%% 0. Paths and dependencies
script_dir  = fileparts(mfilename('fullpath'));
data_dir    = fullfile(script_dir, '..', 'data');
results_dir = fullfile(script_dir, '..', 'results');

% Add LMDI functions to path (shared with Tesla)
lmdi_dir = fullfile(script_dir, '..', '..', 'scripts', 'lmdi');
if exist(lmdi_dir, 'dir')
    addpath(lmdi_dir);
end
addpath(script_dir);

%% 1. Load parameters (for rw, gr, validation targets)
if ~exist('P', 'var')
    run(fullfile(script_dir, 'AE_BoltEV_LMDI_Params.m'));
end

rw = P.veh.rw;           % 0.317 m
gr = P.gear.ratio;        % 7.05

% LMDI parameters (matching Tesla runner)
eta_drive = 0.90;         % drivetrain efficiency for torque reconstruction
fold_tol  = 0.01;         % fold regimes with S < 1% into adjacent
pres_tol  = 1e-9;         % presence threshold for LMDI pair formula

%% 2. Load CRG FW onset curve
fw_file = fullfile(data_dir, 'BoltEV_FW_onset_curve.mat');
assert(exist(fw_file, 'file') == 2, ...
    'BoltEV_FW_onset_curve.mat not found. Run BoltEV_generate_fw_onset.m first.');
FW = load(fw_file);
fw_tq  = FW.fw_tq_Nm(:);
fw_rpm = FW.fw_rpm_mech(:);
fprintf('  CRG FW onset curve: %d breakpoints, V_dc = %d V, threshold = %d A\n', ...
    numel(fw_tq), FW.Vdc_V, FW.threshold_A);

%% 3. Define cycles and their trace files
c_names = {'UDDS', 'HWFET', 'US06', 'WLTP'};
targets = [101.9, 125.2, 167.8, 136.3]; % UDDS WP1, corrected 24 Jul 2026
n_cycles = numel(c_names);

trace_files = cell(1, n_cycles);
for ci = 1:n_cycles
    trace_files{ci} = fullfile(results_dir, ...
        sprintf('BoltEV_Simscape_%s.mat', c_names{ci}));
end

% Check all trace files exist
for ci = 1:n_cycles
    assert(exist(trace_files{ci}, 'file') == 2, ...
        'Trace file not found: %s\nRun BoltEV_Simscape_AllCycles.m first.', ...
        trace_files{ci});
end

rlbl = {'MTPA','Trans','FW'};

%% 4. Load traces + LMDI decomposition per cycle
CELLS = cell(1, n_cycles);
SIM   = struct();

fprintf('\n=== Loading Simscape Traces + LMDI Decomposition ===\n');
for ci = 1:n_cycles
    fprintf('\n--- %s ---\n', c_names{ci});

    % Load trace file
    D = load(trace_files{ci}, 'P_batt', 'v_spd', 't_batt', 'gear_ratio', 'cycle');

    % Gear provenance guard
    assert(abs(D.gear_ratio - gr) < 0.01, ...
        'Gear mismatch in %s: file %.2f, expected %.2f', ...
        trace_files{ci}, D.gear_ratio, gr);

    P_batt = D.P_batt(:);
    v_spd  = D.v_spd(:);
    t_batt = D.t_batt(:);

    N  = numel(P_batt);
    dt = t_batt(2) - t_batt(1);

    fprintf('  Loaded: %d pts (%.0f Hz), max v = %.1f km/h\n', ...
        N, 1/dt, max(v_spd)*3.6);

    % Energy metrics (motor-level cross-check)
    dist_km = sum(abs(v_spd(1:end-1))) * dt / 1000;

    P_trac = max(P_batt, 0);
    P_reg  = min(P_batt, 0);
    E_gross_Wh = sum(P_trac(1:end-1)) * dt / 3600;
    E_regen_Wh = abs(sum(P_reg(1:end-1)) * dt / 3600);
    E_net_Wh   = E_gross_Wh - E_regen_Wh;
    Whkm_net   = E_net_Wh / dist_km;
    regen_pct  = 100 * E_regen_Wh / E_gross_Wh;

    fprintf('  Motor-level: dist=%.2f km, net=%.1f Wh/km, regen=%.1f%%\n', ...
        dist_km, Whkm_net, regen_pct);

    SIM(ci).name      = c_names{ci};
    SIM(ci).dist_km   = dist_km;
    SIM(ci).Whkm_net  = Whkm_net;
    SIM(ci).target    = targets(ci);
    SIM(ci).regen_pct = regen_pct;

    % --- LMDI decomposition ---
    R = AE_lmdi_decomposition(P_batt, v_spd, t_batt, fw_tq, fw_rpm, ...
                               eta_drive, rw, gr);
    R = AE_fold_regimes(R, fold_tol);
    CELLS{ci} = R;

    fprintf('  LMDI: dk=%.2f km  Ept=%.1f Wh/km  S=[%.1f %.1f %.1f]%%  I=[%.1f %.1f %.1f]\n', ...
        R.dk, R.Ept, 100*R.S, R.I);
    fprintf('  Regen: Et=%.1f Wh, Er=%.1f Wh (%.1f%%)\n', R.Et, R.Er, R.regen_pct);
end

%% 5. Cross-cycle LMDI-I pairs
fprintf('\n=== Cross-Cycle LMDI-I Decomposition ===\n');
fprintf('%-18s %8s %8s %8s %8s %10s\n', ...
    'Pair', 'Delta', 'Struct', 'Intens', 'S share', 'Residual');

pairs = nchoosek(1:n_cycles, 2);
n_pairs = size(pairs, 1);
XCYC = struct('pair',{},'Dt',{},'Ds',{},'Di',{},'R',{});

for pp = 1:n_pairs
    A = CELLS{pairs(pp,1)};
    B = CELLS{pairs(pp,2)};
    [Dt, Ds, Di, Rres] = AE_lmdi_pair(A, B, pres_tol);

    if abs(Dt) > 1e-9
        s_share = 100 * Ds / Dt;
    else
        s_share = 0;
    end

    pair_name = sprintf('%s->%s', c_names{pairs(pp,1)}, c_names{pairs(pp,2)});
    XCYC(end+1) = struct('pair', pair_name, ...
        'Dt', Dt, 'Ds', Ds, 'Di', Di, 'R', Rres); %#ok<SAGROW>

    fprintf('%-18s %+8.2f %+8.2f %+8.2f %7.1f%% %10.2e\n', ...
        pair_name, Dt, Ds, Di, s_share, Rres);
end

%% 6. Residual check
allR = [XCYC.R];
maxR = max(abs(allR));
fprintf('\nMax |residual| over %d pairs: %.3e Wh/km ', n_pairs, maxR);
if maxR < 1e-6
    fprintf('(LMDI exact) OK\n');
else
    fprintf('- INVESTIGATE\n');
end

%% 7. Summary table
fprintf('\n================================================================\n');
fprintf(' SUMMARY: Bolt EV LMDI Decomposition (Simscape traces)\n');
fprintf('================================================================\n');
fprintf('%-6s  %6s  %7s  %6s  %6s  %6s  %6s\n', ...
    'Cycle', 'Dist', 'Net', 'S_MTPA', 'S_Trn', 'S_FW', 'I_FW');
fprintf('%-6s  %6s  %7s  %6s  %6s  %6s  %6s\n', ...
    '', 'km', 'Wh/km', '%', '%', '%', 'Wh/km');
fprintf('------  ------  -------  ------  ------  ------  ------\n');
for ci = 1:n_cycles
    R = CELLS{ci};
    fprintf('%-6s  %6.2f  %7.1f  %5.1f%%  %5.1f%%  %5.1f%%  %6.1f\n', ...
        c_names{ci}, R.dk, R.Ept, ...
        100*R.S(1), 100*R.S(2), 100*R.S(3), R.I(3));
end
fprintf('------  ------  -------  ------  ------  ------  ------\n');

%% 8. Key LMDI pair: UDDS->US06 (maximum contrast)
fprintf('\nKey pair: UDDS->US06\n');
for pp = 1:n_pairs
    if strcmp(XCYC(pp).pair, 'UDDS->US06')
        fprintf('  Delta: %+.1f Wh/km\n', XCYC(pp).Dt);
        fprintf('  Structural: %+.1f Wh/km (%.1f%%)\n', ...
            XCYC(pp).Ds, 100*XCYC(pp).Ds/XCYC(pp).Dt);
        fprintf('  Intensity:  %+.1f Wh/km (%.1f%%)\n', ...
            XCYC(pp).Di, 100*XCYC(pp).Di/XCYC(pp).Dt);
        fprintf('  Residual:   %.2e\n', XCYC(pp).R);
        break;
    end
end

%% 9. Save results
out_file = fullfile(results_dir, 'BoltEV_LMDI_results.mat');
gear_ratio_val = gr;
save(out_file, 'CELLS', 'XCYC', 'SIM', 'c_names', 'rlbl', ...
     'fw_tq', 'fw_rpm', 'eta_drive', 'fold_tol', 'gear_ratio_val', ...
     'trace_files');
fprintf('\nSaved: %s\n', out_file);

fprintf('\n================================================================\n');
fprintf(' LMDI decomposition complete: %s\n', datestr(now));
fprintf('================================================================\n');
