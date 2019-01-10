function h = PlotSequence(states_dg, blockpath, entries, n_iter, startNode, endNode, logsout)
    
    % full_dg is the digraph as plotted:
    [h, full_dg] = PlotNormalized(states_dg, blockpath, entries, n_iter, startNode, endNode);
    
    % choose either path from Before to startNode or Before to After
    
    % indices of edges that may be highlighted:
    before_start = findedge(full_dg, 'Before', startNode);
    end_after = findedge(full_dg, endNode, 'After');
    before_after = findedge(full_dg, 'Before', 'After');    
    
    % -----------------------------
    % highlight remainder of graph if it goes to startNode:
    
    % need to add blockpath back in for matching to stateslist:
    full_dg.Nodes.Name = strcat(blockpath, full_dg.Nodes.Name);

    perc_entries = entries/n_iter;
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
    
    if ~isempty(VisitedStates)
        highlight(h, 'Edges', before_start, 'EdgeColor', 'r');
        highlight(h, 'Edges', end_after, 'EdgeColor', 'r');
    end


    % 3 - Traverse graph:
    ancestor = startNode;
    dest = full_dg.successors(ancestor); % destination nodes

    while ~isempty(dest)
        % iterate through destination nodes to find the path taken:
        dest_len = length(dest); % number of destination nodes
        for ii = 1:dest_len
            if sum( strcmp( VisitedStates.Name, dest(ii) ) )     
                edge_idx = full_dg.findedge( ancestor, dest(ii) );
                po_seq = po_seq * full_dg.Edges.Weight(edge_idx);
                highlight(h, 'Edges', edge_idx, 'EdgeColor', 'r');

                % there should only be 1 successor that's true (would otherwise
                % break depth-based traversal)
                ancestor = dest(ii);
                dest = full_dg.successors( dest(ii) );
                break
            elseif ii == dest_len % false and it's the last successor
                % there may be further successors, but this state is unentered
                
                % when these are equal, whole graph has been bypassed:
                if strcmp(ancestor, startNode)
                    dest = string.empty; % breaks while loop
                    po_seq = 1 - perc_entries;
                    highlight(h, 'Edges', before_after, 'EdgeColor', 'r');
                else
                    if endsWith(dest{1}, 'After')
                        dest = string.empty; % breaks while loop
                    else
                        error('State Machine is exiting before reaching a stable state');
                    end
                end
            end
        end
    end
    
    title( compose( 'Sequence Probability: %f', po_seq ) );
end
