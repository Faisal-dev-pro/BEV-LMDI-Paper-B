%% BoltEV_generate_current_refs.m
%  Generate MTPA + Field-Weakening current reference lookup tables for
%  the Bolt EV IPMSM (150 kW, 8-pole, constant Ld/Lq).
%
%  Outputs:
%    BoltEV_CurrentRefs.mat      — 2D LUT: id_table(T,rpm), iq_table(T,rpm)
%    BoltEV_CurrentRef_LUT.mat   — 3D LUT: ID_MAP(rpm,T,Vdc), IQ_MAP(rpm,T,Vdc)
%
%  These replace TeslaM3_CurrentRefs.mat and IPMSM_CurrentRef_LUT.mat
%  from the Tesla Paper A model.
%
%  Method:
%    MTPA region:  Lagrange-multiplier analytical solution
%    FW region:    Voltage-constrained torque maximisation (numerical)
%
%  Author: F. Shah Khan, UEL, July 2026
% =========================================================================

fprintf('\n=== Bolt EV Current Reference Generation ===\n');

%% Motor parameters (from AE_BoltEV_LMDI_Params.m)
p_bolt     = 4;              % pole pairs
psim_bolt  = 0.1017;         % PM flux linkage [Wb]
Ld_bolt    = 253.7e-6;       % d-axis inductance [H]
Lq_bolt    = 389.1e-6;       % q-axis inductance [H]
Rs_bolt    = 0.00659;        % stator resistance [Ohm]
n_max_rpm  = 8800;           % max speed [rpm]
T_max_Nm   = 360;            % peak torque [Nm]

% Voltage levels for 3D LUT (Bolt EV 96s LG Chem pouch)
VDC_levels = [300 330 350 400];  % [V] DC bus voltages
kVmax_bolt = 0.904;              % modulation index

%% =====================================================================
%  1) 2D LUT: BoltEV_CurrentRefs.mat  (200 x 200)
%  =====================================================================
N = 200;

% Determine peak current from MTPA at T_max
% T = 1.5*p*(psim*iq + (Ld-Lq)*id*iq)
% MTPA: id = psim/(2*(Lq-Ld)) - sqrt((psim/(2*(Lq-Ld)))^2 + iq^2)
delta_L = Lq_bolt - Ld_bolt;  % positive for IPM
a_mtpa  = psim_bolt / (2 * delta_L);

% Find iq that gives T_max at MTPA
iq_search = linspace(0, 800, 5000);
id_search = a_mtpa - sqrt(a_mtpa^2 + iq_search.^2);
T_search  = 1.5 * p_bolt * (psim_bolt * iq_search + (Ld_bolt - Lq_bolt) .* id_search .* iq_search);
[T_max_mtpa, idx_max] = max(T_search);
I_peak = ceil(sqrt(id_search(idx_max)^2 + iq_search(idx_max)^2));
fprintf('  MTPA peak: T=%.1f Nm at id=%.1f, iq=%.1f, Is=%.0f A\n', ...
    T_max_mtpa, id_search(idx_max), iq_search(idx_max), I_peak);

% Voltage limit (peak phase voltage)
V_dc_nom   = 350;  % nominal DC voltage
V_lim      = kVmax_bolt * V_dc_nom / sqrt(3);
fprintf('  V_lim = %.1f V (V_dc=%d, kVmax=%.3f)\n', V_lim, V_dc_nom, kVmax_bolt);

% Grid vectors
T_vec_max  = min(T_max_mtpa, T_max_Nm * 1.1);  % include 10% margin
T_vec      = linspace(0, T_vec_max, N);
rpm_vec    = linspace(0, n_max_rpm * 1.1, N);
omega_e_vec = rpm_vec * (2*pi/60) * p_bolt;

% Preallocate
id_table = zeros(N, N);  % (torque, speed)
iq_table = zeros(N, N);

% Compute MTPA for each torque level (speed-independent)
iq_mtpa = zeros(1, N);
id_mtpa = zeros(1, N);
for jT = 1:N
    T_dem = T_vec(jT);
    if T_dem < 0.1
        iq_mtpa(jT) = 0;
        id_mtpa(jT) = 0;
        continue;
    end
    % Solve for iq: T = 1.5*p*(psim*iq + (Ld-Lq)*id_mtpa(iq)*iq)
    % Use fzero
    fun_T = @(iq) torque_at_mtpa(iq, p_bolt, psim_bolt, Ld_bolt, Lq_bolt) - T_dem;
    try
        iq_mtpa(jT) = fzero(fun_T, [0, 800]);
        id_mtpa(jT) = a_mtpa - sqrt(a_mtpa^2 + iq_mtpa(jT)^2);
    catch
        % If fzero fails, torque is above MTPA capability
        iq_mtpa(jT) = iq_search(idx_max);
        id_mtpa(jT) = id_search(idx_max);
    end
end

% Fill 2D table: for each (torque, speed), apply MTPA or FW
for jT = 1:N
    for jN = 1:N
        omega_e = omega_e_vec(jN);
        if omega_e < 1
            % Zero speed: use MTPA
            id_table(jT, jN) = id_mtpa(jT);
            iq_table(jT, jN) = iq_mtpa(jT);
            continue;
        end

        % Check if MTPA satisfies voltage constraint
        id_m = id_mtpa(jT);
        iq_m = iq_mtpa(jT);
        Vd = Rs_bolt * id_m - omega_e * Lq_bolt * iq_m;
        Vq = Rs_bolt * iq_m + omega_e * (Ld_bolt * id_m + psim_bolt);
        V_mag = sqrt(Vd^2 + Vq^2);

        if V_mag <= V_lim
            % MTPA region
            id_table(jT, jN) = id_m;
            iq_table(jT, jN) = iq_m;
        else
            % Field-weakening region: find (id, iq) on voltage ellipse
            % that produces required torque with minimum current
            T_dem = T_vec(jT);
            [id_fw, iq_fw] = solve_fw(T_dem, omega_e, V_lim, ...
                p_bolt, psim_bolt, Ld_bolt, Lq_bolt, Rs_bolt, I_peak);
            id_table(jT, jN) = id_fw;
            iq_table(jT, jN) = iq_fw;
        end
    end
end

% Assign flat variable names for compatibility with Tesla model
p     = p_bolt;
psim  = psim_bolt;
Ld    = Ld_bolt;
Lq    = Lq_bolt;
Rs    = Rs_bolt;
LdmLq = Ld_bolt - Lq_bolt;

% Save 2D LUT
save_path_2d = fullfile(fileparts(mfilename('fullpath')), ...
    '..', 'data', 'BoltEV_CurrentRefs.mat');
save(save_path_2d, 'id_table', 'iq_table', 'T_vec', 'rpm_vec', ...
    'omega_e_vec', 'I_peak', 'V_lim', ...
    'p', 'psim', 'Ld', 'Lq', 'Rs', 'LdmLq');

fprintf('  Saved BoltEV_CurrentRefs.mat: %dx%d (T x rpm)\n', N, N);

%% =====================================================================
%  2) 3D LUT: BoltEV_CurrentRef_LUT.mat  (33 x 83 x 4)
%  =====================================================================
N_rpm = 33;
N_tq  = 83;
N_vdc = numel(VDC_levels);

RPM_VECT = linspace(0, n_max_rpm * 1.2, N_rpm);
TQ_VECT  = linspace(-T_max_Nm, T_max_Nm, N_tq);
VDC_VECT = uint16(VDC_levels);

ID_MAP = zeros(N_rpm, N_tq, N_vdc);
IQ_MAP = zeros(N_rpm, N_tq, N_vdc);

for jV = 1:N_vdc
    V_dc_j  = double(VDC_levels(jV));
    V_lim_j = kVmax_bolt * V_dc_j / sqrt(3);
    fprintf('  3D LUT: V_dc = %d V, V_lim = %.1f V\n', V_dc_j, V_lim_j);

    for jR = 1:N_rpm
        omega_e = RPM_VECT(jR) * (2*pi/60) * p_bolt;

        for jT = 1:N_tq
            T_dem = TQ_VECT(jT);

            if abs(T_dem) < 0.1
                % Zero torque: still need FW id at high speed to keep
                % back-EMF within voltage limit and prevent uncontrolled
                % body diode conduction in the Converter block.
                if omega_e > 1
                    V_back_0 = omega_e * psim_bolt;
                    if V_back_0 > V_lim_j
                        id_fw0 = (V_lim_j / omega_e - psim_bolt) / Ld_bolt;
                        ID_MAP(jR, jT, jV) = id_fw0;
                    else
                        ID_MAP(jR, jT, jV) = 0;
                    end
                else
                    ID_MAP(jR, jT, jV) = 0;
                end
                IQ_MAP(jR, jT, jV) = 0;
                continue;
            end

            % For negative torque (regen), flip sign convention
            T_sign = sign(T_dem);
            T_abs  = abs(T_dem);

            % Compute MTPA for |T|
            fun_T = @(iq) torque_at_mtpa(iq, p_bolt, psim_bolt, Ld_bolt, Lq_bolt) - T_abs;
            try
                iq_m = fzero(fun_T, [0, 800]);
            catch
                iq_m = iq_search(idx_max);
            end
            id_m = a_mtpa - sqrt(a_mtpa^2 + iq_m^2);

            % Check voltage
            if omega_e < 1
                id_out = id_m;
                iq_out = iq_m;
            else
                Vd = Rs_bolt * id_m - omega_e * Lq_bolt * iq_m;
                Vq = Rs_bolt * iq_m + omega_e * (Ld_bolt * id_m + psim_bolt);
                V_mag = sqrt(Vd^2 + Vq^2);
                if V_mag <= V_lim_j
                    id_out = id_m;
                    iq_out = iq_m;
                else
                    [id_out, iq_out] = solve_fw(T_abs, omega_e, V_lim_j, ...
                        p_bolt, psim_bolt, Ld_bolt, Lq_bolt, Rs_bolt, I_peak);
                end
            end

            % Apply sign: regen uses negative iq
            ID_MAP(jR, jT, jV) = id_out;
            IQ_MAP(jR, jT, jV) = T_sign * iq_out;
        end
    end
end

save_path_3d = fullfile(fileparts(mfilename('fullpath')), ...
    '..', 'data', 'BoltEV_CurrentRef_LUT.mat');
save(save_path_3d, 'ID_MAP', 'IQ_MAP', 'RPM_VECT', 'TQ_VECT', 'VDC_VECT');
fprintf('  Saved BoltEV_CurrentRef_LUT.mat: %dx%dx%d (rpm x T x Vdc)\n', ...
    N_rpm, N_tq, N_vdc);

fprintf('\n=== Current reference generation complete ===\n');

%% =====================================================================
%  LOCAL FUNCTIONS
%  =====================================================================

function T = torque_at_mtpa(iq, p, psim, Ld, Lq)
    % Compute torque at MTPA operating point for given iq
    delta_L = Lq - Ld;
    a = psim / (2 * delta_L);
    id = a - sqrt(a^2 + iq^2);
    T = 1.5 * p * (psim * iq + (Ld - Lq) * id * iq);
end

function [id_fw, iq_fw] = solve_fw(T_dem, omega_e, V_lim, p, psim, Ld, Lq, Rs, I_max)
    % Solve for (id, iq) in field-weakening region.
    % Finds the point on the voltage ellipse that produces T_dem
    % with minimum current magnitude.
    %
    % Strategy: parametric search over id, solve for iq from voltage
    % constraint, check torque feasibility.

    if T_dem < 0.1
        id_fw = 0; iq_fw = 0; return;
    end

    % Characteristic current
    i_ch = psim / (Lq - Ld);

    % Search over id from 0 to -I_max
    N_search = 500;
    id_range = linspace(0, -I_max, N_search);

    best_Is  = Inf;
    id_fw    = 0;
    iq_fw    = 0;

    for k = 1:N_search
        id_k = id_range(k);

        % From voltage constraint (neglecting Rs for speed):
        % V_lim^2 = (omega_e*Lq*iq)^2 + (omega_e*(Ld*id + psim))^2
        flux_d = Ld * id_k + psim;
        V_d_sq = (omega_e * flux_d)^2;

        V_q_sq_avail = V_lim^2 - V_d_sq;
        if V_q_sq_avail < 0
            continue;  % id too small, voltage saturated on d-axis
        end

        iq_max_v = sqrt(V_q_sq_avail) / (omega_e * Lq);

        % Torque from this id at max iq
        T_k = 1.5 * p * (psim * iq_max_v + (Ld - Lq) * id_k * iq_max_v);

        if T_k < T_dem
            continue;  % not enough torque at this id
        end

        % Solve for exact iq to meet T_dem
        % T_dem = 1.5*p*(psim*iq + (Ld-Lq)*id*iq) = 1.5*p*iq*(psim + (Ld-Lq)*id)
        denom = 1.5 * p * (psim + (Ld - Lq) * id_k);
        if abs(denom) < 1e-10
            continue;
        end
        iq_k = T_dem / denom;

        if iq_k < 0 || iq_k > iq_max_v
            continue;
        end

        % Check current magnitude
        Is_k = sqrt(id_k^2 + iq_k^2);
        if Is_k < best_Is
            best_Is = Is_k;
            id_fw = id_k;
            iq_fw = iq_k;
        end
    end

    % If no solution found, return MTPA-limited values
    if best_Is == Inf
        delta_L = Lq - Ld;
        a = psim / (2 * delta_L);
        iq_fw = 0;
        id_fw = -psim / Ld;  % deep FW (MTPV limit)
    end
end
