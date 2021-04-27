% SaveClu(FileName, Fet)
%
% Saves a cluster file from an array -
% i.e. adds a header line at the top.

function Saveres(FileName, res);

outputfile = fopen(FileName,'w');
fprintf(outputfile,'%d\n', res(:));
fclose(outputfile);