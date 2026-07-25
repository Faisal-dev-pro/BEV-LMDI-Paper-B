function onepedal_regen_bolt(block)
%ONEPEDAL_REGEN_BOLT  3-state regenerative braking (Level-2 S-Function)
%
%  Bolt EV D-mode one-pedal driving with three distinct states:
%    State 1 (traction): a_ref >= -0.1 m/s^2 => T_regen = 0
%    State 2 (coast):    -1.0 < a_ref < -0.1  => T_regen = T_coast (-30 Nm)
%    State 3 (braking):  a_ref <= -1.0         => physics-based regen,
%                         capped at brake_regen_share (0.60) of total braking
%
%  Input:  RefSpd [m/s] — reference speed from Drive Cycle Source
%  Output: T_regen [Nm] — motor shaft torque (negative or zero)
%
%  All vehicle parameters read from base workspace via evalin('base',...).
%  Parameters sourced from AE_BoltEV_LMDI_Params.m:
%    A_rl, B_rl, C_rl      — Allca-Pekarovic 2024 road load [N]
%    M_veh                  — test mass [kg]
%    rw                     — wheel radius [m]
%    gear_ratio             — final drive ratio [-]
%    T_coast_regen_Nm       — coast regen torque [Nm] (-30)
%    brake_regen_share      — fraction of brake torque as regen (0.60)
%    regen_minSpeed         — low-speed cutoff [m/s] (1.39)
%    P_regen_max            — max regen power [W] (50 kW)
%
%  Author: F. Shah Khan, University of East London, July 2026
% -------------------------------------------------------------------------

    setup(block);
end

%% ========================================================================
function setup(block)
    block.NumDialogPrms = 0;

    % Input: reference speed [m/s]
    block.NumInputPorts  = 1;
    block.InputPort(1).Dimensions        = 1;
    block.InputPort(1).DirectFeedthrough  = true;
    block.InputPort(1).SamplingMode       = 'Sample';

    % Output: regen torque [Nm]
    block.NumOutputPorts = 1;
    block.OutputPort(1).Dimensions   = 1;
    block.OutputPort(1).SamplingMode = 'Sample';

    % 10 Hz discrete (matches drive cycle resolution)
    block.SampleTimes = [0.1 0];

    block.RegBlockMethod('PostPropagationSetup', @DoPostPropSetup);
    block.RegBlockMethod('InitializeConditions', @InitConditions);
    block.RegBlockMethod('Outputs',              @Output);
end

%% ========================================================================
function DoPostPropSetup(block)
    % Dwork: previous speed for discrete derivative
    block.NumDworks = 1;
    block.Dwork(1).Name       = 'v_prev';
    block.Dwork(1).Dimensions = 1;
    block.Dwork(1).DatatypeID = 0;       % double
    block.Dwork(1).Complexity = 'Real';
end

%% ========================================================================
function InitConditions(block)
    block.Dwork(1).Data = 0;
end

%% ========================================================================
function Output(block)
    v_ref  = block.InputPort(1).Data;
    v_prev = block.Dwork(1).Data;
    dt     = 0.1;   % [s] sample period

    % ---- Discrete derivative of reference speed ----
    a_ref = (v_ref - v_prev) / dt;
    block.Dwork(1).Data = v_ref;

    % ---- Read vehicle parameters from base workspace ----
    A   = evalin('base', 'A_rl');            % [N]
    B   = evalin('base', 'B_rl');            % [N/(m/s)]
    C   = evalin('base', 'C_rl');            % [N/(m/s)^2]
    m   = evalin('base', 'M_veh');           % [kg]
    r   = evalin('base', 'rw');              % [m]
    gr  = evalin('base', 'gear_ratio');      % [-]
    T_coast     = evalin('base', 'T_coast_regen_Nm');    % [Nm] (-30)
    brake_share = evalin('base', 'brake_regen_share');   % [-]  (0.60)
    v_min       = evalin('base', 'regen_minSpeed');      % [m/s] (1.39)
    P_max       = evalin('base', 'P_regen_max');         % [W]  (50e3)

    m_eff = m * 1.04;   % 4% rotational inertia correction

    % ---- Motor speed (feedforward from reference) ----
    omega_m = v_ref * gr / r;

    % ---- 3-state regen logic ----
    T_regen = 0;

    if v_ref < v_min
        % Below cutoff speed: no regen
        T_regen = 0;

    elseif a_ref >= -0.1
        % State 1 (traction / cruise): no regen
        T_regen = 0;

    elseif a_ref > -1.0
        % State 2 (coast): fixed coast regen
        T_regen = T_coast;   % -30 Nm

    else
        % State 3 (braking): physics-based regen
        % Road load at current speed
        F_road = A + B * v_ref + C * v_ref^2;

        % Total required motor torque for deceleration
        T_required = (m_eff * a_ref + F_road) * r / gr;

        % Cap at brake_regen_share of total braking torque
        T_brake_total = m_eff * abs(a_ref) * r / gr;
        T_regen_limit = -brake_share * T_brake_total;

        % Use the less negative value (smaller magnitude)
        T_regen = max(T_required, T_regen_limit);

        % Ensure negative (regen only)
        T_regen = min(T_regen, 0);
    end

    % ---- Power limit ----
    if omega_m > 0 && T_regen < 0
        T_power_limit = -P_max / omega_m;
        T_regen = max(T_regen, T_power_limit);
    end

    block.OutputPort(1).Data = T_regen;
end
