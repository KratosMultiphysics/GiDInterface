# Project Parameters
proc ::FluidDEM::write::getParametersDict { } {
    set project_parameters_dict [dict create ]
    FluidDEM::write::InitExternalProjectParameters
    dict set project_parameters_dict DEM $FluidDEM::write::dem_project_parameters
    dict set project_parameters_dict Fluid $FluidDEM::write::fluid_project_parameters
    # TODO: Get common things or hardcode them
    dict set project_parameters_dict General [dict create]
    return $project_parameters_dict
}

proc FluidDEM::write::writeParametersEvent { } {
    # DEM
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}


proc FluidDEM::write::InitExternalProjectParameters { } {
    # Fluid section
    #UpdateUniqueNames Fluid
    apps::setActiveAppSoft Fluid
    write::initWriteConfiguration [Fluid::write::GetAttributes]
    set FluidDEM::write::fluid_project_parameters [Fluid::write::getParametersDict]

    # Structure section
    #UpdateUniqueNames DEM
    apps::setActiveAppSoft DEM
    write::initWriteConfiguration [DEM::write::GetAttributes]
    set FluidDEM::write::dem_project_parameters [DEM::write::getParametersDict]

    
    apps::setActiveAppSoft FluidDEM
}