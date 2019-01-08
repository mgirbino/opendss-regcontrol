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
TReg1a = TransformerObj('fNphases', 1, 'bank', "reg1", 'XHL', 0.01, 'kVAs', [1666 1666], ...
    'buses', ["650.1", "RG60.1"], 'kVs', [2.4 2.4], 'pctLoadLoss', 0.01);

TReg1b = TransformerObj('fNphases', 1, 'bank', "reg1", 'XHL', 0.01, 'kVAs', [1666 1666], ...
    'buses', ["650.2", "RG60.2"], 'kVs', [2.4 2.4], 'pctLoadLoss', 0.01);

TReg1c = TransformerObj('fNphases', 1, 'bank', "reg1", 'XHL', 0.01, 'kVAs', [1666 1666], ...
    'buses', ["650.3", "RG60.3"], 'kVs', [2.4 2.4], 'pctLoadLoss', 0.01);

RCReg1a = RegControlObj('ElementName', TReg1a.getName, 'xsfWinding', 2, 'Vreg', 122, ...
    'Bandwidth', 2.0, 'PTRatio', 20, 'CTRating', 700, 'R', 3, 'X', 9);

RCReg1b = RegControlObj('ElementName', TReg1b.getName, 'xsfWinding', 2, 'Vreg', 122, ...
    'Bandwidth', 2.0, 'PTRatio', 20, 'CTRating', 700, 'R', 3, 'X', 9);

RCReg1c = RegControlObj('ElementName', TReg1c.getName, 'xsfWinding', 2, 'Vreg', 122, ...
    'Bandwidth', 2.0, 'PTRatio', 20, 'CTRating', 700, 'R', 3, 'X', 9);

% new regcontrol.Reg1  transformer=Reg1 winding=2  vreg=122  band=2  ptratio=20 ctprim=700  R=3   X=9 !maxtapchange=1

DSSText.command = TReg1a.DSSCommand;
DSSText.command = TReg1b.DSSCommand;
DSSText.command = TReg1c.DSSCommand;

DSSText.command = RCReg1a.DSSCommand;
DSSText.command = RCReg1b.DSSCommand;
DSSText.command = RCReg1c.DSSCommand;

% reversible regulator at 692:

TReg2a = TransformerObj('fNphases', 1, 'bank', "reg2", 'XHL', 0.01, 'kVAs', [1666 1666], ...
    'buses', ["RG61.1", "692.1"], 'kVs', [2.4 2.4], 'pctLoadLoss', 0.01);

TReg2b = TransformerObj('fNphases', 1, 'bank', "reg2", 'XHL', 0.01, 'kVAs', [1666 1666], ...
    'buses', ["RG61.2", "692.2"], 'kVs', [2.4 2.4], 'pctLoadLoss', 0.01);

TReg2c = TransformerObj('fNphases', 1, 'bank', "reg2", 'XHL', 0.01, 'kVAs', [1666 1666], ...
    'buses', ["RG61.3", "692.3"], 'kVs', [2.4 2.4], 'pctLoadLoss', 0.01);

RCReg2a = RegControlObj('ElementName', TReg2a.getName, 'xsfWinding', 2, 'Vreg', 122, ...
    'Bandwidth', 2.0, 'PTRatio', 20, 'CTRating', 700, 'R', 3, 'X', 9, ...
    'IsReversible', true, 'RevVreg', 122, 'ReverseNeutral', false);

RCReg2b = RegControlObj('ElementName', TReg2b.getName, 'xsfWinding', 2, 'Vreg', 122, ...
    'Bandwidth', 2.0, 'PTRatio', 20, 'CTRating', 700, 'R', 3, 'X', 9, ...
    'IsReversible', true, 'RevVreg', 122, 'ReverseNeutral', false);

RCReg2c = RegControlObj('ElementName', TReg2c.getName, 'xsfWinding', 2, 'Vreg', 122, ...
    'Bandwidth', 2.0, 'PTRatio', 20, 'CTRating', 700, 'R', 3, 'X', 9, ...
    'IsReversible', true, 'RevVreg', 122, 'ReverseNeutral', false);

% new regcontrol.Reg1  transformer=Reg1 winding=2  vreg=122  band=2  ptratio=20 ctprim=700  R=3   X=9 !maxtapchange=1

DSSText.command = TReg2a.DSSCommand;
DSSText.command = TReg2b.DSSCommand;
DSSText.command = TReg2c.DSSCommand;

DSSText.command = RCReg2a.DSSCommand;
DSSText.command = RCReg2b.DSSCommand;
DSSText.command = RCReg2c.DSSCommand;

xsfNames = {TReg2a.getName; TReg2b.getName; TReg2c.getName};
regNames = {RCReg2a.getName; RCReg2b.getName; RCReg2c.getName};
xsfIncr = [TReg2a.Winding(RCReg2a.xsfWinding).TapIncrement;
    TReg2b.Winding(RCReg2b.xsfWinding).TapIncrement;
    TReg2c.Winding(RCReg2c.xsfWinding).TapIncrement];

%% Proof of steady-state deviations:
DSSText.command = char(dirCommand);

DSSText.command = TReg1a.DSSCommand;
DSSText.command = TReg1b.DSSCommand;
DSSText.command = TReg1c.DSSCommand;

DSSText.command = RCReg1a.DSSCommand;
DSSText.command = RCReg1b.DSSCommand;
DSSText.command = RCReg1c.DSSCommand;

DSSText.command = TReg2a.DSSCommand;
DSSText.command = TReg2b.DSSCommand;
DSSText.command = TReg2c.DSSCommand;

DSSText.command = RCReg2a.DSSCommand;
DSSText.command = RCReg2b.DSSCommand;
DSSText.command = RCReg2c.DSSCommand;

DSSSolution.LoadMult = 1;
DSSText.command = 'Solve';
DSSText.command = 'BusCoords IEEE13Node_BusXY_2.csv';

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

DSSText.command = TReg1a.DSSCommand;
DSSText.command = TReg1b.DSSCommand;
DSSText.command = TReg1c.DSSCommand;

DSSText.command = RCReg1a.DSSCommand;
DSSText.command = RCReg1b.DSSCommand;
DSSText.command = RCReg1c.DSSCommand;

DSSText.command = TReg2a.DSSCommand;
DSSText.command = TReg2b.DSSCommand;
DSSText.command = TReg2c.DSSCommand;

DSSText.command = RCReg2a.DSSCommand;
DSSText.command = RCReg2b.DSSCommand;
DSSText.command = RCReg2c.DSSCommand;

DSSSolution.SolveSnap;

% size of connected load is kW=1155 kvar=660

kWRated = 600;
kWhRated = 1*kWRated;
kWhStored = 1*kWRated;

% add storage element:
DSSText.Command = sprintf('New Storage.N98 Bus1=675.1.2.3 kV=2.4 kWRated=%d kWhRated=%d kWhStored=%d', ...
    kWRated, kWhRated, kWhStored);
DSSText.Command = 'Storage.n98.state=Dischar'; % %discharge=25';

% Disable all controls
DSSText.command = 'set controlmode=off';
DSSSolution.SolveSnap;

% Compare saved voltages to current case solved
DSSText.command = 'vdiff'; % creates voltage difference file
DSSText.command = 'BusCoords IEEE13Node_BusXY_2.csv';
DSSText.command = 'set markercode=24 nodewidth=2.5';

% Plot difference in voltage between no-PV and with-PV cases
DSSText.command = 'plot general quantity=1 max=15 min=0 dots=y labels=y object=IEEE13Nodeckt_VDIFF.csv C1=$0000FFFF C2=$000000FF';

%% Voltage change test:

% re-compile, solve:
DSSText.command = char(dirCommand);

DSSText.command = TReg1a.DSSCommand;
DSSText.command = TReg1b.DSSCommand;
DSSText.command = TReg1c.DSSCommand;

DSSText.command = RCReg1a.DSSCommand;
DSSText.command = RCReg1b.DSSCommand;
DSSText.command = RCReg1c.DSSCommand;

DSSText.command = TReg2a.DSSCommand;
DSSText.command = TReg2b.DSSCommand;
DSSText.command = TReg2c.DSSCommand;

DSSText.command = RCReg2a.DSSCommand;
DSSText.command = RCReg2b.DSSCommand;
DSSText.command = RCReg2c.DSSCommand;

kWRated = 600;
kWhRated = 1*kWRated;
kWhStored = 1*kWRated;

% add storage element:
DSSText.Command = sprintf('New Storage.N98 Bus1=675.1.2.3 kV=2.4 kWRated=%d kWhRated=%d kWhStored=%d', ...
    kWRated, kWhRated, kWhStored);
DSSText.Command = 'Storage.n98.state=Dischar'; % %discharge=25';

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

Pin = RealPowerInOut(:,1,:);
Qin = ReactPowerInOut(:,1,:);
figure(4);
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
figure(4);
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


% DSSMon = DSSCircuit.Monitors;
% DSSMon.name='P4a';
% t_pow = ExtractMonitorData(DSSMon,0,3600.0);
% Powers1 = ExtractMonitorData(DSSMon,1,1.0);
% 
% DSSMon.name='P4b';
% Powers2 = ExtractMonitorData(DSSMon,1,1.0);
% DSSMon.name='P4c';
% Powers3 = ExtractMonitorData(DSSMon,1,1.0);

% figure(4);
% plot(t_pow, Powers1,'-k');
% hold on;
% plot(t_pow, Powers2, '-r');
% plot(t_pow, Powers3, '-b');
% % plot(t, Q,'-r');
% % legend('P','Q','Location','SouthEast');
% title('Real Power Fluctuation');
% ylabel('[kW]');
% xlabel('Time [hr]');    
% hold off

% DSSText.Command = 'Plot monitor object= p4a channels=(1 )';







