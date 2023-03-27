# Project Parameters

proc ::GeoMechanics::write::writeParametersEvent { } {
    write::WriteJSON [getParametersDict]

}

# Project Parameters
proc ::GeoMechanics::write::getParametersDict { } {
    # Get the base dictionary for the project parameters
    set project_parameters_dict [dict create]

    return $project_parameters_dict
}

proc ::GeoMechanics::write::writeParametersEvent { } {
    write::WriteJSON [::GeoMechanics::write::getParametersDict]
}
