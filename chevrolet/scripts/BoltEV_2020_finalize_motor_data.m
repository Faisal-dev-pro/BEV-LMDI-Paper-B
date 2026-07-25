%% BoltEV_2020_finalize_motor_data.m
%  Combine the validated total-loss map (BoltEV_loss_map.mat, ANL Hioki-
%  fit, energy-validated to 0.5%/3.2% on US06/WLTP) with the empirical
%  current map (BoltEV_CurrentMap_2020.mat, built from real 2020 ANL
%  dyno data) to produce a genuine copper/iron loss DECOMPOSITION, all
%  on the SAME (T_grid_Nm, n_grid_rpm) breakpoint grid the Simulink
%  P_loss_map block already uses -- so no new breakpoint blocks are
%  needed, only new Table variables.
%
%  P_cu_map(T,rpm)   = 1.5 * Rs * Is_2020(T,rpm)^2      [real, physics]
%  P_iron_map(T,rpm) = P_loss_W(T,rpm) - P_cu_map(T,rpm) [residual, floored >=0]
%
%  Sum P_cu_map + P_iron_map == original validated P_loss_W by
%  construction (up to the floor), so the previously-validated total
%  energy accuracy (0.5% US06, 3.2% WLTP) is preserved unchanged.
%
%  Author: F. Shah Khan, UEL, July 2026
% =========================================================================
fprintf('\n=== Finalizing Bolt EV motor data: copper/iron decomposition ===\n');

proj_root = fileparts(fileparts(mfilename('fullpath')));
data_dir  = fullfile(proj_root, 'data');

L  = load(fullfile(data_dir, 'BoltEV_loss_map.mat'));      % T_grid_Nm, n_grid_rpm, P_loss_W
CM = load(fullfile(data_dir, 'BoltEV_CurrentMap_2020.mat'));% T_curr_bp, n_curr_bp, Is_table, id_table, iq_table, Rs

T_loss_bp = L.T_grid_Nm(:)';
n_loss_bp = L.n_grid_rpm(:)';
[TT, RR] = ndgrid(T_loss_bp, n_loss_bp);

% Interpolate the empirical current map onto the loss-map grid
Is_interp = griddedInterpolant({CM.T_curr_bp, CM.n_curr_bp}, CM.Is_table, 'linear', 'nearest');
id_interp = griddedInterpolant({CM.T_curr_bp, CM.n_curr_bp}, CM.id_table, 'linear', 'nearest');
iq_interp = griddedInterpolant({CM.T_curr_bp, CM.n_curr_bp}, CM.iq_table, 'linear', 'nearest');

Tq = min(abs(TT), max(CM.T_curr_bp));
Rq = min(abs(RR), max(CM.n_curr_bp));

Is_map = Is_interp(Tq, Rq);
id_map = id_interp(Tq, Rq);
iq_map = iq_interp(Tq, Rq);

Rs_bolt = CM.Rs;
P_cu_map = 1.5 * Rs_bolt * Is_map.^2;

P_loss_total = L.P_loss_W;   % already (T x rpm) matching T_loss_bp/n_loss_bp
P_iron_map = P_loss_total - P_cu_map;
n_floored = sum(P_iron_map(:) < 0);
P_iron_map = max(P_iron_map, 0);

fprintf('Grid: %d x %d\n', numel(T_loss_bp), numel(n_loss_bp));
fprintf('P_cu_map range   : %.0f - %.0f W\n', min(P_cu_map(:)), max(P_cu_map(:)));
fprintf('P_iron_map range : %.0f - %.0f W (%d/%d cells floored to 0)\n', ...
    min(P_iron_map(:)), max(P_iron_map(:)), n_floored, numel(P_iron_map));
fprintf('Reconstruction check: max|P_cu+P_iron - P_loss_total| = %.4g W (0 unless floored)\n', ...
    max(abs(P_cu_map(:) + P_iron_map(:) - P_loss_total(:))));

% Sanity: mean copper-loss fraction of total loss
frac_cu = P_cu_map ./ max(P_loss_total, 1);
fprintf('Mean copper-loss fraction of total loss: %.1f%%\n', 100*mean(frac_cu(P_loss_total(:)>10)));

description = ['Bolt EV motor copper/iron loss decomposition on the ' ...
    'validated BoltEV_loss_map.mat grid (T_loss_bp x n_loss_bp). ' ...
    'P_cu_map = 1.5*Rs*Is_map.^2 using Rs=0.00659 Ohm (literal, not ' ...
    'independently fit) and Is_map interpolated from the empirical 2020 ' ...
    'ANL current map (BoltEV_CurrentMap_2020.mat, real dyno data). ' ...
    'P_iron_map = P_loss_W(original, ANL-Hioki-fit, validated 0.5%%/3.2%% ' ...
    'on US06/WLTP) minus P_cu_map, floored at 0. P_cu_map + P_iron_map ' ...
    'reconstructs the original validated total loss exactly (except ' ...
    'where floored), so total-energy validation is unchanged. id_map/' ...
    'iq_map are a documented FW-visualization heuristic only (see ' ...
    'BoltEV_2020_build_currentmap.m) -- not used for loss computation.'];
source = 'BoltEV_loss_map.mat (ANL D3 dyno + Hioki) x BoltEV_CurrentMap_2020.mat (2020 ANL 46-file dataset)';

save(fullfile(data_dir, 'BoltEV_MotorData_2020_final.mat'), ...
    'T_loss_bp','n_loss_bp','P_cu_map','P_iron_map','Is_map','id_map','iq_map', ...
    'Rs_bolt','description','source');

fprintf('\nSaved: data/BoltEV_MotorData_2020_final.mat\n');
fprintf('=== Done ===\n');
