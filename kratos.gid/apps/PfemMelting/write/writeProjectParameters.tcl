
proc ::PfemMelting::write::getParametersDict { } {
    set project_parameters_dict [dict create ]

    dict set project_parameters_dict problem_data [GetProblemDataDict]
    dict set project_parameters_dict output_processes [GetProblemDataDict]
    dict set project_parameters_dict restart_options [GetProblemDataDict]
    dict set project_parameters_dict solver_settings [GetProblemDataDict]
    dict set project_parameters_dict processes [GetProblemDataDict]

    # Set reform_dofs_at_each_step
    dict set project_parameters_dict solver_settings thermal_solver_settings reform_dofs_at_each_step true
    dict set project_parameters_dict solver_settings fluid_solver_settings reform_dofs_at_each_step true
    dict set project_parameters_dict solver_settings fluid_solver_settings alpha 0.0
    dict set project_parameters_dict solver_settings fluid_solver_settings move_mesh_strategy 2

    dict set project_parameters_dict solver_settings solver_type ThermallyCoupledPfem2

    return $project_parameters_dict
}

proc ::PfemMelting::write::GetProblemDataDict { } {
    set problem_data_dict [write::GetDefaultProblemDataDict]
    dict set problem_data_dict domain_size 3
    dict set problem_data_dict material_settings material_filename MateralCharacterization.json
    dict set problem_data_dict environment_settings gravity [write::GetGravityByModuleDirection Gravity]
    dict set problem_data_dict environment_settings ambient_temperature 293.15
    return $problem_data_dict
}

proc ::PfemMelting::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}
