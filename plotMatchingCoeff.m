function plotMatchingCoeff(plot_title, phaseName, time, matching_tab, varargin)
%PLOTMATCHINGCOEFF Utility to plot matching coefficients, optionally
%probabilities
%   Used to automate process, not customizeable
    Idx = matching_tab.idx;
    
    matching_tab_1ph = matching_tab{:,{phaseName}};
    
    plot(time(Idx), matching_tab_1ph.MakeTC, '+k-');
    hold on
    plot(time(Idx), matching_tab_1ph.Exec, 'xr-');
    plot(time(Idx), matching_tab_1ph.LFwd, '^b-');
    plot(time(Idx), matching_tab_1ph.LRev, 'og-');
    
    fieldnames = {'MakeTC' 'Exec' 'LFwd' 'LRev' 'RevN'};
    leg_text = strcat(fieldnames(1:4), ' - Matching Coefficient');
    
    if nargin == 5
        prob_tab = varargin{1};
        prob_tab_1ph = prob_tab{:,{phaseName}};
        
        plot(time(Idx), prob_tab_1ph.MakeTC.P(Idx), '.k:');
        plot(time(Idx), prob_tab_1ph.Exec.P(Idx), '.r:');
        plot(time(Idx), prob_tab_1ph.LFwd.P(Idx), '.b:');
        plot(time(Idx), prob_tab_1ph.LRev.P(Idx), '.g:');
        
        ylabel('Matching Coefficient and Event Probability');
        
        leg_text = cat(2, leg_text, ...
            strcat(fieldnames(1:4), ' - Event Probability') );
    else
        ylabel('Matching Coefficient');
    end
    
    grid minor

    legend(leg_text, 'Location', 'east');
    title( sprintf('%s - %s', plot_title, phaseName) );
    xlabel('Time in Hours');
    axis([0 25 0 1.1 ]);
end

