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

% Add loadshape:
LoadShape = csvread('LoadShape1.csv');
LoadNorm = normalize(LoadShape, 'range');

%% Snapshot approximating Daily Simulation:

DSSText.Command = 'set mode=snapshot controlmode=static';

DSSSolution.MaxControlIterations=30;

N = 96;
TimeInVals = (24/N)*3600*( (1:N) - 1 ); % for the purpose of starting at zero
HourInVals = floor(TimeInVals/3600);
SecInVals = TimeInVals - 3600*HourInVals;

TimeOutVals = (24/N)*3600*(1:N); % starts at 0:900
HourOutVals = floor(TimeOutVals/3600);
SecOutVals = TimeInVals - 3600*HourOutVals;

tapPos = zeros(N, length(regNames));
VoltagesInOut = zeros(3,2,N); % 3 phases, 2 terminals, N samples
CurrentsInOut = zeros(3,2,N);

for nn = 1:N
    DSSSolution.LoadMult = LoadNorm(nn); % new loadshape per iteration
    
    DSSSolution.Hour = HourInVals(nn); % controlling clock
    DSSSolution.Seconds = SecInVals(nn);
    
    DSSSolution.InitSnap;

    MyControlIterations = 0;

    while MyControlIterations < DSSSolution.MaxControlIterations
        DSSSolution.SolveNoControl;
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

        if DSSSolution.ControlActionsDone, break, end 

        MyControlIterations = MyControlIterations + 1;
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

%% Daily Simulation:
DSSText.Command = 'set mode=daily stepsize=15m number=1 controlmode=time';

DSSText.Command = 'New LoadShape.LoadShape2a npts=96 interval=0.25';
DSSCircuit.LoadShape.name = 'LoadShape2a';
ls = csvread('LoadShape1.csv');
feature('COM_SafeArraySingleDim',1);
DSSCircuit.LoadShape.pmult =  LoadNorm;
feature('COM_SafeArraySingleDim',0);

% Apply loadshape to daily simulation:
DSSLoads = DSSCircuit.Loads;
iLoad = DSSLoads.First;
while iLoad>0
    DSSLoads.daily = 'LoadShape2a';
    iLoad = DSSLoads.Next;
end

N = 96;
TimeInVals = (24/N)*3600*(1:N);
HourInVals = floor(TimeInVals/3600);
SecInVals = TimeInVals - 3600*HourInVals;

ts = zeros(N,1);

for nn = 1:N
    ts(nn) = DSSSolution.Seconds;
    DSSSolution.Solve; % time starts at zero before solution, is advanced afterward
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

%% Daily analysis:

DSSText.Command = 'set mode=daily';
DSSSolution.Solve;

%% 2-day analysis:

DSSText.Command = 'Set number=1';  % Still in Daily mode, but each Solve does one hour
    
% we'll actually run this for 48 hrs (2 days) to make a more interesting plot 
for i=1:48
    DSSSolution.Solve;
end








