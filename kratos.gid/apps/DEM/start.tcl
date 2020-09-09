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

    GiD_Set CalcWithoutMesh 1

    LoadMyFiles
}

proc ::DEM::LoadMyFiles { } {
    variable dir

    uplevel #0 [list source [file join $dir xml XmlController.tcl]]
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
    if {$::Model::SpatialDimension eq "3D"} {
        Kratos::ToolbarAddItem "Example3D" [file join $dir images drop.png] [list -np- ::DEM::examples::SpheresDrop] [= "Example3D\nSpheres drop"]
    }
    if {$::Model::SpatialDimension eq "2D"} {
        Kratos::ToolbarAddItem "Example2D" [file join $dir images drop.png] [list -np- ::DEM::examples::CirclesDrop] [= "Example2D\nCircles drop"]
    }
}

proc ::DEM::CustomMenus { } {
    DEM::examples::UpdateMenus
}

proc ::DEM::BeforeMeshGeneration {elementsize} {
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute DEMParts]/group"
    foreach group [concat [$root selectNodes $xp1] [DEM::write::GetDEMGroupsCustomSubmodelpart]] {
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
        } else {
            if {$::Model::SpatialDimension eq "3D"} {
                foreach volume [GiD_EntitiesGroups get $groupid volumes] {
                    GiD_Process Mescape Meshing ElemType Default Volumes $volume escape escape
                }
            } {
                foreach surfs [GiD_EntitiesGroups get $groupid surfaces] {
                    GiD_Process Mescape Meshing ElemType Default Surfaces $surfs escape escape
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

    set xp0 "[spdAux::getRoute "DEMConditions"]/condition\[@n ='DEM-VelocityIC'\]/group"
    foreach group [$root selectNodes $xp0] {
        set groupid [$group @n]
        GiD_EntitiesGroups unassign $groupid -also_lower_entities elements [GiD_EntitiesGroups get $groupid elements -element_type triangle]
    }

    set xp0 "[spdAux::getRoute "DEMConditions"]/condition\[@n ='DEM-VelocityIC2D'\]/group"
    foreach group [$root selectNodes $xp0] {
        set groupid [$group @n]
        GiD_EntitiesGroups unassign $groupid -also_lower_entities elements [GiD_EntitiesGroups get $groupid elements -element_type linear]
    }

    set xp0 "[spdAux::getRoute "DEMConditions"]/condition\[@n ='DEM-VelocityBC'\]/group"
    foreach group [$root selectNodes $xp0] {
        set groupid [$group @n]
        GiD_EntitiesGroups unassign $groupid -also_lower_entities elements [GiD_EntitiesGroups get $groupid elements -element_type triangle]
    }

    set xp0 "[spdAux::getRoute "DEMConditions"]/condition\[@n ='DEM-VelocityBC2D'\]/group"
    foreach group [$root selectNodes $xp0] {
        set groupid [$group @n]
        GiD_EntitiesGroups unassign $groupid -also_lower_entities elements [GiD_EntitiesGroups get $groupid elements -element_type linear]
    }

    set xp0 "[spdAux::getRoute "DEMConditions"]/condition\[@n ='DEM-GraphCondition'\]/group"
    foreach group [$root selectNodes $xp0] {
        set groupid [$group @n]
        GiD_EntitiesGroups unassign $groupid -also_lower_entities elements [GiD_EntitiesGroups get $groupid elements -element_type triangle]
    }

    set xp0 "[spdAux::getRoute "DEMConditions"]/condition\[@n ='DEM-GraphCondition2D'\]/group"
    foreach group [$root selectNodes $xp0] {
        set groupid [$group @n]
        GiD_EntitiesGroups unassign $groupid -also_lower_entities elements [GiD_EntitiesGroups get $groupid elements -element_type linear]
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

proc ::DEM::AfterSaveModel { filespd } {

    # GiD bug detected in versions prev to 15.0.1
    # Spheres disapear in groups after load. Fixing it by removing the limitation in the prj file.
    # GiD Team -> @jginternationa and @escolano
    # Fixed in any 15.1.X (developer) and 15.0.1 and later (official)
    if {[GidUtils::VersionCmp "15.0.0"] <= 0} {
        ::DEM::PatchMissingSpheresInGroup $filespd
    }
}

proc ::DEM::PatchMissingSpheresInGroup {filespd} {
    set prj_file [file join [file dirname $filespd] [file rootname $filespd].prj]
    if {[file exists $prj_file]} {
        dom parse [tDOM::xmlReadFile $prj_file] doc

        set grlist [$doc getElementsByTagName group]
        foreach group $grlist {
            if {[$group hasAttribute allowed_element_types]} {
                $group removeAttribute allowed_element_types
            }
            if {[$group hasAttribute allowed_types]} {
                $group removeAttribute allowed_types
            }
        }
        set fp [open $prj_file w]
        puts $fp [$doc asXML]
        close $fp
    }
}


::DEM::Init
