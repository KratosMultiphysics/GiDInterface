
proc ::GeoMechanics::PhreaticButton { } {
    variable curr_stage
    variable state_phreatic_line

    # Get the current active stage
    set stages [::GeoMechanics::xml::GetStages]
    set stage [lindex $stages $curr_stage]

    # If the state is none, the user clicked because he wants to create a phreatic line
    if {$state_phreatic_line eq "none"} {

        # Get the current stage phreatic points
        set current_phreatic_points [::GeoMechanics::xml::GetPhreaticPoints $stage]
        # If there are no phreatic points, create a new line
        if {[llength $current_phreatic_points] eq 0} {
            set state_phreatic_line creating
            ::GeoMechanics::CreatePhreaticLine $stage
        } else {
            # If there are phreatic points, display it somehow
            ::GeoMechanics::DisplayPhreaticLine
        }
    } elseif {$state_phreatic_line in [list "creating" "displaying"]} {
        ::GeoMechanics::EndCreatePhreaticLine
    }
}

proc ::GeoMechanics::DeletePhreaticButton { } {
    variable curr_stage

    # Get the current active stage
    set stages [::GeoMechanics::xml::GetStages]
    set stage [lindex $stages $curr_stage]

    ::GeoMechanics::xml::DeletePhreaticPoints $stage
    ::GeoMechanics::EndCreatePhreaticLine
}

proc ::GeoMechanics::CreatePhreaticLine {stage} {
    variable state_phreatic_line
    variable creating_phreatic_previous_layer
    set creating_phreatic_previous_layer [GiD_Layers get to_use]
    set stage_name [$stage @name]
    if {[GiD_Layers exists PhreaticLine_$stage_name]} {
        GiD_Layers delete PhreaticLine_$stage_name
    }
    GiD_Layers create PhreaticLine_$stage_name
    GiD_Layers edit to_use PhreaticLine_$stage_name
    GiD_RegisterEvent GiD_Event_AfterCreateLine ::GeoMechanics::AfterCreatePhreaticLine PROBLEMTYPE Kratos
    GiD_Process MEscape Mescape Geometry Create Line 
}

proc ::GeoMechanics::AfterCreatePhreaticLine { line } {
    variable curr_stage 
    variable state_phreatic_line
    if {$state_phreatic_line eq "creating"} {
    
        # Get the current active stage
        set stages [::GeoMechanics::xml::GetStages]
        set stage [lindex $stages $curr_stage]
        
        # Get line points
        lassign [GiD_Geometry get line $line] a b p1 p2
        # Get point coordinates
        lassign [GiD_Geometry get point $p1] a x1 y1 z1
        lassign [GiD_Geometry get point $p2] a x2 y2 z2
        # Add coordinates to xml
        if {[llength [::GeoMechanics::xml::GetPhreaticPoints $stage]] == 0} {
            ::GeoMechanics::xml::AddPhreaticPoint $stage $x1 $y1 $z1
        }
        ::GeoMechanics::xml::AddPhreaticPoint $stage $x2 $y2 $z2
    } else {

    }

    # TODO: at this moment we only allow 2 points, in the future, will see
    set num [llength [::GeoMechanics::xml::GetPhreaticPoints $stage]]
    if {$num >= 2} {
        ::GeoMechanics::EndCreatePhreaticLine
        ::GeoMechanics::DisplayPhreaticLine
    }
}
proc ::GeoMechanics::EndCreatePhreaticLine { } {
    variable state_phreatic_line
    set state_phreatic_line none

    # Delete the phreatic line
    ::GeoMechanics::DeleteVisiblePhreaticLine

    # Delete the lines from the variable list
    variable creating_phreatic_previous_layer
    GiD_Layers edit to_use $creating_phreatic_previous_layer
    catch {GiD_UnRegisterEvent GiD_Event_AfterCreateLine ::GeoMechanics::AfterCreatePhreaticLine PROBLEMTYPE Kratos}
    spdAux::RequestRefresh
}

proc ::GeoMechanics::DeleteVisiblePhreaticLine { } {
    variable curr_stage

    # Get the current active stage
    set stages [::GeoMechanics::xml::GetStages]
    set stage [lindex $stages $curr_stage]

    set stage_name [$stage @name]
    # Delete the lines from the variable list
    if {[GiD_Layers exists PhreaticLine_$stage_name]} {GiD_Layers delete PhreaticLine_$stage_name}
    GiD_Process MEscape 'Redraw escape
}

proc ::GeoMechanics::DisplayPhreaticLine {} {
    variable state_phreatic_line
    set state_phreatic_line displaying
    
    # Get the current active stage
    variable curr_stage
    set stages [::GeoMechanics::xml::GetStages]
    set stage [lindex $stages $curr_stage]

    set stage_name [$stage @name]
    set layer_name PhreaticLine_$stage_name
    if {[GiD_Layers exists $layer_name]} {
        GiD_Layers delete $layer_name
    }
    GiD_Layers create $layer_name
    # GiD_Layers edit to_use $layer_name
    set current_phreatic_points [::GeoMechanics::xml::GetPhreaticPoints $stage]
    set point_list [list ]
    foreach point $current_phreatic_points {
        lassign $point x y
        lappend point_list [GiD_Geometry -v2 create point append $layer_name $x $y 0.0]
    }
    # set coordinates "" 
    set ini [lindex $point_list 0]
    foreach end [lrange $point_list 1 end] {
        GiD_Geometry -v2 create line append stline $layer_name $ini $end
        set ini $end
    }
    GiD_Process MEscape 'Redraw escape
}