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
    set grid_import_settings_dict [dict get $project_parameters_dict solver_settings model_import_settings]
    dict append grid_import_settings_dict input_filename _Grid
    dict set project_parameters_dict solver_settings grid_model_import_settings $grid_import_settings_dict

    # add _Body to model_import_settings
    set model_import_settings_dict [dict get $project_parameters_dict solver_settings model_import_settings]
    dict append model_import_settings_dict input_filename _Body
    if {[write::isBooleanTrue [write::getValue EnableRestartOutput]]} {dict set model_import_settings_dict restart_load_file_label " "}
    dict set project_parameters_dict solver_settings model_import_settings $model_import_settings_dict


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


    # REMOVE RAYLEIGH
    dict set project_parameters_dict solver_settings auxiliary_variables_list [list NORMAL IS_STRUCTURE]
    dict unset project_parameters_dict solver_settings rayleigh_alpha
    dict unset project_parameters_dict solver_settings rayleigh_beta

    # REMOVE use_old_stiffness_in_first_iteration
    dict unset project_parameters_dict solver_settings use_old_stiffness_in_first_iteration

    return $project_parameters_dict
}


proc write::GetResultsList { un {cnd ""} } {
    if {$cnd eq ""} {set xp1 [spdAux::getRoute $un]} {set xp1 "[spdAux::getRoute $un]/container\[@n = '$cnd'\]"}
    return [GetResultsByXPathList $xp1]
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

    return $output_process
}


proc ::MPM::write::writeParametersEvent { } {
    write::WriteJSON [getParametersDict]
}
