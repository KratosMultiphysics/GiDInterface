namespace eval MPM::xml {
    namespace path ::MPM
    Kratos::AddNamespace [namespace current]

}

proc MPM::xml::Init { } {
    # Namespace variables inicialization
    Model::InitVariables dir $::MPM::dir

    # Import our elements
    Model::ForgetElements
    Model::getElements Elements.xml

    Model::ForgetSolutionStrategies
    Model::getSolutionStrategies Strategies.xml

    # Modify the schemes so more elements are filtered
    foreach strategy $::Model::SolutionStrategies {
        $strategy setAttribute NeedElements false
        foreach scheme [$strategy getSchemes] {
            $scheme addElementFilter ImplementedInApplication ParticleMechanicsApplication
        }
    }

    # Add some parameters
    set implicit_solution_strategy [Model::GetSolutionStrategy implicit]

    # Import our Constitutive Laws
    Model::ForgetConstitutiveLaws
    Model::getConstitutiveLaws ConstitutiveLaws.xml


    # Import our Materials
    Model::ForgetMaterials
    Model::getMaterials Materials.xml

    # Import our Nodal conditions
    Model::getProcesses Processes.xml
    Model::ForgetNodalConditions
    Model::getNodalConditions NodalConditions.xml

    # Import our conditions
    Model::ForgetConditions
    Model::getConditions Conditions.xml

}


proc MPM::xml::MultiAppEvent {args} {
   if {$args eq "init"} {
     spdAux::parseRoutes
     spdAux::ConvertAllUniqueNames ST MPM
   }
}

proc MPM::xml::getUniqueName {name} {
    return MPM${name}
}

proc MPM::xml::CustomTree { args } {

#     spdAux::SetValueOnTreeItem v "time" Results OutputControlType
#     spdAux::SetValueOnTreeItem values "time" Results OutputControlType
    spdAux::SetValueOnTreeItem v No NodalResults PARTITION_INDEX
    spdAux::SetValueOnTreeItem v "LinearSolversApplication.sparse_lu" MPMimplicitlinear_solver_settings Solver
}


proc MPM::xml::ProcCheckGeometry {domNode args} {
    set ret "surface"
    if {$::Model::SpatialDimension eq "3D"} {
        set ret "volume"
    }
    return $ret
}

proc MPM::xml::ProcCheckActivateStabilizationState {domNode args} {
    set ret "hidden"
    set up_mixed UpdatedLagrangianUP$::Model::SpatialDimension
    set used_elements [::MPM::write::GetUsedElements Name]
    if {$up_mixed in $used_elements} {
        set ret "normal"
    }
    return $ret
}

proc MPM::xml::ProcCheckStabilizationState {domNode args} {
    set ret "hidden"
    set first_check [MPM::xml::ProcCheckActivateStabilizationState domNode args]
    if {$first_check eq "normal"} {
        set second_check [write::getValueByNode [$domNode selectNodes "..//value\[@n='ActivateStabilization']"] ]
        if {$second_check eq "On"} {set ret "normal"}
    }
    return $ret
}
