%% Start COM Server

% execute DSSStartup.m
[DSSStartOK, DSSObj, DSSText] = DSSStartup;

if DSSStartOK
    a = 'DSS Started';
    formatSpec = string('Compile (%s\\IEEE13Nodeckt.dss)');
    dirCommand = compose(formatSpec, cd);
    DSSText.command = char(dirCommand);
    % Set up the interface variables
    DSSCircuit=DSSObj.ActiveCircuit;
    DSSSolution=DSSCircuit.Solution;
    DSSControlQueue = DSSCircuit.CtrlQueue;
else
    a = 'DSS Did Not Start';
end

disp(a)

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
DSSText.Command = 'New monitor.Tap1 element=Transformer.Reg1 terminal=2 mode=2';
DSSText.Command = 'New monitor.Tap2 element=Transformer.Reg2 terminal=2 mode=2';
DSSText.Command = 'New monitor.Tap3 element=Transformer.Reg3 terminal=2 mode=2';

% Solve for a daily simulation:
DSSText.Command = 'set mode=daily stepsize=15m number=96 controlmode=time';
% number of solns to perform for Monte Carlo/daily load simulations
DSSText.Command = 'Set number=1';  % Still in Daily mode; each Solve does 15 min

CtrlOps = zeros(10,4,96);
% run for 24 hours:
for i=1:96 % 3rd dimension of Ctrl Ops := # time divisions
    DSSSolution.SolveNoControl;
    DSSSolution.SampleControlDevices;

    len = DSSCircuit.CtrlQueue.QueueSize;
    if len >= 1 % parse the Queue if it isn't empty
        DSSText.Command = 'Show Control Queue'
        CtrlQueueFile = 'C:\Users\Michael Girbino\Documents\13Node Matlab OpenDSS\IEEE13Nodeckt_ControlQueue.csv';  	
        RawQueue = parseCSV(CtrlQueueFile);
        
        % CtrlOps(:,:,i) = [ Time | Handle | ActionCode | Device ]
        CtrlOps(1:len,CtrlOpsFields.Time,i) = RawQueue{CtrlQueueFields.Hour}...
            + RawQueue{CtrlQueueFields.Sec}/3600;
        CtrlOps(1:len,CtrlOpsFields.Handle,i) = RawQueue{CtrlQueueFields.Handle};
        CtrlOps(1:len,CtrlOpsFields.ActionCode,i) = RawQueue{CtrlQueueFields.ActionCode};
        CtrlDev = erase(RawQueue{CtrlQueueFields.Device},' ');
        for i = 1:size(CtrlDev,1)
            switch string(CtrlDev(i,1))
                case 'reg1'
                    CtrlOps(1:len,CtrlOpsFields.Device,i) = Device.Reg1;
                case 'reg2'
                    CtrlOps(1:len,CtrlOpsFields.Device,i) = Device.Reg2;
                case 'reg3'
                    CtrlOps(1:len,CtrlOpsFields.Device,i) = Device.Reg3;
            end
        end
    end
    
    DSSSolution.Solve;
% 
%     DSSText.Command='Buscoords Buscoords.dat   ! load in bus coordinates';
end

DSSText.Command = 'Show Eventlog';

%% Interaction
DSSCircuit.SetActiveElement('Transformer.sub');
xfm1 = DSSCircuit.ActiveCktElement;

VBuffer = (xfm1.Voltages)';
CBuffer = (xfm1.Currents)';


%% Show plots

DSSText.Command = 'Summary';  %show solution summary
% display the result, which should be the solution summary
disp(['Result='  DSSText.Result])

% Feeder Voltage:
DSSText.Command = 'Export monitors feedervoltagecurrent';
MonFileName = DSSText.Result;
MyCSV = csvread(MonFileName, 1, 0);
Time = MyCSV(:,1) + MyCSV(:,2)/3600; % converts cumulative seconds to hours
Volts1 = MyCSV(:,3);
Volts2 = MyCSV(:,5);
Volts3 = MyCSV(:,7);

figure(1);
plot(Time, Volts1,'-k+');  % black *
hold on
plot(Time, Volts2,'-r+');
plot(Time, Volts3,'-b+');
title('Daily Simulation: Feeder Voltage');
ylabel('Volts');
xlabel('Hour');
hold off
% 
% Transformer Taps:
DSSText.Command = 'Export monitors tap1';
MonFileName = DSSText.Result;
MyCSV = csvread(MonFileName, 1, 0);
Time = MyCSV(:,1) + MyCSV(:,2)/3600; % converts cumulative seconds to hours
TapPos1 = MyCSV(:,3);

DSSText.Command = 'Export monitors tap2';
MonFileName = DSSText.Result;
MyCSV = csvread(MonFileName, 1, 0);
TapPos2 = MyCSV(:,3);

DSSText.Command = 'Export monitors tap3';
MonFileName = DSSText.Result;
MyCSV = csvread(MonFileName, 1, 0);
TapPos3 = MyCSV(:,3);

figure(2);
plot(Time, TapPos1,'-k+');  % black *
hold on
plot(Time, TapPos2,'-r+');
plot(Time, TapPos3,'-b+');
title('Daily Simulation: Transformer Taps');
ylabel('Tap Position');
xlabel('Hour');
hold off

reg1tapchange = zeros(96,1);
reg2tapchange = zeros(96,1);
reg3tapchange = zeros(96,1);

reg1reverse = zeros(96,1);
reg2reverse = zeros(96,1);
reg3reverse = zeros(96,1);

% Control Actions:
TimeAxis = squeeze( CtrlOps(1, CtrlOpsFields.Time, 1:96) );
i = 1;
while i <= 96
    j = 1;
    while CtrlOps(j, CtrlOpsFields.Time, i) ~= 0 % while row isn't empty
        switch CtrlOps(j, CtrlOpsFields.Device, i)
            case Device.Reg1
                if CtrlOps(j, CtrlOpsFields.ActionCode, i) == ActionCode.ACTION_TAPCHANGE
                    reg1tapchange(i) = 1;
                elseif CtrlOps(j, CtrlOpsFields.ActionCode, i) == ActionCode.ACTION_REVERSE
                    reg1reverse(i) = 1;
                end
            case Device.Reg2
                if CtrlOps(j, CtrlOpsFields.ActionCode, i) == ActionCode.ACTION_TAPCHANGE
                    reg2tapchange(i) = 2;
                elseif CtrlOps(j, CtrlOpsFields.ActionCode, i) == ActionCode.ACTION_REVERSE
                    reg2reverse(i) = 2;
                end
            case Device.Reg3
                if CtrlOps(j, CtrlOpsFields.ActionCode, i) == ActionCode.ACTION_TAPCHANGE
                    reg3tapchange(i) = 3;
                elseif CtrlOps(j, CtrlOpsFields.ActionCode, i) == ActionCode.ACTION_REVERSE
                    reg3reverse(i) = 3;
                end
        end
        
        j = j + 1;
    end
    i = i + 1;
end
figure(3);
plot(TimeAxis, reg1tapchange,'-k+');  % black *
hold on
plot(TimeAxis, reg2tapchange,'-r+');
plot(TimeAxis, reg3tapchange,'-b+');
title('Tap Change Actions in Control Queue');
ylabel('Regulator');
xlabel('Hour');
hold off



