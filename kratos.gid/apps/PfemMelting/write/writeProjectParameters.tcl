
proc ::PfemMelting::write::getParametersDict { } {
    # Get the project parameters from buoyancy
    set project_parameters_dict [::Buoyancy::write::getParametersDict]
    
    # Set laser import settings
    dict set project_parameters_dict problem_data laser_import_settings laser_filename [::write::getValue PFEMMELTING_Laser Parameters_file]
    # Move fluid material settings
    dict set project_parameters_dict problem_data material_settings [dict get $project_parameters_dict solver_settings fluid_solver_settings material_import_settings]
    dict unset project_parameters_dict solver_settings fluid_solver_settings material_import_settings
    # Add InitialTemperature process using Parts submodelpart
    # Copy Ambient temperature to the processes

    return $project_parameters_dict
}

proc ::PfemMelting::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}
