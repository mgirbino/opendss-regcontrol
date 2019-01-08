%% Start COM Server
addpath(pwd);
import RegControlPkg.WindingObj;
import RegControlPkg.TransformerObj;
import RegControlPkg.RegControlObj;

enumpath = strcat(pwd, '\enums');
addpath(enumpath);

exppath = strcat(pwd, '\experimental');
addpath(exppath);

% execute DSSStartup.m
[DSSStartOK, DSSObj, DSSText] = DSSStartup;

if DSSStartOK
    a = 'DSS Started';
    formatSpec = "Compile (%s\\IEEE13Nodeckt_noreg_692.dss)";
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
TReg1_1 = TransformerObj('fNphases', 1, 'bank', "reg1", 'XHL', 0.01, 'kVAs', [1666 1666], ...
    'buses', ["650.1", "RG60.1"], 'kVs', [2.4 2.4], 'pctLoadLoss', 0.01);

TReg1_2 = TransformerObj('fNphases', 1, 'bank', "reg1", 'XHL', 0.01, 'kVAs', [1666 1666], ...
    'buses', ["650.2", "RG60.2"], 'kVs', [2.4 2.4], 'pctLoadLoss', 0.01);

TReg1_3 = TransformerObj('fNphases', 1, 'bank', "reg1", 'XHL', 0.01, 'kVAs', [1666 1666], ...
    'buses', ["650.3", "RG60.3"], 'kVs', [2.4 2.4], 'pctLoadLoss', 0.01);

RCReg1_1 = RegControlObj('ElementName', TReg1_1.getName, 'xsfWinding', 2, 'Vreg', 122, ...
    'Bandwidth', 2.0, 'PTRatio', 20, 'CTRating', 700, 'R', 3, 'X', 9);

RCReg1_2 = RegControlObj('ElementName', TReg1_2.getName, 'xsfWinding', 2, 'Vreg', 122, ...
    'Bandwidth', 2.0, 'PTRatio', 20, 'CTRating', 700, 'R', 3, 'X', 9);

RCReg1_3 = RegControlObj('ElementName', TReg1_3.getName, 'xsfWinding', 2, 'Vreg', 122, ...
    'Bandwidth', 2.0, 'PTRatio', 20, 'CTRating', 700, 'R', 3, 'X', 9);

% new regcontrol.Reg1  transformer=Reg1 winding=2  vreg=122  band=2  ptratio=20 ctprim=700  R=3   X=9 !maxtapchange=1

DSSText.command = TReg1_1.DSSCommand;
DSSText.command = TReg1_2.DSSCommand;
DSSText.command = TReg1_3.DSSCommand;

DSSText.command = RCReg1_1.DSSCommand;
DSSText.command = RCReg1_2.DSSCommand;
DSSText.command = RCReg1_3.DSSCommand;

% reversible regulator at 692:
TReg2_1 = TransformerObj('fNphases', 1, 'bank', "reg2", 'XHL', 0.01, 'kVAs', [1666 1666], ...
    'buses', ["RG61.1", "692.1"], 'kVs', [2.4 2.4], 'pctLoadLoss', 0.01);

TReg2_2 = TransformerObj('fNphases', 1, 'bank', "reg2", 'XHL', 0.01, 'kVAs', [1666 1666], ...
    'buses', ["RG61.2", "692.2"], 'kVs', [2.4 2.4], 'pctLoadLoss', 0.01);

TReg2_3 = TransformerObj('fNphases', 1, 'bank', "reg2", 'XHL', 0.01, 'kVAs', [1666 1666], ...
    'buses', ["RG61.3", "692.3"], 'kVs', [2.4 2.4], 'pctLoadLoss', 0.01);

RCReg2_1 = RegControlObj('ElementName', TReg2_1.getName, 'xsfWinding', 2, 'Vreg', 122, ...
    'Bandwidth', 2.0, 'PTRatio', 20, 'CTRating', 700, 'R', 3, 'X', 9, ...
    'IsReversible', true, 'RevVreg', 122, 'ReverseNeutral', false);

RCReg2_2 = RegControlObj('ElementName', TReg2_2.getName, 'xsfWinding', 2, 'Vreg', 122, ...
    'Bandwidth', 2.0, 'PTRatio', 20, 'CTRating', 700, 'R', 3, 'X', 9, ...
    'IsReversible', true, 'RevVreg', 122, 'ReverseNeutral', false);

RCReg2_3 = RegControlObj('ElementName', TReg2_3.getName, 'xsfWinding', 2, 'Vreg', 122, ...
    'Bandwidth', 2.0, 'PTRatio', 20, 'CTRating', 700, 'R', 3, 'X', 9, ...
    'IsReversible', true, 'RevVreg', 122, 'ReverseNeutral', false);

DSSText.command = TReg2_1.DSSCommand;
DSSText.command = TReg2_2.DSSCommand;
DSSText.command = TReg2_3.DSSCommand;

xsfNames = {TReg2_1.getName; TReg2_2.getName; TReg2_3.getName};
regNames = {RCReg2_1.getName; RCReg2_2.getName; RCReg2_3.getName};
regWsNames = {'RegControl1'; 'RegControl2'; 'RegControl3'};
xsfIncr = [TReg2_1.Winding(RCReg2_1.xsfWinding).TapIncrement;
    TReg2_2.Winding(RCReg2_2.xsfWinding).TapIncrement;
    TReg2_3.Winding(RCReg2_3.xsfWinding).TapIncrement];

%% Data packaging for Simulink:

TimeInSec = Simulink.Parameter;
TimeInSec.DataType = 'double';

LastQueue = Simulink.Parameter;
LastQueue.DataType = 'double';

LastHandle = Simulink.Parameter;
LastHandle.DataType = 'uint8';
LastHandle.Value = uint8(0);

ControlledTransformerVoltages = Simulink.Parameter;
ControlledTransformerVoltages.DataType = 'double';
ControlledTransformerVoltages.Value = zeros(4,3); % pre-allocation

ControlledTransformerCurrents = Simulink.Parameter;
ControlledTransformerCurrents.DataType = 'double';
ControlledTransformerCurrents.Value = zeros(4,3); % pre-allocation

ControlledTransformerPowers = Simulink.Parameter;
ControlledTransformerPowers.DataType = 'double';
ControlledTransformerPowers.Value = zeros(4,3); % pre-allocation

VTerminal = Simulink.Parameter;
VTerminal.DataType = 'double';
VTerminal.Value = zeros(4,3); % pre-allocation

% Bus:

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
BandWidth.Value = double(RCReg2_1.Bandwidth); 

EquipElems(1) = Simulink.BusElement;
EquipElems(1).Name = 'BandWidth';
EquipElems(1).Dimensions = 1;
EquipElems(1).DimensionsMode = 'Fixed';
EquipElems(1).DataType = 'double';
EquipElems(1).SampleTime = -1;
EquipElems(1).Complexity = 'real';

UsingRegulatedBus = Simulink.Parameter;
UsingRegulatedBus.DataType = 'boolean';
UsingRegulatedBus.Value = boolean(RCReg2_1.UsingRegulatedBus); 

EquipElems(2) = Simulink.BusElement;
EquipElems(2).Name = 'UsingRegulatedBus';
EquipElems(2).Dimensions = 1;
EquipElems(2).DimensionsMode = 'Fixed';
EquipElems(2).DataType = 'boolean';
EquipElems(2).SampleTime = -1;
EquipElems(2).Complexity = 'real';

CogenEnabled = Simulink.Parameter;
CogenEnabled.DataType = 'boolean';
CogenEnabled.Value = boolean(RCReg2_1.CogenEnabled); 

EquipElems(3) = Simulink.BusElement;
EquipElems(3).Name = 'CogenEnabled';
EquipElems(3).Dimensions = 1;
EquipElems(3).DimensionsMode = 'Fixed';
EquipElems(3).DataType = 'boolean';
EquipElems(3).SampleTime = -1;
EquipElems(3).Complexity = 'real';

LDC_Z = Simulink.Parameter;
LDC_Z.DataType = 'double';
LDC_Z.Value = double(RCReg2_1.LDC_Z); 

EquipElems(4) = Simulink.BusElement;
EquipElems(4).Name = 'LDC_Z';
EquipElems(4).Dimensions = 1;
EquipElems(4).DimensionsMode = 'Fixed';
EquipElems(4).DataType = 'double';
EquipElems(4).SampleTime = -1;
EquipElems(4).Complexity = 'real';

TapLimitPerChange = Simulink.Parameter;
TapLimitPerChange.DataType = 'uint8';
TapLimitPerChange.Value = uint8(RCReg2_1.TapLimitPerChange); 

EquipElems(5) = Simulink.BusElement;
EquipElems(5).Name = 'TapLimitPerChange';
EquipElems(5).Dimensions = 1;
EquipElems(5).DimensionsMode = 'Fixed';
EquipElems(5).DataType = 'uint8';
EquipElems(5).SampleTime = -1;
EquipElems(5).Complexity = 'real';

PTratio = Simulink.Parameter;
PTratio.DataType = 'double';
PTratio.Value = double(RCReg2_1.PTRatio); 

EquipElems(6) = Simulink.BusElement;
EquipElems(6).Name = 'PTratio';
EquipElems(6).Dimensions = 1;
EquipElems(6).DimensionsMode = 'Fixed';
EquipElems(6).DataType = 'double';
EquipElems(6).SampleTime = -1;
EquipElems(6).Complexity = 'real';

RevBand = Simulink.Parameter;
RevBand.DataType = 'double';
RevBand.Value = double(RCReg2_1.RevBandwidth); 

EquipElems(7) = Simulink.BusElement;
EquipElems(7).Name = 'RevBand';
EquipElems(7).Dimensions = 1;
EquipElems(7).DimensionsMode = 'Fixed';
EquipElems(7).DataType = 'double';
EquipElems(7).SampleTime = -1;
EquipElems(7).Complexity = 'real';

RevDelay = Simulink.Parameter;
RevDelay.DataType = 'double';
RevDelay.Value = double(RCReg2_1.RevDelay); 

EquipElems(8) = Simulink.BusElement;
EquipElems(8).Name = 'RevDelay';
EquipElems(8).Dimensions = 1;
EquipElems(8).DimensionsMode = 'Fixed';
EquipElems(8).DataType = 'double';
EquipElems(8).SampleTime = -1;
EquipElems(8).Complexity = 'real';

IsReversible = Simulink.Parameter;
IsReversible.DataType = 'boolean';
IsReversible.Value = boolean(RCReg2_1.IsReversible); 

EquipElems(9) = Simulink.BusElement;
EquipElems(9).Name = 'IsReversible';
EquipElems(9).Dimensions = 1;
EquipElems(9).DimensionsMode = 'Fixed';
EquipElems(9).DataType = 'boolean';
EquipElems(9).SampleTime = -1;
EquipElems(9).Complexity = 'real';

RevVreg = Simulink.Parameter;
RevVreg.DataType = 'double';
RevVreg.Value = double(RCReg2_1.RevVreg); 

EquipElems(10) = Simulink.BusElement;
EquipElems(10).Name = 'RevVreg';
EquipElems(10).Dimensions = 1;
EquipElems(10).DimensionsMode = 'Fixed';
EquipElems(10).DataType = 'double';
EquipElems(10).SampleTime = -1;
EquipElems(10).Complexity = 'real';

RevPowerThreshold = Simulink.Parameter;
RevPowerThreshold.DataType = 'double';
RevPowerThreshold.Value = double(RCReg2_1.RevPowerThreshold); 

EquipElems(11) = Simulink.BusElement;
EquipElems(11).Name = 'RevPowerThreshold';
EquipElems(11).Dimensions = 1;
EquipElems(11).DimensionsMode = 'Fixed';
EquipElems(11).DataType = 'double';
EquipElems(11).SampleTime = -1;
EquipElems(11).Complexity = 'real';

Vlimit = Simulink.Parameter;
Vlimit.DataType = 'double';
Vlimit.Value = double(RCReg2_1.Vlimit); 

EquipElems(12) = Simulink.BusElement;
EquipElems(12).Name = 'Vlimit';
EquipElems(12).Dimensions = 1;
EquipElems(12).DimensionsMode = 'Fixed';
EquipElems(12).DataType = 'double';
EquipElems(12).SampleTime = -1;
EquipElems(12).Complexity = 'real';

Vreg = Simulink.Parameter;
Vreg.DataType = 'double';
Vreg.Value = double(RCReg2_1.Vreg); 

EquipElems(13) = Simulink.BusElement;
EquipElems(13).Name = 'Vreg';
EquipElems(13).Dimensions = 1;
EquipElems(13).DimensionsMode = 'Fixed';
EquipElems(13).DataType = 'double';
EquipElems(13).SampleTime = -1;
EquipElems(13).Complexity = 'real';

TapDelay = Simulink.Parameter;
TapDelay.DataType = 'double';
TapDelay.Value = double(RCReg2_1.TapDelay); 

EquipElems(14) = Simulink.BusElement;
EquipElems(14).Name = 'TapDelay';
EquipElems(14).Dimensions = 1;
EquipElems(14).DimensionsMode = 'Fixed';
EquipElems(14).DataType = 'double';
EquipElems(14).SampleTime = -1;
EquipElems(14).Complexity = 'real';

TapWinding = Simulink.Parameter;
TapWinding.DataType = 'uint8';
TapWinding.Value = uint8(RCReg2_1.xsfWinding); 

EquipElems(15) = Simulink.BusElement;
EquipElems(15).Name = 'TapWinding';
EquipElems(15).Dimensions = 1;
EquipElems(15).DimensionsMode = 'Fixed';
EquipElems(15).DataType = 'uint8';
EquipElems(15).SampleTime = -1;
EquipElems(15).Complexity = 'real';

FPTphase = Simulink.Parameter;
FPTphase.DataType = 'uint8';
FPTphase.Value = uint8(RCReg2_1.fPTphase); 

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
MinTap.Value = double(TReg2_1.Winding(tw).MinTap); 

EquipElems(17) = Simulink.BusElement;
EquipElems(17).Name = 'MinTap';
EquipElems(17).Dimensions = 1;
EquipElems(17).DimensionsMode = 'Fixed';
EquipElems(17).DataType = 'double';
EquipElems(17).SampleTime = -1;
EquipElems(17).Complexity = 'real';

MaxTap = Simulink.Parameter;
MaxTap.DataType = 'double';
MaxTap.Value = double(TReg2_1.Winding(tw).MaxTap); 

EquipElems(18) = Simulink.BusElement;
EquipElems(18).Name = 'MaxTap';
EquipElems(18).Dimensions = 1;
EquipElems(18).DimensionsMode = 'Fixed';
EquipElems(18).DataType = 'double';
EquipElems(18).SampleTime = -1;
EquipElems(18).Complexity = 'real';

TapIncrement = Simulink.Parameter;
TapIncrement.DataType = 'double';
TapIncrement.Value = double(TReg2_1.Winding(tw).TapIncrement);

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
    uint8(TReg2_1.Winding(tw).Connection); 

EquipElems(20) = Simulink.BusElement;
EquipElems(20).Name = 'ControlledTransformerConnection';
EquipElems(20).Dimensions = 1;
EquipElems(20).DimensionsMode = 'Fixed';
EquipElems(20).DataType = 'uint8';
EquipElems(20).SampleTime = -1;
EquipElems(20).Complexity = 'real';

BaseVoltage = Simulink.Parameter;
BaseVoltage.DataType = 'double';
BaseVoltage.Value = double(TReg2_1.Winding(tw).Vbase); 

EquipElems(21) = Simulink.BusElement;
EquipElems(21).Name = 'BaseVoltage';
EquipElems(21).Dimensions = 1;
EquipElems(21).DimensionsMode = 'Fixed';
EquipElems(21).DataType = 'double';
EquipElems(21).SampleTime = -1;
EquipElems(21).Complexity = 'real';

% PresentTap = Simulink.Parameter;
% PresentTap.DataType = 'double';
% PresentTap.Value = double(TReg1.Winding(tw).puTap); 

EquipElems(22) = Simulink.BusElement; % unused, replaced with PresentTap as previous state
EquipElems(22).Name = 'PresentTap';
EquipElems(22).Dimensions = 1;
EquipElems(22).DimensionsMode = 'Fixed';
EquipElems(22).DataType = 'double';
EquipElems(22).SampleTime = -1;
EquipElems(22).Complexity = 'real';

NumConductors = Simulink.Parameter;
NumConductors.DataType = 'uint8';
NumConductors.Value = uint8(TReg2_1.fNconds);

EquipElems(23) = Simulink.BusElement;
EquipElems(23).Name = 'NumConductors';
EquipElems(23).Dimensions = 1;
EquipElems(23).DimensionsMode = 'Fixed';
EquipElems(23).DataType = 'uint8';
EquipElems(23).SampleTime = -1;
EquipElems(23).Complexity = 'real';

CTRating = Simulink.Parameter;
CTRating.DataType = 'double';
CTRating.Value = double(RCReg2_1.CTRating);

EquipElems(24) = Simulink.BusElement;
EquipElems(24).Name = 'CTRating';
EquipElems(24).Dimensions = 1;
EquipElems(24).DimensionsMode = 'Fixed';
EquipElems(24).DataType = 'double';
EquipElems(24).SampleTime = -1;
EquipElems(24).Complexity = 'real';

NumPhases = Simulink.Parameter;
NumPhases.DataType = 'uint8';
NumPhases.Value = uint8(TReg2_1.fNphases);

EquipElems(25) = Simulink.BusElement;
EquipElems(25).Name = 'NumPhases';
EquipElems(25).Dimensions = 1;
EquipElems(25).DimensionsMode = 'Fixed';
EquipElems(25).DataType = 'uint8';
EquipElems(25).SampleTime = -1;
EquipElems(25).Complexity = 'real';

IsInverseTime = Simulink.Parameter;
IsInverseTime.DataType = 'boolean';
IsInverseTime.Value = boolean(RCReg2_1.fInverseTime);

EquipElems(26) = Simulink.BusElement;
EquipElems(26).Name = 'IsInverseTime';
EquipElems(26).Dimensions = 1;
EquipElems(26).DimensionsMode = 'Fixed';
EquipElems(26).DataType = 'boolean';
EquipElems(26).SampleTime = -1;
EquipElems(26).Complexity = 'real';

R = Simulink.Parameter;
R.DataType = 'double';
R.Value = double(RCReg2_1.R);

EquipElems(27) = Simulink.BusElement;
EquipElems(27).Name = 'R';
EquipElems(27).Dimensions = 1;
EquipElems(27).DimensionsMode = 'Fixed';
EquipElems(27).DataType = 'double';
EquipElems(27).SampleTime = -1;
EquipElems(27).Complexity = 'real';

X = Simulink.Parameter;
X.DataType = 'double';
X.Value = double(RCReg2_1.X);

EquipElems(28) = Simulink.BusElement;
EquipElems(28).Name = 'X';
EquipElems(28).Dimensions = 1;
EquipElems(28).DimensionsMode = 'Fixed';
EquipElems(28).DataType = 'double';
EquipElems(28).SampleTime = -1;
EquipElems(28).Complexity = 'real';

revR = Simulink.Parameter;
revR.DataType = 'double';
revR.Value = double(RCReg2_1.revR);

EquipElems(29) = Simulink.BusElement;
EquipElems(29).Name = 'revR';
EquipElems(29).Dimensions = 1;
EquipElems(29).DimensionsMode = 'Fixed';
EquipElems(29).DataType = 'double';
EquipElems(29).SampleTime = -1;
EquipElems(29).Complexity = 'real';

revX = Simulink.Parameter;
revX.DataType = 'double';
revX.Value = double(RCReg2_1.revX);

EquipElems(30) = Simulink.BusElement;
EquipElems(30).Name = 'revX';
EquipElems(30).Dimensions = 1;
EquipElems(30).DimensionsMode = 'Fixed';
EquipElems(30).DataType = 'double';
EquipElems(30).SampleTime = -1;
EquipElems(30).Complexity = 'real';

revLDC_Z = Simulink.Parameter;
revLDC_Z.DataType = 'double';
revLDC_Z.Value = double(RCReg2_1.revLDC_Z);

EquipElems(31) = Simulink.BusElement;
EquipElems(31).Name = 'revLDC_Z';
EquipElems(31).Dimensions = 1;
EquipElems(31).DimensionsMode = 'Fixed';
EquipElems(31).DataType = 'double';
EquipElems(31).SampleTime = -1;
EquipElems(31).Complexity = 'real';

TimeDelay = Simulink.Parameter;
TimeDelay.DataType = 'double';
TimeDelay.Value = double(RCReg2_1.TimeDelay);

EquipElems(32) = Simulink.BusElement;
EquipElems(32).Name = 'TimeDelay';
EquipElems(32).Dimensions = 1;
EquipElems(32).DimensionsMode = 'Fixed';
EquipElems(32).DataType = 'double';
EquipElems(32).SampleTime = -1;
EquipElems(32).Complexity = 'real';

DeltaDirection = Simulink.Parameter;
DeltaDirection.DataType = 'uint8';
DeltaDirection.Value = uint8(TReg2_1.DeltaDirection);

EquipElems(33) = Simulink.BusElement;
EquipElems(33).Name = 'DeltaDirection';
EquipElems(33).Dimensions = 1;
EquipElems(33).DimensionsMode = 'Fixed';
EquipElems(33).DataType = 'uint8';
EquipElems(33).SampleTime = -1;
EquipElems(33).Complexity = 'real';

ElementTerminal = Simulink.Parameter;
ElementTerminal.DataType = 'uint8';
ElementTerminal.Value = uint8(RCReg2_1.ElementTerminal);

EquipElems(34) = Simulink.BusElement;
EquipElems(34).Name = 'ElementTerminal';
EquipElems(34).Dimensions = 1;
EquipElems(34).DimensionsMode = 'Fixed';
EquipElems(34).DataType = 'uint8';
EquipElems(34).SampleTime = -1;
EquipElems(34).Complexity = 'real';

EquipmentBus = Simulink.Bus;
EquipmentBus.Elements = EquipElems;

% ongoing system states:

ReversePending = Simulink.Parameter;
ReversePending.DataType = 'boolean';
ReversePending.Value = false(3,1);

InCogenMode = Simulink.Parameter;
InCogenMode.DataType = 'boolean';
InCogenMode.Value = false(3,1);

InReverseMode = Simulink.Parameter;
InReverseMode.DataType = 'boolean';
InReverseMode.Value = false(3,1);

LookingForward = Simulink.Parameter;
LookingForward.DataType = 'boolean';
LookingForward.Value = false(3,1);

Armed = Simulink.Parameter;
Armed.DataType = 'boolean';
Armed.Value = false(3,1);

RevHandle = Simulink.Parameter;
RevHandle.DataType = 'uint8';
RevHandle.Value = zeros(3,1);

RevBackHandle = Simulink.Parameter;
RevBackHandle.DataType = 'uint8';
RevBackHandle.Value = zeros(3,1);

PresentTap = Simulink.Parameter;
PresentTap.DataType = 'double';
PresentTap.Value = [double(TReg2_1.Winding(tw).puTap);
    double(TReg2_2.Winding(tw).puTap);
    double(TReg2_3.Winding(tw).puTap)];

% Bus:

StatesElems(1) = Simulink.BusElement;
StatesElems(1).Name = 'ReversePending';
StatesElems(1).Dimensions = 1;
StatesElems(1).DimensionsMode = 'Fixed';
StatesElems(1).DataType = 'boolean';
StatesElems(1).SampleTime = -1;
StatesElems(1).Complexity = 'real';

StatesElems(2) = Simulink.BusElement;
StatesElems(2).Name = 'InCogenMode';
StatesElems(2).Dimensions = 1;
StatesElems(2).DimensionsMode = 'Fixed';
StatesElems(2).DataType = 'boolean';
StatesElems(2).SampleTime = -1;
StatesElems(2).Complexity = 'real';

StatesElems(3) = Simulink.BusElement;
StatesElems(3).Name = 'InReverseMode';
StatesElems(3).Dimensions = 1;
StatesElems(3).DimensionsMode = 'Fixed';
StatesElems(3).DataType = 'boolean';
StatesElems(3).SampleTime = -1;
StatesElems(3).Complexity = 'real';

StatesElems(4) = Simulink.BusElement;
StatesElems(4).Name = 'LookingForward';
StatesElems(4).Dimensions = 1;
StatesElems(4).DimensionsMode = 'Fixed';
StatesElems(4).DataType = 'boolean';
StatesElems(4).SampleTime = -1;
StatesElems(4).Complexity = 'real';

StatesElems(5) = Simulink.BusElement;
StatesElems(5).Name = 'Armed';
StatesElems(5).Dimensions = 1;
StatesElems(5).DimensionsMode = 'Fixed';
StatesElems(5).DataType = 'boolean';
StatesElems(5).SampleTime = -1;
StatesElems(5).Complexity = 'real';

StatesElems(6) = Simulink.BusElement;
StatesElems(6).Name = 'RevHandle';
StatesElems(6).Dimensions = 1;
StatesElems(6).DimensionsMode = 'Fixed';
StatesElems(6).DataType = 'uint8';
StatesElems(6).SampleTime = -1;
StatesElems(6).Complexity = 'real';

StatesElems(7) = Simulink.BusElement;
StatesElems(7).Name = 'RevBackHandle';
StatesElems(7).Dimensions = 1;
StatesElems(7).DimensionsMode = 'Fixed';
StatesElems(7).DataType = 'uint8';
StatesElems(7).SampleTime = -1;
StatesElems(7).Complexity = 'real';

StatesElems(8) = Simulink.BusElement;
StatesElems(8).Name = 'PresentTap';
StatesElems(8).Dimensions = 1;
StatesElems(8).DimensionsMode = 'Fixed';
StatesElems(8).DataType = 'double';
StatesElems(8).SampleTime = -1;
StatesElems(8).Complexity = 'real';

StatesBus = Simulink.Bus;
StatesBus.Elements = StatesElems;

%% Build directed graphs representing state transition Markov chain:

% MakeTapChange Graph:
MakeTCsource = {'', '', '.GetVboostFromVlimit', ...
    '.QuantizeTapChange', '.QuantizeTapChange', '.QuantizeTapChange', ...
    '.TapChangeUp', '.TapChangeUp', '.TapChangeUp.Finished', ...
    '.TapChangeUp.PushChange', '.TapChangeDown', '.TapChangeDown', ...
    '.TapChangeDown.Finished', '.TapChangeDown.PushChange'};

MakeTCdest = {'.GetVboostFromVlimit', '.QuantizeTapChange', '.QuantizeTapChange', ...
    '.TapChangeUp', '.TapChangeDown', '.Finished', ...
    '.TapChangeUp.PushChange', '.TapChangeUp.Finished', '.Finished', ...
    '.TapChangeUp.Finished', '.TapChangeDown.PushChange', '.TapChangeDown.Finished', ...
    '.Finished', '.TapChangeDown.Finished'};

MakeTCblockpath = 'Sampling.MakeTapChange';

mtcg = MakeStatesDigraph(MakeTCsource, MakeTCdest, MakeTCblockpath);
MakeTCgraph = struct;

for phase = 1:3
    MakeTCgraph = setfield(MakeTCgraph, regWsNames{phase}, mtcg);
end

MakeTCentry = zeros(3,1);
MakeTCentries = zeros(3,1);

% Execution Graph:
ExecSource = {'.ParseAction', '.ParseAction', '.ParseAction', ...
    '.MakingTapChange', '.MakingTapChange', '.Reversing', ...
    '.Reversing', '.Reversing', '.MakingTapChange.NonzeroTapChange', ...
    '.MakingTapChange.Finished', '.Reversing.FlipCogen', '.Reversing.FlipReverse', ...
    '.Reversing.Finished'};

ExecDest = {'.MakingTapChange', '.Reversing', '.Finished', ...
    '.MakingTapChange.NonzeroTapChange', '.MakingTapChange.Finished', '.Reversing.FlipCogen', ...
    '.Reversing.FlipReverse', '.Reversing.Finished', '.MakingTapChange.Finished', ...
    '.Finished', '.Reversing.Finished', '.Reversing.Finished', ...
    '.Finished'};

ExecBlockpath = 'Execution';

execg = MakeStatesDigraph(ExecSource, ExecDest, ExecBlockpath);
ExecGraph = struct;

for phase = 1:3
    ExecGraph = setfield(ExecGraph, regWsNames{phase}, execg);
end

ExecEntry = zeros(3,1);
ExecEntries = zeros(3,1);

% LookingForwardMode Graph:
LookingFwdSource = {'.DetermineReversePending', '.DetermineReversePending', ...
    '.DetermineReversePending', '.DetermineReversePending.CorrectFalseReversePending', ...
    '.DetermineReversePending.CorrectFalseReversePending', '.DetermineReversePending.CorrectTrueReversePending', ...
    '.DetermineReversePending.CorrectTrueReversePending', '.DetermineReversePending.CorrectFalseReversePending.FlipToTrue', ...
    '.DetermineReversePending.CorrectFalseReversePending.Finished', '.DetermineReversePending.CorrectFalseReversePending.Finished', ...
    '.DetermineReversePending.CorrectTrueReversePending.FlipToFalse', '.DetermineReversePending.CorrectTrueReversePending.Finished'};

LookingFwdDest = {'.DetermineReversePending.CorrectFalseReversePending', '.DetermineReversePending.CorrectTrueReversePending', ...
    '.DetermineReversePending.Finished', '.DetermineReversePending.CorrectFalseReversePending.FlipToTrue', ...
    '.DetermineReversePending.CorrectFalseReversePending.Finished', '.DetermineReversePending.CorrectTrueReversePending.FlipToFalse', ...
    '.DetermineReversePending.CorrectTrueReversePending.Finished', '.DetermineReversePending.CorrectFalseReversePending.Finished', ...
    '.DetermineReversePending.CorrectTrueReversePending', '.DetermineReversePending.Finished', ...
    '.DetermineReversePending.CorrectTrueReversePending.Finished', '.DetermineReversePending.Finished'};

LookingFwdBlockpath = 'Sampling.LookingForwardMode';

lfwdg = MakeStatesDigraph(LookingFwdSource, LookingFwdDest, LookingFwdBlockpath);
LookingFwdGraph = struct;

for phase = 1:3
    LookingFwdGraph = setfield(LookingFwdGraph, regWsNames{phase}, lfwdg);
end

LookingFwdEntry = zeros(3,1);
LookingFwdEntries = zeros(3,1);

% LookingReverseOrCogenMode.DetermineReversePending Graph:
LookingRevDRPsource = {'', '', ...
    '', '.CorrectFalseReversePending', ...    
    '.CorrectFalseReversePending', '.CorrectTrueReversePending', ...
    '.CorrectTrueReversePending', '.CorrectFalseReversePending.FlipToTrue', ...    
    '.CorrectFalseReversePending.Finished', '.CorrectTrueReversePending.FlipToFalse', ...
    '.CorrectTrueReversePending.Finished'};

LookingRevDRPdest = {'.CorrectFalseReversePending', '.CorrectTrueReversePending', ...
    '.Finished', '.CorrectFalseReversePending.FlipToTrue', ...    
    '.CorrectFalseReversePending.Finished', '.CorrectTrueReversePending.FlipToFalse', ...
    '.CorrectTrueReversePending.Finished', '.CorrectFalseReversePending.Finished', ...    
    '.Finished', '.CorrectTrueReversePending.Finished', ...
    '.Finished'};

LookingRevDRPblockpath = 'Sampling.LookingReverseOrCogenMode.DetermineReversePending';

drpg = MakeStatesDigraph(LookingRevDRPsource, LookingRevDRPdest, LookingRevDRPblockpath);
LookingRevDRPgraph = struct;

for phase = 1:3
    LookingRevDRPgraph = setfield(LookingRevDRPgraph, regWsNames{phase}, drpg);
end

LookingRevDRPentry = zeros(3,1);
LookingRevDRPentries = zeros(3,1);

% LookingReverseOrCogenMode.ReverseNeutralCase Graph:

LookingRevRNCsource = {'', '', ...
    '.QuantizeTapChange', '.QuantizeTapChange', ...
    '.MakeTapChange'};  

LookingRevRNCdest = {'.QuantizeTapChange', '.Finished', ...
    '.MakeTapChange', '.Exiting', ...
    '.Exiting'};

LookingRevRNCblockpath = 'Sampling.LookingReverseOrCogenMode.ReverseNeutralCase';

rncg = MakeStatesDigraph(LookingRevRNCsource, LookingRevRNCdest, LookingRevRNCblockpath);
LookingRevRNCgraph = struct;

for phase = 1:3
    LookingRevRNCgraph = setfield(LookingRevRNCgraph, regWsNames{phase}, rncg);
end

LookingRevRNCentry = zeros(3,1);
LookingRevRNCentries = zeros(3,1);

% Queue Handler Executive Graph:
QHexecSource = {'Asleep', 'Asleep', 'Asleep', ...
    'DoNearestActions', 'DoNearestActions', 'DeletingByHandle', ...
    'Pushing', 'DoNearestActions.WaitOnPeek', 'DoNearestActions.WaitOnPeek', ...
    'DoNearestActions.ErrorNoItems', 'ReadyAgain', 'DoNearestActions.WaitOnPop', ...
    'DoNearestActions.WaitOnPop', 'DoNearestActions.WaitOnPop', 'DoNearestActions.Finished', ...
    'DoNearestActions.SendAction', 'DoNearestActions.SendAction'};

QHexecDest = {'DoNearestActions', 'Pushing', 'DeletingByHandle', ...
    'DoNearestActions.WaitOnPeek', 'DoNearestActions.ErrorNoItems', 'ReadyAgain', ...
    'ReadyAgain', 'DoNearestActions.WaitOnPop', 'DoNearestActions.Finished', ...
    'DoNearestActions.Finished', 'Asleep', 'DoNearestActions.SendAction', ...
    'DoNearestActions.WaitOnPop', 'DoNearestActions.Finished', 'ReadyAgain', ...
    'DoNearestActions.WaitOnPop', 'DoNearestActions.Finished'};

QHexecBlockpath = 'Executive.';

QHexecGraph = MakeStatesDigraph(QHexecSource, QHexecDest, QHexecBlockpath);

QHexecEntry = 0;
QHexecEntries = 0;

%% Snapshot approximating Daily Simulation:

DSSText.Command = 'set mode=snapshot controlmode=static';

DSSSolution.MaxControlIterations=30;

% time-keeping:
N = 96;
TimeInVals = (24/N)*3600*( (1:N) - 1 ); % for the purpose of starting at zero
HourInVals = floor(TimeInVals/3600);
SecInVals = TimeInVals - 3600*HourInVals;

TimeOutVals = (24/N)*3600*(1:N); % starts at 0:900
HourOutVals = floor(TimeOutVals/3600);
SecOutVals = TimeOutVals - 3600*HourOutVals;

% signal logging:

simOut = repmat(Simulink.SimulationOutput, N, 1);
LastQueue.Value = zeros(1,6,50);
% LastHandle.Value = 1;

QueueTimeLapse = zeros(1,6,50,N);
ExecutedTimeLapse = zeros(1,6,N); % last executed item, updated on each iteration
HandleTimeLapse = zeros(N,1);

tapPos = zeros(N, length(regNames));
VoltagesInOut = zeros(3,2,N); % 3 phases, 2 terminals, N samples
CurrentsInOut = zeros(3,2,N);

RealPowerInOut = zeros(3,2,N);
ReactPowerInOut = zeros(3,2,N);

EventLog = struct( 'Hour', {}, 'Sec', {}, 'ControlIter', {}, 'Action', {}, ...
    'Position', {}, 'TapChange', {}, 'Device', {});

% Add loadshape:
% LoadShapeYear = csvread('LoadShape1.csv');
LoadShapeYear = normalize( csvread('LoadShape1.csv'), 'range', [0,1] );
% interpolating 24 hours into 96 x 15min periods;
% in interpolation, index=1 becomes hour=0:
LoadShapeDaily = interp1(1:25,LoadShapeYear(1:25),(1+24/N):(24/N):25);

% size of connected load is kW=1155 kvar=660

kWRated = 600;
kWhRated = 1*kWRated;
kWhStored = 1*kWRated;

% add storage element:
DSSText.Command = sprintf('New Storage.N98 Bus1=675.1.2.3 kV=2.4 kWRated=%d kWhRated=%d kWhStored=%d', ...
    kWRated, kWhRated, kWhStored);
DSSText.Command = 'Storage.n98.state=Dischar'; % %discharge=25';

N = 12;

for nn = 1:N
    tic;
    
    DSSSolution.LoadMult = LoadShapeDaily(nn); % new loadshape per iteration
    
    DSSSolution.Hour = HourInVals(nn); % controlling clock
    DSSSolution.Seconds = SecInVals(nn);
    
    DSSSolution.InitSnap;

    CtrlIter = 0;

    while CtrlIter < DSSSolution.MaxControlIterations
        DSSSolution.SolveNoControl;
        
        % 2 - Package DSS measurements for Simulink:
        xf_trans = DSSCircuit.Transformers;
        for phase = 1:3
            DSSCircuit.SetActiveElement(char( strcat('Transformer.', xsfNames{phase}) ));
            xf_ckt = DSSCircuit.ActiveCktElement;
            
            ControlledTransformerVoltages.Value(:,phase) = MakeComplex(xf_ckt.Voltages); 
            % [in ... | out ...]' (complex)

            ControlledTransformerCurrents.Value(:,phase) = MakeComplex(xf_ckt.Currents); 
            % [in ... | out ...]' (complex)

            ControlledTransformerPowers.Value(:,phase) = MakeComplex(xf_ckt.Powers); 
            % [in ... | out ...]' (complex)

            % this would come from a separate tranformer if UsingRegulatedBus:
            VTerminal.Value(:,phase) = MakeComplex(xf_ckt.Voltages);
            % [in ... | out ...]' (complex)
            
            xf_trans.Name = xsfNames{phase};            
            PresentTap.Value(phase) = double(xf_trans.Tap); 
            % foregoing storage in TReg.Winding(tw).puTap
        end        

        % 3 - configure simulation parameters with prior timestep's results:    
        TimeInSec.Value = TimeInVals(nn);
        
        LastQueueToLog = [];
    
        if nn > 1 % there exists an output from a prior iteration
            for phase = 1:3
                % select bus source of TimeSeries data:
                switch phase
                    case 1
                        tempOut = simOut(nn-1).Curr1;
                    case 2
                        tempOut = simOut(nn-1).Curr2;
                    case 3
                        tempOut = simOut(nn-1).Curr3;
                end
                
                ReversePending.Value(phase) = tempOut.ReversePending.Data;
                InCogenMode.Value(phase) = tempOut.InCogenMode.Data;
                InReverseMode.Value(phase) = tempOut.InReverseMode.Data;
                LookingForward.Value(phase) = tempOut.LookingForward.Data;
                Armed.Value(phase) = tempOut.Armed.Data;       
%                 Handle.Value(phase) = tempOut.Handle.Data;
                RevHandle.Value(phase) = tempOut.RevHandle.Data;
                RevBackHandle.Value(phase) = tempOut.RevBackHandle.Data;
%                 PresentTap.Value(phase) = tempOut.PresentTap.Data;            
            end
            
            TempHandle = simOut(nn-1).currHandle.Data;
            if TempHandle ~= 0
                LastHandle.Value = TempHandle;
            end

            CurrQueueSize = simOut(nn-1).QueueSize.Data;
            TempLastQueue = zeros(1,6,50);
            LastQueueToLog = [];
            if CurrQueueSize > 0
                LastQueueToLog = ...
                    simOut(nn-1).CurrQueue.signals.values(:,:,1:CurrQueueSize,end);
                TempLastQueue(:,:,1:CurrQueueSize) = LastQueueToLog;
            end
            LastQueue.Value = TempLastQueue;

            HandleTimeLapse( nn-1 ) = LastHandle.Value;
            QueueTimeLapse( :,:,:,(nn-1) ) = LastQueue.Value;
            ExecutedTimeLapse( :,:,(nn-1) ) = ...
                simOut(nn-1).FromQueue.signals.values(:,:,end); % based on latest addition to the Queue
        end
        
        % 4 - obtain control actions from Simulink:    
        simOut(nn) = sim('regcontrol_model_3ph', 'TimeOut', 1000);

        % 5 - execute tap changes in DSS:
        TapChangesMade = [simOut(nn).TapChangeToMake1.Data;
            simOut(nn).TapChangeToMake2.Data;
            simOut(nn).TapChangeToMake3.Data];
        
        xf_trans.Name = xsfNames{1};
        xf_trans.Tap = xf_trans.Tap + TapChangesMade(1);
        xf_trans.Name = xsfNames{2};
        xf_trans.Tap = xf_trans.Tap + TapChangesMade(2);
        xf_trans.Name = xsfNames{3};
        xf_trans.Tap = xf_trans.Tap + TapChangesMade(3);
        
        DSSSolution.Solve;
        
        % display the result
        disp(['Result='  DSSText.Result])

        if DSSSolution.Converged 
           a = ['Solution Converged in ' num2str(DSSSolution.Iterations) ' iterations.'];
        else
           a = 'Solution did not Converge';
        end
        disp(a)    
        
        Logged = LogEvent_3ph( nn, HourOutVals(nn), SecOutVals(nn), ...
            simOut(nn).ToQueue.signals.values, LastQueueToLog, ...
            simOut(nn).FromQueue.signals.values, TapChangesMade, ...
            tapPos, regNames, repmat(TapIncrement.Value, 3, 1), CtrlIter);
        
        if CtrlIter == 0
              EventLog(nn) = Logged;
        else % if subsequent action does nothing, do not replace original:
            if ~contains(Logged.Action, 'None')
               EventLog(nn) = Logged;
            end
        end
        
        TimeElapsed = toc;    
        fprintf('Iteration %d, Time = %g\n', nn, TimeElapsed);

        if simOut(nn).ControlActionsDone.Data && DSSSolution.ControlActionsDone, break, end 

        CtrlIter = CtrlIter + 1;
    end
    
    % Update QueueHandler Executive graph:
    loclog = find(simOut(nn).logsout, '-regexp', 'BlockPath', ...
            sprintf('\\w*%s\\w*', 'Queue Handler'));
        
    [QHexecGraph, QHexecEntry] = UpdateEdgeWeightsMult( QHexecGraph, ...
            QHexecGraph.Nodes.Name{1}, loclog, 1 );
        
    QHexecEntries = QHexecEntries + QHexecEntry;
        
    for phase = 1:3
        % update plot data on all tap positions:
        xf_trans.Name = xsfNames{phase};
        DSSCircuit.SetActiveElement(char( strcat('Transformer.', xsfNames{phase}) ));
        xf_ckt = DSSCircuit.ActiveCktElement;
        tapPos(nn, phase) = xf_trans.Tap;
        
        tempVolts = abs(MakeComplex(xf_ckt.Voltages));
        tempCurr = abs(MakeComplex(xf_ckt.Currents)); 
        tempP = real(MakeComplex(xf_ckt.Powers)); 
        tempQ = imag(MakeComplex(xf_ckt.Powers));
        
        VoltagesInOut(phase,1,nn) = tempVolts(1);
        VoltagesInOut(phase,2,nn) = tempVolts(3);
        CurrentsInOut(phase,1,nn) = tempCurr(1);
        CurrentsInOut(phase,2,nn) = tempCurr(3);
        
        RealPowerInOut(phase,1,nn) = tempP(1);
        RealPowerInOut(phase,2,nn) = tempP(3);
        ReactPowerInOut(phase,1,nn) = tempQ(1);
        ReactPowerInOut(phase,2,nn) = tempQ(3);
        
        % Update graphs:
        loclog = find(simOut(nn).logsout, '-regexp', 'BlockPath', ...
            sprintf('\\w*%s\\w*', regWsNames{phase}));

        temp_g = getfield(MakeTCgraph, regWsNames{phase});
        [temp_g, MakeTCentry(phase)] = UpdateEdgeWeights( temp_g, ...
            temp_g.Nodes.Name{1}, loclog, 1 );
        MakeTCgraph = setfield(MakeTCgraph, regWsNames{phase}, temp_g);
        
        temp_g = getfield(ExecGraph, regWsNames{phase});
        [temp_g, ExecEntry(phase)] = UpdateEdgeWeights( temp_g, ...
            temp_g.Nodes.Name{1}, loclog, 1 );
        ExecGraph = setfield(ExecGraph, regWsNames{phase}, temp_g);
        
        temp_g = getfield(LookingFwdGraph, regWsNames{phase});
        [temp_g, LookingFwdEntry(phase)] = UpdateEdgeWeights( temp_g, ...
            temp_g.Nodes.Name{1}, loclog, 1 );
        LookingFwdGraph = setfield(LookingFwdGraph, regWsNames{phase}, temp_g);
        
        temp_g = getfield(LookingRevDRPgraph, regWsNames{phase});
        [temp_g, LookingRevDRPentry(phase)] = UpdateEdgeWeights( temp_g, ...
            temp_g.Nodes.Name{1}, loclog, 1 );
        LookingRevDRPgraph = setfield(LookingRevDRPgraph, regWsNames{phase}, temp_g);
        
        temp_g = getfield(LookingRevRNCgraph, regWsNames{phase});
        [temp_g, LookingRevRNCentry(phase)] = UpdateEdgeWeights( temp_g, ...
            temp_g.Nodes.Name{1}, loclog, 1 );
        LookingRevRNCgraph = setfield(LookingRevRNCgraph, regWsNames{phase}, temp_g);

        % increment frequency of entries:
        MakeTCentries(phase)       =   MakeTCentries(phase) + MakeTCentry(phase);
        ExecEntries(phase)         =   ExecEntries(phase) + ExecEntry(phase);
        LookingFwdEntries(phase)   =   LookingFwdEntries(phase) + LookingFwdEntry(phase);
        LookingRevDRPentries(phase)   =   LookingRevDRPentries(phase) + LookingRevDRPentry(phase);
        LookingRevRNCentries(phase)   =   LookingRevRNCentries(phase) + LookingRevRNCentry(phase);
    end
end

%% Plots 

Time = TimeOutVals/3600; % converts cumulative seconds to hours

figure(1);
plot(Time(1:N), tapPos(1:N,1),'-k+');  % black *
hold on
plot(Time(1:N), tapPos(1:N,2),'-r+');
plot(Time(1:N), tapPos(1:N,3),'-b+');
title('Transformer Taps (Stateflow RegControl Emulation, All Phases)');
ylabel('Tap Position');
xlabel('Hour');
hold off

Vin = VoltagesInOut(:,1,:);
figure(2);
subplot(2,1,1);
plot(Time(1:N), Vin(1,1:N),'-k+');  % black *
hold on
plot(Time(1:N), Vin(2,1:N),'-r+');
plot(Time(1:N), Vin(3,1:N),'-b+');
title('Voltages on Input Terminal (Stateflow RegControl Emulation, All Phases)');
ylabel('Voltage');
xlabel('Hour');
hold off

Vout = VoltagesInOut(:,2,:);
subplot(2,1,2);
plot(Time(1:N), Vout(1,1:N),'-k+');  % black *
hold on
plot(Time(1:N), Vout(2,1:N),'-r+');
plot(Time(1:N), Vout(3,1:N),'-b+');
title('Voltages on Output Terminal (Stateflow RegControl Emulation, All Phases)');
ylabel('Voltage');
xlabel('Hour');
hold off

Cin = CurrentsInOut(:,1,:);
figure(3);
subplot(2,1,1);
plot(Time(1:N), Cin(1,1:N),'-k+');  % black *
hold on
plot(Time(1:N), Cin(2,1:N),'-r+');
plot(Time(1:N), Cin(3,1:N),'-b+');
title('Currents on Input Terminal (Stateflow RegControl Emulation, All Phases)');
ylabel('Voltage');
xlabel('Hour');
hold off

Cout = CurrentsInOut(:,2,:);
subplot(2,1,2);
plot(Time(1:N), Cout(1,1:N),'-k+');  % black *
hold on
plot(Time(1:N), Cout(2,1:N),'-r+');
plot(Time(1:N), Cout(3,1:N),'-b+');
title('Currents on Output Terminal (Stateflow RegControl Emulation, All Phases)');
ylabel('Voltage');
xlabel('Hour');
hold off

Pin = RealPowerInOut(:,1,:);
Qin = ReactPowerInOut(:,1,:);
figure(10);
subplot(2,1,1);
plot(Time(1:N), Pin(1,1:N),'-k+');  % black *
hold on
plot(Time(1:N), Qin(1,1:N),'-k');
plot(Time(1:N), Pin(2,1:N),'-r+');
plot(Time(1:N), Qin(2,1:N),'-r');
plot(Time(1:N), Pin(3,1:N),'-b+');
plot(Time(1:N), Qin(3,1:N),'-b');
title('Daily Simulation: Real and Reactive Powers on Input Terminal');
ylabel('Power [kW or kVAR]');
xlabel('Hour');
hold off

Pout = RealPowerInOut(:,2,:);
Qout = ReactPowerInOut(:,2,:);
figure(10);
subplot(2,1,2);
plot(Time(1:N), Pout(1,1:N),'-k+');  % black *
hold on
plot(Time(1:N), Qout(1,1:N),'-k');
plot(Time(1:N), Pout(2,1:N),'-r+');
plot(Time(1:N), Qout(2,1:N),'-r');
plot(Time(1:N), Pout(3,1:N),'-b+');
plot(Time(1:N), Qout(3,1:N),'-b');
title('Daily Simulation: Real and Reactive Powers on Output Terminal');
ylabel('Power [kW or kVAR]');
xlabel('Hour');
hold off

for phase = 1:3
    figure(4);
    subplot(1,3,phase);
    
    mtcg = MakeDigraphProb( getfield(MakeTCgraph, regWsNames{phase}) );
    PlotNormalized(mtcg, MakeTCblockpath, MakeTCentries(phase), N);

    figure(5);
    subplot(1,3,phase);
    
    execg = MakeDigraphProb( getfield(ExecGraph, regWsNames{phase}) );
    PlotNormalized(execg, ExecBlockpath, ExecEntries(phase), N);

    figure(6);
    subplot(1,3,phase);
    
    lfwdg = MakeDigraphProb( getfield(LookingFwdGraph, regWsNames{phase}) );
    PlotNormalized(lfwdg, LookingFwdBlockpath, LookingFwdEntries(phase), N);
          
    figure(7);
    subplot(1,3,phase);
    
    drpg = MakeDigraphProb( getfield(LookingRevDRPgraph, regWsNames{phase}) );
    PlotNormalized(drpg, LookingRevDRPblockpath, LookingRevDRPentries(phase), N);
    
    figure(8);
    subplot(1,3,phase);
    
    rncg = MakeDigraphProb( getfield(LookingRevRNCgraph, regWsNames{phase}) );
    PlotNormalized(rncg, LookingRevRNCblockpath, LookingRevRNCentries(phase), N);
end

figure(9);
PlotNormalized(QHexecGraph, QHexecBlockpath, QHexecEntries, N);

DSSText.Command = 'Show Powers kva Elements';
% DSSText.Command = 'Show Voltages LN Nodes';
% DSSText.Command = 'Show Currents Elem';
% DSSText.Command = 'Show Powers kVA Elem';
% DSSText.Command = 'Show Losses';
% DSSText.Command = 'Show Taps';

struct2table(EventLog)

loclog = find(simOut(nn).logsout, '-regexp', 'BlockPath', ...
            sprintf('\\w*%s\\w*', regWsNames{2}));

ProbOfSequence(getfield(ExecGraph, regWsNames{2}), ExecEntries(2)/N, loclog)