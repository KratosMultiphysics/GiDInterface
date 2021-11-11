
proc ::PfemMelting::write::getParametersDict { } {
    set project_parameters_dict [dict create ]

    dict set project_parameters_dict problem_data [GetProblemDataDict]
    dict set project_parameters_dict output_processes  [write::GetDefaultOutputProcessDict]
    dict set project_parameters_dict restart_options [write::GetDefaultRestartDict]
    dict set project_parameters_dict solver_settings [Getsolver_settings_dict]
    dict set project_parameters_dict processes [write::getConditionsParametersDict BC]
    dict lappend project_parameters_dict processes {*}[getLaserProcesses]

    return $project_parameters_dict
}

proc ::PfemMelting::write::GetProblemDataDict { } {
    set problem_data_dict [write::GetDefaultProblemDataDict]
    dict set problem_data_dict domain_size 3
    dict set problem_data_dict material_settings material_filename [GetAttribute materials_file]
    dict set problem_data_dict environment_settings gravity [write::GetGravityByModuleDirection Gravity]
    dict set problem_data_dict environment_settings ambient_temperature [write::getValue [::PfemMelting::GetUniqueName ambient_temperature]]
    return $problem_data_dict
}

proc ::PfemMelting::write::Getsolver_settings_dict { } {
    set solver_settings_dict [dict create ]

    dict set solver_settings_dict solver_type ThermallyCoupledPfem2
    dict set solver_settings_dict domain_size 3
    dict set solver_settings_dict echo_level 0

    dict set solver_settings_dict fluid_solver_settings [GetSolverSettingsFluidDict]
    dict set solver_settings_dict thermal_solver_settings [GetSolverSettingsThermicDict]

    return $solver_settings_dict
}

proc ::PfemMelting::write::GetSolverSettingsFluidDict { } {
    set solver_settings_dict [dict create ]

    dict set solver_settings_dict model_part_name [GetAttribute model_part_name]
    dict set solver_settings_dict domain_size 3
    dict set solver_settings_dict solver_type Monolithic

    # model import settings
    dict set solver_settings_dict model_import_settings input_type "mdpa"
    dict set solver_settings_dict model_import_settings input_filename [Kratos::GetModelName]

    set solver_settings_dict [dict merge $solver_settings_dict [write::getSolutionStrategyParametersDict "" "" StratParams] ]
    set solver_settings_dict [dict merge $solver_settings_dict [write::getSolversParametersDict] ]
    foreach key [list convergence_criterion line_search solution_relative_tolerance solution_absolute_tolerance residual_relative_tolerance residual_absolute_tolerance max_iteration] { if {[dict exists $solver_settings_dict $key]} {dict unset solver_settings_dict $key} }

    # Skin parts
    dict set solver_settings_dict skin_parts [list "NoSlip3D_No_Slip_Auto1"]
    dict set solver_settings_dict volume_model_part_name [GetAttribute model_part_name]
    # dict set solver_settings_dict


    # Time stepping settings
    set timeSteppingDict [dict create]
    dict set timeSteppingDict "time_step" [write::getValue TimeParameters DeltaTime]
    dict set timeSteppingDict "automatic_time_step" false

    dict set solver_settings_dict time_stepping $timeSteppingDict

    # Create formulation dictionary
    set formulationSettingsDict [dict create]

    # Set formulation dictionary element type
    dict set formulationSettingsDict element_type vms

    # Set OSS and remove oss_switch from the original dictionary
    # It is important to check that there is oss_switch, otherwise the derived apps (e.g. embedded) might crash
    if {[dict exists $solver_settings_dict oss_switch]} {
        # Always remove the oss_switch from the original dictionary
        dict unset solver_settings_dict oss_switch
    }

    # Set dynamic tau and remove it from the original dictionary
    if {[dict exists $solver_settings_dict dynamic_tau]} {
        dict set formulationSettingsDict use_orthogonal_subscales false
        dict set formulationSettingsDict dynamic_tau [dict get $solver_settings_dict dynamic_tau]
        dict unset solver_settings_dict dynamic_tau
    }

    # Include the formulation settings in the solver settings dict
    dict set solver_settings_dict formulation $formulationSettingsDict

    return $solver_settings_dict
}

proc ::PfemMelting::write::GetSolverSettingsThermicDict { } {
    set solver_settings_dict [dict create ]

    dict set solver_settings_dict model_part_name [GetAttribute model_part_name]
    dict set solver_settings_dict domain_size 3
    dict set solver_settings_dict solver_type transient
    dict set solver_settings_dict analysis_type non_linear

    # model import settings
    dict set solver_settings_dict model_import_settings input_type "mdpa"
    dict set solver_settings_dict model_import_settings input_filename [Kratos::GetModelName]
    dict set solver_settings_dict material_import_settings materials_filename material.json

    dict set solver_settings_dict time_integration_method implicit

    set solver_settings_dict [dict merge $solver_settings_dict [write::getSolutionStrategyParametersDict "" "" StratParams] ]
    set solver_settings_dict [dict merge $solver_settings_dict [write::getSolversParametersDict] ]

    foreach key [list relative_velocity_tolerance absolute_velocity_tolerance relative_pressure_tolerance absolute_pressure_tolerance] { if {[dict exists $solver_settings_dict $key]} {dict unset solver_settings_dict $key} }

    dict set solver_settings_dict problem_domain_sub_model_part_list [list [GetAttribute model_part_name]]

    # Time stepping settings
    set timeSteppingDict [dict create]
    dict set timeSteppingDict "time_step" [write::getValue TimeParameters DeltaTime]

    dict set solver_settings_dict time_stepping $timeSteppingDict

    # Create formulation dictionary
    set formulationSettingsDict [dict create]

    # Set OSS and remove oss_switch from the original dictionary
    # It is important to check that there is oss_switch, otherwise the derived apps (e.g. embedded) might crash
    if {[dict exists $solver_settings_dict oss_switch]} {
        # Always remove the oss_switch from the original dictionary
        dict unset solver_settings_dict oss_switch
    }

    # Set dynamic tau and remove it from the original dictionary
    if {[dict exists $solver_settings_dict dynamic_tau]} {
        dict set formulationSettingsDict theta 0.5
        dict set formulationSettingsDict dynamic_tau [dict get $solver_settings_dict dynamic_tau]
        dict unset solver_settings_dict dynamic_tau
    }

    # Include the formulation settings in the solver settings dict
    dict set solver_settings_dict transient_parameters $formulationSettingsDict

    return $solver_settings_dict
}

proc ::PfemMelting::write::getLaserProcesses { } {
    set laser_process_list [list ]
    set lasers [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute [::PfemMelting::GetUniqueName laser]]/blockdata/value\[@n='laser_path'\]"]
    foreach laser $lasers {
        set laser_process_dict [dict create]
        dict set laser_process_dict python_module apply_laser_process
        dict set laser_process_dict kratos_module KratosMultiphysics.PfemMelting
        dict set laser_process_dict Parameters model_part_name [GetAttribute model_part_name]
        dict set laser_process_dict Parameters filename [write::getValueByNode $laser]
        lappend laser_process_list $laser_process_dict
    }
    return $laser_process_list
}

proc ::PfemMelting::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}
