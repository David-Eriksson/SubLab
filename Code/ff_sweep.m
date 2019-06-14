% David Eriksson, 2019


currElement = length(elements);

finishedNodes = zeros(1,size(W,1));

while currElement >= 1
    currNodes = elements{currElement};
    
    %disp(['forward: ' num2str(currNodes)]);
    
    % Check directions within this element
    directions = W(:,currNodes);
    directions = directions(~isnan(directions));
    if isempty(directions)
        direction = 0;
    else
        forwardDir = sum(directions > 0)>0; 
        backwardDir = sum(directions < 0)>0; 
        
        if (forwardDir == 1) && (backwardDir == 1)
            disp('use only one direction per element.');
            pause;
        end
        
        direction = sign(mean(directions(:)));
    end
    
    if direction == 1
        ts = (g_opts.jumpTime+g_opts.preJumpTime-1):(-1):1;
        jumps = (0:(g_opts.jumpCount-2))*g_opts.jumpTime;
    elseif direction == -1 
        ts = (-g_opts.preJumpTime+1):(g_opts.jumpTime);
        jumps = (1:(g_opts.jumpCount-1))*g_opts.jumpTime;
    end
    
    % Go through nodes in a temporal order, begin with the
    % node that reads most completely from finishedNodes

    if direction ~= 0
        %tic;
        % cyclic
        ti = 1;
        while ti<length(ts)
            %ti/jumpTime
            nodesCalced = zeros(1,size(W,1));

            while sum(nodesCalced)<length(currNodes)
                readinessScores = [];
                for ni=1:length(currNodes)
                    inputNodes = find(~isnan(W(:,currNodes(ni))));
                    
                    readinessScore = 0;
                    for ii=1:length(inputNodes)
                        if finishedNodes(inputNodes(ii)) == 1
                            readinessScore = readinessScore + 1/length(inputNodes);
                            continue;
                        end
                        %Important: If weight -1 or 1, all inputNodes that project to the currNode 
                        % will be finished (either from the previous time point (ti-1),
                        % , or as a previous element: a element cannot have a
                        % previous element whose nodes are not finished!
                        if W(inputNodes(ii),currNodes(ni)) ~= 0  
                            readinessScore = readinessScore + 1/length(inputNodes);
                        elseif (nodesCalced(inputNodes(ii)) == 1)
                            readinessScore = readinessScore + 1/length(inputNodes);
                        end
                    end
                    readinessScores = [readinessScores readinessScore];
                end
                
                [vs bestNode] = max(readinessScores.*(~nodesCalced(currNodes)));
                bestNode = currNodes(bestNode);
                
                nodesCalced(bestNode) = nodesCalced(bestNode) + 1;
                
                %tic;
                g_nodeArray(bestNode).op(bestNode,jumps+ts(ti),'forward');
                %disp(['ff_sweep ' func2str(g_nodeArray(currNodes(ci)).op) ' ' num2str(toc)]);
                %disp(['ff_sweep ' func2str(g_nodeArray(bestNode).op) ' ' num2str(mean(g_activities{g_nodeArray(bestNode).ais}(:)))]); 
            
                
            end
            
            ti = ti + 1;
        end
        
        if 0
            str = 'ff_sweep circular ';
            for ci=1:length(currNodes)
                str = [str func2str(g_nodeArray(currNodes(ci)).op) ' ' num2str(mean(g_activities{g_nodeArray(currNodes(ci)).ais}(:))) ' ' ];
            end
            disp([str]);
        end
    else
        % acyclic element node: do all times at ones
        for ci=1:length(currNodes)
            %tic;
            l_startToc = toc;
            %printf(['ff_sweep ' func2str(g_nodeArray(currNodes(ci)).op) ' ']);
            if strcmp(func2str(g_nodeArray(currNodes(ci)).op),'op_weightSeparated') == 1
                ci = ci;
            end
            g_nodeArray(currNodes(ci)).op(currNodes(ci),1:(g_opts.jumpCount*g_opts.jumpTime),'forward');
            %printf([num2str(mean(g_activities{g_nodeArray(currNodes(ci)).ais}(:))) ' ']);
            %printf([num2str(toc-l_startToc) '\n']);
            
        end
    end
    
    %figure(1); clf; imagesc(g_activities{g_nodeArray(gateNode).ais}); pause; %pause(0.001);
    
    %finishedNodes = [finishedNodes elements{currElement}];
    finishedNodes(currNodes) = 1;
    
    currElement = currElement - 1;    
end