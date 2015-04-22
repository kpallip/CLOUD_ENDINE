#Author: Dr. Vivek K. Pallipuram
#Date Modified: 06/04/2014
#Description: This Python Parser reads the Digraph object, extracts the adjacency matrix. and computes the level of each node using Depth-First Search (DFS) algorithm.
#The maximum graph level is the maximum distance from a source node to a leaf node. This level is also the 'critical path' of the graph. The maximum distance from any source to a node is called its 'node level'. 

#How to execute? : python matlab_adjacency.py <PATH_TO_DIGRAPH FILE>
#Std outputs the node-level for each node


#!/usr/bin/python
from dag_exporter import *
import numpy as np
import networkx as nx
import sys
import pickle as pick
from collections import defaultdict
#import matplotlib.pyplot as plt

#Default Dictionary that serves as Adjacency List.#

Deps= defaultdict(list)

#Default Dictionary that serves as Dependencies list conducive to matlab

IDeps=defaultdict(list) # Read name as


Distance_From_Source=defaultdict(list) # A default dictionary where the key is node and values in the list are distance from th ith source

Dependency_flag=[] #If true then this task is not a source (has dependencies)

matrix_row=[] #Reads the row of a matrix

#Input the files#

f=open(sys.argv[1],"rb")

#load the pickle file

D=pick.load(f)

#Get the adjacency matrix

Adj_M=nx.to_numpy_matrix(D.dag) #In this Adj_M, the row i influences the indices
Adj_MT=Adj_M.transpose() #The indices influence this row 

Sources=[]
Sinks=[]
Distance = []

NULL=-1001
INFINITY=1e6


#============Depth First Search (DFS) to find node levels==================#

def DFS():
	"""Performs Depth-First Search to find the level of each node"""

	Q=[] #A list to store the source nodes

#Find the sources and sinks first
	
	for i in range(len(D.dag.nodes())):
		Distance.append(INFINITY)
		if(Dependency_flag[i]==0):	#If the node is not dependent on any one, it is a source!
			Sources.append(i)
		if(not (i in Deps.keys())):	#If the node has no children or dependents, it is a sink!
			Sinks.append(i)


#Iterate over all sources. Find node distances/node-levels from each source

	#print(Sources);
	#for iter in range(len(Sources)):

	while Sources:

		source=Sources.pop(0)
		Q.append(source)
		
		#for each source, give the distance infinity to all nodes	
		for i in range(len(D.dag.nodes())):
			if(not(Distance[i]==0)):
				Distance[i]=INFINITY
						
		Distance[source]=0;#Source is at level 0

		while Q:
			i=Q.pop()
			if (i in Deps.keys()): #If this node is a key in Deps, it has dependents. 
				for j in Deps[i]:
					if (Distance[j] == INFINITY):
						#Pred[j]=i;
						Distance[j] = Distance[i] + 1
						Q.append(j)
						Distance_From_Source[j].append(Distance[j])

	#	print(Distance_From_Source);
	#	input();

	#print(Distance_From_Source);
	#input();

	for i in range(len(D.dag.nodes())):
		if ((i in Distance_From_Source.keys())):
			Distance[i]=max(Distance_From_Source[i]);

	#print(Distance);


#======ENTRY POINT: Creating the Adjacency list (Default Dict). Also write dependencies to a file file=====#

#Ambiguity because 0 is also a task ID

for i in range(len(D.dag.nodes())):

	matrix_row=Adj_M[i]

	matrix_rowT=Adj_MT[i]

	tuple=matrix_row.shape #Get the dimensions of the matrix
	
	flag=0

	for j in range(tuple[1]):

		if(matrix_row.item(j)):
			
			Deps[i].append(j)
		
		if(matrix_rowT.item(j)):
		
			IDeps[i].append(j)		

			flag=1
	if not flag:
		IDeps[i].append(-1000) #No dependencies
	
	Dependency_flag.append(flag)


#=============Call DFS===========#

#DFS()

for key in IDeps:
	for i in range(len(IDeps[key])):
		print "%d," %IDeps[key][i],
	print "-1000,\n"
#print(D#eps[4]);
	#
#print(D#ependency_flag);
#for i i#n range(len(Distance)):
#	#sys.stdout.write(str(Distance[i])+' ')
        #
        #
        #
        #
        #
        #
        #
        #
