% David Eriksson, 2019

function op_amplitudeLowerSpikeError( nodenr, timeIndices,command)

% Lower means the negactive error that is when the reonstruction goes above threshold in the abscence of a spike. 

global g_opts;
global g_nodeArray;
global g_parameters;
global g_deltaParameters;
global g_activities;
global g_deltaActivities;
global g_trainingAndTestData;

if strcmp(command,'newSession') == 1
    % Allocate space
    g_activities{length(g_activities)+1} = zeros(1,g_opts.nrSamples,g_opts.datatype);
    g_nodeArray(nodenr).ais = [length(g_activities)];
    
    g_deltaActivities{length(g_deltaActivities)+1} = zeros(1,g_opts.nrSamples,g_opts.datatype);
    g_nodeArray(nodenr).dais = [length(g_deltaActivities)];
elseif strcmp(command,'newBatch') == 1
    % Allocate space
    
elseif strcmp(command,'forward') == 1
    %forward mode
    
    filePathNew = [g_opts.resultsPath 'newLower_fromSample' num2str(g_nodeArray(nodenr).fromSample) '_Runnr' num2str(g_opts.runnr) '.mat'];
    filePathBest = [g_opts.resultsPath 'bestLower_fromSample' num2str(g_nodeArray(nodenr).fromSample) '_Runnr' num2str(g_opts.runnr) '.mat'];

    if g_opts.train1test0 == 1    
        % First check if new should replace best activities
        if (g_opts.updateSelectedNodes == 1)  && (exist(filePathNew))
            load(filePathNew,'x');
            save(filePathBest,'x');
        end
    end
    
    spikeNode = g_nodeArray(nodenr).inp(1);
    netNode = g_nodeArray(nodenr).inp(2);
    
    spikes = g_activities{g_nodeArray(spikeNode).ais};
    x = g_activities{g_nodeArray(netNode).ais};
    
    if 1
        starts = find(diff(x>0)==1)+1;
        if x(end) > 0
            starts = starts(1:(end-1));
        end
        
        stops = find(diff(x>0)==-1);
        if x(1) > 0
            stops = stops(2:end);
        end
        
        g_activities{g_nodeArray(nodenr).ais}(:) = NaN;
        for i=1:length(starts)
            inds = starts(i):stops(i);
            if sum(spikes(inds)) > 0
                [vs is] = max(spikes(inds));
                firstSpikeInd = inds(is);
                inds = starts(i):firstSpikeInd;
            end
            
            g_activities{g_nodeArray(nodenr).ais}(inds) = x(inds);
             
        end
        
    else
        % The following code has the problem with error estimation of a burst of spikes
        bias = mean(-x(x<0));
        bias = 0;
        if isempty(bias)
            bias = 0;
        end
        N2 = round(g_opts.ISImode/2);
        effectiveSpikeRegion = conv([zeros(1,N2) spikes zeros(1,N2)],ones(1,g_opts.ISImode))>0;
        effectiveSpikeRegion = effectiveSpikeRegion(N2-1+(1:length(spikes)));
        
        g_activities{g_nodeArray(nodenr).ais} = (effectiveSpikeRegion == 0).*(x+bias).*(x > 0);
        g_activities{g_nodeArray(nodenr).ais}(find(effectiveSpikeRegion > 0)) = NaN;
        
    end
    
    
    if g_opts.train1test0 == 1    
          
        % Save this
        x = g_activities{g_nodeArray(nodenr).ais}(:);
        if ~exist(filePathNew)
            save(filePathBest,'x');
        end
        save(filePathNew,'x');
        
        % Load previous "certified"
        load(filePathBest,'x');
        g_activities{g_nodeArray(nodenr).ais}(:) = x;
    end
elseif strcmp(command,'backprop') == 1
    
    %backward mode
    
end
end




