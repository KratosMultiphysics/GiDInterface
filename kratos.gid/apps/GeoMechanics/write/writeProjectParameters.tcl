
# Project Parameters
proc ::GeoMechanics::write::getParametersDict { stage } {
    # Get the base dictionary for the project parameters
    
    set project_parameters_dict [Structural::write::getParametersDict $stage]

    if { [GetAttribute multistage_write_mdpa_file_mode] != "single_file" } {
        dict set project_parameters_dict solver_settings model_import_settings input_filename [$stage @name]
    }
    
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

    foreach stage [::GeoMechanics::xml::GetStages] {
        set stage_name [$stage @name]
        set stage_content [::GeoMechanics::write::getParametersDict $stage]
        dict set stage_content stage_preprocess prepare_restart write_restart true
        dict set stage_content stage_preprocess prepare_restart restart_settings [dict create]
        dict set stage_content stage_preprocess operations [list [dict create name "user_operation.UserOperation" parameters [dict create ] ]] 
        dict set stage_content stage_preprocess operations [list [dict create name "user_operation.UserOperation" parameters [dict create ] ]] 
        dict set stage_content stage_preprocess modelers [list [dict create name "KratosMultiphysics.modelers.import_mdpa_modeler.ImportMDPAModeler" Parameters [dict create ] ]]
        dict set stages $stage_name $stage_content
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
    }
}
