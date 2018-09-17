start_len = 10;
queue = zeros(1,4,start_len);
queue(1,4,11) = 1;

t_col = 4;

time = [1:1:10]';
queue(1,t_col,1:10) = time;

q_cand = [1 0 0 9];

% push:
% insert into queue right before item of greater or equal execution time
q_len = size(queue,3);
for ii = 1:q_len
    if q_cand(1,t_col) <= queue(1,t_col,ii)
        temp = queue(:,:,ii:q_len); % remaining items
        queue(:,:,ii) = q_cand;
        queue(:,:, (ii+1):(q_len+1)) = temp;
        break
    end
end

% peek:
% pop without deletion
ActionTime = 3;
q_len = size(queue,3);
for ii = 1:q_len
    if queue(1,t_col,ii) <= ActionTime
        Result = queue(:,:,ii);
        break
    end
end

% pop/pop_time:
% delete from beginning, t<= ActionTime:
ActionTime = 3;
q_len = size(queue,3);
for ii = 1:q_len
    if queue(1,t_col,ii) <= ActionTime
        Result = queue(:,:,ii);
        temp = queue(:,:,(ii+1):q_len);
        queue = queue(:,:,1:(ii-1));
        queue(:,:,ii:(q_len-1)) = temp;
        break
    end
end