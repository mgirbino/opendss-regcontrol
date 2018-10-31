% Queuetest_Sixth multiple-simulation
% Purpose is to test multiple simulations:
% - Parameter inputs and toWorkspace structure outputs
% - ^ for the queue and for handles
% - Different solver modes and their effect on time
% - Logging multiple iterations and single iterations of toWorkspace's

LastHandle = Simulink.Parameter;
LastHandle.DataType = 'double';

TimeInSec = Simulink.Parameter;
TimeInSec.DataType = 'double';

LastQueue = Simulink.Parameter;
LastQueue.DataType = 'double';

N = 3;
simOut = repmat(Simulink.SimulationOutput, N, 1);
% starting values:
LastQueue.Value = zeros(1,5,50);
LastHandle.Value = 1;

QueueTimeLapse = zeros(1,5,50,N);
HandleTimeLapse = zeros(N);

for nn = 1:N
    tic;
    
    % 3 - configure simulation parameters with prior timestep's results:    
    TimeInSec.Value = double( nn*(24/N)*3600 );
    
    if nn > 1 % there exists an output from a prior iteration
        LastHandle.Value = CurrHandle.Data(end); % 1-D vector
        LastQueue.Value = CurrQueue.signals.values(:,:,:,end);
        
        HandleTimeLapse(nn) = LastHandle.Value;
        QueueTimeLapse(:,:,:,nn) = LastQueue.Value;
    end
    
    % 4 - obtain control actions from Simulink:    
    simOut(nn) = sim('queuetest_sixth', 'timeout', 1000);
    
    TimeElapsed = toc;    
    fprintf('Iteration %d, Time = %g\n', nn, TimeElapsed);
end





