% David Eriksson, 2019

function op_copy( nodenr,timeIndices,command)

% First dimension is coordinates, Second dimension is datas
global g_opts;
global g_nodeArray;
global g_parameters;
global g_deltaParameters;
global g_activities;
global g_deltaActivities;
global g_trainingAndTestData;

if strcmp(command,'newSession') == 1
    g_activities{length(g_activities)+1} = zeros(g_nodeArray(nodenr).N,g_opts.nrSamples,g_opts.datatype);
    g_nodeArray(nodenr).ais = [length(g_activities)];
    
    g_deltaActivities{length(g_deltaActivities)+1} = zeros(g_nodeArray(nodenr).N,g_opts.nrSamples,g_opts.datatype);
    g_nodeArray(nodenr).dais = [length(g_deltaActivities)];
  
elseif strcmp(command,'newBatch') == 1
    
elseif strcmp(command,'forward') == 1
    %forward mode
    timeDirs = g_nodeArray(nodenr).dir;
    inputNode = g_nodeArray(nodenr).inp;
    ft = g_activities{g_nodeArray(inputNode).ais}(:,timeIndices+timeDirs);
    g_activities{g_nodeArray(nodenr).ais}(:,timeIndices) = ft;
    
elseif strcmp(command,'backprop') == 1
    %backward mode
    timeDirs = g_nodeArray(nodenr).dir;
    inputNode = g_nodeArray(nodenr).inp;
    g_deltaActivities{g_nodeArray(inputNode).dais}(:,timeIndices+timeDirs) = g_deltaActivities{g_nodeArray(inputNode).dais}(:,timeIndices+timeDirs) + g_deltaActivities{g_nodeArray(nodenr).dais}(:,timeIndices);
    
end




