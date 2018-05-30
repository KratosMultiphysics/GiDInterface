namespace eval ::Structural {
    # Variable declaration
    variable dir
    variable attributes
    variable kratos_name
}

proc ::Structural::Init { } {
    # Variable initialization
    variable dir
    variable attributes
    variable kratos_name
    
    set dir [apps::getMyDir "Structural"]
    set attributes [dict create]
    
    # Allow to open the tree
    set ::spdAux::TreeVisibility 1
    
    # Intervals 
    dict set attributes UseIntervals 1
    if {$::Kratos::kratos_private(DevMode) eq "dev"} {dict set attributes UseIntervals 1}
    
    set kratos_name StructuralMechanicsApplication
    
    LoadMyFiles
}

proc ::Structural::LoadMyFiles { } {
    variable dir
    
    uplevel #0 [list source [file join $dir examples examples.tcl]]
    uplevel #0 [list source [file join $dir xml GetFromXML.tcl]]
    uplevel #0 [list source [file join $dir write write.tcl]]
    uplevel #0 [list source [file join $dir write writeProjectParameters.tcl]]
    uplevel #0 [list source [file join $dir postprocess formfinding.tcl]]
}

proc ::Structural::CustomToolbarItems { } {
    Kratos::ToolbarAddItem "Example" "example.png" [list -np- ::Structural::examples::TrussCantilever] [= "Example\nTruss cantilever"]   
}

proc ::Structural::CustomMenus { } {
    Structural::examples::UpdateMenus

    GiDMenu::InsertOption "Kratos" [list "---"] 8 PRE "" "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "Formfinding - Update geometry" ] end POST [list ::Structural::Formfinding::UpdateGeometry] "" "" insert =
    GiDMenu::UpdateMenus
}

proc ::Structural::GetAttribute {name} {
    variable attributes
    set value ""
    if {[dict exists $attributes $name]} {set value [dict get $attributes $name]}
    return $value
}

proc ::Structural::BeforeMeshGeneration { size } { 
    foreach group [GiD_Groups list] {
        GiD_AssignData condition relation_line_geo_mesh Lines {0} [GiD_EntitiesGroups get $group lines]
    }
}

::Structural::Init
