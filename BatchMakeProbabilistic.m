function [varargout] = BatchMakeProbabilistic(regWsNames, varargin)
%BATCHMAKEPROBABILISTIC Makes multiple digraphs probabilistic
%   output digraphs should be same as input digraphs
    num_phases = length(regWsNames);
    num_dgs = length(varargin);

    for phase = 1:num_phases
        for dg = 1:num_dgs
            temp_dg = MakeDigraphProb( getfield(varargin{dg}, regWsNames{phase}) );
            varargin{dg} = setfield(varargin{dg}, regWsNames{phase}, temp_dg);
        end
    end
    
    varargout = varargin;
end

