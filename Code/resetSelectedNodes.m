% David Eriksson, 2019

currElement = length(elements);

finishedNodes = zeros(1,size(W,1));
while currElement >= 1
    currNodes = elements{currElement};
    for ni = 1:length(currNodes)
        nodenr = currNodes(ni);
        if g_nodeArray(nodenr).resetWeightsAtUpdateReference == 1
            g_nodeArray(nodenr).op(nodenr,[],'newSession'); % means the node should allocate needed space
            
            % Reset momentum etc
            for in = 1:length(g_nodeArray(nodenr).pis)
                pi = g_nodeArray(nodenr).pis(in);
                g_momentum2nd{pi} = [];
                g_momentum1st{pi} = [];
            end
        end
        % Debug
        %[nodenr length(g_parameters)]
    end
    currElement = currElement - 1;
end

currElement = currElement;