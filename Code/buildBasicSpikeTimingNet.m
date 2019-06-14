% David Eriksson, 2019

nodeCount = nodeCount + 1;
dataNode = nodeCount;
nodeArray(nodeCount).op = @op_inputData;
nodeArray(nodeCount).N = length(inputNeurons);
nodeArray(nodeCount).neuronLabels = inputNeurons;
nodeArray(nodeCount).inp = [0];
nodeArray(nodeCount).dir = [0];

nodeCount = nodeCount + 1;
inNode = nodeCount;
nodeArray(nodeCount).op = @op_dropout;
nodeArray(nodeCount).N = length(inputNeurons);
nodeArray(nodeCount).dropOutRatio = g_opts.dropOutRatio;
nodeArray(nodeCount).inp = [dataNode];
nodeArray(nodeCount).dir = [0];

% bidir neg
nodeCount = nodeCount + 1;
biasNode = nodeCount;
nodeArray(nodeCount).op = @op_bias;
nodeArray(nodeCount).N = length(inputNeurons);
nodeArray(nodeCount).initFromFile = []; %{'Init_Causal'};
nodeArray(nodeCount).init_seed = seednr;
nodeArray(nodeCount).init_m = 1;
nodeArray(nodeCount).init_s = 0.01;
nodeArray(nodeCount).inp = [0];
nodeArray(nodeCount).dir = [0];
nodeArray(nodeCount).pla = {recurrentBiasPlasticOrNot};


nodeCount = nodeCount + 1;
sigmNode = nodeCount;
nodeArray(nodeCount).op = @op_sigmoid;
nodeArray(nodeCount).N = length(inputNeurons);
nodeArray(nodeCount).inp = [biasNode];
nodeArray(nodeCount).dir = [0];

nodeCount = nodeCount + 1;
gateNode = nodeCount;
copyNode = nodeCount + 1; % Just for referencing
nodeArray(nodeCount).op = @op_gate;
nodeArray(nodeCount).N = length(inputNeurons);
nodeArray(nodeCount).inp = [sigmNode copyNode inNode];
nodeArray(nodeCount).dir = [0 -1 0];

nodeCount = nodeCount + 1;
nodeArray(nodeCount).op = @op_copy;
nodeArray(nodeCount).N = length(inputNeurons);
nodeArray(nodeCount).inp = [gateNode];
nodeArray(nodeCount).dir = [0];

% bidir pos
nodeCount = nodeCount + 1;
biasNode2 = nodeCount;
nodeArray(nodeCount).op = @op_bias;
nodeArray(nodeCount).N = length(inputNeurons);
nodeArray(nodeCount).initFromFile = []; %{'Init_ACausal'};
nodeArray(nodeCount).init_seed = seednr;
nodeArray(nodeCount).init_m = 1;
nodeArray(nodeCount).init_s = 0.01;
nodeArray(nodeCount).inp = [0];
nodeArray(nodeCount).dir = [0];
nodeArray(nodeCount).pla = {recurrentBiasPlasticOrNot};


nodeCount = nodeCount + 1;
sigmNode2 = nodeCount;
nodeArray(nodeCount).op = @op_sigmoid;
nodeArray(nodeCount).N = length(inputNeurons);
nodeArray(nodeCount).inp = [biasNode2];
nodeArray(nodeCount).dir = [0];

nodeCount = nodeCount + 1;
gateNode2 = nodeCount;
copyNode2 = nodeCount + 1; % Just for referencing
nodeArray(nodeCount).op = @op_gate;
nodeArray(nodeCount).N = length(inputNeurons);
nodeArray(nodeCount).inp = [sigmNode2 copyNode2 inNode];
nodeArray(nodeCount).dir = [0 1 0];

nodeCount = nodeCount + 1;
nodeArray(nodeCount).op = @op_copy;
nodeArray(nodeCount).N = length(inputNeurons);
nodeArray(nodeCount).inp = [gateNode2];
nodeArray(nodeCount).dir = [0];
% bidir end

nodeCount = nodeCount + 1;
mainWeightsNode = nodeCount;
nodeArray(nodeCount).op = @op_weight;
nodeArray(nodeCount).initFromFile = []; %{'PreNorm_Init_Causal', 'PreNorm_Init_ACausal'};
nodeArray(nodeCount).init_seed = seednr;
nodeArray(nodeCount).init_m = 0;
nodeArray(nodeCount).init_s = 0.1;
nodeArray(nodeCount).N = 1;
nodeArray(nodeCount).inp = [gateNode gateNode2];
nodeArray(nodeCount).dir = [0 0];
nodeArray(nodeCount).pla = {finalWeightPlasticOrNot, finalWeightPlasticOrNot};

% Add bias for the final stage
nodeCount = nodeCount + 1;
biasOutputNode = nodeCount;
nodeArray(nodeCount).op = @op_bias;
nodeArray(nodeCount).N = 1;
nodeArray(nodeCount).init_seed = seednr;
nodeArray(nodeCount).init_m = -1;
nodeArray(nodeCount).init_s = 0.01
nodeArray(nodeCount).inp = [0];
nodeArray(nodeCount).dir = [0];
nodeArray(nodeCount).pla = {finalBiasPlasticOrNot};
nodeArray(nodeCount).flagStr = additionFlagStr;

nodeCount = nodeCount + 1;
biasWeightNode = nodeCount;
nodeArray(nodeCount).op = @op_addition;
nodeArray(nodeCount).N = 1;
nodeArray(nodeCount).inp = [biasOutputNode mainWeightsNode];
nodeArray(nodeCount).dir = [0 0];
nodeArray(nodeCount).dataGen = dataGen;
nodeArray(nodeCount).flagStr = '';



