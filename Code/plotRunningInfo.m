function [corrIndices, zscores, timings] = plotRunningInfo(runningInfoPath,matlab1_octave0)
   


runningInfoFiles = systemDir([runningInfoPath],'Runnr','.bin', matlab1_octave0);

corrIndices = zeros(length(runningInfoFiles),1)+NaN;
zscores = zeros(length(runningInfoFiles),1)+NaN;
timings = zeros(length(runningInfoFiles),1)+NaN;

for ri=1:length(runningInfoFiles)
    try % try because runnnig files are removed in the _distr.m
        fid = fopen([runningInfoPath runningInfoFiles(ri).name],'r'); corrs = fread(fid,'double'); fclose(fid);
        corrs = reshape(corrs,[6 size(corrs,1)/6]);
        corrIndices(ri,1:size(corrs,2)) = corrs(1,:);
        zscores(ri,1:size(corrs,2)) = corrs(2,:);
        timings(ri,1:size(corrs,2)) = corrs(3,:);            
    end
end