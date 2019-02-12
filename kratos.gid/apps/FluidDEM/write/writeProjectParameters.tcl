# Project Parameters
proc ::FluidDEM::write::getParametersDict { } {
    set project_parameters_dict [dict create ]
    set dem_project_parameters_dict [DEM::write::getParametersEvent]
    set fluid_project_parameters_dict [Fluid::write::writeParametersEvent]
    return $project_parameters_dict
}

proc FluidDEM::write::writeParametersEvent { } {
    # DEM
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}
