% David Eriksson, 2019

function itemsVec = appendResults(itemsVec) 

global g_opts;
global g_nodeArray;
global g_parameters;
global g_deltaParameters;
global g_activities;
global g_deltaActivities;
global g_trainingAndTestData;
global g_referenceData;
global g_momentum2nd;
global g_momentum1st;
global g_paramAccumT;

tinds = (1:g_opts.batchSize)+g_opts.batchSizeOverlap;

itemsVec.spikesRef = [itemsVec.spikesRef g_activities{g_nodeArray(g_opts.nodeIds.spikesRef).ais}(1,tinds)];
itemsVec.errorVec = [itemsVec.errorVec g_activities{g_nodeArray(g_opts.nodeIds.errorNode).ais}(1,tinds)];
itemsVec.subReconstr = [itemsVec.subReconstr g_activities{g_nodeArray(g_opts.nodeIds.subReconstr).ais}(1,tinds)];
itemsVec.goalLowerErr = [itemsVec.goalLowerErr g_activities{g_nodeArray(g_opts.nodeIds.subReconstr).ais}(1,tinds)];
itemsVec.goalUpperErr = [itemsVec.goalUpperErr g_activities{g_nodeArray(g_opts.nodeIds.subReconstr).ais}(1,tinds)];

