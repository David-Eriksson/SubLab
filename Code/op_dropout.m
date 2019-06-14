% David Eriksson, 2019

function op_dropout( nodenr, timeIndices,command)

% First dimension is coordinates, Second dimension is datas
global g_opts;
global g_nodeArray;
global g_parameters;
global g_deltaParameters;
global g_activities;
global g_deltaActivities;

if strcmp(command,'newSession') == 1
    % Allocate space
    
    
    g_parameters{length(g_parameters)+1} = [];
    g_nodeArray(nodenr).pis = [length(g_parameters)];
    
    g_deltaParameters{length(g_deltaParameters)+1} = [];
    g_nodeArray(nodenr).dpis = [length(g_deltaParameters)];
    
    g_activities{length(g_activities)+1} = zeros(g_nodeArray(nodenr).N,g_opts.nrSamples,g_opts.datatype);
    g_nodeArray(nodenr).ais = [length(g_activities)];
    
    g_deltaActivities{length(g_deltaActivities)+1} = zeros(g_nodeArray(nodenr).N,g_opts.nrSamples,g_opts.datatype);
    g_nodeArray(nodenr).dais = [length(g_deltaActivities)];
    
elseif strcmp(command,'newBatch') == 1
    rand('state',sum(100*clock));
    randn('state',sum(100*clock));
    
    scale = 1 / (1 - g_nodeArray(nodenr).dropOutRatio);
    if g_opts.train1test0 == 1
        g_parameters{g_nodeArray(nodenr).pis} = scale*(rand(g_nodeArray(nodenr).N,g_opts.nrSamples,g_opts.datatype) > g_nodeArray(nodenr).dropOutRatio);
    else
        g_parameters{g_nodeArray(nodenr).pis} = [];
    end
    
elseif strcmp(command,'forward') == 1
    %forward mode

    inputNode = g_nodeArray(nodenr).inp;
    pi = g_nodeArray(nodenr).pis;
    ai = g_nodeArray(nodenr).ais;
    
    if g_opts.train1test0 == 1
        g_activities{ai}(:,timeIndices) = g_activities{g_nodeArray(inputNode).ais}(:,timeIndices).*g_parameters{g_nodeArray(nodenr).pis}(:,timeIndices);
    else
        g_activities{ai}(:,timeIndices) = g_activities{g_nodeArray(inputNode).ais}(:,timeIndices);
    end
        
elseif strcmp(command,'backprop') == 1
    %backward mode
    
    inputNode = g_nodeArray(nodenr).inp;
    pi = g_nodeArray(nodenr).pis;
    dpi = g_nodeArray(nodenr).dpis;
    dai = g_nodeArray(nodenr).dais;
    
    if g_opts.train1test0 == 1
        g_deltaActivities{g_nodeArray(inputNode).dais}(:,timeIndices) = g_deltaActivities{g_nodeArray(nodenr).dais}(:,timeIndices).*g_parameters{g_nodeArray(nodenr).pis}(:,timeIndices);    
    else
        g_deltaActivities{g_nodeArray(inputNode).dais}(:,timeIndices) = g_deltaActivities{g_nodeArray(nodenr).dais}(:,timeIndices);    
    end
end




