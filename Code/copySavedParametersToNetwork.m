% David Eriksson, 2019

global g_opts;
global g_parameters;
global g_momentum2nd;
global g_momentum1st;
global g_paramAccumT;

found = 0;
while found == 0  
    try
        parameters = load(currentFile,'g_parameters','g_momentum1st','g_momentum2nd','g_paramAccumT');
        found = 1;
    catch
        found = 0;
        disp('load error');
        pause(1);
    end
end

for pi = 1:length(g_parameters)
    [R, C] = size(parameters.g_parameters{pi});
    g_parameters{pi}(1:R,1:C) = parameters.g_parameters{pi};
    g_momentum1st{pi}(1:R,1:C) = parameters.g_momentum1st{pi};
    g_momentum2nd{pi}(1:R,1:C) = parameters.g_momentum2nd{pi};
    g_paramAccumT{pi} = parameters.g_paramAccumT{pi};
    
    %disp('copySavedParametersToNetwork: fix!');
    %g_paramAccumT{pi} = length(g_opts.trainBatchIndices)*g_opts.epoch;
end