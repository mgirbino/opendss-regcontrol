% initiate DoPendingAction variables:

LastChange = Simulink.Parameter(0);
ProposedChange = Simulink.Parameter(0);
NumTaps = Simulink.Parameter(0);
ControlMode = Simulink.Parameter(ControlModes.TIMEDRIVEN);
DSSCircuit.Transformer.name = 'Reg1';
Increment = Simulink.Parameter( 1 / (DSSCircuit.Transformer.NumTaps) ); % in pu

% LastChange = 0;
% ProposedChange = 0;
% NumTaps = 0;
% ControlMode = ControlModes.TIMEDRIVEN;
% DSSCircuit.Transformer.name = 'Reg1';
% Increment = 1 / ( DSSCircuit.Transformer.NumTaps ); % in pu