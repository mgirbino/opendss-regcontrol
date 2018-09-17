classdef ControlledElement < Simulink.Parameter
    properties (PropertyType = 'double scalar', Access = private)
        HighWindingVoltage
        LowWindingVoltage
        Currents % need to pre-allocate
    end
    
    properties (PropertyType = 'int32 scalar', Access = private)
        Nconds
    end
    
    methods
        function CE = ControlledElement(...
                highWindingVoltage, lowWindingVoltage, ...
                current, nconds)
            if nargin > 0
                CE.HighWindingVoltage = highWindingVoltage;
                CE.LowWindingVoltage = lowWindingVoltage;
                CE.Current = current;
                CE.Nconds = nconds;
            else
                CE.HighWindingVoltage = highWindingVoltage;
                CE.LowWindingVoltage = lowWindingVoltage;
                CE.Current = current;
                CE.Nconds = nconds;
            end
        end
        
        function CE = set.Nconds(CE, nconds)
            if nconds > 0 && nconds <= 2
                CE.Nconds = nconds;
            else
                error('Invalid number')
            end
        end
        
        function nconds = GetNconds(CE)
            nconds = CE.Nconds;
        end
        
        function currents = GetCurrents(CE)
            currents = CE.Currents;
        end
        
        function VBuffer = GetWindingVoltages(CE, ...
                ElementTerminal, VBuffer)
            if ElementTerminal == 1
                VBuffer = CE.HighWindingVoltage;
            elseif ElementTerminal == 2
                    VBuffer = CE.LowWindingVoltage;
            end
    end
end