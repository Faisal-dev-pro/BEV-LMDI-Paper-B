%% BoltEV_2020_build_currentmap.m
%  Build an EMPIRICAL stator-current map Is(T,rpm) directly from the real
%  2020 Chevrolet Bolt ANL dynamometer data (46 files, ~1.28M rows), used
%  to give the Bolt EV Simulink model genuine motor presence/operation
%  (real measured current draw + physically-grounded copper loss) after
%  the constant-Ld/Lq analytical MTPA fit was shown to fail at high torque
%  (see BoltEV_2020_motor_param_fit.m: -26% to -60% error above 150 Nm,
%  with physically implausible fitted inductances).
%
%  Copper loss only needs total |Is|^2 (P_cu = 1.5*Rs*Is^2), so no id/iq
%  split is required for loss physics. The id/iq split built here is a
%  DOCUMENTED, clearly-labelled heuristic for the field-weakening
%  narrative (i_d<0 above base speed) only -- it does not feed the loss
%  computation.
%
%  Author: F. Shah Khan, UEL, July 2026
% =========================================================================

fprintf('\n=== Bolt EV 2020 ANL data: empirical current map ===\n');

proj_root = fileparts(fileparts(mfilename('fullpath')));
val_file  = fullfile(proj_root, 'results', 'BoltEV_2020_param_validation.mat');
V = load(val_file);
CR = V.CR;   % literal params, kept for Rs and as a fallback/reference

T_all   = abs(V.T_f);
rpm_all = abs(V.rpm_f);
Is_all  = abs(V.I_f);

valid = ~isnan(T_all) & ~isnan(rpm_all) & ~isnan(Is_all) & rpm_all < 11000 & T_all < 450;
T_all = T_all(valid); rpm_all = rpm_all(valid); Is_all = Is_all(valid);
fprintf('Points for empirical map: %d\n', numel(T_all));

%% ---- 1) Torque-speed envelope (max deliverable torque vs speed) ----
rpm_env_edges = 0:100:9000;
rpm_env_mid   = 0.5*(rpm_env_edges(1:end-1)+rpm_env_edges(2:end));
T_env = nan(size(rpm_env_mid));
for b = 1:numel(rpm_env_mid)
    m = rpm_all >= rpm_env_edges(b) & rpm_all < rpm_env_edges(b+1);
    if sum(m) > 30
        T_env(b) = prctile(T_all(m), 97);
    end
end
valid_env = ~isnan(T_env);

% Base speed: plateau = median of envelope over first 1500 rpm; base
% speed = first rpm where envelope falls below 90% of plateau, after the
% plateau region (skip the first 2 bins which can be noisy/low-N).
plateau_mask = rpm_env_mid > 200 & rpm_env_mid < 2000 & valid_env;
T_plateau = median(T_env(plateau_mask));
drop_idx = find(rpm_env_mid > 1500 & valid_env & T_env < 0.9*T_plateau, 1, 'first');
if isempty(drop_idx)
    n_base = 3000;  % fallback
else
    n_base = rpm_env_mid(drop_idx);
end
fprintf('Torque plateau (rated torque): %.1f Nm\n', T_plateau);
fprintf('Base speed (envelope 90%% dropoff, empirical, informational only): %.0f rpm\n', n_base);

% The empirical envelope-dropoff estimate above is noisy (few real drive-
% cycle points reach high torque AND high speed simultaneously). For the
% id/iq FW-visualization split, use the documented [D]-tier base speed
% from AE_BoltEV_LMDI_Params.m (Patel FEA Table III) instead, which is
% independently validated and not subject to that sparse-data artifact.
n_base_empirical = n_base;
n_base = 4400;  % P.motor.n_base, Patel FEA Table III
fprintf('Base speed used for id/iq split (P.motor.n_base, Patel FEA): %.0f rpm\n', n_base);

%% ---- 2) Empirical Is(T,rpm) map: bin + median + fill + smooth ----
T_edges   = 0:5:ceil(prctile(T_all,99.9)/5)*5;
rpm_edges = 0:150:ceil(prctile(rpm_all,99.9)/150)*150;
T_vec2   = 0.5*(T_edges(1:end-1)+T_edges(2:end));
rpm_vec2 = 0.5*(rpm_edges(1:end-1)+rpm_edges(2:end));

Is_grid = nan(numel(T_vec2), numel(rpm_vec2));
N_grid  = zeros(numel(T_vec2), numel(rpm_vec2));

Tbin_idx   = discretize(T_all, T_edges);
rpmbin_idx = discretize(rpm_all, rpm_edges);
okbin = ~isnan(Tbin_idx) & ~isnan(rpmbin_idx);

accum = accumarray([Tbin_idx(okbin), rpmbin_idx(okbin)], Is_all(okbin), ...
    [numel(T_vec2), numel(rpm_vec2)], @median, NaN);
cnt   = accumarray([Tbin_idx(okbin), rpmbin_idx(okbin)], 1, ...
    [numel(T_vec2), numel(rpm_vec2)], @sum, 0);
Is_grid = accum;
N_grid  = cnt;

fprintf('Grid: %d x %d (T x rpm), %d/%d cells populated (N>0)\n', ...
    numel(T_vec2), numel(rpm_vec2), sum(N_grid(:)>0), numel(N_grid));

% Fill sparse/empty cells via scattered interpolation over populated cells
[TT, RR] = ndgrid(T_vec2, rpm_vec2);
pop = N_grid > 3 & ~isnan(Is_grid);
F = scatteredInterpolant(TT(pop), RR(pop), Is_grid(pop), 'linear', 'nearest');
Is_filled = Is_grid;
Is_filled(~pop) = F(TT(~pop), RR(~pop));

% Light smoothing to remove dyno-noise jaggedness (3x3 moving average)
k = ones(3,3)/9;
Is_smooth = conv2(Is_filled, k, 'same');
% Fix edge bias from conv2 'same' zero-padding by renormalizing edges
norm_mask = conv2(ones(size(Is_filled)), k, 'same');
Is_smooth = Is_smooth ./ norm_mask;

% Enforce monotonic non-negative and physically sane (Is=0 at T=0)
Is_smooth(1,:) = 0;
Is_smooth = max(Is_smooth, 0);

fprintf('Is map range: %.1f - %.1f A\n', min(Is_smooth(:)), max(Is_smooth(:)));

%% ---- 3) id/iq split (documented heuristic, does NOT affect copper loss) ----
id_map = zeros(size(Is_smooth));
iq_map = Is_smooth;
for r = 1:numel(rpm_vec2)
    if rpm_vec2(r) > n_base
        frac = min(1, (rpm_vec2(r)-n_base)/(0.6*n_base)) * 0.55;  % ramps to 55% of Is
        id_map(:,r)  = -frac .* Is_smooth(:,r);   % negative d-axis current (FW)
        iq_map(:,r)  = sqrt(max(Is_smooth(:,r).^2 - id_map(:,r).^2, 0));
    end
end

%% ---- 4) Validate: does the empirical map reproduce real data by band? ----
Is_interp = griddedInterpolant({T_vec2, rpm_vec2}, Is_smooth, 'linear', 'nearest');
Is_check = Is_interp(min(T_all,max(T_vec2)), min(rpm_all,max(rpm_vec2)));
err = Is_check - Is_all;
fprintf('\nSelf-consistency check (should be small, map built from same data):\n');
fprintf('RMSE: %.2f A, MAPE: %.1f%%\n', sqrt(mean(err.^2)), mean(abs(err)./max(Is_all,1))*100);

edges2 = [0 20 60 100 150 200 300 500];
fprintf('\nBy torque band:\n');
for b = 1:numel(edges2)-1
    m = T_all >= edges2(b) & T_all < edges2(b+1);
    if sum(m) > 5
        fprintf('%4d-%4d Nm  N=%8d  I_meas=%7.1f  I_map=%7.1f  err=%+5.1f%%\n', ...
            edges2(b), edges2(b+1), sum(m), mean(Is_all(m)), mean(Is_check(m)), ...
            100*(mean(Is_check(m))-mean(Is_all(m)))/mean(Is_all(m)));
    end
end

%% ---- 5) Save ----
T_curr_bp  = T_vec2;
n_curr_bp  = rpm_vec2;
Is_table   = Is_smooth;
id_table   = id_map;
iq_table   = iq_map;
Rs         = CR.Rs;                 % kept literal (0.00659 Ohm) - not identifiable from Is alone
p          = CR.p;
base_speed_rpm = n_base;
rated_torque_Nm = T_plateau;
description = ['Empirical Bolt EV stator current map Is(T,rpm), built by binning/' ...
    'smoothing 738581+ real (T,rpm,I) points from 2020 Chevrolet Bolt ANL ' ...
    'D3 dynamometer + Hioki + CAN data (46 test files). Replaces the ' ...
    'constant-Ld/Lq analytical MTPA model, which was shown to error -26% ' ...
    'to -60% at torque >150 Nm with physically implausible fitted ' ...
    'inductances. Copper loss should be computed as 1.5*Rs*Is_table.^2 ' ...
    '(does not require id/iq split). The id/iq split provided is a ' ...
    'documented heuristic for FW visualization only (linear ramp of ' ...
    '|id| to 55% of Is over base_speed_rpm to 1.6*base_speed_rpm), NOT ' ...
    'independently validated -- do not use id_table/iq_table for loss ' ...
    'or torque computation, only Is_table.'];
source = '2020 Chevrolet Bolt, ANL Extended Datasets, 46 files (620090xx Test Data.txt), D3 dynamometer + Hioki power analyser + CAN, 10Hz';

out_dir = fullfile(proj_root, 'data');
save(fullfile(out_dir, 'BoltEV_CurrentMap_2020.mat'), ...
    'T_curr_bp','n_curr_bp','Is_table','id_table','iq_table','Rs','p', ...
    'base_speed_rpm','n_base_empirical','rated_torque_Nm','description','source');

fprintf('\nSaved: data/BoltEV_CurrentMap_2020.mat\n');
fprintf('=== Done ===\n');
