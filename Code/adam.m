% David Eriksson, 2019

function adam()

global g_opts;
global g_nodeArray;
global g_parameters;
global g_deltaParameters;
global g_activities;
global g_deltaActivities;
global g_trainingAndTestData;
global g_momentum2nd;
global g_momentum1st;
global g_paramAccumT;


for pi=1:length(g_parameters)
    % From which node does this parameter come?
    
    dropOutRatio = [];
    plasticity_flags = [];
    for ni=1:length(g_nodeArray)
        inds = find(pi == g_nodeArray(ni).pis);
        
        if isempty(inds)
            continue;
        end
        
        dropOutRatio = g_nodeArray(ni).dropOutRatio;
        
        if isfield(g_nodeArray(ni),'pla')
            if ~isempty(g_nodeArray(ni).pla)
                plasticity_flags = g_nodeArray(ni).pla;
            end
        end
    end
    
    if ~isempty(dropOutRatio)
        g_parameters{pi} = [];
        g_deltaParameters{pi} = [];
        g_momentum2nd{pi} = [];
        g_momentum1st{pi} = [];
        
        continue;
    end
  
    if isempty(g_momentum2nd)
        g_momentum2nd = cell(length(g_parameters),1);
        g_momentum1st = cell(length(g_parameters),1);
        g_paramAccumT = cell(length(g_parameters),1);
        
        for i=1:length(g_momentum2nd)
            g_momentum2nd{i} = [];
            g_momentum1st{i} = [];
            g_paramAccumT{i} = [];
        end
    end
          
        
    if isempty(g_momentum2nd{pi})
        g_momentum2nd{pi}=zeros(size(g_parameters{pi}),g_opts.datatype);
        g_momentum1st{pi}=zeros(size(g_parameters{pi}),g_opts.datatype);
        g_paramAccumT{pi} = 1;
    end
    
    constantParameter = 0; 
    for fi=1:length(plasticity_flags)
        if strcmp(plasticity_flags{fi},'constant parameter') == 1
            constantParameter = 1;
        end
    end

    if constantParameter == 0    
        g_momentum1st{pi}=g_opts.beta1*g_momentum1st{pi}+(1-g_opts.beta1)*g_deltaParameters{pi};    
        g_momentum2nd{pi}=g_opts.beta2*g_momentum2nd{pi}+(1-g_opts.beta2)*(g_deltaParameters{pi}.^2);
        m1st = g_momentum1st{pi}/(1-g_opts.beta1^g_paramAccumT{pi});
        m2nd = g_momentum2nd{pi}/(1-g_opts.beta2^g_paramAccumT{pi});
        g_parameters{pi}=g_parameters{pi}-1*g_opts.learningRate*m1st./(sqrt(m2nd)+g_opts.learningEps) - g_opts.weightDecay*g_parameters{pi};
        g_paramAccumT{pi} = g_paramAccumT{pi} + 1;
    end
    
    
    
    
    positiveParameter = 0; 
    for fi=1:length(plasticity_flags)
        if strcmp(plasticity_flags{fi},'positive parameter') == 1
            positiveParameter = 1;
        end
    end
    
    if positiveParameter == 1
        mp = mean(abs(g_parameters{pi}));
        loLimit = mp*0.0001;
        g_parameters{pi} = g_parameters{pi}.*(g_parameters{pi}>loLimit)+loLimit.*(g_parameters{pi}<=loLimit);
    end
    
    
    
    
    negativeParameter = 0; 
    for fi=1:length(plasticity_flags)
        if strcmp(plasticity_flags{fi},'negative parameter') == 1
            negativeParameter = 1;
        end
    end
   
    if negativeParameter == 1
        mp = mean(abs(g_parameters{pi}));
        loLimit = mp*0.0001;
        g_parameters{pi} = g_parameters{pi}.*(g_parameters{pi}<(-loLimit))+(-loLimit).*(g_parameters{pi}>=(-loLimit));
    end 
    
end