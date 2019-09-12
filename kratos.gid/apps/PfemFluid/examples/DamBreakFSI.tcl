
proc ::PfemFluid::examples::DamBreakFSI {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
                if { $retval == "cancel" } { return }
    }

    Kratos::ResetModel
    DrawDamBreakFSIGeometry$::Model::SpatialDimension
    AssignGroupsDamBreakFSIGeometry$::Model::SpatialDimension
    # AssignDamBreakFSIMeshSizes$::Model::SpatialDimension
    TreeAssignationDamBreakFSI$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}


# Draw Geometry
proc PfemFluid::examples::DrawDamBreakFSIGeometry3D {args} {
    # To be implemented
}

proc PfemFluid::examples::DrawDamBreakFSIGeometry2D {args} {
    set layer PfemFluid
    GiD_Layers create $layer
    GiD_Layers edit to_use $layer

    ## Lines ##
    set points_fluid [list   0 0 0       0.146 0 0       0.146 0.292 0   0 0.292 0]
    foreach {x y z} $points_fluid {
        GiD_Geometry create point append $layer $x $y $z
    }
    set points_solid [list   0.304 0 0   0.304 0.08 0    0.292 0.08 0    0.292 0 0]
    foreach {x y z} $points_solid {
        GiD_Geometry create point append $layer $x $y $z
    }
    set points_rigid [list 0 0.596 0     0.596 0.596 0    0.596 0 0 ]
    foreach {x y z} $points_rigid {
        GiD_Geometry create point append $layer $x $y $z
    }

    set lines_fluid [list 1 2   2 3   3 4   4 1]
    foreach {p1 p2} $lines_fluid {
        GiD_Geometry create line append stline $layer $p1 $p2
    }

    set lines_solid [list 5 6   6 7   7 8   8 5]
    foreach {p1 p2} $lines_solid {
        GiD_Geometry create line append stline $layer $p1 $p2
    }

    set lines_rigid [list 4 9   9 10   10 11   11 5   8 2]
    foreach {p1 p2} $lines_rigid {
        GiD_Geometry create line append stline $layer $p1 $p2
    }
    
    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface 2 3 4 1 escape escape

    GiD_Process Mescape Geometry Create NurbsSurface 5 6 7 8 escape escape

}



# Group assign
proc PfemFluid::examples::AssignGroupsDamBreakFSIGeometry2D {args} {
    # Create the groups
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid surfaces 1

    GiD_Groups create Solid
    GiD_Groups edit color Solid "#26d1a8ff"
    GiD_EntitiesGroups assign Solid surfaces 2

    GiD_Groups create Interface
    GiD_Groups edit color Interface "#e0210fff"
    GiD_EntitiesGroups assign Interface lines {5 6 7}

    GiD_Groups create Rigid_Walls
    GiD_Groups edit color Rigid_Walls "#e0210fff"
    GiD_EntitiesGroups assign Rigid_Walls lines {1 4 9 10 11 12 13}

}
proc PfemFluid::examples::AssignGroupsDamBreakFSIGeometry3D {args} {
    # To be implemented
}

# Tree assign
proc PfemFluid::examples::TreeAssignationDamBreakFSI3D {args} {
    # To be implemented
}

proc PfemFluid::examples::TreeAssignationDamBreakFSI2D {args} {

    gid_groups_conds::setAttributesF [spdAux::getRoute PFEMFLUID_DomainType] {v FSI}

    # Fluid Parts
    set bodies_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body1'\]"
    
    gid_groups_conds::copyNode $bodies_xpath [spdAux::getRoute PFEMFLUID_Bodies]
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@n='Body'\]\[2\]" {name Body2}
    
    gid_groups_conds::copyNode $bodies_xpath [spdAux::getRoute PFEMFLUID_Bodies]
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@n='Body'\]\[3\]" {name Body3}

    gid_groups_conds::copyNode $bodies_xpath [spdAux::getRoute PFEMFLUID_Bodies]
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@n='Body'\]\[4\]" {name Body4}

    set fluid_part_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body1'\]/condition\[@n='Parts'\]"
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body1'\]/value\[@n='BodyType'\]" {v Fluid}
    set fluidNode [customlib::AddConditionGroupOnXPath $fluid_part_xpath Fluid]
    set props [list ConstitutiveLaw Newtonian DENSITY 1e3]
    foreach {prop val} $props {
        set propnode [$fluidNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Fluid $prop"
        }
    }

    # Solid Parts
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body2'\]/value\[@n='BodyType'\]" {v Solid}
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body2'\]/value\[@n='MeshingStrategy'\]" {v "No remesh"}
    set solid_part_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body2'\]/condition\[@n='Parts'\]"
    set solidNode [customlib::AddConditionGroupOnXPath $solid_part_xpath Solid]
    set props [list Element UpdatedLagrangianVSolidElement2D ConstitutiveLaw Hypoelastic DENSITY 2500 YOUNG_MODULUS 1000000 POISSON_RATIO 0]
    foreach {prop val} $props {
        set propnode [$solidNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Solid $prop"
        }
    }
   

    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body3'\]/value\[@n='BodyType'\]" {v Rigid}
    set interface_part_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body3'\]/condition\[@n='Parts'\]"
    set interfaceNode [customlib::AddConditionGroupOnXPath $interface_part_xpath Interface]
    $interfaceNode setAttribute ov line
   
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body4'\]/value\[@n='BodyType'\]" {v Rigid}
    set rigid_part_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body4'\]/condition\[@n='Parts'\]"
    set rigidNode [customlib::AddConditionGroupOnXPath $rigid_part_xpath Rigid_Walls]
    $rigidNode setAttribute ov line
    
    # Velocity
    GiD_Groups clone Rigid_Walls Total
    GiD_Groups edit parent Total Rigid_Walls
    spdAux::AddIntervalGroup Rigid_Walls "Rigid_Walls//Total"
    GiD_Groups edit state "Rigid_Walls//Total" hidden
    set fixVelocity "[spdAux::getRoute PFEMFLUID_NodalConditions]/condition\[@n='VELOCITY'\]"
    set fixVelocityNode [customlib::AddConditionGroupOnXPath $fixVelocity "Rigid_Walls//Total"]
    $fixVelocityNode setAttribute ov line


}

proc PfemFluid::examples::ErasePreviousIntervals { } {
    set root [customlib::GetBaseRoot]
    set interval_base [spdAux::getRoute "Intervals"]
    foreach int [$root selectNodes "$interval_base/blockdata\[@n='Interval'\]"] {
        if {[$int @name] ni [list Initial Total Custom1]} {$int delete}
    }
}
