# Project Parameters
proc ::ShallowWater::write::getParametersDict { } {
    set projectParametersDict [dict create]

    # Set the problem data section
    dict set projectParametersDict problem_data [ShallowWater::write::GetProblemDataDict]

    # Solver settings
    # dict set projectParametersDict solver_settings [ConvectionDiffusion::write::GetSolverSettingsDict]

    set processes [dict create]
    # Boundary conditions processes
    dict set processes initial_conditions_process_list [write::getConditionsParametersDict [GetAttribute nodal_conditions_un] "Nodal"]
    dict set processes constraints_process_list [write::getConditionsParametersDict [GetAttribute conditions_un]]
    
    dict set projectParametersDict processes $processes

    # Output configuration
    dict set projectParametersDict output_processes [write::GetDefaultOutputProcessDict]

    return $projectParametersDict
}

proc ::ShallowWater::write::writeParametersEvent { } {
    write::WriteJSON [::ShallowWater::write::getParametersDict]
}



proc ::ShallowWater::write::GetProblemDataDict { } {

    # First section -> Problem data
    set problem_data_dict [dict create]
    set model_name [Kratos::GetModelName]
    dict set problem_data_dict problem_name $model_name

    # Parallelization
    set paralleltype [write::getValue ParallelType]
    dict set problem_data_dict parallel_type $paralleltype

    # Time step
    set timeSteppingDict [dict create]
    dict set problem_data_dict start_time [write::getValue SWTimeParameters StartTime]
    dict set problem_data_dict end_time [write::getValue SWTimeParameters EndTime]
    
    return $problem_data_dict
}