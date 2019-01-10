function [po_seq, varargout] = ProbOfSequence(states_dg, perc_entries, logsout, varargin)
%PROBOFSEQUENCE Gives the probability of a sequence of events from logsout
% traverses states_dg, in the same way as UpdateEdgeWeights (referring to
% logsout for nodes), and multiplies edge weights along the way to get the
% probabilty of a sequence of events
    uniqueness_mode = nargout > 1 && nargin > 3; % mode for checking uniqueness of path
    
    uniqueSeqList = struct.empty;
    
    
    if uniqueness_mode
        % a table, containing sequences (cell array), indexed by probabilities:
        uniqueSeqList = varargin{1};
    end
    
    po_seq = perc_entries;
    
    startNode = states_dg.Nodes.Name{1};

    % 1 - Initialize statesList:
    statesList = table('Size', [height(states_dg.Nodes) 2], 'VariableTypes', ...
        {'string', 'uint8'}, 'VariableNames', {'Name', 'Value'});
    
    % 2 - Parse logsout into statesList:
    searchFor = table2array(states_dg.Nodes);

    for ii = 1:height(statesList)
        elem = logsout.getElement(searchFor{ii});
        statesList(ii,1) = {elem.Name};
        % sum needed for time-stamped state activity:
        statesList(ii,2) = {sum(elem.Values.Data)};
    end

    % 2a - Reduce statesList into visitedStates:
    VisitedStates = statesList(statesList.Value == 1,{'Name'});
    ongoingSeq = cell(size(VisitedStates)); % sequence built through iterations

    % 3 - Traverse graph:
    ancestor = startNode;
    dest = states_dg.successors(ancestor); % destination nodes
    
    idx = 1;
    ongoingSeq{1} = ancestor;

    while ~isempty(dest)
        idx = idx + 1;
        % iterate through destination nodes to find the path taken:
        dest_len = length(dest); % number of destination nodes
        for ii = 1:dest_len
            if sum( strcmp( VisitedStates.Name, dest(ii) ) )     
                edge_idx = states_dg.findedge( ancestor, dest(ii) );
                po_seq = po_seq * states_dg.Edges.Weight(edge_idx);

                % there should only be 1 successor that's true (would otherwise
                % break depth-based traversal)
                ancestor = dest(ii);
                dest = states_dg.successors( dest(ii) );
                
                ongoingSeq{idx} = ancestor;
                
                break
            elseif ii == dest_len % false and it's the last successor
                % there may be further successors, but this state is unentered
                
                % when these are equal, whole graph has been bypassed:
                if strcmp(ancestor, startNode)
                    dest = string.empty; % breaks while loop
                    po_seq = 1 - perc_entries;
                    
                    ongoingSeq = {'Before' 'After'};
                else                    
                    error('State Machine is exiting before reaching a stable state');
                end
            end
        end
    end
    
    if uniqueness_mode
        % if sequence already exists in uniqueSeqList, it's not
        % a unique sequence:
        isUnique = false;
        
        % empty if not in the list, single row if is:
        matching_prob = uniqueSeqList(ismember(uniqueSeqList.Probability, po_seq));
        
        if ~isempty(matching_prob)
            % probability exists in table --> need to match sequence now
            if isequal(matching_prob.Sequence, ongoingSeq)
                % if sequence isn't in there, it is added and marked as
                % unique:
                usl_row = table(po_seq, ongoingSeq, 'VariableNames', {'Probability' 'Sequence'});
                uniqueSeqList = vertcat(uniqueSeqList, usl_row);                
                isUnique = true;
            end
        else % probability not in the table, so neither is sequence --> unique
            usl_row = table(po_seq, ongoingSeq, 'VariableNames', {'Probability' 'Sequence'});
            uniqueSeqList = vertcat(uniqueSeqList, usl_row);      
            isUnique = true;
        end
        varargout{1} = isUnique;
        varargout{2} = uniqueSeqList;
    end
end
