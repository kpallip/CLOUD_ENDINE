import networkx as nx

class dag_export(object):

    ''' dag : a networx x object that stores the dag.
              you can get nodes for instance D by D.nodes() and edges
              as D.edges()

        size: this was the size generation target, may not be exact.

        aospd_sched: an ordered list of nodes.
                    the schedule as determined by the series parallel heuristic
                     see attached aper Cordasco and Rosenberg

        dynamic_sched: an ordered list of nodes
                       this is the schedule computed using a dynamic greedy heuristic
                       the basic idea of which is: at time t, look at all elegible nodes,
                       pick the one to execute next which will give the greatest yield (i.e.
                       number of new nodes made eligible). Then recompute for all nodes, move
                       on to next step

        sydney_sched: an ordered list of nodes 
                      this is the new one, based on the heuristic we developed. I'm going to delay
                      details to our paper, but i hope to have a draft by next week

    '''
    def __init__(self,dag,size,aospd_sched,dynamic_sched,sydney_sched):
        self.dag = dag
        self.size = size
        self.aopsd_sched = aospd_sched
        self.dynamic_sched = dynamic_sched
        self.sydney_sched = sydney_sched
	
        return


    
