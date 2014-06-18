function handleGraph = drawGraph(dag,node_labels,edge_width_factor,boolArrows,boolColors,boolLabels)

    if ~ispc
        disp(sprintf('%s: RETURN! this function only runs on a PC...',mfilename))
        return
    end

    if isempty(dag)
        fprintf('%s: err.. try putting a non-empty graph next time..',mfilename)
        return
    end    
    
    if nargin < 2 
        % default labels
        node_labels = num2strcell(1:size(dag,1));
    end
    
    if nargin < 3
        % such that the absolute biggest edge gets a line thickness of 3.
        edge_width_factor = 3/max(abs(dag(~isinf(dag))));
    end
    if nargin < 4
        boolArrows = 1;
    end
    if nargin < 5
        boolColors = 1;
    end
    if nargin < 6
        boolLabels = 1;
    end
    
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
    
    % self connections are anyway not allowed...
    dag(logical(eye(size(dag,1)))) = 0;
    if all(dag(:)==0) || isempty(dag)
        fprintf('%s: empty graph passed.. done.\n',mfilename)
        return
    end
    
    if length(node_labels) > size(dag,1)
        fprintf('%s: shortening length of node_labels to fit number of nodes\n',mfilename)
        node_labels = node_labels(1:length(dag));
    end

    % separate dag for edge width weights to maximize dynamic range
    matWeightsDAG = abs(dag);
    matWeightsDAG = matWeightsDAG - (0.5*min(matWeightsDAG(matWeightsDAG(:)>0)));
    matWeightsDAG = matWeightsDAG / max(matWeightsDAG(:));
    matWeightsDAG = matWeightsDAG * 5;

    Graph=biograph(sparse(dag),node_labels,'ShowWeights',strShowWeights,'ShowArrows',strShowArrows,'EdgeCallbacks',@(node)click_graph_edge(node));%,'LayoutType','radial'
    
    handleGraph = view(Graph);

    % matWeights = abs(dag(find(dag~=0)))
    for i = 1:length(handleGraph.Edges)
        % get the edge connection details
        strEdgeID=handleGraph.Edges(i).ID;
        strEdgeNode1 = strtrim(strEdgeID(1:strfind(strEdgeID,' -> ')));
        strEdgeNode2 = strtrim(strEdgeID(strfind(strEdgeID,' -> ')+4:end));
        iNode1 = find(strcmp(node_labels,strEdgeNode1));
        iNode2 = find(strcmp(node_labels,strEdgeNode2));

    %     set(handleGraph.Edges(i),'LineWidth',abs(dag(iNode1,iNode2))*20)
%         set(handleGraph.Edges(i),'LineWidth',max(abs(dag(iNode1,iNode2))*edge_width_factor,0.1))
        set(handleGraph.Edges(i),'LineWidth',max(matWeightsDAG(iNode1,iNode2),0.5))
        

    %     strLabel = sprintf('%.3f (%.3f)',dag(iNode1,iNode2),dag3Stdevs(iNode1,iNode2));
    %     set(handleGraph.Edges(i),'Label',strLabel);

        if boolColors
            if dag(iNode1,iNode2) > 0
                set(handleGraph.Edges(i),'LineColor',[0 1 0]);    
            else
                set(handleGraph.Edges(i),'LineColor',[1 0 0]);
            end
        end

        fprintf('%s: %.3f\n',strEdgeID,dag(iNode1,iNode2))
    end
    
    % add figure name with a bit more info.
    strFigureName = sprintf('%s - %s',mfilename, get(gcf,'Name'));
    if ~isempty(inputname(1))
        strFigureName = [strFigureName, ' - ', inputname(1)];
    end
    set(gcf,'Name',strFigureName)

end