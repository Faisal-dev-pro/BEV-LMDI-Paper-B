%% v26_run_WLTP.m — Standalone WLTP simulation (Tier 1 standard)
%
%  Same architecture as US06 and HWFET runs: Drive Cycle Source connected
%  directly to Longitudinal_Driver, feedforward regen from drive cycle
%  data, BMS postprocessing and validation.
%
%  Prerequisites:
%    - Drive Cycle Source set to "WLTP Class 3" via GUI
%    - Model saved after GUI change
%
%  Usage:
%    cd('v26');
%    run('v26_run_WLTP.m');
%
%  Author: F. Shah Khan, University of East London, July 2026
% -------------------------------------------------------------------------

clear; clc;
fprintf('\n========================================================\n');
fprintf(' v26 STANDALONE WLTP SIMULATION\n');
fprintf(' Started: %s\n', datestr(now));
fprintf('========================================================\n\n');

%% 1. Open model and load parameters
mdl = 'AE_TeslaM3_LMDI';
cycle = 'WLTP';

% Path fix (16 Jul 2026): the old computation resolved scripts/model,
% which does not exist. Resolve the project root properly, put model/
% and validation/ on the path, and run with cwd = model/ so InitFcn,
% caches, and load_system all resolve to the canonical model.
v26_dir   = fileparts(mfilename('fullpath'));
proj_root = char(java.io.File(fullfile(v26_dir, '..', '..')).getCanonicalPath());
addpath(fullfile(proj_root, 'model'));
addpath(fullfile(proj_root, 'scripts', 'validation'));
cd(fullfile(proj_root, 'model'));

fprintf('1. Loading model and parameters...\n');
% Force a FRESH model load: a plain sim() on an already-loaded model can
% reuse the in-memory compiled Simscape network from a previous run at a
% DIFFERENT gear ratio, even in Normal mode (15 Jul 2026 incident: UDDS
% g=11 reused the Artemis g=9.04 compile and produced g=9.04 physics).
if bdIsLoaded(mdl), bdclose(mdl); end
load_system(mdl);
run('AE_TeslaM3_LMDI_Params.m');

%% 2. Verify Drive Cycle Source is connected to Longitudinal_Driver
fprintf('2. Verifying model wiring...\n');

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

%% 3. Verify WLTP cycle data
fprintf('3. Checking drive cycle data...\n');

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

% WLTP Class 3: max speed ~36.5 m/s (131.3 km/h), duration 1800 s
if vmax_mask < 30 || vmax_mask > 40
    error('vmax=%.1f m/s. Expected ~36.5 for WLTP Class 3. Set WLTP via GUI first.', vmax_mask);
end
if tmax_mask < 1700 || tmax_mask > 1900
    error('Duration %.0f s. Expected ~1800 for WLTP Class 3. Set WLTP via GUI first.', tmax_mask);
end
fprintf('   Confirmed: WLTP Class 3 (vmax %.1f km/h, %.0f s)\n', vmax_mask*3.6, tmax_mask);

%% 4. Cycle configuration
C.StopTime = 1800;
C.Distance = 23.27;
fprintf('4. StopTime=%d s, ref distance=%.2f km\n', C.StopTime, C.Distance);

%% 5. Model settings
fprintf('5. Configuring model...\n');
set_param(mdl, 'StopTime', num2str(C.StopTime));
set_param(mdl, 'ReturnWorkspaceOutputs', 'off');

%% 6. Road load
A_rl = P.veh.A_rl;
B_rl = P.veh.B_rl;
C_rl = P.veh.C_rl;
fprintf('6. Road load: F = %.1f + %.3f*v + %.4f*v^2\n', A_rl, B_rl, C_rl);

%% 7. BMS parameters
P_aux_W   = 690;
V_oc      = 370;
R_int_ohm = 0.070;
R_cable   = 0.015;

%% 8. BMS validation targets (WLTP)
% Motor-level targets from Validation_Targets.md (T6, T7):
%   T6: WLTP net Wh/km = 116.7 (accept 111-123)
%   T7: WLTP regen %   = ~20% (accept 15-30%)
BMS = struct();
BMS.gross_target  = 175.0;
BMS.regen_target  = 35.0;
BMS.net_target    = 132.0;
BMS.regen_pct     = 20.0;
BMS.gross_tol     = 0.10;
BMS.regen_pct_tol = 5.0;
BMS.net_tol       = 0.10;
BMS.gross_lo = BMS.gross_target * (1 - BMS.gross_tol);
BMS.gross_hi = BMS.gross_target * (1 + BMS.gross_tol);
BMS.net_lo   = BMS.net_target * (1 - BMS.net_tol);
BMS.net_hi   = BMS.net_target * (1 + BMS.net_tol);
BMS.regen_lo = BMS.regen_pct - BMS.regen_pct_tol;
BMS.regen_hi = BMS.regen_pct + BMS.regen_pct_tol;

fprintf('8. BMS targets:\n');
fprintf('   Gross: %.1f Wh/km (accept %.0f-%.0f)\n', BMS.gross_target, BMS.gross_lo, BMS.gross_hi);
fprintf('   Net:   %.1f Wh/km (accept %.0f-%.0f)\n', BMS.net_target, BMS.net_lo, BMS.net_hi);
fprintf('   Regen: %.1f%% (accept %.1f-%.1f%%)\n', BMS.regen_pct, BMS.regen_lo, BMS.regen_hi);

%% 9. Verify OnePedal_Regen S-Function block
fprintf('9. Checking OnePedal_Regen block...\n');
regen_blk = [mdl '/OnePedal_Regen'];
try
    get_param(regen_blk, 'Handle');
    sfcn_name = get_param(regen_blk, 'FunctionName');
    fprintf('   OnePedal_Regen: present (S-Function: %s)\n', sfcn_name);
catch
    error('OnePedal_Regen block not found. Run v26_restore_regen.m first.');
end

%% 10. Update driver block road load
try
    drv = [mdl '/Longitudinal_Driver/Longitudinal Driver'];
    aR_driver = round(P.veh.mass * P.env.g * P.veh.Crr);
    cR_driver = 0.5 * P.env.rho_air * P.veh.Cd * P.veh.A;
    set_param(drv, 'aR', num2str(aR_driver));
    set_param(drv, 'bR', '0');
    set_param(drv, 'cR', num2str(cR_driver));
    fprintf('10. Driver block road load updated.\n');
catch ME
    fprintf('10. Driver block not found: %s\n', ME.message);
end

%% 11. Save and run
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
fprintf('\n11. Model saved.\n');

fprintf('\n========================================================\n');
fprintf(' RUNNING WLTP SIMULATION (1800 s)\n');
fprintf(' Start time: %s\n', datestr(now));
fprintf(' Do not close MATLAB.\n');
fprintf('========================================================\n\n');

tic;
sim(mdl);
wall_time = toc;

fprintf('\n========================================================\n');
fprintf(' SIMULATION COMPLETE\n');
fprintf(' Wall time: %.1f min (%.1f hours)\n', wall_time/60, wall_time/3600);
fprintf('========================================================\n\n');

%% 12. Construct P_batt, t_batt, v_spd
N = numel(Pbatt_ws);
dt = 0.1;
t_batt = (0:N-1)' * dt;
P_batt = Pbatt_ws(:);
v_spd  = interp1(dc_ts.Time, dc_ts.Data(:), t_batt, 'linear', 0);

fprintf('12. Post-sim data:\n');
fprintf('    P_batt: %d pts, t=[0, %.1f]s\n', N, t_batt(end));
fprintf('    v_spd max: %.2f m/s (%.1f km/h)\n', max(v_spd), max(v_spd)*3.6);

dist_km = sum(abs(v_spd(1:end-1))) * dt / 1000;
fprintf('    Distance: %.2f km (ref %.2f km, err %.1f%%)\n', ...
    dist_km, C.Distance, 100*abs(dist_km - C.Distance)/C.Distance);

E_motor_gross = sum(max(P_batt,0)) * dt / 3600;
E_motor_regen = abs(sum(min(P_batt,0)) * dt / 3600);
fprintf('    Motor gross: %.1f Wh/km\n', E_motor_gross/dist_km);
fprintf('    Motor regen: %.1f%%\n', 100*E_motor_regen/E_motor_gross);
fprintf('    Motor net:   %.1f Wh/km (target ~116.7)\n', (E_motor_gross-E_motor_regen)/dist_km);

%% 13. BMS postprocessing
fprintf('\n13. BMS postprocessing...\n');
run('v26_BMS_postprocess.m');

%% 14. Motor-level validation (T6, T7)
fprintf('\n========================================================\n');
fprintf(' MOTOR-LEVEL VALIDATION (T6, T7)\n');
fprintf('========================================================\n');

motor_gross_Whkm = E_motor_gross / dist_km;
motor_regen_pct  = 100 * E_motor_regen / E_motor_gross;
motor_net_Whkm   = (E_motor_gross - E_motor_regen) / dist_km;

pass_T6 = motor_net_Whkm >= 111 && motor_net_Whkm <= 123;
pass_T7 = motor_regen_pct >= 15 && motor_regen_pct <= 30;

fprintf('  T6 Motor net:   %.1f Wh/km (accept 111-123) %s\n', ...
    motor_net_Whkm, tf2str(pass_T6));
fprintf('  T7 Motor regen: %.1f%% (accept 15-30%%) %s\n', ...
    motor_regen_pct, tf2str(pass_T7));

if pass_T6 && pass_T7
    fprintf('\n  *** ALL MOTOR-LEVEL TARGETS PASS ***\n');
else
    fprintf('\n  *** SOME TARGETS FAILED — review above ***\n');
end

%% 15. Save results
save_name = fullfile(v26_dir, sprintf('BMS_%s_v26_%s.mat', cycle, ...
    datestr(now, 'yyyymmdd_HHMMSS')));
save(save_name, 'P_batt', 'P_bms', 'I_bms', 't_batt', 'v_spd', ...
    'E_bms_gross_Wh', 'E_bms_regen_Wh', 'E_bms_net_Wh', ...
    'Wh_km_bms_gross', 'Wh_km_bms_net', 'bms_regen_pct', ...
    'E_motor_gross', 'E_motor_regen', 'motor_gross_Whkm', ...
    'motor_net_Whkm', 'motor_regen_pct', ...
    'dist_km', 'cycle', 'BMS', 'C', 'wall_time', ...
    'pass_T6', 'pass_T7');
fprintf('\n15. Results saved: %s\n', save_name);

fprintf('\n========================================================\n');
fprintf(' WLTP RUN COMPLETE — %s\n', datestr(now));
fprintf('========================================================\n');

%% LOCAL
function s = tf2str(tf)
    if tf, s = 'PASS'; else, s = 'FAIL'; end
end
