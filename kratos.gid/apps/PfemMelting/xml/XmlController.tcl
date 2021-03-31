namespace eval PfemMelting::xml {
    # Namespace variables declaration
    variable dir
}

proc PfemMelting::xml::Init { } {
    # Namespace variables initialization
    variable dir
    Model::InitVariables dir $PfemMelting::dir
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
    return ${::PfemMelting::prefix}${name}
}

proc PfemMelting::xml::CustomTree { args } {
    Buoyancy::xml::CustomTree args

    #gid_groups_conds::addF [spdAux::getRoute BondElem] value [list n TypeOfFailure pn "Type of failure" v No values {Yes,No} icon "black1" help "Displays different numbers for different types of failure. 2: tension. 4: shear or combination of stresses. 6: neighbour not found by search. 8: less bonds than minimum"]
    #spdAux::SetValueOnTreeItem state {[getStateFromXPathValue {string(../value[@n='ContactMeshOption']/@v)} Yes]} BondElem TypeOfFailure

    

    # Remove / hide Fluid conditions
    spdAux::SetValueOnTreeItem state hidden FLBC AutomaticInlet3D
    spdAux::SetValueOnTreeItem state hidden FLBC Outlet3D
    spdAux::SetValueOnTreeItem state hidden FLBC Slip3D
    spdAux::SetValueOnTreeItem state hidden FLBC VelocityConstraints3D
    spdAux::SetValueOnTreeItem pn "Fixed velocity boundary" FLBC NoSlip3D
}



proc PfemMelting::xml::MultiAppEvent {args} {
    if {$args eq "init"} {
        spdAux::parseRoutes
        spdAux::ConvertAllUniqueNames Buoyancy ${::PfemMelting::prefix}
    }
}

PfemMelting::xml::Init
