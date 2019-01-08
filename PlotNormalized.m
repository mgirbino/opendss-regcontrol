function PlotNormalized(states_dg, blockpath, entries, n_iter)
%PLOTNORMALIZED Plots a digraph, with normalized number of entries and
%simplified name
%   Takes a digraph of state transitions, removes their blockpath from the
%   node labels, normalizes transition weights (entry frequency) to number
%   of entries into the starting node, and prints the number of entries
%   into the starting node, normalized by the number of iterations
    states_dg.Nodes.Name = erase(states_dg.Nodes.Name, blockpath);
    % entries == 0 --> weight = NaN
%     if entries ~= 0
%         states_dg.Edges.Weight = states_dg.Edges.Weight / entries;
%     end
    plot(states_dg,'Layout','layered','EdgeLabel',states_dg.Edges.Weight);
    title( compose( '%s Entered %f', blockpath, (entries/n_iter) ) );
end

