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

    # Modify the schemes so more elements are filtered
    foreach strategy $::Model::SolutionStrategies {
        $strategy setAttribute NeedElements false
        foreach scheme [$strategy getSchemes] {
            $scheme addElementFilter ImplementedInApplication ParticleMechanicsApplication
        }
    }

    # Add some parameters
    set implicit_solution_strategy [Model::GetSolutionStrategy implicit]
    # Geometry type
    set geometry_input [::Model::Parameter new "geometry_element" "Geometry element" "combo" "Triangle" "" "" "help" "Triangle,Quadrilateral" "Triangle,Quadrilateral"]
    $implicit_solution_strategy addInputDone $geometry_input
    # Number of particles per element for triangles
    set input [::Model::Parameter new "particle_per_element_triangle" "Particles per element" "combo" "3" "" "" "help" "1,3,6,12" "1,3,6,12"]
    $implicit_solution_strategy addInputDone $input
    $implicit_solution_strategy addInputDependency "particle_per_element_triangle" "geometry_element" "Triangle"
    # Quadrilateral
    set input [::Model::Parameter new "particle_per_element_quadrilateral" "Particles per element" "combo" "4" "" "" "help" "1,4,9,16" "1,4,9,16"]
    $implicit_solution_strategy addInputDone $input
    $implicit_solution_strategy addInputDependency "particle_per_element_quadrilateral" "geometry_element" "Quadrilateral"

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
