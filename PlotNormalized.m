function [h, states_dg] = PlotNormalized(states_dg, blockpath, entries, n_iter, startNode, endNode)
%PLOTNORMALIZED Plots a digraph, with normalized number of entries and
%simplified name
%   Takes a digraph of state transitions, removes their blockpath from the
%   node labels, normalizes transition weights (entry frequency) to number
%   of entries into the starting node, and prints the number of entries
%   into the starting node, normalized by the number of iterations
    states_dg.Nodes.Name = erase(states_dg.Nodes.Name, blockpath);
    
    % the transition from x.Finished --> After has a probability of 1 in
    % every case, except if states_dg is never entered. Then it's 0.
    out_weight = 1;
    if entries == 0
        out_weight = 0;
    end
    
    before = 'Before';
    after = 'After';
    % parts_dg is constructed so its nodes and edges can be added to
    % states_dg:    
    parts_source = {before, before, endNode};
    parts_dest = {startNode, after, after};    
    parts_dg = digraph(parts_source, parts_dest);
    parts_dg.Edges.Weight = [entries/n_iter; (1 - entries/n_iter); out_weight];
    
    states_dg = addnode(states_dg, {before after});
    states_dg = addedge(states_dg, parts_dg.Edges);
    
    
    % entries == 0 --> weight = NaN
%     if entries ~= 0
%         states_dg.Edges.Weight = states_dg.Edges.Weight / entries;
%     end
    h = plot(states_dg,'Layout','layered','EdgeLabel',states_dg.Edges.Weight);
%     title( compose( '%s Entered %f', blockpath, (entries/n_iter) ) );
    title(blockpath);
end

