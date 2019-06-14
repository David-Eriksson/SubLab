% David Eriksson, 2019

function copyDependencies2Folder(functionName,destinationFolder)

fs = dir('*.m');

%fname = mfilename();
targetIndex = [];
for fsi=1:length(fs)
    if strcmp(fs(fsi).name(1:(end-2)),functionName) == 1
        targetIndex = fsi;
    end
end

callingIndex = targetIndex;

targetInds = targetIndex;
allVisited = [];
newInds = 1;
while newInds
    newTargetInds = [];
    %deps = zeros(length(fs),length(fs));        
    %for targetIndex = 1:length(fs)
    for ti = 1:length(targetInds)
        targetName = fs(targetInds(ti)).name(1:(end-2));
        fid = fopen([pwd '\' targetName '.m'],'r');
        str = fscanf(fid,'%s');
        fclose(fid);

        for fsi=1:length(fs)
              if ~isempty(strfind(str,fs(fsi).name(1:(end-2))))
                    %fs(fsi).name
                    %deps(targetIndex,fsi) = 1;
                    newTargetInds = [newTargetInds fsi];
              end
        end
    end
    
    rest = setdiff(newTargetInds,allVisited);
    if isempty(rest)
        newInds = 0;
    end
    targetInds = newTargetInds;
    allVisited = union(allVisited, targetInds);
end

allVisited = [allVisited ; callingIndex];

for fsi=1:length(allVisited)
    %copyfile(fs(allVisited(fsi)).name,[destinationFolder fs(allVisited(fsi)).name]);
    system(['cp C:\Users\daffs\Documents\David\SubLab\' fs(allVisited(fsi)).name ' ' [destinationFolder fs(allVisited(fsi)).name]]);
end
%deps