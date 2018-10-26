%% Start COM Server
addpath(pwd);
import RegControlPkg.WindingObj;
import RegControlPkg.TransformerObj;
import RegControlPkg.RegControlObj;

enumpath = strcat(pwd, '\enums');
addpath(enumpath);

% execute DSSStartup.m
[DSSStartOK, DSSObj, DSSText] = DSSStartup;

if DSSStartOK
    a = 'DSS Started';
    formatSpec = "Compile (%s\\IEEE13Nodeckt_noreg.dss)";
    dirCommand = compose(formatSpec, pwd);
    DSSText.command = char(dirCommand);
    % Set up the interface variables
    DSSCircuit=DSSObj.ActiveCircuit;
    DSSSolution=DSSCircuit.Solution;
    DSSControlQueue = DSSCircuit.CtrlQueue;
else
    a = 'DSS Did Not Start';
end

disp(a)

%% Initializing Transformers and adding to script:
TReg1 = TransformerObj('fNphases', 1, 'bank', "reg1", 'XHL', 0.01, 'kVAs', [1666 1666], ...
    'buses', ["650.1", "RG60.1"], 'kVs', [2.4 2.4], 'pctLoadLoss', 0.01);

TReg2 = TransformerObj('fNphases', 1, 'bank', "reg1", 'XHL', 0.01, 'kVAs', [1666 1666], ...
    'buses', ["650.2", "RG60.2"], 'kVs', [2.4 2.4], 'pctLoadLoss', 0.01);

TReg3 = TransformerObj('fNphases', 1, 'bank', "reg1", 'XHL', 0.01, 'kVAs', [1666 1666], ...
    'buses', ["650.3", "RG60.3"], 'kVs', [2.4 2.4], 'pctLoadLoss', 0.01);

RCReg1 = RegControlObj('ElementName', TReg1.getName, 'xsfWinding', 2, 'Vreg', 122, ...
    'Bandwidth', 2.0, 'PTRatio', 20, 'CTRating', 700, 'R', 3, 'X', 9);

RCReg2 = RegControlObj('ElementName', TReg2.getName, 'xsfWinding', 2, 'Vreg', 122, ...
    'Bandwidth', 2.0, 'PTRatio', 20, 'CTRating', 700, 'R', 3, 'X', 9);

RCReg3 = RegControlObj('ElementName', TReg3.getName, 'xsfWinding', 2, 'Vreg', 122, ...
    'Bandwidth', 2.0, 'PTRatio', 20, 'CTRating', 700, 'R', 3, 'X', 9);

% new regcontrol.Reg1  transformer=Reg1 winding=2  vreg=122  band=2  ptratio=20 ctprim=700  R=3   X=9 !maxtapchange=1

DSSText.command = TReg1.DSSCommand;
DSSText.command = TReg2.DSSCommand;
DSSText.command = TReg3.DSSCommand;

DSSText.command = RCReg2.DSSCommand;
DSSText.command = RCReg3.DSSCommand;

%% Data packaging for Simulink:

LastHandle = Simulink.Parameter;
LastHandle.DataType = 'double';

TimeInSec = Simulink.Parameter;
TimeInSec.DataType = 'double';

LastQueue = Simulink.Parameter;
LastQueue.DataType = 'double';

ControlledTransformerVoltages = Simulink.Parameter;
ControlledTransformerVoltages.DataType = 'double';
% ControlledTransformerVoltages.Value = MakeComplex(xfm1.Voltages); 
% [in ... | out ...]' (complex)

ControlledTransformerCurrents = Simulink.Parameter;
ControlledTransformerCurrents.DataType = 'double';
% ControlledTransformerCurrents.Value = MakeComplex(xfm1.Currents); 
% [in ... | out ...]' (complex)

ControlledTransformerPowers = Simulink.Parameter;
ControlledTransformerPowers.DataType = 'double';
% ControlledTransformerPowers.Value = MakeComplex(xfm1.Powers); 
% [in ... | out ...]' (complex)

DSSCircuit.SetActiveElement('Transformer.TReg1'); % assume this is at the regulated bus
RegulatedBus = DSSCircuit.ActiveCktElement;

VTerminal = Simulink.Parameter;
VTerminal.DataType = 'double';
% VTerminal.Value = MakeComplex(RegulatedBus.Voltages); 
% [in ... | out ...]' (complex)

SignalElems(1) = Simulink.BusElement;
SignalElems(1).Name = 'ControlledTransformerVoltages';
SignalElems(1).Dimensions = 4;
SignalElems(1).DimensionsMode = 'Fixed';
SignalElems(1).DataType = 'double';
SignalElems(1).SampleTime = -1;
SignalElems(1).Complexity = 'complex';

SignalElems(2) = Simulink.BusElement;
SignalElems(2).Name = 'ControlledTransformerCurrents';
SignalElems(2).Dimensions = 4;
SignalElems(2).DimensionsMode = 'Fixed';
SignalElems(2).DataType = 'double';
SignalElems(2).SampleTime = -1;
SignalElems(2).Complexity = 'complex';

SignalElems(3) = Simulink.BusElement;
SignalElems(3).Name = 'ControlledTransformerPowers';
SignalElems(3).Dimensions = 4;
SignalElems(3).DimensionsMode = 'Fixed';
SignalElems(3).DataType = 'double';
SignalElems(3).SampleTime = -1;
SignalElems(3).Complexity = 'complex';

SignalElems(4) = Simulink.BusElement;
SignalElems(4).Name = 'VTerminal';
SignalElems(4).Dimensions = 4;
SignalElems(4).DimensionsMode = 'Fixed';
SignalElems(4).DataType = 'double';
SignalElems(4).SampleTime = -1;
SignalElems(4).Complexity = 'complex';

SignalBus = Simulink.Bus;
SignalBus.Elements = SignalElems;

% 2 buses for equipment:

BandWidth = Simulink.Parameter;
BandWidth.DataType = 'double';
BandWidth.Value = double(RCReg1.Bandwidth); 

EquipElems(1) = Simulink.BusElement;
EquipElems(1).Name = 'BandWidth';
EquipElems(1).Dimensions = 1;
EquipElems(1).DimensionsMode = 'Fixed';
EquipElems(1).DataType = 'double';
EquipElems(1).SampleTime = -1;
EquipElems(1).Complexity = 'real';

UsingRegulatedBus = Simulink.Parameter;
UsingRegulatedBus.DataType = 'boolean';
UsingRegulatedBus.Value = boolean(RCReg1.UsingRegulatedBus); 

EquipElems(2) = Simulink.BusElement;
EquipElems(2).Name = 'UsingRegulatedBus';
EquipElems(2).Dimensions = 1;
EquipElems(2).DimensionsMode = 'Fixed';
EquipElems(2).DataType = 'boolean';
EquipElems(2).SampleTime = -1;
EquipElems(2).Complexity = 'real';

CogenEnabled = Simulink.Parameter;
CogenEnabled.DataType = 'boolean';
CogenEnabled.Value = boolean(RCReg1.CogenEnabled); 

EquipElems(3) = Simulink.BusElement;
EquipElems(3).Name = 'CogenEnabled';
EquipElems(3).Dimensions = 1;
EquipElems(3).DimensionsMode = 'Fixed';
EquipElems(3).DataType = 'boolean';
EquipElems(3).SampleTime = -1;
EquipElems(3).Complexity = 'real';

LDC_Z = Simulink.Parameter;
LDC_Z.DataType = 'double';
LDC_Z.Value = double(RCReg1.LDC_Z); 

EquipElems(4) = Simulink.BusElement;
EquipElems(4).Name = 'LDC_Z';
EquipElems(4).Dimensions = 1;
EquipElems(4).DimensionsMode = 'Fixed';
EquipElems(4).DataType = 'double';
EquipElems(4).SampleTime = -1;
EquipElems(4).Complexity = 'real';

TapLimitPerChange = Simulink.Parameter;
TapLimitPerChange.DataType = 'uint8';
TapLimitPerChange.Value = uint8(RCReg1.TapLimitPerChange); 

EquipElems(5) = Simulink.BusElement;
EquipElems(5).Name = 'TapLimitPerChange';
EquipElems(5).Dimensions = 1;
EquipElems(5).DimensionsMode = 'Fixed';
EquipElems(5).DataType = 'uint8';
EquipElems(5).SampleTime = -1;
EquipElems(5).Complexity = 'real';

PTratio = Simulink.Parameter;
PTratio.DataType = 'double';
PTratio.Value = double(RCReg1.PTRatio); 

EquipElems(6) = Simulink.BusElement;
EquipElems(6).Name = 'PTratio';
EquipElems(6).Dimensions = 1;
EquipElems(6).DimensionsMode = 'Fixed';
EquipElems(6).DataType = 'double';
EquipElems(6).SampleTime = -1;
EquipElems(6).Complexity = 'real';

RevBand = Simulink.Parameter;
RevBand.DataType = 'double';
RevBand.Value = double(RCReg1.revBandwidth); 

EquipElems(7) = Simulink.BusElement;
EquipElems(7).Name = 'RevBand';
EquipElems(7).Dimensions = 1;
EquipElems(7).DimensionsMode = 'Fixed';
EquipElems(7).DataType = 'double';
EquipElems(7).SampleTime = -1;
EquipElems(7).Complexity = 'real';

RevDelay = Simulink.Parameter;
RevDelay.DataType = 'double';
RevDelay.Value = double(RCReg1.RevDelay); 

EquipElems(8) = Simulink.BusElement;
EquipElems(8).Name = 'RevDelay';
EquipElems(8).Dimensions = 1;
EquipElems(8).DimensionsMode = 'Fixed';
EquipElems(8).DataType = 'double';
EquipElems(8).SampleTime = -1;
EquipElems(8).Complexity = 'real';

IsReversible = Simulink.Parameter;
IsReversible.DataType = 'boolean';
IsReversible.Value = boolean(RCReg1.IsReversible); 

EquipElems(9) = Simulink.BusElement;
EquipElems(9).Name = 'IsReversible';
EquipElems(9).Dimensions = 1;
EquipElems(9).DimensionsMode = 'Fixed';
EquipElems(9).DataType = 'boolean';
EquipElems(9).SampleTime = -1;
EquipElems(9).Complexity = 'real';

RevVreg = Simulink.Parameter;
RevVreg.DataType = 'double';
RevVreg.Value = double(RCReg1.RevVreg); 

EquipElems(10) = Simulink.BusElement;
EquipElems(10).Name = 'RevVreg';
EquipElems(10).Dimensions = 1;
EquipElems(10).DimensionsMode = 'Fixed';
EquipElems(10).DataType = 'double';
EquipElems(10).SampleTime = -1;
EquipElems(10).Complexity = 'real';

RevPowerThreshold = Simulink.Parameter;
RevPowerThreshold.DataType = 'double';
RevPowerThreshold.Value = double(RCReg1.revPowerThreshold); 

EquipElems(11) = Simulink.BusElement;
EquipElems(11).Name = 'RevPowerThreshold';
EquipElems(11).Dimensions = 1;
EquipElems(11).DimensionsMode = 'Fixed';
EquipElems(11).DataType = 'double';
EquipElems(11).SampleTime = -1;
EquipElems(11).Complexity = 'real';

Vlimit = Simulink.Parameter;
Vlimit.DataType = 'double';
Vlimit.Value = double(RCReg1.Vlimit); 

EquipElems(12) = Simulink.BusElement;
EquipElems(12).Name = 'Vlimit';
EquipElems(12).Dimensions = 1;
EquipElems(12).DimensionsMode = 'Fixed';
EquipElems(12).DataType = 'double';
EquipElems(12).SampleTime = -1;
EquipElems(12).Complexity = 'real';

Vreg = Simulink.Parameter;
Vreg.DataType = 'double';
Vreg.Value = double(RCReg1.Vreg); 

EquipElems(13) = Simulink.BusElement;
EquipElems(13).Name = 'Vreg';
EquipElems(13).Dimensions = 1;
EquipElems(13).DimensionsMode = 'Fixed';
EquipElems(13).DataType = 'double';
EquipElems(13).SampleTime = -1;
EquipElems(13).Complexity = 'real';

TapDelay = Simulink.Parameter;
TapDelay.DataType = 'double';
TapDelay.Value = double(RCReg1.TapDelay); 

EquipElems(14) = Simulink.BusElement;
EquipElems(14).Name = 'TapDelay';
EquipElems(14).Dimensions = 1;
EquipElems(14).DimensionsMode = 'Fixed';
EquipElems(14).DataType = 'double';
EquipElems(14).SampleTime = -1;
EquipElems(14).Complexity = 'real';

TapWinding = Simulink.Parameter;
TapWinding.DataType = 'uint8';
TapWinding.Value = uint8(RCReg1.xsfWinding); 

EquipElems(15) = Simulink.BusElement;
EquipElems(15).Name = 'TapWinding';
EquipElems(15).Dimensions = 1;
EquipElems(15).DimensionsMode = 'Fixed';
EquipElems(15).DataType = 'uint8';
EquipElems(15).SampleTime = -1;
EquipElems(15).Complexity = 'real';

FPTphase = Simulink.Parameter;
FPTphase.DataType = 'uint8';
FPTphase.Value = uint8(RCReg1.fPTphase); 

EquipElems(16) = Simulink.BusElement;
EquipElems(16).Name = 'FPTphase';
EquipElems(16).Dimensions = 1;
EquipElems(16).DimensionsMode = 'Fixed';
EquipElems(16).DataType = 'uint8';
EquipElems(16).SampleTime = -1;
EquipElems(16).Complexity = 'real';


%----

tw = TapWinding.Value;

MinTap = Simulink.Parameter;
MinTap.DataType = 'double';
MinTap.Value = double(TReg1.Winding(tw).MinTap); 

EquipElems(17) = Simulink.BusElement;
EquipElems(17).Name = 'MinTap';
EquipElems(17).Dimensions = 1;
EquipElems(17).DimensionsMode = 'Fixed';
EquipElems(17).DataType = 'double';
EquipElems(17).SampleTime = -1;
EquipElems(17).Complexity = 'real';

MaxTap = Simulink.Parameter;
MaxTap.DataType = 'double';
MaxTap.Value = double(TReg1.Winding(tw).MaxTap); 

EquipElems(18) = Simulink.BusElement;
EquipElems(18).Name = 'MaxTap';
EquipElems(18).Dimensions = 1;
EquipElems(18).DimensionsMode = 'Fixed';
EquipElems(18).DataType = 'double';
EquipElems(18).SampleTime = -1;
EquipElems(18).Complexity = 'real';

TapIncrement = Simulink.Parameter;
TapIncrement.DataType = 'double';
TapIncrement.Value = double(TReg1.Winding(tw).TapIncrement);

EquipElems(19) = Simulink.BusElement;
EquipElems(19).Name = 'TapIncrement';
EquipElems(19).Dimensions = 1;
EquipElems(19).DimensionsMode = 'Fixed';
EquipElems(19).DataType = 'double';
EquipElems(19).SampleTime = -1;
EquipElems(19).Complexity = 'real';

ControlledTransformerConnection = Simulink.Parameter;
ControlledTransformerConnection.DataType = 'uint8';
ControlledTransformerConnection.Value = ...
    uint8(TReg1.Winding(tw).Connection); 

EquipElems(20) = Simulink.BusElement;
EquipElems(20).Name = 'ControlledTransformerConnection';
EquipElems(20).Dimensions = 1;
EquipElems(20).DimensionsMode = 'Fixed';
EquipElems(20).DataType = 'uint8';
EquipElems(20).SampleTime = -1;
EquipElems(20).Complexity = 'real';

BaseVoltage = Simulink.Parameter;
BaseVoltage.DataType = 'double';
BaseVoltage.Value = double(TReg1.Winding(tw).Vbase); 

EquipElems(21) = Simulink.BusElement;
EquipElems(21).Name = 'BaseVoltage';
EquipElems(21).Dimensions = 1;
EquipElems(21).DimensionsMode = 'Fixed';
EquipElems(21).DataType = 'double';
EquipElems(21).SampleTime = -1;
EquipElems(21).Complexity = 'real';

PresentTap = Simulink.Parameter;
PresentTap.DataType = 'double';
PresentTap.Value = double(TReg1.Winding(tw).puTap); 

EquipElems(22) = Simulink.BusElement;
EquipElems(22).Name = 'PresentTap';
EquipElems(22).Dimensions = 1;
EquipElems(22).DimensionsMode = 'Fixed';
EquipElems(22).DataType = 'double';
EquipElems(22).SampleTime = -1;
EquipElems(22).Complexity = 'real';

NumConductors = Simulink.Parameter;
NumConductors.DataType = 'uint8';
NumConductors.Value = uint8(TReg1.fNconds);

EquipElems(23) = Simulink.BusElement;
EquipElems(23).Name = 'NumConductors';
EquipElems(23).Dimensions = 1;
EquipElems(23).DimensionsMode = 'Fixed';
EquipElems(23).DataType = 'uint8';
EquipElems(23).SampleTime = -1;
EquipElems(23).Complexity = 'real';

CTRating = Simulink.Parameter;
CTRating.DataType = 'double';
CTRating.Value = double(RCReg1.CTRating);

EquipElems(24) = Simulink.BusElement;
EquipElems(24).Name = 'CTRating';
EquipElems(24).Dimensions = 1;
EquipElems(24).DimensionsMode = 'Fixed';
EquipElems(24).DataType = 'double';
EquipElems(24).SampleTime = -1;
EquipElems(24).Complexity = 'real';

NumPhases = Simulink.Parameter;
NumPhases.DataType = 'uint8';
NumPhases.Value = uint8(TReg1.fNphases);

EquipElems(25) = Simulink.BusElement;
EquipElems(25).Name = 'NumPhases';
EquipElems(25).Dimensions = 1;
EquipElems(25).DimensionsMode = 'Fixed';
EquipElems(25).DataType = 'uint8';
EquipElems(25).SampleTime = -1;
EquipElems(25).Complexity = 'real';

IsInverseTime = Simulink.Parameter;
IsInverseTime.DataType = 'boolean';
IsInverseTime.Value = boolean(RCReg1.fInverseTime);

EquipElems(26) = Simulink.BusElement;
EquipElems(26).Name = 'IsInverseTime';
EquipElems(26).Dimensions = 1;
EquipElems(26).DimensionsMode = 'Fixed';
EquipElems(26).DataType = 'boolean';
EquipElems(26).SampleTime = -1;
EquipElems(26).Complexity = 'real';

R = Simulink.Parameter;
R.DataType = 'double';
R.Value = double(RCReg1.R);

EquipElems(27) = Simulink.BusElement;
EquipElems(27).Name = 'R';
EquipElems(27).Dimensions = 1;
EquipElems(27).DimensionsMode = 'Fixed';
EquipElems(27).DataType = 'double';
EquipElems(27).SampleTime = -1;
EquipElems(27).Complexity = 'real';

X = Simulink.Parameter;
X.DataType = 'double';
X.Value = double(RCReg1.X);

EquipElems(28) = Simulink.BusElement;
EquipElems(28).Name = 'X';
EquipElems(28).Dimensions = 1;
EquipElems(28).DimensionsMode = 'Fixed';
EquipElems(28).DataType = 'double';
EquipElems(28).SampleTime = -1;
EquipElems(28).Complexity = 'real';

revR = Simulink.Parameter;
revR.DataType = 'double';
revR.Value = double(RCReg1.revR);

EquipElems(29) = Simulink.BusElement;
EquipElems(29).Name = 'revR';
EquipElems(29).Dimensions = 1;
EquipElems(29).DimensionsMode = 'Fixed';
EquipElems(29).DataType = 'double';
EquipElems(29).SampleTime = -1;
EquipElems(29).Complexity = 'real';

revX = Simulink.Parameter;
revX.DataType = 'double';
revX.Value = double(RCReg1.revX);

EquipElems(30) = Simulink.BusElement;
EquipElems(30).Name = 'revX';
EquipElems(30).Dimensions = 1;
EquipElems(30).DimensionsMode = 'Fixed';
EquipElems(30).DataType = 'double';
EquipElems(30).SampleTime = -1;
EquipElems(30).Complexity = 'real';

revLDC_Z = Simulink.Parameter;
revLDC_Z.DataType = 'double';
revLDC_Z.Value = double(RCReg1.revLDC_Z);

EquipElems(31) = Simulink.BusElement;
EquipElems(31).Name = 'revLDC_Z';
EquipElems(31).Dimensions = 1;
EquipElems(31).DimensionsMode = 'Fixed';
EquipElems(31).DataType = 'double';
EquipElems(31).SampleTime = -1;
EquipElems(31).Complexity = 'real';

TimeDelay = Simulink.Parameter;
TimeDelay.DataType = 'double';
TimeDelay.Value = double(RCReg1.TimeDelay);

EquipElems(32) = Simulink.BusElement;
EquipElems(32).Name = 'TimeDelay';
EquipElems(32).Dimensions = 1;
EquipElems(32).DimensionsMode = 'Fixed';
EquipElems(32).DataType = 'double';
EquipElems(32).SampleTime = -1;
EquipElems(32).Complexity = 'real';

EquipmentBus = Simulink.Bus;
EquipmentBus.Elements = EquipElems;

%% Bootstrap for single-run testing purposes:
ControlledTransformerVoltages.Value = 100*complex([2.4018 0 2.3882 0]', ...
    [-0.0003 0 -0.0063 0]');
ControlledTransformerCurrents.Value = 10*complex([2.8348 -2.8348 -2.8348 2.8348]', ...
    [-1.0965 1.0965 1.0965 -1.0965]');
ControlledTransformerPowers.Value = 10*complex([6.8090 0 -6.7770 0]', ...
    [2.6327 0 -2.6008 0]');
VTerminal.Value = 100*complex([2.4018 0 2.3882 0]', ...
    [-0.0003 0 -0.0063 0]');

%% Looping the simulation (1 run = 1 timestep in DSS)

% Add loadshape:
DSSText.Command = 'New LoadShape.LoadShape2a npts=96 interval=0.25';
DSSCircuit.LoadShape.name = 'LoadShape2a';
ls = csvread('LoadShape1.csv');
feature('COM_SafeArraySingleDim',1);
DSSCircuit.LoadShape.pmult =  ls;
feature('COM_SafeArraySingleDim',0);

% Apply loadshape to daily simulation:
DSSLoads = DSSCircuit.Loads;
iLoad = DSSLoads.First;
while iLoad>0
    DSSLoads.daily = 'LoadShape2a';
    iLoad = DSSLoads.Next;
end

% Solve for a daily simulation:
DSSText.Command = 'set mode=daily stepsize=15m number=96 controlmode=time';
% number of solns to perform for Monte Carlo/daily load simulations
DSSText.Command = 'Set number=1';  % Still in Daily mode; each Solve does 15 min

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
        LastHandle.Value = CurrHandle.Data(end); % 1-D vecto
        LastQueue.Value = CurrQueue.signals.values(:,:,:,end);
    end
    
    % 4 - obtain control actions from Simulink:    
    simOut(nn) = sim('regcontrol_model', 'timeout', 1000);
    
    % 5 - execute tap changes in DSS:
    xfms.Tap = xfms.Tap + TapChangeToMake.Data(end);
    
    TimeElapsed = toc;
    
    fprintf('Iteration %d, Time = %g\n', nn, TimeElapsed);
    
    % 5 - Power flow after control actions:    
    DSSSolution.Solve;
end

DSSText.Command = 'Show Eventlog';