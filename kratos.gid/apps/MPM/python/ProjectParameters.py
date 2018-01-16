domain_size = $domain_size

#Problem Data
#################################################

ProblemType = "Mechanical"
NumberofThreads = 1
Solution_method = "Newton-Raphson"
SolverType = $solution_type
time_step = $time_step
end_time = $end_time

#Solver Data
#################################################

class SolverSettings:
    solver_type = "particle_solver"
    domain_size = $domain_size
    echo_level  = $echo_level

    max_delta_time  = time_step
    time_integration_method = "Implicit"
    explicit_integration_scheme = "CentralDifferences"
    time_step_prediction_level  = "Automatic"
    rayleigh_damping = False

    RotationDofs = False
    PressureDofs = False
    ReformDofSetAtEachStep = False
    LineSearch = False
    Implex = False
    ComputeReactions = True
    ComputeContactForces = False
    scheme_type = $solution_type
    convergence_criterion = "Residual_criteria"
    displacement_relative_tolerance = 1.0E-4
    displacement_absolute_tolerance = 1.0E-9
    residual_relative_tolerance = 1.0E-4
    residual_absolute_tolerance = 1.0E-9
    max_iteration = 10
    class linear_solver_config:
        solver_type = $solver_type
        scaling = $scaling


#Constraints Data
#################################################

Incremental_Load = "False"
Incremental_Displacement = "False"

#PostProcess Data
#################################################

nodal_results=["DISPLACEMENT", "REACTION"]
gauss_points_results=[]

# GiD output configuration
class GidOutputConfiguration:
    GiDPostMode = "Binary"
    GiDWriteMeshFlag = False
    GiDWriteConditionsFlag = False
    GiDWriteParticlesFlag = False
    GiDMultiFileFlag = "Single"

GiDWriteFrequency = $GiDWriteFrequency
WriteResults = "PreMeshing"
echo_level = $echo_level

# graph_options
PlotGraphs = "False"
PlotFrequency = 0 

# list options
PrintLists = "True"
file_list = [] 

# restart options
SaveRestart = False
RestartFrequency = 0
LoadRestart = False
Restart_Step = 0

problem_name=$problem_name_grid
problem_name2=$problem_name_body
problem_path="/home/prestamo/Desktop/angle_og_repose/angle_repose_test.gid"
