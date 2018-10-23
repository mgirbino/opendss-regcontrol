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
    formatSpec = string('Compile (%s\\IEEE13Nodeckt_noreg.dss)');
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

%% Run a Daily analysis and plot the voltages at the end of the feeder

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

% Change regulators to 1 tap:
DSSRegs = DSSCircuit.RegControls;
iReg = DSSRegs.First;
while iReg>0
    DSSRegs.MaxTapChange = 1;
    iReg = DSSRegs.Next;
end

% Place monitors:
DSSText.Command = 'New monitor.FeederVoltageCurrent element=Line.650632 terminal=1 mode=0';
DSSText.Command = 'New monitor.Tap1 element=Transformer.TReg1 terminal=2 mode=2';
DSSText.Command = 'New monitor.Tap2 element=Transformer.TReg2 terminal=2 mode=2';
DSSText.Command = 'New monitor.Tap3 element=Transformer.TReg3 terminal=2 mode=2';

% Solve for a daily simulation:
DSSText.Command = 'set mode=daily stepsize=15m number=96 controlmode=time';
% number of solns to perform for Monte Carlo/daily load simulations
DSSText.Command = 'Set number=1';  % Still in Daily mode; each Solve does 15 min

CtrlOps = zeros(10,4,96);
% run for 24 hours:
for nn=1:96 % 3rd dimension of Ctrl Ops := # time divisions
    DSSSolution.SolveNoControl;
    DSSSolution.SampleControlDevices;

    len = DSSCircuit.CtrlQueue.QueueSize;
    if len >= 1 % parse the Queue if it isn't empty
        DSSText.Command = 'Show Control Queue'
        CtrlQueueFile = 'C:\Users\Michael Girbino\Documents\13Node Matlab OpenDSS\IEEE13Nodeckt_ControlQueue.csv';  	
        RawQueue = parseCSV(CtrlQueueFile);
        
        % CtrlOps(:,:,i) = [ Time | Handle | ActionCode | Device ]
        CtrlOps(1:len,CtrlOpsFields.Time,nn) = RawQueue{CtrlQueueFields.Hour}...
            + RawQueue{CtrlQueueFields.Sec}/3600;
        CtrlOps(1:len,CtrlOpsFields.Handle,nn) = RawQueue{CtrlQueueFields.Handle};
        CtrlOps(1:len,CtrlOpsFields.ActionCode,nn) = RawQueue{CtrlQueueFields.ActionCode};
        CtrlDev = erase(RawQueue{CtrlQueueFields.Device},' ');
        for nn = 1:size(CtrlDev,1)
            switch string(CtrlDev(nn,1))
                case 'reg1'
                    CtrlOps(1:len,CtrlOpsFields.Device,nn) = Device.Reg1;
                case 'reg2'
                    CtrlOps(1:len,CtrlOpsFields.Device,nn) = Device.Reg2;
                case 'reg3'
                    CtrlOps(1:len,CtrlOpsFields.Device,nn) = Device.Reg3;
            end
        end
    end
    
    DSSSolution.Solve;
% 
%     DSSText.Command='Buscoords Buscoords.dat   ! load in bus coordinates';
end

DSSText.Command = 'Show Eventlog';

%% Running through OpenDSS Transformers:
DSSTransf = DSSCircuit.Transformers;
iTransf = DSSTransf.First;

xsfdata = "";
while iTransf > 0
    xsfdata = xsfdata + string(DSSTransf.Name) + newline;
    for ii = 1:DSSTransf.NumWindings
        DSSTransf.Wdg = ii;
        xsfdata = xsfdata + string(ii) + " IsDelta: " + string(DSSTransf.IsDelta) + newline;
        xsfdata = xsfdata + string(ii) + " kV: " + string(DSSTransf.kV) + newline;
        xsfdata = xsfdata + string(ii) + " kVA: " + string(DSSTransf.kva) + newline;
        xsfdata = xsfdata + string(ii) + " MaxTap: " + string(DSSTransf.MaxTap) + newline;
        xsfdata = xsfdata + string(ii) + " MinTap: " + string(DSSTransf.MinTap) + newline;
        xsfdata = xsfdata + string(ii) + " NumTaps: " + string(DSSTransf.NumTaps) + newline;
        xsfdata = xsfdata + string(ii) + " Current Tap: " + string(DSSTransf.Tap) + newline;
        xsfdata = xsfdata + string(ii) + " R: " + string(DSSTransf.R) + newline;
        xsfdata = xsfdata + string(ii) + " Rneut: " + string(DSSTransf.Rneut) + newline;
    end    
    xsfdata = xsfdata + "Xhl: " + string(DSSTransf.Xhl) + newline;
    xsfdata = xsfdata + "Xht: " + string(DSSTransf.Xht) + newline;
    xsfdata = xsfdata + "Xlt: " + string(DSSTransf.Xlt) + newline;
    xsfdata = xsfdata + "Xneut: " + string(DSSTransf.Xneut) + newline + newline;
    
    iTransf = DSSTransf.Next;
end

%% Using plain text commands for comparison purposes:
DSSText.Command = 'New Transformer.TReg1 phases=1 bank=reg1 XHL=0.01 kVAs=[1666 1666] Buses=[650.1 RG60.1] kVs=[2.4  2.4] %LoadLoss=0.01 Xht=0.35 Xlt=0.3';
DSSText.Command = 'New Transformer.TReg2 phases=1 bank=reg1 XHL=0.01 kVAs=[1666 1666] Buses=[650.2 RG60.2] kVs=[2.4  2.4] %LoadLoss=0.01';
DSSText.Command = 'New Transformer.TReg3 phases=1 bank=reg1 XHL=0.01 kVAs=[1666 1666] Buses=[650.3 RG60.3] kVs=[2.4  2.4] %LoadLoss=0.01';

%% Data sharing 2.0:
DSSCircuit.SetActiveElement('Transformer.TReg1');
xfm1 = DSSCircuit.ActiveCktElement;

ControlledTransformerVoltages = MakeComplex(xfm1.Voltages); % [in ... | out ...]; [1 2], [3 4] = [real imag], [real imag]
CBuffer = MakeComplex(xfm1.Currents);

% VBMA = xfm1.VoltagesMagAng; % [in ... | out ...]; [1 2], [3 4] = [mag ang], [mag ang]
% CBMA = xfm1.CurrentsMagAng;

ControlledTransformerPowers = MakeComplex(xfm1.Powers);

% reading I from current transformer;
% getting to a single phase by its element terminal (quantized by number
% of conductors) + the phase of that element;
% using 1-indexing (Matlab)
ILDC = CBuffer(TReg1.fNconds*(RCReg1.ElementTerminal) + RCReg1.ControlledPhase - 1) / RCReg1.CTRating;
%% When using Regulated Bus (RegControl affects voltage at separate bus):
DSSCircuit.SetActiveElement('Transformer.TReg1'); % assume this is at the regulated bus
RegulatedBus = DSSCircuit.ActiveCktElement;

VTerminal = MakeComplex(RegulatedBus.Voltages); % [in ... | out ...]; [1 2], [3 4] = [real imag], [real imag]
% ...package into a parameter


%% Data packaging for Simulink:

% ControlledTransformerVoltages
% ControlledTransformerPowers
% VTerminal
% ILDC

DSSCircuit.SetActiveElement('Transformer.TReg1');
xfm1 = DSSCircuit.ActiveCktElement;

ControlledTransformerVoltages = Simulink.Parameter;
ControlledTransformerVoltages.DataType = 'double';
ControlledTransformerVoltages.Value = MakeComplex(xfm1.Voltages); 
% [in ... | out ...]' (complex)

ControlledTransformerCurrents = Simulink.Parameter;
ControlledTransformerCurrents.DataType = 'double';
ControlledTransformerCurrents.Value = MakeComplex(xfm1.Currents); 
% [in ... | out ...]' (complex)

ControlledTransformerPowers = Simulink.Parameter;
ControlledTransformerPowers.DataType = 'double';
ControlledTransformerPowers.Value = MakeComplex(xfm1.Powers); 
% [in ... | out ...]' (complex)

DSSCircuit.SetActiveElement('Transformer.TReg1'); % assume this is at the regulated bus
RegulatedBus = DSSCircuit.ActiveCktElement;

VTerminal = Simulink.Parameter;
VTerminal.DataType = 'double';
VTerminal.Value = MakeComplex(RegulatedBus.Voltages); 
% [in ... | out ...]' (complex)

% CBuffer = MakeComplex(xfm1.Currents);

% ILDC = Simulink.Parameter;
% ILDC.DataType = 'double';
% ILDC.Value = CBuffer(TReg1.fNconds*(RCReg1.ElementTerminal) + RCReg1.ControlledPhase - 1) ...
%     / RCReg1.CTRating;
% a complex scalar

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

% SignalElems(4) = Simulink.BusElement;
% SignalElems(4).Name = 'ILDC';
% SignalElems(4).Dimensions = 1;
% SignalElems(4).DimensionsMode = 'Fixed';
% SignalElems(4).DataType = 'double';
% SignalElems(4).SampleTime = -1;
% SignalElems(4).Complexity = 'complex';

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

%% Buses for 3-phase operation:

%% Running the simulation:

simOut = sim('regcontrol_model','SimulationMode','normal','AbsTol','1e-5',...
            'SaveState','on','StateSaveName','xout',...
            'SaveOutput','on','OutputSaveName','yout',...
 'SaveFormat', 'Dataset');
% 
% outputs = simOut.get('yout');

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
for nn = 1:N
    % 1 - Obtain power flow:
    DSSSolution.SolveNoControl;
    
    % 2 - Package measurements:
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
    
    PresentTap.Value = double(TReg1.Winding(tw).puTap); 
    
    % 3 - obtain control actions:    
    simOut(nn) = sim('regcontrol_model', 'timeout', 1000);
    
    % 4 - execute tap changes:
    xfms = DSSCircuit.Transformers;
    xfms.Name = 'TReg1';
    xfms.Tap = xfms.Tap + TapChangeToMake;
    
    % 5 - Power flow after control actions:    
    DSSSolution.Solve;
end

DSSText.Command = 'Show Eventlog';

%% Old data packaging:

Reg1v = Simulink.Parameter;
Reg1v.DataType = 'double';
Reg1v.Value = 1;%xfm1.Voltages; % 1 x 4 : [re_in im_in re_out im_out]

Reg1i = Simulink.Parameter;
Reg1i.DataType = 'double';
Reg1i.Value = 2;%xfm1.Currents; % 1 x 4 : [re_in im_in re_out im_out]

% setting up 2 buses:
EquipElems(1) = Simulink.BusElement;
EquipElems(1).Name = 'RCReg1';
EquipElems(1).Dimensions = 1;
EquipElems(1).DimensionsMode = 'Fixed';
EquipElems(1).DataType = 'RegControlObj';
EquipElems(1).SampleTime = -1;
EquipElems(1).Complexity = 'real';

EquipElems(2) = Simulink.BusElement;
EquipElems(2).Name = 'TReg1';
EquipElems(2).Dimensions = 1;
EquipElems(2).DimensionsMode = 'Fixed';
EquipElems(2).DataType = 'TransformerObj';
EquipElems(2).SampleTime = -1;
EquipElems(2).Complexity = 'real';

EquipElems(1) = Simulink.BusElement;
EquipElems(1).Name = 'Reg1v';
EquipElems(1).Dimensions = 4;
EquipElems(1).DimensionsMode = 'Fixed';
EquipElems(1).DataType = 'double';
EquipElems(1).SampleTime = -1;
EquipElems(1).Complexity = 'real';

EquipElems(2) = Simulink.BusElement;
EquipElems(2).Name = 'Reg1i';
EquipElems(2).Dimensions = 4;
EquipElems(2).DimensionsMode = 'Fixed';
EquipElems(2).DataType = 'double';
EquipElems(2).SampleTime = -1;
EquipElems(2).Complexity = 'real';

EquipmentBus = Simulink.Bus;
EquipmentBus.Elements = EquipElems;

SignalBus = Simulink.Bus;
SignalBus.Elements = EquipElems;

%% Data sharing between OpenDSS and Matlab workspace:

DSSCircuit.SetActiveElement('Transformer.Reg1');
xfm1 = DSSCircuit.ActiveCktElement;
xfm1v = xfm1.Voltages; % 1 x 4 : [re_in im_in re_out im_out]
xfm1i = xfm1.Currents;
xfm1o = xfm1.NodeOrder; % [1 0 1 0]
xfm1c = xfm1.NumConductors; % 2 (per port, input and output)
% wye-wye (all 3 phases)

aa = DSSCircuit.AllNames % array of strings with all tranformer names in the active circuit
bb = xfm1.Count
cc = xfm1.First % sets the first transformer active. Returns 0 if no more.
dd = xfm1.IsDelta % false if Wye
ee = xfm1.kV % active winding kV rating. Phase-phase for 2 or 3 phases, actual winding kV for 1 phase transformer
ff = xfm1.kva % active winding kVA rating. On winding 1, this also determines normal and emergency current ratings for all windings
gg = xfm1.MaxTap % active winding max tap in PU
hh = xfm1.MinTap % active winding min tap in PU
iii = xfm1.Name % sets a transformer active by name
jj = xfm1.Next % sets the next transformer active. Returns 0 if no more
kk = xfm1.NumTaps % Active winding number of tap steps between MinTap and MaxTap
ll = xfm1.NumWindings % Number of windings on this transformer
mm = xfm1.R % active winding resistance in percent
nn = xfm1.Rneut % active winding neutral resistance in ohms for wye connections. < 0 for ungrounded wye
oo = xfm1.Tap % active winding tap in PU
pp = xfm1.Wdg % active winding number from 1..NumWindings. Update this before reading or setting a sequence of winding properties
qq = xfm1.XfmrCode % name of XfmrCode that supplies electrical parameters for this transformer
rr = xfm1.Xhl % percent reactance between windings 1 and 2, on winding 1 kVA base. for 2- and 3-wdg transformers
ss = xfm1.Xht % percent reactance between windings 1 and 3, on winding 1 kVA base. for 3- winding transformers only.
tt = xfm1.Xlt % percent reactance between windings 2 and 3, on winding 1 kVA base. for 3- winding transformers only.
uu = xfm1.Xneut % active winding neutral reactance in ohms for wye connections


DSSCircuit.SetActiveElement('Transformer.Reg2');
xfm2 = DSSCircuit.ActiveCktElement;
xfm2v = xfm2.Voltages;
xfm2i = xfm2.Currents;
xfm2o = xfm2.NodeOrder; % [2 0 2 0]

DSSCircuit.SetActiveElement('Transformer.Reg3');
xfm3 = DSSCircuit.ActiveCktElement;
xfm3v = xfm3.Voltages;
xfm3i = xfm3.Currents;
xfm3o = xfm3.NodeOrder; % [3 0 3 0]

DSSCircuit.SetActiveElement('Transformer.Sub');
sub = DSSCircuit.ActiveCktElement;
subv = sub.Voltages; % 1 x 16
subi = sub.Currents;
subo = sub.NodeOrder; % [1   2   3   0   1   2   3   0]

%% Set starting parameters:
R = 0;
X = 0;
LDC_Z = 0;
% LDC_Active
RegulatedBus = 0;
% UsingRegulatedBus
Nphases = 0;
Nconds = 0;
FPTphase = 0; 
ElementTerminal = 0; % AKA TapWinding

%% Recalculate element data:
if R~=0 || X~=0 || LDC_Z>0
    LDCActive = true;
else
    LDCActive = false;
end

if length(RegulatedBus) == 0
    UsingRegulatedBus = false;
else
    UsingRegulatedBus = true;
end

if UsingRegulatedBus
    Nphases = 1; % Only need one phase
    Nconds  = 2;
else
    Nphases = xfm1.NumPhases; % transformer's # phases
    Nconds = FNphases; % # conductors = transformer's # phases
    if FPTphase > FNphases
        FPTphase = 1;
    end
end

% if ControlledElement is a transformer:
if contains(xfm1.Name, 'transformer', 'IgnoreCase', true)
    if ElementTerminal > xfm1.NumTerminals
        error('Winding does not exist.');
    else
        % Sets name of i-th terminal's connected bus in RegControl's buslist
        % This value will be used to set the NodeRef array (see Sample function)
%         if UsingRegulatedBus
%             if i <= xfm1.NumTerminals
%                 FBusNames^[i] := lowercase(S);
%                 ActiveCircuit.BusNameRedefined = true;  % Set Global Flag to signal circuit to rebuild busdefs
%             end
%             Setbus(1, RegulatedBus)   % hopefully this will actually exist
%         else
%             Setbus(1, ControlledElement.GetBus(ElementTerminal));
%         end
        VBuffer = double( zeros(xfm1.NumPhases, 1) ); % buffer to hold regulator voltages
        CBuffer = double( zeros( length(xfm1.Yprim), 1 ) ); % dimension = Yorder
    end
else
    error('Controlled element is not a transformer.');
end

%% Data Objects:
% parameters for Execution state machine:
ControlMode = Simulink.Parameter;
ControlMode.DataType = 'uint8';
ControlMode.Value = ControlModes.EVENTDRIVEN;

% parameters, only changed by state machine:
BandWidth = Simulink.Parameter;
BandWidth.DataType = 'double';
BandWidth.Value = 3.0;

EquipElems(1) = Simulink.BusElement;
EquipElems(1).Name = 'BandWidth';
EquipElems(1).Dimensions = 1;
EquipElems(1).DimensionsMode = 'Fixed';
EquipElems(1).DataType = 'double';
EquipElems(1).SampleTime = -1;
EquipElems(1).Complexity = 'real';

UsingRegulatedBus = Simulink.Parameter;
UsingRegulatedBus.DataType = 'boolean';
UsingRegulatedBus.Value = false;

EquipElems(2) = Simulink.BusElement;
EquipElems(2).Name = 'UsingRegulatedBus';
EquipElems(2).Dimensions = 1;
EquipElems(2).DimensionsMode = 'Fixed';
EquipElems(2).DataType = 'boolean';
EquipElems(2).SampleTime = -1;
EquipElems(2).Complexity = 'real';

CogenEnabled = Simulink.Parameter;
CogenEnabled.DataType = 'boolean';
CogenEnabled.Value = false;

EquipElems(3) = Simulink.BusElement;
EquipElems(3).Name = 'CogenEnabled';
EquipElems(3).Dimensions = 1;
EquipElems(3).DimensionsMode = 'Fixed';
EquipElems(3).DataType = 'boolean';
EquipElems(3).SampleTime = -1;
EquipElems(3).Complexity = 'real';

LDC_Z = Simulink.Parameter;
LDC_Z.DataType = 'double';
LDC_Z.Value = 0; % verify

EquipElems(4) = Simulink.BusElement;
EquipElems(4).Name = 'LDC_Z';
EquipElems(4).Dimensions = 1;
EquipElems(4).DimensionsMode = 'Fixed';
EquipElems(4).DataType = 'double';
EquipElems(4).SampleTime = -1;
EquipElems(4).Complexity = 'real';

TapLimitPerChange = Simulink.Parameter;
TapLimitPerChange.DataType = 'uint8';
TapLimitPerChange.Value = 16;

EquipElems(5) = Simulink.BusElement;
EquipElems(5).Name = 'TapLimitPerChange';
EquipElems(5).Dimensions = 1;
EquipElems(5).DimensionsMode = 'Fixed';
EquipElems(5).DataType = 'uint8';
EquipElems(5).SampleTime = -1;
EquipElems(5).Complexity = 'real';

PTratio = Simulink.Parameter;
PTratio.DataType = 'double';
PTratio.Value = 60;

EquipElems(6) = Simulink.BusElement;
EquipElems(6).Name = 'PTratio';
EquipElems(6).Dimensions = 1;
EquipElems(6).DimensionsMode = 'Fixed';
EquipElems(6).DataType = 'double';
EquipElems(6).SampleTime = -1;
EquipElems(6).Complexity = 'real';

RevBand = Simulink.Parameter;
RevBand.DataType = 'double';
RevBand.Value = 0; % verify

EquipElems(7) = Simulink.BusElement;
EquipElems(7).Name = 'RevBand';
EquipElems(7).Dimensions = 1;
EquipElems(7).DimensionsMode = 'Fixed';
EquipElems(7).DataType = 'double';
EquipElems(7).SampleTime = -1;
EquipElems(7).Complexity = 'real';

IsReversible = Simulink.Parameter;
IsReversible.DataType = 'boolean';
IsReversible.Value = false;

EquipElems(8) = Simulink.BusElement;
EquipElems(8).Name = 'IsReversible';
EquipElems(8).Dimensions = 1;
EquipElems(8).DimensionsMode = 'Fixed';
EquipElems(8).DataType = 'boolean';
EquipElems(8).SampleTime = -1;
EquipElems(8).Complexity = 'real';

RevVreg = Simulink.Parameter;
RevVreg.DataType = 'double';
RevVreg.Value = 0; % verify

EquipElems(9) = Simulink.BusElement;
EquipElems(9).Name = 'RevVreg';
EquipElems(9).Dimensions = 1;
EquipElems(9).DimensionsMode = 'Fixed';
EquipElems(9).DataType = 'double';
EquipElems(9).SampleTime = -1;
EquipElems(9).Complexity = 'real';

Vlimit = Simulink.Parameter;
Vlimit.DataType = 'double';
Vlimit.Value = 0; % verify

EquipElems(10) = Simulink.BusElement;
EquipElems(10).Name = 'Vlimit';
EquipElems(10).Dimensions = 1;
EquipElems(10).DimensionsMode = 'Fixed';
EquipElems(10).DataType = 'double';
EquipElems(10).SampleTime = -1;
EquipElems(10).Complexity = 'real';

Vreg = Simulink.Parameter;
Vreg.DataType = 'double';
Vreg.Value = 120;

EquipElems(11) = Simulink.BusElement;
EquipElems(11).Name = 'Vreg';
EquipElems(11).Dimensions = 1;
EquipElems(11).DimensionsMode = 'Fixed';
EquipElems(11).DataType = 'double';
EquipElems(11).SampleTime = -1;
EquipElems(11).Complexity = 'real';

% signals, only changed outside of state machine:
FwdPower = Simulink.Signal;
FwdPower.DataType = 'double';
% FwdPower.InitialValue = 0;

EquipElems(12) = Simulink.BusElement;
EquipElems(12).Name = 'FwdPower';
EquipElems(12).Dimensions = 1;
EquipElems(12).DimensionsMode = 'Fixed';
EquipElems(12).DataType = 'double';
EquipElems(12).SampleTime = -1;
EquipElems(12).Complexity = 'real';

ILDC = Simulink.Signal;
ILDC.DataType = 'double';
% ILDC.InitialValue = 0;

EquipElems(13) = Simulink.BusElement;
EquipElems(13).Name = 'ILDC';
EquipElems(13).Dimensions = 1;
EquipElems(13).DimensionsMode = 'Fixed';
EquipElems(13).DataType = 'double';
EquipElems(13).SampleTime = -1;
EquipElems(13).Complexity = 'real';

% Information about transformer (parameters and signals):

WindingConnections = Simulink.Parameter;
WindingConnections.DataType = 'uint8';
WindingConnections.Value = [Connections.DELTA Connections.WYE];

EquipElems(1) = Simulink.BusElement;
EquipElems(1).Name = 'WindingConnections';
EquipElems(1).Dimensions = 1;
EquipElems(1).DimensionsMode = 'Variable';
EquipElems(1).DataType = 'uint8';
EquipElems(1).SampleTime = -1;
EquipElems(1).Complexity = 'real';

WindingVoltages = Simulink.Signal;
WindingVoltages.DataType = 'double';
%WindingVoltages.Value = [100 100];

EquipElems(2) = Simulink.BusElement;
EquipElems(2).Name = 'WindingVoltages';
EquipElems(2).Dimensions = 1;
EquipElems(2).DimensionsMode = 'Variable';
EquipElems(2).DataType = 'double';
EquipElems(2).SampleTime = -1;
EquipElems(2).Complexity = 'complex';

BaseVoltage = Simulink.Parameter;
BaseVoltage.DataType = 'double';
BaseVoltage.Value = [100 100]; % change

EquipElems(3) = Simulink.BusElement;
EquipElems(3).Name = 'BaseVoltage';
EquipElems(3).Dimensions = 1;
EquipElems(3).DimensionsMode = 'Variable';
EquipElems(3).DataType = 'double';
EquipElems(3).SampleTime = -1;
EquipElems(3).Complexity = 'real';

EquipElems(14) = Simulink.BusElement;
EquipElems(14).Name = 'ControlledTransformer';
EquipElems(14).Dimensions = 1;
EquipElems(14).DimensionsMode = 'Fixed';
EquipElems(14).DataType = 'Bus';
EquipElems(14).SampleTime = -1;
EquipElems(14).Complexity = 'complex';

% TapDelay

% VBuffer - dimension = NPhases.Value

% CBuffer - dimension = Yorder.Value

% Yorder = fNConds * fNTerms (includes ground for delta)

% NConds = fNphases + 1, also fNConds = fNphases + 1

% equate NConds, NPhases with fNConds and fNPhases

% LastChange is only used by execution state machine

% ILDC = CBuffer( ControlledElement.Nconds*(ElementTerminal-1) +
% ControlledPhase ) / CTRating -- can do in SF

% MaxTap(Winding)
% MinTap(Winding)

% RevPowerThreshold

% Increment = TapIncrement(TapWinding)

% TapIncrement = (MaxTap - MinTap)/NumTaps -- from Transformer

% FPTphase : 'For multi-phase transformers, the number of the phase being monitored or one of { MAX | MIN} for all phases. Default=1. ' +
%                         'Must be less than or equal to the number of phases. Ignored for regulated bus.'
% 1 by default, otherwise bounded by MAXPHASE and MINPHASE

% If Vlimit >0 --> VlimitActive = true

portHandles = get_param('regcontrol_model/RegControl','portHandles');
outportHandle = portHandles.Outport;

%% Buses:

ControlledTransformer = Simulink.Bus;
ControlledTransformer.Elements = EquipElems;

InputsBus = Simulink.Bus;
InputsBus.Elements = EquipElems;

% % Specify the programmatic port parameter 'Name'.
% set_param(outportHandle,'state','RevBand')
% 
% % Set the port parameter 'MustResolveToSignalObject'.
% set_param(outportHandle,'MustResolveToSignalObject','on')


