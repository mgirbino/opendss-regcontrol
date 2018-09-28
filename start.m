%% Start COM Server
addpath(pwd);
import RegControlPkg.WindingObj;
import RegControlPkg.TransformerObj;
import RegControlPkg.RegControlObj;

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

RCReg2 = RegControlObj('ElementName', TReg1.getName, 'xsfWinding', 2, 'Vreg', 122, ...
    'Bandwidth', 2.0, 'PTRatio', 20, 'CTRating', 700, 'R', 3, 'X', 9);

RCReg3 = RegControlObj('ElementName', TReg1.getName, 'xsfWinding', 2, 'Vreg', 122, ...
    'Bandwidth', 2.0, 'PTRatio', 20, 'CTRating', 700, 'R', 3, 'X', 9);

% new regcontrol.Reg1  transformer=Reg1 winding=2  vreg=122  band=2  ptratio=20 ctprim=700  R=3   X=9 !maxtapchange=1

DSSText.command = TReg1.DSSCommand;
DSSText.command = TReg2.DSSCommand;
DSSText.command = TReg3.DSSCommand;

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

VBuffer = xfm1.Voltages; % [in ... | out ...]; [1 2], [3 4] = [real imag], [real imag]
CBuffer = xfm1.Currents;

VBMA = xfm1.VoltagesMagAng; % [in ... | out ...]; [1 2], [3 4] = [mag ang], [mag ang]
CBMA = xfm1.CurrentsMagAng;

PBuffer = xfm1.Powers;

% reading I from current transformer;
% getting to a single phase by its element terminal (quantized by number
% of conductors) + the phase of that element;
% using 1-indexing (Matlab)
ILDC = CBuffer(TReg1.fNconds*(RCReg1.ElementTerminal) + RCReg1.ControlledPhase - 1) / RCReg1.CTRating;

%% Data packaging for Simulink:

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

SignalElems(1) = Simulink.BusElement;
SignalElems(1).Name = 'Reg1v';
SignalElems(1).Dimensions = 4;
SignalElems(1).DimensionsMode = 'Fixed';
SignalElems(1).DataType = 'double';
SignalElems(1).SampleTime = -1;
SignalElems(1).Complexity = 'real';

SignalElems(2) = Simulink.BusElement;
SignalElems(2).Name = 'Reg1i';
SignalElems(2).Dimensions = 4;
SignalElems(2).DimensionsMode = 'Fixed';
SignalElems(2).DataType = 'double';
SignalElems(2).SampleTime = -1;
SignalElems(2).Complexity = 'real';

EquipmentBus = Simulink.Bus;
EquipmentBus.Elements = EquipElems;

SignalBus = Simulink.Bus;
SignalBus.Elements = SignalElems;

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


