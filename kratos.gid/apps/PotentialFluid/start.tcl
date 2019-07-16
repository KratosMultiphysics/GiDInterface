namespace eval ::PotentialFluid {
    # Variable declaration
    variable dir
    variable prefix
    variable attributes
    variable app_id
    variable kratos_name
}

proc ::PotentialFluid::Init { } {
    # Variable initialization
    variable dir
    variable prefix
    variable attributes
    variable kratos_name
    set app_id "PotentialFluid"
    set kratos_name "CompressiblePotentialFlowApplication"

    apps::LoadAppById "Fluid"

    set dir [apps::getMyDir "PotentialFluid"]
    set attributes [dict create]

    set prefix PTFL
    set ::Model::ValidSpatialDimensions [list 2D 3D]

    # Allow to open the tree
    set ::spdAux::TreeVisibility 1

    dict set attributes UseIntervals 0

    LoadMyFiles
    Kratos::AddRestoreVar "::GidPriv(DuplicateEntities)"
    set ::GidPriv(DuplicateEntities) 1

    # TODO: activate this as soon as the 3D wake detection is working
    #::spdAux::CreateDimensionWindow
}

proc ::PotentialFluid::LoadMyFiles { } {
    variable dir

    uplevel #0 [list source [file join $dir examples examples.tcl]]
    uplevel #0 [list source [file join $dir xml GetFromXML.tcl]]
    uplevel #0 [list source [file join $dir write write.tcl]]
    uplevel #0 [list source [file join $dir write writeProjectParameters.tcl]]
}

proc ::PotentialFluid::GetAttribute {name} {
    variable attributes
    set value ""
    catch {set value [dict get $attributes $name]}
    return $value
}

proc ::PotentialFluid::CustomToolbarItems { } {
    variable dir
    Kratos::ToolbarAddItem "Example" "example.png" [list -np- ::PotentialFluid::examples::NACA0012] [= "Example\nNACA 0012"]
}


::PotentialFluid::Init
