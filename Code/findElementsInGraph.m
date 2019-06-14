% David Eriksson, 2019

function elements = findElementsInGraph(W)
 
more off;
%W = [0 1 0 0 0 0 0 ; 0 0 1 0 0 0 1 ; 0 1 0 0 0 0 0 ; 0 0 0 0 1 0 0 ; 0 0 0 0 0 1 1 ; 0 0 0 0 1 0 0 ; 0 0 0 0 0 0 0 ]; 
  
%W = [0 1 0 0 0 0 0 ; 0 0 1 0 1 0 1 ; 0 1 0 0 0 0 0 ; 0 0 0 0 1 0 0 ; 0 0 0 0 0 1 1 ; 0 0 0 0 1 0 0 ; 0 0 0 0 0 0 0 ]; 
  
  
nodes = 1:size(W,1);

clusters = zeros(length(nodes),length(nodes));
for ni=1:length(nodes)
    clusters(ni,visitForward(W,nodes(ni))) = 1;
end

order = sum(clusters);
origInds = 1:length(order);
elements = [];
while ~isempty(clusters)
    [vs is] = max(order);
    
    % Which other nodes are coactivated?
    coactivatedNodes = find(clusters(is,:));    
    
    elements{length(elements)+1} = origInds(coactivatedNodes);
   
    remainingInds = setdiff(1:length(order),coactivatedNodes);
    order = order(remainingInds);
    origInds = origInds(remainingInds);
    clusters = clusters(remainingInds,remainingInds);
end

elements = elements;

end

function nodes = visitForward(W,node)
  
edges = [];
nodes = [node];
nextNodes = node;

traversedNodes = [];
while ~isempty(nextNodes)
    node = nextNodes(1);
    
    traversedNodes = [traversedNodes node];
    
    foundNodes = find(W(node,:));
    
    nextNodes = [nextNodes foundNodes];
    nextNodes = setdiff(nextNodes,traversedNodes);
    
    nodes = unique([foundNodes nodes]);
    
end
end