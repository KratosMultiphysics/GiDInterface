namespace eval ::CompressibleFluid::examples::Wedge {
    namespace path ::CompressibleFluid::examples
    Kratos::AddNamespace [namespace current]
}

proc ::CompressibleFluid::examples::Wedge::Init {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }

    Kratos::ResetModel
    DrawGeometry$::Model::SpatialDimension
    AssignGroups$::Model::SpatialDimension
    AssignMeshSizes$::Model::SpatialDimension
    TreeAssignation$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}


# Draw Geometry
proc ::CompressibleFluid::examples::Wedge::DrawGeometry3D {args} {
    # To be implemented
}

proc ::CompressibleFluid::examples::Wedge::DrawGeometry2D {args} {
    GiD_Layers create Fluid
    GiD_Layers edit to_use Fluid

    # Geometry creation
    ## Points ##
    set coordinates [list {0 0 0} {5.54679 0 0} {11.58963 2.39008 0} {11.58963 7.77903 0} {0 7.77903 0}]
    foreach point $coordinates {
        lassign $point x y z
        GiD_Geometry create point append Fluid $x $y $z
    }

    ## Lines ##
    GiD_Geometry create line append stline Fluid 1 2
    GiD_Geometry create line append stline Fluid 2 3
    GiD_Geometry create line append stline Fluid 3 4
    GiD_Geometry create line append stline Fluid 4 5
    GiD_Geometry create line append stline Fluid 5 1

    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface 1 2 3 4 5 escape escape
}


# Group assign
proc ::CompressibleFluid::examples::Wedge::AssignGroups2D {args} {
    # Create the groups
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid surfaces 1

    GiD_Groups create Left
    GiD_Groups edit color Left "#e0210fff"
    GiD_EntitiesGroups assign Left lines 5

    GiD_Groups create Right
    GiD_Groups edit color Right "#42eb71ff"
    GiD_EntitiesGroups assign Right lines 3

    GiD_Groups create Top
    GiD_Groups edit color Top "#3b3b3bff"
    GiD_EntitiesGroups assign Top lines 4

    GiD_Groups create Bottom
    GiD_Groups edit color Bottom "#3b3b3bff"
    GiD_EntitiesGroups assign Bottom lines {1 2}

}
proc ::CompressibleFluid::examples::Wedge::AssignGroups3D {args} {
    # To be implemented
}


# Mesh sizes
proc ::CompressibleFluid::examples::Wedge::AssignMeshSizes3D {args} {
    # To be implemented
}

proc ::CompressibleFluid::examples::Wedge::AssignMeshSizes2D {args} {
    # set fluid_mesh_size 0.01
    # set walls_mesh_size 0.01
    # GiD_Process Mescape Meshing AssignSizes Lines $walls_mesh_size {*}[GiD_EntitiesGroups get Left lines] escape escape
    # GiD_Process Mescape Meshing AssignSizes Lines $walls_mesh_size {*}[GiD_EntitiesGroups get Right lines] escape escape
    # GiD_Process Mescape Meshing AssignSizes Lines $walls_mesh_size {*}[GiD_EntitiesGroups get Top lines] escape escape
    # GiD_Process Mescape Meshing AssignSizes Lines $walls_mesh_size {*}[GiD_EntitiesGroups get Bottom lines] escape escape
    # GiD_Process Mescape Meshing AssignSizes Surfaces $fluid_mesh_size [GiD_EntitiesGroups get Fluid surfaces] escape escape
    # Kratos::Event_BeforeMeshGeneration $fluid_mesh_size
}


# Tree assign
proc ::CompressibleFluid::examples::Wedge::TreeAssignation3D {args} {
    # To be implemented
}

proc ::CompressibleFluid::examples::Wedge::TreeAssignation2D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype line
    if {$nd eq "3D"} { set condtype surface }

    # Monolithic solution strategy set
    # spdAux::SetValueOnTreeItem v "Monolithic" FLSolStrat

    # Fluid Parts
    set fluidParts [spdAux::getRoute "FLParts"]
    set fluidNode [customlib::AddConditionGroupOnXPath $fluidParts Fluid]
    set props [list ConstitutiveLaw Newtonian DENSITY 1.225 DYNAMIC_VISCOSITY 0.0000178 CONDUCTIVITY 0.001 SPECIFIC_HEAT 717.25 HEAT_CAPACITY_RATIO 1.4]
    spdAux::SetValuesOnBaseNode $fluidNode $props

    set initial_conditions [spdAux::getRoute "FLNodalConditions"]
    # Fluid density
    set fluid_density "$initial_conditions/condition\[@n='DENSITY'\]"
    set initial_density_node [customlib::AddConditionGroupOnXPath $fluid_density Fluid]
    $initial_density_node setAttribute ov surface
    set props [list ByFunction No value 1.225]
    spdAux::SetValuesOnBaseNode $initial_density_node $props

    set fluid_energy "$initial_conditions/condition\[@n='TOTAL_ENERGY'\]"
    set initial_energy_node [customlib::AddConditionGroupOnXPath $fluid_energy Fluid]
    $initial_energy_node setAttribute ov surface
    set props [list ByFunction No value 8.9119e5]
    spdAux::SetValuesOnBaseNode $initial_energy_node $props

    set momentum "$initial_conditions/condition\[@n='MOMENTUM'\]"
    set initial_momentum_node [customlib::AddConditionGroupOnXPath $momentum Fluid]
    $initial_momentum_node setAttribute ov surface
    set props [list value_component_X 1262 value_component_Y 0.0]
    spdAux::SetValuesOnBaseNode $initial_momentum_node $props

    set fluidConditions [spdAux::getRoute "FLBC"]

    # Fluid Conditions
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='Slip$nd'\]" Bottom] setAttribute ov $condtype

    set momentum "$fluidConditions/condition\[@n='MomentumConstraints$nd'\]"
    set density "$fluidConditions/condition\[@n='DensityBC$nd'\]"
    set energy "$fluidConditions/condition\[@n='EnergyBC$nd'\]"
    foreach gr [list Left] {
        GiD_Groups create "$gr//Total"
        GiD_Groups edit state "$gr//Total" hidden
        spdAux::AddIntervalGroup $gr "$gr//Total"

        set momentum [customlib::AddConditionGroupOnXPath $momentum "$gr//Total"]
        $momentum setAttribute ov line
        set props [list value_component_X 1262 value_component_Y 0.0]
        spdAux::SetValuesOnBaseNode $momentum $props

        set density [customlib::AddConditionGroupOnXPath $density "$gr//Total"]
        $density setAttribute ov line
        set props [list ByFunction No value 1.225 Interval Total]
        spdAux::SetValuesOnBaseNode $density $props

        set energy [customlib::AddConditionGroupOnXPath $energy "$gr//Total"]
        $energy setAttribute ov line
        set props [list ByFunction No value 8.9119e5 Interval Total]
        spdAux::SetValuesOnBaseNode $energy $props

    }

    # Time parameters
    set parameters [list CFLNumber 0.7 EndTime 0.025 AutomaticDeltaTime Yes MinimumDeltaTime 1.0e-8]
    set xpath [spdAux::getRoute "FLTimeParameters"]
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Output
    set parameters [list OutputControlType time OutputDeltaTime 0.001]
    set xpath "[spdAux::getRoute FLResults]/container\[@n='GiDOutput'\]/container\[@n='GiDOptions'\]"
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Parallelism
    set parameters [list ParallelSolutionType OpenMP OpenMPNumberOfThreads 4]
    set xpath [spdAux::getRoute "Parallelization"]
    spdAux::SetValuesOnBasePath $xpath $parameters

    spdAux::RequestRefresh
}
