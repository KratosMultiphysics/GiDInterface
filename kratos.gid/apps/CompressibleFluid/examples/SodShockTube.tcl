namespace eval ::CompressibleFluid::examples::SodShockTube {
    namespace path ::CompressibleFluid::examples
    Kratos::AddNamespace [namespace current]
}

proc ::CompressibleFluid::examples::SodShockTube::Init {args} {
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
proc ::CompressibleFluid::examples::SodShockTube::DrawGeometry3D {args} {
    # To be implemented
}

proc ::CompressibleFluid::examples::SodShockTube::DrawGeometry2D {args} {
    GiD_Layers create Fluid
    GiD_Layers edit to_use Fluid

    # Geometry creation
    ## Points ##
    set coordinates [list {0 0 0} {1 0 0} {1 0.1 0} {0 0.1 0} ]
    foreach point $coordinates {
        lassign $point x y z
        GiD_Geometry create point append Fluid $x $y $z
    }

    ## Lines ##
    GiD_Geometry create line append stline Fluid 1 2
    GiD_Geometry create line append stline Fluid 2 3
    GiD_Geometry create line append stline Fluid 3 4
    GiD_Geometry create line append stline Fluid 4 1

    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface 1 2 3 4 escape escape
}


# Group assign
proc ::CompressibleFluid::examples::SodShockTube::AssignGroups2D {args} {
    # Create the groups
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid surfaces 1

    GiD_Groups create Left
    GiD_Groups edit color Left "#e0210fff"
    GiD_EntitiesGroups assign Left lines 4

    GiD_Groups create Right
    GiD_Groups edit color Right "#42eb71ff"
    GiD_EntitiesGroups assign Right lines 2

    GiD_Groups create Top
    GiD_Groups edit color Top "#3b3b3bff"
    GiD_EntitiesGroups assign Top lines 3

    GiD_Groups create Bottom
    GiD_Groups edit color Bottom "#3b3b3bff"
    GiD_EntitiesGroups assign Bottom lines 1

}
proc ::CompressibleFluid::examples::SodShockTube::AssignGroups3D {args} {
    # To be implemented
}


# Mesh sizes
proc ::CompressibleFluid::examples::SodShockTube::AssignMeshSizes3D {args} {
    # To be implemented
}

proc ::CompressibleFluid::examples::SodShockTube::AssignMeshSizes2D {args} {
    # set fluid_mesh_size 30.0
    # set walls_mesh_size 30.0
    # set building_mesh_size 3.0
    # GiD_Process Mescape Meshing AssignSizes Lines $walls_mesh_size {*}[GiD_EntitiesGroups get Inlet lines] escape escape
    # GiD_Process Mescape Meshing AssignSizes Lines $walls_mesh_size {*}[GiD_EntitiesGroups get Outlet lines] escape escape
    # GiD_Process Mescape Meshing AssignSizes Lines $walls_mesh_size {*}[GiD_EntitiesGroups get Top_Wall lines] escape escape
    # GiD_Process Mescape Meshing AssignSizes Lines $walls_mesh_size {*}[GiD_EntitiesGroups get Bottom_Wall lines] escape escape
    # GiD_Process Mescape Meshing AssignSizes Lines $building_mesh_size {*}[GiD_EntitiesGroups get InterfaceFluid lines] escape escape
    # GiD_Process Mescape Meshing AssignSizes Surfaces $fluid_mesh_size [GiD_EntitiesGroups get Fluid surfaces] escape escape
    # Kratos::Event_BeforeMeshGeneration $fluid_mesh_size
}


# Tree assign
proc ::CompressibleFluid::examples::SodShockTube::TreeAssignation3D {args} {
    # To be implemented
}

proc ::CompressibleFluid::examples::SodShockTube::TreeAssignation2D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype line
    if {$nd eq "3D"} { set condtype surface }

    # Monolithic solution strategy set
    # spdAux::SetValueOnTreeItem v "Monolithic" FLSolStrat

    # Fluid Parts
    set fluidParts [spdAux::getRoute "FLParts"]
    set fluidNode [customlib::AddConditionGroupOnXPath $fluidParts Fluid]
    # set props [list Element Monolithic$nd ConstitutiveLaw Newtonian Material Air]
    # spdAux::SetValuesOnBaseNode $fluidNode $props

    set initial_conditions [spdAux::getRoute "CFNodalConditions"]
    # Fluid density
    set fluid_density "$initial_conditions/condition\[@n='DENSITY'\]"
    set initial_density_node [customlib::AddConditionGroupOnXPath $fluid_density Fluid]
    $initial_density_node setAttribute ov surface
    set props [list ByFunction Yes function_value "1.0 if x < 0.5 else 0.125"]
    spdAux::SetValuesOnBaseNode $initial_density_node $props

    set fluid_energy "$initial_conditions/condition\[@n='TOTAL_ENERGY'\]"
    set initial_energy_node [customlib::AddConditionGroupOnXPath $fluid_energy Fluid]
    $initial_energy_node setAttribute ov surface
    set props [list ByFunction Yes function_value "2.5 if x < 0.5 else 0.25"]
    spdAux::SetValuesOnBaseNode $initial_energy_node $props

    set fluidConditions [spdAux::getRoute "FLBC"]

    # Fluid Conditions
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='Slip$nd'\]" Top] setAttribute ov $condtype
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='Slip$nd'\]" Bottom] setAttribute ov $condtype

    set momentum "$fluidConditions/condition\[@n='MomentumConstraints$nd'\]"
    foreach gr [list Left Right] {
        GiD_Groups create "$gr//Total"
        GiD_Groups edit state "$gr//Total" hidden
        spdAux::AddIntervalGroup $gr "$gr//Total"
        set momentum_node [customlib::AddConditionGroupOnXPath $momentum "$gr//Total"]
        $momentum_node setAttribute ov $condtype
        [$momentum_node selectNodes "./value\[@n = 'selector_component_X'\]"] setAttribute v "Not"

    }

    # Time parameters
    set parameters [list EndTime 0.1 AutomaticDeltaTime Yes]
    set xpath [spdAux::getRoute "FLTimeParameters"]
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Output
    set parameters [list OutputControlType time OutputDeltaTime 0.01]
    set xpath "[spdAux::getRoute FLResults]/container\[@n='GiDOutput'\]/container\[@n='GiDOptions'\]"
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Parallelism
    set parameters [list ParallelSolutionType OpenMP OpenMPNumberOfThreads 4]
    set xpath [spdAux::getRoute "Parallelization"]
    spdAux::SetValuesOnBasePath $xpath $parameters

    spdAux::RequestRefresh
}
