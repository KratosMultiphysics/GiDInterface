namespace eval MPM::xml {
    # Namespace variables declaration
    variable dir

}

proc MPM::xml::Init { } {
    # Namespace variables inicialization
    variable dir
    Model::InitVariables dir $MPM::dir

    # Import our elements
    Model::ForgetElements
    Model::getElements Elements.xml
    
    foreach strategy $::Model::SolutionStrategies {
        $strategy setAttribute NeedElements false
        foreach scheme [$strategy getSchemes] {
            $scheme addElementFilter ImplementedInApplication ParticleMechanicsApplication
        }
    }
    #W [::Model::GetSchemes]

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

    
}


proc MPM::xml::MultiAppEvent {args} {
   if {$args eq "init"} {
     spdAux::parseRoutes
     spdAux::ConvertAllUniqueNames ST ${::MPM::prefix}
   }
}

proc MPM::xml::getUniqueName {name} {
    return ${::MPM::prefix}${name}
}

proc MPM::xml::CustomTree { args } {

    spdAux::SetValueOnTreeItem v "time" Results OutputControlType
    spdAux::SetValueOnTreeItem values "time" Results OutputControlType
    spdAux::SetValueOnTreeItem v No NodalResults PARTITION_INDEX
    spdAux::SetValueOnTreeItem v SuperLUSolver MPMimplicitlinear_solver_settings Solver
}


proc MPM::xml::ProcCheckGeometry {domNode args} {
    set ret "surface"
    if {$::Model::SpatialDimension eq "3D"} {
        set ret "volume"
    }
    return $ret
}

MPM::xml::Init
