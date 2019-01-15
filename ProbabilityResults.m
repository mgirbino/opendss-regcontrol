%% Loading data:
normal692_data = load('reg692_inj.mat', 'simOut', 'HourOutVals', 'SecOutVals', 'TimeOutVals', 'regWsNames', ...
    'MakeTCentries', 'ExecEntries', 'LookingFwdEntries', 'LookingRevDRPentries', ...
    'LookingRevRNCentries', 'MakeTCgraph', 'ExecGraph', 'LookingFwdGraph', ...
    'LookingRevDRPgraph', 'LookingRevRNCgraph', 'ExecBlockpath', 'LookingRevDRPblockpath', 'EventLog');

% operator spoofed:
inj692_data = load('reg692_inj_quarter.mat', 'simOut', 'HourOutVals', 'SecOutVals', 'TimeOutVals', 'regWsNames', ...
    'MakeTCentries', 'ExecEntries', 'LookingFwdEntries', 'LookingRevDRPentries', ...
    'LookingRevRNCentries', 'MakeTCgraph', 'ExecGraph', 'LookingFwdGraph', ...
    'LookingRevDRPgraph', 'LookingRevRNCgraph', 'ExecBlockpath', 'LookingRevDRPblockpath', 'EventLog');
load692_data = load('reg692_load_quarter.mat', 'simOut', 'HourOutVals', 'SecOutVals', 'TimeOutVals', 'regWsNames', ...
    'MakeTCentries', 'ExecEntries', 'LookingFwdEntries', 'LookingRevDRPentries', ...
    'LookingRevRNCentries', 'MakeTCgraph', 'ExecGraph', 'LookingFwdGraph', ...
    'LookingRevDRPgraph', 'LookingRevRNCgraph', 'ExecBlockpath', 'LookingRevDRPblockpath', 'EventLog');

% system spoofed:
inj692spoof_data = load('reg692_spoof_inj.mat', 'simOut', 'HourOutVals', 'SecOutVals', 'TimeOutVals', 'regWsNames', ...
    'MakeTCentries', 'ExecEntries', 'LookingFwdEntries', 'LookingRevDRPentries', ...
    'LookingRevRNCentries', 'MakeTCgraph', 'ExecGraph', 'LookingFwdGraph', ...
    'LookingRevDRPgraph', 'LookingRevRNCgraph', 'ExecBlockpath', 'LookingRevDRPblockpath', 'EventLog');
load692spoof_data = load('reg692_spoof_load.mat', 'simOut', 'HourOutVals', 'SecOutVals', 'TimeOutVals', 'regWsNames', ...
    'MakeTCentries', 'ExecEntries', 'LookingFwdEntries', 'LookingRevDRPentries', ...
    'LookingRevRNCentries', 'MakeTCgraph', 'ExecGraph', 'LookingFwdGraph', ...
    'LookingRevDRPgraph', 'LookingRevRNCgraph', 'ExecBlockpath', 'LookingRevDRPblockpath', 'EventLog');

%% operator spoof: probabilities of sequences based on normal operating conditions Markov chain:

% reference - normal conditions:
[normal_thru_normal, sequences] = MakeProbChart(normal692_data.simOut, normal692_data.HourOutVals, normal692_data.SecOutVals, 1:3, ...
    {'MakeTC' 'Exec' 'LFwd' 'LRev' 'RevN'}, ...
    [normal692_data.MakeTCentries normal692_data.ExecEntries normal692_data.LookingFwdEntries normal692_data.LookingRevDRPentries normal692_data.LookingRevRNCentries], ...
    normal692_data.MakeTCgraph, normal692_data.ExecGraph, normal692_data.LookingFwdGraph, normal692_data.LookingRevDRPgraph, normal692_data.LookingRevRNCgraph, 'ShowBudget');

% unexpected injection:
inj692_thru_normal = MakeProbChart(inj692_data.simOut, normal692_data.HourOutVals, normal692_data.SecOutVals, 1:3, ...
    {'MakeTC' 'Exec' 'LFwd' 'LRev' 'RevN'}, ...
    [normal692_data.MakeTCentries normal692_data.ExecEntries normal692_data.LookingFwdEntries normal692_data.LookingRevDRPentries normal692_data.LookingRevRNCentries], ...
    normal692_data.MakeTCgraph, normal692_data.ExecGraph, normal692_data.LookingFwdGraph, normal692_data.LookingRevDRPgraph, normal692_data.LookingRevRNCgraph, ...
    'ShowBudget', sequences);

% unexpected load:
load692_thru_normal = MakeProbChart(load692_data.simOut, normal692_data.HourOutVals, normal692_data.SecOutVals, 1:3, ...
    {'MakeTC' 'Exec' 'LFwd' 'LRev' 'RevN'}, ...
    [normal692_data.MakeTCentries normal692_data.ExecEntries normal692_data.LookingFwdEntries normal692_data.LookingRevDRPentries normal692_data.LookingRevRNCentries], ...
    normal692_data.MakeTCgraph, normal692_data.ExecGraph, normal692_data.LookingFwdGraph, normal692_data.LookingRevDRPgraph, normal692_data.LookingRevRNCgraph, ...
    'ShowBudget', sequences);

%% operator spoof - injection - probabilities over time:

fieldnames = {'MakeTC' 'Exec' 'LFwd' 'LRev' 'RevN'};

N = 96;
Time = normal692_data.TimeOutVals/3600;

matching = compareCharts(normal_thru_normal, inj692_thru_normal, fieldnames, ...
    normal692_data.regWsNames, sequences, N);

[matching3D, matching_tab] = compareChartsOverTime(normal_thru_normal, inj692_thru_normal, fieldnames, ...
    normal692_data.regWsNames, sequences, N);

figure(1)
plot(Time, matching_tab.RegControl1.MakeTC, '+k-');
hold on
plot(Time, matching_tab.RegControl1.Exec, '+r-');
plot(Time, matching_tab.RegControl1.LFwd, '+b-');
plot(Time, matching_tab.RegControl1.LRev, '+g-');

plot(Time, inj692_thru_normal.RegControl1.MakeTC.P, '.k:');
plot(Time, inj692_thru_normal.RegControl1.Exec.P, '.r:');
plot(Time, inj692_thru_normal.RegControl1.LFwd.P, '.b:');
plot(Time, inj692_thru_normal.RegControl1.LRev.P, '.g:');
grid on

leg_text = cat(2, strcat(fieldnames(1:4), ' - Matching Coefficient'), ...
    strcat(fieldnames(1:4), ' - Event Probability') );
legend(leg_text, 'Location', 'east');
title('Matching Coefficient Over Time');



%% All state machines of a single phase:

rc1_sm = horzcat(i_thru_ni_tab(:, {'idx' 'hr' 'sec'}), i_thru_ni_tab.RegControl1)
rc2_sm = horzcat(i_thru_ni_tab(:, {'idx' 'hr' 'sec'}), i_thru_ni_tab.RegControl2)
rc3_sm = horzcat(i_thru_ni_tab(:, {'idx' 'hr' 'sec'}), i_thru_ni_tab.RegControl3)


%% Same state machine across all phases:

i_thru_ni_sm_order = inner2outer(i_thru_ni_tab);

all_MakeTC = horzcat(i_thru_ni_sm_order(:, {'idx' 'hr' 'sec'}), i_thru_ni_sm_order.MakeTC)
all_Exec = horzcat(i_thru_ni_sm_order(:, {'idx' 'hr' 'sec'}), i_thru_ni_sm_order.Exec)
all_LFwd = horzcat(i_thru_ni_sm_order(:, {'idx' 'hr' 'sec'}), i_thru_ni_sm_order.LFwd)
all_LRev = horzcat(i_thru_ni_sm_order(:, {'idx' 'hr' 'sec'}), i_thru_ni_sm_order.LRev)
all_RevN = horzcat(i_thru_ni_sm_order(:, {'idx' 'hr' 'sec'}), i_thru_ni_sm_order.LRev)

%% Investigating RegControl1 LRev:

phase = 1;

% at nn = 2 (what should happen all the time):
loclog = find(normal692_data.simOut(2).logsout, '-regexp', 'BlockPath', ...
                    sprintf('\\w*%s\\w*', normal692_data.regWsNames{phase}));
                
[po_seq, uniqueSeq, ID, count] = ...
    ProbOfSequence( getfield(noinj_data.LookingRevDRPgraph, noinj_data.regWsNames{phase}), ...
   noinj_data.LookingRevDRPentries(phase)/96, loclog, struct.empty);

uniqueSeq.Sequence

figure(1)                
h = PlotSequence(MakeDigraphProb( getfield(noinj_data.LookingRevDRPgraph, noinj_data.regWsNames{phase}) ), ...
    noinj_data.LookingRevDRPblockpath, noinj_data.LookingRevDRPentries(phase), length(normal692_data.simOut), ...
        '', '.Finished', loclog);

% at nn = 3 (what happens from nn=3:96 that shouldn't occur at all):
loclog = find(normal692_data.simOut(3).logsout, '-regexp', 'BlockPath', ...
                    sprintf('\\w*%s\\w*', normal692_data.regWsNames{phase}));
                
[po_seq, uniqueSeq, ID, count] = ...
    ProbOfSequence( getfield(noinj_data.LookingRevDRPgraph, noinj_data.regWsNames{phase}), ...
   noinj_data.LookingRevDRPentries(phase)/96, loclog, struct.empty);

uniqueSeq.Sequence

figure(2)                
h = PlotSequence(MakeDigraphProb( getfield(noinj_data.LookingRevDRPgraph, noinj_data.regWsNames{phase}) ), ...
    noinj_data.LookingRevDRPblockpath, noinj_data.LookingRevDRPentries(phase), length(normal692_data.simOut), ...
        '', '.Finished', loclog);







