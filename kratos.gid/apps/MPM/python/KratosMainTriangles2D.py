from __future__ import print_function, absolute_import, division #makes KratosMultiphysics backward compatible with python 2.6 and 2.7
import math
import csv
# Activate it to import in the gdb path:
# import sys
# sys.path.append('/home/jmaria/kratos')
# x = raw_input("stopped to allow debug: set breakpoints and press enter to continue");

#
# ***************GENERAL MAIN OF THE ANALISYS****************###
#

# time control starts
from time import *
print(ctime())
# measure process time
t0p = clock()
# measure wall time
t0w = time()

# ----------------------------------------------------------------#
# --CONFIGURATIONS START--####################
# Import the general variables read from the GiD
import ProjectParameters as general_variables

# setting the domain size for the problem to be solved
domain_size = general_variables.domain_size

# including kratos path
from KratosMultiphysics import *

# including Applications paths

from KratosMultiphysics.ExternalSolversApplication import *
from KratosMultiphysics.SolidMechanicsApplication import *
from KratosMultiphysics.ParticleMechanicsApplication import *
#from KratosMultiphysics.PfemBaseApplication import *
#from KratosMultiphysics.PfemSolidMechanicsApplication import *



# import the python utilities:
import restart_utility as restart_utils
import gid_output_utility as gid_utils

import conditions_python_utility as condition_utils
import list_files_python_utility as files_utils

import time_operation_utility as operation_utils

# ------------------------#--FUNCTIONS START--#------------------#
# ---------------------------------------------------------------#
# --TIME MONITORING START--##################
def StartTimeMeasuring():
    # measure process time
    time_ip = clock()
    return time_ip


def StopTimeMeasuring(time_ip, process):
    # measure process time
    time_fp = clock()
    print(" ", process, " [ spent time = ", time_fp - time_ip, "] ")
# --TIME MONITORING END --###################

# --SET NUMBER OF THREADS --#################


#def SetParallelSize(num_threads):
    #parallel = OpenMPUtils()
    #print("Num Threads = ", num_threads)
    #parallel.SetNumThreads(int(num_threads))
# --SET NUMBER OF THREADS --#################

# ------------------------#--FUNCTIONS END--#--------------------#
# ---------------------------------------------------------------#


# defining the number of threads:
num_threads = general_variables.NumberofThreads
#SetParallelSize(num_threads)

# defining the type, the name and the path of the problem:
problem_type = general_variables.ProblemType
problem_name = general_variables.problem_name
problem_name2 = general_variables.problem_name2
problem_path = general_variables.problem_path

#MPM_problem_name = general_variables.MPM_results_name

# defining a model part
model_part1 = ModelPart("ComputationalDomain")
model_part2 = ModelPart("InitialDomain")
model_part3 = ModelPart("SolidDomain")
if (domain_size == 2):
    new_element = CreateUpdatedLagragian2D3N() #CreateUpdatedLagragian2D3N()
    #print(new_element)
else:
    new_element = CreateUpdatedLagragian3D4N()
    #print(new_element)
# defining the model size to scale
length_scale = 1.0

# --DEFINE MAIN SOLVER START--################

SolverSettings = general_variables.SolverSettings
GeometryElement = "Triangle"
NumPar = 3
# import solver file
# I am importing the particle solver
solver_constructor = __import__(SolverSettings.solver_type)

# construct the solver
main_step_solver = solver_constructor.CreateSolver(model_part1, model_part2, model_part3, new_element, SolverSettings,GeometryElement,NumPar)

# --DEFINE MAIN SOLVER END--##################


# --READ AND SET MODEL FILES--###############

# set the restart of the problem
restart_step = general_variables.Restart_Step
#problem_restart = restart_utils.RestartUtility(model_part1, problem_path, problem_name)

# set the results file list of the problem (managed by the problem_restart and gid_print)
print_lists = general_variables.PrintLists
output_mode = general_variables.GidOutputConfiguration.GiDPostMode
list_files = files_utils.ListFilesUtility(problem_path, problem_name, print_lists, output_mode)
list_files.Initialize(general_variables.file_list)

# --READ AND SET MODEL FILES END--############


# --DEFINE CONDITIONS START--#################
incr_disp = general_variables.Incremental_Displacement
incr_load = general_variables.Incremental_Load
rotation_dofs = SolverSettings.RotationDofs
conditions = condition_utils.ConditionsUtility(model_part1, domain_size, incr_disp, incr_load, rotation_dofs)
conditions = condition_utils.ConditionsUtility(model_part2, domain_size, incr_disp, incr_load, rotation_dofs)

# --DEFINE CONDITIONS END--###################


# --GID OUTPUT OPTIONS START--###############
# set gid print options
gid_print = gid_utils.GidOutputUtility(problem_name, general_variables.GidOutputConfiguration)

# --GID OUTPUT OPTIONS END--##################


# --CONFIGURATIONS END--######################
# ----------------------------------------------------------------#


# --START SOLUTION--######################
#
# initialize problem : load restart or initial start
load_restart = general_variables.LoadRestart
save_restart = general_variables.SaveRestart

# set buffer size  (definito in particle_solver)
buffer_size = 3

# define problem variables:
solver_constructor.AddVariables(model_part1, SolverSettings)

solver_constructor.AddVariables(model_part2, SolverSettings)
# --- READ MODEL ------#
if(load_restart == False):

    # remove results, restart, graph and list previous files
    #problem_restart.CleanPreviousFiles()
    list_files.RemoveListFiles()

    #vector of active elements
    #active_elements = [1,2]   #[7,8,9,10]

    # reading the model1
    model_part_io = ModelPartIO(problem_name)
    model_part_io.ReadModelPart(model_part1)
    
    model_part_io2 = ModelPartIO(problem_name2)
    model_part_io2.ReadModelPart(model_part2)
    #for node in model_part1.Nodes:
        #node.SetSolutionStepValue(VOLUME_ACCELERATION_Y,0, -9.81)    
        #if (node.Y<-0.375):
            #node.SetSolutionStepValue(DISPLACEMENT_X, 0.000000)  
            #node.SetSolutionStepValue(DISPLACEMENT_Y, 0.000000)    
    #for elements in model_part1.Elements:
        #id_el = elements.Id
        #print(id_el)
        #for active_elem in active_elements:
            #if (id_el==active_elem):
                #elements.Set(ACTIVE, True)
    #for element in model_part1.Elements:
        ##id_el = elements.Id
        ##element.Set(ACTIVE, True)
        ##for active_elem in active_elements:
            ##if (element.Id == active_elem):
                ##element.Set(ACTIVE, True)
         #if (element.GetNode(0).X<= 1.25 and element.GetNode(0).Y>= 0 and element.GetNode(0).Y<= 0.0625
            #and element.GetNode(1).X<= 1.25 and element.GetNode(1).Y>= 0 and element.GetNode(1).Y<= 0.0625
            #and element.GetNode(2).X<= 1.25 and element.GetNode(2).Y>= 0 and element.GetNode(2).Y<= 0.0625):
                #element.Set(ACTIVE, True)
               # print(active_elem)
    for node in model_part1.Nodes:
	
	    if (node.Is(ACTIVE)):
	    
		    print(node.Id)
		    
    for element in model_part2.Elements:
        #if(element.GetNode(0).Is(ACTIVE) and element.GetNode(1).Is(ACTIVE) and element.GetNode(2).Is(ACTIVE) and element.GetNode(3).Is(ACTIVE)):
        element.Set(ACTIVE, True)
        #print(element.Id)
    # set the buffer size
    model_part1.SetBufferSize(buffer_size)
    model_part2.SetBufferSize(buffer_size)
    # Note: the buffer size should be set once the mesh is read for the first time

    # set the degrees of freedom
    solver_constructor.AddDofs(model_part1, SolverSettings)
    solver_constructor.AddDofs(model_part2, SolverSettings)

    #Properties of mpm_model_part are assigned:
    #ATTENTION: ASSIGNE PROPERTIES TO THE MPM MODEL PART NOT TO HAVE PROBLEM IN CHECK FUNCTION, SITUATED IN THE ELEMENT!!! 
    
    model_part3.Properties = model_part2.Properties
    # set the constitutive law
    import constitutive_law_python_utility as constitutive_law_utils

    constitutive_law = constitutive_law_utils.ConstitutiveLawUtility(model_part3, domain_size);
    constitutive_law.Initialize();

else:

    # reading the model from the restart file
    problem_restart.Load(restart_step);

    # remove results, restart, graph and list posterior files
    problem_restart.CleanPosteriorFiles(restart_step)
    list_files.ReBuildListFiles()

# set mesh searches and modeler
# modeler.InitializeDomains();

# if(load_restart == False):
    # find nodal h
    # modeler.SearchNodalH();


# --- PRINT CONTROL ---#
print('aaaaaaaaaa')
print(model_part1)
print('bbbbbbbbbb')
print(model_part1.Properties[1])
print('cccccccccc')

# --INITIALIZE--###########################
#

# set delta time in process info
model_part1.ProcessInfo[DELTA_TIME] = general_variables.time_step
model_part2.ProcessInfo[DELTA_TIME] = general_variables.time_step


# solver initialize
#setting of solution scheme, builder and solver, solving strategy
#IMPORTANT: here I created the Material Points and I call the check!

main_step_solver.Initialize() 
main_step_solver.SetRestart(load_restart) #calls strategy initialize if no restart


#########################################################################################
#here I create the mesh of Material Points to be read in the post-process
mesh_file = open("MPM_gid_out" + ".post.msh",'w')
mesh_file.write("MESH \"")
mesh_file.write("outmesh")
mesh_file.write("\" dimension 3 ElemType Point Nnode 1\n")
mesh_file.write("Coordinates\n")
for mpm in model_part3.Elements:
    coord = mpm.GetValue(GAUSS_COORD)
    #print('coord',coord)
    mesh_file.write("{} {} {} {}\n".format( mpm.Id ,coord[0] , coord[1], coord[2]))
mesh_file.write("End Coordinates\n")
mesh_file.write("Elements\n")  
for mpm in model_part3.Elements:
    mesh_file.write("{} {}\n".format(mpm.Id, mpm.Id ))   ##attenzione Id element qui inizia da uno
mesh_file.write("End Elements\n")
mesh_file.flush()
############################################################################################
#here I create the mesh of the fixed grid to be read in the post-process

mesh_file = open("second_mesh" + ".post.msh",'w')
mesh_file.write("MESH \"")
if (domain_size == 2):
    mesh_file.write("Kratos_Triangle2D3_Mesh_1")
    mesh_file.write("\" dimension 2 ElemType Triangle Nnode 3\n")
    mesh_file.write("Coordinates\n")
    for node in model_part1.Nodes:
        mesh_file.write("{} {} {} {}\n".format( node.Id , node.X, node.Y, node.Z))
    mesh_file.write("End Coordinates\n")
    mesh_file.write("Elements\n") 
    for elem in model_part1.Elements:
        node1 = elem.GetNodes()[0].Id
        node2 = elem.GetNodes()[1].Id
        node3 = elem.GetNodes()[2].Id
        #node4 = elem.GetNodes()[3].Id
        mesh_file.write("{} {} {} {} \n".format( elem.Id , node1, node2, node3))
else:
    mesh_file.write("Kratos_Tetrahedra3D4_Mesh_1")
    mesh_file.write("\" dimension 3 ElemType Tetrahedra Nnode 4\n")
    mesh_file.write("Coordinates\n")
    for node in model_part1.Nodes:
        mesh_file.write("{} {} {} {}\n".format( node.Id , node.X, node.Y, node.Z))
    mesh_file.write("End Coordinates\n")
    mesh_file.write("Elements\n") 
    for elem in model_part1.Elements:
        node1 = elem.GetNodes()[0].Id
        node2 = elem.GetNodes()[1].Id
        node3 = elem.GetNodes()[2].Id
        node4 = elem.GetNodes()[3].Id
        mesh_file.write("{} {} {} {} {}\n".format( elem.Id , node1, node2, node3, node4))
mesh_file.write("End Elements\n")
mesh_file.flush()
###############################################################################################


# initial contact search
# modeler.InitialContactSearch()

#define time steps and loop range of steps
time_step = model_part1.ProcessInfo[DELTA_TIME]

# define time steps and loop range of steps
if(load_restart):

    buffer_size = 0

else:

    model_part1.ProcessInfo[TIME]                = 0
    model_part1.ProcessInfo[STEP]          = 0
    model_part1.ProcessInfo[PREVIOUS_DELTA_TIME] = time_step;

    conditions.Initialize(time_step);


# initialize step operations
starting_step  = model_part1.ProcessInfo[STEP]
starting_time  = model_part1.ProcessInfo[TIME]
#ending_step    = general_variables.nsteps
ending_time    = general_variables.end_time


output_print = operation_utils.TimeOperationUtility()
gid_time_frequency = general_variables.GiDWriteFrequency
output_print.InitializeTime(starting_time, ending_time, time_step, gid_time_frequency)

restart_print = operation_utils.TimeOperationUtility()
restart_time_frequency = general_variables.RestartFrequency
restart_print.InitializeTime(starting_time, ending_time, time_step, restart_time_frequency)


# --TIME INTEGRATION--#######################
#

# writing a single file
gid_print.initialize_results(model_part1)

#initialize time integration variables
current_time = starting_time
print("current_time",current_time)
current_step = starting_step

# filling the buffer
for step in range(0,buffer_size):

  model_part1.CloneTimeStep(current_time)
  model_part1.ProcessInfo[DELTA_TIME] = time_step
  model_part1.ProcessInfo[STEP] = step-buffer_size

# writing a initial state results file
current_id = 0
gid_print.write_results(model_part1, general_variables.nodal_results, general_variables.gauss_points_results, current_time, current_step, current_id)
list_files.PrintListFiles(current_id);


result_fixmesh = open( "second_mesh" + ".post.res", 'w')
result_fixmesh.write("GiD Post Results File 1.0\n")

result_file = open( "MPM_gid_out" + ".post.res", 'w')
result_file.write("GiD Post Results File 1.0\n")


#total_acceleration_in_time = -9.81*current_time/ending_time
#for element in model_part2.Elements:
    #node.SetSolutionStepValue(VOLUME_ACCELERATION_Y,0, -9.81) 
    #element.SetValue(MP_VOLUME_ACCELERATION,(0,-9.81,0))

#assign gravitational acceleration (after pybind)
grav_acceleration = Vector([0.0,-9.81,0.0])

for element in model_part3.Elements:
    
    #if(element.Properties[DENSITY] < 2000):
    element.SetValue(MP_VOLUME_ACCELERATION,grav_acceleration) 
        
    #if(element.Id <= 7169 and element.Id >= 6481):
    #if(element.Properties[DENSITY] == 7870):
        #element.SetValue(MP_VELOCITY,(-1,0,0)) 
    #if(element.Id > 935):
        
# solving the problem

while(current_time < ending_time):
    
  start_solve_time = time()       
    
  # store previous time step
  model_part1.ProcessInfo[PREVIOUS_DELTA_TIME] = time_step
  # set new time step ( it can change when solve is called )
  time_step = model_part1.ProcessInfo[DELTA_TIME]

  current_time = current_time + time_step
  current_step = current_step + 1
  model_part1.CloneTimeStep(current_time)
  model_part1.ProcessInfo[TIME] = current_time
  
  print("STEP = ", current_step)
  print("TIME = ", current_time)

  #clock_time = StartTimeMeasuring();
  # solve time step non-linear system
  
   
          
#   if(current_time < 0.01):
#       for node in model_part1.Nodes:
#           if((node.X<=0.005 and node.Y == 0.0737) or (node.X>=-0.005 and node.Y == 0.0737)):
#               node.Fix(DISPLACEMENT_X)
#               node.SetSolutionStepValue(DISPLACEMENT, 1,(0.0,0.0,0.0))
#   else:
#       for node in model_part1.Nodes:
#           if((node.X<=0.005 and node.Y == 0.0737) or (node.X>=-0.005 and node.Y == 0.0737)):
#               node.Free(DISPLACEMENT_X)
            
              #node.SetSolutionStepValue(DISPLACEMENT, 1,(0.0,0.0,0.0))

#Comment out the following section to activate particle erase feature
################################################################

  #for elem in model_part3.Elements:
      #gauss_coord = elem.GetValue(GAUSS_COORD)
      ##These are specific coordinates for the current problem case.
      #if(gauss_coord[0] < 0.00 or gauss_coord[0] > 1.00 or gauss_coord[1] < 0.00 or gauss_coord[1] > 0.50 or gauss_coord[2] < -1.00 or gauss_coord[2] > 0.00 ): 
          #print('element id = ', elem.Id, 'is out of the possible range. Set it to erase.')
          #elem.Set(TO_ERASE, True)

  #ParticleEraseProcess(model_part3).Execute()

################################################################

  main_step_solver.Solve()
  
    
  #for mpm in model_part2.Elements:
      #if (mpm.Id == 30899):
          #aa=mpm.GetValue(MP_ACCELERATION) 
          #bb = mpm.GetValue(MP_VELOCITY) 
          #print("despues",aa)
          #print("despues",bb)
  #input()
  #StopTimeMeasuring(clock_time, "Solving");
  end_solve_time = time()
  print("    [Solving time: ", end_solve_time - start_solve_time, " s]")
  # incremental load
  conditions.SetIncrementalLoad(current_step, time_step);

  # print the results at the end of the step
  execute_write = output_print.perform_time_operation(current_time)
  if(execute_write):
      clock_time = StartTimeMeasuring();
      current_id = output_print.operation_id()
      # print gid output file
      gid_print.write_results(model_part1, general_variables.nodal_results, general_variables.gauss_points_results, current_time, current_step, current_id)
      result_file.write("Result \"")
      result_file.write("MPMDisplacement")
      result_file.write('" "Kratos" {} Vector OnNodes\n'.format(current_time))
      result_file.write("Values\n")
      result_fixmesh.write("Result \"")
      result_fixmesh.write("MPMDisplacement")
      result_fixmesh.write('" "Kratos" {} Vector OnNodes\n'.format(current_time))
      result_fixmesh.write("Values\n")
      for mpm in model_part3.Elements:
          #previous_coord = mpm.GetValue(GAUSS_COORD,1)
          coord = mpm.GetValue(GAUSS_COORD)
          displacement = mpm.GetValue(MP_DISPLACEMENT)
          result_file.write("{} {} {} {}\n".format(mpm.Id, displacement[0], displacement[1], displacement[2]))            
      result_file.write("End Values\n")
      #result_file.flush()
     
      for node in model_part1.Nodes:
	      result_fixmesh.write("{} {} {} {}\n".format(node.Id , 0, 0,0))
      result_fixmesh.write("End Values\n")
      
      result_file.write("Result \"")
      result_file.write("MPMVelocity")
      result_file.write('" "Kratos" {} Vector OnNodes\n'.format(current_time))
      result_file.write("Values\n")
      result_fixmesh.write("Result \"")
      result_fixmesh.write("MPMVelocity")
      result_fixmesh.write('" "Kratos" {} Vector OnNodes\n'.format(current_time))
      result_fixmesh.write("Values\n")
      for mpm in model_part3.Elements:
          #previous_coord = mpm.GetValue(GAUSS_COORD,1)
          coord = mpm.GetValue(GAUSS_COORD)
          velocity = mpm.GetValue(MP_VELOCITY)
          result_file.write("{} {} {} {}\n".format(mpm.Id, velocity[0], velocity[1], velocity[2]))            
      result_file.write("End Values\n")
      #result_file.flush()
      for node in model_part1.Nodes:
	      result_fixmesh.write("{} {} {} {}\n".format(node.Id , 0, 0,0))
      result_fixmesh.write("End Values\n")
      
      result_file.write("Result \"")
      result_file.write("MPMPressure")
      result_file.write('" "Kratos" {} Scalar OnNodes\n'.format(current_time))
      result_file.write("Values\n")
      result_fixmesh.write("Result \"")
      result_fixmesh.write("MPMPressure")
      result_fixmesh.write('" "Kratos" {} Scalar OnNodes\n'.format(current_time))
      result_fixmesh.write("Values\n")
      for mpm in model_part3.Elements:
          #previous_coord = mpm.GetValue(GAUSS_COORD,1)
          coord = mpm.GetValue(GAUSS_COORD)
          pressure = mpm.GetValue(MP_PRESSURE)
          result_file.write("{} {}\n".format(mpm.Id, pressure))         
      result_file.write("End Values\n")
      #result_file.flush()
      for node in model_part1.Nodes:
	      result_fixmesh.write("{} {}\n".format(node.Id , 0))
      result_fixmesh.write("End Values\n")  
      

      
      result_file.write("Result \"")
      result_file.write("MPMEquivalentPlaticStrain")
      result_file.write('" "Kratos" {} Scalar OnNodes\n'.format(current_time))
      result_file.write("Values\n")
      result_fixmesh.write("Result \"")
      result_fixmesh.write("MPMEquivalentPlaticStrain")
      result_fixmesh.write('" "Kratos" {} Scalar OnNodes\n'.format(current_time))
      result_fixmesh.write("Values\n")
      for mpm in model_part3.Elements:
          #previous_coord = mpm.GetValue(GAUSS_COORD,1)
          coord = mpm.GetValue(GAUSS_COORD)
          plasticstrain_eq = mpm.GetValue(MP_EQUIVALENT_PLASTIC_STRAIN)
          result_file.write("{} {}\n".format(mpm.Id, plasticstrain_eq))         
      result_file.write("End Values\n")
      #result_file.flush()
      for node in model_part1.Nodes:
	      result_fixmesh.write("{} {}\n".format(node.Id , 0))
      result_fixmesh.write("End Values\n")   
      
          
      result_file.write("Result \"")
      result_file.write("MPMStress")
      result_file.write('" "Kratos" {} Vector OnNodes\n'.format(current_time))
      result_file.write("Values\n")
      result_fixmesh.write("Result \"")
      result_fixmesh.write("MPMStress")
      result_fixmesh.write('" "Kratos" {} Vector OnNodes\n'.format(current_time))
      result_fixmesh.write("Values\n")
      for mpm in model_part3.Elements:
          #previous_coord = mpm.GetValue(GAUSS_COORD,1)
          coord = mpm.GetValue(GAUSS_COORD)
          stress = mpm.GetValue(MP_CAUCHY_STRESS_VECTOR)
          result_file.write("{} {} {} {}\n".format(mpm.Id, stress[0], stress[1], stress[2]))            
      result_file.write("End Values\n")
      #result_file.flush()
      for node in model_part1.Nodes:
	      result_fixmesh.write("{} {} {} {}\n".format(node.Id , 0, 0,0))
      result_fixmesh.write("End Values\n")
      
      #result_file.write("Result \"")
      #result_file.write("MPMAcceleration")
      #result_file.write('" "Kratos" {} Vector OnNodes\n'.format(current_time))
      #result_file.write("Values\n")
      #result_fixmesh.write("Result \"")
      #result_fixmesh.write("MPMAcceleration")
      #result_fixmesh.write('" "Kratos" {} Vector OnNodes\n'.format(current_time))
      #result_fixmesh.write("Values\n")
      #for mpm in model_part3.Elements:
          ##previous_coord = mpm.GetValue(GAUSS_COORD,1)
          #coord = mpm.GetValue(GAUSS_COORD)
          #acceleration = mpm.GetValue(MP_ACCELERATION)
          #result_file.write("{} {} {} {}\n".format(mpm.Id, acceleration[0], acceleration[1], acceleration[2]))            
      #result_file.write("End Values\n")
      ##result_file.flush()
      #for node in model_part1.Nodes:
	      #result_fixmesh.write("{} {} {} {}\n".format(node.Id , 0, 0,0))
      #result_fixmesh.write("End Values\n")
      
      
      
      
      
      # print on list files
      list_files.PrintListFiles(current_id);
      StopTimeMeasuring(clock_time, "Write Results");

  # print restart file
  if(save_restart):
      execute_save = restart_print.perform_time_operation(current_time)
      if(execute_save):
          clock_time = StartTimeMeasuring();
          current_id = output_print.operation_id()
          problem_restart.Save(current_time, current_step, current_id);
          StopTimeMeasuring(clock_time, "Restart");

        
  #conditions.RestartImposedDisp()

# --FINALIZE--############################
#

# writing a single file
gid_print.finalize_results()

print("Analysis Finalized ")

# --END--###############################
#

# measure process time
tfp = clock()
# measure wall time
tfw = time()

print(ctime())
print ("Analysis Completed  [Process Time = ", tfp - t0p, "seconds, Wall Time = ", tfw - t0w, " ]")
#print("Analysis Completed  [Process Time = ", tfp - t0p, "] ")

#I want to print the strain, kinetic and total energy

# to create a benchmark: add standard benchmark files and decomment next two lines 
# rename the file to: run_test.py
#from run_test_benchmark_results import *
#WriteBenchmarkResults(model_part)
