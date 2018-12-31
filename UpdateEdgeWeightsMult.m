function [states_dg, entry] = UpdateEdgeWeightsMult(states_dg, startNode, ...
    logsout, increment)
%UPDATEEDGEWEIGHTSMULT Increments the edge weights connecting visited nodes
%   Traverses states_dg, beginning at startNode. Adds increment to the
%   weight of edges connecting visited nodes. Visitation is determined by
%   whether the nodes occur as a Name in logsout. The edge weights can be
%   greater than 1 depending on number of visitations (difference from
%   non-mult version)

    % 1 - Initialize statesList:
    statesList = table('Size', [height(states_dg.Nodes) 2], 'VariableTypes', ...
        {'string', 'uint8'}, 'VariableNames', {'Name', 'Value'});
    entry = 1;
    
    % 2 - Parse logsout into statesList:
    searchFor = table2array(states_dg.Nodes);

    for ii = 1:height(statesList)
        elem = logsout.getElement(searchFor{ii});
        statesList(ii,1) = {elem.Name};
        % sum needed for time-stamped state activity:
        statesList(ii,2) = {sum(elem.Values.Data)};
    end

    % 3 - Enter graph through startNode:
    ancestor = table2struct( statesList( strcmp(statesList.Name, startNode), ...
        {'Name' 'Value'} ) );
    ancestor = DecrFreqOnEntry(ancestor); % decrement # entries into ancestor
    dest = states_dg.successors(ancestor.Name); % destination nodes (cell array)
    dest_len = length(dest);

    % 4 - Traverse graph:
    while dest_len ~= 0
        % 4a - build a struct of Name / Value pairs for destination nodes:
        feasible_dest = statesList( strcmp( dest(1), statesList.Name ), ...
            {'Name' 'Value'} );
        for ii = 2:length(dest)
            feasible_dest = union( statesList( strcmp( dest(ii), statesList.Name ), ...
                {'Name' 'Value'} ), feasible_dest);
        end
        feasible_dest = feasible_dest(feasible_dest.Value >= 1, {'Name' 'Value'});
        feasible_dest = sortrows(feasible_dest, 'Value', 'descend');
        fd_struct = table2struct(feasible_dest);
        
        dest_len = size(fd_struct,1);
        
        % 4b - iterate through destination nodes to find the path taken:
        for ii = 1:dest_len
            found_next_dest = false; % flag
            
            % if highest Nentries
            if ii < dest_len && fd_struct(ii).Value > fd_struct(ii+1).Value
                % if dest is self and non-self dest exists --> take
                % non-self
                if strcmp( fd_struct(ii).Name, ancestor )
                    [ancestor, dest] = IncrEdgeWeight( ancestor, fd_struct(ii+1) );
                    found_next_dest = true;
                % else take this dest (it's non-self)
                else
                    [ancestor, dest] = IncrEdgeWeight( ancestor, fd_struct(ii) );
                    found_next_dest = true;
                end
                
                break
            % else - at least one neighboring element in fd_struct with 
            % equal Nentries OR ii == dest_len
            else
                for jj = ii:dest_len
                    % if dest is predecessor (in addition to successor) -->
                    % prefer
                    if (jj == 1 || fd_struct(jj).Value == fd_struct(jj-1).Value) && ...
                    	ismember( fd_struct(jj).Name, states_dg.predecessors(ancestor.Name) )
                    
                        [ancestor, dest] = IncrEdgeWeight( ancestor, fd_struct(jj) );
                        found_next_dest = true;
                        break % this jj for loop
                    end                    
                end
                
                if found_next_dest
                    break
                % else take the 1st
                else
                    [ancestor, dest] = IncrEdgeWeight( ancestor, fd_struct(ii) );
                    found_next_dest = true;
                    break
                end
            end

            if ~found_next_dest && ii == dest_len % false and it's the last successor
                % there may be further successors, but this state is unentered
                
                % when these are equal, whole graph has been bypassed:
                if strcmp(ancestor.Name, startNode)
                    dest = string.empty; % breaks while loop
                    entry = 0; % indicates never entered / bypassed
                else                    
                    error('State Machine is exiting before reaching a stable state');
                end
            end
        end
    end
    
    function [next_from, next_to] = IncrEdgeWeight(from, to) 
        % structs: from, to, next_from
        % vector: next_to
        
        
        to = DecrFreqOnEntry(to);        
        
        % increment edge weight:
        edge_idx = states_dg.findedge( from.Name, to.Name );
        prevWeight = states_dg.Edges.Weight(edge_idx);
        states_dg.Edges.Weight(edge_idx) = prevWeight + increment;

        % there should only be 1 successor that's true (would otherwise
        % break depth-based traversal)
        next_from = to;
        next_to = states_dg.successors( to.Name );
    end

    function updatedState = DecrFreqOnEntry(state) % called on state entry
        % decrement frequency in statesList:
        newElem = table;
        newElem.Name = state.Name;
        newElem.Value = state.Value - 1;
        updatedState = table2struct(newElem);
        
        % remove member from list:
        smallerList = statesList( ~strcmp(statesList.Name, state.Name), {'Name' 'Value'} );
        
        % then replace with newElem:
        statesList = union(smallerList, newElem);
    end
end
