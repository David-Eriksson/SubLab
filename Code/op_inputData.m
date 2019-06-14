% David Eriksson, 2019

function op_inputData( nodenr, timeIndices,command)

% First dimension is coordinates, Second dimension is datas
global g_opts;
global g_nodeArray;
global g_parameters;
global g_deltaParameters;
global g_activities;
global g_deltaActivities;
global g_trainingAndTestData;

if strcmp(command,'newSession') == 1
    % Allocate space
    g_activities{length(g_activities)+1} = zeros(g_nodeArray(nodenr).N,g_opts.nrSamples,g_opts.datatype);
    g_nodeArray(nodenr).ais = [length(g_activities)];
    
    g_deltaActivities{length(g_deltaActivities)+1} = zeros(g_nodeArray(nodenr).N,g_opts.nrSamples,g_opts.datatype);
    g_nodeArray(nodenr).dais = [length(g_deltaActivities)];
elseif strcmp(command,'newBatch') == 1
    % Load training/test data
    spikes = g_trainingAndTestData{1};
    fromSample = g_nodeArray(nodenr).fromSample;    
    toSample = g_nodeArray(nodenr).fromSample+(g_opts.nrSamples-1);
    spikes = spikes(((spikes(:,2)>fromSample).*(spikes(:,2)<toSample))==1,:);
    
    channels = g_nodeArray(nodenr).neuronLabels;
    g_activities{g_nodeArray(nodenr).ais}(:,:) = 0.0;
    for chi=1:length(channels)
        ch = channels(chi);
        g_activities{g_nodeArray(nodenr).ais}(chi,spikes(spikes(:,1)==ch,2)-fromSample+1) = 1;
    end
elseif strcmp(command,'forward') == 1
    %forward mode

    
elseif strcmp(command,'backprop') == 1    
    %backward mode
    
    
end




