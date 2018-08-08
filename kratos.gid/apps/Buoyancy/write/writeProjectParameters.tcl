# Project Parameters
proc ::Buoyancy::write::getParametersDict { } {
    set projectParametersDict [dict create]

    # problem data
    set problem_data_dict [dict create]
    dict set projectParametersDict problem_data $problem_data_dict

    # output configuration
    set output_configuration_dict [dict create]
    dict set projectParametersDict output_configuration $output_configuration_dict

    # restart options
    set restart_options_dict [dict create]
    dict set projectParametersDict restart_options $restart_options_dict

    # solver settings
    set solver_settings_dict [dict create]
    dict set projectParametersDict solver_settings $solver_settings_dict

    # processes
    set processes_dict [dict create]
    dict set projectParametersDict processes $processes_dict

    return $projectParametersDict
}

proc Buoyancy::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}

