%% AE_Generate_Figures.m — Paper B (Results in Engineering) figures
% Results in Engineering publication figures — all exported as vector PDF
% Paste into MATLAB workspace or run as script.
%
% Output:  Figures/Fig1_Topology.pdf  … Figures/Fig7_idiq.pdf
% Format:  vector PDF (resolution-independent, satisfies AE 1000 dpi line-art rule)
% Width:   190 mm full-page, 90 mm single-column where noted
%
% Requires: model/*.mat files listed below
% Run from: BEV_LMDI_Decomposition root folder

clear; clc;

%% ── 0. PATHS AND SETUP ──────────────────────────────────────────────────
% Locate project root regardless of whether script is run from scripts/ or root
script_dir = fileparts(which('AE_Generate_Figures.m'));
if isempty(script_dir)
    script_dir = pwd;
end
% If we are inside scripts/, go up one level to the project root
[~, last_folder] = fileparts(script_dir);
if strcmpi(last_folder, 'scripts')
    root = fileparts(script_dir);
else
    root = script_dir;
end
mdl    = fullfile(root, 'model');
outDir = fullfile(root, 'Figures');
if ~exist(outDir,'dir'), mkdir(outDir); end

% ── AE column widths in centimetres ──────────────────────────────────────
W_full = 19.0;   % 190 mm  full page
W_half =  9.0;   % 90 mm   single column

% ── House style ──────────────────────────────────────────────────────────
FONT   = 'Arial';
FS     = 8;       % body font size (pt) — AE minimum is 6 pt
LW     = 1.2;     % line width (pt)
clrs   = [0.12 0.47 0.71;   % blue  — MTPA
          0.50 0.00 0.50;   % purple — Transition
          0.84 0.15 0.16];  % red   — FW
cyc_clr = [0.00 0.45 0.70;  % HWFET (blue)
            0.84 0.37 0.01;  % US06  (orange)
            0.00 0.62 0.45]; % WLTP  (green)

%% ── EXPORT HELPER ───────────────────────────────────────────────────────
function export_fig(fig, filepath, w_cm, h_cm)
    fig.Units           = 'centimeters';
    fig.Position        = [2, 2, w_cm, h_cm];
    fig.PaperUnits      = 'centimeters';
    fig.PaperSize       = [w_cm, h_cm];
    fig.PaperPosition   = [0, 0, w_cm, h_cm];
    exportgraphics(fig, filepath, 'ContentType', 'vector', ...
                   'BackgroundColor', 'white');
    fprintf('Saved: %s\n', filepath);
end

%% ── LOAD DATA ───────────────────────────────────────────────────────────
fprintf('Loading .mat files...\n');

% LMDI results
LR  = load(fullfile(mdl, 'LMDI_results.mat'));
% Cycle signals
HW  = load(fullfile(mdl, 'HWFET_signals.mat'));   % Pb_hw, t_hw, vS_hw
US  = load(fullfile(mdl, 'US06_signals.mat'));     % Pb_us06, t_us06, vS_us06
% WLTP speed signal
WL  = load(fullfile(mdl, 'WLTP_signals.mat'));
% FW onset curve
FWC = load(fullfile(mdl, 'FW_onset_curve.mat'));       % fw_tq_Nm, fw_rpm_mech
% CRG current-reference lookup table
LUT = load(fullfile(mdl, 'IPMSM_CurrentRef_LUT.mat')); % ID_MAP, IQ_MAP, RPM_VECT, TQ_VECT

% ── Drive cycle reference schedules (EPA standard, km/h) ─────────────────
% Read directly from the ANL test CSVs that are already in model/test_data/
% If they are missing, fall back to the simulated traces (no reference overlay)
td = fullfile(mdl, 'test_data');

function s = try_load_anl(fpath)
    % ANL columns (1-indexed): 1=Time[s]_RawFacilities, 2=Dyno_Spd[mph],
    %   19=Drive_Trace_Schedule[mph], 20=Phase_number
    s.t_s = []; s.v_kmh = []; s.phase = [];
    if ~exist(fpath,'file'), return; end
    T = readtable(fpath, 'VariableNamingRule','preserve', ...
                  'FileType','text', 'Delimiter','\t');
    s.t_s   = T{:,1};                  % Time[s]_RawFacilities
    s.v_kmh = T{:,2} * 1.60934;        % Dyno_Spd[mph] → km/h
    s.phase = T{:,20};                  % Phase_number
end

hwfet_ref = try_load_anl(fullfile(td,'62005022_Test_Data.txt'));
us06_ref  = try_load_anl(fullfile(td,'62005024_Test_Data.txt'));
wltp_ref  = try_load_anl(fullfile(td,'62006002_Test_Data.txt'));

% For each cycle keep only Phase 1 (integer phase = 1)
function s = filter_phase1(s)
    if isempty(s.t_s), return; end
    mask    = floor(s.phase) == 1 & s.phase == floor(s.phase);
    s.t_s   = s.t_s(mask);
    s.v_kmh = s.v_kmh(mask);
    s.t_s   = s.t_s - s.t_s(1);   % start at t=0
end
hwfet_ref = filter_phase1(hwfet_ref);
us06_ref  = filter_phase1(us06_ref);
% WLTP: keep phases 5-8 (sub-phases of full WLTP)
if ~isempty(wltp_ref.t_s)
    mask_wl      = ismember(floor(wltp_ref.phase), 5:8) & ...
                   wltp_ref.phase == floor(wltp_ref.phase);
    wltp_ref.t_s   = wltp_ref.t_s(mask_wl);
    wltp_ref.v_kmh = wltp_ref.v_kmh(mask_wl);
    wltp_ref.t_s   = wltp_ref.t_s - wltp_ref.t_s(1);
end

fprintf('Data loaded.\n\n');

% ── Derived quantities ───────────────────────────────────────────────────
% Speed from simulation (vS_hw is negative-forward convention; abs to km/h)
t_hw   = HW.t_hw(:);
v_hw   = abs(HW.vS_hw(:)) * 3.6;     % m/s → km/h
Pb_hw  = HW.Pb_hw(:);

t_us   = US.t_us06(:);
v_us   = abs(US.vS_us06(:)) * 3.6;
Pb_us  = US.Pb_us06(:);

dt_wl  = 0.1;
t_wl   = (0 : length(WL.Pbatt_ws)-1)' * dt_wl;
Pb_wl  = WL.Pbatt_ws(:);
% WLTP speed: interpolate from ANL reference if available, else use zeros
if ~isempty(wltp_ref.t_s)
    v_wl = interp1(wltp_ref.t_s(:), wltp_ref.v_kmh(:), t_wl, 'linear', 'extrap');
    v_wl = max(v_wl, 0);
else
    warning('WLTP ANL CSV not found in model/test_data/ — speed profile will be missing from Fig 2.');
    v_wl = zeros(size(t_wl));
end

% FW onset curve
fw_rpm = FWC.fw_rpm_mech(:) * 60 / (2*pi);        % rad/s mech → RPM
fw_spd = fw_rpm ./ 60 .* (2*pi) .* 0.326 ./ 9.04 .* 3.6; % RPM → km/h
fw_tq  = FWC.fw_tq_Nm(:);

% CRG id-iq locus (MTPA locus from LUT)
id_mtpa = LUT.ID_MAP(:, 1);   % column 1 = lowest RPM = MTPA condition
iq_mtpa = LUT.IQ_MAP(:, 1);

%% ── FIGURE 1: Powertrain topology block diagram ──────────────────────────
fprintf('Generating Fig 1...\n');

fig1 = figure('Visible','off','Units','centimeters','Position',[0 0 19 8.5]);
ax1  = axes(fig1,'Position',[0 0 1 1]);
set(ax1,'XLim',[0 19],'YLim',[0 8.5],'Visible','off');
hold(ax1,'on');

% Layout
BW1=2.30; BHp1=1.40; BHc1=1.05; Yp1=5.30; Yc1=1.30;
Xphy1=[0.20,3.30,6.40,9.50,12.60,15.60];
Xctl1=[3.30,6.40,12.60,15.60];
cxP1=Xphy1+BW1/2; cxC1=Xctl1+BW1/2;
cyP1=Yp1+BHp1/2; cyC1=Yc1+BHc1/2;
Cp1=[0.17 0.45 0.70]; Cc1=[0.84 0.37 0.01]; Cm1=[0.20 0.63 0.17];
Cr1=[0.55 0.55 0.55]; Ca1=[0.12 0.12 0.12];

% Physical boxes
f1_pbox(ax1,Xphy1(1),Yp1,BW1,BHp1,Cp1,'Battery',  '75 kWh',        FONT,FS);
f1_pbox(ax1,Xphy1(2),Yp1,BW1,BHp1,Cp1,'Inverter', '(VSI)',         FONT,FS);
f1_pbox(ax1,Xphy1(3),Yp1,BW1,BHp1,Cp1,'IPMSM',    'Tesla M3 Rear', FONT,FS);
f1_pbox(ax1,Xphy1(4),Yp1,BW1,BHp1,Cp1,'Gearbox',  'i_g = 9.04',   FONT,FS);
f1_pbox(ax1,Xphy1(5),Yp1,BW1,BHp1,Cp1,'Vehicle',  'm = 1928 kg',   FONT,FS);
rectangle('Parent',ax1,'Position',[Xphy1(6) Yp1 BW1 BHp1],...
    'FaceColor',[0.92 0.92 0.92],'EdgeColor',Cr1,'LineWidth',0.8,'LineStyle','--','Curvature',0.08);
text(ax1,cxP1(6),Yp1+BHp1*0.67,'Road Load','HorizontalAlignment','center','FontName',FONT,'FontSize',FS,'Color',Cr1);
text(ax1,cxP1(6),Yp1+BHp1*0.25,'F = A + Bv + Cv^2','HorizontalAlignment','center','FontName',FONT,'FontSize',FS-2,'Color',Cr1,'Interpreter','tex');

% Control boxes
f1_pbox(ax1,Xctl1(1),Yc1,BW1,BHc1,Cc1,'CRG',           'MTPA / FW',FONT,FS);
f1_pbox(ax1,Xctl1(2),Yc1,BW1,BHc1,Cc1,'VCU',           '',         FONT,FS);
f1_pbox(ax1,Xctl1(3),Yc1,BW1,BHc1,Cc1,'PID Driver',    '',         FONT,FS);
f1_pbox(ax1,Xctl1(4),Yc1,BW1,BHc1,Cc1,'Drive Schedule','',         FONT,FS);
text(ax1,cxC1(4),Yc1-0.22,'HWFET  |  US06  |  WLTP','HorizontalAlignment','center',...
    'FontName',FONT,'FontSize',FS-2,'Color',Cc1,'FontAngle','italic');

% Power arrows (right)
f1_harr(ax1,Xphy1(1)+BW1,Xphy1(2),cyP1,Ca1,'P_{batt}',      FONT,FS-2);
f1_harr(ax1,Xphy1(2)+BW1,Xphy1(3),cyP1,Ca1,'3\phi AC',       FONT,FS-2);
f1_harr(ax1,Xphy1(3)+BW1,Xphy1(4),cyP1,Ca1,'T_{sh},\omega_m',FONT,FS-2);
f1_harr(ax1,Xphy1(4)+BW1,Xphy1(5),cyP1,Ca1,'F,  v',          FONT,FS-2);
f1_harr(ax1,Xphy1(5)+BW1,Xphy1(6),cyP1,Ca1,'',               FONT,FS-2);

% Control arrows (left)
f1_larr(ax1,Xctl1(4),Xctl1(3)+BW1,cyC1,Cc1,'v_{ref}',FONT,FS-2);
f1_larr(ax1,Xctl1(3),Xctl1(2)+BW1,cyC1,Cc1,'F_{cmd}',FONT,FS-2);
f1_larr(ax1,Xctl1(2),Xctl1(1)+BW1,cyC1,Cc1,'T^*',    FONT,FS-2);

% CRG → Inverter (vertical, solid orange)
f1_vline(ax1,cxC1(1),Yc1+BHc1,Yp1,Cc1,'up');
text(ax1,cxC1(1)+0.13,(Yc1+BHc1+Yp1)/2,'i_d^*, i_q^*','HorizontalAlignment','left',...
    'VerticalAlignment','middle','FontName',FONT,'FontSize',FS-2,'Color',Cc1,'Interpreter','tex');

% IPMSM → VCU (dashed green)
f1_vline_dash(ax1,cxP1(3),Yp1,Yc1+BHc1,Cm1,'down');
text(ax1,cxP1(3)-0.13,(Yp1+Yc1+BHc1)/2,'\omega_m','HorizontalAlignment','right',...
    'VerticalAlignment','middle','FontName',FONT,'FontSize',FS-2,'Color',Cm1,'FontAngle','italic','Interpreter','tex');

% Vehicle → PID (dashed green)
f1_vline_dash(ax1,cxP1(5),Yp1,Yc1+BHc1,Cm1,'down');
text(ax1,cxP1(5)+0.13,(Yp1+Yc1+BHc1)/2,'v_{meas}','HorizontalAlignment','left',...
    'VerticalAlignment','middle','FontName',FONT,'FontSize',FS-2,'Color',Cm1,'FontAngle','italic','Interpreter','tex');

% Regen arc (above)
yr1=Yp1+BHp1+0.45;
plot(ax1,[cxP1(5) cxP1(5)],[Yp1+BHp1 yr1],'-','Color',Cm1,'LineWidth',1.0);
plot(ax1,[cxP1(5) cxP1(1)],[yr1 yr1],       '-','Color',Cm1,'LineWidth',1.0);
plot(ax1,[cxP1(1) cxP1(1)],[yr1 Yp1+BHp1], '-','Color',Cm1,'LineWidth',1.0);
f1_ahd(ax1,cxP1(1),Yp1+BHp1,'down',Cm1);
text(ax1,(cxP1(1)+cxP1(5))/2,yr1+0.13,'P_{regen}  (regenerative braking)',...
    'HorizontalAlignment','center','VerticalAlignment','bottom','FontName',FONT,'FontSize',FS-1.5,'Color',Cm1,'Interpreter','tex');

% Legend
lx1=9.90; ly1=4.20; dy1=0.52;
plot(ax1,[lx1 lx1+0.65],[ly1 ly1],'-','Color',Ca1,'LineWidth',1.2);
text(ax1,lx1+0.75,ly1,'Power flow','FontName',FONT,'FontSize',FS-2,'VerticalAlignment','middle');
plot(ax1,[lx1 lx1+0.65],[ly1-dy1 ly1-dy1],'-','Color',Cc1,'LineWidth',1.0);
text(ax1,lx1+0.75,ly1-dy1,'Control signal','FontName',FONT,'FontSize',FS-2,'VerticalAlignment','middle');
plot(ax1,[lx1 lx1+0.65],[ly1-2*dy1 ly1-2*dy1],'--','Color',Cm1,'LineWidth',0.85);
text(ax1,lx1+0.75,ly1-2*dy1,'Feedback / regen','FontName',FONT,'FontSize',FS-2,'VerticalAlignment','middle');

hold(ax1,'off');
export_fig(fig1, fullfile(outDir,'Fig1_PowertrainTopology.pdf'), 19, 8.5);

%% ── FIGURE 2: Three-panel speed profiles with per-timestep regime shading ─
fprintf('Generating Fig 2...\n');

% Load WLTP standard schedule (1 Hz, 1801 pts) for accurate speed profile
SCH    = load(fullfile(mdl, 'WLTP_Class3b_schedule.mat'));
v_wl   = interp1(SCH.t_wltp(:), SCH.v_wltp_kmh(:), t_wl, 'linear', 0);
v_wl   = max(v_wl, 0);
v_wl_ms = v_wl / 3.6;   % m/s for regime assignment

% FW onset vectors (already loaded as FWC)
fw_tq_v  = FWC.fw_tq_Nm(:);
fw_rpm_v = FWC.fw_rpm_mech(:);   % already in RPM
[fw_tq_v, si2] = sort(fw_tq_v);
fw_rpm_v = fw_rpm_v(si2);

G2 = 9.04;  r_w2 = 0.326;  eta2 = 0.90;

% Per-timestep regime assignment
reg_us = f2_regime(Pb_us, abs(US.vS_us06(:)),  G2, r_w2, eta2, fw_tq_v, fw_rpm_v);
reg_hw = f2_regime(Pb_hw, abs(HW.vS_hw(:)),    G2, r_w2, eta2, fw_tq_v, fw_rpm_v);
reg_wl = f2_regime(WL.Pbatt_ws(:), v_wl_ms,   G2, r_w2, eta2, fw_tq_v, fw_rpm_v);

fprintf('  US06  MTPA:%d%%  Trans:%d%%  FW:%d%%\n', ...
    round(100*mean(reg_us==1)), round(100*mean(reg_us==2)), round(100*mean(reg_us==3)));
fprintf('  HWFET MTPA:%d%%  Trans:%d%%  FW:%d%%\n', ...
    round(100*mean(reg_hw==1)), round(100*mean(reg_hw==2)), round(100*mean(reg_hw==3)));
fprintf('  WLTP  MTPA:%d%%  Trans:%d%%  FW:%d%%\n', ...
    round(100*mean(reg_wl==1)), round(100*mean(reg_wl==2)), round(100*mean(reg_wl==3)));

% Regime colours
c2_mtpa  = [0.55 0.78 0.73];
c2_trans = [0.98 0.78 0.28];
c2_fw    = [0.86 0.48 0.45];
clrs2    = [c2_mtpa; c2_trans; c2_fw];

fig2 = figure('Visible','off','Units','centimeters','Position',[0 0 W_full 18]);
tl2  = tiledlayout(fig2, 3, 1, 'Padding','compact', 'TileSpacing','compact');

panels2 = {
    struct('t',t_us,'v',v_us,'reg',reg_us,'ttl','US06 (600 s)',         'ymax',135,'leg',true);
    struct('t',t_hw,'v',v_hw,'reg',reg_hw,'ttl','HWFET (765 s)',        'ymax',100,'leg',false);
    struct('t',t_wl,'v',v_wl,'reg',reg_wl,'ttl','WLTP Class 3 (1800 s)','ymax',135,'leg',false);
};

for ci = 1:3
    P2 = panels2{ci};
    ax2 = nexttile(tl2);
    hold(ax2,'on');
    f2_bg_image(ax2, P2.t, P2.reg, P2.ymax, clrs2, P2.leg);
    plot(ax2, P2.t, P2.v, 'k-', 'LineWidth',1.2, 'HandleVisibility','off');
    hold(ax2,'off');
    xlim(ax2,[0 P2.t(end)]);  ylim(ax2,[0 P2.ymax]);
    xlabel(ax2,'Time (s)',      'FontName',FONT,'FontSize',FS);
    ylabel(ax2,'Speed (km/h)', 'FontName',FONT,'FontSize',FS);
    title(ax2,  P2.ttl,         'FontName',FONT,'FontSize',FS,'FontWeight','bold');
    set(ax2,'FontName',FONT,'FontSize',FS,'Box','on', ...
            'XGrid','on','YGrid','on','GridAlpha',0.25,'Layer','top');
    if P2.leg
        legend(ax2,'Location','northeast','FontName',FONT,'FontSize',FS-1,'NumColumns',3);
    end
end

export_fig(fig2, fullfile(outDir,'Fig2_SpeedProfiles.pdf'), W_full, 18);

%% ── FIGURE 3: Cumulative energy — model vs ANL ──────────────────────────
fprintf('Generating Fig 3...\n');
fig3 = figure('Visible','off');
t3   = tiledlayout(fig3, 1, 2, 'Padding','compact','TileSpacing','compact');

% Panel (a) HWFET
ax3a = nexttile(t3);
dist_hw    = cumsum(abs(HW.vS_hw(:)) * 0.1) / 1000;   % km
Ecum_hw    = cumsum(max(Pb_hw,0) * 0.1) / 3600;       % Wh
Ecum_hw_km = Ecum_hw ./ max(dist_hw, 1e-9);           % Wh/km (running)

% ANL 62005022 Ph1 cumulative (from validation table: 15.45 km, 118.3 Wh/km net)
% Approximate linear target for display
d_anl_hw   = linspace(0, 15.45, 100);
E_anl_hw   = d_anl_hw * 126.5;   % gross Wh/km: 118.3/(1-0.065) = 126.5 (test 62005022)

hold(ax3a,'on');
plot(dist_hw, Ecum_hw, '-',  'Color',cyc_clr(1,:), 'LineWidth',LW, ...
     'DisplayName','Model');
plot(d_anl_hw, E_anl_hw, '--k', 'LineWidth',0.8, 'DisplayName','ANL 62005022 Ph1');
hold(ax3a,'off');
xlabel(ax3a,'Distance (km)','FontName',FONT,'FontSize',FS);
ylabel(ax3a,'Cumulative gross energy (Wh)','FontName',FONT,'FontSize',FS);
title(ax3a,'(a) HWFET','FontName',FONT,'FontSize',FS,'FontWeight','bold');
legend(ax3a,'Location','northwest','FontName',FONT,'FontSize',FS-1);
set(ax3a,'FontName',FONT,'FontSize',FS,'Box','on');
grid(ax3a,'on');

% Panel (b) US06
ax3b = nexttile(t3);
dist_us    = cumsum(abs(US.vS_us06(:)) * 0.1) / 1000;
Ecum_us    = cumsum(max(Pb_us,0) * 0.1) / 3600;
d_anl_us   = linspace(0, 12.47, 100);
E_anl_us   = d_anl_us * 216.5;   % gross Wh/km: 125.3/(1-0.421) = 216.5 (test 62006024)

hold(ax3b,'on');
plot(dist_us, Ecum_us, '-', 'Color',cyc_clr(2,:), 'LineWidth',LW, ...
     'DisplayName','Model');
plot(d_anl_us, E_anl_us, '--k', 'LineWidth',0.8, 'DisplayName','ANL 62006024 Ph1');
hold(ax3b,'off');
xlabel(ax3b,'Distance (km)','FontName',FONT,'FontSize',FS);
ylabel(ax3b,'Cumulative gross energy (Wh)','FontName',FONT,'FontSize',FS);
title(ax3b,'(b) US06','FontName',FONT,'FontSize',FS,'FontWeight','bold');
legend(ax3b,'Location','northwest','FontName',FONT,'FontSize',FS-1);
set(ax3b,'FontName',FONT,'FontSize',FS,'Box','on');
grid(ax3b,'on');

export_fig(fig3, fullfile(outDir,'Fig3_CumulativeEnergy.pdf'), W_full, 7.5);

%% ── FIGURE 4: Distance shares (structural factor S) ─────────────────────
fprintf('Generating Fig 4...\n');
fig4 = figure('Visible','off');
ax4  = axes(fig4);

% S(r,k) from LMDI results [MTPA, Trans, FW]
S = [ LR.HWFET.S; LR.US06.S; LR.WLTP.S ] * 100;  % percent
cyc_lbl  = {'HWFET','US06','WLTP'};
bar_clrs = clrs;   % MTPA=blue, Trans=purple, FW=red

b = bar(ax4, S, 'stacked', 'BarWidth', 0.55);
for ii = 1:3
    b(ii).FaceColor = bar_clrs(ii,:);
    b(ii).EdgeColor = [1 1 1];    % white dividers so thin Transition band is distinct
    b(ii).LineWidth = 0.8;
end
set(ax4,'XTickLabel', cyc_lbl, 'FontName',FONT,'FontSize',FS,'Box','on');
xlabel(ax4,'Drive cycle','FontName',FONT,'FontSize',FS);
ylabel(ax4,'Distance share (%)','FontName',FONT,'FontSize',FS);
title(ax4,'Per-regime distance shares (structural factor $S_{r,k}$)', ...
     'Interpreter','latex','FontName',FONT,'FontSize',FS,'FontWeight','bold');
legend(ax4, {'MTPA','Transition','Field-weakening'}, ...
       'Location','northeastoutside','FontName',FONT,'FontSize',FS-1);
ylim(ax4,[0 115]);
grid(ax4,'on');

% Label FW% just above each bar — only where FW > 0.5%
for ii = 1:3
    if S(ii,3) > 0.5
        text(ax4, ii, 102, sprintf('FW: %.1f%%', S(ii,3)), ...
             'HorizontalAlignment','center','FontName',FONT,'FontSize',FS-1, ...
             'FontWeight','bold');
    end
end

export_fig(fig4, fullfile(outDir,'Fig4_RegimeShares.pdf'), W_half*1.5, 8.0);

%% ── FIGURE 5: LMDI waterfall charts ─────────────────────────────────────
fprintf('Generating Fig 5...\n');
fig5 = figure('Visible','off');
t5   = tiledlayout(fig5, 1, 2, 'Padding','compact','TileSpacing','compact');

% Pair 1: HWFET → US06
Ds_HW_US = -LR.Ds_fix(1);   % structural effect (HWFET→US06)
Di_HW_US = -LR.Di_fix(1);   % intensity effect  (HWFET→US06)

ax5a = nexttile(t5);
cats = categorical({'$\Delta_{\rm str}$','$\Delta_{\rm int}$','$\Delta e$'});
vals = [Ds_HW_US, Di_HW_US, Ds_HW_US + Di_HW_US];
bc   = bar(ax5a, cats, vals, 0.55);
bc.FaceColor = 'flat';
bc.CData(1,:) = [0.84 0.15 0.16];  % structural (red)
bc.CData(2,:) = [0.12 0.47 0.71];  % intensity  (blue)
bc.CData(3,:) = [0.50 0.50 0.50];  % total      (grey)
yline(ax5a, 0, 'k-', 'LineWidth', 0.5);
xlabel(ax5a,'Effect','Interpreter','latex','FontName',FONT,'FontSize',FS);
ylabel(ax5a,'$\Delta e$ (Wh/km)','Interpreter','latex','FontName',FONT,'FontSize',FS);
title(ax5a,'(a) HWFET \rightarrow US06', ...
     'Interpreter','tex','FontName',FONT,'FontSize',FS,'FontWeight','bold');
set(ax5a,'FontName',FONT,'FontSize',FS,'Box','on');
grid(ax5a,'on');

% Pair 2: WLTP → US06
Ds_WL_US = -LR.Ds_fix(2);   % structural effect (WLTP→US06)
Di_WL_US = -LR.Di_fix(2);   % intensity effect  (WLTP→US06)

ax5b = nexttile(t5);
vals2 = [Ds_WL_US, Di_WL_US, Ds_WL_US + Di_WL_US];
bc2   = bar(ax5b, cats, vals2, 0.55);
bc2.FaceColor = 'flat';
bc2.CData(1,:) = [0.84 0.15 0.16];
bc2.CData(2,:) = [0.12 0.47 0.71];
bc2.CData(3,:) = [0.50 0.50 0.50];
yline(ax5b, 0, 'k-', 'LineWidth', 0.5);
xlabel(ax5b,'Effect','Interpreter','latex','FontName',FONT,'FontSize',FS);
ylabel(ax5b,'$\Delta e$ (Wh/km)','Interpreter','latex','FontName',FONT,'FontSize',FS);
title(ax5b,'(b) WLTP \rightarrow US06', ...
     'Interpreter','tex','FontName',FONT,'FontSize',FS,'FontWeight','bold');
set(ax5b,'FontName',FONT,'FontSize',FS,'Box','on');
grid(ax5b,'on');

export_fig(fig5, fullfile(outDir,'Fig5_LMDI_Waterfall.pdf'), W_full, 7.5);

%% ── FIGURE 6: Loss budget stacked bars ──────────────────────────────────
fprintf('Generating Fig 6...\n');
fig6 = figure('Visible','off');
ax6  = axes(fig6);

% Per-regime energy intensity (Wh/km) by mechanism: [Cu, Fe, Batt, Gear, Useful] x regime
%   Source: manuscript loss-budget table (columns: Cu, Fe, Batt, Gear, Useful traction)
loss_data = [
%  MTPA:  Cu    Fe   Batt  Gear  Useful
    3.8,  2.9,  1.6,  3.2,  112.1;   % HWFET MTPA
    4.1,  3.6,  2.0,  3.5,   90.6;   % US06  MTPA
    4.0,  3.5,  1.8,  3.4,   92.0;   % WLTP  MTPA
%  FW:
    0,    0,    0,    0,     0;       % HWFET FW (none)
   12.4, 14.3,  7.8, 13.5,  220.6;   % US06  FW
    8.8, 16.7,  5.7, 11.2,  196.9;   % WLTP  FW
];

% Plot as grouped bars: HWFET-MTPA | US06-MTPA | WLTP-MTPA | gap | US06-FW | WLTP-FW
% Column order: [Useful, Gear, Batt, Fe, Cu] — Useful traction as base,
% losses stacked on top so the breakdown is clearly visible.
loss_labels = {'Useful traction','Gearbox','Battery I^2R','Iron','Copper'};
bar_clrs6   = [0.60 0.60 0.60;   % Useful  grey   (base)
               0.60 0.40 0.12;   % Gear    brown
               1.00 0.50 0.05;   % Batt    orange
               0.30 0.69 0.29;   % Fe      green
               0.89 0.10 0.11];  % Cu      red     (top)

grp_lbl = {'HWFET MTPA','US06 MTPA','WLTP MTPA','US06 FW','WLTP FW'};
% Reorder columns: original = [Cu Fe Batt Gear Useful] → new = [Useful Gear Batt Fe Cu]
plot_data = loss_data([1 2 3 5 6], [5 4 3 2 1]);

b6 = bar(ax6, plot_data, 'stacked', 'BarWidth', 0.6);
for ii = 1:5
    b6(ii).FaceColor = bar_clrs6(ii,:);
    b6(ii).EdgeColor = [1 1 1];
    b6(ii).LineWidth = 0.6;
end
set(ax6,'XTickLabel', grp_lbl, 'FontName',FONT,'FontSize',FS,'Box','on');
xtickangle(ax6, 30);
ylabel(ax6,'Energy intensity (Wh/km)','FontName',FONT,'FontSize',FS);
title(ax6,'Per-regime loss-mechanism energy budget', ...
     'FontName',FONT,'FontSize',FS,'FontWeight','bold');
lg6 = legend(ax6, loss_labels, 'Location','northeastoutside', ...
             'FontName',FONT,'FontSize',FS-1, 'NumColumns',1);
grid(ax6,'on');

export_fig(fig6, fullfile(outDir,'Fig6_LossBudget.pdf'), W_full, 8.5);

%% ── FIGURE 7: i_d - i_q operating-point scatter (per-timestep LUT lookup) ─
fprintf('Generating Fig 7...\n');

% LUT Vdc slice at 370 V
RPM_v7  = double(LUT.RPM_VECT(:));
TQ_v7   = double(LUT.TQ_VECT(:));
VDC_v7  = double(LUT.VDC_VECT(:));
[~,vi7] = min(abs(VDC_v7 - 370));
ID2_7   = squeeze(LUT.ID_MAP(:,:,vi7));   % nRPM x nTQ
IQ2_7   = squeeze(LUT.IQ_MAP(:,:,vi7));

% Motor parameters
psi_m7=0.07719; L_d7=0.000125; L_q7=0.000244; p7=3; Vdc7=370; k_Vmax7=1.10;
V_max7 = Vdc7 / (sqrt(3)*k_Vmax7);
G7=9.04; r_w7=0.326; eta7=0.90;

% Per-timestep LUT lookup for each cycle
fprintf('  LUT lookup HWFET...'); tic
[id_hw7,iq_hw7,mk_hw7] = lut_lookup7(Pb_hw, abs(HW.vS_hw(:)),   eta7,G7,r_w7,RPM_v7,TQ_v7,ID2_7,IQ2_7);
fprintf(' %.1fs\n',toc);
fprintf('  LUT lookup US06 ...'); tic
[id_us7,iq_us7,mk_us7] = lut_lookup7(Pb_us, abs(US.vS_us06(:)), eta7,G7,r_w7,RPM_v7,TQ_v7,ID2_7,IQ2_7);
fprintf(' %.1fs\n',toc);
fprintf('  LUT lookup WLTP ...'); tic
[id_wl7,iq_wl7,mk_wl7] = lut_lookup7(Pb_wl, v_wl_ms,            eta7,G7,r_w7,RPM_v7,TQ_v7,ID2_7,IQ2_7);
fprintf(' %.1fs\n',toc);

% Analytical MTPA locus
iq_mtpa7 = linspace(0,520,400)';
id_mtpa7 = -(psi_m7 - sqrt(psi_m7.^2 + (2*(L_q7-L_d7)*iq_mtpa7).^2)) ./ (2*(L_q7-L_d7));
id_mtpa7 = -abs(id_mtpa7);

% CRG FW-onset from LUT (first RPM where |id|>5 A at each torque)
n_tq7=numel(TQ_v7); id_fw7=NaN(n_tq7,1); iq_fw7=NaN(n_tq7,1);
for ti7=1:n_tq7
    if TQ_v7(ti7)<=0, continue; end
    fi7=find(ID2_7(:,ti7)<-5,1,'first');
    if ~isempty(fi7), id_fw7(ti7)=ID2_7(fi7,ti7); iq_fw7(ti7)=IQ2_7(fi7,ti7); end
end
valid_fw7 = ~isnan(id_fw7) & iq_fw7>0;

% Voltage-limit ellipses
rpm_ell7=[3000,6000,9000,12000,15000]; iq_e7=linspace(0,600,500)';

fig7 = figure('Visible','off','Units','centimeters','Position',[0 0 W_full 9]);
ax7  = axes(fig7);
hold(ax7,'on');

scatter(ax7,iq_hw7(mk_hw7),id_hw7(mk_hw7),10,[0.21 0.47 0.75],...
    'filled','MarkerFaceAlpha',0.45,'MarkerEdgeColor','none','DisplayName','HWFET (highway, 0% FW)');
scatter(ax7,iq_us7(mk_us7),id_us7(mk_us7),10,[0.89 0.10 0.11],...
    'filled','MarkerFaceAlpha',0.45,'MarkerEdgeColor','none','DisplayName','US06 (aggressive, FW active)');
scatter(ax7,iq_wl7(mk_wl7),id_wl7(mk_wl7),10,[0.20 0.63 0.17],...
    'filled','MarkerFaceAlpha',0.35,'MarkerEdgeColor','none','DisplayName','WLTP (mixed, partial FW)');

for ri7=1:numel(rpm_ell7)
    om_e=p7*rpm_ell7(ri7)*(2*pi/60);
    disc=max(0,(V_max7/om_e).^2-(L_q7.*iq_e7).^2);
    id_el=-(psi_m7-sqrt(disc))/L_d7;
    ok_el=imag(id_el)==0 & id_el<0;
    if any(ok_el)
        plot(ax7,iq_e7(ok_el),id_el(ok_el),'--','Color',[0.70 0.70 0.70],'LineWidth',0.7,'HandleVisibility','off');
        ix=find(ok_el,1,'last');
        text(ax7,iq_e7(ix)+4,id_el(ix),sprintf('%d krpm',round(rpm_ell7(ri7)/1000)),...
            'FontName',FONT,'FontSize',6,'Color',[0.50 0.50 0.50]);
    end
end
plot(ax7,iq_mtpa7,id_mtpa7,'k-','LineWidth',2.0,'DisplayName','MTPA locus');
plot(ax7,iq_fw7(valid_fw7),id_fw7(valid_fw7),'-','Color',[0.75 0.0 0.75],...
    'LineWidth',1.8,'DisplayName','FW onset (CRG, 370 V)');

hold(ax7,'off');
xlabel(ax7,'$i_q$ (A)','Interpreter','latex','FontName',FONT,'FontSize',FS+1);
ylabel(ax7,'$i_d$ (A)','Interpreter','latex','FontName',FONT,'FontSize',FS+1);
title(ax7,'Motor current operating points: MTPA and field-weakening regimes',...
    'FontName',FONT,'FontSize',FS,'FontWeight','bold');
legend(ax7,'Location','southwest','FontName',FONT,'FontSize',FS-1,'NumColumns',2);
set(ax7,'FontName',FONT,'FontSize',FS,'Box','on','XGrid','on','YGrid','on','GridAlpha',0.25);
xlim(ax7,[0 500]); ylim(ax7,[-230 20]);
text(ax7, 30,-12, 'MTPA region',         'FontName',FONT,'FontSize',7,'Color',[0.25 0.25 0.25],'FontAngle','italic');
text(ax7,240,-210,'Field-weakening region','FontName',FONT,'FontSize',7,'Color',[0.25 0.25 0.25],'FontAngle','italic');

export_fig(fig7, fullfile(outDir,'Fig7_IdIq_scatter.pdf'), W_full, 9);

%% ── DONE ─────────────────────────────────────────────────────────────────
fprintf('\n=== All figures exported to %s ===\n', outDir);
fprintf('Open any PDF to confirm vector quality (zoom in — no pixelation).\n');
fprintf('\nFiles written:\n');
for f = {'Fig1_PowertrainTopology.pdf','Fig2_SpeedProfiles.pdf','Fig3_CumulativeEnergy.pdf', ...
         'Fig4_RegimeShares.pdf','Fig5_LMDI_Waterfall.pdf','Fig6_LossBudget.pdf','Fig7_IdIq_scatter.pdf'}
    fp = fullfile(outDir, f{1});
    if exist(fp,'file')
        d = dir(fp);
        fprintf('  %-35s  %.1f kB\n', f{1}, d.bytes/1024);
    end
end

%% ════════════════════════════════════════════════════════════════════════
%% Local helper functions for Fig 2
%% ════════════════════════════════════════════════════════════════════════

function reg = f2_regime(Pb, vS_ms, G, r_w, eta, fw_tq_v, fw_rpm_v)
%F2_REGIME  Per-timestep CRG-based regime assignment.
%   Returns uint8: 1=MTPA, 2=Transition, 3=FW
    om   = vS_ms(:) .* (G / r_w);
    rpm  = om .* (60 / (2*pi));
    mask = Pb(:) > 50 & om > 0.1;
    T_sh = zeros(size(Pb));
    T_sh(mask) = Pb(mask) .* eta ./ max(om(mask), 0.1);
    T_sh = min(max(T_sh, min(fw_tq_v)), max(fw_tq_v));
    rpm_onset = interp1(fw_tq_v, fw_rpm_v, T_sh, 'linear', 'extrap');
    rpm_onset = max(rpm_onset, 0);
    reg = uint8(ones(size(Pb)));
    reg(mask & rpm >= rpm_onset & rpm < 1.1*rpm_onset) = 2;
    reg(mask & rpm >= 1.1*rpm_onset)                   = 3;
end

function f2_bg_image(ax, t, reg, ymax, clrs, show_legend)
%F2_BG_IMAGE  Single image object background — fast vector PDF export.
    leg_names = {'MTPA','Transition','Field weakening'};
    N  = numel(t);
    bg = zeros(1, N, 3);
    for r = 1:3
        m = (reg == r);
        bg(1,m,1) = clrs(r,1);
        bg(1,m,2) = clrs(r,2);
        bg(1,m,3) = clrs(r,3);
    end
    bg = repmat(bg, 2, 1, 1);
    image(ax, [t(1) t(end)], [0 ymax], bg, 'AlphaData', 0.55);
    if show_legend
        for r = 1:3
            patch(ax, NaN, NaN, clrs(r,:), 'FaceAlpha',0.55, ...
                  'EdgeColor','none', 'DisplayName', leg_names{r});
        end
    end
end

%% ════════════════════════════════════════════════════════════════════════
%% Local helper functions — Fig 1 (topology)
%% ════════════════════════════════════════════════════════════════════════

function f1_pbox(ax, x, y, w, h, fc, top_lbl, bot_lbl, font, fs)
    ec = fc * 0.72;
    rectangle('Parent',ax,'Position',[x y w h],...
        'FaceColor',fc,'EdgeColor',ec,'LineWidth',0.8,'Curvature',0.08);
    if isempty(bot_lbl)
        text(ax,x+w/2,y+h/2,top_lbl,'HorizontalAlignment','center',...
            'VerticalAlignment','middle','FontName',font,'FontSize',fs,...
            'FontWeight','bold','Color',[1 1 1]);
    else
        text(ax,x+w/2,y+h*0.67,top_lbl,'HorizontalAlignment','center',...
            'VerticalAlignment','middle','FontName',font,'FontSize',fs,...
            'FontWeight','bold','Color',[1 1 1]);
        text(ax,x+w/2,y+h*0.25,bot_lbl,'HorizontalAlignment','center',...
            'VerticalAlignment','middle','FontName',font,'FontSize',fs-1.5,...
            'Color',[0.93 0.93 0.93],'Interpreter','tex');
    end
end

function f1_harr(ax, x1, x2, y, clr, lbl, font, fs)
    aL=0.17; aW=0.09;
    plot(ax,[x1 x2-aL],[y y],'-','Color',clr,'LineWidth',1.1,'HandleVisibility','off');
    patch(ax,[x2-aL x2 x2-aL],[y-aW y y+aW],clr,'EdgeColor','none','HandleVisibility','off');
    if ~isempty(lbl)
        text(ax,(x1+x2)/2,y+0.18,lbl,'HorizontalAlignment','center',...
            'VerticalAlignment','bottom','FontName',font,'FontSize',fs,'Color',clr,'Interpreter','tex');
    end
end

function f1_larr(ax, x2, x1, y, clr, lbl, font, fs)
    aL=0.17; aW=0.09;
    plot(ax,[x2 x1+aL],[y y],'-','Color',clr,'LineWidth',1.1,'HandleVisibility','off');
    patch(ax,[x1+aL x1 x1+aL],[y-aW y y+aW],clr,'EdgeColor','none','HandleVisibility','off');
    if ~isempty(lbl)
        text(ax,(x1+x2)/2,y+0.18,lbl,'HorizontalAlignment','center',...
            'VerticalAlignment','bottom','FontName',font,'FontSize',fs,'Color',clr,'Interpreter','tex');
    end
end

function f1_vline(ax, x, y1, y2, clr, dir)
    aL=0.14; aW=0.09;
    if strcmp(dir,'up')
        plot(ax,[x x],[y1 y2-aL],'-','Color',clr,'LineWidth',1.0,'HandleVisibility','off');
        patch(ax,[x-aW x x+aW],[y2-aL y2 y2-aL],clr,'EdgeColor','none','HandleVisibility','off');
    else
        plot(ax,[x x],[y1 y2+aL],'-','Color',clr,'LineWidth',1.0,'HandleVisibility','off');
        patch(ax,[x-aW x x+aW],[y2+aL y2 y2+aL],clr,'EdgeColor','none','HandleVisibility','off');
    end
end

function f1_vline_dash(ax, x, y1, y2, clr, dir)
    aL=0.14; aW=0.09;
    if strcmp(dir,'down')
        plot(ax,[x x],[y1 y2+aL],'--','Color',clr,'LineWidth',0.9,'HandleVisibility','off');
        patch(ax,[x-aW x x+aW],[y2+aL y2 y2+aL],clr,'EdgeColor','none','HandleVisibility','off');
    else
        plot(ax,[x x],[y1 y2-aL],'--','Color',clr,'LineWidth',0.9,'HandleVisibility','off');
        patch(ax,[x-aW x x+aW],[y2-aL y2 y2-aL],clr,'EdgeColor','none','HandleVisibility','off');
    end
end

function f1_ahd(ax, x, y, dir, clr)
    aL=0.14; aW=0.09;
    switch dir
        case 'down'
            patch(ax,[x-aW x x+aW],[y+aL y y+aL],clr,'EdgeColor','none','HandleVisibility','off');
        case 'up'
            patch(ax,[x-aW x x+aW],[y-aL y y-aL],clr,'EdgeColor','none','HandleVisibility','off');
    end
end

%% ════════════════════════════════════════════════════════════════════════
%% Local helper function — Fig 7 (LUT per-timestep lookup)
%% ════════════════════════════════════════════════════════════════════════

function [id_out, iq_out, mask] = lut_lookup7(Pb, vS, eta, G, r_w, RPM_v, TQ_v, ID2, IQ2)
    Pb=Pb(:); vS=vS(:);
    om  = abs(vS) .* (G/r_w);
    rpm = om .* (60/(2*pi));
    mask = Pb>50 & om>0.1;
    T_sh = zeros(size(Pb));
    T_sh(mask) = Pb(mask).*eta ./ max(om(mask),0.1);
    T_sh = min(max(T_sh,0), max(TQ_v));
    id_out=zeros(size(Pb)); iq_out=zeros(size(Pb));
    for k=find(mask)'
        [~,ri]=min(abs(RPM_v-rpm(k)));
        [~,ti]=min(abs(TQ_v-T_sh(k)));
        id_out(k)=ID2(ri,ti);
        iq_out(k)=IQ2(ri,ti);
    end
end
