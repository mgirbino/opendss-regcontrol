function [ numRows ] = getNumRows( fileName )
%GETNUMCOLS returns number of columns in a csv file
%   Detailed explanation goes here
    fid = fopen(fileName, 'rb');
    %# Get file size.
    fseek(fid, 0, 'eof');
    fileSize = ftell(fid);
    frewind(fid);
    %# Read the whole file.
    data = fread(fid, fileSize, 'uint8');
    %# Count number of line-feeds and increase by one.
    numRows = sum(data == 10) + 1;
    fclose(fid);
end

