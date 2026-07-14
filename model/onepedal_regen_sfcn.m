function onepedal_regen_sfcn(block)
%ONEPEDAL_REGEN_SFCN  One-pedal regenerative braking (Level-2 S-Function)
%
%  Computes feedforward regen torque from the Drive Cycle Source reference
%  speed. Uses reference speed (not actual vehicle speed) so there is no
%  feedback loop with the PID speed controller.
%
%  Input:  RefSpd [m/s] — reference speed from Drive Cycle Source
%  Output: T_regen [Nm] — motor shaft torque (negative during decel, zero
%                          during traction or standstill)
%
%  Physics:
%    1. Discrete derivative of reference speed at 10 Hz → a_ref
%    2. Road load force: F = A + B*v + C*v^2  (ANL coastdown)
%    3. Required motor torque: T = (m_eff * a + F) * rw / gear
%    4. Gate: apply regen only when T < 0, v > 1.39 m/s, a < -0.1 m/s^2
%    5. Power limit: |T * omega| <= 60 kW
%
%  This replicates Tesla's one-pedal driving: 0.15g-class deceleration on
%  pedal lift-off, with regen power capped at the inverter limit.
%
%  Vehicle parameters from AE_TeslaM3_LMDI_Params.m (Tesla Model 3 LR).
%  Road load from ANL coastdown test 62005005 (three-run average).
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

    % ---- Vehicle parameters (AE_TeslaM3_LMDI_Params.m) ----
    %  Road load: ANL coastdown 62005005, three-run average
    A_rl = 162.0;           % [N]
    B_rl = 0.552;           % [N/(m/s)]
    C_rl = 0.315;           % [N/(m/s)^2]

    %  Powertrain
    m_eff          = 1928 * 1.04;   % [kg] test mass + 4% rotational inertia
    rw             = 0.326;         % [m]  wheel radius
    gear           = evalin('base', 'gear_ratio');  % [-] from AE_TeslaM3_LMDI_Params.m
    regen_minSpeed = 1.39;          % [m/s] ~5 km/h cutoff
    P_regen_max    = 60000;         % [W]  max regen power (mechanical)

    % ---- Road load force at current speed ----
    F_road = A_rl + B_rl * v_ref + C_rl * v_ref^2;

    % ---- Required motor torque (wheel → motor shaft) ----
    T_required = (m_eff * a_ref + F_road) * rw / gear;

    % ---- Motor speed from reference (feedforward, no feedback) ----
    omega_m = v_ref * gear / rw;

    % ---- Regen gate and power limit ----
    T_regen = 0;
    if T_required < 0 && v_ref >= regen_minSpeed && a_ref < -0.1
        if omega_m > 0
            T_max_regen = P_regen_max / omega_m;
            T_regen = max(T_required, -T_max_regen);  % clamp magnitude
        end
    end

    block.OutputPort(1).Data = T_regen;
end
