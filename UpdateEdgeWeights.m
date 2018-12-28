function states_dg = UpdateEdgeWeights(states_dg, startNode, logsout, increment)
%UPDATEEDGEWEIGHTS Increments the edge weights connecting visited nodes
%   Traverses states_dg, beginning at startNode. Adds increment to the
%   weight of edges connecting visited nodes. Visitation is determined by
%   whether the nodes occur as a Name in logsout, with a Value of 1 (or any
%   array containing a 1 element).

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
    dest_len = length(dest); % number of destination nodes

    while ~isempty(dest)
        % iterate through destination nodes to find the path taken:
        for ii = 1:dest_len
            if sum( strcmp( VisitedStates.Name, dest(ii) ) )       
                % increment edge weight:
                edge_idx = states_dg.findedge( ancestor, dest(ii) );
                prevWeight = states_dg.Edges.Weight(edge_idx);
                states_dg.Edges.Weight(edge_idx) = prevWeight + increment;

                % there should only be 1 successor that's true (would otherwise
                % break depth-based traversal)
                ancestor = dest(ii);
                dest = states_dg.successors( dest(ii) );
                break
            elseif ii == dest_len % false and it's the last successor
                % there may be further successors, but this state is unentered
                error('State Machine is exiting before reaching a stable state');
            end
        end
    end
end
