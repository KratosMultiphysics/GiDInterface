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
    return ""
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
    set coordinates [list {0 0 0} {0.5 0 0} {0.5 0.1 0} {0 0.1 0} {1 0 0} {1 0.1 0}]
    foreach point $coordinates {
        lassign $point x y z
        GiD_Geometry create point append Fluid $x $y $z
    }

    ## Lines ##
    GiD_Geometry create line append stline Fluid 1 2
    GiD_Geometry create line append stline Fluid 2 3
    GiD_Geometry create line append stline Fluid 3 4
    GiD_Geometry create line append stline Fluid 4 1
    GiD_Geometry create line append stline Fluid 2 5
    GiD_Geometry create line append stline Fluid 5 6
    GiD_Geometry create line append stline Fluid 6 3

        

    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface 1 2 3 4 escape escape
    GiD_Process Mescape Geometry Create NurbsSurface 2 5 6 7 escape escape
    
}


# Group assign
proc ::CompressibleFluid::examples::SodShockTube::AssignGroups2D {args} {
    # Create the groups
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid surfaces 1

    GiD_Groups create Inlet
    GiD_Groups edit color Inlet "#e0210fff"
    GiD_EntitiesGroups assign Inlet lines 8

    GiD_Groups create Outlet
    GiD_Groups edit color Outlet "#42eb71ff"
    GiD_EntitiesGroups assign Outlet lines 6

    GiD_Groups create Top_Wall
    GiD_Groups edit color Top_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Top_Wall lines 7

    GiD_Groups create Bottom_Wall
    GiD_Groups edit color Bottom_Wall "#3b3b3bff"
    GiD_EntitiesGroups assign Bottom_Wall lines {1 5}

    GiD_Groups create InterfaceFluid
    GiD_Groups edit color InterfaceFluid "#3b3b3bff"
    GiD_EntitiesGroups assign InterfaceFluid lines {2 3 4}
}
proc ::CompressibleFluid::examples::SodShockTube::AssignGroups3D {args} {
    # To be implemented
}


# Mesh sizes
proc ::CompressibleFluid::examples::SodShockTube::AssignMeshSizes3D {args} {
    # To be implemented
}

proc ::CompressibleFluid::examples::SodShockTube::AssignMeshSizes2D {args} {
    set fluid_mesh_size 30.0
    set walls_mesh_size 30.0
    set building_mesh_size 3.0
    GiD_Process Mescape Meshing AssignSizes Lines $walls_mesh_size {*}[GiD_EntitiesGroups get Inlet lines] escape escape
    GiD_Process Mescape Meshing AssignSizes Lines $walls_mesh_size {*}[GiD_EntitiesGroups get Outlet lines] escape escape
    GiD_Process Mescape Meshing AssignSizes Lines $walls_mesh_size {*}[GiD_EntitiesGroups get Top_Wall lines] escape escape
    GiD_Process Mescape Meshing AssignSizes Lines $walls_mesh_size {*}[GiD_EntitiesGroups get Bottom_Wall lines] escape escape
    GiD_Process Mescape Meshing AssignSizes Lines $building_mesh_size {*}[GiD_EntitiesGroups get InterfaceFluid lines] escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $fluid_mesh_size [GiD_EntitiesGroups get Fluid surfaces] escape escape
    Kratos::Event_BeforeMeshGeneration $fluid_mesh_size
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
    spdAux::SetValueOnTreeItem v "Monolithic" FLSolStrat

    # Fluid Parts
    set fluidParts [spdAux::getRoute "FLParts"]
    set fluidNode [customlib::AddConditionGroupOnXPath $fluidParts Fluid]
    set props [list Element Monolithic$nd ConstitutiveLaw Newtonian Material Air]
    spdAux::SetValuesOnBaseNode $fluidNode $props

    set fluidConditions [spdAux::getRoute "FLBC"]
    ::CompressibleFluid::examples::ErasePreviousIntervals

    # Fluid Inlet
    ::CompressibleFluid::xml::CreateNewInlet Inlet {new true name inlet1 ini 0 end 10.0} true "25.0*t/10.0"
    ::CompressibleFluid::xml::CreateNewInlet Inlet {new true name inlet2 ini 10.0 end End} false 25.0

    # Fluid Outlet
    set fluidOutlet "$fluidConditions/condition\[@n='Outlet$nd'\]"
    set outletNode [customlib::AddConditionGroupOnXPath $fluidOutlet Outlet]
    $outletNode setAttribute ov $condtype
    set props [list value 0.0]
    spdAux::SetValuesOnBaseNode $outletNode $props

    # Fluid Conditions
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='Slip$nd'\]" Top_Wall] setAttribute ov $condtype
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='Slip$nd'\]" Bottom_Wall] setAttribute ov $condtype
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='NoSlip$nd'\]" InterfaceFluid] setAttribute ov $condtype

    # Time parameters
    set parameters [list EndTime 40.0 DeltaTime 0.05]
    set xpath [spdAux::getRoute "FLTimeParameters"]
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Output
    set parameters [list OutputControlType time OutputDeltaTime 1.0]
    set xpath "[spdAux::getRoute FLResults]/container\[@n='GiDOutput'\]/container\[@n='GiDOptions'\]"
    spdAux::SetValuesOnBasePath $xpath $parameters
    
    # Parallelism
    set parameters [list ParallelSolutionType OpenMP OpenMPNumberOfThreads 4]
    set xpath [spdAux::getRoute "Parallelization"]
    spdAux::SetValuesOnBasePath $xpath $parameters

    spdAux::RequestRefresh
}
