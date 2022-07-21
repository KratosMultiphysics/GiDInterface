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

    Model::getNodalConditions NodalConditions.xml


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

    # Add displacement
    foreach element [Model::GetElements [list ElementType Fluid]] {
        $element addNodalCondition DISPLACEMENT
    }

}
