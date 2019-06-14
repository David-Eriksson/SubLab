% David Eriksson, 2019

currElement = 1;

finishedNodes = zeros(1,size(W,1));

while currElement <= length(elements)
    currNodes = elements{currElement};
    
    %disp(['backward: ' num2str(currNodes)]);
    
    
    % Check directions within this element
    directions = W(:,currNodes);
    directions = directions(~isnan(directions));
    if isempty(directions)
        direction = 0;
    else
        direction = sign(mean(directions(:)));
    end
    if direction == 1
        ts = (g_opts.jumpTime-1):(-1):1;
        jumps = (0:(g_opts.jumpCount-2))*g_opts.jumpTime;
    elseif direction == -1 
        ts = 2:g_opts.jumpTime;
        jumps = (1:(g_opts.jumpCount-1))*g_opts.jumpTime;
    end
    
    % Go through nodes in a temporal order, begin with the
    % node that reads most completely from finishedNodes

    if direction ~= 0
        %tic;
        % cyclic
        ti = length(ts);
        while ti > 1
            nodesCalced = zeros(1,size(W,1));

            while sum(nodesCalced)<length(currNodes)
                readinessScores = [];
                for ni=1:length(currNodes)
                    outputNodes = find(~isnan(W(currNodes(ni),:)));
                    
                    readinessScore = 0;
                    for ii=1:length(outputNodes)
                    
                        if finishedNodes(outputNodes(ii)) == 1
                            readinessScore = readinessScore + 1/length(outputNodes);
                            continue;
                        end
                        %Important: If weight -1 or 1, all inputNodes that project to the currNode 
                        % will be finished (either from the previous time point (ti-1),
                        % , or as a previous element: a element cannot have a
                        % previous element whose nodes are not finished!)
                        if W(currNodes(ni),outputNodes(ii)) ~= 0  
                            readinessScore = readinessScore + 1/length(outputNodes);
                        elseif (nodesCalced(outputNodes(ii)) == 1)
                            readinessScore = readinessScore + 1/length(outputNodes);
                        end
                    end
                    readinessScores = [readinessScores readinessScore];
                end
                
                [vs bestNode] = max(readinessScores.*(~nodesCalced(currNodes)));
                bestNode = currNodes(bestNode);
                
                nodesCalced(bestNode) = nodesCalced(bestNode) + 1;
                
                inputNodes = find(~isnan(W(:,bestNode)));
                
                %tic;
                g_nodeArray(bestNode).op(bestNode,jumps+ts(ti),'backprop');
                %disp(['bp_sweep ' func2str(g_nodeArray(currNodes(ci)).op) ' ' num2str(toc)]);
            
            end
            ti = ti - 1;
        end
        if 0
            str = 'bp_sweep circular ';
            for ci=1:length(currNodes)
                str = [str func2str(g_nodeArray(currNodes(ci)).op) ' '];
            end
            disp([str ' ' num2str(toc)]);
        end
    else
        % acyclic element node: do all times at ones, but exclude those not
        % given by the 
        timePoints = (g_opts.jumpTime+1):((g_opts.jumpCount-1)*g_opts.jumpTime);
        for ci=1:length(currNodes)
            l_startToc = toc;
            %printf(['bp_sweep ' func2str(g_nodeArray(currNodes(ci)).op) ' ']);
            g_nodeArray(currNodes(ci)).op(currNodes(ci),timePoints,'backprop');
            %printf([num2str(mean(g_activities{g_nodeArray(currNodes(ci)).ais}(:))) ' ']);
            %printf([num2str(toc-l_startToc) '\n']);
            
        end
    end
    
    
    %finishedNodes = [finishedNodes elements{currElement}];
    finishedNodes(currNodes) = 1;
    
    currElement = currElement + 1;    
end