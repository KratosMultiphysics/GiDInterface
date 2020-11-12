namespace eval ::ShallowWater {
    # Variable declaration
    variable dir
    variable prefix
    variable attributes
    variable app_id
    variable kratos_name
}

proc ::ShallowWater::Init { } {
    # Variable initialization
    variable dir
    variable prefix
    variable attributes
    variable kratos_name
    set app_id "ShallowWater"
    set kratos_name "ShallowWaterApplication"

#    apps::LoadAppById "Fluid"

    set dir [apps::getMyDir "ShallowWater"]
    set attributes [dict create]
    set prefix SW

    spdAux::SetSpatialDimmension "2D"

    # Allow to open the tree
    set ::spdAux::TreeVisibility 1

    dict set attributes UseIntervals 0

    LoadMyFiles

    Kratos::AddRestoreVar "::GidPriv(DuplicateEntities)"
    set ::GidPriv(DuplicateEntities) 1
}

proc ::ShallowWater::LoadMyFiles { } {
    variable dir

    uplevel #0 [list source [file join $dir xml XmlController.tcl]]
#    uplevel #0 [list source [file join $dir write write.tcl]]
#    uplevel #0 [list source [file join $dir write writeProjectParameters.tcl]]
}

proc ::ShallowWater::GetAttribute {name} {
    variable attributes
    set value ""
    catch {set value [dict get $attributes $name]}
    return $value
}

proc ::ShallowWater::CustomToolbarItems { } {
#    Kratos::ToolbarAddItem "Example" "example.png" [list -np- ::ShallowWater::examples::DamBreak] [= "Example\nDamBreak"]
}

::ShallowWater::Init
