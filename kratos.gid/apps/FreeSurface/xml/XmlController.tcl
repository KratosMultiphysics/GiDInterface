namespace eval ::FreeSurface::xml {
    namespace path ::FreeSurface
    Kratos::AddNamespace [namespace current]
    # Namespace variables declaration
    variable dir
}

proc ::FreeSurface::xml::Init { } {
    # Namespace variables initialization
    variable dir
    Model::InitVariables dir $::FreeSurface::dir


    Model::ForgetSolutionStrategies
    Model::getSolutionStrategies Strategies.xml
    Model::ForgetElements
    Model::getElements Elements.xml

    Model::getNodalConditions NodalConditions.xml
    Model::getConditions Conditions.xml


    # Remove No splip
    Model::ForgetCondition NoSlip2D
    Model::ForgetCondition NoSlip3D
}

proc ::FreeSurface::xml::getUniqueName {name} {
    return [::FreeSurface::GetAttribute prefix]${name}
}

proc ::FreeSurface::xml::CustomTree { args } {
    spdAux::parseRoutes

    apps::setActiveAppSoft Fluid
    Fluid::xml::CustomTree

    apps::setActiveAppSoft FreeSurface

}

proc ::FreeSurface::xml::UpdateParts {domNode args} {
    set childs [$domNode getElementsByTagName group]
    if {[llength $childs] > 1} {
        foreach group [lrange $childs 1 end] {$group delete}
        gid_groups_conds::actualize_conditions_window
        error "You can only set one part"
    }
}
