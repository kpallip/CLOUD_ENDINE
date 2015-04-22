function [ filename1 ] = AFAST_GENERATE_TASKS( PickleName,PicklePath,PriorityName1, PriorityPath1 )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%-------------SETTING TASKS ATTRIBUTES---------------------------
%%

%Priority Selectors
AO=1;
SIDNEY=2;
DYNAMIC=3;
priority_string={'AO';'sidney';'dynamic'};

gops_mean=7200;     % tasks' mean giga-ops per second. Set to this value to lead to 1 hr execution 

%gops_std=12e5;      % tasks' stdev giga-ps per second, set to 0 to make all equal tasks
gops_std=0;

%gops_err=0.1;       % error in the estimation of tasks giga-ops per second, set to 0 to remove uncertainty
gops_err=0;

%in_mean=5; %GB      % input file mean in GB

in_mean=5;        %Set to this value to lead to 1 hour task execution

%in_std=5;         % input file stdev in GB, set to 0 to make all inputs the same

in_std=0;

%out_mean=10;        % output file mean in GB

out_mean=5;       %Set to this value to lead to 1 hour task execution

%out_std=15;          % output file stdev in GB, set to 0 to make all inputs the same

out_std=0;

memory=1.5; %G      % RAM required memory per task. Set to low value so that task can execute

% ----------  other experimental variables:

deadline=3600*24*365*30; % Set really high deadline of the batch of tasks, can be set individually if needed

%==============GET THE ADJACENCY LIST======================


% priority_string={'AO';'sidney';'dynamic'};
filename1=strcat('../INPUT/TASKS/tasks_',PriorityName1);

if(exist(filename1,'file'))
    disp('Task File exists..');
    return;
end
disp('Creating task file..');
command='python adjacency_list_only.py ';

adj_path=strcat(PicklePath,PickleName);
py_command=[command adj_path ' >>File.csv'];
[s,cmdout]=system(py_command);
echo_command=['echo ' command PickleName];
system(echo_command);
adjacency_list=csvread('File.csv');
delete('File.csv')

nn=size(adjacency_list);
n=nn(1);

 
 
 %%strcat(directory,'/',POLICY{K},'/',fname(i).name)
%===============READ the Priority File============================%


            priority1=csvread(strcat(PriorityPath1,PriorityName1));
            
%%
%================Parameters for the Task============%

        status=0;

        budget=0;

        total_bg=10*n;       % total budget for the batch of tasks, is is still experimental

        est_gops=abs(normrnd(gops_mean,gops_std,n,1));

        budget=total_bg/sum(est_gops);

        in_size=abs(normrnd(in_mean,in_std,n,1));

        out_size=abs(normrnd(out_mean,out_std,n,1));
    
%
%% Write the tasks to a temp file. Remove later
%==============Tasks Writing=================%


        fout1=fopen(filename1,'w');
        
        for i=1:n
            
           x=in_size(i,1) + out_size(i,1);
            
           fprintf(fout1,'%i,0,%i,%i,',i-1,est_gops(i,1),est_gops(i,1)*gops_err);
           fprintf(fout1,'%.2f,%.2f,%i,%i,',in_size(i,1),out_size(i,1),memory,x);
           fprintf(fout1,'0,%i,%f,%i,1,',priority1(i,2),est_gops(i,1)*budget,deadline);
           fprintf(fout1,'\"%s\"\n',getDependenciesfromList(adjacency_list(i,:)));
          
   
        end
       
        fclose(fout1);
end

