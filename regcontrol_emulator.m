%% Set all transformer parameters:
transformer_regs = struct('Reg1', 'Reg1', 'Reg', 'Reg2', 'Reg3', 'Reg3');

fields = fieldnames(transformer_regs);

for fn=fields' % iteration through all named transformers
    % assign active devices:
    DSSCircuit.Transformer.name = fn{1};
    DSSCircuit.RegControls.name = transformer_regs.(fn{1});
    
    ControlledTransformer = DSSCircuit.Transformer;
    ActiveRegulator = DSSCircuit.RegControls; % not a variable in Sample
    
    % set transformer parameters:
    Bus = null;

    % set regulator parameters:
    ActiveRegulator.MaxTapChange = 1;
    ActiveRegulator.IsReversible = 'No';
    InReverseMode = false; % as a result of IsReversible
    InCogenMode = false;
    CogenEnabled = false; % not in COM
    
    % initialize helpers:
    VBuffer = zeros(3,1);
    FPTphase = Simulink.Parameter(FPTphases.DEFAULT);
    
end

%ControlledTransformer = setControlledTransformer('Reg1');



%% Emulating RegControl Sample: