%% diag_battery_beta.m — Diagnose battery beta assertion warning
%
%  The Simscape Battery block at AE_TeslaM3_LMDI/Battery_Model/Battery
%  warns at t=0: "Voltage versus state-of-charge equation coefficient,
%  beta is not in an acceptable range. Setting to 0."
%
%  This script queries every relevant block parameter and computes beta
%  manually so we can identify what needs to change.
%
%  Usage:
%    cd('/Users/fsk/Documents/MATLAB/BEV_LMDI_Paper_B/model')
%    run('../scripts/diag_battery_beta.m')
%
%  Author: F. Shah Khan, University of East London, July 2026
% -------------------------------------------------------------------------

clear; clc;
fprintf('\n========================================================\n');
fprintf(' BATTERY BETA DIAGNOSTIC\n');
fprintf(' %s\n', datestr(now));
fprintf('========================================================\n\n');

%% 1. Open model and load params
mdl = 'AE_TeslaM3_LMDI';

script_dir = fileparts(mfilename('fullpath'));
proj_root  = fullfile(script_dir, '..');
proj_root  = char(java.io.File(proj_root).getCanonicalPath());

addpath(fullfile(proj_root, 'model'));
cd(fullfile(proj_root, 'model'));

fprintf('1. Loading model...\n');
load_system(mdl);
run('AE_TeslaM3_LMDI_Params.m');

%% 2. Locate the Battery block
batt_path = [mdl '/Battery_Model/Battery'];
fprintf('\n2. Battery block: %s\n', batt_path);

% Get block type
block_type = get_param(batt_path, 'BlockType');
mask_type  = get_param(batt_path, 'MaskType');
fprintf('   BlockType: %s\n', block_type);
fprintf('   MaskType:  %s\n', mask_type);

%% 3. Get ALL dialog parameters
fprintf('\n3. All dialog parameters:\n');
fprintf('   %-35s  %s\n', 'PARAMETER', 'VALUE');
fprintf('   %s\n', repmat('-', 1, 70));

dp = get_param(batt_path, 'DialogParameters');
if isstruct(dp)
    fnames = fieldnames(dp);
    for k = 1:numel(fnames)
        try
            val = get_param(batt_path, fnames{k});
            if ischar(val) || isstring(val)
                fprintf('   %-35s  %s\n', fnames{k}, char(val));
            elseif isnumeric(val)
                fprintf('   %-35s  %g\n', fnames{k}, val);
            end
        catch
            fprintf('   %-35s  [cannot read]\n', fnames{k});
        end
    end
else
    fprintf('   DialogParameters not a struct. Trying MaskWSVariables...\n');
end

%% 4. Get mask workspace variables
fprintf('\n4. Mask workspace variables:\n');
try
    mws = get_param(batt_path, 'MaskWSVariables');
    for k = 1:numel(mws)
        val = mws(k).Value;
        if isnumeric(val) && isscalar(val)
            fprintf('   %-25s = %g\n', mws(k).Name, val);
        elseif isnumeric(val)
            fprintf('   %-25s = [%s]\n', mws(k).Name, num2str(val(:)', '%.4g '));
        elseif ischar(val) || isstring(val)
            fprintf('   %-25s = %s\n', mws(k).Name, char(val));
        else
            fprintf('   %-25s = [%s]\n', mws(k).Name, class(val));
        end
    end
catch ME
    fprintf('   Cannot read MaskWSVariables: %s\n', ME.message);
end

%% 5. Check workspace variables used by the block
fprintf('\n5. Workspace battery variables:\n');
fprintf('   Vnom  = %g V\n', Vnom);
fprintf('   V1    = %g V\n', V1);
fprintf('   R_int = %g Ohm\n', R_int);
fprintf('   Cdc   = %g F\n', Cdc);

fprintf('\n   From P struct:\n');
fprintf('   P.batt.Vnom  = %g V\n', P.batt.Vnom);
fprintf('   P.batt.V1    = %g V\n', P.batt.V1);
fprintf('   P.batt.Ah    = %.1f Ah\n', P.batt.Ah);
fprintf('   P.batt.kWh   = %g kWh\n', P.batt.kWh);
fprintf('   P.batt.SOC0  = %g %%\n', P.batt.SOC0);
fprintf('   P.batt.Rint  = %g Ohm\n', P.batt.Rint);

%% 6. Per-cell values (96s configuration)
n_series = 96;
fprintf('\n6. Per-cell values (assuming %d cells in series):\n', n_series);
fprintf('   Vnom/cell  = %.4f V\n', Vnom / n_series);
fprintf('   V1/cell    = %.4f V\n', V1 / n_series);
fprintf('   Delta      = %.4f V/cell\n', (Vnom - V1) / n_series);

%% 7. Simscape Battery beta computation (documented formula)
%
%  For the Simscape Battery block (ee_battery), the discharge model is:
%
%    E = E0 - K*(Q/(Q-it))*it + A*exp(-B*it)
%
%  where:
%    E0  = constant voltage
%    K   = polarisation constant
%    Q   = max capacity (Ah)
%    it  = extracted charge (Ah)
%    A   = exponential zone amplitude (V)
%    B   = exponential zone time constant inverse (1/Ah) = BETA
%
%  Beta is computed from exponential zone capacity Q_exp:
%    B = 3/Q_exp
%
%  If Q_exp <= 0 or the voltage parameters produce an invalid discharge
%  curve, beta goes out of range.
%
fprintf('\n7. Beta computation (Simscape documented formula):\n');
fprintf('   The block computes beta = 3/Q_exp from discharge curve params.\n');
fprintf('   Need to identify which block parameter maps to Q_exp.\n');
fprintf('   Check Section 3 output above for parameter names.\n');

%% 8. Try to suppress the warning and run 1s test
fprintf('\n8. Running 1s test to capture the exact warning...\n');
set_param(mdl, 'StopTime', '1');
set_param(mdl, 'SimulationMode', 'normal');

% Capture warnings
lastwarn('');
[warnMsg, warnId] = lastwarn();

try
    warning('on', 'all');
    sim(mdl);
catch ME
    fprintf('   Simulation error: %s\n', ME.message);
end

[warnMsg, warnId] = lastwarn();
if ~isempty(warnMsg)
    fprintf('\n   Last warning message:\n');
    fprintf('   MSG: %s\n', warnMsg);
    fprintf('   ID:  %s\n', warnId);
else
    fprintf('   No warning captured (may have been assertion, not warning).\n');
end

fprintf('\n========================================================\n');
fprintf(' DIAGNOSTIC COMPLETE\n');
fprintf(' Copy ALL output above and paste to Claude.\n');
fprintf('========================================================\n');
