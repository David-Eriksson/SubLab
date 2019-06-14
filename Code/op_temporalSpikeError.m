% David Eriksson, 2019

function op_temporalSpikeError( nodenr, timeIndices,command)

% First dimension is coordinates, Second dimension is datas
global g_opts;
global g_nodeArray;
global g_parameters;
global g_deltaParameters;
global g_activities;
global g_deltaActivities;
global g_trainingAndTestData;

if strcmp(command,'newSession') == 1 %newSession
    % Allocate space
    g_activities{length(g_activities)+1} = zeros(1,g_opts.nrSamples,g_opts.datatype);
    g_nodeArray(nodenr).ais = [length(g_activities)];
    
    g_deltaActivities{length(g_deltaActivities)+1} = zeros(1,g_opts.nrSamples,g_opts.datatype);
    g_nodeArray(nodenr).dais = [length(g_deltaActivities)];
    
    g_opts.timeErrors = [];
elseif strcmp(command,'newBatch') == 1 %newBatch
    % Allocate space
    
elseif strcmp(command,'newEpoch') == 1
    % Reset batch accumulation
    
    %g_opts.timeErrors = [];
    
elseif strcmp(command,'forward') == 1
    %forward mode
    
    goalNode = g_nodeArray(nodenr).inp(1);
    isNode = g_nodeArray(nodenr).inp(2);
    
    goal = g_activities{g_nodeArray(goalNode).ais}(1,timeIndices);
    x = g_activities{g_nodeArray(isNode).ais}(1,timeIndices);
    goalSpikes = find(goal==1);
    
    g_activities{g_nodeArray(nodenr).ais}(1,:) = NaN;
    
    time_errors = [];
    for i = 1:length(goalSpikes)
        index = goalSpikes(i);
        
        if (index > 0) && (index < length(x))
            % Find previous spike
            previousIndex = 1;
            if i>1
                previousIndex = goalSpikes(i-1);
            end
            MinIndex = round((previousIndex+index)/2);
            MinIndex = max([1 MinIndex]);
            
            nextIndex = length(x);
            if i<length(goalSpikes)
                nextIndex = goalSpikes(i+1);
            end
            MaxIndex = round((nextIndex+index)/2);
            MaxIndex = min([length(x) MaxIndex]);
            
            if (i>1) && (i<length(goalSpikes))
                if ((previousIndex+index)/2 > 0) && ((nextIndex+index)/2 <= length(x))
                    [vs peak_index] = max(x(MinIndex:MaxIndex));
                    peak_index = peak_index + MinIndex - 1;
                    min_norm = (index-goalSpikes(i-1))/2;
                    max_norm = (goalSpikes(i+1)-index)/2;
                    norm_error = abs(peak_index - index)/((min_norm*min_norm+max_norm*max_norm)/(min_norm+max_norm));
                    time_errors = [time_errors norm_error];
                    %[goalSpikes(i) norm_error]
                    g_activities{g_nodeArray(nodenr).ais}(1,goalSpikes(i)) = norm_error;
                end
            end
        end
    end
    
    errorVector = g_activities{g_nodeArray(g_opts.nodeIds.errorNode).ais}(1,:);
    nonNaNInds = find(~isnan(errorVector));
    %[nodenr g_opts.nodeIds.errorNode mean(errorVector(nonNaNInds))]

    
    g_opts.timeErrors = [g_opts.timeErrors time_errors];
    
end




