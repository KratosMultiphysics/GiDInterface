namespace eval ::FSI::xml {
    namespace path ::FSI
    # Namespace variables declaration
    variable dir
}

proc ::FSI::xml::Init { } {
    # Namespace variables initialization
    variable dir
    Model::InitVariables dir $::FSI::dir

    Model::ForgetSolutionStrategies
    Model::getSolutionStrategies "../../Fluid/xml/Strategies.xml"
    Model::getSolutionStrategies "../../Structural/xml/Strategies.xml"
    #Model::ForgetSolutionStrategy Eigen
    Model::getSolutionStrategies Strategies.xml
    Model::getConditions Conditions.xml

    Model::ForgetSolvers
    Model::getSolvers "../../Common/xml/Solvers.xml"
    Model::getSolvers "../../Structural/xml/Solvers.xml"
    Model::getSolvers Coupling_solvers.xml
}

proc ::FSI::xml::getUniqueName {name} {
    return [::FSI::GetAttribute prefix]${name}
}

proc ::FSI::xml::MultiAppEvent {args} {
   if {$args eq "init"} {
        catch {::Structural::xml::MultiAppEvent init}
   }
}


proc ::FSI::xml::CustomTree { args } {
    FSI::write::UpdateUniqueNames Fluid
    apps::setActiveAppSoft Fluid
    Fluid::xml::CustomTree

    FSI::write::UpdateUniqueNames Structural
    apps::setActiveAppSoft Structural
    Structural::xml::CustomTree

    FSI::write::UpdateUniqueNames FSI
    apps::setActiveAppSoft FSI

    # Modify the tree: field newValue UniqueName OptionalChild
    spdAux::SetValueOnTreeItem v "Monolithic" FLSolStrat
    spdAux::SetValueOnTreeItem v "Yes" FLStratParams compute_reactions

    # Remove Eigen
    #spdAux::SetValueOnTreeItem values "Static,Quasi-static,Dynamic,formfinding" STSoluType

    # Disable MPI parallelism until it is fully tested
    #spdAux::SetValueOnTreeItem values "OpenMP" ParallelType

    # Mesh movement results in fluid output settings
    set root [customlib::GetBaseRoot]
    if {[$root selectNodes "[spdAux::getRoute FLResults]/container\[@n='OnNodes'\]"] ne ""} {
        gid_groups_conds::addF "[spdAux::getRoute FLResults]/container\[@n='OnNodes'\]" value [list n MESH_DISPLACEMENT pn "Mesh displacement" v Yes values "Yes,No"]
        gid_groups_conds::addF "[spdAux::getRoute FLResults]/container\[@n='OnNodes'\]" value [list n MESH_VELOCITY pn "Mesh velocity" v No values "Yes,No"]
    }
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
