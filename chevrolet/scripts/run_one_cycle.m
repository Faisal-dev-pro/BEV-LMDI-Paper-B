%% run_one_cycle.m — Run one Bolt EV Simscape cycle and save trace
%  Usage: set cycle_name before running, e.g.:
%    cycle_name = 'UDDS'; run('run_one_cycle.m')

mdl = 'AE_BoltEV_LMDI';
dcs = [mdl '/Drive Cycle Source'];

if ~exist('cycle_name','var'), cycle_name = 'UDDS'; end

switch upper(cycle_name)
    case 'UDDS',  cVar='UDDS';         tf='1369'; tgt=101.9;
    case 'HWFET', cVar='HWFET';        tf='765';  tgt=125.2;
    case 'US06',  cVar='US06';         tf='600';  tgt=167.8;
    case 'WLTP',  cVar='WLTP Class 3'; tf='1800'; tgt=136.3;
    otherwise, error('Unknown cycle: %s', cycle_name);
end

if ~bdIsLoaded(mdl), load_system(mdl); end
if ~exist('P','var'), run('AE_BoltEV_LMDI_Params.m'); end

set_param(dcs, 'cycleVar', cVar);
set_param(dcs, 'tfinal', [tf '  seconds']);
set_param(mdl, 'StopTime', tf);
save_system(mdl);
fprintf('\n=== %s (target %.1f Wh/km, StopTime=%s) ===\n', cycle_name, tgt, tf);

% Skip simulation if simOut already exists for this cycle
if exist('simOut','var') && exist('last_cycle_run','var') && strcmp(last_cycle_run, cycle_name)
    fprintf('  simOut already in workspace for %s — skipping sim\n', cycle_name);
else
    tic; simOut = sim(mdl); t_sim = toc;
    last_cycle_run = cycle_name;
    fprintf('Simulation complete: %.1f s wall time\n', t_sim);
end

% Extract P_batt — plain array at 10 Hz (13691 pts for 1369s)
dt = 0.1;
tf_num = str2double(tf);
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
fprintf('  P_batt: %d pts (class=%s, raw=%d)\n', numel(P_batt), class(raw_P), numel(raw_P));

% Extract v_spd — use vehSpd_ws if valid, else load drive cycle schedule
raw_v = simOut.vehSpd_ws;
if isa(raw_v, 'timeseries') && numel(raw_v.Data) >= 100
    v_spd = interp1(raw_v.Time(:), raw_v.Data(:), t_uniform, 'linear', 0);
    fprintf('  v_spd: %d pts from vehSpd_ws timeseries\n', numel(v_spd));
elseif numel(raw_v) == N_target
    v_spd = raw_v(:);
    fprintf('  v_spd: %d pts from vehSpd_ws array\n', numel(v_spd));
else
    % vehSpd_ws broken — load drive cycle reference speed
    fprintf('  WARNING: vehSpd_ws has only %d pts — loading cycle schedule\n', numel(raw_v));
    repo_root = fullfile(fileparts(mfilename('fullpath')), '..', '..');
    switch upper(cycle_name)
        case 'UDDS'
            cyc_data = load(fullfile(repo_root, 'data', 'drive_cycles', 'UDDS_schedule.mat'));
            t_cyc = double(cyc_data.t_udds(:));
            v_cyc = cyc_data.v_udds_ms(:);
        case 'HWFET'
            cyc_data = load(fullfile(repo_root, 'chevrolet', 'data', 'HWFET_cycle.mat'));
            t_cyc = double(cyc_data.t_1hz(:));
            v_cyc = cyc_data.v_1hz(:);
        case 'US06'
            cyc_data = load(fullfile(repo_root, 'chevrolet', 'data', 'US06_cycle.mat'));
            t_cyc = double(cyc_data.t_us06(:));
            v_cyc = cyc_data.v_us06_ms(:);
        case 'WLTP'
            cyc_data = load(fullfile(repo_root, 'data', 'drive_cycles', 'WLTP_Class3b_schedule.mat'));
            t_cyc = cyc_data.t_wltp(:);
            v_cyc = cyc_data.v_wltp_kmh(:) / 3.6;  % km/h to m/s
    end
    v_spd = interp1(t_cyc, v_cyc, t_uniform, 'linear', 0);
    fprintf('  v_spd: %d pts from cycle schedule file\n', numel(v_spd));
end
t_batt = t_uniform;
clear simOut;  % free RAM immediately (Tesla pattern)

N = numel(P_batt);
dist_km = sum(abs(v_spd(1:end-1))) * dt / 1000;

% BMS post-processing
P_motor = P_batt(:);
P_aux = P_aux_W * ones(N,1);
P_bms = P_motor + P_aux;
I_bms = P_bms / V_oc;
P_cable = I_bms.^2 * R_cable;
P_bms = P_bms + P_cable .* sign(P_bms);

P_bms_trac  = max(P_bms, 0);
P_bms_regen = min(P_bms, 0);
E_bms_gross = sum(P_bms_trac(1:end-1)) * dt / 3600;
E_bms_regen = abs(sum(P_bms_regen(1:end-1)) * dt / 3600);
E_bms_net   = E_bms_gross - E_bms_regen;
Wh_km_net   = E_bms_net / dist_km;
Wh_km_gross = E_bms_gross / dist_km;
regen_pct   = 100 * E_bms_regen / E_bms_gross;
err_pct     = (Wh_km_net - tgt) / tgt * 100;

fprintf('  Dist: %.2f km\n', dist_km);
fprintf('  BMS net: %.1f Wh/km (target %.1f, err %+.1f%%)\n', Wh_km_net, tgt, err_pct);
fprintf('  BMS gross: %.1f Wh/km, regen: %.1f%%\n', Wh_km_gross, regen_pct);
if abs(err_pct) <= 5, fprintf('  Gate: PASS\n'); else, fprintf('  Gate: FAIL\n'); end

% Save trace (motor-level, no aux)
gear_ratio = P.gear.ratio;
cycle = cycle_name;
trace_dir = fullfile(fileparts(mfilename('fullpath')), '..', 'results');
if ~exist(trace_dir,'dir'), mkdir(trace_dir); end
trace_file = fullfile(trace_dir, sprintf('BoltEV_Simscape_%s.mat', cycle));
save(trace_file, 'P_batt','v_spd','t_batt','gear_ratio','cycle','dist_km','Wh_km_net','Wh_km_gross','regen_pct');
fprintf('  Trace saved: %s\n', trace_file);
