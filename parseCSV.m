function [ C ] = parseCSV( fileName )
%PARSECSV Extracts numbers and text from CSV file
%   Detailed explanation goes here
    fid = fopen(fileName);
    C = textscan(fid,'%f %f %f %f %f %s',...
    'Delimiter',',','EmptyValue',-Inf,'EndOfLine','\r\n','HeaderLines',1);
    fclose(fid);
end

