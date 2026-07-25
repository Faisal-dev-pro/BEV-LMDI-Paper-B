%% BoltEV_Simscape_AllCycles.m — Run AE_BoltEV_LMDI.slx on all 4 cycles
%  Validates against ANL 2020 Hioki BMS targets (+-5% gate).
%
%  Drive Cycle Source block: autolibshared/Drive Cycle Source (built-in)
%  Key mask params: cycleVar, tfinal, outUnit (m/s)
%
%  Author: F. Shah Khan, UEL, July 2026
% =========================================================================

fprintf('\n================================================================\n');
fprintf(' Bolt EV: Simscape Model Validation — All Cycles\n');
fprintf(' Model: AE_BoltEV_LMDI.slx (efficiency-map motor)\n');
fprintf(' %s\n', datestr(now));
fprintf('================================================================\n');

%% 0. Setup
mdl = 'AE_BoltEV_LMDI';
dcs = [mdl '/Drive Cycle Source'];

% Load model if not loaded
if ~bdIsLoaded(mdl)
    load_system(mdl);
end

% Run params (also loads via InitFcn, but ensure workspace is ready)
if ~exist('P', 'var')
    run(fullfile(fileparts(mfilename('fullpath')), 'AE_BoltEV_LMDI_Params.m'));
end

gear_ratio = 7.05;

%% 1. Define cycles
%  cycleVar names match Powertrain Blockset built-in cycles.
%  UDDS = FTP75 in the block (EPA FTP urban driving schedule).
cycles = struct();

cycles(1).name     = 'UDDS';
cycles(1).cycleVar = 'UDDS';
cycles(1).tfinal   = '1369';
cycles(1).target   = 101.9;  % warm UDDS Hioki WP1, corrected 24 Jul 2026
                              %   WP1 = 101.88; consistent with HWFET/US06 (also WP1)
                              %   Old 99.6 was Hioki P1 (wrong channel, inconsistent)

cycles(2).name     = 'HWFET';
cycles(2).cycleVar = 'HWFET';
cycles(2).tfinal   = '765';
cycles(2).target   = 125.2;

cycles(3).name     = 'US06';
cycles(3).cycleVar = 'US06';
cycles(3).tfinal   = '600';
cycles(3).target   = 167.8;

cycles(4).name     = 'WLTP';
cycles(4).cycleVar = 'WLTP Class 3';
cycles(4).tfinal   = '1800';
cycles(4).target   = 136.3;

n_cycles = numel(cycles);

%% 2. Run each cycle
results = struct();

for ci = 1:n_cycles
    cyc = cycles(ci);
    fprintf('\n--- %s (target %.1f Wh/km) ---\n', cyc.name, cyc.target);

    % Set Drive Cycle Source
    set_param(dcs, 'cycleVar', cyc.cycleVar);
    set_param(dcs, 'tfinal', [cyc.tfinal '  seconds']);

    % Set model StopTime
    set_param(mdl, 'StopTime', cyc.tfinal);

    % Save before run
    save_system(mdl);
    fprintf('  Cycle set: %s, StopTime=%s s\n', cyc.cycleVar, cyc.tfinal);

    % Run simulation
    fprintf('  Running simulation...\n');
    tic;
    simOut = sim(mdl);
    t_sim = toc;
    fprintf('  Simulation complete: %.1f s wall time\n', t_sim);

    % Extract signals then free RAM (Tesla pattern: never hold full simOut)
    dt = 0.1;
    tf_num = str2double(cyc.tfinal);
    t_uniform = (0:dt:tf_num)';
    N_target = numel(t_uniform);

    raw_P = simOut.Pbatt_ws;
    if isa(raw_P, 'timeseries')
        P_batt = interp1(raw_P.Time(:), raw_P.Data(:), t_uniform, 'linear', 0);
    elseif numel(raw_P) == N_target
        P_batt = raw_P(:);
    else
        P_batt = interp1(linspace(0,tf_num,numel(raw_P))', raw_P(:), t_uniform, 'linear', 0);
    end

    raw_v = simOut.vehSpd_ws;
    if isa(raw_v, 'timeseries') && numel(raw_v.Data) >= 100
        v_spd = interp1(raw_v.Time(:), raw_v.Data(:), t_uniform, 'linear', 0);
    elseif numel(raw_v) == N_target
        v_spd = raw_v(:);
    else
        fprintf('  WARNING: vehSpd_ws has only %d pts — loading cycle schedule\n', numel(raw_v));
        repo_root = fullfile(fileparts(mfilename('fullpath')), '..', '..');
        switch upper(cyc.name)
            case 'UDDS'
                cyc_data = load(fullfile(repo_root, 'data', 'drive_cycles', 'UDDS_schedule.mat'));
                v_spd = interp1(double(cyc_data.t_udds(:)), cyc_data.v_udds_ms(:), t_uniform, 'linear', 0);
            case 'HWFET'
                cyc_data = load(fullfile(repo_root, 'chevrolet', 'data', 'HWFET_cycle.mat'));
                v_spd = interp1(double(cyc_data.t_1hz(:)), cyc_data.v_1hz(:), t_uniform, 'linear', 0);
            case 'US06'
                cyc_data = load(fullfile(repo_root, 'chevrolet', 'data', 'US06_cycle.mat'));
                v_spd = interp1(double(cyc_data.t_us06(:)), cyc_data.v_us06_ms(:), t_uniform, 'linear', 0);
            case 'WLTP'
                cyc_data = load(fullfile(repo_root, 'data', 'drive_cycles', 'WLTP_Class3b_schedule.mat'));
                v_spd = interp1(cyc_data.t_wltp(:), cyc_data.v_wltp_kmh(:)/3.6, t_uniform, 'linear', 0);
        end
    end
    t_batt = t_uniform;
    clear simOut;  % free RAM immediately (Tesla pattern)

    N = numel(P_batt);
    fprintf('  Extracted: %d pts (%.1f Hz), max v=%.1f km/h\n', ...
        N, 1/dt, max(v_spd)*3.6);
    fprintf('  Pbatt: max=%.0f W, min=%.0f W\n', max(P_batt), min(P_batt));

    % Distance
    dist_km = sum(abs(v_spd(1:end-1))) * dt / 1000;
    fprintf('  Distance: %.2f km\n', dist_km);

    % BMS post-processing (inline, same logic as BoltEV_BMS_postprocess.m)
    P_motor = P_batt(:);
    P_motor_trac  = max(P_motor, 0);
    P_motor_regen = min(P_motor, 0);

    E_motor_gross_Wh = sum(P_motor_trac(1:end-1)) * dt / 3600;
    E_motor_regen_Wh = abs(sum(P_motor_regen(1:end-1)) * dt / 3600);

    % Add auxiliary load (P_aux_W from AE_BoltEV_LMDI_Params.m)
    P_aux = P_aux_W * ones(N, 1);
    P_bms = P_motor + P_aux;

    % Cable I2R (R_cable = 0 for Bolt)
    I_bms = P_bms / V_oc;
    P_cable = I_bms.^2 * R_cable;
    P_bms = P_bms + P_cable .* sign(P_bms);

    % BMS metrics
    P_bms_trac  = max(P_bms, 0);
    P_bms_regen = min(P_bms, 0);

    E_bms_gross_Wh = sum(P_bms_trac(1:end-1)) * dt / 3600;
    E_bms_regen_Wh = abs(sum(P_bms_regen(1:end-1)) * dt / 3600);
    E_bms_net_Wh   = E_bms_gross_Wh - E_bms_regen_Wh;

    Wh_km_net   = E_bms_net_Wh / dist_km;
    Wh_km_gross = E_bms_gross_Wh / dist_km;
    regen_pct   = 100 * E_bms_regen_Wh / E_bms_gross_Wh;

    % Validation gate
    err_pct = (Wh_km_net - cyc.target) / cyc.target * 100;
    if abs(err_pct) <= 5
        gate = 'PASS';
    else
        gate = 'FAIL';
    end

    fprintf('  BMS gross: %.1f Wh/km\n', Wh_km_gross);
    fprintf('  BMS regen: %.1f%% \n', regen_pct);
    fprintf('  BMS net:   %.1f Wh/km  (target %.1f, err %+.1f%%)\n', ...
        Wh_km_net, cyc.target, err_pct);
    fprintf('  Gate: %s\n', gate);

    % Store results
    results(ci).name       = cyc.name;
    results(ci).dist_km    = dist_km;
    results(ci).Wh_km_gross = Wh_km_gross;
    results(ci).Wh_km_net  = Wh_km_net;
    results(ci).regen_pct  = regen_pct;
    results(ci).target     = cyc.target;
    results(ci).err_pct    = err_pct;
    results(ci).gate       = gate;
    results(ci).t_sim      = t_sim;

    % Save per-cycle trace file for LMDI (motor-level, no aux)
    % Convention: P_batt = motor electrical power (Pbatt_ws from Simulink)
    % P > 0 = traction (battery discharge), P < 0 = regen
    % Matches Tesla BMS trace files used by AE_run_LMDI_matrix.m
    trace_dir = fullfile(fileparts(mfilename('fullpath')), '..', 'results');
    if ~exist(trace_dir, 'dir'), mkdir(trace_dir); end
    cycle = cyc.name;
    trace_file = fullfile(trace_dir, sprintf('BoltEV_Simscape_%s.mat', cycle));
    save(trace_file, 'P_batt', 'v_spd', 't_batt', ...
        'gear_ratio', 'cycle', 'dist_km', ...
        'Wh_km_net', 'Wh_km_gross', 'regen_pct');
    fprintf('  Trace saved: %s\n', trace_file);
end

%% 3. Summary
fprintf('\n================================================================\n');
fprintf(' SUMMARY: Bolt EV Simscape Validation\n');
fprintf('================================================================\n');
fprintf('%-6s  %7s  %7s  %7s  %6s  %6s  %5s  %6s\n', ...
    'Cycle', 'Dist', 'Gross', 'Net', 'Regen', 'Target', 'Err', 'Gate');
fprintf('%-6s  %7s  %7s  %7s  %6s  %6s  %5s  %6s\n', ...
    '', 'km', 'Wh/km', 'Wh/km', '%', 'Wh/km', '%', '');
fprintf('------  -------  -------  -------  ------  ------  -----  ------\n');
for ci = 1:n_cycles
    r = results(ci);
    fprintf('%-6s  %7.2f  %7.1f  %7.1f  %5.1f%%  %6.1f  %+5.1f  %s\n', ...
        r.name, r.dist_km, r.Wh_km_gross, r.Wh_km_net, ...
        r.regen_pct, r.target, r.err_pct, r.gate);
end
fprintf('------  -------  -------  -------  ------  ------  -----  ------\n');

n_pass = sum(strcmp({results.gate}, 'PASS'));
fprintf('\n  %d / %d cycles PASS the +/-5%% gate.\n', n_pass, n_cycles);
fprintf('\n================================================================\n');
fprintf(' Validation complete: %s\n', datestr(now));
fprintf('================================================================\n');
