function [matfiles ] = CLOUD_ENGINE(STAT_RUNS )
%Author: Dr. Vivek K. Pallipuram
%Last Updated 31st March, 2015
% This session is a scripted version of the heuristic, meaning all the test
% cases are automatically tested.
% Heuristic:
%    A brief synopsis is as follows.
%         Use the DAG structure to provide a starting point for the resource selection. Specifically, use median as 
% 
% the 'degree of concurrency': C.
% 
%         Find the candidates (instance-type, instance-number). For an instance size I_i, the candidate is (I_i, ceil(C/I_i)). 
% 
% Let us say we have 'I' instance types and 't' threshold on the number of instances, then the search space is: I*t. Using
%degree of concurrency (median) as described above, we have significantly reduced the search space.
% 
%Simulation:
%         1. Traverse the static priority list using the identified candidates from each instance type.
%          
% 
%     More interesting part: Plot Wall-time vs. Total-Cost plot and it shows a Pareto front. The heuristic places 
% 
% the candidates on the 'knee', which is the desired region, when using median and weighted median as the degree of concurrency.
% 
%     
%RUN FOR STAT_RUNS TIMES AT CANDIDATE ONLY. STORE MEAN, MEDIAN, AND STANDARD
%DEVIATION. ONLY STORE RUNS FOR INSTANCE CANDIDATES. This is for cost
%effectiveness analysis
% additionally for a unit improvement in performance. 
%It also encodes how valuable that application is to the user. We want to 
%select a candidate such that C is minimized. The candidate that yields 
%minimum C for the utility function is the choice for the user. 


%% Get the DAG to be tested.
matfiles={'A' 'B'};
% directory=uigetdir('*', 'Enter the DAG folder (parent of CP32, CP64, etc.)');
% p_directory=uigetdir('*', 'Enter the Priority Folder. The name is "PRIORITY" ');
% meta_directory=uigetdir('*', 'Enter the LEVELS  directory. This directory stores the level widths of all DAGs (precomputed) ');
directory='../INPUT/DAGs/SAMPLES';
p_directory='../INPUT/PRIORITY/SAMPLES';
meta_directory='../INPUT/LEVELS';
FOLDER={'CP64' 'WM64' 'CP32' 'WM32' 'CONSTANT_RATIO'};
%FOLDER={'CP64'};

Instance_File={'c38xlarge32.csv' 'c34xlarge16.csv' 'c32xlarge8.csv' 'c3xlarge4.csv' 'c3large2.csv'};
%Instance_Path= uigetdir('*', 'Enter the directory for instances');
Instance_Path='../INPUT/INSTANCES';

NUM_DAGS_PGRP=16; %number of DAGs per group
MAX_RES_NUM=20; %Number set by EC2
user_input=input('Read the levels from meta-data? 0 for no...');

inst_counter=1;

SCHEDULING={'AO' 'dynamic'}; %scheduling name used for task files
SCHED_NAME={'AO' 'LOPT'}; % scheduling names used to save MAT files


    
for folder=1:length(FOLDER)

    for sched=1:2

        %% Read the files
        filepath1=strcat(directory,'/',FOLDER{folder},'/');
        PriorityPath1=strcat(p_directory,'/',FOLDER{folder},'/');
        %filepath1=strcat(directory,'/');
        filepath=strcat(filepath1,'*u_*');
        fname=dir(filepath);
        numfids=length(fname);
        OPTION={'WM' 'M'};
        for Opt=2:2 %Forcing median computation for degree of concurrency

            %%  get weighted percentile and CP
                iterator=1;

                %STATISTICS FOR COST-EFFECTIVENESS ANALYSIS OF INSTANCE
                %CANDIDATES
                INST_WALLTIME=zeros(STAT_RUNS*1*length(Instance_File)*NUM_DAGS_PGRP,1); % here 1 represents the number of candidates in that instance type (which is always 1)
                INST_COST=zeros(STAT_RUNS*length(Instance_File)*NUM_DAGS_PGRP,1);
                INST_SIZE=zeros(STAT_RUNS*length(Instance_File)*NUM_DAGS_PGRP,1);
                INST_NUM=zeros(STAT_RUNS*length(Instance_File)*NUM_DAGS_PGRP,1);

                %For all the other cases
                mean_WALLTIME=zeros(NUM_DAGS_PGRP*length(Instance_File)*MAX_RES_NUM,1);
                mean_COST=zeros(NUM_DAGS_PGRP*length(Instance_File)*MAX_RES_NUM,1);

                median_WALLTIME=zeros(NUM_DAGS_PGRP*length(Instance_File)*MAX_RES_NUM,1);
                median_COST=zeros(NUM_DAGS_PGRP*length(Instance_File)*MAX_RES_NUM,1);

                sd_WALLTIME=zeros(NUM_DAGS_PGRP*length(Instance_File)*MAX_RES_NUM,1);
                sd_COST=zeros(NUM_DAGS_PGRP*length(Instance_File)*MAX_RES_NUM,1);


                X=zeros(NUM_DAGS_PGRP*length(Instance_File)*MAX_RES_NUM,1);

            for F=1:numfids    

                if user_input
                    GL=csvread(strcat(meta_directory,'/',fname(F).name,'.csv'));
                    GRAPH_LEVEL=transpose(GL);
                    cp=length(GRAPH_LEVEL);
                    if Opt ==1 %if weighted median is used for concurrency
                        [ H, Weights, Perc, wm ] = Weighted_Median_F1( GRAPH_LEVEL, 50 );
                    else
                      wm=prctile(GRAPH_LEVEL,50);
                      fprintf('Median-based heuristic \n');
                    end
                else
                [ GRAPH_LEVEL,wm,cp] = CONCURR_CP_F1( filepath1, fname(F).name, 50, Opt ); %Levelize the DAG and then compute concurrency
                end

                %% Elasticity Exeriments
                %Find the instance candidates. ONLY relevant return parameter is INSTANCE_NUM i.e. the
                %optimal number of instances for a given type. Ignore
                %others. Just for some extra study.
                [ INSTANCE_NUM,CUMM_IDLE,CUMM_IDLE_INST,TOTAL_COST,TOTAL_TIME,SELECT ] = OPT_INSTANCES_F1( GRAPH_LEVEL, wm );

                %% Mark the Optimal Points

                %% Run ALL possible simulations

                TYPE=[32 16 8 4 2];

                PriorityName1=strcat(fname(F).name,'_',SCHEDULING{sched},'.csv');

                [ filename1 ] = GENERATE_TASKS( fname(F).name,filepath1,PriorityName1, PriorityPath1 );

                for type=1:5
                    for res=1:20

                        command='python cloud_sim_traditional_15Jan.py ';
                        pycommand=[command '-i ' strcat(Instance_Path,'/',Instance_File{type}) ' -t ' filename1 ' -cp -res ' int2str(res)];
                        disp(fname(F).name);
                        disp(PriorityName1);
                        echocommand=['echo ' pycommand];
                        system(echocommand);

                        % statistical runs



                        if (res==INSTANCE_NUM(type))
                            stat_WALLTIME=zeros(STAT_RUNS,1);
                            stat_COST=zeros(STAT_RUNS,1);

                            for RUN=1:STAT_RUNS
                                [s,cmdout]=system(pycommand,'-echo' );
                                [stat_WALLTIME(RUN) stat_COST(RUN)] = strread(cmdout);

                                 if (res==INSTANCE_NUM(type))
                                    INST_WALLTIME(inst_counter)=stat_WALLTIME(RUN);
                                    INST_COST(inst_counter)=stat_COST(RUN);
                                    INST_SIZE(inst_counter)=type;
                                    INST_NUM(inst_counter)=res;
                                    inst_counter=inst_counter + 1;
                                 end

                            end
                        else
                                stat_WALLTIME=zeros(1,1);
                                stat_COST=zeros(1,1);
                                [s,cmdout]=system(pycommand,'-echo' );
                                [stat_WALLTIME(1) stat_COST(1)] = strread(cmdout);
                        end

                       if (res==INSTANCE_NUM(type))
                            X(iterator)=1;

                       end

                       %GATHER STATISTICS FOR ALL CASES
                       median_WALLTIME(iterator) = median(stat_WALLTIME);

                       median_COST(iterator) = median(stat_COST);


                       iterator=iterator+1;
                    end
                end

                %delete(filename1);
            end


        matfiles{sched}=strcat('./','STAT_',SCHED_NAME{sched},'_',FOLDER{folder},'_',OPTION{Opt},'.mat');

        save(matfiles{sched},'median_WALLTIME','median_COST','X','INST_WALLTIME','INST_COST','INST_SIZE','INST_NUM'); %Name convention: STAT_Sched_Dataset_M.mat
        end
    end %end looping over AO and LOPT
    %% Analysis using matfiles. matfile{1} contains AO data and matfile{2}
%contains LOPT data
    A=load(matfiles{1});
    B=load(matfiles{2});
    KNEE_GRAPH( A,B ); %plot the knee graph

    %% Cost-Effectiveness analysis: plots the box plots. Other return parameters are not
    %important. Below is example for DAG 1000


    [ WALL_STATISTICS,COST_STATISTICS,NUM, DIST_FROM_ORIG, THISSAMPLE_TYPE, THISSAMPLE_NUM ] = COST_EFFECTIVENESS( A, 0, STAT_RUNS,1 );
     
end %end looping over DAG sample

