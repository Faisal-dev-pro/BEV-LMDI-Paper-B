function R = AE_lmdi_decomposition(Pb, vS, t, fw_tq, fw_rpm, eta_drive, wheel_r, gear_ratio)
%AE_LMDI_DECOMPOSITION  Per-regime LMDI-I quantities for one drive cycle.
%
%  Computes the structural factor S(r), intensity factor I(r), and
%  contribution e(r) = S(r)*I(r) for three motor operating regimes:
%    Regime 1 - MTPA, Regime 2 - Trans (5% band), Regime 3 - FW
%
%  Regime assignment is delegated to AE_regime_binning.m (single source
%  of truth; regen binned by speed since 17 Jul 2026). Intensities are
%  NET (traction minus regen) per regime, consistent across regimes.
%
%  Inputs
%    Pb, vS, t  - battery power [W], vehicle speed [m/s], time [s]
%    fw_tq/rpm  - CRG FW onset curve breakpoints
%    eta_drive  - drivetrain efficiency for torque reconstruction [-]
%    wheel_r, gear_ratio - vehicle geometry
%
%  Output struct R
%    S, I, e   - share, net intensity [Wh/km], contribution per regime [1x3]
%    d, E      - distance [km] and net energy [Wh] per regime
%    dk        - total cycle distance [km]
%    Et, Er    - gross traction / regen energy [Wh]
%    Ept       - net cycle intensity (Et-Er)/dk [Wh/km]
%    regen_pct - regen fraction Er/Et*100 [%]
%    regime    - per-timestep labels (for figures)
%
%  Called by: AE_run_LMDI_matrix.m
%
%  Author: F. Shah Khan, University of East London, July 2026
% -------------------------------------------------------------------------

Pb = Pb(:); vS = vS(:); t = t(:);

% Regime assignment — single source of truth
regime = AE_regime_binning(Pb, vS, fw_tq, fw_rpm, eta_drive, wheel_r, gear_ratio);
mk = {regime == 1, regime == 2, regime == 3};

% Cycle totals
vA = abs(vS);
dk = trapz(t, vA) / 1000;
Et = trapz(t, max(Pb, 0))      / 3600;
Er = abs(trapz(t, min(Pb, 0))) / 3600;

% Per-regime quantities (NET energy per regime)
S = zeros(1,3);  I = zeros(1,3);  e = zeros(1,3);
d = zeros(1,3);  E = zeros(1,3);

for r = 1:3
    m_r  = double(mk{r});
    d(r) = trapz(t, vA .* m_r) / 1000;
    etr  = trapz(t, max(Pb, 0) .* m_r) / 3600;
    erv  = abs(trapz(t, min(Pb, 0) .* m_r)) / 3600;
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
           'regen_pct', Er / Et * 100, ...
           'regime', regime);
end
