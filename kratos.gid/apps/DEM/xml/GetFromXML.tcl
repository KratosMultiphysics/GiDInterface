namespace eval DEM::xml {
    variable dir
}

proc DEM::xml::Init { } {
    variable dir
    Model::InitVariables dir $DEM::dir

    Model::getSolutionStrategies Strategies.xml
    Model::getElements Elements.xml
    Model::getConstitutiveLaws ConstitutiveLaws.xml
    Model::getMaterials Materials.xml
    # Model::getNodalConditions NodalConditions.xml
    # Model::getProcesses Processes.xml
    # Model::getConditions Conditions.xml
}

proc DEM::xml::getUniqueName {name} {
    return DEM$name
}

proc DEM::xml::MultiAppEvent {args} {

}

proc DEM::xml::CustomTree { args } {
    
}


DEM::xml::Init
