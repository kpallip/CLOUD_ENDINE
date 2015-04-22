function [ GRAPH_LEVEL,WM,CP] = CCGRID_WM_CP_F1( filepath1, Name, p, SWITCH )
%UNTITLED2 Summary of this function goes here
%   The function inputs the DAG and outputs weighted median concurrency and
%   critical path after levelizing the DAG
        command='python matlab_adjacency.py ';
        pycommand=[command strcat(filepath1,Name)];
        [s,cmdout]=system(pycommand);
        DISTANCES=strread(cmdout,'%d');     
        
        %% Now after the distances, get the graph levels. Akin to EPTASKS_PTIME
        
        max_level=max(DISTANCES) + 1;
        
        GRAPH_LEVEL=zeros(max_level,1);
        
        for i=1:length(DISTANCES)
            GRAPH_LEVEL(DISTANCES(i)+1)=1+GRAPH_LEVEL(DISTANCES(i)+1);
        end
        
        %% Get the Weighted Median
        CP=max_level;
        if SWITCH==1
        [ H, Weights, Perc, WM ] = Weighted_Median_F1( GRAPH_LEVEL, p ); %compute weighted median
        
        else
            WM=prctile(GRAPH_LEVEL,p); %just compute median
            
        end

end

