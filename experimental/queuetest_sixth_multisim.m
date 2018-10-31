% Queuetest_Sixth multiple-simulation
% Purpose is to test multiple simulations:
% - Parameter inputs and toWorkspace structure outputs
% - ^ for the queue and for handles
% - Different solver modes and their effect on time
% - Logging multiple iterations and single iterations of toWorkspace's

N = 96;
simOut = repmat(Simulink.SimulationOutput, N, 1);
LastQueue.Value = zeros(1,5,50);
LastHandle.Value = 1;

for nn = 1:N
    tic;
    % 1 - Obtain power flow from DSS:
    DSSSolution.SolveNoControl;
    
    % 2 - Package DSS measurements for Simulink:
    DSSCircuit.SetActiveElement('Transformer.TReg1');
    xfm1 = DSSCircuit.ActiveCktElement;

    ControlledTransformerVoltages.Value = MakeComplex(xfm1.Voltages); 
    % [in ... | out ...]' (complex)

    ControlledTransformerCurrents.Value = MakeComplex(xfm1.Currents); 
    % [in ... | out ...]' (complex)

    ControlledTransformerPowers.Value = MakeComplex(xfm1.Powers); 
    % [in ... | out ...]' (complex)

    DSSCircuit.SetActiveElement('Transformer.TReg1'); % assume this is at the regulated bus
    RegulatedBus = DSSCircuit.ActiveCktElement;

    VTerminal.Value = MakeComplex(RegulatedBus.Voltages); 
    % [in ... | out ...]' (complex)
    
    xfms = DSSCircuit.Transformers;
    xfms.Name = 'TReg1';
    TReg1.Winding(tw).puTap = double(xfms.Tap);
    
    PresentTap.Value = double(TReg1.Winding(tw).puTap); 
    
    % 3 - configure simulation parameters with prior timestep's results:    
    TimeInSec.Value = double( nn*(24/N)*3600 );
    
    if nn > 1 % there exists an output from a prior iteration
%         LastHandle.Value = CurrHandle.Data(end); % 1-D vecto
        LastHandle.Value = CurrHandle;
%         LastQueue.Value = CurrQueue.signals.values(:,:,:,end);
        LastQueue.Value = CurrQueue;
    end
    
    % 4 - obtain control actions from Simulink:    
    simOut(nn) = sim('regcontrol_model', 'timeout', 1000);
    
    % 5 - execute tap changes in DSS:
%     xfms.Tap = xfms.Tap + TapChangeToMake.Data(end);
    xfms.Tap = xfms.Tap + TapChangeToMake;
    
    TimeElapsed = toc;
    
    fprintf('Iteration %d, Time = %g\n', nn, TimeElapsed);
    
    % 5 - Power flow after control actions:    
    DSSSolution.Solve;
end