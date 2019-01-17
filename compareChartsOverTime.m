function [matching, varargout] = compareChartsOverTime(chart1, chart2, ...
    fieldnames, regNames, sequences, N, varargin)
%COMPARECHARTSOVERTIME outputs a percentage match between 2 probability charts
%   Separates charts into vectors of IDs and counts number of matches,
%   normalized to number of entries (N), in a 3D matrix tracking match over
%   time (optionally beginning at startIdx <= N, with a specified window of
%   recent points)

    % use inputParser for adjustable windowing!!
    % args are startIdx and window
    p = inputParser;
    numchk = {'numeric'};
    posint = {'nonempty','integer','positive','nonzero'};

    % doubles:
    addOptional(p,'StartIdx',1,@(x)validateattributes(x,numchk,posint));
    addOptional(p,'Window',N/12,@(x)validateattributes(x,numchk,posint));

    parse(p,varargin{:});

    startIdx = p.Results.StartIdx;
    window = p.Results.Window;
    
    % check for/correct infeasible window:
    tempStart = startIdx - window;
    if tempStart < 1
        startIdx = startIdx - tempStart;
    end
    
    seqDims = size(sequences);
    
    % same first 2 dimensions of sequences, with depth for each time step
    sz = (N - startIdx + 1);
    matching = zeros( [seqDims(1:2) sz] );

    for phase = 1:seqDims(1)
        for sm = 1:seqDims(2)
            for id = 1:seqDims(3)
                % break if no ID specified:
                if isempty( sequences(phase,sm,id).ID )
                    break
                end
                
                
                % get vector of IDs from 2 charts:
                tab1ph1 = chart1{:,regNames{phase}};
                tab1ph1_sm = tab1ph1{:,fieldnames{sm}};
                tab1ph1_id = tab1ph1_sm.ID;

                tab2ph1 = chart2{:,regNames{phase}};
                tab2ph1_sm = tab2ph1{:,fieldnames{sm}};
                tab2ph1_id = tab2ph1_sm.ID;
                
                % get occurrences of a single ID:
                cmpWith = id * ones(N,1);
                
                bools1 = double(tab1ph1_id == cmpWith);
                bools2 = double(tab2ph1_id == cmpWith);
                
                for nn = startIdx:N
                    % use dot product to get correlation, then divide by total:
                    matching( phase, sm, (nn-startIdx+1) ) = ...
                        matching( phase, sm, (nn-startIdx+1) ) + ...
                        dot( bools1( (nn-window+1):nn ), bools2( (nn-window+1):nn ) )/window;
                end
            end
        end
    end
    
    % optionally return a table:
    if nargout == 2
        match_struct = struct;
        match_struct.idx = [startIdx:N]';
        
        for phase = 1:seqDims(1)
            reg1match = zeros(seqDims(2), sz);
            reg1match(:,:) = matching(phase,:,:);
            reg1_table = array2table(reg1match');
            reg1_table.Properties.VariableNames = fieldnames;
            
            match_struct = setfield(match_struct, regNames{phase}, reg1_table);
        end
        varargout{1} = struct2table(match_struct);
%         matching_table.Properties.VariableNames = regNames;
    end
    
%     matching_table = array2table(matching);
%     matching_table.Properties.VariableNames = fieldnames;
%     matching_table.Properties.RowNames = regNames;
end