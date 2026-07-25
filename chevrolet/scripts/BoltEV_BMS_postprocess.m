%% BoltEV_BMS_postprocess.m — Convert motor electrical power to BMS-level metrics
%
%  Run this AFTER the simulation completes. It takes the motor electrical
%  power signal (Pbatt_ws from Simulink) and adds:
%    1. Auxiliary load (constant 300 W for Bolt EV)
%    2. Cable/contactor I^2*R losses (R_cable = 0 Ohm for Bolt)
%
%  The result is BMS-level gross, regen, and net Wh/km, validated against
%  ANL 2020 Hioki BMS cumulative counters.
%
%  Parameters P_aux_W, V_oc, R_cable are set in
%  AE_BoltEV_LMDI_Params.m and must be in the workspace.
%
%  Requires: P_batt, t_batt, v_spd from simulation output (or loaded .mat)
%
%  Author: F. Shah Khan, University of East London, July 2026
% -------------------------------------------------------------------------

fprintf('\n========================================\n');
fprintf(' v26 BMS POST-PROCESSING\n');
fprintf('========================================\n\n');

%% 1. Check inputs
assert(exist('P_batt', 'var') == 1, 'P_batt not in workspace. Run simulation first.');
assert(exist('t_batt', 'var') == 1, 't_batt not in workspace.');
assert(exist('v_spd', 'var') == 1, 'v_spd not in workspace.');

if ~exist('cycle', 'var') || isempty(cycle)
    cycle = 'Unknown';
    fprintf('WARNING: cycle name not set. Defaulting to ''%s''.\n\n', cycle);
end

dt = 0.1;  % 10 Hz sample rate
N = numel(P_batt);

%% 2. Motor-level metrics (from Simulink output)
P_motor = P_batt(:);  % Motor electrical power [W]
% Sign convention: P > 0 = traction (battery discharging), P < 0 = regen

P_motor_trac  = max(P_motor, 0);
P_motor_regen = min(P_motor, 0);

E_motor_gross_Wh = sum(P_motor_trac(1:end-1)) * dt / 3600;
E_motor_regen_Wh = abs(sum(P_motor_regen(1:end-1)) * dt / 3600);
E_motor_net_Wh   = E_motor_gross_Wh - E_motor_regen_Wh;

dist_km = sum(abs(v_spd(1:end-1))) * dt / 1000;

fprintf('Motor-level (Simulink output):\n');
fprintf('  Gross: %.1f Wh/km\n', E_motor_gross_Wh / dist_km);
fprintf('  Regen: %.1f Wh/km (%.1f%%)\n', ...
    E_motor_regen_Wh / dist_km, 100 * E_motor_regen_Wh / E_motor_gross_Wh);
fprintf('  Net:   %.1f Wh/km\n\n', E_motor_net_Wh / dist_km);

%% 3. Add auxiliary load
% P_aux is always drawn from the battery (positive = discharge)
% Bolt EV auxiliary load: 300 W
% P_aux_W set in AE_BoltEV_LMDI_Params.m
P_aux = P_aux_W * ones(N, 1);

%% 4. BMS-level power
% The BMS cumulative counters measure V_terminal * I at the battery
% terminals. Between battery terminals and inverter DC bus, there are
% cable/contactor losses and the auxiliary draw.
%
% Model:
%   P_bms = P_motor + P_aux + P_cable_I2R
%
% The auxiliary load draws from the DC bus continuously, reducing regen
% credit during charge and adding to discharge during traction.

P_bms = P_motor + P_aux;

% Cable/contactor I^2*R: add as a function of current
% R_cable set in AE_BoltEV_LMDI_Params.m (0 Ohm for Bolt)
I_bms = P_bms / V_oc;
P_cable = I_bms.^2 * R_cable;  % always positive, always loss
P_bms = P_bms + P_cable .* sign(P_bms);
% During discharge: cable loss increases discharge
% During charge: cable loss decreases charge (less reaches battery)

% Current statistics
fprintf('Battery current stats:\n');
fprintf('  I_rms:  %.1f A\n', sqrt(mean(I_bms.^2)));
fprintf('  I_peak: %.1f A (discharge), %.1f A (charge)\n', ...
    max(I_bms), min(I_bms));
fprintf('  Cable I2R avg: %.1f W\n\n', mean(P_cable));

%% 6. BMS metrics
P_bms_trac  = max(P_bms, 0);
P_bms_regen = min(P_bms, 0);

E_bms_gross_Wh = sum(P_bms_trac(1:end-1)) * dt / 3600;
E_bms_regen_Wh = abs(sum(P_bms_regen(1:end-1)) * dt / 3600);
E_bms_net_Wh   = E_bms_gross_Wh - E_bms_regen_Wh;

Wh_km_bms_gross = E_bms_gross_Wh / dist_km;
Wh_km_bms_regen = E_bms_regen_Wh / dist_km;
Wh_km_bms_net   = E_bms_net_Wh / dist_km;
bms_regen_pct   = 100 * E_bms_regen_Wh / E_bms_gross_Wh;

% Reference-only mode: no ANL test exists for this cycle/gear combination,
% so BMS.*_target values are references (e.g. another gear ratio), NOT
% validation targets. Set BMS.is_reference = true in the run script.
is_ref = isfield(BMS, 'is_reference') && BMS.is_reference;

fprintf('BMS-level results:\n');
if is_ref
    fprintf('  Gross: %.1f Wh/km  (reference %.1f)\n', ...
        Wh_km_bms_gross, BMS.gross_target);
    fprintf('  Regen: %.1f Wh/km (%.1f%%)  (reference %.1f%%)\n', ...
        Wh_km_bms_regen, bms_regen_pct, BMS.regen_pct);
    fprintf('  Net:   %.1f Wh/km  (reference %.1f)\n', ...
        Wh_km_bms_net, BMS.net_target);
else
    fprintf('  Gross: %.1f Wh/km  (target %.1f, accept %.0f-%.0f)\n', ...
        Wh_km_bms_gross, BMS.gross_target, BMS.gross_lo, BMS.gross_hi);
    fprintf('  Regen: %.1f Wh/km (%.1f%%)\n', Wh_km_bms_regen, bms_regen_pct);
    fprintf('         (target %.1f%%, accept %.1f-%.1f%%)\n', ...
        BMS.regen_pct, BMS.regen_lo, BMS.regen_hi);
    fprintf('  Net:   %.1f Wh/km  (target %.1f, accept %.0f-%.0f)\n', ...
        Wh_km_bms_net, BMS.net_target, BMS.net_lo, BMS.net_hi);
end

%% 7. Pass/Fail
if is_ref
    fprintf('\nValidation gates: SKIPPED — reference values only.\n');
    fprintf('No ANL target exists for this configuration. Comparison\n');
    fprintf('numbers above are informational, NOT a validation claim.\n');
else
    pass_gross = Wh_km_bms_gross >= BMS.gross_lo && Wh_km_bms_gross <= BMS.gross_hi;
    pass_regen = bms_regen_pct >= BMS.regen_lo && bms_regen_pct <= BMS.regen_hi;
    pass_net   = Wh_km_bms_net >= BMS.net_lo && Wh_km_bms_net <= BMS.net_hi;

    fprintf('\nValidation gates:\n');
    fprintf('  V1 BMS gross: %s  (%.1f vs %.1f +/- 5%%)\n', ...
        tf2str(pass_gross), Wh_km_bms_gross, BMS.gross_target);
    fprintf('  V2 BMS regen%%: %s  (%.1f%% vs %.1f%% +/- 3pp)\n', ...
        tf2str(pass_regen), bms_regen_pct, BMS.regen_pct);
    fprintf('  V3 BMS net: %s  (%.1f vs %.1f +/- 5%%)\n', ...
        tf2str(pass_net), Wh_km_bms_net, BMS.net_target);

    if pass_gross && pass_regen && pass_net
        fprintf('\n*** ALL GATES PASS — BMS-LEVEL VALIDATION ACHIEVED ***\n');
    else
        fprintf('\n*** SOME GATES FAILED — see above ***\n');
    end
end

%% 8. Energy waterfall
fprintf('\nEnergy waterfall (Wh/km):\n');
fprintf('  Motor gross:     %.1f\n', E_motor_gross_Wh / dist_km);
fprintf('  + Auxiliary:     +%.1f\n', ...
    sum(P_aux(P_bms > 0)) * dt / 3600 / dist_km);
fprintf('  + Cable I2R:     +%.1f\n', ...
    sum(P_cable(P_bms > 0)) * dt / 3600 / dist_km);
fprintf('  = BMS gross:     %.1f\n', Wh_km_bms_gross);
fprintf('\n');
fprintf('  Motor regen:     %.1f\n', E_motor_regen_Wh / dist_km);
fprintf('  - Aux during regen: -%.1f\n', ...
    sum(P_aux(P_bms < 0)) * dt / 3600 / dist_km);
fprintf('  - Cable I2R regen:  -%.1f\n', ...
    sum(P_cable(P_bms < 0)) * dt / 3600 / dist_km);
fprintf('  = BMS regen:     %.1f\n', Wh_km_bms_regen);

%% 9. Save
% Gear ratio is embedded in BOTH the filename and the struct so a file
% can never masquerade as a different gear configuration (July 2026
% Artemis g=9.04 contamination incident).
if ~exist('gear_ratio', 'var') || isempty(gear_ratio)
    gear_ratio = NaN;
    fprintf('\nWARNING: gear_ratio not in workspace. Saved as NaN.\n');
end
v26_dir = fileparts(mfilename('fullpath'));
if isempty(v26_dir), v26_dir = pwd; end
save_name = fullfile(v26_dir, sprintf('BMS_%s_v26_g%.2f_%s.mat', cycle, ...
    gear_ratio, datestr(now, 'yyyymmdd_HHMMSS')));
save(save_name, 'P_batt', 'P_bms', 'I_bms', 't_batt', 'v_spd', ...
    'E_bms_gross_Wh', 'E_bms_regen_Wh', 'E_bms_net_Wh', ...
    'Wh_km_bms_gross', 'Wh_km_bms_net', 'bms_regen_pct', ...
    'dist_km', 'cycle', 'BMS', 'gear_ratio');
fprintf('\nBMS results saved: %s\n', save_name);

%% LOCAL
function s = tf2str(tf)
    if tf, s = 'PASS'; else, s = 'FAIL'; end
end
