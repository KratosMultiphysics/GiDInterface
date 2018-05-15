from __future__ import print_function, absolute_import, division  # makes KratosMultiphysics backward compatible with python 2.6 and 2.7

## Time control starts
from time import *
print(ctime())
## Measure process time
t0p = clock()
## Measure wall time
t0w = time()

## Including application paths
from KratosMultiphysics import *
from KratosMultiphysics.ExternalSolversApplication  import *
from KratosMultiphysics.SolidMechanicsApplication import *
from KratosMultiphysics.ParticleMechanicsApplication import *

## Import define output
with open("ProjectParameters.json",'r') as parameter_file:
    ProjectParameters = Parameters(parameter_file.read())

## Get echo level and parallel type
echo_level = ProjectParameters["problem_data"]["echo_level"].GetInt()
parallel_type = ProjectParameters["problem_data"]["parallel_type"].GetString()

## Set domain size
domain_size = ProjectParameters["problem_data"]["domain_size"].GetInt()

## Material model part definition
material_model_part_name = ProjectParameters["problem_data"]["model_part_name"].GetString()
material_model_part = ModelPart(material_model_part_name) #Equivalent to model_part3 in the old format
material_model_part.ProcessInfo.SetValue(DOMAIN_SIZE, domain_size)

## Initial material model part definition
initial_material_model_part_name = "Initial_" + material_model_part_name
initial_material_model_part = ModelPart(initial_material_model_part_name) #Equivalent to model_part2 in the old format
initial_material_model_part.ProcessInfo.SetValue(DOMAIN_SIZE, domain_size)

## Grid model part definition
grid_model_part = ModelPart("Background_Grid") #Equivalent to model_part1 in the old format
grid_model_part.ProcessInfo.SetValue(DOMAIN_SIZE, domain_size)

## Solver construction
import particle_mpm_solver as ParticleMPM
solver = ParticleMPM.CreateSolver(grid_model_part, initial_material_model_part, material_model_part, ProjectParameters["solver_settings"])

## TODO: to be removed
## Definite Conditions start
########################################################################
import conditions_python_utility as condition_utils
incr_disp = "False"
incr_load = "False"
rotation_dofs = False
conditions = condition_utils.ConditionsUtility(grid_model_part, domain_size, incr_disp, incr_load, rotation_dofs)
conditions = condition_utils.ConditionsUtility(initial_material_model_part, domain_size, incr_disp, incr_load, rotation_dofs)
########################################################################

## Add variables to the model part
solver.AddVariables()

## Read the model - note that SetBufferSize and ImportConstitutiveLaws are done here
solver.ImportModelPart()

## Add AddDofs
solver.AddDofs()

## Initialize GiD I/O 
## For the Background Grid, the default gid_output_process is used
grid_output_post  = ProjectParameters.Has("grid_output_configuration")
if (grid_output_post == True):
    if (parallel_type == "OpenMP"):
        from gid_output_process import GiDOutputProcess
        grid_output_file_name = ProjectParameters["problem_data"]["problem_name"].GetString() + "_Grid"
        grid_gid_output = GiDOutputProcess(grid_model_part, grid_output_file_name,
                                    ProjectParameters["grid_output_configuration"])
    grid_gid_output.ExecuteInitialize()
## For the Material Point, a modified mpm_gid_output_process is used
mp_output_post  = ProjectParameters.Has("body_output_configuration")
if (mp_output_post == True):
    if (parallel_type == "OpenMP"):
        from mpm_gid_output_process import ParticleMPMGiDOutputProcess
        mp_output_file_name = ProjectParameters["problem_data"]["problem_name"].GetString() + "_Body"
        mp_gid_output = ParticleMPMGiDOutputProcess(material_model_part, mp_output_file_name,
                                    ProjectParameters["body_output_configuration"])
    mp_gid_output.ExecuteInitialize()

## Creation of the Kratos model (build sub_model_parts or submeshes)
ParticleMPMModel = Model()
ParticleMPMModel.AddModelPart(grid_model_part)
ParticleMPMModel.AddModelPart(initial_material_model_part)
ParticleMPMModel.AddModelPart(material_model_part)

## Processes construction
import process_factory
list_of_processes = process_factory.KratosProcessFactory(ParticleMPMModel).ConstructListOfProcesses(ProjectParameters["constraints_process_list"])
list_of_processes += process_factory.KratosProcessFactory(ParticleMPMModel).ConstructListOfProcesses(ProjectParameters["loads_process_list"])
if (ProjectParameters.Has("list_other_processes") == True):
    list_of_processes += process_factory.KratosProcessFactory(ParticleMPMModel).ConstructListOfProcesses(ProjectParameters["list_other_processes"])
if (ProjectParameters.Has("gravity") == True):
    list_of_processes += process_factory.KratosProcessFactory(ParticleMPMModel).ConstructListOfProcesses(ProjectParameters["gravity"])

## Processes initialization
for process in list_of_processes:
    process.ExecuteInitialize()

## Stepping and time settings
delta_time = ProjectParameters["problem_data"]["time_step"].GetDouble()
start_time = ProjectParameters["problem_data"]["start_time"].GetDouble()
end_time = ProjectParameters["problem_data"]["end_time"].GetDouble()

## Set time settings inside model part
grid_model_part.ProcessInfo[DELTA_TIME] = delta_time
grid_model_part.ProcessInfo[TIME] = 0
grid_model_part.ProcessInfo[STEP] = 0
grid_model_part.ProcessInfo[PREVIOUS_DELTA_TIME] = delta_time
initial_material_model_part.ProcessInfo[DELTA_TIME] = delta_time

## Solver Initialization
solver.Initialize()

if (grid_output_post == True):
    grid_gid_output.ExecuteBeforeSolutionLoop()
if (mp_output_post == True):
    mp_gid_output.ExecuteBeforeSolutionLoop()

for process in list_of_processes:
    process.ExecuteBeforeSolutionLoop()

## Current time and step
current_time = start_time
current_step = grid_model_part.ProcessInfo[STEP]

## Filling the buffer
for step in range(0,grid_model_part.GetBufferSize()):
  grid_model_part.CloneTimeStep(current_time)
  grid_model_part.ProcessInfo[DELTA_TIME] = delta_time
  grid_model_part.ProcessInfo[STEP] = step - grid_model_part.GetBufferSize()

## TODO: to be removed somewhere - process.ExecuteBeforeSolutionLoop()
########################################################################
# ## 1. Compute normal vector for the inclined slip boundary nodes
# normal_calculator = NormalCalculationUtils()
# normal_calculator.CalculateOnSimplex(grid_model_part.GetSubModelPart("SLIP_Boundary"), domain_size)

# # Assigning IS_STRUCTURE to slip nodes
# for node in grid_model_part.GetSubModelPart("SLIP_Boundary").Nodes:
#     node.SetSolutionStepValue(IS_STRUCTURE, 1.0)

# ## 2. Assign volume acceleration (gravity) to the material points
# if ProjectParameters.Has("gravity"):
#     gravity_modulus = ProjectParameters["gravity"]["Parameters"]["modulus"].GetDouble()
#     gravity_direction = ProjectParameters["gravity"]["Parameters"]["direction"].GetVector()
#     gravity_acceleration = gravity_modulus * gravity_direction

#     for element in material_model_part.Elements:
#         element.SetValue(MP_VOLUME_ACCELERATION,gravity_acceleration) 
########################################################################


while(current_time < end_time):

    ## Start Timer
    start_solve_time = time() 

    ## Store previous time step
    grid_model_part.ProcessInfo[PREVIOUS_DELTA_TIME] = delta_time
    
    ## Set new time step ( it can change when solve is called )
    delta_time = grid_model_part.ProcessInfo[DELTA_TIME]

    ## Update current time and step
    current_time = current_time + delta_time
    current_step = current_step + 1
    grid_model_part.CloneTimeStep(current_time)
    grid_model_part.ProcessInfo[TIME] = current_time

    ## Output
    print("STEP = ", current_step)
    print("TIME = ", current_time)

    ## TODO: to be removed somewhere - process.ExecuteInitializeSolutionStep()
    ## Activate particle erase process
    ########################################################################
    # for element in material_model_part.Elements:
    #     gauss_coord = element.GetValue(GAUSS_COORD)
    #     # TODO: Put the coordinate range in the interface
    #     # These are specific coordinates for the current problem case.
    #     if(gauss_coord[0] < 0.00 or gauss_coord[0] > 1.00 or gauss_coord[1] < 0.00 or gauss_coord[1] > 0.50 or gauss_coord[2] < -1.00 or gauss_coord[2] > 0.00 ): 
    #         print('element id = ', element.Id, 'is out of the possible range. Set it to erase.')
    #         element.Set(TO_ERASE, True)

    # ParticleEraseProcess(material_model_part).Execute()
    ########################################################################

    for process in list_of_processes:
        process.ExecuteInitializeSolutionStep()

    if (grid_output_post == True):
        grid_gid_output.ExecuteInitializeSolutionStep()
    if (mp_output_post == True):
        mp_gid_output.ExecuteInitializeSolutionStep()

    ## Solve
    solver.Solve()

    for process in list_of_processes:
        process.ExecuteFinalizeSolutionStep()

    if (grid_output_post == True):
        grid_gid_output.ExecuteFinalizeSolutionStep()
    if (mp_output_post == True):
        mp_gid_output.ExecuteFinalizeSolutionStep()

    for process in list_of_processes:
        process.ExecuteBeforeOutputStep()

    if (grid_output_post == True) and (grid_gid_output.IsOutputStep()):
        grid_gid_output.PrintOutput()
    if (mp_output_post == True) and (mp_gid_output.IsOutputStep()):
        mp_gid_output.PrintOutput()

    for process in list_of_processes:
        process.ExecuteAfterOutputStep()

    ## Stop Timer
    end_solve_time = time()
    print("[Solving time: ", end_solve_time - start_solve_time, " s]")
    
    ## Set incremental load
    #TODO: to be removed somewhere 
    conditions.SetIncrementalLoad(current_step, delta_time)

print("Analysis Finalized")

for process in list_of_processes:
    process.ExecuteFinalize()

if (grid_output_post == True):
    grid_gid_output.ExecuteFinalize()
if (mp_output_post == True):
    mp_gid_output.ExecuteFinalize()

## Measure process and wall time
tfp = clock()
tfw = time()

print(ctime())
print("Analysis Completed  [Time = ", tfw - t0w, "sec , Process Time = ", tfp - t0p, " sec]")
