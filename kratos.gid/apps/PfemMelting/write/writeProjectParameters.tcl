
proc ::PfemMelting::write::getParametersDict { } {
    set project_parameters_dict [dict create ]

    # Set reform_dofs_at_each_step
    dict set project_parameters_dict solver_settings thermal_solver_settings reform_dofs_at_each_step true
    dict set project_parameters_dict solver_settings fluid_solver_settings reform_dofs_at_each_step true
    dict set project_parameters_dict solver_settings fluid_solver_settings alpha 0.0
    dict set project_parameters_dict solver_settings fluid_solver_settings move_mesh_strategy 2

    dict set project_parameters_dict solver_settings solver_type ThermallyCoupledPfem2

    return $project_parameters_dict
}

proc ::PfemMelting::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}
