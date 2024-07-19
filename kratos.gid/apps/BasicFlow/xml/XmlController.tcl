namespace eval ::BasicFlow::xml {
    namespace path ::BasicFlow
    Kratos::AddNamespace [namespace current]
    # Namespace variables declaration
    variable dir
}

proc ::BasicFlow::xml::Init { } {
    # Namespace variables inicialization
    Model::InitVariables dir $::BasicFlow::dir

    Model::getProcesses "../../Common/xml/Processes.xml"
    Model::getElements "../../Fluid/xml/Elements.xml"
    foreach element [Model::GetElements] {
        if {[$element getName] ne "FractionalStep2D" && [$element getName] ne "FractionalStep3D"} {
            Model::ForgetElement [$element getName]
        }
    }
    Model::getProcesses "../../Fluid/xml/Processes.xml"
    Model::getConditions "../../Fluid/xml/Conditions.xml"
}

proc ::BasicFlow::xml::getUniqueName {name} {
    return [::BasicFlow::GetAttribute prefix]${name}
}

proc ::BasicFlow::xml::CustomTree { args } {
    set root [customlib::GetBaseRoot]

    # Rename inlet condition
    spdAux::SetValueOnTreeItem pn Inlet BFLBC AutomaticInlet2D
    spdAux::SetValueOnTreeItem pn Inlet BFLBC AutomaticInlet3D
    spdAux::SetValueOnTreeItem pn Outlet BFLBC Outlet2D
    spdAux::SetValueOnTreeItem pn Outlet BFLBC Outlet3D

    # Hide the rest of conditions
    spdAux::SetValueOnTreeItem state hidden BFLBC WallLaw2D
    spdAux::SetValueOnTreeItem state hidden BFLBC WallLaw3D
    spdAux::SetValueOnTreeItem state hidden BFLBC VelocityConstraints2D
    spdAux::SetValueOnTreeItem state hidden BFLBC VelocityConstraints3D
    spdAux::SetValueOnTreeItem state hidden BFLBC PressureConstraints2D
    spdAux::SetValueOnTreeItem state hidden BFLBC PressureConstraints3D

    
}
