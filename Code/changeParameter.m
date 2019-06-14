% David Eriksson, 2019

function changeParameter(param,val)
    global g_nodeArray;
    
    for ni=1:length(g_nodeArray)
        if isfield(g_nodeArray(ni),param)
            if ~isempty(getfield(g_nodeArray(ni),param))
                g_nodeArray(ni) = setfield(g_nodeArray(ni),param,val);
            end
       end
   end
end
