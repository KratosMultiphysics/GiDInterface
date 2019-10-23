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

    set ::Model::ValidSpatialDimensions [list 2D 3D]

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

proc ::DEM::BeforeMeshGeneration {elementsize} {
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute DEMParts]/group"
    foreach group [$root selectNodes $xp1] {
        set groupid [$group @n]
        set advanced_meshing_features [write::getValueByNode [$group selectNodes "./value\[@n='AdvancedMeshingFeatures'\]"]]
        if {![write::isBooleanTrue $advanced_meshing_features]} {
            if {$::Model::SpatialDimension eq "3D"} {
                foreach volume [GiD_EntitiesGroups get $groupid volumes] {
                    GiD_Process Mescape Meshing ElemType Sphere Volumes $volume escape escape
                }
            } {
                foreach surfs [GiD_EntitiesGroups get $groupid surfaces] {
                    GiD_Process Mescape Meshing ElemType Circle Surfaces $surfs escape escape
                }
            }
        }
    }
    if {[catch {DEM::write::BeforeMeshGenerationUtils $elementsize} err]} {
        WarnWinText $err
    }
}


proc ::DEM::AfterMeshGeneration { fail } {

    set root [customlib::GetBaseRoot]
    # Separar 2d de 3d
    set xp1 "[spdAux::getRoute "DEMConditions"]/condition\[@n ='DEM-FEM-Wall'\]/group"
    foreach group [$root selectNodes $xp1] {
        set groupid [$group @n]
        GiD_EntitiesGroups unassign $groupid -also_lower_entities elements [GiD_EntitiesGroups get $groupid elements -element_type sphere]
    }
    set xp2 "[spdAux::getRoute "DEMConditions"]/condition\[@n ='DEM-FEM-Wall2D'\]/group"
    foreach group [$root selectNodes $xp2] {
        set groupid [$group @n]
        GiD_EntitiesGroups unassign $groupid -also_lower_entities elements [GiD_EntitiesGroups get $groupid elements -element_type circle]
    }

    if [GiD_Groups exists SKIN_SPHERE_DO_NOT_DELETE] {
        GiD_Mesh delete element [GiD_EntitiesGroups get SKIN_SPHERE_DO_NOT_DELETE elements -element_type quadrilateral]
        GiD_EntitiesGroups unassign SKIN_SPHERE_DO_NOT_DELETE elements [GiD_EntitiesGroups get SKIN_SPHERE_DO_NOT_DELETE elements -element_type linear]
        GiD_EntitiesGroups unassign SKIN_SPHERE_DO_NOT_DELETE elements [GiD_EntitiesGroups get SKIN_SPHERE_DO_NOT_DELETE elements -element_type triangle]
        GiD_EntitiesGroups unassign SKIN_SPHERE_DO_NOT_DELETE elements [GiD_EntitiesGroups get SKIN_SPHERE_DO_NOT_DELETE elements -element_type quadrilateral]
    }

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
