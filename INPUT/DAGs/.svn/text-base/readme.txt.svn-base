This directory contains the following:

1. The subdirectory export_dags. It contains around 2000 DAGs generated in the LEGO format according to the methods described in the attached paper, using the harmonic distribution for the size of the LEGO building blocks.

2. the class file dag_exporter.py

3. the paper describing the generation method


REQUIRED DEPENDENCY:

The actual DAG (stored as export_dag.dag) is a networkx x digraph object. You can pip install networkx or obtain the source code and documentation from http://networkx.lanl.gov/index.html

If you just want to get a list of the nodes and edges, you can do the following (for an export_dag instance E:)

E.dag.nodes()
E.dag.edges() 

if you would like to turn this into an adjacency matrix, and you have numpy installed, you can do:

networkx.to_nump_matrix(E.dag) 

*********TO GENERATE ADJACENCY MATRICES ********



The file adjacency_matrix.py reads the pickled DAGs present in CP32, CP64,
WM32, WM64, and CONSTANT_RATIO folders and writes
adjacency matrices to a ./ADJACENCY_MATRICES folder.  

Command:

python adjacency_matrix.py PATH_TO_DAG

Or conversely, just run do ./adjacency_gen.sh to automatically read from the
pickled DAG folders and write it to ADJACENCY_MATRIX Folder.

  
