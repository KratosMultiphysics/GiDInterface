namespace eval PfemMelting::xml {
    namespace path ::PfemMelting
    Kratos::AddNamespace [namespace current]
    # Namespace variables declaration
}

proc PfemMelting::xml::Init { } {
    # Namespace variables initialization
    Model::InitVariables dir $::PfemMelting::dir
    #Model::ForgetElements
    # Model::getElements ElementsC.xml
    #Model::ForgetConditions
    # Model::getConditions Conditions.xml
    Model::ForgetConstitutiveLaws
    Model::getConstitutiveLaws ConstitutiveLaws.xml
    Model::ForgetMaterials
    Model::getMaterials Materials.xml
    Model::getProcesses "../../Common/xml/Processes.xml"
    Model::getProcesses Processes.xml
}

proc PfemMelting::xml::getUniqueName {name} {
    return [::PfemMelting::GetAttribute prefix]${name}
}

proc PfemMelting::xml::CustomTree { args } {
    Buoyancy::xml::CustomTree args

    # Remove / hide Fluid conditions
    spdAux::SetValueOnTreeItem state hidden FLBC AutomaticInlet3D
    spdAux::SetValueOnTreeItem state hidden FLBC Outlet3D
    spdAux::SetValueOnTreeItem state hidden FLBC Slip3D
    spdAux::SetValueOnTreeItem state hidden FLBC VelocityConstraints3D
    spdAux::SetValueOnTreeItem pn "Fixed velocity boundary" FLBC NoSlip3D
    spdAux::SetValueOnTreeItem state hidden CNVDFFBodyForce 
    spdAux::SetValueOnTreeItem pn "Environment settings" PFEMMELTING__Boussinesq  
    

    # Delete this lines when heat conditions are back!
    # spdAux::SetValueOnTreeItem state hidden CNVDFFBC HeatFlux3D
    # spdAux::SetValueOnTreeItem state hidden CNVDFFBC ImposedTemperature3D
    # spdAux::SetValueOnTreeItem state hidden CNVDFFBC ThermalFace3D
}

proc PfemMelting::xml::MultiAppEvent {args} {
    if {$args eq "init"} {
        spdAux::parseRoutes
        spdAux::ConvertAllUniqueNames Buoyancy [::PfemMelting::GetAttribute prefix]
    }
}
