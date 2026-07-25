%% AE_cross_vehicle_LMDI.m
%  Cross-vehicle LMDI-I decomposition: Tesla Model 3 (g=9.04) vs Bolt EV (g=7.05)
%
%  For each matched cycle (UDDS, HWFET, US06, WLTP), decomposes the
%  motor-level Wh/km difference between the two vehicles into:
%    Structural effect  — different regime shares (S_MTPA, S_FW)
%    Intensity effect   — different per-regime efficiency (I_MTPA, I_FW)
%
%  This is the paper's central cross-vehicle finding: the Bolt has lower
%  gear ratio (7.05 vs 9.04) but HIGHER FW share on every cycle, because
%  motor design (psi_m, V_dc, k_Vmax) sets the FW boundary, not gear ratio.
%
%  Uses the same AE_lmdi_pair.m function as within-vehicle decompositions.
%  All quantities are MOTOR level (no P_aux), consistent with both
%  LMDI_matrix_results.mat and BoltEV_LMDI_results.mat.
%
%  Author: F. Shah Khan, University of East London, July 2026
% =========================================================================

clear; clc;
fprintf('\n================================================================\n');
fprintf(' Cross-Vehicle LMDI-I: Tesla Model 3 vs Chevrolet Bolt EV\n');
fprintf(' %s\n', datestr(now));
fprintf('================================================================\n');

%% 0. Paths
script_dir  = fileparts(mfilename('fullpath'));
results_dir = fullfile(script_dir, '..', '..', 'results');
bolt_dir    = fullfile(script_dir, '..', '..', 'chevrolet', 'results');

%% 1. Load Tesla LMDI results (g=9.04 row)
tesla_file = fullfile(results_dir, 'LMDI_matrix_results.mat');
assert(exist(tesla_file, 'file') == 2, 'Tesla LMDI results not found: %s', tesla_file);
T = load(tesla_file, 'CELLS', 'c_names', 'g_names');

% Find g=9.04 row
g_idx = find(strcmp(T.g_names, 'g9.04'));
assert(~isempty(g_idx), 'g9.04 not found in Tesla g_names');
fprintf('  Tesla: loaded %s, gear row %d (g9.04)\n', tesla_file, g_idx);
fprintf('  Tesla cycles: %s\n', strjoin(T.c_names, ', '));

%% 2. Load Bolt LMDI results
bolt_file = fullfile(bolt_dir, 'BoltEV_LMDI_results.mat');
assert(exist(bolt_file, 'file') == 2, 'Bolt LMDI results not found: %s', bolt_file);
B = load(bolt_file, 'CELLS', 'c_names', 'gear_ratio_val');
fprintf('  Bolt:  loaded %s, gear %.2f\n', bolt_file, B.gear_ratio_val);
fprintf('  Bolt cycles:  %s\n', strjoin(B.c_names, ', '));

%% 3. Match cycles (UDDS, HWFET, US06, WLTP — common to both)
match_cycles = {'UDDS', 'HWFET', 'US06', 'WLTP'};
n_match = numel(match_cycles);

% Build index maps
t_idx = zeros(1, n_match);  % Tesla column index in CELLS(g_idx, :)
b_idx = zeros(1, n_match);  % Bolt column index in CELLS{:}
for ci = 1:n_match
    ti = find(strcmp(T.c_names, match_cycles{ci}));
    bi = find(strcmp(B.c_names, match_cycles{ci}));
    assert(~isempty(ti), 'Cycle %s not found in Tesla results', match_cycles{ci});
    assert(~isempty(bi), 'Cycle %s not found in Bolt results', match_cycles{ci});
    t_idx(ci) = ti;
    b_idx(ci) = bi;
end

%% 4. Print per-cycle regime comparison
fprintf('\n=== Per-Cycle Regime Comparison (motor level) ===\n');
fprintf('%-6s  %-7s  %7s  %6s  %6s  %6s  %7s\n', ...
    'Cycle', 'Vehicle', 'Net', 'S_MTPA', 'S_Trn', 'S_FW', 'I_FW');
fprintf('%-6s  %-7s  %7s  %6s  %6s  %6s  %7s\n', ...
    '', '', 'Wh/km', '%', '%', '%', 'Wh/km');
fprintf('------  -------  -------  ------  ------  ------  -------\n');

TESLA_CELLS = cell(1, n_match);
BOLT_CELLS  = cell(1, n_match);

for ci = 1:n_match
    Rt = T.CELLS{g_idx, t_idx(ci)};
    Rb = B.CELLS{b_idx(ci)};
    TESLA_CELLS{ci} = Rt;
    BOLT_CELLS{ci}  = Rb;

    fprintf('%-6s  Tesla    %6.1f  %5.1f%%  %5.1f%%  %5.1f%%  %6.1f\n', ...
        match_cycles{ci}, Rt.Ept, 100*Rt.S(1), 100*Rt.S(2), 100*Rt.S(3), Rt.I(3));
    fprintf('        Bolt     %6.1f  %5.1f%%  %5.1f%%  %5.1f%%  %6.1f\n', ...
        Rb.Ept, 100*Rb.S(1), 100*Rb.S(2), 100*Rb.S(3), Rb.I(3));
end
fprintf('------  -------  -------  ------  ------  ------  -------\n');

%% 5. Cross-vehicle LMDI-I decomposition (same cycle, Tesla → Bolt)
pres_tol = 1e-9;

fprintf('\n=== Cross-Vehicle LMDI-I: Tesla (g=9.04) -> Bolt (g=7.05) ===\n');
fprintf('%-8s  %8s  %8s  %8s  %8s  %10s\n', ...
    'Cycle', 'Delta', 'Struct', 'Intens', 'S share', 'Residual');

XV = struct('cycle',{}, 'Dt',{}, 'Ds',{}, 'Di',{}, 'R',{});

for ci = 1:n_match
    Rt = TESLA_CELLS{ci};
    Rb = BOLT_CELLS{ci};

    [Dt, Ds, Di, Rres] = AE_lmdi_pair(Rt, Rb, pres_tol);

    if abs(Dt) > 1e-9
        s_share = 100 * Ds / Dt;
    else
        s_share = 0;
    end

    XV(ci) = struct('cycle', match_cycles{ci}, ...
        'Dt', Dt, 'Ds', Ds, 'Di', Di, 'R', Rres);

    fprintf('%-8s  %+8.2f  %+8.2f  %+8.2f  %+7.1f%%  %10.2e\n', ...
        match_cycles{ci}, Dt, Ds, Di, s_share, Rres);
end

%% 6. Residual check
allR = [XV.R];
maxR = max(abs(allR));
fprintf('\nMax |residual| over %d pairs: %.3e Wh/km ', n_match, maxR);
if maxR < 1e-6
    fprintf('(LMDI exact) OK\n');
else
    fprintf('- INVESTIGATE\n');
end

%% 7. Cross-cycle pairs within each vehicle (for comparison table)
fprintf('\n=== Key Cross-Cycle Pair: UDDS -> US06 ===\n');

% Tesla
[Dt_t, Ds_t, Di_t, Rr_t] = AE_lmdi_pair(TESLA_CELLS{1}, TESLA_CELLS{3}, pres_tol);
fprintf('  Tesla:  Delta %+.1f  Struct %+.1f (%.1f%%)  Intens %+.1f  Res %.1e\n', ...
    Dt_t, Ds_t, 100*Ds_t/Dt_t, Di_t, Rr_t);

% Bolt
[Dt_b, Ds_b, Di_b, Rr_b] = AE_lmdi_pair(BOLT_CELLS{1}, BOLT_CELLS{3}, pres_tol);
fprintf('  Bolt:   Delta %+.1f  Struct %+.1f (%.1f%%)  Intens %+.1f  Res %.1e\n', ...
    Dt_b, Ds_b, 100*Ds_b/Dt_b, Di_b, Rr_b);

%% 8. Summary interpretation
fprintf('\n=== Interpretation ===\n');

% UDDS cross-vehicle
udds_xv = XV(1);
fprintf('UDDS (Tesla -> Bolt): %+.1f Wh/km\n', udds_xv.Dt);
fprintf('  Bolt Ept = %.1f, Tesla Ept = %.1f\n', ...
    BOLT_CELLS{1}.Ept, TESLA_CELLS{1}.Ept);
fprintf('  Tesla S_FW = %.1f%%, Bolt S_FW = %.1f%%\n', ...
    100*TESLA_CELLS{1}.S(3), 100*BOLT_CELLS{1}.S(3));

% US06 cross-vehicle
us06_xv = XV(3);
fprintf('\nUS06 (Tesla -> Bolt): %+.1f Wh/km\n', us06_xv.Dt);
fprintf('  Bolt Ept = %.1f, Tesla Ept = %.1f\n', ...
    BOLT_CELLS{3}.Ept, TESLA_CELLS{3}.Ept);
fprintf('  Tesla S_FW = %.1f%%, Bolt S_FW = %.1f%%\n', ...
    100*TESLA_CELLS{3}.S(3), 100*BOLT_CELLS{3}.S(3));

fprintf('\nConclusion: Bolt has HIGHER FW share on every cycle despite\n');
fprintf('LOWER gear ratio (7.05 vs 9.04). The cause is motor design:\n');
fprintf('  psi_m: 0.1017 vs 0.0772 Wb (higher = lower omega_base)\n');
fprintf('  V_dc:  350 vs 370 V (lower = lower omega_base)\n');
fprintf('  k_Vmax: 0.904 vs 1.10 (six-step vs overmod)\n');
fprintf('  v_FW:  88.4 vs 117.6 km/h\n');

%% 9. Save results
out_file = fullfile(results_dir, 'cross_vehicle_LMDI_results.mat');
save(out_file, 'XV', 'TESLA_CELLS', 'BOLT_CELLS', 'match_cycles', ...
     'Dt_t', 'Ds_t', 'Di_t', 'Dt_b', 'Ds_b', 'Di_b');
fprintf('\nSaved: %s\n', out_file);

fprintf('\n================================================================\n');
fprintf(' Cross-vehicle LMDI complete: %s\n', datestr(now));
fprintf('================================================================\n');
