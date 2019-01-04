function prob_dg = MakeDigraphProb(freq_dg)
%MAKEGRAPHPROB Makes a digraph with edge weights corresponding to frequency
% of entry into one with edge weights corresponding to probability of
% entry.

prob_dg = freq_dg;

for ii=1:height(prob_dg.Nodes)
    ancestor = prob_dg.Nodes.Name{ ii };
    o_edges = prob_dg.outedges(ancestor);

    if ~isempty(o_edges)
        % normalize outgoing edge weights by their total weight:
        total_weight = 0;
        for jj = 1:length(o_edges)
            total_weight = total_weight + prob_dg.Edges.Weight(o_edges(jj));
        end

        for jj = 1:length(o_edges)
            prob_dg.Edges.Weight(o_edges(jj)) = ...
                prob_dg.Edges.Weight(o_edges(jj)) / total_weight;
        end
    end
end