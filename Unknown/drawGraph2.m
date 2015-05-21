function handleGraph = drawGraph2(dag,node_labels,dag2,nodeScores)

    if ~ispc
        disp(sprintf('%s: RETURN! Sorry, this function only runs on a PC...',mfilename))
        return
    end

    % second dag containing some more values
    if nargin < 3
        dag2 = dag;
    end
    
    % nodescores
    if nargin < 4
        nodeScores = [];
    end
    
    edge_width_factor = 5;
    boolArrows = 0;
    boolLabels = 1;
        
    if boolLabels
        strShowWeights = 'on';
    else
        strShowWeights = 'off';
    end
    
    if boolArrows
        strShowArrows = 'on';
    else
        strShowArrows = 'off';
    end
    
    Graph=biograph(sparse(dag),node_labels,'ShowWeights',strShowWeights,'ShowArrows',strShowArrows);%
    %,'LayoutType','radial'
    % ,'NodeAutoSize','off'
    % 
    handleGraph = view(Graph);
    
    % matWeights = abs(dag(find(dag~=0)))
    for i = 1:length(handleGraph.Edges)
        % get the edge connection details
        strEdgeID=handleGraph.Edges(i).ID;
        strEdgeNode1 = strtrim(strEdgeID(1:strfind(strEdgeID,' -> ')));
        strEdgeNode2 = strtrim(strEdgeID(strfind(strEdgeID,' -> ')+4:end));
        iNode1 = find(strcmp(node_labels,strEdgeNode1));
        iNode2 = find(strcmp(node_labels,strEdgeNode2));

        % set edge-width to dag2 value
%         handleGraph.Edges(i).LineWidth = max(abs(1-dag2(iNode1,iNode2))*edge_width_factor,0.1);
        handleGraph.Edges(i).LineWidth = max(dag2(iNode1,iNode2)*edge_width_factor,0.1);

        % set edge-color to dag-value via redgreen colormap
        matMap = flipud(redgreencmap(128));
        matBinEdges = linspace(full(nanmin(dag(:))),full(nanmax(dag(:))),size(matMap,1));
        handleGraph.Edges(i).LineColor = matMap(find(histc(handleGraph.Edges(i).Weight,matBinEdges)),:);

        % display edge
%         disp(sprintf('%s: %.3f',strEdgeID,dag(iNode1,iNode2)))
    end

    
    for i =  1:length(handleGraph.Nodes)

        % if we're dealing with a non-leaf node, make shape circular, and
        % size dependent on the node score, and color white?
        if ~isnan(str2double(handleGraph.Nodes(i).ID(1))) % non-leaf node

            % node score
            nodeIX = ismember(node_labels,handleGraph.Nodes(i).ID);            
            nodeScore = nodeScores(nodeIX);
            
            % Set node-color to node-score via redgreen colormap
            matMap = flipud(redgreencmap(128));
            matMap = matMap + 0.3;
            matMap(matMap>1)=1;
%             matMap = flipud(redbluecmap(128));
%             matBinEdges = linspace(full(nanmin(nodeScores(:))),full(nanmax(nodeScores(:))),size(matMap,1));
            matBinEdges = linspace(-1,1,size(matMap,1));
            matColors = matMap(find(histc(nodeScore,matBinEdges)),:);
            if ~isempty(matColors)
                handleGraph.Nodes(i).Color = matColors;
            end
%             handleGraph.Nodes(i).Color= [1 1 1];

            handleGraph.Nodes(i).Shape = 'circle';
            
            % size depends on current node height and nodeScores value
            nodeHeight = min(handleGraph.Nodes(i).Size);
            newNodeHeight = nodeHeight;
%             newNodeHeight = max([nodeScore * 2,1]) * nodeHeight;
            
            % set node label
            handleGraph.Nodes(i).Label = sprintf('%.2g',nodeScore);
            
            handleGraph.Nodes(i).Size = repmat(newNodeHeight,1,2);
            handleGraph.Nodes(i).LineColor = [0.75 0.75 0.75];
            handleGraph.Nodes(i).LineWidth = 0.5;
            handleGraph.Nodes(i).FontSize = 9;
        else % leaf node with text-id
            handleGraph.Nodes(i).Label = handleGraph.Nodes(i).ID;
            handleGraph.Nodes(i).Color = [1 1 1];
            handleGraph.Nodes(i).LineColor = [0 0 0];
            handleGraph.Nodes(i).LineWidth = 1;
            handleGraph.Nodes(i).FontSize = 9;
        end
    end
    
    
%     drawnow
    
end