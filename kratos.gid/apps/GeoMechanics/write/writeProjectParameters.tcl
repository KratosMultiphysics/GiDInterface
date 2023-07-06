
# Project Parameters
proc ::GeoMechanics::write::getParametersDict { stage } {
    # Get the base dictionary for the project parameters
    
    set project_parameters_dict [Structural::write::getParametersDict $stage]

    if { [GetAttribute multistage_write_mdpa_file_mode] != "single_file" } {
        dict set project_parameters_dict solver_settings model_import_settings input_filename [$stage @name]
    }
    
    return $project_parameters_dict
}

proc ::GeoMechanics::write::GetSingleFileStageProjectParameters {  } {
    # Get the base dictionary for the project parameters
    set project_parameters_dict [dict create]

    # Set the list of stages
    dict set project_parameters_dict "execution_list" [::GeoMechanics::xml::GetStages "names"]

    # Set the stages
    set stages [dict create]

    foreach stage [::GeoMechanics::xml::GetStages] {
        set stage_name [$stage @name]
        dict set stages $stage_name [::GeoMechanics::write::getParametersDict $stage]
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
