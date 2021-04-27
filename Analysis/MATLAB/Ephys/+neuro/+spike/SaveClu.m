% SaveClu(FileName, Fet)
%
% Saves a cluster file from an array -
% i.e. adds a header line at the top.

function SaveClu(FileName, Clu);

nClusters = max(Clu);

outputfile = fopen(FileName,'w');
fprintf(outputfile, '%d\n', nClusters);
fprintf(outputfile,'%d\n', Clu(:));
fclose(outputfile);