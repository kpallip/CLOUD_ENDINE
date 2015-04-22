function [ WALL_STATISTICS,COST_STATISTICS, NUM, DIST_FROM_ORIG, THISSAMPLE_TYPE, THISSAMPLE_NUM ] = COST_EFFECTIVENESS( A, offset, STAT_RUNS,DAG )
%Plots the boxplots for instances of a given resource types (1 = 32 and 5 =
%2) DAG is the the DAG number for testing
%Offset is for those matfiles that mistakenly pooled all sample folders (0)
%into one matfile
%STAT_RUNS is obtained from CLOUD_ENGINE.m. DAG is the DAG number 1 for
%1000, 2 for 1200, and so on..
%A is the matfile produced by CLOUD_ENGINE.m

    THISSAMPLE_TYPE=zeros(16,1);
    THISSAMPLE_NUM=zeros(16,1);

    %for DAG=1:16
        offset=0;
        offset_mult = STAT_RUNS*5; %5 is the number of instances

        WALLTIME=A.INST_WALLTIME(offset_mult*(DAG - 1)+1+offset:offset_mult*(DAG - 1)+offset_mult+offset);
        COST=A.INST_COST(offset_mult*(DAG - 1)+1+offset:offset_mult*(DAG - 1)+offset_mult+offset);
        TYPE=A.INST_SIZE(offset_mult*(DAG - 1)+1+offset:offset_mult*(DAG - 1)+offset_mult+offset);
        NUM=A.INST_NUM(offset_mult*(DAG - 1)+1+offset:offset_mult*(DAG - 1)+offset_mult+offset);
        RES=[32 16 8 4 2];

        %Some Vital Stats
        %mean, variance

        WALL_STATISTICS=zeros(6,5); %6 rows: mean,std,cov,median,max,min 5 cols: 2, 4, 8, 16, 32  
        COST_STATISTICS=zeros(6,5); %6 rows: mean,std,cov,median,max,min 5 cols: 2, 4, 8, 16, 32

        DAGS=[1000 1200 1400 1600 1800 2000 2200 2400 2600 2800 3000 3200 3400 3600 3800 4000];

        for i=1:length(RES)

            WALL_STATISTICS(1,6-i)=mean(WALLTIME(STAT_RUNS*(i-1)+1:STAT_RUNS*(i-1)+STAT_RUNS)); %mean
            WALL_STATISTICS(2,6-i)=std(WALLTIME(STAT_RUNS*(i-1)+1:STAT_RUNS*(i-1)+STAT_RUNS)); %standard deviation
            WALL_STATISTICS(3,6-i)=WALL_STATISTICS(2,6-i)/WALL_STATISTICS(1,6-i); %COV
            WALL_STATISTICS(4,6-i)=median(WALLTIME(STAT_RUNS*(i-1)+1:STAT_RUNS*(i-1)+STAT_RUNS)); %median
            WALL_STATISTICS(5,6-i)=max(WALLTIME(STAT_RUNS*(i-1)+1:STAT_RUNS*(i-1)+STAT_RUNS)); %max
            WALL_STATISTICS(6,6-i)=min(WALLTIME(STAT_RUNS*(i-1)+1:STAT_RUNS*(i-1)+STAT_RUNS)); %min

            COST_STATISTICS(1,6-i)=mean(COST(STAT_RUNS*(i-1)+1:STAT_RUNS*(i-1)+STAT_RUNS)); %mean
            COST_STATISTICS(2,6-i)=std(COST(STAT_RUNS*(i-1)+1:STAT_RUNS*(i-1)+STAT_RUNS)); %standard deviation
            COST_STATISTICS(3,6-i)=COST_STATISTICS(2,6-i)/COST_STATISTICS(1,6-i); %COV
            COST_STATISTICS(4,6-i)=median(COST(STAT_RUNS*(i-1)+1:STAT_RUNS*(i-1)+STAT_RUNS)); %median
            COST_STATISTICS(5,6-i)=max(COST(STAT_RUNS*(i-1)+1:STAT_RUNS*(i-1)+STAT_RUNS)); %max
            COST_STATISTICS(6,6-i)=min(COST(STAT_RUNS*(i-1)+1:STAT_RUNS*(i-1)+STAT_RUNS)); %min


        end

        RES_T=[2 4 8 16 32];


        %Distance from (0,0)

        DIST_FROM_ORIG=zeros(5,1);

        for i=1:length(RES)

            DIST_FROM_ORIG(i,1)=sqrt(WALL_STATISTICS(4,i)*WALL_STATISTICS(4,i) + COST_STATISTICS(4,i)*COST_STATISTICS(4,i));

        end


        for i=1:length(TYPE)

            if(TYPE(i)~=0)
                TYPE(i) = RES(TYPE(i));
            end

        end

        %Find the instance candidate: 1 least distance, then least COV

        CANDIDATES=zeros(1,4); %t,n,index,cov

        minimum=1e5;
        index=-1;
        for i=1:length(DIST_FROM_ORIG)

            if (DIST_FROM_ORIG(i)<minimum)
                index=i;
                minimum=DIST_FROM_ORIG(i);
            end

        end

        t=TYPE((6-index-1)*STAT_RUNS+1);
        n=NUM((6-index-1)*STAT_RUNS+1);

        CANDIDATES(1,1)=t;
        CANDIDATES(1,2)=n;
        CANDIDATES(1,3)=index;
        CANDIDATES(1,4)=COST_STATISTICS(3,index);

        %find if any instance candidate exists with this min distance
        counter=2;
        for i=1:length(DIST_FROM_ORIG)

           if(i~=index)

               if(DIST_FROM_ORIG(i)==minimum)
                   CANDIDATES(counter,1)=TYPE((6-i-1)*STAT_RUNS+1);
                    CANDIDATES(counter,2)=NUM((6-i-1)*STAT_RUNS+1);
                    CANDIDATES(counter,3)=i;
                    CANDIDATES(counter,4)=COST_STATISTICS(3,i);
                    counter=counter+1;
               end

           end
        end

        %Now select the one with minimum COV

        new_index=-1;
        minimum_cov=1000;
        for i=1:length(CANDIDATES(:,4))

            if(CANDIDATES(i,4)<minimum_cov)

                new_index=i;
                minimum_cov=CANDIDATES(i,4);
            end

        end
        
        THISSAMPLE_TYPE(DAG)=CANDIDATES(new_index,1);
        THISSAMPLE_NUM(DAG)=CANDIDATES(new_index,2);

        figure;
        boxplot(WALLTIME,TYPE);
        xlabel('type of instance (#vCPUs)','FontSize',14);
        ylabel('wall-clock time (hours)','FontSize',14);
        figure;
        boxplot(COST,TYPE);
        xlabel('type of instance (#vCPUs)','FontSize',14);
        ylabel('cost (dollars)','FontSize',14);


end

