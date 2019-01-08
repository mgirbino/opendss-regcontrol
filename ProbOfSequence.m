function po_seq = ProbOfSequence(states_dg, perc_entries, logsout)
%PROBOFSEQUENCE Gives the probability of a sequence of events from logsout
% traverses states_dg, in the same way as UpdateEdgeWeights (referring to
% logsout for nodes), and multiplies edge weights along the way to get the
% probabilty of a sequence of events
    
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


    % 3 - Traverse graph:
    ancestor = startNode;
    dest = states_dg.successors(ancestor); % destination nodes

    while ~isempty(dest)
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
                break
            elseif ii == dest_len % false and it's the last successor
                % there may be further successors, but this state is unentered
                
                % when these are equal, whole graph has been bypassed:
                if strcmp(ancestor, startNode)
                    dest = string.empty; % breaks while loop
                    po_seq = 1 - perc_entries;
                else                    
                    error('State Machine is exiting before reaching a stable state');
                end
            end
        end
    end
end
