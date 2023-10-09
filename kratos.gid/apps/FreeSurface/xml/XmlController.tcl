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


    # Remove No slip
    Model::ForgetCondition NoSlip2D
    Model::ForgetCondition NoSlip3D
    # Remove Wall Law
    Model::ForgetCondition WallLaw2D
    Model::ForgetCondition WallLaw3D
}

proc ::FreeSurface::xml::getUniqueName {name} {
    return [::FreeSurface::GetAttribute prefix]${name}
}

proc ::FreeSurface::xml::CustomTree { args } {
    spdAux::parseRoutes

    apps::setActiveAppSoft Fluid
    Fluid::xml::CustomTree

    apps::setActiveAppSoft FreeSurface

    spdAux::SetValueOnTreeItem v 9.8 FLGravity GravityValue

    set root [customlib::GetBaseRoot]
    foreach {n pn} [list LIN_DARCY_COEF "Linear darcy coefficient" NONLIN_DARCY_COEF "Nonlinear darcy coefficient" POROSITY "Porosity"] {
        if {[$root selectNodes "[spdAux::getRoute NodalResults]/value\[@n='$n'\]"] eq ""} {
            gid_groups_conds::addF [spdAux::getRoute NodalResults] value [list n $n pn $pn v Yes values "Yes,No"]
        }
    }

}

proc ::FreeSurface::xml::UpdateParts {domNode args} {
    set childs [$domNode getElementsByTagName group]
    if {[llength $childs] > 1} {
        foreach group [lrange $childs 1 end] {$group delete}
        gid_groups_conds::actualize_conditions_window
        error "You can only set one part"
    }
}
