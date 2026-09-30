%% AE_run_LMDI.m — LMDI-I Decomposition (Paper B, Results in Engineering)
%
%  *** DEPRECATED 17 Jul 2026 — do not run. ***
%  Superseded by AE_run_LMDI_matrix.m, which loads the 15 gear-verified
%  matrix files (tag tesla-matrix-complete-v26) instead of re-running
%  simulations, covers all 3 gears x 5 cycles, handles zero regimes via
%  Ang eps-substitution, and bins regen by speed. This script also
%  depends on model/WLTP_signals.mat which no longer exists.
%
%  Cycles   : US06 (600s), HWFET (765s), WLTP Class 3 (1800s)
%  WLTP     : loaded from saved mat — NO re-run needed
%  US06/HWFET: lean re-run, signals saved to mat immediately
%
%  Regime boundaries — CRG-derived, torque-dependent FW onset at V_dc=370V:
%    The FW onset speed varies with motor torque. At low torque the MTPA
%    zone extends to higher speed; at peak torque (430 Nm) FW onset is
%    lowest. The boundary is loaded from FW_onset_curve.mat, extracted
%    from IPMSM_CurrentRef_LUT.mat at V_dc=370V (ANL CAN average OCV)
%    with a 10A Id-departure threshold.
%
%    omega_base (CRG, zero-torque limit) = 906 rad/s mech = 117.6 km/h
%    V_dc = 370 V (average operating voltage, not 400V fully charged)
%    Regime 1 MTPA  : RPM < fw_onset(T_motor)
%    Regime 2 Trans : within 5% buffer band of fw_onset
%    Regime 3 FW    : RPM >= fw_onset(T_motor) + 5% buffer
%
%  Author: F. Shah Khan, University of East London, June 2026
% -------------------------------------------------------------------------

clear; clc;
script_dir = fileparts(mfilename('fullpath'));
proj_root  = fullfile(script_dir, '..', '..');
proj_root  = char(java.io.File(proj_root).getCanonicalPath());
model_dir  = fullfile(proj_root, 'model');
addpath(model_dir);
cd(model_dir);

%% Parameters
wheel_r    = 0.326;
gear_ratio = 9.04;
eta_drive  = 0.90;     % drivetrain efficiency estimate for torque reconstruction
rlbl       = {'MTPA','Trans','FW'};

%% Load CRG-based FW onset curve
%   FW_onset_curve.mat contains fw_tq_Nm and fw_rpm_mech extracted from
%   IPMSM_CurrentRef_LUT.mat at Vdc=370V with 10A Id-departure threshold.
%   This gives the actual speed at which the CRG transitions from MTPA to FW
%   as a function of motor torque — the physically correct regime boundary.
fw_file = fullfile(model_dir, 'FW_onset_curve.mat');
assert(exist(fw_file,'file')==2, 'FW_onset_curve.mat not found — run Python extraction first');
FW = load(fw_file);
% Monotone: FW onset RPM decreases as torque increases (voltage limit tighter)
% Extrapolate: below min torque → max RPM (17000); above max torque → min RPM
fw_tq  = FW.fw_tq_Nm(:);
fw_rpm = FW.fw_rpm_mech(:);

fprintf('CRG FW onset curve loaded: %d breakpoints, Vdc=%.0fV\n', ...
    numel(fw_tq), FW.Vdc_V);
fprintf('  Low torque  (22 Nm)  → FW onset %.0f km/h\n', ...
    interp1(fw_tq,fw_rpm,22,'linear','extrap')/60*2*pi*wheel_r/gear_ratio*3.6);
fprintf('  Mid torque  (110 Nm) → FW onset %.0f km/h\n', ...
    interp1(fw_tq,fw_rpm,110,'linear','extrap')/60*2*pi*wheel_r/gear_ratio*3.6);
fprintf('  Peak torque (430 Nm) → FW onset %.0f km/h\n\n', ...
    interp1(fw_tq,fw_rpm,430,'linear','extrap')/60*2*pi*wheel_r/gear_ratio*3.6);

fprintf('Regime assignment: CRG instantaneous (torque-dependent FW onset)\n');
fprintf('  MTPA: operating RPM < fw_onset(T_est)  — CRG in MTPA current locus\n');
fprintf('  FW:   operating RPM >= fw_onset(T_est) — CRG driving negative Id\n');
fprintf('  Trans: 5%% buffer band around onset boundary\n\n');

%% -----------------------------------------------------------------------
%  Pre-run verification — 10 s sanity check on model outputs
%% -----------------------------------------------------------------------
fprintf('============================================================\n');
fprintf(' Pre-run check  10 s\n');
fprintf('============================================================\n');
mdl = 'AE_TeslaM3_LMDI';
if ~bdIsLoaded(mdl), open_system(mdl); end
AE_TeslaM3_LMDI_Params;
set_param(mdl,'SimscapeLogType','none','SaveOutput','off', ...
              'SaveState','off','MaxStep','0.1');
set_param([mdl '/Drive Cycle Source'], 'cycleVar', 'US06');
set_param(mdl, 'StopTime', '10');
save_system(mdl);
simOut_smk = sim(mdl);

Pb_smk = simOut_smk.get('Pbatt_ws');
vS_smk = simOut_smk.get('vehSpd_v22');
clear simOut_smk;

assert(~isempty(Pb_smk), 'FAIL: Pbatt_ws empty');
assert(~isempty(vS_smk), 'FAIL: vehSpd_v22 empty');

if isa(vS_smk,'timeseries'); v_smk = vS_smk.Data(:);
else; v_smk = vS_smk(:); end
rpm_smk = abs(v_smk) * gear_ratio / wheel_r * 60/(2*pi);

fprintf('  Pbatt_ws : %d pts  [%s]\n', numel(Pb_smk), class(Pb_smk));
fprintf('  vehSpd   : %d pts  [%s]\n', numel(v_smk), class(vS_smk));
fprintf('  Peak RPM (10s): %.0f RPM mech\n', max(rpm_smk));
fw_check = interp1(fw_tq, fw_rpm, 30, 'linear', 'extrap');  % FW onset at 30 Nm
fprintf('  CRG check: FW onset @ 30 Nm = %.0f RPM (%.1f km/h)\n', ...
    fw_check, fw_check/60*2*pi*wheel_r/gear_ratio*3.6);
clear Pb_smk vS_smk v_smk rpm_smk fw_check;

% Check WLTP mat file loads
wltp_file = fullfile(model_dir, 'WLTP_signals.mat');
assert(exist(wltp_file,'file')==2, 'FAIL: WLTP mat file not found: %s', wltp_file);
W_smk = load(wltp_file, 'Pbatt_ws', 't');
assert(numel(W_smk.Pbatt_ws) == 19001, ...
    'FAIL: WLTP Pbatt_ws has %d pts (expected 19001)', numel(W_smk.Pbatt_ws));
clear W_smk;
fprintf('  WLTP mat  : OK (19001 pts)\n');
fprintf('\n  === Pre-run check passed — starting LMDI run ===\n\n');

%% -----------------------------------------------------------------------
%  [1/3] US06 — lean run (~20 min)
%% -----------------------------------------------------------------------
fprintf('============================================================\n');
fprintf(' [1/3] US06  600 s\n');
fprintf('============================================================\n');

[Pb, vS, t] = run_lean(mdl, 'US06', 650);
% Save raw signals — so LMDI can be reprocessed without re-running sim
us06_mat = fullfile(model_dir, 'US06_signals.mat');
Pb_us06 = Pb; vS_us06 = vS; t_us06 = t;
save(us06_mat, 'Pb_us06', 'vS_us06', 't_us06');
fprintf('  Signals saved: %s\n', us06_mat);
mask = t <= 600;
US06 = lmdi_regime(Pb(mask), vS(mask), t(mask), fw_tq, fw_rpm, eta_drive, wheel_r, gear_ratio);
clear Pb vS t mask Pb_us06 vS_us06 t_us06;
print_regime(US06, 'US06', rlbl);

%% -----------------------------------------------------------------------
%  [2/3] HWFET — lean run (~45 min)
%% -----------------------------------------------------------------------
fprintf('============================================================\n');
fprintf(' [2/3] HWFET  765 s\n');
fprintf('============================================================\n');
[Pb, vS, t] = run_lean(mdl, 'HWFET', 900);
% Save raw signals
hwfet_mat = fullfile(model_dir, 'HWFET_signals.mat');
Pb_hw = Pb; vS_hw = vS; t_hw = t;
save(hwfet_mat, 'Pb_hw', 'vS_hw', 't_hw');
fprintf('  Signals saved: %s\n', hwfet_mat);
mask = t <= 765;
HWFET = lmdi_regime(Pb(mask), vS(mask), t(mask), fw_tq, fw_rpm, eta_drive, wheel_r, gear_ratio);
clear Pb vS t mask Pb_hw vS_hw t_hw;
print_regime(HWFET, 'HWFET', rlbl);

%% -----------------------------------------------------------------------
%  [3/3] WLTP — load from saved mat (no re-run)
%% -----------------------------------------------------------------------
fprintf('============================================================\n');
fprintf(' [3/3] WLTP  1800 s — from saved mat\n');
fprintf('============================================================\n');
wltp_file = fullfile(model_dir, 'WLTP_signals.mat');
W = load(wltp_file);
fprintf('  Loaded: %s\n', wltp_file);

% Unpack Pbatt
if isa(W.Pbatt_ws,'double');      Pb = W.Pbatt_ws(:);
elseif isa(W.Pbatt_ws,'timeseries'); Pb = W.Pbatt_ws.Data(:);
else;                              Pb = W.Pbatt_ws.signals.values(:); end

% Unpack vehSpd — timeseries saved by vehSpd_backup_v22 block
if isfield(W,'vehSpd_v22')
    if isa(W.vehSpd_v22,'timeseries'); vS = W.vehSpd_v22.Data(:);
    elseif isa(W.vehSpd_v22,'double'); vS = W.vehSpd_v22(:);
    else;                              vS = W.vehSpd_v22.signals.values(:); end
else
    error('vehSpd_v22 not found in %s', wltp_file);
end

t    = W.t(:);
clear W;

% Trim to 1800 s (cycle end; StopTime=1900 leaves idle tail)
mask = t <= 1800;
WLTP = lmdi_regime(Pb(mask), vS(mask), t(mask), fw_tq, fw_rpm, eta_drive, wheel_r, gear_ratio);
clear Pb vS t mask;
print_regime(WLTP, 'WLTP', rlbl);

%% -----------------------------------------------------------------------
%  LMDI-I Decomposition — 3 cycle pairs
%% -----------------------------------------------------------------------
fprintf('============================================================\n');
fprintf(' LMDI-I DECOMPOSITION\n');
fprintf('============================================================\n');

cycles  = {US06, HWFET, WLTP};
c_names = {'US06','HWFET','WLTP'};
pairs   = {[1 2],[1 3],[2 3]};
p_names = {'US06->HWFET','US06->WLTP','HWFET->WLTP'};

fprintf('\n%-16s %8s %8s %8s %12s\n','Pair','Delta','Struct','Intens','Residual');
fprintf('%s\n', repmat('-',1,58));

Ds_all = zeros(1,3); Di_all = zeros(1,3);
Dt_all = zeros(1,3); Resid  = zeros(1,3);

for pp = 1:3
    A = cycles{pairs{pp}(1)};
    B = cycles{pairs{pp}(2)};

    ok = (A.S>1e-6) & (B.S>1e-6) & (A.I>1e-6) & (B.I>1e-6);
    Lv = zeros(1,3);
    for ii = find(ok)
        if abs(B.e(ii)-A.e(ii)) < 1e-12
            Lv(ii) = A.e(ii);
        else
            Lv(ii) = (B.e(ii)-A.e(ii)) / (log(B.e(ii)) - log(A.e(ii)));
        end
    end
    Ds = sum(Lv(ok) .* log(B.S(ok)./A.S(ok)));
    Di = sum(Lv(ok) .* log(B.I(ok)./A.I(ok)));
    Dt = sum(B.e) - sum(A.e);
    R  = Dt - Ds - Di;

    Ds_all(pp)=Ds; Di_all(pp)=Di; Dt_all(pp)=Dt; Resid(pp)=R;
    fprintf('%-16s %+8.2f %+8.2f %+8.2f %12.2e\n', p_names{pp}, Dt, Ds, Di, R);
end

if max(abs(Resid)) < 1e-10
    fprintf('\n  Residuals: identically ZERO (LMDI exact) ✓\n');
else
    fprintf('\n  WARNING: max residual = %.2e\n', max(abs(Resid)));
end

%% -----------------------------------------------------------------------
%  Regime table (paper Table 5)
%% -----------------------------------------------------------------------
fprintf('\n%-8s | %-22s | %-22s | %-22s\n', 'Cycle', ...
    'MTPA (d km | S%% | I Wh/km)', 'Trans', 'FW');
fprintf('%s\n', repmat('-',1,80));
for cc = 1:3
    C = cycles{cc};
    fprintf('%-8s', c_names{cc});
    for r = 1:3
        fprintf(' | %5.2f %5.1f%% %6.1f', C.d(r), C.S(r)*100, C.I(r));
    end
    fprintf('\n');
end
fprintf('(I = traction-only net Wh/km per regime)\n');

%% -----------------------------------------------------------------------
%  Save
%% -----------------------------------------------------------------------
out = fullfile(model_dir, 'LMDI_results.mat');
save(out, 'US06','HWFET','WLTP', ...
     'Ds_all','Di_all','Dt_all','Resid', ...
     'p_names','c_names','rlbl', ...
     'fw_tq','fw_rpm','eta_drive');
fprintf('\nSaved: %s\n', out);
fprintf('Complete: %s\n', datestr(now,'HH:MM:SS'));


%% =======================================================================
%  LOCAL FUNCTIONS  (must be at end of script)
%% =======================================================================

function [Pb, vS, t] = run_lean(mdl, cycle_name, stop_time)
% Run one drive cycle, extract Pbatt + vehSpd, clear simOut immediately.
    set_param([mdl '/Drive Cycle Source'], 'cycleVar', cycle_name);
    set_param(mdl, 'StopTime', num2str(stop_time));
    save_system(mdl);
    fprintf('  Start %s @ %s\n', cycle_name, datestr(now,'HH:MM:SS'));
    tic;
    simOut = sim(mdl);
    fprintf('  Done: %.1f min\n', toc/60);

    Pb_raw = simOut.get('Pbatt_ws');
    vS_raw = simOut.get('vehSpd_v22');
    clear simOut;  % ← free RAM immediately

    if isa(Pb_raw,'timeseries');   Pb = Pb_raw.Data(:);
    elseif isa(Pb_raw,'double');   Pb = Pb_raw(:);
    else;                          Pb = Pb_raw.signals.values(:); end

    if isa(vS_raw,'timeseries');   vS = vS_raw.Data(:);
    elseif isa(vS_raw,'double');   vS = vS_raw(:);
    else;                          vS = vS_raw.signals.values(:); end

    N = numel(Pb);
    t = (0:(N-1))' * 0.1;
    fprintf('  Captured %d pts (%.0f s), dist=%.2f km, vmax=%.1f km/h\n', ...
        N, t(end), trapz(t,abs(vS))/1000, max(abs(vS))*3.6);
end

function R = lmdi_regime(Pb, vS, t, fw_tq, fw_rpm, eta_drive, wheel_r, gear_ratio)
% Compute per-regime LMDI quantities using CRG-based instantaneous regime assignment.
%
% Regime assignment (per timestep, traction only):
%   1. Estimate motor torque: T_est = Pb * eta_drive / omega_mech
%   2. Look up FW onset RPM for T_est from CRG table: rpm_fw = interp1(fw_tq, fw_rpm, T_est)
%   3. Compute motor RPM: rpm_mech = |vS| * gear_ratio / wheel_r * 60/(2*pi)
%   4. MTPA if rpm_mech < 0.95*rpm_fw (5% margin below boundary)
%      Trans if 0.95*rpm_fw <= rpm_mech < rpm_fw
%      FW    if rpm_mech >= rpm_fw
%   For regen/coast (Pb<=0): timestep assigned to MTPA (motor at light/zero load)

    rpm_mech = abs(vS) * gear_ratio / wheel_r * 60/(2*pi);  % RPM mechanical

    % Estimate torque from battery power (traction timesteps only)
    omega_mech = abs(vS) * gear_ratio / wheel_r;   % rad/s mech
    traction   = Pb > 0;
    T_est      = zeros(size(Pb));
    safe       = traction & (omega_mech > 0.5);    % avoid div-by-zero at standstill
    T_est(safe) = Pb(safe) .* eta_drive ./ omega_mech(safe);
    T_est = max(0, min(T_est, fw_tq(end)));        % clamp to LUT range

    % Look up FW onset RPM for each estimated torque
    rpm_fw_onset = interp1(fw_tq, fw_rpm, T_est, 'linear', 'extrap');
    rpm_fw_onset = max(rpm_fw_onset, fw_rpm(end)); % floor at minimum LUT value

    % Regime masks — 5% transition band around onset boundary
    in_FW    = traction & (rpm_mech >= rpm_fw_onset);
    in_Trans = traction & (rpm_mech >= 0.95*rpm_fw_onset) & ~in_FW;
    in_MTPA  = ~in_FW & ~in_Trans;   % includes regen/coast timesteps

    mk    = {double(in_MTPA), double(in_Trans), double(in_FW)};
    vA    = abs(vS);
    dk    = trapz(t, vA) / 1000;
    Et    = trapz(t, max(Pb,0))  / 3600;
    Er    = abs(trapz(t, min(Pb,0))) / 3600;

    S=zeros(1,3); I=zeros(1,3); e=zeros(1,3); d=zeros(1,3); E=zeros(1,3);
    for r = 1:3
        d(r) = trapz(t, vA.*mk{r}) / 1000;
        etr  = trapz(t, max(Pb,0).*mk{r}) / 3600;
        erv  = abs(trapz(t, min(Pb,0).*mk{r})) / 3600;
        E(r) = etr - erv;
        S(r) = d(r) / dk;
        if d(r) > 0.001; I(r) = E(r) / d(r); end
        e(r) = S(r) * I(r);
    end
    R = struct('S',S,'I',I,'e',e,'d',d,'E',E,'dk',dk,'Et',Et,'Er',Er, ...
               'Ept',(Et-Er)/dk,'regen_pct',Er/Et*100);
end

function print_regime(R, name, rlbl)
% Pretty-print regime breakdown for one cycle.
    fprintf('  %s: dk=%.2f km  Gross=%.1f  Regen=%.1f%%  Net=%.1f Wh/km\n', ...
        name, R.dk, R.Et/R.dk, R.regen_pct, R.Ept);
    fprintf('  %-8s %8s %8s %8s\n','Regime','dist km','share','Wh/km');
    for r = 1:3
        fprintf('  %-8s %8.3f %7.1f%% %8.1f\n', ...
            rlbl{r}, R.d(r), R.S(r)*100, R.I(r));
    end
    fprintf('  Closure: sum(d)=%.3f/%.3f  sum(e)=%.2f vs Ept=%.2f\n\n', ...
        sum(R.d), R.dk, sum(R.e), R.Ept);
end
