namespace eval Structural::write {

}

proc Structural::write::Init { } {
}


# Project Parameters
proc Structural::write::getParametersEvent { } {
    set project_parameters_dict [::Solid::write::getParametersDict]
    dict set project_parameters_dict solver_settings rotation_dofs [UsingRotationDofElements]
    set solverSettingsDict [dict get $project_parameters_dict solver_settings]
    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolversParametersDict Structural] ]
    dict set project_parameters_dict solver_settings $solverSettingsDict
    return $project_parameters_dict
}
proc Structural::write::writeParametersEvent { } {
    write::WriteJSON [getParametersEvent]
}

proc Structural::write::UsingRotationDofElements { } {
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute STParts]/group/value\[@n='Element'\]"
    set elements [$root selectNodes $xp1]
    set bool false
    foreach element_node $elements {
        set elemid [$element_node @v]
        set elem [Model::getElement $elemid]
        if {[write::isBooleanTrue [$elem getAttribute "RotationDofs"]]} {set bool true; break}
    }
    
    return $bool
}



Structural::write::Init
