function [Dt, Ds, Di, Rres] = AE_lmdi_pair(A, B, pres_tol)
%AE_LMDI_PAIR  Additive LMDI-I over e(r) = S(r)*I(r) with exact
%  zero-regime handling:
%    both present  -> standard log-mean terms
%    emerging in B -> +e_B(r) fully structural (intensity-unchanged
%                     convention, Ang & Liu 2007 limit)
%    disappearing  -> -e_A(r) fully structural
%  Residual is machine-precision zero by construction (verified 17 Jul
%  2026 across all 45 matrix pairs, MATLAB vs Python).
%
%  Shared by: AE_run_LMDI_matrix.m, FW_boundary_comparison.m
%  (extracted 17 Jul 2026 from AE_run_LMDI_matrix.m local function,
%  body identical to the verified version).
%
%  Author: F. Shah Khan, University of East London, July 2026
% -------------------------------------------------------------------------
    Ds = 0; Di = 0;
    for r = 1:3
        pA = A.S(r) > pres_tol;  pB = B.S(r) > pres_tol;
        if ~pA && ~pB, continue; end
        if pA && pB
            eA = A.e(r); eB = B.e(r);
            if abs(eB - eA) < 1e-12
                L = eA;
            else
                L = (eB - eA) / (log(eB) - log(eA));
            end
            Ds = Ds + L * log(B.S(r)/A.S(r));
            Di = Di + L * log(B.I(r)/A.I(r));
        elseif pB
            Ds = Ds + B.e(r);
        else
            Ds = Ds - A.e(r);
        end
    end
    Dt   = sum(B.e) - sum(A.e);
    Rres = Dt - Ds - Di;
end
