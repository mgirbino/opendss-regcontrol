%% Loading data:
inj_data = load('reg692_inj.mat', 'simOut', 'HourOutVals', 'SecOutVals', 'TimeOutVals', 'regWsNames', ...
    'MakeTCentries', 'ExecEntries', 'LookingFwdEntries', 'LookingRevDRPentries', ...
    'LookingRevRNCentries', 'MakeTCgraph', 'ExecGraph', 'LookingFwdGraph', ...
    'LookingRevDRPgraph', 'LookingRevRNCgraph', 'ExecBlockpath', 'EventLog');
noinj_data = load('reg692_noinj.mat', 'simOut', 'HourOutVals', 'SecOutVals', 'regWsNames', ...
    'MakeTCentries', 'ExecEntries', 'LookingFwdEntries', 'LookingRevDRPentries', ...
    'LookingRevRNCentries', 'MakeTCgraph', 'ExecGraph', 'LookingFwdGraph', ...
    'LookingRevDRPgraph', 'LookingRevRNCgraph', 'ExecBlockpath', 'LookingRevDRPblockpath', 'EventLog');

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

% RegControl1:
% MakeTC: over: 1: 1.0012 @ 93 / under: 2: 0.75 @ 73, 3: 0.6667 @ 95
% Exec: over: 2: Inf @ 2, 1: 1.0012 @ 96 / under: 3: 0.75 @ 73, 4: 0.667 @
% 95
% LFwd: over: 1: Inf @ 1, 2: Inf @ 2, 3: Inf @ 3 / under: 
% LRev: over: 2: Inf @ 3 / under: 1: 0.020833 @ 2

% RegControl1 summary:
% MakeTC: close match
% Exec: Event that shouldn't happen occurs once, otherwise close match
% LFwd: None of these events should occur at all
% LRev: Event that shouldn't occur at all happens >95% of the time

% RegControl2:
% MakeTC: over: 2: Inf @ 2, 1: 1.3333 @ 70  / under: 3: 0.97849 @ 96
% Exec: over: 1: 1.3333 @ 70 / under: 2: 0.98925 @ 96
% LFwd: over: 1: Inf @ 1, 2: Inf @ 2 / under: 
% LRev: over:  / under: (100% match, same event occurs every time)

% RegControl2 summary:
% MakeTC: Event that shouldn't happen occurs once, otherwise close match
% Exec: Close match
% LFwd: None of these events should occur at all
% LRev: 100% match, state machine bypassed every time

% RegControl3:
% MakeTC: over: 2: 1.667 @ 93 / under: 1: 0.83333 @ 91
% Exec: over: 2: Inf @ 2, 4: 1.1667 @ 70, 3: 1.1667 @ 93 / under: 1:
% 0.85714 @ 90
% LFwd: over: 1: Inf @ 1, 2: Inf @ 2, 3: Inf @ 3 / under: 
% LRev: over: 2: Inf @ 3 / under: 1: 0.020833 @ 2

% RegControl3 summary:
% MakeTC: one event that should occur >90% occurs ~70%
% Exec: one event that should occur >90% occurs ~70%, event that shouldn't
% happen occurs once
% LFwd: None of these events should occur at all
% LRev: Event that shouldn't occur at all happens >95% of the time


%% Same state machine across all phases:

i_thru_ni_sm_order = inner2outer(i_thru_ni_tab);

all_MakeTC = horzcat(i_thru_ni_sm_order(:, {'idx' 'hr' 'sec'}), i_thru_ni_sm_order.MakeTC)
all_Exec = horzcat(i_thru_ni_sm_order(:, {'idx' 'hr' 'sec'}), i_thru_ni_sm_order.Exec)
all_LFwd = horzcat(i_thru_ni_sm_order(:, {'idx' 'hr' 'sec'}), i_thru_ni_sm_order.LFwd)
all_LRev = horzcat(i_thru_ni_sm_order(:, {'idx' 'hr' 'sec'}), i_thru_ni_sm_order.LRev)
all_RevN = horzcat(i_thru_ni_sm_order(:, {'idx' 'hr' 'sec'}), i_thru_ni_sm_order.LRev)

% MakeTC:
% RegControl1: over: 1: 1.0112 @ 93 / under: 2: 0.75 @ 73, 3: 0.66667 @ 95
% RegControl2: over: 2: Inf @ 3, 1: 1.3333 @ 70 / under: 3: 0.97849 @ 96
% RegControl3: over: 3: 1.1667 @ 70, 2: 1.1667 @ 93 / under: 1: 0.86905 @
% 90

% MakeTC summary:
% RegControl1: MakeTC: close match
% RegControl2: Event that shouldn't happen occurs once, otherwise close match
% RegControl3: one event that should occur >90% occurs ~70%

% could catch at half-day, maybe earlier based on RegControl3

% Exec:
% RegControl1: over: 2: Inf @ 2, 1: 1.0112 @ 96 / under: 3: 0.75 @ 73, 4:
% 0.6667 @ 95
% RegControl2: over: 1: 1.3333 @ 70 / under: 2: 0.98925 @ 96
% RegControl3: over: 2: Inf @ 2, 3: 1.1667 @ 93, 4: 1.1667 @ 70 / under: 1: 0.85714 @ 90

% Exec summary:
% RegControl1: Event that shouldn't happen occurs once, otherwise close match
% RegControl2: Close match
% RegControl3: one event that should occur >90% occurs ~70%, event that shouldn't
% happen occurs once

% could catch at half-day, maybe earlier based on RegControl3

% LFwd:
% RegControl1: over: 1: Inf @ 1, 2: Inf @ 2, 3: Inf @ 3 / under: 
% RegControl2: over: 1: Inf @ 1, 2: Inf @ 2 / under: 
% RegControl3: over: 1: Inf @ 1, 2: Inf @ 2, 3: Inf @ 3 / under: 

% LFwd summary:
% RegControl1: None of these events should occur at all
% RegControl2: None of these events should occur at all
% RegControl3: None of these events should occur at all

% fast indication because of consistent unexpected behavior

% LRev:
% RegControl1: over: 2: Inf @ 3 / under: 2: 0.020833 @ 2
% RegControl2: over:  / under: (100% match, same event occurs every time)
% RegControl3: over: 2: Inf @ 3 / under: 2: 0.020833 @ 2

% LRev summary:
% RegControl1: Event that shouldn't occur at all happens >95% of the time
% RegControl2: 100% match, state machine bypassed every time
% RegControl3: Event that shouldn't occur at all happens >95% of the time

%% Investigating RegControl1 LRev:

phase = 1;

% at nn = 2 (what should happen all the time):
loclog = find(inj_data.simOut(2).logsout, '-regexp', 'BlockPath', ...
                    sprintf('\\w*%s\\w*', inj_data.regWsNames{phase}));
                
[po_seq, uniqueSeq, ID, count] = ...
    ProbOfSequence( getfield(noinj_data.LookingRevDRPgraph, noinj_data.regWsNames{phase}), ...
   noinj_data.LookingRevDRPentries(phase)/96, loclog, struct.empty);

uniqueSeq.Sequence

figure(1)                
h = PlotSequence(MakeDigraphProb( getfield(noinj_data.LookingRevDRPgraph, noinj_data.regWsNames{phase}) ), ...
    noinj_data.LookingRevDRPblockpath, noinj_data.LookingRevDRPentries(phase), length(inj_data.simOut), ...
        '', '.Finished', loclog);

% at nn = 3 (what happens from nn=3:96 that shouldn't occur at all):
loclog = find(inj_data.simOut(3).logsout, '-regexp', 'BlockPath', ...
                    sprintf('\\w*%s\\w*', inj_data.regWsNames{phase}));
                
[po_seq, uniqueSeq, ID, count] = ...
    ProbOfSequence( getfield(noinj_data.LookingRevDRPgraph, noinj_data.regWsNames{phase}), ...
   noinj_data.LookingRevDRPentries(phase)/96, loclog, struct.empty);

uniqueSeq.Sequence

figure(2)                
h = PlotSequence(MakeDigraphProb( getfield(noinj_data.LookingRevDRPgraph, noinj_data.regWsNames{phase}) ), ...
    noinj_data.LookingRevDRPblockpath, noinj_data.LookingRevDRPentries(phase), length(inj_data.simOut), ...
        '', '.Finished', loclog);
    
%% Experiments with the data:

% keep in mind that these ID's all mean different things.
% (assume they're the same for now)
dat1 = i_thru_ni_tab.RegControl1.Exec.ID;
dat2 = i_thru_ni_tab.RegControl2.Exec.ID;
dat3 = i_thru_ni_tab.RegControl3.Exec.ID;

idx = i_thru_ni_tab.idx;

prob = i_thru_ni_tab.RegControl1.Exec.P;
normal_dat = dat1 / sum(dat1); % adds to 1dat/

ts1 = timeseries(dat1,idx);
ts2 = timeseries(dat2,idx);
ts3 = timeseries(dat3,idx);

figure(4)
plot(ts1,'k');
hold on
plot(ts2,'r');
plot(ts3,'b');

%% comparison based on same data, but using same ID's for consistency:

% example: probability of events of power injection (unexpected) occurring
% under normal conditions (no power injection; expected)
[ni_thru_ni, sequences] = MakeProbChart(noinj_data.simOut, noinj_data.HourOutVals, noinj_data.SecOutVals, 1:3, ...
    {'MakeTC' 'Exec' 'LFwd' 'LRev' 'RevN'}, ...
    [noinj_data.MakeTCentries noinj_data.ExecEntries noinj_data.LookingFwdEntries noinj_data.LookingRevDRPentries noinj_data.LookingRevRNCentries], ...
    noinj_data.MakeTCgraph, noinj_data.ExecGraph, noinj_data.LookingFwdGraph, noinj_data.LookingRevDRPgraph, noinj_data.LookingRevRNCgraph, 'ShowBudget');

i_thru_ni_sameIDs = MakeProbChart(inj_data.simOut, noinj_data.HourOutVals, noinj_data.SecOutVals, 1:3, ...
    {'MakeTC' 'Exec' 'LFwd' 'LRev' 'RevN'}, ...
    [noinj_data.MakeTCentries noinj_data.ExecEntries noinj_data.LookingFwdEntries noinj_data.LookingRevDRPentries noinj_data.LookingRevRNCentries], ...
    noinj_data.MakeTCgraph, noinj_data.ExecGraph, noinj_data.LookingFwdGraph, noinj_data.LookingRevDRPgraph, noinj_data.LookingRevRNCgraph, ...
    'ShowBudget', sequences);

ni_thru_ni_tab2 = struct2table(ni_thru_ni);
i_thru_ni_tab2 = struct2table(i_thru_ni_sameIDs);

%% compare i_thru_i and i_thru_ni ID matches of RegControl1, per state machine:

fieldnames = {'MakeTC' 'Exec' 'LFwd' 'LRev' 'RevN'};

N = 96;
Time = inj_data.TimeOutVals/3600;

matching = compareCharts(ni_thru_ni_tab2, i_thru_ni_tab2, fieldnames, ...
    inj_data.regWsNames, sequences, N);

[matching3D, matching_tab] = compareChartsOverTime(ni_thru_ni_tab2, i_thru_ni_tab2, fieldnames, ...
    inj_data.regWsNames, sequences, N);

figure(1)
plot(Time, matching_tab.RegControl1.MakeTC, '+k-');
hold on
plot(Time, matching_tab.RegControl1.Exec, '+r-');
plot(Time, matching_tab.RegControl1.LFwd, '+b-');
plot(Time, matching_tab.RegControl1.LRev, '+g-');
grid on
legend(fieldnames{1:4}, 'Location', 'east');
title('Matching Coefficient Over Time');

% rc1_sm2 = horzcat(i_thru_ni_tab2(:, {'idx' 'hr' 'sec'}), i_thru_ni_tab2.RegControl1)
% rc2_sm2 = horzcat(i_thru_ni_tab2(:, {'idx' 'hr' 'sec'}), i_thru_ni_tab2.RegControl2)
% rc2_sm2 = horzcat(i_thru_ni_tab2(:, {'idx' 'hr' 'sec'}), i_thru_ni_tab2.RegControl3)







