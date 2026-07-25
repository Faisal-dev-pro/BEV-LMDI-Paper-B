%% BoltEV_2020_motor_param_validate.m
%  Validate the analytical MTPA/FW current-reference tables
%  (BoltEV_CurrentRefs.mat: Rs=0.00659, Ld=253.7uH, Lq=389.1uH, psi_m=0.1017)
%  against REAL 2020 Chevrolet Bolt ANL dynamometer data.
%
%  Data source: chevrolet/2020 Chevrolet Bolt/Extended Datasets/
%               620090xx Test Data.txt  (46 files, ANL D3 dyno + Hioki + CAN)
%
%  Method: for each real (T_measured, rpm_measured) point, interpolate the
%  existing id_table/iq_table (built from the literal Ld/Lq/Rs/psi_m) to
%  get the PREDICTED total motor current Is_pred = sqrt(id^2+iq^2), and
%  compare against the REAL measured Motor_1_current_DMCM1__A.
%
%  This tells us whether the constant-Ld/Lq analytical motor parameters
%  already in the repo are trustworthy, or whether they need refitting
%  before being wired into a real dq-motor Simulink subsystem.
%
%  Author: F. Shah Khan, UEL, July 2026
% =========================================================================

fprintf('\n=== Bolt EV 2020 ANL data: motor current-reference validation ===\n');

proj_root = fileparts(fileparts(mfilename('fullpath')));   % .../chevrolet
data_dir  = fullfile(proj_root, '2020 Chevrolet Bolt', 'Extended Datasets');
files     = dir(fullfile(data_dir, '*Test Data.txt'));
fprintf('Found %d test files in %s\n', numel(files), data_dir);

%% Load existing current-reference tables (literal params)
CR = load(fullfile(proj_root, 'data', 'BoltEV_CurrentRefs.mat'));
fprintf('Loaded BoltEV_CurrentRefs.mat: Rs=%.5f Ld=%.6g Lq=%.6g psim=%.4f p=%d\n', ...
    CR.Rs, CR.Ld, CR.Lq, CR.psim, CR.p);

%% Columns of interest
cols = {'Motor_1_torque_DMCM1__Nm', 'Motor_1_speed_DMCM1__rpm', ...
        'Motor_1_current_DMCM1__A', 'Motor_1_HV_circuit_voltage_DMCM1__V', ...
        'HVBatt_Power_Hioki_P1__kW', 'Vehicle_spd_CAN__kph'};

T_all = []; rpm_all = []; I_all = []; V_all = []; P_all = []; vspd_all = []; tid_all = {};

for k = 1:numel(files)
    fpath = fullfile(files(k).folder, files(k).name);
    tid = extractBefore(files(k).name, ' Test Data.txt');
    try
        opts = detectImportOptions(fpath, 'FileType', 'text', 'Delimiter', '\t');
        avail = intersect(cols, opts.VariableNames, 'stable');
        opts.SelectedVariableNames = avail;
        Ttab = readtable(fpath, opts);
    catch ME
        fprintf('  SKIP %s (%s)\n', tid, ME.message);
        continue;
    end

    getcol = @(name) (ismember(name, Ttab.Properties.VariableNames) * 1) && true;
    if ~all(ismember(cols([1 2 3]), Ttab.Properties.VariableNames))
        fprintf('  SKIP %s (missing motor columns)\n', tid);
        continue;
    end

    n = height(Ttab);
    T_all    = [T_all;    Ttab.Motor_1_torque_DMCM1__Nm];
    rpm_all  = [rpm_all;  Ttab.Motor_1_speed_DMCM1__rpm];
    I_all    = [I_all;    Ttab.Motor_1_current_DMCM1__A];
    if ismember('Motor_1_HV_circuit_voltage_DMCM1__V', Ttab.Properties.VariableNames)
        V_all = [V_all; Ttab.Motor_1_HV_circuit_voltage_DMCM1__V];
    else
        V_all = [V_all; nan(n,1)];
    end
    if ismember('HVBatt_Power_Hioki_P1__kW', Ttab.Properties.VariableNames)
        P_all = [P_all; Ttab.HVBatt_Power_Hioki_P1__kW];
    else
        P_all = [P_all; nan(n,1)];
    end
    if ismember('Vehicle_spd_CAN__kph', Ttab.Properties.VariableNames)
        vspd_all = [vspd_all; Ttab.Vehicle_spd_CAN__kph];
    else
        vspd_all = [vspd_all; nan(n,1)];
    end
    tid_all = [tid_all; repmat({tid}, n, 1)];
    fprintf('  %s: %d rows\n', tid, n);
end

fprintf('\nTotal rows loaded: %d\n', numel(T_all));

%% Clean / filter
valid = ~isnan(T_all) & ~isnan(rpm_all) & ~isnan(I_all) & abs(rpm_all) < 12000 & abs(T_all) < 500;
T_f = T_all(valid); rpm_f = rpm_all(valid); I_f = I_all(valid); V_f = V_all(valid);

fprintf('Valid rows after filtering: %d\n', numel(T_f));

% Focus on meaningfully-loaded points (|T| > 20 Nm) for parameter ID
loaded = abs(T_f) > 20 & abs(rpm_f) > 50;
fprintf('Loaded points (|T|>20 Nm, |rpm|>50): %d\n', sum(loaded));

%% Interpolate predicted Is from existing id_table/iq_table
% id_table/iq_table are indexed (T_vec, rpm_vec) per BoltEV_generate_current_refs.m
id_interp = griddedInterpolant({CR.T_vec, CR.rpm_vec}, CR.id_table, 'linear', 'nearest');
iq_interp = griddedInterpolant({CR.T_vec, CR.rpm_vec}, CR.iq_table, 'linear', 'nearest');

Tq_query  = min(abs(T_f(loaded)), max(CR.T_vec));
rpm_query = min(abs(rpm_f(loaded)), max(CR.rpm_vec));

id_pred = id_interp(Tq_query, rpm_query);
iq_pred = iq_interp(Tq_query, rpm_query);
Is_pred = sqrt(id_pred.^2 + iq_pred.^2);
Is_meas = abs(I_f(loaded));

err = Is_pred - Is_meas;
rmse = sqrt(mean(err.^2, 'omitnan'));
bias = mean(err, 'omitnan');
mape = mean(abs(err) ./ max(Is_meas, 1), 'omitnan') * 100;

fprintf('\n=== Current-reference validation vs 2020 ANL data (|T|>20 Nm) ===\n');
fprintf('N points          : %d\n', sum(~isnan(err)));
fprintf('Mean |I_pred|     : %.1f A\n', mean(Is_pred, 'omitnan'));
fprintf('Mean |I_measured| : %.1f A\n', mean(Is_meas, 'omitnan'));
fprintf('RMSE              : %.1f A\n', rmse);
fprintf('Bias (pred-meas)  : %.1f A\n', bias);
fprintf('MAPE              : %.1f %%\n', mape);

% Percentile breakdown by torque band
edges = [20 60 100 150 200 300 500];
fprintf('\nBy torque band:\n');
fprintf('%10s %8s %10s %10s %8s\n', 'T range', 'N', 'I_meas', 'I_pred', 'err%%');
for b = 1:numel(edges)-1
    m = abs(Tq_query) >= edges(b) & abs(Tq_query) < edges(b+1);
    if sum(m) > 5
        im = mean(Is_meas(m), 'omitnan');
        ip = mean(Is_pred(m), 'omitnan');
        fprintf('%4d-%4d %8d %10.1f %10.1f %7.1f%%\n', edges(b), edges(b+1), sum(m), im, ip, 100*(ip-im)/max(im,1));
    end
end

%% Save results
out_dir = fullfile(proj_root, 'results');
if ~exist(out_dir, 'dir'); mkdir(out_dir); end
save(fullfile(out_dir, 'BoltEV_2020_param_validation.mat'), ...
    'T_f','rpm_f','I_f','V_f','Is_pred','Is_meas','Tq_query','rpm_query', ...
    'rmse','bias','mape','CR');

fprintf('\nSaved: results/BoltEV_2020_param_validation.mat\n');
fprintf('=== Done ===\n');
