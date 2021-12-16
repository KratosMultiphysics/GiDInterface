proc ::DEM::write::WriteMDPAWalls { } {
    # Headers
    write::writeModelPartData

    # Material
    DEM::write::processRigidWallMaterials
    if {$::Model::SpatialDimension ne "2D"} {
        DEM::write::processPhantomWallMaterials
    }

    # Properties section
    WriteRigidWallProperties

    # Nodal coordinates (only for Walls <inefficient> )
    write::writeNodalCoordinatesOnGroups [DEM::write::GetWallsGroups]
    if {$::Model::SpatialDimension ne "2D"} {
        write::writeNodalCoordinatesOnGroups [DEM::write::GetWallsGroupsSmp]
    }

    # Nodal conditions and conditions
    writeConditions
    if {$::Model::SpatialDimension ne "2D"} {
        writePhantomConditions
    }

    # SubmodelParts
    writeWallConditionMeshes

    # CustomSubmodelParts
    WriteWallCustomSmp
}


proc ::DEM::write::processRigidWallMaterials { } {
    variable wallsProperties
    set walls_xpath [DEM::write::GetRigidWallXPath]
    write::processMaterials $walls_xpath/group
    set wallsProperties [write::getPropertiesListByConditionXPath $walls_xpath 0 RigidFacePart]
}

proc ::DEM::write::processPhantomWallMaterials { } {
    variable wallsProperties
    set phantom_walls_xpath [DEM::write::GetPhantomWallXPath]
    write::processMaterials $phantom_walls_xpath/group
    set phantomwallsProperties [write::processMaterials $phantom_walls_xpath]
}

proc ::DEM::write::WriteRigidWallProperties { } {

    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"
    write::WriteString ""
}

proc ::DEM::write::WritePhantomWallProperties { } {
    set wall_properties [dict create ]
    set condition_name "Phantom-Wall"
    set cnd [Model::getCondition $condition_name]

    set xp1 [DEM::write::GetPhantomWallXPath]

    #set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-FEM-Wall'\]/group"
    set i $DEM::write::last_property_id
    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
        incr i
        write::WriteString "Begin Properties $i"
        #foreach {prop obj} [$cnd getAllInputs] {
            #    if {$prop in $print_list} {
                #        set v [write::getValueByNode [$group selectNodes "./value\[@n='$prop'\]"]]
                #        write::WriteString "  $prop $v"
                #    }
            #}
        set friction_value [write::getValueByNode [$group selectNodes "./value\[@n='friction_angle'\]"]]
        set pi $MathUtils::PI
        set propvalue [expr {tan($friction_value*$pi/180.0)}]
        write::WriteString "  FRICTION $propvalue"
        # write::WriteString "  FRICTION [write::getValueByNode [$group selectNodes "./value\[@n='friction_coeff'\]"]]"
        write::WriteString "  WALL_COHESION [write::getValueByNode [$group selectNodes "./value\[@n='WallCohesion'\]"]]"
        set compute_wear_bool [write::getValueByNode [$group selectNodes "./value\[@n='DEM_Wear'\]"]]
        if {[write::isBooleanTrue $compute_wear_bool]} {
            set compute_wear 1
            set severiy_of_wear [write::getValueByNode [$group selectNodes "./value\[@n='K_Abrasion'\]"]]
            set impact_wear_severity [write::getValueByNode [$group selectNodes "./value\[@n='K_Impact'\]"]]
            set brinell_hardness [write::getValueByNode [$group selectNodes "./value\[@n='H_Brinell'\]"]]
        } else {
            set compute_wear 0
            set severiy_of_wear 0.001
            set impact_wear_severity 0.001
            set brinell_hardness 200.0
        }
        set rigid_structure_bool [write::getValueByNode [$group selectNodes "./value\[@n='RigidPlane'\]"]]
        if {[write::isBooleanTrue $rigid_structure_bool]} {
            set young_modulus [write::getValueByNode [$group selectNodes "./value\[@n='YoungModulus'\]"]]
            set poisson_ratio [write::getValueByNode [$group selectNodes "./value\[@n='PoissonRatio'\]"]]
        } else {
            set young_modulus 1e20
            set poisson_ratio 0.25
        }
        write::WriteString "  COMPUTE_WEAR $compute_wear"
        write::WriteString "  SEVERITY_OF_WEAR $severiy_of_wear"
        write::WriteString "  IMPACT_WEAR_SEVERITY $impact_wear_severity"
        write::WriteString "  BRINELL_HARDNESS $brinell_hardness"
        write::WriteString "  YOUNG_MODULUS $young_modulus"
        write::WriteString "  POISSON_RATIO $poisson_ratio"

        write::WriteString "End Properties"
        set groupid [$group @n]
        dict set wall_properties $groupid $i
        incr DEM::write::last_property_id
    }
    write::WriteString ""
    return $wall_properties
}


proc ::DEM::write::WriteWallCustomSmp { } {
    set condition_name "DEM-CustomSmp"
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-CustomSmp'\]/group"

    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {

        set groupid [$group @n]
        set destination_mdpa [write::getValueByNode [$group selectNodes "./value\[@n='WhatMdpa'\]"]]
        if {$destination_mdpa == "FEM"} {
            set mid [write::AddSubmodelpart $condition_name $groupid]
            write::WriteString  "Begin SubModelPart $mid \/\/ Custom SubModelPart. Group name: $groupid"
            write::WriteString  "Begin SubModelPartData // DEM-FEM-Wall. Group name: $groupid"
            write::WriteString  "End SubModelPartData"
            write::WriteString  "Begin SubModelPartNodes"
            GiD_WriteCalculationFile nodes -sorted [dict create [write::GetWriteGroupName $groupid] [subst "%10i\n"]]
            write::WriteString  "End SubModelPartNodes"
            write::WriteString  "End SubModelPart"
            write::WriteString  ""
        }
    }
}


proc ::DEM::write::writeConditions {  } {
    variable wallsProperties
    ::write::writeConditionsByGiDId DEMConditions [GetRigidWallConditionName] $wallsProperties
}

proc ::DEM::write::writePhantomConditions {  } {
    variable phantomwallsProperties
    ::write::writeConditionsByGiDId DEMConditions [GetPhantomWallConditionName] $phantomwallsProperties
}

proc ::DEM::write::GetWallsGroups { } {
    set groups [list ]
    set groups_rigid [GetRigidWallsGroups]
    set groups_phantom [GetPhantomWallsGroups]
    set groups [concat $groups_rigid $groups_phantom]
    return $groups
}

proc ::DEM::write::GetRigidWallConditionName {} {
    set condition_name "FEMVelocity"
    if {$::Model::SpatialDimension eq "2D"} {
        set condition_name "FEMVelocity2D"
    }
    return $condition_name
}

proc ::DEM::write::GetFEMVelocityConditionName {} {
    set condition_name "FEMVelocity"
    if {$::Model::SpatialDimension eq "2D"} {
        set condition_name "FEMVelocity2D"
    }
    return $condition_name
}

proc ::DEM::write::GetFEMAngularConditionName {} {
    set condition_name "FEMAngular"
    if {$::Model::SpatialDimension eq "2D"} {
        set condition_name "FEMAngular2D"
    }
    return $condition_name
}

# proc ::DEM::write::GetRigidWallConditionName {} {
#     set condition_name "DEM-FEM-Wall"
#     if {$::Model::SpatialDimension eq "2D"} {
#         set condition_name "DEM-FEM-Wall2D"
#     }
#     return $condition_name
# }


proc ::DEM::write::GetPhantomWallConditionName {} {
    set condition_name "Phantom-Wall"
    if {$::Model::SpatialDimension eq "2D"} {
        set condition_name "Phantom-Wall2D"
    }
    return $condition_name
}

proc ::DEM::write::GetRigidWallXPath { } {
    set condition_name [GetRigidWallConditionName]
    return "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = '$condition_name'\]"
}
proc ::DEM::write::GetPhantomWallXPath { } {
    set condition_name [GetPhantomWallConditionName]
    return "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = '$condition_name'\]"
}

proc ::DEM::write::GetRigidWallsGroups { } {
    set groups [list ]

    foreach group [[customlib::GetBaseRoot] selectNodes "[DEM::write::GetRigidWallXPath]/group"] {
        set groupid [$group @n]
        lappend groups [write::GetWriteGroupName $groupid]
    }
    return $groups
}

proc ::DEM::write::GetPhantomWallsGroups { } {
    set groups [list ]

    foreach group [[customlib::GetBaseRoot] selectNodes "[DEM::write::GetPhantomWallXPath]/group"] {
        set groupid [$group @n]
        lappend groups [write::GetWriteGroupName $groupid]
    }
    return $groups
}

proc ::DEM::write::GetWallsGroupsSmp { } {
    set groups [list ]
    set xp2 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-CustomSmp'\]/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp2] {
        set destination_mdpa [write::getValueByNode [$group selectNodes "./value\[@n='WhatMdpa'\]"]]
        if {$destination_mdpa == "FEM"} {
            set groupid [$group @n]
            lappend groups [write::GetWriteGroupName $groupid]
        }
    }
    return $groups
}

## TODO: UNDER REVISION, UNUSED PROC
proc ::DEM::write::GetWallsGroupsListInConditions { } {
    set conds_groups_dict [dict create ]
    set groups [list ]

    # Get all the groups with surfaces involved in walls
    foreach group [GetRigidWallsGroups] {
        foreach surface [GiD_EntitiesGroups get $group surfaces] {
            foreach involved_group [GiD_EntitiesGroups entity_groups surfaces $surface] {
                set involved_group_id [write::GetWriteGroupName $involved_group]
                if {$involved_group_id ni $groups} {lappend groups $involved_group_id}
            }
        }
    }

    foreach group [GetRigidWallsGroups] {
        foreach line [GiD_EntitiesGroups get $group lines] {
            foreach involved_group [GiD_EntitiesGroups entity_groups lines $line] {
                set involved_group_id [write::GetWriteGroupName $involved_group]
                if {$involved_group_id ni $groups} {lappend groups $involved_group_id}
            }
        }
    }

    # Find the relations condition -> group
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition"
    foreach cond [[customlib::GetBaseRoot] selectNodes $xp1] {
        set condid [$cond @n]
        foreach cond_group [$cond selectNodes "group"] {
            set group [write::GetWriteGroupName [$cond_group @n]]
            if {$group in $groups} {dict lappend conds_groups_dict $condid [$cond_group @n]}
        }
    }
    return $conds_groups_dict
}


## TODO: UNDER REVISION, UNUSED PROC
proc ::DEM::write::GetConditionsGroups { } {
    set groups [list ]
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
        set groupid [$group @n]
        lappend groups [write::GetWriteGroupName $groupid]
    }
    return $groups
}

proc ::DEM::write::writeWallConditionMeshes { } {
    variable wallsProperties
    variable phantomwallsProperties

    set condition_name [GetRigidWallConditionName]
    foreach group [GetRigidWallsGroups] {
        set mid [write::AddSubmodelpart $condition_name $group]
        set props [DEM::write::FindPropertiesBySubmodelpart $wallsProperties $mid]
        writeWallConditionMesh $condition_name $group $props
    }

    if {$::Model::SpatialDimension ne "2D"} {
        set condition_name [GetPhantomWallConditionName]
        foreach group [GetPhantomWallsGroups] {
            set mid [write::AddSubmodelpart $condition_name $group]
            set props [DEM::write::FindPropertiesBySubmodelpart $phantomwallsProperties $mid]
            writeWallConditionMesh $condition_name $group $props
        }
    }
}

proc ::DEM::write::writeWallConditionMesh { condition group props } {

    set mid [write::AddSubmodelpart $condition $group]

    write::WriteString "Begin SubModelPart $mid // $condition - group identifier: $group"
    write::WriteString "  Begin SubModelPartData // $condition. Group name: $group"
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = '$condition'\]/group\[@n = '$group'\]"
    set group_node [[customlib::GetBaseRoot] selectNodes $xp1]

    set is_active [dict get $props Material Variables SetActive]
    set is_active 0
    if {[write::isBooleanTrue $is_active]} {

            write::WriteString "    RIGID_BODY_OPTION 1"
            #TODO: read from parts-FEM-Mass, inertia, etc..
            set mass [dict get $props Material Variables Mass]
            write::WriteString "    RIGID_BODY_MASS $mass"

            lassign [dict get $props Material Variables CenterOfMass] cX cY cZ
            if {$::Model::SpatialDimension eq "2D"} {write::WriteString "    RIGID_BODY_CENTER_OF_ROTATION \[3\] ($cX,$cY,0.0)"
            } else {write::WriteString "    RIGID_BODY_CENTER_OF_ROTATION \[3\] ($cX,$cY,$cZ)"}

            set inertias [dict get $props Material Variables Inertia]
            if {$::Model::SpatialDimension eq "2D"} {
                set iX $inertias
                write::WriteString "    RIGID_BODY_INERTIAS \[3\] (0.0,0.0,$iX)"
            } else {
                lassign $inertias iX iY iZ
                write::WriteString "    RIGID_BODY_INERTIAS \[3\] ($iX,$iY,$iZ)"
            }
            write::WriteString "    ORIENTATION \[4\] ($iX,$iY,$iZ, $iW)"

        write::WriteString "    IDENTIFIER [write::transformGroupName $group]"
        DEM::write::DefineFEMExtraConditions $props
    }
    write::WriteString "  End SubModelPartData"

    write::WriteString "  Begin SubModelPartNodes"
    GiD_WriteCalculationFile nodes -sorted [dict create [write::GetWriteGroupName $group] [subst "%10i\n"]]
    write::WriteString "  End SubModelPartNodes"

    write::WriteString "Begin SubModelPartConditions"
    set gdict [dict create]
    set f "%10i\n"
    set f [subst $f]
    dict set gdict $group $f
    GiD_WriteCalculationFile elements -sorted $gdict
    write::WriteString "End SubModelPartConditions"
    write::WriteString ""
    write::WriteString "End SubModelPart"
    write::WriteString ""
}

proc ::DEM::write::DefineFEMExtraConditions {props} {
    set GraphPrint [dict get $props Material Variables GraphPrint]
    set GraphPrintval 0
    if {[write::isBooleanTrue $GraphPrint]} {
        set GraphPrintval 1
    }
    write::WriteString "    FORCE_INTEGRATION_GROUP $GraphPrintval"
}
