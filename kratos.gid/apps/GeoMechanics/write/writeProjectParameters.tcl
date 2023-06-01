
# Project Parameters
proc ::GeoMechanics::write::getParametersDict { stage } {
    # Get the base dictionary for the project parameters
    set project_parameters_dict [dict create]

    

    return $project_parameters_dict
}

proc ::GeoMechanics::write::writeParametersEvent { } {
    
    set stages [::GeoMechanics::xml::GetStages]
    foreach stage $stages {
        write::CloseFile
        write::OpenFile "ProjectParameters[$stage @name].json"
        write::WriteJSON [::GeoMechanics::write::getParametersDict $stage]
    }
}
