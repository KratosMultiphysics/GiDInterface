
proc ::PfemThermic::examples::ThermicSloshing {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
        if { $retval == "cancel" } { return }
    }

    Kratos::ResetModel
    DrawThermicSloshingGeometry$::Model::SpatialDimension
    AssignGroupsThermicSloshingGeometry$::Model::SpatialDimension
    # AssignThermicSloshingMeshSizes$::Model::SpatialDimension
    TreeAssignationThermicSloshing$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}


# Draw Geometry
proc PfemThermic::examples::DrawThermicSloshingGeometry3D {args} {
    # To be implemented
}

proc PfemThermic::examples::DrawThermicSloshingGeometry2D {args} {
    set layer PfemThermic
    GiD_Layers create $layer
    GiD_Layers edit to_use $layer

    ## Lines ##
    set points_inner [list 0 0 0 1.0 0 0 1.0 0.3 0 0 0.7 0]
    foreach {x y z} $points_inner {
        GiD_Geometry create point append $layer $x $y $z
    }
    set points_outer [list 0 1.0 0 1.0 1.0 0]
    foreach {x y z} $points_outer {
        GiD_Geometry create point append $layer $x $y $z
    }
    set lines_inner [list 1 2 2 3 3 4 4 1]
    foreach {p1 p2} $lines_inner {
        GiD_Geometry create line append stline $layer $p1 $p2
    }
    set lines_outer [list 4 5 5 6 6 3]
    foreach {p1 p2} $lines_outer {
        GiD_Geometry create line append stline $layer $p1 $p2
    }
    
    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface 2 3 4 1 escape escape
}



# Group assign
proc PfemThermic::examples::AssignGroupsThermicSloshingGeometry2D {args} {
    # Create the groups
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid surfaces 1

    GiD_Groups create Rigid_Walls
    GiD_Groups edit color Rigid_Walls "#e0210fff"
    GiD_EntitiesGroups assign Rigid_Walls lines {1 2 4 5 6 7}

}
proc PfemThermic::examples::AssignGroupsThermicSloshingGeometry3D {args} {
    # To be implemented
}

# Tree assign
proc PfemThermic::examples::TreeAssignationThermicSloshing3D {args} {
    # To be implemented
}

proc PfemThermic::examples::TreeAssignationThermicSloshing2D {args} {
# ONLY ASSIGN VELOCITY X Y EQUAL TO 0 TO THE RIGID LINES (SEE ABOVE)
    # Fluid Parts
    set bodies_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body1'\]"
    gid_groups_conds::copyNode $bodies_xpath [spdAux::getRoute PFEMFLUID_Bodies]
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@n='Body'\]\[2\]" {name Body2}
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body1'\]/value\[@n='BodyType'\]" {v Fluid}

    set fluid_part_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body1'\]/condition\[@n='Parts'\]"
    set fluidNode [customlib::AddConditionGroupOnXPath $fluid_part_xpath Fluid]
    set props [list ConstitutiveLaw Newtonian DENSITY 1e3]
    spdAux::SetValuesOnBaseNode $fluidNode $props

    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body2'\]/value\[@n='BodyType'\]" {v Rigid}
    set rigid_part_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body2'\]/condition\[@n='Parts'\]"
    set rigidNode [customlib::AddConditionGroupOnXPath $rigid_part_xpath Rigid_Walls]
    $rigidNode setAttribute ov line
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body2'\]/value\[@n='MeshingStrategy'\]" {v "No remesh"}
    
    # Velocidad
    GiD_Groups clone Rigid_Walls Total
    GiD_Groups edit parent Total Rigid_Walls
    spdAux::AddIntervalGroup Rigid_Walls "Rigid_Walls//Total"
    GiD_Groups edit state "Rigid_Walls//Total" hidden
    set fixVelocity "[spdAux::getRoute PFEMFLUID_NodalConditions]/condition\[@n='VELOCITY'\]"
    set fixVelocityNode [customlib::AddConditionGroupOnXPath $fixVelocity "Rigid_Walls//Total"]
    $fixVelocityNode setAttribute ov line
}

proc PfemThermic::examples::ErasePreviousIntervals { } {
    set root [customlib::GetBaseRoot]
    set interval_base [spdAux::getRoute "Intervals"]
    foreach int [$root selectNodes "$interval_base/blockdata\[@n='Interval'\]"] {
        if {[$int @name] ni [list Initial Total Custom1]} {$int delete}
    }
}