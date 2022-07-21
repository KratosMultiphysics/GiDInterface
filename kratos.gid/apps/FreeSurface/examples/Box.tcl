
namespace eval ::FreeSurface::examples::Box {
    namespace path ::FreeSurface::examples
    Kratos::AddNamespace [namespace current]
}

proc ::FreeSurface::examples::Box::Init {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawGeometry$::Model::SpatialDimension
    #AssignGroups$::Model::SpatialDimension
    #AssignMeshSizes$::Model::SpatialDimension
    #TreeAssignation$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}


# Draw Geometry
proc ::FreeSurface::examples::Box::DrawGeometry2D {args} {
    Kratos::ResetModel
    GiD_Layers create Fluid
    GiD_Layers edit to_use Fluid

    # Geometry creation
    ## Points ##
    set coordinates [list -3.91362 -3.3393 0 -2.91362 -3.3393 0 -2.91362 -3.1393 0 -2.91362 -2.7393 0 -2.71362 -2.7393 0]
    lappend coordinates {*}[list -2.71362 -2.5393 0 -3.91362 -2.5393 0 -3.91362 -3.1393 0 -4.11362 -3.1393 0 -4.11362 -3.3393 0 ]
    set fluidPoints [list ]
    foreach {x y z} $coordinates {
        lappend fluidPoints [GiD_Geometry create point append Fluid $x $y $z]
    }

    ## Lines ##
    set fluidLines [list ]
    set initial [lindex $fluidPoints 0]
    foreach point [lrange $fluidPoints 1 end] {
        lappend fluidLines [GiD_Geometry create line append stline Fluid $initial $point]
        set initial $point
    }
    lappend fluidLines [GiD_Geometry create line append stline Fluid $initial [lindex $fluidPoints 0]]

    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface {*}$fluidLines escape escape

    ## Points ##
    set coordinates [list -3.91362 -3.5393 0 -2.91362 -3.5393 0 ]
    set fluidPoints [list ]
    foreach {x y z} $coordinates {
        lappend fluidPoints [GiD_Geometry create point append Fluid $x $y $z]
    }

    ## Lines ##
    set fluidLines [list ]
    set initial 1
    foreach point [list {*}$fluidPoints 2] {
        lappend fluidLines [GiD_Geometry create line append stline Fluid $initial $point]
        set initial $point
    }

    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface 1 {*}$fluidLines escape escape


}


# Group assign
proc ::FreeSurface::examples::Box::AssignGroups2D {args} {
    # Create the groups
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid surfaces 1

    GiD_Groups create Inlet
    GiD_Groups edit color Inlet "#e0210fff"
    GiD_EntitiesGroups assign Inlet lines 4

    GiD_Groups create Outlet
    GiD_Groups edit color Outlet "#42eb71ff"
    GiD_EntitiesGroups assign Outlet lines 2

    GiD_Groups create No_Slip_Walls
    GiD_Groups edit color No_Slip_Walls "#3b3b3bff"
    GiD_EntitiesGroups assign No_Slip_Walls lines {1 3}

    GiD_Groups create No_Slip_Cylinder
    GiD_Groups edit color No_Slip_Cylinder "#3b3b3bff"
    GiD_EntitiesGroups assign No_Slip_Cylinder lines 5
}
proc ::FreeSurface::examples::Box::AssignGroups3D {args} {
    # Create the groups
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid volumes 1

    GiD_Groups create Inlet
    GiD_Groups edit color Inlet "#e0210fff"
    GiD_EntitiesGroups assign Inlet surfaces 5

    GiD_Groups create Outlet
    GiD_Groups edit color Outlet "#42eb71ff"
    GiD_EntitiesGroups assign Outlet surfaces 3

    GiD_Groups create No_Slip_Walls
    GiD_Groups edit color No_Slip_Walls "#3b3b3bff"
    GiD_EntitiesGroups assign No_Slip_Walls surfaces {1 2 4 7}

    GiD_Groups create No_Slip_Cylinder
    GiD_Groups edit color No_Slip_Cylinder "#3b3b3bff"
    GiD_EntitiesGroups assign No_Slip_Cylinder surfaces 6
}


# Mesh sizes
proc ::FreeSurface::examples::Box::AssignMeshSizes3D {args} {
    set cylinder_mesh_size 0.005
    set walls_mesh_size 0.05
    set fluid_mesh_size 0.05
    GiD_Process Mescape Utilities Variables SizeTransitionsFactor 0.4 escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $cylinder_mesh_size {*}[GiD_EntitiesGroups get No_Slip_Cylinder surfaces] escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $walls_mesh_size {*}[GiD_EntitiesGroups get Inlet surfaces] escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $walls_mesh_size {*}[GiD_EntitiesGroups get Outlet surfaces] escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $walls_mesh_size {*}[GiD_EntitiesGroups get No_Slip_Walls surfaces] escape escape
    GiD_Process Mescape Meshing AssignSizes Volumes $fluid_mesh_size [GiD_EntitiesGroups get Fluid volumes] escape escape
    Kratos::Event_BeforeMeshGeneration $fluid_mesh_size
}
proc ::FreeSurface::examples::Box::AssignMeshSizes2D {args} {
    set cylinder_mesh_size 0.005
    set fluid_mesh_size 0.05
    GiD_Process Mescape Utilities Variables SizeTransitionsFactor 0.4 escape escape
    GiD_Process Mescape Meshing AssignSizes Lines $cylinder_mesh_size {*}[GiD_EntitiesGroups get No_Slip_Cylinder lines] escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $fluid_mesh_size [GiD_EntitiesGroups get Fluid surfaces] escape escape
    Kratos::Event_BeforeMeshGeneration $fluid_mesh_size
}


# Tree assign
proc ::FreeSurface::examples::Box::TreeAssignation3D {args} {
    TreeAssignation2D
    ::Fluid::examples::AddCuts
}
proc ::FreeSurface::examples::Box::TreeAssignation2D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype line
    if {$nd eq "3D"} { set condtype surface }

    # Monolithic solution strategy set
    spdAux::SetValueOnTreeItem v "Monolithic" FLSolStrat

    # Fluid Parts
    set fluidParts [spdAux::getRoute "FLParts"]
    set fluidNode [customlib::AddConditionGroupOnXPath $fluidParts Fluid]
    # set props [list Element Monolithic$nd ConstitutiveLaw Newtonian2DLaw DENSITY 1.0 DYNAMIC_VISCOSITY 0.002 YIELD_STRESS 0 POWER_LAW_K 1 POWER_LAW_N 1]
    set props [list Element Monolithic$nd ConstitutiveLaw Newtonian2DLaw DENSITY 1.0 DYNAMIC_VISCOSITY 0.002]
    spdAux::SetValuesOnBaseNode $fluidNode $props

    set fluidConditions [spdAux::getRoute "FLBC"]
    ::Fluid::examples::ErasePreviousIntervals

    # Fluid Inlet
    Fluid::xml::CreateNewInlet Inlet {new true name inlet1 ini 0 end 1} true "6*y*(1-y)*sin(pi*t*0.5)"
    Fluid::xml::CreateNewInlet Inlet {new true name inlet2 ini 1 end End} true "6*y*(1-y)"

    # Fluid Outlet
    set fluidOutlet "$fluidConditions/condition\[@n='Outlet$nd'\]"
    set outletNode [customlib::AddConditionGroupOnXPath $fluidOutlet Outlet]
    $outletNode setAttribute ov $condtype
    set props [list value 0.0]
    spdAux::SetValuesOnBaseNode $outletNode $props

    # Fluid Conditions
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='NoSlip$nd'\]" No_Slip_Walls] setAttribute ov $condtype
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='NoSlip$nd'\]" No_Slip_Cylinder] setAttribute ov $condtype

    # Time parameters
    set parameters [list EndTime 45 DeltaTime 0.1]
    set xpath [spdAux::getRoute "FLTimeParameters"]
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Output
    set parameters [list OutputControlType step OutputDeltaStep 1]
    set xpath "[spdAux::getRoute FLResults]/container\[@n='GiDOutput'\]/container\[@n='GiDOptions'\]"
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Parallelism
    set parameters [list ParallelSolutionType OpenMP OpenMPNumberOfThreads 4]
    set xpath [spdAux::getRoute "Parallelization"]
    spdAux::SetValuesOnBasePath $xpath $parameters

    spdAux::RequestRefresh
}
