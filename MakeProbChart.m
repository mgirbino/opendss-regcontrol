function prob_log = MakeProbChart(simOut, hr, sec, phases, fieldnames, entries, varargin)
%MAKEPROBCHART Outputs a chart of probabilities of state transitions taken
%in simOut; can be used to see probability of an event through a separate
%Markov chain
%   simOut - a simulation output; hours and seconds;
%   phases - a vector of phase numbers (can be a single phase); fieldnames 
%   labels the chart fields (corresponding to structs given); entries is a 
%   3 x nargin matrix of state entries; and the
%   rest are specified structs containing digraphs, indexed by their
%   names
    num_fields = length(fieldnames);

    showIDmode = (length(varargin) == num_fields + 1) && strcmp(varargin{end}, 'ShowID');
    showBudgetMode = (length(varargin) == num_fields + 1) && strcmp(varargin{end}, 'ShowBudget');
    uniqueSeqs = struct('Probability', {}, 'Sequence', {}, 'ID', {}, 'Count', {});
    
    N = length(simOut);
    
    regWsNames = fields(varargin{1}); % names that index digraphs inside containing structs
    
    prob_struct = struct;

    prob_log = struct('idx', {}, 'hr', {}, 'sec', {}, regWsNames{1}, {}, ...
        regWsNames{2}, {}, regWsNames{3}, {});
    
    for nn = 1:N
        prob_log(nn).idx = nn;
        prob_log(nn).hr = hr(nn);
        prob_log(nn).sec = sec(nn);

        for phase = phases
            loclog = find(simOut(nn).logsout, '-regexp', 'BlockPath', ...
                        sprintf('\\w*%s\\w*', regWsNames{phase}));
            
            for graph_ind = 1:num_fields
                if showIDmode || showBudgetMode
                    if phase <= size(uniqueSeqs,1) && graph_ind <= size(uniqueSeqs,2) && ...
                        ~isempty(uniqueSeqs(phase, graph_ind, 1).Probability)
                        to_po_seq = uniqueSeqs(phase, graph_ind, :);
                    else
                        to_po_seq = struct.empty;
                    end
                    
                    [po_seq, temp_us, ID, count] = ...
                        ProbOfSequence(getfield(varargin{graph_ind}, regWsNames{phase}), ...
                        entries(phase, graph_ind)/N, loclog, to_po_seq);
                    uniqueSeqs(phase, graph_ind, 1:size(temp_us,3)) = temp_us;                    
                    
                    if showIDmode
                        prob_struct = setfield(prob_struct, fieldnames{graph_ind}, ...
                            table(po_seq, ID, 'VariableNames', {'P' 'ID'}));
                    else % showBudgetMode
                        prob_struct = setfield(prob_struct, fieldnames{graph_ind}, ...
                            table(po_seq, ID, count, count/(N*po_seq), ...
                            'VariableNames', {'P' 'ID', 'Ct', 'Bgt'}));
                    end                                 
                else
                    po_seq = ProbOfSequence(getfield(varargin{graph_ind}, regWsNames{phase}), ...
                        entries(phase, graph_ind)/N, loclog);
                    prob_struct = setfield(prob_struct, fieldnames{graph_ind}, po_seq);
                end              
            end

            prob_log(nn) = setfield(prob_log(nn), regWsNames{phase}, ...
                struct2table(prob_struct));
        end
    end
end