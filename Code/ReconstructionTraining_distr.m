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
    tic;

    g_nodeArray = [];
    g_parameters = [];
    g_deltaParameters = [];
    g_activities = [];
    g_deltaActivities = [];
    g_momentum2nd = [];
    g_momentum1st = [];
    g_paramAccumT = [];
    g_opts = [];


    fid = fopen(['parallelControlPath.txt'],'r');
    parallelControlPath = char(fread(fid)');
    fclose(fid);
    
    fid = fopen(['maxNumberOfEpochs.txt'],'r');
    maxNumberOfEpochs = str2num(fscanf(fid,'%s\n'));
    fclose(fid);


    fid = fopen(['resultsMainPath.txt'],'r');
    resultsMainPath = char(fread(fid)');
    fclose(fid);

    [st, str] = matlabOctaveLs([resultsMainPath 'TODO\'],matlab1_octave0);
    if isempty(str)
        return;
    end
    currentFolderNumber = 1;
    found = 0;
    while ~found
        try 
            fid = fopen([resultsMainPath 'TODO\' 'trainingDataDir' num2str(currentFolderNumber) '.txt'],'r');
            trainingDataDir = fscanf(fid,'%s\n');
            fclose(fid);
            found = 1;
        catch
            currentFolderNumber = currentFolderNumber + 1;
        end
    end

    resultsPath = [resultsMainPath trainingDataDir '\'];
    resultsTODOPath = [resultsPath 'TODO\'];
    mkdir(resultsTODOPath);
    workingPath = [resultsPath 'Working\'];
    mkdir(workingPath);
    errorPath = [resultsPath 'Error\'];
    mkdir(errorPath);
    debugPath = [resultsPath 'Debug\'];
    mkdir(debugPath);

    rand('state',time*10000000000);  %cputime is relative to the start of the instance: useless
    thisJobNr = round(time*10000000000);
    fid = fopen([resultsMainPath 'Running\' num2str(thisJobNr) '.txt'],'w'); fclose(fid);

    g_trainingAndTestData = [];
    referenceData = [];
    spikeCount = [];
    g_opts.loadTemporalResolution = 10;
    g_opts.forwardTemporalResolution = 10;
    LoadTrainingAndTestData;

    finishedJobs = 0;
    while ~finishedJobs

        disp('directory extraction');
        st = systemDir(resultsTODOPath,'Epoch','.mat', matlab1_octave0);
        disp('directory extracted');

        epochs = [];
        for sti=1:length(st)
            if mod(sti,100) == 0
                %disp(num2str(sti));
            end
            inds = strfind(st(sti).name,'_');
            epoch = str2num(st(sti).name(6:(inds(1)-1)));
            runnr = str2num(st(sti).name((inds(1)+6):(inds(2)-1)));

            workingFile = [resultsPath 'Working' num2str(runnr)];

            if exist(workingFile)
                epoch = 10000;
                %disp(num2str(sti));
            end

            epochs = [epochs ; epoch runnr];
        end

        disp('epoch found');


        [vs oi] = min(epochs(:,1));
        if vs >= maxNumberOfEpochs % stop after maxNumberOfEpochs epochs
            delete([resultsMainPath 'TODO\' 'trainingDataDir' num2str(currentFolderNumber) '.txt']);
            fid = fopen([resultsMainPath 'DONE\' trainingDataDir '.txt'],'w'); fclose(fid);
        end        

        workingFile = [workingPath 'Working' num2str(epochs(oi,2))];        
        vs = 0;
        while exist(workingFile) && (vs < 10000)
            epochs(oi,1) = 10000;        
            [vs oi] = min(epochs(:,1));        
            workingFile = [workingPath 'Working' num2str(epochs(oi,2))];
        end

        if epochs(oi,1) >= maxNumberOfEpochs % stop after maxNumberOfEpochs epochs
            currentFolderNumber = currentFolderNumber + 1;
            try
                fid = fopen([resultsMainPath 'TODO\' 'trainingDataDir' num2str(currentFolderNumber) '.txt'],'r');
                trainingDataDir = fscanf(fid,'%s\n');
                fclose(fid);
            catch
                finishedJobs = 1;
                continue;
            end

            resultsPath = [resultsMainPath trainingDataDir '\'];
            resultsTODOPath = [resultsPath 'TODO\'];
            workingPath = [resultsPath 'Working\'];
            errorPath = [resultsPath 'Error\'];
            debugPath = [resultsPath 'Debug\'];

            g_trainingAndTestData = [];
            referenceData = [];
            spikeCount = [];

            % Load new data 
            LoadTrainingAndTestData;
            continue;
        end

        fid = fopen(workingFile,'w'); fclose(fid);

        currentFileBase = st(oi).name;
        currentFile = [resultsPath currentFileBase];
        currentDirFile = [resultsTODOPath currentFileBase];

        disp('create files');

        %for debugging
        fid = fopen([debugPath 'Working' num2str(epochs(oi,2)) '_Processnr' num2str(thisJobNr) '_Epoch' num2str(epochs(oi,1)+1)],'w'); fclose(fid);

        % Retrieve epoch number
        inds = strfind(currentFileBase,'_');
        epochNr = str2num(currentFileBase(6:(inds(1)-1)));
        runnr = str2num(currentFileBase((inds(1)+6):(inds(2)-1)));
        postFix = currentFileBase((inds(1)+1):end);


        disp(trainingDataDir)
        disp('old file:');
        disp(currentFileBase);
        disp('new file:');    
        newFileFile = ['Epoch' num2str(epochNr+1) '_' postFix];
        disp(newFileFile);

        newFile = [resultsPath newFileFile];
        newDirFile = [resultsTODOPath 'Epoch' num2str(epochNr+1) '_' postFix];    

        errorFile = [errorPath currentFileBase];

        fid = fopen([resultsMainPath 'LastReadFile\' num2str(thisJobNr) '.txt'],'w');
        fprintf(fid,'%s 1',currentFile);
        fclose(fid);

        try
            load(currentFile,'g_parameters','g_momentum1st','g_momentum2nd','g_paramAccumT','g_opts');
        catch
            disp('file corrupted');

            %restoreCorruptedFile(resultsPath, resultsTODOPath, resultsSeedPath, currentFileBase);                

            delete(workingFile);
            continue;
        end

        fid = fopen([resultsMainPath 'LastReadFile\' num2str(thisJobNr) '.txt'],'w');
        fprintf(fid,'%s 2',currentFile);
        fclose(fid);

        disp('start network specifics');

        g_nodeArray = g_opts.nodeArray;
        nodeIds = g_opts.nodeIds;


        % Find non-circular elements
        parseGraphIntoIndependentElements;

        % Can be an extended network
        allocateMemoryForNewSession;

        fid = fopen([resultsMainPath 'LastReadFile\' num2str(thisJobNr) '.txt'],'w');
        fprintf(fid,'%s 3',currentFile);
        fclose(fid);

        % Training and test division
        rand('state',1);
        randn('state',1);

        
        % Choosing train, test, and validation batch indices
        L4 = ceil(g_opts.nrBatches/4);
        g_opts.testBatchIndices = ceil(L4/2):L4:(g_opts.nrBatches-1);
        g_opts.validBatchIndices = g_opts.testBatchIndices+1;
        g_opts.trainBatchIndices = setdiff(1:g_opts.nrBatches, [g_opts.testBatchIndices g_opts.validBatchIndices]);

        fid = fopen([resultsMainPath 'LastReadFile\' num2str(thisJobNr) '.txt'],'w');
        fprintf(fid,'%s 4',currentFile);
        fclose(fid);

        % Fill in parameters
        if g_opts.epoch == 1
            g_opts.train1test0 = 0; % test means no backprop, and no dropout

            % Test data
            testDataScript;

            g_opts.INIT_subReconstr = itemsVec.subReconstr;
            g_opts.spikesRef = itemsVec.spikesRef;

            [meanError, reconstrErr, reconstrCorr] = estimateReconstrSpikeAmplitudeError(itemsVec.subReconstr, itemsVec.spikesRef);
            g_opts.spikeTimeErrors = [g_opts.spikeTimeErrors meanError];
            g_opts.reconstrErrors = [g_opts.reconstrErrors reconstrErr];
            g_opts.reconstrCorr = [g_opts.reconstrCorr reconstrCorr];

            storeVariables;

            % Valid data
            validateDataScript;

            g_opts.INIT2_subReconstr = itemsVec.subReconstr;
            g_opts.spikesRef2 = itemsVec.spikesRef;

            [meanError, reconstrErr, reconstrCorr] = estimateReconstrSpikeAmplitudeError(itemsVec.subReconstr, itemsVec.spikesRef);
            g_opts.spikeTimeErrors2 = [g_opts.spikeTimeErrors2 meanError];
            g_opts.reconstrErrors2 = [g_opts.reconstrErrors2 reconstrErr];
            g_opts.reconstrCorr2 = [g_opts.reconstrCorr2 reconstrCorr];

        else          
            copySavedParametersToNetwork;

            % Reset flagged parameters if g_opts.updateReference==1
            if g_opts.updateSelectedNodes == 1
                resetSelectedNodes;
            end

        end

        fid = fopen([resultsMainPath 'LastReadFile\' num2str(thisJobNr) '.txt'],'w');
        fprintf(fid,'%s 5',currentFile);
        fclose(fid);

        % ************************************** Training *******************************************
        g_opts.train1test0 = 1;
        rand('state',1);
        randn('state',1);
        rps = randperm(length(g_opts.trainBatchIndices));

        fprintf('%s ',num2str(length(rps)));    
        startToc = toc;
        for bi=1:length(rps)
            fprintf('%s ',num2str(bi));
            pause(0.1); % could probably be smaller: is necessary for avoiding display output hanging in the MATLB command window


            batchIndex = g_opts.trainBatchIndices(rps(bi));
            for ni=1:length(g_nodeArray)
                g_nodeArray(ni).fromSample = (batchIndex-1)*g_opts.batchSize;
                g_nodeArray(ni).op(ni,[],'newBatch');
            end

            ff_sweep;

            resetDeltaActivities;

            bp_sweep;


            % Update weights
            g_opts.optim();

            %disp(['Time: ' num2str(toc-startToc)]);
            %startToc = toc;

            if exist(parallelControlPath)
                delete(workingFile);
                return;
            end

        end
        fprintf('\n');

        fid = fopen([resultsMainPath 'LastReadFile\' num2str(thisJobNr) '.txt'],'w');
        fprintf(fid,'%s 6',currentFile);
        fclose(fid);


        g_opts.nodeArray = g_nodeArray;

        if matlab1_octave0
            save(newFile,'g_parameters','g_momentum1st','g_momentum2nd','g_paramAccumT','g_opts');
        else
            save(newFile,'g_parameters','g_momentum1st','g_momentum2nd','g_paramAccumT','g_opts','-text');
        end
        fid = fopen(newDirFile,'w'); fclose(fid);

        fid = fopen([resultsMainPath 'LastReadFile\' num2str(thisJobNr) '.txt'],'w');
        fprintf(fid,'%s 7',currentFile);
        fclose(fid);

        % ***************************** Test phase ********************************
        g_opts.train1test0 = 0;
        allocateMemoryForNewSession;

        % Initialize
        try
            load(newFile,'g_parameters','g_momentum1st','g_momentum2nd','g_paramAccumT');
            fid = fopen(newDirFile,'r'); fclose(fid);
        catch
            fid = fopen(errorFile,'w'); fclose(fid);

            delete(newDirFile);
            delete(newFile);

            delete(workingFile);
            continue;
        end 

        fid = fopen([resultsMainPath 'LastReadFile\' num2str(thisJobNr) '.txt'],'w');
        fprintf(fid,'%s 8',currentFile);
        fclose(fid);


        % Test data
        testDataScript;
        testSubReconstruct = itemsVec.subReconstr;

        [meanError, reconstrErr, reconstrCorr] = estimateReconstrSpikeAmplitudeError(itemsVec.subReconstr, itemsVec.spikesRef);
        g_opts.spikeTimeErrors = [g_opts.spikeTimeErrors meanError];
        g_opts.reconstrErrors = [g_opts.reconstrErrors reconstrErr];
        g_opts.reconstrCorr = [g_opts.reconstrCorr reconstrCorr];

        disp(['reconstrCorr: ' num2str(reconstrCorr)]);
        str = [''];
        for pepi = 1:length(g_opts.reconstrCorr)
            str = [str [num2str(g_opts.reconstrCorr(pepi),2) ' ']];
        end
        disp(str);
        disp('');

        storeVariables;

        % Validation data
        validateDataScript;
        validSubReconstruct = itemsVec.subReconstr;

        [meanError, reconstrErr, reconstrCorr] = estimateReconstrSpikeAmplitudeError(itemsVec.subReconstr, itemsVec.spikesRef);
        g_opts.spikeTimeErrors2 = [g_opts.spikeTimeErrors2 meanError];
        g_opts.reconstrErrors2 = [g_opts.reconstrErrors2 reconstrErr];
        g_opts.reconstrCorr2 = [g_opts.reconstrCorr2 reconstrCorr];

        % Save reconstruction if it is the best so far (cross checking: valid<->test)
        % Check test for determining if validation reconstruction should be stored
        if min(g_opts.spikeTimeErrors) == g_opts.spikeTimeErrors(end)
            g_opts.STE2_subReconstr = validSubReconstruct;
        end

        if min(g_opts.reconstrErrors) == g_opts.reconstrErrors(end)
            g_opts.RE2_subReconstr = validSubReconstruct;
        end

        if max(g_opts.reconstrCorr) == g_opts.reconstrCorr(end)
            g_opts.RC2_subReconstr = validSubReconstruct;
        end

        % Check validation for determining if test reconstruction should be stored
        if min(g_opts.spikeTimeErrors2) == g_opts.spikeTimeErrors2(end)
            g_opts.STE_subReconstr = testSubReconstruct;
        end

        if min(g_opts.reconstrErrors2) == g_opts.reconstrErrors2(end)
            g_opts.RE_subReconstr = testSubReconstruct;
        end

        if max(g_opts.reconstrCorr2) == g_opts.reconstrCorr2(end)
            g_opts.RC_subReconstr = testSubReconstruct;
        end

        fid = fopen([resultsMainPath 'LastReadFile\' num2str(thisJobNr) '.txt'],'w');
        fprintf(fid,'%s 9',currentFile);
        fclose(fid);

        % Is spikeTimeError better than before? In that case
        %if g_opts.spikeTimeErrors(end) < min(g_opts.spikeTimeErrors(1:(end-1)))
        %    g_opts.updateSelectedNodes = 1;
        %else
        %    g_opts.updateSelectedNodes = 0;
        %end

        g_opts.epoch = g_opts.epoch + 1;

        if matlab1_octave0
            save(newFile,'g_parameters','g_momentum1st','g_momentum2nd','g_paramAccumT','g_opts');
        else
            save(newFile,'g_parameters','g_momentum1st','g_momentum2nd','g_paramAccumT','g_opts','-text');
        end
            
            


        % try to load the new file
        try
            load(newFile,'g_parameters','g_momentum1st','g_momentum2nd','g_paramAccumT','g_opts');
            fid = fopen(newDirFile,'r'); fclose(fid);
        catch
            fid = fopen(errorFile,'w'); fclose(fid);

            delete(newDirFile);
            delete(newFile);
            delete(workingFile);
            continue;
        end 

        fid = fopen([resultsMainPath 'LastReadFile\' num2str(thisJobNr) '.txt'],'w');
        fprintf(fid,'%s 10',currentFile);
        fclose(fid);

        % Delete old file
        delete(currentDirFile);

        delete(currentFile);
        delete(workingFile);

        fid = fopen([resultsMainPath 'LastReadFile\' num2str(thisJobNr) '.txt'],'w');
        fprintf(fid,'%s 11',currentFile);
        fclose(fid);



        % **************** Plotting ***********************

        if 0            
            subplot(4,2,1);
            hold on; plot(g_opts.spikeTimeErrors);
            subplot(4,2,2);
            hold on; plot(g_opts.spikeTimeErrors2);
            subplot(4,2,3);
            hold on; plot(g_opts.reconstrErrors);
            subplot(4,2,4);
            hold on; plot(g_opts.reconstrErrors2);
            subplot(4,2,5);
            hold on; plot(g_opts.reconstrCorr);
            subplot(4,2,6);
            hold on; plot(g_opts.reconstrCorr2);
            subplot(4,2,7);
            hold on; plot(g_opts.subCorrs);
        end

    end
    
    delete([resultsMainPath 'Running\' num2str(thisJobNr) '.txt']);
catch
    displayLastError();
    
    pause
end
