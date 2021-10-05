# Project Parameters
proc ::ShallowWater::write::writeParametersEvent { } {
    write::WriteJSON [getParametersDict]
}

proc ::ShallowWater::write::getParametersDict { } {
    set projectParametersDict [dict create]

    # Set the problem data section
    dict set projectParametersDict problem_data [GetProblemDataDict]

    # Solver settings
    dict set projectParametersDict solver_settings [GetSolverSettingsDict]

    # Regular processes
    set processes [dict create]
    dict set processes topography_process_list [write::getConditionsParametersDict [GetAttribute topography_data_un] "Nodal"]
    dict set processes initial_conditions_process_list [write::getConditionsParametersDict [GetAttribute initial_conditions_un] "Nodal"]
    dict set processes boundary_conditions_process_list [write::getConditionsParametersDict [GetAttribute conditions_un]]
    dict set projectParametersDict processes $processes

    # Output processes
    dict set projectParametersDict output_processes [write::GetDefaultOutputProcessDict]

    return $projectParametersDict
}

proc ::ShallowWater::write::GetProblemDataDict { } {

    # First section -> Problem data
    set problem_data_dict [dict create]
    set model_name [Kratos::GetModelName]
    dict set problem_data_dict problem_name $model_name

    # Parallelization
    set paralleltype [write::getValue ParallelType]
    dict set problem_data_dict parallel_type $paralleltype

    # Time settings
    set timeSteppingDict [dict create]
    dict set problem_data_dict start_time [write::getValue SWTimeParameters StartTime]
    dict set problem_data_dict end_time [write::getValue SWTimeParameters EndTime]

    # Write the echo level in the problem data section
    set echo_level [write::getValue Results EchoLevel]
    dict set problem_data_dict echo_level $echo_level

    return $problem_data_dict
}

proc ::ShallowWater::write::GetSolverSettingsDict { } {
    # General data
    set solverSettingsDict [dict create]
    dict set solverSettingsDict solver_type "stabilized_shallow_water_solver"
    dict set solverSettingsDict model_part_name [GetAttribute model_part_name]
    dict set solverSettingsDict domain_size 2

    # Model import settings
    set modelImportDict [dict create]
    dict set modelImportDict input_type "mdpa"
    dict set modelImportDict input_filename [Kratos::GetModelName]
    dict set solverSettingsDict model_import_settings $modelImportDict

    # Materials
    set materialsDict [dict create]
    dict set materialsDict materials_filename [GetAttribute materials_file]
    dict set solverSettingsDict material_import_settings $materialsDict

    # set solverSettingsDict [dict merge $solverSettingsDict [write::getSolutionStrategyParametersDict SWSolutionStrat SWScheme SWStratParams]]
    # set solverSettingsDict [dict merge $solverSettingsDict [write::getSolversParametersDict ShallowWater]]

    # Time stepping settings
    set timeSteppingDict [dict create]
    if {[write::getValue SWAutomaticDeltaTime] eq "Yes"} {
        dict set timeSteppingDict courant_number [write::getValue SWTimeParameters CFLNumber]
        dict set timeSteppingDict maximum_delta_time [write::getValue SWTimeParameters MaximumDeltaTime]
        dict set timeSteppingDict minimum_delta_time [write::getValue SWTimeParameters MinimumDeltaTime]
    } else {
        dict set timeSteppingDict time_step [write::getValue SWTimeParameters DeltaTime]
    }
    dict set solverSettingsDict time_stepping $timeSteppingDict

    return $solverSettingsDict
}
