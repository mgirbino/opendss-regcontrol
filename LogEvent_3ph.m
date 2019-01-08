function LogItem = LogEvent_3ph(idx, Hour, Sec, ItemToQueue2D, OriginalQueue, ...
    AfterExec, TapChangesToMake, Positions, regNames, TapIncrements, ControlIter)
%LOGEVENT_3PH Logs events into readable format
%   Compares the control queue before and after executing control actions
%   to determine which events occurred and must be logged (OriginalQueue
%   and AfterExec)
%   Main differences between this and LogEvent_dss: (1) combines
%   ItemToQueue and OriginalQueue (which is from the last iteration) to
%   form how the Queue appeared before AfterExec, (2) operates on matrix
%   representation of the queue, not struct, (3) fields are numbered
%   differently and are enumerated in NewCtrlQueueFields
    LogItem.Hour = Hour;
    LogItem.Sec = Sec;
    LogItem.ControlIter = ControlIter; % might change
    
    allphases = length(regNames);        
    
    % before anything else, need to combine ItemToQueue and OriginalQueue:
    if ~isnan(ItemToQueue2D(1))
        ItemToQueue3D = Make3D(ItemToQueue2D);
        % CASE 1: ItemToQueue exists and OriginalQueue does not
        if isempty_orzero(OriginalQueue)
            OriginalQueue = ItemToQueue3D;
        % CASE 2: Both ItemToQueue and OriginalQueue exist, and
        % OriginalQueue might contain ItemToQueue:
        elseif OriginalQueue(1,NewCtrlQueueFields.Handle,1) < ...
                ItemToQueue3D(NewCtrlQueueFields.Handle)
%             sizeO = size(OriginalQueue);
%             sizeI = size(ItemToQueue);
%             if sizeI(1) > sizeO(1)
%                 tempQ = zeros(sizeI);
%                 tempQ(1:sizeO(1), 1:sizeO(2)) = OriginalQueue;
%                 OriginalQueue = tempQ;
%             elseif sizeO(1) > sizeI(1)
%                 tempQ = zeros(sizeO);
%                 tempQ(1:sizeI(1), 1:sizeI(2)) = ItemToQueue;
%                 ItemToQueue = tempQ;
%             end
            OriginalQueue = cat(3, ItemToQueue3D, OriginalQueue);
        end
    end
    
    OriginalQueue = trimQueue(OriginalQueue);
    
    % CASE 1: Nothing in OriginalQueue (nothing executed) --> log nothing
    % CASE 1a: OriginalQueue matches AfterExec or AfterExec only adds to
    % OriginalQueue (nothing executed either way) --> also log nothing
    if isempty_orzero(OriginalQueue) || isempty_orzero(AfterExec)
        for phase = 1:allphases
            LogItem.Action{phase} = 'None';
            LogItem.TapChange{phase} = 0;
            if idx > 1
                LogItem.Position{phase} = Positions((idx-1),phase);
            else
                LogItem.Position{phase} = 1;
            end
            LogItem.Device{phase} = regNames{phase};
        end          
%     elseif isempty_orzero(OriginalQueue) || ...
%             ~isempty(AfterExec) && ...
%             AfterExec(1,NewCtrlQueueFields.Handle,end) == ...
%             OriginalQueue(1,NewCtrlQueueFields.Handle,end)
%         for phase = 1:allphases
%             LogItem.Action{phase} = 'None';
%             LogItem.TapChange{phase} = 0;
%             LogItem.Position{phase} = Positions(idx,phase);
%             LogItem.Device{phase} = regNames{phase};
%         end            
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
            
        elseif AfterExec(1,NewCtrlQueueFields.Handle,end) == ...
                OriginalQueue(1,NewCtrlQueueFields.Handle,end)
            RecentExecuted = OriginalQueue;
        % CASE 4: part of or all of OriginalQueue is inside AfterExec
        % --> get the array index of the first item in OriginalQueue that
        % is not in AfterExec
        else % AfterExec{...}(end) < OriginalQueue{...}(1) / overlap exists
            for startIdx = 1:size(OriginalQueue,3)
                if OriginalQueue(1,NewCtrlQueueFields.Handle,startIdx) < ...
                        AfterExec(1,NewCtrlQueueFields.Handle,end)
                    break;
                end
            end
            
            RecentExecuted = OriginalQueue(:,:,startIdx:end);
        end
        
        usedPhases = false(allphases, 1); % keeps track of devices used in events
        lastjj = zeros(allphases, 1);
        
        iter = size(RecentExecuted,3);
        for jj = 1:iter
            use_lastjj = false;
            for phase = 1:allphases
            	if endsWith( regNames{phase}, ...
                        string( RecentExecuted(1,NewCtrlQueueFields.Device,jj) ) )
                    break
                end
            end
            
            % if phase has previously been used, might need to refer to
            % previous tap position; condition signified by use_lastjj flag:
            if usedPhases(phase)
                use_lastjj = true;
            else
                lastjj(phase) = jj;
            end
            
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
                        LogItem.TapChange{jj} = TapChangesToMake(phase)/TapIncrements(phase);
%                             (Position(idx,phase) - Position(idx-1,phase))/TapIncrements(phase);
                        if LogItem.TapChange{jj} == 0
                            LogItem.Action{jj} = 'None';
                        end
                    else % assumes starting at 1.0
                        LogItem.TapChange{jj} = TapChangesToMake(phase)/TapIncrements(phase);
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
            if idx > 1
                if ~use_lastjj
                    LogItem.Position{jj} = Positions((idx-1),phase) + TapChangesToMake(phase);
                else
                    LogItem.Position{jj} = LogItem.Position{lastjj(phase)} + TapChangesToMake(phase);
                end
            else
                LogItem.Position{jj} = 1 + TapChangesToMake(phase);
            end
        end
        
        % log nothing for any phases remaining with no actions:
        jj = 1;
        for phase = 1:allphases
            if ~usedPhases(phase)
                LogItem.Action{iter+jj} = 'None';
                LogItem.TapChange{iter+jj} = 0;
                if idx > 1
                    LogItem.Position{iter+jj} = Positions((idx-1),phase);
                else
                    LogItem.Position{iter+jj} = 1;
                end
                LogItem.Device{iter+jj} = regNames{phase};
                jj = jj + 1;
            end
        end
    end
    
    function mat_3d = Make3D(mat_2d)
        % outputs a 1x6x3 matrix from a 3x6x1 matrix        
        mat_3d = zeros(1,6,3);
        for ii = 1:3
            mat_3d(:,:,ii) = mat_2d(ii,:);
        end
    end

    function iez = isempty_orzero(mat_3d)
        iez = isempty(mat_3d) || isequal(mat_3d, zeros(size(mat_3d)));
    end

    function tq = trimQueue(mat_3d)
        tq = mat_3d;
        
        for endIdx = 1:size(mat_3d,3)
            if isequal(mat_3d(:,:,endIdx), zeros(1,6))
                tq = mat_3d( :,:,1:max((endIdx-1),1) );
                break
            end
        end
    end
end
