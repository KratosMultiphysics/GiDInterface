namespace eval ::EmbeddedFluid::examples::CylinderInFlow {
    namespace path ::EmbeddedFluid::examples
    Kratos::AddNamespace [namespace current]
    
    variable CylinderInFlow_Data
}

proc ::EmbeddedFluid::examples::CylinderInFlow::Init {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    InitVariables
    DrawGeometry3D
    AssignGroups3D
    AssignMeshSizes3D
    TreeAssignation3D

    AddMeshOptimizationPoints

    GiD_Process 'Zoom Frame
    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
}

proc EmbeddedFluid::examples::CylinderInFlow::InitVariables { } {
    variable CylinderInFlow_Data
    set CylinderInFlow_Data(circle_center_x) 0.75
    set CylinderInFlow_Data(circle_center_y) 0.5
    set CylinderInFlow_Data(circle_center_z) 0.0
    set CylinderInFlow_Data(circle_radius)   0.1
}


# Draw Geometry
proc EmbeddedFluid::examples::CylinderInFlow::DrawGeometry3D {args} {
    DrawGeometry2D
    GiD_Process Mescape Utilities Copy Surfaces Duplicate DoExtrude Volumes MaintainLayers Translation FNoJoin 0.0,0.0,0.0 FNoJoin 0.0,0.0,1.0 1 escape escape escape
    GiD_Process Mescape Utilities Copy Surfaces Duplicate DoExtrude Surfaces MaintainLayers Translation FNoJoin 0.0,0.0,0.0 FNoJoin 0.0,0.0,1.0 2 escape escape escape
    GiD_Layers edit opaque Fluid 0

}
proc EmbeddedFluid::examples::CylinderInFlow::DrawGeometry2D {args} {
    Kratos::ResetModel
    GiD_Layers create Fluid
    GiD_Layers edit to_use Fluid

    # Geometry creation
    ## Points ##
    set coordinates [list 0 1 0 3.5 1 0 3.5 0 0 0 0 0]
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

    # Body #
    GiD_Layers create Body
    GiD_Layers edit to_use Body
    variable CylinderInFlow_Data
    set circle_center_x $CylinderInFlow_Data(circle_center_x)
    set circle_center_y $CylinderInFlow_Data(circle_center_y)
    set circle_center_z $CylinderInFlow_Data(circle_center_z)
    set circle_radius   $CylinderInFlow_Data(circle_radius)
    GiD_Process Mescape Geometry Create Object CirclePNR $circle_center_x $circle_center_y $circle_center_z 0.0 0.0 1.0 $circle_radius escape
    GiD_Process escape MEscape Geometry Edit DivideLine Multiple NumDivisions 2 5 escape escape 

    # GiD_Geometry delete surface 2

    # Create the hole
    GiD_Layers edit to_use Fluid
    # GiD_Process MEscape Geometry Edit HoleNurb 1 5 escape escape

}

# Group assign
proc EmbeddedFluid::examples::CylinderInFlow::AssignGroups3D {args} {
    # Create the groups
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid volumes 1

    GiD_Groups create Inlet
    GiD_Groups edit color Inlet "#e0210fff"
    GiD_EntitiesGroups assign Inlet surfaces 6

    GiD_Groups create Outlet
    GiD_Groups edit color Outlet "#42eb71ff"
    GiD_EntitiesGroups assign Outlet surfaces 4

    GiD_Groups create No_Slip_Walls
    GiD_Groups edit color No_Slip_Walls "#3b3b3bff"
    GiD_EntitiesGroups assign No_Slip_Walls surfaces {1 3 5 7}

    GiD_Groups create No_Slip_Cylinder
    GiD_Groups edit color No_Slip_Cylinder "#3b3b3bff"
    GiD_EntitiesGroups assign No_Slip_Cylinder surfaces {8 9}
}

# Mesh sizes
proc EmbeddedFluid::examples::CylinderInFlow::AssignMeshSizes3D {args} {
    set cylinder_mesh_size 0.005
    set walls_mesh_size 0.05
    set fluid_mesh_size 0.05
    GiD_Process Mescape Utilities Variables SizeTransitionsFactor 0.4 escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $cylinder_mesh_size {*}[GiD_EntitiesGroups get No_Slip_Cylinder surfaces] escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $walls_mesh_size {*}[GiD_EntitiesGroups get Inlet surfaces] escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $walls_mesh_size {*}[GiD_EntitiesGroups get Outlet surfaces] escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $walls_mesh_size {*}[GiD_EntitiesGroups get No_Slip_Walls surfaces] escape escape
    GiD_Process Mescape Meshing AssignSizes Volumes $fluid_mesh_size [GiD_EntitiesGroups get Fluid volumes] escape escape
    # Kratos::BeforeMeshGeneration $fluid_mesh_size
}
proc EmbeddedFluid::examples::CylinderInFlow::AssignMeshSizes2D {args} {
    set cylinder_mesh_size 0.005
    set fluid_mesh_size 0.05
    GiD_Process Mescape Utilities Variables SizeTransitionsFactor 0.4 escape escape
    GiD_Process Mescape Meshing AssignSizes Lines $cylinder_mesh_size {*}[GiD_EntitiesGroups get No_Slip_Cylinder lines] escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces $fluid_mesh_size [GiD_EntitiesGroups get Fluid surfaces] escape escape
    # Kratos::BeforeMeshGeneration $fluid_mesh_size
}

# Tree assign
proc EmbeddedFluid::examples::CylinderInFlow::TreeAssignation3D {args} {
    TreeAssignation2D
}
proc EmbeddedFluid::examples::CylinderInFlow::TreeAssignation2D {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype line
    if {$nd eq "3D"} { set condtype surface }

    # Monolithic solution strategy set
    spdAux::SetValueOnTreeItem v "Monolithic" FLSolStrat

    # Fluid Parts
    set fluidParts [spdAux::getRoute "FLParts"]
    set fluidNode [customlib::AddConditionGroupOnXPath $fluidParts Fluid]
    # set props [list Element Monolithic$nd ConstitutiveLaw Newtonian DENSITY 1.0 DYNAMIC_VISCOSITY 0.002 YIELD_STRESS 0 POWER_LAW_K 1 POWER_LAW_N 1]
    set props [list Element Monolithic$nd ConstitutiveLaw Newtonian DENSITY 1.0 DYNAMIC_VISCOSITY 0.002]
    spdAux::SetValuesOnBaseNode $fluidNode $props

    ErasePreviousIntervals
    set fluidConditions [spdAux::getRoute "FLBC"]

    # Fluid Inlet
    Fluid::xml::CreateNewInlet Inlet {new true name inlet1 ini 0 end 1} true "6*y*(1-y)*sin(pi*t*0.5)"
    Fluid::xml::CreateNewInlet Inlet {new true name inlet2 ini 0 end End} true "6*y*(1-y)"

    # Fluid Outlet
    set fluidOutlet "$fluidConditions/condition\[@n='Outlet$nd'\]"
    set outletNode [customlib::AddConditionGroupOnXPath $fluidOutlet Outlet]
    $outletNode setAttribute ov $condtype
    set props [list value 0.0]
    spdAux::SetValuesOnBaseNode $outletNode $props

    # Fluid Conditions
    [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='NoSlip$nd'\]" No_Slip_Walls] setAttribute ov $condtype
    # [customlib::AddConditionGroupOnXPath "$fluidConditions/condition\[@n='NoSlip$nd'\]" No_Slip_Cylinder] setAttribute ov $condtype

    # Time parameters
    set parameters [list EndTime 45 DeltaTime 0.1]
    set xpath [spdAux::getRoute "FLTimeParameters"]
    spdAux::SetValuesOnBasePath $xpath $parameters

    # Output
    set parameters [list OutputControlType step OutputDeltaStep 1]
    set xpath "[spdAux::getRoute Results]/container\[@n='GiDOutput'\]/container\[@n='GiDOptions'\]"
    spdAux::SetValuesOnBasePath $xpath $parameters
    
    # Parallelism
    set parameters [list ParallelSolutionType OpenMP OpenMPNumberOfThreads 4]
    set xpath [spdAux::getRoute "Parallelization"]
    spdAux::SetValuesOnBasePath $xpath $parameters

    spdAux::RequestRefresh
}

proc EmbeddedFluid::examples::CylinderInFlow::AddMeshOptimizationPoints { } {
    set optimized_group "Optimized mesh"
    
    GiD_Layers create Mesh_Optimization
    GiD_Layers edit to_use Mesh_Optimization
    
    variable CylinderInFlow_Data
    set radius   $CylinderInFlow_Data(circle_radius)
    set center_x [expr $CylinderInFlow_Data(circle_center_x) + $radius +0.025]
    set center_y $CylinderInFlow_Data(circle_center_y)
    set center_z [expr $CylinderInFlow_Data(circle_center_z) + 0.025]
    set origin_point [GiD_Geometry create point append Mesh_Optimization $center_x $center_y $center_z]

    GiD_Groups create $optimized_group
    GiD_EntitiesGroups assign $optimized_group points $origin_point
    GiD_Process Mescape Utilities Copy Points Duplicate MaintainLayers MCopy 19 Translation FNoJoin 0.0,0.0,0.0 FNoJoin 0.0,0.0,0.05 $origin_point escape Mescape escape 
    
    set original_points [GiD_EntitiesGroups get $optimized_group points]
    GiD_Process Mescape Utilities Copy Points Duplicate MaintainLayers MCopy 15 Translation FNoJoin 0.0,0.0,0.0 FNoJoin 0.166,0.0,0.0 {*}$original_points escape Mescape escape 
    
    set original_points [GiD_EntitiesGroups get $optimized_group points]
    GiD_Process Mescape Meshing MeshCriteria ForcePointsTo VolumeMesh 1 escape {*}$original_points escape 
    GiD_Process Mescape Meshing AssignSizes Points 0.005 {*}$original_points escape escape

    GiD_Process Mescape Utilities Copy Points Duplicate MaintainLayers Translation FNoJoin 0.0,0.0,0.0 FNoJoin 0.0,0.1,0.0  {*}$original_points escape 
    GiD_Process Mescape Utilities Copy Points Duplicate MaintainLayers Translation FNoJoin 0.0,0.0,0.0 FNoJoin 0.0,-0.1,0.0 {*}$original_points escape 

}