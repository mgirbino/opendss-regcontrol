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

DSSText.command = TReg1.DSSCommand;
DSSText.command = TReg2.DSSCommand;
DSSText.command = TReg3.DSSCommand;

xsfNames = {TReg1.getName; TReg2.getName; TReg3.getName};
regNames = {RCReg1.getName; RCReg2.getName; RCReg3.getName};
xsfIncr = [TReg1.Winding(RCReg1.xsfWinding).TapIncrement;
    TReg2.Winding(RCReg2.xsfWinding).TapIncrement;
    TReg3.Winding(RCReg3.xsfWinding).TapIncrement];

%% Data packaging for Simulink:

% LastHandle = Simulink.Parameter;
% LastHandle.DataType = 'double';

TimeInSec = Simulink.Parameter;
TimeInSec.DataType = 'double';

LastQueue = Simulink.Parameter;
LastQueue.DataType = 'double';

% Phase 1:
ControlledTransformerVoltages1 = Simulink.Parameter;
ControlledTransformerVoltages1.DataType = 'double';

ControlledTransformerCurrents1 = Simulink.Parameter;
ControlledTransformerCurrents1.DataType = 'double';

ControlledTransformerPowers1 = Simulink.Parameter;
ControlledTransformerPowers1.DataType = 'double';

VTerminal1 = Simulink.Parameter;
VTerminal1.DataType = 'double';

% Phase 2:
ControlledTransformerVoltages2 = Simulink.Parameter;
ControlledTransformerVoltages2.DataType = 'double';

ControlledTransformerCurrents2 = Simulink.Parameter;
ControlledTransformerCurrents2.DataType = 'double';

ControlledTransformerPowers2 = Simulink.Parameter;
ControlledTransformerPowers2.DataType = 'double';

VTerminal2 = Simulink.Parameter;
VTerminal2.DataType = 'double';

% Phase 3:
ControlledTransformerVoltages3 = Simulink.Parameter;
ControlledTransformerVoltages3.DataType = 'double';

ControlledTransformerCurrents3 = Simulink.Parameter;
ControlledTransformerCurrents3.DataType = 'double';

ControlledTransformerPowers3 = Simulink.Parameter;
ControlledTransformerPowers3.DataType = 'double';

VTerminal3 = Simulink.Parameter;
VTerminal3.DataType = 'double';

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
RevBand.Value = double(RCReg1.RevBandwidth); 

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

EquipElems(22) = Simulink.BusElement; % unused, replaced with PresentTap as previous state
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

DeltaDirection = Simulink.Parameter;
DeltaDirection.DataType = 'uint8';
DeltaDirection.Value = uint8(TReg1.DeltaDirection);

EquipElems(33) = Simulink.BusElement;
EquipElems(33).Name = 'DeltaDirection';
EquipElems(33).Dimensions = 1;
EquipElems(33).DimensionsMode = 'Fixed';
EquipElems(33).DataType = 'uint8';
EquipElems(33).SampleTime = -1;
EquipElems(33).Complexity = 'real';

ElementTerminal = Simulink.Parameter;
ElementTerminal.DataType = 'uint8';
ElementTerminal.Value = uint8(RCReg1.ElementTerminal);

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
% Phase 1:

ReversePending1 = Simulink.Parameter;
ReversePending1.DataType = 'boolean';
ReversePending1.Value = false;

InCogenMode1 = Simulink.Parameter;
InCogenMode1.DataType = 'boolean';
InCogenMode1.Value = false;

InReverseMode1 = Simulink.Parameter;
InReverseMode1.DataType = 'boolean';
InReverseMode1.Value = false;

LookingForward1 = Simulink.Parameter;
LookingForward1.DataType = 'boolean';
LookingForward1.Value = false;

Armed1 = Simulink.Parameter;
Armed1.DataType = 'boolean';
Armed1.Value = false;

Handle1 = Simulink.Parameter;
Handle1.DataType = 'uint8';
Handle1.Value = 0;

RevHandle1 = Simulink.Parameter;
RevHandle1.DataType = 'uint8';
RevHandle1.Value = 0;

RevBackHandle1 = Simulink.Parameter;
RevBackHandle1.DataType = 'uint8';
RevBackHandle1.Value = 0;

PresentTap1 = Simulink.Parameter;
PresentTap1.DataType = 'double';
PresentTap1.Value = double(TReg1.Winding(tw).puTap); % specific to transformer

% Phase2:

ReversePending2 = Simulink.Parameter;
ReversePending2.DataType = 'boolean';
ReversePending2.Value = false;

InCogenMode2 = Simulink.Parameter;
InCogenMode2.DataType = 'boolean';
InCogenMode2.Value = false;

InReverseMode2 = Simulink.Parameter;
InReverseMode2.DataType = 'boolean';
InReverseMode2.Value = false;

LookingForward2 = Simulink.Parameter;
LookingForward2.DataType = 'boolean';
LookingForward2.Value = false;

Armed2 = Simulink.Parameter;
Armed2.DataType = 'boolean';
Armed2.Value = false;

Handle2 = Simulink.Parameter;
Handle2.DataType = 'uint8';
Handle2.Value = 0;

RevHandle2 = Simulink.Parameter;
RevHandle2.DataType = 'uint8';
RevHandle2.Value = 0;

RevBackHandle2 = Simulink.Parameter;
RevBackHandle2.DataType = 'uint8';
RevBackHandle2.Value = 0;

PresentTap2 = Simulink.Parameter;
PresentTap2.DataType = 'double';
PresentTap2.Value = double(TReg2.Winding(tw).puTap); % specific to transformer 

% Phase 3:

ReversePending3 = Simulink.Parameter;
ReversePending3.DataType = 'boolean';
ReversePending3.Value = false;

InCogenMode3 = Simulink.Parameter;
InCogenMode3.DataType = 'boolean';
InCogenMode3.Value = false;

InReverseMode3 = Simulink.Parameter;
InReverseMode3.DataType = 'boolean';
InReverseMode3.Value = false;

LookingForward3 = Simulink.Parameter;
LookingForward3.DataType = 'boolean';
LookingForward3.Value = false;

Armed3 = Simulink.Parameter;
Armed3.DataType = 'boolean';
Armed3.Value = false;

Handle3 = Simulink.Parameter;
Handle3.DataType = 'uint8';
Handle3.Value = 0;

RevHandle3 = Simulink.Parameter;
RevHandle3.DataType = 'uint8';
RevHandle3.Value = 0;

RevBackHandle3 = Simulink.Parameter;
RevBackHandle3.DataType = 'uint8';
RevBackHandle3.Value = 0;

PresentTap3 = Simulink.Parameter;
PresentTap3.DataType = 'double';
PresentTap3.Value = double(TReg3.Winding(tw).puTap); % specific to transformer

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
StatesElems(6).Name = 'Handle';
StatesElems(6).Dimensions = 1;
StatesElems(6).DimensionsMode = 'Fixed';
StatesElems(6).DataType = 'uint8';
StatesElems(6).SampleTime = -1;
StatesElems(6).Complexity = 'real';

StatesElems(7) = Simulink.BusElement;
StatesElems(7).Name = 'RevHandle';
StatesElems(7).Dimensions = 1;
StatesElems(7).DimensionsMode = 'Fixed';
StatesElems(7).DataType = 'uint8';
StatesElems(7).SampleTime = -1;
StatesElems(7).Complexity = 'real';

StatesElems(8) = Simulink.BusElement;
StatesElems(8).Name = 'RevBackHandle';
StatesElems(8).Dimensions = 1;
StatesElems(8).DimensionsMode = 'Fixed';
StatesElems(8).DataType = 'uint8';
StatesElems(8).SampleTime = -1;
StatesElems(8).Complexity = 'real';

StatesElems(9) = Simulink.BusElement;
StatesElems(9).Name = 'PresentTap';
StatesElems(9).Dimensions = 1;
StatesElems(9).DimensionsMode = 'Fixed';
StatesElems(9).DataType = 'double';
StatesElems(9).SampleTime = -1;
StatesElems(9).Complexity = 'real';

StatesBus = Simulink.Bus;
StatesBus.Elements = StatesElems;

%% Snapshot approximating Daily Simulation:

% Add loadshape:
LoadShape = csvread('LoadShape1.csv');
LoadNorm = normalize(LoadShape, 'range');

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
LastQueue.Value = zeros(1,5,50);
% LastHandle.Value = 1;

QueueTimeLapse = zeros(1,5,50,N);
ExecutedTimeLapse = zeros(1,5,N); % last executed item, updated on each iteration
HandleTimeLapse = zeros(N,1);

tapPos = zeros(N, length(regNames));
VoltagesInOut = zeros(3,2,N); % 3 phases, 2 terminals, N samples
CurrentsInOut = zeros(3,2,N);

EventLog = struct( 'Hour', {}, 'Sec', {}, 'ControlIter', {}, 'Action', {}, ...
    'Position', {}, 'TapChange', {}, 'Device', {});

for nn = 1:N
    tic;
    
    DSSSolution.LoadMult = LoadNorm(nn); % new loadshape per iteration
    
    DSSSolution.Hour = HourInVals(nn); % controlling clock
    DSSSolution.Seconds = SecInVals(nn);
    
    DSSSolution.InitSnap;

    CtrlIter = 0;

    while CtrlIter < DSSSolution.MaxControlIterations
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

        % 3 - configure simulation parameters with prinnor timestep's results:    
        TimeInSec.Value = TimeInVals(nn);
        
        LastQueueToLog = [];
    
        if nn > 1 % there exists an output from a prior iteration
            ReversePending.Value = simOut(nn-1).CurrReversePending.Data;
            InCogenMode.Value = simOut(nn-1).CurrInCogenMode.Data;
            InReverseMode.Value = simOut(nn-1).CurrInReverseMode.Data;
            LookingForward.Value = simOut(nn-1).CurrLookingForward.Data;
            Armed.Value = simOut(nn-1).CurrArmed.Data;       
            Handle.Value = simOut(nn-1).CurrHandle.Data;
            RevHandle.Value = simOut(nn-1).CurrRevHandle.Data;
            RevBackHandle.Value = simOut(nn-1).CurrRevBackHandle.Data;

            CurrQueueSize = simOut(nn-1).QueueSize.Data;
            TempLastQueue = zeros(1,5,50);
            LastQueueToLog = [];
            if CurrQueueSize > 0
                LastQueueToLog = ...
                    simOut(nn-1).CurrQueue.signals.values(:,:,1:CurrQueueSize,end);
                TempLastQueue(:,:,1:CurrQueueSize) = LastQueueToLog;
            end
            LastQueue.Value = TempLastQueue;

            HandleTimeLapse( nn-1 ) = Handle.Value;
            QueueTimeLapse( :,:,:,(nn-1) ) = LastQueue.Value;
            ExecutedTimeLapse( :,:,(nn-1) ) = ...
                simOut(nn-1).FromQueue.signals.values(:,:,end); % based on latest addition to the Queue
        end
        
        % 4 - obtain control actions from Simulink:    
        simOut(nn) = sim('regcontrol_1ph', 'TimeOut', 1000);

        TimeElapsed = toc;

        % 5 - execute tap changes in DSS:
        xfms.Tap = xfms.Tap + simOut(nn).TapChangeToMake.Data;
        
        % display the result
        disp(['Result='  DSSText.Result])

        if DSSSolution.Converged 
           a = ['Solution Converged in ' num2str(DSSSolution.Iterations) ' iterations.'];
        else
           a = 'Solution did not Converge';
        end
        disp(a)    

        DSSSolution.SampleControlDevices;
        DSSSolution.DoControlActions;
        
        Logged = LogEvent_1ph( nn, HourOutVals(nn), SecOutVals(nn), ...
            simOut(nn).ToQueue.signals.values, LastQueueToLog, ...
            simOut(nn).FromQueue.signals.values, simOut(nn).TapChangeToMake.Data, ...
            tapPos, regNames{1}, TapIncrement.Value, CtrlIter);
        
        if CtrlIter == 0
              EventLog(nn) = Logged;
        else % if subsequent action does nothing, do not replace original:
            if ~contains(Logged.Action, 'None')
               EventLog(nn) = Logged;
            end
        end
    
        fprintf('Iteration %d, Time = %g\n', nn, TimeElapsed);

        if DSSSolution.ControlActionsDone, break, end 

        CtrlIter = CtrlIter + 1;
    end
    
    % update all tap positions:
    xf_trans = DSSCircuit.Transformers;
    
    for phase = 1:length(regNames)
        xf_trans.Name = xsfNames{phase};
        DSSCircuit.SetActiveElement(char( strcat('Transformer.', xsfNames{phase}) ));
        xf_ckt = DSSCircuit.ActiveCktElement;
        tapPos(nn, phase) = xf_trans.Tap;
        
        tempVolts = abs(MakeComplex(xf_ckt.Voltages));
        tempCurr = abs(MakeComplex(xf_ckt.Currents)); 
        VoltagesInOut(phase,1,nn) = tempVolts(1);
        VoltagesInOut(phase,2,nn) = tempVolts(3);
        CurrentsInOut(phase,1,nn) = tempCurr(1);
        CurrentsInOut(phase,2,nn) = tempCurr(3);
    end
end

DSSText.Command = 'Show Eventlog';

%% Plots 

Time = TimeOutVals/3600; % converts cumulative seconds to hours

figure(1);
plot(Time, tapPos(:,1),'-k+');  % black *
hold on
plot(Time, tapPos(:,2),'-r+');
plot(Time, tapPos(:,3),'-b+');
title('Daily Simulation: Transformer Taps');
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
title('Daily Simulation: Voltages on Input Terminal');
ylabel('Voltage');
xlabel('Hour');
hold off

Vout = VoltagesInOut(:,2,:);
subplot(2,1,2);
plot(Time(1:N), Vout(1,1:N),'-k+');  % black *
hold on
plot(Time(1:N), Vout(2,1:N),'-r+');
plot(Time(1:N), Vout(3,1:N),'-b+');
title('Daily Simulation: Voltages on Output Terminal');
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
title('Daily Simulation: Currents on Input Terminal');
ylabel('Voltage');
xlabel('Hour');
hold off

Cout = CurrentsInOut(:,2,:);
subplot(2,1,2);
plot(Time(1:N), Cout(1,1:N),'-k+');  % black *
hold on
plot(Time(1:N), Cout(2,1:N),'-r+');
plot(Time(1:N), Cout(3,1:N),'-b+');
title('Daily Simulation: Currents on Output Terminal');
ylabel('Voltage');
xlabel('Hour');
hold off







