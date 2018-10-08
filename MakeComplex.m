function [complexVector] = MakeComplex(realsVector)
%MAKECOMPLEX Ouput vector is half the length and transpose of input vector
%   Converts {voltage, current, power} arrays from OpenDSS, whose items are
%   [real complex ...] into [real+i*complex real+i*complex ...]'
    realsVector = realsVector';    
    complexVector = complex(realsVector(1:2:end), realsVector(2:2:end));
end

