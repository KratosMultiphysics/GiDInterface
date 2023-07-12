namespace eval ::GeoMechanics {
    Kratos::AddNamespace [namespace current]
    
    # Variable declaration
    variable _app
    variable dir
    variable curr_stage

    variable state_phreatic_line
    variable creating_phreatic_lines
    variable creating_phreatic_previous_layer

    proc GetAttribute {name} {variable _app; return [$_app getProperty $name]}
    proc GetUniqueName {name} {variable _app; return [$_app getUniqueName $name]}
    proc GetWriteProperty {name} {variable _app; return [$_app getWriteProperty $name]}
}

proc ::GeoMechanics::Init { app } {
    # Variable initialization
    variable _app
    variable dir
    variable curr_stage
    variable state_phreatic_line

    set _app $app
    set dir [apps::getMyDir "GeoMechanics"]
    
    # XML init event
    ::GeoMechanics::xml::Init
    ::GeoMechanics::write::Init
    ::GeoMechanics::toolbar::Init

    
    set curr_stage 0
    set state_phreatic_line none
}

proc ::GeoMechanics::CustomToolbarItems { } {
    variable dir

    Kratos::ToolbarAddItem "BackStage" "back.png" [list -np- ::GeoMechanics::PrevStage] [= "Previous stage"]
    Kratos::ToolbarAddItem "DrawStage" "pie.png" [list -np- ::GeoMechanics::DrawStage] [= "Draw stage"]
    Kratos::ToolbarAddItem "WaterLevel" "wave.png" [list -np- ::GeoMechanics::PhreaticButton] [= "Phreatic line"]
    Kratos::ToolbarAddItem "NextStage" "next.png" [list -np- ::GeoMechanics::NextStage] [= "Next stage"]
    Kratos::ToolbarAddItem "SpacerGeoMechanics1" "" "" ""
    Kratos::ToolbarAddItem "callPython" "python.png" [list -np- ::GeoMechanics::PythonButton] [= "Python click"]
}

proc ::GeoMechanics::PrevStage {  } {
    variable curr_stage
    set stages [::GeoMechanics::xml::GetStages]
    incr curr_stage -1
    if {$curr_stage < 0} {
        set curr_stage 0
    }
    ::GeoMechanics::xml::CloseStages
    ::GeoMechanics::xml::OpenStage [[lindex $stages $curr_stage] @name]
    spdAux::RequestRefresh
}

proc ::GeoMechanics::NextStage {  } {
    variable curr_stage
    set stages [::GeoMechanics::xml::GetStages]
    incr curr_stage 1
    set max [llength [::GeoMechanics::xml::GetStages]]
    if {$curr_stage >= $max} {
        set curr_stage [expr $max - 1]
    }
    ::GeoMechanics::xml::CloseStages
    ::GeoMechanics::xml::OpenStage [[lindex $stages $curr_stage] @name]
    spdAux::RequestRefresh
}

proc ::GeoMechanics::DrawStage { } {
    variable curr_stage
    
    set stages [::GeoMechanics::xml::GetStages]
    ::GeoMechanics::xml::CloseStages
    ::GeoMechanics::xml::DrawStage [[lindex $stages $curr_stage] @name]

}

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
            set state_phreatic_line displaying
            ::GeoMechanics::DisplayPhreaticLine $stage
        }
    } elseif {$state_phreatic_line in [list "creating" "displaying"]} {
        set state_phreatic_line none
        # Delete the phreatic line
        ::GeoMechanics::DeletePhreaticLine $stage
        catch {::GeoMechanics::EndCreatePhreaticLine}
    }
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
}
proc ::GeoMechanics::EndCreatePhreaticLine { } {

    # Delete the lines from the variable list
    variable creating_phreatic_previous_layer
    GiD_Layers edit to_use $creating_phreatic_previous_layer
    GiD_UnRegisterEvent GiD_Event_AfterCreateLine ::GeoMechanics::AfterCreatePhreaticLine PROBLEMTYPE Kratos
    spdAux::RequestRefresh
}

proc ::GeoMechanics::DeletePhreaticLine { stage } {
    variable state_phreatic_line
    variable creating_phreatic_lines


    set stage_name [$stage @name]
    # Delete the lines from the variable list
    GiD_Layers delete PhreaticLine_$stage_name
    GiD_Process MEscape 'Redraw escape
}

proc ::GeoMechanics::DisplayPhreaticLine {stage} {

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