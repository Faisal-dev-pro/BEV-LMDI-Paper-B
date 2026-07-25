%% ============================================================================
%  ANL_Model_Initialization.m
%
%  Tesla Model 3 BEV Powertrain Model — Parameter & Validation Setup
%
%  Purpose: Load all motor, vehicle, and validation parameters from ANL
%           dynamometer data in a single execution. Supports Paper A validation.
%
%  v26 UPDATE (July 2026):
%    - Road load coefficients re-extracted from three independent coastdown
%      runs in ANL test 62005005 (Savitzky-Golay smoothed deceleration).
%    - Motor P_max corrected to 188 kW (ANL D3 test record).
%    - Crr and Cd derived from v26 coastdown coefficients.
%    - Base speed formula corrected (sqrt(3) phase voltage factor).
%    - All values cross-checked against AE_TeslaM3_LMDI_Params.m.
%
%  Author: Faisal Shah Khan, University of East London
%  Date: June 2026 (updated July 2026)
%
%  Usage:
%    >> ANL_Model_Initialization
%    >> disp(validation_summary)
%
% ============================================================================
clear all; close all; clc;
fprintf('\n%s\n', repmat('=',1,80));
fprintf('  ANL MODEL INITIALIZATION — TESLA MODEL 3 BEV POWERTRAIN\n');
fprintf('%s\n\n', repmat('=',1,80));
%% ============================================================================
%  SECTION 1: MOTOR PARAMETERS (MotorXP teardown + ANL validation)
%  ============================================================================
fprintf('[1] Loading motor parameters...\n');
% Electrical parameters (MotorXP teardown, June 2020)
motor.Rs    = 0.00475;    % Stator resistance @ 20°C [Ohm]
motor.psi_m = 0.07719;   % PM flux linkage [Wb]
motor.Ld    = 0.000125;  % d-axis inductance [H]  (ANL fitted, 2.7% RMS error)
motor.Lq    = 0.000244;  % q-axis inductance [H]  (ANL fitted, 2.7% RMS error)
motor.p     = 3;         % Pole pairs [-]
motor.I_max = 953;       % Peak continuous current [A]
motor.P_max = 188e3;     % Peak power output [W]  (ANL D3 test record)
% Temperature dependency
motor.Rs_coeff = 0.00393; % Temperature coefficient [1/°C] (copper)
motor.T_ref    = 20;      % Reference temperature [°C]
% Voltage and control limits
motor.k_Vmax   = 1.10;   % Voltage modulation margin (SVM safety margin, CRG-confirmed)
motor.V_dc_nom = 370;    % DC link operating voltage [V] (ANL CAN, phases 4-7 avg)
% Efficiency parameters
motor.eta_peak    = 0.96; % Peak motor efficiency [-]
motor.eta_nominal = 0.95; % Nominal operating efficiency [-]
% Field-weakening parameters (derived from psi_m and Ld/Lq)
motor.I_ch         = motor.psi_m / (motor.Lq * motor.I_max);
% Base speed: simplified M1 estimate (back-EMF limit with SVM margin).
%   V_phase_max = V_dc / (sqrt(3) * k_Vmax)
%   omega_e     = V_phase_max / psi_m
%   n_mech      = omega_e / p * 60 / (2*pi)
% This gives ~8009 RPM. The CRG-derived value (906 rad/s = 8651 RPM) is
% higher because it accounts for the MTPA operating point and saliency.
% The CRG value is used in simulation (AE_TeslaM3_LMDI_Params.m).
motor.n_base_rpm = (motor.V_dc_nom / (sqrt(3) * motor.k_Vmax)) ...
                   / (2*pi*motor.psi_m/60) / motor.p;
motor.base_speed_rpm   = motor.n_base_rpm;  % RPM at which FW begins (M1 estimate)
motor.omega_base_CRG   = 906;               % [rad/s] CRG-derived (authoritative)
motor.base_speed_CRG_rpm = motor.omega_base_CRG * 60 / (2*pi);  % 8651 RPM
fprintf('  R_s = %.5f Ohm (@ 20 degC)\n', motor.Rs);
fprintf('  psi_m = %.5f Wb\n', motor.psi_m);
fprintf('  L_d = %.6f H, L_q = %.6f H (saliency ratio = %.2f)\n', ...
    motor.Ld, motor.Lq, motor.Lq/motor.Ld);
fprintf('  I_max = %d A, P_max = %.0f kW\n', motor.I_max, motor.P_max/1e3);
fprintf('  Base speed (M1 estimate) = %.0f RPM\n', motor.base_speed_rpm);
fprintf('  Base speed (CRG, authoritative) = %.0f RPM (%.0f rad/s)\n\n', ...
    motor.base_speed_CRG_rpm, motor.omega_base_CRG);
%% ============================================================================
%  SECTION 2: VEHICLE & DRIVETRAIN PARAMETERS (ANL test vehicle)
%  ============================================================================
fprintf('[2] Loading vehicle parameters...\n');
% Vehicle mass (per ANL test specification)
vehicle.mass_kerb = 1847;  % Kerb mass [kg]
vehicle.mass_test = 1928;  % Test mass (with driver + instrumentation) [kg]
vehicle.mass_used = 1928;  % Mass used in simulation
% Drivetrain
vehicle.gear_ratio      = 9.04;  % Single-speed reducer final drive [-]
vehicle.gear_efficiency = 0.97;  % Gear mechanical efficiency [-]
vehicle.wheel_radius    = 0.326; % Loaded radius (235/45R18) [m]
% Aerodynamics (v26: Cd derived from coastdown C_rl)
vehicle.Cd      = 0.2317;  % Drag coefficient [-] (= 2*C_rl / (rho*A))
vehicle.Af      = 2.22;    % Frontal area [m^2]
vehicle.rho_air = 1.225;   % Air density (sea level, 15 degC) [kg/m^3]
% Rolling resistance (v26: from ANL coastdown test 62005005, 3-run avg)
vehicle.Crr = 0.00857;  % Rolling resistance coefficient [-] (= A_rl / (m*g))
% Tyre specifications
vehicle.tire_size       = '235/45R18'; % OEM fitment
vehicle.tire_load_index = 101;         % Max load per tyre [x 325 kg]
fprintf('  Mass (test) = %d kg\n', vehicle.mass_test);
fprintf('  Gear ratio = %.2f:1\n', vehicle.gear_ratio);
fprintf('  Wheel radius = %.3f m (%s)\n', vehicle.wheel_radius, vehicle.tire_size);
fprintf('  Drag: C_d = %.4f, A_f = %.2f m2, C_d*A_f = %.3f m2\n', ...
    vehicle.Cd, vehicle.Af, vehicle.Cd * vehicle.Af);
fprintf('  Rolling resistance: C_rr = %.5f\n\n', vehicle.Crr);
%% ============================================================================
%  SECTION 3: BATTERY PARAMETERS
%  ============================================================================
fprintf('[3] Loading battery parameters...\n');
battery.V_nominal        = 400;   % Nominal pack voltage [V] (96s x 4.2 V)
battery.V_oc             = 370;   % Open-circuit operating voltage [V] (ANL CAN avg)
battery.V_min            = 292;   % Minimum voltage observed in tests [V]
battery.V_max            = 345;   % Maximum voltage observed in tests [V]
battery.capacity_nominal = 75;    % Nominal capacity [kWh] (Tesla spec)
battery.capacity_Ah      = 203;   % Usable capacity [Ah] (75e3 / 370)
battery.Rint             = 0.05;  % Internal resistance (lumped) [Ohm]
battery.chemistry        = 'NCA'; % Cell chemistry (2170 format)
fprintf('  V_nominal = %d V, V_oc = %d V\n', battery.V_nominal, battery.V_oc);
fprintf('  Capacity = %.0f kWh (%.0f Ah)\n', battery.capacity_nominal, battery.capacity_Ah);
fprintf('  R_int = %.3f Ohm (lumped)\n\n', battery.Rint);
%% ============================================================================
%  SECTION 4: ROAD LOAD COEFFICIENTS (from ANL coastdown test 62005005)
%  ============================================================================
fprintf('[4] Loading road load model (ANL coastdown test 62005005)...\n');
% v26: Coefficients re-extracted from three independent coastdown runs
% using Savitzky-Golay smoothed deceleration.
%   CD1: A=161.69, B=0.520, C=0.3142
%   CD2: A=161.76, B=0.580, C=0.3152
%   CD3: A=162.36, B=0.578, C=0.3158
%   Combined 3-run average: A=162.0, B=0.552, C=0.315
%
% SI units (v in m/s):
%   F = 162.0 + 0.552*|v| + 0.315*v^2  [N]
%
% Verification (v26, ANL coastdown-derived):
%   v = 10 m/s: F_model = 199 N
%   v = 20 m/s: F_model = 299 N
%   v = 30 m/s: F_model = 462 N
roadload.A    = 162.0;            % Constant term [N]
roadload.B    = 0.1533;           % Linear coefficient [N/(km/h)]
roadload.C    = 0.02431;          % Quadratic coefficient [N/(km/h)^2]
roadload.B_SI = 0.552;            % SI: N*s/m  (= 0.1533 * 3.6)
roadload.C_SI = 0.315;            % SI: N*s^2/m^2  (= 0.02431 * 3.6^2)
% Verification at key speeds
speeds_verify_mph = [30, 50, 70];
speeds_verify_ms  = speeds_verify_mph * 0.44704;
F_verify = roadload.A + roadload.B_SI * speeds_verify_ms + roadload.C_SI * speeds_verify_ms.^2;
fprintf('  Road load (v26): F = %.1f + %.3f*v + %.3f*v^2  [N, v in m/s]\n', ...
    roadload.A, roadload.B_SI, roadload.C_SI);
fprintf('  Road load verification (SI coefficients):\n');
for i = 1:length(speeds_verify_mph)
    fprintf('    @ %d mph (%.1f m/s): F = %.0f N\n', ...
        speeds_verify_mph(i), speeds_verify_ms(i), F_verify(i));
end
fprintf('\n');
%% ============================================================================
%  SECTION 5: VALIDATION TARGETS (rear inverter WP4, from ANL tests)
%  ============================================================================
fprintf('[5] Loading validation targets from ANL dynamometer data...\n\n');
% ========== HWY CYCLES (Steady-State Cruising) ==========
fprintf('  [HWY] Steady-state baseline:\n');
% HWFET target: 9 warm HWY phases extracted from 7 ANL test sessions.
% Cold-start phases and partial HWY runs excluded (manuscript Table 4).
% Source sessions: 62005016, 62005018, 62006001, 62006032, 62006034, 62006039, 62006040.
validation.HWY.target_Wh_km   = 109.3;  % Mean of 9 warm phases, 7 sessions
validation.HWY.std_Wh_km      = 2.1;    % Sample std (manuscript Table 4)
validation.HWY.tolerance_pct  = round(100 * 2.1 / 109.3, 1);  % 1.9%, for summary table
validation.HWY.acceptance_range = [validation.HWY.target_Wh_km - validation.HWY.std_Wh_km, ...
                                    validation.HWY.target_Wh_km + validation.HWY.std_Wh_km];
validation.HWY.n_tests    = 9;   % Warm HWFET phases (9 phases from 7 sessions)
validation.HWY.n_sessions = 7;
validation.HWY.session_ids = {'62005016','62005018','62006001','62006032', ...
                               '62006034','62006039','62006040'};
fprintf('    Target: %.1f +/- %.1f Wh/km\n', validation.HWY.target_Wh_km, validation.HWY.std_Wh_km);
fprintf('    Acceptance: %.1f -- %.1f Wh/km\n', validation.HWY.acceptance_range(1), validation.HWY.acceptance_range(2));
fprintf('    N = %d warm phases from %d sessions, std = %.1f Wh/km\n\n', ...
    validation.HWY.n_tests, validation.HWY.n_sessions, validation.HWY.std_Wh_km);
% ========== US06 CYCLES (Aggressive Transient) ==========
fprintf('  [US06] Aggressive transient:\n');
validation.US06.target_Wh_km      = 132.5;  % Mean of 5 tests (WP4 net)
validation.US06.tolerance_pct      = 3.0;
validation.US06.tolerance_Wh_km    = validation.US06.target_Wh_km * validation.US06.tolerance_pct / 100;
validation.US06.acceptance_range   = [validation.US06.target_Wh_km - validation.US06.tolerance_Wh_km, ...
                                       validation.US06.target_Wh_km + validation.US06.tolerance_Wh_km];
validation.US06.regen_target_pct   = 39.0;   % Mean of 5 tests (energy-weighted = 39.0%)
validation.US06.regen_tolerance_pct = 3.0;
validation.US06.n_tests             = 5;  % Test 62006028 excluded (partial cycle)
us06_test_data = {
    '62005024', 12.47, 123.9, 42.6;
    '62006024', 12.48, 125.3, 42.1;
    '62006025', 12.49, 136.1, 37.0;
    '62006026', 12.49, 135.9, 37.1;
    '62006027', 12.49, 141.2, 36.3;
};
for i = 1:size(us06_test_data, 1)
    validation.US06.tests(i).id             = us06_test_data{i,1};
    validation.US06.tests(i).dist_km        = us06_test_data{i,2};
    validation.US06.tests(i).measured_Wh_km = us06_test_data{i,3};
    validation.US06.tests(i).regen_pct      = us06_test_data{i,4};
end
fprintf('    Target: %.1f +/- %.1f Wh/km\n', validation.US06.target_Wh_km, validation.US06.tolerance_Wh_km);
fprintf('    Regen target: %.1f +/- %.1f%%\n', validation.US06.regen_target_pct, validation.US06.regen_tolerance_pct);
fprintf('    Acceptance: %.1f -- %.1f Wh/km\n', validation.US06.acceptance_range(1), validation.US06.acceptance_range(2));
fprintf('    N = %d tests, std = 7.5 Wh/km\n\n', validation.US06.n_tests);
% ========== WLTP CYCLES (Mixed Urban-Highway) ==========
fprintf('  [WLTP] Mixed urban-highway:\n');
% Target is the standard full-cycle WLTP consumption from ANL (116.7 Wh/km).
% The 19 individual test runs below span multiple sub-cycles and partial runs
% (range 92-168 Wh/km, std 42 Wh/km); they are retained for reference and
% sub-phase analysis but the headline validation target is the full-cycle value.
validation.WLTP.target_Wh_km   = 116.7;
validation.WLTP.tolerance_pct   = 3.0;
validation.WLTP.tolerance_Wh_km = validation.WLTP.target_Wh_km * validation.WLTP.tolerance_pct / 100;
validation.WLTP.acceptance_range = [validation.WLTP.target_Wh_km - validation.WLTP.tolerance_Wh_km, ...
                                     validation.WLTP.target_Wh_km + validation.WLTP.tolerance_Wh_km];
validation.WLTP.n_tests = 19;
% Test 62005021 excluded: negative WP4 energy (instrumentation anomaly).
wltp_test_data = {
    '62005016', 5.79,  122.4, 28.5;
    '62005018', 12.92, 142.1, 57.9;
    '62005019', 35.42, 135.4,  3.5;
    '62006001', 5.79,  110.2, 34.9;
    '62006002', 3.09,   92.0, 43.2;
    '62006003', 12.92, 142.3, 31.5;
    '62006005', 5.79,  102.9, 35.9;
    '62006006', 5.79,  145.0, 25.3;
    '62006011', 12.92, 164.7, 53.7;
    '62006012', 19.29, 160.3,  4.2;
    '62006015', 5.79,  152.2, 25.5;
    '62006019', 12.92, 167.2, 53.3;
    '62006020', 28.43, 168.4,  2.9;
    '62006023', 12.92, 150.7, 29.6;
    '62006032', 5.79,  126.0, 26.5;
    '62006034', 12.92, 139.4, 58.6;
    '62006035', 43.85, 134.4,  2.6;
    '62006039', 5.79,  108.7, 35.2;
    '62006040', 5.78,  127.9, 25.4;
};
for i = 1:size(wltp_test_data, 1)
    validation.WLTP.tests(i).id             = wltp_test_data{i,1};
    validation.WLTP.tests(i).dist_km        = wltp_test_data{i,2};
    validation.WLTP.tests(i).measured_Wh_km = wltp_test_data{i,3};
    validation.WLTP.tests(i).regen_pct      = wltp_test_data{i,4};
end
fprintf('    Target (full cycle): %.1f +/- %.1f Wh/km\n', validation.WLTP.target_Wh_km, validation.WLTP.tolerance_Wh_km);
fprintf('    Acceptance: %.1f -- %.1f Wh/km\n', validation.WLTP.acceptance_range(1), validation.WLTP.acceptance_range(2));
fprintf('    N = %d test runs retained (mixed sub-cycles; range 92-168 Wh/km)\n\n', validation.WLTP.n_tests);
%% ============================================================================
%  SECTION 6: SUMMARY TABLE
%  ============================================================================
fprintf('%s\n', repmat('=',1,80));
fprintf('  VALIDATION SUMMARY TABLE\n');
fprintf('%s\n\n', repmat('=',1,80));
validation_summary = table();
validation_summary.Cycle        = {'HWY'; 'US06'; 'WLTP'};
validation_summary.N_tests      = [validation.HWY.n_tests; validation.US06.n_tests; validation.WLTP.n_tests];
validation_summary.Target_Wh_km = [validation.HWY.target_Wh_km; validation.US06.target_Wh_km; validation.WLTP.target_Wh_km];
validation_summary.Tolerance_pct = [validation.HWY.tolerance_pct; validation.US06.tolerance_pct; validation.WLTP.tolerance_pct];
validation_summary.Acceptance_Range = {
    sprintf('%.1f-%.1f', validation.HWY.acceptance_range(1),  validation.HWY.acceptance_range(2));
    sprintf('%.1f-%.1f', validation.US06.acceptance_range(1), validation.US06.acceptance_range(2));
    sprintf('%.1f-%.1f', validation.WLTP.acceptance_range(1), validation.WLTP.acceptance_range(2))};
validation_summary.Purpose = {'Baseline efficiency'; 'FOC & regen verification'; 'Cross-cycle decomposition'};
disp(validation_summary);
%% ============================================================================
%  SECTION 7: PARAMETER VERIFICATION
%  ============================================================================
fprintf('\n%s\n', repmat('=',1,80));
fprintf('  PARAMETER VERIFICATION\n');
fprintf('%s\n\n', repmat('=',1,80));
fprintf('Motor electrical parameters:\n');
fprintf('  L_q / L_d = %.2f (IPM-SynRM typical range: 1.8-2.2)\n', motor.Lq / motor.Ld);
fprintf('  Characteristic current ratio I_ch/I_max = %.3f\n', motor.I_ch);
fprintf('  Field-weakening entry (M1): n_base = %.0f RPM @ k_Vmax = %.2f\n', motor.base_speed_rpm, motor.k_Vmax);
fprintf('  Field-weakening entry (CRG): n_base = %.0f RPM (omega = %d rad/s)\n', motor.base_speed_CRG_rpm, motor.omega_base_CRG);
fprintf('\nVehicle parameters (ANL test vehicle):\n');
fprintf('  Rolling resistance C_rr = %.5f (ANL coastdown test 62005005, v26)\n', vehicle.Crr);
fprintf('  Drag: C_d = %.4f, A_f = %.2f m2, C_d*A_f = %.3f m2\n', vehicle.Cd, vehicle.Af, vehicle.Cd * vehicle.Af);
fprintf('  Gear efficiency eta_g = %.2f%% (single-speed reducer)\n', vehicle.gear_efficiency * 100);
fprintf('\nRoad load cross-check (v26 SI coefficients):\n');
v_check = [10, 20, 30];
for i = 1:length(v_check)
    F_check = roadload.A + roadload.B_SI * v_check(i) + roadload.C_SI * v_check(i)^2;
    fprintf('  v = %d m/s: F = %.0f N\n', v_check(i), F_check);
end
fprintf('\nValidation data coverage:\n');
fprintf('  HWY:  %d warm phases (%d sessions), std = %.1f Wh/km\n', ...
    validation.HWY.n_tests, validation.HWY.n_sessions, validation.HWY.std_Wh_km);
fprintf('  US06: %d tests, std = 7.5 Wh/km\n', validation.US06.n_tests);
fprintf('  WLTP: %d test runs, full-cycle target = 116.7 Wh/km\n', validation.WLTP.n_tests);
%% ============================================================================
%  SECTION 8: WORKSPACE READY
%  ============================================================================
fprintf('\n%s\n', repmat('=',1,80));
fprintf('  INITIALIZATION COMPLETE\n');
fprintf('%s\n\n', repmat('=',1,80));
fprintf('Workspace variables ready:\n');
fprintf('  motor.*            -- Motor parameters (MotorXP teardown + ANL fit)\n');
fprintf('  vehicle.*          -- Vehicle parameters (ANL D3 test vehicle)\n');
fprintf('  battery.*          -- Battery parameters (Tesla 75 kWh pack)\n');
fprintf('  roadload.*         -- Road load coefficients (ANL coastdown 62005005, v26)\n');
fprintf('  validation.*       -- Validation targets by cycle\n');
fprintf('  validation_summary -- Summary table\n\n');
fprintf('Next steps:\n');
fprintf('  1. Run AE_TeslaM3_LMDI_Params.m to load Simulink block parameters\n');
fprintf('  2. Open AE_TeslaM3_LMDI.slx and run v26 script for target cycle\n');
fprintf('  3. Compare BMS-level output to validation target\n');
fprintf('  4. Run AE_run_LMDI.m for LMDI decomposition\n\n');
fprintf('Reference:\n');
fprintf('  Motor: MotorXP teardown 2020 (IEEE ICEM 2022)\n');
fprintf('  Validation: ANL Suite D3 dynamometer (VIN 5YJ3E1EB5LF618578)\n');
fprintf('  Manuscript: Khan & Sutharssan, ECM:X, submitted July 2026\n\n');
fprintf('Timestamp: %s\n\n', datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
