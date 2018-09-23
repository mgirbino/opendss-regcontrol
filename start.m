%% Start COM Server
addpath(pwd);
import RegControlPkg.WindingObj;
import RegControlPkg.TransformerObj;
import RegControlPkg.RegControlObj;

% execute DSSStartup.m
[DSSStartOK, DSSObj, DSSText] = DSSStartup;

if DSSStartOK
    a = 'DSS Started';
    formatSpec = string('Compile (%s\\IEEE13Nodeckt.dss)');
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
Reg1 = TransformerObj("fNphases", 1, "bank", "reg1", "XHL", 0.01, "kVAs", [1666 1666], ...
    "buses", ["650.1", "RG60.1"], "kVs", [2.4 2.4], "pctLoadLoss", 0.01);

Reg2 = TransformerObj("fNphases", 1, "bank", "reg1", "XHL", 0.01, "kVAs", [1666 1666], ...
    "buses", ["650.2", "RG60.2"], "kVs", [2.4 2.4], "pctLoadLoss", 0.01);

Reg3 = TransformerObj("fNphases", 1, "bank", "reg1", "XHL", 0.01, "kVAs", [1666 1666], ...
    "buses", ["650.3", "RG60.3"], "kVs", [2.4 2.4], "pctLoadLoss", 0.01);



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

elems(1) = Simulink.BusElement;
elems(1).Name = 'BandWidth';
elems(1).Dimensions = 1;
elems(1).DimensionsMode = 'Fixed';
elems(1).DataType = 'double';
elems(1).SampleTime = -1;
elems(1).Complexity = 'real';

UsingRegulatedBus = Simulink.Parameter;
UsingRegulatedBus.DataType = 'boolean';
UsingRegulatedBus.Value = false;

elems(2) = Simulink.BusElement;
elems(2).Name = 'UsingRegulatedBus';
elems(2).Dimensions = 1;
elems(2).DimensionsMode = 'Fixed';
elems(2).DataType = 'boolean';
elems(2).SampleTime = -1;
elems(2).Complexity = 'real';

CogenEnabled = Simulink.Parameter;
CogenEnabled.DataType = 'boolean';
CogenEnabled.Value = false;

elems(3) = Simulink.BusElement;
elems(3).Name = 'CogenEnabled';
elems(3).Dimensions = 1;
elems(3).DimensionsMode = 'Fixed';
elems(3).DataType = 'boolean';
elems(3).SampleTime = -1;
elems(3).Complexity = 'real';

LDC_Z = Simulink.Parameter;
LDC_Z.DataType = 'double';
LDC_Z.Value = 0; % verify

elems(4) = Simulink.BusElement;
elems(4).Name = 'LDC_Z';
elems(4).Dimensions = 1;
elems(4).DimensionsMode = 'Fixed';
elems(4).DataType = 'double';
elems(4).SampleTime = -1;
elems(4).Complexity = 'real';

TapLimitPerChange = Simulink.Parameter;
TapLimitPerChange.DataType = 'uint8';
TapLimitPerChange.Value = 16;

elems(5) = Simulink.BusElement;
elems(5).Name = 'TapLimitPerChange';
elems(5).Dimensions = 1;
elems(5).DimensionsMode = 'Fixed';
elems(5).DataType = 'uint8';
elems(5).SampleTime = -1;
elems(5).Complexity = 'real';

PTratio = Simulink.Parameter;
PTratio.DataType = 'double';
PTratio.Value = 60;

elems(6) = Simulink.BusElement;
elems(6).Name = 'PTratio';
elems(6).Dimensions = 1;
elems(6).DimensionsMode = 'Fixed';
elems(6).DataType = 'double';
elems(6).SampleTime = -1;
elems(6).Complexity = 'real';

RevBand = Simulink.Parameter;
RevBand.DataType = 'double';
RevBand.Value = 0; % verify

elems(7) = Simulink.BusElement;
elems(7).Name = 'RevBand';
elems(7).Dimensions = 1;
elems(7).DimensionsMode = 'Fixed';
elems(7).DataType = 'double';
elems(7).SampleTime = -1;
elems(7).Complexity = 'real';

IsReversible = Simulink.Parameter;
IsReversible.DataType = 'boolean';
IsReversible.Value = false;

elems(8) = Simulink.BusElement;
elems(8).Name = 'IsReversible';
elems(8).Dimensions = 1;
elems(8).DimensionsMode = 'Fixed';
elems(8).DataType = 'boolean';
elems(8).SampleTime = -1;
elems(8).Complexity = 'real';

RevVreg = Simulink.Parameter;
RevVreg.DataType = 'double';
RevVreg.Value = 0; % verify

elems(9) = Simulink.BusElement;
elems(9).Name = 'RevVreg';
elems(9).Dimensions = 1;
elems(9).DimensionsMode = 'Fixed';
elems(9).DataType = 'double';
elems(9).SampleTime = -1;
elems(9).Complexity = 'real';

Vlimit = Simulink.Parameter;
Vlimit.DataType = 'double';
Vlimit.Value = 0; % verify

elems(10) = Simulink.BusElement;
elems(10).Name = 'Vlimit';
elems(10).Dimensions = 1;
elems(10).DimensionsMode = 'Fixed';
elems(10).DataType = 'double';
elems(10).SampleTime = -1;
elems(10).Complexity = 'real';

Vreg = Simulink.Parameter;
Vreg.DataType = 'double';
Vreg.Value = 120;

elems(11) = Simulink.BusElement;
elems(11).Name = 'Vreg';
elems(11).Dimensions = 1;
elems(11).DimensionsMode = 'Fixed';
elems(11).DataType = 'double';
elems(11).SampleTime = -1;
elems(11).Complexity = 'real';

% signals, only changed outside of state machine:
FwdPower = Simulink.Signal;
FwdPower.DataType = 'double';
% FwdPower.InitialValue = 0;

elems(12) = Simulink.BusElement;
elems(12).Name = 'FwdPower';
elems(12).Dimensions = 1;
elems(12).DimensionsMode = 'Fixed';
elems(12).DataType = 'double';
elems(12).SampleTime = -1;
elems(12).Complexity = 'real';

ILDC = Simulink.Signal;
ILDC.DataType = 'double';
% ILDC.InitialValue = 0;

elems(13) = Simulink.BusElement;
elems(13).Name = 'ILDC';
elems(13).Dimensions = 1;
elems(13).DimensionsMode = 'Fixed';
elems(13).DataType = 'double';
elems(13).SampleTime = -1;
elems(13).Complexity = 'real';

% Information about transformer (parameters and signals):

WindingConnections = Simulink.Parameter;
WindingConnections.DataType = 'uint8';
WindingConnections.Value = [Connections.DELTA Connections.WYE];

CTelems(1) = Simulink.BusElement;
CTelems(1).Name = 'WindingConnections';
CTelems(1).Dimensions = 1;
CTelems(1).DimensionsMode = 'Variable';
CTelems(1).DataType = 'uint8';
CTelems(1).SampleTime = -1;
CTelems(1).Complexity = 'real';

WindingVoltages = Simulink.Signal;
WindingVoltages.DataType = 'double';
%WindingVoltages.Value = [100 100];

CTelems(2) = Simulink.BusElement;
CTelems(2).Name = 'WindingVoltages';
CTelems(2).Dimensions = 1;
CTelems(2).DimensionsMode = 'Variable';
CTelems(2).DataType = 'double';
CTelems(2).SampleTime = -1;
CTelems(2).Complexity = 'complex';

BaseVoltage = Simulink.Parameter;
BaseVoltage.DataType = 'double';
BaseVoltage.Value = [100 100]; % change

CTelems(3) = Simulink.BusElement;
CTelems(3).Name = 'BaseVoltage';
CTelems(3).Dimensions = 1;
CTelems(3).DimensionsMode = 'Variable';
CTelems(3).DataType = 'double';
CTelems(3).SampleTime = -1;
CTelems(3).Complexity = 'real';

elems(14) = Simulink.BusElement;
elems(14).Name = 'ControlledTransformer';
elems(14).Dimensions = 1;
elems(14).DimensionsMode = 'Fixed';
elems(14).DataType = 'Bus';
elems(14).SampleTime = -1;
elems(14).Complexity = 'complex';

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
ControlledTransformer.Elements = CTelems;

InputsBus = Simulink.Bus;
InputsBus.Elements = elems;

% % Specify the programmatic port parameter 'Name'.
% set_param(outportHandle,'state','RevBand')
% 
% % Set the port parameter 'MustResolveToSignalObject'.
% set_param(outportHandle,'MustResolveToSignalObject','on')


