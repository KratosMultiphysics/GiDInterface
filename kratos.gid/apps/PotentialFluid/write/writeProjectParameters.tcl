
proc PotentialFluid::write::writeParametersEvent { } {
    ## Get the base settings dictionary from the base application (Fluid)
    set projectParametersDict [Fluid::write::getParametersDict]

    ## Remove unused entries
    # Remove gravity and initial conditions
    dict set projectParametersDict processes [dict remove [dict get $projectParametersDict processes] gravity]
    dict set projectParametersDict processes [dict remove [dict get $projectParametersDict processes] initial_conditions_process_list]
    # Remove time stepping settings
    dict set projectParametersDict solver_settings [dict remove [dict get $projectParametersDict solver_settings] time_stepping]
    
    ## Set the parallelism
    write::SetParallelismConfiguration

    ## Write the resultant settings dictionary to .json
    write::WriteJSON $projectParametersDict
}
