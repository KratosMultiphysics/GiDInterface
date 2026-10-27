namespace eval ::FluidBiomedical::xml {
    namespace path ::FluidBiomedical
    Kratos::AddNamespace [namespace current]
    # Namespace variables declaration
    variable dir
}

proc ::FluidBiomedical::xml::Init { } {
    # Namespace variables initialization
    variable dir
    Model::InitVariables dir $::FluidBiomedical::dir

    Model::ForgetCondition AutomaticInlet3D
    Model::ForgetCondition Outlet3D
    Model::getConditions Conditions.xml
    Model::getProcesses Processes.xml

}

proc ::FluidBiomedical::xml::getUniqueName {name} {
    return [::FluidBiomedical::GetAttribute prefix]${name}
}

proc ::FluidBiomedical::xml::CustomTree { args } {
    spdAux::parseRoutes

    apps::setActiveAppSoft Fluid
    Fluid::xml::CustomTree

    apps::setActiveAppSoft FluidBiomedical

}

proc ::FluidBiomedical::xml::UpdateParts {domNode args} {
    set childs [$domNode getElementsByTagName group]
    if {[llength $childs] > 1} {
        foreach group [lrange $childs 1 end] {$group delete}
        gid_groups_conds::actualize_conditions_window
        error "You can only set one part"
    }
}
