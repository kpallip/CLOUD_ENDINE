#Author: Dr. Vivek K. Pallipuram
#Date Modified: 03/20/2014
#Description: This Python Parser reads the Digraph object, extracts the adjacency matrix (writes it to a folder ADJACENCY_MATRIX) and writes the scheduling priority files (AO, Sydney, and Dynamic).

#!/usr/bin/python
from dag_exporter import *
import numpy as np
import networkx as nx
import sys
import pickle as pick

#lists of Area-Optimized SP DAG, Dynamic, and  Sydney Schedule for the input Graph#

aospd_schedule=[];
dynamic_schedule=[];
sydney_schedule=[];



##Function to write the priority file##

def write_priority(D,schedule,priority_file):
	"This function writes the priority for the nodes in the DAG. Note that the node IDs are NOT indexed conventionally. This function writes IDs conventionally."
	for i in range(len(D.dag.nodes())):
		for j in range(len(schedule)):
			if(schedule[j]==D.dag.nodes()[i]):
				break;
		priority_file.write(str(i)+","+str(j+1)+"\n");



#Input the files#
#print(sys.argv[1]);
f=open(sys.argv[1],"rb")

#load the pickle file
D=pick.load(f);

#print(D.dag.nodes()[5]);
#print(D.dag.edges());

#Get the adjacency matrix

Adj_M=nx.to_numpy_matrix(D.dag);

#####Debugging Start: Is Adj_M correct?####

#newG=nx.from_numpy_matrix(Adj_M);
#print(newG.nodes());
#print(newG.edges());

####Debugging End####

#Write the matrix to a file#
np.savetxt('./ADJACENCY_MATRICES/' + sys.argv[1]+'.txt',Adj_M);

##Load Scheduling##

#aospd_schedule = D.aopsd_sched;
#dynamic_schedule = D.dynamic_sched;
#sydney_schedule = D.sydney_sched;
#
###Write the AO scheduling to Priority File.##
#
#AO_priority_file = open("./PRIORITY/priority_AO_"+sys.argv[1]+".txt","a+");
#write_priority(D,aospd_schedule,AO_priority_file);
#AO_priority_file.close();
# 
###Write Sydney Schedule to Priority File.##
#
#sydney_priority_file = open("./PRIORITY/priority_sydney_"+sys.argv[1]+".txt","a+");
#write_priority(D,sydney_schedule,sydney_priority_file);
#sydney_priority_file.close();
#
###Write Dynamice Schedule to Priority File.##
#dynamic_priority_file = open("./PRIORITY/priority_dynamic_"+sys.argv[1]+".txt","a+");
#write_priority(D,dynamic_schedule,dynamic_priority_file);
#dynamic_priority_file.close();



#print(D.aopsd_sched);
#print(D.aopsd_sched[5]);

