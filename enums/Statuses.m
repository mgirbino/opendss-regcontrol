classdef Statuses < uint8 % statuses of Queue operations
   enumeration
       READY                        (1)
       ERROR                        (2)
       PENDING_ACTION_COMPLETED     (3)
       CONTROL_ACTIONS_COMPLETED    (4)
   end    
end
