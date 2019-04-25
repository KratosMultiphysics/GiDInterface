namespace eval ::DEM {
    # Variable declaration
    variable dir
    variable attributes
    variable kratos_name
}

proc ::DEM::Init { } {
    # Variable initialization
    variable dir
    variable attributes
    variable kratos_name

    set dir [apps::getMyDir "DEM"]
    set attributes [dict create]

    # Allow to open the tree
    set ::spdAux::TreeVisibility 1
    dict set attributes UseIntervals 1

    set kratos_name DEMApplication

    set ::Model::ValidSpatialDimensions [list 3D]
    spdAux::SetSpatialDimmension "3D"

    LoadMyFiles
}

proc ::DEM::LoadMyFiles { } {
    variable dir

    uplevel #0 [list source [file join $dir xml GetFromXML.tcl]]
    uplevel #0 [list source [file join $dir write write.tcl]]
    uplevel #0 [list source [file join $dir write writeMDPA_Parts.tcl]]
    uplevel #0 [list source [file join $dir write writeMDPA_Inlet.tcl]]
    uplevel #0 [list source [file join $dir write writeMDPA_Walls.tcl]]
    uplevel #0 [list source [file join $dir write writeMDPA_Clusters.tcl]]
    uplevel #0 [list source [file join $dir write writeProjectParameters.tcl]]
    uplevel #0 [list source [file join $dir write write_utils.tcl]]
    uplevel #0 [list source [file join $dir examples examples.tcl]]
}

proc ::DEM::GetAttribute {name} {
    variable attributes
    set value ""
    if {[dict exists $attributes $name]} {set value [dict get $attributes $name]}
    return $value
}

proc ::DEM::CustomToolbarItems { } {
    variable dir
    Kratos::ToolbarAddItem "Example" [file join $dir images drop.png] [list -np- ::DEM::examples::SpheresDrop] [= "Example\nSpheres drop"]
}

proc ::DEM::CustomMenus { } {
    DEM::examples::UpdateMenus
}

proc ::DEM::BeforeMeshGeneration_working {elementsize} {
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute DEMParts]/group"
    foreach group [$root selectNodes $xp1] {
        set groupid [$group @n]
        set advanced_meshing_features [write::getValueByNode [$group selectNodes "./value\[@n='AdvancedMeshingFeatures'\]"]]
		if {![write::isBooleanTrue $advanced_meshing_features]} {
            foreach volume [GiD_EntitiesGroups get $groupid volumes] {
            GiD_Process Mescape Meshing ElemType Sphere Volumes $volume escape escape
            }
        }
    }
}

proc ::DEM::BeforeMeshGeneration {elementsize} {
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute DEMParts]/group"
    foreach group [$root selectNodes $xp1] {
        set groupid [$group @n]
        set advanced_meshing_features [write::getValueByNode [$group selectNodes "./value\[@n='AdvancedMeshingFeatures'\]"]]
		if {![write::isBooleanTrue $advanced_meshing_features]} {
            foreach volume [GiD_EntitiesGroups get $groupid volumes] {
            GiD_Process Mescape Meshing ElemType Sphere Volumes $volume escape escape
            }
        }
    }
    #wkcf::Preprocess   what is this???
    if {[catch {DEM::write::BeforeMeshGenerationUtils $elementsize} err]} {
	WarnWinText $err
    }
}


proc ::DEM::AfterMeshGeneration { fail } {
    # set without_window [GidUtils::AreWindowsDisabled];
    # if {!$without_window} {
	# GidUtils::DisableGraphics
    # }
    if {[catch {::DEM::write::Elements_Substitution} msg]} {
      W "::DEM::write::Elements_Substitution!. $msg"
    }
    # if {!$without_window} {
	# GidUtils::EnableGraphics
    # }
}



::DEM::Init
