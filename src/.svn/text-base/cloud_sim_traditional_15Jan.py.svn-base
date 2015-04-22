#!/usr/bin/python
import time
from numpy import *
from math import sqrt, ceil
from heapq import heappush, heappop
from collections import defaultdict
from collections import OrderedDict
import time
import sys
import re
import csv
from time import sleep
import argparse
#from random import random
#IMPORTANT: Throughout this code, keep a watch on notes of the format "Vivek Note mm/dd/yyyy" for updates. This will guide to debug/change code in future
#Vivek Note on 08/19/2014: VIEW IMAGES AS VCPUS NOW! In Image class, see that cost has been divided by number of vCPUs. Assignment is one task per vCPU.
#Vivek Note 10/17/2014: Now instance file should have an additional comma separated value that tells the number of instances
#Vivek Note 02/05/2015: This file incorporates S3 storage modeling. Upload and Download bandwidths are modeled using real traces on S3.
# Due to S3 storage modeling, we don't require network. All tasks from vCPUs forward data to S3 and proceed. Useful for checkpointing and failure recovery.

_INIT=0
_PENDING=1
_EXEC=2
_INCOMPLETE=3
_COMPLETE=4
_FAIL=5

_CANNOT_TASK=-1
_CANNOT_IMAGE=-2
_OK=1

DEBUG=0
TRACE=0
SUMMARY=0
LOG=0
TIME_UNIT=3600
VERY_SMALL=0.00000000000000001
TOTAL_INTENDED_BUDGET=0
TOTAL_COST=0
TOTAL_TIME=0
TOTAL_IDLE_COST=0
TOTAL_COMM_COST=0
AVG_COMPLETION_TIME=0
TOTAL_TASKS=0
EXTRA_BUDGET=100000000000000
AVG_DEP_PTASK=0
NTASKS=0
EXECUTION_TIME=0
IDLE_TIME=0
Networks={'VeryLow':125,'Low':12.5,'Moderate':1.25,'High':0.125,'10Gigabit':0.012}

#Vivek Note 19th Jan 2015: CPU performance scale. Using traces from Schad et al., we fit Weibull distributions for the Xeon and Opteron Performance.
#Schad et al. Runtime measurements in the cloud: observing, analyzing, and reducing variance.VLDB 2010
#Below are the scale and shape parameters. 

XEONSCALE=116017 #In terms of CPU UBench score
XEONSHAPE=259.3
OPTERONSCALE=58007.5
OPTERONSHAPE=184.92
UBENCHMAX=122831

#Vivek Note 19th Jan 2015: We performed 200 iterations of 100 MB uploads and downloads between an EC2 instance (Virginia us-east) to S3 (Oregon).
#The resulting distributions were fit the best by Weibull distribution; the scale and shape parameters appear under.
#Note that a few extreme outliers were observed and suppressed for the fit.

UPLOADSCALE= 25.559 #in MB/s
UPLOADSHAPE = 4.85
DOWNLOADSCALE=20.93 #in MB/s
DOWNLOADSHAPE=5.03

#Vivek Note 16 Jan 2015: Network parameters. Schad et al. report a Gaussian fit for EC2 network bandwidth. Below are the parameters from their traces
MU=583.94 #in KB/s
SIGMA=58.03 #in KB/sec

EntryHeap=[] # tasks with no dependencies, but that are not ready to be executed, sorted by create_time
ExecHeap = [] # tasks executing, sorted by event_time
ReadyHeap = [] # tasks ready to execute (cleared dependencies), sorted by priority
Tasks=[]
Replicas={}
Deps= defaultdict(list)
WHICH_TASKS=defaultdict(list)
Where_Executed={} #Vivek Note 08/20/2014: A dictionary that tells where the given task was executed (on which vCPU). Updated in assign_toImage function. Possible use in network modeling. Not fully functional
IdleImgs=[]
Global_Images=[] #Vivek Note 08/20/2014: An additional global list of images for any look-up. Immutable

#Vivek Note 08/20/2014: Below three are used to create a priority list used by traditional_simulate function. NOTE: The scheduling priority is in the task file.

TASK_NUMBER=[]
TASK_PRIORITY=[]
Priority =[] #Vivek: From Verifier, a Priority List

class Ddict(dict):
	def __init__(self, default=None):
		self.default = default

	def __getitem__(self, key):
		if not self.has_key(key):
			self[key] = self.default()
		return dict.__getitem__(self, key)
# end of bidimensional dict

class Scheduler:
	
	def __init__(self,schedule_model,pricing_model,power_model,deadline_model):
		self.schedule_model=schedule_model
		self.pricing_model=pricing_model
		self.power_model=power_model 
		self.deadline_model=deadline_model
		

	def estimate_maxbudget(self,task,min_gops):
		# do something with pricing_model
		max_budget=task.budget
		return max_budget
		
		
	def estimate_mingops(self,task,this_time):
		# do something with the deadline_model
			
		min_gops=task.est_gops/(task.deadline-this_time+VERY_SMALL) # minimum estimated gops in the resource to complete
		return min_gops
	
	def estimate_costbenefit(self,task,instance):
		return 0
		
	def estimate_fitness(self,time_complete,time_cushion,res_time_remaining,task,res,this_time):
		
		# NOTE: rethink this sentence! penalty for being busy
		if res.busy_until_time > this_time:
			return -1
		
		if res_time_remaining > 0 :
			time_units=ceil((time_complete-res_time_remaining)/TIME_UNIT)

			eval=(time_cushion)/((time_units*res.cost)+VERY_SMALL) #Vivek: eval is proportional to time_cushion (residual time after execution until deadline). Higher eval means higher fitness
		else:
			time_units=ceil(time_complete/TIME_UNIT)
			eval=1/(time_units*res.cost)+VERY_SMALL
		
		return eval
			
		
	
class Replica:
	
	def __init__(self,id,id_task,id_image,nvCPU,start_time,end_time,event_time,status,in_comm,out_comm,this_cost):
		self.id=id
		self.id_task=id_task
		self.id_image=id_image
		self.start_time=start_time
		self.end_time=end_time
		self.next_time=event_time
		self.nvCPU=nvCPU
		self.status=status # current status
		self.identifier=str(id_image)+'_'+str(id_task)+'_'+str(id)
		self.in_comm=in_comm
		self.out_comm=out_comm
		self.cost=this_cost
		# add to the ExecHeap of events
		heappush(ExecHeap, (event_time, self.identifier))
		# add to the dictionary of tasks
		Replicas[self.identifier]=self
	
	def execute(self,this_time,amis):
		if self.status==_COMPLETE:	
			Tasks[self.id_task].finish_task(this_time,amis.Images[self.id_image],self)
			Tasks[self.id_task].clear_dependencies(this_time)
			
			global TOTAL_COST,AVG_COMPLETION_TIME
			#TOTAL_COST=TOTAL_COST+self.cost
			AVG_COMPLETION_TIME=AVG_COMPLETION_TIME+(self.end_time-self.start_time)
			
			if TRACE==1:
				print "1, "+str(self.id_image)+", "+str(self.id_task)+", "+str(self.id)+", "+str(amis.Images[self.id_image].type)+", "+str(self.start_time)+", "+str(self.end_time)+", "+str(self.cost)
			if TRACE==2:
				print "1, "+str(self.id_task)+", "+str(self.id_image)+", 1, "+str(self.start_time)+", "+str(self.end_time)
				
				
		if self.status== _INCOMPLETE:
			if TRADITIONAL_DEBUG:
				print "INCOMPLETE"
			#TOTAL_COST=TOTAL_COST+self.cost
			Tasks[self.id_task].enqueue_task(this_time)
				
				
		if self.status == _FAIL:
			if TRADITIONAL_DEBUG:
				print "FAIL"
			#TOTAL_COST=TOTAL_COST+self.cost
			Tasks[self.id_task].enqueue_task(this_time)
		

class Task:
	"""A task class"""

	def __init__(self,id,create_time,est_gops,err_gops,input_fileSize,output_fileSize,memory,storage,status,priority,budget,
		deadline,max_nvCPU,dep_str,IO,SIM_TIME):
			
		
		"""Init method, assigning default values and initializing the metrics dict"""
		self.id = id # id of the task
		self.create_time = create_time
		self.nReplicas=0
		self.Replicas=[]
		self.max_nvCPU=max_nvCPU #Vivek Note 08/2014: Number of max. vCPUs per task is an indicator of 'parallelism'
		self.active_deps={}
		self.status=0
		# estimated and real gops
		self.est_gops=est_gops
		self.gops = random.uniform(est_gops-err_gops, est_gops+err_gops)

		#Vivek Note 01/22/2015: Constant 100 MB data to store and read from S3.
		self.input_fileSize=100
		self.output_fileSize=100
		#Vivek Note 01/22/2015: If file sizes need to be read from the task file		
		if IO:
			self.input_fileSize=input_fileSize
			self.output_fileSize = output_fileSize
		
		self.memory=memory
		self.storage=storage

		#Vivek Note 08/22/2014: priority assigned by the scheduler
		self.priority=priority
		self.p_fail=0
		self.budget=budget
		self.deadline=deadline  # very IMPORTANT rethink everything in terms of deadline
		self.cannot_schedule=0
		
		# dependencies mean that this task depends on these ones
		if dep_str:
			self.dependencies = [int(x) for x in dep_str.split(":")]
			self.nDependencies=len(self.dependencies)
			for dp in self.dependencies:
				self.active_deps[dp]=1
				Deps[dp].append(id) # Deps[dp] depends on this one
		else:
			self.dependencies=[]
			self.nDependencies=0
			#self.enqueue_task(SIM_TIME) #Vivek Note 08/22/204: DO NOT ENQUEUE TASKS JUST YET! because the traditional_simulate performs STRICT ENFORCEMENT
			
		global AVG_DEP_PTASK	
		AVG_DEP_PTASK=AVG_DEP_PTASK+self.nDependencies
			
		
	def finish_task(self,this_time,image,rep):
		global IdleImgs,TOTAL_TASKS
		if self.status != _COMPLETE:	
			self.status=_COMPLETE
			TOTAL_TASKS=TOTAL_TASKS+1
			
		image.release_storage(self.storage)
		self.end_fromImage(image, rep.nvCPU)
		if image.busy_until_time <= this_time:
			image.idle_start=this_time
			IdleImgs.append(image)

	
	def enqueue_task(self,this_time):
		global ReadyHeap
		global EntryHeap
		
		
		if self.create_time <= this_time:
			heappush(ReadyHeap, (self.priority, self.id)) # if the task has no dependencies, enqueue on the ready heap
			if DEBUG:
				print ReadyHeap
		else:
			heappush(EntryHeap, (self.create_time, self.id)) # if the task has no dependencies, enqueue on the entry heap
			if DEBUG:
				print EntryHeap
							
	
	def clear_dependencies(self,this_time):
		for dep in Deps[self.id]:
			Tasks[dep].remove_dependency(self.id,this_time)
	
	
	def remove_dependency(self,id_dep,this_time):
		was_active=self.active_deps[id_dep]
		
		if was_active:		
			self.active_deps[id_dep]=0
			self.nDependencies=self.nDependencies-1

	#Vivek Note 08/20/2014: Below lines were commented out because we are strictly enforcing the priority list
		
	#	if self.nDependencies==0:
	#		global ReadyHeap
	#		global EntryHeap
	#		if self.create_time <= this_time:
	#			if TRADITIONAL_DEBUG:
	#				print "Inserting in ReadyHeap:%d which was dependent on %d" %(self.id,id_dep)
	#			heappush(ReadyHeap, (self.priority, self.id)) # if the task has no dependencies, enqueue on the ready heap
	#			if DEBUG:
	#				print ReadyHeap
	#		else:
	#			heappush(EntryHeap, (self.create_time, self.id)) # if the task has no dependencies, enqueue on the entry heap
	#			if DEBUG:
	#				print EntryHeap
		
		
		
		
	def print_info(self):
		print "id: " + str(self.id)
		print "create time: " + str(self.create_time)
		print "est_gops: " + str(self.est_gops)
		print "gops: " + str(self.gops)
		print "input_fileSize: " + str(self.input_fileSize)
		print "output_fileSize: " + str(self.output_fileSize)
		print "memory: " + str(self.memory)
		print "storage: " + str(self.storage)
		print "priority: " + str(self.priority)
		print "gops: " + str(self.gops)
		print "budget: " + str(self.budget)
		print "deadline: " + str(self.deadline)
		print self.Replicas
		print self.active_deps
		
		print "========================"
			
	def add_replica(self,id_image,nvCPU,start_time,end_time,event_time,status,in_comm,out_comm,this_cost):
		rep = Replica(self.nReplicas,self.id,id_image,nvCPU,start_time,end_time,event_time,status,in_comm,out_comm,this_cost)
		self.nReplicas=self.nReplicas+1
		self.Replicas.append(rep.identifier)

		
	def replica_changeStatus(self,rep,status):
		Replicas[rep.identifier].status=status
			
			
	def assign_toImage(self, image, amis, params, this_time):
		global EXTRA_BUDGET,IdleImgs,Global_Images

		
		#Vivek Note 08/20/2014: Check where the predecessors were executed. And in_comm is maximum of task communication time executing in another instance
		last_in_comm=0
		in_comm=0
		which_dependency=-1

		#Vivek 08/21/2014: the vCPU and parents vCPU should be on the same instance. So, just do (image.id)/self.vCPU == Where_Executed[dependency].vCPU
		#The following section will not execute for source tasks

		start_time=max(params['task.start_time'],image.busy_until_time,this_time)

		#Vivek Note 02/05/2015: This code section was intended to model network communications. However, it is not functional due to unresolved task-to-task sync. issues
		if 0:	
			for dependency in self.dependencies:
			#print "I am "+str(self.id)+" set to execute on "+str(image.id)
			#print "dependency "+str(dependency)+" executed on "+str(Where_Executed[dependency])
				if dependency in Where_Executed.keys():
				#if (image.id/image.vCPU != Where_Executed[dependency]/Global_Images[Where_Executed[dependency]].vCPU):#Vivek 23Sept: If executed on different Instances
					if(image.parent_id!=Global_Images[Where_Executed[dependency]].parent_id): #Vivek: 26th Sept: image is now vCPU ID and a set of vCPUs belong to a 'parent' instance. Use parent_id to check if two vCPUs reside on the same parent or not.
					#in_comm=Tasks[dependency].input_fileSize*Networks[Global_Images[Where_Executed[dependency]].network] #Vivek 16Jan commented
						in_comm=image.communicate(start_time,self.input_fileSize)
						if in_comm > last_in_comm:#Vivek 23Sept: I think this IF is just used for printing in the next IF statement
							last_in_comm=in_comm
							which_dependency=dependency
		#Update in_comm
			in_comm = last_in_comm

		#Vivek Note 01/19/2015: New S3 only synchronization. Tasks read from S3 and write to S3.

		in_comm=image.communicate_S3(start_time,self.input_fileSize,0);
	
		#Vivek: Just for debugging
		if TRADITIONAL_DEBUG:	
			if which_dependency in Where_Executed.keys():
				print "Task "+str(self.id)+" executing on "+str(Global_Images[image.id].parent_id)			
				print "The communication time from dependency is " + str(in_comm)+" from dependency "+str(which_dependency)+" executed at "+str(Global_Images[Where_Executed[which_dependency]].parent_id)

				raw_input("Hit Enter")

		#Vivek 08/20/2014: Note where this task is set for execution. May help in network communication modeling    

		Where_Executed[self.id]=image.id	
	
		if image.on==0:
			image.on=this_time+0.0000000001
			
		this_cost=0
		nvCPU=min(image.nvCPU_available,params['image.nvCPU']) #Vivek: params['image.nvCPU'] is always 1
		params['image.nvCPU']=nvCPU # update in params
		
		img_gops=image.gops_perCPU*nvCPU	# gops to use given the number of vCPUs
		
		#start_time=max(params['task.start_time'],image.busy_until_time,this_time) #start time is always in the beginning

		#Vivek: Start Overhead Added Here: start_time=start_time + overhead

		if img_gops <= 0:
			return -1
		
		image.nvCPU_available=image.nvCPU_available-nvCPU # reduce the num of vCPU available
		image.gops_available=image.gops_available-(image.gops_perCPU*nvCPU) # reduce the number of gops available
			
		#end_time=ceil(in_comm + start_time + self.gops/img_gops) # calculate end_time of the replica. Vivek 08/20/2014: add in_comm here. Why ceil???
		end_time=(in_comm + start_time + self.gops/img_gops)

		# add the communication times
		
		#Vivek: 08/20/2014 commented these two lines
		#in_comm=image.communicate(start_time,self.input_fileSize)
		
		#end_time=end_time+in_comm
					
		if end_time > image.end_time:
			this_cost=image.increase_end_time(end_time,self.budget)
			self.budget=max(0,self.budget-this_cost)

		if end_time <= image.end_time: # if the task will complete within the time allocated
			
			out_comm=0
		#	if self.id in Deps.keys():
		#		out_comm=image.communicate(end_time,self.output_fileSize) #Vivek: remove extra in_comm from end_time. Vivek 08/20/2014: DO NOT NEED out_comm now(?)

			#Vivek Note 01/19/2015: Write the output to S3
			out_comm=image.communicate_S3(end_time,self.output_fileSize,1)
		#	print "\n out_comm:"+str(out_comm)
			end_time=end_time+out_comm
			event_time=end_time
			status=_COMPLETE
		else:
			out_comm=0
			event_time=image.end_time
			status=_INCOMPLETE
		
		 #Vivek: These lines added to evaluate the execution cost for this image

		if ELASTIC:
			
			if (image.id%amis.Instances[0].vCPU==0): #Vivek 10/19" If the virtual CPU is the first one, only then accrue the cost
				amis.Instances[image.parent_id].instance_cost=amis.Instances[image.parent_id].instance_cost + amis.Instances[image.parent_id].cost*(ceil((end_time - start_time)/TIME_UNIT))
				#amis.Instances[image.parent_id].logged= amis.Instances[image.parent_id].logged+ceil((((end_time - start_time)/TIME_UNIT)))
	
				#print str(ceil(((end_time - start_time)/TIME_UNIT))) + " " + str(amis.Instances[image.parent_id].instance_cost) + " " + str(image.id)
		else:	
			image.execution_cost=image.execution_cost + image.cost*((end_time - start_time)/TIME_UNIT);

		#Vivek: Added on 7th July
		global EXECUTION_TIME,IDLE_TIME

		
	
		EXECUTION_TIME=EXECUTION_TIME+(end_time - start_time);
	
	#	if self.p_fail >= random.random(): # if the task will fail
	#		event_time=random.uniform(start_time,end_time)
	#		status=_FAIL
	
		if params['index_idle']>=0:
			
			del IdleImgs[params['index_idle']] # remove from idle
			
			idle_cost=0
			if image.end_time<this_time: # print idle + unused
				if image.idle_start>0:	
					idle_cost=image.cost*((image.end_time-image.idle_start)/3600.0)
					#Vivek: Added the line below
					image.idle_cost=image.idle_cost+idle_cost

				if TRACE==1:
					print "0, "+str(image.id)+", 0, 0, "+str(image.type)+", "+str(image.idle_start)+", "+str(image.end_time)+", "+str(idle_cost)
					print "3, "+str(image.id)+", 0, 0, "+str(image.type)+", "+str(image.end_time)+", "+str(this_time)+", 0"
			else:
				if image.idle_start>0:
					#Vivek: Actually, the image is idle until start_time. this_time was in original code
                                        idle_cost=image.cost*((this_time-image.idle_start)/3600.0)
					IDLE_TIME=IDLE_TIME + (this_time-image.idle_start)
					#idle_cost=image.cost*((start_time-image.idle_start)/3600.0)
					#Vivek: Added the line below
					image.idle_cost=image.idle_cost+idle_cost
				if TRACE==1:
					print "0, "+str(image.id)+", 0, 0, "+str(image.type)+", "+str(image.idle_start)+", "+str(this_time)+", "+str(idle_cost)
					
				
			global TOTAL_IDLE_COST
			TOTAL_IDLE_COST=TOTAL_IDLE_COST+idle_cost
			
			if TRACE==2:
				#print idle
				if image.end_time<this_time: # print idle + unused
					print "0, 0, "+str(image.id)+", 1, "+str(image.idle_start)+", "+str(image.end_time)
					print "3, 0, "+str(image.id)+", 1, "+str(image.end_time)+", "+str(this_time) # unused
				else: # print only idle
					print "0, 0, "+str(image.id)+", 1, "+str(image.idle_start)+", "+str(this_time)
					
			if image.idle_start > 0:
				image.idle_start=0
					
	

		self.add_replica(image.id,nvCPU,start_time,end_time,event_time,status,in_comm,out_comm,this_cost) # add the task replica, and to the queue
		
		return self.nReplicas
			

		
		
	def end_fromImage(self, image, nvCPU):
		image.nvCPU_available=image.nvCPU_available+nvCPU # increment the num of vCPU available
		image.gops_available=image.gops_available+(image.gops_perCPU*nvCPU) # increment the number of gops available

	

			


class AMIs:
	def __init__(self,filename):
		global IdleImgs, Global_Images #Vivek: A global list of Idle Images. We will operate on IdleImgs but Global_Images are IMMUTABLE
		self.Instances=[] #Vivek: Just the list of Instances. Does not change
		self.Images=[]
		id_img=-1
		id_inst=-1
		self.nImages=0
		
		for row in csv.reader(open(filename), delimiter=','):
		#	id_inst=id_inst+1
		#	inst=Instance(id_inst,row[0],row[1],int(row[2]),float(row[3]),float(row[4]),float(row[5]),row[6],float(row[7]),float(row[8]))
		
			if res:
				num_res=res #Vivek Note 01/14/2015: Number of resources from the task file
			else:
				num_res=int(row[10]) #Vivek Note 01/14/2015: else 1

			if 1:
				AMD=-1
			
			for iterator in range(num_res):#Vivek Note 10/17/2014: change to row[10] for the number of instances from 		
				id_inst=id_inst+1

				#Vivek Note 02/05/2015: Geometric distribution where AMD performance is selected with p=0.2 Geometric random numbers, k are produced.
				#k denote the number of Xeon instances before an AMD instance. if k=4, then an AMD is selected after 4 Xeon selections
				if 1:
					if(AMD==-1):
						AMD=random.geometric(0.2)

					if(AMD==0): #Select an AMD after Xeon selections have been done
						inst=Instance(id_inst,row[0],row[1],int(row[2]),float(row[3]),float(row[4]),float(row[5]),row[6],float(row[7]),float(row[8]),0) 
						AMD=-1
					else:
						inst=Instance(id_inst,row[0],row[1],int(row[2]),float(row[3]),float(row[4]),float(row[5]),row[6],float(row[7]),float(row[8]),1)
						AMD=AMD-1
				else:
					inst=Instance(id_inst,row[0],row[1],int(row[2]),float(row[3]),float(row[4]),float(row[5]),row[6],float(row[7]),float(row[8]),int(row[11]))
	
		
				self.Instances.append(inst)
				
				nimages=int(row[9]) # create number of reserved images (vCPUs in our case). Vivek Note 09/25/2014: Remember the modified view. images are now vCPUs as we have ONE_TASK_PVCPU
				for i in range(nimages):
					image=Image(self.nImages,inst,0)
					self.Images.append(image)
					Global_Images.append(image) #Vivek Note 08/20/2014: Added to access an immutable list of images
					IdleImgs.append(image) #Vivek Note 01/14/2015: Append the idle vCPU (in our context)
					self.nImages=self.nImages+1
				
				
			if DEBUG:
				inst.print_info()
				print row
				
	def select_image(self,task,params,S):
		eval=-1
		last_eval=0
		#print task.id
		#print params['task.start_time']
		cnt=0
		idx=-1
		for img in IdleImgs:#Vivek Note 09/26/2014: Here is the round-robin checking of all the images that are not idle
			eval=self.evaluate_resource(task,img,params,img.busy_until_time,S)
			
			#print img
			#print eval
			if DEBUG:
				print "Evaluate image"
				print "Evaluate image: "+str(eval)+", id "+str(img.id)+", type:"+img.type+", busy until: "+str(img.busy_until_time)
				
			if eval > last_eval:
				save_image=img
				idx=cnt
				last_eval=eval
			cnt=cnt+1
		
		if last_eval > 0: #Vivek: Should be last_eval; it was eval initially
			#print "size of idle image list:" +str(len(IdleImgs))
			params['index_idle']=idx
			#Uncomment below two for forcing RR. 
			params['index_idle']=0
			save_image=IdleImgs[0]
			return save_image	
		return False
		
		
	def select_instance(self,task,params,S):
		eval=-10000000
		last_eval=0
		for inst in self.Instances:
			eval=self.evaluate_resource(task,inst,params,params['task.start_time'],S)
			if DEBUG:
				print "Evaluate instance"
				print inst
				print eval
			if eval > last_eval:
				save_inst=inst
			last_eval=eval
		if eval > 0:
			return save_inst
			
		return False
		
		
	def release_images(self,this_time):
		total_cost=0
		for img in self.Images:
			total_cost=total_cost+img.calculate_cost(this_time,1)
		return total_cost
		
#Vivek: Added this function to evaluate the total execution cost

	def execution_costs(self):
		total_execution_cost=0
		
		if ELASTIC:
			for inst in self.Instances:
				total_execution_cost = total_execution_cost + inst.instance_cost
			#	if(inst.id==1):
			#		print str(inst.instance_cost)+" " +str(inst.id) + " " +str(inst.logged)

		else:
			for img in self.Images:
				if DEBUG:
					print "Execution cost on" + str(img.id)+"="+str(img.execution_cost)
				total_execution_cost=total_execution_cost+img.execution_cost
		return total_execution_cost

        #Vivek: Added this function to evaluate the total idle cost

	def idle_costs(self):
		total_idle_cost=0
		for img in self.Images:
			print "Idle cost on" + str(img.id)+"="+str(img.idle_cost)
			total_idle_cost=total_idle_cost+img.idle_cost
		return total_idle_cost
		
	def evaluate_resource(self,task,res,params,busy_until_time,S):
		# 'task.min_gops':min_gops,
		# 'task.budget':max_budget,
		# 'task.start_time':this_time,
		# 'image.end_time':this_time,
		# 'image.nvCPU':1,
		# 'policy':policy
		
		nvCPUs=min(task.max_nvCPU,res.vCPU)
		
		#if busy_until_time > params['task.start_time'] :
			#min_gops=S.estimate_mingops(task,busy_until_time)
			
		if res.memory >= task.memory and res.storage >= task.storage: # available gops are enough
			
			time_complete=task.est_gops/(res.gops_perCPU*nvCPUs) # time to complete in this resource. Vivek 08/19/2014: This should be modified such that it is evaluated for a task on ONE vCPUs
			time_cushion=task.deadline-(busy_until_time+time_complete) # time to complete before the deadline
			
			if res.end_time > 0:
				#res_time_remaining=res.end_time-(busy_until_time+time_complete)
				res_time_remaining=res.end_time-(max(busy_until_time,params['task.start_time']))#Vivek: For subsequent SIM steps, res.end_time and busy_until_time will be equal
			else:
				res_time_remaining=0
			
			res_eval=S.estimate_fitness(time_complete,time_cushion,res_time_remaining,task,res,params['task.start_time'])
			
			if DEBUG:
				print "enough resources time_complete, time_cushion, res_time_remaining, res.end_time, res_eval"
				print time_complete
				print time_cushion
				print res_time_remaining
				print res.end_time
				print res_eval
							
			return res_eval
			
		else:
			if DEBUG:
				print "NOT enough resources"
			return _CANNOT_TASK
			
			
	
class Instance:
	
	def __init__(self,id,family,type,vCPU,ECU,memory,storage,network,cost,power_pergop,arch_type):
		self.id=id
		self.family=family
		self.type=type
		self.vCPU=vCPU
		self.ECU=ECU
		self.memory=memory
		self.storage=storage
		self.network=network
		self.gops=self.get_gops(ECU,arch_type)
		#print "\n gops:" +str(self.gops)
		self.gops_perCPU=self.gops/self.vCPU
		self.power_pergop=power_pergop
		self.cost=cost
		self.end_time=0
		self.busy_until_time=0
		self.p_fail=0
		self.instance_cost = 0
		self.logged=0
	def print_info(self):
		print "id: " + str(self.id)
		print "family: " + str(self.family)
		print "type: " + str(self.type)
		print "vCPU: " + str(self.vCPU)
		print "ECU: " + str(self.ECU)
		print "memory: " + str(self.memory)
		print "storage: " + str(self.storage)
		print "network: " + str(self.network)
		print "gops: " + str(self.gops)
		print "power/gop: " + str(self.power_pergop)
		print "cost: " + str(self.cost)
		
		temp=self.ECU/self.gops
		
		
	def get_gops(self,ECU,arch_type):
		# theoretical peak is 4.4 GOPS per ECU
		# performance measures indicate that in rela life this is 6 to 8 X lower
		# ref: http://www.st.ewi.tudelft.nl/~iosup/ec2perf-sci-comp09cloudcomp.pdf
		#Vivek Note 02/05/2015: Modeling the performance of Xeon and Opteron
		if arch_type:
			gops=(ECU*XEONSCALE*random.weibull(XEONSHAPE))/UBENCHMAX
		else:
			gops=(ECU*OPTERONSCALE*random.weibull(OPTERONSHAPE))/UBENCHMAX
		return gops
		

class Image(Instance):
	
	def __init__(self,this_id,parent,start_time):
		self.id=this_id
		self.parent_id=parent.id
		self.family=parent.family
		self.type=parent.type
		self.vCPU=parent.vCPU
		self.ECU=parent.ECU
		self.memory=parent.memory
		self.storage=parent.storage
		self.network=parent.network
		self.gops=parent.gops
		self.gops_perCPU=parent.gops_perCPU
		self.power_pergop=parent.power_pergop
		self.cost=parent.cost/parent.vCPU #Vivek: Getting the cost per vCPU
		self.p_fail=parent.p_fail
		self.comm_total=0
		self.idle_start=0
		self.on=0
		
		# addtional variables for use
		self.start_time=start_time
		self.end_time=start_time+3600
		self.busy_until_time=start_time
		self.nvCPU_available=self.vCPU
		self.gops_available=self.gops
		self.events=[]

		 #Vivek: Added the variable execution_cost and idle cost
		self.execution_cost=0
		self.idle_cost=0
		
	#def assign_task
	
	def communicate(self, start_time, filesize):
		self.comm_total=self.comm_total+filesize
		factor=Networks[self.network]

		#Vivek 16th Jan: Logistic distribution
		if TRADITIONAL_DEBUG:	
			factor=random.logistic(MU,SIGMA)
			if factor <=0:
				factor=MU		

 		comm_time=filesize/factor
		factor_cost=0
		comm_cost=filesize*factor_cost
		# return an overhead of time for communication
		# based on the network type and the filesize, the overhead is smaller or larger
		global TOTAL_COMM_COST
		TOTAL_COMM_COST=TOTAL_COMM_COST+comm_cost
		
		if TRACE==1:
			print "2, "+str(self.id)+", 0, 0, "+str(self.type)+", "+str(start_time)+", "+str(start_time+comm_time)+", "+str(comm_cost)
		if TRACE==2:
			print "2, 0, "+str(self.id)+", 1, "+str(start_time)+", "+str(start_time+comm_time)
		return comm_time
		
	#Vivek Note 02/05/2015: Modeling S3 uploads and downloads

	def communicate_S3(self, start_time, filesize,UPLOAD):
		self.comm_total=self.comm_total+filesize
		
		if UPLOAD:
			factor=UPLOADSCALE*random.weibull(UPLOADSHAPE)
		else:
			factor=DOWNLOADSCALE*random.weibull(DOWNLOADSHAPE)


		comm_time=filesize/factor
		factor_cost=0
		comm_cost=filesize*factor_cost
                # return an overhead of time for communication
                # based on the network type and the filesize, the overhead is smaller or larger
		global TOTAL_COMM_COST
		TOTAL_COMM_COST=TOTAL_COMM_COST+comm_cost

		if TRACE==1:
			print "2, "+str(self.id)+", 0, 0, "+str(self.type)+", "+str(start_time)+", "+str(start_time+comm_time)+", "+str(comm_cost)
		if TRACE==2:
			print "2, 0, "+str(self.id)+", 1, "+str(start_time)+", "+str(start_time+comm_time)
		return comm_time

		
	def release_storage(self,storage):
		self.storage=self.storage+storage
		return 1
		
	
	def lock_storage(self,storage):
		if storage <= self.storage:
			self.storage=self.storage-storage
			return 1
		return -1
		
		
	def calculate_cost(self,this_time,erase):
		this_cost=0
		if self.on>0:
			this_cost=self.cost*ceil((this_time-self.on)/3600)
			if erase:
				self.on=0
		return this_cost
			
			
	def increase_end_time(self,tentative_end_time,budget):
		this_cost=0
		global TOTAL_INTENDED_BUDGET
		global EXTRA_BUDGET
		
		if tentative_end_time > self.end_time:
			new_units=ceil((tentative_end_time-self.start_time)/TIME_UNIT)
			old_units=ceil((self.end_time-self.start_time)/TIME_UNIT)
			if DEBUG:
				print "new and old units"
				print new_units
				print old_units
			
			this_cost=(new_units-old_units)*self.cost
			if budget >= this_cost or EXTRA_BUDGET+budget >= this_cost:
				TOTAL_INTENDED_BUDGET=TOTAL_INTENDED_BUDGET+budget
				if this_cost>budget:
					EXTRA_BUDGET=EXTRA_BUDGET-(this_cost-budget)
				self.end_time=self.start_time+(TIME_UNIT*new_units)
				self.busy_until_time=tentative_end_time
			else:
				self.busy_until_time=self.end_time				
		return this_cost
				



class Simulator:
	
	
	
	def __init__(self,instances_file,tasks_file,cp):
	
		self.SIM_TIME=0
		# build the DEPENDENCY GRAPH =======================
		#self.Graph = loadtxt(graph_file)        # argument 1 is the graph of dependencies
		#self.Graph[:,0]
		self.cp=cp
		self.run=0
		self.print_log=False
		self.stop_time=0
		
		# build the INSTANCES =======================
		self.amis=AMIs(instances_file)				# argument 2 is a csv file with resources

		if DEBUG:
			for inst in self.amis.Instances:
				inst.print_info()
				
		# build the SCHEDULER =======================
		schedule_model='default'
		pricing_model='default'
		power_model='default'
		deadline_model='default'
		self.S=Scheduler(schedule_model,pricing_model,power_model,deadline_model)
		
		#build the TASKS =======================
		self.read_tasks(tasks_file)
		#Vivek: build priority
		self.Priority_List()

	def update_priority(self,priority_file):
		"""read the schedule from a file and update the priority"""
		for row in csv.reader(open(priority_file), delimiter=','):
			Tasks[int(row[0])].priority=int(row[1])

	def Priority_List(self):
		"""Vivek: Creating a priority list. Zip and sort for faster performance"""	
		PT=zip(TASK_PRIORITY,TASK_NUMBER)
		PT.sort()

		for i in range(len(PT)):
			Priority.append(PT[i][1])



	#Vivek Note 08/20/2014: Traditional Simulator. Strictly Honor the Scheduling Policy
	def traditional_simulate(self):
		"""Vivek: Traditional Simulator. Strictly Honor the Scheduling Policy"""
		global ReadyHeap
		global Priority
		counter=0 #To Keep track of the number of tasks executed
		pointer=0 #To Point to the first element in the Priority List. NEVER CHANGES!
		
		while Priority or ReadyHeap or ExecHeap: #Until the Priority List or ReadyHeap or ExecHeap are Empty

			counter=0
			
			while Priority: #Get high priority eligible tasks. STOP when a dependent task is met
				myid=Priority[pointer]
				tsk=Tasks[myid]
				
				if tsk.nDependencies==0:#If Independent only then put on ReadyHeap
					heappush(ReadyHeap,(tsk.priority,tsk.id)) # insert in ready based on priority
					Priority.remove(tsk.id) #Now since the task is in the readyheap, no longer needed in the priority
				else:
					break
			#Vivek: Now the Tasks are in ReadyHeap. Allocate Image (vCPU in our case) to all that are in ReadyHeap as long as resources are available
			ReadyHeapTemp=[]
			while ReadyHeap and IdleImgs:#Vivek: Independent tasks (at SIM_TIME) inserted based on priority
			# read from the ready queue
				tskr=heappop(ReadyHeap) #Vivek: Independent tasks extracted based on priority
				# allocate an image for the task, if possible
				allocated=self.allocate_image(self.S,self.amis,Tasks[tskr[1]],self.SIM_TIME)
				if allocated==_CANNOT_IMAGE:
					Tasks[tskr[1]].cannot_schedule=Tasks[tskr[1]].cannot_schedule+1
					if Tasks[tskr[1]].cannot_schedule < 2000000:  # Vivek: Change it to 2000 (instead of 20)  attempts at rescheduling this task
						heappush(ReadyHeapTemp,tskr)
					
			
			while ReadyHeapTemp:
				tsk=heappop(ReadyHeapTemp)
				heappush(ReadyHeap,tsk)
	
			if TRADITIONAL_DEBUG:
				print "ExecHeap \n"
				print ExecHeap
				print "SIM_TIME:%f" %self.SIM_TIME
				raw_input("Hit Enter")			
			
			# read from the exec_queue and get NEXT_TIME, execute task if its exec time is = SIM_TIME
			if ExecHeap:
				NEXT_TIME=ExecHeap[0][0] 
				if NEXT_TIME==self.SIM_TIME:
					rep=heappop(ExecHeap)
					WHICH_TASKS[self.SIM_TIME].append(Replicas[rep[1]].id_task) #Vivek 23Sept: Which tasks are eligible for execution at SIM_TIME. For print debug only
					Replicas[rep[1]].execute(self.SIM_TIME,self.amis)
				#	if ExecHeap:
				#		NEXT_TIME=ExecHeap[0][0]
										
				
			# update SIM_TIME
			if NEXT_TIME==self.SIM_TIME:
				self.SIM_TIME=self.SIM_TIME
			else:
				self.SIM_TIME=NEXT_TIME
			


		#pprint(WHICH_TASKS)

		if TRADITIONAL_DEBUG:
			od=OrderedDict(sorted(WHICH_TASKS.items()));

			for keys,values in od.items():
				print str(keys)+": " + str(values) 
		


		global EXECUTION_TIME, IDLE_TIME

		
		TOTAL_EXECUTION_COST=self.amis.execution_costs()

		#Vivek: Write this to a csv for quick analysis  
                #Comma delimited

		execution_walltime = self.SIM_TIME

		paid_walltime=ceil(self.SIM_TIME/3600.00)

		paid_walltime=paid_walltime*3600

		idle_time=self.amis.nImages*paid_walltime - EXECUTION_TIME			

		if ELASTIC:
			total_cost = TOTAL_EXECUTION_COST
		else:
			total_cost=(paid_walltime/3600)*self.amis.Instances[0].cost*len(self.amis.Instances);

		idle_cost = total_cost - TOTAL_EXECUTION_COST

		#Vivek: comment/uncomment this as required
	#	idle_cost=(idle_time*self.amis.Instances[0].cost)/(3600*self.amis.nImages)

		#print " Total-Tasks	Exec. Walltime	Paid-Walltime	Execution-time	Idle-Time	Total-Cost	total-exec-cost		idle-cost	avg-completion-time	number of vCPUs		task-file	instance-file"
	
		#print str(TOTAL_TASKS)+","+str((execution_walltime/3600.00))+","+str((paid_walltime/3600.00))+", "+str((EXECUTION_TIME/3600.00))+", "+str((idle_time/3600.00))+", "+str(total_cost)+", "+str(TOTAL_EXECUTION_COST)+", "+str(idle_cost)+", "+str(AVG_COMPLETION_TIME/(3600*TOTAL_TASKS))+", "+str(len(self.amis.Instances)) +", " +args.task_file + ", "+args.instance_file
	
		#Vivek: Print paid wallclock time (rounded up) and cost alone
		print str((paid_walltime/3600.00))+" "+str(total_cost)
		
	
	
	def read_tasks(self,tasks_file):
		global AVG_DEP_PTASK, NTASKS
		
		for row in csv.reader(open(tasks_file), delimiter=','):
			NTASKS=NTASKS+1
			tsk=Task(int(row[0]),int(row[1]),int(row[2]),int(row[3]),float(row[4]),float(row[5]),
				float(row[6]),int(row[7]),int(row[8]),int(row[9]),float(row[10]),int(row[11]),int(row[12]),row[13],IO,self.SIM_TIME)
				
			Tasks.append(tsk)
			if DEBUG:
				print "Compare:"
				Tasks[int(row[0])].print_info()
				print "======================================="
				tsk.print_info()
				print row
			#Vivek: To build the priority list	
			TASK_NUMBER.append(int(row[0]))
			TASK_PRIORITY.append(int(row[9]))
			
		AVG_DEP_PTASK=AVG_DEP_PTASK/NTASKS
				
	
	def allocate_image(self,S,amis,task,this_time):
		min_gops=S.estimate_mingops(task,this_time) # minimum estimated gops in the resource to complete
		#find a resource with at least that much gops, ram and disk, but within the budget
		max_budget=S.estimate_maxbudget(task,min_gops)
		notAssigned=1
		
		while notAssigned:
			params={'task.min_gops':min_gops,'task.budget':max_budget,'task.start_time':this_time,
				'image.end_time':this_time,'image.nvCPU':1,'index_idle':-1}
				
			image=amis.select_image(task,params,S) #Vivek: Select an image from the list of idle images

			if not image and not self.cp: # increase the resources if cp is 0
				instance=amis.select_instance(task,params,S)
				
				if instance:
					image=Image(amis.nImages,instance,this_time) #Vivek 19Jan: for loop due to modified look of an image?
					amis.Images.append(image)
					amis.nImages=amis.nImages+1
				else:
					return _CANNOT_IMAGE
					
			if image:
				if DEBUG:
					print "TENTATIVE Task:  "+str(task.id)+" assigned to image: "+str(image.id)
				if task.assign_toImage(image, amis, params,this_time) >=0: #Vivek 10/19: AMIs is a special addition
					notAssigned=0
					if DEBUG:
						print "Task:  "+str(task.id)+" assigned to image: "+str(image.id)
				else:
					if DEBUG:
						print "ERROR: Task NOT assigned"
					return _CANNOT_IMAGE
			else:
				#TODO increase budget?
				return _CANNOT_IMAGE
		return _OK
				
		
			

		
#=====================================================


parser = argparse.ArgumentParser(description='This is a python Cloud simulator that executes a workflow of tasks given by the TASK_FILE using the resources specified in the INSTANCE_FILE.')
parser.add_argument('-i','--instance_file', help='CSV file of instances [family,type,vCPU,ECU,memory,storage,network,cost/hr,power/gop, number_of_reserved_instances]',required=True)
parser.add_argument('-t','--task_file',help='CSV file of tasks [id,create_time,est_gops,err_gops,input_fileSize,output_fileSize,memory,storage,status,priority,budget,deadline,max_nvCPU,dependencies]', required=True)
parser.add_argument('-run','--run',help='Number of run or id', required=False)
parser.add_argument('-stop','--stop',help='Stop time from the begining of the simulation in minites', required=False)
parser.add_argument('-l','--log_file',help='TXT file of final log', required=False)
parser.add_argument('-p','--priority',help='CSV file of task priority [id_task,priority]', required=False)
parser.add_argument('-cp','--constrained_pool', action='store_const', const=1, help='If this flag is present the resource pool will remain constant',required=False)
parser.add_argument('-io','--input_output', action='store_const', const=1, help='If this flag is present the files will be read from tasks file',required=False)
#The above line is to read input and output file sizes from the Tasks file
parser.add_argument('-res','--resources',help='Number of resources. Used for veryify_two and beyond.',required=False);


parser.add_argument('-d','--debug', action='store_const', const=1, help='If this flag is present it will output information in debug mode',required=False)
parser.add_argument('-e','--elastic', action='store_const', const=1, help='If this flag is present, the cost will be evaluated in the elastic mode',required=False)
parser.add_argument('-td','--tdebug', action='store_const', const=1, help='If this flag is present it will output information in traditional simualtor debug mode',required=False)
parser.add_argument('-tr','--trace', action='store_const', const=2, help='If this flag is present trace will be printed',required=False)
parser.add_argument('-s','--summary', action='store_const', const=1, help='If this flag is present it will output a summary of execution',required=False)
				
args = parser.parse_args()

if args.resources:
        res=int(args.resources)
else:
	res=0 
## show values ##
IO=args.input_output
DEBUG=args.debug
ELASTIC=args.elastic
TRADITIONAL_DEBUG=args.tdebug
TRACE=args.trace
SUMMARY=args.summary
if DEBUG:
	print ("Instances file: %s" % args.instance_file )
	print ("Tasks file: %s" % args.task_file )
	if args.constrained_pool:
		print ("Constrained pool: TRUE")
	else:
		print ("Constrained pool: FALSE")




	

Sim = Simulator(args.instance_file,args.task_file,args.constrained_pool)

if args.log_file:
	Sim.log_file=args.log_file
	Sim.print_log=1

if args.priority:
	Sim.update_priority(args.priority)

if args.run:
	Sim.run=args.run
	
if args.stop:
		Sim.stop_time=args.stop
		

Sim.traditional_simulate()

#Just for debug
if TRADITIONAL_DEBUG:
	for keys,values in Where_Executed.items():
		print str(keys)+": " + str(values)

