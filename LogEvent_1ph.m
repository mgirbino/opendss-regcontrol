function LogItem = LogEvent_1ph(idx, Hour, Sec, ItemToQueue, OriginalQueue, ...
    AfterExec, TapChangeToMake, Position, regName, TapIncrement)
%LOGEVENT_1PH Logs events into readable format
%   Compares the control queue before and after executing control actions
%   to determine which events occurred and must be logged (OriginalQueue
%   and AfterExec)
%   Main differences between this and LogEvent_dss: (1) operates on a
%   single phase, so does not require list of regs, (2) combines
%   ItemToQueue and OriginalQueue (which is from the last iteration) to
%   form how the Queue appeared before AfterExec, (3) operates on matrix
%   representation of the queue, not structm, (4) fields are numbered
%   differently and are enumerated in NewCtrlQueueFields
    LogItem.Hour = Hour;
    LogItem.Sec = Sec;
    LogItem.ControlIter = 1; % might change
    
    % idea is to easily adapt to 3-phase mode:
    regNames = {regName};
    allphases = 1;
    TapIncrements = TapIncrement;
    
    % before anything else, need to combine ItemToQueue and OriginalQueue:
    if ~isnan(ItemToQueue(1))
        % CASE 1: ItemToQueue exists and OriginalQueue does not
        if isempty(OriginalQueue)
            OriginalQueue = ItemToQueue;
        % CASE 2: Both ItemToQueue and OriginalQueue exist, and
        % OriginalQueue might contain ItemToQueue:
        elseif OriginalQueue(1,NewCtrlQueueFields.Handle,1) < ...
                ItemToQueue(NewCtrlQueueFields.Handle)
            OriginalQueue = cat(3, ItemToQueue, OriginalQueue);
        end
    end
    
    % CASE 1: Nothing in OriginalQueue (nothing executed) --> log nothing
    % CASE 1a: OriginalQueue matches AfterExec or AfterExec only adds to
    % OriginalQueue (nothing executed either way) --> also log nothing
    if isempty(OriginalQueue) || ...
            ~isempty(AfterExec) && ...
            AfterExec(1,NewCtrlQueueFields.Handle,end) == ...
            OriginalQueue(1,NewCtrlQueueFields.Handle,end)
        for phase = 1:allphases
            LogItem.Action{phase} = 'None';
            LogItem.TapChange{phase} = 0;
            LogItem.Position{phase} = Position(idx,phase);
            LogItem.Device{phase} = regNames{phase};
        end            
    % CASES 2-4: Something executed because OriginalQueue is nonempty
    % and it does not match AfterExec --> put those actions into RecentExecuted
    else
        RecentExecuted = cell(1,6);
        
        % CASE 2: all actions executed, and none added --> just copy
        % OriginalQueue into RecentExecuted
        if isempty(AfterExec) 
            RecentExecuted = OriginalQueue;
        % CASES 3-4 examine overlapping handles:
        % CASE 3: all actions executed (no overlap), some added --> just copy
        % OriginalQueue into RecentExecuted
        elseif AfterExec(1,NewCtrlQueueFields.Handle,end) > ...
                OriginalQueue(1,NewCtrlQueueFields.Handle,1)
            RecentExecuted = OriginalQueue;
        % CASE 4: part of or all of OriginalQueue is inside AfterExec
        % --> get the array index of the first item in OriginalQueue that
        % is not in AfterExec
        else % AfterExec{...}(end) <= OriginalQueue{...}(1) / overlap exists
            for startIdx = 1:size(OriginalQueue,3)
                if OriginalQueue(1,NewCtrlQueueFields.Handle,startIdx) < ...
                        AfterExec(1,NewCtrlQueueFields.Handle,end)
                    break;
                end
            end
            
            RecentExecuted = OriginalQueue(:,:,startIdx:end);
%             for field = 1:6
%                 RecentExecuted{field} = OriginalQueue{field}(startIdx:end);
%             end
        end
        
%         floatError = 0.02; % accounts for error in floating-point math
% 
%         % make sure times are consistent with simulation:        
%         CheckTime(Sec, RecentExecuted{NewCtrlQueueFields.Sec}(1), floatError);
%         %CheckTime(Hour, RecentExecuted{NewCtrlQueueFields.Hour}(1), floatError);
        
        usedPhases = false(allphases, 1); % keeps track of devices used in events
        
        iter = size(RecentExecuted,3);
        for jj = 1:iter
%             Device = RecentExecuted(1,NewCtrlQueueFields.Device,jj);
%             % get the phase/device and mark as used:
%             for phase = 1:allphases
%                 if startsWith(Device{jj}, regNames{phase}, 'IgnoreCase', true)
%                     LogItem.Device{jj} = regNames{phase};
%                     usedPhases(phase) = true;
%                     break;
%                 end
%             end
            phase = 1;
            LogItem.Device{jj} = regNames{phase};
            usedPhases(phase) = true;
            % Action:
            switch( uint8(RecentExecuted(1,NewCtrlQueueFields.ActionCode,jj)) )
                case ActionCodes.ACTION_TAPCHANGE
                    LogItem.Action{jj} = 'Tap Change';
                    % Tap Change:
                    if idx > 1
                        % for an unknown reason (may be related to
                        % simulation mode), OpenDSS does not execute every
                        % action that has been removed from the queue, so
                        % the size of the tap change needs to be verified
                        % as nonzero:
                        LogItem.TapChange{jj} = TapChangeToMake/TapIncrement(phase);
%                             (Position(idx,phase) - Position(idx-1,phase))/TapIncrements(phase);
                        if LogItem.TapChange{jj} == 0
                            LogItem.Action{jj} = 'None';
                        end
                    else % assumes starting at 1.0
                        LogItem.TapChange{jj} = TapChangeToMake/TapIncrement(phase);
%                             (Position(idx,phase) - 1.0)/TapIncrements(phase);
                    end
                case ActionCodes.ACTION_REVERSE
                    LogItem.Action{jj} = 'Reverse';
                    % Tap Change:
                    LogItem.TapChange{jj} = 0;
                otherwise
                    error('ActionCode does not exist')
            end
            
            % Position:
            LogItem.Position{jj} = Position(idx,phase);    
        end
        
        % log nothing for any phases remaining with no actions:
        jj = 1;
        for phase = 1:allphases
            if ~usedPhases(phase)
                LogItem.Action{iter+jj} = 'None';
                LogItem.TapChange{iter+jj} = 0;
                LogItem.Position{iter+jj} = Position(idx,phase);
                LogItem.Device{iter+jj} = regNames{phase};
                jj = jj + 1;
            end
        end
    end
    
%     function CheckTime(t1, t2, erramt)
%         tChk = abs(t2 - t1)/t1;
%         if isnan(tChk) || isinf(tChk) % NaN if zero/zero, Inf if nonzero/zero
%             if ~(t1 < 100 && t2 < 100) % not same order
%                 error('The executed items do not match the current time');
%             end
%         elseif tChk > erramt
%             error('The executed items do not match the current time');
%         end
%     end
end
