
namespace eval ::Fluid::examples::LidDrivenCavity {
    namespace path ::Fluid::examples
    Kratos::AddNamespace [namespace current]
}

proc ::Fluid::examples::LidDrivenCavity::Init {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
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
# proc ::Fluid::examples::LidDrivenCavity::DrawGeometry3D {args} {
#     DrawGeometry2D
#     GiD_Process Mescape Utilities Copy Surfaces Duplicate DoExtrude Volumes MaintainLayers Translation FNoJoin 0.0,0.0,0.0 FNoJoin 0.0,0.0,1.0 1 escape escape escape
#     GiD_Layers edit opaque Fluid 0

#     GiD_Process escape escape 'Render Flat escape 'Rotate Angle 270 90 escape escape escape escape 'Rotate objaxes x -150 y -30 escape escape
# }

proc ::Fluid::examples::LidDrivenCavity::DrawGeometry2D {args} {
    Kratos::ResetModel
    GiD_Layers create Fluid
    GiD_Layers edit to_use Fluid

    # Geometry creation
    ## Points ##
    set coordinates [list 0 1 0 1 1 0 1 0 0 0 0 0]
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

    # # Body #
    # GiD_Layers create Body
    # GiD_Layers edit to_use Body
    # set circle_center_x 1.25
    # set circle_center_y 0.5
    # set circle_center_z 0.0
    # set center_radius 0.1
    # GiD_Process Mescape Geometry Create Object CirclePNR $circle_center_x $circle_center_y $circle_center_z 0.0 0.0 1.0 $center_radius escape
    # GiD_Geometry delete surface 2

    # # Create the hole
    # GiD_Layers edit to_use Fluid
    # GiD_Process MEscape Geometry Edit HoleNurb 1 5 escape escape

}


# Group assign
proc ::Fluid::examples::LidDrivenCavity::AssignGroups2D {args} {
    # Create the groups
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid surfaces 1

    GiD_Groups create Lid
    GiD_Groups edit color Lid "#e0210fff"
    GiD_EntitiesGroups assign Lid lines 1

    GiD_Groups create Walls
    GiD_Groups edit color Walls "#3b3b3bff"
    GiD_EntitiesGroups assign Walls lines {2 3 4}

    GiD_Groups create Corner
    GiD_Groups edit color Corner "#42eb71ff"
    GiD_EntitiesGroups assign Corner points 4
}

# proc ::Fluid::examples::LidDrivenCavity::AssignGroups3D {args} {
#     # Create the groups
#     GiD_Groups create Fluid
#     GiD_Groups edit color Fluid "#26d1a8ff"
#     GiD_EntitiesGroups assign Fluid volumes 1

#     GiD_Groups create Inlet
#     GiD_Groups edit color Inlet "#e0210fff"
#     GiD_EntitiesGroups assign Inlet surfaces 5

#     GiD_Groups create Outlet
#     GiD_Groups edit color Outlet "#42eb71ff"
#     GiD_EntitiesGroups assign Outlet surfaces 3

#     GiD_Groups create No_Slip_Walls
#     GiD_Groups edit color No_Slip_Walls "#3b3b3bff"
#     GiD_EntitiesGroups assign No_Slip_Walls surfaces {1 2 4 7}

#     GiD_Groups create No_Slip_Cylinder
#     GiD_Groups edit color No_Slip_Cylinder "#3b3b3bff"
#     GiD_EntitiesGroups assign No_Slip_Cylinder surfaces 6
# }

# Mesh sizes
# proc ::Fluid::examples::LidDrivenCavity::AssignMeshSizes3D {args} {
#     set cylinder_mesh_size 0.005
#     set walls_mesh_size 0.05
#     set fluid_mesh_size 0.05
#     GiD_Process Mescape Utilities Variables SizeTransitionsFactor 0.4 escape escape
#     GiD_Process Mescape Meshing AssignSizes Surfaces $cylinder_mesh_size {*}[GiD_EntitiesGroups get No_Slip_Cylinder surfaces] escape escape
#     GiD_Process Mescape Meshing AssignSizes Surfaces $walls_mesh_size {*}[GiD_EntitiesGroups get Inlet surfaces] escape escape
#     GiD_Process Mescape Meshing AssignSizes Surfaces $walls_mesh_size {*}[GiD_EntitiesGroups get Outlet surfaces] escape escape
#     GiD_Process Mescape Meshing AssignSizes Surfaces $walls_mesh_size {*}[GiD_EntitiesGroups get No_Slip_Walls surfaces] escape escape
#     GiD_Process Mescape Meshing AssignSizes Volumes $fluid_mesh_size [GiD_EntitiesGroups get Fluid volumes] escape escape
#     Kratos::Event_BeforeMeshGeneration $fluid_mesh_size
# }

proc ::Fluid::examples::LidDrivenCavity::AssignMeshSizes2D {args} {
    set fluid_mesh_size 0.02
    # GiD_Process Mescape Utilities Variables SizeTransitionsFactor 0.4 escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $fluid_mesh_size [GiD_EntitiesGroups get Fluid surfaces] escape escape
    Kratos::Event_BeforeMeshGeneration $fluid_mesh_size
}


# Tree assign
# proc ::Fluid::examples::LidDrivenCavity::TreeAssignation3D {args} {
#     TreeAssignation2D
#     ::Fluid::examples::AddCuts
# }

proc ::Fluid::examples::LidDrivenCavity::TreeAssignation2D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype line
    if {$nd eq "3D"} { set condtype surface }

    # Monolithic solution strategy set
    spdAux::SetValueOnTreeItem v "Monolithic" FLSolStrat
    spdAux::SetValueOnTreeItem v "bdf2" FLScheme

    # Fluid Parts
    set fluidParts [spdAux::getRoute "FLParts"]
    set fluidNode [customlib::AddConditionGroupOnXPath $fluidParts Fluid]
    set props [list Element P2P1$nd ConstitutiveLaw Newtonian2DLaw DENSITY 1.0 DYNAMIC_VISCOSITY 0.0025]
    spdAux::SetValuesOnBaseNode $fluidNode $props

    set fluidConditions [spdAux::getRoute "FLBC"]
    ::Fluid::examples::ErasePreviousIntervals

    # Fluid wall condition
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='NoSlip$nd'\]" Walls] setAttribute ov $condtype

    # Fluid lid velocity
    set fluidLid "$fluidConditions/condition\[@n='VelocityConstraints$nd'\]"
    set lidNode [customlib::AddConditionGroupOnXPath $fluidLid Lid]
    $lidNode setAttribute ov $condtype
    set props [list selector_component_X ByValue value_component_X 1.0 selector_component_Y ByValue value_component_Y 0.0 Interval Total]
    spdAux::SetValuesOnBaseNode $lidNode $props

    # Fluid corner pressure
    set fluidCorner "$fluidConditions/condition\[@n='PressureConstraints$nd'\]"
    set cornerNode [customlib::AddConditionGroupOnXPath $fluidCorner Corner]
    $cornerNode setAttribute ov Point
    set props [list value 0.0 Interval Total]
    spdAux::SetValuesOnBaseNode $cornerNode $props

    # Time parameters
    set parameters [list EndTime 30.0 DeltaTime 0.25]
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

    # Set the linear solver as bicgstab
    spdAux::SetValueOnTreeItem v "bicgstab" FLMonolithiclinear_solver_settings Solver

    spdAux::RequestRefresh
}
