
proc ::MPM::examples::FallingSandBall {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawFallingSandBallGeometry$::Model::SpatialDimension
    AssignGroupsFallingSandBall$::Model::SpatialDimension
    AssignFallingSandBallMeshSizes$::Model::SpatialDimension
    TreeAssignationFallingSandBall$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}


# Draw Geometry
proc MPM::examples::DrawFallingSandBallGeometry3D {args} {
    # DrawFallingSandBallGeometry2D
    # GiD_Process Mescape Utilities Copy Surfaces Duplicate DoExtrude Volumes MaintainLayers Translation FNoJoin 0.0,0.0,0.0 FNoJoin 0.0,0.0,1.0 1 escape escape escape
    # GiD_Layers edit opaque Fluid 0

    # GiD_Process escape escape 'Render Flat escape 'Rotate Angle 270 90 escape escape escape escape 'Rotate obj x -150 y -30 escape escape
}
proc MPM::examples::DrawFallingSandBallGeometry2D {args} {
    Kratos::ResetModel
    GiD_Layers create Sand
    GiD_Layers edit to_use Sand

    # Sand circle
    GiD_Process Mescape Geometry Create Object CirclePNR 2.0 3.0 0.0 0.0 0.0 1.0 0.5 escape escape 


    # Grid creation
    GiD_Layers create Grid
    GiD_Layers edit to_use Grid
    
    ## Points ##
    set coordinates [list {0 0 0} {0 4 0} {4 4 0} {4 0 0}]
    set grid_points [list ]
    foreach point $coordinates {
        lappend grid_points [GiD_Geometry create point append Grid {*}$point]
    }

    ## Lines ##
    set grid_lines [list ]
    set initial [lindex $grid_points 0]
    foreach point [lrange $grid_points 1 end] {
        lappend grid_lines [GiD_Geometry create line append stline Grid $initial $point]
        set initial $point
    }
    lappend grid_lines [GiD_Geometry create line append stline Grid $initial [lindex $grid_points 0]]

    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface {*}$grid_lines escape escape
}


# Group assign
proc MPM::examples::AssignGroupsFallingSandBall2D {args} {
    # Create the groups
    GiD_Groups create Sand
    GiD_Groups edit color Sand "#26d1a8ff"
    GiD_EntitiesGroups assign Sand surfaces 1

    GiD_Groups create Grid
    GiD_Groups edit color Grid "#e0210fff"
    GiD_EntitiesGroups assign Grid surfaces 2

    GiD_Groups create FixedDisplacement
    GiD_Groups edit color FixedDisplacement "#3b3b3bff"
    GiD_EntitiesGroups assign FixedDisplacement lines 5

    GiD_Groups create Slip
    GiD_Groups edit color Slip "#42eb71ff"
    GiD_EntitiesGroups assign Slip lines {2 4}
}

proc MPM::examples::AssignGroupsFallingSandBall3D {args} {
    
}

# Tree assign
proc MPM::examples::TreeAssignationFallingSandBall3D {args} {
    TreeAssignationFallingSandBall2D
}

proc MPM::examples::TreeAssignationFallingSandBall2D {args} {
    
}

proc MPM::examples::ErasePreviousIntervals { } {
    set root [customlib::GetBaseRoot]
    set interval_base [spdAux::getRoute "Intervals"]
    foreach int [$root selectNodes "$interval_base/blockdata\[@n='Interval'\]"] {
        if {[$int @name] ni [list Initial Total Custom1]} {$int delete}
    }
}