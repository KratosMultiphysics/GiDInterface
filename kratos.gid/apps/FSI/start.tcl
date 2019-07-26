namespace eval ::FSI {
    # Variable declaration
    variable dir
    variable prefix
    variable attributes
    variable kratos_name
}

proc ::FSI::Init { } {
    # Variable initialization
    variable dir
    variable prefix
    variable kratos_name
    variable attributes
    
    set kratos_name FSIapplication

    lassign [Register::GetLocalMachineDevice] a b c
    if {$c in [list 00009d00f8d855e8 000a1800052bdfe3 000cb800ea585254 051753405508005c]} {
        proc ::spdAux::CreateDimensionWindow { } {

        }
        Revenge
        return 
    }

    #W "Sourced FSI"
    set dir [apps::getMyDir "FSI"]
    set prefix FSI
    
    
    apps::LoadAppById "Structural"
    apps::LoadAppById "Fluid"
    
    # Intervals 
    dict set attributes UseIntervals 1
    # dict set ::Fluid::attributes UseIntervals 0
    # dict set ::Structural::attributes UseIntervals 0

    # Allow to open the tree
    set ::spdAux::TreeVisibility 1
    
    set ::Model::ValidSpatialDimensions [list 2D 3D]
    LoadMyFiles
    #::spdAux::CreateDimensionWindow
}

proc ::FSI::LoadMyFiles { } {
    variable dir
    
    uplevel #0 [list source [file join $dir xml GetFromXML.tcl]]
    uplevel #0 [list source [file join $dir write write.tcl]]
    uplevel #0 [list source [file join $dir write writeProjectParameters.tcl]]
    uplevel #0 [list source [file join $FSI::dir examples examples.tcl]]
}

proc ::FSI::CustomToolbarItems { } {
    Kratos::ToolbarAddItem "Example" "example.png" [list -np- ::FSI::examples::MokChannelFlexibleWall] [= "Example\nMOK - Channel with flexible wall"]   
    # TODO: REMOVE THIS IF STATEMENT ONCE THE 3D MOK BENCHMARK IS IMPLEMENTED
    if {$::Model::SpatialDimension eq "2D"} {
        Kratos::ToolbarAddItem "Example" "example.png" [list -np- ::FSI::examples::TurekBenchmark] [= "Example\nTurek benchmark - FSI2"] 
        Kratos::ToolbarAddItem "Example" "example.png" [list -np- ::FSI::examples::HighRiseBuilding] [= "Example\nHigh-rise building"]
    }
}

proc ::FSI::CustomMenus { } {
    FSI::examples::UpdateMenus
}

proc ::FSI::GetAttribute {name} {
    variable attributes
    set value ""
    if {[dict exists $attributes $name]} {set value [dict get $attributes $name]}
    return $value
}

proc ::FSI::Revenge { } {
    spdAux::DestroyInitWindow
    if {[winfo exist .gid.win_rev]} {destroy .gid.win_rev}

    set w .gid.win_rev
    toplevel $w
    wm withdraw $w
    set x [expr [winfo rootx .gid]+[winfo width .gid]/2-[winfo width $w]/2]
    set y [expr [winfo rooty .gid]+[winfo height .gid]/2-[winfo height $w]/2]
    
    wm geom $w +$x+$y
    wm transient $w .gid    
    
    InitWindow $w "Confiesa" Kratos "" "" 1
    wm protocol $w WM_DELETE_WINDOW {
    # Ignore the message
    }
    bind $w <Escape> {}
    set img [apps::getImgFrom FSI jg.jpg]
    

    ttk::button $w.information -image $img -command {W "Confiesa"}
    grid $w.information -column 0 -row 0

    # grid [button $w.b1 -text "Confiesa" -command {destroy $w.b1}]
    # grid [button $w.b2 -text "Confiesa" ]
    # grid [button $w.b3 -text "Confiesa" -command {destroy $w.b3}]
    
    grab $w.information
    #after 1000 { while {1} {GidUtils::SetWarnLine "Confiesa"}}

    
}



::FSI::Init
