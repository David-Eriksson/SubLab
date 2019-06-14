% David Eriksson, 2019

hlen = length(g_opts.history);
g_opts.history(hlen+1).parameters = g_parameters;
g_opts.history(hlen+1).momentum1st = g_momentum1st;
g_opts.history(hlen+1).momentum2nd = g_momentum2nd;

if 0
    errorVector = itemsVec.errorVec;
    nonNaNInds = find(~isnan(errorVector));

    if ~isempty(nonNaNInds)
        g_opts.spikeTimeErrors = [g_opts.spikeTimeErrors mean(errorVector(nonNaNInds))];
    else
        g_opts.spikeTimeErrors = [g_opts.spikeTimeErrors 1];
    end
elseif 0
        [meanError] = estimateReconstrSpikeAmplitudeError(itemsVec.subReconstr, itemsVec.spikesRef);
        g_opts.spikeTimeErrors = [g_opts.spikeTimeErrors meanError];        
end       

net = itemsVec.subReconstr; % For normalization
        
% Error
errorVector = itemsVec.goalLowerErr;
%errorVector = itemsVec.subReconstrLowerErr;
nonNaNInds = find(~isnan(errorVector));
if ~isempty(nonNaNInds)
    g_opts.lowerError = [g_opts.lowerError mean(errorVector(nonNaNInds))/std(net)];
else
    g_opts.lowerError = [g_opts.lowerError 1];
end

errorVector = itemsVec.goalUpperErr;
%errorVector = itemsVec.subReconstrLowerErr;
nonNaNInds = find(~isnan(errorVector));
if ~isempty(nonNaNInds)
    g_opts.upperError = [g_opts.upperError mean(errorVector(nonNaNInds))/std(net)];
else
    g_opts.upperError = [g_opts.upperError 1];
end

if 0
    net = itemsVec.subReconstr;
    g_opts.subReconstrMean = [g_opts.subReconstrMean mean(net)/std(net)];
    if ~isempty(itemsVec.refSynInputs)
        refs = itemsVec.refSynInputs;
    else
        refs = randn(1,length(net))*0;
    end
    N = min([length(net) length(refs)]);
    net = net(1:N);
    refs = refs(1:N);
    R = corrcoef(net,refs);
    g_opts.subCorrs = [g_opts.subCorrs R(2,1)];

    reconstr = itemsVec.subReconstr;
    s = std(reconstr);
    refs = (refs-mean(refs))/std(refs)*s+mean(reconstr);
    
    disp('goal error');
    g_opts.relativeError = [g_opts.relativeError nanmean(itemsVec.goalLowerErr)/mean(abs(reconstr-mean(reconstr)))];
    errLower = nanmean(itemsVec.goalLowerErr);
    errUpper = nanmean(itemsVec.goalLowerErr);
    lowerErrCount = sum((reconstr-refs) > errLower);
    upperErrCount = sum(-(reconstr-refs) > errUpper);
    [lowerErrCount upperErrCount lowerErrCount+upperErrCount]/length(refs)
    g_opts.goalLowerErrCounts = [g_opts.goalLowerErrCounts lowerErrCount/length(refs)];
    g_opts.goalUpperErrCounts = [g_opts.goalUpperErrCounts upperErrCount/length(refs)];
    
    
end




if 0

    %g_opts.adaptationTimeConst = [g_opts.adaptationTimeConst mean(g_parameters{g_nodeArray(g_opts.nodeIds.adaptationTimeConst).pis})];
    %disp('g_opts.adaptationTimeConst');
    %g_opts.adaptationTimeConst

    % ************ subCorrs *******************
    if ~isempty(referenceData)        
        net = g_activities{g_nodeArray(g_opts.nodeIds.subReconstr).ais};
        refs = referenceData.SynInputs(g_opts.labelNeuron,1:10:end);
        N = min([length(net) length(refs)]);
        net = net(1:N);
        refs = refs(1:N);
        R = corrcoef(net,refs);
        g_opts.subCorrs = [g_opts.subCorrs R(2,1)];
    end

    %g_opts.subReconstr = [g_opts.subReconstr ; g_activities{g_nodeArray(g_opts.nodeIds.subReconstr).ais}];
    %g_opts.subReconstrErr = [g_opts.subReconstrErr ; g_activities{g_nodeArray(g_opts.nodeIds.subReconstrErr).ais}];

    if 0
        figure(1); clf;
        subplot(3,1,1);
        hold on;
        plot(g_activities{g_nodeArray(g_opts.nodeIds.subReconstr).ais}+g_activities{g_nodeArray(g_opts.nodeIds.subReconstrErr).ais},'Color',[0.2 1 0.2]); hold on;
        plot(g_activities{g_nodeArray(g_opts.nodeIds.subReconstr).ais}-g_activities{g_nodeArray(g_opts.nodeIds.subReconstrErr).ais},'Color',[0.2 1 0.2]); hold on;
    end

    if ~isempty(g_opts.calibrationScores)
        p_value = 0.05;
        vs = sort(g_opts.calibrationScores);
        alpha_s = vs(round(length(vs)*(1-p_value)));
        
        conf = alpha_s*(g_opts.confBeta+g_activities{g_nodeArray(g_opts.nodeIds.subReconstrErr).ais});
        
        %plot(g_activities{g_nodeArray(12).ais}+conf,'Color',[1 0.2 0.2]); hold on;
        %plot(g_activities{g_nodeArray(12).ais}-conf,'Color',[1 0.2 0.2]); hold on;
    else
        conf = g_activities{g_nodeArray(g_opts.nodeIds.subReconstrErr).ais}*0+NaN;
    end

    g_opts.subReconstrErr = [g_opts.subReconstrErr ; conf];

    if ~isempty(referenceData)    
        g_opts.subRef = [g_opts.subRef ; referenceData.SynInputs(g_opts.labelNeuron,:)];
    end
        
    g_opts.spikesRef = [g_activities{g_nodeArray(g_opts.nodeIds.spikesRef).ais}];

    g_opts.spikesReconstr = [g_opts.spikesReconstr ; [0 diff(g_activities{g_nodeArray(g_opts.nodeIds.subReconstr).ais}>0,[],2)==1]];
end



        

