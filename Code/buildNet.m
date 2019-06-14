% David Eriksson, 2019

function [nodeArray, nodeIds] = buildNet(labelNeuron,inputNeurons,seednr)

global g_opts;

nodeIds = [];

nodeCount = 0;
nodeArray = [];

backwardPhases = [1];
%forwardPhases = [1]; % Forward phase must be there in order to update activities after a new set of parameters have been loaded.

% ************************ Main net ****************
%recurrentBiasPlasticOrNot = 'constant parameter';
recurrentBiasPlasticOrNot = '';
resetWeightsAtUpdateReference = 0;
finalBiasPlasticOrNot = '';
finalWeightPlasticOrNot = '';
additionFlagStr = '';
dataGen = 0;
additionFlagStr = 'modify bias to fit output firing rate';
%buildBasicSpikeTimingNet;
buildBasicSpikeTimingNet_Nonlinear;

% Fill in ids
nodeIds.biasNode = biasOutputNode;
nodeIds.subReconstr = subReconstrNode;

nodeCount = nodeCount + 1;
goalSpikeNode = nodeCount;
nodeArray(nodeCount).op = @op_inputData;
nodeArray(nodeCount).N = 1;
nodeArray(nodeCount).neuronLabels = labelNeuron;
nodeArray(nodeCount).inp = [0];
nodeArray(nodeCount).dir = [0];
nodeArray(nodeCount).backwardPhases = backwardPhases;
nodeArray(nodeCount).resetWeightsAtUpdateReference = resetWeightsAtUpdateReference;

nodeIds.spikesRef = goalSpikeNode;
if 1
    nodeCount = nodeCount + 1;
    errorNode = nodeCount;
    nodeArray(nodeCount).op = @op_temporalSpikeError; % Temporal error estimation node
    nodeArray(nodeCount).N = 1;
    nodeArray(nodeCount).inp = [goalSpikeNode subReconstrNode];
    nodeArray(nodeCount).dir = [0 0];
    nodeArray(nodeCount).backwardPhases = backwardPhases;
    nodeArray(nodeCount).resetWeightsAtUpdateReference = resetWeightsAtUpdateReference;
    nodeIds.temporalReconstrError = nodeCount;
    nodeIds.errorNode = nodeCount;

    % Should always be based on the best subReconstrNode
    if 0
        nodeCount = nodeCount + 1;
        amplitudeUpperErrorTeachingNode = nodeCount;
        nodeArray(nodeCount).op = @op_amplitudeUpperSpikeError; % Amplitude error estimation node
        nodeArray(nodeCount).N = 1;
        nodeArray(nodeCount).inp = [goalSpikeNode subReconstrNode];
        nodeArray(nodeCount).dir = [0 0];
        nodeArray(nodeCount).backwardPhases = backwardPhases;
        nodeArray(nodeCount).resetWeightsAtUpdateReference = resetWeightsAtUpdateReference;
        nodeIds.goalUpperError = amplitudeUpperErrorTeachingNode;

        nodeCount = nodeCount + 1;
        amplitudeLowerErrorTeachingNode = nodeCount;
        nodeArray(nodeCount).op = @op_amplitudeLowerSpikeError; % Amplitude error estimation node
        nodeArray(nodeCount).N = 1;
        nodeArray(nodeCount).inp = [goalSpikeNode subReconstrNode];
        nodeArray(nodeCount).dir = [0 0];
        nodeArray(nodeCount).backwardPhases = backwardPhases;
        nodeArray(nodeCount).resetWeightsAtUpdateReference = resetWeightsAtUpdateReference;
        nodeIds.goalLowerError = amplitudeLowerErrorTeachingNode;

      end
end
nodeCount = nodeCount + 1;
errorNode = nodeCount;
nodeArray(nodeCount).op = @op_costSpikeTimeCont; % The node that drives backpropagation
nodeArray(nodeCount).N = 1;
nodeArray(nodeCount).inp = [goalSpikeNode subReconstrNode];
nodeArray(nodeCount).dir = [0 0];
nodeArray(nodeCount).backwardPhases = backwardPhases;
nodeArray(nodeCount).resetWeightsAtUpdateReference = resetWeightsAtUpdateReference;

