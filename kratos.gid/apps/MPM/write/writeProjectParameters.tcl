# Project Parameters
proc ::MPM::write::getParametersDict { } {
    set project_parameters_dict [Structural::write::getParametersDict]

    # Analysis stage field
    dict set project_parameters_dict analysis_stage "KratosMultiphysics.MPMApplication.mpm_analysis"

    # Quasi-static must be written as Quasi-static...
    set solutiontype [write::getValue STSoluType]
    dict set project_parameters_dict solver_settings solver_type $solutiontype
    if {$solutiontype eq "Quasi-static"} {
        dict set project_parameters_dict solver_settings time_integration_method [write::getValue STSolStrat]
        dict set project_parameters_dict solver_settings scheme_type [write::getValue STcheme]
    }

    # Time Parameters
    if {$solutiontype eq "Dynamic"} {
        dict unset project_parameters_dict solver_settings time_stepping "time_step_table"
        dict set project_parameters_dict solver_settings time_stepping "time_step" [write::getValue MPTimeParameters DeltaTime]
        dict set project_parameters_dict problem_data start_time [write::getValue MPTimeParameters StartTime]
        dict set project_parameters_dict problem_data end_time [write::getValue MPTimeParameters EndTime]
    }

    # Change the model part name
    dict set project_parameters_dict solver_settings model_part_name MPM_Material

    # create grid_import_settings
    dict set project_parameters_dict solver_settings grid_model_import_settings input_type use_input_model_part

    # materials file
    dict set project_parameters_dict solver_settings material_import_settings materials_filename [GetAttribute materials_file]

    # Axis-symmetric flag
    if {$::Model::SpatialDimension eq "2Da"} {
        dict set project_parameters_dict solver_settings axis_symmetric_flag true
    }

    # Pressure dofs
    set check_list [list "MPMUpdatedLagrangianUP2D" "MPMUpdatedLagrangianUP3D"]
    foreach elem $check_list {
        if {$elem in [MPM::write::GetUsedElements Name]} {
            dict set project_parameters_dict solver_settings pressure_dofs true
            set active_stab [write::getValue STStratParams ActivateStabilization]
            if {$active_stab eq "Off"} {
                dict set project_parameters_dict solver_settings stabilization "none"
            } else {
                dict set project_parameters_dict solver_settings stabilization "ppp"
            }
            dict unset project_parameters_dict solver_settings ActivateStabilization
            break
        } else {
            dict set project_parameters_dict solver_settings pressure_dofs false
            dict unset project_parameters_dict solver_settings activate_stabilization
            dict unset project_parameters_dict solver_settings stabilization
        }
    }


    # Rotation dofs
    dict unset project_parameters_dict solver_settings rotation_dofs

    # Line search
    dict unset project_parameters_dict solver_settings line_search

    # Volumetric strain dofs
    dict unset project_parameters_dict solver_settings strain_dofs
    dict unset project_parameters_dict solver_settings volumetric_strain_dofs

    # Add the solver information
    set solverSettingsDict [dict get $project_parameters_dict solver_settings]
    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolversParametersDict MPM] ]
    dict lappend solverSettingsDict auxiliary_variables_list RAYLEIGH_ALPHA
    dict set project_parameters_dict solver_settings $solverSettingsDict

    # Move slip to constraints
    set slip_process_list [list ]
    set new_load_process_list [list ]
    set load_process_list [dict get $project_parameters_dict processes loads_process_list]
    foreach load $load_process_list {
        if {[dict get $load python_module] eq "apply_mpm_slip_boundary_process"} {
            set load [MPM::write::CleanSlipBoundaryProcess $load]
            lappend slip_process_list $load
        } else {
            lappend new_load_process_list $load
        }
    }
    dict set project_parameters_dict processes loads_process_list $new_load_process_list
    dict set project_parameters_dict processes list_other_processes $slip_process_list

    # Gravity
    set activate_gravity [write::getValue ActivateGravity]
    if {$activate_gravity eq "On"} {
        set gravity_dict [dict create ]
        dict set gravity_dict python_module assign_gravity_to_material_point_process
        dict set gravity_dict kratos_module "KratosMultiphysics.MPMApplication"
        dict set gravity_dict process_name AssignGravityToMaterialPointProcess
        set gravity_parameters_dict [dict create ]
        dict set gravity_parameters_dict model_part_name MPM_Material
        dict set gravity_parameters_dict variable_name MP_VOLUME_ACCELERATION
        dict set gravity_parameters_dict modulus [write::getValue MPMGravity modulus]
        lassign [write::getValue MPMGravity direction] dx dy dz
        dict set gravity_parameters_dict direction [list [expr $dx] [expr $dy] [expr $dz]]
        dict set gravity_dict Parameters $gravity_parameters_dict
        dict set project_parameters_dict processes gravity [list $gravity_dict]
    }

    # Output processes
    dict set project_parameters_dict output_processes [MPM::write::GetOutputProcessesList]

    set json_output_processes [MPM::write::GetJsonOutputProcessesList]
    if {[llength $json_output_processes] > 0} {
        set other_processes_list [dict get $project_parameters_dict processes list_other_processes]
        foreach json_output_process $json_output_processes {
            lappend other_processes_list $json_output_process
        }
        dict set project_parameters_dict processes list_other_processes $other_processes_list
    }


    # REMOVE RAYLEIGH
    dict set project_parameters_dict solver_settings auxiliary_variables_list [list NORMAL IS_STRUCTURE]
    dict unset project_parameters_dict solver_settings rayleigh_alpha
    dict unset project_parameters_dict solver_settings rayleigh_beta

    # REMOVE use_old_stiffness_in_first_iteration
    dict unset project_parameters_dict solver_settings use_old_stiffness_in_first_iteration

    dict set project_parameters_dict modelers [write::getModelersParametersList [dict get $project_parameters_dict modelers]]

    return $project_parameters_dict
}


proc write::GetResultsList { un {cnd ""} } {
    if {$cnd eq ""} {set xp1 [spdAux::getRoute $un]} {set xp1 "[spdAux::getRoute $un]/container\[@n = '$cnd'\]"}
    return [GetResultsByXPathList $xp1]
}

proc ::MPM::write::GetValueFromBlock { block_node value_name {default ""} } {
    set value_node [$block_node selectNodes "./value\[@n='$value_name'\]"]
    if {$value_node eq ""} {
        return $default
    }
    return [write::getValueByNode $value_node]
}

proc ::MPM::write::GetJsonOutputFileName { block_node } {
    set output_file_settings_node [$block_node selectNodes "./container\[@n='OutputFileSettings'\]"]

    if {$output_file_settings_node ne ""} {
        set output_path [MPM::write::GetValueFromBlock $output_file_settings_node OutputPath]
        set file_name [MPM::write::GetValueFromBlock $output_file_settings_node FileName]
        set file_extension [MPM::write::GetValueFromBlock $output_file_settings_node FileExtension]
        if {$file_extension ne ""} {
            set output_file_name "${file_name}.${file_extension}"
        } else {
            set output_file_name $file_name
        }
    } else {
        set output_path [MPM::write::GetValueFromBlock $block_node OutputPath]
        set output_file_name [MPM::write::GetValueFromBlock $block_node OutputFileName]
    }

    if {$output_path eq ""} {
        return $output_file_name
    }
    return [file join $output_path $output_file_name]
}

proc ::MPM::write::GetJsonOutputVariablesList { block_node container_name } {
    set output_variables [list ]
    foreach variable_node [$block_node selectNodes "./container\[@n='$container_name'\]/value"] {
        if {[write::isBooleanTrue [get_domnode_attribute $variable_node v]] && [get_domnode_attribute $variable_node state] ne "hidden"} {
            lappend output_variables [get_domnode_attribute $variable_node n]
        }
    }
    return $output_variables
}

proc ::MPM::write::GetJsonOutputProcessesList { } {
    set json_output_processes [list ]

    set root [customlib::GetBaseRoot]
    set json_output_route [spdAux::getRoute JsonOutput]

    set enable_grid_json_output [write::getValue EnableBackgroundGridJsonOutput]
    if {[write::isBooleanTrue $enable_grid_json_output]} {
        foreach json_output_node [$root selectNodes "$json_output_route/container\[@n='BackgroundGridJsonOutput'\]/blockdata\[@n='JsonOutput'\]"] {
            lappend json_output_processes [MPM::write::GetBackgroundGridJsonOutputProcess $json_output_node]
        }
    }

    set enable_material_json_output [write::getValue EnableMaterialPointJsonOutput]
    if {[write::isBooleanTrue $enable_material_json_output]} {
        foreach json_output_node [$root selectNodes "$json_output_route/container\[@n='MaterialPointJsonOutput'\]/blockdata\[@n='JsonOutput'\]"] {
            lappend json_output_processes [MPM::write::GetMaterialPointJsonOutputProcess $json_output_node]
        }
    }

    return $json_output_processes
}

proc ::MPM::write::GetBackgroundGridJsonOutputProcess { json_output_node } {
    set json_dict [dict create ]
    dict set json_dict python_module json_output_process
    dict set json_dict kratos_module KratosMultiphysics
    dict set json_dict process_name JsonOutputProcess

    set json_parameters_dict [dict create ]
    dict set json_parameters_dict model_part_name [MPM::write::GetValueFromBlock $json_output_node ModelPartName Background_Grid]
    dict set json_parameters_dict output_file_name [MPM::write::GetJsonOutputFileName $json_output_node]
    dict set json_parameters_dict output_variables [MPM::write::GetJsonOutputVariablesList $json_output_node OutputVariables]
    dict set json_parameters_dict historical_value [write::getStringBinaryFromValue [MPM::write::GetValueFromBlock $json_output_node HistoricalValue true]]
    dict set json_parameters_dict resultant_solution [write::getStringBinaryFromValue [MPM::write::GetValueFromBlock $json_output_node ResultantSolution true]]
    dict set json_parameters_dict time_frequency [MPM::write::GetValueFromBlock $json_output_node TimeFrequency 1.0]

    dict set json_dict Parameters $json_parameters_dict
    return $json_dict
}

proc ::MPM::write::GetMaterialPointJsonOutputProcess { json_output_node } {
    set json_dict [dict create ]
    dict set json_dict kratos_module KratosMultiphysics.MPMApplication
    dict set json_dict python_module mpm_json_output_process

    set model_part_name [MPM::write::GetValueFromBlock $json_output_node ModelPartName MPM_Material]
    set split_model_part_name [split $model_part_name "."]
    set sub_model_part_name ""
    if {[llength $split_model_part_name] > 1} {
        set model_part_name [lindex $split_model_part_name 0]
        set sub_model_part_name [join [lrange $split_model_part_name 1 end] "."]
    }

    set json_parameters_dict [dict create ]
    dict set json_parameters_dict model_part_name $model_part_name
    dict set json_parameters_dict sub_model_part_name $sub_model_part_name
    dict set json_parameters_dict output_file_name [MPM::write::GetJsonOutputFileName $json_output_node]
    dict set json_parameters_dict gauss_points_output_variables [MPM::write::GetJsonOutputVariablesList $json_output_node GaussPointOutputVariables]
    dict set json_parameters_dict check_for_flag [MPM::write::GetValueFromBlock $json_output_node CheckForFlag]
    dict set json_parameters_dict time_frequency [MPM::write::GetValueFromBlock $json_output_node TimeFrequency 1.0]
    dict set json_parameters_dict resultant_solution [write::getStringBinaryFromValue [MPM::write::GetValueFromBlock $json_output_node ResultantSolution false]]

    dict set json_dict Parameters $json_parameters_dict
    return $json_dict
}



proc ::MPM::write::GetOutputProcessesList { } {
    set output_process [dict create]

    set project_parameters_dict [Structural::write::getParametersDict]
    # Change the model part name
    dict set project_parameters_dict solver_settings model_part_name MPM_Material

    # create grid_import_settings
    set grid_import_settings_dict [dict get $project_parameters_dict solver_settings model_import_settings]
    dict append grid_import_settings_dict input_filename _Grid
    dict set project_parameters_dict solver_settings grid_model_import_settings $grid_import_settings_dict

    # add _Body to model_import_settings
    set model_import_settings_dict [dict get $project_parameters_dict solver_settings model_import_settings]
    dict append model_import_settings_dict input_filename _Body
    dict set project_parameters_dict solver_settings model_import_settings $model_import_settings_dict

    set need_gid [write::getValue EnableGiDOutput]
    if {[write::isBooleanTrue $need_gid]} {

        set body_output_configuration_dict [lindex [dict get $project_parameters_dict output_processes gid_output] 0]
        set grid_output_configuration_dict [lindex [dict get $project_parameters_dict output_processes gid_output] 0]
        dict set body_output_configuration_dict python_module mpm_gid_output_process
        dict set body_output_configuration_dict kratos_module KratosMultiphysics.MPMApplication
        dict set body_output_configuration_dict process_name MPMGiDOutputProcess
        dict set body_output_configuration_dict Parameters model_part_name MPM_Material
        dict set grid_output_configuration_dict Parameters model_part_name Background_Grid
        dict set body_output_configuration_dict Parameters output_name [dict get $project_parameters_dict solver_settings model_import_settings input_filename]
        dict set grid_output_configuration_dict Parameters output_name [dict get $project_parameters_dict solver_settings grid_model_import_settings input_filename]
        dict unset body_output_configuration_dict Parameters postprocess_parameters result_file_configuration nodal_results


        dict unset grid_output_configuration_dict Parameters postprocess_parameters result_file_configuration gauss_point_results


        dict set project_parameters_dict output_processes body_output_process [list $body_output_configuration_dict]
        dict set project_parameters_dict output_processes grid_output_process [list $grid_output_configuration_dict]
        dict unset project_parameters_dict output_processes gid_output

        # Append the fluid and solid output processes to the output processes list
        lappend gid_output_processes_list $body_output_configuration_dict
        lappend gid_output_processes_list $grid_output_configuration_dict
        dict set output_process gid_output_processes $gid_output_processes_list

    }

    set need_vtk [write::getValue EnableVtkOutput]
    if {[write::isBooleanTrue $need_vtk]} {
        #set vtk_options_xpath "[spdAux::getRoute $results_UN]/container\[@n='VtkOutput'\]/container\[@n='VtkOptions'\]"

        set body_output_configuration_dict [lindex [dict get $project_parameters_dict output_processes vtk_output] 0]
        set grid_output_configuration_dict [lindex [dict get $project_parameters_dict output_processes vtk_output] 0]


        dict set body_output_configuration_dict python_module mpm_vtk_output_process
        dict set body_output_configuration_dict kratos_module KratosMultiphysics.MPMApplication
        dict set body_output_configuration_dict process_name MPMVtkOutputProcess
        dict set body_output_configuration_dict Parameters model_part_name MPM_Material
        dict unset body_output_configuration_dict Parameters nodal_data_value_variables
        dict unset body_output_configuration_dict Parameters element_data_value_variables
        dict unset body_output_configuration_dict Parameters condition_data_value_variables
        dict unset body_output_configuration_dict Parameters nodal_solution_step_data_variables
        #dict unset body_output_configuration_dict Parameters output_interval
        #set outputCT [getValueByXPath $vtk_options_xpath OutputControlType]
        #dict set resultDict output_control_type $outputCT
        #if {$outputCT eq "time"} {set frequency [getValueByXPath $vtk_options_xpath OutputDeltaTime]} {set frequency [getValueByXPath $vtk_options_xpath OutputDeltaStep]}
        dict set body_output_configuration_dict Parameters output_path  "vtk_output_Body"
        dict unset body_output_configuration_dict Parameters gauss_point_variables_extrapolated_to_nodes
        dict set body_output_configuration_dict Parameters gauss_point_variables_in_elements [write::GetResultsList ElementResults]


        dict set grid_output_configuration_dict Parameters model_part_name Background_Grid
        dict unset grid_output_configuration_dict Parameters gauss_point_variables_extrapolated_to_nodes
        dict unset grid_output_configuration_dict Parameters nodal_data_value_variables
        dict unset grid_output_configuration_dict Parameters element_data_value_variables
        dict unset grid_output_configuration_dict Parameters condition_data_value_variables


        dict set project_parameters_dict output_processes body_output_process [list $body_output_configuration_dict]
        #dict set project_parameters_dict output_processes grid_output_process [list $grid_output_configuration_dict]
        dict unset project_parameters_dict output_processes vtk_output
        dict unset grid_output_configuration_dict Parameters gauss_point_results

        # Append the fluid and solid output processes to the output processes list
        lappend vtk_output_processes_list $grid_output_configuration_dict
        lappend vtk_output_processes_list $body_output_configuration_dict
        dict set output_process vtk_output_processes $vtk_output_processes_list


    }

    # Restart
    set need_restart [write::getValue EnableRestartOutput]
    if {[write::isBooleanTrue $need_restart]} {
        set restart_dict [dict create ]
        dict set restart_dict python_module save_restart_process
        dict set restart_dict kratos_module KratosMultiphysics
        dict set restart_dict process_name SaveRestartProcess
        set restart_parameters_dict [dict create ]
        dict set restart_parameters_dict model_part_name MPM_Material
        dict set restart_parameters_dict echo_level 0
        set restOutputCT [write::getValue RestartOptions OutputControlType]
        dict set restart_parameters_dict restart_control_type $restOutputCT
        if {$restOutputCT eq "time"} {dict set restart_parameters_dict restart_save_frequency [write::getValue RestartOptions OutputDeltaTime]} {dict set restart_parameters_dict restart_save_frequency [write::getValue RestartOptions OutputDeltaStep]}
        dict set restart_dict Parameters $restart_parameters_dict
        dict set output_process save_restart_process [list $restart_dict]

    }
    
    # Energy output
    lassign [write::getValue EnergyOutput EnableEnergyOutput] energy_output
    if {$energy_output eq "Yes"} {
        set energy_dict [dict create ]
        dict set energy_dict python_module mpm_write_energy_output_process
        dict set energy_dict kratos_module "KratosMultiphysics.MPMApplication"
        dict set energy_dict process_name MPMWriteEnergyOutputProcess

        set energy_parameters_dict [dict create ]
        dict set energy_parameters_dict model_part_name "MPM_Material"
        set energy_output_control [write::getValue EnergyOptions OutputControlType]
        dict set energy_parameters_dict output_control_type $energy_output_control
        if {$energy_output_control eq "time"} {
            dict set energy_parameters_dict output_interval [write::getValue EnergyOptions OutputDeltaTime]
        } else {
            dict set energy_parameters_dict output_interval [write::getValue EnergyOptions OutputDeltaStep]
        }
        dict set energy_parameters_dict print_format [write::getValue EnergyOptions PrintFormat]

        set output_file_settings_dict [dict create ]
        set output_path_value [write::getValue OutputFileSettings OutputPath]
        # If OutputPath is empty, use "." (current folder), otherwise use the provided value
        if {$output_path_value eq ""} {
            set output_path_value "."
        }
        dict set output_file_settings_dict output_path [string map {} $output_path_value]
        dict set output_file_settings_dict file_name [write::getValue OutputFileSettings FileName]
        dict set output_file_settings_dict file_extension [write::getValue OutputFileSettings FileExtension]
        dict set energy_parameters_dict output_file_settings $output_file_settings_dict

        dict set energy_dict Parameters $energy_parameters_dict
        dict set output_process mpm_energy_output [list $energy_dict]
    }


    return $output_process
}

proc ::MPM::write::getModelersParametersList { old_modelers } {

    set body_groups [MPM::write::GetPartsGroupsNames Body]
    set corrected_names [list ]
    foreach g $body_groups {
        lappend corrected_names [write::transformGroupName $g]
    }
    set body_groups $corrected_names
    set lista [list ]
    foreach modeler $old_modelers {
        set new_modeler [dict create]
        # if [dict get $modeler name] contains "ImportMDPAModeler"
        set name [dict get $modeler name]
        if {[string match "*ImportMDPAModeler" $name]} {
            dict set new_modeler name $name
            dict set new_modeler parameters input_filename [Kratos::GetModelName]_Grid
            dict set new_modeler parameters model_part_name "Background_Grid"
            lappend lista $new_modeler

            dict set new_modeler name $name
            dict set new_modeler parameters input_filename [Kratos::GetModelName]_Body
            dict set new_modeler parameters model_part_name "Initial_MPM_Material"
            lappend lista $new_modeler
        } elseif {[string match "*CreateEntitiesFromGeometriesModeler" $name]} {
            dict set new_modeler name $name
            set elements_list [list ]
            foreach element [dict get $modeler parameters elements_list] {
                set new_element [dict create]
                set model_part_name [dict get $element model_part_name]
                set group_name [lindex [split $model_part_name "."] end]
                set good_name [write::transformGroupName $group_name]
                if {$good_name in $body_groups} {
                    dict set new_element model_part_name "Initial_MPM_Material.$good_name"
                } else {
                    dict set new_element model_part_name $model_part_name
                }
                dict set new_element element_name [dict get $element element_name]
                lappend elements_list $new_element
            }

            dict set new_modeler parameters elements_list $elements_list
            dict set new_modeler parameters conditions_list [dict get $modeler parameters conditions_list]
            lappend lista $new_modeler
        }
    }
    return $lista
}

proc ::MPM::write::writeParametersEvent { } {
    write::WriteJSON [getParametersDict]
}

proc ::MPM::write::CleanSlipBoundaryProcess { slip_process_dict } {
    if {![dict exists $slip_process_dict Parameters]} {
        return $slip_process_dict
    }

    set friction "Off"
    if {[dict exists $slip_process_dict Parameters Friction]} {
        set friction [dict get $slip_process_dict Parameters Friction]
        dict unset slip_process_dict Parameters Friction
    }

    if {$friction ne "On"} {
        foreach parameter_name [list friction_coefficient tangential_penalty_factor option] {
            if {[dict exists $slip_process_dict Parameters $parameter_name]} {
                dict unset slip_process_dict Parameters $parameter_name
            }
        }
        return $slip_process_dict
    }

    if {[dict exists $slip_process_dict Parameters option]} {
        set option [dict get $slip_process_dict Parameters option]
        if {$option eq "" || $option eq "none"} {
            dict unset slip_process_dict Parameters option
        }
    }

    return $slip_process_dict
}
