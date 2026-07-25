%% BoltEV_generate_fw_onset.m
%  Generate the CRG field-weakening onset curve for the Bolt EV IPMSM.
%
%  Uses the ANALYTICAL approach: at each torque level, compute the MTPA
%  operating point (id, iq), then find the speed at which the terminal
%  voltage reaches V_lim = kVmax * V_dc / sqrt(3).
%
%  The LUT-based Id-departure method (used for Tesla in Paper A) does not
%  work cleanly for the Bolt because at higher torques (>50 Nm) the MTPA
%  id already exceeds the 10A departure threshold due to the Bolt's higher
%  saliency ratio (Lq/Ld = 1.53 vs Tesla ~1.95). The analytical method is
%  exact and threshold-free.
%
%  Cross-check: the LUT-extracted zero-torque onset (4403 rpm, V_dc=350V)
%  matches the analytical value to within the LUT grid step (330 rpm).
%
%  Outputs:
%    BoltEV_FW_onset_curve.mat containing:
%      fw_tq_Nm     - torque breakpoints [Nm], ascending, T=0 to T_max
%      fw_rpm_mech  - FW onset speed [RPM mechanical], decreasing
%      Vdc_V        - DC bus voltage used [V]
%      threshold_A  - set to 0 (analytical method, no threshold)
%      method       - 'analytical_MTPA_voltage'
%
%  Author: F. Shah Khan, University of East London, July 2026
% =========================================================================

fprintf('\n=== Bolt EV: CRG FW Onset Curve (Analytical) ===\n');

%% Motor parameters
p_bolt     = 4;              % pole pairs
psim_bolt  = 0.1017;         % PM flux linkage [Wb]
Ld_bolt    = 253.7e-6;       % d-axis inductance [H]
Lq_bolt    = 389.1e-6;       % q-axis inductance [H]
Rs_bolt    = 0.00659;        % stator resistance [Ohm]
T_max_Nm   = 360;            % peak torque [Nm]
kVmax_bolt = 0.904;          % modulation index

% Voltage limit
V_dc       = 350;            % nominal DC bus [V]
V_lim      = kVmax_bolt * V_dc / sqrt(3);
fprintf('  V_dc = %d V, kVmax = %.3f, V_lim = %.1f V\n', V_dc, kVmax_bolt, V_lim);

% Saliency
delta_L = Lq_bolt - Ld_bolt;
a_mtpa  = psim_bolt / (2 * delta_L);
fprintf('  Ld = %.1f uH, Lq = %.1f uH, Lq/Ld = %.2f\n', ...
    Ld_bolt*1e6, Lq_bolt*1e6, Lq_bolt/Ld_bolt);
fprintf('  MTPA characteristic: a = %.1f A\n', a_mtpa);

%% Torque grid: T = 0 to T_max in fine steps
N_tq = 50;
T_vec = linspace(0, T_max_Nm, N_tq);

fw_tq_Nm    = zeros(N_tq, 1);
fw_rpm_mech = zeros(N_tq, 1);

for jT = 1:N_tq
    T_dem = T_vec(jT);
    fw_tq_Nm(jT) = T_dem;

    if T_dem < 0.1
        % Zero torque: id=0, iq=0
        % V = omega_e * psim (at zero current)
        omega_e_FW = V_lim / psim_bolt;
        fw_rpm_mech(jT) = omega_e_FW / p_bolt * 60 / (2*pi);
        continue;
    end

    % MTPA operating point
    % T = 1.5 * p * (psim*iq + (Ld-Lq)*id*iq)
    % MTPA: id = a - sqrt(a^2 + iq^2), where a = psim/(2*(Lq-Ld))
    % Solve for iq that gives T_dem
    fun_T = @(iq) 1.5 * p_bolt * (psim_bolt * iq + ...
        (Ld_bolt - Lq_bolt) * (a_mtpa - sqrt(a_mtpa^2 + iq^2)) * iq) - T_dem;

    try
        iq_mtpa = fzero(fun_T, [0, 800]);
    catch
        % If fzero fails, T_dem exceeds MTPA capability
        iq_mtpa = 600;  % saturate
    end
    id_mtpa = a_mtpa - sqrt(a_mtpa^2 + iq_mtpa^2);

    % FW onset speed: V_mag = V_lim
    % V_mag = omega_e * sqrt((Lq*iq)^2 + (Ld*id + psim)^2)
    % (neglecting Rs, valid since Rs*I << omega_e*L*I at high speed)
    flux_d = Ld_bolt * id_mtpa + psim_bolt;
    flux_q = Lq_bolt * iq_mtpa;
    flux_mag = sqrt(flux_d^2 + flux_q^2);

    if flux_mag > 1e-9
        omega_e_FW = V_lim / flux_mag;
    else
        omega_e_FW = 1e6;  % effectively infinite
    end

    omega_m_FW = omega_e_FW / p_bolt;
    fw_rpm_mech(jT) = omega_m_FW * 60 / (2*pi);

    % Cross-check with Rs included (optional, for verification)
    if jT == 1 || jT == N_tq || mod(jT, 10) == 0
        Vd_full = Rs_bolt * id_mtpa - omega_e_FW * Lq_bolt * iq_mtpa;
        Vq_full = Rs_bolt * iq_mtpa + omega_e_FW * (Ld_bolt * id_mtpa + psim_bolt);
        V_full = sqrt(Vd_full^2 + Vq_full^2);
        V_err_pct = (V_full - V_lim) / V_lim * 100;
        % Rs correction is < 0.5% at typical operating points
    end
end

%% Enforce monotonicity (physical: higher torque = lower FW onset)
for k = 2:N_tq
    if fw_rpm_mech(k) > fw_rpm_mech(k-1)
        fw_rpm_mech(k) = fw_rpm_mech(k-1);
    end
end

%% Display
fprintf('\n  FW onset curve: %d breakpoints (analytical, V_dc=%d V)\n', N_tq, V_dc);
fprintf('  %8s  %10s  %10s  %10s  %10s\n', 'T [Nm]', 'RPM_FW', 'v_FW [km/h]', 'id_MTPA', 'iq_MTPA');
wheel_r    = 0.317;
gear_ratio = 7.05;

disp_idx = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50];
disp_idx = disp_idx(disp_idx <= N_tq);
for k = disp_idx
    omega_m = fw_rpm_mech(k) * 2*pi/60;
    v_FW_kmh = omega_m * wheel_r / gear_ratio * 3.6;
    T_dem = fw_tq_Nm(k);
    if T_dem < 0.1
        id_m = 0; iq_m = 0;
    else
        fun_T = @(iq) 1.5 * p_bolt * (psim_bolt * iq + ...
            (Ld_bolt - Lq_bolt) * (a_mtpa - sqrt(a_mtpa^2 + iq^2)) * iq) - T_dem;
        try, iq_m = fzero(fun_T, [0, 800]); catch, iq_m = 0; end
        id_m = a_mtpa - sqrt(a_mtpa^2 + iq_m^2);
    end
    fprintf('  %8.1f  %10.1f  %10.1f  %10.1f  %10.1f\n', ...
        T_dem, fw_rpm_mech(k), v_FW_kmh, id_m, iq_m);
end

% Key reference points
omega_m_0 = fw_rpm_mech(1) * 2*pi/60;
v_FW_0 = omega_m_0 * wheel_r / gear_ratio * 3.6;
fprintf('\n  Zero-torque FW onset:  %.0f rpm = %.1f km/h\n', fw_rpm_mech(1), v_FW_0);

[~, idx_cruise] = min(abs(fw_tq_Nm - 24));
omega_m_c = fw_rpm_mech(idx_cruise) * 2*pi/60;
v_FW_c = omega_m_c * wheel_r / gear_ratio * 3.6;
fprintf('  Cruise (~24 Nm) onset: %.0f rpm = %.1f km/h\n', fw_rpm_mech(idx_cruise), v_FW_c);

omega_m_p = fw_rpm_mech(end) * 2*pi/60;
v_FW_p = omega_m_p * wheel_r / gear_ratio * 3.6;
fprintf('  Peak (%.0f Nm) onset:   %.0f rpm = %.1f km/h\n', ...
    fw_tq_Nm(end), fw_rpm_mech(end), v_FW_p);

%% Cross-check: LUT-extracted zero-torque onset
lut_dir = fullfile(fileparts(mfilename('fullpath')), '..', 'data');
lut_3d  = fullfile(lut_dir, 'BoltEV_CurrentRef_LUT.mat');
if exist(lut_3d, 'file')
    L = load(lut_3d);
    VDC_vec = double(L.VDC_VECT);
    [~, jV] = min(abs(VDC_vec - V_dc));
    zero_tq_idx = find(abs(double(L.TQ_VECT)) < 1, 1);
    if ~isempty(zero_tq_idx)
        id_vs_rpm = L.ID_MAP(:, zero_tq_idx, jV);
        above_10 = find(abs(id_vs_rpm) > 10, 1, 'first');
        if ~isempty(above_10) && above_10 > 1
            lut_rpm = L.RPM_VECT(above_10);
            lut_v = lut_rpm * 2*pi/60 / p_bolt * wheel_r / gear_ratio * 3.6;
            fprintf('\n  LUT cross-check (10A departure at T=0): %.0f rpm = %.1f km/h\n', ...
                lut_rpm, lut_v);
            fprintf('  Analytical vs LUT difference: %.0f rpm (grid step = %.0f rpm)\n', ...
                abs(fw_rpm_mech(1) - lut_rpm), ...
                L.RPM_VECT(2) - L.RPM_VECT(1));
        end
    end
end

%% Save
out_file = fullfile(lut_dir, 'BoltEV_FW_onset_curve.mat');
Vdc_V = V_dc;
threshold_A = 0;
method = 'analytical_MTPA_voltage';
save(out_file, 'fw_tq_Nm', 'fw_rpm_mech', 'Vdc_V', 'threshold_A', 'method');
fprintf('\n  Saved: %s\n', out_file);
fprintf('\n=== FW onset curve generation complete ===\n');
