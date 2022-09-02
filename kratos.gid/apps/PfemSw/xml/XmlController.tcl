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
    apps::setActiveAppSoft SW
    SW::xml::CustomTree

    PfemSw::write::UpdateUniqueNames PfemSw
    apps::setActiveAppSoft PfemSw
}
