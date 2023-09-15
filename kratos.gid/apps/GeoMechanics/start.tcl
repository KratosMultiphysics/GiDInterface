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
    Kratos::ToolbarAddItem "NextStage" "next.png" [list -np- ::GeoMechanics::NextStage] [= "Next stage"]
    Kratos::ToolbarAddItem "SpacerGeoMechanics1" "" "" ""
    Kratos::ToolbarAddItem "WaterLevel" "wave.png" [list -np- ::GeoMechanics::PhreaticButton] [= "Phreatic line"]
    Kratos::ToolbarAddItem "WaterLevelDelete" "wave_cross.png" [list -np- ::GeoMechanics::DeletePhreaticButton] [= "Delete phreatic line"]
    Kratos::ToolbarAddItem "callPython" "python.png" [list -np- ::GeoMechanics::PythonButton] [= "Python click"]
    Kratos::ToolbarAddItem "callPython" "python.png" [list -np- ::GeoMechanics::PythonButtonImportPlaxis] [= "Import Plaxis model"]
}

proc ::GeoMechanics::PrevStage {  } {
    variable curr_stage
    variable state_phreatic_line
    set prev_state_phreatic_line $state_phreatic_line
    
    set stages [::GeoMechanics::xml::GetStages]
    # try to end the line creation or displaying
    catch {::GeoMechanics::EndCreatePhreaticLine}

    incr curr_stage -1
    if {$curr_stage < 0} {
        set curr_stage 0
    }
    ::GeoMechanics::xml::CloseStages
    ::GeoMechanics::xml::OpenStage [[lindex $stages $curr_stage] @name]
    spdAux::RequestRefresh
    ::GeoMechanics::WarnActiveStage
    if {$prev_state_phreatic_line eq "displaying"} {::GeoMechanics::DisplayPhreaticLine}
}

proc ::GeoMechanics::NextStage {  } {
    variable curr_stage
    variable state_phreatic_line
    set prev_state_phreatic_line $state_phreatic_line
    
    # try to end the line creation or displaying
    catch {::GeoMechanics::EndCreatePhreaticLine}

    set stages [::GeoMechanics::xml::GetStages]
    incr curr_stage 1
    set max [llength [::GeoMechanics::xml::GetStages]]
    if {$curr_stage >= $max} {
        set curr_stage [expr $max - 1]
    }
    ::GeoMechanics::xml::CloseStages
    ::GeoMechanics::xml::OpenStage [[lindex $stages $curr_stage] @name]
    spdAux::RequestRefresh
    ::GeoMechanics::WarnActiveStage

    if {$prev_state_phreatic_line eq "displaying"} {::GeoMechanics::DisplayPhreaticLine}
}

proc ::GeoMechanics::DrawStage { } {
    variable curr_stage
        
    set stages [::GeoMechanics::xml::GetStages]
    ::GeoMechanics::xml::CloseStages
    ::GeoMechanics::xml::DrawStage [[lindex $stages $curr_stage] @name]
    ::GeoMechanics::WarnActiveStage
}

# Print the current stage
proc ::GeoMechanics::WarnActiveStage { } {
    variable curr_stage
    set stages [::GeoMechanics::xml::GetStages]
    set stage [lindex $stages $curr_stage]
    ::GidUtils::SetWarnLine "Current active stage: [$stage @name]"
}