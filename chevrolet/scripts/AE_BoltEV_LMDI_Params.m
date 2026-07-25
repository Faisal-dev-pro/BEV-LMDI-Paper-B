%% AE_BoltEV_LMDI_Params.m
%  Master parameter file — Chevrolet Bolt EV 2019 IPM (150 kW).
%  Validated against ANL D3 dynamometer data (series 61910xxx / 61911xxx).
%
%  ARCHITECTURE: Simscape Electrical IPMSM + FOC controller + converter.
%  Full Simscape architecture re-parameterized from Tesla Paper A model.
%  CRG boundary computed separately using psi_m and k_Vmax only.
%
%  CALIBRATION TIERS
%    [V]  VALIDATED  — ANL TDMS / Patel FEA / GM spec / coastdown verified
%    [D]  DATA-DERIVED — extracted from ANL data with stated method
%    [E]  ESTIMATE   — initial value from measurement, not calibrated
%
%  Author: F. Shah Khan, University of East London, 2026
% -------------------------------------------------------------------------

%% =====================================================================
%  1) HIERARCHICAL STRUCT
%  =====================================================================

P = struct();

% ----- Motor: Bolt EV IPM, 8-pole double-V hairpin (150 kW) ----------
P.motor.Pmax  = 150000;       % [V] peak power [W]             EPA cert
P.motor.Tmax  = 360;          % [V] peak torque [N.m]          GM spec (Patel FEA: 353)
P.motor.p     = 4;            % [V] pole pairs (8-pole)        Patel 2025 teardown
P.motor.Rs    = 0.00659;      % [D] stator resistance [Ohm]    Patel FEA (DC, 20C)
P.motor.psim  = 0.1017;       % [V] PM flux linkage [Wb]       Fitted, FEA-anchored
                               %     FEA prior 0.1078, -5.7% consistent with
                               %     reversible demagnetisation at 85C
P.motor.kVmax = 0.904;        % [V] modulation index            Fitted, six-step=0.906
P.motor.n_base = 4400;        % [D] rated speed [rpm]           Patel FEA Table III
P.motor.n_max  = 8800;        % [V] max speed [rpm]             Momen 2018

% Ld/Lq used in Simscape IPMSM block and FOC current reference LUTs.
% Constant-inductance gives 23% peak torque error at saturation, but
% drive cycle operating points are mostly below 50% peak and within
% the linear region where constant Ld/Lq is adequate.
P.motor.Ld    = 253.7e-6;     % [E] d-axis inductance [H]      constant-inductance fit
P.motor.Lq    = 389.1e-6;     % [E] q-axis inductance [H]      23% peak torque error
P.motor.L0    = 200e-6;       % [E] zero-sequence inductance [H] estimate
P.motor.Jm    = 0.08;         % [E] rotor inertia [kg.m^2]     design estimate
P.motor.tref  = 150;          % torque reference for step tests [N.m]

% ----- Motor loss map (efficiency-map architecture) -------------------
%  Loaded from BoltEV_loss_map.mat:
%    T_grid_Nm  — 49 torque bins [-125 to 355 Nm]
%    n_grid_rpm — 44 speed bins [100 to 8700 rpm]
%    P_loss_W   — 49 x 44 loss matrix [W]
%  Built from 151,420 ANL data points across 4 training files.
%  Holdout validation: US06 +0.5%, WLTP +3.2% motor energy error.
loss_map_file = fullfile(fileparts(mfilename('fullpath')), ...
                         '..', 'data', 'BoltEV_loss_map.mat');
if exist(loss_map_file, 'file')
    LM = load(loss_map_file);
    P.motor.T_grid   = LM.T_grid_Nm;     % [Nm] torque breakpoints
    P.motor.n_grid   = LM.n_grid_rpm;    % [rpm] speed breakpoints
    P.motor.P_loss   = LM.P_loss_W;      % [W]  loss map (T x n)
    fprintf('  Loss map loaded: %d x %d grid\n', ...
            length(P.motor.T_grid), length(P.motor.n_grid));
else
    warning('AE_BoltEV_LMDI_Params:noLossMap', ...
            'BoltEV_loss_map.mat not found at %s', loss_map_file);
end

% ----- High-voltage system: Bolt EV 60 kWh LG Chem pouch pack --------
%  Pack voltage levels (96s, LG Chem pouch):
%    V_max   = 96 x 4.15 = 398 V (fully charged)
%    V_nom   = 96 x 3.65 = 350 V (nominal)
%    V_oc    = 380 V              (Hioki measured avg, 61911008 cruise)
%    Range in ANL TDMS: 324-387 V
%
%  For the CRG FW boundary, V_dc = 350 V (nominal) is used.
%  At cruise (40A): omega_base = 2189 rad/s, v_FW = 88.4 km/h.
%  All five cycles exceed v_FW (unlike Tesla where only WLTP/US06 do).
P.batt.Vnom   = 400;          % [V] Simscape block voltage (near V_max)
P.batt.V_dc   = 350;          % [V] nominal DC link for CRG calc
P.batt.V1     = 310;          % [E] discharge curve knee [V]
P.batt.Cdc    = 0.001;        % [E] DC-link capacitor [F]
P.batt.kWh    = 60;           % [V] usable pack capacity [kWh]  EPA cert
P.batt.Ah     = 60e3 / 350;   % [D] ~171.4 Ah (at V_nom = 350 V)
P.batt.SOC0   = 95;           % [V] initial SOC [%]  ANL test start
P.batt.Rint   = 0.05;         % [E] pack internal resistance [Ohm]

% ----- Vehicle (Bolt EV 2019, Allca-Pekarovic 2024 + ANL TDMS) --------
P.veh.mass    = 1705;         % [V] test mass [kg]  Allca-Pekarovic (1625+80)
P.veh.rw      = 0.317;        % [V] tyre rolling radius [m]  data-derived from
                               %     Motor_1_speed vs Vehicle_spd_CAN (std=0.0002m)
P.veh.A       = 2.37;         % [E] frontal area [m^2]  (approx from vehicle dims)
%
% Road load from Allca-Pekarovic 2024 Table III (SI units):
%   F = 126.3 + 2.008 v + 0.4336 v^2  [N],  v in m/s
%
% Coastdown verification: steady-state torque balance at two speeds
%   55 mph (61911008, 430s): CAN torque -5.7% vs predicted (CAN tolerance)
%   65 mph (61910022 SSS):   CAN torque -6.6% vs predicted (CAN tolerance)
%   Systematic -6% offset consistent with CAN motor torque accuracy.
%   Road load LOCKED.
%
% Effective coefficients for driver feedforward and LMDI:
P.veh.Crr     = 126.3 / (1705 * 9.81);  % [D] = 0.00755
P.veh.Cd      = 2 * 0.4336 / (1.225 * 2.37);  % [D] = 0.2986
%
% Road load verification:
%   v = 10 m/s: F = 190 N
%   v = 20 m/s: F = 340 N
%   v = 30 m/s: F = 556 N
%
P.veh.A_rl    = 126.3;        % [V] constant term [N]           Allca-Pekarovic 2024
P.veh.B_rl    = 2.008;        % [V] speed-proportional [N.s/m]  Allca-Pekarovic 2024
P.veh.C_rl    = 0.4336;       % [V] aerodynamic [N.s^2/m^2]     Allca-Pekarovic 2024

% ----- Drivetrain (Patel 2025 teardown, ANL TDMS verified) ------------
P.gear.ratio  = 7.05;         % [V] final drive (35/73 x 21/71)  TDMS: Axle/Motor=7.05
P.gear.eff    = 0.972;        % [V] gearbox efficiency            CAN torque vs dyno

% ----- Environment ----------------------------------------------------
P.env.rho_air     = 1.225;    % [V] air density [kg/m^3]        ISO 2533
P.env.T_ambient   = 20;       % [V] ambient temperature [C]
P.env.g           = 9.81;     % [V] gravitational acceleration [m/s^2]

% ----- Control / PWM --------------------------------------------------
P.ctrl.Ts     = 5e-6;         % [E] fundamental sample time [s]
P.ctrl.fsw    = 2e3;          % [E] PWM switching frequency [Hz] (2 kHz for sim speed; energy unaffected)
P.ctrl.Tsi    = 1e-4;         % [E] current-loop sample time [s]

% Current-controller PI gains (IMC method, omega_bw = f_sw/10 * 2pi)
omega_bw      = 2*pi * P.ctrl.fsw / 10;   % 6283.2 rad/s
P.ctrl.Kp_id  = omega_bw * P.motor.Ld;    % d-axis P gain
P.ctrl.Ki_id  = omega_bw * P.motor.Rs;    % d-axis I gain
P.ctrl.Kp_iq  = omega_bw * P.motor.Lq;    % q-axis P gain
P.ctrl.Ki_iq  = omega_bw * P.motor.Rs;    % q-axis I gain

% ----- Driver (to be tuned during Phase 4 validation) -----------------
%  Initial gains from Tesla model; will need adjustment for lighter
%  vehicle with lower gear ratio (faster speed response).
P.driver.Kp   = 400;          % proportional gain
P.driver.Ki   = 80;           % integral gain
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
LdmLq = Ld - Lq;

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
brake_force_max = 16000;   % [N]  max friction brake (~0.95g at 1705 kg)

%% Zero-cancellation transfer functions (for FOC controller)
numd_id = Tsi / (Kp_id / Ki_id);
dend_id = [1   (Tsi - (Kp_id/Ki_id)) / (Kp_id/Ki_id)];
numd_iq = Tsi / (Kp_iq / Ki_iq);
dend_iq = [1   (Tsi - (Kp_iq/Ki_iq)) / (Kp_iq/Ki_iq)];

% Road load flat variables (for Simulink Fcn blocks, which can't access structs)
A_rl = P.veh.A_rl;   % constant term [N]
B_rl = P.veh.B_rl;   % speed-proportional [N.s/m]
C_rl = P.veh.C_rl;   % aerodynamic [N.s^2/m^2]

% Vehicle flat variables
M_veh   = P.veh.mass;    % test mass [kg]
rw      = P.veh.rw;      % wheel radius [m]

%% =====================================================================
%  3) TORQUE ENVELOPE AND LOSS MAP LOOKUP
%  =====================================================================

% Torque-speed envelope (Bolt EV, from Patel FEA + GM spec)
% Full torque to ~3500 rpm, then power-limited above rated speed.
RPM_env  = [0, 1, 3500, 4400, 5000, 5500, 6000, 6500, 7000, 7500, 8000, 8800];
Tmax_env = [360, 360, 360, 325, 286, 260, 238, 220, 204, 191, 179, 162];

% Motor electrical power: P_elec = T * omega_m + P_loss(T, n)
% The Simscape IPMSM block computes copper and iron losses internally.
% The loss map is retained for post-processing cross-checks.
if isfield(P.motor, 'P_loss')
    T_loss_bp   = P.motor.T_grid;    % breakpoints for Simulink lookup
    n_loss_bp   = P.motor.n_grid;
    P_loss_map  = P.motor.P_loss;    % 2D loss matrix (total, kept for
                                      % backward compatibility / cross-checks)
end

% ----- Copper/iron loss decomposition + real motor current (2020 ANL) --
%  Improvement: give the Bolt EV genuine motor presence/operation
%  (real measured stator current + physics-based copper loss), matching
%  the Tesla model's P_cu/P_fe architecture, instead of a single opaque
%  total-loss lookup. See BoltEV_2020_build_currentmap.m and
%  BoltEV_2020_finalize_motor_data.m for full derivation and provenance.
%    P_cu_map(T,n)   = 1.5*Rs*Is_map(T,n)^2   real, from 2020 ANL current data
%    P_iron_map(T,n) = P_loss_map - P_cu_map  residual (preserves validated
%                                              total energy: US06 +0.5%, WLTP +3.2%)
%    id_map/iq_map   = documented FW-visualization heuristic only, NOT used
%                      for loss or torque computation.
motor2020_file = fullfile(fileparts(mfilename('fullpath')), ...
                           '..', 'data', 'BoltEV_MotorData_2020_final.mat');
if exist(motor2020_file, 'file')
    MD2020 = load(motor2020_file);
    P_cu_map   = MD2020.P_cu_map;    % 2D copper loss matrix [W] (T_loss_bp x n_loss_bp)
    P_iron_map = MD2020.P_iron_map;  % 2D iron+stray loss matrix [W]
    Is_map     = MD2020.Is_map;      % 2D real stator current magnitude [A]
    id_map     = MD2020.id_map;      % 2D d-axis current heuristic [A] (viz only)
    iq_map     = MD2020.iq_map;      % 2D q-axis current heuristic [A] (viz only)
    recon_err  = max(abs(P_cu_map(:) + P_iron_map(:) - P_loss_map(:)));
    fprintf('  Motor 2020 data loaded: P_cu/P_iron decomposition (max recon err %.1f W)\n', recon_err);
else
    warning('AE_BoltEV_LMDI_Params:noMotor2020', ...
            'BoltEV_MotorData_2020_final.mat not found at %s. Run BoltEV_2020_build_currentmap.m and BoltEV_2020_finalize_motor_data.m first.', motor2020_file);
end

%% =====================================================================
%  3b) CURRENT-REFERENCE LOOKUP TABLES (MTPA + FIELD WEAKENING)
%  =====================================================================
%  BoltEV_CurrentRefs.mat    — id_table, iq_table, T_vec, rpm_vec (2D, 200x200)
%  BoltEV_CurrentRef_LUT.mat — ID_MAP, IQ_MAP, RPM_VECT, TQ_VECT, VDC_VECT (3D, 33x83x4)
%
%  Generated by BoltEV_generate_current_refs.m from constant Ld/Lq values.
%  Run that script first if .mat files do not exist.
lut_dir = fullfile(fileparts(mfilename('fullpath')), '..', 'data');
lut_2d  = fullfile(lut_dir, 'BoltEV_CurrentRefs.mat');
lut_3d  = fullfile(lut_dir, 'BoltEV_CurrentRef_LUT.mat');

if exist(lut_2d, 'file')
    load(lut_2d);
    fprintf('  Current refs loaded: BoltEV_CurrentRefs.mat (2D)\n');
else
    warning('AE_BoltEV_LMDI_Params:noLUT2D', ...
        'BoltEV_CurrentRefs.mat not found. Run BoltEV_generate_current_refs.m first.');
end

if exist(lut_3d, 'file')
    load(lut_3d);
    fprintf('  Current refs loaded: BoltEV_CurrentRef_LUT.mat (3D)\n');
else
    warning('AE_BoltEV_LMDI_Params:noLUT3D', ...
        'BoltEV_CurrentRef_LUT.mat not found. Run BoltEV_generate_current_refs.m first.');
end

%% Restore motor params that may have been overwritten by load
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
%  4) REGEN PARAMETERS (3-state D-mode)
%  =====================================================================
%
%  The Bolt EV uses D-mode one-pedal driving. The regen subsystem has
%  three states (see BoltEV_Implementation.md Section 9.3):
%
%  State 1 (traction): accel_cmd > 0 => T_regen = 0
%  State 2 (coast):    accel=0, brake=0, v > 1.4 m/s => T_regen = -30 Nm
%  State 3 (braking):  brake_cmd > 0 => T_regen = -0.60 x T_brake_total
%
%  No split-authority driver needed. PID handles traction; regen
%  subsystem applies fixed coast regen when PID output is zero.

% Coast regen (D-mode lift-off): measured from 794 US06 data points
% where accel_cmd = 0 and brake_pedal < 2%.
T_coast_regen_Nm = -30;       % [D] constant coast regen torque [Nm]
regen_minSpeed   = 1.39;      % [V] low-speed regen cutoff [m/s] (5 km/h)

% Brake regen share: fraction of total brake torque delivered by motor
% Estimated from ANL brake pedal vs motor torque data:
%   5-15% pedal gives 67-88 Nm regen out of ~150 Nm total braking
brake_regen_share = 0.60;     % [E] initial value from measurement

% Maximum regen power (battery charging limit)
P_regen_max    = 50e3;        % [W] max regen power at battery terminals
P_regen_mech   = 50e3;        % [W] mechanical power cap

% regen_fraction: fraction of available brake force delivered by motor regen.
% Used by the Simscape Regen_Braking subsystem.
regen_fraction = 0.60;

% coast_regen_N: set to zero. Coast regen is handled by the 3-state
% OnePedal_Regen subsystem or lift-off regen (below).
coast_regen_N  = 0;

% ----- Lift-off regen (torque domain, compatible with Tesla architecture) --
% Rule-based one-pedal driving: when accel is released and no brake demand,
% a fixed regen torque equivalent to coast deceleration is applied.
T_liftoff_Nm = abs(T_coast_regen_Nm);  % 30 Nm (from measured coast regen)
liftoff_on_thresh  = 0.005;  % regen engages when AccelCmd <= this
liftoff_off_thresh = 0.02;   % regen disengages when AccelCmd >= this
T_liftoff_slew     = 1000;   % [Nm/s] engagement/release rate limit

% Regen power cap LUT (speed-dependent ceiling on regen torque)
spd_bp = [0 1.38 1.39 2 5 10 15 20 25 30 40 50 60 70 80];
Regen_PowerCap_BP    = spd_bp;
Regen_PowerCap_Table = [0 0 ...
    P_regen_mech./spd_bp(3:end)];

%% =====================================================================
%  5) CRG FIELD-WEAKENING BOUNDARY (regime classifier)
%  =====================================================================
%
%  The CRG boundary is independent of the Simscape motor block.
%  It uses psi_m and k_Vmax (both validated) to compute the base speed
%  at each torque level. The regime classifier operates post-simulation
%  on the (torque, speed) trajectory.
%
%  At cruise (40A, 24 Nm):  v_FW = 88.4 km/h, n_base = 5214 rpm
%  At rated (300A, 196 Nm): v_FW = 67.0 km/h, n_base = 3951 rpm
%  90% CI: +/-4.5 km/h (Monte Carlo, 10,000 samples)
%
%  All five drive cycles exceed v_FW at cruise, unlike Tesla where
%  only WLTP and US06 enter FW.
P.crg.psim    = P.motor.psim;  % 0.1017 Wb
P.crg.kVmax   = P.motor.kVmax; % 0.904
P.crg.p       = P.motor.p;     % 4
P.crg.V_dc    = P.batt.V_dc;   % 350 V

%% =====================================================================
%  6) BMS-LEVEL PARAMETERS
%  =====================================================================
% These define the battery-to-motor power offset for BMS validation.
P_aux_W    = 155;       % [W] constant auxiliary load [W]
                        %     ANL Hioki DCDC_In_Power_Hioki_P2__W, test 62009019
                        %     mean ~155W across all phases (AC/heaters off)
                        %     Corrected from 300W (undocumented), 24 Jul 2026
V_oc       = 380;       % [D] battery OCV (Hioki avg, 61911008 cruise)
R_int_ohm  = 0.050;     % [E] pack internal resistance [Ohm]
R_cable    = 0;         % [D] cable resistance [Ohm]
                        %     Measured 1.7 mOhm (4.7 W, negligible)
                        %     0.7 V Hioki-CAN offset is ADC bias, not resistive

%% =====================================================================
%  6b) IRON LOSS PARAMETERS (Simscape IPMSM empirical model)
%  =====================================================================
% Iron loss: DISABLED for initial validation.
% The Bolt motor has limited open-circuit and short-circuit loss data.
% Once BMS-level validation passes, iron losses can be estimated from
% the ANL loss map residuals (total loss - copper loss = iron + stray).
losses_oc  = [0, 0, 0];       % [W] OC [P_h, P_e, P_x] at f_losses
losses_sc  = [0, 0, 0];       % [W] SC [P_h, P_e, P_x] at f_losses
f_losses   = 200;             % [Hz] reference electrical freq
Isc_losses = 400;             % [A] RMS phase current for SC loss

%% =====================================================================
%  7) ANL VALIDATION TARGETS (net Wh/km from Hioki WP1 bag data)
%  =====================================================================
%  Primary source: 2020 Bolt EV, ANL test 62009019 (23-25C, SOC 97.3%)
%  Hioki WP1 (500A) battery terminal power, bag-level Wh/mi -> Wh/km.
%  Same powertrain as 2019 (motor, battery, gear ratio unchanged MY20).
%  2019 cross-check in parentheses for traceability.
P.val.UDDS_Whkm   = 101.9;   % 2020 ANL 62009019 warm UDDS Hioki WP1=101.88, corrected 24 Jul 2026
P.val.HWFET_Whkm  = 125.2;   % 2020 ANL 62009019 HWY1 (2019: 123.0, delta +1.8%)
P.val.US06_Whkm   = 167.8;   % 2020 ANL 62009019 US06 combined (2019: 176.4, delta -4.9%)
P.val.WLTP_Whkm   = 136.3;   % 2019 ANL 61911001 WLTP x2 avg (no 2020 WLTP data)
P.val.gate_pct     = 5.0;     % +/-5% pass/fail gate

%% =====================================================================
%  8) UNCERTAINTY QUANTIFICATION METADATA
%  =====================================================================
uq = struct([]);

% Vehicle
uq(end+1).field='veh.mass'; uq(end).baseline=P.veh.mass;
  uq(end).dist='TruncatedNormal'; uq(end).cov=0.03;
  uq(end).range=[]; uq(end).trunc=P.veh.mass*[1-0.09 1+0.09];
  uq(end).tier='V'; uq(end).source='Allca-Pekarovic 2024';

uq(end+1).field='veh.Cd'; uq(end).baseline=P.veh.Cd;
  uq(end).dist='TruncatedNormal'; uq(end).cov=0.10;
  uq(end).range=[]; uq(end).trunc=P.veh.Cd*[1-0.30 1+0.30];
  uq(end).tier='D'; uq(end).source='Derived from Allca-Pekarovic C_rl';

uq(end+1).field='veh.Crr'; uq(end).baseline=P.veh.Crr;
  uq(end).dist='TruncatedNormal'; uq(end).cov=0.15;
  uq(end).range=[]; uq(end).trunc=[0.003 0.020];
  uq(end).tier='D'; uq(end).source='Derived from Allca-Pekarovic A_rl';

uq(end+1).field='veh.rw'; uq(end).baseline=P.veh.rw;
  uq(end).dist='Uniform'; uq(end).cov=NaN;
  uq(end).range=P.veh.rw*[1-0.02 1+0.02]; uq(end).trunc=[];
  uq(end).tier='V'; uq(end).source='CAN speed cross-check (std=0.0002m)';

% Battery
uq(end+1).field='batt.kWh'; uq(end).baseline=P.batt.kWh;
  uq(end).dist='TruncatedNormal'; uq(end).cov=0.03;
  uq(end).range=[]; uq(end).trunc=P.batt.kWh*[0.90 1.10];
  uq(end).tier='V'; uq(end).source='EPA cert';

uq(end+1).field='batt.Rint'; uq(end).baseline=P.batt.Rint;
  uq(end).dist='Lognormal'; uq(end).cov=0.20;
  uq(end).range=[]; uq(end).trunc=[];
  uq(end).tier='E'; uq(end).source='Typical LG Chem pouch';

% Drivetrain
uq(end+1).field='gear.eff'; uq(end).baseline=P.gear.eff;
  uq(end).dist='TruncatedNormal'; uq(end).cov=0.01;
  uq(end).range=[]; uq(end).trunc=[0.93 0.99];
  uq(end).tier='V'; uq(end).source='CAN torque vs dyno cross-check';

% Environment
uq(end+1).field='env.rho_air'; uq(end).baseline=P.env.rho_air;
  uq(end).dist='Uniform'; uq(end).cov=NaN;
  uq(end).range=[1.15 1.30]; uq(end).trunc=[];
  uq(end).tier='V'; uq(end).source='ISO 2533';

P.uq = uq;

%% =====================================================================
%  9) SANITY CHECK
%  =====================================================================
for k = 1:numel(P.uq)
    v_live = local_getfield(P, P.uq(k).field);
    v_base = P.uq(k).baseline;
    if abs(v_live - v_base) > 1e-12 * max(1, abs(v_live))
        error('AE_BoltEV_LMDI_Params:baselineMismatch', ...
              'P.uq(%d) field ''%s'': baseline %.6g != live value %.6g', ...
              k, P.uq(k).field, v_base, v_live);
    end
end

% CRG boundary sanity: v_FW at cruise
% M1 (back-EMF limit, no kVmax): omega_e = V_dc / (sqrt(3) * psim)
% This gives a conservative lower bound. The full CRG (M3) at cruise
% gives 88.4 km/h because kVmax provides additional voltage headroom.
omega_e_M1 = P.crg.V_dc / (sqrt(3) * P.crg.psim);
omega_m_M1 = omega_e_M1 / P.crg.p;
v_FW_M1 = omega_m_M1 * P.veh.rw / P.gear.ratio * 3.6;  % km/h
v_FW_CRG_cruise = 88.4;  % [km/h] from full CRG calculation (see Section 3.2)

fprintf(['AE_BoltEV_LMDI_Params loaded.\n' ...
         '  Motor: p=%d, Rs=%.5f Ohm, psim=%.4f Wb, kVmax=%.3f\n' ...
         '  Pack:  %d V / %d kWh  Gear: %.2f:1 (eta=%.3f)\n' ...
         '  Road:  F = %.1f + %.3f v + %.4f v^2 [N]\n' ...
         '  CRG:   v_FW(M1) = %.1f km/h, v_FW(CRG,cruise) = %.1f km/h\n' ...
         '  BMS:   P_aux=%d W, R_cable=%.0f mOhm\n' ...
         '  UQ:    %d uncertain parameters\n'], ...
    P.motor.p, P.motor.Rs, P.motor.psim, P.motor.kVmax, ...
    P.batt.V_dc, P.batt.kWh, P.gear.ratio, P.gear.eff, ...
    P.veh.A_rl, P.veh.B_rl, P.veh.C_rl, ...
    v_FW_M1, v_FW_CRG_cruise, ...
    P_aux_W, R_cable*1000, ...
    numel(P.uq));

%% =====================================================================
%  10) APPLY BLOCK PARAMETERS TO MODEL (if open)
%  =====================================================================
try
    mdl_name = 'AE_BoltEV_LMDI';

    % --- Driver ---
    drv = [mdl_name '/Longitudinal_Driver/Longitudinal Driver'];
    set_param(drv, 'Kp',       num2str(P.driver.Kp));
    set_param(drv, 'Ki',       num2str(P.driver.Ki));
    set_param(drv, 'Kff',      num2str(P.driver.Kff));
    set_param(drv, 'aMode',    '2');
    set_param(drv, 'VehVelVec','[0 15 30 100]');
    set_param(drv, 'KpVec',    mat2str([P.driver.Kp P.driver.Kp 200 200]));
    set_param(drv, 'KiVec',    mat2str([P.driver.Ki P.driver.Ki 40 40]));

    aR_driver = round(P.veh.mass * P.env.g * P.veh.Crr);
    cR_driver = 0.5 * P.env.rho_air * P.veh.Cd * P.veh.A;
    set_param(drv, 'aR',   num2str(aR_driver));
    set_param(drv, 'bR',   '0');
    set_param(drv, 'cR',   num2str(cR_driver));
    set_param(drv, 'tauPt','0.2');
    set_param(drv, 'Kaw',  '5');

    % --- IPMSM block (Simscape Electrical, masked block) ---
    % Correct mask parameter names (discovered via get_param inspection):
    %   nPolePairs, Rs, pm_flux_linkage, LdMatrix, LqMatrix
    % Scalar params (p, Rs, psim) also work via workspace variables.
    % LdMatrix/LqMatrix are 3x3 matrices (constant Ld/Lq mode).
    ipmsm_blk = [mdl_name '/IPMSM'];
    try
        set_param(ipmsm_blk, 'nPolePairs',      num2str(P.motor.p));
        set_param(ipmsm_blk, 'Rs',              num2str(P.motor.Rs));
        set_param(ipmsm_blk, 'pm_flux_linkage', num2str(P.motor.psim));
        set_param(ipmsm_blk, 'LdMatrix', ...
            sprintf('%.6f * ones(3, 3)', P.motor.Ld));
        set_param(ipmsm_blk, 'LqMatrix', ...
            sprintf('%.6f * ones(3, 3)', P.motor.Lq));
    catch ME
        fprintf('  [WARN] IPMSM set_param: %s\n', ME.message);
    end

    % --- Iron loss (disabled for initial validation) ---
    try
        set_param(ipmsm_blk, 'loss_param',  'ee.enum.ironloss.none');
    catch, end

    % --- Torque envelope ---
    try
        set_param([mdl_name '/Torque_Envelope/Tq_Envelope'], ...
                  'Table',                   mat2str(Tmax_env));
        set_param([mdl_name '/Torque_Envelope/Tq_Envelope'], ...
                  'BreakpointsForDimension1', mat2str(RPM_env));
    catch, end

    % --- Vehicle block ---
    veh_paths = {
        [mdl_name '/Vehicle_Dynamics/Longitudinal Vehicle']
        [mdl_name '/Longitudinal Vehicle']
        [mdl_name '/Vehicle/Longitudinal Vehicle']
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
        warning('AE_BoltEV_LMDI_Params: Vehicle block not found.');
    end

    % --- Gear block ---
    gear_blk = [mdl_name '/Vehicle_Dynamics/Simple Gear'];
    try
        set_param(gear_blk, 'ratio', num2str(P.gear.ratio));
        set_param(gear_blk, 'mu_visc',  '[0 0]');
        set_param(gear_blk, 'T_noload', '0');
    catch, end

    % --- Regen braking ---
    try
        set_param([mdl_name '/Regen_Braking/BrakeForce_Total'], ...
                  'Gain', 'brake_force_max');
    catch, end

    % --- Road load Fcn block (external application via brake port) ---
    % The Simscape Longitudinal Vehicle block has C_tireroll and C_airdrag
    % set to 1e-6. Road load is applied externally via RoadLoad_v21 Fcn
    % block inside Vehicle_Dynamics, which feeds BrakeSum_v21 -> PS_Conv_brake
    % -> Longitudinal Vehicle R port.
    try
        rl_expr = sprintf('%.1f + %.3f*u + %.4f*u^2', ...
            P.veh.A_rl, P.veh.B_rl, P.veh.C_rl);
        set_param([mdl_name '/Vehicle_Dynamics/RoadLoad_v21'], 'Expr', rl_expr);
    catch, end

    % Save so that compile-time parameters are baked into the .slx
    save_system(mdl_name);
    fprintf('  AE_BoltEV_LMDI_Params: block parameters applied and saved.\n');

catch
    % Model not open; workspace variables are ready for when it is opened
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
