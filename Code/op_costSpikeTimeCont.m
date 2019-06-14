% David Eriksson, 2019

function op_costSpikeTimeCont( nodenr, timeIndices,command)

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
elseif strcmp(command,'newBatch') == 1 %newBatch
    % Allocate space
elseif strcmp(command,'newEpoch') == 1
    % Reset batch accumulation
    
    %g_opts.timeErrors = [];
    
elseif strcmp(command,'forward') == 1
    %forward mode
        
elseif strcmp(command,'backprop') == 1
    
    %backward mode
    
    goalNode = g_nodeArray(nodenr).inp(1);
    isNode = g_nodeArray(nodenr).inp(2);
    
    goal = g_activities{g_nodeArray(goalNode).ais}(:,timeIndices);
    x = g_activities{g_nodeArray(isNode).ais}(:,timeIndices);
    
    goalSpikes = find(goal==1);
    
    meanTemporalError = 0;
    nSpikes = 0; 
    error_matrix = 0*x;
    amp_error = [];
    shrinkage_correction = 0*x;
    goalSpikes_cont = x*0;
    
    aboveThres = x.*(x>0)+1e-30;
    p = sum(goal)*aboveThres./sum(aboveThres); %probabilityPerBinUnit
    
    goalSpikes_cont = x*0;
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
            
            tLocal = (MinIndex:MaxIndex) - index;
            pLocal = p(MinIndex:MaxIndex);
            %Find resulting spikes between MinIndex and MaxIndex
            %genSpikesCandidates = resSpksInds(find((resSpksInds>=MinIndex).*(resSpksInds<=MaxIndex))); 
            if sum(pLocal) == 0
                avgBestCase = (abs(MinIndex-index)+abs(MaxIndex-index))/2;
                % If there are generated spikes beyond the minIndex:maxIndex window 
                % then we gain avgBestCase if we add a spike at index.
                
                delta_error = -avgBestCase;
                error_matrix(index) = error_matrix(index) + delta_error;
                
                meanTemporalError = meanTemporalError+avgBestCase;
                
                % correct for shrinkage:
                %m = sqrt((sum(x.^2)+2*x(index)*delta_error+delta_error*delta_error)/sum(x.^2))-1;
                
                %shrinkage_correction = shrinkage_correction - m*x;
            else
                %delta_error = -min(abs(genSpikesCandidates-index));
                delta_error = pLocal.*abs(tLocal); % decreasing spiking probability
                error_matrix(index+tLocal) = error_matrix(index+tLocal) + delta_error;
                %delta_error = 0;
                delta_error = -sum(pLocal.*abs(tLocal)); % increase spiking probability
                %delta_error = -mean(pLocal.*abs(tLocal)); % increase spiking probability
                error_matrix(index) = error_matrix(index) + delta_error;
                
                %meanTemporalError = meanTemporalError+sum(abs(genSpikesCandidates-index));
                
                % correct for shrinkage:
                %m = sqrt((sum(x.^2)+2*x(index)*delta_error+delta_error*delta_error)/sum(x.^2))-1;
                
                %shrinkage_correction = shrinkage_correction - m*x;
            end
            
            
            goalSpikes_cont(index) = 1;
            
            nSpikes = nSpikes + 1;
        end
    end
    
    %g_deltaActivities{g_nodeArray(isNode).dais}(:,timeIndices) = error_matrix+shrinkage_correction/(1e-30+abs(sum(shrinkage_correction)))*abs(sum(error_matrix));
    g_deltaActivities{g_nodeArray(isNode).ais}(:,timeIndices) = error_matrix;
    
    %mean(g_deltaActivities{g_nodeArray(isNode).dais}(:,timeIndices))
    %figure(1); clf; plot(g_deltaActivities{g_nodeArray(isNode).dais}(:,timeIndices)); pause;
    %figure(1); clf; plot(x); pause;
       
    
end




