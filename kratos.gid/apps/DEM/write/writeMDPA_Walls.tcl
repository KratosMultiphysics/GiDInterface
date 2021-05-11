proc DEM::write::WriteMDPAWalls { } {
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


proc DEM::write::processRigidWallMaterials { } {
    variable wallsProperties
    set walls_xpath [DEM::write::GetRigidWallXPath]
    write::processMaterials $walls_xpath/group
    set wallsProperties [write::getPropertiesListByConditionXPath $walls_xpath 0 RigidFacePart]
}

proc DEM::write::processPhantomWallMaterials { } {
    variable wallsProperties
    set phantom_walls_xpath [DEM::write::GetPhantomWallXPath]
    write::processMaterials $phantom_walls_xpath/group
    set phantomwallsProperties [write::processMaterials $phantom_walls_xpath]
}

proc DEM::write::WriteRigidWallProperties { } {

    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"
    write::WriteString ""
}

proc DEM::write::WritePhantomWallProperties { } {
    set wall_properties [dict create ]
    set condition_name 'Phantom-Wall'
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


proc DEM::write::WriteWallCustomSmp { } {
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


proc DEM::write::writeConditions {  } {
    variable wallsProperties
    write::writeConditionsByGiDId DEMConditions [GetRigidWallConditionName] $wallsProperties
}

proc DEM::write::writePhantomConditions {  } {
    variable phantomwallsProperties
    write::writeConditionsByGiDId DEMConditions [GetPhantomWallConditionName] $phantomwallsProperties
}

proc DEM::write::GetWallsGroups { } {
    set groups [list ]
    set groups_rigid [GetRigidWallsGroups]
    set groups_phantom [GetPhantomWallsGroups]
    set groups [concat $groups_rigid $groups_phantom]
    return $groups
}

proc DEM::write::GetRigidWallConditionName {} {
    set condition_name "DEM-FEM-Wall"
    if {$::Model::SpatialDimension eq "2D"} {
        set condition_name "DEM-FEM-Wall2D"
    }
    return $condition_name
}
proc DEM::write::GetPhantomWallConditionName {} {
    set condition_name "Phantom-Wall"
    if {$::Model::SpatialDimension eq "2D"} {
        set condition_name "Phantom-Wall2D"
    }
    return $condition_name
}

proc DEM::write::GetRigidWallXPath { } {
    set condition_name [GetRigidWallConditionName]
    return "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = '$condition_name'\]"
}
proc DEM::write::GetPhantomWallXPath { } {
    set condition_name [GetPhantomWallConditionName]
    return "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = '$condition_name'\]"
}

proc DEM::write::GetRigidWallsGroups { } {
    set groups [list ]

    foreach group [[customlib::GetBaseRoot] selectNodes "[DEM::write::GetRigidWallXPath]/group"] {
        set groupid [$group @n]
        lappend groups [write::GetWriteGroupName $groupid]
    }
    return $groups
}

proc DEM::write::GetPhantomWallsGroups { } {
    set groups [list ]

    foreach group [[customlib::GetBaseRoot] selectNodes "[DEM::write::GetPhantomWallXPath]/group"] {
        set groupid [$group @n]
        lappend groups [write::GetWriteGroupName $groupid]
    }
    return $groups
}

proc DEM::write::GetWallsGroupsSmp { } {
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
proc DEM::write::GetWallsGroupsListInConditions { } {
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
proc DEM::write::GetConditionsGroups { } {
    set groups [list ]
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
        set groupid [$group @n]
        lappend groups [write::GetWriteGroupName $groupid]
    }
    return $groups
}

proc DEM::write::writeWallConditionMeshes { } {
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

proc DEM::write::writeWallConditionMesh { condition group props } {

    set mid [write::AddSubmodelpart $condition $group]

    write::WriteString "Begin SubModelPart $mid // $condition - group identifier: $group"
    write::WriteString "  Begin SubModelPartData // $condition. Group name: $group"
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = '$condition'\]/group\[@n = '$group'\]"
    set group_node [[customlib::GetBaseRoot] selectNodes $xp1]

    set is_active [dict get $props Material Variables SetActive]
    if {[write::isBooleanTrue $is_active]} {
        set motion_type [dict get $props Material Variables DEM-ImposedMotion]
        if {$motion_type == "LinearPeriodic"} {
            # Linear velocity
            set velocity [dict get $props Material Variables VelocityModulus]
            lassign [dict get $props Material Variables DirectionVector] velocity_X velocity_Y velocity_Z
            if {$::Model::SpatialDimension eq "2D"} {
                lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y]] velocity_X velocity_Y
                lassign [MathUtils::ScalarByVectorProd $velocity [list $velocity_X $velocity_Y] ] vx vy
                write::WriteString "    LINEAR_VELOCITY \[3\] ($vx, $vy, 0.0)"
            } else {
                lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y $velocity_Z]] velocity_X velocity_Y velocity_Z
                lassign [MathUtils::ScalarByVectorProd $velocity [list $velocity_X $velocity_Y $velocity_Z] ] vx vy vz
                write::WriteString "    LINEAR_VELOCITY \[3\] ($vx, $vy, $vz)"
            }
            # set vX [dict get $props Material Variables LinearVelocityX'\]"]]

            # Period
            set periodic [dict get $props Material Variables LinearPeriodic]
            if {[write::isBooleanTrue $periodic]} {
                set period [dict get $props Material Variables LinearPeriod]
            } else {
                set period 0.0
            }
            write::WriteString "    VELOCITY_PERIOD $period"

            # Angular velocity
            set avelocity [dict get $props Material Variables AngularVelocityModulus]
            if {$::Model::SpatialDimension eq "2D"} {
                write::WriteString "    ANGULAR_VELOCITY \[3\] (0.0,0.0,$avelocity)"
            } else {
                lassign [dict get $props Material Variables AngularDirectionVector] velocity_X velocity_Y velocity_Z
                lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y $velocity_Z]] velocity_X velocity_Y velocity_Z
                lassign [MathUtils::ScalarByVectorProd $avelocity [list $velocity_X $velocity_Y $velocity_Z] ] wx wy wz
                write::WriteString "    ANGULAR_VELOCITY \[3\] ($wx,$wy,$wz)"}

            # Angular center of rotation
            lassign  [dict get $props Material Variables CenterOfRotation] oX oY oZ
            if {$::Model::SpatialDimension eq "2D"} {write::WriteString "    ROTATION_CENTER \[3\] ($oX,$oY,0.0)"
            } else {write::WriteString "    ROTATION_CENTER \[3\] ($oX,$oY,$oZ)"}

            # Angular Period
            set angular_periodic [dict get $props Material Variables AngularPeriodic]
            set angular_period 0.0
            if {[write::isBooleanTrue $angular_periodic]} {
                set angular_period [dict get $props Material Variables AngularPeriod]
            }
            write::WriteString "    ANGULAR_VELOCITY_PERIOD $angular_period"

            # set intervals
            set LinearStartTime  [dict get $props Material Variables LinearStartTime]
            set LinearEndTime    [dict get $props Material Variables LinearEndTime]
            set AngularStartTime [dict get $props Material Variables AngularStartTime]
            set AngularEndTime   [dict get $props Material Variables AngularEndTime]
            write::WriteString "    VELOCITY_START_TIME $LinearStartTime"
            write::WriteString "    VELOCITY_STOP_TIME $LinearEndTime"
            write::WriteString "    ANGULAR_VELOCITY_START_TIME $AngularStartTime"
            write::WriteString "    ANGULAR_VELOCITY_STOP_TIME $AngularEndTime"

            set fixed_mesh_option_bool [dict get $props Material Variables fixed_wall]
            set fixed_mesh_option 0
            if {[write::isBooleanTrue $fixed_mesh_option_bool]} {
                set fixed_mesh_option 1
            }
            set rigid_body_motion 1
            set free_body_motion 0
            #Hardcoded
            write::WriteString "    FIXED_MESH_OPTION $fixed_mesh_option"
            write::WriteString "    RIGID_BODY_MOTION $rigid_body_motion"
            write::WriteString "    FREE_BODY_MOTION $free_body_motion"

        } elseif {$motion_type == "FreeMotion"} {
            set fixed_mesh_option 0
            set rigid_body_motion 0
            set free_body_motion 1

            set mass [dict get $props Material Variables Mass]
            write::WriteString "    RIGID_BODY_MASS $mass"

            lassign [dict get $props Material Variables CenterOfMass] cX cY cZ
            if {$::Model::SpatialDimension eq "2D"} {write::WriteString "    RIGID_BODY_CENTER_OF_MASS \[3\] ($cX,$cY,0.0)"
            } else {write::WriteString "    RIGID_BODY_CENTER_OF_MASS \[3\] ($cX,$cY,$cZ)"}

            set inertias [dict get $props Material Variables Inertia]
            if {$::Model::SpatialDimension eq "2D"} {
                set iX $inertias
                write::WriteString "    RIGID_BODY_INERTIAS \[3\] (0.0,0.0,$iX)"
            } else {
                lassign $inertias iX iY iZ
                write::WriteString "    RIGID_BODY_INERTIAS \[3\] ($iX,$iY,$iZ)"
            }

            # DOFS
            set Ax [dict get $props Material Variables Ax]
            set Ay [dict get $props Material Variables Ay]
            set Az [dict get $props Material Variables Az]
            set Bx [dict get $props Material Variables Bx]
            set By [dict get $props Material Variables By]
            set Bz [dict get $props Material Variables Bz]
            if {$Ax == "Constant"} {
                set fix_vx [dict get $props Material Variables Vx]
                write::WriteString "    IMPOSED_VELOCITY_X_VALUE $fix_vx"
            }
            if {$Ay == "Constant"} {
                set fix_vy [dict get $props Material Variables Vy]
                write::WriteString "    IMPOSED_VELOCITY_Y_VALUE $fix_vy"
            }
            if {$Az == "Constant"} {
                set fix_vz [dict get $props Material Variables Vz]
                if {$::Model::SpatialDimension eq "2D"} {write::WriteString "    IMPOSED_VELOCITY_Z_VALUE 0.0"
                } else {write::WriteString "    IMPOSED_VELOCITY_Z_VALUE $fix_vz"}

            }
            if {$Bx == "Constant"} {
                set fix_avx [dict get $props Material Variables AVx]
                if {$::Model::SpatialDimension eq "2D"} {write::WriteString "    IMPOSED_ANGULAR_VELOCITY_X_VALUE 0.0"
                } else {write::WriteString "    IMPOSED_ANGULAR_VELOCITY_X_VALUE $fix_avx"}

            }
            if {$By == "Constant"} {
                set fix_avy [dict get $props Material Variables AVy]
                if {$::Model::SpatialDimension eq "2D"} {write::WriteString "    IMPOSED_ANGULAR_VELOCITY_Y_VALUE 0.0"
                } else {write::WriteString "    IMPOSED_ANGULAR_VELOCITY_Y_VALUE $fix_avy"}

            }
            if {$Bz == "Constant"} {
                set fix_avz [dict get $props Material Variables AVz]
                write::WriteString "    IMPOSED_ANGULAR_VELOCITY_Z_VALUE $fix_avz"
            }
            set VStart [dict get $props Material Variables VStart]
            set VEnd [dict get $props Material Variables VEnd]
            write::WriteString "    VELOCITY_START_TIME $VStart"
            write::WriteString "    VELOCITY_STOP_TIME $VEnd"

            # initial conditions
            set iAx [dict get $props Material Variables iAx]
            set iAy [dict get $props Material Variables iAy]
            set iAz [dict get $props Material Variables iAz]
            set iBx [dict get $props Material Variables iBx]
            set iBy [dict get $props Material Variables iBy]
            set iBz [dict get $props Material Variables iBz]
            if {$iAx == "true"} {
                set fix_vx [dict get $props Material Variables iVx]
                write::WriteString "    INITIAL_VELOCITY_X_VALUE $fix_vx"
            }
            if {$iAy == "true"} {
                set fix_vy [dict get $props Material Variables iVy]
                write::WriteString "    INITIAL_VELOCITY_Y_VALUE $fix_vy"
            }
            if {$iAz == "true"} {
                set fix_vz [dict get $props Material Variables iVz]
                if {$::Model::SpatialDimension eq "2D"} {write::WriteString "    INITIAL_VELOCITY_Z_VALUE 0.0"
                } else {write::WriteString "    INITIAL_VELOCITY_Z_VALUE $fix_vz"}

            }
            if {$iBx == "true"} {
                set fix_avx [dict get $props Material Variables iAVx]
                if {$::Model::SpatialDimension eq "2D"} {write::WriteString "    INITIAL_ANGULAR_VELOCITY_X_VALUE 0.0"
                } else {write::WriteString "    INITIAL_ANGULAR_VELOCITY_X_VALUE $fix_avx"}

            }
            if {$iBy == "true"} {
                set fix_avy [dict get $props Material Variables iAVy]
                if {$::Model::SpatialDimension eq "2D"} {write::WriteString "    INITIAL_ANGULAR_VELOCITY_Y_VALUE 0.0"
                } else {write::WriteString "    INITIAL_ANGULAR_VELOCITY_Y_VALUE $fix_avy"}

            }
            if {$iBz == "true"} {
                set fix_avz [dict get $props Material Variables iAVz]
                write::WriteString "    INITIAL_ANGULAR_VELOCITY_Z_VALUE $fix_avz"
            }

            # impose forces and moments
            set ExternalForceX [dict get $props Material Variables ExternalForceX]
            set ExternalForceY [dict get $props Material Variables ExternalForceY]
            set ExternalForceZ [dict get $props Material Variables ExternalForceZ]
            set ExternalMomentX [dict get $props Material Variables ExternalMomentX]
            set ExternalMomentY [dict get $props Material Variables ExternalMomentY]
            set ExternalMomentZ [dict get $props Material Variables ExternalMomentZ]

            if {$ExternalForceX == "true"} {
                set FX [dict get $props Material Variables FX]
                write::WriteString "    EXTERNAL_APPLIED_FORCE_X $FX"
            }
            if {$ExternalForceY == "true"} {
                set FY [dict get $props Material Variables FY]
                write::WriteString "    EXTERNAL_APPLIED_FORCE_Y $FY"
            }
            if {$ExternalForceZ == "true"} {
                set FZ [dict get $props Material Variables FZ]
                write::WriteString "    EXTERNAL_APPLIED_FORCE_Z $FZ"
            }
            if {$ExternalMomentX == "true"} {
                set MX [dict get $props Material Variables MX]
                write::WriteString "    EXTERNAL_APPLIED_MOMENT_X $MX"
            }
            if {$ExternalMomentY == "true"} {
                set MY [dict get $props Material Variables MY]
                write::WriteString "    EXTERNAL_APPLIED_MOMENT_Y $MY"
            }
            if {$ExternalMomentZ == "true"} {
                set MZ [dict get $props Material Variables MZ]
                write::WriteString "    EXTERNAL_APPLIED_MOMENT_Z $MZ"
            }
            #Hardcoded
            write::WriteString "    FIXED_MESH_OPTION $fixed_mesh_option"
            write::WriteString "    RIGID_BODY_MOTION $rigid_body_motion"
            write::WriteString "    FREE_BODY_MOTION $free_body_motion"
        }

        #Hardcoded
        set is_ghost [dict get $props Material Variables IsGhost]
        if {$is_ghost == "true"} {
            write::WriteString "    IS_GHOST 1"
        } else {
            write::WriteString "    IS_GHOST 0"
        }
        write::WriteString "    IDENTIFIER [write::transformGroupName $group]"

        DefineFEMExtraConditions $props

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

proc DEM::write::DefineFEMExtraConditions {props} {
    set GraphPrint [dict get $props Material Variables GraphPrint]
    if {$GraphPrint == "true"} {
        set GraphPrintval 1
    } else {
        set GraphPrintval 0
    }
    write::WriteString "    FORCE_INTEGRATION_GROUP $GraphPrintval"
}
