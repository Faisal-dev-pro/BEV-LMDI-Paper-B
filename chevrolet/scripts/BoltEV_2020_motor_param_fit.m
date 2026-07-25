%% BoltEV_2020_motor_param_fit.m
%  Refit psi_m and (Lq-Ld) of the Bolt EV IPMSM MTPA model against the
%  REAL 2020 ANL dynamometer data (738,581 loaded points, |T|>20 Nm),
%  loaded previously by BoltEV_2020_motor_param_validate.m.
%
%  Rationale: the literal constants in BoltEV_generate_current_refs.m
%  (psim=0.1017, Ld=253.7uH, Lq=389.1uH) over-predict stator current by
%  66-245% vs measured Motor_1_current_DMCM1__A at matching torque. The
%  error shrinks with torque, the signature of psi_m being too low.
%
%  Identifiability: only psi_m and deltaL=(Lq-Ld) are observable from
%  (T, Is) pairs under the MTPA assumption -- Rs and the individual
%  Ld/Lq split are not separable from this signal alone. We therefore:
%    - fit psi_m and deltaL by nonlinear least squares
%    - preserve the original Ld/Lq SALIENCY RATIO (Ld/Lq = 0.6519) to
%      split deltaL back into individual Ld, Lq
%    - keep Rs at its literal value (copper loss only, no current-
%      magnitude leverage in the MTPA fit)
%
%  Author: F. Shah Khan, UEL, July 2026
% =========================================================================

fprintf('\n=== Bolt EV 2020 ANL data: MTPA parameter refit ===\n');

proj_root = fileparts(fileparts(mfilename('fullpath')));
val_file  = fullfile(proj_root, 'results', 'BoltEV_2020_param_validation.mat');
V = load(val_file);
CR = V.CR;

p_bolt = double(CR.p);
ratio_LdLq = CR.Ld / CR.Lq;   % preserve saliency character (0.6519)
fprintf('Fixed: p=%d, Ld/Lq ratio (from literal values) = %.4f\n', p_bolt, ratio_LdLq);

%% Build a clean, robust (T, Is) dataset for fitting
% Restrict to a "near-MTPA" proxy: exclude very high speed points where
% field weakening (not MTPA) governs the id/iq split, since psi_m/deltaL
% are only identifiable from the below-base-speed MTPA trajectory.
T_f   = V.T_f;
rpm_f = V.rpm_f;
I_f   = V.I_f;

mtpa_mask = abs(T_f) > 20 & abs(rpm_f) > 50 & abs(rpm_f) < 3500;  % proxy base-speed region
Tq   = abs(T_f(mtpa_mask));
Is_m = abs(I_f(mtpa_mask));
fprintf('Near-MTPA fit set: %d points (rpm<3500)\n', numel(Tq));

% Bin into 40 torque bins, use median current per bin (robust to noise
% and to non-MTPA transients) as the fit target.
edges = linspace(20, min(360, prctile(Tq,99.5)), 41);
Tmid = 0.5*(edges(1:end-1)+edges(2:end));
Imed = nan(size(Tmid));
Nbin = zeros(size(Tmid));
for b = 1:numel(Tmid)
    m = Tq >= edges(b) & Tq < edges(b+1);
    Nbin(b) = sum(m);
    if Nbin(b) > 20
        Imed(b) = median(Is_m(m));
    end
end
keep = ~isnan(Imed) & Nbin > 20;
Tmid = Tmid(keep); Imed = Imed(keep); Nbin = Nbin(keep);
fprintf('Fit bins: %d (torque range %.0f-%.0f Nm)\n', numel(Tmid), min(Tmid), max(Tmid));

%% Forward MTPA model: Is_pred(T; psim, deltaL)
iq_grid = linspace(0, 900, 4000);

function Is = mtpa_forward(Tq_query, psim, deltaL, p, iq_grid)
    a = psim / (2*deltaL);
    id_grid = a - sqrt(a^2 + iq_grid.^2);
    T_grid  = 1.5*p*(psim*iq_grid + (-deltaL)*id_grid.*iq_grid);  % Ld-Lq = -deltaL
    [T_grid, ia] = unique(T_grid, 'stable');
    iq_g = iq_grid(ia); id_g = id_grid(ia);
    iq_q = interp1(T_grid, iq_g, Tq_query, 'linear', 'extrap');
    id_q = interp1(T_grid, id_g, Tq_query, 'linear', 'extrap');
    Is = sqrt(id_q.^2 + iq_q.^2);
end

cost = @(x) sum(Nbin .* (mtpa_forward(Tmid, x(1), x(2), p_bolt, iq_grid) - Imed).^2);

x0 = [CR.psim, CR.Lq - CR.Ld];
fprintf('Initial: psim=%.4f deltaL=%.6g -> cost=%.3g\n', x0(1), x0(2), cost(x0));

opts = optimset('Display', 'iter', 'MaxFunEvals', 2000, 'MaxIter', 2000, 'TolX', 1e-8, 'TolFun', 1e-6);
x_fit = fminsearch(cost, x0, opts);

psim_fit   = x_fit(1);
deltaL_fit = x_fit(2);
Lq_fit = deltaL_fit / (1 - ratio_LdLq);
Ld_fit = ratio_LdLq * Lq_fit;

fprintf('\n=== FIT RESULT ===\n');
fprintf('psi_m : %.4f Wb  (literal was %.4f, %+.1f%%)\n', psim_fit, CR.psim, 100*(psim_fit-CR.psim)/CR.psim);
fprintf('deltaL: %.6g H   (literal was %.6g)\n', deltaL_fit, CR.Lq-CR.Ld);
fprintf('Ld    : %.6g H  (literal was %.6g)\n', Ld_fit, CR.Ld);
fprintf('Lq    : %.6g H  (literal was %.6g)\n', Lq_fit, CR.Lq);

%% Validate fit against binned data and full point cloud
Is_pred_bins = mtpa_forward(Tmid, psim_fit, deltaL_fit, p_bolt, iq_grid);
err_bins = Is_pred_bins - Imed;
fprintf('\nBinned fit RMSE: %.2f A,  MAPE: %.1f%%\n', sqrt(mean(err_bins.^2)), mean(abs(err_bins)./Imed)*100);

Is_pred_full = mtpa_forward(Tq, psim_fit, deltaL_fit, p_bolt, iq_grid);
err_full = Is_pred_full - Is_m;
fprintf('Full near-MTPA set (N=%d) RMSE: %.2f A, MAPE: %.1f%%, bias: %.2f A\n', ...
    numel(Tq), sqrt(mean(err_full.^2)), mean(abs(err_full)./max(Is_m,1))*100, mean(err_full));

fprintf('\nBy torque band (refit):\n');
edges2 = [20 60 100 150 200 300 500];
for b = 1:numel(edges2)-1
    m = Tq >= edges2(b) & Tq < edges2(b+1);
    if sum(m) > 5
        im = mean(Is_m(m)); ip = mean(Is_pred_full(m));
        fprintf('%4d-%4d Nm  N=%7d  I_meas=%7.1f  I_pred=%7.1f  err=%+6.1f%%\n', ...
            edges2(b), edges2(b+1), sum(m), im, ip, 100*(ip-im)/im);
    end
end

%% Save
out.psim_fit = psim_fit; out.deltaL_fit = deltaL_fit;
out.Ld_fit = Ld_fit; out.Lq_fit = Lq_fit;
out.Rs = CR.Rs; out.p = p_bolt;
out.Tmid = Tmid; out.Imed = Imed; out.Nbin = Nbin;
out.fit_rmse_binned = sqrt(mean(err_bins.^2));
out.fit_mape_full = mean(abs(err_full)./max(Is_m,1))*100;
out.n_points_used = numel(Tq);
out.method = 'nonlinear LSQ (fminsearch) of psi_m, deltaL=Lq-Ld vs median-binned Is(T), near-MTPA points (20<T<max, 50<rpm<3500), N bins weighted by count. Ld/Lq split preserves literal saliency ratio.';
out.source = '2020 Chevrolet Bolt ANL dyno data, 46 files, 738581 loaded points';

save(fullfile(proj_root, 'results', 'BoltEV_2020_motor_param_fit.mat'), 'out');
fprintf('\nSaved: results/BoltEV_2020_motor_param_fit.mat\n');
fprintf('=== Done ===\n');
