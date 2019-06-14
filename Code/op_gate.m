% David Eriksson, 2019

function op_gate( nodenr,timeIndices,command)

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
    
elseif strcmp(command,'forward') == 1
    %forward mode

    nodeInfo = g_nodeArray(nodenr);
    
    inputNodes = g_nodeArray(nodenr).inp;
    timeDirs = g_nodeArray(nodenr).dir;
    
        
    ft = g_activities{g_nodeArray(inputNodes(1)).ais}(:,timeIndices+timeDirs(1));
    htm = g_activities{g_nodeArray(inputNodes(2)).ais}(:,timeIndices+timeDirs(2));
    xt = g_activities{g_nodeArray(inputNodes(3)).ais}(:,timeIndices+timeDirs(3));
    
    ft = 1-((1-ft)*g_opts.forwardTemporalResolution/g_opts.trainedTemporalResolution);
    
    %g_activities{nodeInfo.ais}(:,timeIndices) = ft.*htm+(1-ft).*xt;
    g_activities{nodeInfo.ais}(:,timeIndices) = ft.*htm+(1-ft).*xt;
    
elseif strcmp(command,'backprop') == 1
    %backward mode
    
    nodeInfo = g_nodeArray(nodenr);
    
    inputNodes = g_nodeArray(nodenr).inp;
    timeDirs = g_nodeArray(nodenr).dir;
            
    ft = g_activities{g_nodeArray(inputNodes(1)).ais}(:,timeIndices+timeDirs(1));
    htm = g_activities{g_nodeArray(inputNodes(2)).ais}(:,timeIndices+timeDirs(2));
    xt = g_activities{g_nodeArray(inputNodes(3)).ais}(:,timeIndices+timeDirs(3));
    
    input_dai1 = g_nodeArray(inputNodes(1)).dais;
    input_dai2 = g_nodeArray(inputNodes(2)).dais;
    input_dai3 = g_nodeArray(inputNodes(3)).dais;
    
    
    g_deltaActivities{input_dai1}(:,timeIndices+timeDirs(1)) = g_deltaActivities{input_dai1}(:,timeIndices+timeDirs(1)) + ( htm - xt ).*g_deltaActivities{nodeInfo.dais}(:,timeIndices);
    g_deltaActivities{input_dai2}(:,timeIndices+timeDirs(2)) = g_deltaActivities{input_dai2}(:,timeIndices+timeDirs(2)) + ft.*g_deltaActivities{nodeInfo.dais}(:,timeIndices);
    g_deltaActivities{input_dai3}(:,timeIndices+timeDirs(3)) = g_deltaActivities{input_dai3}(:,timeIndices+timeDirs(3)) + ( 1 - ft ).*g_deltaActivities{nodeInfo.dais}(:,timeIndices);
    
end




