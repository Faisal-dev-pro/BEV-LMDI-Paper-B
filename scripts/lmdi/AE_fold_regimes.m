function R = AE_fold_regimes(R, fold_tol)
%AE_FOLD_REGIMES  Fold regimes with distance share < fold_tol into the
%  adjacent regime (FW -> Trans -> MTPA), then recompute S, I, e.
%  Prevents near-absent slivers with noisy intensities from dominating
%  LMDI log ratios. Documented in the methods section.
%
%  Shared by: AE_run_LMDI_matrix.m, FW_boundary_comparison.m
%  (extracted 17 Jul 2026 from AE_run_LMDI_matrix.m local function,
%  body identical to the verified version).
%
%  Author: F. Shah Khan, University of East London, July 2026
% -------------------------------------------------------------------------
    for r = [3 2]
        if R.S(r) > 0 && R.S(r) < fold_tol
            R.d(r-1) = R.d(r-1) + R.d(r);   R.d(r) = 0;
            R.E(r-1) = R.E(r-1) + R.E(r);   R.E(r) = 0;
        end
    end
    for r = 1:3
        R.S(r) = R.d(r) / R.dk;
        if R.d(r) > 0.001, R.I(r) = R.E(r) / R.d(r); else, R.I(r) = 0; end
        R.e(r) = R.S(r) * R.I(r);
    end
end
