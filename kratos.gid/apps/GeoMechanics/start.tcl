namespace eval ::GeoMechanics {
    Kratos::AddNamespace [namespace current]
    
    # Variable declaration
    variable _app
    variable dir
    variable curr_stage

    proc GetAttribute {name} {variable _app; return [$_app getProperty $name]}
    proc GetUniqueName {name} {variable _app; return [$_app getUniqueName $name]}
    proc GetWriteProperty {name} {variable _app; return [$_app getWriteProperty $name]}
}

proc ::GeoMechanics::Init { app } {
    # Variable initialization
    variable _app
    variable dir
    variable curr_stage

    set _app $app
    set dir [apps::getMyDir "GeoMechanics"]
    
    # XML init event
    ::GeoMechanics::xml::Init
    ::GeoMechanics::write::Init
    ::GeoMechanics::toolbar::Init

    
    set curr_stage 0
}

proc ::GeoMechanics::CustomToolbarItems { } {
    variable dir

    Kratos::ToolbarAddItem "BackStage" "back.png" [list -np- ::GeoMechanics::PrevStage] [= "Previous stage"]
    Kratos::ToolbarAddItem "DrawStage" "pie.png" [list -np- ::GeoMechanics::DrawStage] [= "Draw stage"]
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