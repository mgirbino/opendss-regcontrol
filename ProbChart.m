prob_phase = struct;
prob_struct = struct;

all_iter_table = table.empty;

probability_log = struct('idx', {}, 'hr', {}, 'sec', {}, 'RegControl1', {}, ...
    'RegControl2', {}, 'RegControl3', {});

for nn = 1:N
    probability_log(nn).idx = nn;
    probability_log(nn).hr = HourOutVals(nn);
    probability_log(nn).sec = SecOutVals(nn);
    
    for phase = 1:3
        loclog = find(simOut(nn).logsout, '-regexp', 'BlockPath', ...
                    sprintf('\\w*%s\\w*', regWsNames{phase}));
                
        mtcprob = ProbOfSequence(getfield(ExecGraph, regWsNames{phase}), MakeTCentries(phase)/N, loclog);
        execprob = ProbOfSequence(getfield(ExecGraph, regWsNames{phase}), ExecEntries(phase)/N, loclog);
        lfwdprob = ProbOfSequence(getfield(ExecGraph, regWsNames{phase}), LookingFwdEntries(phase)/N, loclog);      
        lrevprob = ProbOfSequence(getfield(ExecGraph, regWsNames{phase}), LookingRevDRPentries(phase)/N, loclog);
        rncprob = ProbOfSequence(getfield(ExecGraph, regWsNames{phase}), LookingRevRNCentries(phase)/N, loclog);
        
        prob_struct.MakeTC = mtcprob;
        prob_struct.Exec = execprob;
        prob_struct.LFwd = lfwdprob;
        prob_struct.LRev = lrevprob;
        prob_struct.RevN = rncprob;
        
        probability_log(nn) = setfield(probability_log(nn), regWsNames{phase}, struct2table(prob_struct));
    end
end
struct2table(probability_log)
