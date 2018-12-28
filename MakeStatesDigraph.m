function states_dg = MakeStatesDigraph(sourceNodes, destNodes, blockpath)
%MAKESTATESDIGRAPH Build directed graph with 0 weights
%   Uses a list of sourceNodes and destNodes to build a directed graph,
%   with the full node names specified by the blockpath + node lists, and
%   all edges weighted at 0

    % 1 - concatenate blockpath with node names:
    sourceBP = strcat(blockpath, sourceNodes);
    destBP = strcat(blockpath, destNodes);
    
    % 1a - build initial graph:
    states_dg = digraph(sourceBP,destBP);
    
    % 2 - extract list of nodes and edges:
    EdgeTable = states_dg.Edges;
    NodeTable = states_dg.Nodes;

    % 2a - add weights column to EdgeTable:
    weights = zeros( length(sourceNodes), 1 );
    EdgeTable.Weight = weights;

    % 3 - Build final graph:
    states_dg = digraph(EdgeTable, NodeTable);
end

