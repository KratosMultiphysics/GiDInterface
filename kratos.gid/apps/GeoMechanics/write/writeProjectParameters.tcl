
# Project Parameters
proc ::GeoMechanics::write::getParametersDict { stage } {
    # Get the base dictionary for the project parameters
    
    set project_parameters_dict [Structural::write::getParametersDict $stage]

    if { [GetAttribute multistage_write_mdpa_file_mode] != "single_file" } {
        dict set project_parameters_dict solver_settings model_import_settings input_filename [$stage @name]
    }

    # add the phreatic water properties
    set list_of_processes [dict get $project_parameters_dict processes constraints_process_list]
    lappend list_of_processes [::GeoMechanics::write::getPhreaticWaterProperties $stage]
    dict set project_parameters_dict processes constraints_process_list $list_of_processes

    # Modify the analysis stage
    dict set project_parameters_dict analysis_stage "KratosMultiphysics.GeoMechanicsApplication.staged_geo_mechanics_analysis"

    return $project_parameters_dict
}


proc ::GeoMechanics::write::GetSingleFileStageProjectParameters {  } {
    # Get the base dictionary for the project parameters
    set project_parameters_dict [dict create]

    # Get the stages
    set stages_list [::GeoMechanics::xml::GetStages]
    set stages_names [list ]
    foreach stage $stages_list {
        lappend stages_names [$stage @name]
    }

    # Set the orchestrator
    dict set project_parameters_dict orchestrator [::write::GetOrchestratorDict $stages_names]

    # Set the stages
    set stages [dict create]

    set i 0
    foreach stage $stages_list {
        set stage_name [$stage @name]
        set stage_content [::GeoMechanics::write::getParametersDict $stage]
        # In first iteration we add the mdpa importer
        if {$i == 0} {
            set parameters_modeler [dict create input_filename [Kratos::GetModelName] model_part_name [write::GetConfigurationAttribute model_part_name]]
            dict set stages $stage_name stage_preprocess [::write::getPreprocessForStage $stage $parameters_modeler]
        } else {
            dict set stages $stage_name stage_preprocess [::write::getPreprocessForStage $stage]
        }
        dict set stages $stage_name stage_settings $stage_content
        dict set stages $stage_name stage_postprocess [::write::getPostprocessForStage $stage]
        incr i
    }

    dict set project_parameters_dict "stages" $stages
    
    return $project_parameters_dict
}


proc ::GeoMechanics::write::writeParametersEvent { } {
    if { [GetAttribute multistage_write_json_mode] == "single_file" } {  
        write::WriteJSON [::GeoMechanics::write::GetSingleFileStageProjectParameters]
    } else {
        set stages [::GeoMechanics::xml::GetStages]
        foreach stage $stages {
            write::CloseFile
            write::OpenFile "ProjectParameters[$stage @name].json"
            write::WriteJSON [::GeoMechanics::write::getParametersDict $stage]
        }

        # TODO: add the orchestrator in ProjectParameters.json
    }
}

# Get the phreatic water properties for the stage
proc ::GeoMechanics::write::getPhreaticWaterProperties { stage } {
    # Get the points from the tree
    set points [::GeoMechanics::xml::GetPhreaticPoints $stage]

    # TODO: AT THIS MOMENT WE ONLY ALLOW 2 POINTS
    set p1 [lindex $points 0] 
    set point_1 [lappend p1 0.0]
    set p2 [lindex $points end]
    set point_2 [lappend p2 0.0]

    set phreatic_water_process [dict create]
    dict set phreatic_water_process python_module apply_constant_phreatic_line_pressure_process
    dict set phreatic_water_process kratos_module KratosMultiphysics.GeoMechanicsApplication
    dict set phreatic_water_process process_name ApplyConstantPhreaticLinePressureProcess
    dict set phreatic_water_process Parameters model_part_name [GetAttribute model_part_name]
    dict set phreatic_water_process Parameters variable_name WATER_PRESSURE
    dict set phreatic_water_process Parameters first_reference_coordinate $point_1
    dict set phreatic_water_process Parameters second_reference_coordinate $point_2
}