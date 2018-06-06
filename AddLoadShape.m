function [ DSSCircuit ] = AddLoadShape( DSSCircuit, file, name, npts, interval )
%ADDLOADSHAPE Adds a LoadShape from a CSV to a DSSCircuit
%   Detailed explanation goes here
    DSSText.Command = sprintf('%s%s', 'New LoadShape.', name);
    DSSCircuit.LoadShape.name = name;
    DSSCircuit.LoadShape.npts = npts;
    DSSCircuit.LoadShape.hrinterval = interval;
    ls = csvread(file);
    feature('COM_SafeArraySingleDim',1); % workaround for array formatting
    DSSCircuit.LoadShape.pmult =  ls;
    feature('COM_SafeArraySingleDim',0);
end

