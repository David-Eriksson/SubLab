% David Eriksson, 2019

function [reconstruction_full, spikes_full] = SubLab_Function(spikeData, targetNeuron, maxNumberOfEpochs)


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

g_nodeArray = [];
g_parameters = [];
g_deltaParameters = [];
g_activities = [];
g_deltaActivities = [];
g_momentum2nd = [];
g_momentum1st = [];
g_paramAccumT = [];
g_opts = [];
tic; 

    
g_trainingAndTestData = [];
referenceData = [];
spikeCount = [];
g_opts.loadTemporalResolution = 10;
g_opts.forwardTemporalResolution = 10;


spikes = spikeData;
spikes(2,:) = round(spikeData(2,:)*1000/g_opts.loadTemporalResolution);
g_trainingAndTestData{1} = spikes';

generateSeedDataStructure;

g_nodeArray = g_opts.nodeArray;
nodeIds = g_opts.nodeIds;


% Find non-circular elements
parseGraphIntoIndependentElements;

% Can be an extended network
allocateMemoryForNewSession;

while g_opts.epoch <= maxNumberOfEpochs


    
    % Training and test division
    rand('state',1);
    randn('state',1);

    
    % Choosing train, test, and validation batch indices
    L4 = ceil(g_opts.nrBatches/4);
    g_opts.testBatchIndices = (L4:(L4+L4-1));
    g_opts.validBatchIndices = L4+g_opts.testBatchIndices;
    g_opts.trainBatchIndices = setdiff(1:g_opts.nrBatches, [g_opts.testBatchIndices g_opts.validBatchIndices]);

    
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
        %copySavedParametersToNetwork;

        % Reset flagged parameters if g_opts.updateReference==1
        if g_opts.updateSelectedNodes == 1
            resetSelectedNodes;
        end

    end

    

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

    end
    fprintf('\n');

    

    g_opts.nodeArray = g_nodeArray;

    
    

    % ***************************** Test phase ********************************
    g_opts.train1test0 = 0;
    
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
    if (min(g_opts.spikeTimeErrors) == g_opts.spikeTimeErrors(end)) || (g_opts.epoch==1)
        g_opts.STE2_subReconstr = validSubReconstruct;
    end

    if (min(g_opts.reconstrErrors) == g_opts.reconstrErrors(end)) || (g_opts.epoch==1)
        g_opts.RE2_subReconstr = validSubReconstruct;
    end

    if (max(g_opts.reconstrCorr) == g_opts.reconstrCorr(end)) || (g_opts.epoch==1)
        g_opts.RC2_subReconstr = validSubReconstruct;
    end

    % Check validation for determining if test reconstruction should be stored
    if (min(g_opts.spikeTimeErrors2) == g_opts.spikeTimeErrors2(end)) || (g_opts.epoch==1)
        g_opts.STE_subReconstr = testSubReconstruct;
    end

    if (min(g_opts.reconstrErrors2) == g_opts.reconstrErrors2(end)) || (g_opts.epoch==1)
        g_opts.RE_subReconstr = testSubReconstruct;
    end

    if (max(g_opts.reconstrCorr2) == g_opts.reconstrCorr2(end)) || (g_opts.epoch==1)
        g_opts.RC_subReconstr = testSubReconstruct;
    end
    
    
   

    g_opts.epoch = g_opts.epoch + 1;


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

% Run complete reconstruction
temporalResolution = 1;
g_opts.trainedTemporalResolution = 10;
g_opts.forwardTemporalResolution = temporalResolution;
g_opts.loadTemporalResolution = temporalResolution;

spikes = spikeData;
spikes(2,:) = round(spikeData(2,:)*1000/g_opts.loadTemporalResolution);    
g_trainingAndTestData{1} = spikes';

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

    reconstruction = single(reconstruction);

    reconstruction_full = [reconstruction_full reconstruction];
    spikes_full = [spikes_full spikes];
end
