function L = AE_loss_decomposition(Pb, vS, t, regime, params)
%AE_LOSS_DECOMPOSITION  Per-regime energy loss budget by physical mechanism.
%
%  Decomposes traction energy into five mechanisms for each motor operating
%  regime (MTPA / Transition / FW):
%    1. Useful traction  — road load + net kinetic energy change
%    2. Copper loss      — stator I^2*R_s (by energy closure)
%    3. Iron loss        — ANL-calibrated post-hoc correction
%    4. Gearbox loss     — (1 - eta_gear) fraction of motor shaft power
%    5. Battery I^2*R    — internal resistance dissipation
%
%  Iron loss is computed analytically (not from simulation) because the
%  Simscape abc_thermal IPMSM iron-loss model injects energy rather than
%  dissipating it; iron-loss coefficients are zeroed in the model and
%  applied here using ANL-calibrated values.
%
%  Inputs
%    Pb     - battery power [W], N x 1, 10 Hz (positive = discharge)
%    vS     - vehicle speed [m/s], N x 1
%    t      - time vector [s], N x 1
%    regime - per-timestep regime assignment [N x 1]: 1=MTPA, 2=Trans, 3=FW
%    params - struct with fields:
%               .m          test mass [kg]          (default 1928)
%               .A_rl       road load constant [N]  (default 178)
%               .B_rl       road load linear  [N.s/m] (default 3.024)
%               .C_rl       road load quad    [N.s^2/m^2] (default 0.370)
%               .eta_gear   gearbox efficiency [-]  (default 0.97)
%               .V_nom      battery nominal voltage [V] (default 370)
%               .R_int      battery internal resistance [Ohm] (default 0.05)
%               .P_fe       iron loss by regime [W, 1x3] (default [37 524 1729])
%
%  Output struct L — all energies in Wh/km per regime (1x3 vectors)
%    E_useful    - useful traction energy intensity [Wh/km]
%    E_copper    - copper loss intensity [Wh/km]
%    E_iron      - iron loss intensity [Wh/km]
%    E_gear      - gearbox loss intensity [Wh/km]
%    E_batt      - battery I^2*R loss intensity [Wh/km]
%    E_gross     - gross traction energy intensity [Wh/km]
%    d           - distance per regime [km, 1x3]
%    closure_pct - energy closure error [%] (should be < 1%)
%
%  Called by: AE_run_LMDI.m (after AE_lmdi_decomposition)
%
%  Author: F. Shah Khan, University of East London, June 2026
% -------------------------------------------------------------------------

%% ── Default parameters ───────────────────────────────────────────────────
if nargin < 5 || isempty(params), params = struct(); end
p = @(f,d) params_get(params, f, d);

m       = p('m',       1928);
A_rl    = p('A_rl',    178);
B_rl    = p('B_rl',    3.024);
C_rl    = p('C_rl',    0.370);
eta_g   = p('eta_gear', 0.97);
V_nom   = p('V_nom',   370);
R_int   = p('R_int',   0.05);
P_fe    = p('P_fe',    [37, 524, 1729]);   % W: MTPA / mid-FW / deep-FW

%% ── Setup ────────────────────────────────────────────────────────────────
Pb  = Pb(:);  vS = abs(vS(:));  t = t(:);  regime = regime(:);
N   = numel(Pb);
dt  = median(diff(t));
dk  = trapz(t, vS) / 1000;              % total distance [km]

mk = {regime == 1, regime == 2, regime == 3};

%% ── Physical quantities (per timestep) ───────────────────────────────────
% Road load force and power
F_road  = A_rl + B_rl .* vS + C_rl .* vS .^ 2;
P_road  = F_road .* vS;                 % [W]

% Battery current (approximate: I = P / V_nom)
I_batt  = Pb / V_nom;                   % [A]
P_Rint  = R_int .* I_batt .^ 2;         % [W] battery internal loss

% Motor shaft power (traction only)
trac    = Pb > 0;
P_shaft = zeros(N, 1);
P_shaft(trac) = Pb(trac) - P_Rint(trac);   % shaft = battery - batt loss
P_shaft = max(P_shaft, 0);

% Gearbox loss
P_gear  = P_shaft .* (1 - eta_g);       % [W]

% Kinetic energy rate (dKE/dt = m*v*a)
dv_dt   = gradient(vS, dt);
P_KE    = m .* vS .* dv_dt;             % [W] positive = accelerating

% Useful traction = road load + net KE rate (clamped to traction timesteps)
P_useful = max(P_road + P_KE, 0) .* double(trac);

%% ── Per-regime loss budget ───────────────────────────────────────────────
E_useful = zeros(1,3);  E_copper = zeros(1,3);
E_iron   = zeros(1,3);  E_gear   = zeros(1,3);
E_batt   = zeros(1,3);  E_gross  = zeros(1,3);
d        = zeros(1,3);

for r = 1:3
    m_r = mk{r};
    d(r) = trapz(t, vS .* double(m_r)) / 1000;
    if d(r) < 1e-4, continue; end

    % Gross traction energy in this regime [Wh]
    Eg_r = trapz(t(m_r), max(Pb(m_r), 0)) / 3600;

    % Battery I^2*R [Wh]
    Eb_r = trapz(t(m_r), P_Rint(m_r))   / 3600;

    % Iron loss: constant power per regime from ANL calibration [Wh]
    Efe_r = P_fe(r) * trapz(t, double(m_r) .* double(trac)) / 3600;

    % Gearbox loss [Wh]
    Eg_gear_r = trapz(t(m_r), P_gear(m_r)) / 3600;

    % Useful traction [Wh]
    Eu_r = trapz(t(m_r), P_useful(m_r))  / 3600;

    % Copper loss by energy closure
    Ecu_r = max(0, Eg_r - Eb_r - Efe_r - Eg_gear_r - Eu_r);

    % Normalise to Wh/km
    E_useful(r) = Eu_r  / d(r);
    E_copper(r) = Ecu_r / d(r);
    E_iron(r)   = Efe_r / d(r);
    E_gear(r)   = Eg_gear_r / d(r);
    E_batt(r)   = Eb_r  / d(r);
    E_gross(r)  = Eg_r  / d(r);
end

%% ── Energy closure check ─────────────────────────────────────────────────
E_sum = E_useful + E_copper + E_iron + E_gear + E_batt;
closure_pct = abs(E_sum - E_gross) ./ max(E_gross, 1) * 100;

%% ── Output ───────────────────────────────────────────────────────────────
L = struct( ...
    'E_useful',    E_useful,   ...
    'E_copper',    E_copper,   ...
    'E_iron',      E_iron,     ...
    'E_gear',      E_gear,     ...
    'E_batt',      E_batt,     ...
    'E_gross',     E_gross,    ...
    'd',           d,          ...
    'dk',          dk,         ...
    'closure_pct', closure_pct);
end

%% ── Helper: safe field access with default ───────────────────────────────
function v = params_get(s, field, default)
    if isfield(s, field)
        v = s.(field);
    else
        v = default;
    end
end
