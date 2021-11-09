namespace eval PfemMelting::xml {
    namespace path ::PfemMelting
    Kratos::AddNamespace [namespace current]
    # Namespace variables declaration
}

proc PfemMelting::xml::Init { } {
    # Namespace variables initialization
    Model::InitVariables dir $::PfemMelting::dir

    Model::getSolutionStrategies "../../Fluid/xml/Strategies.xml"
    Model::getElements Elements.xml
    Model::getConditions Conditions.xml
    Model::getConstitutiveLaws ConstitutiveLaws.xml
    Model::getMaterials Materials.xml
    Model::getProcesses "../../Common/xml/Processes.xml"
    # Model::getProcesses Processes.xml

    Model::getSolvers "../../Common/xml/Solvers.xml"
}

proc PfemMelting::xml::getUniqueName {name} {
    return [::PfemMelting::GetAttribute prefix]${name}
}

proc PfemMelting::xml::CustomTree { args } {
    set xp1 "[spdAux::getRoute [GetUniqueName conditions]]/condition\[@n='VelocityConstraints3D'\]/value\[@n = 'Interval'\]"
    spdAux::SetFieldOnPath $xp1 v Total
    spdAux::SetFieldOnPath $xp1 values Total
    # spdAux::SetFieldOnPath $xp1 state hidden

    spdAux::SetValueOnTreeItem v MultipleFiles GiDOptions GiDMultiFileFlag
    spdAux::SetValueOnTreeItem state disabled GiDOptions GiDMultiFileFlag

}

proc PfemMelting::xml::ProcAfterApplyParts { domNode } {
    # Fluid::xml::ProcAfterApplyParts $domNode
}
proc PfemMelting::xml::MultiAppEvent {args} {
    if {$args eq "init"} {
        spdAux::parseRoutes
        spdAux::ConvertAllUniqueNames FL [::PfemMelting::GetAttribute prefix]
    }
}
