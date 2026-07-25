%% AE_TeslaM3_LMDI_Params.m
%  Master parameter file — Tesla Model 3 Long Range rear IPMSM (188 kW).
%  Validated against ANL D3 dynamometer data (series 62005xxx / 62006xxx).
%
%  CALIBRATION TIERS
%    [V]  VERIFIED   — ANL D3 report / MotorXP teardown / Tesla spec
%    [D]  DERIVED    — computed from verified source (incl. ANL vehicle fit)
%    [E]  ESTIMATE   — IPMSM design literature; uncertainty-quantification candidate
%
%  Author: F. Shah Khan, University of East London, 2026
% -------------------------------------------------------------------------

%% =====================================================================
%  1) HIERARCHICAL STRUCT
%  =====================================================================

P = struct();

% ----- Motor: Tesla Model 3 LR rear IPMSM (188 kW) --------------------
P.motor.Pmax  = 188000;       % [V] peak power [W]             ANL D3 test record
P.motor.Tmax  = 430;          % [V] peak torque [N·m]          MotorXP teardown
P.motor.p     = 3;            % [V] pole pairs                 ANL / MotorXP
P.motor.Rs    = 0.00475;      % [V] stator resistance [Ohm]    MotorXP teardown (20°C)
P.motor.psim  = (42/sqrt(3)) / ((1000/60)*2*pi*3);  % [D] PM flux linkage [Wb]
P.motor.Ld    = 1.25e-4;      % [D] d-axis inductance [H]      ANL vehicle fit (2.7% RMS)
P.motor.Lq    = 2.44e-4;      % [D] q-axis inductance [H]      ANL vehicle fit (2.7% RMS)
P.motor.L0    = 1.0e-4;       % [E] zero-sequence inductance [H]
P.motor.Jm    = 0.05;         % [E] rotor inertia [kg·m²]
P.motor.tref  = 200;          % torque reference for step tests [N·m]

% ----- High-voltage system: Tesla Model 3 LR pack ---------------------
%  Pack voltage levels (96 series NCA 2170 cells):
%    V_max   = 96 x 4.2 = 403 V  (fully charged, SOC ~ 100%)
%    V_nom   = 96 x 3.7 = 355 V  (cell nominal)
%    V_oc    = 370 V              (ANL CAN bus avg, warm phases 4-7)
%
%  P.batt.Vnom = 400 V is the Simscape battery block parameter.
%  For the CRG field-weakening boundary, V_dc = 370 V is used (average
%  operating voltage under load). This gives omega_base = 906 rad/s and
%  v_FW = 117.6 km/h at g=9.04. Using V_max = 400 V would give
%  v_FW ~ 127 km/h and understate FW operation. See ANL_Model_Initialization.m.
P.batt.Vnom   = 400;          % [V] Simscape block voltage (~ V_max, 96s x 4.2 V)
P.batt.V1     = 330;          % [E] discharge curve knee [V]
P.batt.Cdc    = 0.001;        % [E] DC-link capacitor [F]
P.batt.kWh    = 75;           % [V] pack energy capacity [kWh]
P.batt.Ah     = 75e3 / 370;   % [D] ~202.7 Ah (at V_oc = 370 V)
P.batt.SOC0   = 95;           % [V] initial SOC [%]  — ANL test start condition
P.batt.Rint   = 0.05;         % [E] pack internal resistance [Ohm]

% ----- Vehicle (Tesla Model 3 LR, ANL coastdown-fitted) ----------------
P.veh.mass    = 1928;         % [V] test mass [kg]  (curb 1847 + 81 kg ballast)
if exist('mass_override', 'var') && ~isempty(mass_override)
    P.veh.mass = mass_override;   % Improvement 6 sensitivity sweep (m_test)
end
P.veh.rw      = 0.326;        % [V] tyre rolling radius [m]  235/45R18
P.veh.A       = 2.22;         % [E] frontal area [m²]
%
% Road load from ANL coastdown test 62005005 (SI units):
%   F = 162.0 + 0.552·|v| + 0.315·v²  [N],  v in m/s
%
% v26 UPDATE: Coefficients re-extracted from three independent coastdown
% runs in test 62005005 using Savitzky-Golay smoothed deceleration.
%   CD1: A=161.69, B=0.520, C=0.3142
%   CD2: A=161.76, B=0.580, C=0.3152
%   CD3: A=162.36, B=0.578, C=0.3158
% Combined 3-run average: A=162.0, B=0.552, C=0.315
% US06 road load energy: 116.6 Wh/km (was 151.6 with old coefficients).
% Motor gross with corrected RL matches ANL to 0.2% (198.6 vs 199.0).
%
% The Simscape Longitudinal Vehicle block does not apply C_tireroll or
% C_airdrag at run-time in Regular parameterisation mode. Road load is
% therefore applied externally via the vehicle brake port (see AE_v25_Run.m).
% C_tireroll and C_airdrag are set to near-zero to avoid double-counting.
%
% Crr_eff and Cd_eff below are used for driver feedforward and LMDI analysis:
P.veh.Crr     = 0.00857;       % [D] effective rolling resistance (ANL coastdown v26)
                               %     = A_rl / (m*g) = 162.0 / (1928*9.81)
P.veh.Cd      = 0.2317;        % [D] effective drag coefficient   (ANL coastdown v26)
                               %     = 2*C_rl / (rho*A) = 2*0.315 / (1.225*2.22)
%
% Road load verification (v26, ANL coastdown-derived):
%   v = 10 m/s: F_model = 199 N
%   v = 20 m/s: F_model = 299 N
%   v = 30 m/s: F_model = 462 N
%
P.veh.A_rl    = 162.0;         % [V] constant term [N]           (ANL coastdown 62005005)
P.veh.B_rl    = 0.552;         % [V] speed-proportional term [N·s/m]
P.veh.C_rl    = 0.315;         % [V] aerodynamic term [N·s²/m²]

% ----- Drivetrain (ANL D3 2020) ---------------------------------------
P.gear.ratio  = 9.04;         % [V] final drive ratio          ANL test record
if exist('gear_override', 'var') && ~isempty(gear_override)
    P.gear.ratio = gear_override;
end
P.gear.eff    = 0.97;         % [E] mechanical efficiency

% ----- Environment ----------------------------------------------------
P.env.rho_air     = 1.225;    % [V] air density [kg/m³]        ISO 2533
P.env.T_ambient   = 20;       % [V] ambient temperature [°C]
P.env.g           = 9.81;     % [V] gravitational acceleration [m/s²]

% ----- Control / PWM --------------------------------------------------
P.ctrl.Ts     = 5e-6;         % [E] fundamental sample time [s]
P.ctrl.fsw    = 10e3;         % [E] PWM switching frequency [Hz]
P.ctrl.Tsi    = 1e-4;         % [E] current-loop sample time [s]

% ----- Current-controller PI gains (IMC method, ω_bw = f_sw/10 · 2π) --
omega_bw      = 2*pi * P.ctrl.fsw / 10;   % 6283.2 rad/s
P.ctrl.Kp_id  = omega_bw * P.motor.Ld;    % 0.7854
P.ctrl.Ki_id  = omega_bw * P.motor.Rs;    % 29.845
P.ctrl.Kp_iq  = omega_bw * P.motor.Lq;    % 1.5331
P.ctrl.Ki_iq  = omega_bw * P.motor.Rs;    % 29.845

% ----- Driver (ANL-validated speed-tracking) --------------------------
%  Gains tuned to achieve <0.1% distance error on all three drive cycles.
%  Scheduled Kp/Ki reduce gain at highway speed to prevent overshoot.
P.driver.Kp   = 500;          % proportional gain
P.driver.Ki   = 100;          % integral gain
P.driver.Kff  = 0.15;         % feedforward gain

%% =====================================================================
%  2) FLAT WORKSPACE VARIABLES
%  =====================================================================
Pmax = P.motor.Pmax;
Tmax = P.motor.Tmax;
p    = P.motor.p;
Rs   = P.motor.Rs;
psim = P.motor.psim;
Ld   = P.motor.Ld;
Lq   = P.motor.Lq;
L0   = P.motor.L0;
Jm   = P.motor.Jm;
tref = P.motor.tref;

Cdc   = P.batt.Cdc;
Vnom  = P.batt.Vnom;
V1    = P.batt.V1;
R_int = P.batt.Rint;

Ts  = P.ctrl.Ts;
fsw = P.ctrl.fsw;
Tsi = P.ctrl.Tsi;

Kp_id = P.ctrl.Kp_id;
Ki_id = P.ctrl.Ki_id;
Kp_iq = P.ctrl.Kp_iq;
Ki_iq = P.ctrl.Ki_iq;

gear_ratio      = P.gear.ratio;
gear_eff        = P.gear.eff;
brake_force_max = 18000;   % [N]  maximum friction brake force (~0.95g at 1928 kg)

%% Zero-cancellation transfer functions
numd_id = Tsi / (Kp_id / Ki_id);
dend_id = [1   (Tsi - (Kp_id/Ki_id)) / (Kp_id/Ki_id)];
numd_iq = Tsi / (Kp_iq / Ki_iq);
dend_iq = [1   (Tsi - (Kp_iq/Ki_iq)) / (Kp_iq/Ki_iq)];

%% =====================================================================
%  3) CURRENT-REFERENCE LOOKUP TABLES (MTPA + FIELD WEAKENING)
%  =====================================================================
%  TeslaM3_CurrentRefs.mat   — id_table, iq_table, T_vec, rpm_vec (2D, 200×200)
%  IPMSM_CurrentRef_LUT.mat  — ID_MAP, IQ_MAP, RPM_VECT, TQ_VECT, VDC_VECT (3D, 33×83×4)
load TeslaM3_CurrentRefs;
load IPMSM_CurrentRef_LUT;

%% Restore motor params overwritten by load
Ld    = P.motor.Ld;
Lq    = P.motor.Lq;
psim  = P.motor.psim;
Rs    = P.motor.Rs;
p     = P.motor.p;
LdmLq = Ld - Lq;
Kp_id = P.ctrl.Kp_id;
Ki_id = P.ctrl.Ki_id;
Kp_iq = P.ctrl.Kp_iq;
Ki_iq = P.ctrl.Ki_iq;

%% =====================================================================
%  4) UNCERTAINTY QUANTIFICATION METADATA
%  =====================================================================
uq = struct([]);

% Vehicle
uq(end+1).field='veh.mass'; uq(end).baseline=P.veh.mass;
  uq(end).dist='TruncatedNormal'; uq(end).cov=0.03;
  uq(end).range=[]; uq(end).trunc=P.veh.mass*[1-0.09 1+0.09];
  uq(end).tier='V'; uq(end).source='ANL D3 + payload';

uq(end+1).field='veh.Cd'; uq(end).baseline=P.veh.Cd;
  uq(end).dist='TruncatedNormal'; uq(end).cov=0.05;
  uq(end).range=[]; uq(end).trunc=P.veh.Cd*[1-0.15 1+0.15];
  uq(end).tier='V'; uq(end).source='Tesla spec / wind-tunnel';

uq(end+1).field='veh.A'; uq(end).baseline=P.veh.A;
  uq(end).dist='Uniform'; uq(end).cov=NaN;
  uq(end).range=P.veh.A*[1-0.02 1+0.02]; uq(end).trunc=[];
  uq(end).tier='E'; uq(end).source='0.85×h×w approximation';

uq(end+1).field='veh.Crr'; uq(end).baseline=P.veh.Crr;
  uq(end).dist='TruncatedNormal'; uq(end).cov=0.15;
  uq(end).range=[]; uq(end).trunc=[0.003 0.020];
  uq(end).tier='V'; uq(end).source='ANL coastdown test 62005005';

uq(end+1).field='veh.rw'; uq(end).baseline=P.veh.rw;
  uq(end).dist='Uniform'; uq(end).cov=NaN;
  uq(end).range=P.veh.rw*[1-0.02 1+0.02]; uq(end).trunc=[];
  uq(end).tier='V'; uq(end).source='235/45R18 OEM tyre';

% Battery
uq(end+1).field='batt.kWh'; uq(end).baseline=P.batt.kWh;
  uq(end).dist='TruncatedNormal'; uq(end).cov=0.03;
  uq(end).range=[]; uq(end).trunc=P.batt.kWh*[0.90 1.10];
  uq(end).tier='V'; uq(end).source='Schuster et al.';

uq(end+1).field='batt.Rint'; uq(end).baseline=P.batt.Rint;
  uq(end).dist='Lognormal'; uq(end).cov=0.20;
  uq(end).range=[]; uq(end).trunc=[];
  uq(end).tier='E'; uq(end).source='Birkl et al.';

% Motor
uq(end+1).field='motor.Jm'; uq(end).baseline=P.motor.Jm;
  uq(end).dist='Uniform'; uq(end).cov=NaN;
  uq(end).range=P.motor.Jm*[0.9 1.1]; uq(end).trunc=[];
  uq(end).tier='E'; uq(end).source='Design tolerance';

% Drivetrain
uq(end+1).field='gear.eff'; uq(end).baseline=P.gear.eff;
  uq(end).dist='TruncatedNormal'; uq(end).cov=0.01;
  uq(end).range=[]; uq(end).trunc=[0.93 0.99];
  uq(end).tier='E'; uq(end).source='Manufacturer';

% Environment
uq(end+1).field='env.rho_air'; uq(end).baseline=P.env.rho_air;
  uq(end).dist='Uniform'; uq(end).cov=NaN;
  uq(end).range=[1.15 1.30]; uq(end).trunc=[];
  uq(end).tier='V'; uq(end).source='ISO 2533';

uq(end+1).field='env.T_ambient'; uq(end).baseline=P.env.T_ambient;
  uq(end).dist='Uniform'; uq(end).cov=NaN;
  uq(end).range=[-10 40]; uq(end).trunc=[];
  uq(end).tier='V'; uq(end).source='Typical operating range';

P.uq = uq;

%% =====================================================================
%  5) SANITY CHECK
%  =====================================================================
for k = 1:numel(P.uq)
    v_live = local_getfield(P, P.uq(k).field);
    v_base = P.uq(k).baseline;
    if abs(v_live - v_base) > 1e-12 * max(1, abs(v_live))
        error('AE_TeslaM3_LMDI_Params:baselineMismatch', ...
              'P.uq(%d) field ''%s'': baseline %.6g != live value %.6g', ...
              k, P.uq(k).field, v_base, v_live);
    end
end

fprintf(['AE_TeslaM3_LMDI_Params: %d uncertain parameters loaded.\n' ...
         '  Motor: p=%d, Rs=%.5f Ohm, psim=%.5f Wb, Ld=%.4g H, Lq=%.4g H\n' ...
         '  PI:    Kp_id=%.4f  Ki_id=%.2f  Kp_iq=%.4f  Ki_iq=%.2f\n' ...
         '  Pack:  %.0f V / %.0f kWh  Gear: %.4f:1\n' ...
         '  LUT:   IPMSM_CurrentRef_LUT.mat + TeslaM3_CurrentRefs.mat\n'], ...
    numel(P.uq), p, Rs, psim, Ld, Lq, ...
    Kp_id, Ki_id, Kp_iq, Ki_iq, ...
    Vnom, P.batt.kWh, gear_ratio);

%% =====================================================================
%  6) TORQUE ENVELOPE, REGEN & IRON LOSS
%  =====================================================================

% Torque–speed envelope (used by Tq_Dyn_Clamp)
% Full torque is available from zero speed; power-limited above base speed.
RPM_env  = [0, 1, 4000, 6000, 7000, 7500, 8000, 8500, 9000, 9500, 10000, 11000];
Tmax_env = [430, 430, 430, 306, 262, 244, 229, 216, 204, 193, 183, 167];

% Regen parameters
P_regen_max    = 60e3;    % [W] maximum regenerative power at battery terminals
P_regen_mech   = 60e3;    % [W] mechanical power cap (equals electrical: iron loss zeroed)
regen_minSpeed = 1.39;    % [m/s] low-speed regen cutoff (5 km/h)

% regen_fraction: fraction of available brake force delivered by motor regen.
% Set to 0.95 to maximise brake-phase regen capture in simulation.
% Coast-phase regen (lift-off deceleration) is modelled analytically in
% v24_PostHocRegen.m to avoid closed-loop energy cycling artefacts.
regen_fraction = 0.95;

% coast_regen_N: coast regen force applied by model subsystem (v22 chain).
% Set to zero — the v22 force-domain coast regen caused PID cycling and is
% superseded by the v25 split-authority lift-off regen below. The v22
% blocks remain in the model but are inert at coast_regen_N = 0.
coast_regen_N  = 0;

% ----- v25 split-authority lift-off regen (torque domain) --------------
% Rule-based one-pedal driving: when the accelerator is released and no
% brake demand exists, a fixed regen torque equivalent to 0.15g vehicle
% deceleration is injected at Tq_Sum port 3 (bypasses PID and brake path).
% See v25_LiftOffRegen.m for the block construction and rationale.
T_liftoff_Nm = P.veh.mass * 0.15 * P.env.g * P.veh.rw / P.gear.ratio;
%              = 1928 * 0.15 * 9.81 * 0.326 / 9.04 = 102.3 Nm
liftoff_on_thresh  = 0.005;  % regen engages when AccelCmd <= this
liftoff_off_thresh = 0.02;   % regen disengages when AccelCmd >= this
%                              (hysteresis band; cruise AccelCmd is
%                               0.02-0.14 per v22 measurement, so the
%                               gate stays off during cruise)
T_liftoff_slew     = 1000;   % [Nm/s] engagement/release rate limit

% Regen power cap LUT (speed-dependent ceiling on regen torque)
Regen_PowerCap_BP    = [0 1.38 1.39 2 5 10 15 20 25 30 40 50 60 70 80];
Regen_PowerCap_Table = [0 0 ...
    P_regen_mech/1.39 P_regen_mech/2 P_regen_mech/5 P_regen_mech/10 ...
    P_regen_mech/15 P_regen_mech/20 P_regen_mech/25 P_regen_mech/30 ...
    P_regen_mech/40 P_regen_mech/50 P_regen_mech/60 P_regen_mech/70 ...
    P_regen_mech/80];

% Iron loss: v26 — ENABLED in Simscape IPMSM block.
%
% In v24/v25 iron losses were zeroed because the Simscape abc_thermal
% iron-loss formulation showed a small energy conservation artefact during
% regeneration. For v26 BMS-level validation, iron losses are re-enabled
% because:
%   (a) The artefact is small (< 1% of regen energy) and acceptable for
%       validation within the 5% tolerance band.
%   (b) Without iron losses, the BMS gross gap is 6-7 Wh/km too large.
%       Iron losses add 3-5 Wh/km to motor gross, closing this gap.
%   (c) BMS-level validation requires realistic total losses to match the
%       battery terminal power measured by the BMS cumulative counters.
%
% Physical values from ANL-calibrated motor characterisation:
% MotorXP OC iron losses at three speeds (total, for reference):
%   1000 RPM (50 Hz):  37 W
%   4000 RPM (200 Hz): 524 W
%   8000 RPM (400 Hz): 1729 W
% Simscape R2026a empirical model requires [P_hysteresis, P_eddy, P_excess]
% at a single reference frequency. NNLS decomposition from 3-point data:
%   OC fit: [51.2, 520.1, 1729.8] vs data [37, 524, 1729]
%   SC fit: [35.6, 354.1, 1164.6] vs data [25, 357, 1164]
losses_oc  = [0, 220.9, 299.2];  % [W] OC [P_h, P_e, P_x] at f_losses
losses_sc  = [0, 139.2, 214.9];  % [W] SC [P_h, P_e, P_x] at f_losses
f_losses   = 200;               % [Hz] reference electrical freq (4000 RPM, p=3)
Isc_losses = 400;               % [A] RMS phase current for SC loss measurement
losses_oc_physical = losses_oc;  % retained alias for post-processing scripts
losses_sc_physical = losses_sc;  % retained alias

% ----- BMS-level parameters (v26) ----------------------------------------
% Added for BMS-level validation. These define the battery-to-motor offset.
P_aux_W    = 690;       % [V] constant auxiliary load [W]
                        %     DCDC converter: 61 Wh / (600/3600) = 366 W
                        %     Front motor quiescent: 54 Wh / (600/3600) = 324 W
                        %     Source: ANL test summary WP7 + WP3 channels
V_oc       = 370;       % [V] battery open-circuit voltage (phases 4-7 avg)
R_int_ohm  = 0.070;     % [E] pack internal resistance [Ohm]
R_cable    = 0.015;     % [E] cable + contactor resistance [Ohm]

%% =====================================================================
%  7) APPLY BLOCK PARAMETERS TO MODEL (if open)
%  =====================================================================
try
    mdl_name = 'AE_TeslaM3_LMDI';

    % --- Driver ---
    drv = [mdl_name '/Longitudinal_Driver/Longitudinal Driver'];
    set_param(drv, 'Kp',       num2str(P.driver.Kp));
    set_param(drv, 'Ki',       num2str(P.driver.Ki));
    set_param(drv, 'Kff',      num2str(P.driver.Kff));
    set_param(drv, 'aMode',    '2');
    set_param(drv, 'VehVelVec','[0 15 30 100]');
    set_param(drv, 'KpVec',    '[500 500 200 200]');
    set_param(drv, 'KiVec',    '[100 100 40 40]');

    aR_driver = round(P.veh.mass * P.env.g * P.veh.Crr);
    cR_driver = 0.5 * P.env.rho_air * P.veh.Cd * P.veh.A;
    set_param(drv, 'aR',   num2str(aR_driver));
    set_param(drv, 'bR',   '0');
    set_param(drv, 'cR',   num2str(cR_driver));
    set_param(drv, 'tauPt','0.2');
    set_param(drv, 'Kaw',  '5');

    % --- Iron loss (v26: ENABLED for BMS-level validation) ---
    set_param([mdl_name '/IPMSM'], 'loss_param',  'ee.enum.ironloss.empirical');
    set_param([mdl_name '/IPMSM'], 'losses_oc',   mat2str(losses_oc));
    set_param([mdl_name '/IPMSM'], 'losses_sc',   mat2str(losses_sc));
    set_param([mdl_name '/IPMSM'], 'f_losses',    mat2str(f_losses));
    set_param([mdl_name '/IPMSM'], 'Isc_losses',  num2str(Isc_losses));

    % --- Torque envelope ---
    set_param([mdl_name '/Torque_Envelope/Tq_Envelope'], ...
              'Table',                   mat2str(Tmax_env));
    set_param([mdl_name '/Torque_Envelope/Tq_Envelope'], ...
              'BreakpointsForDimension1', mat2str(RPM_env));

    % --- Vehicle block ---
    % Road load is applied externally via the brake port; C_tireroll and
    % C_airdrag are set near-zero to prevent double-counting.
    veh_paths = {
        [mdl_name '/Vehicle_Dynamics/Longitudinal Vehicle']
        [mdl_name '/Longitudinal Vehicle']
        [mdl_name '/Vehicle/Longitudinal Vehicle']
        [mdl_name '/Vehicle Body/Longitudinal Vehicle']
    };
    veh_found = false;
    for vp = 1:numel(veh_paths)
        try
            get_param(veh_paths{vp}, 'BlockType');
            veh_blk  = veh_paths{vp};
            veh_found = true;
            break;
        catch, end
    end
    if ~veh_found
        all_blks = find_system(mdl_name, 'SearchDepth', 3, ...
            'LookUnderMasks', 'all', 'RegExp', 'on', 'Name', '[Vv]ehicle');
        if ~isempty(all_blks)
            veh_blk  = all_blks{1};
            veh_found = true;
        end
    end
    if veh_found
        set_param(veh_blk, 'vehParamType', ...
            'sdl.enum.VehicleParameterizationType.Regular');
        set_param(veh_blk, 'M_vehicle',  num2str(P.veh.mass));
        set_param(veh_blk, 'R_tireroll', num2str(P.veh.rw));
        set_param(veh_blk, 'air_density',num2str(P.env.rho_air));
        set_param(veh_blk, 'C_tireroll', '1e-6');
        set_param(veh_blk, 'C_airdrag',  '1e-6');
        set_param(veh_blk, 'A_front',    num2str(P.veh.A));
    else
        warning('AE_TeslaM3_LMDI_Params: Longitudinal Vehicle block not found.');
    end

    % --- Gear block (viscous friction zeroed; gearbox loss post-processed) ---
    gear_blk = [mdl_name '/Vehicle_Dynamics/Simple Gear'];
    try
        set_param(gear_blk, 'mu_visc',  '[0 0]');
        set_param(gear_blk, 'T_noload', '0');
    catch, end

    % --- Regen braking ---
    set_param([mdl_name '/Regen_Braking/BrakeForce_Total'], ...
              'Gain', 'brake_force_max');

    % Save so that compile-time parameters are baked into the .slx
    save_system(mdl_name);
    fprintf('  AE_TeslaM3_LMDI_Params: block parameters applied and model saved.\n');

catch
    % Model not open — workspace variables are ready for when it is opened
end

%% =====================================================================
%  LOCAL FUNCTIONS
%  =====================================================================
function v = local_getfield(S, dottedPath)
    parts = strsplit(dottedPath, '.');
    v = S;
    for ii = 1:numel(parts)
        v = v.(parts{ii});
    end
end
