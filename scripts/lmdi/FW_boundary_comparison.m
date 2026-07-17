%% FW_boundary_comparison.m — Improvement 1: CRG boundary as methodological contribution
%
%  Demonstrates that LMDI regime attribution is sensitive to the
%  field-weakening boundary method. Three boundary definitions are
%  compared at g=9.04 across all five verified drive cycles:
%
%    M1: Back-EMF limit — omega_e = V_dc / (sqrt(3) * psi_m)
%        Constant RPM for all torques. Ignores saliency and load current.
%
%    M2: d-q voltage equation at id=0, iq from torque
%        Accounts for current magnitude but not MTPA trajectory.
%
%    M3: CRG LUT Id-departure criterion (10A threshold)
%        Exact MTPA operating point, full saliency, k_Vmax margin.
%        Three voltage levels: 350 V, 370 V (baseline), 400 V.
%
%  Uses the same verified infrastructure as AE_run_LMDI_matrix.m:
%    - AE_lmdi_decomposition.m (delegates to AE_regime_binning.m)
%    - AE_fold_regimes.m (sub-1% regime folding)
%    - AE_lmdi_pair.m (zero-regime handling, Ang & Liu 2007)
%
%  NO simulation. Loads 5 verified g=9.04 files (tag tesla-matrix-
%  complete-v26) and re-bins each under every boundary variant.
%
%  Output: sensitivity table (Paper Section 2.X) showing that the
%  UDDS->US06 structural share swings from 21% (M1) to 78% (M3_370)
%  depending solely on boundary method.
%
%  Cross-check: FW_boundary_expected_values.md (Python prototype).
%
%  Author: F. Shah Khan, University of East London, July 2026
% -------------------------------------------------------------------------

clear; clc;
script_dir = fileparts(mfilename('fullpath'));
proj_root  = char(java.io.File(fullfile(script_dir, '..', '..')).getCanonicalPath());
addpath(script_dir);

fprintf('\n================================================================\n');
fprintf(' FW BOUNDARY COMPARISON — Improvement 1 (Paper Section 2.X)\n');
fprintf(' Started: %s\n', datestr(now));
fprintf('================================================================\n\n');

%% Parameters (identical to AE_run_LMDI_matrix.m)
wheel_r   = 0.326;
eta_drive = 0.90;
fold_tol  = 0.01;
pres_tol  = 1e-9;
gear      = 9.04;
rlbl      = {'MTPA','Trans','FW'};
c_names   = {'UDDS','HWFET','US06','WLTP','Artemis'};

%% Load FW boundary variants
BV = load(fullfile(proj_root, 'model', 'FW_boundary_variants.mat'));
tq_grid = BV.tq_Nm(:);
v_names = {'M1_370','M2_370','M3_350','M3_370','M3_400'};
nv = numel(v_names);
nc = numel(c_names);

fprintf('Boundary variants loaded: %d curves, %d torque breakpoints\n', nv, numel(tq_grid));
for vi = 1:nv
    rpm_v = BV.(v_names{vi});
    fprintf('  %-8s  zero-torque onset: %.2f RPM = %.1f km/h at g=%.2f\n', ...
        v_names{vi}, rpm_v(1), rpm_v(1)*2*pi/60 * wheel_r/gear * 3.6, gear);
end

%% Load the 5 verified g=9.04 files
res = @(f) fullfile(proj_root, 'results', 'tesla_g9.04', f);
fnames = { ...
    res('BMS_UDDS_v26_g9.04_20260716_191321.mat'), ...
    res('BMS_HWFET_v26_g9.04_20260717_040227.mat'), ...
    res('BMS_US06_v26_20260711_231029.mat'), ...
    res('BMS_WLTP_v26_20260712_065209.mat'), ...
    res('BMS_ArtemisMW130_v26_g9.04_20260715_100638.mat')};

fprintf('\nLoading %d verified g=9.04 files...\n', nc);
DATA = cell(1, nc);
for ci = 1:nc
    f = fnames{ci};
    assert(exist(f,'file')==2, 'Missing verified file: %s', f);
    D = load(f, 'P_batt', 'v_spd', 't_batt');
    DATA{ci} = D;
    fprintf('  %-8s  %d samples, %.1f s\n', c_names{ci}, numel(D.t_batt), D.t_batt(end));
end

%% 1. Per-cell regime decomposition under each boundary variant
CELLS = cell(nv, nc);   % CELLS{vi, ci} = struct from AE_lmdi_decomposition + fold

fprintf('\n================================================================\n');
fprintf(' PER-CELL REGIME DECOMPOSITION (motor level)\n');
fprintf('================================================================\n');

for vi = 1:nv
    fw_tq  = tq_grid;
    fw_rpm = BV.(v_names{vi})(:);
    fprintf('\n--- %s ---\n', v_names{vi});
    for ci = 1:nc
        D = DATA{ci};
        R = AE_lmdi_decomposition(D.P_batt, D.v_spd, D.t_batt, ...
                fw_tq, fw_rpm, eta_drive, wheel_r, gear);
        R = AE_fold_regimes(R, fold_tol);
        CELLS{vi, ci} = R;
        fprintf('%-8s dk=%6.2f Ept=%6.1f S=[%5.1f %4.1f %5.1f]%% I=[%6.1f %6.1f %6.1f] e=[%7.4f %7.4f %7.4f]\n', ...
            c_names{ci}, R.dk, R.Ept, 100*R.S, R.I, R.e);
    end
end

%% 2. FW distance shares table
fprintf('\n================================================================\n');
fprintf(' FW DISTANCE SHARES (%%)\n');
fprintf('================================================================\n');
fprintf('%-10s %8s %8s %8s %8s %8s\n', 'Variant', c_names{:});
for vi = 1:nv
    fw_pct = zeros(1, nc);
    for ci = 1:nc
        fw_pct(ci) = CELLS{vi, ci}.S(3) * 100;
    end
    fprintf('%-10s %8.1f %8.1f %8.1f %8.1f %8.1f\n', v_names{vi}, fw_pct);
end

%% 3. Verify: net intensity is invariant across variants
fprintf('\n================================================================\n');
fprintf(' NET INTENSITY CHECK (Ept must be identical across variants)\n');
fprintf('================================================================\n');
Ept_ref = zeros(1, nc);
for ci = 1:nc
    Ept_ref(ci) = CELLS{1, ci}.Ept;
end
fprintf('Reference (M1_370): '); fprintf('%.2f  ', Ept_ref); fprintf('\n');
ept_ok = true;
for vi = 2:nv
    for ci = 1:nc
        diff = abs(CELLS{vi, ci}.Ept - Ept_ref(ci));
        if diff > 0.01
            fprintf('  MISMATCH: %s %s Ept=%.2f vs ref %.2f\n', ...
                v_names{vi}, c_names{ci}, CELLS{vi, ci}.Ept, Ept_ref(ci));
            ept_ok = false;
        end
    end
end
if ept_ok
    fprintf('All variants match to 0.01 Wh/km — boundary changes classification, not physics. OK\n');
else
    error('Ept mismatch across variants — this should be impossible.');
end

%% 4. LMDI sensitivity — headline pairs: UDDS->US06, UDDS->Artemis
fprintf('\n================================================================\n');
fprintf(' LMDI SENSITIVITY TABLE — UDDS->US06 and UDDS->Artemis\n');
fprintf('================================================================\n');
fprintf('%-10s | %8s %8s %8s %8s %10s | %8s %8s %8s %8s %10s\n', ...
    'Variant', 'Dt(U6)', 'Ds(U6)', 'Di(U6)', 'Ssh(U6)', 'R(U6)', ...
    'Dt(Art)', 'Ds(Art)', 'Di(Art)', 'Ssh(Art)', 'R(Art)');
fprintf('%-10s-+-%s-+-%s\n', repmat('-',1,10), repmat('-',1,47), repmat('-',1,47));

LMDI = struct('variant',{},'pair',{},'Dt',{},'Ds',{},'Di',{},'R',{},'Ssh',{});
idx_UDDS = 1;  idx_US06 = 3;  idx_Art = 5;

for vi = 1:nv
    A = CELLS{vi, idx_UDDS};

    % UDDS -> US06
    B = CELLS{vi, idx_US06};
    [Dt_u, Ds_u, Di_u, R_u] = AE_lmdi_pair(A, B, pres_tol);
    if abs(Dt_u) > 1e-9, ssh_u = 100*Ds_u/Dt_u; else, ssh_u = 0; end
    LMDI(end+1) = struct('variant',v_names{vi},'pair','UDDS->US06', ...
        'Dt',Dt_u,'Ds',Ds_u,'Di',Di_u,'R',R_u,'Ssh',ssh_u); %#ok<SAGROW>

    % UDDS -> Artemis
    B = CELLS{vi, idx_Art};
    [Dt_a, Ds_a, Di_a, R_a] = AE_lmdi_pair(A, B, pres_tol);
    if abs(Dt_a) > 1e-9, ssh_a = 100*Ds_a/Dt_a; else, ssh_a = 0; end
    LMDI(end+1) = struct('variant',v_names{vi},'pair','UDDS->Artemis', ...
        'Dt',Dt_a,'Ds',Ds_a,'Di',Di_a,'R',R_a,'Ssh',ssh_a); %#ok<SAGROW>

    fprintf('%-10s | %+8.2f %+8.2f %+8.2f %7.1f%% %10.2e | %+8.2f %+8.2f %+8.2f %7.1f%% %10.2e\n', ...
        v_names{vi}, Dt_u, Ds_u, Di_u, ssh_u, R_u, Dt_a, Ds_a, Di_a, ssh_a, R_a);
end

%% 5. All cross-cycle pairs per variant (for completeness / appendix)
fprintf('\n================================================================\n');
fprintf(' ALL CROSS-CYCLE PAIRS (within g=9.04) per variant\n');
fprintf('================================================================\n');

pairs_c = nchoosek(1:nc, 2);
XCYC = struct('variant',{},'pair',{},'Dt',{},'Ds',{},'Di',{},'R',{});

for vi = 1:nv
    fprintf('\n--- %s ---\n', v_names{vi});
    fprintf('  %-18s %8s %8s %8s %8s %10s\n', 'Pair', 'Dt', 'Ds', 'Di', 'Ssh', 'Residual');
    for pp = 1:size(pairs_c, 1)
        A = CELLS{vi, pairs_c(pp,1)};
        B = CELLS{vi, pairs_c(pp,2)};
        [Dt, Ds, Di, Rres] = AE_lmdi_pair(A, B, pres_tol);
        if abs(Dt) > 1e-9, ssh = 100*Ds/Dt; else, ssh = 0; end
        pname = sprintf('%s->%s', c_names{pairs_c(pp,1)}, c_names{pairs_c(pp,2)});
        XCYC(end+1) = struct('variant',v_names{vi},'pair',pname, ...
            'Dt',Dt,'Ds',Ds,'Di',Di,'R',Rres); %#ok<SAGROW>
        fprintf('  %-18s %+8.2f %+8.2f %+8.2f %7.1f%% %10.2e\n', ...
            pname, Dt, Ds, Di, ssh, Rres);
    end
end

%% 6. Residual check
allR = [LMDI.R];
xcR  = [XCYC.R];
allR = [allR xcR];
fprintf('\n================================================================\n');
fprintf(' RESIDUAL CHECK\n');
fprintf('================================================================\n');
fprintf('Max |residual| over %d headline + %d cross-cycle pairs: %.3e Wh/km ', ...
    numel([LMDI.R]), numel(xcR), max(abs(allR)));
if max(abs(allR)) < 1e-6
    fprintf('(LMDI exact) OK\n');
else
    fprintf('- INVESTIGATE\n');
end

%% 7. Cross-check against Python prototype (FW_boundary_expected_values.md)
fprintf('\n================================================================\n');
fprintf(' CROSS-CHECK vs PYTHON PROTOTYPE\n');
fprintf('================================================================\n');

% Expected headline values from Python (FW_boundary_expected_values.md)
%               Ds_U6    Di_U6    Ds_Art   Di_Art
expected = [ ...
    +11.07,  +42.00,  +38.75,  +27.27;  % M1_370
    +37.84,  +15.24,  +45.51,  +20.51;  % M2_370
    +54.38,   -1.30,  +58.30,   +7.73;  % M3_350
    +41.19,  +11.89,  +52.62,  +13.41;  % M3_370
    +22.37,  +30.71,  +47.43,  +18.60]; % M3_400

xcheck_ok = true;
for vi = 1:nv
    % Find headline LMDI entries for this variant
    idx_u = find(strcmp({LMDI.variant}, v_names{vi}) & strcmp({LMDI.pair}, 'UDDS->US06'));
    idx_a = find(strcmp({LMDI.variant}, v_names{vi}) & strcmp({LMDI.pair}, 'UDDS->Artemis'));

    diffs = [ ...
        abs(LMDI(idx_u).Ds - expected(vi,1)), ...
        abs(LMDI(idx_u).Di - expected(vi,2)), ...
        abs(LMDI(idx_a).Ds - expected(vi,3)), ...
        abs(LMDI(idx_a).Di - expected(vi,4))];

    maxd = max(diffs);
    if maxd < 0.05
        fprintf('%-10s max diff = %.4f Wh/km  MATCH\n', v_names{vi}, maxd);
    else
        fprintf('%-10s max diff = %.4f Wh/km  MISMATCH — check FW_boundary_expected_values.md\n', ...
            v_names{vi}, maxd);
        xcheck_ok = false;
    end
end

if xcheck_ok
    fprintf('\nAll variants match Python prototype to 0.05 Wh/km. Cross-check PASSED.\n');
else
    fprintf('\nCross-check FAILED — investigate before using results.\n');
end

%% 8. Expected FW shares cross-check
fprintf('\n--- FW share cross-check ---\n');
expected_fw = [ ...
    0.0, 0.0,  6.4, 13.1, 47.8;  % M1_370
    0.0, 0.0, 13.4, 16.0, 54.9;  % M2_370
    0.0, 0.0, 51.5, 25.6, 80.1;  % M3_350
    0.0, 0.0, 36.3, 21.4, 70.3;  % M3_370
    0.0, 0.0, 11.5, 15.9, 54.1]; % M3_400

fw_ok = true;
for vi = 1:nv
    for ci = 1:nc
        actual = CELLS{vi, ci}.S(3) * 100;
        diff = abs(actual - expected_fw(vi, ci));
        if diff > 0.15
            fprintf('  %s %s: actual=%.1f expected=%.1f diff=%.2f MISMATCH\n', ...
                v_names{vi}, c_names{ci}, actual, expected_fw(vi,ci), diff);
            fw_ok = false;
        end
    end
end
if fw_ok
    fprintf('All FW shares match to 0.15 pp. OK\n');
else
    fprintf('FW share mismatch — investigate.\n');
end

%% 9. Save
out = fullfile(proj_root, 'results', 'FW_boundary_comparison.mat');
save(out, 'CELLS', 'LMDI', 'XCYC', 'v_names', 'c_names', 'rlbl', ...
     'tq_grid', 'eta_drive', 'fold_tol', 'gear');
fprintf('\nSaved: %s\n', out);

fprintf('\n================================================================\n');
fprintf(' COMPLETE: %s\n', datestr(now));
fprintf(' Paper Section 2.X: CRG boundary (M3) gives materially\n');
fprintf(' different LMDI attribution than simplified methods (M1/M2).\n');
fprintf(' Structural share of UDDS->US06 gap: 21%% (M1) vs 78%% (M3_370).\n');
fprintf('================================================================\n');
