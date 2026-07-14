function regime = AE_regime_binning(Pb, vS, fw_tq, fw_rpm, eta_drive, wheel_r, gear_ratio)
%AE_REGIME_BINNING  CRG-based per-timestep motor operating regime classifier.
%
%  Assigns each timestep to one of three motor operating regimes:
%    1 - MTPA  (Maximum Torque Per Ampere, below FW onset)
%    2 - Trans (Transition band, within 5% of FW onset speed)
%    3 - FW    (Field Weakening, above FW onset speed)
%
%  Regime boundary is CRG-based: the FW onset mechanical speed is a
%  function of motor torque, interpolated from the CRG lookup table at
%  each timestep.  Regen and coast timesteps (Pb <= 0) are assigned
%  to MTPA (regime 1).
%
%  Inputs
%    Pb         - battery power [W], N x 1, positive = discharge
%    vS         - vehicle speed [m/s], N x 1
%    fw_tq      - CRG FW onset torque breakpoints [Nm], ascending
%    fw_rpm     - CRG FW onset RPM breakpoints [RPM mech], same length
%    eta_drive  - drivetrain efficiency for torque reconstruction [-]
%    wheel_r    - loaded wheel radius [m]
%    gear_ratio - single-speed reducer ratio [-]
%
%  Output
%    regime     - per-timestep regime label [N x 1, uint8]: 1, 2, or 3
%
%  Called by: AE_run_LMDI.m, AE_lmdi_decomposition.m, AE_Generate_Figures.m
%
%  Author: F. Shah Khan, University of East London, June 2026
% -------------------------------------------------------------------------

Pb  = Pb(:);
vS  = vS(:);
N   = numel(Pb);

%% ── Motor speed from vehicle speed ──────────────────────────────────────
rpm_mech   = abs(vS) * gear_ratio / wheel_r * 60 / (2*pi);   % [RPM]
omega_mech = abs(vS) * gear_ratio / wheel_r;                  % [rad/s]

%% ── Motor torque estimate (traction timesteps only) ──────────────────────
traction = Pb > 0;
T_est    = zeros(N, 1);
safe     = traction & (omega_mech > 0.5);                     % avoid /0 at standstill
T_est(safe) = Pb(safe) .* eta_drive ./ omega_mech(safe);
T_est    = max(0, min(T_est, fw_tq(end)));                    % clamp to table range

%% ── CRG-based FW onset speed ─────────────────────────────────────────────
rpm_fw_onset = interp1(fw_tq, fw_rpm, T_est, 'linear', 'extrap');
rpm_fw_onset = max(rpm_fw_onset, fw_rpm(end));                % floor at deep-FW limit

%% ── Regime assignment ────────────────────────────────────────────────────
in_FW    = traction & (rpm_mech >= rpm_fw_onset);
in_Trans = traction & (rpm_mech >= 0.95 * rpm_fw_onset) & ~in_FW;
% All remaining timesteps (MTPA, regen, coast, standstill) -> regime 1

regime           = ones(N, 1, 'uint8');
regime(in_Trans) = 2;
regime(in_FW)    = 3;

end
