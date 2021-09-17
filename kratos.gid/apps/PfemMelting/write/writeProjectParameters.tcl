
proc ::PfemMelting::write::getParametersDict { } {
    # Get the ma
    set project_parameters_dict [::Buoyancy::write::getParametersDict]
    dict set project_parameters_dict problem_data laser_import_settings laser_filename [::write::getValue PFEMMELTING_Laser Parameters_file]
    dict set project_parameters_dict problem_data material_settings [dict get $project_parameters_dict solver_settings fluid_solver_settings material_import_settings]
    dict unset project_parameters_dict solver_settings fluid_solver_settings material_import_settings
    return $project_parameters_dict
}

proc ::PfemMelting::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}
