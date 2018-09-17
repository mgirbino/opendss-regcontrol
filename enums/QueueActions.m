classdef QueueActions < uint8
   enumeration
       PUSH                 (1)
       POP                  (2)
       POP_TIME             (3) % unused because time is included in ActionItem vector
       PEEK                 (4)
       DO_ACTIONS           (5)
       DO_ALL_ACTIONS       (6)
       DO_NEAREST_ACTIONS   (7)
       DO_MULTIRATE         (8)
       DELETE               (9) % added last
   end
end