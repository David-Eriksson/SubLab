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

