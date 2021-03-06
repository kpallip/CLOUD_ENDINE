I. INTRODUCTION

This README file describes how to use the cloud engine. The tool
is based on matlab files that invoke appropriate python scripts to 
produce the DAG simulation results. Specifically, for each of the 
16 DAGs in the DAG samples (i.e., CP32, CP64, WM32, WM64, and CONSTANT_RATIO)
the engine: 1) finds optimal resource instance candidates via the resource-selection
heuristic; 2) tests ALL possible configurations and plot a walltime vs. cost
curve and highlights how the instance candidates perform when paired
with AO and LOPT; and 3) performs a cost-effectiveness analysis on a user-specified
DAG with a given scheduling policy. 

System Requirements

1. MATLAB R2013b for Linux
2. Python 2.7 and later

II. SYNOPSIS

The top level file is main.m that invokes the CLOUD_ENGINE.m file (the primary workhorse).
The CLOUD_ENGINE.m automatically reads all the DAG samples from INPUT/DAGs folder and their
respective priorities from the INPUT/PRIORITY folder. Then, it invokes GENERATE_TASKS.m
that first converts DAGs to adjacency list and then creates a tasks file, which is
used by the discrete-event simulator for execution. The generated tasks file are stored
in INPUT/TASKS folder. The tasks file excerpt is under:

0,0,7200,0,5.00,5.00,1.500000e+00,10,0,15,10.000000,946080000,1,""
1,0,7200,0,5.00,5.00,1.500000e+00,10,0,16,10.000000,946080000,1,""
2,0,7200,0,5.00,5.00,1.500000e+00,10,0,17,10.000000,946080000,1,""
3,0,7200,0,5.00,5.00,1.500000e+00,10,0,21,10.000000,946080000,1,"0"
4,0,7200,0,5.00,5.00,1.500000e+00,10,0,22,10.000000,946080000,1,"0:1"
:
:
The format for all the lines is: <task ID>, <create time>, <estimated gops>, <error in gops>,
<input filesize>, <output filesize>, <memory>, <storage>, <status>, <priority>, <budget>, <deadline>, <max vCPU>, <Dependencies>.

The users can tweak parameters in AFAST_GENERATE_TASKS.m to create
tasks file conducive for their testing. After reading the tasks file,
CLOUD_ENGINE.m invokes in a loop, the cloud_sim_traditional_15Jan.py script (DISCRETE_EVENT SIMULATOR)
to test ALL possible instance configurations {2 vCPUs, 4 vCPUs, 
8 vCPUs, 16 vCPUS, 32 vCPUs} x 20 instances maximum x 16 DAGs per sample x 5 samples
for both AO and LOPT. For each DAG sample (i.e. CP32, CP64, etc.), the engine then invokes KNEE_GRAPH.m to obtain the knee curve and then
COST_EFFECTIVENESS.m to plot box plots for statistical analysis. 

Read the paper *cite* for the detailed description
of the cloud testing engine.

III. CODE FLOW

main.m (The main matlab file. Check matlab console for user inputs)
|
|_CLOUD_ENGINE.m (runs the resource-selection heuristic and tests all instance
      |                 configurations. Generate results for AO and LOPT when tested on all )
      |_CONCURR_CP_F1.m (If called, levelizes the DAG and computes critical
      |                   path length and degree of concurrency. The DAGs are already levelized in
      |                   LEVELS folder. Script reads LEVEL folder automatically so this file is bypassed)
      |_OPT_INSTANCES_F1.m (performs the resource-selection heuristic)
      |   
      |_AFAST_GENERATE_TASKS.m (Uses DAG Adjacency list to generate the task file for discrete-event
      |    |                           simulator. It is faster than adjacency matrix. The DAG info is used to "create" a task workflow)
      |    |__adjacency_list_only.py (python script to generate adjacency list (faster than matrix)
      | 
      |_ cloud_sim_traditional_15Jan.py (the discrete-event simulator. See
      |                                      DISCRETE-EVENT SIMULATOR below)
      |
      |_KNEE_GRAPH.m (plots the walltime vs. cost for all the test cases. Highlights
      |                those given by the instance candidates)
      |_COST_EFFECTIVENESS.m (Performs cost-effectiveness analysis on user specified
                        DAG. Plots the boxplots for cost and walltime)

 
						
IV. DISCRETE-EVENT SIMULATOR

Static Simulator: cloud_sim_traditional_15Jan.py

INPUT/INSTANCES: C3 Compute optimized instances. 

DAG Data-set:

INPUT/DAGS (Main Folder)
|
|
 SAMPLES (Directory Structure)
 |
 |__CP32 (DAGs with Critical Path: 32)
 |      |__AO
 |      |_DYNAMIC (LOPT)
 |      
 |__CP64 (DAGs with Critical Path: 64)
 |      |__AO
 |      |_DYNAMIC (LOPT)
 |      
 |__WM32 (DAGs with degree of concurrency: 32)
 |      |__AO
 |      |_DYNAMIC (LOPT)
 |      
 |__WM64 (DAGs with degree of concurrency: 64)
 |      |__AO
 |      |_DYNAMIC (LOPT)
 |      
 |__CONSTANT_RATIO (ratio between critical path and degree of concurrency
       |            equal to 1)
       |__AO
       |_DYNAMIC (LOPT)
 

INPUT/PRIORITY (Main Folder)
|
|
 SAMPLES (Directory Structure)
 |
 |__CP32 (DAGs with Critical Path: 32)
 |      |__AO
 |      |_DYNAMIC (LOPT)
 |      
 |__CP64 (DAGs with Critical Path: 64)
 |      |__AO
 |      |_DYNAMIC (LOPT)
 |      
 |__WM32 (DAGs with degree of concurrency: 32)
 |      |__AO
 |      |_DYNAMIC (LOPT)
 |      
 |__WM64 (DAGs with degree of concurrency: 64)
 |      |__AO
 |      |_DYNAMIC (LOPT)
 |      
 |__CONSTANT_RATIO (ratio between critical path and degree of concurrency
                  equal to 1)



How the discrete-event simulator works?

E.g.:
	./cloud_sim_traditional.py -i UCC_INSTANCES/c32xlarge8.csv -t UCC_TASKS/CP32/AO/tasks_4000u_8_AO.csv -cp

*No need to specify priority file. They are integrated within the tasks file,
which is produced by the matlab script GENERATE_TASKS.m*

Output for both:

<PAID WALLTIME IN HOURS>,<TOTAL COST>
      
Note: 1. Paid wall time is execution walltime rounded to nearest hour. For e.g.: If execution walltime is 489.4 then paid walltime is 490
      2. Total cost is the cost paid for the use of instances for time given
         in 1. 

V. HOW TO RUN THE ENGINE?

Open the main.m file and just run! Check the MATLAB console for any user input.

What output will I get?

Knee graphs for all the DAG samples.
Cost-Effectiveness analysis (boxplot) for any one DAG from all the DAG samples.

