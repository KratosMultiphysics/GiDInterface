namespace eval Chimera::xml {
    # Namespace variables declaration
    variable dir
    variable lastImportMeshSize
    variable export_dir

}

proc Chimera::xml::Init { } {
    # Namespace variables inicialization
    variable dir
    variable lastImportMeshSize
    set lastImportMeshSize 0
    Model::DestroyEverything
    Model::InitVariables dir $Chimera::dir

    Model::getSolutionStrategies Strategies.xml
    Model::getElements "../../Fluid/xml/Elements.xml"
    Model::getMaterials Materials.xml
    Model::getNodalConditions "../../Fluid/xml/NodalConditions.xml"
    Model::getConstitutiveLaws "../../Fluid/xml/ConstitutiveLaws.xml"
    Model::getProcesses "../../Common/xml/Processes.xml"
    Model::getProcesses "../../Fluid/xml/Processes.xml"
    Model::getConditions "../../Fluid/xml/Conditions.xml"
    Model::getSolvers "../../Common/xml/Solvers.xml"
}


proc Chimera::xml::MultiAppEvent {args} {
    if {$args eq "init"} {
        spdAux::parseRoutes
        spdAux::ConvertAllUniqueNames FL ${::Chimera::prefix}
    }
}

proc Chimera::xml::getUniqueName {name} {
    return ${::Chimera::prefix}${name}
}

proc Chimera::xml::CustomTree { args } {

}

Chimera::xml::Init
