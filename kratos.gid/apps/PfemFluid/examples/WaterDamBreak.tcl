
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
    GiD_Layers create PfemFluid
    GiD_Layers edit to_use PfemFluid

    ## Lines ##
    GiD_Process Mescape Geometry Create Line 0 0 0 0.146 0 0 0.146 0.292 0 0 0.292 0 0 0 0 Old escape 
    GiD_Process Mescape Geometry Create Line 0 0.292 0 Old 0 0.608 0 0.608 0.608 0 0.608 0 0 0.316 0 0 0.316 0.048 0 0.292 0.048 0 0.292 0 0 0.146 0 0 Old escape 
  
    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface 2 3 1 4 escape escape
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