% David Eriksson, 2019

W = zeros(length(g_nodeArray))+NaN;
for ni = 1:length(g_nodeArray)
    for ii=1:length(g_nodeArray(ni).inp)
        from = g_nodeArray(ni).inp(ii);
        to = ni;
        if (to==0) || (from == 0)
            continue;
        end
        W(from,to) = g_nodeArray(ni).dir(ii);
    end
end

elements = findElementsInGraph(~isnan(W));

currElement = length(elements);

rand('state',1);
randn('state',1);

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
    end
    currElement = currElement - 1;
end