function regime = AE_regime_binning(Pb, vS, fw_tq, fw_rpm, eta_drive, wheel_r, gear_ratio)
%AE_REGIME_BINNING  CRG-based per-timestep motor operating regime classifier.
%
%  Assigns each timestep to one of three motor operating regimes:
%    1 - MTPA  (below FW onset)
%    2 - Trans (within 5% of FW onset speed)
%    3 - FW    (at/above FW onset speed)
%
%  Boundary: torque-dependent CRG FW onset (Id-departure criterion at
%  V_dc = 370 V), interpolated from (fw_tq, fw_rpm) at each timestep.
%
%  REGEN RULE (updated 17 Jul 2026, decision F.S.K.):
%  Regen timesteps are binned BY SPEED like traction, using the torque
%  magnitude estimated from |Pb|/(eta_drive*omega) (shaft power exceeds
%  battery power during regen). High-speed regen therefore counts as FW
%  operation. Only standstill/idle timesteps (omega <= 0.5 rad/s)
%  default to MTPA. This gives consistent net-energy intensity semantics
%  across regimes.
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
%  Called by: AE_lmdi_decomposition.m, AE_run_LMDI_matrix.m,
%             AE_Generate_Figures.m
%
%  Author: F. Shah Khan, University of East London, July 2026
% -------------------------------------------------------------------------

Pb  = Pb(:);
vS  = vS(:);
N   = numel(Pb);

%% Motor speed from vehicle speed
rpm_mech   = abs(vS) * gear_ratio / wheel_r * 60 / (2*pi);   % [RPM]
omega_mech = abs(vS) * gear_ratio / wheel_r;                  % [rad/s]

%% Motor torque magnitude estimate (traction AND regen)
moving = omega_mech > 0.5;                     % avoid /0 at standstill
T_est  = zeros(N, 1);

trac_m  = moving & (Pb > 0);
regen_m = moving & (Pb < 0);
% Traction: shaft power ~ Pb * eta (losses upstream of shaft)
T_est(trac_m)  = Pb(trac_m)  .* eta_drive ./ omega_mech(trac_m);
% Regen: shaft power magnitude exceeds |battery| power
T_est(regen_m) = abs(Pb(regen_m)) ./ (eta_drive .* omega_mech(regen_m));
T_est = max(0, min(T_est, fw_tq(end)));        % clamp to table range

%% CRG-based FW onset speed for each timestep
rpm_fw_onset = interp1(fw_tq, fw_rpm, T_est, 'linear', 'extrap');
rpm_fw_onset = max(rpm_fw_onset, fw_rpm(end)); % floor at deep-FW limit

%% Regime assignment (speed vs torque-dependent boundary, all moving steps)
in_FW    = moving & (rpm_mech >= rpm_fw_onset);
in_Trans = moving & (rpm_mech >= 0.95 * rpm_fw_onset) & ~in_FW;
% Remaining (MTPA-zone moving steps + standstill/idle) -> regime 1

regime           = ones(N, 1, 'uint8');
regime(in_Trans) = 2;
regime(in_FW)    = 3;

end
