%Author: Vivek Pallipuram
%MAIN file that calls the CLOUD_ENGINE, Knee graph, and Cost-effectiveness
%analysis
STAT_RUNS=input('Enter the number of statistical runs for candidates');
%Call the Cloud Engine
[matfiles ] = CLOUD_ENGINE(STAT_RUNS);

