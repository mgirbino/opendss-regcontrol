function LogItem = LogEvent_dss(idx, Hour, Sec, OriginalQueue, AfterExec, ...
    Position, regNames, TapIncrement)
%LOGEVENT_DSS Logs events into readable format
%   Compares the control queue before and after executing control actions
%   to determine which events occurred and must be logged (OriginalQueue
%   and AfterExec)
    LogItem.Hour = Hour;
    LogItem.Sec = Sec;
    LogItem.ControlIter = 1; % might change
    
    allphases = length(regNames);
    
    % CASE 1: Nothing in OriginalQueue (nothing executed) --> log nothing
    % CASE 1a: OriginalQueue matches AfterExec or AfterExec only adds to
    % OriginalQueue (nothing executed either way) --> also log nothing
    if isempty(OriginalQueue{1}) || ...
            ~isempty(AfterExec{1}) && ...
            AfterExec{CtrlQueueFields.Handle}(end) == ...
            OriginalQueue{CtrlQueueFields.Handle}(end)
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
        if isempty(AfterExec{1}) 
            RecentExecuted = OriginalQueue;
        % CASES 3-4 examine overlapping handles:
        % CASE 3: all actions executed (no overlap), some added --> just copy
        % OriginalQueue into RecentExecuted
        elseif AfterExec{CtrlQueueFields.Handle}(end) > ...
                OriginalQueue{CtrlQueueFields.Handle}(1)
            RecentExecuted = OriginalQueue;
        % CASE 4: part of or all of OriginalQueue is inside AfterExec
        % --> get the array index of the first item in OriginalQueue that
        % is not in AfterExec
        else % AfterExec{...}(end) <= OriginalQueue{...}(1) / overlap exists
            for startIdx = 1:size(OriginalQueue{1},1)
                if OriginalQueue{CtrlQueueFields.Handle}(startIdx) < ...
                        AfterExec{CtrlQueueFields.Handle}(end)
                    break;
                end
            end
            
            for field = 1:6
                RecentExecuted{field} = OriginalQueue{field}(startIdx:end);
            end
        end
        
%         floatError = 0.02; % accounts for error in floating-point math
% 
%         % make sure times are consistent with simulation:        
%         CheckTime(Sec, RecentExecuted{CtrlQueueFields.Sec}(1), floatError);
%         %CheckTime(Hour, RecentExecuted{CtrlQueueFields.Hour}(1), floatError);
        
        usedPhases = false(allphases, 1); % keeps track of devices used in events
        
        iter = size(RecentExecuted{1},1);
        for jj = 1:iter
            Device = erase(RecentExecuted{CtrlQueueFields.Device},' ');
            % get the phase/device and mark as used:
            for phase = 1:allphases
                if startsWith(Device{jj}, regNames{phase}, 'IgnoreCase', true)
                    LogItem.Device{jj} = regNames{phase};
                    usedPhases(phase) = true;
                    break;
                end
            end
            % Action:
            switch( uint8(RecentExecuted{CtrlQueueFields.ActionCode}(jj)) )
                case ActionCodes.ACTION_TAPCHANGE
                    LogItem.Action{jj} = 'Tap Change';
                    % Tap Change:
                    if idx > 1
                        % for an unknown reason (may be related to
                        % simulation mode), OpenDSS does not execute every
                        % action that has been removed from the queue, so
                        % the size of the tap change needs to be verified
                        % as nonzero:
                        LogItem.TapChange{jj} = ...
                            (Position(idx,phase) - Position(idx-1,phase))/TapIncrement(phase);
                        if LogItem.TapChange{jj} == 0
                            LogItem.Action{jj} = 'None';
                        end
                    else % assumes starting at 1.0
                        LogItem.TapChange{jj} = ...
                            (Position(idx,phase) - 1.0)/TapIncrement(phase);
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
