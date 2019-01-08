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

DSSText.command = RCReg1.DSSCommand;
DSSText.command = RCReg2.DSSCommand;
DSSText.command = RCReg3.DSSCommand;

xsfNames = {TReg1.getName; TReg2.getName; TReg3.getName};
regNames = {RCReg1.getName; RCReg2.getName; RCReg3.getName};
xsfIncr = [TReg1.Winding(RCReg1.xsfWinding).TapIncrement;
    TReg2.Winding(RCReg2.xsfWinding).TapIncrement;
    TReg3.Winding(RCReg3.xsfWinding).TapIncrement];

%% Proof of steady-state deviations:
DSSText.command = char(dirCommand);

DSSText.command = TReg1.DSSCommand;
DSSText.command = TReg2.DSSCommand;
DSSText.command = TReg3.DSSCommand;

DSSText.command = RCReg1.DSSCommand;
DSSText.command = RCReg2.DSSCommand;
DSSText.command = RCReg3.DSSCommand;

DSSSolution.LoadMult = 1;
DSSText.command = 'Solve';
DSSText.command = 'BusCoords IEEE13Node_BusXY.csv';

% Plot Circuit Power Flow:
DSSText.command = 'set markercode=24';
DSSText.command = 'set markregulators=yes';
DSSText.command = 'plot circuit power 1ph=3';

% Plot voltages:
DSSText.command = 'set emergvminpu=1.0';
DSSText.command = 'set normvminpu=1.035';
DSSText.command = 'plot circuit voltage';

% Plot profile:
% DSSText.command = 'set normvminpu=0.95';
% DSSText.command = 'plot profile phases = primary';
% DSSText.command = 'plot profile phases = all';

%% Voltage change test:

% re-compile, solve:
DSSText.command = char(dirCommand);

DSSText.command = TReg1.DSSCommand;
DSSText.command = TReg2.DSSCommand;
DSSText.command = TReg3.DSSCommand;

DSSText.command = RCReg1.DSSCommand;
DSSText.command = RCReg2.DSSCommand;
DSSText.command = RCReg3.DSSCommand;

DSSSolution.SolveSnap;

% size of connected load is kW=1155 kvar=660

kWRated = 1800;
kWhRated = 1*kWRated;
kWhStored = 1*kWRated;

% add storage element:
DSSText.Command = sprintf('New Storage.N98 Bus1=671.1.2.3 kV=4.16 kWRated=%d kWhRated=%d kWhStored=%d', ...
    kWRated, kWhRated, kWhStored);
DSSText.Command = 'Storage.n98.state=Dischar'; % %discharge=25';

% ^ could also be generation

% Disable all controls
DSSText.command = 'set controlmode=off';
DSSSolution.SolveSnap;

% Compare saved voltages to current case solved
DSSText.command = 'vdiff'; % creates voltage difference file
DSSText.command = 'BusCoords IEEE13Node_BusXY.csv';
DSSText.command = 'set markercode=24 nodewidth=2.5';

% Plot difference in voltage between no-PV and with-PV cases
DSSText.command = 'plot general quantity=1 max=15 min=0 dots=y labels=y object=IEEE13Nodeckt_VDIFF.csv C1=$0000FFFF C2=$000000FF';
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

% EventLog = struct( 'Hour', {}, 'Sec', {}, 'ControlIter', {}, 'Action', {}, ...
%     'Position', {}, 'TapChange', {}, 'Device', {});

% Add loadshape:
% LoadShapeYear = csvread('LoadShape1.csv');
LoadShapeYear = normalize( csvread('LoadShape1.csv'), 'range', [0,1] );
% interpolating 24 hours into 96 x 15min periods;
% in interpolation, index=1 becomes hour=0:
LoadShapeDaily = interp1(1:25,LoadShapeYear(1:25),(1+24/N):(24/N):25);

N = 96;

for nn = 1:N
    tic;
    
    DSSSolution.LoadMult = LoadShapeDaily(nn); % new loadshape per iteration
    
    DSSSolution.Hour = HourInVals(nn); % controlling clock
    DSSSolution.Seconds = SecInVals(nn);
    
    DSSSolution.InitSnap;

    CtrlIter = 0;
    
    while CtrlIter < DSSSolution.MaxControlIterations
        DSSSolution.SolveNoControl;

        TimeElapsed = toc;
        
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
% DSSText.Command = 'Show Powers kva Elements';

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







