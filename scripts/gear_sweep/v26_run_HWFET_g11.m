%% v26_run_HWFET_g11.m — HWFET at gear ratio 11.0
%
%  Gear ratio sweep: g = 11.0 (baseline 9.04).
%  FW onset: 96.7 km/h (baseline 117.6 km/h).
%
%  Prerequisites:
%    - Drive Cycle Source set to "HWFET (765 seconds)" via GUI
%    - Model saved after GUI change
%
%  Usage:
%    cd('v26');
%    run('v26_run_HWFET_g11.m');
%
%  Author: F. Shah Khan, University of East London, July 2026
% -------------------------------------------------------------------------

clear; clc;
fprintf('\n========================================================\n');
fprintf(' v26 HWFET — GEAR RATIO 11.0\n');
fprintf(' Started: %s\n', datestr(now));
fprintf('========================================================\n\n');

%% 1. Set gear ratio override BEFORE loading params
gear_override = 11.0;
fprintf('1. Gear ratio override: %.1f (baseline 9.04)\n', gear_override);

%% 2. Open model and load parameters
mdl   = 'AE_TeslaM3_LMDI';
cycle = 'HWFET';

% Path fix (16 Jul 2026): the old computation resolved scripts/model,
% which does not exist. Resolve the project root properly, put model/
% and validation/ on the path, and run with cwd = model/ so InitFcn,
% caches, and load_system all resolve to the canonical model.
v26_dir   = fileparts(mfilename('fullpath'));
proj_root = char(java.io.File(fullfile(v26_dir, '..', '..')).getCanonicalPath());
addpath(fullfile(proj_root, 'model'));
addpath(fullfile(proj_root, 'scripts', 'validation'));
cd(fullfile(proj_root, 'model'));

fprintf('2. Loading model and parameters...\n');
% Force a FRESH model load: a plain sim() on an already-loaded model can
% reuse the in-memory compiled Simscape network from a previous run at a
% DIFFERENT gear ratio, even in Normal mode (15 Jul 2026 incident: UDDS
% g=11 reused the Artemis g=9.04 compile and produced g=9.04 physics).
if bdIsLoaded(mdl), bdclose(mdl); end
load_system(mdl);
run('AE_TeslaM3_LMDI_Params.m');

% Confirm gear ratio applied
fprintf('   gear_ratio = %.2f (expect 11.00)\n', gear_ratio);
if abs(gear_ratio - 11.0) > 0.01
    error('gear_ratio is %.2f, expected 11.0. Check gear_override logic.', gear_ratio);
end

%% 3. Verify Drive Cycle Source is connected to Longitudinal_Driver
fprintf('3. Verifying model wiring...\n');

dcs = [mdl '/Drive Cycle Source'];
ld  = [mdl '/Longitudinal_Driver'];

ld_ph = get_param(ld, 'PortHandles');
velref_line = get_param(ld_ph.Inport(1), 'Line');
if velref_line == -1
    error('VelRef on Longitudinal_Driver has no input. Reconnect Drive Cycle Source.');
end
src_blk = get_param(velref_line, 'SrcBlockHandle');
src_name = get_param(src_blk, 'Name');

if ~strcmp(src_name, 'Drive Cycle Source')
    fprintf('   WARNING: VelRef connected to "%s", not Drive Cycle Source.\n', src_name);
    fprintf('   Fixing: reconnecting Drive Cycle Source...\n');
    delete_line(velref_line);
    try
        bypass_blk = [mdl '/CycleSpeed_FromWS'];
        bp_ph = get_param(bypass_blk, 'PortHandles');
        if ~isempty(bp_ph.Outport)
            bp_line = get_param(bp_ph.Outport(1), 'Line');
            if bp_line ~= -1, delete_line(bp_line); end
        end
        delete_block(bypass_blk);
        fprintf('   Deleted CycleSpeed_FromWS bypass block.\n');
    catch
    end
    add_line(mdl, 'Drive Cycle Source/1', 'Longitudinal_Driver/1', ...
        'autorouting', 'smart');
    fprintf('   Drive Cycle Source reconnected.\n');
else
    fprintf('   Drive Cycle Source -> VelRef: OK\n');
end

%% 4. Verify HWFET cycle data
fprintf('4. Checking drive cycle data...\n');

mws = get_param(dcs, 'MaskWSVariables');
idx = find(strcmp({mws.Name}, 'DriveCycle'));
if isempty(idx)
    error('DriveCycle not found in Drive Cycle Source mask workspace.');
end
dc_ts = mws(idx).Value;

vmax_mask = max(dc_ts.Data);
tmax_mask = dc_ts.Time(end);
fprintf('   Mask: %d pts, t=[0, %.0f]s, vmax=%.2f m/s (%.1f km/h)\n', ...
    numel(dc_ts.Time), tmax_mask, vmax_mask, vmax_mask*3.6);

if vmax_mask < 24 || vmax_mask > 30
    error('vmax=%.1f m/s. Expected ~26.8 for HWFET. Set cycle via GUI first.', vmax_mask);
end
if tmax_mask < 700 || tmax_mask > 800
    error('Duration %.0f s. Expected ~765 for HWFET. Set cycle via GUI first.', tmax_mask);
end
fprintf('   Confirmed: HWFET (vmax %.1f km/h, %.0f s)\n', vmax_mask*3.6, tmax_mask);

%% 5. FW onset speed at g=11.0
omega_base = 906;  % [rad/s] CRG-derived base speed
rw = 0.326;        % [m] wheel radius
v_FW = omega_base * rw / gear_ratio;
fprintf('5. FW onset at g=11.0: %.1f m/s = %.1f km/h\n', v_FW, v_FW*3.6);
fprintf('   Baseline g=9.04: v_FW = %.1f km/h\n', 117.6);
fprintf('   FW onset shift: %+.1f km/h from baseline\n', v_FW*3.6 - 117.6);

%% 6. Cycle configuration
C.StopTime = 765;
C.Distance = 16.53;
fprintf('6. StopTime=%d s, ref distance=%.2f km\n', C.StopTime, C.Distance);

%% 7. Model settings
fprintf('7. Configuring model...\n');
set_param(mdl, 'StopTime', num2str(C.StopTime));
set_param(mdl, 'ReturnWorkspaceOutputs', 'off');

%% 8. Road load
A_rl = P.veh.A_rl;
B_rl = P.veh.B_rl;
C_rl = P.veh.C_rl;
fprintf('8. Road load: F = %.1f + %.3f*v + %.4f*v^2\n', A_rl, B_rl, C_rl);

%% 9. BMS parameters
P_aux_W   = 690;
V_oc      = 370;
R_int_ohm = 0.070;
R_cable   = 0.015;

% BMS struct required by v26_BMS_postprocess.m (no ANL target for g=11.0,
% use g=9.04 baseline values as reference only — not a pass/fail gate)
BMS = struct();
BMS.is_reference  = true;    % no ANL target off stock gear; skip PASS/FAIL
BMS.gross_target  = 129.5;   % g=9.04 verified 17 Jul (reference)
BMS.regen_target  = 12.6;
BMS.net_target    = 116.9;   % g=9.04 verified 17 Jul (reference)
BMS.regen_pct     = 9.8;
BMS.gross_tol     = 0.20;    % wide tolerance — report only
BMS.regen_pct_tol = 10.0;
BMS.net_tol       = 0.20;
BMS.gross_lo = BMS.gross_target * (1 - BMS.gross_tol);
BMS.gross_hi = BMS.gross_target * (1 + BMS.gross_tol);
BMS.net_lo   = BMS.net_target * (1 - BMS.net_tol);
BMS.net_hi   = BMS.net_target * (1 + BMS.net_tol);
BMS.regen_lo = BMS.regen_pct - BMS.regen_pct_tol;
BMS.regen_hi = BMS.regen_pct + BMS.regen_pct_tol;

%% 10. Verify OnePedal_Regen S-Function block
fprintf('10. Checking OnePedal_Regen block...\n');
regen_blk = [mdl '/OnePedal_Regen'];
try
    get_param(regen_blk, 'Handle');
    sfcn_name = get_param(regen_blk, 'FunctionName');
    fprintf('   OnePedal_Regen: present (S-Function: %s)\n', sfcn_name);
catch
    error('OnePedal_Regen block not found. Run v26_restore_regen.m first.');
end

%% 11. Update driver block road load
try
    drv = [mdl '/Longitudinal_Driver/Longitudinal Driver'];
    aR_driver = round(P.veh.mass * P.env.g * P.veh.Crr);
    cR_driver = 0.5 * P.env.rho_air * P.veh.Cd * P.veh.A;
    set_param(drv, 'aR', num2str(aR_driver));
    set_param(drv, 'bR', '0');
    set_param(drv, 'cR', num2str(cR_driver));
    fprintf('11. Driver block road load updated.\n');
catch ME
    fprintf('11. Driver block not found: %s\n', ME.message);
end

%% 12. Save and run
% Simscape gear ratio literal fix (15 Jul 2026): another sweep script may
% have saved the model with ITS gear baked into the Simple Gear block as
% a literal. Set the literal to THIS run's gear before saving, and clear
% the compiled cache, so the compile cannot inherit a foreign ratio.
gear_blk = [mdl '/Vehicle_Dynamics/Simple Gear'];
set_param(gear_blk, 'ratio', sprintf('%.4f', gear_ratio));
fprintf('    Simple Gear ratio set to literal: %.4f\n', gear_ratio);
slprj_path = fullfile(fileparts(which(mdl)), 'slprj');
if exist(slprj_path, 'dir')
    rmdir(slprj_path, 's');
    fprintf('    Simscape cache (slprj/) cleared.\n');
end

save_system(mdl);
fprintf('\n12. Model saved.\n');

% Switch to Normal mode for gear sweep simulation.
% Simscape Accelerator caches compiled physical parameters by checksum.
% Changing gear_ratio in workspace does not trigger Simscape recompile.
% Normal mode evaluates all parameters from workspace at runtime.
set_param(mdl, 'SimulationMode', 'normal');
fprintf('    SimulationMode switched to Normal (gear sweep safety)\n');

fprintf('\n========================================================\n');
fprintf(' RUNNING HWFET at g=11.0 (765 s)\n');
fprintf(' Start time: %s\n', datestr(now));
fprintf(' Do not close MATLAB.\n');
fprintf('========================================================\n\n');

tic;
sim(mdl);
wall_time = toc;

% Restore Accelerator mode after gear sweep sim
set_param(mdl, 'SimulationMode', 'accelerator');

fprintf('\n========================================================\n');
fprintf(' SIMULATION COMPLETE\n');
fprintf(' Wall time: %.1f min (%.1f hours)\n', wall_time/60, wall_time/3600);
fprintf('========================================================\n\n');

%% 13. Construct P_batt, t_batt, v_spd
N = numel(Pbatt_ws);
dt = 0.1;
t_batt = (0:N-1)' * dt;
P_batt = Pbatt_ws(:);
v_spd  = interp1(dc_ts.Time, dc_ts.Data(:), t_batt, 'linear', 0);

fprintf('13. Post-sim data:\n');
fprintf('    P_batt: %d pts, t=[0, %.1f]s\n', N, t_batt(end));
fprintf('    v_spd max: %.2f m/s (%.1f km/h)\n', max(v_spd), max(v_spd)*3.6);

dist_km = sum(abs(v_spd(1:end-1))) * dt / 1000;
fprintf('    Distance: %.2f km (ref %.2f km, err %.1f%%)\n', ...
    dist_km, C.Distance, 100*abs(dist_km - C.Distance)/C.Distance);

E_motor_gross = sum(max(P_batt,0)) * dt / 3600;
E_motor_regen = abs(sum(min(P_batt,0)) * dt / 3600);
motor_gross_Whkm = E_motor_gross / dist_km;
motor_regen_pct  = 100 * E_motor_regen / E_motor_gross;
motor_net_Whkm   = (E_motor_gross - E_motor_regen) / dist_km;

fprintf('    Motor gross: %.1f Wh/km\n', motor_gross_Whkm);
fprintf('    Motor regen: %.1f%%\n', motor_regen_pct);
fprintf('    Motor net:   %.1f Wh/km\n', motor_net_Whkm);

% FW analysis
v_FW_mps = omega_base * rw / gear_ratio;
t_above_FW = sum(v_spd > v_FW_mps) * dt;
d_above_FW = sum(v_spd(v_spd > v_FW_mps)) * dt / 1000;
fw_dist_pct = 100 * d_above_FW / dist_km;
fprintf('    Time above v_FW (%.1f km/h): %.0f s (%.1f%%)\n', ...
    v_FW_mps*3.6, t_above_FW, 100*t_above_FW/C.StopTime);
fprintf('    Distance in FW: %.2f km (%.1f%%)\n', d_above_FW, fw_dist_pct);

%% 13b. GEAR CONTAMINATION GUARDS (17 Jul 2026)
% Known HWFET signatures (E_bms_gross_Wh):
%   g=9.04 verified: 2138.014747529
%   g=11 PREDICTED:  2223.232382152 (the quarantined 10 Jul run, proven
%   by inference to be g=11 physics). If THIS verified g=11 run
%   reproduces it bit-exactly, the contamination story is confirmed to
%   machine precision and the value gains verified provenance.
E_ref_g904   = 2138.014747529;
E_pred_g11   = 2223.232382152;

%% 14. BMS postprocessing
fprintf('\n14. BMS postprocessing...\n');
run('v26_BMS_postprocess.m');

if abs(E_bms_gross_Wh - E_ref_g904) < 1e-6
    error('GEAR GUARD FAILED: bit-identical to the g=9.04 run. DO NOT use.');
end
if abs(E_bms_gross_Wh - E_pred_g11) < 1e-6
    fprintf('    PREDICTION CONFIRMED: bit-identical to the quarantined 10 Jul\n');
    fprintf('    run (2223.232382 Wh). That run was g=11; this value now has\n');
    fprintf('    verified provenance. Contamination story proven end to end.\n');
else
    fprintf('    NOTE: differs from the 10 Jul prediction by %.6f Wh.\n', ...
        E_bms_gross_Wh - E_pred_g11);
    fprintf('    Deterministic reruns should match exactly - investigate before logging.\n');
end

%% 15. Save results (gear ratio in filename for dashboard)
% NOTE: do not use v26_dir here - v26_BMS_postprocess.m overwrites it
% with its own folder (shared-workspace collision). Use proj_root.
results_dir = fullfile(proj_root, 'results', sprintf('tesla_g%.1f', gear_ratio));
if ~exist(results_dir, 'dir'), mkdir(results_dir); end
save_name = fullfile(results_dir, sprintf('BMS_%s_v26_g%.1f_%s.mat', ...
    cycle, gear_ratio, datestr(now, 'yyyymmdd_HHMMSS')));
save(save_name, 'P_batt', 'P_bms', 'I_bms', 't_batt', 'v_spd', ...
    'E_bms_gross_Wh', 'E_bms_regen_Wh', 'E_bms_net_Wh', ...
    'Wh_km_bms_gross', 'Wh_km_bms_net', 'bms_regen_pct', ...
    'E_motor_gross', 'E_motor_regen', 'motor_gross_Whkm', ...
    'motor_net_Whkm', 'motor_regen_pct', ...
    'dist_km', 'cycle', 'BMS', 'C', 'wall_time', ...
    'gear_ratio', 'gear_override', ...
    'v_FW_mps', 'fw_dist_pct', 't_above_FW', 'd_above_FW');
fprintf('\n15. Results saved: %s\n', save_name);

%% 16. Comparison with g=9.04 baseline
fprintf('\n========================================================\n');
fprintf(' HWFET g=11.0 vs g=9.04 COMPARISON\n');
fprintf('========================================================\n');
fprintf('  g=9.04 verified (17 Jul): BMS net 116.9 Wh/km, FW onset 117.6 km/h\n');
fprintf('  g=11.0 result:   BMS net %.1f Wh/km, FW onset %.1f km/h\n', ...
    Wh_km_bms_net, v_FW*3.6);
fprintf('  Delta: %+.1f Wh/km (operating-point effect; FW marginal at g=11)\n', ...
    Wh_km_bms_net - 116.9);
fprintf('  FW distance share: %.1f%%\n', fw_dist_pct);

fprintf('\n========================================================\n');
fprintf(' HWFET g=11.0 COMPLETE — %s\n', datestr(now));
fprintf(' BMS net: %.1f Wh/km | Regen: %.1f%% | FW dist: %.1f%%\n', ...
    Wh_km_bms_net, bms_regen_pct, fw_dist_pct);
fprintf('========================================================\n');
