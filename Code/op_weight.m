% David Eriksson, 2019

function op_weight( nodenr, timeIndices,command)

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
            
    % Allocate space
    if ~isfield(g_nodeArray(nodenr),'pis') || (length(g_nodeArray(nodenr).inp) ~= length(g_nodeArray(nodenr).pis))
        g_nodeArray(nodenr).pis = [];
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
            initParams = g_nodeArray(nodenr).init_m+g_nodeArray(nodenr).init_s*(rand(g_nodeArray(nodenr).N,g_nodeArray(inpnr).N,g_opts.datatype)-0.5);
        
      end
      
        if ~isfield(g_nodeArray(nodenr),'pis') || (length(g_nodeArray(nodenr).inp) ~= length(g_nodeArray(nodenr).pis))
            g_nodeArray(nodenr).pis(i) = length(g_parameters)+1;
        end
        g_parameters{g_nodeArray(nodenr).pis(i)} = initParams;
        g_deltaParameters{g_nodeArray(nodenr).pis(i)} = zeros(g_nodeArray(nodenr).N,g_nodeArray(inpnr).N,g_opts.datatype);
    end
    
    
    if ~isfield(g_nodeArray(nodenr),'ais') || isempty(g_nodeArray(nodenr).ais)
        g_nodeArray(nodenr).ais = length(g_activities)+1;
    end
    
        
    g_activities{g_nodeArray(nodenr).ais} = zeros(g_nodeArray(nodenr).N,g_opts.nrSamples,g_opts.datatype);
    g_deltaActivities{g_nodeArray(nodenr).ais} = zeros(g_nodeArray(nodenr).N,g_opts.nrSamples,g_opts.datatype);
    
  
elseif strcmp(command,'newBatch') == 1
    

elseif strcmp(command,'forward') == 1

    %forward mode
    ai = g_nodeArray(nodenr).ais;
        
    g_activities{ai}(:,timeIndices) = 0;
    inputNodes = g_nodeArray(nodenr).inp;
    for i=1:length(inputNodes)
        inputNode = inputNodes(i);
        pi = g_nodeArray(nodenr).pis(i);
        timeDir = g_nodeArray(nodenr).dir(i);
        input_ai = g_nodeArray(inputNode).ais;
        g_activities{ai}(:,timeIndices) = g_activities{ai}(:,timeIndices)+g_parameters{pi}*g_activities{input_ai}(:,timeIndices+timeDir);
    end
    
elseif strcmp(command,'backprop') == 1
    %backward mode
    top_delta=permute(g_deltaActivities{g_nodeArray(nodenr).ais}(:,timeIndices),[1,3,2]);
    
    nodeInfo = g_nodeArray(nodenr);
    
    inputNodes = g_nodeArray(nodenr).inp;
    for i=1:length(inputNodes)
        inputNode = inputNodes(i);
        
        input_pi = nodeInfo.pis(i);
        timeDir = nodeInfo.dir(i);
        
        ai = g_nodeArray(nodenr).ais;
        input_ai = g_nodeArray(inputNode).ais;
        
        if ~isfield(nodeInfo,'bkp') || isempty(nodeInfo.bkp) || (strcmp(nodeInfo.bkp{i},'no back propagation') == 0)
            g_deltaActivities{input_ai}(:,timeIndices+timeDir) = g_deltaActivities{input_ai}(:,timeIndices+timeDir)+(g_parameters{input_pi}')*g_deltaActivities{ai}(:,timeIndices);
        end
        
        I=permute(g_activities{input_ai}(:,timeIndices+timeDir),[3,1,2]);
        g_deltaParameters{input_pi} = mean(top_delta.*I,3);
        %g_deltaParameters{input_dpi} = sum(top_delta.*I,3);
    end
end




