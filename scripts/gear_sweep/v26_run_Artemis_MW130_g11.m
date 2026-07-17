%% v26_run_Artemis_MW130_g11.m — Artemis Motorway 130 at gear ratio 11.0
%
%  Last cell in the g=11.0 row of the simulation matrix.
%  Gear ratio override: 11.0 (baseline 9.04).
%
%  Prerequisites:
%    - Drive Cycle Source set to "Artemis Motorway 130" via GUI
%    - Model saved after GUI change
%
%  Usage:
%    cd('v26');
%    run('v26_run_Artemis_MW130_g11.m');
%
%  Author: F. Shah Khan, University of East London, July 2026
% -------------------------------------------------------------------------

clear; clc;
fprintf('\n========================================================\n');
fprintf(' v26 ARTEMIS MW130 — GEAR RATIO 11.0\n');
fprintf(' Started: %s\n', datestr(now));
fprintf('========================================================\n\n');

%% 1. Set gear ratio override BEFORE loading params
gear_override = 11.0;
fprintf('1. Gear ratio override: %.1f (baseline 9.04)\n', gear_override);

%% 2. Open model and load parameters
mdl   = 'AE_TeslaM3_LMDI';
cycle = 'ArtemisMW130';

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

%% 4. Verify Artemis MW130 cycle data
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

% Artemis MW130: max speed ~36.1 m/s (130 km/h), duration ~1068 s
if vmax_mask < 33 || vmax_mask > 40
    error('vmax=%.1f m/s. Expected ~36.1 for Artemis MW130. Set Artemis via GUI first.', vmax_mask);
end
if tmax_mask < 1000 || tmax_mask > 1150
    error('Duration %.0f s. Expected ~1068 for Artemis MW130. Set Artemis via GUI first.', tmax_mask);
end
fprintf('   Confirmed: Artemis Motorway 130 (vmax %.1f km/h, %.0f s)\n', vmax_mask*3.6, tmax_mask);

%% 5. FW onset speed at g=11.0
omega_base = 906;  % [rad/s] CRG-derived base speed
rw = 0.326;        % [m] wheel radius
v_FW = omega_base * rw / gear_ratio;
fprintf('5. FW onset at g=11.0: %.1f m/s = %.1f km/h\n', v_FW, v_FW*3.6);
fprintf('   Artemis vmax %.1f km/h > v_FW %.1f km/h => significant FW operation expected\n', ...
    vmax_mask*3.6, v_FW*3.6);

%% 6. Cycle configuration
C.StopTime = round(tmax_mask);
C.Distance = 28.83;  % [km] Artemis MW130 reference distance
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
% use g=9.04 Artemis values as reference only — not a pass/fail gate)
BMS = struct();
BMS.is_reference  = true;    % postprocess skips PASS/FAIL gates (15 Jul audit)
BMS.gross_target  = 189.9;   % g=9.04 Artemis measured 15 Jul (reference)
BMS.regen_target  = 30.2;
BMS.net_target    = 159.7;   % g=9.04 Artemis measured 15 Jul (reference)
BMS.regen_pct     = 15.9;
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

%% 12. Save and run — Simscape gear ratio fix
% Simscape caches compiled physical network by expression checksum.
% Writing a literal value (not variable name) changes the expression,
% forcing Simscape to recompile with the correct gear ratio.
gear_blk = [mdl '/Vehicle_Dynamics/Simple Gear'];
set_param(gear_blk, 'ratio', sprintf('%.4f', gear_ratio));
fprintf('12. Simple Gear ratio set to literal: %.4f\n', gear_ratio);

% Delete Simscape compiled cache to guarantee fresh compilation
slprj_path = fullfile(fileparts(which(mdl)), 'slprj');
if exist(slprj_path, 'dir')
    rmdir(slprj_path, 's');
    fprintf('    Simscape cache (slprj/) cleared.\n');
else
    fprintf('    No slprj/ cache found (clean build).\n');
end

% Save model with literal gear ratio baked in
save_system(mdl);
fprintf('    Model saved with literal gear ratio.\n');

% Normal mode as additional safety layer
set_param(mdl, 'SimulationMode', 'normal');
fprintf('    SimulationMode: Normal\n');

fprintf('\n========================================================\n');
fprintf(' RUNNING ARTEMIS MW130 at g=11.0 (%d s)\n', C.StopTime);
fprintf(' Start time: %s\n', datestr(now));
fprintf(' Do not close MATLAB.\n');
fprintf('========================================================\n\n');

tic;
sim(mdl);
wall_time = toc;

% Restore: gear ratio expression + Accelerator mode
set_param(gear_blk, 'ratio', 'gear_ratio');
set_param(mdl, 'SimulationMode', 'accelerator');
save_system(mdl);
fprintf('    Restored gear_ratio expression + Accelerator mode.\n');

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

%% 13b. GEAR CONTAMINATION GUARDS (15 Jul 2026 audit)
% Guard 1: at g=11.0 the FW onset is 96.7 km/h and Artemis MW130 peaks at
% 131.8 km/h, so FW time MUST be nonzero (expect > 51.3% distance share,
% the g=9.04 value, since the onset dropped from 117.6 to 96.7 km/h).
if t_above_FW <= 0
    error(['GEAR GUARD FAILED: zero FW time at g=11.0 on a cycle that ', ...
        'peaks at %.1f km/h (FW onset %.1f km/h). The gear override did ', ...
        'not reach the simulation. DO NOT use this result.'], ...
        max(v_spd)*3.6, v_FW_mps*3.6);
end
fprintf('    Gear guard 1 PASS: nonzero FW time as required at g=11.0.\n');

% Guard 2: bit-identity references (exact E_bms_gross_Wh from valid runs)
E_bms_gross_g904_ref = 5456.131410576;  % Artemis g=9.04, 15 Jul
E_bms_gross_g7_ref   = 5308.927105981;  % Artemis g=7.0, 14 Jul

%% 14. BMS postprocessing
fprintf('\n14. BMS postprocessing...\n');
run('v26_BMS_postprocess.m');

% Guard 2 check (needs E_bms_gross_Wh from postprocess)
if abs(E_bms_gross_Wh - E_bms_gross_g904_ref) < 1e-6
    error(['GEAR GUARD FAILED: E_bms_gross bit-identical to the g=9.04 ', ...
        'Artemis run (%.6f Wh). DO NOT use this result.'], E_bms_gross_Wh);
end
if abs(E_bms_gross_Wh - E_bms_gross_g7_ref) < 1e-6
    error(['GEAR GUARD FAILED: E_bms_gross bit-identical to the g=7.0 ', ...
        'Artemis run (%.6f Wh). DO NOT use this result.'], E_bms_gross_Wh);
end
fprintf('    Gear guard 2 PASS: energy differs from g=9.04 and g=7.0 runs.\n');

%% 15. Save results (gear ratio in filename for dashboard)
results_dir = fullfile(v26_dir, '..', '..', 'results', 'tesla_g11.0');
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

%% 16. Comparison across all three gear ratios
fprintf('\n========================================================\n');
fprintf(' ARTEMIS MW130 GEAR SWEEP COMPARISON\n');
fprintf('========================================================\n');
fprintf('  g=7.0  (14 Jul): BMS net 154.0 Wh/km, FW onset 151.9 km/h, FW  0.0%%\n');
fprintf('  g=9.04 (15 Jul): BMS net 159.7 Wh/km, FW onset 117.6 km/h, FW 51.3%%\n');
fprintf('  g=11.0 (this):   BMS net %.1f Wh/km, FW onset %.1f km/h, FW %.1f%%\n', ...
    Wh_km_bms_net, v_FW_mps*3.6, fw_dist_pct);
fprintf('  Delta g11 - g9.04: %+.1f Wh/km | Delta g11 - g7: %+.1f Wh/km\n', ...
    Wh_km_bms_net - 159.7, Wh_km_bms_net - 154.0);

fprintf('\n========================================================\n');
fprintf(' ARTEMIS MW130 g=11.0 COMPLETE — %s\n', datestr(now));
fprintf(' BMS net: %.1f Wh/km | Regen: %.1f%% | FW: %.1f%%\n', ...
    Wh_km_bms_net, bms_regen_pct, fw_dist_pct);
fprintf('========================================================\n');
