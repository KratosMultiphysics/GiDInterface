from __future__ import print_function, absolute_import, division #makes KratosMultiphysics backward compatible with python 2.6 and 2.7

from KratosMultiphysics import *
from KratosMultiphysics.FluidDynamicsApplication import *
from KratosMultiphysics.ExternalSolversApplication import *

import sys
import time as system_time

######################################################################################
######################################################################################
######################################################################################

## Parse the ProjectParameters
with open("ProjectParameters.json",'r') as parameter_file:
    project_parameters = Parameters( parameter_file.read())

## Get echo level and parallel type
echo_level = project_parameters["problem_data"]["echo_level"].GetInt()
parallel_type = project_parameters["problem_data"]["parallel_type"].GetString()

## Import KratosMPI if needed
if (parallel_type == "MPI"):
    from KratosMultiphysics.mpi import *
    from KratosMultiphysics.MetisApplication import *
    from KratosMultiphysics.TrilinosApplication import *

## Fluid model part definition
main_model_part = ModelPart(project_parameters["problem_data"]["model_part_name"].GetString())
main_model_part.ProcessInfo.SetValue(DOMAIN_SIZE, project_parameters["problem_data"]["domain_size"].GetInt())

## Solver construction
import python_solvers_wrapper_fluid
solver = python_solvers_wrapper_fluid.CreateSolver(main_model_part, project_parameters)

solver.AddVariables()

## Read the model - note that SetBufferSize is done here
solver.ImportModelPart()

## Add AddDofs
solver.AddDofs()

## Initialize GiD  I/O
output_post  = project_parameters.Has("output_configuration")
if (output_post == True):
    if (parallel_type == "OpenMP"):
        from gid_output_process import GiDOutputProcess
        gid_output = GiDOutputProcess(solver.GetComputingModelPart(),
                                      project_parameters["problem_data"]["problem_name"].GetString() ,
                                      project_parameters["output_configuration"])
    elif (parallel_type == "MPI"):
        from gid_output_process_mpi import GiDOutputProcessMPI
        gid_output = GiDOutputProcessMPI(solver.GetComputingModelPart(),
                                         project_parameters["problem_data"]["problem_name"].GetString() ,
                                         project_parameters["output_configuration"])

    gid_output.ExecuteInitialize()

## Creation of Kratos model (build sub_model_parts or submeshes)
fluid_model = Model()
fluid_model.AddModelPart(main_model_part)

## Get the list of the skin submodel parts in the object Model
for i in range(project_parameters["solver_settings"]["skin_parts"].size()):
    skin_part_name = project_parameters["solver_settings"]["skin_parts"][i].GetString()
    fluid_model.AddModelPart(main_model_part.GetSubModelPart(skin_part_name))

## Get the list of the no-skin submodel parts in the object Model (results processes and no-skin conditions)
for i in range(project_parameters["solver_settings"]["no_skin_parts"].size()):
    no_skin_part_name = project_parameters["solver_settings"]["no_skin_parts"][i].GetString()
    fluid_model.AddModelPart(main_model_part.GetSubModelPart(no_skin_part_name))

## Get the list of the initial conditions submodel parts in the object Model
for i in range(project_parameters["initial_conditions_process_list"].size()):
    initial_cond_part_name = project_parameters["initial_conditions_process_list"][i]["Parameters"]["model_part_name"].GetString()
    fluid_model.AddModelPart(main_model_part.GetSubModelPart(initial_cond_part_name))

## Get the gravity submodel part in the object Model
for i in range(project_parameters["gravity"].size()):
    gravity_part_name = project_parameters["gravity"][i]["Parameters"]["model_part_name"].GetString()
    fluid_model.AddModelPart(main_model_part.GetSubModelPart(gravity_part_name))

## Print model_part and properties
if (echo_level > 1) and ((parallel_type == "OpenMP") or (mpi.rank == 0)):
    print("")
    print(main_model_part)
    for properties in main_model_part.Properties:
        print(properties)

## Processes construction
import process_factory
# "list_of_processes" contains all the processes already constructed (boundary conditions, initial conditions and gravity)
# Note 1: gravity is firstly constructed. Outlet process might need its information.
# Note 2: initial conditions are constructed before BCs. Otherwise, they may overwrite the BCs information.
list_of_processes =  process_factory.KratosProcessFactory(fluid_model).ConstructListOfProcesses( project_parameters["gravity"] )
list_of_processes += process_factory.KratosProcessFactory(fluid_model).ConstructListOfProcesses( project_parameters["initial_conditions_process_list"] )
list_of_processes += process_factory.KratosProcessFactory(fluid_model).ConstructListOfProcesses( project_parameters["boundary_conditions_process_list"] )
list_of_processes += process_factory.KratosProcessFactory(fluid_model).ConstructListOfProcesses( project_parameters["auxiliar_process_list"] )

if (echo_level > 1) and ((parallel_type == "OpenMP") or (mpi.rank == 0)):
    for process in list_of_processes:
        print(process)

## Processes initialization
for process in list_of_processes:
    process.ExecuteInitialize()

## Solver initialization
solver.Initialize()

## Stepping and time settings
start_time = project_parameters["problem_data"]["start_time"].GetDouble()
end_time = project_parameters["problem_data"]["end_time"].GetDouble()

time = start_time
step = 0

if (output_post == True):
    gid_output.ExecuteBeforeSolutionLoop()

for process in list_of_processes:
    process.ExecuteBeforeSolutionLoop()

## Writing the full ProjectParameters file before solving
if ((parallel_type == "OpenMP") or (mpi.rank == 0)) and (echo_level > 1):
    with open("ProjectParametersOutput.json", 'w') as f:
        f.write(project_parameters.PrettyPrintJsonString())

# force a flush to get some output in windows
# Note: we don't do flushes in MPI, they are only good for causing bottlenecks in disk access.
if parallel_type == "OpenMP":
    sys.stdout.flush()
    last_flush = system_time.time()

while(time <= end_time):

    delta_time = solver.ComputeDeltaTime()
    step += 1
    time += delta_time
    main_model_part.CloneTimeStep(time)
    main_model_part.ProcessInfo[STEP] = step

    if (parallel_type == "OpenMP") or (mpi.rank == 0):
        print("")
        print("STEP = ", main_model_part.ProcessInfo[STEP])
        print("TIME = ", main_model_part.ProcessInfo[TIME])

    if parallel_type == "OpenMP":
        now = system_time.time()
        if now - last_flush > 10.0: # if we didn't flush for the last 10 seconds
            sys.stdout.flush()
            last_flush = now

    for process in list_of_processes:
        process.ExecuteInitializeSolutionStep()

    if (output_post == True):
        gid_output.ExecuteInitializeSolutionStep()

    solver.Solve()

    for process in list_of_processes:
        process.ExecuteFinalizeSolutionStep()

    if (output_post == True):
        gid_output.ExecuteFinalizeSolutionStep()

    for process in list_of_processes:
        process.ExecuteBeforeOutputStep()

    if (gid_output.IsOutputStep()) and (output_post == True):
        gid_output.PrintOutput()

    for process in list_of_processes:
        process.ExecuteAfterOutputStep()

for process in list_of_processes:
    process.ExecuteFinalize()

if (output_post == True):
    gid_output.ExecuteFinalize()
