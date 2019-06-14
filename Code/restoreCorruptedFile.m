% David Eriksson, 2019

function restoreCorruptedFile(resultsPath, resultsDirPath, resultsSeedPath, currentFileBase);

delete([resultsPath currentFileBase]);
delete([resultsDirPath currentFileBase]);
inds = strfind(currentFileBase,'_');
postFix = currentFileBase((inds(1)+1):end);
copyfile([resultsSeedPath '*' postFix],resultsPath);
fid = fopen([resultsDirPath 'Epoch1_' postFix],'w'); fclose(fid);