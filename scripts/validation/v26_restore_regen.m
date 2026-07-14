%% v26_restore_regen.m — Replace From Workspace regen with proper S-Function
%
%  Removes the DecelTorqueFF_WS From Workspace block and replaces it with
%  the OnePedal_Regen S-Function block (onepedal_regen_sfcn.m).
%
%  The S-Function computes regen torque internally from the Drive Cycle
%  Source reference speed. No workspace variables needed. Self-contained,
%  double-click to inspect.
%
%  Signal flow after this script:
%    DCS RefSpd ──┬──→ Longitudinal_Driver/VelRef
%                 └──→ OnePedal_Regen ──→ Tq_Sum (+)
%
%  Prerequisites:
%    - Drive Cycle Source connected to Longitudinal_Driver (run v26_reconnect_DCS.m first)
%    - onepedal_regen_sfcn.m in model/ folder (on MATLAB path)
%
%  Author: F. Shah Khan, University of East London, July 2026
% -------------------------------------------------------------------------

mdl = 'AE_TeslaM3_LMDI';

if ~bdIsLoaded(mdl)
    load_system(mdl);
end

fprintf('\n========================================================\n');
fprintf(' v26 RESTORE ONE-PEDAL REGEN (S-Function)\n');
fprintf('========================================================\n\n');

% Ensure model folder is on path (contains onepedal_regen_sfcn.m)
model_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'model');
addpath(model_dir);

%% 1. Find and delete DecelTorqueFF_WS (From Workspace block)
fprintf('1. Removing DecelTorqueFF_WS From Workspace block...\n');

ff_blk = [mdl '/DecelTorqueFF_WS'];
try
    ff_ph = get_param(ff_blk, 'PortHandles');

    % Record which port on Tq_Sum it connects to
    if ~isempty(ff_ph.Outport)
        ff_line = get_param(ff_ph.Outport(1), 'Line');
        if ff_line ~= -1
            tq_sum_port_idx = get_param(ff_line, 'DstPortHandle');
            delete_line(ff_line);
            fprintf('   Disconnected from Tq_Sum.\n');
        end
    end

    % Get position before deleting (for placing new block nearby)
    ff_pos = get_param(ff_blk, 'Position');
    delete_block(ff_blk);
    fprintf('   Deleted DecelTorqueFF_WS.\n');
catch ME
    fprintf('   DecelTorqueFF_WS not found: %s\n', ME.message);
    fprintf('   Using default position.\n');
    ff_pos = [880 280 1020 320];  % approximate from screenshot
end

%% 2. Delete decel_gate From Workspace block (if present)
fprintf('2. Checking for decel_gate From Workspace block...\n');
gate_blks = {'decel_gate_ws', 'DecelGate_WS', 'decel_gate'};
for k = 1:numel(gate_blks)
    gate_blk = [mdl '/' gate_blks{k}];
    try
        gp = get_param(gate_blk, 'PortHandles');
        if ~isempty(gp.Outport)
            gl = get_param(gp.Outport(1), 'Line');
            if gl ~= -1, delete_line(gl); end
        end
        delete_block(gate_blk);
        fprintf('   Deleted %s.\n', gate_blks{k});
    catch
    end
end

%% 3. Add OnePedal_Regen S-Function block
fprintf('3. Adding OnePedal_Regen S-Function block...\n');

regen_blk = [mdl '/OnePedal_Regen'];

% Delete if already exists (re-running this script)
try
    rp = get_param(regen_blk, 'PortHandles');
    if ~isempty(rp.Outport)
        rl = get_param(rp.Outport(1), 'Line');
        if rl ~= -1, delete_line(rl); end
    end
    if ~isempty(rp.Inport)
        rl = get_param(rp.Inport(1), 'Line');
        if rl ~= -1, delete_line(rl); end
    end
    delete_block(regen_blk);
catch
end

% Place new block near where DecelTorqueFF_WS was
new_pos = [ff_pos(1), ff_pos(2), ff_pos(1)+140, ff_pos(4)];
add_block('simulink/User-Defined Functions/Level-2 MATLAB S-Function', ...
    regen_blk, 'Position', new_pos);
set_param(regen_blk, 'FunctionName', 'onepedal_regen_sfcn');

% Label it clearly
set_param(regen_blk, 'ForegroundColor', 'blue');
fprintf('   Added OnePedal_Regen (Level-2 S-Function).\n');

%% 4. Connect DCS RefSpd → OnePedal_Regen input
fprintf('4. Connecting Drive Cycle Source → OnePedal_Regen...\n');

% Branch from DCS output (already connected to Longitudinal_Driver)
add_line(mdl, 'Drive Cycle Source/1', 'OnePedal_Regen/1', ...
    'autorouting', 'smart');
fprintf('   RefSpd branched to OnePedal_Regen input.\n');

%% 5. Connect OnePedal_Regen output → Tq_Sum
fprintf('5. Connecting OnePedal_Regen → Tq_Sum...\n');

tq_sum = [mdl '/Tq_Sum'];
try
    % Find which input port was used by DecelTorqueFF_WS
    tq_ph = get_param(tq_sum, 'PortHandles');
    n_inputs = numel(tq_ph.Inport);

    % Check which input is free
    free_port = 0;
    for p = 1:n_inputs
        line_p = get_param(tq_ph.Inport(p), 'Line');
        if line_p == -1
            free_port = p;
            break;
        end
    end

    if free_port > 0
        add_line(mdl, 'OnePedal_Regen/1', sprintf('Tq_Sum/%d', free_port), ...
            'autorouting', 'smart');
        fprintf('   Connected to Tq_Sum port %d.\n', free_port);
    else
        % All ports occupied. Add to port 2 (the regen port)
        add_line(mdl, 'OnePedal_Regen/1', 'Tq_Sum/2', ...
            'autorouting', 'smart');
        fprintf('   Connected to Tq_Sum port 2.\n');
    end
catch ME
    fprintf('   ERROR connecting to Tq_Sum: %s\n', ME.message);
    fprintf('   You may need to connect OnePedal_Regen to Tq_Sum manually.\n');
end

%% 6. Save model
save_system(mdl);
fprintf('\n6. Model saved.\n');

%% 7. Verify
fprintf('\nVerification:\n');

% Check OnePedal_Regen exists and is connected
try
    rp2 = get_param(regen_blk, 'PortHandles');
    in_line = get_param(rp2.Inport(1), 'Line');
    out_line = get_param(rp2.Outport(1), 'Line');

    if in_line ~= -1
        src = get_param(in_line, 'SrcBlockHandle');
        fprintf('   Input from: %s\n', get_param(src, 'Name'));
    else
        fprintf('   WARNING: input not connected!\n');
    end

    if out_line ~= -1
        dst = get_param(out_line, 'DstBlockHandle');
        fprintf('   Output to:  %s\n', get_param(dst, 'Name'));
    else
        fprintf('   WARNING: output not connected!\n');
    end
catch ME
    fprintf('   ERROR checking connections: %s\n', ME.message);
end

% Check no From Workspace blocks remain for regen
all_blocks = find_system(mdl, 'SearchDepth', 1, 'BlockType', 'FromWorkspace');
if ~isempty(all_blocks)
    fprintf('\n   Remaining From Workspace blocks at top level:\n');
    for b = 1:numel(all_blocks)
        fprintf('      %s\n', all_blocks{b});
    end
    fprintf('   Review: are any of these regen-related?\n');
else
    fprintf('   No From Workspace blocks at top level. Clean.\n');
end

fprintf('\n========================================================\n');
fprintf(' DONE. Model signal flow:\n');
fprintf('   DCS RefSpd → Longitudinal_Driver/VelRef (traction PID)\n');
fprintf('   DCS RefSpd → OnePedal_Regen → Tq_Sum (regen torque)\n');
fprintf('   Tq_Sum = PID_traction + OnePedal_regen → IPMSM\n');
fprintf('========================================================\n');
fprintf('\nThe OnePedal_Regen block is a standard Simulink S-Function.\n');
fprintf('Double-click it to see the code (onepedal_regen_sfcn.m).\n');
fprintf('No workspace variables needed for regen.\n\n');
