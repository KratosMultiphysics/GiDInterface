namespace eval ShallowWater::xml {
    # Namespace variables declaration
    variable dir
    variable lastImportMeshSize
    variable export_dir
}

proc ShallowWater::xml::Init { } {
    # Namespace variables inicialization
    variable dir
    Model::DestroyEverything
    Model::InitVariables dir $ShallowWater::dir

    Model::getSolutionStrategies Strategies.xml
    Model::getElements "../../Common/xml/Elements.xml"
    Model::getConditions Conditions.xml
    Model::getNodalConditions NodalConditions.xml
    Model::getProcesses "../../Common/xml/Processes.xml"
    Model::getProcesses Processes.xml
    Model::getSolvers "../../Common/xml/Solvers.xml"
}

# proc ShallowWater::xml::MultiAppEvent {args} {
#    if {$args eq "init"} {
#      spdAux::parseRoutes
#      spdAux::ConvertAllUniqueNames FL ${::ShallowWater::prefix}
#    }
# }

proc ShallowWater::xml::getUniqueName {name} {
    return ${::ShallowWater::prefix}${name}
}

# proc ShallowWater::xml::CustomTree { args } {
    # spdAux::SetValueOnTreeItem state normal FLGravity
    # spdAux::SetValueOnTreeItem state normal FLTimeParameters
# }

ShallowWater::xml::Init
