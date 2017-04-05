
proc ::Fluid::examples::CylinderInFlow {args} {
    DrawCylinderInFlowGeometry$::Model::SpatialDimension
    AssignCylinderInFlowMeshSizes
    TreeAssignationCylinderInFlow
}
proc Fluid::examples::DrawCylinderInFlowGeometry3D {args} {W "Not Implemented"}
proc Fluid::examples::DrawCylinderInFlowGeometry2D {args} {
    Kratos::ResetModel
    GiD_Layers create Fluid
    GiD_Layers edit to_use Fluid

    # Geometry creation
    ## Points ##
    set coordinates [list 0 1 0 5 1 0 5 0 0 0 0 0]
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
    set circle_center_x 1.25
    set circle_center_y 0.5
    set circle_center_z 0.0
    set center_radius 0.1
    GiD_Process Mescape Geometry Create Object CirclePNR $circle_center_x $circle_center_y $circle_center_z 0.0 0.0 1.0 $center_radius escape 
    GiD_Geometry delete surface 2
    
    # Create the hole
    GiD_Layers edit to_use Fluid
    GiD_Process MEscape Geometry Edit HoleNurb 1 5 escape escape
    
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
    
    GiD_Groups create No_Slip
    GiD_Groups edit color No_Slip "#3b3b3bff"
    GiD_EntitiesGroups assign No_Slip lines {1 3 5}
    
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
}

proc Fluid::examples::AssignCylinderInFlowMeshSizes {args} {
    
}

proc Fluid::examples::TreeAssignationCylinderInFlow {args} {
    
}
