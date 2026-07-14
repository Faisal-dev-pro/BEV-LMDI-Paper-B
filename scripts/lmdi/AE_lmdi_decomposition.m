function R = AE_lmdi_decomposition(Pb, vS, t, fw_tq, fw_rpm, eta_drive, wheel_r, gear_ratio)
%AE_LMDI_DECOMPOSITION  Per-regime LMDI-I quantities for one drive cycle.
%
%  Computes the structural factor S(r), intensity factor I(r), and
%  contribution e(r) = S(r)*I(r) for three motor operating regimes:
%    Regime 1 - MTPA  (Maximum Torque Per Ampere)
%    Regime 2 - Trans (Transition band, 5% buffer around FW onset)
%    Regime 3 - FW    (Field Weakening)
%
%  Regime assignment is CRG-based: the FW onset speed is a function of
%  motor torque, interpolated from the CRG lookup table at each timestep.
%  Regen and coast timesteps (Pb <= 0) are assigned to MTPA.
%
%  Inputs
%    Pb         - battery power [W], N x 1, 10 Hz
%    vS         - vehicle speed [m/s], N x 1 (forward = positive)
%    t          - time vector [s], N x 1
%    fw_tq      - CRG FW onset torque breakpoints [Nm]
%    fw_rpm     - CRG FW onset RPM breakpoints [RPM mech]
%    eta_drive  - drivetrain efficiency for torque reconstruction [-]
%    wheel_r    - loaded wheel radius [m]
%    gear_ratio - single-speed reducer ratio [-]
%
%  Output struct R
%    S         - distance share per regime [1x3]
%    I         - traction energy intensity per regime [Wh/km, 1x3]
%    e         - LMDI contribution S*I per regime [Wh/km, 1x3]
%    d         - distance per regime [km, 1x3]
%    E         - net energy per regime [Wh, 1x3]
%    dk        - total cycle distance [km]
%    Et        - gross traction energy [Wh]
%    Er        - total regen energy [Wh]
%    Ept       - net cycle intensity (Et-Er)/dk [Wh/km]
%    regen_pct - regen fraction Er/Et*100 [%]
%
%  Called by: AE_run_LMDI.m
%
%  Author: F. Shah Khan, University of East London, June 2026
% -------------------------------------------------------------------------

% ── Regime assignment ────────────────────────────────────────────────────
rpm_mech   = abs(vS) * gear_ratio / wheel_r * 60 / (2*pi);
omega_mech = abs(vS) * gear_ratio / wheel_r;

traction = Pb > 0;
T_est    = zeros(size(Pb));
safe     = traction & (omega_mech > 0.5);
T_est(safe) = Pb(safe) .* eta_drive ./ omega_mech(safe);
T_est    = max(0, min(T_est, fw_tq(end)));

rpm_fw_onset = interp1(fw_tq, fw_rpm, T_est, 'linear', 'extrap');
rpm_fw_onset = max(rpm_fw_onset, fw_rpm(end));

in_FW    = traction & (rpm_mech >= rpm_fw_onset);
in_Trans = traction & (rpm_mech >= 0.95*rpm_fw_onset) & ~in_FW;
in_MTPA  = ~in_FW & ~in_Trans;

mk = {double(in_MTPA), double(in_Trans), double(in_FW)};

% ── Cycle totals ─────────────────────────────────────────────────────────
vA = abs(vS);
dk = trapz(t, vA) / 1000;
Et = trapz(t, max(Pb, 0))      / 3600;
Er = abs(trapz(t, min(Pb, 0))) / 3600;

% ── Per-regime quantities ─────────────────────────────────────────────────
S = zeros(1,3);  I = zeros(1,3);  e = zeros(1,3);
d = zeros(1,3);  E = zeros(1,3);

for r = 1:3
    d(r) = trapz(t, vA .* mk{r}) / 1000;
    etr  = trapz(t, max(Pb, 0) .* mk{r}) / 3600;
    erv  = abs(trapz(t, min(Pb, 0) .* mk{r})) / 3600;
    E(r) = etr - erv;
    S(r) = d(r) / dk;
    if d(r) > 0.001
        I(r) = E(r) / d(r);
    end
    e(r) = S(r) * I(r);
end

R = struct('S', S, 'I', I, 'e', e, 'd', d, 'E', E, ...
           'dk', dk, 'Et', Et, 'Er', Er, ...
           'Ept', (Et - Er) / dk, ...
           'regen_pct', Er / Et * 100);
end
