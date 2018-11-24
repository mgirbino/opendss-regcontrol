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

% new regcontrol.Reg1  transformer=Reg1 winding=2  vreg=122  band=2  ptratio=20 ctprim=700  R=3   X=9 !maxtapchange=1

DSSText.command = TReg1.DSSCommand;
DSSText.command = TReg2.DSSCommand;
DSSText.command = TReg3.DSSCommand;

DSSText.command = strcat(RCReg1.DSSCommand, " DebugTrace = Yes");
DSSText.command = strcat(RCReg2.DSSCommand, " DebugTrace = Yes");
DSSText.command = strcat(RCReg3.DSSCommand, " DebugTrace = Yes");

xsfNames = {TReg1.getName; TReg2.getName; TReg3.getName};
regNames = {RCReg1.getName; RCReg2.getName; RCReg3.getName};
xsfIncr = [TReg1.Winding(RCReg1.xsfWinding).TapIncrement;
    TReg2.Winding(RCReg2.xsfWinding).TapIncrement;
    TReg3.Winding(RCReg3.xsfWinding).TapIncrement];

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

EventLog = struct( 'Hour', {}, 'Sec', {}, 'ControlIter', {}, 'Action', {}, ...
    'Position', {}, 'TapChange', {}, 'Device', {});

N = 96;

tapPos = zeros(N, length(regNames));

TimeVals = (24/N)*3600*(1:N); % convert to fraction of 24 hours, then to seconds
HourVals = floor(TimeVals/3600);
SecVals = TimeVals - 3600*HourVals;

N = 12;

for nn = 1:N    
    DSSSolution.SolveNoControl;
    DSSSolution.SampleControlDevices;
    
    CtrlQueueFile = ...
            'C:\Users\Michael Girbino\Documents\13Node Matlab OpenDSS\IEEE13Nodeckt_ControlQueue.csv';
    
    RawOriginal = cell(1,6);
    qs_original = DSSCircuit.CtrlQueue.QueueSize;
    if qs_original >= 1 % parse the Queue if it isn't empty
        DSSText.Command = 'Show Control Queue';	
        RawOriginal = parseCSV(CtrlQueueFile);
    end
    
    DSSSolution.Solve;
    
    RawAfterward = cell(1,6);
    qs_afterward = DSSCircuit.CtrlQueue.QueueSize;
    if qs_afterward >= 1 % parse the Queue if it isn't empty
        DSSText.Command = 'Show Control Queue';
        RawAfterward = parseCSV(CtrlQueueFile);
    end
    
    % update all tap positions:
    xsfm = DSSCircuit.Transformers;
    
    for phase = 1:length(regNames)
        xsfm.Name = xsfNames{phase};
        tapPos(nn, phase) = xsfm.Tap;
    end
    
    EventLog(nn) = LogEvent_dss( nn, HourVals(nn), SecVals(nn), ... 
        RawOriginal, RawAfterward, ...
        tapPos, regNames, xsfIncr);
end

DSSText.Command = 'Show Eventlog';
