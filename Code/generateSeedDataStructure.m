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


g_opts.loadTemporalResolution = 10;
g_opts.forwardTemporalResolution = 10;
g_opts.trainedTemporalResolution = 10;

units = unique(g_trainingAndTestData{1}(:,1));


g_opts.batchSize = 5000;

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

%targetNeurons = units;
analogTraceBatches = 1;
maxNumberOfTrainingSets = 1;
rps = 1;

runnr = 1;
eps = [];
weightDecays = [0.00001];
timeBias = [2];
dropOutRatio = [0.1];

seedNrs = 1; %[1 2 3 4 5 6 7 8 9];

g_opts.epoch = 1;
g_opts.labelNeuron = targetNeuron;
g_opts.inputNeurons = setdiff(g_opts.uniqueNeurons,g_opts.labelNeuron);
g_opts.inputNeurons = [g_opts.inputNeurons g_opts.inputNeurons];            
g_opts.extension.inputNeurons = [g_opts.inputNeurons g_opts.inputNeurons];
g_opts.extension.afterEpochs = 20000;
g_opts.seednr = seedNrs;
g_opts.weightDecay = weightDecays;
g_opts.dropOutRatio = dropOutRatio;
g_opts.negTimeBias = timeBias;
g_opts.posTimeBias = timeBias;
g_opts.learningRate = 0.001;%was 0.001
g_opts.analogTraceBatch = analogTraceBatches;

g_opts.beta1 = 0.9;
g_opts.beta2 = 0.999;
g_opts.optim = @adam;

postFix= [];
postFix = [postFix '_wde' num2str(weightDecays)]; 
postFix = [postFix '_dropout' num2str(dropOutRatio)]; 
postFix = [postFix '_tbias' num2str(timeBias)]; 
postFix = [postFix '_neuron' num2str(g_opts.labelNeuron)];
postFix = [postFix '_trvai' num2str(g_opts.analogTraceBatch)]; 

%g_opts.parameterFile = [resultsPath 'Epoch' num2str(g_opts.epoch) '_Runnr' num2str(runnr) postFix '.mat'];
g_opts.confBeta = 1e-6;
g_opts.runnr = runnr;
[g_opts.nodeArray, nodeIds] = buildNet(g_opts.labelNeuron,g_opts.inputNeurons, g_opts.seednr);


g_opts.nodeIds = nodeIds;
g_opts.updateSelectedNodes = 0;

eps = [eps g_opts.epoch];
optsArray{runnr} = g_opts;
