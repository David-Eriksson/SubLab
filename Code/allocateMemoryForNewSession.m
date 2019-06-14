% David Eriksson, 2019

currElement = length(elements);

g_parameters = [];
g_deltaParameters = [];
g_activities = [];
g_deltaActivities = [];
g_momentum2nd = [];
g_momentum1st = [];

finishedNodes = zeros(1,size(W,1));
while currElement >= 1
    currNodes = elements{currElement};
    for ni = 1:length(currNodes)
        nodenr = currNodes(ni);
        g_nodeArray(nodenr).op(nodenr,[],'newSession'); % means the node should allocate needed space
        
        % Reset momentum etc
        if isfield(g_nodeArray(nodenr),'pis')
            for in = 1:length(g_nodeArray(nodenr).pis)
                pi = g_nodeArray(nodenr).pis(in);
                g_momentum2nd{pi} = [];
                g_momentum1st{pi} = [];  
            end
        end
    end
    currElement = currElement - 1;
end