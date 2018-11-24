function LogItem = LogEvent(QueueTimeLapse, LastQueue, ElementNames, TapChangeToMake, Position)
%LOGEVENT Logs events into readable format
%   Takes Queue Data and 
    LogItem.Hour = HourVals;
    LogItem.Sec = SecVals;
    LogItem.ControlIter = 1; % might change

    iter = LastQueue(1,CtrlQueueFields.Handle,1) - ...
        QueueTimeLapse(1,CtrlQueueFields.Handle,1,end); % difference in handles
                                                        % at top of the queue
    ExecutedActions = QueueTimeLapse(1,:,1:iter,end);

    for ii = 1:iter
        % Element name:
        switch( ExecutedActions(1,CtrlQueueFields.Element,ii) )
            case 1
                LogItem.Element{ii} = RCReg1.ElementName;
            case 2
                LogItem.Element{ii} = RCReg2.ElementName;
            case 3
                LogItem.Element{ii} = RCReg3.ElementName;
        end
        % Action:
        switch( ExecutedActions(1,CtrlQueueFields.ActionCode,ii) )
            case ActionCodes.ACTION_TAPCHANGE
                LogItem.Action{ii} = 'Tap Change';
            case ActionCodes.ACTION_REVERSE
                LogItem.Action{ii} = 'Reverse';
        end
        % Tap Change:
        LogItem.TapChange{ii} = TapChangeToMake(ii);
        % Position:
        LogItem.Position{ii} = xfms.Tap;    
    end
end

