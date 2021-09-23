namespace eval ::ShallowWater::xml {
    namespace path ::ShallowWater
    Kratos::AddNamespace [namespace current]
}

proc ::ShallowWater::xml::Init {} {
    Model::InitVariables dir $::ShallowWater::dir

    Model::getElements "../../Common/xml/Elements.xml"
    Model::getConditions Conditions.xml
    Model::getNodalConditions NodalConditions.xml
    Model::getProcesses "../../Common/xml/Processes.xml"
    Model::getProcesses Processes.xml
    Model::getSolvers "../../Common/xml/Solvers.xml"
}

proc ::ShallowWater::xml::getUniqueName {name} {
    return [::ShallowWater::GetAttribute prefix]${name}
}

# proc ::ShallowWater::xml::CustomTree {args} {
    # spdAux::SetValueOnTreeItem state normal FLGravity
    # spdAux::SetValueOnTreeItem state normal FLTimeParameters
# }
