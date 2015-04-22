function [  ] = KNEE_GRAPH( A,B )
%UNTITLED2 Plots the Knee graph for algorithms in structures A and B
%   A and B have structures: median_WALLTIME,median_COST, X for gscatter

WALLTIME=[A.median_WALLTIME;B.median_WALLTIME];
COST=[A.median_COST;B.median_COST];

%change the markers in vector B.X

for i=1:length(B.X)

    if(B.X(i)==0)
        B.X(i)=2;
    else
        B.X(i)=3;
    end

end

X=[A.X;B.X];
figure;
gscatter(WALLTIME,COST,X,'rcgb','o^+v');
legend({'AO all points', 'AO instance candidates', 'L-OPT all points', 'L-OPT instance candidates'},'Location','northwest','FontSize',14);
legend('boxoff');
xlabel('wall-clock time (hours)','FontSize',14);
ylabel('cost (dollars)','FontSize',14);


end

