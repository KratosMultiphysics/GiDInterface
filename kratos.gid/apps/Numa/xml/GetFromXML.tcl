namespace eval Numa::xml {
    variable dir
}

proc Numa::xml::Init { } {
    variable dir
    Model::InitVariables dir $Numa::dir
    
    Model::getSolutionStrategies Strategies.xml
    #Model::getElements Elements.xml
    Model::getMaterials Materials.xml
    Model::getNodalConditions NodalConditions.xml
    #Model::getConstitutiveLaws ConstitutiveLaws.xml
    Model::getProcesses Processes.xml
    Model::getConditions Conditions.xml
    Model::getSolvers "../../Common/xml/Solvers.xml"
}

proc Numa::xml::getUniqueName {name} {
    return Numa$name
}

proc ::Numa::xml::MultiAppEvent {args} {
    if {$args eq "init"} {
        spdAux::parseRoutes
        spdAux::ConvertAllUniqueNames SL Numa
    }
}

Numa::xml::Init
