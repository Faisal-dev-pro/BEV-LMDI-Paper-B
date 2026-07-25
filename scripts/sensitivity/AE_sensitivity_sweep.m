%% AE_sensitivity_sweep.m — Improvement 6: Parameter Sensitivity / Uncertainty
%
%  US06 g=9.04 baseline re-run under systematic +/- variations of five
%  parameters (PLAN_AE.md Section 6):
%
%    Parameter      Nominal    Low          High
%    A_rl            162.0 N    154 N (-5%)   170 N (+5%)
%    C_rl             0.315     0.299 (-5%)   0.331 (+5%)
%    P_regen_max      60 kW     50 kW         70 kW
%    m_test           1928 kg   1889 (-2%)    1967 (+2%)
%    P_aux            690 W     550 (-20%)    830 (+20%)
%
%  Physical injection points (confirmed by direct Simulink inspection,
%  20 Jul 2026):
%    A_rl, B_rl, C_rl  -> Vehicle_Dynamics/RoadLoad_v21 Fcn block, literal
%                         expression "162 + 0.552*u + 0.315*u^2" applied
%                         via the vehicle's Brake port. B_rl is not swept
%                         (not in Improvement 6 table) and stays nominal.
%    m_test            -> Vehicle_Dynamics/Longitudinal Vehicle M_vehicle
%                         block param + Longitudinal_Driver 'aR' feedforward
%                         (aR = mass * g * Crr_nominal; Crr held at its
%                         nominal coastdown-derived value, only mass moves).
%    P_regen_max       -> onepedal_regen_sfcn.m, was hardcoded 60000; now
%                         reads an optional base-workspace override
%                         P_regen_max_sens (added 20 Jul 2026, backward
%                         compatible — see model/onepedal_regen_sfcn.m).
%    P_aux             -> pure post-hoc BMS-level addition
%                         (v26_BMS_postprocess.m: P_bms = P_motor + P_aux).
%                         Does NOT touch the motor-level P_batt signal, so
%                         it requires NO re-simulation and has ZERO effect
%                         on the LMDI structural/intensity split (which is
%                         computed from motor-level P_batt only).
%
%  For each variant: BMS gross/net/regen Wh/km, FW distance share (v_FW
%  threshold method, matching the gear-sweep scripts), and the LMDI-I
%  structural/intensity split of the UDDS->US06(variant) pair (paired
%  against the fixed, gear-verified UDDS g=9.04 baseline cell used
%  throughout the matrix) are computed and appended to a resumable
%  summary table (results/sensitivity/sensitivity_summary.{mat,csv}).
%
%  Resumable: re-running skips variants already present in SUM.
%  SAFETY: RoadLoad_v21 and the Vehicle mass/driver aR are restored to
%  nominal after every resim iteration, so a crash mid-sweep cannot leave
%  the shared model in a perturbed state for other work.
%
%  Author: F. Shah Khan, University of East London, July 2026
% -------------------------------------------------------------------------

clear; clc;
script_dir = fileparts(mfilename('fullpath'));
proj_root  = char(java.io.File(fullfile(script_dir, '..', '..')).getCanonicalPath());
model_dir  = fullfile(proj_root, 'model');
addpath(model_dir);
addpath(fullfile(proj_root, 'scripts', 'validation'));
addpath(fullfile(proj_root, 'scripts', 'lmdi'));
results_dir = fullfile(proj_root, 'results', 'sensitivity');
if ~exist(results_dir, 'dir'), mkdir(results_dir); end

mdl = 'AE_TeslaM3_LMDI';

fprintf('\n########################################################\n');
fprintf('# AE_sensitivity_sweep.m — Improvement 6\n');
fprintf('# Started: %s\n', datestr(now));
fprintf('########################################################\n\n');

%% Nominal values (must match AE_TeslaM3_LMDI_Params.m v26 exactly)
NOM.A_rl = 162.0; NOM.B_rl = 0.552; NOM.C_rl = 0.315;
NOM.P_regen_max = 60000;
NOM.m_test = 1928;
NOM.P_aux_W = 690;

%% Variant table
V = struct('name',{},'param',{},'value',{},'needs_resim',{});
V(end+1) = struct('name','A_rl_lo',   'param','A_rl',        'value',154.0, 'needs_resim',true);
V(end+1) = struct('name','A_rl_hi',   'param','A_rl',        'value',170.0, 'needs_resim',true);
V(end+1) = struct('name','C_rl_lo',   'param','C_rl',        'value',0.299, 'needs_resim',true);
V(end+1) = struct('name','C_rl_hi',   'param','C_rl',        'value',0.331, 'needs_resim',true);
V(end+1) = struct('name','Pregen_lo', 'param','P_regen_max', 'value',50000, 'needs_resim',true);
V(end+1) = struct('name','Pregen_hi', 'param','P_regen_max', 'value',70000, 'needs_resim',true);
V(end+1) = struct('name','mtest_lo',  'param','m_test',      'value',1889,  'needs_resim',true);
V(end+1) = struct('name','mtest_hi',  'param','m_test',      'value',1967,  'needs_resim',true);
V(end+1) = struct('name','Paux_lo',   'param','P_aux',       'value',550,   'needs_resim',false);
V(end+1) = struct('name','Paux_hi',   'param','P_aux',       'value',830,   'needs_resim',false);

%% LMDI setup — must match AE_run_LMDI_matrix.m exactly (17 Jul verified pipeline)
wheel_r = 0.326; eta_drive = 0.90; fold_tol = 0.01; pres_tol = 1e-9;
FW = load(fullfile(model_dir, 'FW_onset_curve_v2.mat'));
fw_tq = FW.fw_tq_Nm(:); fw_rpm = FW.fw_rpm_mech(:);

udds_file = fullfile(proj_root, 'results', 'tesla_g9.04', ...
    'BMS_UDDS_v26_g9.04_20260716_191321.mat');
assert(exist(udds_file,'file')==2, 'UDDS baseline not found: %s', udds_file);
DU = load(udds_file, 'P_batt','v_spd','t_batt','gear_ratio');
assert(abs(DU.gear_ratio - 9.04) < 0.01, 'UDDS baseline gear mismatch');
UDDS_R = AE_lmdi_decomposition(DU.P_batt, DU.v_spd, DU.t_batt, fw_tq, fw_rpm, eta_drive, wheel_r, 9.04);
UDDS_R = AE_fold_regimes(UDDS_R, fold_tol);
fprintf('UDDS g=9.04 baseline (fixed comparison cell): Net=%.1f Wh/km, S_FW=%.1f%%\n\n', ...
    UDDS_R.Ept, 100*UDDS_R.S(3));

nominal_baseline_file = fullfile(proj_root, 'results', 'tesla_g9.04', ...
    'BMS_US06_v26_20260711_231029.mat');

omega_base = 906; rw = 0.326; gear_ratio_nom = 9.04;
v_FW_mps = omega_base * rw / gear_ratio_nom;

%% Resumable summary table
summary_file = fullfile(results_dir, 'sensitivity_summary.mat');
csv_file     = fullfile(results_dir, 'sensitivity_summary.csv');
if exist(summary_file, 'file')
    Sload = load(summary_file);
    SUM = Sload.SUM;
    fprintf('RESUMING: %d/%d variants already complete.\n\n', numel(SUM), numel(V));
else
    SUM = struct('name',{},'param',{},'value',{},'Wh_km_bms_net',{}, ...
        'Wh_km_bms_gross',{},'bms_regen_pct',{},'fw_dist_pct',{}, ...
        'Ds',{},'Di',{},'Dt',{},'Rres',{},'wall_time',{},'result_file',{});
end

%% ------------------------------------------------------------------------
%  Main loop
%% ------------------------------------------------------------------------
for vi = 1:numel(V)
    v = V(vi);
    if any(strcmp({SUM.name}, v.name))
        fprintf('[%d/%d] %-10s already complete — skipping.\n', vi, numel(V), v.name);
        continue;
    end

    fprintf('\n============================================================\n');
    fprintf(' [%d/%d] SENSITIVITY VARIANT: %s  (%s = %g)\n', vi, numel(V), v.name, v.param, v.value);
    fprintf(' Started: %s\n', datestr(now));
    fprintf('============================================================\n\n');

    if ~v.needs_resim
        % ---- P_aux: pure post-hoc, reuse cached nominal g=9.04 US06 signals ----
        assert(exist(nominal_baseline_file,'file')==2, ...
            'Nominal US06 g=9.04 baseline not found: %s', nominal_baseline_file);
        D = load(nominal_baseline_file, 'P_batt','t_batt','v_spd','gear_ratio');
        P_batt = D.P_batt; t_batt = D.t_batt; v_spd = D.v_spd;
        if isfield(D, 'gear_ratio') && ~isempty(D.gear_ratio)
            gear_ratio = D.gear_ratio;
        else
            % Pre-hardening file (no gear_ratio field) — this is the known
            % g=9.04 baseline file itself (BMS_US06_v26_20260711_231029.mat,
            % same handling as AE_run_LMDI_matrix.m).
            gear_ratio = gear_ratio_nom;
            fprintf('NOTE: %s has no gear_ratio field; assuming %.2f (pre-hardening file).\n', ...
                nominal_baseline_file, gear_ratio_nom);
        end
        cycle = 'US06';
        P_aux_W = v.value; V_oc = 370; R_int_ohm = 0.070; R_cable = 0.015;
        BMS = struct('gross_target',210.6,'net_target',148.7,'regen_pct',29.4, ...
            'gross_tol',0.20,'regen_pct_tol',10.0,'net_tol',0.20,'is_reference',true);
        BMS.gross_lo = BMS.gross_target*(1-BMS.gross_tol); BMS.gross_hi = BMS.gross_target*(1+BMS.gross_tol);
        BMS.net_lo   = BMS.net_target*(1-BMS.net_tol);     BMS.net_hi   = BMS.net_target*(1+BMS.net_tol);
        BMS.regen_lo = BMS.regen_pct-BMS.regen_pct_tol;    BMS.regen_hi = BMS.regen_pct+BMS.regen_pct_tol;
        wall_time = 0;
        run('v26_BMS_postprocess.m');

        % LMDI is motor-level -> P_aux cannot change it; recompute anyway
        % from the cached signals so US06_R is self-consistent for saving.
        US06_R = AE_lmdi_decomposition(P_batt, v_spd, t_batt, fw_tq, fw_rpm, eta_drive, wheel_r, gear_ratio);
        US06_R = AE_fold_regimes(US06_R, fold_tol);
        dist_km_v = sum(abs(v_spd(1:end-1)))*0.1/1000;
        fw_dist_pct = 100 * (sum(abs(v_spd(v_spd>v_FW_mps)))*0.1/1000) / dist_km_v;

    else
        % ---- Re-simulate with the perturbed parameter ----
        if bdIsLoaded(mdl), bdclose(mdl); end
        load_system(mdl);
        clear gear_override P_regen_max_sens mass_override
        % m_test must be applied via mass_override + AE_TeslaM3_LMDI_Params.m
        % (added 20 Jul 2026), NOT via a direct set_param on M_vehicle: the
        % model's InitFcn re-runs AE_TeslaM3_LMDI_Params.m fresh when sim()
        % starts, which silently reverted a direct set_param override back
        % to nominal (confirmed: variants 7/8 mtest_lo/mtest_hi came back
        % bit-identical to nominal in the first sweep attempt). mass_override
        % stays in the base workspace through both the explicit call below
        % AND the InitFcn's automatic rerun, so it is honoured consistently.
        if strcmp(v.param, 'm_test')
            mass_override = v.value; %#ok<NASGU>
        end
        run('AE_TeslaM3_LMDI_Params.m');   % nominal load unless mass_override set

        set_param([mdl '/Drive Cycle Source'], 'cycleVar', 'US06');
        dcs = [mdl '/Drive Cycle Source'];
        mws = get_param(dcs, 'MaskWSVariables');
        idxc = find(strcmp({mws.Name}, 'DriveCycle'));
        dc_ts = mws(idxc).Value;
        vmax_mask = max(dc_ts.Data); tmax_mask = dc_ts.Time(end);
        assert(vmax_mask > 33 && vmax_mask < 40 && tmax_mask > 550 && tmax_mask < 650, ...
            'Drive cycle mismatch: vmax=%.1f m/s, dur=%.0f s (expected US06 ~35.8 m/s, 600 s)', ...
            vmax_mask, tmax_mask);

        roadload_blk = [mdl '/Vehicle_Dynamics/RoadLoad_v21'];

        % m_test needs no direct set_param here: AE_TeslaM3_LMDI_Params.m
        % (just run above, with mass_override in scope) already pushed the
        % perturbed mass into Vehicle_Dynamics/Longitudinal Vehicle's
        % M_vehicle and into the driver's aR feedforward via its own
        % section 7 (identical mechanism as every gear-sweep script).
        Aeff = NOM.A_rl; Beff = NOM.B_rl; Ceff = NOM.C_rl;
        switch v.param
            case 'A_rl'
                Aeff = v.value;
            case 'C_rl'
                Ceff = v.value;
            case 'P_regen_max'
                assignin('base', 'P_regen_max_sens', v.value);
        end
        set_param(roadload_blk, 'Expr', sprintf('%g + %g*u + %g*u^2', Aeff, Beff, Ceff));

        if strcmp(v.param, 'm_test')
            veh_blk = [mdl '/Vehicle_Dynamics/Longitudinal Vehicle'];
            fprintf('m_test check: M_vehicle = %s (expect %g)\n', ...
                get_param(veh_blk, 'M_vehicle'), v.value);
            assert(abs(str2double(get_param(veh_blk,'M_vehicle')) - v.value) < 0.5, ...
                'M_vehicle did not pick up mass_override -- aborting before a wasted sim.');
        end

        C.StopTime = 600; C.Distance = 12.89;
        set_param(mdl, 'StopTime', num2str(C.StopTime));
        set_param(mdl, 'ReturnWorkspaceOutputs', 'off');

        slprj_path = fullfile(fileparts(which(mdl)), 'slprj');
        if exist(slprj_path, 'dir'), rmdir(slprj_path, 's'); end
        save_system(mdl);

        % Normal mode required whenever a compiled block PARAMETER changes
        % (RoadLoad_v21 Expr, M_vehicle) — Accelerator's checksum cache can
        % silently miss these (see gear-sweep contamination incident, 16
        % Jul 2026). P_regen_max is read live via evalin() inside an
        % interpreted MATLAB S-Function, so Accelerator mode is safe and
        % faster for that variant only.
        use_normal = ~strcmp(v.param, 'P_regen_max');
        if use_normal
            set_param(mdl, 'SimulationMode', 'normal');
        else
            set_param(mdl, 'SimulationMode', 'accelerator');
        end
        fprintf('SimulationMode: %s\n', get_param(mdl,'SimulationMode'));

        fprintf('Running US06 (%s = %g)...  [do not close MATLAB]\n', v.param, v.value);
        tic;
        sim(mdl);
        wall_time = toc;
        fprintf('Done: %.1f min (%.2f hr)\n', wall_time/60, wall_time/3600);

        % Restore to nominal IMMEDIATELY, before any post-processing that
        % could error and abort the script.
        set_param(roadload_blk, 'Expr', sprintf('%g + %g*u + %g*u^2', NOM.A_rl, NOM.B_rl, NOM.C_rl));
        clear P_regen_max_sens mass_override
        if strcmp(v.param, 'm_test')
            % Re-run Params.m (now with mass_override cleared) so it pushes
            % M_vehicle/aR back to nominal via its own section 7, instead of
            % hand-computing the restore value here.
            run('AE_TeslaM3_LMDI_Params.m');
        end
        set_param(mdl, 'SimulationMode', 'accelerator');
        save_system(mdl);
        fprintf('Model restored to nominal.\n');

        N = numel(Pbatt_ws); dt = 0.1;
        t_batt = (0:N-1)' * dt;
        P_batt = Pbatt_ws(:);
        v_spd  = interp1(dc_ts.Time, dc_ts.Data(:), t_batt, 'linear', 0);
        cycle = 'US06';
        gear_ratio = gear_ratio_nom;

        P_aux_W = NOM.P_aux_W; V_oc = 370; R_int_ohm = 0.070; R_cable = 0.015;
        BMS = struct('gross_target',210.6,'net_target',148.7,'regen_pct',29.4, ...
            'gross_tol',0.20,'regen_pct_tol',10.0,'net_tol',0.20,'is_reference',true);
        BMS.gross_lo = BMS.gross_target*(1-BMS.gross_tol); BMS.gross_hi = BMS.gross_target*(1+BMS.gross_tol);
        BMS.net_lo   = BMS.net_target*(1-BMS.net_tol);     BMS.net_hi   = BMS.net_target*(1+BMS.net_tol);
        BMS.regen_lo = BMS.regen_pct-BMS.regen_pct_tol;    BMS.regen_hi = BMS.regen_pct+BMS.regen_pct_tol;
        run('v26_BMS_postprocess.m');

        US06_R = AE_lmdi_decomposition(P_batt, v_spd, t_batt, fw_tq, fw_rpm, eta_drive, wheel_r, gear_ratio);
        US06_R = AE_fold_regimes(US06_R, fold_tol);
        dist_km_v = sum(abs(v_spd(1:end-1)))*dt/1000;
        fw_dist_pct = 100 * (sum(abs(v_spd(v_spd>v_FW_mps)))*dt/1000) / dist_km_v;
    end

    [Dt, Ds, Di, Rres] = AE_lmdi_pair(UDDS_R, US06_R, pres_tol);

    save_name = fullfile(results_dir, sprintf('SENS_%s_%s.mat', v.name, datestr(now,'yyyymmdd_HHMMSS')));
    save(save_name, 'v', 'P_batt','t_batt','v_spd','gear_ratio','cycle', ...
         'Wh_km_bms_gross','Wh_km_bms_net','bms_regen_pct','fw_dist_pct', ...
         'US06_R','UDDS_R','Dt','Ds','Di','Rres','wall_time');

    row = struct('name',v.name,'param',v.param,'value',v.value, ...
        'Wh_km_bms_net',Wh_km_bms_net,'Wh_km_bms_gross',Wh_km_bms_gross, ...
        'bms_regen_pct',bms_regen_pct,'fw_dist_pct',fw_dist_pct, ...
        'Ds',Ds,'Di',Di,'Dt',Dt,'Rres',Rres,'wall_time',wall_time, ...
        'result_file',save_name);
    SUM(end+1) = row; %#ok<SAGROW>
    save(summary_file, 'SUM');

    fid = fopen(csv_file, 'w');
    fprintf(fid, 'name,param,value,Wh_km_bms_net,Wh_km_bms_gross,bms_regen_pct,fw_dist_pct,Dstr,Dint,Dtotal,residual,wall_time_s\n');
    for k = 1:numel(SUM)
        fprintf(fid, '%s,%s,%g,%.2f,%.2f,%.2f,%.2f,%.3f,%.3f,%.3f,%.2e,%.1f\n', ...
            SUM(k).name, SUM(k).param, SUM(k).value, SUM(k).Wh_km_bms_net, ...
            SUM(k).Wh_km_bms_gross, SUM(k).bms_regen_pct, SUM(k).fw_dist_pct, ...
            SUM(k).Ds, SUM(k).Di, SUM(k).Dt, SUM(k).Rres, SUM(k).wall_time);
    end
    fclose(fid);

    fprintf('\n>>> %-10s Net=%.1f Wh/km | Gross=%.1f | Regen=%.1f%% | FW=%.1f%% | Dstr=%+.2f Dint=%+.2f (res=%.2e)\n', ...
        v.name, Wh_km_bms_net, Wh_km_bms_gross, bms_regen_pct, fw_dist_pct, Ds, Di, Rres);
    fprintf('    Saved: %s\n', save_name);
    fprintf('    Progress: %d/%d variants complete. Summary: %s\n', numel(SUM), numel(V), csv_file);
end

%% ------------------------------------------------------------------------
%  Final report
%% ------------------------------------------------------------------------
fprintf('\n############################################################\n');
fprintf('# SENSITIVITY SWEEP COMPLETE (Improvement 6): %d/%d variants\n', numel(SUM), numel(V));
fprintf('# Nominal (tesla_g9.04 baseline, UDDS->US06): Net=148.7 Wh/km, Dstr=+41.2, Dint=+11.9, Sshare=78%%\n');
fprintf('############################################################\n\n');
fprintf('%-10s %-12s %10s %10s %10s %8s %8s %8s\n', ...
    'Variant','Param','Value','NetWh/km','FWdist%','Dstr','Dint','Sshare%');
for k = 1:numel(SUM)
    if abs(SUM(k).Dt) > 1e-9, s_share = 100*SUM(k).Ds/SUM(k).Dt; else, s_share = NaN; end
    fprintf('%-10s %-12s %10g %10.1f %10.1f %8.2f %8.2f %8.1f\n', ...
        SUM(k).name, SUM(k).param, SUM(k).value, SUM(k).Wh_km_bms_net, ...
        SUM(k).fw_dist_pct, SUM(k).Ds, SUM(k).Di, s_share);
end
fprintf('\nMax |residual|: %.2e\n', max(abs([SUM.Rres])));
fprintf('Results dir: %s\n', results_dir);
fprintf('Summary:     %s\n             %s\n', summary_file, csv_file);
fprintf('Complete: %s\n', datestr(now));
