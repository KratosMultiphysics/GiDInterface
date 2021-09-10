namespace eval ::PotentialFluid::xml {
    namespace path ::PotentialFluid
    Kratos::AddNamespace [namespace current]
    
    # Namespace variables declaration
    variable lastImportMeshSize
    variable export_dir

}

proc PotentialFluid::xml::Init { } {
    # Namespace variables inicialization
    Model::DestroyEverything
    Model::InitVariables dir [apps::getMyDir "PotentialFluid"]

    Model::getSolutionStrategies Strategies.xml
    Model::getElements Elements.xml
    Model::getMaterials Materials.xml
    Model::getNodalConditions NodalConditions.xml
    Model::getConstitutiveLaws ConstitutiveLaws.xml
    Model::getProcesses "../../Common/xml/Processes.xml"
    Model::getProcesses "../../Fluid/xml/Processes.xml"
    Model::getProcesses Processes.xml
    Model::getConditions Conditions.xml
    Model::getSolvers "../../Common/xml/Solvers.xml"
}


proc PotentialFluid::xml::MultiAppEvent {args} {
   if {$args eq "init"} {
     spdAux::parseRoutes
     spdAux::ConvertAllUniqueNames [::Fluid::GetAttribute prefix] [::PotentialFluid::GetAttribute prefix]
   }
}

proc PotentialFluid::xml::getUniqueName {name} {
    return [::PotentialFluid::GetAttribute prefix]${name}
}

proc PotentialFluid::xml::CustomTree { args } {
    # Hide Results Cut planes
    #Fluid::xml::CustomTree {*}$args
    
    spdAux::SetValueOnTreeItem state hidden PTFLGravity
    spdAux::SetValueOnTreeItem state hidden PTFLTimeParameters
    
}

proc spdAux::injectConditions { basenode args} {
    set conditions [::Model::GetConditions [list ImplementedInApplication {FluidApplication CompressiblePotentialFlowApplication}]]
    spdAux::_injectCondsToTree $basenode $conditions
    $basenode delete
}

