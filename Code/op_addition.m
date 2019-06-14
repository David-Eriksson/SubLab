% David Eriksson, 2019

function op_addition( nodenr, timeIndices,command)

% goalNode = input nr 1
% isNode = input nr 2.

global g_opts;
global g_nodeArray;
global g_parameters;
global g_deltaParameters;
global g_activities;
global g_deltaActivities;
global g_trainingAndTestData;

if strcmp(command,'newSession') == 1 % initSession
    % Allocate space
    if ~isfield(g_nodeArray(nodenr),'ais') || isempty(g_nodeArray(nodenr).ais)
        g_nodeArray(nodenr).ais = length(g_activities)+1;
    end    
    
    g_activities{g_nodeArray(nodenr).ais} = zeros(g_nodeArray(nodenr).N,g_opts.nrSamples,g_opts.datatype);
    
    g_deltaActivities{g_nodeArray(nodenr).ais} = zeros(g_nodeArray(nodenr).N,g_opts.nrSamples,g_opts.datatype);
    
elseif strcmp(command,'newBatch') == 1 % initEpoch
    % Allocate space
    
elseif strcmp(command,'forward') == 1
    %forward mode
    
    timeDirs = g_nodeArray(nodenr).dir;
    
    g_activities{g_nodeArray(nodenr).ais}(:,timeIndices) = 0;
    for ini=1:length(g_nodeArray(nodenr).inp)
        node1 = g_nodeArray(nodenr).inp(ini);
    
        n1 = g_activities{g_nodeArray(node1).ais}(:,timeIndices+timeDirs(ini));
    
        g_activities{g_nodeArray(nodenr).ais}(:,timeIndices) = g_activities{g_nodeArray(nodenr).ais}(:,timeIndices) + n1;
    end

    
      
elseif strcmp(command,'backprop') == 1
    
    %backward mode
    
    bp = g_deltaActivities{g_nodeArray(nodenr).ais}(:,timeIndices);
    
    timeDirs = g_nodeArray(nodenr).dir;
    
    for ini=1:length(g_nodeArray(nodenr).inp)
        node1 = g_nodeArray(nodenr).inp(ini);
    
        g_deltaActivities{g_nodeArray(node1).ais}(:,timeIndices+timeDirs(ini)) = g_deltaActivities{g_nodeArray(node1).ais}(:,timeIndices+timeDirs(ini)) + 1*bp;
    end
end




