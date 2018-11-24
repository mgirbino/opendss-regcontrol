function LogItem = LogEvent_1ph(idx, Hour, Sec, ExecutedTimeLapse, RecentExecuted, ...
    TapChangeToMake, TapIncrement, Position)
%LOGEVENT_1PH Logs events into readable format
%   Compares latest queue with historical queue data to choose how many items to log 
    LogItem.Hour = Hour;
    LogItem.Sec = Sec;
    LogItem.ControlIter = 1; % might change
   
    LastHandle = RecentExecuted(1,NewCtrlQueueFields.Handle, end);
    if isnan(LastHandle)
        error('The last executed action is empty')
    end
    
    if idx > 1
        PriorHandle = ExecutedTimeLapse(1,NewCtrlQueueFields.Handle,(idx - 1));
        if isnan(PriorHandle)
            error('The second last executed action is empty')
        end
    else 
        PriorHandle = 0;
    end
    
    iter = LastHandle - PriorHandle;
    
    switch(iter)
        case 0  % no new changes
            LogItem = LogInner( LogItem );
        case 1  % 1 change made (either pushed earlier or pushed and 
                % executed in the same time step)
            LogItem = LogInner( LogItem, RecentExecuted(:,:,end) );
        case 2  % iter > 1 --> multiple changes, for 1-phase, it's at 
                % most 2 (1 executed on same time step and 1 executed 
                % from an earlier timestep)
            for ii = 1:size(RecentExecuted, 3)
                if RecentExecuted(1,NewCtrlQueueFields.Handle,ii) > PriorHandle && ...
                        RecentExecuted(1,NewCtrlQueueFields.Handle,ii) < LastHandle
                    LogItem = ...
                        LogInner( LogItem, RecentExecuted(:,:,ii), ...
                        RecentExecuted(:,:,end) );
                    break;
                end
            end
        otherwise % may be applicable in 3-phase case
    end
    
    function LogItem = LogInner(LogItem, varargin) % inner function that does the actual logging                                                
        for jj = 1:length(varargin)
            ExecutedAction = varargin{jj};
            % Action:
            switch( uint8(ExecutedAction(1,NewCtrlQueueFields.ActionCode)) )
                case ActionCodes.ACTION_TAPCHANGE
                    LogItem.Action{jj} = 'Tap Change';
                    % Tap Change:
                    LogItem.TapChange{jj} = TapChangeToMake / TapIncrement;
                case ActionCodes.ACTION_REVERSE
                    LogItem.Action{jj} = 'Reverse';
                    % Tap Change:
                    LogItem.TapChange{jj} = 0;
                otherwise
                    error('ActionCode does not exist')
            end
            
            % Position:
            LogItem.Position{jj} = Position;    
        end
        if isempty(varargin) % just LogItem
            LogItem.Action{1} = 'None';
            LogItem.TapChange{1} = 0;
            LogItem.Position{1} = Position; 
        end
    end
end

