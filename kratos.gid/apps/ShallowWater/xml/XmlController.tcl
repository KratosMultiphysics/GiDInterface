namespace eval ::Shallow::xml {
    namespace path ::Shallow
    Kratos::AddNamespace [namespace current]
}

proc ::Shallow::xml::Init {} {
    Model::InitVariables dir $::Shallow::dir

    Model::getElements "../../Common/xml/Elements.xml"
    Model::getConditions Conditions.xml
    Model::getNodalConditions NodalConditions.xml
    Model::getProcesses "../../Common/xml/Processes.xml"
    Model::getProcesses Processes.xml
    Model::getSolvers "../../Common/xml/Solvers.xml"
}

proc ::Shallow::xml::getUniqueName {name} {
    return [::Shallow::GetAttribute prefix]${name}
}

# proc ::Shallow::xml::CustomTree {args} {
    # spdAux::SetValueOnTreeItem state normal FLGravity
    # spdAux::SetValueOnTreeItem state normal FLTimeParameters
# }
