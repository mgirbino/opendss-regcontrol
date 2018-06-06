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
else
    a = 'DSS Did Not Start';
end

disp(a)

%% Run a Daily analysis and plot the voltages at the end of the feeder

% Add loadshape:
DSSText.Command = 'New LoadShape.LoadShape1a npts=96 interval=0.25 mult=(File=LoadShape1.csv)';

% Apply loadshape to daily simulation:
DSSLoads = DSSCircuit.Loads;
iLoad = DSSLoads.First;
while iLoad>0
    DSSLoads.daily = 'LoadShape1a';
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
DSSText.Command = 'set mode=daily stepsize=15m number=96';
DSSSolution.Solve;

%% Show plots

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




