
proc ::PfemFluid::examples::WaterDamBreak {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
                if { $retval == "cancel" } { return }
    }

    Kratos::ResetModel
    DrawWaterDamBreakGeometry$::Model::SpatialDimension
    # AssignGroupsWaterDamBreak$::Model::SpatialDimension
    # AssignWaterDamBreakMeshSizes$::Model::SpatialDimension
    # TreeAssignationWaterDamBreak$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}


# Draw Geometry
proc PfemFluid::examples::DrawWaterDamBreakGeometry3D {args} {
    # To be implemented
}

proc PfemFluid::examples::DrawWaterDamBreakGeometry2D {args} {
    set layer PfemFluid
    GiD_Layers create $layer
    GiD_Layers edit to_use $layer

    ## Lines ##
    set points_inner [list 0 0 0 0.146 0 0 0.146 0.292 0 0 0.292 0]
    foreach {x y z} $points_inner {
        GiD_Geometry create point append $layer $x $y $z
    }
    set points_outer [list 0 0.608 0 0.608 0.608 0 0.608 0 0 0.316 0 0 0.316 0.048 0 0.292 0.048 0 0.292 0 0]
    foreach {x y z} $points_outer {
        GiD_Geometry create point append $layer $x $y $z
    }
    set lines_inner [list 1 2 2 3 3 4 4 1]
    foreach {p1 p2} $lines_inner {
        GiD_Geometry create line append stline $layer $p1 $p2
    }
    set lines_outer [list 4 5 5 6 6 7 7 8 8 9 9 10 10 11 11 2]
    foreach {p1 p2} $lines_outer {
        GiD_Geometry create line append stline $layer $p1 $p2
    }
    
    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface 2 3 4 1 escape escape
}



# Group assign
proc PfemFluid::examples::AssignGroupsWaterDamBreakGeometry2D {args} {
    # Create the groups
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid surfaces 1

    GiD_Groups create Rigid_Walls
    GiD_Groups edit color Rigid_Walls "#e0210fff"
    GiD_EntitiesGroups assign Rigid_Walls lines lines {1 4 5 6 7 8 9 10 11 12}

}
proc PfemFluid::examples::AssignGroupsWaterDamBreakGeometry3D {args} {
    # To be implemented
}



# Mesh sizes
proc PfemFluid::examples::AssignWaterDamBreakGeometryMeshSizes3D {args} {
    # To be implemented
}

proc PfemFluid::examples::AssignWaterDamBreakGeometryMeshSizes2D {args} {
    # DO NOTHING
}


# Tree assign
proc PfemFluid::examples::TreeAssignationWaterDamBreakGeometry3D {args} {
    # To be implemented
}

proc PfemFluid::examples::TreeAssignationWaterDamBreakGeometry2D {args} {
# ONLY ASSIGN VELOCITY X Y EQUAL TO 0 TO THE RIGID LINES (SEE ABOVE)
}

proc PfemFluid::examples::ErasePreviousIntervals { } {
    set root [customlib::GetBaseRoot]
    set interval_base [spdAux::getRoute "Intervals"]
    foreach int [$root selectNodes "$interval_base/blockdata\[@n='Interval'\]"] {
        if {[$int @name] ni [list Initial Total Custom1]} {$int delete}
    }
}