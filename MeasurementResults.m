%% Loading data:
normal692_meas = load('reg692_noinj_replog.mat', 'TimeOutVals', 'regWsNames', ...
    'VoltagesInOut', 'RealPowerInOut', 'ReactPowerInOut', 'EventLog');

% system spoofed:
inj692spoof_meas = load('reg692_spoof_inj.mat', 'regWsNames', ...
    'VoltagesInOut', 'RealPowerInOut', 'ReactPowerInOut', 'EventLog');
load692spoof_meas = load('reg692_spoof_load.mat', 'regWsNames', ...
    'VoltagesInOut', 'RealPowerInOut', 'ReactPowerInOut', 'EventLog');

%% Comparing normal conditions to system spoof:

Time = normal692_meas.TimeOutVals/3600; % converts cumulative seconds to hours
leg_text = {'Re(1)', 'Im(1)', 'Re(2)', 'Im(2)', 'Re(3)', 'Im(3)'};

% normal vs inj:
Pout1 = normal692_meas.RealPowerInOut(:,2,:);
Qout1 = normal692_meas.ReactPowerInOut(:,2,:);
figure(10);
subplot(2,1,1);
plot(Time(1:N), Pout1(1,1:N),'-k+');  % black *
hold on
plot(Time(1:N), Qout1(1,1:N),'-k');
plot(Time(1:N), Pout1(2,1:N),'-r+');
plot(Time(1:N), Qout1(2,1:N),'-r');
plot(Time(1:N), Pout1(3,1:N),'-b+');
plot(Time(1:N), Qout1(3,1:N),'-b');
title('Normal Load Conditions: Real and Reactive Powers on Output Terminal');
legend(leg_text, 'Location', 'southeast');
ylabel('Power [kW or kVAR]');
xlabel('Hour');
hold off

Pout2 = inj692spoof_meas.RealPowerInOut(:,2,:);
Qout2 = inj692spoof_meas.ReactPowerInOut(:,2,:);
figure(10);
subplot(2,1,2);
plot(Time(1:N), Pout2(1,1:N),'-k+');  % black *
hold on
plot(Time(1:N), Qout2(1,1:N),'-k');
plot(Time(1:N), Pout2(2,1:N),'-r+');
plot(Time(1:N), Qout2(2,1:N),'-r');
plot(Time(1:N), Pout2(3,1:N),'-b+');
plot(Time(1:N), Qout2(3,1:N),'-b');
title('System Spoof - Power Injection: Real and Reactive Powers on Output Terminal');
legend(leg_text, 'Location', 'southeast');
ylabel('Power [kW or kVAR]');
xlabel('Hour');
hold off

% normal vs load:
figure(11);
subplot(2,1,1);
plot(Time(1:N), Pout1(1,1:N),'-k+');  % black *
hold on
plot(Time(1:N), Qout1(1,1:N),'-k');
plot(Time(1:N), Pout1(2,1:N),'-r+');
plot(Time(1:N), Qout1(2,1:N),'-r');
plot(Time(1:N), Pout1(3,1:N),'-b+');
plot(Time(1:N), Qout1(3,1:N),'-b');
title('Normal Load Conditions: Real and Reactive Powers on Output Terminal');
legend(leg_text, 'Location', 'southeast');
ylabel('Power [kW or kVAR]');
xlabel('Hour');
hold off

Pout4 = load692spoof_meas.RealPowerInOut(:,2,:);
Qout4 = load692spoof_meas.ReactPowerInOut(:,2,:);
figure(11);
subplot(2,1,2);
plot(Time(1:N), Pout4(1,1:N),'-k+');  % black *
hold on
plot(Time(1:N), Qout4(1,1:N),'-k');
plot(Time(1:N), Pout4(2,1:N),'-r+');
plot(Time(1:N), Qout4(2,1:N),'-r');
plot(Time(1:N), Pout4(3,1:N),'-b+');
plot(Time(1:N), Qout4(3,1:N),'-b');
title('System Spoof - Load Connected: Real and Reactive Powers on Output Terminal');
legend(leg_text, 'Location', 'southeast');
ylabel('Power [kW or kVAR]');
xlabel('Hour');
hold off

%% 
figure(1);
plot(Time(1:N), tapPos(1:N,1),'-k+');  % black *
hold on
plot(Time(1:N), tapPos(1:N,2),'-r+');
plot(Time(1:N), tapPos(1:N,3),'-b+');
title('Transformer Taps (Stateflow RegControl Emulation, All Phases)');
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
title('Voltages on Input Terminal (Stateflow RegControl Emulation, All Phases)');
ylabel('Voltage');
xlabel('Hour');
hold off

Vout = VoltagesInOut(:,2,:);
subplot(2,1,2);
plot(Time(1:N), Vout(1,1:N),'-k+');  % black *
hold on
plot(Time(1:N), Vout(2,1:N),'-r+');
plot(Time(1:N), Vout(3,1:N),'-b+');
title('Voltages on Output Terminal (Stateflow RegControl Emulation, All Phases)');
ylabel('Voltage');
xlabel('Hour');
hold off

Pin = normal692_meas.RealPowerInOut(:,1,:);
Qin = normal692_meas.ReactPowerInOut(:,1,:);
figure(10);
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

