# Project Parameters
proc ::MPM::write::getParametersDict { } {
    set project_parameters_dict [Structural::write::getParametersEvent]

    # Change the model part name
    dict set project_parameters_dict problem_data model_part_name MPM_Material

    # Quasi-static must be written as Quasi-static...
    set solutiontype [write::getValue STSoluType]
    dict set project_parameters_dict solver_settings solver_type $solutiontype
        
    # create grid_import_settings
    set grid_import_settings_dict [dict get $project_parameters_dict solver_settings model_import_settings]
    dict append grid_import_settings_dict input_filename _Grid
    dict set project_parameters_dict solver_settings grid_model_import_settings $grid_import_settings_dict
    
    # add _Body to model_import_settings
    set model_import_settings_dict [dict get $project_parameters_dict solver_settings model_import_settings]
    dict append model_import_settings_dict input_filename _Body
    dict set project_parameters_dict solver_settings model_import_settings $model_import_settings_dict

    # Geometry in elements
    set geometry_element [dict get $project_parameters_dict solver_settings geometry_element]
    if {$geometry_element eq "Triangle"} {
        dict unset project_parameters_dict solver_settings particle_per_element_quadrilateral
        set number [dict get $project_parameters_dict solver_settings particle_per_element_triangle]
        dict unset project_parameters_dict solver_settings particle_per_element_triangle
    } else {
        dict unset project_parameters_dict solver_settings particle_per_element_triangle
        set number [dict get $project_parameters_dict solver_settings particle_per_element_quadrilateral]
        dict unset project_parameters_dict solver_settings particle_per_element_quadrilateral
    }
    dict set project_parameters_dict solver_settings particle_per_element $number

    # Pressure dofs
    dict set project_parameters_dict solver_settings pressure_dofs false

    # Add the solver information
    set solverSettingsDict [dict get $project_parameters_dict solver_settings]
    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolversParametersDict MPM] ]
    dict set project_parameters_dict solver_settings $solverSettingsDict

    return $project_parameters_dict
}
proc ::MPM::write::writeParametersEvent { } {
    write::WriteJSON [getParametersDict]
}

