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
%     per_imag
%     per_loadloss
%     per_noloadloss
%     per_R
%     per_Rs
%     bank
%     basefreq
%     bus
%     buses
%     conn
%     conns
%     emergamps
%     emerghkVA
%     enabled
%     faultrate
%     flrise
%     hsrise
%     kV
%     kVA
%     kVAs
%     kVs
%     like
%     m
%     MaxTap
%     MinTap
%     n
%     normamps
%     normhkVA
%     NumTaps
%     pctperm
%     phases
%     ppm_antifloat
%     repair
%     Rneut
%     sub
%     subname
%     tap
%     taps
%     thermal
%     wdg
%     windings
%     X12
%     X13
%     X23
%     XfmrCode
%     Xhl
%     Xht
%     Xlt
%     Xneut
%     XRConst
%     Xscarray
    
    
    % set regulator parameters:
    ActiveRegulator.MaxTapChange = 1;
    ActiveRegulator.IsReversible = 'No';
    InReverseMode = false; % as a result of IsReversible
    InCogenMode = false;
    CogenEnabled = false; % not in COM
    
    
%     band
%     basefreq
%     bus
%     Cogen
%     CTprim
%     debugtrace
%     delay
%     enabled
%     EventLog
%     inversetime
%     LDC_Z
%     like
%     maxtapchange
%     PTphase
%     ptratio
%     R
%     RemotePTRatio
%     Reset
%     rev_Z
%     revband
%     revDelay
%     reversible
%     revNeutral
%     revR
%     revThreshold
%     revvreg
%     revX
%     tapdelay
%     TapNum
%     tapwinding
%     transformer
%     vlimit
%     vreg
%     winding
%     X
    
end

%ControlledTransformer = setControlledTransformer('Reg1');



%% Emulating RegControl Sample: