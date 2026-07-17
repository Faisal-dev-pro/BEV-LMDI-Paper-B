%% v26_run_UDDS_g904.m — UDDS at gear ratio 9.04 (TRUE BASELINE RERUN)
%
%  RERUN of the UDDS g=9.04 baseline. The original 10 July 2026 run
%  (BMS_UDDS_v26_20260710_190022.mat, quarantined) actually executed at
%  g=11: a stale gear_override in the base workspace was picked up by
%  the exist() check in AE_TeslaM3_LMDI_Params.m. Proof (16 Jul): its
%  first-60 s gross energy is 74.7770 Wh, exactly the g=11 signature
%  measured by diag_gear_effective.m (g=9.04 gives 74.3681 Wh).
%
%  This run re-establishes the ANL validation point T12/T12a/T13:
%  UDDS is the only cycle whose baseline was invalidated. Real ANL
%  gates apply (NOT reference-only).
%
%  Expected: BMS net ~107-109 Wh/km (between g=7.0 105.3 and g=11 110.6),
%  0% FW (onset 117.6 km/h, UDDS max 91.25 km/h), regen ~33-36%.
%
%  Prerequisites:
%    - Drive Cycle Source set to "UDDS (1369 seconds)" via GUI
%    - Model saved after GUI change
%
%  Author: F. Shah Khan, University of East London, July 2026
% -------------------------------------------------------------------------

clear; clc;

fprintf('\n========================================================\n');
fprintf(' v26 UDDS — GEAR RATIO 9.04 (TRUE BASELINE RERUN)\n');
fprintf(' Started: %s\n', datestr(now));
fprintf('========================================================\n\n');

%% 1. Set gear ratio EXPLICITLY
gear_override = 9.04;
fprintf('1. Gear ratio override: %.2f (explicit baseline)\n', gear_override);

%% 2. Open model and load parameters
mdl   = 'AE_TeslaM3_LMDI';
cycle = 'UDDS';

script_dir = fileparts(mfilename('fullpath'));
proj_root  = fullfile(script_dir, '..', '..');
proj_root  = char(java.io.File(proj_root).getCanonicalPath());

addpath(fullfile(proj_root, 'model'));
addpath(fullfile(proj_root, 'scripts', 'validation'));
cd(fullfile(proj_root, 'model'));

fprintf('2. Loading model and parameters...\n');
if bdIsLoaded(mdl), bdclose(mdl); end
load_system(mdl);
run('AE_TeslaM3_LMDI_Params.m');

fprintf('   gear_ratio = %.2f (expect 9.04)\n', gear_ratio);
if abs(gear_ratio - 9.04) > 0.01
    error('gear_ratio is %.2f, expected 9.04. Check gear_override logic.', gear_ratio);
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

%% 4. Verify UDDS cycle data
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

if vmax_mask < 20 || vmax_mask > 30
    error('vmax=%.1f m/s. Expected ~25.35 for UDDS. Set cycle via GUI first.', vmax_mask);
end
if tmax_mask < 1300 || tmax_mask > 1400
    error('Duration %.0f s. Expected ~1369 for UDDS. Set cycle via GUI first.', tmax_mask);
end
fprintf('   Confirmed: UDDS (vmax %.1f km/h, %.0f s)\n', vmax_mask*3.6, tmax_mask);

%% 5. FW onset speed at g=9.04
omega_base = 906;  % [rad/s] CRG-derived base speed
rw = 0.326;        % [m] wheel radius
v_FW = omega_base * rw / gear_ratio;
fprintf('5. FW onset at g=9.04: %.1f m/s = %.1f km/h\n', v_FW, v_FW*3.6);
fprintf('   UDDS max %.1f km/h < onset -> expect 0%% FW.\n', vmax_mask*3.6);

%% 6. Cycle configuration
C.StopTime = 1369;
C.Distance = 11.99;
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

%% 9. BMS parameters and ANL validation gates (REAL gates, not reference)
P_aux_W   = 690;
V_oc      = 370;
R_int_ohm = 0.070;
R_cable   = 0.015;

% ANL D3 targets for UDDS at stock gear 9.04 (T12/T12a/T13):
BMS = struct();
BMS.gross_target  = 169.6;   % ANL BMS gross (T12a)
BMS.regen_target  = 60.6;    % gross - net
BMS.net_target    = 109.0;   % ANL BMS net (T12), +/- 3.0 measured spread
BMS.regen_pct     = 35.7;    % ANL regen fraction (T13)
BMS.gross_tol     = 0.05;
BMS.regen_pct_tol = 4.0;     % accept 31.7 - 39.7%
BMS.net_tol       = 0.05;
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

%% 12. Save and run — Simscape gear ratio literal fix
gear_blk = [mdl '/Vehicle_Dynamics/Simple Gear'];
set_param(gear_blk, 'ratio', sprintf('%.4f', gear_ratio));
fprintf('12. Simple Gear ratio set to literal: %.4f\n', gear_ratio);

slprj_path = fullfile(fileparts(which(mdl)), 'slprj');
if exist(slprj_path, 'dir')
    rmdir(slprj_path, 's');
    fprintf('    Simscape cache (slprj/) cleared.\n');
end

save_system(mdl);
fprintf('    Model saved.\n');

set_param(mdl, 'SimulationMode', 'normal');
fprintf('    SimulationMode: Normal\n');

fprintf('\n========================================================\n');
fprintf(' RUNNING UDDS at g=9.04 (1369 s)\n');
fprintf(' Start time: %s\n', datestr(now));
fprintf(' Do not close MATLAB.\n');
fprintf('========================================================\n\n');

tic;
sim(mdl);
wall_time = toc;

% Restore variable expression in the gear block, then Accelerator mode
set_param(gear_blk, 'ratio', 'gear_ratio');
set_param(mdl, 'SimulationMode', 'accelerator');
save_system(mdl);

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

%% 13b. GEAR CONTAMINATION GUARDS (16 Jul 2026, both signatures known)
% First-60s gross signature check (from diag_gear_effective.m):
%   true g=9.04 -> 74.3681 Wh | true g=11 -> 74.7770 Wh
E60 = sum(max(P_batt(1:601),0)) * dt / 3600;
fprintf('    First-60s gross: %.4f Wh (expect ~74.368 at g=9.04; 74.777 = g=11 signature)\n', E60);
if abs(E60 - 74.7770) < 0.01
    error(['GEAR GUARD FAILED: first-60s gross matches the g=11 ', ...
        'signature (74.777 Wh). DO NOT use this result.']);
end

E_bms_gross_g7_ref  = 1910.007241792;     % UDDS g=7.0
E_bms_gross_g11_ref = 1962.974889217331;  % UDDS g=11 (verified 16 Jul)

%% 14. BMS postprocessing
fprintf('\n14. BMS postprocessing...\n');
run('v26_BMS_postprocess.m');

if abs(E_bms_gross_Wh - E_bms_gross_g7_ref) < 1e-6
    error('GEAR GUARD FAILED: bit-identical to the g=7.0 run. DO NOT use.');
end
if abs(E_bms_gross_Wh - E_bms_gross_g11_ref) < 1e-6
    error('GEAR GUARD FAILED: bit-identical to the g=11 run. DO NOT use.');
end
fprintf('    Gear guards PASS: energy differs from g=7.0 and g=11 runs.\n');

%% 15. Save results
results_dir = fullfile(proj_root, 'results', 'tesla_g9.04');
if ~exist(results_dir, 'dir'), mkdir(results_dir); end
save_name = fullfile(results_dir, sprintf('BMS_%s_v26_g9.04_%s.mat', ...
    cycle, datestr(now, 'yyyymmdd_HHMMSS')));
save(save_name, 'P_batt', 'P_bms', 'I_bms', 't_batt', 'v_spd', ...
    'E_bms_gross_Wh', 'E_bms_regen_Wh', 'E_bms_net_Wh', ...
    'Wh_km_bms_gross', 'Wh_km_bms_net', 'bms_regen_pct', ...
    'E_motor_gross', 'E_motor_regen', 'motor_gross_Whkm', ...
    'motor_net_Whkm', 'motor_regen_pct', ...
    'dist_km', 'cycle', 'BMS', 'C', 'wall_time', ...
    'gear_ratio', 'gear_override', ...
    'v_FW_mps', 'fw_dist_pct', 't_above_FW', 'd_above_FW');
fprintf('\n15. Results saved: %s\n', save_name);

%% 16. Gear sweep comparison
fprintf('\n========================================================\n');
fprintf(' UDDS GEAR SWEEP COMPARISON\n');
fprintf('========================================================\n');
fprintf('  g=7.0  (13 Jul): BMS net 105.3 Wh/km\n');
fprintf('  g=9.04 (this):   BMS net %.1f Wh/km  <- ANL validation run\n', Wh_km_bms_net);
fprintf('  g=11.0 (16 Jul): BMS net 110.6 Wh/km\n');
fprintf('  Monotone g7 < g9.04 < g11 expected: %.1f < %.1f < 110.6\n', ...
    105.3, Wh_km_bms_net);

fprintf('\n========================================================\n');
fprintf(' UDDS g=9.04 COMPLETE — %s\n', datestr(now));
fprintf(' BMS net: %.1f Wh/km | Regen: %.1f%% | FW dist: %.1f%%\n', ...
    Wh_km_bms_net, bms_regen_pct, fw_dist_pct);
fprintf('========================================================\n');
