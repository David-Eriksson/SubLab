% David Eriksson, 2019

clear variables; % Such that debugging can be done as if the script was called as a new octave instance
close all;

warning('off');

global g_opts;
global g_nodeArray;
global g_parameters;
global g_deltaParameters;
global g_activities;
global g_deltaActivities;
global g_trainingAndTestData;
global g_referenceData;
global g_momentum2nd;
global g_momentum1st;
global g_paramAccumT;

%pkg load statistics

try
    OCTAVE_VERSION
    disp('octave is running');
    matlab1_octave0 = 0;
catch
    disp('matlab is running');
    version;
    matlab1_octave0 = 1;
end

try 
    g_nodeArray = [];
    g_parameters = [];
    g_deltaParameters = [];
    g_activities = [];
    g_deltaActivities = [];
    g_momentum2nd = [];
    g_momentum1st = [];
    g_paramAccumT = [];
    g_opts = [];    

    temporalResolution = 1; %1 ms temporal resolution


    fid = fopen(['parallelControlPath.txt'],'r');
    parallelControlPath = char(fread(fid)');
    fclose(fid);


    fid = fopen(['resultsMainPath.txt'],'r');
    resultsMainPath = char(fread(fid)');
    fclose(fid);

    fid = fopen(['fullReconstructionMainPath.txt'],'r');
    fullReconstructionMainPath = char(fread(fid)');
    fclose(fid);
    
    [st, str] = matlabOctaveLs([fullReconstructionMainPath 'TODO\'],matlab1_octave0);
    if isempty(str)
        return;
    end
    
    
    rand('state',round(datenum(clock())*100000000));  %cputime is relative to the start of the instance: useless
    thisJobNr = round(datenum(clock())*100000000);
    fid = fopen([fullReconstructionMainPath 'Running\' num2str(thisJobNr) '.txt'],'w'); fclose(fid);

    currentFolderNumber = 1;
    found = 0;
    while ~found
        try 
            fid = fopen([fullReconstructionMainPath 'TODO\' 'FullReconstructionSessions' num2str(currentFolderNumber) '.txt'],'r');
            trainingDataDir = fscanf(fid,'%s\n');
            fclose(fid);
            found = 1;
        catch
            currentFolderNumber = currentFolderNumber + 1;
        end
    end

    goptsPath = [resultsMainPath trainingDataDir '\'];

    resultsPath = [fullReconstructionMainPath trainingDataDir '\'];
    resultsTODOPath = [resultsPath 'TODO\'];
    mkdir(resultsTODOPath);
    workingPath = [resultsPath 'Working\'];
    mkdir(workingPath);
    errorPath = [resultsPath 'Error\'];
    mkdir(errorPath);
    debugPath = [resultsPath 'Debug\'];
    mkdir(debugPath);

    g_trainingAndTestData = [];
    referenceData = [];
    spikeCount = [];


    tic;

    DataLoaded = 0;

    finishedJobs = 0;
    while ~finishedJobs
        %try

            found = 0;
            while found == 0  
                try
                    %st = dir([resultsTODOPath 'Epoch*']);
                    [st, str] = matlabOctaveLs(resultsTODOPath, matlab1_octave0);
                    found = 1;
                catch
                    found = 0;

                    disp('dir error');
                    pause(1);
                end
            end

            disp('directory extraction');

            startInds = strfind(str,'Epoch');
            stopInds = strfind(str,'.mat');
            st = [];
            for i=1:length(startInds)
                st(i).name = str(startInds(i):(stopInds(i)+3));
            end

            disp('directory extracted');

            if length(st) == 0
                % No more file in this directory
                % Have to load in new data set
                delete([fullReconstructionMainPath 'TODO\' 'FullReconstructionSessions' num2str(currentFolderNumber) '.txt']);
                fid = fopen([fullReconstructionMainPath 'DONE\' trainingDataDir '.txt'],'w'); fclose(fid);

                g_nodeArray = [];
                g_parameters = [];
                g_deltaParameters = [];
                g_activities = [];
                g_deltaActivities = [];
                g_momentum2nd = [];
                g_momentum1st = [];
                g_paramAccumT = [];
                g_opts = [];

                currentFolderNumber = currentFolderNumber + 1;

                try
                    fid = fopen([fullReconstructionMainPath 'TODO\' 'FullReconstructionSessions' num2str(currentFolderNumber) '.txt'],'r');
                    trainingDataDir = fscanf(fid,'%s\n');
                    fclose(fid);
                catch
                    finishedJobs = 1;
                    continue;
                end

                goptsPath = [resultsMainPath trainingDataDir '\'];

                resultsPath = [fullReconstructionMainPath trainingDataDir '\'];
                resultsTODOPath = [resultsPath 'TODO\'];
                workingPath = [resultsPath 'Working\'];
                errorPath = [resultsPath 'ErrorFiles\'];
                debugPath = [resultsPath 'Debug\'];


                g_trainingAndTestData = [];
                referenceData = [];
                spikeCount = [];

                DataLoaded = 0;
                continue;

            end

            i=1;
            currentDirFile = [resultsTODOPath st(i).name];
            while (i<length(st)) && (~exist(currentDirFile))
                i=i+1;
                currentDirFile = [resultsTODOPath st(i).name];
            end

            currentFilePure = st(i).name;
            delete(currentDirFile);

            disp('create files');

            %for debugging

            try
                copyfile([goptsPath currentFilePure],[goptsPath 'temp_' currentFilePure]);
                load([goptsPath 'temp_' currentFilePure],'g_parameters','g_momentum1st','g_momentum2nd','g_paramAccumT','g_opts');
            catch
                delete([goptsPath 'temp_' currentFilePure]);
                disp('file corrupted');
                continue;
            end

            disp(trainingDataDir);
            disp(currentFilePure);

            g_opts.trainedTemporalResolution = 10;
            g_opts.forwardTemporalResolution = temporalResolution;
            g_opts.loadTemporalResolution = temporalResolution;

            if DataLoaded == 0
                LoadTrainingAndTestData;

                DataLoaded = 1;
            end

            g_opts.nrSpikes = size(g_trainingAndTestData{1},1);
            g_opts.recordingSamples = max(g_trainingAndTestData{1}(:,2));
            g_opts.batchSize = g_opts.batchSize*g_opts.trainedTemporalResolution/g_opts.forwardTemporalResolution;
            g_opts.batchSizeOverlap = round(g_opts.batchSize/20);
            g_opts.jumpTime = 100*g_opts.trainedTemporalResolution/g_opts.forwardTemporalResolution;
            g_opts.preJumpTime = 50*g_opts.trainedTemporalResolution/g_opts.forwardTemporalResolution;
            g_opts.nrSamples = g_opts.batchSize+2*g_opts.batchSizeOverlap; % !!!must be divisible with jumpTime!!!;
            g_opts.nrBatches = floor(g_opts.recordingSamples/g_opts.batchSize);
            g_opts.jumpCount = floor(g_opts.nrSamples/g_opts.jumpTime);

            disp('start network specifics');


            g_nodeArray = g_opts.nodeArray;

            % Find non-circular elements
            parseGraphIntoIndependentElements;

            resetIndices = [1];
            for hi=1:length(g_opts.spikeTimeErrors)
                if g_opts.spikeTimeErrors(hi) < min(g_opts.spikeTimeErrors(1:(hi-1)))
                    resetIndices = [resetIndices hi];
                end
            end

            resetIndices = [resetIndices length(g_opts.spikeTimeErrors)];
            disp(['reconstrCorr: ']);


            % Crucial: estimate the number of epochs from the test and validation data set 
            [vs1 hi1] = max(g_opts.reconstrCorr);
            [vs2 hi2] = max(g_opts.reconstrCorr2);
            if isnan(vs1) && isnan(vs2)
                hi = length(g_opts.reconstrCorr);
            elseif isnan(vs1)
                hi = hi2;
            elseif isnan(vs2)
                hi = hi1;
            else
                hi = round((hi1+hi2)/2);
            end

            disp(['Optimal epoch: ' num2str(hi)]);

            % Can be an extended network
            changeParameter('init_seed',hi);
            allocateMemoryForNewSession;

            minErrorEpoch = hi;
            currentEpoch = hi;
            for ni=1:length(g_nodeArray)
                if ~isempty(g_nodeArray(ni).pis)
                    if g_nodeArray(ni).resetWeightsAtUpdateReference == 0
                        for pii=1:length(g_nodeArray(ni).pis)
                            pi = g_nodeArray(ni).pis(pii);
                            [R, C] = size(g_opts.history(minErrorEpoch).parameters{pi});
                            g_parameters{pi}(1:R,1:C) = g_opts.history(minErrorEpoch).parameters{pi};
                            %[mean(g_parameters{pi}(:)) std(g_parameters{pi}(:))]
                        end
                    elseif g_nodeArray(ni).resetWeightsAtUpdateReference == 1
                        for pii=1:length(g_nodeArray(ni).pis)
                            pi = g_nodeArray(ni).pis(pii);
                            [R, C] = size(g_opts.history(currentEpoch).parameters{pi});
                            g_parameters{pi}(1:R,1:C) = g_opts.history(currentEpoch).parameters{pi};
                        end
                    else
                         disp('weight update failed');
                    end
                end
            end

            g_opts.train1test0 = 0; % test means no backprop, and no dropout

            rand('state',1);
            randn('state',1);

            writeFileId = fopen([resultsPath 'Full_' currentFilePure],'w');
            fwrite(writeFileId,length(g_opts.reconstrCorr),'int32');
            fwrite(writeFileId,g_opts.reconstrCorr,'int32');

            reconstruction_full = [];
            spikes_full = [];
            reconstrCorrs = [];
            for bi=1:g_opts.nrBatches
                fprintf('%s ',num2str(bi));
                pause(0.1); % necessary for avoiding display output hanging in the MATLB command window

                batchIndex = bi;
                for ni=1:length(g_nodeArray)
                    g_nodeArray(ni).fromSample = (batchIndex-1)*g_opts.batchSize-g_opts.batchSizeOverlap;
                    g_nodeArray(ni).op(ni,[],'newBatch'); 
                end

                ff_sweep;

                tinds = (1:g_opts.batchSize)+g_opts.batchSizeOverlap;
                reconstruction = g_activities{g_nodeArray(g_opts.nodeIds.subReconstr).ais}(1,tinds);
                spikes = g_activities{g_nodeArray(g_opts.nodeIds.spikesRef).ais}(1,tinds);

                [meanError, reconstrErr, reconstrCorr] = estimateReconstrSpikeAmplitudeError(reconstruction, spikes);
                reconstrCorrs = [reconstrCorrs reconstrCorr];

                if 0    
                    % Do a compression according to up/down state character of data
                    vs = sort(reconstruction);
                    negVal = vs(round(length(vs)*0.01));
                    reconstruction = reconstruction/abs(negVal); 

                    %reconstruction(reconstruction > 0) = 0;
                    %reconstruction(reconstruction < -1) = -1;
                    reconstruction = reconstruction+1;
                    reconstruction = reconstruction*127+64;
                    reconstruction(reconstruction > 255) = 255;
                    reconstruction(reconstruction < 0) = 0;
                    reconstruction = uint8(reconstruction);
                else
                    reconstruction = single(reconstruction);
                end

                if 1
                    fwrite(writeFileId,length(reconstruction),'int32');
                    fwrite(writeFileId,reconstrCorr,'single');
                    fwrite(writeFileId,spikes,'uint8');
                    fwrite(writeFileId,reconstruction,'single');
                else        
                    reconstruction_full = [reconstruction_full reconstruction];
                    spikes_full = [spikes_full spikes];
                end
            end

            reconstrCorr = mean(reconstrCorrs);
            
            fclose(writeFileId);
            movefile([resultsPath 'Full_' currentFilePure],[resultsPath 'Full' num2str(reconstrCorr,2) '_' currentFilePure]);
        
            if exist(parallelControlPath)
                fid = fopen(currentDirFile,'w'); fclose(fid);
                delete([resultsPath 'temp_' currentFilePure]);

                return;
            end

            delete([resultsPath 'temp_' currentFilePure]);
            %catch
        %    msg = lasterror.message;
        %    fid = fopen([errorPath 'error.txt'],'w');
        %    fprintf(fid,'%s',msg);
        %    fclose(fid);
        %end

    end
    
    delete([fullReconstructionMainPath 'Running\' num2str(thisJobNr) '.txt']);

    fid = fopen([errorPath 'error.txt'],'w');
    fprintf(fid,'%s','done.');
    fclose(fid);
catch
    displayLastError();
    
    pause
end