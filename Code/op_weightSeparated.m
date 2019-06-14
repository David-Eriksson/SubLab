% David Eriksson, 2019

function op_weightSeparated( nodenr, timeIndices,command)

% First dimension is coordinates, Second dimension is datas
global g_opts;
global g_nodeArray;
global g_parameters;
global g_deltaParameters;
global g_activities;
global g_deltaActivities;
global g_trainingAndTestData;

if strcmp(command,'newSession') == 1
  
    rand('state',g_nodeArray(nodenr).init_seed);
    randn('state',g_nodeArray(nodenr).init_seed);
            
    inputN = 0;
    for i=1:length(g_nodeArray(nodenr).inp)
        inpnr = g_nodeArray(nodenr).inp(i);
        
        inputN = inputN + g_nodeArray(inpnr).N;
    end
    
    outputN = g_nodeArray(nodenr).N;
    inputsPerOutput = inputN/outputN;
    
    outputSubN = outputN/length(g_nodeArray(nodenr).inp);
    
    if outputSubN < 1
        outputSubN = 1;
        paramsPerInput = inputN/length(g_nodeArray(nodenr).inp);
      else
        paramsPerInput = inputsPerOutput;
    end
    
    % Allocate space
    if ~isfield(g_nodeArray(nodenr),'pis') || (length(g_nodeArray(nodenr).inp) ~= length(g_nodeArray(nodenr).pis))
        g_nodeArray(nodenr).pis = [];
        g_nodeArray(nodenr).dpis = [];
    end
    for i=1:length(g_nodeArray(nodenr).inp)
        inpnr = g_nodeArray(nodenr).inp(i);
        % fully connected weights between inpnr and nodenr
        if ~isempty(g_nodeArray(nodenr).initFromFile)
            dataPath = 'C:\Users\David\Documents\Projects\ComputationalPert\Data\Training\';

            fid = fopen([dataPath g_nodeArray(nodenr).initFromFile{i} '_Weight' num2str(g_opts.labelNeuron) '.dat'],'r');  
            ratio = fread(fid,'float');
            fclose(fid);

            ratio = reshape(ratio,[length(ratio)/3, 3]);
            initParams = ratio(setdiff(g_opts.uniqueNeurons,g_opts.labelNeuron),3)'; % Simple sta
            
            if ~isempty(strfind(g_nodeArray(nodenr).initFromFile, 'PreNorm'))
                  initParams = initParams*10000;
            end
            
        else
            %initParams = g_nodeArray(nodenr).init_m+g_nodeArray(nodenr).init_s*randn(g_nodeArray(nodenr).N,g_nodeArray(inpnr).N,g_opts.datatype);
            initParams = g_nodeArray(nodenr).init_m+g_nodeArray(nodenr).init_s*(rand(outputSubN,paramsPerInput,g_opts.datatype)-0.5);
        
        end
    
        if ~isfield(g_nodeArray(nodenr),'pis') || (length(g_nodeArray(nodenr).inp) ~= length(g_nodeArray(nodenr).pis))
            g_nodeArray(nodenr).pis(i) = length(g_parameters)+1;
        end
        
        g_parameters{g_nodeArray(nodenr).pis(i)} = initParams;
        
        g_deltaParameters{g_nodeArray(nodenr).pis(i)} = zeros(outputSubN,paramsPerInput,g_opts.datatype);
    end
    
    if ~isfield(g_nodeArray(nodenr),'ais') || isempty(g_nodeArray(nodenr).ais)
        g_nodeArray(nodenr).ais = length(g_activities)+1;
    end
    
    g_activities{g_nodeArray(nodenr).ais} = zeros(g_nodeArray(nodenr).N,g_opts.nrSamples,g_opts.datatype);
    
    g_deltaActivities{g_nodeArray(nodenr).ais} = zeros(g_nodeArray(nodenr).N,g_opts.nrSamples,g_opts.datatype);
    
elseif strcmp(command,'newBatch') == 1
    

elseif strcmp(command,'forward') == 1

    %forward mode
    inputN = 0;
    inputs = [];
    for i=1:length(g_nodeArray(nodenr).inp)
        inpnr = g_nodeArray(nodenr).inp(i);
        
        inputs = [inputs (1:g_nodeArray(inpnr).N)*0+i];
        
        inputN = inputN + g_nodeArray(inpnr).N;
    end
    
    outputN = g_nodeArray(nodenr).N;
    inputsPerOutput = inputN/outputN;
    
    outputSubN = outputN/length(g_nodeArray(nodenr).inp);
    
    if outputSubN < 1
        outputSubN = 1;
        paramsPerInput = inputN/length(g_nodeArray(nodenr).inp);
      else
        paramsPerInput = inputsPerOutput;
    end
    
    ai = g_nodeArray(nodenr).ais;
    g_activities{ai}(:,timeIndices) = 0;
        
    inputNodes = g_nodeArray(nodenr).inp;
        
    inputOffset = 0;
    for outputIndex=1:outputN
        inputInds = inputOffset+(1:inputsPerOutput);
        remainingInputs = inputs(inputInds);
        while ~isempty(remainingInputs)
              currInputNr = remainingInputs(1);
              
              inputNode = inputNodes(currInputNr);
              input_pi = g_nodeArray(nodenr).pis(currInputNr);
              timeDir = g_nodeArray(nodenr).dir(currInputNr);
              input_ai = g_nodeArray(inputNode).ais;
              parameterSubIndex = mod(outputIndex-1,size(g_parameters{input_pi},1))+1;
          
              currInputInds = mod(inputInds(remainingInputs == currInputNr)-1,g_nodeArray(inputNode).N)+1;
              
              g_activities{ai}(outputIndex,timeIndices) = g_activities{ai}(outputIndex,timeIndices) + g_parameters{input_pi}(parameterSubIndex,:)*g_activities{input_ai}(currInputInds,timeIndices+timeDir);
              
              inputInds = inputInds(remainingInputs ~= currInputNr);
              remainingInputs = remainingInputs(remainingInputs ~= currInputNr);
        end
        
        inputOffset = inputOffset + inputsPerOutput;
    end
    
elseif strcmp(command,'backprop') == 1
    %backward mode
    inputN = 0;
    inputs = [];
    for i=1:length(g_nodeArray(nodenr).inp)
        inpnr = g_nodeArray(nodenr).inp(i);
        
        inputs = [inputs (1:g_nodeArray(inpnr).N)*0+i];
        
        inputN = inputN + g_nodeArray(inpnr).N;
    end
    
    outputN = g_nodeArray(nodenr).N;
    inputsPerOutput = inputN/outputN;
    
    outputSubN = outputN/length(g_nodeArray(nodenr).inp);
    
    if outputSubN < 1
        outputSubN = 1;
        paramsPerInput = inputN/length(g_nodeArray(nodenr).inp);
      else
        paramsPerInput = inputsPerOutput;
    end
    
    ai = g_nodeArray(nodenr).ais;
    g_activities{ai}(:,timeIndices) = 0;
        
    inputNodes = g_nodeArray(nodenr).inp;
        
    inputOffset = 0;
    for outputIndex=1:outputN
        inputInds = inputOffset+(1:inputsPerOutput);
        remainingInputs = inputs(inputInds);
        while ~isempty(remainingInputs)
              currInputNr = remainingInputs(1);
              
              inputNode = inputNodes(currInputNr);
              input_pi = g_nodeArray(nodenr).pis(currInputNr);
              timeDir = g_nodeArray(nodenr).dir(currInputNr);
              input_ai = g_nodeArray(inputNode).ais;
              
              parameterSubIndex = mod(outputIndex-1,size(g_parameters{input_pi},1))+1;
          
          
              currInputInds = mod(inputInds(remainingInputs == currInputNr)-1,g_nodeArray(inputNode).N)+1;
              
          
              g_deltaParameters{input_pi}(parameterSubIndex,:)= g_activities{input_ai}(currInputInds,timeIndices+timeDir)*(g_deltaActivities{ai}(outputIndex,timeIndices)') / length(timeIndices);
              g_deltaActivities{input_ai}(currInputInds,timeIndices+timeDir)= g_deltaActivities{input_ai}(currInputInds,timeIndices+timeDir) + repmat(g_parameters{input_pi}(parameterSubIndex,:)',1,length(timeIndices)).*repmat(g_deltaActivities{ai}(outputIndex,timeIndices),paramsPerInput,1);
            
              inputInds = inputInds(remainingInputs ~= currInputNr);
              remainingInputs = remainingInputs(remainingInputs ~= currInputNr);
        end
        
        inputOffset = inputOffset + inputsPerOutput;
    end

        
            
end




