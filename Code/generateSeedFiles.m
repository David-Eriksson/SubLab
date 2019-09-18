% David Eriksson, 2019
% Chengxi Ye, 2017, (backprop code was initially written using LightNet)

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

warning('off');

g_nodeArray = [];
g_parameters = [];
g_deltaParameters = [];
g_activities = [];
g_deltaActivities = [];
g_momentum2nd = [];
g_momentum1st = [];
g_paramAccumT = [];
g_opts = [];

try
    OCTAVE_VERSION
    disp('octave is running');
    matlab1_octave0 = 0;
catch
    disp('matlab is running');
    version;
    matlab1_octave0 = 1;
end


fid = fopen(['resultsMainPath.txt'],'r');
resultsMainPath = fscanf(fid,'%s\n');
fclose(fid);

fid = fopen('trainingDataDir.txt','r');
trainingDataDir = fscanf(fid,'%s\n');
fclose(fid);

fid = fopen(['spikesMainPath.txt'],'r');
spikesMainPath = fscanf(fid,'%s\n');
fclose(fid);

resultsPath = [resultsMainPath trainingDataDir '\'];
mkdir(resultsPath);
delete([resultsPath '*']);

resultsTODOPath = [resultsPath 'TODO\'];
mkdir(resultsTODOPath);
delete([resultsTODOPath '*']);

workingPath = [resultsPath 'Working\'];
mkdir(workingPath);
delete([workingPath '*']);

errorPath = [resultsPath 'Error\'];
mkdir(errorPath);

debugPath = [resultsPath 'Debug\'];
mkdir(debugPath);

seedPath = [resultsPath 'Seed\'];
mkdir(seedPath);
                     
g_trainingAndTestData = [];
referenceData = [];

fid = fopen([spikesMainPath trainingDataDir '\TargetNeurons.bin'],'r');
targetNeurons = fread(fid,'int');
fclose(fid);

fid = fopen(['numberOfTrainingSets.txt'],'r');
numberOfTrainingSets = str2num(fscanf(fid,'%s\n'));
fclose(fid);

g_opts.loadTemporalResolution = 10;
g_opts.forwardTemporalResolution = 10;
g_opts.trainedTemporalResolution = 10;
LoadTrainingAndTestData;

units = unique(g_trainingAndTestData{1}(:,1));

fid = fopen(['batchSizeIn10msBins.txt'],'r');
g_opts.batchSize = str2num(fscanf(fid,'%s\n'));
fclose(fid);

g_opts.nrSpikes = size(g_trainingAndTestData{1},1);
g_opts.recordingSamples = max(g_trainingAndTestData{1}(:,2));
g_opts.jumpTime = 100;
g_opts.preJumpTime = 50;
g_opts.uniqueNeurons = units'; 
g_opts.batchSizeOverlap = round(g_opts.batchSize/20);
g_opts.nrSamples = g_opts.batchSize+2*g_opts.batchSizeOverlap; % !!!must be divisible with jumpTime!!!
g_opts.nrBatches = floor(g_opts.recordingSamples/g_opts.batchSize);
g_opts.jumpCount = floor(g_opts.nrSamples/g_opts.jumpTime);
g_opts.datatype = 'single';
g_opts.learningEps = 1e-8;
g_opts.weightDecay = 0.0;
g_opts.spikeTimeErrors = [];
g_opts.spikeTimeErrors2 = [];
g_opts.reconstrErrors = [];
g_opts.reconstrErrors2 = [];
g_opts.reconstrCorr = [];
g_opts.reconstrCorr2 = [];
g_opts.subCorrs = [];
g_opts.subReconstr = [];
g_opts.subReconstrErr = [];
g_opts.subReconstrConf = [];
g_opts.subRef = [];
g_opts.spikesGoal = [];
g_opts.spikesReconstr = [];
g_opts.history = [];
g_opts.adaptationTimeConst = [];
g_opts.lowerErrCounts = [];
g_opts.upperErrCounts = [];
g_opts.goalLowerErrCounts = [];
g_opts.goalUpperErrCounts = [];
g_opts.errorUpperError = [];
g_opts.errorLowerError = [];
g_opts.lowerError = [];
g_opts.upperError = [];
g_opts.relativeError = [];
g_opts.subReconstrMean = [];


optsArray = [];
nodeIds = [];

rand('state',1);
randn('state',1);
analogTraceBatches = 1;
rps = 1;

runnr = 1;
eps = [];
weightDecays = [0.00001];
timeBias = [2];
dropOutRatio = [0.1];
numberOfTrainingSets = 4;


nrBatches = floor(g_opts.recordingSamples/g_opts.batchSize);
if nrBatches < 8
    return;
end
seedNrs = 1; %[1 2 3 4 5 6 7 8 9];
for sei = 1:length(seedNrs)
    for doi = 1:length(dropOutRatio)
        for wdi = 1:length(weightDecays)
            for tbi = 1:length(timeBias)
                for lni = 1:length(targetNeurons)
                    for numberOfTrainingSetsi = 1:numberOfTrainingSets
                      
                        lni
                        g_opts.epoch = 1;
                        g_opts.resultsPath = resultsPath;
                        g_opts.labelNeuron = targetNeurons(lni);
                        g_opts.inputNeurons = setdiff(g_opts.uniqueNeurons,g_opts.labelNeuron);
                        g_opts.inputNeurons = [g_opts.inputNeurons g_opts.inputNeurons];            
                        g_opts.extension.inputNeurons = [g_opts.inputNeurons g_opts.inputNeurons];
                        g_opts.extension.afterEpochs = 20000;
                        g_opts.seednr = seedNrs(sei);
                        g_opts.weightDecay = weightDecays(wdi);
                        g_opts.dropOutRatio = dropOutRatio(doi);
                        g_opts.negTimeBias = timeBias(tbi);
                        g_opts.posTimeBias = timeBias(tbi);
                        g_opts.learningRate = 0.001;%was 0.001
                        
                        if numberOfTrainingSets == 1
                            L4 = ceil(g_opts.nrBatches/4);
                            g_opts.testBatchIndices = (L4:(L4+L4-1));
                            g_opts.validBatchIndices = L4+g_opts.testBatchIndices;
                            g_opts.trainBatchIndices = setdiff(1:g_opts.nrBatches, [g_opts.testBatchIndices g_opts.validBatchIndices]);
                        else
                            L4 = ceil(g_opts.nrBatches/4);
                            offset = (numberOfTrainingSetsi-1)*L4-L4;
                            g_opts.testBatchIndices = (L4:(L4+L4-1));
                            g_opts.validBatchIndices = L4+g_opts.testBatchIndices;
                            g_opts.trainBatchIndices = setdiff(1:g_opts.nrBatches, [g_opts.testBatchIndices g_opts.validBatchIndices]);
                            
                            g_opts.testBatchIndices = mod(offset+g_opts.testBatchIndices-1,g_opts.nrBatches)+1;
                            g_opts.validBatchIndices = mod(offset+g_opts.validBatchIndices-1,g_opts.nrBatches)+1;
                            g_opts.trainBatchIndices = mod(offset+g_opts.trainBatchIndices-1,g_opts.nrBatches)+1;
                        end
                        
                        g_opts.beta1 = 0.9;
                        g_opts.beta2 = 0.999;
                        g_opts.optim = @adam;
                        
                        postFix= [];
                        postFix = [postFix '_wde' num2str(weightDecays(wdi))]; 
                        postFix = [postFix '_dropout' num2str(dropOutRatio(doi))]; 
                        postFix = [postFix '_tbias' num2str(timeBias(tbi))]; 
                        postFix = [postFix '_neuron' num2str(g_opts.labelNeuron)];
                        postFix = [postFix '_trvai' num2str(numberOfTrainingSetsi)]; 
                        
                        
                        g_opts.parameterFile = [resultsPath 'Epoch' num2str(g_opts.epoch) '_Runnr' num2str(runnr) postFix '.mat'];
                        g_opts.confBeta = 1e-6;
                        g_opts.runnr = runnr;
                        [g_opts.nodeArray, nodeIds] = buildNet(g_opts.labelNeuron,g_opts.inputNeurons, g_opts.seednr);

                        
                        g_opts.nodeIds = nodeIds;
                        g_opts.updateSelectedNodes = 0;
                        
                        eps = [eps g_opts.epoch];
                        optsArray{runnr} = g_opts;
                        save(optsArray{runnr}.parameterFile,'g_opts');
                        % Backup seed file for beeing able to restore files
                        save([seedPath 'Epoch' num2str(g_opts.epoch) '_Runnr' num2str(runnr) postFix '.mat'],'g_opts');                        
                        
                        newDirFile = [resultsTODOPath 'Epoch' num2str(g_opts.epoch) '_Runnr' num2str(runnr) postFix '.mat'];
                        fid = fopen(newDirFile,'w'); fclose(fid);
        
                        runnr = runnr + 1;
                    end
                end
            end
        end
          
    end
end
