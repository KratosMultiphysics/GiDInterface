namespace eval ::ShallowWater::xml {
    namespace path ::ShallowWater
    Kratos::AddNamespace [namespace current]
}

proc ::ShallowWater::xml::Init {} {
    Model::InitVariables dir $::ShallowWater::dir

    Model::getElements "../../Common/xml/Elements.xml"
    Model::getConditions Conditions.xml
    Model::getMaterials Materials.xml
    Model::getNodalConditions NodalConditions.xml
    Model::getProcesses "../../Common/xml/Processes.xml"
    Model::getProcesses Processes.xml
    Model::getSolvers "../../Common/xml/Solvers.xml"
}

proc ::ShallowWater::xml::getUniqueName {name} {
    return [GetAttribute prefix]${name}
}

proc ::ShallowWater::xml::CustomTree {args} {
    # Set the nodal conditions active
    gid_groups_conds::setAttributes "[spdAux::getRoute [GetUniqueName topography_data]]/condition" [list state normal]
    gid_groups_conds::setAttributes "[spdAux::getRoute [GetUniqueName initial_conditions]]/condition" [list state normal]

    # Register the outputs from topography data
    gid_groups_conds::setAttributes "[spdAux::getRoute NodalResults]/value\[@n = 'MOMENTUM'\]" [list state normal]
    gid_groups_conds::setAttributes "[spdAux::getRoute NodalResults]/value\[@n = 'VELOCITY'\]" [list state normal]
    gid_groups_conds::setAttributes "[spdAux::getRoute NodalResults]/value\[@n = 'HEIGHT'\]" [list state normal]
    gid_groups_conds::setAttributes "[spdAux::getRoute NodalResults]/value\[@n = 'TOPOGRAPHY'\]" [list state normal]
    gid_groups_conds::setAttributes "[spdAux::getRoute NodalResults]/value\[@n = 'FREE_SURFACE_ELEVATION'\]" [list state normal]
}
