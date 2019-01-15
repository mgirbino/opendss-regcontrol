function [matching_table] = compareCharts(chart1, chart2, fieldnames, regNames, sequences, N)
%COMPARECHARTS outputs a percentage match between 2 probability charts
%   Separates charts into vectors of IDs and counts number of matches,
%   normalized to number of entries (N)
    seqDims = size(sequences);
    matching = zeros(seqDims(1:2));

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
                
                % use dot product to get correlation, then divide by total:
                matching(phase,sm) = matching(phase,sm) + dot(bools1, bools2)/N;
            end
        end
    end
    
    matching_table = array2table(matching);
    matching_table.Properties.VariableNames = fieldnames;
    matching_table.Properties.RowNames = regNames;
end

