%% Loading data:
inj_data = load('reg692_inj.mat', 'simOut', 'HourOutVals', 'SecOutVals', 'regWsNames', ...
    'MakeTCentries', 'ExecEntries', 'LookingFwdEntries', 'LookingRevDRPentries', ...
    'LookingRevRNCentries', 'MakeTCgraph', 'ExecGraph', 'LookingFwdGraph', ...
    'LookingRevDRPgraph', 'LookingRevRNCgraph', 'ExecBlockpath', 'EventLog');
noinj_data = load('reg692_noinj.mat', 'simOut', 'HourOutVals', 'SecOutVals', 'regWsNames', ...
    'MakeTCentries', 'ExecEntries', 'LookingFwdEntries', 'LookingRevDRPentries', ...
    'LookingRevRNCentries', 'MakeTCgraph', 'ExecGraph', 'LookingFwdGraph', ...
    'LookingRevDRPgraph', 'LookingRevRNCgraph', 'ExecBlockpath', 'EventLog');

%% view probabilities of one sequence based on another sequence's Markov chain:

% example: probability of events of power injection (unexpected) occurring
% under normal conditions (no power injection; expected)
i_thru_ni = MakeProbChart(inj_data.simOut, noinj_data.HourOutVals, noinj_data.SecOutVals, 1:3, ...
    {'MakeTC' 'Exec' 'LFwd' 'LRev' 'RevN'}, ...
    [noinj_data.MakeTCentries noinj_data.ExecEntries noinj_data.LookingFwdEntries noinj_data.LookingRevDRPentries noinj_data.LookingRevRNCentries], ...
    noinj_data.MakeTCgraph, noinj_data.ExecGraph, noinj_data.LookingFwdGraph, noinj_data.LookingRevDRPgraph, noinj_data.LookingRevRNCgraph, 'ShowBudget');

i_thru_ni_tab = struct2table(i_thru_ni);

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






