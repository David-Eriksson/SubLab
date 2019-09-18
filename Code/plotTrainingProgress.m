function plotTrainingProgress(resultsMainPath,trainingDataDirs,matlab1_octave0)

try
    close all;
    ti = 1;
    while (ti <= length(trainingDataDirs)) && exist([resultsMainPath 'DONE\' trainingDataDirs{ti} '.txt'])
        ti = ti + 1;
    end

    if ti > length(trainingDataDirs)
        ti = length(trainingDataDirs);
    end

    [corrIndices, zscores, timings] = plotRunningInfo([resultsMainPath trainingDataDirs{ti} '\RunningInfo\'],matlab1_octave0);

    figure(1); clf; 

    subplot(1,3,1); plot(corrIndices'); hold on;
    xlabel('Training epoch');
    ylabel('Correlation index');
    subplot(1,3,2); plot(zscores'); hold on;
    xlabel('Training epoch');
    ylabel('Z-score reconstr. at spike is larger than average reconstr.');
    %title('Training progress for all units');
    title(trainingDataDirs{ti});
    subplot(1,3,3); plot(timings'); hold on;
    xlabel('Training epoch');
    ylabel('Peak reconstr. time - true spike time');
end
