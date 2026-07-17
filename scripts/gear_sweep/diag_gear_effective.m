%% diag_gear_effective.m — Measure the EFFECTIVE gear ratio inside the sim
%
%  Purpose: the 15 Jul UDDS g=11.0 rerun (Normal mode) was bit-identical
%  to the g=9.04 baseline, so the compiled physics ignored the workspace
%  gear_ratio. This diagnostic runs TWO short sims (60 s, UDDS start) at
%  gear_override = 9.04 and 11.0 and measures, from logged signals:
%
%      g_eff = omega_motor * r_w / v_vehicle
%
%  averaged over moving samples. If g_eff stays at 9.04 when the
%  workspace says 11.0, the gear is not reaching the compiled network,
%  and the print shows exactly that. Also compares the two P_batt traces
%  bit-wise (they must differ).
%
%  Prerequisite: Drive Cycle Source set to UDDS (already set if run
%  after v26_run_UDDS_g11.m).
%
%  Runtime: ~15 min per 60 s sim in Normal mode, ~30 min total.
%
%  Author: F. Shah Khan / audit diagnostic, 15 July 2026
% -------------------------------------------------------------------------

clear; clc;

mdl = 'AE_TeslaM3_LMDI';
script_dir = fileparts(mfilename('fullpath'));
proj_root  = fullfile(script_dir, '..', '..');
proj_root  = char(java.io.File(proj_root).getCanonicalPath());
addpath(fullfile(proj_root, 'model'));
addpath(fullfile(proj_root, 'scripts', 'validation'));
cd(fullfile(proj_root, 'model'));

fprintf('\n========================================================\n');
fprintf(' EFFECTIVE GEAR RATIO DIAGNOSTIC — %s\n', datestr(now));
fprintf('========================================================\n\n');

load_system(mdl);

%% 1. Verify UDDS is loaded (need moving samples within 60 s)
dcs = [mdl '/Drive Cycle Source'];
mws = get_param(dcs, 'MaskWSVariables');
idx = find(strcmp({mws.Name}, 'DriveCycle'));
dc_ts = mws(idx).Value;
fprintf('1. Cycle: vmax=%.1f m/s, T=%.0f s ', max(dc_ts.Data), dc_ts.Time(end));
if abs(dc_ts.Time(end) - 1369) < 50
    fprintf('(UDDS confirmed)\n');
else
    fprintf('\n   WARNING: not UDDS. Diagnostic still works on any cycle\n');
    fprintf('   with motion inside the first 60 s.\n');
end

%% 2. Enable signal logging on the motor speed sensor line
% From_w_sens carries the motor speed signal into the FOC controller.
fprintf('2. Enabling signal logging on From_w_sens output...\n');
wblk = [mdl '/From_w_sens'];
ph_w = get_param(wblk, 'PortHandles');
set_param(ph_w.Outport(1), 'DataLogging', 'on');
set_param(ph_w.Outport(1), 'DataLoggingNameMode', 'Custom');
set_param(ph_w.Outport(1), 'DataLoggingName', 'diag_w_motor');
set_param(mdl, 'SignalLogging', 'on', 'SignalLoggingName', 'logsout');

%% 3. Common settings
set_param(mdl, 'StopTime', '60');
set_param(mdl, 'SimulationMode', 'normal');
set_param(mdl, 'ReturnWorkspaceOutputs', 'off');
save_system(mdl);
fprintf('3. StopTime=60 s, Normal mode, model saved.\n\n');

% NOTE: AE_TeslaM3_LMDI_Params.m runs in this workspace and uses common
% variable names internally (it clobbered plain "k" and may clobber
% others). Everything the diagnostic needs across iterations lives in
% DIAG_* variables that the params script does not touch.
DIAG_rw    = 0.326;   % wheel radius [m]
DIAG_gears = [9.04, 11.0];
DIAG_res   = struct('g_set', {}, 'g_eff', {}, 'P_batt', {}, 'E_Wh', {});
DIAG_dc_t  = dc_ts.Time;
DIAG_dc_v  = dc_ts.Data(:);

%% 4. Run both configurations
for DIAG_i = 1:2
    gear_override = DIAG_gears(DIAG_i);             %#ok<NASGU>
    run('AE_TeslaM3_LMDI_Params.m');
    fprintf('4.%d Running 60 s at gear_override = %.2f ', DIAG_i, DIAG_gears(DIAG_i));
    fprintf('(workspace gear_ratio = %.2f)...\n', gear_ratio);

    tic;
    sim(mdl);
    fprintf('    Done in %.1f min.\n', toc/60);

    % Motor speed from logged signal
    DIAG_el  = logsout.getElement('diag_w_motor');
    DIAG_wm  = squeeze(DIAG_el.Values.Data);
    DIAG_tw  = DIAG_el.Values.Time;

    % Vehicle speed from the reference cycle at the same instants
    DIAG_v = interp1(DIAG_dc_t, DIAG_dc_v, DIAG_tw, 'linear', 0);

    % Effective ratio over samples with meaningful motion (v > 3 m/s)
    DIAG_mask = DIAG_v > 3;
    if nnz(DIAG_mask) < 10
        error('Fewer than 10 moving samples in 60 s. Extend StopTime.');
    end
    DIAG_geff = median(DIAG_wm(DIAG_mask) * DIAG_rw ./ DIAG_v(DIAG_mask));

    % P_batt for bit-comparison
    DIAG_P60 = Pbatt_ws(:);
    DIAG_E   = sum(max(DIAG_P60,0)) * 0.1 / 3600;

    DIAG_res(DIAG_i).g_set  = DIAG_gears(DIAG_i);
    DIAG_res(DIAG_i).g_eff  = DIAG_geff;
    DIAG_res(DIAG_i).P_batt = DIAG_P60;
    DIAG_res(DIAG_i).E_Wh   = DIAG_E;

    fprintf('    Workspace gear: %.2f | MEASURED g_eff (median): %.3f\n', ...
        DIAG_gears(DIAG_i), DIAG_geff);
    fprintf('    (If w_sens is electrical rad/s, expect g_eff = gear * p = gear * 3)\n');
    fprintf('    Gross energy in 60 s: %.4f Wh\n\n', DIAG_E);
end

%% 5. Verdict
fprintf('========================================================\n');
fprintf(' VERDICT\n');
fprintf('========================================================\n');
ratio_of_ratios = DIAG_res(2).g_eff / DIAG_res(1).g_eff;
fprintf('  g_eff at setting 9.04: %.4f\n', DIAG_res(1).g_eff);
fprintf('  g_eff at setting 11.0: %.4f\n', DIAG_res(2).g_eff);
fprintf('  Ratio: %.4f (expect 11.0/9.04 = 1.2168 if gear is applied)\n', ...
    ratio_of_ratios);

identical = isequal(DIAG_res(1).P_batt, DIAG_res(2).P_batt);
fprintf('  P_batt traces bit-identical: %s\n', string(identical));
fprintf('  Gross energy: %.4f vs %.4f Wh (delta %.6f)\n', ...
    DIAG_res(1).E_Wh, DIAG_res(2).E_Wh, DIAG_res(2).E_Wh - DIAG_res(1).E_Wh);

if identical || abs(ratio_of_ratios - 1) < 0.01
    fprintf('\n  *** GEAR NOT APPLIED: compiled network ignores workspace\n');
    fprintf('      gear_ratio. The Simscape simple_gear ratio is a\n');
    fprintf('      compiletime parameter — investigate cache/fast-restart\n');
    fprintf('      and where the compile picks up gear_ratio. ***\n');
elseif abs(ratio_of_ratios - 11.0/9.04) < 0.01
    fprintf('\n  *** GEAR APPLIED CORRECTLY in this session. The UDDS g=11\n');
    fprintf('      failure came from the earlier run pipeline, not the\n');
    fprintf('      model. Re-run UDDS g=11 from THIS session state. ***\n');
else
    fprintf('\n  *** PARTIAL / UNEXPECTED: g_eff ratio %.4f matches neither\n', ...
        ratio_of_ratios);
    fprintf('      1.0 nor 1.2168. Inspect signal units and wiring. ***\n');
end

%% 6. Cleanup: disable diagnostic logging, restore model
ph_w = get_param([mdl '/From_w_sens'], 'PortHandles');  % re-fetch, params script may clobber
set_param(ph_w.Outport(1), 'DataLogging', 'off');
set_param(mdl, 'StopTime', '1369');
save_system(mdl);
fprintf('\n6. Diagnostic logging disabled, model saved (StopTime restored).\n');
fprintf('========================================================\n');
