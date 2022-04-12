namespace eval ::DEM {
    Kratos::AddNamespace [namespace current]

    # Variable declaration
    variable dir
    variable _app

    proc GetAttribute {name} {variable _app; return [$_app getProperty $name]}
    proc GetUniqueName {name} {variable _app; return [$_app getUniqueName $name]}
    proc GetWriteProperty {name} {variable _app; return [$_app getWriteProperty $name]}
}

proc ::DEM::Init { app } {
    # Variable initialization
    variable _app
    variable dir

    set _app $app
    set dir [apps::getMyDir "DEM"]

    GiD_Set CalcWithoutMesh 1

    ::DEM::xml::Init
    ::DEM::write::Init
}

proc ::DEM::CustomToolbarItems { } {
    variable dir

    Kratos::ToolbarAddItem "MaterialRelations" "material-relation.png" [list -np- DEM::xml::ShowMaterialRelationWindow] [= "Material relations"]
}

proc ::DEM::BeforeMeshGeneration {elementsize} {
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute DEMParts]/condition\[@n = 'Parts_DEM'\]/group"
    foreach group [concat [$root selectNodes $xp1] [DEM::write::GetDEMGroupsCustomSubmodelpart]] {
        set groupid [$group @n]
        set advanced_meshing_features [write::getValueByNode [$group selectNodes "./value\[@n='AdvancedMeshingFeatures'\]"]]
        if {![write::isBooleanTrue $advanced_meshing_features]} {
            # Usually, the DEMParts will be marked as not AdvancedMeshingFeatures, composed as volumes and meshed as spheres.
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
            # If a DEMPart is created as FEM and AdvancedMeshingFeatures=true, initially meshed as fem
            # it will later access Elements_Substitution to transform those elements into spheres (in AfterMeshGeneration)
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

    #LINEAR VELOCITY
    # should be: unassign all spheres from all the groups in FEM conditions .
    set xp "[spdAux::getRoute DEMParts]/condition\[@n = 'FEMVelocity'\]/group"
    foreach group [$root selectNodes $xp] {
        set groupid [$group @n]
        GiD_EntitiesGroups unassign $groupid -also_lower_entities elements [GiD_EntitiesGroups get $groupid elements -element_type sphere]
    }

    ## unassign all circles from all the groups in FEM conditions 2D.
    set xp "[spdAux::getRoute DEMParts]/condition\[@n = 'FEMVelocity2D'\]/group"
    foreach group [$root selectNodes $xp] {
        set groupid [$group @n]
        GiD_EntitiesGroups unassign $groupid -also_lower_entities elements [GiD_EntitiesGroups get $groupid elements -element_type circle]
    }

    ## unassign all triangles from all the groups in DEM conditions 3D.
    set xp "[spdAux::getRoute DEMParts]/condition\[@n = 'DEMVelocity'\]/group"
    foreach group [$root selectNodes $xp] {
        set groupid [$group @n]
        GiD_EntitiesGroups unassign $groupid -also_lower_entities elements [GiD_EntitiesGroups get $groupid elements -element_type triangle]
    }

    ## unassign all lines from all the groups in DEM conditions 2D.
    set xp "[spdAux::getRoute DEMParts]/condition\[@n = 'DEMVelocity2D'\]/group"
    foreach group [$root selectNodes $xp] {
        set groupid [$group @n]
        GiD_EntitiesGroups unassign $groupid -also_lower_entities elements [GiD_EntitiesGroups get $groupid elements -element_type linear]
    }


    # ANGULAR VELOCITY
    # should be: unassign all spheres from all the groups in FEM conditions .
    set xp "[spdAux::getRoute DEMParts]/condition\[@n = 'FEMAngular'\]/group"
    foreach group [$root selectNodes $xp] {
        set groupid [$group @n]
        GiD_EntitiesGroups unassign $groupid -also_lower_entities elements [GiD_EntitiesGroups get $groupid elements -element_type sphere]
    }

    ## unassign all circles from all the groups in FEM conditions 2D.
    set xp "[spdAux::getRoute DEMParts]/condition\[@n = 'FEMAngular2D'\]/group"
    foreach group [$root selectNodes $xp] {
        set groupid [$group @n]
        GiD_EntitiesGroups unassign $groupid -also_lower_entities elements [GiD_EntitiesGroups get $groupid elements -element_type circle]
    }

    ## unassign all triangles from all the groups in DEM conditions 3D.
    set xp "[spdAux::getRoute DEMParts]/condition\[@n = 'DEMAngular'\]/group"
    foreach group [$root selectNodes $xp] {
        set groupid [$group @n]
        GiD_EntitiesGroups unassign $groupid -also_lower_entities elements [GiD_EntitiesGroups get $groupid elements -element_type triangle]
    }

    ## unassign all lines from all the groups in DEM conditions 2D.
    set xp "[spdAux::getRoute DEMParts]/condition\[@n = 'DEMAngular2D'\]/group"
    foreach group [$root selectNodes $xp] {
        set groupid [$group @n]
        GiD_EntitiesGroups unassign $groupid -also_lower_entities elements [GiD_EntitiesGroups get $groupid elements -element_type linear]
    }


    # FORCE
    # should be: unassign all spheres from all the groups in FEM conditions .
    set xp "[spdAux::getRoute DEMParts]/condition\[@n = 'FEMForce'\]/group"
    foreach group [$root selectNodes $xp] {
        set groupid [$group @n]
        GiD_EntitiesGroups unassign $groupid -also_lower_entities elements [GiD_EntitiesGroups get $groupid elements -element_type sphere]
    }

    ## unassign all circles from all the groups in FEM conditions 2D.
    set xp "[spdAux::getRoute DEMParts]/condition\[@n = 'FEMForce2D'\]/group"
    foreach group [$root selectNodes $xp] {
        set groupid [$group @n]
        GiD_EntitiesGroups unassign $groupid -also_lower_entities elements [GiD_EntitiesGroups get $groupid elements -element_type circle]
    }

    ## unassign all triangles from all the groups in DEM conditions 3D.
    set xp "[spdAux::getRoute DEMParts]/condition\[@n = 'DEMForce'\]/group"
    foreach group [$root selectNodes $xp] {
        set groupid [$group @n]
        GiD_EntitiesGroups unassign $groupid -also_lower_entities elements [GiD_EntitiesGroups get $groupid elements -element_type triangle]
    }

    ## unassign all lines from all the groups in DEM conditions 2D.
    set xp "[spdAux::getRoute DEMParts]/condition\[@n = 'DEMForce2D'\]/group"
    foreach group [$root selectNodes $xp] {
        set groupid [$group @n]
        GiD_EntitiesGroups unassign $groupid -also_lower_entities elements [GiD_EntitiesGroups get $groupid elements -element_type linear]
    }


    # TORQUE
    # should be: unassign all spheres from all the groups in FEM conditions .
    set xp "[spdAux::getRoute DEMParts]/condition\[@n = 'FEMTorque'\]/group"
    foreach group [$root selectNodes $xp] {
        set groupid [$group @n]
        GiD_EntitiesGroups unassign $groupid -also_lower_entities elements [GiD_EntitiesGroups get $groupid elements -element_type sphere]
    }

    ## unassign all circles from all the groups in FEM conditions 2D.
    set xp "[spdAux::getRoute DEMParts]/condition\[@n = 'FEMTorque2D'\]/group"
    foreach group [$root selectNodes $xp] {
        set groupid [$group @n]
        GiD_EntitiesGroups unassign $groupid -also_lower_entities elements [GiD_EntitiesGroups get $groupid elements -element_type circle]
    }

    ## unassign all triangles from all the groups in DEM conditions 3D.
    set xp "[spdAux::getRoute DEMParts]/condition\[@n = 'DEMTorque'\]/group"
    foreach group [$root selectNodes $xp] {
        set groupid [$group @n]
        GiD_EntitiesGroups unassign $groupid -also_lower_entities elements [GiD_EntitiesGroups get $groupid elements -element_type triangle]
    }

    ## unassign all lines from all the groups in DEM conditions 2D.
    set xp "[spdAux::getRoute DEMParts]/condition\[@n = 'DEMTorque2D'\]/group"
    foreach group [$root selectNodes $xp] {
        set groupid [$group @n]
        GiD_EntitiesGroups unassign $groupid -also_lower_entities elements [GiD_EntitiesGroups get $groupid elements -element_type linear]
    }


    # Delete all linear/triangle/quadrilateral from sphere_skin
    # Unassign all linear/triangle from sphere_skin
    if [GiD_Groups exists SKIN_SPHERE_DO_NOT_DELETE] {
        GiD_Mesh delete element [GiD_EntitiesGroups get SKIN_SPHERE_DO_NOT_DELETE elements -element_type quadrilateral]
        GiD_Mesh delete element [GiD_EntitiesGroups get SKIN_SPHERE_DO_NOT_DELETE elements -element_type triangle]
        GiD_Mesh delete element [GiD_EntitiesGroups get SKIN_SPHERE_DO_NOT_DELETE elements -element_type linear]

        # GiD_EntitiesGroups unassign SKIN_SPHERE_DO_NOT_DELETE elements [GiD_EntitiesGroups get SKIN_SPHERE_DO_NOT_DELETE elements -element_type linear]
        # GiD_EntitiesGroups unassign SKIN_SPHERE_DO_NOT_DELETE elements [GiD_EntitiesGroups get SKIN_SPHERE_DO_NOT_DELETE elements -element_type triangle]
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
