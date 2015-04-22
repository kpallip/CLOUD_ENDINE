function [ INSTANCE_NUM,CUMM_IDLE,CUMM_IDLE_INST,TOTAL_COST,TOTAL_TIME,SELECT ] = CCGRID_ELASTIC_EXPERIMENT_F1( ETASKS_PTIME, CONCURRENCY )

%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
%%  elasticity experiment
 
     key_input=1;
     base_price=0.105/2;
     SIM_STEPS=zeros(5,1);
     INSTANCE_NUM=zeros(5,1);
     CUMM_IDLE=zeros(5,1);
     CUMM_IDLE_INST=zeros(5,1);
     TOTAL_COST=zeros(5,1);
     TOTAL_TIME=zeros(5,1);
     SELECT=ones(5,1);
     
     %LOOP OVER ALL TO FIND INSTANCE NUMBER;
     
     for type = 1:5
         instance_size = pow2(6-type);
         INSTANCE_NUM(type)=ceil(CONCURRENCY/instance_size);
         if INSTANCE_NUM(type) > 20
             INSTANCE_NUM(type)=20;
             SELECT(type)=0;
         end
         
        %SIMULATE with strict priority
        
        RESULTS=zeros(length(ETASKS_PTIME),6); % 
        for i=1:length(ETASKS_PTIME)
            RESULTS(i,4)=ETASKS_PTIME(i);
            RESULTS(i,5)=INSTANCE_NUM(type);
            RESULTS(i,6) = instance_size;
            RESULTS(i,1) = ceil(ETASKS_PTIME(i)/(instance_size*INSTANCE_NUM(type))); %time steps
            RESULTS(i,2) = RESULTS(i,1)*(instance_size*INSTANCE_NUM(type)) - ETASKS_PTIME(i); %idle vCPUs overall in these steps
          
%             if (ceil(ETASKS_PTIME(i)/instance_size) >20)
%                 %RESULTS(i,3) = INSTANCE_NUM(type) - 20; %means none were idle.Check this
                RESULTS(i,3) = floor(RESULTS(i,2)/instance_size);
%             else
%                 RESULTS(i,3) = INSTANCE_NUM(type) - ceil(ETASKS_PTIME(i)/instance_size); 
%             end
            
        end %end loop over i
        CUMM_IDLE_INST(type)=sum(RESULTS(:,3));
        CUMM_IDLE(type) = sum(RESULTS(:,2));
        TOTAL_TIME(type) = sum(RESULTS(:,1));
        TOTAL_COST(type) = TOTAL_TIME(type)*instance_size*INSTANCE_NUM(type)*base_price;
     
     end %end loop type

     %The number of instances for 32 is the base 
     %The heuristics is placed here
       %PRIORITY 1: TIME
       
       SELECT=ones(5,1);
       MIN_TIME=min(TOTAL_TIME);
       for type=1:5
           if(TOTAL_TIME(type)>MIN_TIME)
               SELECT(type)=0;
           end
       end
       
       %PRIORITY 2: COST
        MIN_COST=1e6;
       for type=1:5
           if(SELECT(type)==1)
               if(TOTAL_COST(type)<MIN_COST)
                   MIN_COST=TOTAL_COST(type);
               end
           end
           
       end
       
       for type=1:5
           if(SELECT(type)==1)
               if(TOTAL_COST(type)>MIN_COST)
                   SELECT(type)=0;
               end
           end
       end
       
       %PRIORITY 3: # of Instances
       
       MIN_INSTANCE=100;
       
       for type=1:5
           if(SELECT(type)==1)
               if(INSTANCE_NUM(type)<MIN_INSTANCE)
                   MIN_INSTANCE=INSTANCE_NUM(type);
               end
           end
       end
       for type=1:5
           if(SELECT(type)==1)
               if(INSTANCE_NUM(type)>MIN_INSTANCE)
                   SELECT(type)=0;
               end
           end
       end


end

