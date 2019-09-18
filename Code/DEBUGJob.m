function DEBUGJob(filename,number)
%[resultsMainPath 'LastReadFile\' num2str(thisJobNr) '.txt']
fid = fopen(filename,'w');
fprintf(fid,'%d\n',number);
fclose(fid);