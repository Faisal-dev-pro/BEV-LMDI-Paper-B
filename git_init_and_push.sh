#!/bin/bash
# ============================================================================
# git_init_and_push.sh
# Initializes the Paper B repo with ONLY Tier 1 reviewer-essential files.
# Excludes: ANL raw data, manuscript (under review), copyrighted PDFs,
#           internal dashboards, positioning docs, audit trails, stale results.
#
# Usage:  cd /Users/fsk/Documents/MATLAB/BEV_LMDI_Paper_B
#         bash git_init_and_push.sh
#
# Requires: git, GitHub CLI (gh) or SSH key for push
# ============================================================================

set -euo pipefail

REPO_DIR="/Users/fsk/Documents/MATLAB/BEV_LMDI_Paper_B"
REMOTE="https://github.com/Faisal-dev-pro/BEV-LMDI-Paper-B.git"

cd "$REPO_DIR"

# ── Clean any broken .git from sandbox attempt ──
if [ -d ".git" ]; then
    echo "Removing stale .git directory..."
    rm -rf .git
fi

# ── Init ──
echo "[1/5] Initializing repository..."
git init -b main
git config user.name "Faisal Shah Khan"
git config user.email "fskhub@gmail.com"

# ── Stage files ──
echo "[2/5] Staging Tier 1 files..."

# Core: .gitignore + README
git add .gitignore
git add README.md

# Model (no legacy AE_v25_Run.m)
git add model/AE_TeslaM3_LMDI.slx
git add model/AE_TeslaM3_LMDI_Params.m
git add model/onepedal_regen_sfcn.m
git add model/FW_onset_curve.mat
git add model/IPMSM_CurrentRef_LUT.mat
git add model/TeslaM3_CurrentRefs.mat

# All scripts
git add scripts/

# Drive cycle schedules
git add data/drive_cycles/

# Validation targets
git add docs/Validation_Targets.md

# Canonical results only — one .mat per cycle-config pair
# g=9.04 baseline (4 cycles: UDDS, US06, WLTP, Artemis)
git add results/tesla_g9.04/BMS_UDDS_v26_20260710_190022.mat
git add results/tesla_g9.04/BMS_US06_v26_20260711_231029.mat
git add results/tesla_g9.04/BMS_WLTP_v26_20260712_065209.mat
git add results/tesla_g9.04/BMS_Artemis_MW130_v26_20260710_135939.mat

# g=7.0 (3 cycles: UDDS, US06, WLTP — Artemis corrupted, excluded)
git add results/tesla_g7.0/BMS_UDDS_v26_g7.0_20260713_021559.mat
git add results/tesla_g7.0/BMS_US06_v26_g7.0_20260712_144011.mat
git add results/tesla_g7.0/BMS_WLTP_v26_g7.0_20260713_081328.mat

# g=11.0 (3 cycles: UDDS, US06, WLTP)
git add results/tesla_g11.0/BMS_UDDS_v26_g11.0_20260714_092637.mat
git add results/tesla_g11.0/BMS_US06_v26_g11.0_20260714_001504.mat
git add results/tesla_g11.0/BMS_WLTP_v26_g11.0_20260714_172410.mat

# ── Verify staging ──
echo ""
echo "[3/5] Staged files:"
git diff --cached --name-only
TOTAL=$(git diff --cached --name-only | wc -l | tr -d ' ')
echo ""
echo "Total: $TOTAL files"

# ── Commit ──
echo ""
echo "[4/5] Committing..."
git commit -m "Initial commit: v26 model, LMDI scripts, gear ratio sweep results

Simulink model (v26) with CRG-derived field-weakening boundary,
one-pedal regen S-Function, and BMS-level validation pipeline.

Includes:
- Tesla Model 3 IPMSM model and parameters
- LMDI-I decomposition scripts (regime binning, loss decomposition)
- Gear ratio sweep run scripts (g=7.0, 9.04, 11.0)
- BMS validation postprocessing (ANL D3 targets)
- Canonical results: 10 cycle-config pairs (UDDS/US06/WLTP/Artemis)
- Drive cycle schedules (UDDS, WLTP Class 3b)

Validated against ANL dynamometer data at BMS level (20-25C).
Paper A: ECMX-D-26-01632 (under review).
Paper B: Applied Energy (in preparation)."

# ── Push ──
echo ""
echo "[5/5] Pushing to GitHub..."
git remote add origin "$REMOTE"
git push -u origin main

echo ""
echo "================================================================"
echo "  Done. Repository: $REMOTE"
echo "  Files committed: $TOTAL"
echo "================================================================"
