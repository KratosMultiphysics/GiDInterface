namespace eval CDEM::xml {
    # Namespace variables declaration
    variable dir
}

proc CDEM::xml::Init { } {
    # Namespace variables initialization
    variable dir
    Model::InitVariables dir $CDEM::dir
    Model::ForgetElements
    Model::getElements ElementsC.xml
    Model::getConditions Conditions.xml
    Model::getConstitutiveLaws ConstitutiveLawsC.xml
    Model::getMaterialRelations MaterialRelations.xml
    Model::getProcesses "../../Common/xml/Processes.xml"
    Model::getProcesses Processes.xml
}

proc CDEM::xml::getUniqueName {name} {
    return ${::CDEM::prefix}${name}
}

proc CDEM::xml::CustomTree { args } {
    DEM::xml::CustomTree args

    set root [customlib::GetBaseRoot]
    if {[$root selectNodes "[spdAux::getRoute DEMStratSection]/container\[@n='AdvOptions'\]"] eq ""} {
        gid_groups_conds::addF [spdAux::getRoute DEMStratSection] include [list n AdvOptions active 1 path {apps/CDEM/xml/AdvancedSettings.spd}]
    }
    if {[$root selectNodes "[spdAux::getRoute DEMStratSection]/container\[@n='TestMaterial'\]"] eq ""} {
        gid_groups_conds::addF [spdAux::getRoute DEMStratSection] include [list n TestMaterial active 1 path {apps/CDEM/xml/TestMaterial.spd}]
    }

    gid_groups_conds::addF [spdAux::getRoute BondElem] value [list n TypeOfFailure pn "Type of failure" v No values {Yes,No} icon "black1" help "Displays different numbers for different types of failure. 2: tension. 4: shear or combination of stresses. 6: neighbour not found by search. 8: less bonds than minimum"]
    spdAux::SetValueOnTreeItem state {[getStateFromXPathValue {string(../value[@n='ContactMeshOption']/@v)} Yes]} BondElem TypeOfFailure
    
    customlib::ProcessIncludes $::Kratos::kratos_private(Path)
    spdAux::parseRoutes
}

proc CDEM::xml::ProcGetElements { domNode args } {
    set elems [Model::GetElements]
    set names [list ]
    set pnames [list ]
    foreach elem $elems {
        if {[$elem cumple {*}$args]} {
            lappend names [$elem getName]
            lappend pnames [$elem getName]
            lappend pnames [$elem getPublicName]
        }
    }
    set diction [join $pnames ","]
    set values [join $names ","]
    $domNode setAttribute values $values
    if {[get_domnode_attribute $domNode v] eq ""} {$domNode setAttribute v [lindex $names 0]}
    if {[get_domnode_attribute $domNode v] ni $names} {$domNode setAttribute v [lindex $names 0]; spdAux::RequestRefresh}

    return $diction
}

proc CDEM::xml::MultiAppEvent {args} {
    if {$args eq "init"} {
        spdAux::parseRoutes
        spdAux::ConvertAllUniqueNames DEM ${::CDEM::prefix}
    }
}

CDEM::xml::Init
