namespace eval ConjugateHeatTransfer::xml {
    # Namespace variables declaration
    variable dir
}

proc ConjugateHeatTransfer::xml::Init { } {
    # Namespace variables initialization
    variable dir
    Model::InitVariables dir $ConjugateHeatTransfer::dir

    #Model::ForgetSolutionStrategies
    #Model::getSolutionStrategies "../../Fluid/xml/Strategies.xml"
    #Model::getSolutionStrategies "../../Structural/xml/Strategies.xml"
    #Model::ForgetSolutionStrategy Eigen
    #Model::getSolutionStrategies Strategies.xml
    #Model::getConditions Conditions.xml

    #Model::getSolvers Coupling_solvers.xml
}

proc ConjugateHeatTransfer::xml::getUniqueName {name} {
    return ${::ConjugateHeatTransfer::prefix}${name}
}

proc ::ConjugateHeatTransfer::xml::MultiAppEvent {args} {
   if {$args eq "init"} {
        #::Structural::xml::MultiAppEvent init
   }
}


proc ConjugateHeatTransfer::xml::CustomTree { args } {
    return
    ConjugateHeatTransfer::write::UpdateUniqueNames Fluid
    apps::setActiveAppSoft Fluid
    Fluid::xml::CustomTree

    ConjugateHeatTransfer::write::UpdateUniqueNames Structural
    apps::setActiveAppSoft Structural
    Structural::xml::CustomTree

    ConjugateHeatTransfer::write::UpdateUniqueNames ConjugateHeatTransfer
    apps::setActiveAppSoft ConjugateHeatTransfer

    # Modify the tree: field newValue UniqueName OptionalChild
    spdAux::SetValueOnTreeItem v "Monolithic" FLSolStrat
    spdAux::SetValueOnTreeItem v "Yes" FLStratParams compute_reactions

    # Remove Eigen
    #spdAux::SetValueOnTreeItem values "Static,Quasi-static,Dynamic,formfinding" STSoluType


    # Disable MPI parallelism until it is fully tested
    #spdAux::SetValueOnTreeItem values "OpenMP" ParallelType
}

# Overwriting some procs
proc spdAux::injectNodalConditionsOutputs {basenode args} {
    set base [$basenode parent]
    set args {*}$args
    if {$args eq ""} {
        set app [apps::getAppById [spdAux::GetAppIdFromNode $base]]
        set args [list ImplementedInApplication [join [$app getKratosApplicationName] ","]]
    }
    return [spdAux::injectNodalConditionsOutputs_do $basenode $args]
}

proc spdAux::injectElementOutputs {basenode args} {
    set base [$basenode parent]
    set args {*}$args
    if {$args eq ""} {
        set app [apps::getAppById [spdAux::GetAppIdFromNode $base]]
        set args [list ImplementedInApplication [join [$app getKratosApplicationName] ","]]
    }
    return [spdAux::injectElementOutputs_do $basenode $args]
}

ConjugateHeatTransfer::xml::Init
