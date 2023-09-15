
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

    # Set the orchestrator
    dict set project_parameters_dict orchestrator name "MultistageOrchestrators.KratosMultiphysics.SequentialMultistageOrchestrator"
    dict set project_parameters_dict orchestrator settings echo_level 0
    dict set project_parameters_dict orchestrator settings execution_list [::GeoMechanics::xml::GetStages "names"]
    dict set project_parameters_dict orchestrator settings stage_checkpoints true
    dict set project_parameters_dict orchestrator settings stage_checkpoints_folder new_checkpoints
    # dict set project_parameters_dict orchestrator settings load_from_checkpoint "new_checkpoints/fluid_stage"

    # Set the stages
    set stages [dict create]

    set i 0
    foreach stage [::GeoMechanics::xml::GetStages] {
        set stage_name [$stage @name]
        set stage_content [::GeoMechanics::write::getParametersDict $stage]
        # In first iteration we add the mdpa importer
        if {$i == 0} {
            set parameters_modeler [dict create input_filename [Kratos::GetModelName] model_part_name [write::GetConfigurationAttribute model_part_name]]
            dict set stages $stage_name stage_preprocess [::GeoMechanics::write::getPreprocessForStage $stage $parameters_modeler]
        } else {
            dict set stages $stage_name stage_preprocess [::GeoMechanics::write::getPreprocessForStage $stage]
        }
        dict set stages $stage_name stage_settings $stage_content
        dict set stages $stage_name stage_postprocess [::GeoMechanics::write::getPostprocessForStage $stage]
        incr i
    }

    dict set project_parameters_dict "stages" $stages
    
    return $project_parameters_dict
}

# Get the dictionary for the preprocess of the stage
proc ::GeoMechanics::write::getPreprocessForStage {stage {mdpaimporter ""}} {
    set stage_preprocess [dict create ]
    set operation_parameters [dict create ]
    dict set stage_preprocess operations [list [dict create name "user_operation.EmptyOperation" Parameters $operation_parameters]] 

    if { $mdpaimporter ne "" } {
        # Get the modeler parameters
        set modeler [dict create name "KratosMultiphysics.modelers.import_mdpa_modeler.ImportMDPAModeler" Parameters $mdpaimporter]  
        dict set stage_preprocess modelers [list $modeler]
    }

    return $stage_preprocess 
}

# Get the dictionary for the postprocess of the stage
proc ::GeoMechanics::write::getPostprocessForStage {stage} {
    set stage_postprocess [dict create ]
    dict set stage_postprocess operations [list [dict create name "user_operation.EmptyOperation" Parameters [dict create ] ]] 

    return $stage_postprocess 
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