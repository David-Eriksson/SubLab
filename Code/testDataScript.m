% David Eriksson, 2019

itemsVec = [];
itemsVec.errorVec = [];
itemsVec.subReconstr = [];
itemsVec.goalLowerErr = [];
itemsVec.goalUpperErr = [];
itemsVec.spikesRef = [];
itemsVec.refSynInputs = [];


% Test data
for bi=1:length(g_opts.testBatchIndices) 
    batchIndex = g_opts.testBatchIndices(bi);
    for ni=1:length(g_nodeArray)
        g_nodeArray(ni).fromSample = (batchIndex-1)*g_opts.batchSize-g_opts.batchSizeOverlap;
        g_nodeArray(ni).op(ni,[],'newBatch'); 
    end

    ff_sweep;
    
    itemsVec = appendResults(itemsVec);
    
end

if 0
    figure(12); clf;
    pm = [itemsVec.subReconstr*1000 ; itemsVec.spikesRef];
    plot(pm(:,1:10000)');
    title('testDataScript');
    pause;
end
    