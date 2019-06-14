% David Eriksson, 2019

function nodeInfo = op_bias( nodenr, timeIndices,command)

% First dimension is coordinates, Second dimension is datas
global g_opts;
global g_nodeArray;
global g_parameters;
global g_deltaParameters;
global g_activities;
global g_deltaActivities;

if strcmp(command,'newSession') == 1
    % Allocate space    
    if ~isempty(g_nodeArray(nodenr).initFromFile)
        dataPath = 'C:\Users\David\Documents\Projects\ComputationalPert\Data\Training\';

        if strcmp(g_nodeArray(nodenr).initFromFile{1},'Init_Causal') == 1
            fid = fopen([dataPath 'Init_Causal_Ratio' num2str(g_opts.labelNeuron) '.dat'],'r');  
            ratio = fread(fid,'float');
            fclose(fid);
        elseif strcmp(g_nodeArray(nodenr).initFromFile{1},'Init_ACausal') == 1
            fid = fopen([dataPath 'Init_ACausal_Ratio' num2str(g_opts.labelNeuron) '.dat'],'r');  
            ratio = fread(fid,'float');            
            fclose(fid);
        end
        ratio = reshape(ratio,[length(ratio)/3, 3]);
        initParamsR = ratio(setdiff(g_opts.uniqueNeurons,g_opts.labelNeuron),3); % Simple sta
        nanInds = find(isnan(initParamsR));
        initParamsR(nanInds) = 0.7; % Ratio 0.7 corresponds to bias 1
        initParamsR = initParamsR.*(initParamsR > 0.01) + (initParamsR <= 0.01)*0.01;
        initParamsR = initParamsR.*(initParamsR < 0.99) + (initParamsR >= 0.99)*0.99;
        initParams = -log(1./initParamsR-1);
        % ft = Sigmoid(bias) = 1 ./ (1 + exp(-bias));
        % ft.*htm+(1-ft).*xt
    else
        rand('state',g_nodeArray(nodenr).init_seed);
        randn('state',g_nodeArray(nodenr).init_seed);
        initParams = g_nodeArray(nodenr).init_m+g_nodeArray(nodenr).init_s*randn(g_nodeArray(nodenr).N,1,g_opts.datatype);
    end
    
    if ~isfield(g_nodeArray(nodenr),'pis') || isempty(g_nodeArray(nodenr).pis)
        g_nodeArray(nodenr).pis = length(g_parameters)+1;
    end
    
    if ~isfield(g_nodeArray(nodenr),'ais') || isempty(g_nodeArray(nodenr).ais)
        g_nodeArray(nodenr).ais = length(g_activities)+1;
    end
        
    g_parameters{g_nodeArray(nodenr).pis} = initParams;
    
    g_deltaParameters{g_nodeArray(nodenr).pis} = zeros(g_nodeArray(nodenr).N,1,g_opts.datatype);
        
    g_activities{g_nodeArray(nodenr).ais} = zeros(g_nodeArray(nodenr).N,g_opts.nrSamples,g_opts.datatype);
    
    g_deltaActivities{g_nodeArray(nodenr).ais} = zeros(g_nodeArray(nodenr).N,g_opts.nrSamples,g_opts.datatype);
    
elseif strcmp(command,'newBatch') == 1
    
elseif strcmp(command,'forward') == 1

    %forward mode

    pi = g_nodeArray(nodenr).pis;
    ai = g_nodeArray(nodenr).ais;
    
    g_activities{ai}(:,timeIndices) = repmat(g_parameters{pi},1,length(timeIndices));
elseif strcmp(command,'backprop') == 1
    
    
    %backward mode
    
    % There is no need for a backprop for a bias (inputNode=0)
    pi = g_nodeArray(nodenr).pis;
    ai = g_nodeArray(nodenr).ais;
    
    g_deltaParameters{pi} = (g_parameters{pi}*0+1).*mean(g_deltaActivities{ai}(:,timeIndices),2);
end




