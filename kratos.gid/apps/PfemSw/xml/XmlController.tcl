namespace eval ::PfemSw::xml {
    namespace path ::PfemSw
    Kratos::AddNamespace [namespace current]

    # Namespace variables declaration
    variable dir
}

proc ::PfemSw::xml::Init { } {
    # Namespace variables initialization
    variable dir
    Model::InitVariables dir $::PfemSw::dir

    Model::getConditions CouplingConditions.xml
    Model::getProcesses Processes.xml

    # Model::ForgetSolutionStrategies
    # Model::getSolutionStrategies "../../Fluid/xml/Strategies.xml"
    # Model::getSolutionStrategies "../../Structural/xml/Strategies.xml"
    # Model::ForgetSolutionStrategy Eigen
    # Model::getSolutionStrategies Strategies.xml
    # Model::getConditions Conditions.xml

    # Model::ForgetSolvers
    # Model::getSolvers "../../Common/xml/Solvers.xml"
    # Model::getSolvers "../../Structural/xml/Solvers.xml"
    # Model::getSolvers Coupling_solvers.xml
}

proc ::PfemSw::xml::getUniqueName {name} {
    return [::PfemSw::GetAttribute prefix]${name}
}

proc ::PfemSw::xml::MultiAppEvent {args} {
   if {$args eq "init"} {
        catch {::Structural::xml::MultiAppEvent init}
   }
}


proc ::PfemSw::xml::CustomTree { args } {
    PfemSw::write::UpdateUniqueNames PfemFluid
    apps::setActiveAppSoft PfemFluid
    PfemFluid::xml::CustomTree

    PfemSw::write::UpdateUniqueNames SW
    apps::setActiveAppSoft ShallowWater
    ShallowWater::xml::CustomTree

    PfemSw::write::UpdateUniqueNames PfemSw
    apps::setActiveAppSoft PfemSw


    
    # remove Nodal results from PFEM Fluid Data / Results / Nodal Results
    set pfem_base_root [[customlib::GetBaseRoot] selectNodes "//container\[@n = 'PfemFluid'\]"]
    set pfem_nodal_results_node [$pfem_base_root selectNodes "//container\[@un = 'NodalResults'\]"]

    set pfem_nodal_results_delete_list [list "InitialWaterLevel" "InitialPerturbation" "Topography" "MOMENTUM" "FREE_SURFACE_ELEVATION" "INLET" "ANGULAR_VELOCITY"]
    foreach name $pfem_nodal_results_delete_list {
        set result_node [$pfem_nodal_results_node selectNodes "./value\[@n = '$name'\]"]
        if {$result_node ne "" } {$result_node setAttribute "state" "hidden"}
        if {$result_node ne "" } {$result_node setAttribute "v" "No"}
    }
}
