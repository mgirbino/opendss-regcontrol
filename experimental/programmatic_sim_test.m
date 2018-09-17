% testing, using stateflowtest.slx, how to run simulations from a script
% and also how to log states from a script

load('in_busa.mat')
load('in_busb.mat')
load('in_busc.mat')

mdl = 'multibus_test';
load_system(mdl)
simMode = get_param(mdl, 'SimulationMode');
set_param(mdl, 'SimulationMode', 'normal')
cs = getActiveConfigSet(mdl);
mdl_cs = cs.copy;
set_param(mdl_cs,'SaveState','on','StateSaveName','xout',...
            'SaveOutput','on','OutputSaveName','yout',...
            'SaveOutput','on','OutputSaveName','yout',...
            'SaveFormat', 'Dataset');
         %'SaveState','on','StateSaveName','xoutNew',         
simOut = sim(mdl, mdl_cs);
outputs = simOut.get('yout');
% errors = simOut.getSimulationMetadata.ExecutionInfo;

%%
N = 10;
simOut = repmat(Simulink.SimulationOutput, N, 1);
for i = 1:N
		simOut(i) = sim('multibus_test', 'timeout', 1000);
end

outputs = simOut(1).get('yout');
x1=(outputs.get('x1').Values);

%%
rt = sfroot;
st1 = rt.find('-isa', 'Stateflow.State', 'Name', 'State1');
st1(1).LoggingInfo.DataLogging = true;
plot(logsout.get('State1').Values);

% simOut.getSimulationMetadata.ModelInfo
% simOut.getSimulationMetadata.TimingInfo
% simOut.getSimulationMetadata.ExecutionInfo

% x1=(outputs.get('x1').Values);
% x2=(outputs.get('x2').Values);
% plot(x1); hold on;
% plot(x2);
% title('VDP States')
% xlabel('Time'); legend('x1','x2')